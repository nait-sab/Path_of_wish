class_name SkillIcon extends Control

enum IconMode { SQUARE, ORB }

@export var icon_rect: TextureRect
@export var frame_rect: TextureRect
@export var placeholder: Texture2D
@export var mask_texture: Texture2D

var skill_icon: Texture2D
var _mask_mat: ShaderMaterial

const SHADER_ORB = """
shader_type canvas_item;

uniform sampler2D mask_tex;

uniform float refraction     = 0.1;
uniform float vignette       = 0.1;
uniform float vignette_width = 0.2;
uniform float rim_strength   = 0.2;
uniform vec4  tint_color     = vec4(1.0, 0.5, 0.25, 1.0);
uniform float tint_strength  = 0.2;
uniform float exposure   = 1.5;
uniform float saturation = 1.1;
uniform float spec_intensity = 0.35;
uniform float spec_power     = 36.0;
uniform vec2  light_dir      = vec2(-0.35, -0.65);

void fragment() {
	vec2 uv = UV;
	vec2 c  = vec2(0.5);
	vec2 p  = uv - c;
	float r = length(p) / 0.5;

	vec2 refr = -p * refraction * (1.0 - r*r);
	vec3 col  = texture(TEXTURE, uv + refr).rgb;
	col += tint_color.rgb * tint_strength * (1.0 - smoothstep(0.0, 1.0, r));
	float rim = smoothstep(0.75, 0.95, r) * rim_strength;
	col += rim;
	vec3 n = normalize(vec3(p, sqrt(max(0.0, 1.0 - r*r))));
	vec3 L = normalize(vec3(light_dir, 0.7));
	float spec = pow(max(dot(n, L), 0.0), spec_power) * spec_intensity;
	col += spec;
	col += (1.0 - r) * 0.10;
	col *= exposure;
	float gray = dot(col, vec3(0.3, 0.6, 0.1));
	col = mix(vec3(gray), col, saturation);
	float m = texture(mask_tex, uv).a;
	COLOR.rgb = col;
	COLOR.a   = m;
}
"""

func setupById(skill_id: String, mode: IconMode = IconMode.ORB) -> void:
	var path := "res://assets/textures/skills/%s.png" % skill_id
	
	var texture: Texture2D = placeholder
	if ResourceLoader.exists(path, "Texture2D"):
		texture = load(path) as Texture2D
	
	setupByTexture(texture, mode)

func setupByTexture(texture: Texture2D, mode: IconMode = IconMode.ORB) -> void:
	skill_icon = texture
	icon_rect.texture = skill_icon
	
	if mode == IconMode.ORB:
		_apply_orb_mask()
		frame_rect.visible = true
	else:
		_remove_mask()
		frame_rect.visible = false

func _apply_orb_mask() -> void:
	if _mask_mat == null:
		var shader := Shader.new()
		shader.code = SHADER_ORB
		_mask_mat = ShaderMaterial.new()
		_mask_mat.shader = shader
	
	var mask := mask_texture
	if mask == null and frame_rect.texture != null:
		mask = frame_rect.texture
		
	_mask_mat.set_shader_parameter("mask_tex", mask)
	_mask_mat.set_shader_parameter("refraction", 0.1)
	_mask_mat.set_shader_parameter("vignette", 0.06)
	_mask_mat.set_shader_parameter("vignette_width", 0.1)
	_mask_mat.set_shader_parameter("rim_strength", 0.28)
	_mask_mat.set_shader_parameter("tint_color", Color(1.0, 0.5, 0.25))
	_mask_mat.set_shader_parameter("tint_strength", 0.2)
	_mask_mat.set_shader_parameter("exposure", 1.35)
	_mask_mat.set_shader_parameter("saturation", 1.1)
	_mask_mat.set_shader_parameter("spec_intensity", 0.22)
	_mask_mat.set_shader_parameter("spec_power", 24.0)
	_mask_mat.set_shader_parameter("light_dir", Vector2(-0.35, -0.65))
	
	icon_rect.material = _mask_mat

func _remove_mask() -> void:
	icon_rect.material = null
