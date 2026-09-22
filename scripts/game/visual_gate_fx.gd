class_name VisualGateFX
extends Node

var world: GameWorld = null
var overlay_layer: CanvasLayer
var grade_rect: ColorRect
var grade_material: ShaderMaterial
var hearth_light: PointLight2D
var hero_fill_light: PointLight2D
var night_mix: float = 0.0
var elapsed: float = 0.0

func setup(owner_world: GameWorld) -> void:
    world = owner_world
    _build_world_lights()
    _build_screen_grade()
    _sync_positions()
    set_process(true)

func _build_world_lights() -> void:
    hearth_light = PointLight2D.new()
    hearth_light.name = "VisualGateHearthLight"
    hearth_light.texture = _radial_texture(256)
    hearth_light.texture_scale = 2.35
    hearth_light.color = Color("f2aa62")
    hearth_light.energy = 0.72
    hearth_light.z_index = 30
    add_child(hearth_light)

    hero_fill_light = PointLight2D.new()
    hero_fill_light.name = "VisualGateHeroFill"
    hero_fill_light.texture = _radial_texture(160)
    hero_fill_light.texture_scale = 1.05
    hero_fill_light.color = Color("d8c6a3")
    hero_fill_light.energy = 0.13
    hero_fill_light.z_index = 30
    add_child(hero_fill_light)

func _radial_texture(size: int) -> GradientTexture2D:
    var gradient := Gradient.new()
    gradient.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
    gradient.colors = PackedColorArray([
        Color(1.0, 1.0, 1.0, 0.95),
        Color(1.0, 1.0, 1.0, 0.34),
        Color(1.0, 1.0, 1.0, 0.0)
    ])

    var texture := GradientTexture2D.new()
    texture.width = size
    texture.height = size
    texture.fill = GradientTexture2D.FILL_RADIAL
    texture.fill_from = Vector2(0.5, 0.5)
    texture.fill_to = Vector2(1.0, 0.5)
    texture.gradient = gradient
    return texture

func _build_screen_grade() -> void:
    overlay_layer = CanvasLayer.new()
    overlay_layer.name = "VisualGateScreenGrade"
    overlay_layer.layer = 40
    add_child(overlay_layer)

    grade_rect = ColorRect.new()
    overlay_layer.add_child(grade_rect)
    grade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    grade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var shader := Shader.new()
    shader.code = """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float night_mix = 0.0;
uniform float time_s = 0.0;
uniform vec2 hearth_uv = vec2(0.5, 0.5);
uniform vec2 hero_uv = vec2(0.5, 0.55);

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 src = texture(screen_texture, uv);
    vec3 col = src.rgb;

    // Slightly richer midtones without crushing the hand-painted palette.
    col = (col - 0.5) * 1.045 + 0.5;
    col *= mix(vec3(1.025, 1.0, 0.965), vec3(0.82, 0.91, 1.035), night_mix * 0.62);

    // Warm visual anchor around the hearth. This follows the world position.
    float hearth_dist = distance(uv, hearth_uv);
    float hearth_glow = exp(-hearth_dist * 8.4);
    col += vec3(0.115, 0.052, 0.012) * hearth_glow * (0.48 + night_mix * 0.72);

    // Tiny local lift around the hero so the silhouette never disappears at night.
    float hero_dist = distance(uv, hero_uv);
    float hero_lift = exp(-hero_dist * 13.0);
    col += vec3(0.028, 0.024, 0.018) * hero_lift * (0.35 + night_mix * 0.75);

    // Soft cinematic vignette. Corners darken more at night.
    vec2 centered = uv - vec2(0.5);
    float vignette = smoothstep(0.34, 0.73, length(centered));
    col *= 1.0 - vignette * (0.10 + night_mix * 0.10);

    // Very low amplitude grain avoids a flat digital wash.
    vec2 grain_cell = floor(uv * vec2(195.0, 422.0));
    float grain = (hash21(grain_cell + floor(time_s * 10.0)) - 0.5) * 0.010;
    col += grain;

    COLOR = vec4(clamp(col, vec3(0.0), vec3(1.0)), src.a);
}
"""
    grade_material = ShaderMaterial.new()
    grade_material.shader = shader
    grade_rect.material = grade_material

func _process(delta: float) -> void:
    if world == null or not is_instance_valid(world):
        return

    elapsed += delta
    var target_night := 1.0 if world.phase == "night" else 0.0
    night_mix = move_toward(night_mix, target_night, delta * 0.72)

    _sync_positions()

    if hearth_light != null:
        hearth_light.energy = lerpf(0.66, 1.28, night_mix) * (0.97 + sin(elapsed * 5.2) * 0.035)
        hearth_light.texture_scale = lerpf(2.15, 2.70, night_mix)
    if hero_fill_light != null:
        hero_fill_light.energy = lerpf(0.10, 0.24, night_mix)

    if grade_material != null:
        grade_material.set_shader_parameter("night_mix", night_mix)
        grade_material.set_shader_parameter("time_s", elapsed)
        var viewport_size := get_viewport().get_visible_rect().size
        if viewport_size.x > 1.0 and viewport_size.y > 1.0:
            var canvas := get_viewport().get_canvas_transform()
            var hearth_screen := canvas * world.base_position
            var hero_screen := hearth_screen
            if world.player != null and is_instance_valid(world.player):
                hero_screen = canvas * world.player.global_position
            grade_material.set_shader_parameter(
                "hearth_uv",
                Vector2(
                    clampf(hearth_screen.x / viewport_size.x, 0.0, 1.0),
                    clampf(hearth_screen.y / viewport_size.y, 0.0, 1.0)
                )
            )
            grade_material.set_shader_parameter(
                "hero_uv",
                Vector2(
                    clampf(hero_screen.x / viewport_size.x, 0.0, 1.0),
                    clampf(hero_screen.y / viewport_size.y, 0.0, 1.0)
                )
            )

func _sync_positions() -> void:
    if world == null or not is_instance_valid(world):
        return
    if hearth_light != null:
        hearth_light.global_position = world.base_position
    if hero_fill_light != null and world.player != null and is_instance_valid(world.player):
        hero_fill_light.global_position = world.player.global_position
