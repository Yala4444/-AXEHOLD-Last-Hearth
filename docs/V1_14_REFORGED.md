# AXEHOLD v1.14 — Reforged

## Product goal
v1.14 is a combined quality + gameplay pass. It is intentionally larger than the previous incremental releases.

The target feeling is:
- no obvious prototype artefacts;
- the core weapon fantasy is visible at all times;
- the camp explains itself without a tutorial;
- the world has enough short-term decisions that gathering is not the only daytime verb;
- biome identity affects both moment-to-moment movement and the following night;
- run upgrades can alter play style rather than only increase numbers.

## Critical fixes

### iOS/Web black quadrant
The world background no longer depends on large world-space chunk rectangles for its base fill.

GameWorld owns a screen-space biome fill behind all world CanvasItems. WorldBackdropChunk keeps details, roads, clearings and landmarks but does not paint the giant base rectangle.

This directly targets the recurring iOS/WebGL black square/quadrant seen in real device screenshots.

Regression checks verify that the fallback:
- exists;
- is below the world;
- covers the viewport;
- is not effectively black.

### Weapon orbit
All weapons now have visible motion around the Wanderer.

- Axes: continuous orbit.
- Root Spear: orbits while idle and snaps into a directed thrust when attacking.
- Frost Hammer: heavy slower orbit and slam.
- Ash Twin Blades: fast paired orbit and combo rhythm.

The spear was the main visual regression: its idle representation had become a static facing weapon even though its internal angle was updating. v1.14 restores visible orbit.

## Camp UX
Camp destinations are no longer tiny unexplained icon dots.

Each destination is now a 72×48 thumb-friendly world marker with:
- authored icon;
- visible short label;
- quiet translucent surface;
- pressed/hover state;
- spatial attachment to the corresponding camp object.

Destinations:
- Forge;
- Arsenal;
- Trophies;
- Tasks;
- Contracts;
- Chronicle;
- Map.

The camp remains a physical scene rather than returning to a dashboard grid.

## World art polish
Resource nodes received another production-art pass.

### Trees
- tapered trunks;
- bark shading;
- layered canopy clusters;
- variant silhouettes;
- snow treatment in Frost;
- charred limbs and ember scars in Ash.

### Stone
- faceted silhouette;
- lit and shadowed faces;
- frost cracks;
- ember seams in Ash.

### Ore
- multi-crystal clusters;
- per-biome palettes;
- internal highlight lines;
- harvest sparkle.

## Biome gameplay events
Every biome now owns a gameplay event, not only a palette.

### Forgotten Forest — Roots Awaken
Telegraphed root zones appear around the player.
Touching them damages and briefly slows the Wanderer.

### Frost Hollow — White Storm
The storm reduces movement pressure and creates cracking ice zones.
Standing on active ice damages and applies a strong temporary slow.

### Ashlands — Heat Rift
Fire zones open beneath the Wanderer.
They deal heavier direct damage and force frequent repositioning.

These events reward clean execution:
- coins;
- biome resource;
- lower Darkness Threat;
- persistent regional statistics.

Failure raises Darkness Threat and can alter the next night.

## Regional hunts
The second daytime phase can produce a named regional rare target.

### Root Alpha
Forest pack leader with extra durability and pressure.

### White Hunter
Fast Frost predator using stalker surge behavior.

### Ash Seeder
Heavy armored Ash elite whose region already creates dangerous ground.

Killing a regional target grants:
- coins;
- Mechanism Part;
- lower night pressure;
- regional hunt progression.

Letting it escape:
- leaves it roaming in the expedition;
- raises Darkness Threat;
- applies a biome-specific modifier to the next night.

## Enemies now inherit biome behaviors
### Forest
Runner/basic packs accelerate when they remain close to allies.

### Frost
Runner/Stalker contact can chill and slow the player.

### Ash
Heavy enemies can leave an ember hazard where they die.

The biome changes positioning decisions instead of only enemy stats.

## Night consequences
Failed regional events alter the following night.

Possible effects include:
- larger enemy count;
- faster spawn cadence;
- faster enemies;
- more Stalkers;
- more Brutes;
- higher Hearth damage;
- heavier pressure on the turret.

The night HUD surfaces the regional pressure together with the normal night modifier.

## Build-shaping run perks
Four new perks add conditional play styles.

### Living Supply
Destroyed resource nodes heal the player.

### Hearth Oath
Damage is increased while fighting near the Last Hearth.

### Heavy Load
A backpack at 75%+ capacity increases damage, turning greed into a combat build.

### Hunter Rhythm
Every tenth kill heals the Wanderer.

Level-up choices no longer show prototype-like SPR/DMG/HP prefix codes; they show the upgrade name and effect directly.

## Regional progression
Save version 11 adds persistent per-biome activity statistics:
- events completed;
- perfect event clears;
- regional hunts completed.

The Trophy / Field Journal screen shows these totals per biome.

New daily tasks:
- Calm the Region;
- Hunt the Leader.

Expedition results now summarize regional events and hunts alongside Dynamic World activity.

## Technical regression target
A dedicated v1.14 regression verifies:
- screen-space fallback against black world gaps;
- visible spear orbit progression;
- biome event runtime;
- regional elite spawn identity;
- new perk runtime state;
- larger labeled camp interaction targets;
- new quest specifications.

Previous CI suites remain active.

## Definition of done
v1.14 is shippable to the current web test when:
- all CI suites are green;
- Web export succeeds;
- Pages deploy succeeds;
- a real iPhone no longer shows the black quadrant;
- weapon motion is obvious without explanation;
- every camp destination is understandable without guessing;
- at least one regional event and one regional hunt can be experienced during a full run;
- the new world art is clearly richer than v1.13.
