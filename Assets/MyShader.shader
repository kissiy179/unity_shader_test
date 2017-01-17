Shader "Custom/MyShader" {
	properties{
		_DiffuseColor("Diffuse Color", Color)=(1.0, 1.0, 1.0)
		_Specular("Speculer", Range(1.0, 50.0)) = 15.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		CGPROGRAM
		#pragma surface surf Test
		struct Input{
			float4 color: COLOR;
		};
		float3 _DiffuseColor;
		float _Specular;
		half4 LightingTest(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten){
			half diff = max(0, dot(s.Normal, lightDir));
			half spec = max(0, dot(s.Normal, normalize(lightDir + viewDir)));
			spec = pow(spec, _Specular);
			half4 c;
			c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec / 2) * (atten * 2);
			c.a = s.Alpha;
			return c;
		}

		void surf(Input IN, inout SurfaceOutput o){
			o.Albedo = _DiffuseColor;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
