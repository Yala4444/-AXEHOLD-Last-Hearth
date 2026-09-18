extends Node

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    _test_backdrop_transition()
    _test_biome_guardians()
    _test_core_fx()
    _test_camera_feedback()
    _test_soundscape_layers()

    if failures.is_empty():
        print("[V1.10 FEEL] atmosphere, Guardians, impact FX, camera and music passed")
    _finish()

func _test_backdrop_transition() -> void:
    var chunk := WorldBackdropChunk.new()
    add_child(chunk)
    var biome: Dictionary = GameRules.biome(0)
    chunk.setup(Rect2(Vector2.ZERO, Vector2(420, 420)), Vector2(1400, 3000), Vector2(700, 1500), biome, 0, false)
    if chunk.night_mix != 0.0:
        _fail("Backdrop should begin at day mix 0")
    chunk.set_night(true)
    chunk._process(0.5)
    if chunk.night_mix <= 0.0 or chunk.night_mix >= 1.0:
        _fail("Backdrop day-to-night transition is not gradual")
    chunk._process(2.0)
    if absf(chunk.night_mix - 1.0) > 0.001:
        _fail("Backdrop failed to reach full night mix")
    chunk.queue_free()

func _test_biome_guardians() -> void:
    for biome_index: int in range(3):
        var enemy := AxEnemy.new()
        add_child(enemy)
        enemy.configure("boss", 1.0, 3, Color("8a6670"), true, biome_index)
        if not enemy.boss:
            _fail("Guardian configuration lost boss state")
        if enemy.biome_index != biome_index:
            _fail("Guardian did not preserve biome identity")
        enemy.queue_free()

func _test_core_fx() -> void:
    var fx := CoreFX.new()
    add_child(fx)
    fx.boss_arrival(Vector2(100, 100), 2)
    if fx.particles.size() < 20 or fx.pulses.size() < 2:
        _fail("Guardian arrival lacks production-scale FX")
    var particles_before: int = fx.particles.size()
    fx.enemy_down(Vector2(120, 100), "boss", true, 2)
    if fx.particles.size() <= particles_before:
        _fail("Guardian defeat did not create a distinct FX burst")
    fx.player_hit(Vector2(90, 100))
    fx.hearth_flare(Vector2(100, 120), true)
    if fx.pulses.size() < 5:
        _fail("Player/Hearth feedback did not add readable pulses")
    fx.queue_free()

func _test_camera_feedback() -> void:
    var world := GameWorld.new()
    add_child(world)
    world.trigger_camera_shake(6.0, 0.3)
    if world.camera_shake_strength < 5.9 or world.camera_shake_time < 0.29:
        _fail("Camera impact feedback did not store requested shake")
    world.queue_free()

func _test_soundscape_layers() -> void:
    if Soundscape.alternate_player == null:
        _fail("Soundscape has no crossfade player")
        return
    var day_track: AudioStreamWAV = Soundscape._make_track(0, false, false)
    var boss_track: AudioStreamWAV = Soundscape._make_track(0, true, true)
    if day_track == null or boss_track == null:
        _fail("Production music states failed to generate")
    elif day_track.data.size() == 0 or boss_track.data.size() == 0:
        _fail("Generated music state is empty")

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.10 FEEL] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.10 FEEL] %s" % failure)
    get_tree().quit(1)
