Shader "Custom/MyShader" {
	properties{
		_DiffuseColor("Diffuse Color", Color)=(1.0, 1.0, 1.0)
		_Cube("Cubemap", CUBE) = ""{}
		_Bump("Bump", 2D) = "white"{}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		CGPROGRAM
		#pragma surface surf Lambert

		struct Input {
			float2 uv_Bump;
			float3 worldRefl;
			INTERNAL_DATA
		};
		float3 _DiffuseColor;
		samplerCUBE _Cube;
		sampler2D _Bump;

		void surf (Input IN, inout SurfaceOutput o) {
			o.Albedo = _DiffuseColor * 0.5;
			o.Normal = UnpackNormal(tex2D(_Bump, IN.uv_Bump));
			o.Emission = texCUBE(_Cube, WorldReflectionVector(IN, o.Normal)).rgb;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
