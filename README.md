# EO-DAS Shader

EO-DAS Shader is an omnidirectional display shader for Unity that combines feeds from six cameras.

The cameras capture the scene along the positive and negative X, Y, and Z axes. Their RenderTextures are combined to produce a view-dependent display, simulating a see-through-cockpit view.

## Requirements

- Unity 2022.3
- Built-in Render Pipeline
- URP and HDRP are not currently supported

## Installation

Copy the `EO-DAS_Shader` folder into your Unity project's `Assets` folder.

## Setup

1. Add `EODASDisplay.prefab` to your scene.
2. Position `Capture Cameras` at the center of the area you want to capture.
3. Position `Display Surface` where the combined camera feed should appear.
4. Configure the Culling Mask of each capture camera for your project.
5. Exclude the display surface and camera model from the capture cameras to prevent recursive rendering.

### F-35-Inspired Setup

For an F-35-inspired installation, position the capture cameras to represent the aircraft's distributed-aperture cameras.

These cameras are located around the aircraft, including the forward cockpit area, the sides and underside of the fuselage, and behind the cockpit. On the F-35B, the rear-facing installation is located behind the lift-fan area.

When adjusting the camera system, do not rotate the six cameras individually. Rotate their parent object, `Capture Cameras`, instead. This preserves the orientation required for correctly combining the six RenderTextures.

Place `Display Surface` inside the cockpit. It does not need to remain in its original hierarchy, provided that its Rotation Constraint remains correctly configured and continues to follow `Capture Cameras`.

## Included Assets

- Omnidirectional display shader
- Display material
- Preconfigured prefab
- Six directional RenderTextures
- Camera model

## License

This asset is distributed under the MIT License. See `LICENSE` for details.

## Disclaimer

This is an independent, unofficial project with no affiliation with any aircraft manufacturer or defense organization.
