# AXEHOLD v1.5 — Expedition & Run Diversity 2.0

## Goal
Make repeated expeditions tell different stories instead of converging on one solved build order.

The v1.5 systems are built around five pressures:
- time;
- distance;
- resources;
- threat;
- current run opportunities.

## Core changes in this slice

### Run contracts
Every expedition now starts with one optional contract from a rotating pool. Contracts reward alternate routing and builds instead of only kill counts.

Current contract identities:
- destroy nests before the second night;
- reach the outer ring;
- survive Night 1 with at most one structure;
- resolve world activities;
- survive Night 1 without a Tower;
- finish with a healthy Hearth;
- relight an extinguished ancient Hearth.

### Threat of Darkness
Risky daytime choices now feed a persistent Threat value.
- cursed caches increase Threat;
- altar bargains increase Threat;
- destroying nests reduces Threat;
- relighting old Hearths reduces Threat;
- unresolved nests add temporary effective Threat before each night.

Threat does not secretly rubber-band enemy HP. It influences clearly announced night composition.

### Night foretelling and modifiers
Roughly 18 seconds before darkness, the upcoming night is revealed so the player can react.

Night modifiers include:
- Hungry Night — more fast enemies;
- Siege — tougher heavy pressure;
- Black Wind — faster enemies and weaker Tower support;
- Blood Tide — stronger enemies, better coin rewards;
- Quiet Dark — fewer but much tougher enemies.

### Dark Rift objective
Later nights can spawn a Dark Rift away from the Hearth.
It continuously calls reinforcements until the player leaves the passive defensive position and destroys it.

### Tower counterplay
The Tower is deliberately no longer a self-playing win condition.
- higher build cost;
- lower base damage;
- slower fire;
- certain night modifiers weaken it;
- Stalkers can dive the Tower and temporarily disable it.

A first-night Tower remains possible, but now requires a meaningful route/resource tradeoff.

### World event expansion
Some caches are now cursed: higher reward in exchange for future night pressure.

After the first night, an extinguished ancient Hearth can appear in the outer world. Carrying wood to it relights the Hearth, heals the Wanderer, reduces Threat and advances a dedicated exploration contract.

### Dawn doctrines
The fixed Hunt/Fortify/Supply trio is replaced by a random three-of-seven choice pool:
- Hunt;
- Fortify;
- Supply;
- Scout;
- Gathering;
- Firekeeper;
- Overwatch.

This prevents the same post-night build path every run.

## Design target
Night 1 should still be readable and survivable, but a single Tower should remove only part of the pressure. The hero must still move, intercept threats and respond to objectives.

By Night 2, the player should be reacting to the story created during the day: nests left alive, risky caches opened, Threat raised or lowered, selected doctrine and available structures.

## Next v1.5 passes
- biome-specific expedition events;
- additional night objectives;
- structure level II upgrades;
- richer perk identities;
- authored expedition art;
- stronger harvest feedback;
- enemy presentation and boss pass;
- additional persistent quest rotations.
