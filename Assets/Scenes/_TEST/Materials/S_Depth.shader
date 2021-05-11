Shader "ShaderSandbox/S_Depth"
    {
        properties {
            _debug ("debug", Range (0.001, 1000)) = 1
        }
        
        SubShader {
            Tags { 
                "RenderType"="Opaque"
                "Queue"="Geometry"
                 }
            
            Pass {
                ZWrite ON
                Blend SrcAlpha OneMinusSrcAlpha
                LOD 100

                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
                
                struct appdata
                {
                    float4 vertex   : POSITION;
                    float2 uv       : TEXCOORD0;
                };

                float _debug;
                
                struct v2f {
                    float4 vertex       : SV_POSITION;
                };
                
                v2f vert (appdata v) {
                    v2f o;       
                    o.vertex = TransformObjectToHClip(v.vertex); //obj->wld->view->screen
                    return o;
                }
                
                float4  frag(v2f i) : SV_Target {
                    float3 col = {0.f, 0.f, 0.f};

                    float2 screenPosRGB = i.vertex.xy / _ScreenSize.xy; //get screen pos in 0-1 float.
                   // col.rg = screenPos.xy / _ScreenSize.xy;
                    
                    uint4 screenPosPixels = uint4(i.vertex.xy, 0, 0);
                    float4 depth = _CameraDepthTexture.Load(screenPosPixels); //sample depth from depth texture in pixel coords
                    col.b = depth.r;
                    
                    return float4(col, 1);                    
                }
                ENDHLSL
            }
        }
    }