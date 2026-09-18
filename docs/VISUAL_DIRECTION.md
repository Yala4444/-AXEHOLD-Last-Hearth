# AXEHOLD — Visual Direction v1.1

## Product target
AXEHOLD is a mobile-first hybrid-casual survival builder. The visual target is **modern pixel survival**, not retro parody and not placeholder vector art.

The game must read clearly on a 6–7 inch phone in portrait orientation with one hand.

## Core principles
1. **World first, UI second.** HUD must never occupy more screen than the world needs.
2. **One message at a time.** No stacked tutorial text, persistent debug-like status strings or duplicate explanations.
3. **Silhouette before detail.** Hero, runner, brute, stalker, guardian and boss must be distinguishable without labels.
4. **Chunky pixel forms + smooth motion.** Art uses crisp blocky forms; movement, easing and VFX remain fluid.
5. **Tactile core loop.** Harvest, deposit, build and hit events must always have visual feedback.
6. **No emoji as production icons.** Use text abbreviations or game-drawn shapes until a real icon set is introduced.
7. **Build sites belong to the world.** No parchment cards or spreadsheet-like panels on the ground.

## Forest palette
- Deep ink: #10191D
- Moss dark: #385C46
- Moss mid: #648B58
- Grass light: #9EBE75
- Hearth gold: #D5A652
- Warm highlight: #F3D88E
- Timber dark: #4D3321
- Timber mid: #8D633B
- Stone: #97A2A0
- Ore violet: #A274BE
- Danger red: #C95C55

## UI
- Corners: 2–4 px radius only; avoid large modern SaaS pills.
- Border: 1 px subtle outline.
- Primary accent: warm hearth gold.
- Permanent HUD: HP, Hearth, phase, backpack, storage only.
- Build card: appears only near a build site.
- Status messages: temporary toast, maximum 2 lines.
- Exit: pause menu only.
- Modal events: never during the first gathering minute/run tutorial.

## World composition
- Keep a readable clearing around the Hearth.
- Resource clusters should frame paths rather than fill every empty space.
- Darker edge values, warmer center values.
- Forest ground uses 3–4 values of moss/grass plus small pixel tufts.
- Built structures should increase the visual density of the clearing over time.

## Hero
- 16–22 px-ish readable body at gameplay scale.
- Dark outline, warm face, strong cape/tunic color block.
- Idle, walk bob, hit flash, shield and perk feedback.
- Weapons must remain readable even when the hero overlaps scenery.

## Enemies
- Normal: compact ghoul silhouette.
- Runner: narrow body, long legs.
- Brute: wide shoulders / heavy mass.
- Stalker: angular / pointed silhouette.
- Guardian: rectangular armored silhouette.
- Boss: 1.5–2x visual mass and clear telegraph.

## Buildings
- Palisade: timber, physically encloses the Hearth.
- Forge: warm fire / chimney / metal accent.
- Tower: tall, cool metal/wood silhouette, visible projectile.
- Shrine: cyan crystal, healing glow.
- Build blueprint: circular ground marker, ghost silhouette, short name tag only.

## VFX
- Harvest: colored pixel chips + short pickup text.
- Deposit: warm radial pulse + storage burst.
- Build: gold burst + pulse + structure pop.
- Hit: 4–8 directional pixel sparks.
- Hearth damage: red impact particles and pulse.
- Turret: readable tracer and impact spark.
- Never cover the screen with particles; effects must support readability.

## Definition of done for a visual pass
A build is not visually accepted merely because it compiles. It must:
- preserve at least 60% of the screen for world visibility;
- have no unsupported glyph squares;
- show no persistent debug-like copy;
- make backpack/storage understandable in under 2 seconds;
- make all four buildings visually distinguishable;
- make the hero and major enemy classes distinguishable at phone scale;
- provide feedback for harvest, deposit, build and combat;
- pass mobile control and gameplay regression.
