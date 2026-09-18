extends CanvasLayer

const BASE_SIZE := 94.0
const KNOB_SIZE := 44.0
const STICK_RADIUS := 30.0
const DEADZONE := 0.12

var root: Control
var base_panel: Panel
var knob_panel: Panel
var hint_label: Label
var touch_index: int = -1
var direction: Vector2 = Vector2.ZERO
var center: Vector2 = Vector2.ZERO
var world: GameWorld = null
var visible_for_test: bool = false
var scan_timer: float = 0.0
var test_input_active: bool = false

func _ready() -> void:
    layer = 90
    _build_visuals()
    get_viewport().size_changed.connect(_layout)
    _layout()

func _build_visuals() -> void:
    root = Control.new()
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE

    base_panel = Panel.new()
    root.add_child(base_panel)
    base_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    base_panel.add_theme_stylebox_override("panel", _circle_style(Color(0.04, 0.07, 0.07, 0.34), Color(0.76, 0.86, 0.80, 0.28), 1))

    var inner := Panel.new()
    base_panel.add_child(inner)
    inner.position = Vector2(11, 11)
    inner.size = Vector2(BASE_SIZE - 22.0, BASE_SIZE - 22.0)
    inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inner.add_theme_stylebox_override("panel", _circle_style(Color(0.18, 0.31, 0.27, 0.12), Color(0.63, 0.80, 0.70, 0.12), 1))

    knob_panel = Panel.new()
    root.add_child(knob_panel)
    knob_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    knob_panel.add_theme_stylebox_override("panel", _circle_style(Color(0.38, 0.72, 0.62, 0.82), Color(0.92, 0.97, 0.94, 0.62), 1))

    hint_label = Label.new()
    root.add_child(hint_label)
    hint_label.text = ""
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.add_theme_font_size_override("font_size", 1)
    hint_label.add_theme_color_override("font_color", Color(0.88, 0.93, 0.90, 0.72))
    hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

    root.visible = false

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

func _layout() -> void:
    if root == null:
        return
    var size: Vector2 = get_viewport().get_visible_rect().size
    center = Vector2(61.0, maxf(130.0, size.y - 112.0))
    base_panel.position = center - Vector2(BASE_SIZE, BASE_SIZE) * 0.5
    base_panel.size = Vector2(BASE_SIZE, BASE_SIZE)
    knob_panel.size = Vector2(KNOB_SIZE, KNOB_SIZE)
    _move_knob(direction)
    hint_label.position = Vector2(center.x - 1.0, center.y + 1.0)
    hint_label.size = Vector2(1.0, 1.0)

func _process(delta: float) -> void:
    scan_timer -= delta
    if scan_timer <= 0.0:
        scan_timer = 0.18
        if world == null or not is_instance_valid(world):
            world = _find_world(get_tree().current_scene)

    var should_show: bool = visible_for_test or (_touch_device() and _controls_allowed())
    if root != null:
        root.visible = should_show

    if not should_show:
        if touch_index >= 0 or direction != Vector2.ZERO or test_input_active:
            _release_control()
        return

    if touch_index >= 0 or test_input_active:
        _apply_direction_now()

func _input(event: InputEvent) -> void:
    if root == null or not root.visible:
        return

    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        if touch.pressed:
            if touch_index < 0 and touch.position.distance_to(center) <= BASE_SIZE * 0.66:
                touch_index = touch.index
                _update_direction(touch.position)
                get_viewport().set_input_as_handled()
        elif touch.index == touch_index:
            _release_control()
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        if drag.index == touch_index:
            _update_direction(drag.position)
            get_viewport().set_input_as_handled()

func _update_direction(position: Vector2) -> void:
    var offset: Vector2 = position - center
    var raw: Vector2 = offset / STICK_RADIUS
    if raw.length() > 1.0:
        raw = raw.normalized()
    if raw.length() < DEADZONE:
        direction = Vector2.ZERO
    else:
        var scaled: float = inverse_lerp(DEADZONE, 1.0, raw.length())
        direction = raw.normalized() * clampf(scaled, 0.0, 1.0)
    _move_knob(direction)
    _apply_direction_now()

func _apply_direction_now() -> void:
    if world == null or not is_instance_valid(world):
        world = _find_world(get_tree().current_scene)
    if world == null or not is_instance_valid(world):
        return
    if world.player == null or not is_instance_valid(world.player):
        return
    world.player.set_move_input(direction)

func _move_knob(value: Vector2) -> void:
    if knob_panel == null:
        return
    var knob_center: Vector2 = center + value * STICK_RADIUS
    knob_panel.position = knob_center - Vector2(KNOB_SIZE, KNOB_SIZE) * 0.5

func _release_control() -> void:
    touch_index = -1
    test_input_active = false
    direction = Vector2.ZERO
    _move_knob(direction)
    if world != null and is_instance_valid(world) and world.player != null and is_instance_valid(world.player):
        world.player.release_move_input()

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

func _touch_device() -> bool:
    return DisplayServer.is_touchscreen_available()

func _controls_allowed() -> bool:
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
    if root != null:
        root.visible = value

func simulate_direction_for_test(value: Vector2) -> void:
    test_input_active = true
    direction = value.limit_length(1.0)
    _move_knob(direction)
    _apply_direction_now()

func release_test_input() -> void:
    _release_control()
