# AXEHOLD v1.7 — Buildings & Economy

## Goal
Make resources, coins and Guardian shards matter after the player understands the basic loop. A building should no longer be a one-time checkbox that is finished before Night 1.

## Permanent blueprint economy
The Camp Forge now contains four permanent Level-II building projects.

Each project spends both currencies:
- coins = repeatable camp development currency;
- shards = rare Guardian currency used for qualitative unlocks.

Projects:
- Palisade II — 240 coins + 1 shard;
- Forge II — 320 coins + 1 shard;
- Tower II — 420 coins + 2 shards;
- Shrine II — 380 coins + 2 shards.

A purchased project permanently unlocks two specialization branches for that building in future expeditions.

## Expedition building progression
All four expedition buildings now have two stages.

### Level I
The current building role remains readable and useful.

### Level II
The player must:
1. own the matching permanent blueprint;
2. build Level I;
3. explore the world and find Mechanism Parts;
4. bring ordinary resources back to the Hearth;
5. remain near the building to prepare the upgrade;
6. choose one of two mutually exclusive branches.

The branch lasts for the current expedition. This creates a new run decision without adding more build sites.

## Branches

### Palisade II
- Bastion: +140 Hearth durability, stronger slow and damage reduction.
- Spikes: +80 durability and continuous damage to enemies pressing the wall.

### Forge II
- Tempering: +22% hero damage.
- Arc Workshop: +12 weapon radius and +4% critical chance.

### Tower II
- Ballista: much heavier shots at a slower cadence.
- Repeater: almost twice the firing frequency with lighter individual hits.

### Shrine II
- Renewal: significantly stronger hero and Hearth regeneration.
- Ward: moderate stronger regeneration and a recurring shield charge after dawn.

## Mechanism Parts
A fourth expedition resource now exists: Mechanism Parts.

Unlike wood, stone and ore:
- parts do not consume backpack capacity;
- they are stored directly in the expedition stockpile;
- they are required only for Level-II construction;
- unused parts are converted to coins at the end of the run.

Parts can currently come from:
- Guardians;
- Rare Ore Veins;
- Broken Towers;
- Wanderer Graves;
- Infected Caches;
- the biome Guardian at the end of the expedition.

This directly connects exploration with base progression.

## Quest integration
A new rotating quest can ask the player to upgrade a building to Level II.

## UX rules
- A Level-I building tells the player when its Level-II blueprint is still locked in the Camp Forge.
- When the blueprint is owned, the HUD shows resource and part requirements.
- Holding near an affordable building prepares the upgrade.
- Only after preparation is complete does the branch-choice modal appear.
- Level-II buildings receive an in-world II badge and branch-specific visual detail.
- The result screen explains conversion of unused parts into coins.

## Economy intent
Coins should no longer feel like a number with no consequence.
Shards should no longer exist only as a victory counter.

The target economy loop is now:
Expedition → quests/events → coins + shards → permanent blueprint → deeper expedition choice → stronger/faster progression → next blueprint.

## Definition of done
v1.7 is complete when:
- all four permanent building projects can be purchased with coins and shards;
- save migration preserves old players and adds project state;
- all four buildings can reach Level II;
- every building offers two branch choices;
- Level-II effects alter actual gameplay values;
- mechanism parts are visible in the HUD and spendable;
- risky exploration produces parts;
- unused parts convert to coins;
- previous v1.5.1 and v1.6 regressions remain green.
