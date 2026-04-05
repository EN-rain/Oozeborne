shader_type canvas_item;

// Palette swap for layered slime sprites.
// The source art has three flat blue body tones that get replaced at runtime.

uniform vec4 highlight_color : source_color = vec4(0.52549, 0.890196, 0.996078, 1.0);
uniform vec4 mid_color : source_color = vec4(0.454902, 0.843137, 1.0, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.34902, 0.741176, 0.905882, 1.0);
uniform vec4 outline_color : source_color = vec4(0.137255, 0.129412, 0.188235, 1.0);
uniform vec4 iris_color : source_color = vec4(0.203922, 0.223529, 0.352941, 1.0);
uniform vec4 eye_highlight_color : source_color = vec4(0.992157, 0.992157, 0.992157, 1.0);

uniform vec3 source_highlight = vec3(0.52549, 0.890196, 0.996078);
uniform vec3 source_mid = vec3(0.454902, 0.843137, 1.0);
uniform vec3 source_mid_alt_1 = vec3(0.407843, 0.831373, 1.0);
uniform vec3 source_mid_alt_2 = vec3(0.396078, 0.839216, 1.0);
uniform vec3 source_shadow = vec3(0.34902, 0.741176, 0.905882);
uniform vec3 source_shadow_alt_1 = vec3(0.305882, 0.741176, 0.933333);
uniform vec3 source_shadow_alt_2 = vec3(0.294118, 0.764706, 0.968627);
uniform vec3 source_outline = vec3(0.137255, 0.129412, 0.188235);
uniform vec3 source_iris = vec3(0.203922, 0.223529, 0.352941);
uniform vec3 source_eye_highlight = vec3(0.992157, 0.992157, 0.992157);
uniform vec3 source_eye_highlight_alt_1 = vec3(0.984314, 0.988235, 0.992157);
uniform vec3 source_eye_highlight_alt_2 = vec3(0.956863, 0.984314, 0.988235);
uniform vec3 source_eye_highlight_alt_3 = vec3(0.996078, 0.988235, 0.988235);
uniform float tolerance : hint_range(0.0, 0.1) = 0.01;

bool matches_color(vec3 color, vec3 target_rgb) {
	return distance(color, target_rgb) <= tolerance;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 result = tex_color.rgb;

	if (tex_color.a > 0.0) {
		if (matches_color(tex_color.rgb, source_highlight)) {
			result = highlight_color.rgb;
		} else if (
			matches_color(tex_color.rgb, source_mid) ||
			matches_color(tex_color.rgb, source_mid_alt_1) ||
			matches_color(tex_color.rgb, source_mid_alt_2)
		) {
			result = mid_color.rgb;
		} else if (
			matches_color(tex_color.rgb, source_shadow) ||
			matches_color(tex_color.rgb, source_shadow_alt_1) ||
			matches_color(tex_color.rgb, source_shadow_alt_2)
		) {
			result = shadow_color.rgb;
		} else if (matches_color(tex_color.rgb, source_outline)) {
			result = outline_color.rgb;
		} else if (matches_color(tex_color.rgb, source_iris)) {
			result = iris_color.rgb;
		} else if (
			matches_color(tex_color.rgb, source_eye_highlight) ||
			matches_color(tex_color.rgb, source_eye_highlight_alt_1) ||
			matches_color(tex_color.rgb, source_eye_highlight_alt_2) ||
			matches_color(tex_color.rgb, source_eye_highlight_alt_3)
		) {
			result = eye_highlight_color.rgb;
		}
	}

	COLOR = vec4(result, tex_color.a);
}
