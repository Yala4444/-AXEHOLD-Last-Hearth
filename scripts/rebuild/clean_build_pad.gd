class_name AXEHOLDCleanBuildPad
extends BuildPad

func _draw() -> void:
    _draw_ground_socket()
    if built:
        match build_type:
            "wall":
                _draw_wall()
            "forge":
                _draw_forge()
            "turret":
                _draw_tower()
            "shrine":
                _draw_shrine()
        _draw_level_badge_clean()
    else:
        if focused:
            _draw_blueprint_clean()
        else:
            _draw_dormant_marker()

func _draw_ground_socket() -> void:
    var rx: float = 34.0 if built else 28.0
    var ry: float = 8.0 if built else 6.0
    draw_set_transform(Vector2(0,22),0.0,Vector2(1.0,ry/rx))
    draw_circle(Vector2.ZERO,rx,Color(0.02,0.03,0.02,0.23 if built else 0.14))
    draw_circle(Vector2.ZERO,rx*0.82,Color(0.28,0.19,0.10,0.15))
    draw_set_transform(Vector2.ZERO,0.0,Vector2.ONE)
    var grass := Color(0.24,0.40,0.18,0.38)
    draw_line(Vector2(-27,21),Vector2(-25,13),grass,1.2)
    draw_line(Vector2(26,22),Vector2(23,14),grass,1.2)

func _draw_dormant_marker() -> void:
    # C7 mobile-first rule: unused build pads stay almost invisible until the
    # player approaches them. The world should read as a forest, not a UI map.
    var line := Color(0.50,0.36,0.19,0.22)
    draw_line(Vector2(-10,7),Vector2(-10,-5),line,1.1)
    draw_line(Vector2(10,7),Vector2(10,-5),line,1.1)
    draw_line(Vector2(-10,-3),Vector2(10,-3),Color(0.64,0.48,0.27,0.16),1.0)
    draw_arc(Vector2.ZERO,13.0,0.15,PI-0.15,16,Color(0.81,0.64,0.33,0.11),1.0)


func _draw_blueprint_clean() -> void:
    var breathe: float = 0.5 + 0.5 * sin(idle_time * 2.6)
    var ring := Color(0.86,0.67,0.31,0.76 if affordable else 0.52)
    draw_arc(Vector2.ZERO,25.0 + breathe*1.5,0.0,TAU,28,ring,1.6)
    draw_circle(Vector2.ZERO,18.0,Color(0.05,0.08,0.06,0.16))
    match build_type:
        "wall":
            for x: float in [-12.0,-4.0,4.0,12.0]:
                draw_rect(Rect2(x-2,-11,4,22),Color(0.50,0.32,0.16,0.58))
        "forge":
            draw_rect(Rect2(-12,-7,24,13),Color(0.40,0.29,0.20,0.54))
            draw_circle(Vector2(7,-2),5,Color(0.92,0.42,0.16,0.48))
        "turret":
            draw_rect(Rect2(-5,-15,10,30),Color(0.44,0.31,0.18,0.54))
            draw_rect(Rect2(-13,-15,26,5),Color(0.52,0.34,0.17,0.54))
        "shrine":
            draw_circle(Vector2.ZERO,10,Color(0.38,0.52,0.43,0.44))
            draw_arc(Vector2.ZERO,14,0,TAU,20,Color(0.68,0.82,0.63,0.55),1.3)

func _draw_wall() -> void:
    for x: float in [-18.0,-9.0,0.0,9.0,18.0]:
        var h: float = 31.0 - absf(x)*0.18
        draw_colored_polygon(PackedVector2Array([
            Vector2(x-4,16),Vector2(x-4,16-h),Vector2(x,-20-h*0.08),
            Vector2(x+4,16-h),Vector2(x+4,16)
        ]),Color("8d5a2d"))
        draw_line(Vector2(x-4,6),Vector2(x+4,6),Color("4f321b"),1.2)
    draw_line(Vector2(-23,9),Vector2(23,9),Color("5d3b20"),3.2)

func _draw_forge() -> void:
    draw_rect(Rect2(-24,-6,48,23),Color("5d4431"))
    draw_rect(Rect2(-19,-17,38,14),Color("8b6544"))
    draw_circle(Vector2(10,1),9.0,Color("e77827"))
    draw_circle(Vector2(10,1),5.0,Color("ffd06a"))
    draw_rect(Rect2(-19,5,18,4),Color("2d2d29"))
    draw_rect(Rect2(-12,-26,7,20),Color("50443d"))

func _draw_tower() -> void:
    draw_rect(Rect2(-12,-31,24,47),Color("76502d"))
    draw_rect(Rect2(-20,-34,40,8),Color("9b6936"))
    draw_line(Vector2(-8,-23),Vector2(-8,10),Color("3b2b1d"),2.0)
    draw_line(Vector2(8,-23),Vector2(8,10),Color("3b2b1d"),2.0)
    draw_circle(Vector2(0,-31),4.2,Color("f3b447"))

func _draw_shrine() -> void:
    draw_colored_polygon(PackedVector2Array([
        Vector2(-18,15),Vector2(-13,-18),Vector2(0,-30),Vector2(13,-18),Vector2(18,15)
    ]),Color("6a7667"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-8,8),Vector2(-6,-11),Vector2(0,-18),Vector2(6,-11),Vector2(8,8)
    ]),Color("b9c3a7"))
    draw_circle(Vector2(0,-5),4.5,Color("e5b95b"))
    draw_arc(Vector2(0,-5),9.0,0,TAU,24,Color(0.89,0.74,0.35,0.42),1.4)

func _draw_level_badge_clean() -> void:
    if level < 2:
        return
    draw_circle(Vector2(23,-24),8.0,Color(0.09,0.11,0.09,0.92))
    draw_circle(Vector2(23,-24),6.0,Color("d5a652"))
    draw_circle(Vector2(23,-24),2.2,Color("fff0b0"))
