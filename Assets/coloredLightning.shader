Shader "Custom/coloredLighting" {
    Properties {
        _MainColor ("Main Color", COLOR) = (0,0,1,1)
    }
    SubShader {
        Pass {
            Name "Base"
            Material {
                Diffuse[_MainColor]
                Ambient[_MainColor]
            }
            Lighting On
        }
    }
}