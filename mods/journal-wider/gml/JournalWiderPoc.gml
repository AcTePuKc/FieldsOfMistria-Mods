#macro JP_ID "wide_journal_act"
#macro JP_EXTRA_PAGE_WIDTH 50
#macro JP_BOOK_WIDTH 410
#macro JP_PAGE_WIDTH 189
#macro JP_JOURNAL_BODY_WIDTH 176
#macro JP_RELATIONSHIPS_INSET 14
#macro JP_MISSING_RELATIONSHIP_DROP 2
#macro JP_WRAPPED_JOB_ROW_BREATHING 3
#macro JP_GIFT_COLUMNS 8
#macro JP_GIFT_SLOT_STEP 17
#macro JP_GIFT_SLOT_SIZE 18
#macro JP_GIFT_LOVED_ROWS 2
#macro JP_GIFT_LIKED_ROWS 3
#macro JP_GIFT_LOVED_ZONE_Y 16
#macro JP_GIFT_LIKED_LABEL_Y 52
#macro JP_GIFT_LIKED_ZONE_Y 66
#macro JP_TOWN_RANK_POPUP_WIDTH 272
#macro JP_TOWN_RANK_POPUP_HEIGHT 236
#macro JP_TOWN_RANK_GRID_CENTER_SHIFT 11
#macro JP_TOWN_RANK_LOCK_COLUMN_X 172
#macro JP_SKILL_POPUP_WIDTH 246
#macro JP_SKILL_POPUP_HEIGHT 237
#macro JP_SKILL_SUBPLATE_WIDTH 180
#macro JP_SKILL_BAR_SHIFT 30

function jp_apply_wider_journal(_journal) {
    if (_journal == undefined || _journal[$ "book"] == undefined) return;

    // Switching a Journal tab calls JournalMenu.reset(), which frees every
    // canvas child and creates a new book. Use the live book identity rather
    // than a one-time boolean so each rebuilt Journal gets patched once.
    if (_journal[$ "__journal_wider_poc_book"] == _journal.book) return;
    _journal.__journal_wider_poc_book = _journal.book;

    // The vanilla Journal has fixed 410x234 book art and 189px page art.
    // This isolated POC widens only this menu's visual backgrounds and the
    // geometry used by its content panels. It deliberately leaves height,
    // tabs, fonts, and every other menu untouched.
    var _new_page_width = JP_PAGE_WIDTH + JP_EXTRA_PAGE_WIDTH;
    var _new_book_width = JP_BOOK_WIDTH + (JP_EXTRA_PAGE_WIDTH * 2);

    _journal.book
        .set_scale_x(_new_book_width / JP_BOOK_WIDTH)
        .set_width(_new_book_width);

    _journal.left_page
        .set_scale_x(_new_page_width / JP_PAGE_WIDTH)
        .set_width(_new_page_width);
    _journal.right_page
        .set_scale_x(_new_page_width / JP_PAGE_WIDTH)
        .set_width(_new_page_width);

    _journal.left_header.set_width(_new_page_width);
    _journal.right_header.set_width(_new_page_width);
    _journal.left_body.set_width(_new_page_width);
    _journal.right_body.set_width(_new_page_width);
    _journal.right_full_body.set_width(_new_page_width);

    // Deliberately conspicuous sentinel: proves which screen the hook reaches.
    // Remove this before any non-diagnostic layout test.
    ANCHOR.text(_journal.canvas, 10000)
        .set_text("JOURNAL POC +50")
        .set_align(Align.Center, Align.TopIn)
        .set_y(2)
        .set_lut(COMMON_LUT, CommonLutIndex.WhiteOnGreen)
        .force_font(fnt_mistria_birdseed);

    mmapi_log_info(JP_ID, "Applied Journal width POC: +" + string(JP_EXTRA_PAGE_WIDTH) + "px per page.");
    mmapi_log_flush(JP_ID);
}

function jp_align_left_title_icon(_menu) {
    if (_menu == undefined || _menu[$ "__journal_wider_poc_left_title_icon_aligned"] == true) return;

    // Journal menus do not consistently name their left title: most use
    // `title`, while Settings/QuestLog use `left_title`. They all come from
    // title_for_journal(), whose separately stored icon starts one pixel left
    // of the category-row icon column after the page is widened.
    var _title = undefined;
    if (_menu[$ "left_title"] != undefined) _title = _menu.left_title;
    else if (_menu[$ "title"] != undefined) _title = _menu.title;
    if (_title == undefined) return;

    var _icon = _title.board_get("icon");
    if (_icon == undefined) return;
    _icon.add_x(1);
    _menu.__journal_wider_poc_left_title_icon_aligned = true;
}

function jp_nudge_left_title_icon(_menu, _amount) {
    if (_menu == undefined || _amount == 0) return;
    if (_menu[$ "__journal_wider_poc_left_title_icon_nudged"] == true) return;

    var _title = undefined;
    if (_menu[$ "left_title"] != undefined) _title = _menu.left_title;
    else if (_menu[$ "title"] != undefined) _title = _menu.title;
    if (_title == undefined) return;

    var _icon = _title.board_get("icon");
    if (_icon == undefined) return;
    _icon.add_x(_amount);
    _menu.__journal_wider_poc_left_title_icon_nudged = true;
}

function jp_reflow_relationships(_relationships, _journal) {
    if (_relationships == undefined || _relationships[$ "field_zone"] == undefined) return;
    if (_relationships[$ "__journal_wider_poc_field_width"] == _journal.right_full_body.get_width()) return;

    // Relationships creates its bottom information area at vanilla width and
    // caps every label at 156px. After the outer book becomes wider, use that
    // new page width for these text fields only. Portrait and gift grids remain
    // fixed-size artwork and deliberately keep their vanilla geometry.
    var _width = _journal.right_full_body.get_width();
    var _content_width = _width - JP_RELATIONSHIPS_INSET;
    var _text_width = _content_width - 13; // Preserve vanilla's icon + gap + padding.
    _relationships.field_zone
        .set_align(Align.LeftIn, Align.BottomIn)
        .set_x(JP_RELATIONSHIPS_INSET)
        .set_size(_content_width, 90);
    _relationships.npc_field.text.set_max_width(_text_width);
    _relationships.birthday_field.text.set_max_width(_text_width);
    _relationships.job_field.text.set_max_width(_text_width);
    _relationships.relationship_field.text.set_max_width(_text_width);
    _relationships.__journal_wider_poc_field_width = _width;

    // Anchor the block's final row to the same physical bottom position as
    // vanilla. A longer job title then consumes only the blank room *above*
    // it. NPCs who are not dateable have their partner icon disabled by the
    // vanilla menu, leaving only three visible rows; drop that compact stack
    // by two pixels so its job line has the same breathing room as a full
    // four-row card. This uses rendered text height, so it adapts to every
    // selected font without Font Choices knowing about this menu.
    _relationships.field_zone.set_think_callback(function(_relationships) {
        var _job_height = max(11, _relationships.job_field.text.get_height());
        var _has_relationship = _relationships.relationship_field.icon.get_enabled();
        // TextNode.lines() counts actual line breaks after reflow. Do not infer
        // it from pixel height: a taller selected font can make one line more
        // than 11px high and previously got mistaken for a wrapped job.
        var _job_lines = _relationships.job_field.text.lines();
        var _extra_job_lines = max(0, _job_lines - 1);
        var _job_line_height = ceil(_job_height / _job_lines);
        var _font_row_breathing = max(0, _job_line_height - 11);
        var _row_breathing = _font_row_breathing
            + (_extra_job_lines * JP_WRAPPED_JOB_ROW_BREATHING);
        var _relationship_y = 76;
        var _job_y = _has_relationship
            // A visible partner-status row needs the job's complete physical
            // height cleared above it.
            ? _relationship_y - 14 - max(0, _job_height - 11)
            // When vanilla disables that row there is no lower collision to
            // reserve space for, so retain the pleasant compact three-row
            // layout even with a tall font or a multi-line job title.
            : _relationship_y - 14 + JP_MISSING_RELATIONSHIP_DROP;
        // A wrapped job has a larger physical glyph footprint than the
        // vanilla 14px row pitch. Keep the job and bottom status pinned, but
        // take three pixels of the empty room beneath the portrait per extra
        // job line. One-line jobs retain exact vanilla-style spacing.
        var _birthday_y = _job_y - 14 - _row_breathing;
        var _npc_y = _birthday_y - 14 - _row_breathing;

        _relationships.npc_field.icon.set_y(_npc_y);
        _relationships.birthday_field.icon.set_y(_birthday_y);
        _relationships.job_field.icon.set_y(_job_y);
        _relationships.relationship_field.icon.set_y(_relationship_y);
    }, [_relationships]);

    mmapi_log_info(JP_ID, "Reflowed Relationships text fields to " + string(_text_width) + "px.");
    mmapi_log_flush(JP_ID);
}

function jp_log_relationships_left_nodes(_relationships) {
    if (_relationships == undefined) return;
    if (_relationships[$ "__journal_wider_poc_left_nodes_logged"] == true) return;
    _relationships.__journal_wider_poc_left_nodes_logged = true;

    // The viewport and scrollbar are already identified. Inspect the first NPC
    // row inside root next: that row owns the old-width background and the
    // hearts / relationship bar that need to move into the new space.
    if (_relationships[$ "npc_scroller"] == undefined) return;
    var _scroller = _relationships.npc_scroller;
    if (_scroller[$ "root"] == undefined || !is_array(_scroller.root.children)) return;
    var _children = _scroller.root.children;
    mmapi_log_info(JP_ID, "Relationships NPC row count: " + string(array_length(_children)));
    if (array_length(_children) <= 0) return;
    var _row = _children[0];
    var _row_names = struct_get_names(_row);
    mmapi_log_info(JP_ID, "Relationships NPC first row fields: " + string(_row_names));
    mmapi_log_info(JP_ID, "Relationships NPC first row geometry: x=" + string(_row.x)
        + " y=" + string(_row.y) + " w=" + string(_row.width) + " h=" + string(_row.height));
    if (_row[$ "glyph_node"] != undefined) {
        var _glyph = _row.glyph_node;
        mmapi_log_info(JP_ID, "Relationships NPC glyph geometry: x=" + string(_glyph.x)
            + " y=" + string(_glyph.y) + " w=" + string(_glyph.width) + " h=" + string(_glyph.height));
    }
    if (is_array(_row.children)) {
        mmapi_log_info(JP_ID, "Relationships NPC first row child count: " + string(array_length(_row.children)));
        for (var _i = 0; _i < array_length(_row.children); _i++) {
            var _child = _row.children[_i];
            mmapi_log_info(JP_ID, "Relationships NPC row child " + string(_i) + " fields: " + string(struct_get_names(_child)));
            mmapi_log_info(JP_ID, "Relationships NPC row child " + string(_i) + " geometry: x="
                + string(_child.x) + " y=" + string(_child.y) + " w=" + string(_child.width)
                + " h=" + string(_child.height) + " sprite=" + string(_child[$ "sprite"]));
        }
    }
    mmapi_log_flush(JP_ID);
}

function jp_reflow_relationships_left_list(_relationships) {
    if (_relationships == undefined || _relationships[$ "npc_scroller"] == undefined) return;
    var _scroller = _relationships.npc_scroller;
    if (_scroller[$ "root"] == undefined || _scroller[$ "scroll_bar_root"] == undefined) return;
    if (_relationships[$ "__journal_wider_poc_left_list_reflowed"] == true) return;
    _relationships.__journal_wider_poc_left_list_reflowed = true;

    // Scroller.gml constructs each element at canvas width and uses the canvas
    // render-partial as its clipping rectangle. Both must grow together before
    // rows can use the new page room; widening root alone leaves the old clip
    // in place and cuts off the right-aligned heart block.
    var _canvas_width = _scroller.canvas.get_width() + JP_EXTRA_PAGE_WIDTH;
    var _fits_without_scroll = _scroller.root_bottom_y <= _scroller.view_height;

    // Scroller.gml starts its bordered viewport one pixel outside its parent.
    // Keep the far edge fixed, but bring the widened left list onto the page's
    // inner left seam. Short lists have no scrollbar at all, so let them use
    // that reclaimed gutter rather than displaying an empty grey column.
    _scroller.move(2, 0);
    if (_fits_without_scroll) {
        _canvas_width = JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH - 2;
    } else {
        _canvas_width -= 2;
    }
    _scroller.canvas
        .set_width(_canvas_width)
        .set_render_partial(0, 0, _canvas_width, _scroller.view_height);
    _scroller.scroll_bar_root.set_x(_scroller.scroll_bar_root.get_x() + JP_EXTRA_PAGE_WIDTH);

    // RelationshipsMenu creates every unlocked NPC as a 161x40 scroller row.
    // Their heart sprite is RightIn-aligned, so changing the genuine row width
    // moves hearts and the progress bar to the new right edge while names and
    // portraits keep their original left-side layout.
    if (is_array(_scroller.root.children)) {
        for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
            var _row = _scroller.root.children[_i];
            if (_row.width == 161 && _row.height == 40) {
                _row.set_width(_row.get_width() + JP_EXTRA_PAGE_WIDTH);
            }
        }
    }

    if (_fits_without_scroll) _scroller.scroll_bar_root.disable();

    mmapi_log_info(JP_ID, "Reflowed Relationships left canvas, rows, hearts, and scrollbar by +" + string(JP_EXTRA_PAGE_WIDTH) + "px.");
    mmapi_log_flush(JP_ID);
}

function jp_reflow_customization_left(_customization, _journal) {
    if (_customization == undefined || _customization[$ "player_slot_root"] == undefined) return;
    if (_customization[$ "__journal_wider_poc_customization_left_reflowed"] == true) return;
    _customization.__journal_wider_poc_customization_left_reflowed = true;

    // CustomizationMenu puts every top editor control (slots, character,
    // arrows, and outfit button) in this one root. Its old coordinates target
    // a 189px page; shift the complete composition half of the added width to
    // retain the original balanced margins on a 239px page.
    _customization.player_slot_root.add_x(floor(JP_EXTRA_PAGE_WIDTH / 2));

    // The Customization right page is empty until a body slot is selected.
    // Give that empty state the actual 226px interior as well; otherwise the
    // oversized generic body leaves a false vertical divider near the right.
    if (_journal != undefined && _journal[$ "right_full_body"] != undefined) {
        _journal.right_full_body.set_width(JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH);
    }

    // JournalFields builds each 20px field plate at the parent's construction
    // width. Widen the parent and each existing plate, including its dynamic
    // hover borders, so the lower profile card spans the complete new page.
    if (_customization[$ "field_zone"] != undefined) {
        // Vanilla's body is 176px inside a 189px page (9px left and 4px
        // right padding). Keep those internal margins after widening: the
        // profile card is aligned to the same inner seam as the header. This
        // fixed JournalFields panel is not a Scroller, so it needs its own
        // two-pixel correction while retaining its existing far edge.
        var _field_width = JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH - 1;
        _customization.field_zone
            .set_align(Align.LeftIn, Align.BottomIn)
            .set_x(1)
            .set_width(_field_width);
        if (is_array(_customization.field_zone.children)) {
            for (var _i = 0; _i < array_length(_customization.field_zone.children); _i++) {
                var _plate = _customization.field_zone.children[_i];
                if (_plate.height == 20) {
                    _plate.set_width(_field_width);
                    _plate.border_top.set_scale_x(_field_width);
                    _plate.border_bottom.set_scale_x(_field_width);
                }
            }
        }
    }

    mmapi_log_info(JP_ID, "Reflowed Customization left editor and profile fields.");
    mmapi_log_flush(JP_ID);
}

function jp_reflow_customization_right(_customization) {
    if (_customization == undefined || _customization[$ "right_scroller"] == undefined) return;
    var _scroller = _customization.right_scroller;
    if (_scroller == undefined || _scroller[$ "__journal_wider_poc_customization_right_reflowed"] == true) return;

    // CustomizationMenu creates this scroller after a category is chosen. The
    // generic journal POC leaves right_full_body 13px wider than vanilla's
    // 176px inner body plus the new 50px room. Preserve the scrollbar's fixed
    // right edge, but shift its canvas to the correct inner-page x and shrink
    // it by that excess. All category rows and centred GridLayouts inherit the
    // corrected viewport automatically.
    var _content_width = JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH;
    var _target_canvas_width = _content_width + 2 - 18 + 1; // create_scroller()
    var _canvas_shift = _scroller.canvas.get_width() - _target_canvas_width;
    if (_canvas_shift < 0) return;

    if (_canvas_shift > 0) _scroller.move(_canvas_shift, 0);
    _scroller.canvas
        .set_width(_target_canvas_width)
        .set_render_partial(0, 0, _target_canvas_width, _scroller.view_height);

    if (is_array(_scroller.root.children)) {
        for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
            var _row = _scroller.root.children[_i];
            _row.set_width(_target_canvas_width);
        }
    }

    // Short cosmetic categories should not retain an invisible scrollbar
    // gutter. Their existing six-column GridLayout and pilot map deliberately
    // remain intact: only the real viewport expands, so keyboard/controller
    // navigation stays exactly paired with the visible cells.
    jp_expand_short_scroller_to_page(_scroller, _content_width);
    _scroller.__journal_wider_poc_customization_right_reflowed = true;

    mmapi_log_info(JP_ID, "Reflowed Customization right category scroller to " + string(_target_canvas_width) + "px.");
    mmapi_log_flush(JP_ID);
}

function jp_resize_common_slice(_node, _width) {
    if (_node == undefined) return;
    _node.set_width(_width);
    if (_node[$ "border_top"] != undefined) _node.border_top.set_scale_x(_width);
    if (_node[$ "border_bottom"] != undefined) _node.border_bottom.set_scale_x(_width);
}

function jp_reflow_auxbag_player_slots(_button_section) {
    if (_button_section == undefined || !is_array(_button_section.children)) return;

    // Mistria Auxiliary Bag injects seven 14px buttons into PlayerMenu's
    // button_section at fixed vanilla coordinates (4 + 15 * index). Its
    // label is not retained on the final node, so identify the complete
    // seven-button geometry rather than calling the other mod. The per-node
    // marker makes this harmless on every following frame and a no-op when
    // AuxBag is not installed.
    for (var _i = 0; _i < array_length(_button_section.children); _i++) {
        var _node = _button_section.children[_i];
        var _is_auxbag_slot = _node.width == 14
            && _node.height == 14
            && _node.y == 4
            && _node.x >= 4
            && _node.x <= 94
            && ((_node.x - 4) mod 15) == 0;
        if (!_is_auxbag_slot) continue;
        if (_node[$ "__journal_wider_poc_auxbag_shifted"] == true) continue;
        _node.__journal_wider_poc_auxbag_shifted = true;
        _node.add_x(floor(JP_EXTRA_PAGE_WIDTH / 2));
    }
}

function jp_align_player_defense(_player) {
    if (_player == undefined || _player[$ "equipment_section"] == undefined) return;
    if (_player[$ "__journal_wider_poc_defense_aligned"] == true) return;

    // The defense value is right-aligned independently from the essence
    // value above it. Use the same -5px right inset as essence; the shield is
    // anchored to this text, so the whole pair moves together by two pixels.
    var _children = _player.equipment_section.children;
    if (!is_array(_children)) return;
    for (var _i = 0; _i < array_length(_children); _i++) {
        var _node = _children[_i];
        if (_node[$ "sprite_font_name"] != "player_level") continue;
        _node.set_x(-5);
        _player.__journal_wider_poc_defense_aligned = true;
        return;
    }
}

function jp_align_player_info_fields(_player) {
    if (_player == undefined || _player[$ "info_section"] == undefined) return;
    if (_player[$ "__journal_wider_poc_info_fields_aligned"] == true) return;

    // The three top-left information fields are direct children of
    // info_section at x=2. The town-rank icon uses x=3 and received the
    // shared two-pixel header correction above, so bring these icon/text pairs
    // three pixels right to the same final x=5 line. Their text is parented to
    // each icon and follows automatically; right-hand time/currency stays put.
    var _children = _player.info_section.children;
    if (!is_array(_children)) return;
    var _aligned = 0;
    for (var _i = 0; _i < array_length(_children); _i++) {
        var _node = _children[_i];
        if (_node[$ "sprite"] == undefined || _node.x != 2) continue;
        if (_node.y != 2 && _node.y != 16 && _node.y != 30) continue;
        _node.add_x(3);
        _aligned += 1;
    }
    if (_aligned == 3) _player.__journal_wider_poc_info_fields_aligned = true;
}

function jp_reflow_player_inventory(_player) {
    if (_player == undefined || _player[$ "info_section"] == undefined) return;
    if (_player[$ "__journal_wider_poc_inventory_reflowed"] == true) return;
    _player.__journal_wider_poc_inventory_reflowed = true;

    // PlayerMenu sizes its content sections from left_body/right_body. The
    // generic journal experiment made those containers 239px wide, whereas
    // the visible journal interior is 176px + the new 50px room = 226px.
    // Restrict only those content sections to that real interior width; keep
    // the page headers and the separately centred InventoryMenu canvas alone.
    var _content_width = JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH;
    var _slice_width = _content_width + 2;

    // title_for_journal() centres its text through right_header but leaves the
    // inventory-bag icon at that header's old physical left edge. The title
    // text is already correct; shift only the separately stored icon by the
    // measured 14px correction: this leaves two whole pixels between the bag
    // icon and the header frame, matching the refined quest-details icon.
    if (_player[$ "inventory_title"] != undefined) {
        var _inventory_title_icon = _player.inventory_title.board_get("icon");
        if (_inventory_title_icon != undefined) {
            _inventory_title_icon.add_x(14);
        }
    }

    // PlayerMenu does not retain the Information title, but title_for_journal
    // stores its icon on the title TextNode in left_header. Move that header
    // icon, the two section-title icons, and the rank row by the same two-pixel
    // amount so text that is parented to an icon follows as one composition.
    if (_player[$ "journal"] != undefined && _player.journal[$ "left_header"] != undefined
        && is_array(_player.journal.left_header.children)) {
        for (var _i = 0; _i < array_length(_player.journal.left_header.children); _i++) {
            var _header_child = _player.journal.left_header.children[_i];
            var _info_icon = _header_child.board_get("icon");
            if (_info_icon != undefined) {
                _info_icon.add_x(2);
                break;
            }
        }
    }
    if (_player[$ "equipment_title"] != undefined) {
        var _equipment_icon = _player.equipment_title.board_get("icon");
        if (_equipment_icon != undefined) _equipment_icon.add_x(2);
    }
    if (_player[$ "skill_title"] != undefined) {
        var _skill_icon = _player.skill_title.board_get("icon");
        if (_skill_icon != undefined) _skill_icon.add_x(2);
    }

    _player.info_section.set_width(_content_width);
    jp_align_player_info_fields(_player);
    jp_resize_common_slice(_player.renown_backplate, _slice_width);
    if (is_array(_player.renown_backplate.children)) {
        for (var _i = 0; _i < array_length(_player.renown_backplate.children); _i++) {
            var _rank_icon = _player.renown_backplate.children[_i];
            if (_rank_icon[$ "sprite"] != undefined) {
                _rank_icon.add_x(2);
                break;
            }
        }
    }

    if (_player[$ "equipment_header"] != undefined) _player.equipment_header.set_width(_content_width);
    if (_player[$ "equipment_section"] != undefined) _player.equipment_section.set_width(_content_width);
    jp_align_player_defense(_player);
    if (_player[$ "skill_header"] != undefined) _player.skill_header.set_width(_content_width);
    if (_player[$ "skill_section"] != undefined) {
        _player.skill_section.set_x(-1);
        jp_resize_common_slice(_player.skill_section, _slice_width);
    }

    if (_player[$ "inventory_section"] != undefined) _player.inventory_section.set_width(_content_width);
    if (_player[$ "button_section"] != undefined) {
        _player.button_section.set_width(_content_width);
        // AuxBag creates its optional row from its own ui.menu_opened handler.
        // A node-frame callback guarantees we see it regardless of mod load
        // order, while leaving PlayerMenu and AuxBag code unmodified.
        _player.button_section.set_think_callback(method(_player.button_section, function() {
            jp_reflow_auxbag_player_slots(self);
        }));
    }

    mmapi_log_info(JP_ID, "Reflowed Player information panels and inventory action bar to " + string(_content_width) + "px.");
    mmapi_log_flush(JP_ID);
}

function jp_expand_text_max_widths(_node, _old_width, _new_width) {
    if (_node == undefined) return;
    if (_node[$ "max_width"] == _old_width) _node.set_max_width(_new_width);
    if (!is_array(_node.children)) return;
    for (var _i = 0; _i < array_length(_node.children); _i++) {
        jp_expand_text_max_widths(_node.children[_i], _old_width, _new_width);
    }
}

function jp_reflow_widened_left_scroller(_scroller, _text_old_width, _text_new_width) {
    if (_scroller == undefined || _scroller[$ "root"] == undefined
        || _scroller[$ "scroll_bar_root"] == undefined) return false;
    if (_scroller[$ "__journal_wider_poc_left_scroller_reflowed"] == true) return true;

    // QuestLog uses the same Scroller component as Relationships. The rows
    // differ in height, so share only the genuine viewport/scrollbar work and
    // preserve every existing vertical position and controller behavior.
    var _canvas_width = _scroller.canvas.get_width() + JP_EXTRA_PAGE_WIDTH;
    var _fits_without_scroll = _scroller.root_bottom_y <= _scroller.view_height;

    // Align the usual x=-1 Scroller viewport with the widened page without
    // moving its far edge. The header's inner seam sits two pixels right of
    // the vanilla viewport start; when content fits, the hidden scrollbar
    // also relinquishes its gutter (Spellcasting is the small-list example).
    _scroller.move(2, 0);
    if (_fits_without_scroll) {
        _canvas_width = JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH - 2;
    } else {
        _canvas_width -= 2;
    }
    _scroller.canvas
        .set_width(_canvas_width)
        .set_render_partial(0, 0, _canvas_width, _scroller.view_height);
    _scroller.scroll_bar_root.add_x(JP_EXTRA_PAGE_WIDTH);

    if (is_array(_scroller.root.children)) {
        for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
            var _row = _scroller.root.children[_i];
            jp_resize_common_slice(_row, _canvas_width);
            // Some shared lists (for example Animals) have no explicit text
            // cap. Keep that authored behaviour instead of manufacturing a
            // meaningless -1px cap while still widening the actual row.
            if (_text_old_width >= 0 && _text_new_width >= 0) {
                jp_expand_text_max_widths(_row, _text_old_width, _text_new_width);
            }
        }
    }
    if (_fits_without_scroll) _scroller.scroll_bar_root.disable();
    _scroller.__journal_wider_poc_left_scroller_reflowed = true;
    return true;
}

function jp_expand_short_scroller_to_page(_scroller, _page_inner_width) {
    if (_scroller == undefined || _scroller[$ "root"] == undefined
        || _scroller[$ "scroll_bar_root"] == undefined) return false;
    if (_scroller[$ "__journal_wider_poc_short_scroller_expanded"] == true) return true;
    if (_scroller.root_bottom_y > _scroller.view_height) return false;

    // This is the right-page counterpart to the short-list branch above.
    // A page with no actual scrollbar owns the entire inner rectangle, except
    // for the page nine-slice's final seam pixel.
    var _width = _page_inner_width - 1;
    _scroller.move(1, 0);
    _scroller.canvas
        .set_width(_width)
        .set_render_partial(0, 0, _width, _scroller.view_height);
    if (is_array(_scroller.root.children)) {
        for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
            jp_resize_common_slice(_scroller.root.children[_i], _width);
        }
    }
    _scroller.scroll_bar_root.disable();
    _scroller.__journal_wider_poc_short_scroller_expanded = true;
    return true;
}

function jp_reflow_quest_detail_scroller(_scroller) {
    if (_scroller == undefined || _scroller[$ "root"] == undefined
        || _scroller[$ "scroll_bar_root"] == undefined) return false;
    if (_scroller[$ "__journal_wider_poc_quest_detail_reflowed"] == true) return true;

    // QuestLog creates its detail scroller from right_body, which the generic
    // journal POC has already made 13px wider than the usable 226px interior.
    // Do not add another 50px here: use the CustomizationMenu pattern — shift
    // the canvas in by the excess and shrink it, leaving the existing
    // scrollbar fixed at the actual right edge of the page.
    var _content_width = JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH;
    var _target_canvas_width = _content_width + 2 - 18 + 1;
    var _canvas_shift = _scroller.canvas.get_width() - _target_canvas_width;
    if (_canvas_shift < 0) return false;

    if (_canvas_shift > 0) _scroller.move(_canvas_shift, 0);
    _scroller.canvas
        .set_width(_target_canvas_width)
        .set_render_partial(0, 0, _target_canvas_width, _scroller.view_height);
    if (is_array(_scroller.root.children)) {
        for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
            var _row = _scroller.root.children[_i];
            jp_resize_common_slice(_row, _target_canvas_width);
            jp_expand_text_max_widths(_row, 121, 121 + JP_EXTRA_PAGE_WIDTH);
        }
    }
    if (jp_expand_short_scroller_to_page(_scroller, _content_width)) {
        for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
            jp_expand_text_max_widths(_scroller.root.children[_i], 121 + JP_EXTRA_PAGE_WIDTH, 121 + JP_EXTRA_PAGE_WIDTH + 14);
        }
    }
    _scroller.__journal_wider_poc_quest_detail_reflowed = true;
    return true;
}

function jp_reflow_quest_log(_quests) {
    if (_quests == undefined) return;

    // setup_right_page() constructs text heights from journal.right_body.
    // Give it the genuine interior width *before* a quest is selected, rather
    // than shrinking an already-populated scroller afterwards. This preserves
    // the vanilla row-height calculation for any one-, two- or three-line
    // Bulgarian objective.
    if (_quests[$ "journal"] != undefined && _quests.journal[$ "right_body"] != undefined) {
        _quests.journal.right_body.set_width(JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH);
    }

    if (jp_reflow_widened_left_scroller(_quests[$ "left_scroller"], 111, 111 + JP_EXTRA_PAGE_WIDTH)) {
        if (_quests[$ "__journal_wider_poc_quest_left_logged"] != true) {
            _quests.__journal_wider_poc_quest_left_logged = true;
            mmapi_log_info(JP_ID, "Reflowed QuestLog left scroller and titles by +" + string(JP_EXTRA_PAGE_WIDTH) + "px.");
            mmapi_log_flush(JP_ID);
        }
    }
    if (jp_reflow_quest_detail_scroller(_quests[$ "right_scroller"])) {
        if (_quests[$ "__journal_wider_poc_quest_right_logged"] != true) {
            _quests.__journal_wider_poc_quest_right_logged = true;
            mmapi_log_info(JP_ID, "Reflowed QuestLog detail scroller and listings by +" + string(JP_EXTRA_PAGE_WIDTH) + "px.");
            mmapi_log_flush(JP_ID);
        }
    }
}

function jp_reflow_animals(_animals) {
    if (_animals == undefined || _animals[$ "journal"] == undefined) return;

    // AnimalMenu's left list is the same dynamic Scroller family as the
    // quest list: widening the real viewport moves its RightIn hearts and
    // progress bars naturally, while names and animal icons keep their
    // authored left alignment.
    if (jp_reflow_widened_left_scroller(_animals[$ "scroller"], -1, -1)) {
        if (_animals[$ "__journal_wider_poc_animal_left_logged"] != true) {
            _animals.__journal_wider_poc_animal_left_logged = true;
            mmapi_log_info(JP_ID, "Reflowed AnimalMenu left scroller by +" + string(JP_EXTRA_PAGE_WIDTH) + "px.");
            mmapi_log_flush(JP_ID);
        }
    }

    // AnimalMenu uses right_full_body directly for its preview, right-aligned
    // type/rarity controls, and later JournalFields. Give that parent the
    // genuine 226px interior before an animal is selected; the game's own
    // field builder then creates correctly sized rows without any post-hoc
    // text or height manipulation.
    var _content_width = JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH;
    if (_animals.journal[$ "right_full_body"] != undefined) {
        _animals.journal.right_full_body.set_width(_content_width);
    }
    if (_animals[$ "field_zone"] != undefined) {
        _animals.field_zone
            .set_align(Align.LeftIn, Align.BottomIn)
            // Use the midpoint between the two prior seam attempts: it keeps
            // the left border single while trimming only the one-pixel excess
            // at the right, rather than shifting the complete panel.
            .set_x(0)
            .set_width(_content_width - 1);
    }
}

function jp_hook_animals_reflow(_animals) {
    if (_animals == undefined || _animals[$ "on_think"] == undefined) return;
    if (_animals[$ "__journal_wider_poc_animal_think_hooked"] == true) return;
    _animals.__journal_wider_poc_animal_think_hooked = true;

    // AnimalMenu may rebuild its left list after moving an animal between
    // buildings. AnchorMenu.on_think() is empty here, so observe rebuilding
    // without modifying the game's selection or transfer callbacks.
    _animals.on_think = method(_animals, function() {
        jp_reflow_animals(self);
    });
}

function jp_reflow_spellcasting(_spells) {
    if (_spells == undefined || _spells[$ "journal"] == undefined) return;

    // The spell list has the same Scroller/40px-row structure as Animals.
    // Its labels are explicitly capped at 101px, so expand that cap along
    // with the viewport; the pin and checkbox remain RightIn and therefore
    // naturally keep their intended space at the far right.
    if (jp_reflow_widened_left_scroller(_spells[$ "scroller"], 101, 101 + JP_EXTRA_PAGE_WIDTH)) {
        if (_spells[$ "__journal_wider_poc_spell_left_logged"] != true) {
            _spells.__journal_wider_poc_spell_left_logged = true;
            mmapi_log_info(JP_ID, "Reflowed SpellcastingMenu left scroller by +" + string(JP_EXTRA_PAGE_WIDTH) + "px.");
            mmapi_log_flush(JP_ID);
        }
    }

    // SpellcastingMenu's detail column is authored as 103px wide with two
    // 99px rounded boxes. These are normal Anchor nodes, not baked art:
    // expand their real geometry by the page delta so long localized spell
    // names gain room rather than escaping through the page edge.
    var _content_width = JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH;
    if (_spells.journal[$ "right_full_body"] != undefined) {
        _spells.journal.right_full_body.set_width(_content_width);
    }
    if (_spells[$ "detail_zone"] != undefined) {
        _spells.detail_zone
            .set_width(103 + JP_EXTRA_PAGE_WIDTH - 2)
            .set_x(-2);
    }
    // Keep the rounded fields two pixels inside their detail-zone seam. The
    // original +50 expansion made their far nine-slice edge barely overhang
    // the page artwork; +48 still gives localized labels almost all of that
    // room while restoring the intended inset.
    if (_spells[$ "name_backplate"] != undefined) _spells.name_backplate.set_width(99 + JP_EXTRA_PAGE_WIDTH - 4);
    if (_spells[$ "type_backplate"] != undefined) _spells.type_backplate.set_width(99 + JP_EXTRA_PAGE_WIDTH - 4);
    if (_spells[$ "name_field"] != undefined) _spells.name_field.set_max_width(95 + JP_EXTRA_PAGE_WIDTH - 4);
    if (_spells[$ "type_field"] != undefined) _spells.type_field.set_max_width(95 + JP_EXTRA_PAGE_WIDTH - 4);

    // The lower description zone can use the entire widened page. Its icon
    // and pin button are a fixed visual group, so move that group by half of
    // the new space to keep it centred below the text.
    if (_spells.journal[$ "right_body"] != undefined) _spells.journal.right_body.set_width(_content_width);
    if (_spells[$ "bottom_zone"] != undefined) {
        _spells.bottom_zone
            .set_align(Align.LeftIn, Align.BottomIn)
            .set_x(0)
            .set_width(_content_width);
    }
    if (_spells[$ "lower_spell_icon"] != undefined) _spells.lower_spell_icon.add_x(JP_EXTRA_PAGE_WIDTH div 2);
    if (_spells[$ "pin_button"] != undefined) _spells.pin_button.add_x(JP_EXTRA_PAGE_WIDTH div 2);
}

function jp_reflow_map(_map) {
    if (_map == undefined || _map[$ "__journal_wider_poc_map_reflowed"] == true) return;

    // Maps are fixed pixel art: scaling would blur/deform both the map and
    // its hit locations. Move the whole grid instead; all map art, arrows,
    // location name and NPC markers are descendants of this one node.
    if (_map[$ "grid"] != undefined) _map.grid.add_x(JP_EXTRA_PAGE_WIDTH);

    // The location tabs are the one exception: vanilla creates them as
    // siblings of the grid. Move every tab by exactly the same amount so the
    // entire map interface remains one centred unit, without altering any
    // tab's sprite, selected state or tap callback.
    if (_map[$ "tab_nodes"] != undefined) {
        var _locations = _map.tab_nodes.keys();
        for (var _i = 0; _i < array_length(_locations); _i++) {
            var _tab = _map.tab_nodes.get(_locations[_i]);
            if (_tab != undefined) _tab.add_x(JP_EXTRA_PAGE_WIDTH);
        }
    }

    _map.__journal_wider_poc_map_reflowed = true;
    mmapi_log_info(JP_ID, "Centered fixed-size MapMenu grid and tabs by +" + string(JP_EXTRA_PAGE_WIDTH) + "px.");
    mmapi_log_flush(JP_ID);
}

function jp_reflow_almanac(_almanac) {
    if (_almanac == undefined || _almanac[$ "journal"] == undefined) return;

    // Almanac category rows are ordinary Scroller rows. Widen the real
    // viewport so its background and scrollbar match the rest of the Journal.
    var _scroller = _almanac[$ "category_scroller"];
    if (jp_reflow_widened_left_scroller(_scroller, -1, -1)) {
        var _label_width = _scroller.canvas.get_width() - 42;
        if (is_array(_scroller.root.children)) {
            for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
                var _row = _scroller.root.children[_i];
                if (_row[$ "text_label"] != undefined) {
                    // Reserve the lower-right corner for the collection
                    // counter. This prevents a wrapped category name from
                    // ever drawing through "70/105", even in a longer locale.
                    _row.text_label.set_max_width(_label_width);
                }
                if (!is_array(_row.children)) continue;
                for (var _j = 0; _j < array_length(_row.children); _j++) {
                    var _child = _row.children[_j];
                    if (_child != _row[$ "text_label"] && _child.type == NodeId.Text) {
                        _child
                            .set_align(Align.RightIn, Align.BottomIn)
                            .set_xy(-7, -3);
                    }
                }
            }
        }
        if (_almanac[$ "__journal_wider_poc_almanac_left_logged"] != true) {
            _almanac.__journal_wider_poc_almanac_left_logged = true;
            mmapi_log_info(JP_ID, "Reflowed Almanac category list and protected collection counters by +" + string(JP_EXTRA_PAGE_WIDTH) + "px.");
            mmapi_log_flush(JP_ID);
        }
    }

    // Both Almanac detail modes (a short static-looking grid and a longer
    // scrolling grid) are built by the same item_scroller after a category
    // click. Set the parent to the genuine wider interior first; no item art
    // or built-in icon needs to move or stretch.
    if (_almanac.journal[$ "right_full_body"] != undefined) {
        _almanac.journal.right_full_body.set_width(JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH);
    }

    jp_reflow_almanac_item_grid(_almanac);
    jp_expand_short_scroller_to_page(
        _almanac[$ "item_scroller"],
        JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH
    );
}

function jp_reflow_almanac_item_grid(_almanac) {
    if (_almanac == undefined || _almanac[$ "item_scroller"] == undefined
        || _almanac.item_scroller == undefined) return;
    var _scroller = _almanac.item_scroller;
    if (_scroller[$ "__journal_wider_poc_almanac_grid_reflowed"] == true) return;
    if (_scroller[$ "root"] == undefined || !is_array(_scroller.root.children)) return;

    // Vanilla hard-codes six 24px cells per row. Derive the column count
    // from the real clipped viewport instead: this is eight on our 226px
    // page, while a narrower future layout automatically keeps fewer cells
    // rather than shrinking pixel art or overflowing into the scrollbar.
    var _slot_size = 24;
    var _gap = 2;
    var _base_x = 3;
    var _base_y = 27;
    var _step = _slot_size + _gap;
    var _columns = max(1, floor((_scroller.canvas.get_width() - _base_x) / _step));
    var _squares = [];
    var _owner = undefined;

    for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
        var _element = _scroller.root.children[_i];
        if (!is_array(_element.children)) continue;
        for (var _j = 0; _j < array_length(_element.children); _j++) {
            var _child = _element.children[_j];
            if (_child.width == _slot_size && _child.height == _slot_size) {
                array_push(_squares, _child);
                _owner = _element;
            }
        }
    }
    if (array_length(_squares) <= 0 || _owner == undefined) return;

    for (var _i = 0; _i < array_length(_squares); _i++) {
        _squares[_i].set_xy(
            _base_x + ((_i mod _columns) * _step),
            _base_y + (floor(_i / _columns) * _step)
        );
    }

    // The original builder reserves 23px of extra element height for each
    // additional six-cell row. Correct that reservation after reflow so the
    // scrollbar range reflects the denser grid instead of blank old rows.
    var _old_rows = ceil(array_length(_squares) / 6);
    var _new_rows = ceil(array_length(_squares) / _columns);
    var _height_delta = 23 * (_new_rows - _old_rows);
    if (_height_delta != 0) _scroller.add_height_to_element(_owner, _height_delta);

    _scroller.__journal_wider_poc_almanac_grid_reflowed = true;
    mmapi_log_info(JP_ID, "Reflowed Almanac item grid to " + string(_columns) + " columns.");
    mmapi_log_flush(JP_ID);
}

function jp_fit_settings_buttons(_node, _max_width) {
    if (_node == undefined) return;

    // SettingsMenu's value/action buttons use a fixed 84px vanilla width.
    // Their labels are real child TextNodes, so let the nine-slice follow the
    // rendered label instead of clipping a localized action such as Move.
    if (_node[$ "text_label"] != undefined && _node.width == 84) {
        var _wanted = max(84, _node.text_label.get_width() + 14);
        _wanted = min(_wanted, _max_width);
        _node.set_width(_wanted);
        _node.text_label.set_max_width(_wanted - 10);
    }

    if (!is_array(_node.children)) return;
    for (var _i = 0; _i < array_length(_node.children); _i++) {
        jp_fit_settings_buttons(_node.children[_i], _max_width);
    }
}

function jp_reflow_settings_options(_settings) {
    if (_settings == undefined || _settings[$ "option_scroller"] == undefined
        || _settings.option_scroller == undefined) return;
    var _scroller = _settings.option_scroller;
    if (_scroller[$ "__journal_wider_poc_settings_options_reflowed"] == true) return;
    if (_scroller[$ "root"] == undefined || !is_array(_scroller.root.children)) return;

    var _width = _scroller.canvas.get_width();
    var _cursor_y = 0;

    // Pack once at the normal scrollbar width. Keep each row's original
    // authored height so a second layout pass cannot grow it indefinitely.
    for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
        var _row = _scroller.root.children[_i];
        if (_row[$ "__journal_wider_poc_settings_base_height"] == undefined) {
            _row.__journal_wider_poc_settings_base_height = _row.get_height();
        }
        jp_resize_common_slice(_row, _width);
        jp_expand_text_max_widths(_row, 141, 141 + JP_EXTRA_PAGE_WIDTH);
        jp_fit_settings_buttons(_row, _width - 14);
        var _height = _row.__journal_wider_poc_settings_base_height;
        if (_row[$ "text_label"] != undefined) {
            _height = max(_height, _row.text_label.get_height() + 10);
        }
        _row.set_y(_cursor_y);
        _row.set_height(_height);
        _cursor_y += _height - 1;
    }

    // A hidden scrollbar should not still consume its 18px gutter. Expand
    // only short pages that demonstrably fit, then pack a second time with
    // the wider text area. Long pages keep the original scrollbar geometry.
    if (_cursor_y <= _scroller.view_height) {
        // create_scroller() normally starts at x=-1 for its bordered
        // scrollbar viewport. With the bar absent that makes a full-width
        // panel protrude by a pixel; use the page's exact inner rectangle.
        _scroller.move(1, 0);
        // The page's right nine-slice owns its final seam pixel. Leave that
        // pixel to the page rather than letting a no-scroll option row draw
        // through it; this also covers Settings pages injected by other mods
        // that use the same SettingsMenu element builder.
        _width = _settings.journal.right_full_body.get_width() - 1;
        _scroller.canvas
            .set_width(_width)
            .set_render_partial(0, 0, _width, _scroller.view_height);
        _cursor_y = 0;
        for (var _i = 0; _i < array_length(_scroller.root.children); _i++) {
            var _row = _scroller.root.children[_i];
            jp_resize_common_slice(_row, _width);
            jp_expand_text_max_widths(_row, 141 + JP_EXTRA_PAGE_WIDTH, _width - 20);
            jp_fit_settings_buttons(_row, _width - 14);
            var _height = _row.__journal_wider_poc_settings_base_height;
            if (_row[$ "text_label"] != undefined) {
                _height = max(_height, _row.text_label.get_height() + 10);
            }
            _row.set_y(_cursor_y);
            _row.set_height(_height);
            _cursor_y += _height - 1;
        }
    }

    // Scroller keeps its content extent separately from its children. Update
    // it after packing so the visible scrollbar range is based on the real
    // localized row heights, including long Bulgarian (or future) labels.
    _scroller.root_bottom_y = _cursor_y;
    _scroller.canvas.set_height(max(_cursor_y, _scroller.view_height));
    if (_cursor_y < _scroller.view_height) {
        _scroller.scroll_bar_root.disable();
    } else if (_cursor_y - 1 > _scroller.view_height) {
        _scroller.scroll_bar_root.enable();
    }
    _scroller.update_button_height();
    _scroller.__journal_wider_poc_settings_options_reflowed = true;

    mmapi_log_info(JP_ID, "Reflowed Settings option rows and action buttons to localized text size.");
    mmapi_log_flush(JP_ID);
}

function jp_reflow_settings(_settings) {
    if (_settings == undefined || _settings[$ "journal"] == undefined) return;

    if (jp_reflow_widened_left_scroller(_settings[$ "category_scroller"], -1, -1)) {
        var _categories = _settings.category_scroller;
        if (is_array(_categories.root.children)) {
            for (var _i = 0; _i < array_length(_categories.root.children); _i++) {
                var _row = _categories.root.children[_i];
                if (_row[$ "text_label"] != undefined) {
                    _row.text_label.set_max_width(_categories.canvas.get_width() - 28);
                }
            }
        }
    }

    // The option scroller is created after a category click. Set the parent
    // first so both short pages and pages with a scrollbar start at 226px.
    if (_settings.journal[$ "right_full_body"] != undefined) {
        _settings.journal.right_full_body.set_width(JP_JOURNAL_BODY_WIDTH + JP_EXTRA_PAGE_WIDTH);
    }
    jp_reflow_settings_options(_settings);
}

function jp_hook_settings_reflow(_settings) {
    if (_settings == undefined || _settings[$ "on_think"] == undefined) return;
    if (_settings[$ "__journal_wider_poc_settings_think_hooked"] == true) return;
    _settings.__journal_wider_poc_settings_think_hooked = true;

    // SettingsMenu owns the important interaction callback on journal.book,
    // not on its inherited empty on_think. Observe new option scrollers here
    // so category selection, sliders and mod-injected settings stay vanilla.
    _settings.on_think = method(_settings, function() {
        jp_reflow_settings(self);
    });
}

function jp_hook_almanac_reflow(_almanac) {
    if (_almanac == undefined || _almanac[$ "on_think"] == undefined) return;
    if (_almanac[$ "__journal_wider_poc_almanac_think_hooked"] == true) return;
    _almanac.__journal_wider_poc_almanac_think_hooked = true;

    // The item scroller is created only after the player selects a category.
    // AnchorMenu.on_think() is empty, so this safely observes that later
    // creation without altering Almanac selection or tooltip callbacks.
    _almanac.on_think = method(_almanac, function() {
        jp_reflow_almanac(self);
    });
}

function jp_reflow_quest_titles(_quests) {
    if (_quests == undefined || _quests[$ "__journal_wider_poc_quest_titles_reflowed"] == true) return;
    if (_quests[$ "right_title"] == undefined) return;

    // title_for_journal() leaves its separate header icon at vanilla x=3.
    // The title itself centres correctly after the Journal widens; match the
    // measured +10px correction already used by PlayerMenu's Inventory title,
    // plus one pixel for this sheet icon's border.
    var _right_icon = _quests.right_title.board_get("icon");
    if (_right_icon != undefined) _right_icon.add_x(13);
    _quests.__journal_wider_poc_quest_titles_reflowed = true;
}

function jp_hook_quest_log_reflow(_quests) {
    if (_quests == undefined || _quests[$ "on_think"] == undefined) return;
    if (_quests[$ "__journal_wider_poc_quest_think_hooked"] == true) return;
    _quests.__journal_wider_poc_quest_think_hooked = true;

    // QuestLogMenu inherits AnchorMenu.on_think(), which is empty. Observe it
    // rather than replacing setup_right_page(), because each selected quest
    // rebuilds its right scroller after the click.
    _quests.on_think = method(_quests, function() {
        jp_reflow_quest_log(self);
    });
}

function jp_reflow_popup_header(_popup, _width) {
    // PopupMenu.add_title() calculates its header just once, before the
    // Player-menu callback supplies the popup's final dimensions. Re-measure
    // after widening so translated titles get their natural one-line width
    // when possible, but still wrap cleanly if a future language needs it.
    if (_popup == undefined || _popup[$ "header"] == undefined || _popup[$ "title"] == undefined) return;
    _popup.header.set_width(_width - 30);
    _popup.header.set_height(_popup.title.measure().y + 4);
}

function jp_find_sprite_child(_node, _sprite) {
    if (_node == undefined || !is_array(_node.children)) return undefined;
    for (var _i = 0; _i < array_length(_node.children); _i++) {
        var _child = _node.children[_i];
        if (_child[$ "sprite"] == _sprite) return _child;
    }
    return undefined;
}

function jp_shift_sprite_descendants(_node, _sprite, _amount) {
    if (_node == undefined || !is_array(_node.children)) return;
    for (var _i = 0; _i < array_length(_node.children); _i++) {
        var _child = _node.children[_i];
        if (_child[$ "sprite"] == _sprite
            && _child[$ "__journal_wider_poc_popup_shifted"] != true) {
            _child.__journal_wider_poc_popup_shifted = true;
            _child.add_x(_amount);
        }
        jp_shift_sprite_descendants(_child, _sprite, _amount);
    }
}

function jp_find_first_text_descendant(_node) {
    if (_node == undefined || !is_array(_node.children)) return undefined;
    for (var _i = 0; _i < array_length(_node.children); _i++) {
        var _child = _node.children[_i];
        if (_child[$ "font"] != undefined && _child[$ "text"] != undefined) return _child;
        var _nested = jp_find_first_text_descendant(_child);
        if (_nested != undefined) return _nested;
    }
    return undefined;
}

function jp_position_town_rank_locks(_grid) {
    if (_grid == undefined || !is_array(_grid.children)) return;

    // The chart graphic has two baked columns, but Bulgarian "Ниво 100" needs
    // more space than the authored level cell. Treat the locks as a deliberate
    // borderless third column: every lock shares one fixed x position after
    // the longest level label, so the number of digits never changes the row
    // geometry or produces a diagonal stack of locks.
    var _children = _grid.children;
    for (var _i = 0; _i < array_length(_children); _i++) {
        var _lock = _children[_i];
        if (_lock[$ "sprite"] != spr_ui_blacksmithing_lock_icon) continue;
        _lock
            .set_align(Align.LeftIn, Align.TopIn)
            .set_x(JP_TOWN_RANK_LOCK_COLUMN_X);
    }
}

function jp_reflow_town_rank_popup(_popup) {
    var _grid = jp_find_sprite_child(_popup.backplate, spr_ui_renown_chart_grid);
    if (_grid == undefined) return; // The PlayerMenu builder has not finished yet.

    if (_popup[$ "__journal_wider_poc_town_rank_reflowed"] != true) {
        _popup.backplate.set_size(JP_TOWN_RANK_POPUP_WIDTH, JP_TOWN_RANK_POPUP_HEIGHT);
        jp_reflow_popup_header(_popup, JP_TOWN_RANK_POPUP_WIDTH);

        // The chart artwork stays native-sized. Its visible two columns plus
        // the borderless lock column are 184px wide, so offset the baked grid
        // left by 9px from its ordinary 166px-only centre.
        _grid.add_x(JP_TOWN_RANK_GRID_CENTER_SHIFT);
        _popup.__journal_wider_poc_town_rank_reflowed = true;
        mmapi_log_info(JP_ID, "Reflowed town-rank guide popup to " + string(JP_TOWN_RANK_POPUP_WIDTH) + "px.");
        mmapi_log_flush(JP_ID);
    }
    jp_position_town_rank_locks(_grid);
}

function jp_reflow_skill_levels_popup(_popup) {
    if (_popup[$ "__journal_wider_poc_skill_levels_reflowed"] == true) return;
    if (_popup[$ "sub_plate"] == undefined) return; // The PlayerMenu builder has not finished yet.

    _popup.backplate.set_size(JP_SKILL_POPUP_WIDTH, JP_SKILL_POPUP_HEIGHT);
    jp_reflow_popup_header(_popup, JP_SKILL_POPUP_WIDTH);

    // Keep every pixel-art skill label and bar at its native size. The
    // nine-slice is already Center-aligned in the wider popup; adding another
    // offset would visibly push the complete panel to the right.
    _popup.sub_plate.set_width(JP_SKILL_SUBPLATE_WIDTH);
    jp_shift_sprite_descendants(_popup.sub_plate, spr_ui_journal_skill_progress_bar_green, JP_SKILL_BAR_SHIFT);
    jp_shift_sprite_descendants(_popup.sub_plate, spr_ui_journal_skill_progress_bar_blue, JP_SKILL_BAR_SHIFT);
    jp_shift_sprite_descendants(_popup.sub_plate, spr_ui_journal_skill_progress_bar_pink, JP_SKILL_BAR_SHIFT);
    _popup.__journal_wider_poc_skill_levels_reflowed = true;
    mmapi_log_info(JP_ID, "Reflowed skill-level popup to " + string(JP_SKILL_POPUP_WIDTH) + "px.");
    mmapi_log_flush(JP_ID);
}

function jp_reflow_player_popup(_popup) {
    if (_popup == undefined || _popup[$ "title"] == undefined) return false;
    var _key = _popup.title[$ "local_key"];
    if (_key == "misc_local/town_rank_guide") {
        jp_reflow_town_rank_popup(_popup);
        return true;
    }
    if (_key == "misc_local/skill_levels") {
        jp_reflow_skill_levels_popup(_popup);
        return true;
    }
    return true;
}

function jp_hook_player_popup_reflow(_popup) {
    if (_popup == undefined || _popup[$ "canvas"] == undefined) return;
    if (_popup[$ "__journal_wider_poc_popup_think_hooked"] == true) return;
    _popup.__journal_wider_poc_popup_think_hooked = true;

    // popup_creator() emits ui.menu_opened before PlayerMenu finishes adding
    // its grid/sub-plate. Chain the PopupMenu canvas callback and wait until
    // that authored content exists. A non-matching popup immediately restores
    // its exact vanilla callback, so unrelated dialogs are never changed.
    var _vanilla_think = _popup.canvas.event_callbacks.think;
    _popup.canvas.set_think_callback(function(_popup, _vanilla_think) {
        function_execute_alt(_vanilla_think.func, _vanilla_think.arg_array);
        if (_popup.title == undefined) return;
        var _key = _popup.title[$ "local_key"];
        if (_key != "misc_local/town_rank_guide" && _key != "misc_local/skill_levels") {
            _popup.canvas.set_think_callback(_vanilla_think.func, _vanilla_think.arg_array, true);
            return;
        }
        jp_reflow_player_popup(_popup);
    }, [_popup, _vanilla_think], true);
}

function jp_gift_slot(_gift, _parent, _icons, _npc_id, _xx, _yy) {
    var _slot = common_slice(_parent, JP_GIFT_SLOT_SIZE, JP_GIFT_SLOT_SIZE)
        .set_xy(_xx, _yy);
    if (_gift == undefined) {
        _slot.lock();
        return;
    }

    var _knows_gift = NPCS[_npc_id].known_gift_preferences.contains(_gift);
    var _given_gift = NPCS[_npc_id].gifts_given.contains(_gift);
    var _icon = ANCHOR.sprite(_slot)
        .set_sprite(_knows_gift ? ITEM_PROTOTYPES[_gift].icon_sprite : spr_ui_generic_lock_icon)
        .set_align(Align.Center, Align.Middle)
        .set_alpha(_knows_gift && !_given_gift ? 0.5 : 1);
    _icon.item_id = _gift;
    _icons.push(_icon);
}

function jp_compact_gift_preferences(_relationships) {
    if (_relationships == undefined || _relationships[$ "gift_nodes"] == undefined) return;
    if (_relationships[$ "__journal_wider_poc_compact_gifts"] == true) return;
    _relationships.__journal_wider_poc_compact_gifts = true;

    // Vanilla uses a 5x2 loved grid and a 5x4 liked grid. Eight columns retain
    // two loved rows and reduce the 20 liked slots to three, while preserving
    // the normal-sized portrait without overlap. Grow the existing
    // right-aligned detail zone leftward, so its right edge and page artwork
    // remain untouched.
    var _grid_width = JP_GIFT_SLOT_SIZE + (JP_GIFT_SLOT_STEP * (JP_GIFT_COLUMNS - 1));
    var _gifts = _relationships.gift_nodes;
    // Keep a one-pixel seam between the compact grid and the page frame.
    // RightIn makes the zone grow leftward; the -1 inset flushes its visible
    // edge with every other right-hand journal panel.
    _relationships.detail_zone
        .set_width(_grid_width)
        .set_x(-1);
    _gifts.loved_gift_zone
        .set_size(_grid_width, 35)
        .set_y(JP_GIFT_LOVED_ZONE_Y);
    _gifts.liked_gifts.set_y(JP_GIFT_LIKED_LABEL_Y);
    _gifts.liked_gift_zone
        .set_size(_grid_width, 35)
        .set_y(JP_GIFT_LIKED_ZONE_Y);

    // Reuse vanilla's public node structure and its item-id convention so
    // every slot retains the normal hover/tooltip behavior.
    _gifts.set_to_npc = method(_gifts, function(_npc_id) {
        var _proto = NPC_PROTOTYPES[_npc_id];

        ANCHOR.free_children(self.loved_gift_zone);
        var _iter = 0;
        for (var _i = 0; _i < JP_GIFT_LOVED_ROWS; _i++) {
            for (var _j = 0; _j < JP_GIFT_COLUMNS; _j++) {
                jp_gift_slot(_proto.loved_gifts.try_get(_iter), self.loved_gift_zone,
                    self.icons, _npc_id, JP_GIFT_SLOT_STEP * _j, JP_GIFT_SLOT_STEP * _i);
                _iter += 1;
            }
        }

        ANCHOR.free_children(self.liked_gift_zone);
        _iter = 0;
        for (var _i = 0; _i < JP_GIFT_LIKED_ROWS; _i++) {
            for (var _j = 0; _j < JP_GIFT_COLUMNS; _j++) {
                jp_gift_slot(_proto.liked_gifts.try_get(_iter), self.liked_gift_zone,
                    self.icons, _npc_id, JP_GIFT_SLOT_STEP * _j, JP_GIFT_SLOT_STEP * _i);
                _iter += 1;
            }
        }
    });

    _gifts.set_to_npc(_relationships.npc_id_current);
    mmapi_log_info(JP_ID, "Reflowed gift grids to " + string(JP_GIFT_COLUMNS) + " columns.");
    mmapi_log_flush(JP_ID);
}

function jp_on_menu_opened(_ctx) {
    if (!is_struct(_ctx)) return;

    // Journal itself immediately opens a child page (Player, Relationships,
    // Collections, etc.). That child event happens after JournalMenu.reset(),
    // which is the first point at which the rebuilt book can safely be changed.
    if (_ctx[$ "kind"] == Menu.Journal) return;
    var _journal = ANCHOR.get_menu(Menu.Journal);
    if (_journal == undefined) return;
    jp_apply_wider_journal(_journal);
    jp_align_left_title_icon(_ctx[$ "menu"]);
    if (_ctx[$ "kind"] == Menu.Almanac
        || _ctx[$ "kind"] == Menu.Animal
        || _ctx[$ "kind"] == Menu.Relationships
        || _ctx[$ "kind"] == Menu.QuestLog)
    {
        // Settings is the measured baseline. These four sprites retain one
        // extra pixel of transparent left padding in their authored art.
        jp_nudge_left_title_icon(_ctx[$ "menu"], 1);
    }

    if (_ctx[$ "kind"] == Menu.Relationships) {
        jp_reflow_relationships(_ctx[$ "menu"], _journal);
        jp_compact_gift_preferences(_ctx[$ "menu"]);
        jp_reflow_relationships_left_list(_ctx[$ "menu"]);
    }

    if (_ctx[$ "kind"] == Menu.Customization) {
        jp_reflow_customization_left(_ctx[$ "menu"], _journal);
        jp_hook_customization_right_reflow(_ctx[$ "menu"]);
    }

    if (_ctx[$ "kind"] == Menu.Player) {
        jp_reflow_player_inventory(_ctx[$ "menu"]);
    }

    if (_ctx[$ "kind"] == Menu.QuestLog) {
        jp_hook_quest_log_reflow(_ctx[$ "menu"]);
        jp_reflow_quest_titles(_ctx[$ "menu"]);
        jp_reflow_quest_log(_ctx[$ "menu"]);
    }

    if (_ctx[$ "kind"] == Menu.Animal) {
        jp_hook_animals_reflow(_ctx[$ "menu"]);
        jp_reflow_animals(_ctx[$ "menu"]);
    }

    if (_ctx[$ "kind"] == Menu.Spellcasting) {
        jp_reflow_spellcasting(_ctx[$ "menu"]);
    }

    if (_ctx[$ "kind"] == Menu.Map) {
        jp_reflow_map(_ctx[$ "menu"]);
    }

    if (_ctx[$ "kind"] == Menu.Almanac) {
        jp_hook_almanac_reflow(_ctx[$ "menu"]);
        jp_reflow_almanac(_ctx[$ "menu"]);
    }

    if (_ctx[$ "kind"] == Menu.Settings) {
        jp_hook_settings_reflow(_ctx[$ "menu"]);
        jp_reflow_settings(_ctx[$ "menu"]);
    }

    if (_ctx[$ "kind"] == Menu.Popup) {
        jp_hook_player_popup_reflow(_ctx[$ "menu"]);
    }
}

function jp_hook_customization_right_reflow(_customization) {
    if (_customization == undefined || _customization[$ "on_think"] == undefined) return;
    if (_customization[$ "__journal_wider_poc_customization_right_think_hooked"] == true) return;
    _customization.__journal_wider_poc_customization_right_think_hooked = true;

    // Vanilla CustomizationMenu.on_think() is intentionally empty. Use it as
    // a post-click observer instead of touching setup_right_page(), so the
    // game's category-opening path remains exactly as authored.
    _customization.on_think = method(_customization, function() {
        jp_reflow_customization_right(self);
    });
}

function jp_register() {
    mmapi_on("ui.menu_opened", jp_on_menu_opened);
}

mmapi_mod_declare(JP_ID, "0.1.0");
jp_register();
