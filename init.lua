dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local last_enabled = nil

local function announce_enabled(enabled)
    GamePrint("Thaumic Guidance " .. (enabled and "enabled" or "disabled"))
end

function OnPlayerSpawned(player)
    local setting_enabled = ModSettingGet("thaumic_guidance.enabled")
    local mod_enabled = setting_enabled == nil or setting_enabled == true
    local autoaim = Player(player).autoaim  -- Creates the LuaComponent if not present.
    if autoaim ~= nil then
        autoaim._enabled = mod_enabled
    end
    announce_enabled(mod_enabled)
end

function OnWorldPostUpdate()
    local setting_enabled = ModSettingGet("thaumic_guidance.enabled")
    local mod_enabled = setting_enabled == nil or setting_enabled == true
    if mod_enabled ~= last_enabled then
        local should_announce = last_enabled ~= nil
        last_enabled = mod_enabled
        for _, player in ipairs(EntityGetWithTag("player_unit") or {}) do
            local autoaim = Player(player).autoaim
            if autoaim ~= nil then
                autoaim._enabled = mod_enabled
            end
        end
        if should_announce then
            announce_enabled(mod_enabled)
        end
    end
end
