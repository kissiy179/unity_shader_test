Shader "Custom/MyShader" {
	properties{
		_DiffuseColor("Diffuse Color", Color)=(1.0, 1.0, 1.0)
		_Cube("Cubemap", CUBE) = ""{}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		CGPROGRAM
		#pragma surface surf Lambert

		struct Input {
			float3 worldRefl;
		};
		float3 _DiffuseColor;
		samplerCUBE _Cube;

		void surf (Input IN, inout SurfaceOutput o) {
			o.Albedo = _DiffuseColor * 0.5;
			o.Emission = texCUBE(_Cube, IN.worldRefl).rgb;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
