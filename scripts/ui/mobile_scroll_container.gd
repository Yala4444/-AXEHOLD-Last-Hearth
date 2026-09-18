class_name MobileScrollContainer
extends ScrollContainer

# Godot Web on iOS can deliver menu swipes as pointer/touch events without
# ScrollContainer's native kinetic scrolling taking ownership of the gesture.
# This fallback keeps vertical menus draggable while preserving normal taps.

const DRAG_THRESHOLD := 6.0

var touch_index: int = -1
var touch_drag_distance: float = 0.0
var touch_scrolling: bool = false

var mouse_down: bool = false
var mouse_drag_distance: float = 0.0
var mouse_scrolling: bool = false

func _ready() -> void:
    horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll_deadzone = 3
    follow_focus = true
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
    touch_drag_distance += absf(event.relative.y)
    if touch_drag_distance >= DRAG_THRESHOLD:
        touch_scrolling = true
    if not touch_scrolling:
        return
    _scroll_by(event.relative.y)
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
    mouse_drag_distance += absf(event.relative.y)
    if mouse_drag_distance >= DRAG_THRESHOLD:
        mouse_scrolling = true
    if not mouse_scrolling:
        return
    _scroll_by(event.relative.y)
    get_viewport().set_input_as_handled()

func _scroll_by(pointer_delta_y: float) -> void:
    var bar: VScrollBar = get_v_scroll_bar()
    if bar == null:
        return
    var max_scroll: int = maxi(0, int(ceil(bar.max_value - bar.page)))
    scroll_vertical = clampi(scroll_vertical - int(round(pointer_delta_y)), 0, max_scroll)

func simulate_drag_for_test(pointer_delta_y: float) -> void:
    _scroll_by(pointer_delta_y)
