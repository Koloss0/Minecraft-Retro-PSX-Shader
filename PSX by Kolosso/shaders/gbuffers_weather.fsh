#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;

vec4 quantize(){
	return vec4(texture2D(lightmap, (floor(12.0 * pow(lmcoord.st, vec2(0.8))) + 0.5) / 12.0).rgb, 1.0);
}

void main() {

	gl_FragData[0] = texture2D(texture, texcoord.st) * quantize() * color;
	gl_FragData[1] = vec4(0.0);
		
}