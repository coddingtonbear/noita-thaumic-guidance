dofile("data/scripts/lib/mod_settings.lua")

-- This file can't access other files from this or other mods in all circumstances.

local mod_id = "thaumic_guidance"
mod_settings_version = 1

mod_settings = {
    {
        id = "enabled",
        ui_name = "Enabled",
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
