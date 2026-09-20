# AXEHOLD — Product & Production TЗ
## Direction after BUILDCRAFT: Living World / Living Board Game

### 1. Product goal

AXEHOLD must feel like the game people expect when they see a strong mobile-game ad, but without the ad/game mismatch. The core fantasy is simple:

**leave the Last Hearth → gather automatically → bring resources home → the Hearth visibly grows → build and prepare → survive the night → return stronger → make a different run next time.**

The game is a medium-complexity mobile time-killer with strong replayability. It combines:
- survivor-like automatic combat and harvesting;
- physical resource gathering / carrying / deposit satisfaction;
- base growth and defense;
- short roguelite runs with meaningful events;
- persistent camp progression;
- buildcraft and visual power escalation.

The player controls **movement, route, risk and choices**. The character should not stop to manually chop every tree. Orbiting weapons/tools automatically attack enemies and harvest resources inside their working radius.

### 2. Non-negotiable identity

Keep:
- automatic harvesting and combat;
- resources visibly flying from the world to the player;
- deposit at the Last Hearth;
- the Hearth as the emotional center and “home”;
- day = exploration/preparation, night = defense;
- readable construction and meaningful structures;
- Events 2.0 consequences;
- BUILDCRAFT families/evolutions;
- soft, pleasant, home-like art mood.

Do not:
- return to the rejected primitive prototype;
- turn the game into a runner;
- replace automatic gathering with manual repeated tap/chop actions;
- flood the map with dozens of equal-value events;
- add systems that are invisible, purely numerical or hard to understand;
- make the visual language childish or toy-like;
- solve depth by adding many menus.

### 3. Art direction — “Living Board Game”

The chosen style is **A: Living Board Game**.

Desired feeling:
- warm, tactile and calm by day;
- darker and more threatening at night;
- soft silhouettes and rounded shapes;
- clear hierarchy from phone-screen distance;
- restrained detail so production remains maintainable;
- the world should look handcrafted, not like placeholder primitives.

Rules:
1. One strong silhouette per gameplay object.
2. 2–4 major color masses per object, not dozens of micro-details.
3. Details exist only when they explain role or material.
4. Characters and enemies use subtle squash/bob/lean rather than expensive frame-heavy animation.
5. World decoration never competes with resources, enemies, Hearth or build pads.
6. Warm light = home/safety/reward. Cold/dark contrast = danger.
7. Visual effects use arcs, motes, glow and particles, but stay readable on a phone.
8. Each biome keeps the same production grammar; palette/materials change, not the entire renderer.

### 4. Player character — Wanderer

The Wanderer must read immediately as the same hero from every camera-relative direction.

Silhouette:
- hood / head;
- broad upper body;
- cape;
- satchel/backpack;
- Hearth rune;
- orbiting weapon clearly separated from the body.

Movement:
- movement direction drives body lean;
- front/back/side intent must be readable even with a compact asset set;
- horizontal movement mirrors correctly;
- moving upward compresses the visible face and emphasizes hood/cape;
- moving downward opens the chest/rune silhouette;
- walk cycle uses controlled bob, alternating step and cape lag;
- weapon actions add a short directional recoil/lean;
- no skating: acceleration/deceleration and body movement must visually agree.

Animation targets:
- idle breathing;
- walk;
- impact reaction;
- shield reaction;
- level-up pulse;
- build evolution pulse;
- full backpack weight cue;
- night/home direction cue.

Supportability rule:
**no giant frame atlas is required for the first production pass.** Direction + procedural body motion + one strong illustration is preferred until the art pipeline is locked.

### 5. Automatic weapon / harvesting fantasy

This is one of the main AXEHOLD signatures.

Player:
- moves only;
- does not press an attack button;
- orbiting weapons/tools work automatically.

When a resource enters weapon radius:
- weapon continues its orbit;
- resource wobbles/reacts;
- small chips/sparks appear;
- HP state is readable only while damaged;
- on destruction, physical resource tokens burst outward and then curve into the Wanderer;
- inventory visibly fills.

When an enemy enters weapon radius:
- same weapon remains believable as the source of damage;
- hit particles and weapon trails show contact;
- player never looks like they are “telepathically” damaging objects.

### 6. Resources

Core resources:
- tree → wood;
- rock → stone;
- ore deposit → ore.

Requirements:
- tree is the largest and most immediately readable harvest target;
- rock is lower/wider;
- ore is compact and visually valuable;
- biome palette changes preserve the silhouettes;
- damaged resources react with wobble/squash;
- destruction gives satisfying burst + attraction to player;
- resource respawn should preserve exploration routes rather than appearing inside the Hearth clearing.

The initial screen should show enough harvestable objects to understand the loop immediately, but not become visual noise.

### 7. Last Hearth — core emotional system

The Last Hearth is not just a base HP object. It is the visual measure of progress inside a run.

Hearth has visible growth stages.

Stage 0 — Ember:
- small flame;
- small warm safety radius;
- sparse storage.

Stage 1 — Campfire:
- stronger flame;
- brighter ring;
- larger deposit area;
- first visible supplies/crates.

Stage 2 — Last Hearth:
- powerful central fire;
- larger warm territory;
- additional camp dressing;
- stronger sense of “home”.

Stage 3 — Beacon:
- achieved late in a strong run;
- clearly larger light radius;
- impressive but still clean;
- communicates that the player built something worth defending.

Growth comes from **resources actually delivered home**, not from arbitrary hidden XP.

Gameplay effects are deliberately modest:
- more maximum Hearth HP;
- small recovery/safety benefit close to home;
- slightly larger deposit comfort radius;
- visual territory expansion.

It must never trivialize night combat. Buildings remain strategically important.

### 8. Day loop

The day should feel like a readable sequence rather than simultaneous system spam.

Priority:
1. leave the Hearth;
2. choose a useful route;
3. automatically harvest;
4. fill backpack;
5. return/deposit;
6. spend resources on defense/development;
7. optionally take one meaningful event/risk;
8. notice sunset and return home.

Only one new rule should be introduced at a time for a new player.

### 9. Night loop

Night fantasy:
**“That warm light is my home. The darkness is coming for it.”**

Rules:
- Hearth visible as a warm landmark;
- enemy silhouettes readable before they touch the base;
- first wave direction is understandable;
- enemies choose between player/base according to existing combat rules;
- walls, tower, shrine and forge have visible, understandable value;
- damage to Hearth receives stronger audiovisual feedback;
- night ends with a real release: silence → dawn → repair/reward/development.

Threat II rule remains:
- Night 1 can be survived by active good combat even with minimal building;
- or by basic defense with room for a few mistakes;
- Night 2/3 may punish much harder.

### 10. Buildings

Palisade:
- visibly defines a defensive perimeter;
- slows enemies and lowers damage to Hearth;
- gate opening remains readable.

Forge:
- visibly associated with weapon improvement;
- build result should immediately affect player weapon read.

Tower:
- visibly shoots;
- projectile/shot origin is readable;
- stalkers can disable it, making its vulnerability understandable.

Shrine:
- visible recovery/ward language;
- healing and defense should be visibly communicated.

Do not add more structures until these four are satisfying and strategically distinct.

### 11. Enemy visual roles

Enemy roles must be identifiable by silhouette before the player reads any text.

Normal / Root Husk:
- medium upright threat;
- baseline speed/HP.

Runner / Briar Hound:
- low and long silhouette;
- fastest approach;
- animation reads as pounce/run.

Brute / Ironroot Ravager:
- broad, heavy;
- slower;
- visibly high impact.

Stalker / Hollow Seer:
- tall/thin/masked;
- unnatural movement;
- threat to passive tower play.

Guardian / Oathstone Bulwark:
- wide, stone-like defensive mass;
- slow and durable.

Boss / regional Guardian:
- much larger footprint;
- phase attacks are telegraphed;
- must feel like a run climax, not a scaled-up normal enemy.

### 12. Event philosophy

Events 2.0 remains the standard:
- fewer events;
- larger consequences;
- choices remembered during the run.

A good event changes one of:
- next night;
- build;
- ally;
- relic/buildcraft;
- Hearth;
- route/risk.

A weak event that only gives “+some resources” should either be upgraded or removed.

### 13. BUILDCRAFT

Keep six schools:
- Fire;
- Steel;
- Frost;
- Ward;
- Hunt;
- Roots.

3/3 creates an evolution with visible mechanical change.

Buildcraft must become visible in the world:
- Fire adds stronger orbiting flame;
- Frost creates a larger cold field;
- Roots create thorn/ring language;
- Ward creates spirits/shields;
- Hunt adds red predatory accents/crit feedback;
- Steel increases orbit/weapon density.

The player should be able to look at a late-run Wanderer and roughly understand what kind of build was created.

### 14. Information hierarchy / HUD

The HUD should answer instantly:
- how healthy am I?
- how healthy is the Hearth?
- what night/day is it?
- how full is my backpack?
- what do I carry?
- what is the current meaningful objective?
- what danger is happening right now?

Avoid:
- square placeholder glyphs;
- broken/unavailable icon characters;
- rows of unexplained abbreviations;
- low-value counters during active combat.

Use text labels where an icon is not production-safe.

### 15. Pacing target

A normal run should feel like:
- first 20–40 sec: understand movement/gathering;
- first minute: first satisfying deposit/growth;
- 1–2 min: first building / first important choice;
- Night 1: readable test;
- Day 2: build starts forming;
- Night 2: consequences + synergy matter;
- Day 3: final preparation;
- Night 3: Guardian climax.

No new system should be added if the player cannot understand why it matters inside this rhythm.

### 16. v1.25 implementation package

This version specifically focuses on:
1. Living World visual grammar.
2. Direction-aware Wanderer motion.
3. More physical automatic harvesting feedback.
4. Hearth Growth with visible stages.
5. Warm safety territory around the Hearth.
6. Cleaner resource composition around the starting area.
7. Stronger enemy silhouette/movement differentiation.
8. Cleaner day/night transition and Hearth night readability.
9. HUD cleanup for gameplay-critical information.
10. CI regression coverage for Hearth Growth, automatic harvesting identity and living-world visual contracts.

### 17. Acceptance criteria for v1.25

A build is accepted when:
- the player can stand near a tree and visibly understand that orbiting weapons are harvesting it automatically;
- destroyed resources visibly fly toward the player;
- returning home visibly transfers carried resources;
- after enough deposits, the Hearth visibly grows at least twice during a successful run;
- Hearth growth changes a small gameplay property and is not cosmetic only;
- a screenshot without UI still clearly shows: Wanderer, Hearth, resources and approaching enemies;
- normal/runner/brute/stalker/guardian silhouettes remain distinguishable;
- late-run Buildcraft effects remain readable on top of the new art;
- the starting area remains soft/pleasant rather than cluttered;
- all existing regression tests pass;
- a dedicated v1.25 living-world regression test passes;
- Web build exports and deploys successfully.

### 18. Longer roadmap after v1.25

v1.26 — Guardian Climax
- multi-phase regional bosses;
- arena pressure;
- boss-specific interaction with builds/buildcraft;
- strong victory transition.

v1.27 — Replay Desire / Collection
- run history;
- discovered relic collection;
- silhouettes of undiscovered items;
- meaningful unlock conditions;
- deeper camp resident progression.

v1.28 — Release Calibration
- run duration audit;
- choice frequency audit;
- difficulty curves;
- device performance;
- retention/onboarding metrics;
- economy/reward balance;
- final mobile release UX.

Monetization stays secondary until the player naturally wants another run.
