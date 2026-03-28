dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local last_enabled = nil

function OnPlayerSpawned(player)
    local autoaim = Player(player).autoaim  -- Creates the LuaComponent if not present.
    last_enabled = nil                       -- Force setting re-application on next update.
end

function OnWorldPostUpdate()
    local setting_enabled = ModSettingGet("thaumic_guidance.enabled")
    local mod_enabled = setting_enabled == nil or setting_enabled == true
    if mod_enabled ~= last_enabled then
        last_enabled = mod_enabled
        for _, player in ipairs(EntityGetWithTag("player_unit") or {}) do
            local autoaim = Player(player).autoaim
            if autoaim ~= nil then
                autoaim._enabled = mod_enabled
            end
        end
        GamePrint("Thaumic Guidance " .. (mod_enabled and "enabled" or "disabled"))
    end
end
