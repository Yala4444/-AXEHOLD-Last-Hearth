extends Node

const REPLACEMENTS := {
    "🪙": "мон.",
    "🏕": "ЛАГ",
    "🗺": "КАРТА",
    "⚒": "КУЗНЯ",
    "📜": "ЦЕЛИ",
    "🎭": "ОБЛИК",
    "⚙": "...",
    "❤️": "HP",
    "❤": "HP",
    "🎒": "РЮК",
    "🌙": "НОЧЬ",
    "☀": "ДЕНЬ",
    "🪵": "Д",
    "🪨": "К",
    "⛏": "Р",
    "👑": "БОСС",
    "⚔": "",
    "🗡": "",
    "🪓": "",
    "🔨": "",
    "🌲": "",
    "🏰": "",
    "🧥": "",
    "🍃": "",
    "❄": "",
    "📦": "",
    "🏆": "",
    "🔒": "ЗАКР.",
    "💡": "",
    "🔊": "",
    "📳": "",
    "▶": ">",
    "✓": "OK",
    "🔥": ""
}

func _ready() -> void:
    # Run after gameplay/UI nodes so dynamic labels are cleaned before rendering.
    process_priority = 1000

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    _sanitize_tree(scene)
    var world: GameWorld = _find_world(scene)
    if world != null:
        _polish_game_hud(world)

func _sanitize_tree(node: Node) -> void:
    if node is Label:
        var label := node as Label
        var cleaned: String = clean_text(label.text)
        if cleaned != label.text:
            label.text = cleaned
    elif node is Button:
        var button := node as Button
        var cleaned_button: String = clean_text(button.text)
        if cleaned_button != button.text:
            button.text = cleaned_button

    for child: Node in node.get_children():
        _sanitize_tree(child)

func clean_text(source: String) -> String:
    var result: String = source.replace("\uFE0F", "")
    result = result.replace("Коснись места — герой побежит туда.", "Используй стик слева, чтобы двигаться.")
    result = result.replace("Коснись места", "Используй стик слева")
    for key: String in REPLACEMENTS.keys():
        result = result.replace(key, str(REPLACEMENTS[key]))
    while result.contains("  "):
        result = result.replace("  ", " ")
    result = result.replace(" \n", "\n").replace("\n ", "\n")
    return result.strip_edges()

func _polish_game_hud(world: GameWorld) -> void:
    if world.hud == null or world.player == null:
        return
    if not is_instance_valid(world.hud) or not is_instance_valid(world.player):
        return

    var hud: GameHud = world.hud
    hud.hp_label.text = "HP %d" % int(ceil(world.player.hp))
    hud.base_label.text = "ОЧАГ %d" % int(ceil(maxf(world.base_hp, 0.0)))
    hud.bag_label.text = "РЮК %d/%d" % [world.player.inventory_total(), world.player.capacity]
    hud.wave_label.text = "НОЧЬ %d/3" % world.wave
    hud.resources_label.text = "Д %d   К %d   Р %d" % [
        int(world.storage.get("wood", 0)),
        int(world.storage.get("stone", 0)),
        int(world.storage.get("ore", 0))
    ]

    if world.phase == "day":
        hud.phase_label.text = "ДО НОЧИ · %d сек" % int(ceil(world.phase_time))
    else:
        var remaining: int = world.spawn_left + world.enemies.size()
        hud.phase_label.text = "НОЧЬ %d · ВРАГОВ %d" % [world.wave, remaining]

    if hud.status_label.text.is_empty():
        hud.status_label.text = "Стик слева — движение. Оружие атакует автоматически."

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
