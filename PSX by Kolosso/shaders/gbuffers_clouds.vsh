#version 120

varying vec4 texcoord;
varying vec4 color;

void main() {
	texcoord = gl_MultiTexCoord0;

	color = gl_Color;
	
	gl_Position = ftransform();
	gl_FogFragCoord = gl_Position.z;
}
