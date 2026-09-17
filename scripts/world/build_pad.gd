class_name BuildPad
extends Node2D

var build_type := "wall"
var label := "ЗАБОР"
var cost := {"wood": 16, "stone": 0, "ore": 0}
var built := false

func configure(kind: String, title: String, new_cost: Dictionary, is_built: bool = false) -> void:
    build_type = kind
    label = title
    cost = new_cost.duplicate(true)
    built = is_built
    queue_redraw()

func can_build(storage: Dictionary) -> bool:
    return int(storage.get("wood",0)) >= int(cost.get("wood",0)) and int(storage.get("stone",0)) >= int(cost.get("stone",0)) and int(storage.get("ore",0)) >= int(cost.get("ore",0))

func consume(storage: Dictionary) -> void:
    for k in ["wood","stone","ore"]:
        storage[k] = int(storage.get(k,0)) - int(cost.get(k,0))
    built = true
    queue_redraw()

func _draw() -> void:
    var fill := Color(0.42,0.58,0.37,0.68) if built else Color(0.96,0.88,0.72,0.78)
    var stroke := Color("587f50") if built else Color("9e8151")
    draw_circle(Vector2.ZERO,28,fill)
    draw_arc(Vector2.ZERO,28,0,TAU,48,stroke,2)
    var font := ThemeDB.fallback_font
    draw_string(font,Vector2(-22,3),"ГОТОВО" if built else label,HORIZONTAL_ALIGNMENT_CENTER,44,8,Color("40372e"))
    if not built:
        var txt := "%d/%d/%d" % [int(cost.get("wood",0)),int(cost.get("stone",0)),int(cost.get("ore",0))]
        draw_string(font,Vector2(-22,15),txt,HORIZONTAL_ALIGNMENT_CENTER,44,7,Color("5a4c3a"))
