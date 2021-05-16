Shader "ShaderSandbox/S_RayCloud"
{
    Properties
    {
        [MainTexture][NoScaleOffset] _CloudTexture ("Cloud Texture", 3D) = "white" {}
        
        //cloud properties
        _cloudColor ("Cloud Tint", Color) = (1, 1, 1, 1)
        _baseBrightness ("Brightness", Range (0, 2)) = 1.0
        _darknessThreshold ("Darkness Threshold", Range (0, 1)) = .15
        _density ("Density", Range (0, 1)) = 1
        _densityNoise ("Density Noise", Range(0, 1)) = .5
        _animSpeedL ("Animation Speed Large", Range(0, 50)) = 7
        _animSpeedS ("Animation Speed Detail", Range(0, 5)) = .75
        
        //light properties
        _lightColor ("Light Tint", Color) = (1, 1, 1, 1)
        _lightTraceDist ("Light Trace Distance", Range (0, 1)) = 1
        _lightAbsorptionTowardSun ("Light Absorbation Toward Sun", Range (0, 2)) = 1.21
        _lightAbsorptionThroughCloud ("Light Absorbation Through Cloud", Range (0, 2)) = 0.75
        
        //_debug ("debug", Range (0, 1000)) = 0
    }
    
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull front 
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex   : POSITION;
                float3 uvw      : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex       : SV_POSITION;
                float2 uvw          : TEXCOORD0;
                float3 viewVector   : TEXCOORD1;
                float2 screenPos    : TEXCOORD2;
                float3 blendValues  : TEXCOORD3;
            };

            Texture3D<float4> _CloudTexture;
            SamplerState sampler_CloudTexture;
            float4 _CloudTexture_ST;
            
            float4x4 _ViewProjectInverse;

            float4  _cloudColor;
            vector _cloudPos;
            vector _cloudScale;
            float3 _bbMin;
            float3 _bbMax;
            
            float4  _lightColor;
            float3 _lightPos;

            float _density;
            float _densityNoise;
            
            float3 _blendValues;
            float _animSpeedL;
            float _animSpeedS;
            
            float _baseBrightness;
            float _darknessThreshold;
    
            float _forwardScattering = .9f;
            float _backScattering = .3f;
            
            float _lightAbsorptionTowardSun = 1.21f;
            float _lightAbsorptionThroughCloud = 0.75f;
            
            float _phaseFactor = .5f;
            float _phaseBlend = .5f;

            float _lightTraceDist;
            
            float _debug;
             
            float sigOffset = .5;
            float sigContrast = 5;
            float sigScale = 1.5;
            float sigBlend = 1;
            float sigmoid(float t)
            {
                float x = (t-sigOffset)*sigContrast;
                float fsig = x / (1+abs(x)); //fast sig
                //float fsig = 1 / 1 + pow(2.718, -x);
                fsig *= sigScale;
                fsig = (fsig+1)*.5f;
                return (fsig*sigBlend)+(t*(1-sigBlend));
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex.xyz);
                //o.uvw = TRANSFORM_TEX(v.uvw, _CloudTexture);
                o.viewVector = v.vertex - mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));          
                //o.screenPos = ComputeScreenPos(o.vertex);

                float3 blend = {0.f, 0.f, 0.f};
                float a = (_Time.x*_animSpeedL)%3;
                if(a < 1)
                {
                    float sig = sigmoid(a);
                    blend.x = 1-sig;
                    blend.y = sig;
                }

                if(a >= 1 && a < 2)
                {
                    float sig = sigmoid(a-1);
                    blend.y = 1-sig;
                    blend.z = sig;
                }

                if(a >= 2 && a < 3)
                {
                    float sig = sigmoid(a-2);   
                    blend.z = 1-sig;
                    blend.x = sig;
                }
                o.blendValues = blend;
                return o;
            }

            float2 rayBoxDst(float3 ro, float3 rd)
            {
                float3 t0 = (_bbMin - ro) / rd;
                float3 t1 = (_bbMax - ro) / rd;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }
           
            // Henyey-Greenstein
            float hg(float a, float g) {
                float g2 = g*g;
                return (1-g2) / (4.0f*3.1415f*pow(abs(1.0f+g2-2.0f*g*(a)), 1.5f));
            }

            //Vector4 (forwardScattering, backScattering, baseBrightness, phaseFactor)
            float phase(float a) {
                float fScatter = hg(a,_forwardScattering) * (1-_phaseBlend);
                float bScatter = hg(a,-_backScattering) * _phaseBlend;
                float hgBlend = fScatter + bScatter;
                return _baseBrightness + hgBlend * _phaseFactor;
            }

            float sampleDensity(float3 pos)
            {
                float3 uvw = ((pos-_cloudPos) / _cloudScale) + .5;
                float4 p = _CloudTexture.SampleLevel(sampler_CloudTexture, uvw, 0);

                //blend shapes
                float d = 0;
                d += (p.r * _blendValues.x);
                d += (p.g * _blendValues.y);
                d += (p.b * _blendValues.z);

                //noise
                if(d > 0) {
                    float3 uvw_n = uvw;
                    uvw_n.x -= _Time.x*_animSpeedS;
                    uvw_n.y -= _Time.x*_animSpeedS;
                    uvw_n.z += _Time.x*_animSpeedS;
                    uvw_n -= floor(uvw_n); //texture is clamped so we need only decimals
                    float n = _CloudTexture.SampleLevel(sampler_CloudTexture, uvw_n, 0).a;
                    
                    d -= n * _densityNoise;
                    return d;
                }
                
                return d;
            }

            float sampleLight(float3 ro)
            {
                float3 dirToLight = normalize(_lightPos.xyz-_cloudPos.xyz)*.01;
                float dstInsideBox = rayBoxDst(ro, dirToLight).y;
                
                int numSteps = 8;
                float stepSize = (dstInsideBox * _lightTraceDist)/numSteps;
                float totalDensity = 0;
                
                for (int step = 0; step < numSteps; step++) {
                    ro += dirToLight * stepSize;
                    totalDensity += max(0, sampleDensity(ro) * stepSize);
                }

                float transmittance = exp(-totalDensity * _lightAbsorptionTowardSun);
                return _darknessThreshold + transmittance * (1-_darknessThreshold);
            }
            
            float map(float value, float min1, float max1, float min2, float max2) {
                return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
            }
            
            fixed4 frag (v2f i) : SV_Target {
                _blendValues = i.blendValues;

                fixed4 col = 1;

                float3 ro = _WorldSpaceCameraPos;
                float3 rd = normalize(i.viewVector)*.01;
                float3 ld = normalize(_lightPos.xyz - _cloudPos.xyz);

                float2 rayBoxInfo = rayBoxDst(ro, rd);
                float distToBox = rayBoxInfo.x;
                float distInsideBox = rayBoxInfo.y;

                
                // point of intersection with the cloud box
                float3 entryPoint = ro + rd * distToBox;

                // Phase function makes clouds brighter around sun
                float cosAngle = dot(rd, ld);
                float phaseVal = phase(cosAngle);

                float distTravelled = 0.0f;
                //const float stepSize = dstInsideBox/numSteps;
                float numSteps = 1.f;
                const float stepSize = .2f; //boxIntersectionLength/32.f;
                
                float distExit = distInsideBox;

                //float3 debugColor = {1.f, 1.f, 1.f};
                float transmittance = 1;
                float3 lightEnergy = 0;
                
                while (distTravelled < distExit) {
                    ro = entryPoint + rd * distTravelled;
                    float density = sampleDensity(ro)*_density*numSteps;
                    
                    if(density > 0) {
                        float lightTransmittance = sampleLight(ro)*_density*numSteps;
                        lightEnergy += density * 1 * transmittance * lightTransmittance * phaseVal;
                        transmittance *= exp(-density * stepSize * _lightAbsorptionThroughCloud);
                        
                        if (transmittance < 0.01) {
                            break;
                        }
                    }
                    distTravelled += stepSize;
                }
                
                float3 cloudCol = lightEnergy * _lightColor;
                col.rgb  = lerp(cloudCol*_cloudColor, cloudCol, lightEnergy);
                col.a = 1-transmittance;

               // col.rgb = i.viewVector;
               // col.a = 1;
                return col;
            }
            ENDHLSL
        }
    }
}
