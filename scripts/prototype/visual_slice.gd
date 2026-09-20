extends Node2D

const VIEW := Vector2(390.0, 844.0)
const ART := "res://assets/art/vertical_slice_i/"
const DAY_LENGTH := 27.0
const NIGHT_LENGTH := 25.0

var hero: Sprite2D
var tree: Sprite2D
var hearth: Sprite2D
var backdrop: Sprite2D
var night_wash: ColorRect
var phase_label: Label
var hint_label: Label
var wood_label: Label
var hearth_label: Label
var progress_bar: ProgressBar
var hero_pos := Vector2(196, 590)
var move_input := Vector2.ZERO
var touch_origin := Vector2.ZERO
var touch_position := Vector2.ZERO
var touch_id := -1
var phase_time := 0.0
var anim_time := 0.0
var axe_angle := 0.0
var wood := 0
var build_progress := 0.0
var tree_hp := 5
var tree_hit_cooldown := 0.0
var hearth_hp := 100.0
var phase := 0 # 0 day, 1 dusk, 2 night, 3 result
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var spawn_clock := 0.0
var shot_clock := 0.0
var banner_time := 3.8
var screen_shake := 0.0
var completed := false

func _ready() -> void:
    _make_world()
    _make_hud()
    queue_redraw()

func art_direction_contract() -> String:
    return "CONCEPT_I_CLEAN_CEL_SHADED_ACTION_ADVENTURE"

func _texture(name: String) -> Texture2D:
    return ResourceLoader.load(ART + name) as Texture2D

func _make_world() -> void:
    backdrop = Sprite2D.new()
    backdrop.texture = _texture("forest_arena.webp")
    backdrop.position = VIEW * 0.5
    var tex_size := backdrop.texture.get_size()
    var cover := maxf(VIEW.x / tex_size.x, VIEW.y / tex_size.y)
    backdrop.scale = Vector2.ONE * cover
    backdrop.z_index = -20
    add_child(backdrop)

    tree = _sheet("tree_damage.webp", 4, Vector2(306, 500), 0.39, -1)
    hearth = _sheet("hearth_fire.webp", 4, Vector2(82, 255), 0.47, -2)
    hero = _sheet("hero_walk.webp", 6, hero_pos, 0.32, 5)

    night_wash = ColorRect.new()
    night_wash.color = Color(0.04, 0.09, 0.18, 0.0)
    night_wash.position = Vector2.ZERO
    night_wash.size = VIEW
    night_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    night_wash.z_index = 40
    add_child(night_wash)

func _sheet(file: String, frames: int, at: Vector2, size: float, layer: int) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.texture = _texture(file)
    sprite.hframes = frames
    sprite.position = at
    sprite.scale = Vector2.ONE * size
    sprite.z_index = layer
    add_child(sprite)
    return sprite

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 60
    add_child(layer)

    var top := PanelContainer.new()
    top.position = Vector2(10, 12)
    top.size = Vector2(370, 74)
    top.add_theme_stylebox_override("panel", _panel(Color("eaf3df"), Color("4b653e"), 12, 2))
    layer.add_child(top)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 9)
    top.add_child(row)

    var back := Button.new()
    back.text = "‹"
    back.custom_minimum_size = Vector2(42, 48)
    back.add_theme_font_size_override("font_size", 27)
    back.add_theme_stylebox_override("normal", _panel(Color("ffffff"), Color("759266"), 22, 2))
    back.pressed.connect(_return_home)
    row.add_child(back)

    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)
    phase_label = Label.new()
    phase_label.text = "ДЕНЬ · 27 С"
    phase_label.add_theme_font_size_override("font_size", 13)
    phase_label.add_theme_color_override("font_color", Color("20351f"))
    info.add_child(phase_label)
    progress_bar = ProgressBar.new()
    progress_bar.show_percentage = false
    progress_bar.max_value = DAY_LENGTH
    progress_bar.value = DAY_LENGTH
    progress_bar.custom_minimum_size = Vector2(0, 9)
    progress_bar.add_theme_stylebox_override("background", _panel(Color("c9d9bc"), Color("c9d9bc"), 5, 0))
    progress_bar.add_theme_stylebox_override("fill", _panel(Color("f5b949"), Color("f5b949"), 5, 0))
    info.add_child(progress_bar)

    var stats := VBoxContainer.new()
    row.add_child(stats)
    wood_label = Label.new()
    wood_label.text = "🪵 0"
    wood_label.add_theme_font_size_override("font_size", 12)
    wood_label.add_theme_color_override("font_color", Color("76452b"))
    stats.add_child(wood_label)
    hearth_label = Label.new()
    hearth_label.text = "🔥 100"
    hearth_label.add_theme_font_size_override("font_size", 11)
    hearth_label.add_theme_color_override("font_color", Color("bd523d"))
    stats.add_child(hearth_label)

    hint_label = Label.new()
    hint_label.position = Vector2(32, 102)
    hint_label.size = Vector2(326, 58)
    hint_label.text = "ДОБЫВАЙ ДЕРЕВО · ПОДНЕСИ ЕГО К ОЧАГУ"
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint_label.add_theme_font_size_override("font_size", 10)
    hint_label.add_theme_color_override("font_color", Color.WHITE)
    hint_label.add_theme_stylebox_override("normal", _panel(Color(0.06, 0.12, 0.08, 0.82), Color(1,1,1,0.22), 14, 1))
    layer.add_child(hint_label)

    var badge := Label.new()
    badge.position = Vector2(210, 782)
    badge.size = Vector2(164, 38)
    badge.text = "CONCEPT I · ПРОТОТИП"
    badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    badge.add_theme_font_size_override("font_size", 8)
    badge.add_theme_color_override("font_color", Color("dcead4"))
    badge.add_theme_stylebox_override("normal", _panel(Color(0.05,0.1,0.07,0.72), Color(1,1,1,0.14), 16, 1))
    layer.add_child(badge)

func _panel(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 9
    style.content_margin_right = 9
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    return style

func _process(delta: float) -> void:
    phase_time += delta
    anim_time += delta
    tree_hit_cooldown = maxf(0.0, tree_hit_cooldown - delta)
    banner_time = maxf(0.0, banner_time - delta)
    screen_shake = maxf(0.0, screen_shake - delta)
    _read_keyboard()
    _move_hero(delta)
    _animate_world(delta)
    _update_day_cycle(delta)
    if phase == 2:
        _update_enemies(delta)
        _update_tower(delta)
    _update_projectiles(delta)
    _update_particles(delta)
    _gather_and_build(delta)
    _update_hud()
    queue_redraw()

func _read_keyboard() -> void:
    var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if keyboard.length() > 0.05:
        move_input = keyboard
    elif touch_id < 0:
        move_input = Vector2.ZERO

func _move_hero(delta: float) -> void:
    if phase == 3:
        move_input = Vector2.ZERO
    hero_pos += move_input.limit_length() * 128.0 * delta
    hero_pos.x = clampf(hero_pos.x, 38.0, 352.0)
    hero_pos.y = clampf(hero_pos.y, 175.0, 748.0)
    hero.position = hero_pos
    if absf(move_input.x) > 0.08:
        hero.flip_h = move_input.x < 0.0
    hero.frame = int(anim_time * 9.0) % 6 if move_input.length() > 0.08 else 0

func _animate_world(delta: float) -> void:
    hearth.frame = int(anim_time * 7.0) % 4
    axe_angle += delta * (5.5 if phase < 2 else 8.0)
    night_wash.color.a = move_toward(night_wash.color.a, 0.52 if phase == 2 else 0.0, delta * 0.22)
    if screen_shake > 0.0:
        backdrop.position = VIEW * 0.5 + Vector2(randf_range(-2,2), randf_range(-2,2))
    else:
        backdrop.position = VIEW * 0.5

func _gather_and_build(delta: float) -> void:
    if phase != 0:
        return
    if tree_hp > 0 and hero_pos.distance_to(tree.position) < 84.0 and tree_hit_cooldown <= 0.0:
        tree_hit_cooldown = 0.72
        tree_hp -= 1
        tree.frame = clampi(4 - tree_hp, 0, 3)
        screen_shake = 0.16
        _burst(tree.position + Vector2(0,-20), Color("f1c56d"), 7)
        if tree_hp <= 0:
            wood += 3
            tree.modulate = Color(1,1,1,0.42)
            hint_label.text = "ОТНЕСИ ДРЕВЕСИНУ К ОЧАГУ"
    if wood > 0 and hero_pos.distance_to(hearth.position) < 92.0:
        build_progress = minf(1.0, build_progress + delta * 0.38)
        if build_progress >= 1.0:
            wood = 0
            hint_label.text = "БАШНЯ ГОТОВА · ПРИГОТОВЬСЯ К НОЧИ"
            _burst(Vector2(304,250), Color("ffe48a"), 13)

func _update_day_cycle(_delta: float) -> void:
    if phase == 0 and phase_time >= DAY_LENGTH:
        phase = 1
        phase_time = 0.0
        hint_label.text = "СУМЕРКИ · ВЕРНИСЬ К ОЧАГУ"
    elif phase == 1 and phase_time >= 3.0:
        phase = 2
        phase_time = 0.0
        hint_label.text = "НОЧЬ · ЗАЩИТИ ПОСЛЕДНИЙ ОЧАГ"
        _spawn_enemy("hound")
    elif phase == 2 and phase_time >= NIGHT_LENGTH:
        _finish(true)

func _spawn_enemy(kind: String) -> void:
    var angle := randf_range(-2.7, -0.45)
    var radius := 330.0
    var pos := hearth.position + Vector2(cos(angle), sin(angle)) * radius
    pos.x = clampf(pos.x, 26.0, 364.0)
    pos.y = clampf(pos.y, 150.0, 760.0)
    var sprite := _sheet("hound_run.webp" if kind == "hound" else "husk_walk.webp", 6, pos, 0.27 if kind == "hound" else 0.30, 3)
    enemies.append({"node":sprite, "hp":3.0 if kind == "hound" else 5.0, "speed":58.0 if kind == "hound" else 34.0, "kind":kind, "attack":0.0, "flash":0.0})

func _update_enemies(delta: float) -> void:
    spawn_clock += delta
    var interval := 3.3 if phase_time < 15.0 else 2.25
    if spawn_clock >= interval:
        spawn_clock = 0.0
        _spawn_enemy("hound" if enemies.size() % 2 == 0 else "husk")
    for enemy in enemies.duplicate():
        var node: Sprite2D = enemy.node
        enemy.flash = maxf(0.0, float(enemy.flash) - delta)
        node.modulate = Color("fff0ce") if enemy.flash > 0 else Color.WHITE
        var target := hearth.position if hero_pos.distance_to(node.position) > 105.0 else hero_pos
        var direction := node.position.direction_to(target)
        node.position += direction * float(enemy.speed) * delta
        node.flip_h = direction.x < 0
        node.frame = int(anim_time * 9.0 + enemies.find(enemy)) % 6
        enemy.attack = maxf(0.0, float(enemy.attack) - delta)
        if node.position.distance_to(hearth.position) < 65.0 and enemy.attack <= 0.0:
            enemy.attack = 1.0
            hearth_hp -= 8.0
            screen_shake = 0.22
            _burst(hearth.position, Color("ff7b55"), 5)
            if hearth_hp <= 0.0:
                _finish(false)
        # Orbiting axes are the readable, automatic melee loop.
        for i in 2:
            var axe_pos := hero_pos + Vector2.from_angle(axe_angle + PI * i) * 52.0
            if node.position.distance_to(axe_pos) < 32.0 and enemy.flash <= 0.0:
                enemy.hp = float(enemy.hp) - 1.0
                enemy.flash = 0.24
                _burst(node.position, Color("fff2a6"), 4)
                if enemy.hp <= 0.0:
                    _kill_enemy(enemy)
                break

func _kill_enemy(enemy: Dictionary) -> void:
    if not enemies.has(enemy):
        return
    var node: Sprite2D = enemy.node
    _burst(node.position, Color("bde77b"), 9)
    enemies.erase(enemy)
    node.queue_free()

func _update_tower(delta: float) -> void:
    if build_progress < 1.0 or enemies.is_empty():
        return
    shot_clock -= delta
    if shot_clock <= 0.0:
        shot_clock = 0.9
        var target: Sprite2D = enemies[0].node
        projectiles.append({"pos":Vector2(302,215), "target":target, "life":2.0})

func _update_projectiles(delta: float) -> void:
    for shot in projectiles.duplicate():
        shot.life = float(shot.life) - delta
        var target: Sprite2D = shot.target
        if not is_instance_valid(target) or shot.life <= 0.0:
            projectiles.erase(shot)
            continue
        shot.pos = Vector2(shot.pos).move_toward(target.position, 290.0 * delta)
        if Vector2(shot.pos).distance_to(target.position) < 18.0:
            for enemy in enemies.duplicate():
                if enemy.node == target:
                    enemy.hp = float(enemy.hp) - 2.0
                    enemy.flash = 0.25
                    _burst(target.position, Color("ffe27a"), 6)
                    if enemy.hp <= 0.0:
                        _kill_enemy(enemy)
                    break
            projectiles.erase(shot)

func _burst(at: Vector2, color: Color, count: int) -> void:
    for i in count:
        particles.append({"pos":at, "vel":Vector2.from_angle(randf()*TAU)*randf_range(24,72), "life":randf_range(0.35,0.75), "color":color})

func _update_particles(delta: float) -> void:
    for mote in particles.duplicate():
        mote.life = float(mote.life) - delta
        mote.pos = Vector2(mote.pos) + Vector2(mote.vel) * delta
        mote.vel = Vector2(mote.vel) * 0.94
        if mote.life <= 0.0:
            particles.erase(mote)

func _finish(win: bool) -> void:
    if completed:
        return
    completed = true
    phase = 3
    hint_label.text = "ОЧАГ ВЫСТОЯЛ · VERTICAL SLICE ПРОЙДЕН" if win else "ОЧАГ ПОГАС · ПОПРОБУЙ ЕЩЁ РАЗ"
    hint_label.add_theme_color_override("font_color", Color("fff0aa") if win else Color("ffb0a0"))

func _update_hud() -> void:
    wood_label.text = "🪵 %d" % wood
    hearth_label.text = "🔥 %d" % maxi(0, int(hearth_hp))
    if phase == 0:
        var left := maxf(0.0, DAY_LENGTH - phase_time)
        phase_label.text = "ДЕНЬ · %d С" % ceili(left)
        progress_bar.max_value = DAY_LENGTH
        progress_bar.value = left
    elif phase == 1:
        phase_label.text = "СУМЕРКИ"
        progress_bar.value = 0
    elif phase == 2:
        var left := maxf(0.0, NIGHT_LENGTH - phase_time)
        phase_label.text = "НОЧЬ · %d С" % ceili(left)
        progress_bar.max_value = NIGHT_LENGTH
        progress_bar.value = left
    else:
        phase_label.text = "ИТОГ ВЫЛАЗКИ"
        progress_bar.value = 0

func _draw() -> void:
    # Hearth safety aura and build site make goals legible without debug shapes.
    draw_circle(hearth.position, 76.0, Color(1.0,0.72,0.25,0.10))
    draw_arc(hearth.position, 78.0, 0, TAU, 48, Color(1.0,0.83,0.42,0.34), 2.0)
    _draw_tower(Vector2(304,252), build_progress)
    for i in 2:
        var a := axe_angle + PI * i
        var p := hero_pos + Vector2.from_angle(a) * 52.0
        draw_line(p + Vector2(-2,11).rotated(a), p + Vector2(3,-11).rotated(a), Color("6b442d"), 4.0, true)
        var blade := PackedVector2Array([p+Vector2(-8,-12).rotated(a), p+Vector2(7,-15).rotated(a), p+Vector2(9,-5).rotated(a)])
        draw_colored_polygon(blade, Color("dfe9df"))
        draw_polyline(PackedVector2Array([blade[0],blade[1],blade[2],blade[0]]), Color("314333"), 2.0)
    for shot in projectiles:
        draw_circle(shot.pos, 6.0, Color("fff09a"))
        draw_circle(shot.pos, 12.0, Color(1,0.75,0.18,0.18))
    for mote in particles:
        var c: Color = mote.color
        c.a = clampf(float(mote.life)*1.8, 0.0, 1.0)
        draw_circle(mote.pos, 3.0, c)
    _draw_joystick()
    if phase == 2:
        for enemy in enemies:
            var node: Sprite2D = enemy.node
            if node.position.distance_to(hearth.position) < 92.0:
                draw_arc(node.position, 29.0, 0, TAU, 24, Color(0.95,0.2,0.12,0.58), 3.0)

func _draw_tower(at: Vector2, amount: float) -> void:
    draw_circle(at, 43.0, Color(0.1,0.18,0.1,0.18))
    if amount <= 0.01:
        draw_arc(at, 31, 0, TAU, 24, Color(1,1,1,0.42), 2.0)
        draw_string(ThemeDB.fallback_font, at+Vector2(-32,53), "МЕСТО БАШНИ", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
        return
    var h := 68.0 * amount
    draw_rect(Rect2(at.x-22, at.y-h, 44, h), Color("9b663d"))
    draw_rect(Rect2(at.x-25, at.y-h-8, 50, 12), Color("d8a355"))
    draw_line(Vector2(at.x-22,at.y-h), Vector2(at.x-22,at.y), Color("3f3826"), 3)
    draw_line(Vector2(at.x+22,at.y-h), Vector2(at.x+22,at.y), Color("3f3826"), 3)
    if amount >= 1.0:
        draw_circle(Vector2(at.x,at.y-h-7), 8, Color("fff09a"))

func _draw_joystick() -> void:
    var base := touch_origin if touch_id >= 0 else Vector2(74,752)
    var knob := touch_position if touch_id >= 0 else base
    draw_circle(base, 42, Color(0.05,0.10,0.07,0.28))
    draw_arc(base, 42, 0, TAU, 32, Color(1,1,1,0.24), 2)
    draw_circle(knob, 18, Color(0.88,0.96,0.82,0.48))

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < VIEW.x * 0.62 and event.position.y > 150:
            touch_id = event.index
            touch_origin = event.position
            touch_position = event.position
            move_input = Vector2.ZERO
        elif not event.pressed and event.index == touch_id:
            touch_id = -1
            move_input = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == touch_id:
        var delta := event.position - touch_origin
        touch_position = touch_origin + delta.limit_length(42.0)
        move_input = delta / 42.0
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed and event.position.x < VIEW.x * 0.62 and event.position.y > 150:
                touch_id = 999
                touch_origin = event.position
                touch_position = event.position
            elif not event.pressed and touch_id == 999:
                touch_id = -1
                move_input = Vector2.ZERO
    elif event is InputEventMouseMotion and touch_id == 999:
        var delta := event.position - touch_origin
        touch_position = touch_origin + delta.limit_length(42.0)
        move_input = delta / 42.0

func _return_home() -> void:
    get_tree().change_scene_to_file("res://scenes/app.tscn")
