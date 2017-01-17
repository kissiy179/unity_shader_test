Shader "Custom/MyShader" {
	properties{
		_Texture("Texutre", 2D)= "white"
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		CGPROGRAM
		#pragma surface surf Lambert finalcolor:mycolor
		struct Input{
			float2 uv_Texture;
		};
		sampler2D _Texture;
		void mycolor(Input IN, SurfaceOutput o, inout fixed4 color){
			float r = max(0, dot(float3(0.0, 0.0, -1.0), o.Normal));
			float g = max(0, dot(float3(0.0, 1.0, 0.0), o.Normal));
			float b = max(0, dot(float3(0.0, -1.0, 0.0), o.Normal));
			color += float4(r,g,b,1.0) * 0.5;
		}

		void surf(Input IN, inout SurfaceOutput o){
			o.Albedo = tex2D(_Texture, IN.uv_Texture).rgb;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
