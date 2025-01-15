shader_type canvas_item;
uniform float blur: hint_range(0.0, 2.5);
uniform float bright: hint_range(0.0, 1.0);
uniform sampler2D SCREEN_TEXTURE;


void fragment() {
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur);
	COLOR.rgb *= bright;
	
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
