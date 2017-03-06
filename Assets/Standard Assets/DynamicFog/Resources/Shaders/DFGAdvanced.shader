Shader "DynamicFog/Advanced" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_NoiseTex ("Noise (RGB)", 2D) = "white" {}
		_Noise2Tex ("Noise2 (RGB)", 2D) = "white" {}
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
		_FogSkyHaze ("Sky Haze", Range (0, 500)) = 50
		_FogSkySpeed ("Sky Speed", Range (0, 1)) = 0.3
		_FogSkyNoise ("Sky Noise", Range (0, 1)) = 0
		_FogSkyAlpha ("Sky Alpha", Range (0, 1)) = 1
		_FogOfWarCenter("Fog Of War Center", Vector) = (0,0,0)
		_FogOfWarSize("Fog Of War Size", Vector) = (1,1,1)
		_FogOfWar ("Fog of War Mask", 2D) = "white" {}
	}
	SubShader {
    ZTest Always Cull Off ZWrite Off
   	Fog { Mode Off }
	Pass {

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma fragmentoption ARB_precision_hint_fastest
	#pragma multi_compile __ FOG_OF_WAR_ON
		
	#include "UnityCG.cginc"

	uniform sampler2D _MainTex;
	uniform sampler2D _NoiseTex;
	uniform sampler2D _Noise2Tex;
	sampler2D_float _CameraDepthTexture;
	uniform float4 _MainTex_TexelSize;
	float _FogAlpha;
	float4 _FogDistance; // x = min distance, y = min distance falloff, x = max distance, y = max distance fall off
	float _FogHeight, _FogBaseHeight;
	float _FogHeightFallOff;
	float _FogTurbulence;
	float _FogNoise;
	float _FogSkyHaze;
	float _FogSkySpeed;
	float _FogSkyNoise;
	float _FogSkyAlpha;
	float _FogSpeed;
	fixed4 _FogColor, _FogColor2;

    #if FOG_OF_WAR_ON 
    sampler2D _FogOfWar;
    float3 _FogOfWarCenter;
    float3 _FogOfWarSize;
    float3 _FogOfWarCenterAdjusted;
    #endif

    float4x4 _ClipToWorld;
    
    struct appdata {
    	float4 vertex : POSITION;
		half2 texcoord : TEXCOORD0;
    };
    
    
	struct v2f {
	    float4 pos : POSITION;
	    float2 uv: TEXCOORD0;
    	float2 depthUV : TEXCOORD1;
    	float3 cameraToFarPlane : TEXCOORD2;
	};

	v2f vert(appdata v) {
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
	
	fixed4 computeSkyColor(fixed4 color, float3 worldPos) {
		float2 np = float2(worldPos.x/worldPos.y, worldPos.z/worldPos.y);
		float skyNoise = tex2D(_NoiseTex, np * 0.01+_Time[0]*_FogSkySpeed).g;
		fixed4 skyFogColor = lerp(_FogColor, _FogColor2, saturate(worldPos.y / _FogHeight));
		return step(worldPos.y,0) * skyFogColor + // below ground
			   step(0,worldPos.y) * lerp(color, skyFogColor, _FogSkyAlpha * saturate((_FogSkyHaze/worldPos.y)*(1-skyNoise*_FogSkyNoise)));
	}
	
	fixed4 computeGroundColor(fixed4 color, float3 worldPos, float depth) {
	
	 	#if FOG_OF_WAR_ON
 		fixed voidAlpha = 1.0f;
		float2 fogTexCoord = worldPos.xz / _FogOfWarSize.xz - _FogOfWarCenterAdjusted.xz;
		voidAlpha = tex2D(_FogOfWar, fogTexCoord).a;
		if (voidAlpha <=0) return color;
   		#endif
	
    	// Compute noise
    	float2 xzr = worldPos.xz*0.01 + _Time[1]*_FogSpeed;
		float noise = tex2D(_NoiseTex, xzr).g;
		float noise2 = tex2D(_Noise2Tex, xzr).g;
		noise = noise*noise2;
		noise /= (depth*15); // attenuate with distance

		// Compute ground fog color		
		float nt = noise * _FogTurbulence;
		worldPos.y -= nt;
		float d = (depth - _FogDistance.x) / _FogDistance.y;
		float dmax = (_FogDistance.z - depth) / _FogDistance.w;
		d = min(d, dmax);
		float fogHeight = _FogHeight + nt;
		float h = (fogHeight - worldPos.y) / (fogHeight*_FogHeightFallOff);
		float groundColor = saturate(min(d,h))*saturate(_FogAlpha*(1-noise*_FogNoise));	
	
		#if FOG_OF_WAR_ON
		groundColor *= voidAlpha;
		#endif
		
		fixed4 fogColor = lerp(_FogColor, _FogColor2, saturate(worldPos.y / fogHeight));
	 	return lerp(color, fogColor, groundColor);
	}

	// Fragment Shader
	fixed4 frag (v2f i) : COLOR {
   		fixed4 color = tex2D(_MainTex, i.uv);
		float depth = Linear01Depth(UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.depthUV)));
		
		if (depth>0.999) {
	    	float3 worldPos = (i.cameraToFarPlane * depth) + _WorldSpaceCameraPos;
			worldPos.y -= _FogBaseHeight;
			return computeSkyColor(color, worldPos);
		} else if (depth<_FogDistance.z) {
	    	float3 worldPos = (i.cameraToFarPlane * depth) + _WorldSpaceCameraPos;
			worldPos.y -= _FogBaseHeight;
			return computeGroundColor(color, worldPos, depth);
		} else {
			return color;
		}
	}
	ENDCG
	}
}
FallBack Off

}