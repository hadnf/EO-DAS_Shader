
Shader "Leopard/EO-DAS_Shader"
{
	Properties
	{
		_Opacity ("Opacity", Range(0, 1)) = 0.7
		_VerticalFieldOfView ("Vertical Field of View", Range(0.0, 180.0)) = 30.0
		_HorizontalFieldOfView ("Horizontal Field of View", Range(0.0, 180.0)) = 40.0
		_ProjectionDistance ("Projection Distance", Float) = 100.0
		[Header(Distance Fade)]
		_FadeStartDistance ("Fade Start Distance", Float) = 2.0
		_FadeEndDistance ("Fade End Distance", Float) = 3.0
        [NoScaleOffset] _PositiveXTexture ("Positive X", 2D) = "grey" {}
        [NoScaleOffset] _NegativeXTexture ("Negative X", 2D) = "grey" {}
        [NoScaleOffset] _PositiveYTexture ("Positive Y", 2D) = "grey" {}
        [NoScaleOffset] _NegativeYTexture ("Negative Y", 2D) = "grey" {}
        [NoScaleOffset] _PositiveZTexture ("Positive Z", 2D) = "grey" {}
        [NoScaleOffset] _NegativeZTexture ("Negative Z", 2D) = "grey" {}
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "DisableBatching"="True" "IgnoreProjector" = "True"}
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha
		ZTest Always
		Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityShaderUtilities.cginc"
			#include "UnityShaderVariables.cginc"

			float3 GetViewCameraUp()
			{
				#if defined(USING_STEREO_MATRICES)
					return unity_StereoMatrixV[unity_StereoEyeIndex][1].xyz;
				#else
					return unity_MatrixV[1].xyz;
				#endif
			}

			float3 GetViewCameraForward()
			{
				#if defined(USING_STEREO_MATRICES)
					return normalize(unity_StereoMatrixV[unity_StereoEyeIndex]._m20_m21_m22);
				#else
					return unity_MatrixV[2].xyz;
				#endif
			}

			float3 GetViewCameraPosition()
			{
				#if defined(USING_STEREO_MATRICES)
					return unity_StereoWorldSpaceCameraPos[unity_StereoEyeIndex];
				#else
					return _WorldSpaceCameraPos;
				#endif
			}

			float GetDistanceFade(float fadeStartDistance, float fadeEndDistance)
			{
				float3 objectPosition = float3(
					UNITY_MATRIX_M[0].w,
					UNITY_MATRIX_M[1].w,
					UNITY_MATRIX_M[2].w);
				float distanceToObject = distance(GetViewCameraPosition(), objectPosition);
				float fadeStart = max(min(fadeStartDistance, fadeEndDistance), 0.0);
				float fadeEnd = max(max(fadeStartDistance, fadeEndDistance), fadeStart + 0.0001);
				return 1.0 - smoothstep(fadeStart, fadeEnd, distanceToObject);
			}

			float3 ReconstructWorldPosition(float4 clipPosition)
			{
				#ifdef UNITY_REVERSED_Z
					float3 ndc = clipPosition.xyz / clipPosition.w;
					ndc = float3(ndc.x, ndc.y * _ProjectionParams.x, (1.0 - ndc.z) * 2.0 - 1.0);
					float3 viewPosition = mul(unity_CameraInvProjection, float4(ndc * clipPosition.w, clipPosition.w));
				#else
					float3 viewPosition = mul(unity_CameraInvProjection, clipPosition);
				#endif
				return mul(unity_MatrixInvV, float4(viewPosition, 1.0)).xyz;
			}

			struct VertexInput
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID

			};

			struct FragmentInput
			{
				float3 worldPosition : TEXCOORD0;
				float4 positionCS : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
			};

			float _Opacity;
			float _VerticalFieldOfView;
			float _HorizontalFieldOfView;
			float _ProjectionDistance;
			float _FadeStartDistance;
			float _FadeEndDistance;
			sampler2D _PositiveXTexture;
			sampler2D _NegativeXTexture;
			sampler2D _PositiveYTexture;
			sampler2D _NegativeYTexture;
			sampler2D _PositiveZTexture;
			sampler2D _NegativeZTexture;

			FragmentInput vert(VertexInput input)
			{
				FragmentInput output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_INITIALIZE_OUTPUT(FragmentInput, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 cameraPosition = GetViewCameraPosition();
				float3 cameraForward = GetViewCameraForward();
				float3 cameraUp = GetViewCameraUp();
				float3 cameraRight = -normalize(cross(cameraUp, cameraForward));

				float verticalFieldOfView = max(_VerticalFieldOfView, 0.001);
				float planeDistance = 0.5 / tan(radians(verticalFieldOfView * 0.5));
				float forwardOffset = planeDistance * _ProjectionDistance;
                float3 worldPosition = cameraPosition;
				worldPosition += cameraUp * (input.uv.y - 0.5) * _ProjectionDistance;
				worldPosition += cameraRight * (input.uv.x - 0.5) * _ProjectionDistance
					* (_HorizontalFieldOfView / verticalFieldOfView);
				worldPosition -= cameraForward * forwardOffset;

				output.positionCS = UnityWorldToClipPos(float4(worldPosition, 1.0));
				output.worldPosition = ReconstructWorldPosition(output.positionCS);
				return output;
			}
			
			fixed4 SampleCapturedView(float3 direction)
            {
				float3 absoluteDirection = abs(direction);
				float2 sampleUV;
				fixed4 sampledColor;

				if (absoluteDirection.x >= absoluteDirection.y && absoluteDirection.x >= absoluteDirection.z)
                {
					if (direction.x < 0)
                    {
						sampleUV = (float2(direction.z, direction.y) / absoluteDirection.x + 1.0) * 0.5;
						sampledColor = tex2D(_NegativeXTexture, sampleUV);
                    }
                    else
                    {
						sampleUV = (float2(-direction.z, direction.y) / absoluteDirection.x + 1.0) * 0.5;
						sampledColor = tex2D(_PositiveXTexture, sampleUV);
                    }
                }
				else if (absoluteDirection.y >= absoluteDirection.x && absoluteDirection.y >= absoluteDirection.z)
                {
					if (direction.y > 0)
                    {
						sampleUV = (float2(direction.x, -direction.z) / absoluteDirection.y + 1.0) * 0.5;
						sampledColor = tex2D(_PositiveYTexture, sampleUV);
                    }
                    else
                    {
						sampleUV = (float2(direction.x, direction.z) / absoluteDirection.y + 1.0) * 0.5;
						sampledColor = tex2D(_NegativeYTexture, sampleUV);
                    }
                }
                else
                {
					if (direction.z > 0)
                    {
						sampleUV = (float2(direction.x, direction.y) / absoluteDirection.z + 1.0) * 0.5;
						sampledColor = tex2D(_PositiveZTexture, sampleUV);
                    }
                    else
                    {
						sampleUV = (float2(-direction.x, direction.y) / absoluteDirection.z + 1.0) * 0.5;
						sampledColor = tex2D(_NegativeZTexture, sampleUV);
                    }
                }

				sampledColor.rgb = (sampledColor.r + sampledColor.g + sampledColor.b) / 3.0;

				return sampledColor;
            }

			fixed4 frag(FragmentInput input) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
				float3 viewDirection = normalize(input.worldPosition - GetViewCameraPosition());

				viewDirection = UnityWorldToObjectDir(viewDirection);

				fixed4 outputColor = saturate(SampleCapturedView(viewDirection));
				outputColor.a = _Opacity * GetDistanceFade(_FadeStartDistance, _FadeEndDistance);
				return outputColor;
			}
			ENDCG
		}
	}
}
