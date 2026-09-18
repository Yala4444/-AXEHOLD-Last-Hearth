class_name TrophyHallView
extends Control

var relics: Array = [false,false,false]
var mastery: Array = [0,0,0]
var elapsed: float = 0.0

func _ready() -> void:
    custom_minimum_size = Vector2(0,250)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    relics = GameState.data.get("boss_relics",[false,false,false])
    mastery = GameState.data.get("biome_mastery",[0,0,0])
    set_process(true)
    queue_redraw()

func refresh() -> void:
    relics = GameState.data.get("boss_relics",[false,false,false])
    mastery = GameState.data.get("biome_mastery",[0,0,0])
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var w: float = maxf(size.x,320.0)
    var h: float = maxf(size.y,250.0)

    draw_rect(Rect2(Vector2.ZERO,Vector2(w,h)),Color("0d1417"))
    for i: int in range(8):
        var t: float = float(i)/7.0
        draw_rect(Rect2(0,t*h,w,h/7.0+1.0),Color("10171a").lerp(Color("201f1a"),t))

    # Stone wall divisions and warm center light.
    for x_ratio: float in [0.0,0.25,0.50,0.75,1.0]:
        var x: float = w*x_ratio
        draw_line(Vector2(x,50),Vector2(x,h),Color(0.19,0.20,0.18,0.42),1.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(w*0.41,0),Vector2(w*0.59,0),Vector2(w*0.76,h),Vector2(w*0.24,h)
    ]),Color(VisualSystem.GOLD,0.026))

    var font: Font = ThemeDB.fallback_font
    draw_string(font,Vector2(0,22),"РЕЛИКВИИ ХРАНИТЕЛЕЙ",HORIZONTAL_ALIGNMENT_CENTER,w,12,VisualSystem.GOLD_BRIGHT)
    draw_string(font,Vector2(0,39),"История хранится в предметах, а не в списке достижений.",HORIZONTAL_ALIGNMENT_CENTER,w,7,VisualSystem.TEXT_MUTED)

    var xs: Array[float] = [w*0.18,w*0.50,w*0.82]
    for i: int in range(3):
        _draw_pedestal(Vector2(xs[i],h*0.52),i)

func _draw_pedestal(pos: Vector2,index: int) -> void:
    var owned: bool = index<relics.size() and bool(relics[index])
    var level: int = int(mastery[index]) if index<mastery.size() else 0
    var pulse: float = (sin(elapsed*2.2+float(index))+1.0)*0.5

    var accent: Color = Color("7fb86c")
    if index==1:
        accent=Color("8ec8d9")
    elif index==2:
        accent=Color("df7646")

    # Alcove is architectural rather than a card.
    draw_arc(pos+Vector2(0,-18),34.0,PI,TAU,24,Color(0.30,0.31,0.28,0.54),2.0)
    draw_line(pos+Vector2(-34,-18),pos+Vector2(-34,30),Color(0.23,0.24,0.22,0.55),2.0)
    draw_line(pos+Vector2(34,-18),pos+Vector2(34,30),Color(0.23,0.24,0.22,0.55),2.0)
    draw_rect(Rect2(pos+Vector2(-26,28),Vector2(52,10)),Color("4b463d"))
    draw_rect(Rect2(pos+Vector2(-31,38),Vector2(62,6)),Color("5f594d"))

    if owned:
        draw_circle(pos+Vector2(0,-4),24.0+pulse*2.0,Color(accent,0.055))
        draw_circle(pos+Vector2(0,-4),15.0,Color(accent,0.025))
        _draw_relic(pos+Vector2(0,-4),index)
    else:
        draw_circle(pos+Vector2(0,-4),15.0,Color(0.03,0.04,0.04,0.58))
        draw_arc(pos+Vector2(0,-4),15.0,0.0,TAU,20,Color(0.36,0.39,0.38,0.42),1.5)
        var lock := UiIcon.new()
        # Draw lock manually because children are not useful inside _draw.
        draw_rect(Rect2(pos+Vector2(-4,-5),Vector2(8,8)),Color(0.35,0.38,0.37,0.42))
        draw_arc(pos+Vector2(0,-5),6.0,PI,TAU,12,Color(0.35,0.38,0.37,0.42),1.5)

    var font: Font = ThemeDB.fallback_font
    var names: Array[String] = ["КОРЕНЬ","ИНЕЙ","ПЕПЕЛ"]
    draw_string(font,pos+Vector2(-35,61),names[index],HORIZONTAL_ALIGNMENT_CENTER,70,8,VisualSystem.TEXT if owned else VisualSystem.TEXT_MUTED)

    # Mastery is shown as small dots, easier to scan than repeated text.
    for star_index: int in range(5):
        var star_pos := pos+Vector2(-18+float(star_index)*9.0,72)
        var filled: bool = star_index<level
        draw_circle(star_pos,2.3,VisualSystem.GOLD if filled else Color("394143"))

func _draw_relic(pos: Vector2,index: int) -> void:
    match index:
        1:
            var crystal := PackedVector2Array([
                pos+Vector2(0,-23),pos+Vector2(13,-5),pos+Vector2(8,18),
                pos+Vector2(-8,18),pos+Vector2(-14,-5)
            ])
            draw_colored_polygon(crystal,Color("78bbce"))
            draw_polyline(crystal,Color("d7f2f6"),1.6)
            draw_line(pos+Vector2(0,-18),pos+Vector2(-3,14),Color(0.90,0.98,1.0,0.46),1.5)
        2:
            draw_circle(pos,17.0,Color("8e3d2d"))
            draw_circle(pos,11.0,Color("d35d34"))
            draw_circle(pos,5.0,Color("ffad49"))
            draw_arc(pos,22.0,3.4,5.95,20,Color("e29959"),2.5)
        _:
            draw_line(pos+Vector2(0,15),pos+Vector2(0,-25),Color("416d3d"),5.0)
            draw_circle(pos,15.0,Color("4b7545"))
            draw_arc(pos+Vector2(-1,-8),18.0,3.3,5.88,18,Color("85c76d"),2.7)
            draw_circle(pos+Vector2(8,-14),3.5,Color("b0e48e"))
