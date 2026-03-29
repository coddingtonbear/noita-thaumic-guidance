dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local last_enabled = nil
local last_warding_enabled = nil

local function announce_enabled(enabled)
    GamePrint("Thaumic sigils " .. (enabled and "awakened" or "dormant") .. ".")
end

local function announce_warding_enabled(enabled)
    GamePrint("Warding glyphs " .. (enabled and "inscribed" or "dispelled") .. ".")
end

local function setting_is_enabled(id)
    local value = ModSettingGet("thaumic_guidance." .. id)
    return value == nil or value == true
end

function OnPlayerSpawned(player)
    local mod_enabled = setting_is_enabled("enabled")
    local autoaim = Player(player).autoaim  -- Creates the LuaComponent if not present.
    if autoaim ~= nil then
        autoaim._enabled = mod_enabled
    end
    announce_enabled(mod_enabled)

    local warding_enabled = setting_is_enabled("warding_glyphs")
    local warding = Player(player).warding_glyphs  -- Creates the LuaComponent if not present.
    if warding ~= nil then
        warding._enabled = warding_enabled
    end
    announce_warding_enabled(warding_enabled)
end

function OnWorldPostUpdate()
    local mod_enabled = setting_is_enabled("enabled")
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

    local warding_enabled = setting_is_enabled("warding_glyphs")
    if warding_enabled ~= last_warding_enabled then
        local should_announce = last_warding_enabled ~= nil
        last_warding_enabled = warding_enabled
        for _, player in ipairs(EntityGetWithTag("player_unit") or {}) do
            local warding = Player(player).warding_glyphs
            if warding ~= nil then
                warding._enabled = warding_enabled
            end
        end
        if should_announce then
            announce_warding_enabled(warding_enabled)
        end
    end
end
