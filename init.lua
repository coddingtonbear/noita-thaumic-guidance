dofile_once("mods/aim_assist/files/scripts/lib/utilities.lua")

function OnWorldPreUpdate()
    local player = EntityGetWithTag("player_unit")[1]
    if player == nil then return end
    local player_object = Player(player)
    local autoaim = player_object.autoaim
    autoaim._enabled = GameGetIsGamepadConnected()
end
