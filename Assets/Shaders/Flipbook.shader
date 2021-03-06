Shader "Custom/Flipbook"
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

        [Header(Atlas 1)]
        [NoScaleOffset]
        _AtlasTex1 ("Atlas (Normal)", 2D) = "white" {}
        _Tiling1 ("Tiling", Vector) = (5, 5, 0, 0)
        _CountX1 ("Number of pictures (X)", Float) = 8
        _CountY1 ("Number of pictures (Y)", Float) = 8
        _TilesPerSecond1 ("Tiles/s", Float) = 32

        [Header(Atlas 2)]
        [NoScaleOffset]
        _AtlasTex2 ("Atlas (Normal)", 2D) = "white" {}
        _Tiling2 ("Tiling", Vector) = (6, 6, 0, 0)
        _CountX2 ("Number of pictures (X)", Float) = 8
        _CountY2 ("Number of pictures (Y)", Float) = 8
        _TilesPerSecond2 ("Tiles/s", Float) = 32

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
        #include "lib/Flipbook.cginc"

        sampler2D _MainTex;
		sampler2D _FlowMap;
		sampler2D _DerivHeightMap;
        sampler2D _AtlasTex1;
        sampler2D _AtlasTex2;

		float _Glossiness;
		float _Metallic;
		float4 _Color;

		float _UJump;
		float _VJump;
		float _Tiling;
		float _Speed;
		float _FlowStrength;
		float _FlowOffset;
		float _HeightScale;
		float _HeightScaleModulated;

        float4 _Tiling1;
        float4 _Tiling2;
        fixed _CountX1;
        fixed _CountX2;
        fixed _CountY1;
        fixed _CountY2;
        float _TilesPerSecond1;
        float _TilesPerSecond2;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_AtlasTex1;
            float2 uv_AtlasTex2;

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

            float3 normalDisortion = normalize(float3(-(dhA.xy + dhB.xy), 1));;

			float4 c = (texA + texB) * _Color;

            // Flipbook
            float2 newPos1 = GetAtlasPosition(IN.uv_AtlasTex1, _Tiling1, _TilesPerSecond1, _CountX1, _CountY1);
            float2 newPos2 = GetAtlasPosition(IN.uv_AtlasTex2, _Tiling2, _TilesPerSecond2, _CountX2, _CountY2);

            float3 normal1 = UnpackNormal(tex2D(_AtlasTex1, newPos1));
            float3 normal2 = UnpackNormal(tex2D(_AtlasTex2, newPos2));
			float3 normalFlipbook = normalize(normal1 + normal2);

            o.Albedo = c.rgb;
            o.Normal = BlendNormals(normalDisortion, normalFlipbook);
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
