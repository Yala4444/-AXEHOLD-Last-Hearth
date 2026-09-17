extends Control

const GameScene := preload("res://scenes/game.tscn")

var shell: Control
var body: VBoxContainer
var nav: HBoxContainer
var coins_label: Label
var shards_label: Label
var selected_biome := 0
var active_game: GameWorld
var result_data: Dictionary = {}

func _ready() -> void:
    GameState.ensure_daily_state()
    selected_biome = int(GameState.data.get("selected_biome", 0))
    _build_shell()
    _show_home()

func _build_shell() -> void:
    var bg := ColorRect.new()
    add_child(bg)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color("10161c")

    shell = Control.new()
    add_child(shell)
    shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var margin := MarginContainer.new()
    shell.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 14)
    margin.add_theme_constant_override("margin_right", 14)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 14)

    var main := VBoxContainer.new()
    margin.add_child(main)
    main.add_theme_constant_override("separation", 10)

    var header := HBoxContainer.new()
    main.add_child(header)
    header.custom_minimum_size = Vector2(0, 48)
    var title := Label.new()
    title.text = "AXEHOLD\nLAST HEARTH"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 16)
    header.add_child(title)
    coins_label = _pill(header, "🪙 0")
    shards_label = _pill(header, "🔥 0")
    var settings := Button.new()
    settings.text = "⚙"
    settings.custom_minimum_size = Vector2(44, 40)
    settings.pressed.connect(_show_settings)
    header.add_child(settings)

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
    for child in body.get_children():
        child.queue_free()
    _refresh_currency()

func _refresh_currency() -> void:
    if coins_label != null:
        coins_label.text = "🪙 %d" % int(GameState.data.get("coins", 0))
    if shards_label != null:
        shards_label.text = "🔥 %d" % int(GameState.data.get("shards", 0))

func _show_home() -> void:
    _clear_body()
    var hero := _panel(body)
    var hero_box := VBoxContainer.new()
    hero.add_child(hero_box)
    hero_box.add_theme_constant_override("separation", 8)
    var logo := TextureRect.new()
    logo.texture = load("res://assets/ui/logo.svg") as Texture2D
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.custom_minimum_size = Vector2(0, 95)
    hero_box.add_child(logo)
    var chapter := Label.new()
    chapter.text = "ГЛАВА I · ПОСЛЕДНИЙ ОЧАГ"
    chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter.modulate = Color("d7b478")
    hero_box.add_child(chapter)
    var copy := Label.new()
    copy.text = "Днём добывай ресурсы и строй оборону. Ночью защищай Очаг. Третья ночь приведёт Хранителя."
    copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    copy.modulate = Color(0.78,0.80,0.84)
    hero_box.add_child(copy)
    var play := _button(hero_box, "▶  НАЧАТЬ ЭКСПЕДИЦИЮ", true)
    play.pressed.connect(_start_game)
    var map := _button(hero_box, "🗺  Выбрать биом", false)
    map.pressed.connect(_show_map)

    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    body.add_child(grid)
    _stat(grid, "Лучший забег", "%d ночей" % int(GameState.data.get("best_wave",0)))
    _stat(grid, "Победы", str(GameState.data.get("wins",0)))
    _stat(grid, "Сила героя", str(_hero_power()))
    _stat(grid, "Лагерь", "Ур. %d" % (1 + int(GameState.data.get("shards",0)) / 2))

    var supply := _panel(body)
    var sb := VBoxContainer.new()
    supply.add_child(sb)
    var sl := Label.new()
    sl.text = "📦 Караван припасов\nОдин бонус на текущий день"
    sb.add_child(sl)
    var row := HBoxContainer.new()
    sb.add_child(row)
    var free := _button(row, "+25 🪙", false)
    free.disabled = bool(GameState.data.get("supply_claimed", false))
    free.pressed.connect(_claim_supply.bind(false))
    var ad := _button(row, "▶ +60 🪙", false)
    ad.disabled = bool(GameState.data.get("supply_claimed", false))
    ad.pressed.connect(_claim_supply.bind(true))

func _show_map() -> void:
    _clear_body()
    _section("Карта Тьмы", "Каждый биом меняет темп, ресурсы и опасность ночи.")
    var requirements := [0, 1, 3]
    for i in range(GameRules.BIOMES.size()):
        var b: Dictionary = GameRules.BIOMES[i]
        var unlocked := int(GameState.data.get("shards",0)) >= requirements[i]
        var p := _panel(body)
        var row := HBoxContainer.new()
        p.add_child(row)
        var text := Label.new()
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        text.text = "%s\n%s\n%s" % [str(b["name"]), _biome_desc(i), "Доступен" if unlocked else "🔒 Нужно %d 🔥" % requirements[i]]
        row.add_child(text)
        var choose := _button(row, "✓" if selected_biome == i else "Выбрать", selected_biome == i)
        choose.disabled = not unlocked
        choose.pressed.connect(_select_biome.bind(i))
    var play := _button(body, "▶ Играть: " + str(GameRules.BIOMES[selected_biome]["name"]), true)
    play.pressed.connect(_start_game)

func _show_forge() -> void:
    _clear_body()
    _section("Кузница героя", "Постоянные улучшения действуют во всех экспедициях.")
    var specs := [
        ["damage","⚔️ Закалённые лезвия","+10% базового урона"],
        ["hp","❤️ Крепкое сердце","+10 максимального HP"],
        ["bag","🎒 Большой рюкзак","+5 вместимости"],
        ["speed","👢 Следопыт","+4% скорости"]
    ]
    for spec in specs:
        var kind := str(spec[0])
        var p := _panel(body)
        var row := HBoxContainer.new()
        p.add_child(row)
        var text := Label.new()
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.text = "%s\n%s\nУр. %d" % [spec[1], spec[2], int(GameState.data["upgrades"].get(kind,0))]
        row.add_child(text)
        var buy := _button(row, "%d 🪙" % GameState.upgrade_cost(kind), false)
        buy.pressed.connect(_buy_upgrade.bind(kind))

func _show_goals() -> void:
    GameState.ensure_daily_state()
    _clear_body()
    _section("Задания и трофеи", "Короткие цели дают направление каждому игровому дню.")
    for kind in ["trees","kills","builds"]:
        var m: Dictionary = GameState.data["missions"][kind]
        var names := {"trees":"🌲 Лесоруб","kills":"⚔️ Защитник","builds":"🔨 Строитель"}
        var p := _panel(body)
        var row := HBoxContainer.new()
        p.add_child(row)
        var text := Label.new()
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        text.text = "%s\n%d / %d" % [names[kind], int(m["value"]), int(m["goal"])]
        row.add_child(text)
        var claim := _button(row, "Получено" if bool(m["claimed"]) else "+%d 🪙" % int(m["reward"]), false)
        claim.disabled = bool(m["claimed"]) or int(m["value"]) < int(m["goal"])
        claim.pressed.connect(_claim_mission.bind(kind))
    _trophy("👑 Первый Хранитель", "Победи босса Забытых лесов", int(GameState.data["biome_wins"][0]) > 0, "boss", 1, true)
    _trophy("🏰 Архитектор", "Построй 8 сооружений суммарно", int(GameState.data["stats"]["builds"]) >= 8, "builder", 75, false)
    _trophy("🗡 Охотник", "Уничтожь 75 врагов", int(GameState.data["stats"]["kills"]) >= 75, "hunter", 90, false)

func _show_collection() -> void:
    _clear_body()
    _section("Коллекция", "Облики не влияют на силу героя.")
    var names := ["🧥 Странник","🍃 Лесной страж","❄️ Северный охотник","🔥 Пепельный рыцарь"]
    var prices := [0,180,260,360]
    var owned: Array = GameState.data["skins_owned"]
    for i in range(names.size()):
        var p := _panel(body)
        var row := HBoxContainer.new()
        p.add_child(row)
        var label := Label.new()
        label.text = names[i]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var text := "Выбран" if int(GameState.data["selected_skin"]) == i else ("Выбрать" if bool(owned[i]) else "%d 🪙" % prices[i])
        var button := _button(row, text, int(GameState.data["selected_skin"]) == i)
        button.disabled = int(GameState.data["selected_skin"]) == i
        button.pressed.connect(_skin_action.bind(i, prices[i]))

func _show_settings() -> void:
    _clear_body()
    _section("Настройки", "Игровые параметры и доступность.")
    for key in ["sound","haptics","hints"]:
        var titles := {"sound":"🔊 Звуки","haptics":"📳 Тактильная отдача","hints":"💡 Подсказки"}
        var p := _panel(body)
        var row := HBoxContainer.new()
        p.add_child(row)
        var label := Label.new()
        label.text = titles[key]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(label)
        var toggle := _button(row, "Вкл" if bool(GameState.data["settings"].get(key,true)) else "Выкл", false)
        toggle.pressed.connect(_toggle_setting.bind(key))
    var back := _button(body, "← В лагерь", false)
    back.pressed.connect(_show_home)

func _start_game() -> void:
    GameState.data["selected_biome"] = selected_biome
    GameState.save()
    shell.visible = false
    active_game = GameScene.instantiate() as GameWorld
    active_game.configure(selected_biome)
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
    var p := _panel(body)
    var box := VBoxContainer.new()
    p.add_child(box)
    var icon := Label.new()
    icon.text = "👑" if bool(result_data.get("won",false)) else "🏕️"
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 42)
    box.add_child(icon)
    var title := Label.new()
    title.text = "Хранитель повержен" if bool(result_data.get("won",false)) else "Экспедиция окончена"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    box.add_child(title)
    var stats := Label.new()
    stats.text = "Ночь %d · ⚔️ %d\n🪙 %d · 🔥 %d" % [int(result_data.get("wave",0)),int(result_data.get("kills",0)),int(result_data.get("coins",0)),int(result_data.get("shards",0))]
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(stats)
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
    GameState.add_coins(int(result_data.get("coins",0)) * multiplier)
    GameState.add_shards(int(result_data.get("shards",0)))
    result_data = {}
    nav.visible = true
    _show_home()

func _claim_supply(rewarded: bool) -> void:
    if bool(GameState.data.get("supply_claimed",false)):
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

func _trophy(title_text: String, desc: String, ready: bool, trophy_id: String, reward: int, shard: bool) -> void:
    var claimed: Array = GameState.data["trophies_claimed"]
    var p := _panel(body)
    var row := HBoxContainer.new()
    p.add_child(row)
    var label := Label.new()
    label.text = title_text + "\n" + desc
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    row.add_child(label)
    var button := _button(row, "Получено" if claimed.has(trophy_id) else ("+%d 🔥" % reward if shard else "+%d 🪙" % reward), false)
    button.disabled = claimed.has(trophy_id) or not ready
    button.pressed.connect(_claim_trophy.bind(trophy_id, reward, shard))

func _claim_trophy(trophy_id: String, reward: int, shard: bool) -> void:
    var claimed: Array = GameState.data["trophies_claimed"]
    if claimed.has(trophy_id): return
    claimed.append(trophy_id)
    GameState.data["trophies_claimed"] = claimed
    if shard: GameState.add_shards(reward)
    else: GameState.add_coins(reward)
    GameState.save()
    _show_goals()

func _skin_action(index: int, price: int) -> void:
    var owned: Array = GameState.data["skins_owned"]
    if not bool(owned[index]):
        if int(GameState.data["coins"]) < price: return
        GameState.data["coins"] = int(GameState.data["coins"]) - price
        owned[index] = true
        GameState.data["skins_owned"] = owned
    GameState.data["selected_skin"] = index
    GameState.save()
    _show_collection()

func _toggle_setting(key: String) -> void:
    GameState.data["settings"][key] = not bool(GameState.data["settings"].get(key,true))
    GameState.save()
    _show_settings()

func _hero_power() -> int:
    var u: Dictionary = GameState.data["upgrades"]
    return 100 + int(u["damage"])*18 + int(u["hp"])*11 + int(u["bag"])*5 + int(u["speed"])*7

func _biome_desc(index: int) -> String:
    if index == 1: return "Быстрые враги и больше камня."
    if index == 2: return "Самые тяжёлые волны и богатая руда."
    return "Сбалансированный стартовый биом."

func _section(title_text: String, desc_text: String) -> void:
    var title := Label.new()
    title.text = title_text
    title.add_theme_font_size_override("font_size", 20)
    body.add_child(title)
    var desc := Label.new()
    desc.text = desc_text
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.modulate = Color(0.68,0.72,0.76)
    body.add_child(desc)

func _panel(parent: Control) -> PanelContainer:
    var p := PanelContainer.new()
    parent.add_child(p)
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
    p.add_theme_stylebox_override("panel", style)
    return p

func _button(parent: Control, text: String, primary: bool) -> Button:
    var b := Button.new()
    parent.add_child(b)
    b.text = text
    b.custom_minimum_size = Vector2(0, 46)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style := StyleBoxFlat.new()
    style.bg_color = Color("2b7c69") if primary else Color("222c35")
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    style.content_margin_left = 12
    style.content_margin_right = 12
    b.add_theme_stylebox_override("normal", style)
    return b

func _pill(parent: Control, text: String) -> Label:
    var p := PanelContainer.new()
    parent.add_child(p)
    p.add_theme_stylebox_override("panel", _pill_style())
    var l := Label.new()
    p.add_child(l)
    l.text = text
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    return l

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
    var b := Button.new()
    nav.add_child(b)
    b.text = icon
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.custom_minimum_size = Vector2(0, 50)
    b.pressed.connect(callback)

func _stat(parent: Control, title_text: String, value_text: String) -> void:
    var p := _panel(parent)
    p.custom_minimum_size = Vector2(170, 70)
    var box := VBoxContainer.new()
    p.add_child(box)
    var title := Label.new()
    title.text = title_text
    title.modulate = Color(0.65,0.68,0.72)
    title.add_theme_font_size_override("font_size", 10)
    box.add_child(title)
    var value := Label.new()
    value.text = value_text
    value.add_theme_font_size_override("font_size", 16)
    box.add_child(value)
