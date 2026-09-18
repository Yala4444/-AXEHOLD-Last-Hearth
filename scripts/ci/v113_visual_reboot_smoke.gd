extends Node

const AppScene: PackedScene = preload("res://scenes/app.tscn")
const CampScene: PackedScene = preload("res://scenes/camp_view.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings

    _test_icons()
    await _test_shell()
    await _test_hud()
    await _test_views()
    await _test_character_silhouettes()

    if failures.is_empty():
        print("[V1.13 VISUAL] shell, HUD, views, icons and entity silhouettes passed")
    _finish()

func _test_icons() -> void:
    for kind: String in ["coin","shard","settings","camp","arsenal","map","trophy","heart","hearth","pause","quest","contract","forge"]:
        var icon := UiIcon.new()
        add_child(icon)
        icon.configure(kind, VisualSystem.GOLD, 0.8)
        if icon.custom_minimum_size.x < 12.0:
            _fail("UI icon collapsed: " + kind)
        icon.queue_free()

func _test_shell() -> void:
    var app: Node = AppScene.instantiate()
    add_child(app)
    await _wait_frames(5)

    var nav_variant: Variant = app.get("nav_buttons")
    if not (nav_variant is Dictionary):
        _fail("Visual reboot navigation dictionary missing")
    else:
        var nav_buttons: Dictionary = nav_variant
        if nav_buttons.size() != 4:
            _fail("Bottom navigation should contain exactly four primary destinations")
        for key: String in ["camp","arsenal","map","trophy"]:
            if not nav_buttons.has(key):
                _fail("Primary navigation missing: " + key)

    var coins: Variant = app.get("coins_label")
    if not (coins is Label):
        _fail("Compact coin chip label missing")
    elif str((coins as Label).text).contains("МОН"):
        _fail("Currency header still relies on abbreviation text instead of icon")

    app.queue_free()
    await _wait_frames(3)

func _test_hud() -> void:
    var hud := GameHud.new()
    add_child(hud)
    await _wait_frames(3)
    if hud.hp_bar == null or hud.base_bar == null:
        _fail("Reboot HUD is missing hero/Hearth visual bars")
    if hud.root == null or hud.root.get_node_or_null("PauseButton") == null:
        _fail("Reboot HUD pause control missing")
    hud.update_stats(80.0, 220.0, 8, 24, 1, "day", 35.0, 4, 16, 1, {"wood":4,"stone":2,"ore":1,"parts":0}, 0, {"wood":5,"stone":2,"ore":1})
    if hud.hp_label.text != "80":
        _fail("Hero HUD should show a compact numeric HP value")
    hud.queue_free()
    await _wait_frames(2)

func _test_views() -> void:
    var camp: CampView = CampScene.instantiate() as CampView
    add_child(camp)
    camp.size = Vector2(360, 392)
    await _wait_frames(3)
    for key: String in ["forge","arsenal","goals","quests","contracts","chronicle","map"]:
        var button: Button = camp.action_buttons.get(key) as Button
        if button == null:
            _fail("Camp hotspot missing after reboot: " + key)
        elif button.size.x > 36.0 or button.size.y > 36.0:
            _fail("Camp hotspot remained a large floating text card: " + key)
    camp.queue_free()

    var map_view := WorldMapView.new()
    add_child(map_view)
    map_view.size = Vector2(360, 430)
    map_view.configure(0)
    await _wait_frames(2)
    if map_view.node_buttons.size() != 3:
        _fail("Route map lost biome nodes")
    else:
        for button: Button in map_view.node_buttons:
            if button.size.x > 120.0 or button.size.y > 48.0:
                _fail("Map callout is still too card-heavy")
    map_view.queue_free()

    var preview := WeaponPreview.new()
    add_child(preview)
    preview.custom_minimum_size = Vector2(74, 66)
    preview.size = Vector2(74, 66)
    preview.configure("spear")
    await _wait_frames(2)
    if preview.size.x > 80.0 or preview.size.y > 72.0:
        _fail("Weapon preview cannot collapse into compact Arsenal row")
    preview.queue_free()

    var hall := TrophyHallView.new()
    add_child(hall)
    hall.size = Vector2(360, 250)
    await _wait_frames(2)
    if hall.custom_minimum_size.y < 240.0:
        _fail("Trophy hall collapsed below physical presentation target")
    hall.queue_free()
    await _wait_frames(2)

func _test_character_silhouettes() -> void:
    var player := AxPlayer.new()
    add_child(player)
    player.setup(GameState.data.get("upgrades", {}), GameRules.skin(int(GameState.data.get("selected_skin", 0))))
    player.queue_redraw()

    for kind: String in ["normal","runner","brute","stalker","guardian"]:
        var enemy := AxEnemy.new()
        add_child(enemy)
        enemy.configure(kind, 1.0, 1, Color("765f78"), false, 0)
        if enemy.max_hp <= 0.0:
            _fail("Enemy silhouette configuration failed: " + kind)
        enemy.queue_redraw()
        enemy.queue_free()

    for biome_index: int in range(3):
        var boss := AxEnemy.new()
        add_child(boss)
        boss.configure("boss", 1.0, 3, Color("765f78"), true, biome_index)
        if not boss.boss or boss.biome_index != biome_index:
            _fail("Biome boss visual identity configuration failed")
        boss.queue_redraw()
        boss.queue_free()

    player.queue_free()
    await _wait_frames(3)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.13 VISUAL] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.13 VISUAL] %s" % failure)
    get_tree().quit(1)
