extends SceneTree

const SCENES: Array[String] = [
    "res://scenes/app.tscn",
    "res://scenes/camp_view.tscn",
    "res://scenes/game.tscn",
    "res://scenes/player.tscn",
    "res://scenes/enemy.tscn",
    "res://scenes/resource_spot.tscn",
    "res://scenes/build_pad.tscn",
]

func _initialize() -> void:
    var failures: Array[String] = []

    for scene_path: String in SCENES:
        var packed: PackedScene = load(scene_path) as PackedScene
        if packed == null:
            failures.append("Cannot load %s" % scene_path)
            continue

        var instance: Node = packed.instantiate()
        if instance == null:
            failures.append("Cannot instantiate %s" % scene_path)
            continue

        if instance.get_script() == null:
            failures.append("Root script is missing or failed to parse: %s" % scene_path)
            instance.free()
            continue

        instance.free()
        print("[SMOKE] OK: ", scene_path)

    if failures.is_empty():
        print("[SMOKE] AXEHOLD scene validation passed")
        quit(0)
        return

    for failure: String in failures:
        push_error("[SMOKE] %s" % failure)
    quit(1)
