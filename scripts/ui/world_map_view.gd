class_name WorldMapView
extends Control

signal biome_selected(index: int)

var selected_biome: int = 0
var elapsed: float = 0.0
var node_buttons: Array[Button] = []
var requirements: Array[int] = [0, 1, 3]
var node_points: Array[Vector2] = []

func _ready() -> void:
    custom_minimum_size = Vector2(0, 430)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    clip_contents = true
    _build_buttons()
    resized.connect(_layout_buttons)
    set_process(true)

func configure(index: int) -> void:
    selected_biome = clampi(index, 0, 2)
    if is_node_ready():
        _refresh_buttons()
        _layout_buttons()
        queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _build_buttons() -> void:
    for i: int in range(3):
        var button := Button.new()
        add_child(button)
        node_buttons.append(button)
        button.focus_mode = Control.FOCUS_NONE
        button.add_theme_font_size_override("font_size", 8)
        button.pressed.connect(_on_node_pressed.bind(i))
    _refresh_buttons()
    _layout_buttons()

func _refresh_buttons() -> void:
    var shards: int = int(GameState.data.get("shards", 0))
    var mastery: Array = GameState.data.get("biome_mastery", [0,0,0])
    var relics: Array = GameState.data.get("boss_relics", [false,false,false])
    for i: int in range(node_buttons.size()):
        var button: Button = node_buttons[i]
        var biome: Dictionary = GameRules.biome(i)
        var unlocked: bool = shards >= requirements[i]
        var level: int = int(mastery[i]) if i < mastery.size() else 0
        var selected: bool = selected_biome == i and unlocked

        if not unlocked:
            button.text = "%s\nНУЖНО %d ОСК." % [str(biome.get("name","Регион")).to_upper(), requirements[i]]
        else:
            var relic_mark: String = "РЕЛИКВИЯ" if i < relics.size() and bool(relics[i]) else "МАСТ. %d" % level
            button.text = "%s\n%s" % [str(biome.get("name","Регион")).to_upper(), relic_mark]

        button.disabled = not unlocked
        var fill: Color = Color(0.06,0.09,0.10,0.78)
        var border: Color = Color(0.32,0.40,0.41,0.54)
        if selected:
            fill = Color(VisualSystem.GOLD,0.10)
            border = Color(VisualSystem.GOLD,0.68)
        elif not unlocked:
            fill = Color(0.04,0.055,0.06,0.74)
            border = Color(0.20,0.24,0.25,0.42)

        button.add_theme_stylebox_override("normal", VisualSystem.panel(fill,border,5,5,1))
        button.add_theme_stylebox_override("pressed", VisualSystem.panel(fill.lightened(0.04),VisualSystem.GOLD,5,5,1))
        button.add_theme_stylebox_override("disabled", VisualSystem.panel(fill,border,5,5,1))
        button.add_theme_color_override("font_color", VisualSystem.TEXT if unlocked else VisualSystem.TEXT_MUTED)
        button.add_theme_color_override("font_disabled_color", Color("667174"))

func _layout_buttons() -> void:
    var w: float = maxf(size.x,330.0)
    var h: float = maxf(size.y,430.0)
    node_points = [
        Vector2(w*0.31,h*0.72),
        Vector2(w*0.69,h*0.47),
        Vector2(w*0.36,h*0.22)
    ]
    for i: int in range(mini(node_buttons.size(),node_points.size())):
        var p: Vector2 = node_points[i]
        var button: Button = node_buttons[i]
        if i == 1:
            button.position = p + Vector2(-136,-22)
        else:
            button.position = p + Vector2(27,-22)
        button.size = Vector2(112,44)

func _on_node_pressed(index: int) -> void:
    var shards: int = int(GameState.data.get("shards",0))
    if shards < requirements[index]:
        return
    selected_biome = index
    _refresh_buttons()
    queue_redraw()
    biome_selected.emit(index)

func _draw() -> void:
    var w: float = maxf(size.x,330.0)
    var h: float = maxf(size.y,430.0)

    draw_rect(Rect2(Vector2.ZERO,Vector2(w,h)),Color("0c1418"))
    for i: int in range(12):
        var t: float = float(i)/11.0
        draw_rect(Rect2(0,t*h,w,h/11.0+1.0),Color("111c21").lerp(Color("213029"),t))

    _draw_regions(w,h)
    _draw_ridges(w,h)
    if node_points.size()!=3:
        _layout_buttons()

    var hearth := Vector2(w*0.50,h*0.91)
    var path_color := Color(0.82,0.68,0.39,0.30)
    _draw_route_segment(hearth,node_points[0],path_color)
    _draw_route_segment(node_points[0],node_points[1],path_color)
    _draw_route_segment(node_points[1],node_points[2],path_color)

    _draw_hearth(hearth)
    _draw_biome_node(node_points[0],0)
    _draw_biome_node(node_points[1],1)
    _draw_biome_node(node_points[2],2)

    var font: Font = ThemeDB.fallback_font
    draw_string(font,Vector2(0,20),"ПУТЬ СТРАННИКА",HORIZONTAL_ALIGNMENT_CENTER,w,9,Color("9fa9a6"))
    draw_string(font,Vector2(0,h-10),"ПОСЛЕДНИЙ ОЧАГ",HORIZONTAL_ALIGNMENT_CENTER,w,8,VisualSystem.GOLD_BRIGHT)

func _draw_regions(w: float,h: float) -> void:
    # Forest basin.
    draw_circle(Vector2(w*0.27,h*0.70),88.0,Color(0.20,0.35,0.25,0.17))
    for i: int in range(11):
        var a: float = TAU*float(i)/11.0
        var p := Vector2(w*0.27,h*0.70)+Vector2(cos(a),sin(a))*randf_range(42.0,76.0)
        draw_circle(p,4.0,Color(0.18,0.31,0.22,0.28))

    # Frost hollow.
    draw_circle(Vector2(w*0.71,h*0.46),82.0,Color(0.35,0.55,0.60,0.12))
    for i: int in range(7):
        var x: float = w*0.56 + float(i)*17.0
        var y: float = h*0.39 + sin(float(i))*12.0
        draw_line(Vector2(x,y),Vector2(x+14,y-22),Color(0.62,0.79,0.82,0.22),1.3)

    # Ashlands.
    draw_circle(Vector2(w*0.34,h*0.22),78.0,Color(0.52,0.24,0.18,0.12))
    for i: int in range(5):
        var x: float = w*0.21 + float(i)*27.0
        var y: float = h*0.18 + float(i%2)*12.0
        draw_line(Vector2(x,y),Vector2(x+12,y+15),Color(0.87,0.31,0.16,0.22),2.0)

func _draw_ridges(w: float,h: float) -> void:
    var ridge := PackedVector2Array([
        Vector2(0,h*0.34),Vector2(w*0.14,h*0.26),Vector2(w*0.28,h*0.33),
        Vector2(w*0.48,h*0.22),Vector2(w*0.62,h*0.31),Vector2(w*0.82,h*0.20),
        Vector2(w,h*0.29),Vector2(w,h*0.52),Vector2(0,h*0.52)
    ])
    draw_colored_polygon(ridge,Color(0.08,0.14,0.16,0.52))

func _draw_route_segment(a: Vector2,b: Vector2,color: Color) -> void:
    draw_line(a,b,Color(0.04,0.06,0.06,0.72),5.0)
    draw_line(a,b,color,2.0)
    for i: int in range(1,5):
        var p: Vector2 = a.lerp(b,float(i)/5.0)
        draw_circle(p,1.8,Color(0.91,0.77,0.47,0.42))

func _draw_hearth(pos: Vector2) -> void:
    var pulse: float = (sin(elapsed*3.4)+1.0)*0.5
    draw_circle(pos,37.0+pulse*3.0,Color(1.0,0.53,0.18,0.055))
    draw_circle(pos,18.0,Color("25221d"))
    draw_line(pos+Vector2(-8,7),pos+Vector2(8,-5),Color("6f4328"),4.0)
    draw_line(pos+Vector2(8,7),pos+Vector2(-7,-5),Color("6f4328"),4.0)
    draw_colored_polygon(PackedVector2Array([
        pos+Vector2(-6,5),pos+Vector2(-2,-12-pulse*3.0),
        pos+Vector2(2,-5),pos+Vector2(6,-16+pulse*2.0),pos+Vector2(8,5)
    ]),Color("f39a3d"))
    draw_circle(pos+Vector2(1,0),4.0,Color("ffe486"))

func _draw_biome_node(pos: Vector2,index: int) -> void:
    var selected: bool = index==selected_biome
    var pulse: float = (sin(elapsed*2.4+float(index))+1.0)*0.5
    var accent: Color = Color("7ca06b")
    if index==1:
        accent=Color("8dc2cf")
    elif index==2:
        accent=Color("d16a45")

    draw_circle(pos,28.0+(pulse*2.0 if selected else 0.0),Color(accent,0.07 if selected else 0.03))
    draw_circle(pos,21.0,Color("111a1e"))
    draw_arc(pos,21.0,0.0,TAU,30,VisualSystem.GOLD if selected else Color(accent,0.72),2.0)

    match index:
        1:
            draw_colored_polygon(PackedVector2Array([
                pos+Vector2(-14,10),pos+Vector2(-3,-14),pos+Vector2(4,-3),
                pos+Vector2(10,-18),pos+Vector2(16,10)
            ]),Color("8bb6c0"))
            draw_line(pos+Vector2(-3,-14),pos+Vector2(1,-4),Color("d7edf1"),2.0)
        2:
            draw_line(pos+Vector2(-13,8),pos+Vector2(-3,-11),Color("6c4136"),5.0)
            draw_line(pos+Vector2(3,11),pos+Vector2(13,-9),Color("6c4136"),5.0)
            draw_line(pos+Vector2(-8,9),pos+Vector2(9,4),Color("df6537"),2.0)
            draw_circle(pos+Vector2(10,9),3.0,Color("e37842"))
        _:
            draw_rect(Rect2(pos+Vector2(-3,3),Vector2(6,13)),Color("60442e"))
            draw_circle(pos+Vector2(0,-3),12.0,Color("42684b"))
            draw_circle(pos+Vector2(-8,1),7.0,Color("507a55"))
            draw_circle(pos+Vector2(8,1),7.0,Color("507a55"))
