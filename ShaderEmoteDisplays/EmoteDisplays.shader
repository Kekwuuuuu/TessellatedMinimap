Shader "VRChat/Avatar/EmoteDisplays"
{
    Properties
    {
        _MainTex ("Display Texture", 2D) = "white" {}
        _EmissiveColor ("Emissive Color", Color) = (1,1,1,1)
        _EmissiveStrength ("Emissive Strength", Range(0, 5)) = 1.0
        
        // Old monitor effect
        _PixelCountX ("Pixel Count X", Float) = 32
        _PixelCountY ("Pixel Count Y", Float) = 32
        _Roundness ("Pixel Roundness", Range(0, 1)) = 0.8
        _Fuzziness ("Pixel Fuzziness", Range(0, 0.5)) = 0.15
        
        // Rendering mode
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Float) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Float) = 1
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        [Toggle] _AlphaToMask ("Alpha To Mask", Float) = 0
    }
    
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100
        
        Pass
        {
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _EmissiveColor;
            float _EmissiveStrength;
            float _PixelCountX;
            float _PixelCountY;
            float _Roundness;
            float _Fuzziness;
            float _Cutoff;
            fixed _AlphaToMask;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }
            
            // Helper: rounded rectangle signed distance (box of size 1, centered)
            float roundedRectDistance(float2 p, float radius)
            {
                float2 halfSize = float2(0.5, 0.5) - radius;
                float2 d = abs(p) - halfSize;
                return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                // Clamp pixel count to avoid extreme values
                float pxCountX = max(1, _PixelCountX);
                float pxCountY = max(1, _PixelCountY);
                
                // Compute pixelated grid coordinates
                float2 gridUV = i.uv * float2(pxCountX, pxCountY);
                float2 pixelCoord = floor(gridUV);
                float2 pixelCenterUV = (pixelCoord + 0.5) / float2(pxCountX, pxCountY);
                
                // Sample colors for this pixel and its four neighbors
                fixed4 center = tex2D(_MainTex, pixelCenterUV);
                fixed4 left   = tex2D(_MainTex, (pixelCoord + float2(-1, 0) + 0.5) / float2(pxCountX, pxCountY));
                fixed4 right  = tex2D(_MainTex, (pixelCoord + float2( 1, 0) + 0.5) / float2(pxCountX, pxCountY));
                fixed4 down   = tex2D(_MainTex, (pixelCoord + float2( 0,-1) + 0.5) / float2(pxCountX, pxCountY));
                fixed4 up     = tex2D(_MainTex, (pixelCoord + float2( 0, 1) + 0.5) / float2(pxCountX, pxCountY));
                
                // Cell local UV: range [-0.5, 0.5]
                float2 cellUV = frac(gridUV) - 0.5;
                
                // Distance to rounded rectangle (0 at center, grows outward)
                float radius = _Roundness * 0.5;
                float dist = roundedRectDistance(cellUV, radius);
                // Mask: 1 inside the pixel, 0 outside (sharp)
                float mask = 1.0 - saturate(dist * 2.0);
                
                // Apply fuzziness: blend neighboring colors near the edge
                float blurAmount = _Fuzziness;
                // Gradient direction: how close to horizontal/vertical edges
                float2 edgeFactor = saturate((abs(cellUV) - (0.5 - blurAmount)) / blurAmount);
                float horizBlend = edgeFactor.x;
                float vertBlend = edgeFactor.y;
                
                // Blend horizontally with left/right, vertically with up/down
                fixed4 blurred = center;
                if (horizBlend > 0.01)
                {
                    blurred = lerp(blurred, lerp(left, right, (cellUV.x + 0.5)), horizBlend);
                }
                if (vertBlend > 0.01)
                {
                    blurred = lerp(blurred, lerp(down, up, (cellUV.y + 0.5)), vertBlend);
                }
                
                // Apply the rounded pixel shape mask (edges become transparent/dark)
                float roundMask = smoothstep(0.0, _Fuzziness * 0.8, mask);
                blurred.a *= roundMask;
                
                // Emissive color boost
                fixed3 emissive = _EmissiveColor.rgb * _EmissiveStrength;
                fixed3 finalRGB = blurred.rgb * (emissive + 0.5); // 0.5 base to keep detail with emission
                finalRGB = max(finalRGB, emissive * blurred.a);    // guarantee glow
                
                fixed4 finalColor = fixed4(finalRGB, blurred.a);
                
                // Handle rendering modes via blend states and alpha cutout
                #if defined(_ALPHATEST_ON)
                    clip(finalColor.a - _Cutoff);
                #endif
                
                return finalColor;
            }
            ENDCG
        }
    }
    
    CustomEditor "EmoteDisplaysShaderGUI"
}