Shader "Custom/Minimap"
{
    Properties
    {
        _MainTex ("Color Texture (RGB)", 2D) = "white" {}
        _HeightTex ("Render Texture (Converted to Grayscale Height)", 2D) = "white" {}
        _DisplacementStrength ("Displacement Strength", Range(-0.5, 0.5)) = 0.05
        _DisplacementOffset ("Displacement Offset", Range(-1, 1)) = 0.0
        _Color ("Tint Color", Color) = (1,1,1,1)
        _EmissionColor ("Emission Color", Color) = (1,1,1)
        _EmissionStrength ("Emission Strength", Range(0, 5)) = 1.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Tessellation ("Tessellation (subdivision)", Range(1, 32)) = 8
        _AntiPerspective ("Anti‑Perspective (0=none, 1=full correct)", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert tessellate:tessEdge addshadow
        #pragma target 4.6

        #include "Tessellation.cginc"
        #include "UnityCG.cginc"

        sampler2D _MainTex;
        sampler2D _HeightTex;
        half _DisplacementStrength;
        half _DisplacementOffset;
        fixed4 _Color;
        half3 _EmissionColor;
        half _EmissionStrength;
        half _Glossiness;
        half _Metallic;
        float _Tessellation;
        float _AntiPerspective;

        struct Input
        {
            float2 uv_MainTex;
        };

        float4 tessEdge (appdata_full v0, appdata_full v1, appdata_full v2)
        {
            return UnityEdgeLengthBasedTessCull(v0.vertex, v1.vertex, v2.vertex, _Tessellation, 0.0);
        }

        void vert (inout appdata_full v)
        {
            // Original UV
            float2 origUV = v.texcoord.xy;
            
            // Compute clip space position for this vertex
            float4 clipPos = UnityObjectToClipPos(v.vertex);
            float3 ndc = clipPos.xyz / clipPos.w;  // range -1..1 in x,y
            float2 ndc_centered = ndc.xy;           // (0,0) = screen centre
            
            // Radial distance from screen centre (0 at centre, 1 at corner)
            float radiusSq = dot(ndc_centered, ndc_centered);
            // Pincushion factor: 1 = no change, >1 = pull outward (anti‑perspective)
            float factor = 1.0 + _AntiPerspective * radiusSq;
            
            // Distort UV: centre‑relative scaling
            float2 distortedUV = (origUV - 0.5) * factor + 0.5;
            
            // Clamp to [0,1] to avoid sampling outside texture (optional)
            distortedUV = clamp(distortedUV, 0.001, 0.999);
            
            // Sample height map using distorted UV
            float4 colorTex = tex2Dlod(_HeightTex, float4(distortedUV, 0, 0));
            float height = Luminance(colorTex.rgb);
            
            float offset = (height - 0.5 + _DisplacementOffset) * _DisplacementStrength;
            v.vertex.xyz += v.normal * offset;
            
            // Pass distorted UV to surface shader for colour sampling
            v.texcoord.xy = distortedUV;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 texColor = tex2D(_MainTex, IN.uv_MainTex);
            fixed4 finalColor = texColor * _Color;
            
            o.Albedo = finalColor.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Emission = _EmissionColor * _EmissionStrength;
            o.Alpha = finalColor.a;
        }
        ENDCG
    }
    Fallback "Standard"
}