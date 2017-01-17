Shader "Custom/MyShader" {
	properties{
		_DiffuseColor("Diffuse Color", Color)=(1.0, 1.0, 1.0)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		CGPROGRAM
		#pragma surface surf Original
		half4 LightingOriginal(SurfaceOutput s, half3 lightDir, half atten){
			half diff = dot(s.Normal, lightDir);
			if(diff < 0) diff = 0;
			half4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * (diff * atten * 2);
			c.a = s.Alpha;
			return c;
		}

		struct Input{
			float4 color: COLOR;
		};

		float3 _DiffuseColor;
		void surf(Input IN, inout SurfaceOutput o){
			o.Albedo = _DiffuseColor;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
