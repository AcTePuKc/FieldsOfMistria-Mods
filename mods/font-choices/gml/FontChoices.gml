#macro FC_ID "font_choices_act"
#macro FC_VERSION 1
#macro FC_CATEGORY "font_choices"
#macro FC_SELECT_KEY "font_choices_select"
#macro FC_POPUP_KEY "font_choices_popup"
#macro FC_ALL_TEXT_KEY "font_all_text"
#macro FC_STANDARD_KEY "font_standard"
#macro FC_POPUP_DESCRIPTION_KEY "font_popup_description"
#macro FC_TEXTBOX_KEY "font_textbox"
#macro FC_SETTINGS_KEY "font_choices_selected"
#macro FC_LAB_CATEGORY "font_lab"
#macro FC_LAB_SELECT_KEY "font_lab_select"
#macro FC_LAB_POPUP_KEY "font_lab_popup"
#macro FC_LAB_TARGET_KEY "font_lab_target"
#macro FC_LAB_TARGET_POPUP_KEY "font_lab_target_popup"
#macro FC_LAB_SETTINGS_KEY "font_choices_lab_selected"
#macro FC_LAB_ALL_KEY "font_lab_all"
#macro FC_EXPERIMENTAL_KEY "font_experimental_select"
#macro FC_FONT_BIRDSEED_BUL "fnt_font_choices_birdseed_bul"
#macro FC_FONT_BIRDSEED "fnt_mistria_birdseed"
#macro FC_FONT_SILVER "fnt_silver"
#macro FC_FONT_IBM_PLEX "fnt_font_choices_ibm_plex"
#macro FC_FONT_ROBOTO_CONDENSED "fnt_font_choices_roboto_condensed"
#macro FC_FONT_PLAY "fnt_font_choices_play"
#macro FC_FONT_MARMELAD "fnt_font_choices_marmelad"
#macro FC_FONT_MONOMAKH "fnt_font_choices_monomakh"
#macro FC_FONT_PLAYPEN_SANS "fnt_font_choices_playpen_sans"

function fc_runtime() {
    if (global[$ "__font_choices"] == undefined) {
        global.__font_choices = { registered: false, config: undefined, pending_choices: {}, settings_menu: undefined, startup_fonts_applied: false, diagnostics: {}, original_styles: {}, lab_target: "all" };
    }
    return global.__font_choices;
}

function fc_log_once(_key, _message) {
    var _rt = fc_runtime();
    if (_rt.diagnostics[$ _key]) return;
    _rt.diagnostics[$ _key] = true;
    mmapi_log_info(FC_ID, _message);
    mmapi_log_flush(FC_ID);
}

// This is the only registry to extend after a language/font pair has passed
// glyph coverage and an in-game visual test. A language without an entry is
// deliberately passive: it receives no UI category and no TEXT_STYLES change.
function fc_font_choice(_language, _id, _asset) {
    return { id: _id, label: fc_ui_label(_language, "font_" + _id), asset: _asset };
}

function fc_latin_test_choices(_language) {
    var _choices = [
        fc_font_choice(_language, "silver", FC_FONT_SILVER),
        fc_font_choice(_language, "ibm_plex", FC_FONT_IBM_PLEX),
        fc_font_choice(_language, "roboto_condensed", FC_FONT_ROBOTO_CONDENSED),
        fc_font_choice(_language, "play", FC_FONT_PLAY),
        fc_font_choice(_language, "marmelad", FC_FONT_MARMELAD),
        fc_font_choice(_language, "monomakh", FC_FONT_MONOMAKH),
        fc_font_choice(_language, "playpen_sans", FC_FONT_PLAYPEN_SANS),
    ];
    return _choices;
}

function fc_polish_test_choices(_language) {
    // The visual pass rejected every direct test font for Polish. IBM Plex
    // remains available through its two explicit 17x13 Lab variants only.
    var _choices = [fc_font_choice(_language, "silver", FC_FONT_SILVER)];
    return _choices;
}

function fc_profile_registry() {
    static _registry = [
        {
            code: "bul", default_choice: "birdseed",
            ui: fc_ui_catalog("bul"),
            choices: [
                fc_font_choice("bul", "birdseed", FC_FONT_BIRDSEED_BUL),
                fc_font_choice("bul", "silver", FC_FONT_SILVER),
                fc_font_choice("bul", "roboto_condensed", FC_FONT_ROBOTO_CONDENSED),
                fc_font_choice("bul", "play", FC_FONT_PLAY),
                fc_font_choice("bul", "marmelad", FC_FONT_MARMELAD),
                fc_font_choice("bul", "monomakh", FC_FONT_MONOMAKH),
                fc_font_choice("bul", "playpen_sans", FC_FONT_PLAYPEN_SANS),
            ],
        },
        {
            code: "eng", default_choice: "silver",
            ui: fc_ui_catalog("eng"),
            choices: [
                fc_font_choice("eng", "silver", FC_FONT_SILVER),
                fc_font_choice("eng", "ibm_plex", FC_FONT_IBM_PLEX),
                fc_font_choice("eng", "roboto_condensed", FC_FONT_ROBOTO_CONDENSED),
                fc_font_choice("eng", "play", FC_FONT_PLAY),
                fc_font_choice("eng", "marmelad", FC_FONT_MARMELAD),
                fc_font_choice("eng", "monomakh", FC_FONT_MONOMAKH),
                fc_font_choice("eng", "playpen_sans", FC_FONT_PLAYPEN_SANS),
            ],
        },
        {
            code: "fra", default_choice: "silver",
            ui: fc_ui_catalog("fra"),
            choices: fc_latin_test_choices("fra"),
        },
        {
            code: "spa", default_choice: "silver",
            ui: fc_ui_catalog("spa"),
            choices: fc_latin_test_choices("spa"),
        },
        {
            code: "por", default_choice: "silver",
            ui: fc_ui_catalog("por"),
            choices: fc_latin_test_choices("por"),
        },
        {
            code: "pol", default_choice: "silver",
            ui: fc_ui_catalog("pol"),
            choices: fc_polish_test_choices("pol"),
        },
        {
            code: "rus", default_choice: "birdseed",
            ui: fc_ui_catalog("rus"),
            choices: [
                fc_font_choice("rus", "birdseed", FC_FONT_BIRDSEED),
                // IBM passed the full audit. Playpen is visually approved for
                // Cyrillic; its only audit exception is the invisible U+202F
                // narrow no-break space used by the Russian assets.
                fc_font_choice("rus", "ibm_plex", FC_FONT_IBM_PLEX),
                fc_font_choice("rus", "playpen_sans", FC_FONT_PLAYPEN_SANS),
            ],
        },
        {
            code: "tur", default_choice: "silver",
            ui: fc_ui_catalog("tur"),
            choices: [
                fc_font_choice("tur", "silver", FC_FONT_SILVER),
                fc_font_choice("tur", "ibm_plex", FC_FONT_IBM_PLEX),
                fc_font_choice("tur", "play", FC_FONT_PLAY),
                fc_font_choice("tur", "marmelad", FC_FONT_MARMELAD),
                fc_font_choice("tur", "monomakh", FC_FONT_MONOMAKH),
                fc_font_choice("tur", "playpen_sans", FC_FONT_PLAYPEN_SANS),
            ],
        },
    ];
    return _registry;
}

function fc_language_profile(_language) {
    var _registry = fc_profile_registry();
    for (var _i = 0; _i < array_length(_registry); _i++) {
        if (_registry[_i].code == _language) return _registry[_i];
    }
    return undefined;
}

function fc_choice_profile(_language, _index) {
    var _profile = fc_language_profile(_language);
    if (_profile == undefined || _index < 0 || _index >= array_length(_profile.choices)) return undefined;
    return _profile.choices[_index];
}

function fc_choice_count(_language) {
    var _profile = fc_language_profile(_language);
    return _profile == undefined ? 0 : array_length(_profile.choices);
}

function fc_choice_id(_language, _index) {
    var _choice = fc_choice_profile(_language, _index);
    return _choice == undefined ? undefined : _choice.id;
}

function fc_choice_label(_language, _index) {
    var _choice = fc_choice_profile(_language, _index);
    return _choice == undefined ? "" : _choice.label;
}

function fc_choice_label_by_id(_language, _choice_id) {
    for (var _i = 0; _i < fc_choice_count(_language); _i++) {
        if (fc_choice_id(_language, _i) == _choice_id) return fc_choice_label(_language, _i);
    }
    return fc_ui_label(_language, "font_game_default");
}

function fc_choice_asset(_language, _choice_id) {
    for (var _i = 0; _i < fc_choice_count(_language); _i++) {
        var _choice = fc_choice_profile(_language, _i);
        if (_choice.id == _choice_id) return _choice.asset;
    }
    return undefined;
}

function fc_default_choice(_language) {
    var _profile = fc_language_profile(_language);
    return _profile == undefined ? undefined : _profile.default_choice;
}

function fc_choice_is_valid(_language, _choice) {
    return fc_choice_asset(_language, _choice) != undefined;
}

function fc_lab_language_matches(_family, _language) {
    for (var _i = 0; _i < array_length(_family.languages); _i++) {
        if (_family.languages[_i] == _language) return true;
    }
    return false;
}

function fc_lab_variant_language_matches(_family, _variant, _language) {
    if (_variant == undefined) return false;
    for (var _i = 0; _i < array_length(_variant.languages); _i++) {
        if (_variant.languages[_i] == _language) return true;
    }
    return false;
}

function fc_lab_variant_supports_target(_variant, _target) {
    if (_variant == undefined || _variant.targets == undefined) return true;
    for (var _i = 0; _i < array_length(_variant.targets); _i++) {
        if (_variant.targets[_i] == _target) return true;
    }
    return false;
}

function fc_lab_option_count(_language) {
    return fc_lab_option_count_for_target(_language, "all");
}

function fc_lab_option_count_for_target(_language, _target) {
    var _count = 0;
    var _families = fc_lab_registry();
    for (var _i = 0; _i < array_length(_families); _i++) {
        for (var _j = 0; _j < array_length(_families[_i].variants); _j++) {
            if (fc_lab_variant_language_matches(_families[_i], _families[_i].variants[_j], _language) && fc_lab_variant_supports_target(_families[_i].variants[_j], _target)) _count++;
        }
    }
    return _count;
}

function fc_lab_option_at(_language, _index) {
    return fc_lab_option_at_for_target(_language, _index, "all");
}

function fc_lab_option_at_for_target(_language, _index, _target) {
    var _cursor = 0;
    var _families = fc_lab_registry();
    for (var _i = 0; _i < array_length(_families); _i++) {
        var _family = _families[_i];
        for (var _j = 0; _j < array_length(_family.variants); _j++) {
            if (!fc_lab_variant_language_matches(_family, _family.variants[_j], _language) || !fc_lab_variant_supports_target(_family.variants[_j], _target)) continue;
            if (_cursor == _index) return { family: _family, variant: _family.variants[_j] };
            _cursor++;
        }
    }
    return undefined;
}

function fc_lab_variant(_language, _family_id, _variant_id) {
    var _families = fc_lab_registry();
    for (var _i = 0; _i < array_length(_families); _i++) {
        var _family = _families[_i];
        if (_family.id != _family_id) continue;
        for (var _j = 0; _j < array_length(_family.variants); _j++) {
            var _variant = _family.variants[_j];
            if (_variant.id == _variant_id && fc_lab_variant_language_matches(_family, _variant, _language)) return _variant;
        }
    }
    return undefined;
}

function fc_lab_family_label(_family_id) {
    var _families = fc_lab_registry();
    for (var _i = 0; _i < array_length(_families); _i++) {
        if (_families[_i].id == _family_id) return _families[_i].label;
    }
    return _family_id;
}

function fc_lab_selection_is_valid(_language, _selection) {
    if (!is_struct(_selection)) return false;
    return fc_lab_variant(_language, _selection[$ "family"], _selection[$ "variant"]) != undefined;
}

function fc_lab_targets() { return ["all", "standard", "popup_description", "textbox"]; }

function fc_lab_target_label(_language, _target) {
    if (_target == "all") return fc_ui_label(_language, "lab_target_all");
    if (_target == "standard") return fc_ui_label(_language, "lab_target_standard");
    if (_target == "popup_description") return fc_ui_label(_language, "lab_target_popup_description");
    if (_target == "textbox") return fc_ui_label(_language, "lab_target_textbox");
    return "";
}

function fc_ui_label(_language, _key) {
    var _labels = fc_ui_catalog(_language);
    return _labels[$ _key] == undefined ? "" : _labels[$ _key];
}

function fc_capture_original_styles(_language) {
    var _rt = fc_runtime();
    if (_rt.original_styles[$ _language] != undefined || TEXT_STYLES == undefined) return;
    _rt.original_styles[$ _language] = {
        standard: TEXT_STYLES.standard[$ _language],
        popup_description: TEXT_STYLES.popup_description[$ _language],
        textbox: TEXT_STYLES.textbox[$ _language],
    };
}

function fc_restore_original_styles(_language, _refresh_ui) {
    var _rt = fc_runtime();
    var _original = _rt.original_styles[$ _language];
    if (!is_struct(_original) || TEXT_STYLES == undefined) return false;
    TEXT_STYLES.standard[$ _language] = _original.standard;
    TEXT_STYLES.popup_description[$ _language] = _original.popup_description;
    TEXT_STYLES.textbox[$ _language] = _original.textbox;
    if (_refresh_ui) ANCHOR.language_refresh();
    return true;
}

function fc_apply_runtime(_language, _choice, _refresh_ui) {
    if (TEXT_STYLES == undefined) return false;
    fc_capture_original_styles(_language);
    var _font_name = fc_choice_asset(_language, _choice);
    if (_font_name == undefined) return false;
    var _font = try_string_to_asset(_font_name);
    if (_font == undefined) {
        mmapi_log_warn(FC_ID, "Font asset not found: " + _font_name);
        mmapi_log_flush(FC_ID);
        return false;
    }
    TEXT_STYLES.standard[$ _language] = _font;
    TEXT_STYLES.popup_description[$ _language] = _font;
    TEXT_STYLES.textbox[$ _language] = _font;
    fc_log_once("applied_" + _language, "Applied " + _language + "=" + _choice + " (asset " + string(_font) + ", refresh=" + string(_refresh_ui) + ")");
    if (_refresh_ui) {
        try {
            ANCHOR.language_refresh();
        } catch (_error) {
            mmapi_log_warn(FC_ID, "Could not refresh the active font: " + string(_error));
            mmapi_log_flush(FC_ID);
        }
    }
    return true;
}

function fc_apply_lab_runtime(_language, _family_id, _variant_id, _target, _refresh_ui) {
    if (TEXT_STYLES == undefined) return false;
    fc_capture_original_styles(_language);
    var _variant = fc_lab_variant(_language, _family_id, _variant_id);
    if (!fc_lab_variant_supports_target(_variant, _target)) return false;
    var _font = try_string_to_asset(_variant.asset);
    if (_font == undefined) {
        mmapi_log_warn(FC_ID, "Font Lab asset not found: " + _variant.asset);
        mmapi_log_flush(FC_ID);
        return false;
    }
    if (_target == "all") {
        TEXT_STYLES.standard[$ _language] = _font;
        TEXT_STYLES.popup_description[$ _language] = _font;
        TEXT_STYLES.textbox[$ _language] = _font;
    } else {
        TEXT_STYLES[$ _target][$ _language] = _font;
    }
    fc_log_once("lab_" + _language + "_" + _family_id + "_" + _variant_id + "_" + _target, "Font Lab applied " + _language + "=" + _family_id + "/" + _variant_id + " to " + _target);
    if (_refresh_ui) {
        try {
            ANCHOR.language_refresh();
        } catch (_error) {
            mmapi_log_warn(FC_ID, "Could not refresh the Font Lab preview: " + string(_error));
            mmapi_log_flush(FC_ID);
        }
    }
    return true;
}

function fc_apply_saved_lab_selection(_language, _selection, _refresh_ui) {
    if (!is_struct(_selection)) return false;
    // Migrate the first Lab build's { family, variant } shape in memory.
    if (fc_lab_selection_is_valid(_language, _selection) && fc_lab_variant_supports_target(fc_lab_variant(_language, _selection[$ "family"], _selection[$ "variant"]), "all")) {
        return fc_apply_lab_runtime(_language, _selection[$ "family"], _selection[$ "variant"], "all", _refresh_ui);
    }
    var _applied = false;
    var _all = _selection[$ "all"];
    if (fc_lab_selection_is_valid(_language, _all) && fc_lab_variant_supports_target(fc_lab_variant(_language, _all[$ "family"], _all[$ "variant"]), "all")) {
        _applied = fc_apply_lab_runtime(_language, _all[$ "family"], _all[$ "variant"], "all", false);
    }
    var _roles = ["standard", "popup_description", "textbox"];
    for (var _i = 0; _i < array_length(_roles); _i++) {
        var _role = _roles[_i];
        var _role_selection = _selection[$ _role];
        if (fc_lab_selection_is_valid(_language, _role_selection) && fc_lab_variant_supports_target(fc_lab_variant(_language, _role_selection[$ "family"], _role_selection[$ "variant"]), _role)) {
            _applied = fc_apply_lab_runtime(_language, _role_selection[$ "family"], _role_selection[$ "variant"], _role, false) || _applied;
        }
    }
    if (_applied && _refresh_ui) ANCHOR.language_refresh();
    return _applied;
}

function fc_lab_has_saved_selection(_selection) {
    if (!is_struct(_selection)) return false;
    if (is_struct(_selection[$ "all"])) return true;
    if (is_struct(_selection[$ "standard"])) return true;
    if (is_struct(_selection[$ "popup_description"])) return true;
    if (is_struct(_selection[$ "textbox"])) return true;
    // Compatibility with the original { family, variant } shape.
    return _selection[$ "family"] != undefined || _selection[$ "variant"] != undefined;
}

function fc_forget_unavailable_lab_selection(_language) {
    var _rt = fc_runtime();
    _rt.config.lab_selected[$ _language] = {};
    try {
        SETTINGS.set(FC_LAB_SETTINGS_KEY, _rt.config.lab_selected);
        save_settings();
        mmapi_log_warn(FC_ID, "Unavailable experimental font was reset for " + _language + ".");
        mmapi_log_flush(FC_ID);
    } catch (_error) {
        mmapi_log_warn(FC_ID, "Could not reset unavailable experimental font: " + string(_error));
        mmapi_log_flush(FC_ID);
    }
}

function fc_apply_active_configured_font(_refresh_ui) {
    var _rt = fc_runtime();
    if (_rt.config == undefined || !is_struct(_rt.config.selected)) return false;

    var _language = local_language();
    var _lab_selection = _rt.config.lab_selected[$ _language];
    if (fc_apply_saved_lab_selection(_language, _lab_selection, _refresh_ui)) return true;
    if (fc_lab_has_saved_selection(_lab_selection)) fc_forget_unavailable_lab_selection(_language);
    var _choice = _rt.config.selected[$ _language];
    if (!fc_choice_is_valid(_language, _choice)) {
        fc_restore_original_styles(_language, _refresh_ui);
        return false;
    }
    if (fc_apply_runtime(_language, _choice, _refresh_ui)) return true;
    // A deleted or renamed normal asset must never leave a stale override in
    // memory. Restore the captured game font for a safe next launch.
    fc_restore_original_styles(_language, _refresh_ui);
    return false;
}

function fc_configure() {
    var _rt = fc_runtime();
    if (_rt.config != undefined) return _rt.config;

    // SETTINGS is loaded before TitleMenu. Its settings.json preserves unknown
    // keys, making this an independent boot-time config for this mod.
    if (SETTINGS == undefined) return undefined;
    var _selected = SETTINGS.get(FC_SETTINGS_KEY);
    if (!is_struct(_selected)) _selected = {};
    var _lab_selected = SETTINGS.get(FC_LAB_SETTINGS_KEY);
    if (!is_struct(_lab_selected)) _lab_selected = {};
    var _profiles = fc_profile_registry();
    for (var i = 0; i < array_length(_profiles); i++) {
        var _language = _profiles[i].code;
        var _choice = _selected[$ _language];
        var _pending = _rt.pending_choices[$ _language];
        if (_pending != undefined) _choice = _pending;
        if (!fc_choice_is_valid(_language, _choice)) _choice = fc_default_choice(_language);
        _selected[$ _language] = _choice;
    }
    _rt.config = { selected: _selected, lab_selected: _lab_selected };
    _rt.pending_choices = {};
    fc_log_once("config_loaded", "Loaded saved font choices for " + string(array_length(_profiles)) + " tested language profiles.");
    return _rt.config;
}

function fc_apply_choice(_language, _choice) {
    if (!fc_choice_is_valid(_language, _choice)) return;
    var _rt = fc_runtime();
    if (_rt.config == undefined) fc_configure();
    if (_rt.config == undefined) {
        _rt.pending_choices[$ _language] = _choice;
        fc_apply_runtime(_language, _choice, true);
        return;
    }
    _rt.config.selected[$ _language] = _choice;
    // Selecting a normal font intentionally leaves the Lab mode.
    _rt.config.lab_selected[$ _language] = {};
    try {
        SETTINGS.set(FC_SETTINGS_KEY, _rt.config.selected);
        SETTINGS.set(FC_LAB_SETTINGS_KEY, _rt.config.lab_selected);
        save_settings();
    } catch (_error) {
        mmapi_log_warn(FC_ID, "Could not save selected font to game settings: " + string(_error));
        mmapi_log_flush(FC_ID);
        return;
    }
    _rt.startup_fonts_applied = true;
    fc_apply_runtime(_language, _choice, true);
    fc_refresh_panel_value_labels();
}

function fc_apply_lab_choice(_language, _family_id, _variant_id) {
    var _variant = fc_lab_variant(_language, _family_id, _variant_id);
    if (_variant == undefined) return;
    var _rt = fc_runtime();
    if (!fc_lab_variant_supports_target(_variant, _rt.lab_target)) return;
    if (_rt.config == undefined) fc_configure();
    if (_rt.config == undefined) return;
    var _target = _rt.lab_target;
    var _selection = _rt.config.lab_selected[$ _language];
    if (!is_struct(_selection)) _selection = {};
    if (_target == "all") {
        _selection = { all: { family: _family_id, variant: _variant_id } };
    } else {
        _selection[$ _target] = { family: _family_id, variant: _variant_id };
    }
    _rt.config.lab_selected[$ _language] = _selection;
    try {
        SETTINGS.set(FC_LAB_SETTINGS_KEY, _rt.config.lab_selected);
        save_settings();
    } catch (_error) {
        mmapi_log_warn(FC_ID, "Could not save Font Lab selection: " + string(_error));
        mmapi_log_flush(FC_ID);
        return;
    }
    _rt.startup_fonts_applied = true;
    fc_apply_saved_lab_selection(_language, _selection, true);
    fc_refresh_panel_value_labels();
}

function fc_clear_lab_choice(_language) {
    var _rt = fc_runtime();
    if (_rt.config == undefined) fc_configure();
    if (_rt.config == undefined) return;
    _rt.config.lab_selected[$ _language] = {};
    try {
        SETTINGS.set(FC_LAB_SETTINGS_KEY, _rt.config.lab_selected);
        save_settings();
    } catch (_error) {
        mmapi_log_warn(FC_ID, "Could not clear Font Lab selection: " + string(_error));
        mmapi_log_flush(FC_ID);
        return;
    }
    var _choice = _rt.config.selected[$ _language];
    if (fc_choice_is_valid(_language, _choice)) {
        fc_apply_runtime(_language, _choice, true);
    } else {
        fc_restore_original_styles(_language, true);
    }
    fc_refresh_panel_value_labels();
}

function fc_on_title_entered(_ctx) {
    var _rt = fc_runtime();
    _rt.startup_fonts_applied = false;
    fc_configure();
    if (fc_apply_active_configured_font(true)) {
        _rt.startup_fonts_applied = true;
        fc_log_once("startup_success", "Saved font applied from game settings on title screen.");
    }
}

function fc_picker_option_name(_index) { return fc_choice_label(local_language(), _index); }

function fc_apply_picker(_index) {
    var _language = local_language();
    fc_apply_choice(_language, fc_choice_id(_language, _index));
}

function fc_open_picker() {
    var _language = local_language();
    var _options = [];
    for (var i = 0; i < fc_choice_count(_language); i++) array_push(_options, i);
    if (array_length(_options) == 0) return;
    create_options_popup("misc_local/" + FC_POPUP_KEY, ListFromArray(_options), fc_picker_option_name, fc_apply_picker, undefined);
}

// The normal picker remains intentionally short. Metric experiments live behind
// a second, two-stage picker: family first, then one of that family's variants.
// This avoids one giant cyclic list where later families are practically hidden.
function fc_open_all_picker() { fc_open_picker(); }

function fc_lab_family_count(_language, _target) {
    var _count = 0;
    var _families = fc_lab_registry();
    for (var _i = 0; _i < array_length(_families); _i++) {
        var _family = _families[_i];
        for (var _j = 0; _j < array_length(_family.variants); _j++) {
            if (fc_lab_variant_language_matches(_family, _family.variants[_j], _language) && fc_lab_variant_supports_target(_family.variants[_j], _target)) {
                _count++;
                break;
            }
        }
    }
    return _count;
}

function fc_lab_family_at(_language, _target, _index) {
    var _seen = 0;
    var _families = fc_lab_registry();
    for (var _i = 0; _i < array_length(_families); _i++) {
        var _family = _families[_i];
        var _has_variant = false;
        for (var _j = 0; _j < array_length(_family.variants); _j++) {
            if (fc_lab_variant_language_matches(_family, _family.variants[_j], _language) && fc_lab_variant_supports_target(_family.variants[_j], _target)) {
                _has_variant = true;
                break;
            }
        }
        if (!_has_variant) continue;
        if (_seen == _index) return _family;
        _seen++;
    }
    return undefined;
}

function fc_lab_family_variant_count(_language, _family_id, _target) {
    var _families = fc_lab_registry();
    for (var _i = 0; _i < array_length(_families); _i++) {
        if (_families[_i].id != _family_id) continue;
        var _count = 0;
        for (var _j = 0; _j < array_length(_families[_i].variants); _j++) {
            if (fc_lab_variant_language_matches(_families[_i], _families[_i].variants[_j], _language) && fc_lab_variant_supports_target(_families[_i].variants[_j], _target)) _count++;
        }
        return _count;
    }
    return 0;
}

function fc_lab_family_variant_at(_language, _family_id, _target, _index) {
    var _families = fc_lab_registry();
    for (var _i = 0; _i < array_length(_families); _i++) {
        var _family = _families[_i];
        if (_family.id != _family_id) continue;
        var _seen = 0;
        for (var _j = 0; _j < array_length(_family.variants); _j++) {
            var _variant = _family.variants[_j];
            if (!fc_lab_variant_language_matches(_family, _variant, _language) || !fc_lab_variant_supports_target(_variant, _target)) continue;
            if (_seen == _index) return { family: _family, variant: _variant };
            _seen++;
        }
    }
    return undefined;
}

function fc_lab_picker_option_name(_index) {
    if (_index == -1) {
        var _rt = fc_runtime();
        return _rt.lab_target == "all" ? fc_ui_label(local_language(), "lab_reset") : fc_inherited_all_text_label(local_language());
    }
    var _rt = fc_runtime();
    var _option = fc_lab_family_variant_at(local_language(), _rt.lab_family, _rt.lab_target, _index);
    if (_option == undefined) return "";
    return fc_lab_picker_variant_label(local_language(), _option.variant);
}

function fc_apply_lab_picker(_index) {
    var _language = local_language();
    if (_index == -1) {
        var _rt = fc_runtime();
        if (_rt.lab_target == "all") {
            fc_clear_lab_choice(_language);
        } else {
            var _selection = _rt.config.lab_selected[$ _language];
            if (!is_struct(_selection)) _selection = {};
            _selection[$ _rt.lab_target] = undefined;
            _rt.config.lab_selected[$ _language] = _selection;
            SETTINGS.set(FC_LAB_SETTINGS_KEY, _rt.config.lab_selected);
            save_settings();
            fc_apply_active_configured_font(true);
        }
        return;
    }
    var _rt = fc_runtime();
    var _option = fc_lab_family_variant_at(_language, _rt.lab_family, _rt.lab_target, _index);
    if (_option == undefined) return;
    fc_apply_lab_choice(_language, _option.family.id, _option.variant.id);
}

function fc_open_lab_variant_picker() {
    var _language = local_language();
    var _rt = fc_runtime();
    var _options = [-1];
    for (var _i = 0; _i < fc_lab_family_variant_count(_language, _rt.lab_family, _rt.lab_target); _i++) array_push(_options, _i);
    if (array_length(_options) == 0) return;
    create_options_popup("misc_local/" + FC_LAB_POPUP_KEY, ListFromArray(_options), fc_lab_picker_option_name, fc_apply_lab_picker, undefined);
}

function fc_lab_family_picker_option_name(_index) {
    if (_index == -1) {
        var _rt = fc_runtime();
        return _rt.lab_target == "all" ? fc_ui_label(local_language(), "lab_reset") : fc_inherited_all_text_label(local_language());
    }
    var _rt = fc_runtime();
    var _family = fc_lab_family_at(local_language(), _rt.lab_target, _index);
    return _family == undefined ? "" : _family.label;
}

function fc_apply_lab_family_picker(_index) {
    var _language = local_language();
    var _rt = fc_runtime();
    if (_index == -1) {
        fc_apply_lab_picker(-1);
        return;
    }
    var _family = fc_lab_family_at(_language, _rt.lab_target, _index);
    if (_family == undefined) return;
    _rt.lab_family = _family.id;
    fc_open_lab_variant_picker();
}

function fc_open_lab_picker() {
    var _language = local_language();
    var _rt = fc_runtime();
    var _options = [-1];
    for (var _i = 0; _i < fc_lab_family_count(_language, _rt.lab_target); _i++) array_push(_options, _i);
    create_options_popup("misc_local/" + FC_LAB_POPUP_KEY, ListFromArray(_options), fc_lab_family_picker_option_name, fc_apply_lab_family_picker, undefined);
}

function fc_open_lab_picker_for_target(_target) {
    var _rt = fc_runtime();
    _rt.lab_target = _target;
    fc_open_lab_picker();
}

function fc_open_standard_picker() { fc_open_lab_picker_for_target("standard"); }
function fc_open_popup_description_picker() { fc_open_lab_picker_for_target("popup_description"); }
function fc_open_textbox_picker() { fc_open_lab_picker_for_target("textbox"); }
function fc_open_all_lab_picker() { fc_open_lab_picker_for_target("all"); }

// Experimental is deliberately global. Choosing a profile replaces all three
// text roles and clears individual Lab overrides through fc_apply_lab_choice().
function fc_open_experimental_picker() { fc_open_all_lab_picker(); }

function fc_lab_picker_variant_label(_language, _variant) {
    if (_variant == undefined) return "";
    var _rendering = _variant.allow_shading ? fc_ui_label(_language, "variant_shaded") : fc_ui_label(_language, "variant_flat");
    return string(_variant.size) + "x" + string(_variant.line_height) + " " + _rendering;
}

function fc_lab_short_variant_label(_variant) {
    return fc_lab_metric_label(_variant);
}

function fc_lab_metric_label(_variant) {
    if (_variant == undefined) return "";
    return string(_variant.size) + (_variant.allow_shading ? "S" : "F");
}

function fc_lab_short_family_label(_family_id) {
    if (_family_id == "ibm_plex") return "IBM";
    if (_family_id == "sofia_condensed") return "Sofia C";
    if (_family_id == "sofia_extra_condensed") return "Sofia X";
    return fc_lab_family_label(_family_id);
}

function fc_experimental_display_label(_language) {
    var _rt = fc_runtime();
    if (_rt.config == undefined) fc_configure();
    if (_rt.config == undefined) return "";
    var _selection = _rt.config.lab_selected[$ _language];
    if (is_struct(_selection)) {
        var _all = _selection[$ "all"];
        if (fc_lab_selection_is_valid(_language, _all)) {
            var _variant = fc_lab_variant(_language, _all[$ "family"], _all[$ "variant"]);
            if (fc_lab_variant_supports_target(_variant, "all")) return fc_lab_short_family_label(_all[$ "family"]) + " / " + fc_lab_metric_label(_variant);
        }
    }
    return fc_choice_label_by_id(_language, _rt.config.selected[$ _language]);
}

function fc_inherited_all_text_label(_language) {
    return fc_ui_label(_language, "all_text") + ": " + fc_experimental_display_label(_language);
}

function fc_lab_display_label(_language, _target) {
    var _rt = fc_runtime();
    if (_rt.config == undefined) fc_configure();
    if (_rt.config == undefined) return "";
    var _selection = _rt.config.lab_selected[$ _language];
    if (is_struct(_selection)) {
        var _entry = _target == "all" ? _selection[$ "all"] : _selection[$ _target];
        if (fc_lab_selection_is_valid(_language, _entry) && fc_lab_variant_supports_target(fc_lab_variant(_language, _entry[$ "family"], _entry[$ "variant"]), _target)) {
            var _variant = fc_lab_variant(_language, _entry[$ "family"], _entry[$ "variant"]);
            // The Settings button is a status cue, not a technical
            // description. Keep it short so it remains legible with the
            // very font it is configuring.
            return fc_lab_short_variant_label(_variant);
        }
    }
    if (_target != "all") return fc_inherited_all_text_label(_language);
    return fc_choice_label_by_id(_language, _rt.config.selected[$ _language]);
}

function fc_refresh_panel_value_labels() {
    var _rt = fc_runtime();
    var _language = local_language();
    if (is_struct(_rt.panel_value_labels)) {
        var _targets = fc_lab_targets();
        for (var _i = 0; _i < array_length(_targets); _i++) {
            var _target = _targets[_i];
            var _label = _rt.panel_value_labels[$ _target];
            // set_text accepts the plain display text. Wrapping it as a local key
            // registers a fresh `extra_local_*` entry on every click.
            if (_label != undefined) _label.set_text(fc_lab_display_label(_language, _target));
        }
    }
    if (_rt.experimental_value_label != undefined) _rt.experimental_value_label.set_text(fc_experimental_display_label(_language));
}

function fc_lab_target_option_name(_index) {
    var _targets = fc_lab_targets();
    if (_index < 0 || _index >= array_length(_targets)) return "";
    return fc_lab_target_label(local_language(), _targets[_index]);
}

function fc_apply_lab_target(_index) {
    var _targets = fc_lab_targets();
    if (_index < 0 || _index >= array_length(_targets)) return;
    var _rt = fc_runtime();
    _rt.lab_target = _targets[_index];
}

function fc_open_lab_target_picker() {
    var _targets = fc_lab_targets();
    var _options = [];
    for (var _i = 0; _i < array_length(_targets); _i++) array_push(_options, _i);
    create_options_popup("misc_local/" + FC_LAB_TARGET_POPUP_KEY, ListFromArray(_options), fc_lab_target_option_name, fc_apply_lab_target, undefined);
}

function fc_local_missing(_value, _ctx) {
    if (!is_struct(_ctx)) return undefined;
    var _key = string(_ctx[$ "key"]);
    var _language = local_language();
    if (_key == "misc_local/" + FC_CATEGORY) return fc_ui_label(_language, "category");
    if (_key == "misc_local/" + FC_SELECT_KEY) return fc_ui_label(_language, "select");
    if (_key == "misc_local/" + FC_POPUP_KEY) return fc_ui_label(_language, "popup");
    if (_key == "misc_local/" + FC_ALL_TEXT_KEY) return fc_ui_label(_language, "all_text");
    if (_key == "misc_local/" + FC_STANDARD_KEY) return fc_ui_label(_language, "standard");
    if (_key == "misc_local/" + FC_POPUP_DESCRIPTION_KEY) return fc_ui_label(_language, "popup_description");
    if (_key == "misc_local/" + FC_TEXTBOX_KEY) return fc_ui_label(_language, "textbox");
    if (_key == "misc_local/" + FC_LAB_CATEGORY) return fc_ui_label(_language, "lab_category");
    if (_key == "misc_local/" + FC_LAB_SELECT_KEY) return fc_ui_label(_language, "lab_button");
    if (_key == "misc_local/" + FC_LAB_ALL_KEY) return fc_ui_label(_language, "lab_all");
    if (_key == "misc_local/" + FC_LAB_POPUP_KEY) return fc_ui_label(_language, "lab_popup");
    if (_key == "misc_local/" + FC_LAB_TARGET_KEY) return fc_ui_label(_language, "lab_target");
    if (_key == "misc_local/" + FC_LAB_TARGET_POPUP_KEY) return fc_ui_label(_language, "lab_target_popup");
    if (_key == "misc_local/" + FC_EXPERIMENTAL_KEY) return fc_ui_label(_language, "experimental_select");
    return undefined;
}

function fc_build_panel() {
    var _rt = fc_runtime();
    fc_configure();
    if (_rt.settings_menu == undefined) return;
    var _language = local_language();
    if (fc_choice_count(_language) == 0 && fc_lab_option_count(_language) == 0) {
        _rt.settings_menu.element(
            ANCHOR.wrap_for_local("This language is not supported yet."),
            33,
            false
        );
        return;
    }
    var _all = _rt.settings_menu.button(FC_ALL_TEXT_KEY);
    _all.set_size(130, 21);
    _all
        .add_text_label(ANCHOR.wrap_for_local(fc_lab_display_label(_language, "all")), COMMON_LUT, CommonLutIndex.Dark)
        .set_tap_callback(fc_open_all_picker);

    var _experimental = _rt.settings_menu.button(FC_EXPERIMENTAL_KEY);
    _experimental.set_size(130, 21);
    _experimental
        .add_text_label(ANCHOR.wrap_for_local(fc_experimental_display_label(_language)), COMMON_LUT, CommonLutIndex.Dark)
        .set_tap_callback(fc_open_experimental_picker);

    var _standard = _rt.settings_menu.button(FC_STANDARD_KEY);
    _standard.set_size(130, 21);
    _standard
        .add_text_label(ANCHOR.wrap_for_local(fc_lab_display_label(_language, "standard")), COMMON_LUT, CommonLutIndex.Dark)
        .set_tap_callback(fc_open_standard_picker);

    var _popup = _rt.settings_menu.button(FC_POPUP_DESCRIPTION_KEY);
    _popup.set_size(130, 21);
    _popup
        .add_text_label(ANCHOR.wrap_for_local(fc_lab_display_label(_language, "popup_description")), COMMON_LUT, CommonLutIndex.Dark)
        .set_tap_callback(fc_open_popup_description_picker);

    var _textbox = _rt.settings_menu.button(FC_TEXTBOX_KEY);
    _textbox.set_size(130, 21);
    _textbox
        .add_text_label(ANCHOR.wrap_for_local(fc_lab_display_label(_language, "textbox")), COMMON_LUT, CommonLutIndex.Dark)
        .set_tap_callback(fc_open_textbox_picker);

    _rt.panel_value_labels = {
        all: _all.text_label,
        standard: _standard.text_label,
        popup_description: _popup.text_label,
        textbox: _textbox.text_label,
    };
    _rt.experimental_value_label = _experimental.text_label;
}

function fc_on_menu_opened(_ctx) {
    if (!is_struct(_ctx)) return;
    if (_ctx[$ "kind"] != Menu.Settings) return;
    if (fc_choice_count(local_language()) == 0 && fc_lab_option_count(local_language()) == 0) return;
    var _menu = _ctx[$ "menu"];
    if (_menu == undefined || _menu[$ "categories"] == undefined) return;
    var _rt = fc_runtime();
    _rt.settings_menu = _menu;
    try {
        if (_menu.categories[$ FC_CATEGORY] == undefined) {
            _menu.create_category(FC_CATEGORY, fc_build_panel, spr_ui_journal_settings_icon_gameplay);
        }
    } catch (_error) {
        mmapi_log_warn(FC_ID, "Could not add Font Choices settings: " + string(_error));
        mmapi_log_flush(FC_ID);
    }
}

function fc_register() {
    var _rt = fc_runtime();
    if (_rt.registered) return;
    _rt.registered = true;
    mmapi_on("ui.menu_opened", fc_on_menu_opened);
    mmapi_on("game.title_entered", fc_on_title_entered);
    mmapi_filter("local.missing", fc_local_missing);
}

mmapi_mod_declare(FC_ID, "0.1.0");
fc_register();
