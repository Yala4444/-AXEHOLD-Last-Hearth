# AXEHOLD v1.12 — Dynamic World & Elites

## Goal
Make expeditions feel less scripted and make the daytime map capable of producing urgent, combat-driven stories.

The world can now interrupt routine gathering with short events that create a real decision:
- keep farming;
- turn around and help;
- chase a rare target;
- accept the consequence of arriving too late.

## Daytime combat
Enemies are no longer restricted to the night wave system.

Dynamic-event enemies can exist during the day:
- they are valid auto-attack targets;
- they can chase and damage the hero;
- defenses can still help if an event reaches the camp;
- enemies attacking an event objective stay near that objective unless the hero closes in;
- failed event attackers become roaming threats and can survive into the night.

## Dynamic events
At most one major dynamic event is scheduled during each day phase.

### Caravan Under Attack
A caravan appears a short run away from the player with attackers already closing in.

Success:
- +14 run coins;
- rescued wood and stone;
- lower Darkness Threat;
- guaranteed follow-up clue to a hidden cache.

Failure:
- caravan is lost;
- Darkness Threat rises;
- surviving attackers remain in the world.

### Survivor Rescue
A survivor is surrounded by enemies, including a Ravenous elite.

The event has two stages:
1. clear the attackers;
2. physically return to the survivor and remain nearby long enough to secure them.

Success:
- +12 run coins;
- hero heal;
- +1 shield charge;
- rescue progression for quests and Field Journal.

### Elite Hunt
A rare elite target appears in the outer world.

The target must be hunted before the event timer expires.

Success:
- elite kill rewards;
- +18 run coins;
- Mechanism Part;
- reduced Darkness Threat.

### Ambush
Enemies spawn around the hero instead of at a distant objective.

The player has to survive and clear them quickly.

Success:
- +10 run coins;
- extra experience.

Failure:
- Darkness Threat rises;
- surviving attackers continue hunting the player.

## Chained events
Saving the caravan no longer ends the story immediately.

A clue points to a second location:
- a hidden cache appears 105–160 world units away;
- the player gets 22 seconds to reach it;
- reaching and securing it grants coins and ore;
- the chain is recorded separately for quests and long-term statistics.

This is the first true multi-stage world event in AXEHOLD.

## Elite enemies
Elite enemies are readable variants rather than simple hidden multipliers.

### Ravenous
- faster;
- more contact damage;
- moderate HP increase.

### Armored
- heavy HP increase;
- extra armor;
- slower movement.

### Distorted
- increased damage;
- increased speed;
- explodes on death if the hero is too close.

### Herald of Darkness
- mini-boss scale;
- high HP and damage;
- armor;
- telegraphed charge attack.

All elites have:
- gold/trait-colored aura;
- larger health bar;
- title above the enemy;
- stronger defeat feedback;
- bonus coins and XP;
- Mechanism Part reward.

## Persistent Field Journal
The Trophy screen now tracks:
- completed dynamic events;
- elite kills;
- rescues;
- chained-event completions.

Save version 10 stores these totals.

## Quest integration
New daily quest types:
- defeat elite enemies;
- rescue a survivor;
- finish several dynamic events;
- complete a chained event.

## Result screen
Expedition results now include:
- dynamic events completed;
- events failed;
- elite kills;
- rescues;
- chained events.

## Design rule
Dynamic events never open blocking story modals during normal gathering.
Urgency is communicated through:
- a short banner;
- local event marker;
- timer bar;
- nearby world action.

The player retains one-thumb movement throughout.

## Definition of done
v1.12 is complete when:
- enemies can fight the player during daytime events;
- every day can schedule one major dynamic event;
- caravan, rescue, hunt and ambush events all have success/failure states;
- caravan can branch into a second event;
- elites have visible trait identity and real mechanical differences;
- failed events affect Darkness Threat;
- surviving failed-event enemies remain dangerous;
- persistent Field Journal stats update;
- result screen reports dynamic-world performance;
- all previous regression suites remain green.
