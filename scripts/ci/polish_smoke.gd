extends Node

const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")

var failures: Array[String] = []

func _ready() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    await get_tree().process_frame
    _test_soundscape_tracks()
    _test_guardian_armor()
    _test_stalker_surge()
    _test_biome_rosters()

    if failures.is_empty():
        print("[POLISH] AXEHOLD v0.9 commercial polish validation passed")
        get_tree().quit(0)
        return

    for failure: String in failures:
        push_error("[POLISH] %s" % failure)
    get_tree().quit(1)

func _test_soundscape_tracks() -> void:
    var soundscape: Node = get_tree().root.get_node_or_null("Soundscape")
    if soundscape == null:
        _fail("Soundscape autoload is missing")
        return

    var generated: int = 0
    for biome_index: int in range(3):
        for night: bool in [false, true]:
            var stream_variant: Variant = soundscape.call("_make_track", biome_index, night)
            if not stream_variant is AudioStreamWAV:
                _fail("Soundscape failed to generate biome %d night=%s" % [biome_index, str(night)])
                continue
            var stream: AudioStreamWAV = stream_variant as AudioStreamWAV
            if stream.data.size() < 10000:
                _fail("Soundscape track is unexpectedly empty for biome %d night=%s" % [biome_index, str(night)])
            else:
                generated += 1
    if generated == 6:
        print("[POLISH] six procedural biome soundscapes OK")

func _test_guardian_armor() -> void:
    var guardian: AxEnemy = EnemyScene.instantiate() as AxEnemy
    if guardian == null:
        _fail("Cannot instantiate Guardian test enemy")
        return
    guardian.configure("guardian", 1.0, 2, Color("783f46"), false)
    var hp_before: float = guardian.hp
    guardian.take_damage(40.0)
    var received: float = hp_before - guardian.hp
    if guardian.armor < 0.20:
        _fail("Guardian armor is too low or missing")
    if received >= 39.5 or received <= 0.0:
        _fail("Guardian armor did not reduce incoming damage")
    else:
        print("[POLISH] Guardian armor mitigation OK")
    guardian.free()

func _test_stalker_surge() -> void:
    var stalker: AxEnemy = EnemyScene.instantiate() as AxEnemy
    if stalker == null:
        _fail("Cannot instantiate Stalker test enemy")
        return
    stalker.configure("stalker", 1.0, 2, Color("577086"), false)
    stalker.global_position = Vector2.ZERO
    stalker.set_target_position(Vector2(120.0, 0.0))
    stalker.surge_cooldown = 0.0
    var started: bool = bool(stalker.call("_update_stalker_surge", 0.01))
    if not started or stalker.surge_windup <= 0.0:
        _fail("Stalker did not enter its telegraphed surge windup")
    else:
        print("[POLISH] Stalker surge windup OK")
    stalker.free()

func _test_biome_rosters() -> void:
    var forest: Dictionary = GameRules.biome(0).get("enemy_weights", {})
    var frost: Dictionary = GameRules.biome(1).get("enemy_weights", {})
    var ash: Dictionary = GameRules.biome(2).get("enemy_weights", {})
    if float(frost.get("stalker", 0.0)) <= float(forest.get("stalker", 0.0)):
        _fail("Frost biome does not emphasize Stalkers")
    if float(ash.get("guardian", 0.0)) <= float(forest.get("guardian", 0.0)):
        _fail("Ash biome does not emphasize Guardians")
    if failures.is_empty():
        print("[POLISH] biome enemy identities OK")

func _fail(message: String) -> void:
    failures.append(message)
    print("[POLISH] FAIL: ", message)
