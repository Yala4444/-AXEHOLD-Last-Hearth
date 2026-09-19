extends Node

const GameScene: PackedScene = preload("res://scenes/game.tscn")

var failures: Array[String] = []
var snapshot: Dictionary = {}

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    snapshot = GameState.data.duplicate(true)

    _test_threat_rules()
    _test_meta_progression()
    _test_damage_grace_and_relics()
    await _test_world_threat()
    await _test_endless_checkpoint()

    GameState.data = snapshot
    GameState.save()

    if failures.is_empty():
        print("[V1.16 PROGRESSION] threat tiers, shard forge, endless mode and relic builds passed")
    _finish()

func _test_threat_rules() -> void:
    if ThreatRules.MAX_LEVEL != 5:
        _fail("Threat cap is not five")
    var previous_reward: float = 0.0
    for level: int in range(1, ThreatRules.MAX_LEVEL + 1):
        var spec: Dictionary = ThreatRules.spec(level)
        if int(spec.get("level", 0)) != level:
            _fail("Threat rule level mismatch")
        var reward: float = float(spec.get("reward", 0.0))
        if reward <= previous_reward:
            _fail("Threat reward multiplier does not increase at level %d" % level)
        previous_reward = reward
    if not ThreatRules.endless_is_boss_wave(5) or ThreatRules.endless_is_boss_wave(4):
        _fail("Endless boss cadence must be every fifth night")

func _test_meta_progression() -> void:
    GameState.data = GameState.defaults()
    GameState.data["selected_biome"] = 0
    if GameState.threat_unlocked_level(0) != 1:
        _fail("Fresh save should start at Threat I")
    var first: Dictionary = GameState.record_threat_clear(0, 1)
    if not bool(first.get("first", false)):
        _fail("First Threat I clear was not marked first")
    if GameState.threat_unlocked_level(0) != 2:
        _fail("Threat II was not unlocked after Threat I")
    var repeat: Dictionary = GameState.record_threat_clear(0, 1)
    if bool(repeat.get("first", true)):
        _fail("Repeated threat clear incorrectly grants first-clear state")

    GameState.data["shards"] = 6
    if not GameState.buy_relic_forge("power"):
        _fail("Shard forge could not buy Power I")
    if GameState.relic_forge_level("power") != 1:
        _fail("Shard forge level did not persist")
    if float(GameState.relic_forge_bonuses().get("damage_mult",1.0)) <= 1.0:
        _fail("Shard forge power did not produce a gameplay bonus")

func _test_damage_grace_and_relics() -> void:
    var player := AxPlayer.new()
    add_child(player)
    player.setup({"damage":0,"hp":0,"bag":0,"speed":0}, GameRules.skin(0))
    var start_hp: float = player.hp
    player.take_damage(12.0)
    player.take_damage(12.0)
    if absf(player.hp - (start_hp - 12.0)) > 0.01:
        _fail("Damage grace did not prevent same-frame burst damage")

    for perk_id: String in ["fire_orb","frost_aura","thorn_ring","guardian_spirit"]:
        player.apply_perk(perk_id)
    if player.fire_orb_level < 1 or player.frost_aura_level < 1 or player.thorn_ring_level < 1 or player.guardian_spirit_level < 1:
        _fail("Visible roguelite relic perks did not apply")
    player.queue_free()

func _test_world_threat() -> void:
    GameState.data = GameState.defaults()
    GameState.data["selected_biome"] = 0
    GameState.data["selected_threat"] = 3
    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(0, 3, "expedition")
    add_child(world)
    await _wait_frames(7)

    if world.threat_level != 3 or world.run_mode != "expedition":
        _fail("GameWorld did not preserve selected threat/mode")
    if world.turret_global_damage_mult >= 0.99:
        _fail("Higher threat did not reduce turret dominance")
    if world.phase_max >= GameRules.day_duration(0):
        _fail("Higher threat did not tighten preparation time")

    var enemy := AxEnemy.new()
    add_child(enemy)
    enemy.configure("normal",1.0,1,Color("755b76"),false,0)
    var hp_before: float = enemy.max_hp
    var damage_before: float = enemy.contact_damage
    world._apply_threat_to_enemy(enemy,false)
    if enemy.max_hp <= hp_before or enemy.contact_damage <= damage_before:
        _fail("Threat scaling did not strengthen enemies")
    enemy.queue_free()

    world.queue_free()
    await _wait_frames(4)

func _test_endless_checkpoint() -> void:
    GameState.data = GameState.defaults()
    GameState.data["boss_relics"] = [true,true,true]
    var world: GameWorld = GameScene.instantiate() as GameWorld
    world.configure(2, 1, "endless")
    add_child(world)
    await _wait_frames(7)

    if world.run_mode != "endless":
        _fail("Endless mode was not configured")
    world.wave = 5
    world._show_endless_checkpoint()
    await _wait_frames(2)
    if not world.hud.modal_open():
        _fail("Endless boss checkpoint did not open a relic chest")
    if world.endless_checkpoint_wave != 5:
        _fail("Endless checkpoint did not retain record wave")

    world.hud.hide_modal()
    world.queue_free()
    await _wait_frames(4)

func _wait_frames(count: int) -> void:
    for _i: int in range(count):
        await get_tree().process_frame

func _fail(message: String) -> void:
    failures.append(message)
    print("[V1.16 PROGRESSION] FAIL: ", message)

func _finish() -> void:
    if failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in failures:
        push_error("[V1.16 PROGRESSION] %s" % failure)
    get_tree().quit(1)
