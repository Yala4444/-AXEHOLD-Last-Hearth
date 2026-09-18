extends Node

const PlayerScene: PackedScene = preload("res://scenes/player.tscn")
const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    await get_tree().process_frame
    _test_mobile_autoloads()
    _test_analog_player_input()
    await _test_joystick_moves_live_player()
    await _test_touch_scroll_container()
    _test_ui_sanitizer()

    if failures.is_empty():
        print("[MOBILE] AXEHOLD v0.9.3 mobile movement validation passed")
        get_tree().quit(0)
        return

    for failure: String in failures:
        push_error("[MOBILE] %s" % failure)
    get_tree().quit(1)

func _test_mobile_autoloads() -> void:
    var controls: Node = get_tree().root.get_node_or_null("MobileControls")
    var sanitizer: Node = get_tree().root.get_node_or_null("UISanitizer")
    var web_runtime: Node = get_tree().root.get_node_or_null("WebRuntime")
    if controls == null:
        _fail("MobileControls autoload is missing")
    else:
        controls.call("force_visible_for_test", true)
        controls.call("simulate_direction_for_test", Vector2(0.65, -0.25))
        var direction_value: Vector2 = controls.get("direction")
        if direction_value.length() <= 0.1:
            _fail("Mobile joystick did not retain simulated direction")
        controls.call("release_test_input")
        controls.call("force_visible_for_test", false)
    if sanitizer == null:
        _fail("UISanitizer autoload is missing")
    if web_runtime == null:
        _fail("WebRuntime autoload is missing")
    if failures.is_empty():
        print("[MOBILE] mobile/web autoloads OK")

func _test_analog_player_input() -> void:
    var player: AxPlayer = PlayerScene.instantiate() as AxPlayer
    if player == null:
        _fail("Cannot instantiate AxPlayer")
        return
    add_child(player)
    player.setup({"damage": 0, "hp": 0, "bag": 0, "speed": 0}, GameRules.skin(0))
    var start: Vector2 = player.global_position
    player.set_move_input(Vector2(0.42, 0.0))
    if not player.direct_control:
        _fail("Player did not enter direct mobile control mode")
    if absf(player.move_input.length() - 0.42) > 0.02:
        _fail("Analog movement magnitude was not preserved")
    player._physics_process(0.10)
    if player.global_position.x <= start.x:
        _fail("AxPlayer direct input did not produce physical movement")
    player.release_move_input()
    if player.direct_control or player.move_input != Vector2.ZERO:
        _fail("Player did not release mobile control cleanly")
    else:
        print("[MOBILE] analog player input and movement OK")
    player.queue_free()

func _test_joystick_moves_live_player() -> void:
    var controls: Node = get_tree().root.get_node_or_null("MobileControls")
    if controls == null:
        return

    var world: GameWorld = GameScene.instantiate() as GameWorld
    if world == null:
        _fail("Cannot instantiate live GameWorld for joystick integration test")
        return
    world.configure(0)
    add_child(world)
    await get_tree().process_frame
    await get_tree().physics_frame

    if world.player == null or not is_instance_valid(world.player):
        _fail("Live GameWorld did not create a player")
        world.queue_free()
        return

    controls.call("bind_world", world)
    controls.call("force_visible_for_test", true)
    var start: Vector2 = world.player.global_position
    controls.call("simulate_direction_for_test", Vector2(1.0, 0.0))

    for _i: int in range(8):
        await get_tree().physics_frame

    var travelled: float = world.player.global_position.distance_to(start)
    if travelled < 4.0:
        _fail("Joystick moved visually but did not move the live GameWorld player")
    elif not world.player.direct_control:
        _fail("Live GameWorld player lost direct-control state while joystick was engaged")
    else:
        print("[MOBILE] joystick-to-GameWorld movement bridge OK, travelled=", travelled)

    controls.call("release_test_input")
    controls.call("force_visible_for_test", false)
    controls.call("unbind_world", world)
    world.queue_free()
    await get_tree().process_frame

func _test_touch_scroll_container() -> void:
    var scroll := MobileScrollContainer.new()
    add_child(scroll)
    scroll.position = Vector2(0, 0)
    scroll.size = Vector2(300, 260)

    var content := Control.new()
    content.custom_minimum_size = Vector2(300, 1100)
    scroll.add_child(content)

    await get_tree().process_frame
    await get_tree().process_frame

    var before: int = scroll.scroll_vertical
    scroll.simulate_drag_for_test(-140.0)
    await get_tree().process_frame

    if scroll.scroll_vertical <= before:
        _fail("Touch-safe menu scroll did not move after an upward drag")
    else:
        print("[MOBILE] touch-safe web menu scrolling OK, offset=", scroll.scroll_vertical)

    scroll.queue_free()
    await get_tree().process_frame

func _test_ui_sanitizer() -> void:
    var sanitizer: Node = get_tree().root.get_node_or_null("UISanitizer")
    if sanitizer == null:
        return
    var sample: String = "🪙 80  🗺  ⚙  🎒 0/20"
    var cleaned: String = str(sanitizer.call("clean_text", sample))
    if cleaned.contains("🪙") or cleaned.contains("🗺") or cleaned.contains("⚙") or cleaned.contains("🎒"):
        _fail("Unsupported UI glyphs survived sanitizer")
    if not cleaned.contains("мон.") or not cleaned.contains("КАРТА"):
        _fail("UI sanitizer did not provide readable replacements")
    else:
        print("[MOBILE] UI glyph sanitizer OK")

func _fail(message: String) -> void:
    failures.append(message)
    print("[MOBILE] FAIL: ", message)
