# Last Command — Unity Project

This is a separate Unity 6 project. The existing Godot project and its workflows remain untouched.

## Open locally
1. Install Unity Hub and Unity **6000.0.30f1**.
2. Install the matching editor plus Android Build Support (SDK, NDK and OpenJDK) if you later want an APK.
3. Clone the repository, switch to `unity-prototype`, and add the `LastCommand-Unity` folder in Unity Hub.
4. Open `Assets/Scenes/Prototype.unity` and press Play.

## Controls
- Desktop: WASD / arrow keys to move; click the ground to move.
- Touch: tap the ground to move; use the on-screen skill and base-upgrade controls.
- The commander automatically attacks nearby enemies.
- Gold, food, metal, commander level and HQ level are saved locally.

## Current systems
- Runtime-built military outpost, HQ, barracks, depot and production buildings.
- Commander and hostile units assembled from temporary primitive meshes.
- Enemy pursuit and attacks, automatic combat, grenade, shield and hit tracers.
- Timed resource production, HQ upgrades, rewards and local save/load.

## WebGL build
The workflow `.github/workflows/unity-webgl.yml` exports a WebGL build as a downloadable GitHub Actions artifact. It requires a valid Unity license file stored in the repository Actions secret named `UNITY_LICENSE`. The workflow does not publish to GitHub Pages yet, so it will not overwrite the existing Godot browser preview.

## Honest status
This is an early playable foundation, not a finished or realistic-quality game. Character meshes, animation, pathfinding, proper building interaction, audio, balancing and mobile optimization still need substantial work. No Unity compile, WebGL export or Android APK has been verified in this environment.
