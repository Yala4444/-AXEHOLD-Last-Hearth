# AXEHOLD v1.9 — Story & Residents

## Goal
Make the Last Hearth feel like a place that remembers what the player has done, and give Chapter I a real conclusion instead of ending silently after the third Guardian.

This pass does **not** add fake playable regions. It establishes the next narrative direction inside the finished game systems while keeping the current three biomes as the complete Chapter I route.

## Chronicle
The camp now contains a dedicated Chronicle.

The Chronicle tracks:
- current chapter;
- Guardian relic progress;
- discovered relic clues;
- Memory Rift fragments;
- rescued named residents;
- resident trust;
- the Chapter I finale and the next story objective.

The Chronicle is available from the living camp and from the home story card.

## Chapter I finale
After all three Guardian relics are acquired, the Chronicle exposes the full message:

> Один огонь не удержит ночь.

The relics form a map of the old Hearth network. The Wanderer's objective changes from endlessly defending one fire to searching for the extinguished network beyond the known regions.

The player actively completes the chapter from the Chronicle and receives 2 Guardian Shards. The reward is one-time and saved.

## Chapter II direction
Chapter II is titled:

**ДОРОГА К ОГНЯМ**

Current objective:
- prepare a long-range expedition;
- find the first external Hearth beyond the three known regions.

This is intentionally a narrative direction only. No unimplemented biome is presented as playable content.

## Named residents

### Mira — Scout
Mira is still rescued from the Wounded Scout encounter, but her chain expands from three to five steps:
1. Light 2 Signal Fires.
2. Reach the outer world ring twice.
3. Destroy 3 Darkness Nests.
4. Investigate 2 Memory Rifts.
5. Relight 2 ancient Hearths.

Her trust cap is now 5.

### Thorn — Engineer of the Old Fire
Thorn is a second permanent named resident.

While Thorn is locked, each run guarantees a Broken Tower opportunity. Repairing that tower sends an old signal that leads Thorn back to the Last Hearth.

His four-step chain:
1. Repair 2 Broken Towers.
2. Recover 4 Mechanism Parts.
3. Upgrade 2 buildings to Level II.
4. Survive 3 nights.

His chain connects exploration, the v1.7 economy and defense into one persistent character progression.

## Encounter reliability
When Mira is not yet rescued, the run composer guarantees one Wounded Scout encounter.
When Thorn is not yet rescued, the run composer guarantees one Broken Tower encounter.

This avoids permanent progression being hidden behind unlucky random encounter rolls.

## Living camp presentation
- Added a physical Chronicle hotspot.
- The camp header now shows Chapter I / II.
- Mira and Thorn use distinct in-world silhouettes rather than being represented only as generic population dots.
- The Quest Board renders every unlocked resident and their own trust chain.
- The Chronicle shows both discovered and still-missing residents.

## Save migration
Save version is now 8.

Older saves gain:
- story_state;
- Chapter I finale state;
- normalized Mira/Thorn quest fields.

Existing players who already own all three relics immediately qualify for the Chapter I finale, but the one-time reward still requires an explicit Chronicle claim.

## Analytics
Added/used:
- chapter_ready;
- chapter_completed;
- resident_quest_completed;
- resident_quest_claimed;
- resident_rescued.

## Definition of done
v1.9 is complete when:
- three relics unlock the Chapter I finale;
- the chapter reward can only be claimed once;
- Chapter II direction appears only after Chapter I completion;
- Mira has five working quest steps;
- Thorn can be discovered and has four working quest steps;
- locked residents receive deterministic discovery opportunities;
- Mechanism Parts and survived nights progress Thorn quests;
- the living camp exposes Chronicle and named residents visually;
- all v1.4–v1.8 regressions remain green.
