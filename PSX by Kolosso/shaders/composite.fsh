#version 120

/* DRAWBUFFERS:34 */

varying vec4 texcoord;

uniform sampler2D gaux1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gdepthtex;
uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2DShadow shadowtex0;	//normal shadows
uniform sampler2DShadow shadowtex1; //colored shadows
uniform sampler2D shadowcolor0;

uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform ivec2 eyeBrightness;
uniform float nightVision;
uniform vec3 shadowLightPosition;

void main() {
	gl_FragData[0] = vec4(texcoord.xy,0.0,1.0);
}
