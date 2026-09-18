# AXEHOLD v1.11 — Living Camp & Expedition Contracts

## Goal
Give repeated expeditions a persistent purpose beyond raw coins and Guardian wins.

v1.11 connects four systems that previously lived beside each other:
- expedition contracts;
- resident trust;
- camp appearance;
- long-term progression.

The Last Hearth should now visibly grow because of what the player actually does.

## Daily contract board
Every day the camp receives three persistent expedition contracts.

The player chooses one before leaving:
- the selected contract is used by the next expedition;
- completing it still gives its normal run coin reward;
- a board contract also grants **Camp Renown**;
- a contract can only grant Renown once per daily board;
- completed contracts stay visibly completed for the day;
- the player can then choose another remaining offer.

Starting a run without a selected board contract still gives a random field contract, but that random contract does not grant Camp Renown.

## Contract risk and Renown
Current contracts now expose a risk label and Renown value.

Examples:
- Outer Reach — low risk, +1 Renown.
- Nest Hunter — medium risk, +2 Renown.
- No Tower — high risk, +2 Renown.
- Hearthkeeper — high risk, +3 Renown.

This makes contract choice a strategic pre-run decision instead of a random notification after the expedition already started.

## Camp Renown
New persistent value: **Camp Renown**.

Renown comes primarily from board contracts. Resident quest claims also add Renown, and completing a full resident chain grants an additional point.

Current growth thresholds:
1. Last Hearth — 0.
2. Shelter — 3.
3. Watch Camp — 8.
4. Living Settlement — 15.
5. Fortress of Fire — 25.

Legacy biome mastery remains a valid route to already-earned camp visuals so existing players are never visually downgraded.

## Visible camp growth
Camp level now changes the living hub itself.

Growth includes:
- additional tents;
- lanterns around the Hearth;
- contract board;
- palisade;
- watchtower;
- settlement banners;
- stronger central composition;
- stronghold architecture at the highest level.

The home header now shows current camp identity and Renown.

## Residents now matter in expeditions

### Mira
Each Trust level adds +1% movement speed.
Trust also reveals the upcoming night modifier earlier, up to 6 seconds earlier at maximum Trust.

### Thorn
At Trust 2 he prepares 1 Mechanism Part at expedition start.
At Trust 4 he prepares 2 parts and grants +5% Tower damage.

These bonuses are intentionally small. Residents add utility and personality without invalidating resource collection or defensive choices.

## Expedition result
The result screen now reports:
- which contract was attempted;
- whether it was completed;
- Camp Renown gained.

## Save migration
Save version is now 9.

Older players receive a Renown backfill based on:
- existing biome mastery;
- rescued residents and their Trust;
- purchased Level-II building projects.

This prevents progressed saves from returning to a visually empty camp.

## Definition of done
v1.11 is complete when:
- three unique board contracts generate;
- one can be selected before a run;
- the selected contract reaches RunVariationDirector;
- completing a board contract grants Renown once;
- duplicate daily completion cannot duplicate Renown;
- camp level changes from Renown;
- CampView visibly reacts to camp level;
- Mira and Thorn Trust alter real expedition values;
- contract outcome appears on the result screen;
- older camp/mastery progression remains compatible;
- all previous regression suites remain green.
