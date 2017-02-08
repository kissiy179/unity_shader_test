Shader "Custom/coloredLighthing" {
    Properties {
        _MainColor ("Main Color", COLOR) = (0,0,1,1)
    }
    SubShader {
        Pass {
            Material {
                Diffuse[_MainColor]
                Ambient[_MainColor]
            }
            Lighting On
        }
    }
}