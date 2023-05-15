#version 450
#include "compiled.inc"
#include "std/gbuffer.glsl"
in vec3 wnormal;
out vec4 fragColor[GBUF_SIZE];
void main() {
	vec3 n = normalize(wnormal);
	vec3 basecol;
	float roughness;
	float metallic;
	float occlusion;
	float specular;
	vec3 emissionCol;
	basecol = vec3(0.800000011920929, 0.800000011920929, 0.800000011920929);
	roughness = 0.5;
	metallic = 0.0;
	occlusion = 1.0;
	specular = 0.25;
	emissionCol = vec3(0.0);
	n /= (abs(n.x) + abs(n.y) + abs(n.z));
	n.xy = n.z >= 0.0 ? n.xy : octahedronWrap(n.xy);
	const uint matid = 0;
	fragColor[GBUF_IDX_0] = vec4(n.xy, roughness, packFloatInt16(metallic, matid));
	fragColor[GBUF_IDX_1] = vec4(basecol, packFloat2(occlusion, specular));
	#ifdef _EmissionShaded
	fragColor[GBUF_IDX_EMISSION] = vec4(emissionCol, 0.0);
	#endif
}
