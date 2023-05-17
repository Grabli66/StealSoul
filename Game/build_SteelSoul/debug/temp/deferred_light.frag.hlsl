Texture2D<float4> gbuffer0 : register(t0);
SamplerState _gbuffer0_sampler : register(s0);
Texture2D<float4> gbuffer1 : register(t1);
SamplerState _gbuffer1_sampler : register(s1);
Texture2D<float4> gbufferD : register(t2);
SamplerState _gbufferD_sampler : register(s2);
uniform float3 eye;
uniform float3 eyeLook;
uniform float2 cameraProj;
uniform float4 shirr[7];
uniform float envmapStrength;
uniform float3 sunDir;
uniform float3 sunCol;
uniform float2 cameraPlane;
Texture2D<float4> clustersData : register(t3);
SamplerState _clustersData_sampler : register(s3);
uniform float4 lightsArray[12];

static float2 texCoord;
static float3 viewRay;
static float4 fragColor;

struct SPIRV_Cross_Input
{
    float2 texCoord : TEXCOORD0;
    float3 viewRay : TEXCOORD1;
};

struct SPIRV_Cross_Output
{
    float4 fragColor : SV_Target0;
};

float2 octahedronWrap(float2 v)
{
    return (1.0f.xx - abs(v.yx)) * float2((v.x >= 0.0f) ? 1.0f : (-1.0f), (v.y >= 0.0f) ? 1.0f : (-1.0f));
}

void unpackFloatInt16(float val, out float f, out uint i)
{
    uint bitsValue = uint(val);
    i = bitsValue >> 12u;
    f = float(bitsValue & 4294905855u) / 4095.0f;
}

float2 unpackFloat2(float f)
{
    return float2(floor(f) / 255.0f, frac(f));
}

float3 surfaceAlbedo(float3 baseColor, float metalness)
{
    return lerp(baseColor, 0.0f.xxx, metalness.xxx);
}

float3 surfaceF0(float3 baseColor, float metalness)
{
    return lerp(0.039999999105930328369140625f.xxx, baseColor, metalness.xxx);
}

float3 getPos(float3 eye_1, float3 eyeLook_1, float3 viewRay_1, float depth, float2 cameraProj_1)
{
    float linearDepth = cameraProj_1.y / (((depth * 0.5f) + 0.5f) - cameraProj_1.x);
    float viewZDist = dot(eyeLook_1, viewRay_1);
    float3 wposition = eye_1 + (viewRay_1 * (linearDepth / viewZDist));
    return wposition;
}

float3 shIrradiance(float3 nor, float4 shirr_1[7])
{
    float3 cl00 = float3(shirr_1[0].x, shirr_1[0].y, shirr_1[0].z);
    float3 cl1m1 = float3(shirr_1[0].w, shirr_1[1].x, shirr_1[1].y);
    float3 cl10 = float3(shirr_1[1].z, shirr_1[1].w, shirr_1[2].x);
    float3 cl11 = float3(shirr_1[2].y, shirr_1[2].z, shirr_1[2].w);
    float3 cl2m2 = float3(shirr_1[3].x, shirr_1[3].y, shirr_1[3].z);
    float3 cl2m1 = float3(shirr_1[3].w, shirr_1[4].x, shirr_1[4].y);
    float3 cl20 = float3(shirr_1[4].z, shirr_1[4].w, shirr_1[5].x);
    float3 cl21 = float3(shirr_1[5].y, shirr_1[5].z, shirr_1[5].w);
    float3 cl22 = float3(shirr_1[6].x, shirr_1[6].y, shirr_1[6].z);
    return ((((((((((cl22 * 0.429042994976043701171875f) * ((nor.y * nor.y) - ((-nor.z) * (-nor.z)))) + (((cl20 * 0.743125021457672119140625f) * nor.x) * nor.x)) + (cl00 * 0.88622701168060302734375f)) - (cl20 * 0.2477079927921295166015625f)) + (((cl2m2 * 0.85808598995208740234375f) * nor.y) * (-nor.z))) + (((cl21 * 0.85808598995208740234375f) * nor.y) * nor.x)) + (((cl2m1 * 0.85808598995208740234375f) * (-nor.z)) * nor.x)) + ((cl11 * 1.02332794666290283203125f) * nor.y)) + ((cl1m1 * 1.02332794666290283203125f) * (-nor.z))) + ((cl10 * 1.02332794666290283203125f) * nor.x);
}

float3 lambertDiffuseBRDF(float3 albedo, float nl)
{
    return albedo * nl;
}

float d_ggx(float nh, float a)
{
    float a2 = a * a;
    float denom = pow(((nh * nh) * (a2 - 1.0f)) + 1.0f, 2.0f);
    return (a2 * 0.3183098733425140380859375f) / denom;
}

float g2_approx(float NdotL, float NdotV, float alpha)
{
    float2 helper = (float2(NdotL, NdotV) * 2.0f) * (1.0f.xx / ((float2(NdotL, NdotV) * (2.0f - alpha)) + alpha.xx));
    return max(helper.x * helper.y, 0.0f);
}

float3 f_schlick(float3 f0, float vh)
{
    return f0 + ((1.0f.xxx - f0) * exp2((((-5.554729938507080078125f) * vh) - 6.9831600189208984375f) * vh));
}

float3 specularBRDF(float3 f0, float roughness, float nl, float nh, float nv, float vh)
{
    float a = roughness * roughness;
    return (f_schlick(f0, vh) * (d_ggx(nh, a) * g2_approx(nl, nv, a))) / max(4.0f * nv, 9.9999997473787516355514526367188e-06f).xxx;
}

float linearize(float depth, float2 cameraProj_1)
{
    return cameraProj_1.y / (depth - cameraProj_1.x);
}

int getClusterI(float2 tc, float viewz, float2 cameraPlane_1)
{
    int sliceZ = 0;
    float cnear = 3.0f + cameraPlane_1.x;
    if (viewz >= cnear)
    {
        float z = log((viewz - cnear) + 1.0f) / log((cameraPlane_1.y - cnear) + 1.0f);
        sliceZ = int(z * 15.0f) + 1;
    }
    else
    {
        if (viewz >= cameraPlane_1.x)
        {
            sliceZ = 1;
        }
    }
    return (int(tc.x * 16.0f) + int(float(int(tc.y * 16.0f)) * 16.0f)) + int((float(sliceZ) * 16.0f) * 16.0f);
}

float attenuate(float dist)
{
    return 1.0f / (dist * dist);
}

float3 sampleLight(float3 p, float3 n, float3 v, float dotNV, float3 lp, float3 lightCol, float3 albedo, float rough, float spec, float3 f0)
{
    float3 ld = lp - p;
    float3 l = normalize(ld);
    float3 h = normalize(v + l);
    float dotNH = max(0.0f, dot(n, h));
    float dotVH = max(0.0f, dot(v, h));
    float dotNL = max(0.0f, dot(n, l));
    float3 direct = lambertDiffuseBRDF(albedo, dotNL) + (specularBRDF(f0, rough, dotNL, dotNH, dotNV, dotVH) * spec);
    direct *= attenuate(distance(p, lp));
    direct *= lightCol;
    return direct;
}

void frag_main()
{
    float4 g0 = gbuffer0.SampleLevel(_gbuffer0_sampler, texCoord, 0.0f);
    float3 n;
    n.z = (1.0f - abs(g0.x)) - abs(g0.y);
    float2 _505;
    if (n.z >= 0.0f)
    {
        _505 = g0.xy;
    }
    else
    {
        _505 = octahedronWrap(g0.xy);
    }
    n = float3(_505.x, _505.y, n.z);
    n = normalize(n);
    float roughness = g0.z;
    float param;
    uint param_1;
    unpackFloatInt16(g0.w, param, param_1);
    float metallic = param;
    uint matid = param_1;
    float4 g1 = gbuffer1.SampleLevel(_gbuffer1_sampler, texCoord, 0.0f);
    float2 occspec = unpackFloat2(g1.w);
    float3 albedo = surfaceAlbedo(g1.xyz, metallic);
    float3 f0 = surfaceF0(g1.xyz, metallic);
    float depth = (gbufferD.SampleLevel(_gbufferD_sampler, texCoord, 0.0f).x * 2.0f) - 1.0f;
    float3 p = getPos(eye, eyeLook, normalize(viewRay), depth, cameraProj);
    float3 v = normalize(eye - p);
    float dotNV = max(dot(n, v), 0.0f);
    float3 envl = shIrradiance(n, shirr);
    envl *= albedo;
    envl *= (envmapStrength * occspec.x);
    fragColor = float4(envl.x, envl.y, envl.z, fragColor.w);
    float3 sh = normalize(v + sunDir);
    float sdotNH = max(0.0f, dot(n, sh));
    float sdotVH = max(0.0f, dot(v, sh));
    float sdotNL = max(0.0f, dot(n, sunDir));
    float svisibility = 1.0f;
    float3 sdirect = lambertDiffuseBRDF(albedo, sdotNL) + (specularBRDF(f0, roughness, sdotNL, sdotNH, dotNV, sdotVH) * occspec.y);
    float3 _650 = fragColor.xyz + ((sdirect * svisibility) * sunCol);
    fragColor = float4(_650.x, _650.y, _650.z, fragColor.w);
    float2 param_2 = cameraProj;
    float viewz = linearize((depth * 0.5f) + 0.5f, param_2);
    float2 param_3 = texCoord;
    float param_4 = viewz;
    float2 param_5 = cameraPlane;
    int clusterI = getClusterI(param_3, param_4, param_5);
    int numLights = int(clustersData.Load(int3(int2(clusterI, 0), 0)).x * 255.0f);
    viewz += (clustersData.SampleLevel(_clustersData_sampler, 0.0f.xx, 0.0f).x * 9.999999717180685365747194737196e-10f);
    for (int i = 0; i < min(numLights, 4); i++)
    {
        int li = int(clustersData.Load(int3(int2(clusterI, i + 1), 0)).x * 255.0f);
        float3 _736 = fragColor.xyz + sampleLight(p, n, v, dotNV, lightsArray[li * 3].xyz, lightsArray[(li * 3) + 1].xyz, albedo, roughness, occspec.y, f0);
        fragColor = float4(_736.x, _736.y, _736.z, fragColor.w);
    }
    fragColor.w = 1.0f;
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    texCoord = stage_input.texCoord;
    viewRay = stage_input.viewRay;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.fragColor = fragColor;
    return stage_output;
}
