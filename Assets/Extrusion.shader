Shader "Custom/Extrusion"
{
    Properties
    {
        _Height("Height", float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //面の向きを意識しなくてよくなる
        Cull Off
        
        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            struct v2g
            {
                float4 pos : SV_POSITION;
                float3 nor : NORMAL;
                float3 viewDir : TEXCOORD1;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                float4 col : COLOR;
                float3 viewDir : TEXCOORD1;
                float3 nor : NORMAL;
            };

            float4x4 eulerAnglesToRotationMatrix(float3 angles)
            {
                float3 _angles = angles;
                _angles.x = _angles.x * acos(-1.0)/180.0;
                _angles.y = _angles.y * acos(-1.0)/180.0;
                _angles.z = _angles.z * acos(-1.0)/180.0;

                float ch = cos(_angles.y);
                float sh = sin(_angles.y);

                float ca = cos(_angles.z);
                float sa = sin(_angles.z);

                float cb = cos(_angles.x);
                float sb = sin(_angles.x);

                return float4x4(
                    ch*ca+sh*sb*sa,
                    -ch*sa+sh*sb*ca,
                                sh*cb,
                                    0,

                                cb*sa,
                                cb*ca,
                                -sb,
                                    0,

                    -sh*ca+ch*sb*sa,
                    sh*sa+ch*sb*ca,
                                ch*cb,
                                    0,

                                    0,
                                    0,
                                    0,
                                    1
                );
            }

            float _Height;

            v2g vert(appdata_full v)
            {
                v2g o;

                float4 p = mul(eulerAnglesToRotationMatrix(float3(0.0, _Time.y * 30.0, 0.0)), v.vertex);

                o.pos = p;
                o.nor = normalize(p);
                float3 worldPos = mul(unity_ObjectToWorld, p).xyz;
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                return o;
            }

            [maxvertexcount(15)]
            void geom(triangle v2g input[3], uint pid : SV_PrimitiveID, inout TriangleStream<g2f> outStream)
            {
                float4 p0 = input[0].pos;

                float4 p1 = input[1].pos;

                float4 p2 = input[2].pos;

                float3 n0 = input[0].nor;
                float3 n1 = input[1].nor;
                float3 n2 = input[2].nor;

                float4 n = float4(((n0 + n1 + n2) / 3.0f).xyz, 1.0f);
                float4 ext = n * abs(sin(_Time.y + pid)) * _Height;

                g2f out0;
                out0.pos = UnityObjectToClipPos(p0);
                out0.col = fixed4(1.0, 1.0, 0.0, 1.0);
                out0.viewDir = input[0].viewDir;
                out0.nor = normalize(p0);

                g2f out1;
                out1.pos = UnityObjectToClipPos(p1);
                out1.col = fixed4(1.0, 1.0, 0.0, 1.0);
                out1.viewDir = input[0].viewDir;
                out1.nor = normalize(p1);

                g2f out2;
                out2.pos = UnityObjectToClipPos(p2);
                out2.col = fixed4(1.0, 1.0, 0.0, 1.0);
                out2.viewDir = input[0].viewDir;
                out2.nor = normalize(p2);

                g2f o0;
                o0.pos = UnityObjectToClipPos(p0 + ext);
                o0.col = fixed4(0.0, 1.0, 1.0, 1.0);
                o0.viewDir = input[0].viewDir;
                o0.nor = normalize(p0 + n);

                g2f o1;
                o1.pos = UnityObjectToClipPos(p1 + ext);
                o1.col = fixed4(0.0, 1.0, 1.0, 1.0);
                o1.viewDir = input[0].viewDir;
                o1.nor = normalize(p1 + n);

                g2f o2;
                o2.pos = UnityObjectToClipPos(p2 + ext);
                o2.col = fixed4(0.0, 1.0, 1.0, 1.0);
                o2.viewDir = input[0].viewDir;
                o2.nor = normalize(p2 + n);

                outStream.Append(out0);
                outStream.Append(out1);
                outStream.Append(o0);
                outStream.Append(o1);
                outStream.RestartStrip();

                outStream.Append(out1);
                outStream.Append(out2);
                outStream.Append(o1);
                outStream.Append(o2);
                outStream.RestartStrip();

                outStream.Append(out0);
                outStream.Append(out2);
                outStream.Append(o0);
                outStream.Append(o2);
                outStream.RestartStrip();

                outStream.Append(o0);
                outStream.Append(o1);
                outStream.Append(o2);
                outStream.RestartStrip();
            }

            float4 frag(g2f i) : SV_Target
            {
                return pow(1.0 - saturate(dot(normalize(i.viewDir), i.nor)), 6.0);
            }

            ENDCG
        }
    }
}
