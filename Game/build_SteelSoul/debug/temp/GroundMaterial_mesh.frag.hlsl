static float3 wnormal;
static float4 fragColor[2];

struct SPIRV_Cross_Input
{
    float3 wnormal : TEXCOORD0;
};

struct SPIRV_Cross_Output
{
    float4 fragColor[2] : SV_Target0;
};

float2 octahedronWrap(float2 v)
{
    return (1.0f.xx - abs(v.yx)) * float2((v.x >= 0.0f) ? 1.0f : (-1.0f), (v.y >= 0.0f) ? 1.0f : (-1.0f));
}

float packFloatInt16(float f, uint i)
{
    uint bitsInt = i << 12u;
    uint bitsFloat = uint(f * 4095.0f);
    return float(bitsInt | bitsFloat);
}

float packFloat2(float f1, float f2)
{
    return floor(f1 * 255.0f) + min(f2, 0.9900000095367431640625f);
}

void frag_main()
{
    float3 n = normalize(wnormal);
    float3 basecol = float3(0.1959859430789947509765625f, 0.0400196574628353118896484375f, 0.00346841500140726566314697265625f);
    float roughness = 0.8277056217193603515625f;
    float metallic = 0.0519480518996715545654296875f;
    float occlusion = 1.0f;
    float specular = 0.5f;
    float3 emissionCol = 0.0f.xxx;
    n /= ((abs(n.x) + abs(n.y)) + abs(n.z)).xxx;
    float2 _106;
    if (n.z >= 0.0f)
    {
        _106 = n.xy;
    }
    else
    {
        _106 = octahedronWrap(n.xy);
    }
    n = float3(_106.x, _106.y, n.z);
    fragColor[0] = float4(n.xy, roughness, packFloatInt16(metallic, 0u));
    fragColor[1] = float4(basecol, packFloat2(occlusion, specular));
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    wnormal = stage_input.wnormal;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.fragColor = fragColor;
    return stage_output;
}
