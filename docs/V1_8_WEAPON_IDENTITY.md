# AXEHOLD v1.8 — Weapon Identity

## Goal
Weapon choice must change how the player moves, positions and reads danger. The four weapons can no longer be the same circular DPS system with different percentages.

Controls remain one-thumb and attacks remain automatic. Skill comes from movement and positioning.

## Combat identities

### Wanderer Axes — Circle Control
- Continuous orbit damage.
- Hits every enemy inside the orbit.
- Best at holding a compact area and clearing groups.
- Exclusive perks can enlarge the orbit or strengthen the Whirl.

### Root Spear — Line & Pierce
- No radial damage.
- Automatically aims at the nearest valid enemy.
- Fires a long Root Thrust on a discrete rhythm.
- The thrust pierces up to three enemies aligned behind the first target.
- Exclusive perks increase pierce count or thrust damage.

### Frost Hammer — Burst & Knockback
- No continuous orbit DPS.
- Waits for an enemy to enter slam range.
- Periodically creates an Ice Fracture around the hero.
- Hits all nearby enemies in one burst and knocks them away.
- Exclusive perks enlarge the crater or increase slam damage.

### Ash Twin Blades — Risk & Combo
- Very short attack range.
- Rapid discrete strikes can hit the two closest targets.
- Successful continued aggression builds a combo.
- Each combo level increases following strike damage.
- Leaving combat drops the combo.
- Exclusive perks extend combo cap or increase damage per stack.

## Harvesting identity
The gathering loop also respects the weapon:
- Axes and Hammer can work several nearby resource nodes.
- Spear focuses one nearest node despite its long reach.
- Twin Blades focus up to two nearby nodes.
- Each weapon has an independent harvesting multiplier so combat balance does not automatically dominate gathering balance.

## Weapon-exclusive perks
Level-up choices can now surface one perk tied to the equipped weapon. Generic offense/survival/utility options remain in the same choice.

Current exclusive perks:
- Axes: Dense Whirl, Wide Rim.
- Spear: Forked Root, Deep Impale.
- Hammer: Wide Crater, Frozen Core.
- Twin Blades: Long Chain, Heat of the Chain.

## Presentation
- Arsenal now shows combat identity, signature and attack rhythm.
- Spear has a visible thrust line.
- Hammer produces a circular slam shockwave.
- Twin Blades show their combo around the hero.
- Preview animations now communicate Spear line play, Hammer slam and Twin-Blade combo rather than generic orbiting.

## Analytics
Run start/end now include selected weapon so completion, failure and duration can later be compared by weapon.

## Definition of done
v1.8 is complete when:
- all four weapons use different combat resolvers;
- Spear is directional and piercing, not radial;
- Hammer is periodic AoE with knockback;
- Twin Blades build and lose combo;
- Axes preserve reliable continuous circle control;
- weapon-exclusive perks affect runtime mechanics;
- harvesting target patterns differ by weapon;
- Arsenal explains the identity before the player enters a run;
- all previous regressions remain green.
