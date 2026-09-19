# AXEHOLD v1.16 — Threat & Endless Progression

## Product goal
v1.16 turns the three Chapter-I biomes from one-time content into a long-term progression layer.

The player now has three parallel reasons to keep playing:
1. climb Threat I–V in every biome;
2. spend Guardian Shards on permanent strategic upgrades;
3. push personal records in the Endless Last Stand.

The update deliberately deepens the existing three regions before adding another biome.

## Threat I–V

Each biome now has five selectable Threat levels.

### Threat I — Wanderer's Path
- baseline region;
- first clear introduces the Guardian;
- reward multiplier ×1.00.

### Threat II — Darkness Wakes
- tougher and more numerous enemies;
- slightly shorter preparation;
- Tower effectiveness starts to fall;
- reward multiplier ×1.30.

### Threat III — The Land Resists
- meaningful HP/damage/speed pressure;
- elite enemies can appear naturally;
- shorter day window;
- reward multiplier ×1.62.

### Threat IV — Siege
- dense nights;
- more dangerous elites;
- Tower is support rather than a solution;
- reward multiplier ×2.05.

### Threat V — Region Nightmare
- strongest authored difficulty;
- aggressive enemy and boss scaling;
- substantially reduced passive Tower dominance;
- reward multiplier ×2.55.

A level is unlocked by clearing the one below it.

The map now shows:
- I–V selection;
- locked/unlocked state;
- mastery stars;
- reward multiplier;
- first-clear reward.

## First-clear economy

Threat levels have one-time rewards.

- I: +45 coins
- II: +90 coins
- III: +130 coins + 1 shard
- IV: +190 coins
- V: +280 coins + 2 shards

Repeating a cleared Threat still gives the run multiplier, but does not repeat the first-clear payout.

## Guardian Shards finally have a permanent use

The Camp Forge now contains a Relic Forge with three permanent paths.

### Weapon Heat
Up to III.
Each level: +5% damage in every mode.

### Hearth Oath
Up to III.
Each level: +12 maximum HP.

### Gatherer's Mark
Up to III.
Each level: +10% coins from expedition results.

Costs rise 1 → 2 → 3 Guardian Shards.

The intention is that a shard represents a real long-term choice instead of only being an unlock counter.

## Last Stand — Endless mode

After the player has collected all three Guardian relics (or equivalent mastery), Last Stand unlocks.

There is no final third night.

The loop continues:
Day → objectives/events → preparation → night → dawn → stronger night.

### Scaling
Every night gradually increases:
- enemy HP;
- enemy damage;
- enemy speed;
- spawn count;
- final reward.

### Guardian milestones
Every fifth night contains a Guardian.

Examples:
- Night 5 — first Guardian checkpoint;
- Night 10 — stronger Guardian;
- Night 15 — deep siege;
- Night 20+ — record-push territory.

After killing the Guardian, a chest appears as a modal reward choice.

The player can:
- select one of three run upgrades and continue;
- cash out and return to camp;
- optionally watch a rewarded ad to upgrade the chest into a relic-focused choice.

The ad is optional and never blocks normal continuation.

## Visible roguelite relics

The Endless chest can create builds that are physically visible around the Wanderer.

### Fire Orb
One to three fire spheres orbit the hero and burn nearby enemies.

### Frost Circle
A visible frost aura slows nearby enemies.

### Thorn Ring
A rotating ring of thorns periodically releases a damaging radial pulse.

### Guardian Spirit
A small spirit orbits the Wanderer and periodically restores a shield charge.

These can stack with the selected primary weapon, so a late Endless run visually looks different from its opening minute.

## Personal records

Last Stand stores:
- number of Endless runs;
- best night;
- best kills;
- best coin result.

A new best wave is explicitly called out on the result screen.

## Result screens

Standard expedition results now communicate:
- selected Threat;
- first-clear state;
- newly unlocked next Threat.

Endless results communicate:
- last survived night;
- personal record status;
- kills;
- coins;
- shards earned from Guardian milestones.

## Anti-burst combat safety

Real iPhone testing exposed a bad failure mode at the caravan: several enemies could make contact in nearly the same frame and erase the hero before the player could read the encounter.

v1.16 adds:
- 0.52 second damage grace after a real hit;
- short grace after a shield block;
- a wider attack ring around caravan events;
- an explicit HIGH DANGER warning before entering the pack.

The caravan remains dangerous, but deaths should be readable rather than instantaneous.

## Roguelite + existing systems

The new progression does not replace:
- Field Objectives;
- Dynamic World events;
- biome hazards;
- contracts;
- residents;
- building specializations;
- weapon mastery;
- daily tasks.

Instead, Threat and Endless mode amplify those systems.

At higher Threat, the same decisions are made under tighter time and combat pressure.

## Daily Board additions
New task families:
- clear a Threat level;
- reach five nights in Last Stand.

## Save migration
Save version 13 adds:
- unlocked Threat per biome;
- per-Threat clear flags;
- selected Threat;
- current run mode;
- Endless records;
- Relic Forge progression.

Legacy mastery saves are backfilled into the new Threat model.

Legacy regression behavior remains supported so older saves/tests are not invalidated.

## Definition of done
v1.16 is ready for device playtesting when:
- Threat I–V is selectable and sequentially unlocks;
- first-clear rewards do not duplicate;
- high Threat materially changes enemies, preparation and Tower value;
- shards can be spent permanently;
- Endless mode continues beyond Night 3;
- every fifth Endless night produces a Guardian checkpoint;
- chest choices can create visible relic builds;
- rewarded chest upgrade is optional;
- damage grace prevents same-frame event deaths;
- personal Endless records persist;
- every previous regression and Web export remains green.
