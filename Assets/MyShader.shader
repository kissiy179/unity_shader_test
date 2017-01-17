Shader "Custom/MyShader" {
	properties{
		_DiffuseColor("Diffuse Color", Color)=(1.0, 1.0, 1.0)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		Cull off
		CGPROGRAM
		#pragma surface surf Lambert

		struct Input {
			float3 worldPos;
		};
		float4 _DiffuseColor;

		void surf (Input IN, inout SurfaceOutput o) {
			o.Albedo = _DiffuseColor;
			clip(frac(IN.worldPos.y * 10) - 0.5);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
