Shader "AP1/L08/NormalMap" //Shader路径名
{
    Properties //材质面板参数
    {
        _NormalMap ("法线贴图", 2D) = "bump" {}
    }

    SubShader
    {
        Tags 
        {
            "RenderType"="Opaque"
        }

        Pass 
        {
            Name "FORWARD"
            Tags 
            {
                "LightMode"="ForwardBase"
            }
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            // 输入参数
            uniform sampler2D _NormalMap;
            
            struct VertexInput //输入结构
            {
                float4 vertex  : POSITION;  // 将模型顶点信息输入进来
                float2 uv0     : TEXCOORD0; // 需要UV坐标 采样法线贴图
                float3 normal  : NORMAL;    // 将模型法线信息输入进来
                float4 tangent : TANGENT;   // 构建TBN矩阵 需要模型切线信息
            };

            struct VertexOutput //输出结构
            {
                float4 pos    : SV_POSITION;    // 由模型顶点信息换算而来的顶点屏幕位置
                float2 uv0    : TEXCOORD0;      // UV信息
                float3 nDirWS : TEXCOORD1;      // 世界空间法线信息
                float3 tDirWS : TEXCOORD2;      // 世界空间切线信息
                float3 bDirWS : TEXCOORD3;      // 世界空间切线信息
            };

            VertexOutput vert (VertexInput v) //顶点shader
            {
                VertexOutput o = (VertexOutput)0;               // 新建一个输出结构
                o.pos = UnityObjectToClipPos( v.vertex );       // 变换顶点信息 并将其塞给输出结构
                o.uv0 = v.uv0;                                  // 传递UV信息
                o.nDirWS = UnityObjectToWorldNormal(v.normal);  // 变换法线信息 并将其塞给输出结构
                o.tDirWS = normalize(mul( unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);    // 世界空间切线信息
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w);                      // 世界空间切线信息
                return o;                                       // 将输出结构 输出
            }

            float4 frag(VertexOutput i) : COLOR //像素shader
            {
                // 获取nDir
                float3 var_NormalMap = UnpackNormal(tex2D(_NormalMap, i.uv0)).rgb;  // 采样法线纹理并解码 切线空间nDir
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);              // 构建TBN矩阵
                float3 nDir = normalize(mul(var_NormalMap, TBN));                   // 世界空间nDir

                // 获取lDir
                float3 lDir = _WorldSpaceLightPos0.xyz;

                // 一般Lambert
                float nDotl = dot(nDir, lDir);                  // nDir点积lDir
                float lambert = max(0.0, nDotl);                // 截断负值

                return float4(lambert, lambert, lambert, 1.0);  // 输出最终颜色
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
