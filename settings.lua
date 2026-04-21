dofile("data/scripts/lib/mod_settings.lua")

-- This file can't access other files from this or other mods in all circumstances.

local mod_id = "thaumic_guidance"
mod_settings_version = 1

local SHORTCUT_KEYS = {
    Key_a=4,  Key_b=5,  Key_c=6,  Key_d=7,  Key_e=8,  Key_f=9,  Key_g=10,
    Key_h=11, Key_i=12, Key_j=13, Key_k=14, Key_l=15, Key_m=16, Key_n=17,
    Key_o=18, Key_p=19, Key_q=20, Key_r=21, Key_s=22, Key_t=23, Key_u=24,
    Key_v=25, Key_w=26, Key_x=27, Key_y=28, Key_z=29,
    Key_1=30, Key_2=31, Key_3=32, Key_4=33, Key_5=34,
    Key_6=35, Key_7=36, Key_8=37, Key_9=38, Key_0=39,
    Key_F1=58, Key_F2=59, Key_F3=60, Key_F4=61, Key_F5=62,
    Key_F6=63, Key_F7=64, Key_F8=65, Key_F9=66, Key_F10=67, Key_F11=68, Key_F12=69,
}
local CANCEL_KEYS = { Key_ESCAPE=41, Key_RETURN=40, Key_BACKSPACE=42 }

local function shortcut_key_name(code)
    for name, k in pairs(SHORTCUT_KEYS) do
        if k == code then
            local label = name:gsub("^Key_", "")
            return #label == 1 and label:upper() or label
        end
    end
    return tostring(code)
end

local shortcut_awaiting_input = false
local function shortcut_key_ui_fn(mod_id_, gui, in_main_menu, im_id, setting)
    local id = mod_setting_get_id(mod_id_, setting)
    local current = ModSettingGetNextValue(id) or setting.value_default
    GuiLayoutBeginHorizontal(gui, mod_setting_group_x_offset, 0, true)
    local new_value
    local label
    if shortcut_awaiting_input then
        label = "Press a key..."
        for _, code in pairs(SHORTCUT_KEYS) do
            if InputIsKeyDown(code) then
                shortcut_awaiting_input = false
                new_value = code
                break
            end
        end
        if new_value == nil then
            for _, code in pairs(CANCEL_KEYS) do
                if InputIsKeyDown(code) then
                    shortcut_awaiting_input = false
                    break
                end
            end
        end
    else
        label = shortcut_key_name(current)
    end
    if GuiButton(gui, im_id, 0, 0, setting.ui_name .. ": " .. label) then
        shortcut_awaiting_input = true
    end
    local right_clicked = select(2, GuiGetPreviousWidgetInfo(gui))
    if right_clicked then
        new_value = setting.value_default
        GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
    end
    GuiLayoutEnd(gui)
    if new_value ~= nil then
        ModSettingSetNextValue(id, new_value, false)
        mod_setting_handle_change_callback(mod_id_, gui, in_main_menu, setting, current, new_value)
    end
    mod_setting_tooltip(mod_id_, gui, in_main_menu, setting)
end

mod_settings = {
    {
        id = "thaumic_guidance",
        ui_name = "Thaumic Guidance",
        ui_description = "Enable or disable Thaumic Guidance aim assist.",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "arcane_identification",
        ui_name = "Arcane Identification",
        ui_description = "Show the name of the targeted enemy in the game log when Thaumic Guidance locks on.",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "warding_glyphs",
        ui_name = "Warding Glyphs",
        ui_description = "Show indicators at the edge of the screen pointing toward off-screen enemies.",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
    {
        id = "shortcut_key",
        ui_name = "Binding Rune",
        ui_description = "Key to awaken or silence the thaumic sigils. Click to rebind; right-click to reset to G.",
        value_default = 10,
        ui_fn = shortcut_key_ui_fn,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
}

function ModSettingsUpdate(init_scope)
    local old_version = mod_settings_get_version(mod_id)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
