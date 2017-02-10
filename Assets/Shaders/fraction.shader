Shader "Custom/fraction"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DirX ("Direction_X", range(0, 1)) = 0
		_DirY ("Direction_Y", range(0, 1)) = 1
		_DirZ ("Direction_Z", range(0, 1)) = 0

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _DirX;
			float _DirY;
			float _DirZ;

			v2f vert (appdata v)
			{
				v2f o;
				float speed = 120;
				float sinx = sin(_Time * speed);
				float cosz = cos(_Time * speed);
				float3 dir = float3(_DirX, _DirY, _DirZ);
				float3 diry = float3(0.000001,1,0);
				float3 quatAxis = normalize(cross(dir, diry));
				float angle = acos(dot(dir, diry) / (length(dir) *	 length(diry)));
				float half_angle = angle / 2.0;
				float4 quat = float4(sin(half_angle) * quatAxis.x, sin(half_angle) * quatAxis.y, sin(half_angle) * quatAxis.z, cos(half_angle));
				v.vertex.x += sinx;
				v.vertex.z += cosz;
				v.vertex.xyz = v.vertex.xyz + 2.0 * cross(quat.xyz, cross(quat.xyz, v.vertex.xyz) + quat.w * v.vertex.xyz);
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
