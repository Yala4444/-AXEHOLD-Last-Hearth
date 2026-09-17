extends Node

var world: GameWorld = null
var elapsed: float = 0.0
var intro_done: bool = false
var notices_shown: bool = false
var arsenal_shown: bool = false
var pending_notices: Array[String] = []

func _process(delta: float) -> void:
    if world == null or not is_instance_valid(world):
        world = _find_world(get_tree().current_scene)
        if world != null:
            _attach_world(world)
        return

    if world.finishing:
        return

    elapsed += delta
    if world.hud == null or world.player == null or world.hud.modal_open():
        return

    if not notices_shown and not pending_notices.is_empty():
        _show_unlock_notices()
        return

    if not arsenal_shown and elapsed >= 0.8:
        _show_arsenal_if_needed()
        return

    if not intro_done and elapsed >= 1.0:
        intro_done = true
        _show_camp_identity()

func _find_world(node: Node) -> GameWorld:
    if node == null:
        return null
    if node is GameWorld:
        return node as GameWorld
    for child: Node in node.get_children():
        var found: GameWorld = _find_world(child)
        if found != null:
            return found
    return null

func _attach_world(new_world: GameWorld) -> void:
    world = new_world
    elapsed = 0.0
    intro_done = false
    notices_shown = false
    arsenal_shown = false
    pending_notices = GameState.consume_meta_notices()
    world.hud.action_requested.connect(_on_hud_action)

func _show_unlock_notices() -> void:
    if world == null or world.hud == null:
        return
    notices_shown = true
    var lines: String = ""
    for notice: String in pending_notices:
        if not lines.is_empty():
            lines += "\n\n"
        lines += notice
    pending_notices.clear()
    world.hud.show_modal(
        "🏆",
        "Трофеи вернулись в лагерь",
        lines,
        [{"text": "Продолжить", "action": "meta:continue"}]
    )

func _show_arsenal_if_needed() -> void:
    arsenal_shown = true
    if world == null or world.hud == null or world.player == null:
        return

    var owned: Array = GameState.data.get("weapons_owned", ["axes"])
    if owned.size() <= 1:
        var selected: String = str(GameState.data.get("selected_weapon", "axes"))
        world.player.apply_weapon_profile(selected)
        return

    var buttons: Array = []
    var selected_id: String = str(GameState.data.get("selected_weapon", "axes"))
    for weapon_id: String in WeaponRules.ordered_ids():
        if not owned.has(weapon_id):
            continue
        var profile: Dictionary = WeaponRules.profile(weapon_id)
        var selected_mark: String = " ✓" if weapon_id == selected_id else ""
        buttons.append({
            "text": "%s %s%s — %s" % [
                str(profile.get("icon", "⚔️")),
                str(profile.get("name", weapon_id)),
                selected_mark,
                _short_role(weapon_id)
            ],
            "action": "weapon:" + weapon_id
        })

    world.hud.show_modal(
        "⚔️",
        "Арсенал лагеря",
        "Выбери оружие на экспедицию. Это меняет дистанцию, урон и темп движения.",
        buttons
    )

func _short_role(id: String) -> String:
    match id:
        "spear":
            return "дальний контроль"
        "hammer":
            return "тяжёлый урон"
        "twin_blades":
            return "скорость и крит"
    return "баланс"

func _show_camp_identity() -> void:
    if world == null or world.hud == null:
        return
    var mastery: int = GameState.total_mastery()
    var relics: Array = GameState.data.get("boss_relics", [false, false, false])
    var relic_count: int = 0
    for value: Variant in relics:
        if bool(value):
            relic_count += 1
    world.hud.show_banner(GameState.camp_title().to_upper(), Color("f4cf8c"))
    world.hud.set_status("🏕️ Мастерство %d · Реликвии %d/3 · %s" % [mastery, relic_count, world.player.weapon_name()])

func _on_hud_action(action: String) -> void:
    if world == null or world.hud == null:
        return
    if action == "meta:continue":
        world.hud.hide_modal()
        return
    if not action.begins_with("weapon:"):
        return

    var weapon_id: String = action.trim_prefix("weapon:")
    if not GameState.select_weapon(weapon_id):
        return
    if world.player != null:
        world.player.apply_weapon_profile(weapon_id)
    world.hud.hide_modal()
    var profile: Dictionary = WeaponRules.profile(weapon_id)
    world.hud.show_banner("%s %s" % [str(profile.get("icon", "⚔️")), str(profile.get("name", weapon_id))], Color("f4cf8c"))
    world.hud.set_status(str(profile.get("desc", "Оружие выбрано.")))
    Feedback.play("level", 12)
    Analytics.event("weapon_selected", {"weapon": weapon_id, "biome": world.biome_index})
