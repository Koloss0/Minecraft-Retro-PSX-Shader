#version 120
#define final
#define requires_resolution
#include "shaders.settings"

// Most of the CRT visual effects were adapted from Mattias' shadertoy shader:
// https://www.shadertoy.com/view/Ms23DR

#define clipping far

varying vec4 texcoord;

uniform sampler2D gcolor;
uniform float frameTimeCounter;
uniform float aspectRatio;
uniform int worldTime;
uniform sampler2D gdepthtex;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;

float getDepth(vec2 coord) {
    return 2.0 * near * far / (far + near - (2.0 * texture2D(depthtex0, coord).x - 1.0) * (far - near)) / clipping;
}

vec3 ConvertToHDR(vec3 color) {
	return mix(color / 1.5, color * 1.2, color);
}

vec2 curve(vec2 uv)
{
	uv = (uv - 0.5) * 2.0;
	uv *= 1.1;	
	uv.x *= 1.0 + pow(abs(uv.y) / 4.0 * 0.9,2.0);
	uv.y *= 1.0 + pow(abs(uv.x) / 3.0 * 0.9,2.0);
	uv  = (uv / 2.0) + 0.5;
	uv =  uv *0.92 + 0.04;
	return uv;
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

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Noise generation functions borrowed from: 
// https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl

vec3 mod289_vec3(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289_vec2(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289_vec3(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289_vec2(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

// noiseWaves
//      Author : Ian McEwan, Ashima Arts.
float noiseWaves(vec2 uv, float time) {
	// Create large, incidental noise waves
    float noise = max(0.0, snoise(vec2(time, uv.y * 0.3)) - 0.3) * (1.0 / 0.7);
    
    // Offset by smaller, constant noise waves
    noise = noise + (snoise(vec2(time*10.0, uv.y * 2.4)) - 0.5) * 0.15;
    
    // Apply the noise as x displacement for every line
    noise = -noise * noise * 0.25;
	return noise;
}

vec2 pixelate(vec2 uv) {
#if screen_resolution < 10000 // ## change this to screen_resolution != -1?
	uv *= screen_resolution;
	uv.x *= aspectRatio;
	uv = floor(uv);
	uv.x /= aspectRatio;
	uv /= screen_resolution;
#endif

	return uv;
}

// Dithering code is thanks to MightyDuke
// https://godotshaders.com/author/mighty-duke/
int dithering_pattern(ivec2 fragcoord) {
	const int pattern[] = int[](
		-4, +0, -3, +1,
		+2, -2, +3, -1, 
		-3, +1, -4, +0, 
		+3, -1, +2, -2
	);
	
	int x = fragcoord.x % 4;
	int y = fragcoord.y % 4;
	
	return pattern[y * 4 + x];
}

void main() {
	// buldge
	vec2 uv = texcoord.xy;

#ifdef CRT
	uv = curve(uv);
#endif
	
	float x_offset = noise_waves*noiseWaves(uv, frameTimeCounter*2.0);
	
	float fuzzy = snoise(vec2(frameTimeCounter*20.0,uv.y*80.0))*0.001*fuzziness;
	float big_fuzzy = snoise(vec2(frameTimeCounter*10.0,uv.y*30.0))*0.001*fuzziness;
	x_offset += fuzzy + big_fuzzy;
	
	vec2 offset_uv = uv + vec2(x_offset,0.0);

	// pixelate
	vec2 pix = pixelate(offset_uv);

#if screen_resolution < 10000
	// get pixel collumn/row
	ivec2 pixel = ivec2(offset_uv*float(screen_resolution)*vec2(aspectRatio,1));
#endif
#if screen_resolution == 10000
	ivec2 pixel = ivec2(offset_uv*float(viewHeight));
#endif

	// get fragment color
	vec3 color = texture2D(gcolor,pix).rgb;
	//vec3 color = vec3(pix.y);

	ivec3 c = ivec3(round(color * 255.0));
	
#ifdef dither
	// Apply the dithering pattern
	c += ivec3(dithering_pattern(pixel));
#endif

	// Truncate from 8 bits to color_depth bits
	c >>= (8 - color_depth);
	
	// Convert back to [0.0, 1.0] range
	color = vec3(c) / float(1 << color_depth);

	//color = floor(color*64.0+0.5)/64.0;

#if rgb_offset > 0
	float channel_offset = rgb_offset*0.001 + x_offset*0.5;
	float r = texture2D(gcolor,mod(pixelate(uv+vec2(channel_offset,0.0)),1.0)).r;
	float b = texture2D(gcolor,mod(pixelate(uv-vec2(0.5*channel_offset,0.0)),1.0)).b;
	color.r = mix(color.r,r,rgb_offset_strength*0.01);
	color.b = mix(color.b,b,rgb_offset_strength*0.01);
#endif
	
	// HDR
#ifdef HDR
		color = ConvertToHDR(color);
#endif

#ifdef CRT
	// horizontal scan lines
	float scans = pow(clamp( 0.35+0.35*sin(3.5*frameTimeCounter+uv.y*viewHeight*1.3), 0.0, 1.0),1.7);
	color *= vec3(0.5+0.5*scans);
	color *= 2.2;
	
	// vignette
	float vig = (0.0 + 1.0*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y));
	color *= vec3(pow(vig,0.3));

	if (uv.x < 0.0 || uv.x > 1.0)
		color *= 0.0;
	if (uv.y < 0.0 || uv.y > 1.0)
		color *= 0.0;
	
	// correct brightness
	color*=1.0-0.65*vec3(clamp((mod(texcoord.x*viewWidth, 2.0)-1.0)*2.0,0.0,1.0));
#endif
	
	gl_FragColor = vec4(color, 1.0f);
}
