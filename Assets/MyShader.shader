Shader "Custom/MyShader" {
	properties{
		_Bump("Bump", 2D)="white"{}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		CGPROGRAM
		#pragma surface surf Lambert

		struct Input {
			float2 uv_Bump;
		};
		sampler2D _Bump;
		void surf (Input IN, inout SurfaceOutput o) {
			o.Albedo = half3(1.0, 0.6, 0.4);
			o.Normal = UnpackNormal(tex2D(_Bump, IN.uv_Bump));
		}
		ENDCG
	}
	FallBack "Diffuse"
}
