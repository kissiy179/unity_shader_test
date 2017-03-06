using UnityEngine;
using System;
using System.Collections;

namespace DynamicFogAndMist
{
	public enum FOG_TYPE {
		DesktopFogWithSkyHaze,
		MobileFogWithSkyHaze,
		MobileFogOnlyGround
	}
	
	public enum FOG_PRESET {
		Clear,
		Mist,
		WindyMist,
		GroundFog,
		Fog,
		HeavyFog,
		SandStorm,
		Custom
	}

	[ExecuteInEditMode]
	[RequireComponent(typeof(Camera))]
	public class DynamicFog : MonoBehaviour
	{

		[Header("General Settings")]
		[Tooltip("Advanced: same as normal+sky but shader uses two noise textures instead of one.")]
		public FOG_TYPE effectType = FOG_TYPE.DesktopFogWithSkyHaze;
		public FOG_PRESET preset = FOG_PRESET.Mist;
		public bool useFogVolumes = false;

		[Header("Fog Properties")]
		[Range(0,1)]
		public float
			alpha = 1.0f;
		[Range(0,1)]
		public float
			noiseStrength = 0.5f;
		[Range(0,0.999f)]
		public float
			distance = 0.1f;
		[Range(0.0001f,0.5f)]
		public float
			distanceFallOff = 0.01f;
		[Range(0,1.1f)]
		public float
			maxDistance = 1.1f;
		[Range(0.0001f,0.5f)]
		public float
			maxDistanceFallOff = 0.15f;
		[Range(0,500)]
		public float
			height = 1f;
		public float
			baselineHeight = 0;
		[Range(0,1)]
		public float
			heightFallOff = 0.1f;
		[Range(0,15)]
		public float
			turbulence = 0.1f;
		[Range(0,0.2f)]
		public float
			speed = 0.1f;

		public Color color = Color.white;
		public Color color2 = Color.gray;

		[Header("Sky Properties")]
		[Range(0,500)]
		public float
			skyHaze = 50f;
		[Range(0,1)]
		public float
			skySpeed = 0.3f;
		[Range(0,1)]
		public float
			skyNoiseStrength = 0.1f;
		[Range(0,1)]
		public float
			skyAlpha = 1.0f;

		[Header("Fog of War")]
		public bool fogOfWarEnabled = false;
		public Vector3 fogOfWarCenter;
		public Vector3 fogOfWarSize = new Vector3(1024,0,1024);
		public int fogOfWarTextureSize = 256;

		Material fogMatAdv, fogMatFogSky, fogMatOnlyFog, fogMat;
		FOG_PRESET currentPreset = FOG_PRESET.Fog;

		float initialFogAlpha, targetFogAlpha;
		float initialSkyHazeAlpha, targetSkyHazeAlpha;
		float transitionDuration;
		float transitionStartTime;
		float currentFogAlpha, currentSkyHazeAlpha;
		Camera currentCamera;
		Texture2D fogOfWarTexture;
		Color32[] fogOfWarColorBuffer;
		string[] fogOfWarKeywords = new string[] { "FOG_OF_WAR_ON" };

		static DynamicFog _fog;
		public static DynamicFog instance { 
			get { 
				if (_fog==null) {
					foreach (Camera camera in Camera.allCameras) {
						_fog = camera.GetComponent<DynamicFog>();
						if (_fog!=null) break;
					}
				}
				return _fog;
			} 
		}

		public string GetCurrentPresetName() {
			return Enum.GetName(typeof(FOG_PRESET), preset);
		}

		public Camera fogCamera {
			get {
				return currentCamera;
			}
		}

		// Creates a private material used to the effect
		void OnEnable ()
		{
			targetFogAlpha = -1;
			targetSkyHazeAlpha = -1;
			currentFogAlpha = alpha;
			currentSkyHazeAlpha = skyAlpha;
			fogMatAdv = Instantiate (Resources.Load<Material> ("Materials/DFGAdvanced"));
			fogMatAdv.hideFlags = HideFlags.DontSave;
			fogMatFogSky = Instantiate (Resources.Load<Material> ("Materials/DFGWithSky"));
			fogMatFogSky.hideFlags = HideFlags.DontSave;
			fogMatOnlyFog = Instantiate (Resources.Load<Material> ("Materials/DFGOnlyFog"));
			fogMatOnlyFog.hideFlags = HideFlags.DontSave;
			currentCamera = GetComponent<Camera>();
			if (currentCamera.depthTextureMode == DepthTextureMode.None) {
				currentCamera.depthTextureMode = DepthTextureMode.Depth;
			}
			UpdateFogOfWarTexture();
		}

		// Check possible alpha transition
		void Update () {
			if (fogMat==null) return;
			// Check transitions
			if (targetFogAlpha >= 0) {
				if (targetFogAlpha != currentFogAlpha || targetSkyHazeAlpha != currentSkyHazeAlpha) {
					if (transitionDuration > 0) {
						currentFogAlpha = Mathf.Lerp (initialFogAlpha, targetFogAlpha, (Time.time - transitionStartTime) / transitionDuration);
						currentSkyHazeAlpha = Mathf.Lerp (initialSkyHazeAlpha, targetSkyHazeAlpha, (Time.time - transitionStartTime) / transitionDuration);
					} else {
						currentFogAlpha = targetFogAlpha;
						currentSkyHazeAlpha = targetSkyHazeAlpha;
					}
					fogMat.SetFloat ("_FogAlpha", currentFogAlpha);
					fogMat.SetFloat ("_FogSkyAlpha", currentSkyHazeAlpha);
				}
			} else if (currentFogAlpha != alpha || targetSkyHazeAlpha != currentSkyHazeAlpha) {
				if (transitionDuration > 0) {
					currentFogAlpha = Mathf.Lerp (initialFogAlpha, alpha, (Time.time - transitionStartTime) / transitionDuration);
					currentSkyHazeAlpha = Mathf.Lerp (initialSkyHazeAlpha, alpha, (Time.time - transitionStartTime) / transitionDuration);
				} else {
					currentFogAlpha = alpha;
					currentSkyHazeAlpha = skyAlpha;
				}
				fogMat.SetFloat ("_FogAlpha", currentFogAlpha);
				fogMat.SetFloat ("_FogSkyAlpha", currentSkyHazeAlpha);
			}
		}

		public void CheckPreset() {
			if (currentPreset!=preset) {
				currentPreset = preset;
				switch(currentPreset) {
				case FOG_PRESET.Clear:
					alpha = 0;
					break;
				case FOG_PRESET.Mist:
					alpha = 0.75f;
					skySpeed = 0.11f;
					skyHaze = 15;
					skyNoiseStrength = 1;
					skyAlpha = 0.33f;
					distance = 0;
					distanceFallOff = 0.07f;
					height = 4.4f;
					heightFallOff = 1;
					turbulence = 0;
					noiseStrength = 0.6f;
					speed = 0.01f;
					color = new Color(0.89f, 0.89f, 0.89f,1);
					color2 = color;
					break;
				case FOG_PRESET.WindyMist:
					alpha = 0.75f;
					skySpeed = 0.3f;
					skyHaze = 35;
					skyNoiseStrength = 0.32f;
					skyAlpha = 0.33f;
					distance = 0;
					distanceFallOff = 0.07f;
					height = 2f;
					heightFallOff = 1;
					turbulence = 2;
					noiseStrength = 0.6f;
					speed = 0.06f;
					color = new Color(0.89f, 0.89f, 0.89f,1);
					color2 = color;
					break;
				case FOG_PRESET.GroundFog:
					alpha = 1;
					skySpeed = 0.3f;
					skyHaze = 35;
					skyNoiseStrength = 0.32f;
					skyAlpha = 0.33f;
					distance = 0;
					distanceFallOff = 0;
					height = 1f;
					heightFallOff = 1;
					turbulence = 0.4f;
					noiseStrength = 0.7f;
					speed = 0.005f;
					color = new Color(0.89f, 0.89f, 0.89f,1);
					color2 = color;
					break;
				case FOG_PRESET.Fog:
					alpha = 0.96f;
					skySpeed = 0.3f;
					skyHaze = 155;
					skyNoiseStrength = 0.6f;
					skyAlpha = 0.93f;
					distance = 0.01f;
					distanceFallOff = 0.04f;
					height = 20f;
					heightFallOff = 1;
					turbulence = 0.4f;
					noiseStrength = 0.4f;
					speed = 0.005f;
					color = new Color(0.89f, 0.89f, 0.89f,1);
					color2 = color;
					break;
				case FOG_PRESET.HeavyFog:
					alpha = 1;
					skySpeed = 0.05f;
					skyHaze = 350;
					skyNoiseStrength = 0.8f;
					skyAlpha = 0.97f;
					distance = 0;
					distanceFallOff = 0.045f;
					height = 35f;
					heightFallOff = 0.88f;
					turbulence = 0.4f;
					noiseStrength = 0.24f;
					speed = 0.003f;
					color = new Color(0.86f, 0.847f, 0.847f,1);
					color2 = color;
					break;
				case FOG_PRESET.SandStorm:
					alpha = 1;
					skySpeed = 0.49f;
					skyHaze = 333;
					skyNoiseStrength = 0.72f;
					skyAlpha = 0.97f;
					distance = 0;
					distanceFallOff = 0.028f;
					height = 83f;
					heightFallOff = 0;
					turbulence = 15;
					noiseStrength = 0.45f;
					speed = 0.2f;
					color = new Color(0.364f, 0.36f, 0.36f,1);
					color2 = color;
					break;
				}
			}
		}

		// Postprocess the image
		void OnRenderImage (RenderTexture source, RenderTexture destination)
		{
			CheckPreset();

			if (alpha == 0) {
				Graphics.Blit (source, destination);
				return;
			}

			switch(effectType) {
			case FOG_TYPE.MobileFogOnlyGround:
				fogMat = fogMatOnlyFog; break;
			case FOG_TYPE.MobileFogWithSkyHaze:
				fogMat = fogMatFogSky; ;
				fogMat.SetFloat ("_FogSkySpeed", skySpeed);
				fogMat.SetFloat ("_FogSkyHaze", skyHaze);
				fogMat.SetFloat ("_FogSkyNoise", skyNoiseStrength);
				break;
			default:
				fogMat = fogMatAdv;
				fogMat.SetFloat ("_FogSkySpeed", skySpeed);
				fogMat.SetFloat ("_FogSkyHaze", skyHaze);
				fogMat.SetFloat ("_FogSkyNoise", skyNoiseStrength);
				break;
			}
			if (currentCamera==null) currentCamera = GetComponent<Camera>();
			fogMat.SetMatrix ("_ClipToWorld", currentCamera.cameraToWorldMatrix * currentCamera.projectionMatrix.inverse);
			fogMat.SetFloat ("_FogSpeed", speed);
			fogMat.SetFloat ("_FogNoise", noiseStrength);
			fogMat.SetFloat ("_FogTurbulence", turbulence);
			if (baselineHeight<0) baselineHeight = 0;
			fogMat.SetFloat ("_FogHeight", height);
			fogMat.SetFloat ("_FogBaseHeight", baselineHeight);
			fogMat.SetFloat ("_FogHeightFallOff", heightFallOff);
			fogMat.SetFloat ("_FogAlpha", currentFogAlpha);
			fogMat.SetVector("_FogDistance", new Vector4(distance, distanceFallOff, maxDistance, maxDistanceFallOff));
			fogMat.SetColor ("_FogColor", color);
			fogMat.SetColor ("_FogColor2", color2);
			fogMat.SetFloat ("_FogSkyAlpha", currentSkyHazeAlpha);

			if (fogOfWarEnabled) {
				if (fogOfWarTexture==null) {
					UpdateFogOfWarTexture();
				}
				fogMat.SetTexture("_FogOfWar", fogOfWarTexture);
				fogMat.SetVector ("_FogOfWarCenter", fogOfWarCenter);
				fogMat.SetVector ("_FogOfWarSize", fogOfWarSize);
				Vector3 ca = fogOfWarCenter - 0.5f * fogOfWarSize;
				fogMat.SetVector ("_FogOfWarCenterAdjusted",  new Vector3(ca.x / fogOfWarSize.x, 1f, ca.z / fogOfWarSize.z));
				fogMat.shaderKeywords = fogOfWarKeywords;
			} else {
				fogMat.shaderKeywords = null;
			}

			Graphics.Blit (source, destination, fogMat, 0);
		}


		public void SetTargetAlpha (float newFogAlpha, float newSkyHazeAlpha, float duration) {
			if (!useFogVolumes) return;
			this.initialFogAlpha = currentFogAlpha;
			this.initialSkyHazeAlpha = currentSkyHazeAlpha;
			this.targetFogAlpha = newFogAlpha;
			this.targetSkyHazeAlpha = newSkyHazeAlpha;
			this.transitionDuration = duration;
			this.transitionStartTime = Time.time;
		}
		
		public void ClearTargetAlpha (float duration) {
			SetTargetAlpha(-1, -1, duration);
		}

		void UpdateFogOfWarTexture() {
			if (!fogOfWarEnabled) return;
			int size = GetScaledSize(fogOfWarTextureSize, 1.0f);
			//			fogOfWarTexture = new Texture2D(size, size, TextureFormat.Alpha8, false);
			fogOfWarTexture = new Texture2D(size, size, TextureFormat.ARGB32, false);
			fogOfWarTexture.hideFlags = HideFlags.DontSave;
			fogOfWarTexture.filterMode = FilterMode.Bilinear;
			fogOfWarTexture.wrapMode = TextureWrapMode.Clamp;
			ResetFogOfWar();
		}
		
		/// <summary>
		/// Changes the alpha value of the fog of war at world position. It takes into account FogOfWarCenter and FogOfWarSize.
		/// Note that only x and z coordinates are used. Y (vertical) coordinate is ignored.
		/// </summary>
		/// <param name="worldPosition">in world space coordinates.</param>
		/// <param name="radius">radius of application in world units.</param>
		public void SetFogOfWarAlpha(Vector3 worldPosition, float radius, float fogNewAlpha) {
			if (fogOfWarTexture==null) return;
			
			float tx = (worldPosition.x - fogOfWarCenter.x) / fogOfWarSize.x + 0.5f;
			if (tx<0 || tx>1f) return;
			float tz = (worldPosition.z - fogOfWarCenter.z) / fogOfWarSize.z + 0.5f;
			if (tz<0 || tz>1f) return;
			
			int tw = fogOfWarTexture.width;
			int th = fogOfWarTexture.height;
			int px = (int)(tx * tw);
			int pz = (int)(tz * th);
			int colorBufferPos = pz * tw + px;
			byte newAlpha8 = (byte)(fogNewAlpha * 255);
			Color32 existingColor = fogOfWarColorBuffer[colorBufferPos];
			if (newAlpha8!=existingColor.a) { // just to avoid over setting the texture in an Update() loop
				float tr = radius / fogOfWarSize.z;
				int delta = Mathf.FloorToInt(th * tr);
				for (int r=pz-delta;r<=pz+delta;r++) {
					if (r>0 && r<th-1) {
						for (int c=px-delta;c<=px+delta;c++) {
							if (c>0 && c<tw-1) {
								int distance = Mathf.FloorToInt( Mathf.Sqrt ( (pz-r)*(pz-r) + (px-c)*(px-c)));
								if (distance<=delta) {
									colorBufferPos = r * tw + c;
									Color32 colorBuffer = fogOfWarColorBuffer[colorBufferPos];
									colorBuffer.a = (byte)Mathf.Lerp(newAlpha8, colorBuffer.a, (float)distance/delta);
									fogOfWarColorBuffer[colorBufferPos] = colorBuffer;
									fogOfWarTexture.SetPixel(c, r, colorBuffer);
								}
							}
						}
					}
				}
				fogOfWarTexture.Apply();
			}
		}
		
		
		public void ResetFogOfWarAlpha(Vector3 worldPosition, float radius) {
			if (fogOfWarTexture==null) return;
			
			float tx = (worldPosition.x - fogOfWarCenter.x) / fogOfWarSize.x + 0.5f;
			if (tx<0 || tx>1f) return;
			float tz = (worldPosition.z - fogOfWarCenter.z) / fogOfWarSize.z + 0.5f;
			if (tz<0 || tz>1f) return;
			
			int tw = fogOfWarTexture.width;
			int th = fogOfWarTexture.height;
			int px = (int)(tx * tw);
			int pz = (int)(tz * th);
			int colorBufferPos = pz * tw + px;
			float tr = radius / fogOfWarSize.z;
			int delta = Mathf.FloorToInt(th * tr);
			for (int r=pz-delta;r<=pz+delta;r++) {
				if (r>0 && r<th-1) {
					for (int c=px-delta;c<=px+delta;c++) {
						if (c>0 && c<tw-1) {
							int distance = Mathf.FloorToInt( Mathf.Sqrt ( (pz-r)*(pz-r) + (px-c)*(px-c)));
							if (distance<=delta) {
								colorBufferPos = r * tw + c;
								Color32 colorBuffer = fogOfWarColorBuffer[colorBufferPos];
								colorBuffer.a = 255;
								fogOfWarColorBuffer[colorBufferPos] = colorBuffer;
								fogOfWarTexture.SetPixel(c, r, colorBuffer);
							}
						}
					}
				}
				fogOfWarTexture.Apply();
			}
		}
		
		public void ResetFogOfWar() {
			if (fogOfWarTexture==null) return;
			int h = fogOfWarTexture.height;
			int w = fogOfWarTexture.width;
			int newLength = h * w;
			if (fogOfWarColorBuffer==null || fogOfWarColorBuffer.Length != newLength) {
				fogOfWarColorBuffer = new Color32[newLength];
			}
			Color32 opaque = new Color32(255,255,255,255);
			for (int k=0;k<newLength;k++) fogOfWarColorBuffer[k] = opaque;
			fogOfWarTexture.SetPixels32(fogOfWarColorBuffer);
			fogOfWarTexture.Apply();
		}

		int GetScaledSize(int size, float factor) {
			size = (int)(size / factor);
			size /= 4;
			if (size<1) size = 1;
			return size * 4;
		}
	}

}