extends CanvasLayer

const BUILD_LABEL := "v0.9.2"

var version_label: Label
var scan_timer: float = 0.0
var active_world: GameWorld = null

func _ready() -> void:
    layer = 96
    version_label = Label.new()
    add_child(version_label)
    version_label.text = BUILD_LABEL
    version_label.position = Vector2(318, 124)
    version_label.size = Vector2(64, 18)
    version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    version_label.add_theme_font_size_override("font_size", 8)
    version_label.add_theme_color_override("font_color", Color(0.12, 0.18, 0.16, 0.58))
    version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
    scan_timer -= delta
    if scan_timer <= 0.0:
        scan_timer = 0.12
        active_world = _find_world(get_tree().current_scene)

    var mobile_controls: Node = get_tree().root.get_node_or_null("MobileControls")
    if mobile_controls != null:
        var should_force: bool = OS.has_feature("web") and active_world != null and is_instance_valid(active_world)
        mobile_controls.call("force_visible_for_test", should_force)

    if version_label != null:
        version_label.visible = OS.has_feature("web")

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
