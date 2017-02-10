Shader "Custom/MyShader" {
	properties{
		_Texture("Texutre", 2D)= "white"
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		CGPROGRAM
		#pragma surface surf Lambert finalcolor:mycolor vertex:myvert
		struct Input{
			float2 uv_Texture;
			float customData;
		};
		sampler2D _Texture;

		void myvert(inout appdata_full v, out Input data){
			UNITY_INITIALIZE_OUTPUT(Input, data);
			data.customData = max(0, 0.5 * sin((v.vertex.y + _Time.x * 5) * 3.14159 * 8));
		}

		void mycolor(Input IN, SurfaceOutput o, inout fixed4 color){
			color += float4(1.0, 0.0, 0.0, 1.0) * IN.customData;
		}

		void surf(Input IN, inout SurfaceOutput o){
			o.Albedo = tex2D(_Texture, IN.uv_Texture).rgb;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
