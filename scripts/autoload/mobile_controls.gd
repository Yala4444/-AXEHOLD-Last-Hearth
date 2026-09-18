extends CanvasLayer

const BASE_SIZE := 92.0
const KNOB_SIZE := 42.0
const STICK_RADIUS := 31.0
const DRIFT_START := 43.0
const DRIFT_FACTOR := 0.42
const DEADZONE := 0.10
const TOP_SAFE_Y := 102.0
const EDGE_MARGIN := 48.0

var root: Control
var base_panel: Panel
var inner_panel: Panel
var knob_panel: Panel
var touch_index: int = -1
var direction: Vector2 = Vector2.ZERO
var center: Vector2 = Vector2.ZERO
var world: GameWorld = null
var visible_for_test: bool = false
var test_input_active: bool = false
var fade_tween: Tween = null

func _ready() -> void:
    layer = 90
    _build_visuals()
    get_viewport().size_changed.connect(_on_viewport_changed)

func _build_visuals() -> void:
    root = Control.new()
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.visible = false
    root.modulate.a = 0.0

    base_panel = Panel.new()
    root.add_child(base_panel)
    base_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    base_panel.add_theme_stylebox_override("panel", _circle_style(
        Color(0.035, 0.060, 0.055, 0.48),
        Color(0.82, 0.90, 0.84, 0.34),
        1
    ))

    inner_panel = Panel.new()
    base_panel.add_child(inner_panel)
    inner_panel.position = Vector2(10, 10)
    inner_panel.size = Vector2(BASE_SIZE - 20.0, BASE_SIZE - 20.0)
    inner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inner_panel.add_theme_stylebox_override("panel", _circle_style(
        Color(0.18, 0.31, 0.26, 0.15),
        Color(0.71, 0.83, 0.75, 0.13),
        1
    ))

    knob_panel = Panel.new()
    root.add_child(knob_panel)
    knob_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    knob_panel.size = Vector2(KNOB_SIZE, KNOB_SIZE)
    knob_panel.add_theme_stylebox_override("panel", _circle_style(
        Color(0.41, 0.76, 0.64, 0.88),
        Color(0.94, 0.98, 0.95, 0.66),
        1
    ))

func _circle_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.corner_radius_top_left = 64
    style.corner_radius_top_right = 64
    style.corner_radius_bottom_left = 64
    style.corner_radius_bottom_right = 64
    return style

func _on_viewport_changed() -> void:
    if touch_index >= 0:
        center = _clamp_center(center)
        _layout_stick()

func _process(_delta: float) -> void:
    if world == null or not is_instance_valid(world):
        world = _find_world(get_tree().current_scene)

    if not _controls_allowed():
        if touch_index >= 0 or test_input_active:
            _release_control()
        elif root != null and root.visible and not visible_for_test:
            if fade_tween != null and fade_tween.is_valid():
                fade_tween.kill()
            root.modulate.a = 0.0
            root.visible = false
        return

    if touch_index >= 0 or test_input_active:
        _apply_direction_now()

func _input(event: InputEvent) -> void:
    if not _controls_allowed():
        return

    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if touch_index < 0 and _touch_zone_allowed(touch.position):
                _begin_touch(touch.index, touch.position)
                get_viewport().set_input_as_handled()
        elif touch.index == touch_index:
            _release_control()
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == touch_index:
            _update_direction(drag.position)
            get_viewport().set_input_as_handled()

func _begin_touch(index: int, position: Vector2) -> void:
    touch_index = index
    center = _clamp_center(position)
    direction = Vector2.ZERO
    _layout_stick()
    _show_stick()
    _apply_direction_now()

func _touch_zone_allowed(position: Vector2) -> bool:
    if visible_for_test:
        return true
    if position.y < TOP_SAFE_Y:
        return false
    return _touch_capable_runtime()

func _touch_capable_runtime() -> bool:
    # Safari/Web can report touchscreen availability inconsistently.
    # ScreenTouch events are authoritative, so Web is allowed to start a stick.
    return DisplayServer.is_touchscreen_available() or OS.has_feature("web") or OS.has_feature("mobile")

func _update_direction(position: Vector2) -> void:
    var offset: Vector2 = position - center
    var distance: float = offset.length()

    if distance > DRIFT_START:
        var overshoot: float = distance - DRIFT_START
        center += offset.normalized() * overshoot * DRIFT_FACTOR
        center = _clamp_center(center)
        offset = position - center
        distance = offset.length()

    var raw: Vector2 = offset / STICK_RADIUS
    if raw.length() > 1.0:
        raw = raw.normalized()

    if raw.length() < DEADZONE:
        direction = Vector2.ZERO
    else:
        var scaled: float = inverse_lerp(DEADZONE, 1.0, raw.length())
        direction = raw.normalized() * clampf(scaled, 0.0, 1.0)

    _layout_stick()
    _apply_direction_now()

func _layout_stick() -> void:
    if base_panel == null or knob_panel == null:
        return
    base_panel.position = center - Vector2(BASE_SIZE, BASE_SIZE) * 0.5
    base_panel.size = Vector2(BASE_SIZE, BASE_SIZE)
    var knob_center: Vector2 = center + direction * STICK_RADIUS
    knob_panel.position = knob_center - Vector2(KNOB_SIZE, KNOB_SIZE) * 0.5

func _clamp_center(value: Vector2) -> Vector2:
    var size: Vector2 = get_viewport().get_visible_rect().size
    return Vector2(
        clampf(value.x, EDGE_MARGIN, maxf(EDGE_MARGIN, size.x - EDGE_MARGIN)),
        clampf(value.y, TOP_SAFE_Y + EDGE_MARGIN * 0.45, maxf(TOP_SAFE_Y + EDGE_MARGIN * 0.45, size.y - EDGE_MARGIN))
    )

func _show_stick() -> void:
    if fade_tween != null and fade_tween.is_valid():
        fade_tween.kill()
    root.visible = true
    root.modulate.a = 0.0
    fade_tween = create_tween()
    fade_tween.tween_property(root, "modulate:a", 1.0, 0.07)

func _hide_stick() -> void:
    if visible_for_test:
        root.visible = true
        root.modulate.a = 1.0
        return
    if fade_tween != null and fade_tween.is_valid():
        fade_tween.kill()
    fade_tween = create_tween()
    fade_tween.tween_property(root, "modulate:a", 0.0, 0.12)
    fade_tween.tween_callback(func() -> void:
        if root != null and touch_index < 0 and not test_input_active:
            root.visible = false
    )

func _apply_direction_now() -> void:
    if world == null or not is_instance_valid(world):
        world = _find_world(get_tree().current_scene)
    if world == null or world.player == null or not is_instance_valid(world.player):
        return
    world.player.set_move_input(direction)

func _release_control() -> void:
    touch_index = -1
    test_input_active = false
    direction = Vector2.ZERO
    if world != null and is_instance_valid(world) and world.player != null and is_instance_valid(world.player):
        world.player.release_move_input()
    _layout_stick()
    _hide_stick()

func bind_world(value: GameWorld) -> void:
    if value == null or not is_instance_valid(value):
        return
    world = value
    if direction != Vector2.ZERO and (touch_index >= 0 or test_input_active):
        _apply_direction_now()

func unbind_world(value: GameWorld = null) -> void:
    if value != null and world != value:
        return
    _release_control()
    world = null

func _controls_allowed() -> bool:
    if visible_for_test:
        return true
    if world == null or not is_instance_valid(world):
        return false
    if world.player == null or not is_instance_valid(world.player):
        return false
    if bool(world.get("finishing")) or bool(world.get("paused_local")):
        return false
    if world.hud != null and world.hud.modal_open():
        return false
    return true

func _find_world(node: Node) -> GameWorld:
    if node == null:
        return null
    if node is GameWorld:
        return node as GameWorld
    for child: Node in node.get_children():
        var found: GameWorld = _find_world(child)
        if found != null:
            return found
    return null

func force_visible_for_test(value: bool) -> void:
    visible_for_test = value
    if root == null:
        return
    if value:
        if center == Vector2.ZERO:
            var size: Vector2 = get_viewport().get_visible_rect().size
            center = Vector2(size.x * 0.5, size.y * 0.78)
        _layout_stick()
        root.visible = true
        root.modulate.a = 1.0
    elif touch_index < 0 and not test_input_active:
        root.visible = false

func simulate_direction_for_test(value: Vector2) -> void:
    test_input_active = true
    if center == Vector2.ZERO:
        var size: Vector2 = get_viewport().get_visible_rect().size
        center = Vector2(size.x * 0.5, size.y * 0.78)
    direction = value.limit_length(1.0)
    _layout_stick()
    if root != null:
        root.visible = true
        root.modulate.a = 1.0
    _apply_direction_now()

func simulate_touch_for_test(position: Vector2) -> void:
    _begin_touch(777, position)

func simulate_drag_for_test(position: Vector2) -> void:
    if touch_index < 0:
        simulate_touch_for_test(position)
    _update_direction(position)

func release_test_input() -> void:
    _release_control()
