class_name MobileScrollContainer
extends ScrollContainer

# Godot Web on iOS can deliver menu swipes as pointer/touch events without
# ScrollContainer's native kinetic scrolling taking ownership of the gesture.
# This fallback keeps vertical menus draggable while preserving normal taps.

const DRAG_THRESHOLD := 6.0

var touch_index: int = -1
var touch_drag_distance: float = 0.0
var touch_scrolling: bool = false
var touch_last_position: Vector2 = Vector2.ZERO

var mouse_down: bool = false
var mouse_drag_distance: float = 0.0
var mouse_scrolling: bool = false
var mouse_last_position: Vector2 = Vector2.ZERO

func _ready() -> void:
    horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    vertical_scroll_mode = ScrollContainer.SCROLL_MODE_ALWAYS
    scroll_deadzone = 2
    follow_focus = true
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_PASS
    set_process_input(true)

func _input(event: InputEvent) -> void:
    if not is_visible_in_tree():
        return

    if event is InputEventScreenTouch:
        _handle_touch(event as InputEventScreenTouch)
        return

    if event is InputEventScreenDrag:
        _handle_touch_drag(event as InputEventScreenDrag)
        return

    if event is InputEventMouseButton:
        _handle_mouse_button(event as InputEventMouseButton)
        return

    if event is InputEventMouseMotion:
        _handle_mouse_motion(event as InputEventMouseMotion)

func _handle_touch(event: InputEventScreenTouch) -> void:
    if event.pressed:
        if touch_index < 0 and get_global_rect().has_point(event.position):
            touch_index = event.index
            touch_drag_distance = 0.0
            touch_scrolling = false
            touch_last_position = event.position
            mouse_down = false
            mouse_scrolling = false
    elif event.index == touch_index:
        if touch_scrolling:
            get_viewport().set_input_as_handled()
        touch_index = -1
        touch_drag_distance = 0.0
        touch_scrolling = false

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
    if event.index != touch_index:
        return
    var delta_y: float = event.position.y - touch_last_position.y
    touch_last_position = event.position
    if absf(delta_y) < 0.01:
        delta_y = event.relative.y
    touch_drag_distance += absf(delta_y)
    if touch_drag_distance >= DRAG_THRESHOLD:
        touch_scrolling = true
    if not touch_scrolling:
        return
    _scroll_by(delta_y)
    get_viewport().set_input_as_handled()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
    if event.button_index != MOUSE_BUTTON_LEFT:
        return
    if event.pressed:
        if touch_index >= 0:
            return
        if get_global_rect().has_point(event.position):
            mouse_down = true
            mouse_drag_distance = 0.0
            mouse_scrolling = false
            mouse_last_position = event.position
    elif mouse_down:
        if mouse_scrolling:
            get_viewport().set_input_as_handled()
        mouse_down = false
        mouse_drag_distance = 0.0
        mouse_scrolling = false

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
    if not mouse_down or touch_index >= 0:
        return
    if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
        mouse_down = false
        mouse_drag_distance = 0.0
        mouse_scrolling = false
        return
    var delta_y: float = event.position.y - mouse_last_position.y
    mouse_last_position = event.position
    if absf(delta_y) < 0.01:
        delta_y = event.relative.y
    mouse_drag_distance += absf(delta_y)
    if mouse_drag_distance >= DRAG_THRESHOLD:
        mouse_scrolling = true
    if not mouse_scrolling:
        return
    _scroll_by(delta_y)
    get_viewport().set_input_as_handled()

func _scroll_by(pointer_delta_y: float) -> void:
    var bar: VScrollBar = get_v_scroll_bar()
    if bar == null:
        return
    var max_scroll: int = maxi(0, int(ceil(bar.max_value - bar.page)))
    scroll_vertical = clampi(scroll_vertical - int(round(pointer_delta_y)), 0, max_scroll)

func simulate_drag_for_test(pointer_delta_y: float) -> void:
    _scroll_by(pointer_delta_y)

func can_scroll() -> bool:
    var bar: VScrollBar = get_v_scroll_bar()
    return bar != null and (bar.max_value - bar.page) > 1.0

func jump_to_bottom_for_test() -> void:
    var bar: VScrollBar = get_v_scroll_bar()
    if bar == null:
        return
    scroll_vertical = maxi(0, int(ceil(bar.max_value - bar.page)))
