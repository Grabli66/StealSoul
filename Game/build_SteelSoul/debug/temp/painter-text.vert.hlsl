uniform float4x4 projectionMatrix;

static float4 gl_Position;
static float3 vertexPosition;
static float2 texCoord;
static float2 vertexUV;
static float4 fragmentColor;
static float4 vertexColor;

struct SPIRV_Cross_Input
{
    float4 vertexColor : TEXCOORD0;
    float3 vertexPosition : TEXCOORD1;
    float2 vertexUV : TEXCOORD2;
};

struct SPIRV_Cross_Output
{
    float4 fragmentColor : TEXCOORD0;
    float2 texCoord : TEXCOORD1;
    float4 gl_Position : SV_Position;
};

void vert_main()
{
    gl_Position = mul(float4(vertexPosition, 1.0f), projectionMatrix);
    texCoord = vertexUV;
    fragmentColor = vertexColor;
    gl_Position.z = (gl_Position.z + gl_Position.w) * 0.5;
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    vertexPosition = stage_input.vertexPosition;
    vertexUV = stage_input.vertexUV;
    vertexColor = stage_input.vertexColor;
    vert_main();
    SPIRV_Cross_Output stage_output;
    stage_output.gl_Position = gl_Position;
    stage_output.texCoord = texCoord;
    stage_output.fragmentColor = fragmentColor;
    return stage_output;
}
