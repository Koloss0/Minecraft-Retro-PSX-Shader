#version 120
#define gbuffers_textured
#define requires_resolution
#define requires_classic
#include "shaders.settings"

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 vworldpos;
varying float vaffine;
varying vec2 tc;
varying vec3 normal;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform int renderStage;

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// All components are in the range [0…1], including hue.
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec4 snap(vec4 vertex, vec2 resolution) {
	vec4 snappedPos = vertex;
	snappedPos.xyz = vertex.xyz / vertex.w; // convert to normalised device coordinates (NDC)
	snappedPos.xy = floor(resolution * snappedPos.xy) / resolution; // snap the vertex to the lower-resolution grid
	snappedPos.xyz *= vertex.w; // convert back to projection-space
	return snappedPos;
}

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	tc = texcoord;
#ifdef classic // DROP SHADOWS
	if (lmcoord.t < 0.9375) {
		lmcoord.t = 0.28125;
	}
	lmcoord.s = 0.0; // no block light in classic
#endif

	normal = normalize(mat3(gbufferModelViewInverse) * gl_NormalMatrix * gl_Normal);
	
	//                    view to model                   vertex in view space               model position
	vec3 position = mat3(gbufferModelViewInverse) * (gl_ModelViewMatrix * gl_Vertex).xyz + gbufferModelViewInverse[3].xyz;
	vworldpos = position.xyz + cameraPosition;

	//Fog
	gl_FogFragCoord = length(position.xyz);

	vec4 projVertex = gl_ProjectionMatrix * gbufferModelView * vec4(position, 1.0);

#if texture_warping > 0
	float vertex_distance = length((gl_ModelViewMatrix * gl_Vertex));
	float affine = vertex_distance + ((projVertex.w * texture_warping) / vertex_distance) * 0.5; // Perspective-incorrect texture mapping
	tc *= affine; // Passing out modified texture coordinates
	vaffine = affine;
#endif

	int swap_index = texture_swap;
	int swap_y = int(swap_index / 3.0) - 1;
	int swap_x = swap_index % 3 - 1;

	tc += vec2(swap_x,swap_y)*0.015625;

#if jitteriness > 0 && screen_resolution < 10000
	gl_Position = snap(projVertex,vec2(screen_resolution*aspectRatio,screen_resolution)/jitteriness);
#endif
#if jitteriness > 0 && screen_resolution == 10000
	gl_Position = snap(projVertex,vec2(viewWidth,viewHeight)/jitteriness);
#endif

#if jitteriness == 0
	gl_Position = projVertex;
#endif
/*
#ifdef classic
	color = vec4(gl_Color.xyz,1.0);
	if (renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT) {
		color.rgb *= gl_Color.a;
		//lmcoord.t = 0.96875;
	} else {
		color.rgb *= gl_Color.a;
	}
#else
*/
	color = vec4(gl_Color.xyz*gl_Color.a,1.0);
//#endif
}