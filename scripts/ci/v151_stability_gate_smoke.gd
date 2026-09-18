extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")
const AppScene: PackedScene = preload("res://scenes/app.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var settings: Dictionary = GameState.data.get("settings", {})
    settings["hints"] = false
    settings["sound"] = false
    settings["haptics"] = false
    GameState.data["settings"] = settings
    GameState.data["tutorial_complete"] = true
    GameState.data["v1_tutorial_complete"] = true
    GameState.data["coach_complete"] = true

    await _test_segmented_world_backdrop()
    await _test_quest_scroll_and_nav()
    await _test_modal_safe_width()

    if failures.is_empty():
        print("[V1.5.1 STABILITY] segmented backdrop, quest scroll and modal safety passed")
    _finish()

func _test_segmented_world_backdrop() -> void:
    var game: GameWorld = GameScene.instantiate() as GameWorld
    add_child(game)
    game.configure(2)
    await _wait_frames(8)

    if game.backdrop == null:
        _fail("World backdrop missing")
    else:
        if game.backdrop.chunk_count() < 24:
            _fail("Backdrop is not segmented into enough safe chunks")
        var extent: Vector2 = game.backdrop.max_chunk_extent()
        if extent.x > 512.0 or extent.y > 512.0:
            _fail("Backdrop chunks exceed mobile WebGL safety target")

    if game.camera == null:
        _fail("Camera missing for stability route")
    else:
        var corners: Array[Vector2] = [
            Vector2(game.camera.limit_left + 8, game.camera.limit_top + 8),
            Vector2(game.camera.limit_right - 8, game.camera.limit_top + 8),
            Vector2(game.camera.limit_left + 8, game.camera.limit_bottom - 8),
            Vector2(game.camera.limit_right - 8, game.camera.limit_bottom - 8)
        ]
        for point: Vector2 in corners:
            game.player.global_position = point
            await _wait_frames(3)

    for _cycle: int in range(3):
        game.call("_start_night")
        await _wait_frames(3)
        if not game.backdrop.night:
            _fail("Backdrop failed to enter night during stability route")
        game.call("_start_day")
        await _wait_frames(3)
        if game.backdrop.night:
            _fail("Backdrop failed to leave night during stability route")

    game.hud.show_modal("", "ПРОВЕРКА", "Длинный текст модального окна должен оставаться внутри безопасной ширины экрана.", [
        {"text":"ХРАНИТЕЛЬ ОГНЯ — Лечение героя и сильный ремонт Очагa", "action":"close"},
        {"text":"СНАБЖЕНИЕ — +6 к рюкзаку и дополнительные припасы", "action":"close"},
        {"text":"УКРЕПЛЕНИЕ — +70 прочности и ремонт Очагa", "action":"close"}
    ])
    await _wait_frames(2)
    game.hud.hide_modal()

    game.queue_free()
    await _wait_frames(3)

func _test_quest_scroll_and_nav() -> void:
    var app: Control = AppScene.instantiate() as Control
    add_child(app)
    app.size = Vector2(390, 844)
    await _wait_frames(4)
    app.call("_show_goals")
    await _wait_frames(8)

    var scroll: MobileScrollContainer = app.get("mobile_scroll") as MobileScrollContainer
    if scroll == null:
        _fail("Mobile quest scroll container missing")
    else:
        if not scroll.can_scroll():
            _fail("Quest/Trophy screen does not expose scrollable overflow")
        var nav: Control = app.get("nav") as Control
        var nav_y_before: float = nav.global_position.y if nav != null else -1.0

        for _i: int in range(5):
            scroll.simulate_drag_for_test(-180.0)
            await get_tree().process_frame

        var bar: VScrollBar = scroll.get_v_scroll_bar()
        var max_scroll: int = maxi(0, int(ceil(bar.max_value - bar.page))) if bar != null else 0
        if scroll.scroll_vertical <= 0:
            _fail("Quest screen did not move after repeated mobile swipes")
        scroll.jump_to_bottom_for_test()
        await get_tree().process_frame
        if max_scroll > 0 and abs(scroll.scroll_vertical - max_scroll) > 2:
            _fail("Last quest/achievement cannot be reached")
        if nav != null and absf(nav.global_position.y - nav_y_before) > 1.0:
            _fail("Bottom navigation moved with quest scroll")

    app.queue_free()
    await _wait_frames(3)

func _test_modal_safe_width() -> void:
    var game: GameWorld = GameScene.instantiate() as GameWorld
    add_child(game)
    game.configure(0)
    await _wait_frames(5)
    game.hud.show_modal("", "Рассвет после ночи 1", "Выбери один из трёх курсов. Текст должен переноситься внутри safe area.", [
        {"text":"ХРАНИТЕЛЬ ОГНЯ — Лечение героя и сильный ремонт Очагa", "action":"close"},
        {"text":"СНАБЖЕНИЕ — +6 к рюкзаку и припасы", "action":"close"},
        {"text":"УКРЕПЛЕНИЕ — +70 прочности и ремонт Очагa", "action":"close"}
    ])
    await _wait_frames(3)

    if game.hud.modal_panel == null:
        _fail("Modal panel missing")
    else:
        var viewport_w: float = game.get_viewport_rect().size.x
        if game.hud.modal_panel.size.x > viewport_w - 18.0:
            _fail("Modal exceeds safe mobile width")

    for child: Node in game.hud.modal_box.get_children():
        if child is Button:
            var button := child as Button
            if button.autowrap_mode == TextServer.AUTOWRAP_OFF:
                _fail("Doctrine button wrapping is disabled")
            if button.size.x > game.hud.modal_panel.size.x:
                _fail("Doctrine button exceeds modal width")

    game.queue_free()
    await _wait_frames(3)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.5.1 STABILITY] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.5.1 STABILITY] %s" % failure)
    get_tree().quit(1)
