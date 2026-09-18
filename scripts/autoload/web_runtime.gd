extends CanvasLayer

var scan_timer: float = 0.0
var active_world: GameWorld = null
var last_bound_world: GameWorld = null

func _ready() -> void:
    layer = 96

func _process(delta: float) -> void:
    scan_timer -= delta
    if scan_timer <= 0.0:
        scan_timer = 0.10
        active_world = _find_world(get_tree().current_scene)

    var mobile_controls: Node = get_tree().root.get_node_or_null("MobileControls")
    if mobile_controls != null:
        var has_world: bool = active_world != null and is_instance_valid(active_world)
        if has_world:
            if last_bound_world != active_world:
                mobile_controls.call("bind_world", active_world)
                last_bound_world = active_world
        elif last_bound_world != null:
            mobile_controls.call("unbind_world", last_bound_world)
            last_bound_world = null


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
