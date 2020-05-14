Shader "Custom/Normal"
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

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_RainTex1;
            float2 uv_RainTex2;
            
            float4 screenPos;
        };

        void Surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Disortion
            float3 flow = tex2D(_FlowMap, IN.uv_MainTex).rgb;
			flow.xy = flow.xy * 2 - 1;
			flow *= _FlowStrength;
			float noise = tex2D(_FlowMap, IN.uv_MainTex).a;
			float time = _Time.y * _Speed + noise;
			float2 jump = float2(_UJump, _VJump);

			float3 uvwA = FlowUVW(
				IN.uv_MainTex, flow.xy, jump,
				_FlowOffset, _Tiling, time, false
			);
			float3 uvwB = FlowUVW(
				IN.uv_MainTex, flow.xy, jump,
				_FlowOffset, _Tiling, time, true
			);

			float finalHeightScale =
				flow.z * _HeightScaleModulated + _HeightScale;

			float3 dhA =
				UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwA.xy)) *
				(uvwA.z * finalHeightScale);
			float3 dhB =
				UnpackDerivativeHeight(tex2D(_DerivHeightMap, uvwB.xy)) *
				(uvwB.z * finalHeightScale);

			float4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
			float4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;

            float3 normalDisortion = normalize(float3(-(dhA.xy + dhB.xy), 1));

            float4 c = (texA + texB) * _Color;

            // Rain Ripple
            float noise1 = 0;
            float noise2 = 0;

            noise1 = GenerateNoise(IN.uv_RainTex1, _Tiling1.xy);
            noise2 = GenerateNoise(IN.uv_RainTex2, _Tiling2.xy);

            IN.uv_RainTex1 = IN.uv_RainTex1 * _Tiling1 + _Offset1;
            IN.uv_RainTex2 = IN.uv_RainTex2 * _Tiling2 + _Offset2;

            float3 normalRain;

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
                    float sCenter1 = GetHeightValue(sampleCenter1, _Speed1, _CutoffOffset1, _WaveValue1, noise1, _Sigma, _RhoHeavy);
                    float sRight1 = GetHeightValue(sampleRight1, _Speed1, _CutoffOffset1, _WaveValue1, noise1, _Sigma, _RhoHeavy);
                    float sUp1 = GetHeightValue(sampleUp1, _Speed1, _CutoffOffset1, _WaveValue1, noise1, _Sigma, _RhoHeavy);
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
                    float sCenter2 = GetHeightValue(sampleCenter2, _Speed2, _CutoffOffset2, _WaveValue2, noise2, _Sigma, _RhoHeavy);
                    float sRight2 = GetHeightValue(sampleRight2, _Speed2, _CutoffOffset2, _WaveValue2, noise2, _Sigma, _RhoHeavy);
                    float sUp2 = GetHeightValue(sampleUp2, _Speed2, _CutoffOffset2, _WaveValue2, noise2, _Sigma, _RhoHeavy);
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
                normalRain = normalize(norm1 + norm2);
            }
            else if(norm1.z != 1)
            {
                normalRain = norm1;
            }
            else if(norm2.z != 1)
            {
                normalRain = norm2;
            }

            o.Albedo = c.rgb;
            o.Normal = BlendNormals(normalDisortion, normalRain);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
			o.Emission = ColorBelowWater(IN.screenPos, o.Normal) * (1 - c.a);
        }

        void ResetAlpha (Input IN, SurfaceOutputStandard o, inout float4 color) 
		{
			color.a = 1;
		}
        ENDCG
    }
}
