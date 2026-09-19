# AXEHOLD v1.17 — First Run & Difficulty Calibration

## Goal
v1.16 gave AXEHOLD long-term progression, but it also exposed two problems:
1. a new player can enter the game without understanding the core loop;
2. Threat II can punish the Hearth too sharply on the first night before the player has time to read the mistake.

v1.17 makes the first ten minutes understandable without turning the game into a tutorial slideshow, and smooths only the opening night of higher Threat tiers while preserving later difficulty.

## The First Path
Fresh players now enter a dedicated first-path expedition in Forgotten Forest on Threat I.

This route is still the real game, not a separate fake tutorial level.

The player learns the loop through five contextual steps:

1. Movement
   - move the Wanderer away from the Hearth;
   - no blocking modal;
   - weapon movement remains visible.

2. Harvest
   - approach a tree;
   - learn that the weapon attacks automatically;
   - gather a few resources.

3. Return
   - fill the backpack enough to make returning meaningful;
   - the home arrow activates;
   - depositing at the Hearth is learned through play.

4. Build
   - the Palisade build pad is highlighted;
   - player learns that construction starts by standing near the project when resources are available.

5. First night
   - the day shortens after the first defense is built;
   - the game explicitly explains that Darkness targets the Last Hearth;
   - the first tutorial attack uses fewer and weaker enemies;
   - the tutorial is completed only after surviving the first night.

The message at the end is the complete core promise:
Harvest → build → defend.

## Quiet tutorial run
The first tutorial expedition intentionally disables:
- caravans;
- ambushes;
- survivor rescues;
- regional hunts;
- timed field objectives;
- biome hazard events;
- exploration activities and risk/reward interactables.

This prevents the player from learning six systems before understanding the one that matters.

Normal content returns on the next expedition.

## Replay tutorial
Settings now contain “Repeat Tutorial”.

This:
- does not reset progress;
- enables hints;
- schedules one tutorial expedition;
- temporarily selects Forgotten Forest and Threat I;
- returns to normal progression once the first night is survived.

## Camp onboarding
Before the tutorial is completed, the Camp shows a highlighted First Path card that explains the five-part loop.

The main departure button becomes “Start Tutorial” rather than presenting the first run as a normal expedition.

## Threat readability
The Threat selector now includes a preparation recommendation.

Examples:
- Threat I: suitable for learning the region;
- Threat II: build at least one defense before Night 1;
- Threat III: mastered weapon + one or two structures recommended;
- Threat IV: developed Forge and building specializations;
- Threat V: endgame build planning expected.

The player is informed, not blocked.

## Threat II first-night calibration
Threat II remains meaningfully harder than Threat I, but its first night is no longer allowed to jump straight to full v1.16 pressure.

Night 1 applies a temporary ramp:
- fewer attackers than the previous Threat-II formula;
- slightly reduced enemy HP and contact damage;
- slower spawn cadence;
- reduced damage to the Hearth.

Night 2 onward uses full Threat-II values.

Threat III and IV receive smaller first-night ramps.
Threat V receives no relief.

The intended rule is:
Night 1 checks preparation.
Night 2 checks the build.
Night 3 tests mastery.

## Tutorial combat safety
The tutorial Night 1 receives additional protection:
- capped enemy count;
- lower enemy HP;
- lower contact damage;
- slower spawn interval;
- reduced Hearth damage.

It should still require the player to move and defend, but not erase the Hearth while the player is learning what “night” means.

## Existing progression
v1.17 does not remove or simplify:
- Threat I–V;
- Endless Last Stand;
- regional events;
- Field Objectives;
- contracts;
- residents;
- Relic Forge;
- weapon mastery;
- building specializations.

It only improves when those systems are introduced.

## Save migration
Save version 14 adds a replayable-tutorial flag.

Existing players keep their progression and do not automatically re-enter the tutorial.
They can choose Repeat Tutorial in Settings.

## Definition of done
- Fresh save launches a First Path tutorial expedition.
- Tutorial forces Forgotten Forest / Threat I.
- No surprise events appear during the tutorial run.
- Player is guided through movement, harvest, deposit, Palisade and first night without blocking tutorial modals.
- Tutorial completes after surviving Night 1.
- Tutorial can be replayed from Settings without resetting progression.
- Threat selector communicates expected preparation.
- Threat II Night 1 is clearly survivable with active play or one basic defense.
- Threat II Night 2+ returns to full intended difficulty.
- Previous regressions, Web export and Pages deployment remain green.
