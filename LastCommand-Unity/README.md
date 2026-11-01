# Last Command — Unity Prototype

An independent Unity project inside this repository. The existing Godot project is untouched.

## Open
1. Install Unity Hub and a Unity 6 LTS editor with Android Build Support (SDK/NDK + OpenJDK).
2. Clone this repository and switch to branch `unity-prototype`.
3. In Unity Hub choose **Add > Add project from disk** and select the `LastCommand-Unity` folder.
4. Open `Assets/Scenes/Prototype.unity` and press Play.

The prototype builds its test base and combat arena at runtime. It currently uses generated primitive geometry (greybox), not final realistic art assets.

## Controls
- Desktop: WASD / arrow keys to move; click/tap the ground to set a move target.
- Mobile: tap the ground to move; use the on-screen buttons for skills and base upgrade.
- The hero automatically fires at nearby enemies.
- Progress is saved locally using PlayerPrefs.

## Current scope
- Runtime-generated military outpost, HQ, barracks, depot and resource buildings.
- Player movement, nearest-target auto-fire, enemy chase/attack and rewards.
- Resource counter, base upgrade, basic skills, health and local save/load.
- Lightweight primitive effects and mobile-friendly default rendering.

## Important
This is a playable foundation prototype, not a finished game and not yet an Android APK. Android export must be configured in Unity on a machine with Unity installed and Android Build Support. No paid Unity services or assets are required for this prototype.
