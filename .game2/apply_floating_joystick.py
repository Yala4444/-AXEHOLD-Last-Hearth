from pathlib import Path
import sys

if len(sys.argv) != 2:
    raise SystemExit('usage: apply_floating_joystick.py <main.gd>')

p = Path(sys.argv[1])
s = p.read_text()

if 'const JOYSTICK_RADIUS :=' in s:
    print('floating joystick already applied')
    raise SystemExit(0)

s = s.replace(
    'const NIGHT_ENEMY_COUNT := 8\n',
    'const NIGHT_ENEMY_COUNT := 8\nconst JOYSTICK_RADIUS := 64.0\nconst JOYSTICK_DEADZONE := 0.10\n',
    1,
)

s = s.replace(
    'var input_dragging := false\n',
    'var input_dragging := false\n'
    'var joystick_active := false\n'
    'var joystick_origin := Vector2.ZERO\n'
    'var joystick_knob := Vector2.ZERO\n'
    'var joystick_vector := Vector2.ZERO\n'
    'var joystick_touch_index := -1\n',
    1,
)

s = s.replace(
    '\tlast_objective = ""\n\tqueue_redraw()\n',
    '\tlast_objective = ""\n'
    '\tinput_dragging = false\n'
    '\tjoystick_active = false\n'
    '\tjoystick_origin = Vector2.ZERO\n'
    '\tjoystick_knob = Vector2.ZERO\n'
    '\tjoystick_vector = Vector2.ZERO\n'
    '\tjoystick_touch_index = -1\n'
    '\tqueue_redraw()\n',
    1,
)

old_hero = '''func _update_hero(delta: float) -> void:\n\tvar pos: Vector2 = hero["pos"]\n\tvar target: Vector2 = hero["target"]\n\tvar to_target := target - pos\n\tvar dist := to_target.length()\n\tif dist > 3.0:\n\t\tvar step := minf(dist, HERO_SPEED * delta)\n\t\tpos += to_target.normalized() * step\n\t\thero["walk_phase"] = float(hero["walk_phase"]) + delta * 9.0\n\thero["pos"] = pos\n'''
new_hero = '''func _update_hero(delta: float) -> void:\n\tvar pos: Vector2 = hero["pos"]\n\tif joystick_active and joystick_vector.length() > JOYSTICK_DEADZONE:\n\t\tvar move_strength := clampf(joystick_vector.length(), 0.0, 1.0)\n\t\tvar move_dir := joystick_vector.normalized()\n\t\tpos += move_dir * HERO_SPEED * move_strength * delta\n\t\tpos.x = clampf(pos.x, 24.0, VIEW_SIZE.x - 24.0)\n\t\tpos.y = clampf(pos.y, 130.0, VIEW_SIZE.y - 30.0)\n\t\thero["target"] = pos + move_dir * 24.0\n\t\thero["walk_phase"] = float(hero["walk_phase"]) + delta * (6.0 + 4.0 * move_strength)\n\telse:\n\t\tvar target: Vector2 = hero["target"]\n\t\tvar to_target := target - pos\n\t\tvar dist := to_target.length()\n\t\tif dist > 3.0:\n\t\t\tvar step := minf(dist, HERO_SPEED * delta)\n\t\t\tpos += to_target.normalized() * step\n\t\t\thero["walk_phase"] = float(hero["walk_phase"]) + delta * 9.0\n\thero["pos"] = pos\n'''
if old_hero not in s:
    raise SystemExit('hero movement block not found')
s = s.replace(old_hero, new_hero, 1)

start = s.find('func _unhandled_input(event: InputEvent) -> void:')
end = s.find('\n\nfunc _draw() -> void:', start)
if start < 0 or end < 0:
    raise SystemExit('input block not found')

input_block = '''func _unhandled_input(event: InputEvent) -> void:\n\tif phase == Phase.VICTORY:\n\t\tif (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):\n\t\t\treset_game()\n\t\treturn\n\n\tif event is InputEventScreenTouch:\n\t\tif event.pressed:\n\t\t\tif not joystick_active:\n\t\t\t\tjoystick_touch_index = event.index\n\t\t\t\t_start_joystick(event.position)\n\t\telif joystick_active and event.index == joystick_touch_index:\n\t\t\t_end_joystick()\n\telif event is InputEventScreenDrag:\n\t\tif joystick_active and event.index == joystick_touch_index:\n\t\t\t_update_joystick(event.position)\n\telif event is InputEventMouseButton:\n\t\tif event.button_index == MOUSE_BUTTON_LEFT:\n\t\t\tinput_dragging = event.pressed\n\t\t\tif event.pressed:\n\t\t\t\tjoystick_touch_index = -2\n\t\t\t\t_start_joystick(event.position)\n\t\t\telse:\n\t\t\t\t_end_joystick()\n\telif event is InputEventMouseMotion:\n\t\tif input_dragging and joystick_active:\n\t\t\t_update_joystick(event.position)\n\telif event is InputEventKey and event.pressed:\n\t\tvar target: Vector2 = hero["target"]\n\t\tif event.keycode == KEY_LEFT or event.keycode == KEY_A:\n\t\t\ttarget.x -= 70.0\n\t\telif event.keycode == KEY_RIGHT or event.keycode == KEY_D:\n\t\t\ttarget.x += 70.0\n\t\telif event.keycode == KEY_UP or event.keycode == KEY_W:\n\t\t\ttarget.y -= 70.0\n\t\telif event.keycode == KEY_DOWN or event.keycode == KEY_S:\n\t\t\ttarget.y += 70.0\n\t\telif event.keycode == KEY_R:\n\t\t\treset_game()\n\t\ttarget.x = clampf(target.x, 24.0, VIEW_SIZE.x - 24.0)\n\t\ttarget.y = clampf(target.y, 130.0, VIEW_SIZE.y - 30.0)\n\t\thero["target"] = target\n\n\nfunc _start_joystick(screen_pos: Vector2) -> void:\n\tjoystick_active = true\n\tjoystick_origin = screen_pos\n\tjoystick_knob = screen_pos\n\tjoystick_vector = Vector2.ZERO\n\thero["target"] = hero["pos"]\n\n\nfunc _update_joystick(screen_pos: Vector2) -> void:\n\tvar offset := screen_pos - joystick_origin\n\tif offset.length() > JOYSTICK_RADIUS:\n\t\toffset = offset.normalized() * JOYSTICK_RADIUS\n\tjoystick_knob = joystick_origin + offset\n\tjoystick_vector = offset / JOYSTICK_RADIUS\n\tif joystick_vector.length() < JOYSTICK_DEADZONE:\n\t\tjoystick_vector = Vector2.ZERO\n\n\nfunc _end_joystick() -> void:\n\tjoystick_active = false\n\tinput_dragging = false\n\tjoystick_vector = Vector2.ZERO\n\tjoystick_touch_index = -1\n\thero["target"] = hero["pos"]\n'''
s = s[:start] + input_block + s[end:]

s = s.replace(
    '\t_draw_banner()\n\t_draw_flash()\n',
    '\t_draw_banner()\n\t_draw_joystick()\n\t_draw_flash()\n',
    1,
)

marker = 'func _draw_flash() -> void:\n'
if marker not in s:
    raise SystemExit('draw flash marker not found')
joystick_draw = '''func _draw_joystick() -> void:\n\tif not joystick_active:\n\t\treturn\n\n\t# Floating joystick: the base appears where the player first touches.\n\tdraw_circle(joystick_origin, JOYSTICK_RADIUS + 8.0, Color(0.01, 0.02, 0.015, 0.24))\n\tdraw_circle(joystick_origin, JOYSTICK_RADIUS, Color(0.92, 0.94, 0.89, 0.12))\n\tdraw_arc(joystick_origin, JOYSTICK_RADIUS, 0.0, TAU, 40, Color(0.95, 0.86, 0.62, 0.46), 2.5)\n\tdraw_circle(joystick_knob, 24.0, Color(0.95, 0.86, 0.62, 0.30))\n\tdraw_circle(joystick_knob, 15.0, Color(0.98, 0.91, 0.72, 0.68))\n\n\n'''
s = s.replace(marker, joystick_draw + marker, 1)

p.write_text(s)
print('floating joystick applied')
