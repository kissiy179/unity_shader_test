Shader "Custom/MyShader" {
	properties{
		_DiffuseColor("Diffuse Color", Color)=(1.0, 1.0, 1.0)
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		CGPROGRAM
		#pragma surface surf Lambert vertex:vert
		struct Input{
			float4 color: COLOR;
		};
		float3 _DiffuseColor;
		void vert(inout appdata_full v){
			v.vertex.x += 0.05 * v.normal.x * sin((v.vertex.y + _Time.x * 3) * 3.14159 * 8);
			v.vertex.z += 0.05 * v.normal.z * sin((v.vertex.y + _Time.x * 3) * 3.14159 * 8);
		}

		void surf(Input IN, inout SurfaceOutput o){
			o.Albedo = _DiffuseColor;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
