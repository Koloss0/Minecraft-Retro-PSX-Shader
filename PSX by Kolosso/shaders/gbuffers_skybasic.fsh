#version 120

#define requires_disco
#define requires_classic
#include "shaders.settings"

varying vec4 color;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

const float DISCO_PERIOD = 0.5;

uniform int fogMode;
uniform float frameTimeCounter;
uniform int worldTime;

// hash11 source: https://www.shadertoy.com/view/4djSRW
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 getDiscoColour(float time) {
	float i = floor(time/DISCO_PERIOD);

	vec3 prev = hsv2rgb(vec3(hash11(i-1.0),1.0,1.0));
	vec3 cur = hsv2rgb(vec3(hash11(i),1.0,1.0));

	float t = mod(frameTimeCounter,DISCO_PERIOD)/DISCO_PERIOD;

	return mix(prev,cur,smoothstep(0.0,0.05,t));
}

void main() {
	
	gl_FragData[0] = color;

	// disco
#ifdef disco
	gl_FragData[0].rgb = getDiscoColour(frameTimeCounter);
#else
/*
	vec3 fogCol = gl_Fog.color.rgb;
#ifdef classic
	fogCol = getClassicFog();
#endif
*/	
	if (fogMode == GL_EXP) {
		gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, 1.0 - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0));
	} else if (fogMode == GL_LINEAR) {
		gl_FragData[0].rgb = mix(gl_FragData[0].rgb, gl_Fog.color.rgb, clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0));
	}

#endif
}