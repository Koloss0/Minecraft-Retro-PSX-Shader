#version 120

#include "shaders.settings"

varying vec4 texcoord;
varying vec4 color;

uniform sampler2D texture;
uniform sampler2D lightmap;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

uniform int fogMode;

void main() {
	vec4 col = texture2D(texture, texcoord.xy) * color;
	
	gl_FragData[0] = col;

#ifndef CLASSIC
	if (fogMode == GL_EXP) {
		gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, 1.0 - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0));
	} else if (fogMode == GL_LINEAR) {
		gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0));
	}
#endif
}
