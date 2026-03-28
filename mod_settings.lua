dofile_once("data/scripts/lib/mod_settings.lua")

local mod_id = "thaumic_guidance"

local settings = {
    {
        id = "enabled",
        ui_name = "Enabled",
        ui_description = "Enable or disable Thaumic Guidance aim assist.",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
        ui_fn = mod_setting_bool,
    },
}

function ModSettingsUpdate(init_scope)
    mod_settings_update(mod_id, settings, init_scope)
end

function ModSettingsGuiOrderNumber()
    return 0
end

function ModSettingsGui(gui, in_main_menu, mod_setting_info)
    mod_settings_gui(mod_id, settings, gui, in_main_menu, mod_setting_info)
end
