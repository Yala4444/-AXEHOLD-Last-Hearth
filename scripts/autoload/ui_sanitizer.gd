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
