class_name WeaponPreview
extends Control

var weapon_id: String = "axes"
var elapsed: float = 0.0

func _ready() -> void:
    custom_minimum_size = Vector2(0, 168)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    queue_redraw()

func configure(id: String) -> void:
    weapon_id = id if WeaponRules.WEAPONS.has(id) else "axes"
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var w: float = maxf(size.x, 72.0)
    var h: float = maxf(size.y, 64.0)
    var scale_value: float = clampf(minf(w / 260.0, h / 168.0), 0.46, 1.0)

    draw_rect(Rect2(Vector2.ZERO, Vector2(w,h)), Color("0d1518"))
    for i: int in range(7):
        var t: float = float(i)/6.0
        draw_rect(Rect2(0,t*h,w,h/6.0+1.0),Color("111d21").lerp(Color("202b27"),t))

    var hero := Vector2(w*0.50,h*0.62)
    draw_circle(hero + Vector2(0,4*scale_value), 62.0*scale_value, Color(VisualSystem.GOLD,0.038))
    draw_circle(hero + Vector2(0,4*scale_value), 37.0*scale_value, Color(VisualSystem.GOLD,0.026))
    _draw_ground(hero,scale_value)
    _draw_hero(hero,scale_value)

    var profile: Dictionary = WeaponRules.profile(weapon_id)
    var radius: float = float(profile.get("orbit_radius",44.0))*0.88*scale_value
    var count: int = int(profile.get("axes",1))
    var speed: float = 1.0
    match weapon_id:
        "hammer":
            speed=0.72
        "spear":
            speed=0.84
        "twin_blades":
            speed=1.28
    var base_angle: float = elapsed*2.5*speed

    if weapon_id=="spear":
        var angle: float = sin(elapsed*1.9)*0.32-0.38
        var dir := Vector2(cos(angle),sin(angle))
        draw_line(hero+dir*10.0*scale_value,hero+dir*78.0*scale_value,Color(0.57,0.80,0.60,0.15),4.0*scale_value)
        _draw_weapon(hero+dir*60.0*scale_value,angle,1.08*scale_value)
    elif weapon_id=="hammer":
        var cycle: float = fmod(elapsed,1.18)/1.18
        var angle: float = -0.55+sin(elapsed*1.5)*0.20
        var p := hero+Vector2(cos(angle),sin(angle))*radius
        _draw_weapon(p,angle,1.08*scale_value)
        if cycle<0.30:
            var slam_t: float = cycle/0.30
            draw_arc(hero,18.0*scale_value+slam_t*48.0*scale_value,0.0,TAU,32,Color(0.64,0.84,0.94,0.40*(1.0-slam_t)),3.0*scale_value)
    elif weapon_id=="twin_blades":
        var combo: int = 1+int(fmod(elapsed*2.6,6.0))
        for i: int in range(2):
            var angle: float = base_angle+PI*float(i)
            var p := hero+Vector2(cos(angle),sin(angle))*radius
            draw_arc(hero,radius,angle-0.52,angle+0.08,12,Color(0.94,0.50,0.30,0.16),4.0*scale_value)
            _draw_weapon(p,angle,0.92*scale_value)
        draw_arc(hero,31.0*scale_value,-2.6,-2.6+TAU*float(combo)/6.0,28,Color("e79d6f"),2.0*scale_value)
    else:
        for i: int in range(maxi(1,count)):
            var angle: float = base_angle+TAU*float(i)/float(maxi(1,count))
            var p := hero+Vector2(cos(angle),sin(angle))*radius
            draw_arc(hero,radius,angle-0.34,angle-0.07,10,Color(0.84,0.90,0.91,0.12),3.0*scale_value)
            _draw_weapon(p,angle,0.92*scale_value)

func _draw_ground(hero: Vector2,s: float) -> void:
    var points := PackedVector2Array()
    for i: int in range(24):
        var a: float = TAU*float(i)/24.0
        points.append(hero+Vector2(cos(a)*22.0*s,sin(a)*5.0*s)+Vector2(0,18.0*s))
    draw_colored_polygon(points,Color(0.02,0.03,0.03,0.28))

func _draw_hero(pos: Vector2,s: float) -> void:
    var cape := PackedVector2Array([
        pos+Vector2(-9,-4)*s,pos+Vector2(-11,10)*s,pos+Vector2(-5,20)*s,
        pos+Vector2(1,23)*s,pos+Vector2(9,17)*s,pos+Vector2(10,-3)*s
    ])
    draw_colored_polygon(cape,Color("2f4965"))
    var torso := PackedVector2Array([
        pos+Vector2(-9,-5)*s,pos+Vector2(-12,1)*s,pos+Vector2(-7,12)*s,
        pos+Vector2(0,15)*s,pos+Vector2(7,12)*s,pos+Vector2(12,1)*s,pos+Vector2(9,-5)*s
    ])
    draw_colored_polygon(torso,Color("24303a"))
    var chest := PackedVector2Array([
        pos+Vector2(-7,-4)*s,pos+Vector2(-9,1)*s,pos+Vector2(-5,9)*s,
        pos+Vector2(0,11)*s,pos+Vector2(5,9)*s,pos+Vector2(9,1)*s,pos+Vector2(7,-4)*s
    ])
    draw_colored_polygon(chest,Color("466bc8"))
    draw_line(pos+Vector2(-5,7)*s,pos+Vector2(5,7)*s,Color("9d7144"),3.0*s)
    draw_line(pos+Vector2(-5,12)*s,pos+Vector2(-7,20)*s,Color("26313c"),5.0*s)
    draw_line(pos+Vector2(5,12)*s,pos+Vector2(7,20)*s,Color("26313c"),5.0*s)
    var head := pos+Vector2(0,-15)*s
    draw_circle(head,8.5*s,Color("24262b"))
    draw_colored_polygon(PackedVector2Array([
        head+Vector2(0,-9)*s,head+Vector2(7,-4)*s,head+Vector2(7,5)*s,
        head+Vector2(3,8)*s,head+Vector2(-5,7)*s,head+Vector2(-8,3)*s,head+Vector2(-7,-5)*s
    ]),Color("405d8d"))
    draw_rect(Rect2(head+Vector2(-4,-2)*s,Vector2(8,7)*s),Color("d6a47d"))
    draw_rect(Rect2(head+Vector2(-4,-3)*s,Vector2(8,2)*s),Color("49372f"))

func _draw_weapon(pos: Vector2,angle: float,s: float) -> void:
    var tangent := Vector2(cos(angle),sin(angle))
    var side := Vector2(-tangent.y,tangent.x)
    match weapon_id:
        "spear":
            draw_line(pos-tangent*25.0*s,pos+tangent*22.0*s,Color("77563a"),4.0*s)
            var tip := PackedVector2Array([
                pos+tangent*28.0*s,
                pos+tangent*17.0*s+side*7.0*s,
                pos+tangent*17.0*s-side*7.0*s
            ])
            draw_colored_polygon(tip,Color("c4d4cb"))
        "hammer":
            draw_line(pos-tangent*19.0*s,pos+tangent*13.0*s,Color("6e4c35"),5.0*s)
            var head_center := pos+tangent*17.0*s
            draw_line(head_center-side*12.0*s,head_center+side*12.0*s,Color("9fb8c8"),10.0*s)
            draw_line(head_center-side*9.0*s,head_center+side*9.0*s,Color("dce9f1"),3.0*s)
        "twin_blades":
            draw_line(pos-tangent*12.0*s,pos+tangent*13.0*s,Color("e2a073"),5.0*s)
            draw_line(pos-side*7.0*s,pos+side*7.0*s,Color("5e3e30"),3.0*s)
        _:
            draw_line(pos-tangent*13.0*s,pos+tangent*10.0*s,Color("6a4932"),5.0*s)
            var blade := pos+tangent*11.0*s
            draw_line(blade-side*9.0*s,blade+side*9.0*s,Color("c6d0d1"),7.0*s)
