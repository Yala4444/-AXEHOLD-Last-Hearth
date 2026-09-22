class_name WorldBackdrop
extends Node2D

const CHUNK_SIZE := Vector2(420.0, 420.0)
const SAFETY_PAD := 520.0

var world_size: Vector2 = Vector2(1450, 3200)
var base_position: Vector2 = Vector2.ZERO
var biome: Dictionary = {}
var biome_index: int = 0
var night: bool = false
var chunks: Array[WorldBackdropChunk] = []
var visual_identity_version: int = 2
var visual_gate_enabled: bool = false

func setup(size: Vector2, hearth: Vector2, biome_data: Dictionary, index: int) -> void:
    world_size = size
    base_position = hearth
    biome = biome_data.duplicate(true)
    biome_index = index
    z_index = -20
    _rebuild_chunks()

func set_visual_gate(value: bool) -> void:
    if visual_gate_enabled == value:
        return
    visual_gate_enabled = value
    for chunk: WorldBackdropChunk in chunks:
        if is_instance_valid(chunk):
            chunk.set_visual_gate(value)

func set_night(value: bool) -> void:
    if night == value:
        return
    night = value
    for chunk: WorldBackdropChunk in chunks:
        if is_instance_valid(chunk):
            chunk.set_night(value)

func chunk_count() -> int:
    return chunks.size()

func max_chunk_extent() -> Vector2:
    return CHUNK_SIZE

func visual_identity_profile() -> Dictionary:
    return {
        "version":visual_identity_version,
        "biome":biome_index,
        "chunk_count":chunks.size(),
        "landmark_language":"folk_ruins",
        "day_night_blend":true
    }

func _rebuild_chunks() -> void:
    for child: Node in get_children():
        child.queue_free()
    chunks.clear()

    var start_x: float = -SAFETY_PAD
    var start_y: float = -SAFETY_PAD
    var end_x: float = world_size.x + SAFETY_PAD
    var end_y: float = world_size.y + SAFETY_PAD

    var y: float = start_y
    while y < end_y:
        var x: float = start_x
        while x < end_x:
            var rect := Rect2(
                Vector2(x, y),
                Vector2(
                    minf(CHUNK_SIZE.x, end_x - x),
                    minf(CHUNK_SIZE.y, end_y - y)
                )
            )
            var chunk := WorldBackdropChunk.new()
            add_child(chunk)
            chunks.append(chunk)
            chunk.setup(rect, world_size, base_position, biome, biome_index, night)
            chunk.set_visual_gate(visual_gate_enabled)
            x += CHUNK_SIZE.x
        y += CHUNK_SIZE.y
