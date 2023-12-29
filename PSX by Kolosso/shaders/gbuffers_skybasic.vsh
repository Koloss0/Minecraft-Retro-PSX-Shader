#version 120

#include "shaders.settings"

varying vec4 color;

void main() {
	gl_Position = ftransform();
	
	color = gl_Color;
#ifdef CLASSIC
	color *= vec4(1,1.2,1,1); // teal sky
#endif

	gl_FogFragCoord = gl_Position.z;
}