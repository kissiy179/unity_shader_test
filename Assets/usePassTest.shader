Shader "Custom/usePassTest" {
    Properties {
        _MainColor ("Main Color", COLOR) = (0,0,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
    }
    SubShader {
        UsePass "Custom/coloredLighting/BASE"
    }
}