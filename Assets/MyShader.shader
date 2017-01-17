Shader "Custom/MyShader" {
	properties{
		_DiffuseColor("Diffuse Color", Color)=(1.0, 1.0, 1.0)
		_RimWidth("Rim Width", Range(0.5, 8.0)) = 3.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		CGPROGRAM
		#pragma surface surf Lambert

		struct Input {
			float3 viewDir;
		};
		float4 _DiffuseColor;
		float _RimWidth;

		void surf (Input IN, inout SurfaceOutput o) {
			o.Albedo = _DiffuseColor;
			half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));
			half rim2 = pow(rim, _RimWidth);
			half rim3;
			if(rim2 < 0.5)rim3 = 1.0; else rim3 = 0.0;
			o.Albedo *= rim3;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
