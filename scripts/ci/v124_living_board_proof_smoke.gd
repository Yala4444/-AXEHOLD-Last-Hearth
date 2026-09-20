extends Node

var failures: Array[String] = []

func _ready() -> void:
    var packed := load("res://scenes/living_board_proof.tscn") as PackedScene
    if packed == null:
        _fail("Living board proof scene cannot be loaded")
        _finish()
        return
    var proof := packed.instantiate()
    add_child(proof)
    await get_tree().process_frame
    if not proof.has_method("art_direction_contract"):
        _fail("Living board art contract is missing")
    elif proof.art_direction_contract() != "LIVING_ILLUSTRATED_BOARD_GAME_A":
        _fail("Unexpected living board art direction")
    if not proof.has_method("proof_loop_contract"):
        _fail("Proof loop contract is missing")
    else:
        var loop: PackedStringArray = proof.proof_loop_contract()
        if loop != PackedStringArray(["move", "chop", "collect", "carry", "deliver", "build"]):
            _fail("Proof loop has changed")
    if proof.tree_hp != 4 or proof.cargo != 0 or proof.build_stage != 0:
        _fail("Proof initial state is invalid")
    if proof.hero_pos.distance_to(proof.hero_target) > 0.1:
        _fail("Hero must start stable")
    _finish()

func _fail(message: String) -> void:
    failures.append(message)
    push_error(message)

func _finish() -> void:
    if failures.is_empty():
        print("V1.24 LIVING BOARD PROOF SMOKE PASSED")
        get_tree().quit(0)
    else:
        get_tree().quit(1)
