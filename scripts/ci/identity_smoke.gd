extends Node

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    var map_view := WorldMapView.new()
    add_child(map_view)
    map_view.configure(0)
    await get_tree().process_frame
    if map_view.custom_minimum_size.y < 430.0:
        _fail("World map is not tall enough to read as a route")
    if map_view.node_buttons.size() != 3:
        _fail("World map does not expose all three biome nodes")

    var preview := WeaponPreview.new()
    add_child(preview)
    preview.configure("hammer")
    await get_tree().process_frame
    if preview.custom_minimum_size.y < 160.0:
        _fail("Weapon preview collapsed below presentation target")

    var hall := TrophyHallView.new()
    add_child(hall)
    await get_tree().process_frame
    if hall.custom_minimum_size.y < 250.0:
        _fail("Trophy hall collapsed below presentation target")

    if LoreRules.CHAPTER_TITLE.find("ПОГАСАНИЕ") < 0:
        _fail("Chapter identity is missing the Extinguishing premise")
    for i: int in range(3):
        if LoreRules.biome_tagline(i).is_empty() or LoreRules.biome_lore(i).is_empty():
            _fail("Biome lore missing for index %d" % i)

    var frost: Dictionary = GameRules.biome(1)
    var frost_ground := Color(str(frost.get("ground", "ffffff")))
    if frost_ground.get_luminance() > 0.66:
        _fail("Frost ground is too bright for foreground readability")

    var camp := CampView.new()
    add_child(camp)
    await get_tree().process_frame
    if camp.custom_minimum_size.y < 430.0:
        _fail("Living camp did not adopt immersive v1.4 height")

    if failures.is_empty():
        print("[V1.4 IDENTITY] lore, map, arsenal preview, trophies and camp composition passed")

    map_view.queue_free()
    preview.queue_free()
    hall.queue_free()
    camp.queue_free()
    await get_tree().process_frame
    _finish()

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.4 IDENTITY] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.4 IDENTITY] %s" % failure)
    get_tree().quit(1)
