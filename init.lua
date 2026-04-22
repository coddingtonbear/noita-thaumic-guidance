dofile_once("mods/thaumic_guidance/files/scripts/lib/utilities.lua")

local last_enabled = nil
local last_warding_enabled = nil
local last_shortcut_down = false

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
    local mod_enabled = setting_is_enabled("thaumic_guidance")
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
    local shortcut_code = ModSettingGet("thaumic_guidance.shortcut_key")
    if shortcut_code then
        local key_down = InputIsKeyDown(shortcut_code)
        if key_down and not last_shortcut_down then
            local new_value = not setting_is_enabled("thaumic_guidance")
            ModSettingSetNextValue("thaumic_guidance.thaumic_guidance", new_value, false)
            ModSettingSet("thaumic_guidance.thaumic_guidance", new_value)
        end
        last_shortcut_down = key_down
    end

    local mod_enabled = setting_is_enabled("thaumic_guidance")
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
