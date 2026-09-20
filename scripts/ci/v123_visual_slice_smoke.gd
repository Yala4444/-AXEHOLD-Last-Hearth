extends Node

var failures: Array[String] = []

func _ready() -> void:
    var packed := load("res://scenes/visual_slice.tscn") as PackedScene
    if packed == null:
        _fail("Visual slice scene cannot be loaded")
        _finish()
        return
    var slice := packed.instantiate()
    add_child(slice)
    await get_tree().process_frame
    if not slice.has_method("art_direction_contract"):
        _fail("Visual slice art contract is missing")
    elif slice.art_direction_contract() != "CONCEPT_I_CLEAN_CEL_SHADED_ACTION_ADVENTURE":
        _fail("Unexpected art direction contract")
    for file in ["forest_arena.webp", "hero_walk.webp", "hound_run.webp", "husk_walk.webp", "tree_damage.webp", "hearth_fire.webp"]:
        if not ResourceLoader.exists("res://assets/art/vertical_slice_i/" + file):
            _fail("Missing vertical slice asset: " + file)
    if slice.hero == null or slice.hero.hframes != 6:
        _fail("Hero animation strip is not configured")
    if slice.tree == null or slice.tree.hframes != 4:
        _fail("Tree reaction strip is not configured")
    _finish()

func _fail(message: String) -> void:
    failures.append(message)
    push_error(message)

func _finish() -> void:
    if failures.is_empty():
        print("V1.23 VISUAL SLICE SMOKE PASSED")
        get_tree().quit(0)
    else:
        get_tree().quit(1)
