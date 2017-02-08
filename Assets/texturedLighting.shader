Shader "Custom/texturedLighthing" {
    Properties {
        _MainColor ("Main Color", COLOR) = (0,0,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
    }
    SubShader {
        Pass {
            Name "Base"
            Material {
                Diffuse[_MainColor]
                Ambient[_MainColor]
            }
            Lighting On
            SetTexture[_MainTex] {
                Combine texture * primary DOUBLE
            }
        }

    }
}