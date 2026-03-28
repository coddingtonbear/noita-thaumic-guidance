print("Loading Aim Assist Mod")

dofile_once("mods/aim_assist/files/scripts/lib/utilities.lua")

function OnPlayerSpawned(player)
    local player_object = Player(player)
    local autoaim = player_object.autoaim
    autoaim._enabled = GameGetIsGamepadConnected() or InputIsJoystickConnected(0)
    print("Autoaim " .. (autoaim._enabled and "enabled" or "disabled") .. " for player " .. tostring(player))
end
