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
    var count: int = 30 if world.biome_index == 0 else 24
    for i: int in range(count):
        var point: Vector2 = activity_point(250.0, minf(world.world_size.x, world.world_size.y) * 0.46, occupied)
        occupied.append(point)
        var node := WorldLandmark.new()
        world.add_child(node)
        node.global_position = point
        var kind: String
        if world.biome_index == 1:
            var frost_kinds: Array[String] = ["ice", "ruin", "sign", "firepit", "ice"]
            kind = frost_kinds[i % frost_kinds.size()]
        elif world.biome_index == 2:
            var ash_kinds: Array[String] = ["dead_tree", "bones", "ruin", "firepit", "dead_tree"]
            kind = ash_kinds[i % ash_kinds.size()]
        else:
            var forest_kinds: Array[String]
            if world.visual_v2_enabled:
                # The old ancient sentinel silhouette is too close to the
                # actual Forest Guardian boss. Never place it as scenery in the
                # production-look preview.
                forest_kinds = [
                    "root_arch", "stump", "ruin", "fallen_totem",
                    "sign", "firepit", "bones"
                ]
            else:
                forest_kinds = [
                    "ancient_tree", "root_arch", "stump", "ruin", "fallen_totem",
                    "sign", "firepit", "bones"
                ]
            kind = forest_kinds[i % forest_kinds.size()]
        node.configure(kind, world.biome_index, i % 3)
        landmark_nodes.append(node)
