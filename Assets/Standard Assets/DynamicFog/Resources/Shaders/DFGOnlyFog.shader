Shader "DynamicFog/Only Fog" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_NoiseTex ("Noise (RGB)", 2D) = "white" {}
		_FogAlpha ("Alpha", Range (0, 1)) = 0.8
		_FogDistance ("Distance Params", Vector) = (0.1, 0.001, 1.0, 0.15)
		_FogHeight ("Height", Range (0, 100)) = 1
		_FogBaseHeight ("Baseline Height", float) = 0
		_FogHeightFallOff ("Height FallOff", Range (0, 1)) = 0.1
		_FogColor ("Color", Color) = (1,1,1,1)
		_FogColor2 ("Color 2", Color) = (1,1,1,1)
		_FogNoise ("Noise", Range (0, 1)) = 0
		_FogTurbulence ("Turbulence", Range (0, 15)) = 0
		_FogSpeed ("Speed", Range (0, 0.5)) = 0.1
		_FogOfWarCenter("Fog Of War Center", Vector) = (0,0,0)
		_FogOfWarSize("Fog Of War Size", Vector) = (1,1,1)
		_FogOfWar ("Fog of War Mask", 2D) = "white" {}
	}
	SubShader {
    ZTest Always Cull Off ZWrite Off
   	Fog { Mode Off }
	Pass{

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma fragmentoption ARB_precision_hint_fastest
	#pragma multi_compile __ FOG_OF_WAR_ON
		
	#include "UnityCG.cginc"

	uniform sampler2D _MainTex;
	uniform sampler2D _NoiseTex;
	sampler2D_float _CameraDepthTexture;
	float4 _MainTex_TexelSize;
	float _FogAlpha;
	float4 _FogDistance; // x = min distance, y = min distance falloff, x = max distance, y = max distance fall off
	float _FogHeight, _FogBaseHeight;
	float _FogHeightFallOff;
	float _FogTurbulence;
	float _FogNoise;
	float _FogSpeed;
	fixed4 _FogColor, _FogColor2;

    #if FOG_OF_WAR_ON 
    sampler2D _FogOfWar;
    float3 _FogOfWarCenter;
    float3 _FogOfWarSize;
    float3 _FogOfWarCenterAdjusted;
    #endif
    
    float4x4 _ClipToWorld;
           
	struct v2f {
	    float4 pos : POSITION;
    	float2 uv : TEXCOORD0;
    	float2 depthUV : TEXCOORD1;
    	float3 cameraToFarPlane : TEXCOORD2;
	};

	v2f vert(appdata_img v) {
    	v2f o;
    	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    	o.depthUV = MultiplyUV(UNITY_MATRIX_TEXTURE0, v.texcoord);
       	o.uv = o.depthUV;
       	
    	#if UNITY_UV_STARTS_AT_TOP
    	if (_MainTex_TexelSize.y < 0) {
	        // Depth texture is inverted WRT the main texture
    	    o.depthUV.y = 1 - o.depthUV.y;
    	}
    	#endif
               
    	// Clip space X and Y coords
    	float2 clipXY = o.pos.xy / o.pos.w;
               
    	// Position of the far plane in clip space
    	float4 farPlaneClip = float4(clipXY, 1, 1);
               
    	// Homogeneous world position on the far plane
    	farPlaneClip *= float4(1,_ProjectionParams.x,1,1);   
    	float4 farPlaneWorld4 = mul(_ClipToWorld, farPlaneClip);
               
    	// World position on the far plane
    	float3 farPlaneWorld = farPlaneWorld4.xyz / farPlaneWorld4.w;
               
    	// Vector from the camera to the far plane
    	o.cameraToFarPlane = farPlaneWorld - _WorldSpaceCameraPos;
 
    	return o;
	}

	//Fragment Shader
	fixed4 frag (v2f i) : COLOR {
   		fixed4 color = tex2D(_MainTex, i.uv);

    	// Reconstruct the world position of the pixel
		float depth = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.depthUV)));
		if (depth > _FogDistance.z) return color;
		
    	float3 worldPos = (i.cameraToFarPlane * depth) + _WorldSpaceCameraPos;
    	
    	#if FOG_OF_WAR_ON
 		fixed voidAlpha = 1.0f;
		float2 fogTexCoord = worldPos.xz / _FogOfWarSize.xz - _FogOfWarCenterAdjusted.xz;
		voidAlpha = tex2D(_FogOfWar, fogTexCoord).a;
		if (voidAlpha <=0) return color;
   		#endif
    	
		worldPos.y -= _FogBaseHeight;
		
    	// Compute noise
		float noise = tex2D(_NoiseTex, worldPos.xz*0.01 + _Time[1]*_FogSpeed).g;
		noise /= (depth*15); // attenuate with distance

		// Compute ground fog color		
		float nt = noise * _FogTurbulence;
		float fogHeight = _FogHeight + nt;
		worldPos.y -= nt;
		float d = (depth-_FogDistance.x)/_FogDistance.y;
		float dmax = (_FogDistance.z - depth) / _FogDistance.w;
		d = min(d, dmax);
		float h = (fogHeight - worldPos.y) / (fogHeight*_FogHeightFallOff);
		float groundColor = saturate(min(d,h))*saturate(_FogAlpha*(1-noise*_FogNoise));
		
		#if FOG_OF_WAR_ON
		groundColor *= voidAlpha;
		#endif
		
		// Compute final blended fog color
		fixed4 fogColor = lerp(_FogColor, _FogColor2, saturate(worldPos.y / fogHeight));
	 	return lerp(color, fogColor, groundColor);
	}
	ENDCG
	}
}
FallBack Off
}