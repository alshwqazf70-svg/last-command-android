# Last Command — Original Android Strategy Game

> Working title. An original 3D military survival and strategy game for Android.

This repository is the foundation for a new, original game project. It is **not** a copy of Last War: Survival and contains no proprietary assets, source code, characters, or extracted game data.

## Vision
Combine:
- Third-person / lane-based action shooting missions
- A 3D military base with functional buildings and resource production
- Heroes, squads, troop training, equipment, and research
- Strategic world-map missions and, in later releases, alliances and seasons

## Target device
Initial performance target: Samsung Galaxy Note 9, Android 10, 6 GB RAM. The project must also support scalable quality settings for other Android devices.

## Development approach
Build a small, complete, testable vertical slice first:
1. A lightweight 3D base scene
2. One controllable hero
3. One playable combat mission with basic enemies
4. Rewards and local save/load
5. Android build and on-device performance validation

Only after this slice is stable will larger systems be added.

## Repository layout
- `docs/` — design, architecture, and build decisions
- `project/` — game-engine project (to be added after the Android build pipeline is validated)
- `.github/workflows/` — automated validation and build workflows

## Current status
Foundation branch: `game-foundation`. This initial commit establishes the project brief and technical decision gates. It does not yet contain a playable game or an APK.

## Important engineering rules
- Keep the game original and use properly licensed assets.
- Never commit signing keys, passwords, API tokens, or private credentials.
- Every milestone must pass automated checks and an actual Android installation test before being called complete.
