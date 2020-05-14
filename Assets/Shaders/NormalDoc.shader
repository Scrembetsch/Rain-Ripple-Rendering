Shader "Custom/NormalDoc"
{
    Properties
    {
        [Header(Main Tex)]
		_Color ("Color", Color) = (0.43, 0.62, 1, 0.4)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.7
		_Metallic ("Metallic", Range(0,1)) = 0.0

        [Space]
		[Header(Disortion Settings)]
        [NoScaleOffset]
		_FlowMap ("Flow (RG, A Noise)", 2D) = "black" {}
        [NoScaleOffset]
		_DerivHeightMap ("Deriv (AG) Height (B)", 2D) = "black" {}
        _UJump ("U jump per phase", Range(-0.25, 0.25)) = 0.24
        _VJump ("V jump per phase", Range(-0.25, 0.25)) = 0.21
        _Tiling ("Tiling", Float) = 5
        _Speed ("Speed", Float) = 0.1
        _FlowStrength ("Flow Strength", Float) = 0.1
        _FlowOffset ("Flow Offset", Float) = 0
        _HeightScale ("Height Scale, Constant", Float) = 0.5
        _HeightScaleModulated ("Height Scale, Modulated", Float) = 5

		[Space]
		[Header(Transparency Settings)]
		_WaterFogColor ("Water Fog Color", Color) = (0, 0, 1, 0)
		_WaterFogDensity ("WaterFogDensity", Range(0, 2)) = 0.25
		_RefractionStrength ("Refraction Strength", Range(0, 1)) = 0.1

        [Space]
        [Header(Rain Texture 1)]
        [NoScaleOffset]
        _RainTex1 ("Rain Ripple Texture", 2D) = "white" {}
        _Tiling1 ("Tiling (ignore ZW)", Vector) = (1, 1, 0, 0)
        _Offset1 ("Offset (ignore ZW)", Vector) = (0, 0, 0, 0)
        _NormStrength1 ("Normal Strength Texture", Range(0,10)) = 3.0
        _Speed1 ("Speed", Range(0,2)) = 1
        _CutoffOffset1 ("Cutoff Offset", Range(0, 5)) = 0.5
        _WaveValue1 ("Number of Waves", Range(0, 100)) = 20

        [Space]
        [Header(Rain Texture 2)]
        [NoScaleOffset]
        _RainTex2 ("Rain Ripple Texture", 2D) = "white" {}
        _Tiling2 ("Tiling (ignore ZW)", Vector) = (1, 1, 0, 0)
        _Offset2 ("Offset (ignore ZW)", Vector) = (0, 0, 0, 0)
        _NormStrength2 ("Normal Strength Texture", Range(0,10)) = 3.0
        _Speed2 ("Speed", Range(0,2)) = 1
        _CutoffOffset2 ("Cutoff Offset", Range(0, 5)) = 0.5
        _WaveValue2 ("Number of Waves", Range(0, 100)) = 20

        [Space]
        [Header(Capillary Wave Settings)]
        _Sigma ("Surface Tension", Float) = 72.75
        _RhoHeavy ("Density of Heavier Fuild", Float) = 997

    }
    SubShader
    {
		Tags 
		{
            "RenderType"="Transparent"
			"Queue"="Transparent"
		}
		LOD 300

		GrabPass
		{
			"_WaterBackground"
		}

        CGPROGRAM
		#pragma surface Surf Standard alpha fullforwardshadows addshadow finalcolor:ResetAlpha
		#pragma target 3.0

		#include "lib/General.cginc"
		#include "lib/Flow.cginc"
		#include "lib/LookingThroughWater.cginc"
        #include "lib/Normal.cginc"

        sampler2D _MainTex;
        sampler2D _FlowMap;
		sampler2D _DerivHeightMap;
        sampler2D _RainTex1;
        sampler2D _RainTex2;

        uniform float4 _MainTex_TexelSize;
        uniform float4 _RainTex1_TexelSize;
        uniform float4 _RainTex2_TexelSize;

        float4 _Color;
        float _Glossiness;
        float _Metallic;

		float _UJump;
		float _VJump;
		float _Tiling;
		float _Speed;
		float _FlowStrength;
		float _FlowOffset;
		float _HeightScale;
		float _HeightScaleModulated;

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

        float _NormalStrength;
        float _Speedi;
        float _CutoffOffset;
        float _Frequency;
        float _WaveSpeed;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_RainTex1;
            float2 uv_RainTex2;
            
            float4 screenPos;
        };

        float GetHeight(float3 color, float noise)
        {
            if(color.r != 0)
            {
                float time = (0.2) * _Speedi + color.g + noise;
                float inverseColor = 1 - color.r;
                float duration = time % (1 + _CutoffOffset);
                if(duration > inverseColor)
                {
                    if(duration > _CutoffOffset && (time - _CutoffOffset) % (1 + _CutoffOffset) > inverseColor)
                    {
                        return 0;
                    }
                }
                else
                {
                    return 0;
                }
                float output = -1.5 + sqrt((72.72 / 997) * pow(abs(inverseColor * 7), 3));
                output = output * 2 * 3.14;
                return sin(output + duration * _WaveSpeed) * color.r;
            }
            return color.r;
        }

        bool between(float p, float min, float max)
        {
            return p > min && p < max;
        }

        void Surf (Input IN, inout SurfaceOutputStandard o)
        {
            _NormalStrength = 2;
            _Speedi = 1;
            _CutoffOffset = 0.5;
            _Frequency = 3;
            _WaveSpeed  = 10;

            float noise = GenerateNoise(IN.uv_RainTex1, _Tiling1.xy);
            IN.uv_RainTex1 = IN.uv_RainTex1 * _Tiling1 + _Offset1;

            float4 middle = GetHeight(tex2D(_RainTex1, IN.uv_RainTex1), noise);
            float4 right = GetHeight(tex2D(_RainTex1, IN.uv_RainTex1 
                + float2(_RainTex1_TexelSize.x, 0)), noise);
            float4 up = GetHeight(tex2D(_RainTex1, IN.uv_RainTex1 
                + float2(0, _RainTex1_TexelSize.y)), noise);

            float sampleDeltaRight = (right - middle) * _NormalStrength;
            float sampleDeltaUp = (up - middle) * _NormalStrength;

            float3 norm = normalize(cross(
                float3(1, 0, sampleDeltaRight),
                float3(0, 1, sampleDeltaUp)
            ));

            float space = 0.01;
            if(between(IN.uv_RainTex1.x % 1, 0, space) || between(IN.uv_RainTex1.y % 1, 0, space) || between(IN.uv_RainTex1.x % 1, 1- space, 1) || between(IN.uv_RainTex1.y % 1, 1- space, 1)){
                o.Albedo = float3(0, 0, 0);

            }else{
                o.Albedo = float3(1, 1, 1);
            }
            o.Normal = norm;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = 1;
        }

        void ResetAlpha (Input IN, SurfaceOutputStandard o, inout float4 color) 
		{
			color.a = 1;
		}
        ENDCG
    }
}
