# AXEHOLD v1.10 — Production Feel

## Goal
Raise the moment-to-moment presentation of the existing game without changing its one-thumb structure or hiding unfinished content behind menus.

This pass concentrates on five things that are visible every few seconds:
1. world identity;
2. readable combat impact;
3. Guardian presence;
4. day/night atmosphere;
5. sound and camera response.

## World language
Backdrop chunks now use a much richer deterministic landmark vocabulary.

### Forgotten Forest
- abandoned caravan wheels;
- road markers swallowed by roots;
- ruined arches;
- camp remains;
- root-covered shrines;
- collapsed cabins.

### Frost Hollow
- crystal clusters;
- frozen road arches;
- frozen carts;
- ice-bound cairns;
- memorial spears;
- deep fissures.

### Ashlands
- ruined forges;
- charred trees with ember wounds;
- furnace stacks;
- molten fissures;
- broken war standards;
- collapsed smelter pipework.

Landmark scale grows subtly farther from the Last Hearth so the outer world reads as older, stranger and more dangerous.

## Day → Night
The static background no longer snaps instantly between day and night colors.

Each backdrop chunk now interpolates its palette over time. Path and Hearth clearing colors follow the same transition, while BiomeFX increases local ambience during the change.

The visual intention is:
- day = readable exploration;
- dusk = tension;
- night = compressed visibility and stronger biome ambience;
- dawn = visible relief.

## Biome ambience
### Forest
Day leaves drift across the world. At night, firefly-like motes become denser and brighter.

### Frost
Snow density and wind speed increase with night strength. Fog streaks and late-night gusts make the biome feel colder without covering interactables.

### Ash
Ash and embers increase after dusk. Slow smoke ribbons reinforce heat and ruined industry.

## Guardian identity
Guardians no longer share one generic boss body.

Forest Guardian:
- antlers;
- root mantle;
- living green core.

Frost Guardian:
- ice crown;
- frozen crystal core;
- ice extensions.

Ash Guardian:
- broken horns;
- furnace core;
- glowing cracks.

Each Guardian also gains a biome-colored aura.

## Impact and combat feedback
Added:
- camera shake for hero damage;
- heavier camera response for Frost Hammer;
- stronger arrival shake for Guardians;
- large Guardian defeat burst;
- player damage burst;
- Hearth flare at nightfall and dawn;
- biome-colored enemy death particles;
- larger Guardian arrival ring and title burst.

Weapon rendering also receives stronger action poses and signature glows.

## Harvest feel
Wood, stone and ore now create materially different destruction feedback.

Wood:
- more chips;
- heavier gravity;
- brown splinters.

Stone:
- shorter heavy fragments;
- pale impact pieces;
- compact ring.

Ore:
- brighter purple/biome glints;
- lighter fragments;
- stronger pulse.

## Music
Soundscape now uses two AudioStreamPlayers and crossfades between states instead of hard-cutting every track.

States:
- day;
- night;
- Guardian.

Guardian music has its own lower pulse and biome-specific chord family.

## Performance rules
- backdrop animation only processes while transitioning between day/night;
- ambience remains lightweight immediate drawing;
- no new full-screen translucent CanvasItems were added to the WebGL gameplay viewport;
- existing GL Compatibility target is preserved.

## Definition of done
v1.10 is complete when:
- day/night background changes are gradual;
- all three Guardians visibly differ by biome;
- Guardian arrival and defeat read as major moments;
- camera feedback communicates hits without making one-thumb control uncomfortable;
- biome ambience visibly intensifies at night;
- harvest materials have distinct impact feedback;
- music can crossfade between day/night/Guardian states;
- all previous regression suites remain green.
