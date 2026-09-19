extends Control

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var shell: Control
var body: VBoxContainer
var nav: HBoxContainer
var coins_label: Label
var shards_label: Label
var selected_biome: int = 0
var active_game: GameWorld = null
var result_data: Dictionary = {}

func _ready() -> void:
    GameState.ensure_daily_state()
    selected_biome = int(GameState.data.get("selected_biome", 0))
    _build_shell()
    _show_home()

func _build_shell() -> void:
    var background := ColorRect.new()
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("10161c")

    shell = Control.new()
    add_child(shell)
    shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var margin := MarginContainer.new()
    shell.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 16)
    margin.add_theme_constant_override("margin_bottom", 12)

    var main := VBoxContainer.new()
    margin.add_child(main)
    main.add_theme_constant_override("separation", 10)

    var header := HBoxContainer.new()
    main.add_child(header)
    header.custom_minimum_size = Vector2(0, 48)
    header.add_theme_constant_override("separation", 7)

    var title := Label.new()
    header.add_child(title)
    title.text = "AXEHOLD\nLAST HEARTH"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 16)

    coins_label = _pill(header, "🪙 0")
    shards_label = _pill(header, "🔥 0")

    var settings := Button.new()
    header.add_child(settings)
    settings.text = "⚙"
    settings.custom_minimum_size = Vector2(44, 40)
    settings.pressed.connect(_show_settings)

    var scroll := ScrollContainer.new()
    main.add_child(scroll)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

    body = VBoxContainer.new()
    scroll.add_child(body)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 10)

    nav = HBoxContainer.new()
    main.add_child(nav)
    nav.custom_minimum_size = Vector2(0, 54)
    nav.add_theme_constant_override("separation", 6)
    _nav_button("🏕", _show_home)
    _nav_button("🗺", _show_map)
    _nav_button("⚒", _show_forge)
    _nav_button("📜", _show_goals)
    _nav_button("🎭", _show_collection)

func _clear_body() -> void:
    for child: Node in body.get_children():
        child.queue_free()
    _refresh_currency()
    nav.visible = true

func _refresh_currency() -> void:
    coins_label.text = "🪙 %d" % int(GameState.data.get("coins", 0))
    shards_label.text = "🔥 %d" % int(GameState.data.get("shards", 0))

func _show_home() -> void:
    _clear_body()

    var hero_panel := _panel(body)
    var hero_box := VBoxContainer.new()
    hero_panel.add_child(hero_box)
    hero_box.add_theme_constant_override("separation", 8)

    var logo := TextureRect.new()
    hero_box.add_child(logo)
    logo.texture = load("res://assets/ui/logo.svg") as Texture2D
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.custom_minimum_size = Vector2(0, 92)

    var chapter := Label.new()
    hero_box.add_child(chapter)
    chapter.text = "ГЛАВА I · ПОСЛЕДНИЙ ОЧАГ"
    chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter.modulate = Color("d7b478")

    var copy := Label.new()
    hero_box.add_child(copy)
    copy.text = "Добывай ресурсы днём, строй оборону и переживи три ночи. В последнюю придёт Хранитель."
    copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    copy.modulate = Color(0.78, 0.80, 0.84)

    var play := _button(hero_box, "▶  НАЧАТЬ ЭКСПЕДИЦИЮ", true)
    play.pressed.connect(_start_game)
    var map_button := _button(hero_box, "🗺  Выбрать биом", false)
    map_button.pressed.connect(_show_map)

    var stats := GridContainer.new()
    body.add_child(stats)
    stats.columns = 2
    stats.add_theme_constant_override("h_separation", 8)
    stats.add_theme_constant_override("v_separation", 8)
    _stat(stats, "Лучший забег", "%d ночей" % int(GameState.data.get("best_wave", 0)))
    _stat(stats, "Победы", str(GameState.data.get("wins", 0)))
    _stat(stats, "Сила героя", str(_hero_power()))
    var camp_level: int = 1 + int(GameState.data.get("shards", 0)) / 2
    _stat(stats, "Лагерь", "Ур. %d" % camp_level)

    var supply := _panel(body)
    var supply_box := VBoxContainer.new()
    supply.add_child(supply_box)
    var supply_text := Label.new()
    supply_box.add_child(supply_text)
    supply_text.text = "📦 Караван припасов\nОдин бонус на текущий день"
    var supply_row := HBoxContainer.new()
    supply_box.add_child(supply_row)
    var free := _button(supply_row, "+25 🪙", false)
    free.disabled = bool(GameState.data.get("supply_claimed", false))
    free.pressed.connect(_claim_supply.bind(false))
    var ad := _button(supply_row, "▶ +60 🪙", false)
    ad.disabled = bool(GameState.data.get("supply_claimed", false))
    ad.pressed.connect(_claim_supply.bind(true))

func _show_map() -> void:
    _clear_body()
    _section("Карта Тьмы", "Каждый биом меняет темп, ресурсы и опасность ночи.")
    var requirements: Array[int] = [0, 1, 3]
    var current_shards: int = int(GameState.data.get("shards", 0))

    for i: int in range(GameRules.BIOMES.size()):
        var biome_data: Dictionary = GameRules.BIOMES[i]
        var unlocked: bool = current_shards >= requirements[i]
        var panel := _panel(body)
        var row := HBoxContainer.new()
        panel.add_child(row)

        var text := Label.new()
        row.add_child(text)
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        var access_text: String = "Доступен" if unlocked else "🔒 Нужно %d 🔥" % requirements[i]
        text.text = "%s\n%s\n%s" % [str(biome_data["name"]), _biome_desc(i), access_text]

        var choose_text: String = "✓" if selected_biome == i else "Выбрать"
        var choose := _button(row, choose_text, selected_biome == i)
        choose.disabled = not unlocked
        choose.pressed.connect(_select_biome.bind(i))

    var selected: Dictionary = GameRules.BIOMES[selected_biome]
    var play := _button(body, "▶ Играть: " + str(selected["name"]), true)
    play.pressed.connect(_start_game)

func _show_forge() -> void:
    _clear_body()
    _section("Кузница героя", "Постоянные улучшения действуют во всех экспедициях.")
    var specs: Array[Dictionary] = [
        {"id": "damage", "title": "⚔️ Закалённые лезвия", "desc": "+10% базового урона"},
        {"id": "hp", "title": "❤️ Крепкое сердце", "desc": "+10 максимального HP"},
        {"id": "bag", "title": "🎒 Большой рюкзак", "desc": "+5 вместимости"},
        {"id": "speed", "title": "👢 Следопыт", "desc": "+4% скорости"}
    ]
    var upgrades: Dictionary = GameState.data["upgrades"]
    for spec: Dictionary in specs:
        var kind: String = str(spec["id"])
        var panel := _panel(body)
        var row := HBoxContainer.new()
        panel.add_child(row)
        var text := Label.new()
        row.add_child(text)
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.text = "%s\n%s\nУр. %d" % [spec["title"], spec["desc"], int(upgrades.get(kind, 0))]
        var buy := _button(row, "%d 🪙" % GameState.upgrade_cost(kind), false)
        buy.pressed.connect(_buy_upgrade.bind(kind))

func _show_goals() -> void:
    GameState.ensure_daily_state()
    _clear_body()
    _section("Задания и трофеи", "Короткие цели дают направление каждому игровому дню.")
    var mission_names: Dictionary = {"trees": "🌲 Лесоруб", "kills": "⚔️ Защитник", "builds": "🔨 Строитель"}
    var missions: Dictionary = GameState.data["missions"]
    for kind: String in ["trees", "kills", "builds"]:
        var mission: Dictionary = missions[kind]
        var panel := _panel(body)
        var row := HBoxContainer.new()
        panel.add_child(row)
        var text := Label.new()
        row.add_child(text)
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.text = "%s\n%d / %d" % [mission_names[kind], int(mission["value"]), int(mission["goal"])]
        var claim_text: String = "Получено" if bool(mission["claimed"]) else "+%d 🪙" % int(mission["reward"])
        var claim := _button(row, claim_text, false)
        claim.disabled = bool(mission["claimed"]) or int(mission["value"]) < int(mission["goal"])
        claim.pressed.connect(_claim_mission.bind(kind))

    var biome_wins: Array = GameState.data["biome_wins"]
    var stats: Dictionary = GameState.data["stats"]
    _trophy("👑 Первый Хранитель", "Победи босса Забытых лесов", int(biome_wins[0]) > 0, "boss", 1, true)
    _trophy("🏰 Архитектор", "Построй 8 сооружений суммарно", int(stats["builds"]) >= 8, "builder", 75, false)
    _trophy("🗡 Охотник", "Уничтожь 75 врагов", int(stats["kills"]) >= 75, "hunter", 90, false)

func _show_collection() -> void:
    _clear_body()
    _section("Коллекция", "Облики не влияют на силу героя.")
    var names: Array[String] = ["🧥 Странник", "🍃 Лесной страж", "❄️ Северный охотник", "🔥 Пепельный рыцарь"]
    var prices: Array[int] = [0, 180, 260, 360]
    var owned: Array = GameState.data["skins_owned"]
    var selected_skin: int = int(GameState.data["selected_skin"])
    for i: int in range(names.size()):
        var panel := _panel(body)
        var row := HBoxContainer.new()
        panel.add_child(row)
        var label := Label.new()
        row.add_child(label)
        label.text = names[i]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var action_text: String
        if selected_skin == i:
            action_text = "Выбран"
        elif bool(owned[i]):
            action_text = "Выбрать"
        else:
            action_text = "%d 🪙" % prices[i]
        var button := _button(row, action_text, selected_skin == i)
        button.disabled = selected_skin == i
        button.pressed.connect(_skin_action.bind(i, prices[i]))

func _show_settings() -> void:
    _clear_body()
    nav.visible = false
    _section("Настройки", "Игровые параметры и доступность.")
    var titles: Dictionary = {"sound": "🔊 Звуки", "haptics": "📳 Тактильная отдача", "hints": "💡 Подсказки"}
    var settings_data: Dictionary = GameState.data["settings"]
    for key: String in ["sound", "haptics", "hints"]:
        var panel := _panel(body)
        var row := HBoxContainer.new()
        panel.add_child(row)
        var label := Label.new()
        row.add_child(label)
        label.text = str(titles[key])
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var toggle := _button(row, "Вкл" if bool(settings_data.get(key, true)) else "Выкл", false)
        toggle.pressed.connect(_toggle_setting.bind(key))

    var tutorial_panel := _panel(body)
    var tutorial_box := VBoxContainer.new()
    tutorial_panel.add_child(tutorial_box)
    var tutorial_copy := Label.new()
    tutorial_box.add_child(tutorial_copy)
    tutorial_copy.text = "Обучение можно пройти заново без сброса прогресса. Следующая экспедиция временно запустится в Забытом лесу на Угрозе I."
    tutorial_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var replay := _button(tutorial_box, "ПОВТОРИТЬ ОБУЧЕНИЕ", false)
    replay.pressed.connect(_restart_tutorial)

    var back := _button(body, "← В лагерь", false)
    back.pressed.connect(_show_home)

func _start_game() -> void:
    GameState.data["selected_biome"] = selected_biome
    GameState.save()
    shell.visible = false
    active_game = GameScene.instantiate() as GameWorld
    var selected_threat: int = GameState.selected_threat()
    var mode: String = str(GameState.data.get("run_mode","expedition"))
    active_game.configure(selected_biome, selected_threat, mode)
    add_child(active_game)
    active_game.run_finished.connect(_on_run_finished)
    active_game.quit_requested.connect(_on_game_quit)

func _on_game_quit() -> void:
    if active_game != null:
        active_game.queue_free()
        active_game = null
    shell.visible = true
    _show_home()

func _on_run_finished(result: Dictionary) -> void:
    result_data = result.duplicate(true)
    if active_game != null:
        active_game.queue_free()
        active_game = null
    shell.visible = true
    _show_result()

func _show_result() -> void:
    _clear_body()
    nav.visible = false
    var panel := _panel(body)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_theme_constant_override("separation", 10)

    var icon := Label.new()
    box.add_child(icon)
    icon.text = "👑" if bool(result_data.get("won", false)) else "🏕️"
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 42)

    var title := Label.new()
    box.add_child(title)
    title.text = "Хранитель повержен" if bool(result_data.get("won", false)) else "Экспедиция окончена"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)

    var stats := Label.new()
    box.add_child(stats)
    stats.text = "Ночь %d · ⚔️ %d\n🪙 %d · 🔥 %d" % [int(result_data.get("wave", 0)), int(result_data.get("kills", 0)), int(result_data.get("coins", 0)), int(result_data.get("shards", 0))]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var claim := _button(box, "Забрать награду", true)
    claim.pressed.connect(_grant_result.bind(1))
    var double := _button(box, "▶ Удвоить монеты", false)
    double.pressed.connect(_double_result)

func _double_result() -> void:
    AdService.rewarded_completed.connect(_on_double_ad, CONNECT_ONE_SHOT)
    AdService.show_rewarded("double_result")

func _on_double_ad(_placement: String) -> void:
    _grant_result(2)

func _grant_result(multiplier: int) -> void:
    if result_data.is_empty():
        return
    GameState.add_coins(int(result_data.get("coins", 0)) * multiplier)
    GameState.add_shards(int(result_data.get("shards", 0)))
    result_data = {}
    nav.visible = true
    _show_home()

func _claim_supply(rewarded: bool) -> void:
    if bool(GameState.data.get("supply_claimed", false)):
        return
    if rewarded:
        AdService.rewarded_completed.connect(_on_supply_ad, CONNECT_ONE_SHOT)
        AdService.show_rewarded("camp_supply")
    else:
        GameState.data["supply_claimed"] = true
        GameState.add_coins(25)
        _show_home()

func _on_supply_ad(_placement: String) -> void:
    GameState.data["supply_claimed"] = true
    GameState.add_coins(60)
    _show_home()

func _select_biome(index: int) -> void:
    selected_biome = index
    GameState.data["selected_biome"] = index
    GameState.save()
    _show_map()

func _buy_upgrade(kind: String) -> void:
    GameState.buy_upgrade(kind)
    _show_forge()

func _claim_mission(kind: String) -> void:
    GameState.claim_mission(kind)
    _show_goals()

func _trophy(title_text: String, description: String, ready: bool, trophy_id: String, reward: int, shard: bool) -> void:
    var claimed: Array = GameState.data["trophies_claimed"]
    var panel := _panel(body)
    var row := HBoxContainer.new()
    panel.add_child(row)
    var label := Label.new()
    row.add_child(label)
    label.text = title_text + "\n" + description
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var reward_text: String
    if claimed.has(trophy_id):
        reward_text = "Получено"
    elif shard:
        reward_text = "+%d 🔥" % reward
    else:
        reward_text = "+%d 🪙" % reward
    var button := _button(row, reward_text, false)
    button.disabled = claimed.has(trophy_id) or not ready
    button.pressed.connect(_claim_trophy.bind(trophy_id, reward, shard))

func _claim_trophy(trophy_id: String, reward: int, shard: bool) -> void:
    var claimed: Array = GameState.data["trophies_claimed"]
    if claimed.has(trophy_id):
        return
    claimed.append(trophy_id)
    GameState.data["trophies_claimed"] = claimed
    if shard:
        GameState.add_shards(reward)
    else:
        GameState.add_coins(reward)
    GameState.save()
    _show_goals()

func _skin_action(index: int, price: int) -> void:
    var owned: Array = GameState.data["skins_owned"]
    if not bool(owned[index]):
        if int(GameState.data["coins"]) < price:
            return
        GameState.data["coins"] = int(GameState.data["coins"]) - price
        owned[index] = true
        GameState.data["skins_owned"] = owned
    GameState.data["selected_skin"] = index
    GameState.save()
    _show_collection()

func _restart_tutorial() -> void:
    GameState.restart_tutorial()
    selected_biome = 0
    _show_home()

func _toggle_setting(key: String) -> void:
    var settings_data: Dictionary = GameState.data["settings"]
    settings_data[key] = not bool(settings_data.get(key, true))
    GameState.data["settings"] = settings_data
    GameState.save()
    _show_settings()

func _hero_power() -> int:
    var upgrades: Dictionary = GameState.data["upgrades"]
    return 100 + int(upgrades["damage"]) * 18 + int(upgrades["hp"]) * 11 + int(upgrades["bag"]) * 5 + int(upgrades["speed"]) * 7

func _biome_desc(index: int) -> String:
    if index == 1:
        return "Быстрые враги и больше камня."
    if index == 2:
        return "Самые тяжёлые волны и богатая руда."
    return "Сбалансированный стартовый биом."

func _section(title_text: String, description: String) -> void:
    var title := Label.new()
    body.add_child(title)
    title.text = title_text
    title.add_theme_font_size_override("font_size", 20)
    var desc := Label.new()
    body.add_child(desc)
    desc.text = description
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.modulate = Color(0.68, 0.72, 0.76)

func _panel(parent: Control) -> PanelContainer:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("1b232b")
    style.border_color = Color("303b46")
    style.set_border_width_all(1)
    style.corner_radius_top_left = 18
    style.corner_radius_top_right = 18
    style.corner_radius_bottom_left = 18
    style.corner_radius_bottom_right = 18
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 14
    style.content_margin_bottom = 14
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _button(parent: Control, text: String, primary: bool) -> Button:
    var button := Button.new()
    parent.add_child(button)
    button.text = text
    button.custom_minimum_size = Vector2(0, 46)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style := StyleBoxFlat.new()
    style.bg_color = Color("2b7c69") if primary else Color("222c35")
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    style.content_margin_left = 12
    style.content_margin_right = 12
    button.add_theme_stylebox_override("normal", style)
    return button

func _pill(parent: Control, text: String) -> Label:
    var panel := PanelContainer.new()
    parent.add_child(panel)
    panel.add_theme_stylebox_override("panel", _pill_style())
    var label := Label.new()
    panel.add_child(label)
    label.text = text
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    return label

func _pill_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("202a33")
    style.corner_radius_top_left = 16
    style.corner_radius_top_right = 16
    style.corner_radius_bottom_left = 16
    style.corner_radius_bottom_right = 16
    style.content_margin_left = 10
    style.content_margin_right = 10
    return style

func _nav_button(icon: String, callback: Callable) -> void:
    var button := Button.new()
    nav.add_child(button)
    button.text = icon
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size = Vector2(0, 50)
    button.pressed.connect(callback)

func _stat(parent: Control, title_text: String, value_text: String) -> void:
    var panel := _panel(parent)
    panel.custom_minimum_size = Vector2(170, 70)
    var box := VBoxContainer.new()
    panel.add_child(box)
    var title := Label.new()
    box.add_child(title)
    title.text = title_text
    title.modulate = Color(0.65, 0.68, 0.72)
    title.add_theme_font_size_override("font_size", 10)
    var value := Label.new()
    box.add_child(value)
    value.text = value_text
    value.add_theme_font_size_override("font_size", 16)
