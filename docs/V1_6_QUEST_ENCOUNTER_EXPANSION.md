# AXEHOLD v1.6 — Quest & Encounter Expansion

## Goal
Make the world generate different reasons to leave the Hearth and give the player new objectives after Chapter I instead of ending at three relics.

## Daily Quest Board
The old fixed "trees / kills / builds" block is no longer the main quest layer.

A rotating three-slot Quest Board now:
- refreshes automatically by calendar date;
- replaces a claimed quest with another task up to a daily reward cap;
- draws from exploration, combat, risk, building, biome and run categories;
- keeps permanent achievements separate from daily work.

Current daily pool includes:
- wood, stone and ore gathering;
- combat and building;
- nest destruction;
- world-event completion;
- relighting old Hearths;
- cursed-cache risk;
- run contracts;
- night survival;
- Dark Rift closure;
- outer-ring exploration;
- Guardian victories;
- first-night no-Tower challenge;
- biome-specific clears.

## Resident quest foundation
The first resident chain is live.

### Scout Mira
Mira can be found wounded during an expedition. Rescuing her permanently adds her to the camp state and unlocks a three-step trust chain:
1. light two signal fires;
2. reach the outer ring twice;
3. destroy three Dark Nests.

Each claimed step raises trust and gives a meaningful currency reward.

## Activity Director 2.0
A normal run now builds a mixed encounter set rather than repeating caravan/chest/nest spam.

Every run guarantees:
- strategic pressure;
- at least one clean reward;
- a risk/reward encounter;
- a story or utility encounter;
- spacing between activity points.

Eight new encounter identities join the existing pool:

### Rare Ore Vein
Long interaction, strong ore payout, small Threat increase from noise.

### Broken Tower
Costs carried stone to repair. Grants a run-long Tower improvement.

### Wind Shrine
Grants run-long movement speed and slightly reduces Threat.

### Wanderer Grave
Rewards coins, XP and protection, but increases Threat.

### Signal Fire
Costs carried wood, reduces Threat and advances Mira's quest chain.

### Infected Cache
High material payout with a clear Threat consequence.

### Memory Rift
Adds a persistent lore fragment and a camp notice.

### Wounded Scout
Can rescue Mira as a permanent resident.

Together with caravan, cache, Dark Nest, altar and extinguished Hearth, v1.6 has 13 encounter identities.

## UI separation
Trophy Hall and Quest Board are now separate gameplay destinations.
- Trophy Hall = relic lore + permanent achievements.
- Quest Board = rotating daily tasks + resident chains.
- The camp has a physical Quest Board hotspot.
- The home screen also exposes a direct Quest Board button.

## Persistence
Save data now preserves:
- daily quest rotation state;
- quest archive count;
- daily claim budget;
- resident unlocks;
- resident trust and quest progress;
- lore fragments.

## Definition of done
v1.6 passes when:
- three active daily quests always generate;
- claiming one replaces it while the daily reward budget remains;
- Mira can be rescued and her chain progresses;
- a run contains at least seven mixed activity nodes;
- all eight new encounter types instantiate;
- the Quest Board is reachable and scrollable on mobile;
- all previous gameplay, mobile and stability regressions remain green.
