# AXEHOLD v1.8 — Weapon Identity

## Goal
Make weapon selection change how the player moves through danger instead of changing only four stat bars.

Each weapon now owns a distinct automatic combat grammar, exclusive run perks, visual feedback, sound identity and persistent mastery track.

## Four combat identities

### Wanderer Axes — Circle Control
The original orbit remains the baseline weapon:
- continuous damage to every enemy inside the orbit;
- no attack cooldown;
- benefits most from keeping several enemies in the control ring;
- exclusive perks expand and intensify the whirl.

Signature: **Whirl**.

### Root Spear — Line & Pierce
The Spear no longer behaves like a long-radius orbit:
- selects the nearest target in front;
- performs discrete automatic thrusts;
- damages enemies aligned along the thrust line;
- pierces up to three targets before perks/mastery;
- enemies outside the line are not hit;
- visible thrust trail, action pose and unique sound.

Signature: **Root Thrust**.

### Frost Hammer — Burst Slam
The Hammer becomes a deliberate slow rhythm:
- waits for an enemy to enter slam range;
- damages every enemy in the circular impact zone;
- knocks normal enemies away from the hero;
- has the longest attack cooldown;
- gains readable frost shockwave FX and heavy audio/haptic feedback.

Signature: **Frost Fracture**.

### Ash Twin Blades — Risk & Combo
Twin Blades are now the close-range aggression weapon:
- rapid discrete attacks;
- strike up to two nearby enemies;
- every successful attack builds combo;
- combo increases subsequent attack damage;
- disengaging for too long resets combo;
- combo is surfaced around the hero;
- exclusive perks extend the chain and increase its scaling.

Signature: **Ash Sequence**.

## Weapon-exclusive level-up perks
Every level-up offer now guarantees one perk for the currently equipped weapon.

Current exclusive pool:
- Axes: Dense Whirl / Wide Edge;
- Spear: Branching Root / Deep Impale;
- Hammer: Wide Crater / Frozen Core;
- Twin Blades: Long Sequence / Sequence Heat.

This means run progression reinforces the selected weapon instead of offering the same generic build every time.

## Persistent Weapon Mastery
Every completed expedition now records runs, victories and kills for the equipped weapon.

Mastery ranks from I to V and is displayed in the Arsenal.

Mechanical milestones:
- Axes II: +4 Whirl radius;
- Axes IV: +8% Whirl damage;
- Spear II: +1 pierced target;
- Spear IV: -8% thrust cooldown;
- Hammer II: +6 slam radius;
- Hammer IV: +8% slam damage;
- Twin Blades II: +1 combo cap;
- Twin Blades IV: +0.12 s combo retention.

Rank V is a prestige milestone for the current weapon identity and leaves room for future evolution/cosmetics.

## Arsenal redesign
The Arsenal now communicates:
- weapon philosophy;
- signature attack;
- mechanical role;
- real attack rhythm and range;
- animated preview;
- mastery stars;
- current mastery bonus;
- next mastery milestone.

The intent is that the player can understand why they would choose a weapon before entering a run.

## Audio / haptics
Spear, Hammer and Twin Blades now have different synthetic attack feedback rather than sharing the generic hit tone.

## Balance intent
No weapon should be a strictly better progression tier.

- Axes = safest all-purpose crowd control.
- Spear = safest distance and lane control, weaker when surrounded.
- Hammer = strongest burst/space reset, weakest cadence.
- Twin Blades = highest aggression scaling, highest positioning risk.

## Definition of done
v1.8 is complete when:
- four weapons use four different runtime resolvers;
- Spear line pierce is verified;
- Hammer radial damage and knockback are verified;
- Twin Blade combo build/decay is verified;
- Axes retain continuous orbit identity;
- each weapon has exclusive perks;
- persistent mastery survives save migration;
- Arsenal shows identity, signature and mastery;
- dedicated v1.8 regression passes together with all previous tests.
