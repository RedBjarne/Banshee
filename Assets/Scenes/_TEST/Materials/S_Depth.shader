Shader "ShaderSandbox/S_Depth"
    {
        properties {
          //  _MainTex ("Texture", 2D) = "white" {}
            _debug ("debug", Range (0.001, 1000)) = 1
        }
        
        SubShader {
            Tags { "RenderType"="Opaque" }
            //Tags { "Queue"="Transparent" "RenderType"="Transparent" }
            
            Pass {
                ZWrite ON
                //Blend SrcAlpha OneMinusSrcAlpha
                LOD 100

                HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
                //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Macros.hlsl"
                #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

                #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariables.hlsl"
                #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl"
                #include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"
                
                struct appdata
                {
                    float4 vertex   : POSITION;
                    float2 uv       : TEXCOORD0;
                };

                float _debug;
                
                struct v2f {
                    float4 vertex       : SV_POSITION;
                    float2 uv           : TEXCOORD0;
                    float4 screenPos    : TEXCOORD1;
                };
/*
                sampler2D _MainTex;
                float4 _MainTex_ST;
*/
                
/*
                inline float4 CompScrPos (float4 pos) {
                    float4 o = pos * 0.5f;
                    #if defined(UNITY_HALF_TEXEL_OFFSET)
                    o.xy = float2(o.x, o.y*_ProjectionParams.x) + o.w * _ScreenParams.zw;
                    #else
                    o.xy = float2(o.x, o.y*_ProjectionParams.x) + o.w;
                    #endif
                 
                    o.zw = pos.zw;
                    return o;
                }*/
                
                v2f vert (appdata v) {
                    v2f o;
                    //o.vertex = TransformObjectToHClip(v.vertex); //obj->wld->screen
                    float4 worldPos = mul(UNITY_MATRIX_M, v.vertex);
                    o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                    o.uv = v.uv;
                    
                    //o.screenPos.xy = o.vertex.xy; //perspective correction
                    
                    o.screenPos = ComputeScreenPos(TransformWorldToHClip(worldPos), _ProjectionParams.x);
                 //   output.ScreenPosition = ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
                    //o.screenPos.xy = o.vertex.xy/o.vertex.w; //perspective correction             
                  /*  o.screenPos.x = o.vertex.x; 
                    o.screenPos.y = -o.vertex.y; //flip y
                    
                    float ratio = _ScreenSize.x/_ScreenSize.y;
                    o.screenPos.xy *= 1/(_ScreenSize.x*.005);
                    o.screenPos.xy *= 1/(_ScreenSize.y*.005);*/
                   /* o.screenPos.x *= 1/(_ScreenSize.x*.025);
                    o.screenPos.y *= 1/(_ScreenSize.y*.025);*/
                    
                  /*  o.screenPos.xy += .5;

                    o.screenPos.xy = o.vertex.xy/o.vertex.w; //perspective correction     
                    o.screenPos.x *= _ScreenSize.x*.005*ratio;
                    o.screenPos.y *= -_ScreenSize.y*.005*ratio;
                    o.screenPos.xy += .5;*/
                    //------
                    /*o.screenPos.xy = o.vertex.xy/o.vertex.w;
                    o.screenPos.y = -o.screenPos.y;*/
                   
                    //o.screenPos.xy = o.screenPos.xy/o.screenPos.w;
                    //o.screenPos.x = o.vertex.x; // / _ScreenSize.x; 
                    //o.screenPos.y = -o.vertex.y;// / (_ScreenSize.y*.5);
                    //o.screenPos.x += _debug;
                    //o.screenPos.x /= _debug;
                    //o.screenPos.x *= .5;
                    //VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                    //o.screenPos.xy /= _ScreenSize.xy;
                    return o;
                }
                
                float4  frag(v2f i) : SV_Target {
                    float3 col = {0.f, 0.f, 0.f};
                    float3 col2 = {1.f, 0.f, 0.f};
                    
                 /*   uint2 scrPos;
                   // scrPos.x = i.screenPos.x * _ScreenSize.x;
                  //  scrPos.y = i.screenPos.y * _ScreenSize.y;
                    uint4 lort = 0;
                    lort.xy = scrPos;
                    lort.zw = 0;
                    
                    float4 depthB = _CameraDepthTexture.Load(lort);
                    col.rgb = depthB.r;*/
                    //-----
                    col.r = 1;
                    
                    uint4 lort2 = 0;
                    lort2.xy = i.screenPos.xy;
                    lort2.zw = 0;
                    float4 depthC = _CameraDepthTexture.Load(lort2);
                    col.gb = depthC.r;

                    float4 depthD = SHADERGRAPH_SAMPLE_SCENE_DEPTH(lort2);
                   // col.gb = depthD.r/10;
                    col.rg = i.screenPos.xy;
                  //  col.r = i.screenPos.x / _ScreenSize.x;
                   // col.g = i.screenPos.y / _ScreenSize.y;
                    return float4(col, 1);                    
                }
                ENDHLSL
            }
        }
    }