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
    if (_menu == undefined) return;

    if (_menu[$ "type"] == Menu.Player) {
        var _level_text = format(
            "{Local} {}",
            "misc_local/renown_lvl_insert",
            renown_to_level(ARI.renown)
        );

        try {
            bulgarian_lvl_find_and_replace(_menu.journal.left_body, _level_text);
        } catch (_e) {
            mmapi_warn_rate_limited(
                "bulgarian_lvl.player_menu",
                "bulgarian_localization",
                "Could not update the Player menu level label: " + string(_e)
            );
        }
        return;
    }

    if (_menu[$ "type"] == Menu.Crafting && _menu.book != undefined) {
        try {
            _menu.book.set_think_callback(function(_crafting_menu) {
                // ui.menu_opened fires before CraftingMenu.initialize(). Wait until
                // initialize has set the context, then apply this once and detach.
                if (_crafting_menu.context == undefined) return;

                if (_crafting_menu.context == RecipeContext.Cooking) {
                    _crafting_menu.book.set_sprite(spr_ui_cooking_backplate_bul);
                }
                _crafting_menu.book.event_callbacks.think = undefined;
            }, [_menu]);
        } catch (_e) {
            mmapi_warn_rate_limited(
                "bulgarian_lvl.cooking_backplate",
                "bulgarian_localization",
                "Could not update the Cooking menu baked level label: " + string(_e)
            );
        }
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
