# AXEHOLD v1.15 — Living Expedition

## Goal
v1.14 made the expedition technically safer and added regional events. v1.15 makes the daytime loop feel directed rather than empty.

The player should repeatedly face a short decision:
- keep harvesting;
- follow a temporary field marker;
- take the reward before a larger world event begins;
- accept the Darkness pressure if the opportunity is missed.

This creates an expedition rhythm instead of a continuous resource walk.

## Field Objectives
A new FieldObjectiveDirector introduces short, timed objectives early in each daytime phase.

The system deliberately sequences around larger Dynamic World and biome events instead of stacking three alerts at once.

### Survey Point
A temporary reconnaissance beacon appears away from the Hearth.

Player task:
- reach the marker;
- hold position briefly;
- finish before the timer expires.

Reward:
- coins;
- small expedition movement bonus;
- reduced Darkness Threat.

This turns movement and route choice into a direct objective.

### Field Cache
A salvage point appears on the map.

Player task:
- reach it;
- remain nearby long enough to dismantle it.

Reward:
- Mechanism Part;
- biome-relevant resource;
- coins.

Forest supplies wood, Frost supplies stone, Ash supplies ore.

### Purge Zone
A marked pack occupies an area.

Player task:
- reach the zone;
- eliminate the whole marked group before the timer expires.

Enemy composition is biome-dependent.

Reward:
- coins;
- XP;
- reduced Darkness Threat.

If the player misses the timer, surviving enemies stop guarding the zone and begin hunting the Wanderer.

## Resident integration
Field objectives use residents when they are available:
- Mira calls reconnaissance objectives;
- Thorn calls salvage objectives;
- before a resident is unlocked the same mechanic is framed as general scouting.

Residents now affect what the player hears during the run, not only passive stats in the camp.

## Objective compass
The Wanderer gains a second contextual world cue.

- Hearth arrow remains reserved for returning home.
- Field-objective arrow points toward the active temporary objective.
- It disappears immediately after success/failure.

The marker is local to the hero, so the player never has to guess which edge of the screen contains the task.

## Weapon motion polish
The weapon pass continues:
- player shadow is now an ellipse rather than a prototype rectangle;
- hammer receives a visible idle orbit trail;
- axe, spear, hammer and twin-blade geometry is slightly heavier for phone readability;
- objective compass and weapon visuals coexist without adding attack buttons.

The one-thumb identity remains intact.

## Pacing rules
Field objectives start near the beginning of a day.

Dynamic World encounters wait while a field objective is still active.
Biome events and regional hunts also wait instead of overlapping the temporary objective.

The intended day rhythm becomes:
1. gather / orient;
2. short field objective;
3. broader exploration event;
4. resource/build decision;
5. warning;
6. return to Hearth;
7. night defense.

## Meta progression
Save version 12 adds persistent Field Objective statistics:
- completed;
- failed;
- perfect.

Perfect means the objective was completed with at least eight seconds remaining.

The Camp Field Journal displays these totals.

## Daily tasks
Two task types enter the rotating Daily Board:
- Follow the Mark — complete three field objectives;
- Without Delay — finish a field objective with a large time reserve.

## Run results
The result screen now reports:
- field objectives completed;
- perfect completions;
- missed objectives;
- caches salvaged;
- purge zones cleared.

This makes a run tell the player what actually happened rather than only listing kills and currency.

## UX / readability
Field Objective markers use:
- strong pulsing world ring;
- physical beacon/cache/corruption silhouette;
- timer;
- interaction progress;
- short label.

They remain world objects, not full-screen modal interruptions.

## Technical
New:
- FieldObjectiveDirector
- FieldObjectiveMarker
- persistent field-objective stats
- v1.15 regression smoke test

Updated:
- GameWorld
- AxPlayer
- DynamicWorldDirector
- BiomeEventDirector
- QuestRules
- Camp Field Journal
- Expedition result screen

## Definition of done
- A full run can generate field objectives without blocking existing events.
- Player receives an obvious directional cue.
- Survey and salvage can be completed by reaching/holding the world marker.
- Purge spawns a biome-relevant combat pack.
- Failure raises Darkness pressure instead of simply deleting the event.
- Larger dynamic and regional events wait instead of visually stacking.
- Results and persistent journal report the new gameplay.
- Previous regressions remain green.
