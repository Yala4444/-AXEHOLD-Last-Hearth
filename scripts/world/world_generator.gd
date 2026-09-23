class_name WorldGenerator
extends Node

var world: GameWorld
var clusters: Dictionary = {"tree": [], "rock": [], "ore": []}
var landmark_nodes: Array[WorldLandmark] = []

func setup(world_ref: GameWorld) -> void:
    world = world_ref
    _create_clusters()
    _spawn_landmarks()

func _create_clusters() -> void:
    clusters = {"tree": [], "rock": [], "ore": []}
    _make_ring_clusters("tree", 9, 230.0, 760.0)
    _make_ring_clusters("rock", 6, 470.0, 1050.0)
    _make_ring_clusters("ore", 5, 760.0, 1450.0)

func _make_ring_clusters(kind: String, count: int, min_radius: float, max_radius: float) -> void:
    var points: Array = clusters[kind]
    for i: int in range(count):
        var base_angle: float = TAU * float(i) / float(count)
        var angle: float = base_angle + randf_range(-0.28, 0.28)
        var radius: float = randf_range(min_radius, max_radius)
        var point: Vector2 = world.base_position + Vector2(cos(angle), sin(angle)) * radius
        point = clamp_to_world(point, 70.0)
        points.append(point)
    clusters[kind] = points

func resource_point(kind: String) -> Vector2:
    var points: Array = clusters.get(kind, [])
    if points.is_empty():
        return activity_point(180.0, 640.0, [])
    var center: Vector2 = points[randi() % points.size()] as Vector2
    var spread: float = 82.0 if kind == "tree" else (68.0 if kind == "rock" else 58.0)
    var angle: float = randf_range(0.0, TAU)
    var radius: float = sqrt(randf()) * spread
    return clamp_to_world(center + Vector2(cos(angle), sin(angle)) * radius, 46.0)

func activity_point(min_radius: float, max_radius: float, occupied: Array) -> Vector2:
    for _attempt in range(90):
        var angle: float = randf_range(0.0, TAU)
        var radius: float = randf_range(min_radius, max_radius)
        var point: Vector2 = clamp_to_world(
            world.base_position + Vector2(cos(angle), sin(angle)) * radius,
            80.0
        )
        if point.distance_to(world.base_position) < min_radius:
            continue
        var blocked: bool = false
        for other_variant: Variant in occupied:
            var other: Vector2 = other_variant as Vector2
            if point.distance_to(other) < 145.0:
                blocked = true
                break
        if not blocked:
            return point
    return clamp_to_world(world.base_position + Vector2(max_radius * 0.72, 0), 80.0)

func clamp_to_world(point: Vector2, margin: float) -> Vector2:
    return Vector2(
        clampf(point.x, world.world_rect.position.x + margin, world.world_rect.end.x - margin),
        clampf(point.y, world.world_rect.position.y + margin, world.world_rect.end.y - margin)
    )

func _spawn_landmarks() -> void:
    var occupied: Array = []
    var count: int = 22 if world.biome_index == 0 and world.visual_v2_enabled else (30 if world.biome_index == 0 else 24)
    var forest_kinds: Array[String] = [
        "root_arch", "stump", "ruin", "fallen_totem", "sign", "bones"
    ]
    var frost_kinds: Array[String] = ["ice", "ruin", "sign", "firepit", "ice"]
    var ash_kinds: Array[String] = ["dead_tree", "bones", "ruin", "firepit", "dead_tree"]

    # Do not replay the same landmark sequence every run. Shuffle a small bag
    # once per world, then reshuffle whenever it is exhausted.
    var kind_bag: Array[String] = []
    for i: int in range(count):
        var point: Vector2 = activity_point(280.0, minf(world.world_size.x, world.world_size.y) * 0.46, occupied)
        occupied.append(point)
        var node := WorldLandmark.new()
        world.add_child(node)
        node.global_position = point

        if kind_bag.is_empty():
            if world.biome_index == 1:
                kind_bag = frost_kinds.duplicate()
            elif world.biome_index == 2:
                kind_bag = ash_kinds.duplicate()
            elif world.visual_v2_enabled:
                # No dead firepits and no ancient-tree/boss-like silhouette in
                # the production Forgotten Forest. Landmarks are atmosphere,
                # never fake objectives.
                kind_bag = forest_kinds.duplicate()
            else:
                kind_bag = [
                    "ancient_tree", "root_arch", "stump", "ruin", "fallen_totem",
                    "sign", "firepit", "bones"
                ]
            kind_bag.shuffle()

        var kind: String = kind_bag.pop_back()
        node.configure(kind, world.biome_index, randi() % 3)
        landmark_nodes.append(node)
