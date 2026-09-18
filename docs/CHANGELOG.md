# Changelog

## 1.13.0-alpha.1 — Visual Reboot
- Rebuilt the mobile shell around a lighter header and icon-driven bottom navigation.
- Added a unified VisualSystem for colors, surfaces, buttons and spacing.
- Added authored procedural UiIcon symbols and removed emoji dependence from primary navigation.
- Rebuilt the gameplay HUD with compact HP/Hearth bars, phase hierarchy and contextual panels.
- Simplified Camp home into living scene + story ribbon + departure surface.
- Replaced large floating Camp hotspot labels with compact icon markers.
- Reworked Arsenal into responsive previews and compact weapon rows.
- Redesigned the world map around route readability with smaller node callouts.
- Redesigned Trophy Hall as physical relic alcoves with compact mastery indicators.
- Redrew the Wanderer silhouette with hood, cape, shoulders and visible satchel.
- Redrew Husk, Runner, Brute, Stalker and Guardian enemy silhouettes.
- Redrew all three biome Guardians as distinct boss anatomies.
- Redrew resource icons for small-screen readability.
- Reduced joystick size and opacity.
- Removed the legacy runtime build watermark completely.
- Bumped Android/iOS metadata to 1.13.0-alpha.1 / build 27.

## 1.12.0-alpha.1 — Dynamic World & Elites
- Added daytime enemy combat for dynamic world events.
- Added one scheduled dynamic event per day phase.
- Added Caravan Under Attack with attackers, success/failure consequences and a guaranteed follow-up cache clue.
- Added two-stage Survivor Rescue: clear enemies, then physically secure the survivor.
- Added Elite Hunt rare targets and timed Ambush encounters.
- Failed events now increase Darkness Threat and surviving attackers remain in the expedition.
- Added the first chained world event: saved caravan → timed hidden cache.
- Added four elite traits: Ravenous, Armored, Distorted and Herald of Darkness.
- Herald elites use a telegraphed charge; Distorted elites can burst on death at close range.
- Elites have visible titles, aura/readability treatment, stronger rewards and Mechanism Parts.
- Added persistent Field Journal statistics for events, failures, elites, rescues and chains.
- Added four new daily quest types tied to dynamic-world play.
- Expedition results now summarize dynamic events and elite activity.
- Added dedicated v1.12 regression coverage.
- Bumped Android/iOS metadata to 1.12.0-alpha.1 / build 26.

## 1.11.0-alpha.1 — Living Camp & Expedition Contracts
- Added a persistent daily three-offer Expedition Contract Board.
- Contracts can now be selected before leaving the Last Hearth instead of always being random.
- Board contracts grant persistent Camp Renown in addition to their existing run coin reward.
- Daily contract Renown can only be claimed once per offer.
- Added contract risk labels and per-contract Renown values.
- Added five visible camp growth levels driven by Renown while preserving legacy mastery progression.
- The living camp now gains extra tents, lanterns, palisade, watchtower, banners and stronghold detail as it grows.
- Added a physical Contracts hotspot to the camp.
- Resident quest claims now contribute Camp Renown.
- Mira Trust now grants modest movement speed and earlier night-modifier scouting.
- Thorn Trust now grants starting Mechanism Parts and a max-trust Tower bonus.
- Expedition results now show contract completion and Renown earned.
- Added save migration/backfill for Camp Renown and contract state.
- Added dedicated v1.11 regression coverage for contract offers, selection, duplicate prevention, Renown thresholds, resident bonuses and UI integration.
- Bumped Android/iOS metadata to 1.11.0-alpha.1 / build 25.

## 1.10.0-alpha.1 — Production Feel
- Expanded biome landmark language with abandoned roads, ruins, shrines, carts, fissures, industrial wreckage and other larger environmental set pieces.
- Added gradual backdrop day/night interpolation instead of an immediate palette snap.
- Increased biome atmosphere over the night transition: forest motes, frost wind/snow and ash/ember smoke.
- Gave all three Guardians distinct biome-specific silhouettes, cores and aura language.
- Added Guardian arrival and defeat FX.
- Added camera shake for damage, Frost Hammer impacts and Guardian moments.
- Added player-hit and Hearth dusk/dawn feedback.
- Made wood, stone and ore destruction feedback materially different.
- Improved hero attack poses and signature weapon glows.
- Rebuilt Soundscape state changes around crossfaded dual audio players.
- Added a distinct Guardian music state for every biome.
- Added dedicated v1.10 regression coverage for backdrop transition, Guardian identity, production FX, camera impact and music layers.
- Bumped Android/iOS metadata to 1.10.0-alpha.1 / build 24.

## 1.9.0-alpha.1 — Story & Residents
- Added a dedicated Chronicle screen to the Last Hearth.
- Added a real Chapter I finale that unlocks after all three Guardian relics are collected.
- Completing Chapter I now reveals the old Hearth network, advances the story to Chapter II and grants a one-time 2-shard reward.
- Added Chapter II direction: Road to the Fires, without pretending unfinished regions are already playable.
- Expanded Scout Mira from a three-step resident chain to five steps, now including Memory Rifts and relit ancient Hearths.
- Added Thorn, Engineer of the Old Fire, as a second permanent named resident.
- Repairing a Broken Tower can now return Thorn to the camp.
- Added Thorn's four-step chain around tower repair, Mechanism Parts, Level-II buildings and surviving nights.
- Locked Mira and Thorn now receive guaranteed discovery opportunities in expedition encounter composition.
- Added resident roles, trust caps and centralized ResidentRules data.
- Added a Chronicle hotspot and Chapter indicator to the living camp.
- Mira and Thorn now have recognizable in-world silhouettes in the camp.
- Generalized the Quest Board to render multiple named resident chains.
- Added save migration for story state and resident quest normalization.
- Added dedicated v1.9 regression coverage for chapter completion, one-time rewards, deterministic resident discovery and both resident chains.
- Bumped Android/iOS metadata to 1.9.0-alpha.1 / build 23.

## 1.8.0-alpha.1 — Weapon Identity
- Replaced the shared radial combat model with four independent weapon resolvers.
- Wanderer Axes retain continuous circular zone control.
- Root Spear now performs discrete directional thrusts that pierce aligned enemies.
- Frost Hammer now attacks through periodic AoE slams with knockback.
- Ash Twin Blades now use rapid short-range strikes and an aggression combo that increases damage then decays when disengaged.
- Added eight weapon-exclusive run perks, two per weapon.
- Added separate harvesting multipliers and target patterns per weapon.
- Added signature combat FX for Spear, Hammer and Twin Blades.
- Updated player visuals and Arsenal preview to communicate real weapon behavior.
- Arsenal now shows identity, signature and attack rhythm instead of only stat bars.
- Run analytics now include selected weapon.
- Added dedicated v1.8 regression coverage for range, pierce, radial burst, knockback, combo and weapon perks.
- Bumped Android/iOS metadata to 1.8.0-alpha.1 / build 22.

## 1.7.0-alpha.1 — Buildings & Economy
- Added a permanent Camp Forge blueprint economy that spends both coins and Guardian shards.
- Added Level-II projects for Palisade, Forge, Tower and Shrine.
- Every expedition building now has two mutually exclusive Level-II specialization branches.
- Added Mechanism Parts as a fourth expedition stockpile resource used for advanced construction.
- Parts are earned from high-value exploration activities and Guardian-class enemies.
- Unused Mechanism Parts convert into coins at expedition end instead of being wasted.
- Palisade II can become Bastion or Spikes.
- Forge II can become Tempering or Arc Workshop.
- Tower II can become Ballista or Repeater.
- Shrine II can become Renewal or Ward.
- Level-II effects modify actual defense, hero power, tower cadence/damage, regeneration and shielding.
- Added HUD support and pixel iconography for Mechanism Parts.
- Added a rotating daily quest for upgrading a building to Level II.
- Added save migration for permanent building projects.
- Bumped Android/iOS metadata to 1.7.0-alpha.1 / build 21.

## 1.6.0-alpha.1 — Quest & Encounter Expansion
- Replaced the static daily-task layer with a rotating three-slot Quest Board backed by QuestDirector.
- Added an 18-task daily pool spanning resources, combat, exploration, risk, buildings, nights, contracts and biome clears.
- Claimed daily quests now rotate into new tasks until the daily reward cap is reached; completed daily cards no longer remain as permanent clutter.
- Split Quest Board from Trophy Hall; the camp now has a physical Quest Board hotspot and home-screen shortcut.
- Added the first resident quest chain: Scout Mira can be rescued in the field, joins the camp permanently and offers a three-step trust chain.
- Expanded Activity Director into a mixed encounter composer rather than fixed caravan/chest/nest spam.
- Added eight encounter types: Rare Ore Vein, Broken Tower, Wind Shrine, Wanderer Grave, Signal Fire, Infected Cache, Memory Rift and Wounded Scout.
- New encounters feed back into Threat, run upgrades, permanent lore, resident unlocks and resident quests.
- Added persistent quest rotation state, resident trust/progress and lore-fragment save data.
- Added dedicated v1.6 regression coverage for daily rotation, replacement-after-claim, Mira progression and encounter population.
- Bumped Android/iOS metadata to 1.6.0-alpha.1 / build 20.

## 1.5.0-alpha.1 — Expedition & Run Diversity 2.0
- Added per-run optional contracts that reward alternate routes, exploration and non-standard defensive builds.
- Added Threat of Darkness: cursed caches and altar bargains raise future pressure, while destroyed nests and relit Hearths reduce it.
- Added announced night modifiers with distinct enemy composition, pacing, Tower pressure and reward profiles.
- Added a pre-night foretelling window so players can prepare for the upcoming threat instead of discovering it only after the wave starts.
- Added Dark Rift night objectives that call reinforcements until the Wanderer leaves passive defense and destroys the objective.
- Rebalanced the Tower into support rather than an auto-win: higher cost, lower base throughput, modifier interactions and temporary Stalker sabotage.
- Added cursed cache variants with materially better loot in exchange for higher Threat.
- Added extinguished ancient Hearth activities after Night 1; relighting them costs carried wood, heals the hero, reduces Threat and supports exploration contracts.
- Expanded dawn progression from a fixed three choices to a rotating three-of-seven doctrine pool.
- Added a compact contract/threat line to the gameplay HUD.
- Added v1.5 regression coverage for contract selection, night previews, Tower tradeoffs, doctrine variety and ancient Hearth spawning.
- Bumped Android/iOS metadata to 1.5.0-alpha.1 / build 18.

## 1.4.0-alpha.1 — Identity & Game Feel
- Established Chapter I around The Extinguishing: the Last Hearth is the final known flame and Guardian relics now reveal that the Guardians once protected the old Hearth network.
- Added LoreRules with biome taglines, environmental lore, relic clues and camp progression whispers.
- Expanded the living camp into a taller, denser hub with stronger Hearth lighting, a visible Wanderer, improved framing, progression structures and better use of the mobile screen.
- Rebuilt the biome selector as a vertical route map from the Last Hearth through Forgotten Forest, Frost Hollow and Ashlands instead of a stack of menu cards.
- Rebuilt the arsenal around an animated weapon preview, role copy and readable combat meters so each weapon reads as a playstyle rather than a stat row.
- Added a dedicated relic hall with physical pedestals, mastery state and story clues; daily tasks and permanent achievements now remain visually separate from trophies.
- Deepened all three biome palettes for stronger identity and reduced Frost Hollow washout so the hero, activities and resources remain readable on phone displays.
- Increased the Last Hearth world-space glow so it works as a visual home beacon, especially during night returns.
- Bumped Android/iOS metadata to 1.4.0-alpha.1 / build 17.
- Added a v1.4 identity regression covering lore, route map, weapon preview, trophy hall, camp composition and Frost readability.

## 1.3.0-alpha.1 — World & Hub Expansion
- Expanded expedition maps by roughly another quarter in linear size while keeping camera limits safely inside the rendered world.
- Fixed the post-night black-region failure by padding the static backdrop beyond camera bounds, insetting camera limits by half the viewport, and making night atmosphere explicitly reversible.
- Added WorldGenerator with resource clusters instead of uniformly scattered harvesting nodes.
- Added biome-aware landmarks so players encounter ruins, stumps, signs, fire pits, ice formations, dead trees and bones while travelling.
- Added WorldActivityDirector and four physical exploration activities: wrecked caravans, caches, enemy nests and ancient altars.
- Linked daytime nest decisions to night difficulty: every surviving nest adds attackers, while destroying one grants loot and permanently reduces that night's threat.
- Moved old random daytime altar/chest popups out of ExpeditionDirector; risk/reward choices now live as discoverable world objects.
- Made tree, stone and ore visuals materially different between Forest, Frost Hollow and Ashlands.
- Deepened biome ground identity with frost cracks/snow, ash patches/embers and forest floor detail.
- Increased daylight windows moderately to support the larger map and new activity interactions without turning travel into downtime.
- Strengthened the hero-local backpack bar: wider gauge, earlier count display, amber near-full state and persistent full warning/return cue.
- Shortened building copy to compact mobile-friendly effect summaries.
- Rebuilt the home screen around a one-screen living-camp composition and a single prominent В ЭКСПЕДИЦИЮ action.
- Simplified persistent camp navigation to Camp / Arsenal / Map / Trophies and moved Forge, Arsenal, Trophies and Map interactions onto camp hotspots.
- Added a dedicated v1.3 regression covering world scale, activity population, nest consequences, resource risk bands, camera safety, night-to-dawn cleanup and compact hub layout.


## 1.2.0-alpha.1 — Production Core
- Replaced the fixed bottom-left joystick with a floating dynamic one-thumb stick that appears under the touch point, drifts with the thumb under large deflection and fades on release.
- Expanded each expedition into a multi-screen world and added a smooth player-follow camera with subtle movement look-ahead.
- Moved backpack readability onto the hero with an in-world fill gauge, near-full count, full warning and directional return cue toward the Last Hearth.
- Reduced the permanent HUD to hero HP, phase, Hearth HP, pause and compact Hearth storage; backpack values remain local to the hero.
- Added distance-based gathering risk: wood is concentrated nearer the Hearth, stone farther out, and ore in the outer exploration zones.
- Increased early-day duration and hero movement speed to support meaningful exploration without turning travel into downtime.
- Made night explicitly call the player home when they are far from the Hearth.
- Added camera-aware biome ambience so forest/frost/ash effects remain correct across the larger world.
- Added physically travelling resource pickups from harvest nodes to the hero and from the hero into Hearth storage.
- Added native pixel resource icons and preserved SVG source references for the future texture/sprite art pipeline.
- Split the large static world backdrop from dynamic gameplay rendering to keep the larger map performant on mobile/Web.
- Rebalanced building costs so players must make real preparation choices instead of trivially constructing everything.
- Added a dedicated production-core regression covering world scale, camera, resource distance, floating-stick behaviour and hero-local return UX.


## 1.1.0-alpha.1 — Visual Reboot
- Rebuilt the in-run HUD around five permanent signals only: hero HP, Hearth HP, phase, backpack and Hearth storage.
- Removed the permanent exit button and replaced persistent debug-like status copy with temporary toasts.
- Replaced large parchment-like construction cards with in-world circular blueprints, focus/affordability states and compact contextual build info.
- Rebuilt the Last Hearth as a campfire-centered landmark with stone ring, storage crate, clearing and worn approach path.
- Deepened biome palettes and added forest edge depth/ground detail to focus attention on the camp.
- Added CoreFX for harvest chips, pickup text, storage bursts, construction bursts, combat sparks, Hearth damage and turret impacts.
- Slimmed the mobile joystick and removed the permanent movement caption.
- Delayed random risk events until after the first night so the opening minute teaches the core loop without interruption.
- Gave enemy archetypes distinct role palettes in addition to silhouette differences.
- Added a production visual-direction document and a dedicated visual regression test.
- Preserved the existing resource-first gameplay, mobile movement and expedition systems while replacing the prototype presentation layer.


## 1.0.0-alpha.1 — Resource-first mobile redesign
- Recentered the run around the original satisfying loop: harvest -> backpack -> hearth storage -> construction -> night defense.
- Added always-visible, separate Backpack and Hearth Storage panels with wood/stone/ore counts.
- Added contextual building cards that explain each building's effect, missing resources and construction progress.
- Reworked Palisade, Forge, Tower and Shrine into tangible roles: base mitigation + enemy slow, weapon power/reach, visible auto-fire, and hero/hearth regeneration.
- Added visible hold-to-build construction instead of instant invisible building.
- Lengthened gathering phases and moved resource spawns out from under the mobile HUD.
- Added a physical palisade around the Hearth, visible tower projectiles, deposit feedback and a clearer resource economy.
- Shifted hero, resources, enemies, buildings and app shell toward a cohesive modern 16-bit / pixel-survival visual language.
- Added a dedicated v1 regression that verifies backpack deposit, visible storage, construction, Forge power, Tower damage and Shrine regeneration.
- Sanitized dynamic gameplay messages so unsupported emoji glyphs cannot reappear in mobile Web UI.


## 0.9.3 — Mobile movement bridge hotfix
- Replaced passive GameWorld discovery with an explicit `MobileControls.bind_world()` bridge from the Web runtime.
- Joystick direction is now applied to the live player immediately on touch/drag and reinforced while the stick is held.
- Added a live integration regression that instantiates a real `GameWorld`, drives the joystick, waits for physics frames and verifies that the hero's position actually changes.
- Added explicit release/unbind handling so the hero stops cleanly when the stick is released or a run ends.
- Bumped visible Web build stamp and Android/iOS metadata to 0.9.3 / build 12.

## 0.9.1 — Mobile control and visual polish hotfix
- Added a dedicated touch joystick that appears only on touch-capable devices and preserves desktop tap-to-move behavior.
- Added analog player movement so partial stick deflection produces partial movement speed and releasing the stick stops the hero cleanly.
- Rebuilt the procedural hero silhouette with readable head, torso, arms, legs, boots, cape, belt, facing direction and walk animation.
- Added a mobile-safe app shell with text navigation and compact currency labels instead of unsupported emoji-only controls.
- Added `UISanitizer` to remove unsupported mobile glyphs and keep dynamic HUD text readable in Web/iOS browsers.
- Updated mobile HUD labels to explicit HP, hearth, bag, night and resource abbreviations and rewrote first-run movement guidance around the joystick.
- Added dedicated mobile regression coverage for autoload presence, analog input lifecycle and glyph sanitization.
- Bumped Android/iOS release metadata to 0.9.1 / build 10.

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
