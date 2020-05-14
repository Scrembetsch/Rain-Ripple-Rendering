Shader "Custom/Gerstner" 
{
	Properties 
	{
        [Header(Main Tex)]
		_Color ("Color", Color) = (0.43, 0.62, 1, 0.4)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.7
		_Metallic ("Metallic", Range(0,1)) = 0.0

        [Space]
        [Header(Gerstner Waves)]
        _WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1, 1, 0.25, 30)
        _WaveB ("Wave B", Vector) = (1, 0.6, 0.2, 15)
        _WaveC ("Wave C", Vector) = (1, 1.3, 0.2, 9)

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
		#pragma surface Surf Standard vertex:Vert alpha fullforwardshadows addshadow finalcolor:ResetAlpha
		#pragma target 3.0

		#include "lib/General.cginc"
		#include "lib/Flow.cginc"
		#include "lib/LookingThroughWater.cginc"
		#include "lib/Gerstner.cginc"

		sampler2D _MainTex;
		sampler2D _FlowMap;
		sampler2D _DerivHeightMap;

		float _Glossiness;
		float _Metallic;
		float4 _Color;

		float4 _WaveA;
        float4 _WaveB;
        float4 _WaveC;

		float _UJump;
		float _VJump;
		float _Tiling;
		float _Speed;
		float _FlowStrength;
		float _FlowOffset;
		float _HeightScale;
		float _HeightScaleModulated;
		
		struct Input 
		{
			float2 uv_MainTex;
			float4 screenPos;
		};

        void Vert(inout appdata_full vertexData)
		{
            float3 gridPoint = vertexData.vertex.xyz;
            float3 tangent = float3(1, 0, 0);
            float3 binormal = float3(0, 0, 1);
            float3 p = gridPoint;
            p += GerstnerWave(_WaveA, gridPoint, tangent, binormal);
            p += GerstnerWave(_WaveB, gridPoint, tangent, binormal);
            p += GerstnerWave(_WaveC, gridPoint, tangent, binormal);
            float3 normal = normalize(cross(binormal, tangent));
            vertexData.vertex.xyz = p;
            vertexData.normal = normal;
        }

		void Surf (Input IN, inout SurfaceOutputStandard o) 
		{
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

			float4 c = (texA + texB) * _Color;

			o.Albedo = c.rgb;
			o.Normal = normalize(float3(-(dhA.xy + dhB.xy), 1));
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