dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

function OnPlayerSpawned(player)
    local player_object = Player(player)
    local autoaim = player_object.autoaim
    local setting_enabled = ModSettingGet("thaumic_guidance.enabled")
    local mod_enabled = setting_enabled == nil or setting_enabled == true
    autoaim._enabled = mod_enabled
    GamePrint("Thaumic Guidance " .. (autoaim._enabled and "enabled" or "disabled"))
end
