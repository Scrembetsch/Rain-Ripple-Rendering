#if !defined(GENERAL_INCLUDED)
#define GENERAL_INCLUDED

float3 UnpackDerivativeHeight (float4 textureData) 
{
    float3 dh = textureData.agb;
    dh.xy = dh.xy * 2 - 1;
    return dh;
}

float GenerateNoise(float2 tex, float2 tiling)
{
    float x = (tex.x * tiling.x) - ((tex.x * tiling.x) % 1);
    float y = (tex.y * tiling.y) - ((tex.y * tiling.y) % 1);
    float noise = frac(sin(dot(float2(x, y),
                    float2(1.222,92.976)))
                    * 43758.5453123);
    return noise;
}

float GetIntPart(float value)
{
    return value - (value % 1);
}

#endif  // GENERAL_INCLUDED