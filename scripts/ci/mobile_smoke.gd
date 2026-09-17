extends Node

const PlayerScene: PackedScene = preload("res://scenes/player.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    await get_tree().process_frame
    _test_mobile_autoloads()
    _test_analog_player_input()
    _test_ui_sanitizer()

    if failures.is_empty():
        print("[MOBILE] AXEHOLD v0.9.2 mobile web validation passed")
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
    player.setup({"damage": 0, "hp": 0, "bag": 0, "speed": 0}, GameRules.skin(0))
    player.set_move_input(Vector2(0.42, 0.0))
    if not player.direct_control:
        _fail("Player did not enter direct mobile control mode")
    if absf(player.move_input.length() - 0.42) > 0.02:
        _fail("Analog movement magnitude was not preserved")
    player.release_move_input()
    if player.direct_control or player.move_input != Vector2.ZERO:
        _fail("Player did not release mobile control cleanly")
    else:
        print("[MOBILE] analog player input OK")
    player.free()

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
