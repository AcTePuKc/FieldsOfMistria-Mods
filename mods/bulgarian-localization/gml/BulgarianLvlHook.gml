function bulgarian_lvl_runtime() {
    if (global[$ "__bulgarian_lvl_hook"] == undefined) {
        global.__bulgarian_lvl_hook = { registered: false };
    }
    return global.__bulgarian_lvl_hook;
}

function bulgarian_lvl_register() {
    var _runtime = bulgarian_lvl_runtime();
    if (_runtime.registered) return;
    _runtime.registered = true;

    mmapi_on("ui.menu_opened", bulgarian_lvl_menu_opened);
}

function bulgarian_lvl_menu_opened(_ctx) {
    var _menu = _ctx.menu;
    if (_menu == undefined || _menu[$ "type"] != Menu.Player) return;

    var _level_text = format(
        "{Local} {}",
        "misc_local/renown_lvl_insert",
        renown_to_level(ARI.renown)
    );

    try {
        bulgarian_lvl_find_and_replace(_menu.journal.left_body, _level_text);
    } catch (_e) {
        mmapi_warn_rate_limited(
            "bulgarian_lvl.menu_opened",
            "bulgarian_localization",
            "Could not update the Player menu level label: " + string(_e)
        );
    }
}

function bulgarian_lvl_find_and_replace(_node, _replacement) {
    if (_node == undefined || _node.freed) return;

    try {
        var _text = _node.get_text();
        if (_text != undefined && string_copy(string(_text), 1, 3) == "Lvl") {
            _node.set_text(_replacement);
            return;
        }
    } catch (_e) {
        // Non-text nodes do not expose get_text; continue through their children.
    }

    try {
        var _children = _node.children;
        if (_children == undefined) return;

        for (var i = 0; i < array_length(_children); i++) {
            bulgarian_lvl_find_and_replace(_children[i], _replacement);
        }
    } catch (_e) {
        // A menu can be freed while it is closing; ignore that transient state.
    }
}

mmapi_mod_declare("bulgarian_localization_lvl_hook", "0.0.1");
bulgarian_lvl_register();
