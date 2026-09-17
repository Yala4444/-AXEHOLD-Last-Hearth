extends Node

var timer: float = 0.0

const REPLACEMENTS := {
    "🪙": "мон.",
    "🔥": "",
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
    "✓": "OK"
}

func _process(delta: float) -> void:
    timer -= delta
    if timer > 0.0:
        return
    timer = 0.18
    var scene: Node = get_tree().current_scene
    if scene != null:
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
    for key: String in REPLACEMENTS.keys():
        result = result.replace(key, str(REPLACEMENTS[key]))
    while result.contains("  "):
        result = result.replace("  ", " ")
    result = result.replace(" \n", "\n").replace("\n ", "\n")
    return result.strip_edges()
