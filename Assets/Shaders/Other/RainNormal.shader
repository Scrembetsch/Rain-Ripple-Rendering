Shader "Custom/Normal"
{
    Properties
    {
        [Header(Main Tex)]
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _MainTex ("Albedo (RGB)", 2D) = "white" {}

        [Space]
        [Header(Rain Texture 1)]
        [NoScaleOffset]
        _RainTex1 ("Rain Ripple Texture", 2D) = "white" {}
        _Tiling1 ("Tiling (ignore ZW)", Vector) = (1, 1, 0, 0)
        _Offset1 ("Offset (ignore ZW)", Vector) = (0, 0, 0, 0)
        _NormStrength1 ("Normal Strength Texture", Range(0,10)) = 3.0
        _Speed1 ("Speed", Range(0,2)) = 1
        _CutoffOffset1 ("Cutoff Offset", Range(0, 5)) = 1
        _WaveValue1 ("Number of Waves", Range(0, 100)) = 20

        [Space]
        [Header(Rain Texture 2)]
        [NoScaleOffset]
        _RainTex2 ("Rain Ripple Texture", 2D) = "white" {}
        _Tiling2 ("Tiling (ignore ZW)", Vector) = (1, 1, 0, 0)
        _Offset2 ("Offset (ignore ZW)", Vector) = (0, 0, 0, 0)
        _NormStrength2 ("Normal Strength Texture", Range(0,10)) = 3.0
        _Speed2 ("Speed", Range(0,2)) = 1
        _CutoffOffset2 ("Cutoff Offset", Range(0, 5)) = 1
        _WaveValue2 ("Number of Waves", Range(0, 100)) = 20

        [Space]
        [Header(Capillary Wave Settings)]
        _Sigma ("Surface Tension", Float) = 72.75
        _RhoHeavy ("Density of Heavier Fuild", Float) = 997
        _RhoLight ("Density of Lighter Fluid", Float) = 1.2041
        _Gravity ("Gravity", Float) = 9.81

    }
    SubShader
    {
        Tags 
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        LOD 300

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alpha
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _RainTex1;
        sampler2D _RainTex2;

        uniform float4 _MainTex_TexelSize;
        uniform float4 _RainTex1_TexelSize;
        uniform float4 _RainTex2_TexelSize;

        float4 _Color;
        float _Glossiness;
        float _Metallic;

        float _NormStrength1;
        float _Speed1;
        float _CutoffOffset1;
        float _WaveValue1;
        float2 _Tiling1;
        float2 _Offset1;

        float _NormStrength2;
        float _Speed2;
        float _CutoffOffset2;
        float _WaveValue2;
        float2 _Tiling2;
        float2 _Offset2;

        float _Sigma;
        float _RhoHeavy;
        float _RhoLight;
        float _Gravity;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_RainTex1;
            float2 uv_RainTex2;
        };

        float getHeightValue(float4 colorValue, float speed, float cutoffOffset, float waves, float noise)
        {
            float output = 0;
            float time = (_Time.y + colorValue.g + noise) * speed;
            float invColor = 1 - colorValue.r;
            float duration = time % (1 + cutoffOffset);
            if(duration > invColor)
            {
                if(duration > cutoffOffset && (time - cutoffOffset) % (1 + cutoffOffset) > invColor)
                {
                    output = 0;
                }
                else
                {
                    output = 1;
                }
            }
            if(output == 0)
            {
                return output;
            }
            // Create duration value between 0 - 1
            float normDur = duration / (1 + cutoffOffset);
            float k = invColor * waves;    // Wave number

            // Calculate waves (Capillary Wave)

            // Water, Air
            // output = sqrt((_Sigma / (_RhoHeavy + _RhoLight)) * pow(abs(k), 3));
            
            // Water, Vacuum
            output = -1.5 + sqrt((_Sigma / _RhoHeavy) * pow(abs(k), 3));

            // Water, Air, Gravity
            // float part1 = ((_RhoHeavy - _RhoLight) / (_RhoHeavy + _RhoLight)) * _Gravity;
            // float part2 = (_Sigma / (_RhoHeavy + _RhoLight)) * pow(k, 2);
            // output = sqrt(abs(k) * (part1 + part2));

            // Create moving
            output = sin(output * (3.14 - (normDur * 3.14)));

            // Wave should fade out to the end
            output *= colorValue.r * (1 - normDur);
            return output;
        }

        float generateNoise(float2 tex, float2 tiling)
        {
            float noise = 0;
            float x = (tex.x * tiling.x) - ((tex.x * tiling.x) % 1);
            float y = (tex.y * tiling.y) - ((tex.y * tiling.y) % 1);
            noise = frac(sin(dot(float2(x, y),
                         float2(10.222,93.976)))
                            * 43758.5453123);
            return noise;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            // c.a = 0.2;

            float noise1 = 0;
            float noise2 = 0;

            noise1 = generateNoise(IN.uv_RainTex1, _Tiling1.xy);
            noise2 = generateNoise(IN.uv_RainTex2, _Tiling2.xy);

            IN.uv_RainTex1 = IN.uv_RainTex1 * _Tiling1 + _Offset1;
            IN.uv_RainTex2 = IN.uv_RainTex2 * _Tiling2 + _Offset2;

            float3 norm;

            float3 norm1 = float3(0, 0, 1);
            float4 sampleCenter1 = tex2D(_RainTex1, IN.uv_RainTex1);
            float4 sampleRight1 = tex2D(_RainTex1, IN.uv_RainTex1 + float2(_RainTex1_TexelSize.x, 0));
            float4 sampleUp1 = tex2D(_RainTex1, IN.uv_RainTex1 + float2(0, _RainTex1_TexelSize.y));

            float3 norm2  = float3(0, 0, 1);
            float4 sampleCenter2 = tex2D(_RainTex2, IN.uv_RainTex2);
            float4 sampleRight2 = tex2D(_RainTex2, IN.uv_RainTex2 + float2(_RainTex2_TexelSize.x, 0));
            float4 sampleUp2 = tex2D(_RainTex2, IN.uv_RainTex2 + float2(0, _RainTex2_TexelSize.y));

            if(sampleCenter1.r != 0 || sampleCenter2.r != 0)
            {
                float sampleDeltaRight = 0;
                float sampleDeltaUp = 0;
                
                if(sampleCenter1.r != 0)
                {
                    float sCenter1 = getHeightValue(sampleCenter1, _Speed1, _CutoffOffset1, _WaveValue1, noise1);
                    float sRight1 = getHeightValue(sampleRight1, _Speed1, _CutoffOffset1, _WaveValue1, noise1);
                    float sUp1 = getHeightValue(sampleUp1, _Speed1, _CutoffOffset1, _WaveValue1, noise1);
                    if(sCenter1 != 0)
                    {
                        sampleDeltaRight = (sRight1 - sCenter1) * _NormStrength1;
                        sampleDeltaUp = (sUp1 - sCenter1) * _NormStrength1;
                        norm1 = normalize(cross(
                            float3(1, 0, sampleDeltaRight),
                            float3(0, 1, sampleDeltaUp)
                        ));
                    }
                }
                if(sampleCenter2.r != 0)
                {
                    float sCenter2 = getHeightValue(sampleCenter2, _Speed2, _CutoffOffset2, _WaveValue2, noise2);
                    float sRight2 = getHeightValue(sampleRight2, _Speed2, _CutoffOffset2, _WaveValue2, noise2);
                    float sUp2 = getHeightValue(sampleUp2, _Speed2, _CutoffOffset2, _WaveValue2, noise2);
                    if(sCenter2 != 0)
                    {
                        sampleDeltaRight = (sRight2 - sCenter2) * _NormStrength2;
                        sampleDeltaUp = (sUp2 - sCenter2) * _NormStrength2;
                        norm2 = normalize(cross(
                            float3(1, 0, sampleDeltaRight),
                            float3(0, 1, sampleDeltaUp)
                        ));
                    }
                }
            }

            if(norm1.z != 1 && norm2.z != 1)
            {
                norm = normalize(norm1 + norm2);
            }
            else if(norm1.z != 1)
            {
                norm = norm1;
            }
            else if(norm2.z != 1)
            {
                norm = norm2;
            }

            o.Albedo = c.rgb;
            o.Normal = norm;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
