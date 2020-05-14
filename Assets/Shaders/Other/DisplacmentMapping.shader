Shader "Custom/DisplacmentMapping"
{
    Properties 
    {
        _Tess ("Tessellation", Range(1,64)) = 4

        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _MainTex ("Base (RGB)", 2D) = "white" {}

        _RainTex1 ("Rain Ripple Texture 1", 2D) = "white" {}
        _DispStrength1 ("Displacment Strength Texture 1", Range(0,1)) = 0.3
        _NormStrength1 ("Normal Strength Texture 1", Range(0,10)) = 3.0
        _Speed1 ("Speed 1", Range(0,10)) = 1
        _CutoffOffset1 ("Cutoff Offset 1", Range(0, 5)) = 1
        
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
        #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessDistance nolightmap
        #pragma target 4.6
        #include "Tessellation.cginc"

        sampler2D _MainTex;
        sampler2D _RainTex1;

        uniform float4 _RainTex1_TexelSize;

        float _Tess;

        float4 _Color;
        float _Glossiness;
        float _Metallic;
        
        float _DispStrength1;
        float _NormStrength1;
        float _Speed1;
        float _CutoffOffset1;
        
        struct appdata 
        {
            float4 vertex : POSITION;
            float4 tangent : TANGENT;
            float3 normal : NORMAL;
            float2 texcoord : TEXCOORD0;
        };

        struct Input 
        {
            float2 uv_MainTex;
            float2 uv_RainTex1;
        };


        float4 tessDistance (appdata v0, appdata v1, appdata v2)
        {
            float minDist = 10.0;
            float maxDist = 1000.0;
            return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
        }

        float getHeightValue(float colorValue, float speed, float cutoffOffset)
        {
            float a = 0;
            float time = _Time.y * speed;
            if(time % (1 + cutoffOffset) > colorValue){
                if(time % (1 + cutoffOffset) > cutoffOffset && (time - cutoffOffset) % (1 + cutoffOffset) > colorValue){
                    a = 0;
                    }else{
                    a = 1;
                }
            }
            a = (1 - colorValue) * a * 3.14;
            a = sin(a * 10);
            return a;
        }

        void disp (inout appdata v)
        {
            float sampleCenter = 1 - tex2Dlod(_RainTex1, float4(v.texcoord.xy,0,0)).r;
            sampleCenter = getHeightValue(sampleCenter, _Speed1, _CutoffOffset1);
            float d = sampleCenter * _DispStrength1;
            v.vertex.xyz += v.normal * d;
        }

        void surf (Input IN, inout SurfaceOutput o) 
        {
            float4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            c.a = 0.1;
            float3 norm = float3(0, 0, 1);
            float sampleCenter1 = 1 - tex2D(_RainTex1, IN.uv_RainTex1).r;
            float sampleRight1 = 1 - tex2D(_RainTex1, IN.uv_RainTex1 + float2(_RainTex1_TexelSize.x, 0)).r;
            float sampleUp1 = 1 - tex2D(_RainTex1, IN.uv_RainTex1 + float2(0, _RainTex1_TexelSize.y)).r;

            if(sampleCenter1 != 1)
            {
                sampleCenter1 = getHeightValue(sampleCenter1, _Speed1, _CutoffOffset1);
                sampleRight1 = getHeightValue(sampleRight1, _Speed1, _CutoffOffset1);
                sampleUp1 = getHeightValue(sampleUp1, _Speed1, _CutoffOffset1);

                float sampleDeltaRight = sampleRight1 - sampleCenter1;
                float sampleDeltaUp = sampleUp1 - sampleCenter1;

                norm = cross(
                float3(1, 0, sampleDeltaRight * _NormStrength1 * c.r),
                float3(0, 1, sampleDeltaUp * _NormStrength1 * c.r)
                );
            }

            o.Albedo = c.rgb;
            o.Specular = 0.2;
            o.Normal = normalize(norm);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
