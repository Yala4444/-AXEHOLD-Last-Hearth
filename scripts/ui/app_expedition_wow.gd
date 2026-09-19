extends "res://scripts/ui/app_living_camp.gd"

const HomeCampScene: PackedScene = preload("res://scenes/camp_view.tscn")

func _show_result() -> void:
    _clear_body()
    nav.visible = false

    var won: bool = bool(result_data.get("won", false))
    var biome_index: int = clampi(int(result_data.get("biome", 0)), 0, GameRules.BIOMES.size() - 1)
    var biome_data: Dictionary = GameRules.biome(biome_index)

    var panel := _panel(body)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 10)

    var eyebrow := Label.new()
    box.add_child(eyebrow)
    eyebrow.text = "ТРОФЕЙ ЭКСПЕДИЦИИ" if won else "ЭКСПЕДИЦИЯ ЗАВЕРШЕНА"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 10)
    eyebrow.add_theme_color_override("font_color", Color("d5b675"))

    var title := Label.new()
    box.add_child(title)
    title.text = "%s повержен" % str(biome_data.get("boss_name", "Хранитель")) if won else "Герой отступает к Очагу"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    if won:
        var trophy := Label.new()
        box.add_child(trophy)
        trophy.text = "%s\n%s" % [WeaponRules.relic_name(biome_index), _victory_trophy_line(biome_index)]
        trophy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        trophy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        trophy.add_theme_font_size_override("font_size", 14)
        trophy.add_theme_color_override("font_color", Color("f0d094"))

    var stats := Label.new()
    box.add_child(stats)
    stats.text = "Ночь %d · Убийства %d\n%d мон. · %d оск." % [
        int(result_data.get("wave", 0)),
        int(result_data.get("kills", 0)),
        int(result_data.get("coins", 0)),
        int(result_data.get("shards", 0))
    ]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.add_theme_color_override("font_color", Color(0.78, 0.81, 0.83))

    var contract_result: Dictionary = result_data.get("contract", {}) as Dictionary
    if not contract_result.is_empty():
        var contract_note := Label.new()
        box.add_child(contract_note)
        if bool(contract_result.get("completed", false)):
            var renown_gain: int = int(contract_result.get("renown", 0))
            contract_note.text = "КОНТРАКТ ВЫПОЛНЕН · %s%s" % [
                str(contract_result.get("name", "")),
                " · +%d славы" % renown_gain if renown_gain > 0 else ""
            ]
            contract_note.add_theme_color_override("font_color", Color("d9bd79"))
        else:
            contract_note.text = "Контракт не выполнен · " + str(contract_result.get("name", ""))
            contract_note.add_theme_color_override("font_color", Color("8f999a"))
        contract_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        contract_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        contract_note.add_theme_font_size_override("font_size", 9)

    var dynamic_result: Dictionary = result_data.get("dynamic_world", {})
    if not dynamic_result.is_empty():
        var dynamic_note := Label.new()
        box.add_child(dynamic_note)
        dynamic_note.text = "СОБЫТИЯ МИРА · %d завершено · %d упущено · %d элит · %d спасений" % [
            int(dynamic_result.get("completed", 0)),
            int(dynamic_result.get("failed", 0)),
            int(dynamic_result.get("elites", 0)),
            int(dynamic_result.get("rescues", 0))
        ]
        if int(dynamic_result.get("chains", 0)) > 0:
            dynamic_note.text += "\nЦепочки событий: %d" % int(dynamic_result.get("chains", 0))
        dynamic_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        dynamic_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        dynamic_note.add_theme_font_size_override("font_size", 9)
        dynamic_note.add_theme_color_override("font_color", Color("b8c7c1"))

    var biome_result: Dictionary = result_data.get("biome_events", {})
    if not biome_result.is_empty():
        var region_note := Label.new()
        box.add_child(region_note)
        region_note.text = "РЕГИОН · %d событий · %d охот · %d идеальных прохождений" % [
            int(biome_result.get("completed", 0)),
            int(biome_result.get("hunts", 0)),
            int(biome_result.get("perfect", 0))
        ]
        if int(biome_result.get("failed", 0)) > 0:
            region_note.text += " · %d упущено" % int(biome_result.get("failed", 0))
        region_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        region_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        region_note.add_theme_font_size_override("font_size", 9)
        region_note.add_theme_color_override("font_color", VisualSystem.GOLD)

    var parts_unused: int = int(result_data.get("parts_unused", 0))
    if parts_unused > 0:
        var parts_note := Label.new()
        box.add_child(parts_note)
        parts_note.text = "Неиспользованные детали: %d → +%d мон." % [parts_unused, int(result_data.get("parts_bonus", 0))]
        parts_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        parts_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        parts_note.add_theme_font_size_override("font_size", 9)
        parts_note.add_theme_color_override("font_color", Color("b9c4c3"))

    var claim_text: String = "Забрать трофей и вернуться" if won else "Вернуться в лагерь"
    var claim := _button(box, claim_text, true)
    claim.pressed.connect(_grant_result.bind(1))

    var double := _button(box, "Удвоить монеты", false)
    double.pressed.connect(_double_result)

func _victory_trophy_line(biome_index: int) -> String:
    var wins: Array = GameState.data.get("biome_wins", [0, 0, 0])
    var count: int = int(wins[biome_index]) if biome_index < wins.size() else 1
    if count <= 1:
        var weapon_id: String = WeaponRules.unlock_for_biome(biome_index)
        var profile: Dictionary = WeaponRules.profile(weapon_id)
        return "Новый трофей для лагеря · открыто оружие: %s" % str(profile.get("name", weapon_id))
    return "Мастерство биома: %s" % WeaponRules.mastery_bonus_text(count)

func _grant_result(multiplier: int) -> void:
    if result_data.is_empty():
        return

    var snapshot: Dictionary = result_data.duplicate(true)
    GameState.add_coins(int(snapshot.get("coins", 0)) * multiplier)
    GameState.add_shards(int(snapshot.get("shards", 0)))
    result_data = {}

    if bool(snapshot.get("won", false)):
        _show_homecoming(snapshot)
    else:
        nav.visible = true
        _show_home()

func _show_homecoming(snapshot: Dictionary) -> void:
    _clear_body()
    nav.visible = false

    var camp: CampView = HomeCampScene.instantiate() as CampView
    body.add_child(camp)
    camp.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var biome_index: int = clampi(int(snapshot.get("biome", 0)), 0, GameRules.BIOMES.size() - 1)
    var panel := _panel(body)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 8)

    var eyebrow := Label.new()
    box.add_child(eyebrow)
    eyebrow.text = "ВОЗВРАЩЕНИЕ"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 10)
    eyebrow.add_theme_color_override("font_color", Color("d5b675"))

    var title := Label.new()
    box.add_child(title)
    title.text = "Герой вернулся в %s" % GameState.camp_title()
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 19)
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var description := Label.new()
    box.add_child(description)
    description.text = "%s установлена среди трофеев. Лагерь запомнит эту победу." % WeaponRules.relic_name(biome_index)
    description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.add_theme_color_override("font_color", Color(0.78, 0.81, 0.83))

    var enter := _button(box, "Войти в лагерь", true)
    enter.pressed.connect(_finish_homecoming)

func _finish_homecoming() -> void:
    Feedback.play("victory", 16)
    nav.visible = true
    _show_home()
