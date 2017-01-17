Shader "Custom/MyShader" {
	properties{
		_Texture("Texture", 2D) = "white"{}
		_Alpha("Alpha", Range(0,1)) = 1
	}
	SubShader {
		Tags { "RenderType"="Opaque" }

		CGPROGRAM
		#pragma surface surf Lambert alpha

		struct Input {
			float2 uv_Texture;
		};
		sampler2D _Texture;
		float _Alpha;
		void surf (Input IN, inout SurfaceOutput o) {
			o.Albedo = tex2D(_Texture, IN.uv_Texture).rgb;
			o.Alpha = _Alpha;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
