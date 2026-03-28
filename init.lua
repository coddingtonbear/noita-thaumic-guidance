dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local last_enabled = nil

function OnPlayerSpawned(player)
    local autoaim = Player(player).autoaim  -- Creates the LuaComponent if not present.
    if autoaim ~= nil and last_enabled ~= nil then
        autoaim._enabled = last_enabled
    end
end

function OnWorldPostUpdate()
    local setting_enabled = ModSettingGet("thaumic_guidance.enabled")
    local mod_enabled = setting_enabled == nil or setting_enabled == true
    if mod_enabled ~= last_enabled then
        local players = EntityGetWithTag("player_unit") or {}
        last_enabled = mod_enabled
        for _, player in ipairs(players) do
            local autoaim = Player(player).autoaim
            if autoaim ~= nil then
                autoaim._enabled = mod_enabled
            end
        end
        if #players > 0 then
            GamePrint("Thaumic Guidance " .. (mod_enabled and "enabled" or "disabled"))
        end
    end
end
