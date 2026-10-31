# Godot prototype

Engine: Godot 4.7.2 Stable  
Language: GDScript  
Renderer: GL Compatibility  
Android package: `com.malek.lastcommand`

The current scene is a procedural 3D base blockout. It is intentionally built from primitive meshes so the first APK can validate the Android export pipeline before large art assets are introduced.

The first CI build is a **debug APK**, not a Play Store release. The workflow uploads it as a GitHub Actions artifact when the build succeeds.
