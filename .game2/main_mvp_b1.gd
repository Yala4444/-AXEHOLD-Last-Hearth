extends Node2D

const VIEW_SIZE := Vector2(390.0, 844.0)
const WORLD_SIZE := Vector2(1600.0, 2200.0)
const WORLD_RECT := Rect2(Vector2.ZERO, WORLD_SIZE)

const HERO_SPEED := 205.0
const HERO_RADIUS := 20.0
const JOYSTICK_RADIUS := 66.0
const JOYSTICK_DEADZONE := 0.10
const CAMERA_DAMPING := 9.5
const GATHER_INTERVAL := 0.46
const GATHER_EXTRA_RADIUS := 30.0
const CARRY_LIMIT := 20

const PAUSE_RECT := Rect2(330.0, 16.0, 44.0, 44.0)
const RESUME_RECT := Rect2(80.0, 465.0, 230.0, 58.0)

const HEARTH_WORLD_POS := Vector2(800.0, 1100.0)

var hero_idle_tex: Texture2D = preload("res://assets/hero_wanderer.webp")
var hero_walk_tex: Texture2D = preload("res://assets/hero_walk.webp")
var tree_tex: Texture2D = preload("res://assets/harvest_tree.png")
var stone_tex: Texture2D = preload("res://assets/stone_deposit.png")
var hearth_tex: Texture2D = preload("res://assets/last_hearth.png")

var font: Font
var rng := RandomNumberGenerator.new()

var hero_pos := HEARTH_WORLD_POS + Vector2(0.0, 210.0)
var hero_facing := Vector2(0.0, -1.0)
var hero_moving := false
var walk_phase := 0.0

var camera_pos := hero_pos
var camera_target := hero_pos

var joystick_active := false
var joystick_origin := Vector2.ZERO
var joystick_knob := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var joystick_touch_index := -1
var mouse_dragging := false

var paused := false

var carried_wood := 0
var carried_stone := 0
var gather_cd := 0.0
var gather_phase := 0.0
var active_resource_index := -1
var floaters: Array[Dictionary] = []

var obstacles: Array[Dictionary] = []
var decor: Array[Dictionary] = []
var fences: Array[Dictionary] = []
var paths: Array[PackedVector2Array] = []


func _ready() -> void:
	font = ThemeDB.fallback_font
	rng.seed = 41297
	_build_world()
	camera_pos = _clamped_camera_target(hero_pos)
	camera_target = camera_pos
	queue_redraw()


func _process(delta: float) -> void:
	if paused:
		queue_redraw()
		return

	var input_vector := _movement_input()
	hero_moving = input_vector.length() > JOYSTICK_DEADZONE

	if hero_moving:
		var direction := input_vector.normalized()
		hero_facing = direction
		var speed_scale := clampf(input_vector.length(), 0.0, 1.0)
		_move_hero(direction * HERO_SPEED * speed_scale * delta)
		walk_phase += delta * (7.0 + speed_scale * 3.0)
	else:
		walk_phase = lerpf(walk_phase, roundf(walk_phase / TAU) * TAU, minf(1.0, delta * 8.0))

	gather_cd = maxf(0.0, gather_cd - delta)
	gather_phase += delta * 8.0
	_update_gathering(delta)
	_update_floaters(delta)

	camera_target = _clamped_camera_target(hero_pos)
	var camera_t := 1.0 - exp(-CAMERA_DAMPING * delta)
	camera_pos = camera_pos.lerp(camera_target, camera_t)
	queue_redraw()


func _movement_input() -> Vector2:
	if joystick_active:
		return joystick_vector

	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if keyboard.length() > 0.0:
		return keyboard
	return Vector2.ZERO


func _move_hero(delta_move: Vector2) -> void:
	var target_x := Vector2(
		clampf(hero_pos.x + delta_move.x, HERO_RADIUS, WORLD_SIZE.x - HERO_RADIUS),
		hero_pos.y
	)
	if not _collides(target_x):
		hero_pos.x = target_x.x

	var target_y := Vector2(
		hero_pos.x,
		clampf(hero_pos.y + delta_move.y, HERO_RADIUS + 12.0, WORLD_SIZE.y - HERO_RADIUS)
	)
	if not _collides(target_y):
		hero_pos.y = target_y.y


func _collides(candidate: Vector2) -> bool:
	for obstacle: Dictionary in obstacles:
		if bool(obstacle.get("depleted", false)):
			continue
		var pos: Vector2 = obstacle["pos"]
		var radius := float(obstacle.get("radius", 28.0))
		if candidate.distance_to(pos) < HERO_RADIUS + radius:
			return true
	return false


func _update_gathering(_delta: float) -> void:
	active_resource_index = -1
	if carried_wood + carried_stone >= CARRY_LIMIT:
		return

	var nearest_distance := INF
	for i in range(obstacles.size()):
		var obstacle: Dictionary = obstacles[i]
		var kind := String(obstacle.get("kind", ""))
		if kind != "tree" and kind != "stone":
			continue
		if bool(obstacle.get("depleted", false)):
			continue

		var pos: Vector2 = obstacle["pos"]
		var radius := float(obstacle.get("radius", 30.0))
		var distance := hero_pos.distance_to(pos)
		var interact_distance := HERO_RADIUS + radius + GATHER_EXTRA_RADIUS
		if distance <= interact_distance and distance < nearest_distance:
			nearest_distance = distance
			active_resource_index = i

	if active_resource_index < 0 or gather_cd > 0.0:
		return

	var resource_index := active_resource_index
	var resource: Dictionary = obstacles[resource_index]
	var kind := String(resource.get("kind", "tree"))
	var amount := int(resource.get("amount", 1)) - 1
	resource["amount"] = amount
	gather_cd = GATHER_INTERVAL

	if kind == "tree":
		carried_wood += 1
		_add_floater(resource["pos"], "+1 дерево", Color("#e4b46d"))
	else:
		carried_stone += 1
		_add_floater(resource["pos"], "+1 камень", Color("#c0c7c5"))

	if amount <= 0:
		resource["depleted"] = true
		active_resource_index = -1

	obstacles[resource_index] = resource


func _add_floater(world_pos: Vector2, text: String, color: Color) -> void:
	floaters.append({
		"pos": world_pos,
		"text": text,
		"color": color,
		"life": 0.95
	})


func _update_floaters(delta: float) -> void:
	for i in range(floaters.size() - 1, -1, -1):
		var item: Dictionary = floaters[i]
		var life := float(item.get("life", 0.0)) - delta
		var pos: Vector2 = item["pos"]
		pos.y -= 22.0 * delta
		item["life"] = life
		item["pos"] = pos
		floaters[i] = item
		if life <= 0.0:
			floaters.remove_at(i)


func _clamped_camera_target(world_pos: Vector2) -> Vector2:
	var half := VIEW_SIZE * 0.5
	return Vector2(
		clampf(world_pos.x, half.x, WORLD_SIZE.x - half.x),
		clampf(world_pos.y, half.y, WORLD_SIZE.y - half.y)
	)


func _world_to_screen(world_pos: Vector2) -> Vector2:
	return world_pos - camera_pos + VIEW_SIZE * 0.5


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return screen_pos + camera_pos - VIEW_SIZE * 0.5


func _build_world() -> void:
	obstacles.clear()
	decor.clear()
	fences.clear()
	paths.clear()

	paths.append(PackedVector2Array([
		Vector2(800, 1100), Vector2(800, 760), Vector2(720, 520), Vector2(620, 280)
	]))
	paths.append(PackedVector2Array([
		Vector2(800, 1100), Vector2(1110, 1080), Vector2(1320, 940), Vector2(1490, 790)
	]))
	paths.append(PackedVector2Array([
		Vector2(800, 1100), Vector2(550, 1260), Vector2(360, 1500), Vector2(230, 1810)
	]))
	paths.append(PackedVector2Array([
		Vector2(800, 1100), Vector2(920, 1440), Vector2(1040, 1730), Vector2(1220, 2030)
	]))

	obstacles.append({"kind":"hearth", "pos":HEARTH_WORLD_POS, "radius":60.0, "scale":1.0})

	var tree_positions: Array[Vector2] = [
		Vector2(570, 920), Vector2(1040, 830), Vector2(1170, 1260), Vector2(510, 1500),
		Vector2(1260, 1650), Vector2(340, 620), Vector2(1360, 520), Vector2(820, 1900)
	]
	for p: Vector2 in tree_positions:
		obstacles.append({
			"kind":"tree", "pos":p, "radius":35.0, "scale":rng.randf_range(0.92, 1.10),
			"amount":5, "max_amount":5, "depleted":false
		})

	var stone_positions: Array[Vector2] = [
		Vector2(620, 470), Vector2(1230, 920), Vector2(410, 1210), Vector2(1080, 1540), Vector2(1420, 1900)
	]
	for p: Vector2 in stone_positions:
		obstacles.append({
			"kind":"stone", "pos":p, "radius":31.0, "scale":rng.randf_range(0.92, 1.08),
			"amount":4, "max_amount":4, "depleted":false
		})

	var fence_specs := [
		{"pos":Vector2(690, 990), "length":96.0, "angle":0.08},
		{"pos":Vector2(930, 1015), "length":88.0, "angle":-0.10},
		{"pos":Vector2(760, 1190), "length":78.0, "angle":0.0},
		{"pos":Vector2(1010, 1370), "length":86.0, "angle":0.45},
		{"pos":Vector2(515, 760), "length":82.0, "angle":-0.35}
	]
	for spec: Dictionary in fence_specs:
		fences.append(spec)

	for i in range(42):
		var p := Vector2(rng.randf_range(90.0, WORLD_SIZE.x - 90.0), rng.randf_range(120.0, WORLD_SIZE.y - 100.0))
		if p.distance_to(HEARTH_WORLD_POS) < 180.0:
			continue
		if _near_big_object(p, 64.0):
			continue
		var kind := "flower" if rng.randf() < 0.48 else "bush"
		decor.append({"kind":kind, "pos":p, "variant":rng.randi_range(0, 2)})


func _near_big_object(point: Vector2, extra: float) -> bool:
	for obstacle: Dictionary in obstacles:
		var pos: Vector2 = obstacle["pos"]
		var radius := float(obstacle.get("radius", 28.0))
		if point.distance_to(pos) < radius + extra:
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if paused:
				if RESUME_RECT.has_point(event.position):
					_toggle_pause()
				get_viewport().set_input_as_handled()
				return
			if PAUSE_RECT.has_point(event.position):
				_toggle_pause()
				get_viewport().set_input_as_handled()
				return
			if not joystick_active:
				joystick_touch_index = event.index
				_start_joystick(event.position)
		elif joystick_active and event.index == joystick_touch_index:
			_stop_joystick()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		if not paused and joystick_active and event.index == joystick_touch_index:
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if paused:
				if RESUME_RECT.has_point(event.position):
					_toggle_pause()
				get_viewport().set_input_as_handled()
				return
			if PAUSE_RECT.has_point(event.position):
				_toggle_pause()
				get_viewport().set_input_as_handled()
				return
			mouse_dragging = true
			joystick_touch_index = -2
			_start_joystick(event.position)
		else:
			mouse_dragging = false
			_stop_joystick()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and mouse_dragging and joystick_active and not paused:
		_update_joystick(event.position)
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	paused = not paused
	_stop_joystick()
	queue_redraw()


func _start_joystick(screen_pos: Vector2) -> void:
	joystick_active = true
	joystick_origin = screen_pos
	joystick_knob = screen_pos
	joystick_vector = Vector2.ZERO


func _update_joystick(screen_pos: Vector2) -> void:
	var offset := screen_pos - joystick_origin
	if offset.length() > JOYSTICK_RADIUS:
		offset = offset.normalized() * JOYSTICK_RADIUS
	joystick_knob = joystick_origin + offset
	joystick_vector = offset / JOYSTICK_RADIUS
	if joystick_vector.length() < JOYSTICK_DEADZONE:
		joystick_vector = Vector2.ZERO


func _stop_joystick() -> void:
	joystick_active = false
	joystick_vector = Vector2.ZERO
	joystick_touch_index = -1
	mouse_dragging = false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("#1b281d"))
	_draw_ground()
	_draw_paths()
	_draw_decor()
	_draw_fences()
	_draw_world_objects()
	_draw_floaters()
	_draw_hud()
	_draw_joystick()
	if paused:
		_draw_pause_overlay()


func _draw_ground() -> void:
	# Никакой технической сетки: земля должна восприниматься как мир, а не редактор.
	for i in range(14):
		var seed_x := fmod(float(i * 173) - camera_pos.x * 0.16, VIEW_SIZE.x + 180.0) - 90.0
		var seed_y := fmod(float(i * 257) - camera_pos.y * 0.12, VIEW_SIZE.y + 220.0) - 110.0
		var radius := 42.0 + float((i * 19) % 52)
		draw_circle(Vector2(seed_x, seed_y), radius, Color(0.10, 0.17, 0.11, 0.075))


func _draw_paths() -> void:
	# Тёплая красно-коричневая земля, уже и мягче прежних бежевых "полос".
	for path: PackedVector2Array in paths:
		var points := PackedVector2Array()
		for world_point: Vector2 in path:
			points.append(_world_to_screen(world_point))
		if points.size() < 2:
			continue
		draw_polyline(points, Color("#5f352d"), 74.0, true)
		draw_polyline(points, Color("#955642"), 64.0, true)
		draw_polyline(points, Color("#a9654c"), 54.0, true)
		draw_polyline(points, Color(0.83, 0.55, 0.38, 0.16), 2.0, true)

		for segment in range(points.size() - 1):
			var a := points[segment]
			var b := points[segment + 1]
			for step in range(1, 5):
				var t := float(step) / 5.0
				var p := a.lerp(b, t)
				var n := (b - a).normalized().orthogonal()
				var offset := sin(float(segment * 7 + step * 11)) * 15.0
				draw_circle(p + n * offset, 1.6, Color(0.31, 0.18, 0.14, 0.26))


func _draw_decor() -> void:
	for item: Dictionary in decor:
		var p := _world_to_screen(item["pos"])
		if not _on_screen(p, 28.0):
			continue
		var kind := String(item.get("kind", "flower"))
		if kind == "flower":
			_draw_flower(p, int(item.get("variant", 0)))
		else:
			_draw_small_bush(p, int(item.get("variant", 0)))


func _draw_fences() -> void:
	for fence: Dictionary in fences:
		var p := _world_to_screen(fence["pos"])
		if not _on_screen(p, 90.0):
			continue
		var length := float(fence.get("length", 80.0))
		var angle := float(fence.get("angle", 0.0))
		var dir := Vector2(cos(angle), sin(angle))
		var normal := Vector2(-dir.y, dir.x)
		var a := p - dir * length * 0.5
		var b := p + dir * length * 0.5
		draw_line(a, b, Color("#65442c"), 7.0, true)
		draw_line(a + normal * 13.0, b + normal * 13.0, Color("#6f4a2e"), 7.0, true)
		for t in [0.0, 0.5, 1.0]:
			var post := a.lerp(b, t)
			draw_line(post - normal * 5.0, post + normal * 22.0, Color("#4e3222"), 8.0, true)


func _draw_world_objects() -> void:
	var entries: Array[Dictionary] = []
	for obstacle: Dictionary in obstacles:
		entries.append({"kind":obstacle["kind"], "pos":obstacle["pos"], "data":obstacle})
	entries.append({"kind":"hero", "pos":hero_pos, "data":{}})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float((a["pos"] as Vector2).y) < float((b["pos"] as Vector2).y))

	for entry: Dictionary in entries:
		var kind := String(entry["kind"])
		var world_pos: Vector2 = entry["pos"]
		var screen_pos := _world_to_screen(world_pos)
		if not _on_screen(screen_pos, 130.0):
			continue
		if kind == "hero":
			_draw_hero(screen_pos)
		elif kind == "hearth":
			_draw_hearth(screen_pos)
		elif kind == "tree":
			_draw_tree(screen_pos, entry["data"])
		elif kind == "stone":
			_draw_stone(screen_pos, entry["data"])


func _draw_hero(screen_pos: Vector2) -> void:
	var bob := sin(walk_phase * 1.35) * 1.0 if hero_moving else 0.0
	var shadow_pos := screen_pos + Vector2(0.0, 24.0)
	_draw_ellipse(shadow_pos, Vector2(24.0, 8.0), Color(0.02, 0.03, 0.02, 0.32))
	_draw_cargo(screen_pos + Vector2(0.0, bob))

	var flip_x := hero_facing.x < -0.08
	draw_set_transform(screen_pos + Vector2(0.0, bob), 0.0, Vector2(-1.0 if flip_x else 1.0, 1.0))
	if hero_moving:
		# hero_walk.webp — три реальные позы шага 362x362, а не покачивание одной картинки.
		var frame := int(floor(walk_phase * 0.85)) % 3
		var src := Rect2(Vector2(float(frame) * 362.0, 0.0), Vector2(362.0, 362.0))
		draw_texture_rect_region(hero_walk_tex, Rect2(Vector2(-50.0, -63.0), Vector2(100.0, 100.0)), src)
	else:
		draw_texture_rect(hero_idle_tex, Rect2(Vector2(-42.0, -72.0), Vector2(84.0, 112.0)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if active_resource_index >= 0:
		var swing := sin(gather_phase) * 0.55
		var hand := screen_pos + Vector2(20.0, -6.0 + bob)
		var tip := hand + Vector2(cos(-0.9 + swing), sin(-0.9 + swing)) * 27.0
		draw_line(hand, tip, Color("#d8c5a2"), 3.0, true)
		draw_line(tip + Vector2(-5, -2), tip + Vector2(5, 3), Color("#aeb3ad"), 5.0, true)


func _draw_cargo(screen_pos: Vector2) -> void:
	var total := carried_wood + carried_stone
	if total <= 0:
		return

	var visible_logs := mini(carried_wood, 5)
	for i in range(visible_logs):
		var p := screen_pos + Vector2(-25.0 + float(i % 2) * 13.0, -18.0 - float(i / 2) * 8.0)
		draw_line(p, p + Vector2(15, 1), Color("#9f6f3f"), 6.0, true)
		draw_circle(p, 3.2, Color("#c18a52"))

	var visible_stones := mini(carried_stone, 4)
	for i in range(visible_stones):
		var p := screen_pos + Vector2(23.0 + float(i % 2) * 10.0, -16.0 - float(i / 2) * 9.0)
		draw_circle(p, 5.0, Color("#8e9895"))

	if total > 6:
		draw_string(font, screen_pos + Vector2(-18, -55), "x%d" % total, HORIZONTAL_ALIGNMENT_CENTER, 36, 11, Color("#f2e6ce"))


func _draw_hearth(screen_pos: Vector2) -> void:
	_draw_ellipse(screen_pos + Vector2(0, 22), Vector2(62, 23), Color(0.02, 0.02, 0.01, 0.28))
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.025
	draw_set_transform(screen_pos, 0.0, Vector2(pulse, pulse))
	draw_texture_rect(hearth_tex, Rect2(Vector2(-74.0, -74.0), Vector2(148.0, 148.0)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for i in range(3):
		var angle := Time.get_ticks_msec() * 0.0016 + float(i) * TAU / 3.0
		var ember := screen_pos + Vector2(cos(angle) * (20.0 + i * 4.0), -25.0 - i * 8.0)
		draw_circle(ember, 2.4, Color(1.0, 0.61, 0.18, 0.72))


func _draw_tree(screen_pos: Vector2, data: Dictionary) -> void:
	if bool(data.get("depleted", false)):
		_draw_ellipse(screen_pos + Vector2(0, 16), Vector2(24, 8), Color(0.02, 0.03, 0.02, 0.22))
		draw_rect(Rect2(screen_pos + Vector2(-10, -4), Vector2(20, 18)), Color("#6f4d31"))
		draw_circle(screen_pos + Vector2(0, -4), 10.0, Color("#9b6c43"))
		return

	var scale_value := float(data.get("scale", 1.0))
	_draw_ellipse(screen_pos + Vector2(0, 28), Vector2(39, 13), Color(0.02, 0.03, 0.02, 0.26))
	draw_set_transform(screen_pos, 0.0, Vector2(scale_value, scale_value))
	draw_texture_rect(tree_tex, Rect2(Vector2(-58.0, -104.0), Vector2(116.0, 145.0)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_resource_bar(screen_pos + Vector2(0, -88), data)


func _draw_stone(screen_pos: Vector2, data: Dictionary) -> void:
	if bool(data.get("depleted", false)):
		for off in [Vector2(-12, 5), Vector2(0, 0), Vector2(12, 6)]:
			draw_circle(screen_pos + off, 7.0, Color("#69716f"))
		return

	var scale_value := float(data.get("scale", 1.0))
	_draw_ellipse(screen_pos + Vector2(0, 20), Vector2(35, 11), Color(0.02, 0.03, 0.02, 0.24))
	draw_set_transform(screen_pos, 0.0, Vector2(scale_value, scale_value))
	draw_texture_rect(stone_tex, Rect2(Vector2(-48.0, -55.0), Vector2(96.0, 86.0)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_resource_bar(screen_pos + Vector2(0, -55), data)


func _draw_resource_bar(screen_pos: Vector2, data: Dictionary) -> void:
	var amount := float(data.get("amount", 1))
	var max_amount := maxf(1.0, float(data.get("max_amount", 1)))
	if amount >= max_amount:
		return
	var width := 54.0
	draw_rect(Rect2(screen_pos + Vector2(-width * 0.5, 0), Vector2(width, 5)), Color(0.04, 0.05, 0.04, 0.55))
	draw_rect(Rect2(screen_pos + Vector2(-width * 0.5, 0), Vector2(width * clampf(amount / max_amount, 0.0, 1.0), 5)), Color("#d9bd78"))


func _draw_flower(p: Vector2, variant: int) -> void:
	var stem := Color("#5f7d4d")
	draw_line(p + Vector2(0, 8), p, stem, 2.0)
	var petal := Color("#f0ead9")
	if variant == 1:
		petal = Color("#d9c9ef")
	elif variant == 2:
		petal = Color("#f3dba4")
	for offset in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
		draw_circle(p + offset, 2.3, petal)
	draw_circle(p, 1.8, Color("#c8a24c"))


func _draw_small_bush(p: Vector2, variant: int) -> void:
	var base := Color("#49693f")
	if variant == 1:
		base = Color("#547846")
	elif variant == 2:
		base = Color("#3f6140")
	draw_circle(p + Vector2(-6, 4), 8.0, base)
	draw_circle(p + Vector2(4, 1), 10.0, base.lightened(0.06))
	draw_circle(p + Vector2(10, 7), 6.0, base.darkened(0.05))


func _draw_floaters() -> void:
	for item: Dictionary in floaters:
		var p := _world_to_screen(item["pos"])
		if not _on_screen(p, 80.0):
			continue
		var life := clampf(float(item.get("life", 0.0)), 0.0, 1.0)
		var color: Color = item["color"]
		color.a = life
		draw_string(font, p + Vector2(-55, -42), String(item.get("text", "")), HORIZONTAL_ALIGNMENT_CENTER, 110, 12, color)


func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, VIEW_SIZE.x, 76), Color(0.035, 0.055, 0.04, 0.82))
	draw_string(font, Vector2(16, 27), "AXEHOLD", HORIZONTAL_ALIGNMENT_LEFT, 150, 20, Color("#f2e6ce"))

	var load := carried_wood + carried_stone
	draw_string(font, Vector2(16, 55), "ДЕРЕВО %d    КАМЕНЬ %d    ГРУЗ %d/%d" % [carried_wood, carried_stone, load, CARRY_LIMIT], HORIZONTAL_ALIGNMENT_LEFT, 300, 11, Color("#ddd1b8"))

	# Пауза рисуется геометрией — никаких Unicode-глифов и квадратов с кодом 2161.
	draw_style_box(_panel_box(Color("#2b3028"), Color("#a79372")), PAUSE_RECT)
	var px := PAUSE_RECT.position.x
	var py := PAUSE_RECT.position.y
	draw_rect(Rect2(px + 13.0, py + 11.0, 5.0, 22.0), Color("#f4e6cb"))
	draw_rect(Rect2(px + 26.0, py + 11.0, 5.0, 22.0), Color("#f4e6cb"))

	if not joystick_active and not paused:
		var hint := ""
		if load >= CARRY_LIMIT:
			hint = "Груз заполнен"
		elif active_resource_index >= 0:
			hint = "Добыча идёт автоматически"
		if hint != "":
			var width := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(font, Vector2((VIEW_SIZE.x - width) * 0.5, VIEW_SIZE.y - 24), hint, HORIZONTAL_ALIGNMENT_LEFT, width + 4, 12, Color(0.88, 0.90, 0.83, 0.72))


func _draw_joystick() -> void:
	if not joystick_active or paused:
		return
	draw_circle(joystick_origin, JOYSTICK_RADIUS, Color(0.07, 0.08, 0.07, 0.18))
	draw_arc(joystick_origin, JOYSTICK_RADIUS, 0.0, TAU, 48, Color(0.92, 0.90, 0.82, 0.38), 2.0, true)
	draw_circle(joystick_knob, 25.0, Color(0.88, 0.84, 0.72, 0.36))
	draw_arc(joystick_knob, 25.0, 0.0, TAU, 32, Color(0.96, 0.92, 0.80, 0.62), 2.0, true)


func _draw_pause_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.02, 0.025, 0.02, 0.78))
	var panel := Rect2(34, 325, 322, 235)
	draw_style_box(_panel_box(Color("#1d241d"), Color("#806f54")), panel)
	draw_string(font, Vector2(0, 373), "ПАУЗА", HORIZONTAL_ALIGNMENT_CENTER, VIEW_SIZE.x, 28, Color("#f2e6ce"))
	draw_string(font, Vector2(0, 407), "Игра остановлена", HORIZONTAL_ALIGNMENT_CENTER, VIEW_SIZE.x, 14, Color("#b9c5b2"))

	draw_style_box(_panel_box(Color("#516741"), Color("#a9bb83")), RESUME_RECT)
	draw_string(font, Vector2(0, RESUME_RECT.position.y + 38), "ПРОДОЛЖИТЬ", HORIZONTAL_ALIGNMENT_CENTER, VIEW_SIZE.x, 17, Color("#f5eddc"))


func _panel_box(bg: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(2)
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_left = 10
	box.corner_radius_bottom_right = 10
	return box


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	draw_set_transform(center, 0.0, radius)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _on_screen(screen_pos: Vector2, margin: float) -> bool:
	return screen_pos.x >= -margin and screen_pos.x <= VIEW_SIZE.x + margin and screen_pos.y >= -margin and screen_pos.y <= VIEW_SIZE.y + margin
