# AXEHOLD VG-8 — Quality Sprint

Goal: resolve the current iPhone feedback in one coherent pass while keeping the gameplay baseline intact.

## Scope

1. Hero idle
- Stop using an obvious mid-stride pose as the default rest state.
- No walk transition or body lean while velocity is zero.
- Keep only a tiny breathing offset.

2. Buildcraft correctness
- “Вихрь стали / +1 вращающееся оружие” must visibly and mechanically add a weapon for Axes and Twin Blades.
- Never offer that card to Spear/Hammer where it would have no visible effect.
- Twin Blade target count must follow the added visible blade count.

3. Buildcraft readability
- Common = neutral/silver.
- Rare = cyan/blue.
- Epic = violet.
- Legendary = gold.
- A choice that closes 3/3 uses a stronger gold state and explicitly says which evolution will unlock.
- The modal explains the color language in one short line.

4. Rare ore
- Replace the purple procedural placeholder in Forgotten Forest Visual Gate with the painted ore-deposit asset.
- Keep a restrained violet glow and a readable label.
- Preserve gameplay timing/reward.

5. Enemy scale
- Slightly increase non-boss enemy readability on phone.
- Boss scale is not inflated.

6. Regression gates
- Level-up/modal freeze from VG-7 remains intact.
- Stable non-Visual-Gate expedition remains unchanged.
- Existing hero scale/foot baseline, hearth, dusk/night, camera, HUD and combat-FX tests continue to pass.

## Acceptance

The pass is accepted when:
- a stationary hero visibly settles;
- taking +1 rotating weapon changes both the rendered count and the Twin Blade combat target count;
- rarity can be identified before reading the first word;
- 3/3 reads as a completed evolution choice;
- rare ore belongs to the same painted forest language;
- normal enemies remain readable beside the 98px hero;
- all CI smoke/regression tests pass.
