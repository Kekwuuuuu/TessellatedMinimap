Shader "Custom/VirtualHeightMap"
{
    Properties
    {
        _Invert ("Invert (Near=White, Far=Black)", Range(0,1)) = 0
        _NearFade ("Near Fade (0 = near plane, 1 = far plane)", Range(0,500)) = 0
        _FarFade  ("Far Fade (0 = near plane, 1 = far plane)", Range(0,500)) = 1
        _Steps ("Chunky Steps (2-64)", Range(2, 64)) = 4
        _Orthographic ("Use Orthographic Projection", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD0;
            };

            float _Invert;
            float _NearFade;
            float _FarFade;
            float _Steps;
            float _Orthographic;
            sampler2D _CameraDepthTexture;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV);
                float depthValue;

                if (_Orthographic > 0.5)
                {
                    // Orthographic: rawDepth is linear 0 (near) to 1 (far)
                    // Remap using user-defined near/fade values (also 0..1)
                    depthValue = (rawDepth - _NearFade) / (_FarFade - _NearFade);
                }
                else
                {
                    // Perspective: convert to linear eye depth (world units)
                    float linearDepth = LinearEyeDepth(rawDepth);
                    // User provides _NearFade and _FarFade in world units (same unit as linearDepth)
                    depthValue = (linearDepth - _NearFade) / (_FarFade - _NearFade);
                }

                depthValue = clamp(depthValue, 0, 1);

                if (_Invert > 0.5) depthValue = 1.0 - depthValue;

                float steps = max(2, round(_Steps));
                depthValue = floor(depthValue * steps) / (steps - 1);

                return fixed4(depthValue, depthValue, depthValue, 1.0);
            }
            ENDCG
        }
    }
}