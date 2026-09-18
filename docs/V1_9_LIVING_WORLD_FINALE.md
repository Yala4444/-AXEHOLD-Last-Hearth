# AXEHOLD v1.9 — Living World & Chapter I Finale

## Goal
Turn the end of the original three-biome route into the beginning of a larger journey.

v1.9 answers the problem "I finished the whole game quickly" without prematurely adding a shallow fourth biome. The three existing relics now unlock a playable frontier layer, a second resident, timed field assignments and resident support.

## Chapter I Finale
Collecting all three Guardian relics now permanently completes **Chapter I: The Fading**.

The three relics reveal that the Guardians served the same Hearth network. Their resonance detects a weak signal beyond the Ashlands.

First-time completion:
- unlocks the Frontier Signal;
- awards 2 Guardian Shards;
- creates a persistent camp notice;
- opens a fourth node on the World Map;
- unlocks the route to post-Chapter-I systems.

Old saves with all three relics are migrated into the completed state automatically.

## Frontier Map Node
The World Map now continues beyond Ashlands with a fourth visible destination:

**Distant Hearth — Signal Detected**

It is not a normal biome button. It opens the Frontier screen, where the player prepares reconnaissance work for the future Chapter II route.

Before three relics, the node remains visible but sealed. This gives the player a concrete long-term promise.

## Frontier Assignments
After Chapter I, the player can select one optional timed assignment before an ordinary expedition.

Every assignment:
- generates the required world content;
- must be completed no later than the second night;
- is not considered delivered when the objective is touched;
- requires the player to physically return to the Last Hearth during daytime;
- grants meta currency immediately on safe delivery;
- clears from the board after successful return.

Current assignments:

### Two Fires
Light two Signal Fires before Night 2 and return.
Reward: 120 coins.

### Burn the Roots
Destroy two Dark Nests before Night 2 and return.
Reward: 135 coins.

### Heart of the Machine
Recover two Mechanism Parts before Night 2 and return.
Reward: 110 coins.

### Fire in the Dark
After Night 1, relight an extinguished Hearth and return before Night 2.
Reward: 1 Guardian Shard.

This creates the intended short-window gameplay: choose a destination, sprint away from safety, finish a job and decide whether there is enough time to get home.

## Second Resident — Thorn
After Chapter I, a new outer-ring encounter can spawn: **Stranded Engineer**.

Rescuing him permanently brings **Thorn** to the Living Camp.

Thorn has a three-step trust chain:
1. find 4 Mechanism Parts;
2. upgrade one building to Level II;
3. upgrade two more buildings to Level II.

His quests deliberately connect v1.7 building progression to the Living World.

## Resident Support
Trusted residents can now prepare one benefit for the next expedition.

Only one support can be armed at a time.

### Mira — Route of Mira
Requires Trust I.
- +7% movement speed for the next expedition;
- -1 starting Darkness Threat.

### Thorn — Thorn's Kit
Requires Trust I.
- start the next expedition with 1 Mechanism Part.

Support is consumed at expedition start, so residents affect actual runs instead of existing only as quest text.

## Story Archive
The Trophy Hall now records:
- the Chapter I finale;
- the Frontier Signal;
- number of recovered Memory Fragments.

## World / Quest Integration
Frontier progress listens to existing world actions:
- Signal Fires;
- Dark Nest destruction;
- Mechanism Parts;
- relit Hearths.

The same action can legitimately advance:
- a rotating daily quest;
- a resident quest;
- a Frontier Assignment.

This keeps systems connected rather than multiplying unrelated chores.

## Next direction
The Distant Hearth remains a Chapter II hook rather than a fake full biome.

The next production phases should build on this foundation with:
- remote night-defense objectives;
- stronger resident services and camp spaces;
- more story fragments and authored encounters;
- Chapter II biome production;
- additional weapon families only after the current four are visually production-ready.

## Definition of Done
v1.9 is complete when:
- three relics unlock Chapter I finale state and the Frontier node;
- old saves with three relics migrate correctly;
- four Frontier Assignments can be selected;
- assignments enforce their deadline;
- required assignment content is guaranteed in the world;
- completed objectives require return to the Hearth;
- Thorn can be found and rescued;
- Thorn's quest chain progresses;
- trusted Mira and Thorn provide run support;
- Frontier UI is reachable from both Home and World Map;
- all previous regressions remain green.
