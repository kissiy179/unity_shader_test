Shader "Custom/MyShader" {
	properties{
		_Texture("Texture", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }

		CGPROGRAM
		#pragma surface surf Lambert

		struct Input {
			float2 uv_Texture;
		};
		sampler2D _Texture;

		void surf (Input IN, inout SurfaceOutput o) {
			o.Albedo = tex2D(_Texture, IN.uv_Texture).rgb;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
