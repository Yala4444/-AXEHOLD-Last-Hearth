# Changelog

## 0.9.0 — Commercial polish pass
- Added a procedural `Soundscape` service with distinct day/night themes for Forgotten Forest, Frost Hollow and Ashlands.
- Expanded biome atmosphere during both day and night: forest motes/fireflies and vines, frost snow/mist, ash heat shimmer/embers and stronger edge treatment.
- Added two new enemy archetypes: the telegraphed surging Stalker and the armored Guardian.
- Rebalanced biome enemy identities so Frost Hollow emphasizes Stalkers while Ashlands emphasizes Guardians and brutes.
- Added stronger combat juice: enemy-hit sparks, shield response, player-damage edge feedback, hearth danger pulse and richer signature-attack shockwaves.
- Expanded generated SFX with Stalker/danger/Guardian tones.
- Updated gameplay regression for extensible enemy rosters and added dedicated commercial-polish regression covering six soundscapes, Guardian armor and Stalker surge behavior.

## 0.8.0 — Expedition wow pass
- Added `ExpeditionDirector` and `ExpeditionFX` as isolated expedition-content layers.
- Added automatic signature attacks for all four weapons: Storm Circle, Root Line, Frost Slam and Ash Dash.
- Added elite enemies with stronger combat stats, distinct golden aura, bonus XP and coin rewards.
- Added three daytime risk/reward encounters: Smoldering Altar, Corrupted Chest and Wrecked Caravan.
- Added trophy-focused boss victory presentation and a short homecoming sequence that shows the upgraded living camp before normal camp control returns.
- Added dedicated expedition regression coverage for elite promotion/rewards, weapon signatures, hammer slow, twin-blade shield gain and risk/reward consequences.

## 0.7.0 — Living camp progression
- Replaced the menu-like home screen with a procedural living camp that visually grows with long-term mastery.
- Added visible forge, arsenal rack, boss trophies, residents, palisade, watchtower and stronghold progression tiers.
- Added interactive camp hotspots for Forge, Arsenal, Trophies and Map.
- Moved weapon selection into the camp before expeditions.
- Moved unlock notices into the camp so new relics and weapons are acknowledged where the progression is visible.
- Added dedicated living-camp regression coverage.

## 0.6.0 — Arsenal and meta progression
- Added save schema v4 with backward migration and retroactive rewards for earlier biome victories.
- Added four distinct weapon profiles: Wanderer Axes, Root Spear, Frost Hammer and Ash Twin Blades.
- Added boss relics and first-clear weapon unlocks for all three biomes.
- Added biome mastery up to five stars with milestone shard rewards.
- Added persistent weapon selection and long-term camp identity based on total mastery.
- Expanded gameplay regression tests to cover weapon profiles, unlock persistence and mastery rewards.

## 0.5.0 — Biome identity
- Made Forgotten Forest, Frost Hollow and Ashlands play differently through enemy mixes and environmental rules.
- Added frost-night movement pressure and Ashlands telegraphed eruptions.
- Added biome-specific Guardian identities and attack patterns.
- Added post-night camp doctrine choices: Hunt, Fortify and Supply.
- Added runtime gameplay regression that enters biomes, starts nights, spawns bosses and validates biome mechanics.

## 0.4.0 — First-run experience
- Added contextual first-run coaching instead of a chain of blocking tutorial windows.
- Retuned the first day and early construction costs for a smoother opening run.
- Added strategically balanced perk choices across attack, survival and utility.
- Added contextual priorities between nights and danger/full-backpack hints.
- Updated save migration and daily mission balance.

## 0.3.0 — Game feel
- Added distinct procedural building silhouettes and build feedback.
- Added enemy hit/death animation, stronger visual identity and improved hero/weapon motion.
- Added generated combat SFX and haptic feedback hooks.
- Added a second telegraphed boss charge pattern.
- Reworked the combat HUD, modal styling, boss presentation and phase banners.

## 0.2.1-ci — Runtime validation foundation
- Added Web export preset for browser playtests.
- Added Godot 4.7.2 GitHub Actions validation/build pipeline.
- Added scene smoke test executed by the real Godot runtime.
- Added optional GitHub Pages deployment behind ENABLE_PAGES repository variable.
- Added Git ignore rules for generated builds and local credentials.
- Refactored runtime into GameRules, GameHud and GameWorld layers for safer iteration.

## 0.2.0 — Production pass
- Save schema v2 + migration.
- Daily missions/supply reset.
- App icon + logo SVG.
- Boss HP HUD.
- Night/dawn/boss banners.
- Damage and shield feedback overlay.
- Pause menu with Resume / Exit to Camp.
- Tutorial shown once and persisted.
- Android/iOS export preset scaffolding.
- Release checklist and balance documentation.

## 0.1.0
- Initial Godot vertical slice.
