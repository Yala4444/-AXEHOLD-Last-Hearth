# AXEHOLD v1.13 — Visual Reboot

## Why this pass exists
The game systems had grown much faster than the presentation. On a real iPhone the result read as a prototype:
- too many bordered cards;
- weak information hierarchy;
- debug-like labels;
- repeated rectangular UI;
- small, similar silhouettes for hero and enemies;
- bosses that looked like scaled-up mobs;
- text doing work that icons should do;
- too much visual competition between world and interface.

v1.13 deliberately pauses the next content expansion and fixes the visual foundation first.

## UI principles
1. World first, interface second.
2. One dominant action per screen.
3. Icons replace repeated abbreviations where the meaning is stable.
4. Cards are used only for grouping, not for every line of information.
5. Touch targets remain generous even when visual chrome becomes lighter.
6. Mobile viewport height is treated as scarce.
7. Debug/build information is never rendered over production UI.

## Unified visual system
Added VisualSystem with shared:
- background/surface hierarchy;
- text hierarchy;
- gold/green/red/blue/violet accents;
- panel geometry;
- button geometry;
- compact chips.

Added UiIcon with authored procedural symbols for:
- coins and shards;
- settings;
- camp, arsenal, map, trophies;
- HP and Hearth;
- pause;
- quests, contracts and forge;
- lock/check/skull/arrow/star.

No production navigation relies on emoji.

## Global shell
- Removed the large boxed header.
- Removed the visible build/version subtitle.
- Currency is shown through compact icon chips.
- Settings is icon-only.
- Bottom navigation is now a single restrained dock with icon + label and a clear selected state.
- Panel borders are quieter and spacing is more consistent.
- Section titles are smaller so content starts higher on the screen.

## Camp home
The home screen now has three layers only:
1. living camp scene;
2. one compact story ribbon;
3. one departure surface with route, contract and the Expedition CTA.

Chronicle and contract selection remain accessible without stacking multiple full-width buttons.

Camp world hotspots are now small icon markers over physical objects instead of large text boxes floating across the settlement.

## Arsenal
The previous selected-weapon block consumed too much vertical space.

New layout:
- responsive weapon preview;
- one title/mastery row;
- identity + signature;
- compact stat line;
- small weapon rows with a thumbnail, role and one action.

All four weapons can be browsed with substantially less scrolling.

## Map
The map is route-first:
- smaller node callouts;
- stronger region shapes;
- physical route line;
- cleaner selected state;
- less card coverage over the map itself.

## Trophy hall
Relics now sit in physical architectural alcoves.
Mastery is represented by small dots instead of repeated text blocks.
Locked relics read as empty pedestals rather than disabled cards.

## Gameplay HUD
The HUD was rebuilt around a compact hierarchy:
- hero HP with heart icon and bar;
- central phase/time bar with XP line;
- Hearth HP with Hearth icon and bar;
- icon-only pause;
- one compact storage row;
- contextual build/status panel;
- boss bar only when needed.

The top of the world is less obstructed and no longer looks like four unrelated dashboard cards.

## Characters
The Wanderer now uses a larger authored silhouette:
- hood;
- cape;
- broad shoulders;
- readable torso/legs;
- satchel when carrying resources;
- better attack pose shift.

Enemy families now have visibly different anatomy:
- Husk: asymmetrical corrupted humanoid;
- Runner: low long-limbed predator;
- Brute: broad horned mass;
- Stalker: tall crescent silhouette;
- Guardian: ancient construct.

## Bosses
Guardians no longer share one base body.

Forest Guardian:
- root mass;
- antlers;
- living green core.

Frost Guardian:
- crystalline crown;
- ice blades;
- frozen heart.

Ash Guardian:
- furnace body;
- broken horns;
- glowing cracks.

Each keeps the same mechanical footprint while getting a distinct silhouette.

## Controls and small icons
- Joystick is smaller and more transparent.
- Resource icons were redrawn for 15px readability.
- Legacy WebRuntime build watermark was removed completely.

## Definition of done
v1.13 is complete when:
- shell/navigation no longer depends on emoji;
- home and Arsenal need materially less vertical scrolling;
- gameplay HUD exposes more world;
- player, all four common enemy families and three bosses have clearly different silhouettes;
- map and trophy views read as world spaces rather than card collections;
- all legacy gameplay regressions remain green;
- the deployed Web build is reviewed again from real iPhone screenshots.
