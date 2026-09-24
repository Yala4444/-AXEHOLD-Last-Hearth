# AXEHOLD — Production Lock

This file is the implementation lock for the post-concept production pass.

## Core gameplay lock

- Mobile-first.
- Movement is controlled by the dynamic left-side joystick.
- The hero does **not** use a permanent manual attack button.
- Weapons are separate orbiting gameplay objects.
- 1–5 orbiting weapons is the supported visual range.
- Level-up and other important modal choices pause gameplay.
- Contextual interaction appears only near the relevant object.

## Hero lock

- One hero identity across every direction and state.
- Same scale, foot pivot and silhouette in all orientations.
- Idle is a true planted stance: no walking pose, no foot lift.
- Contact shadow is always present.
- Production gameplay must never mix alternate hero designs.

## World lock

- The forest is calm enough for mobile readability.
- Decorative density stays below concept-art density.
- No repeated poster-like background tiles or visible seams.
- Trees, rocks, ore, buildings and characters must visibly contact the ground.
- Paths guide movement but stay soft and secondary.
- Resource clusters must leave navigation space.

## Base lock

- Hearth -> camp -> fortified camp. Do not grow into a city.
- Build pads are contextual and visually quiet until approached.
- The hearth remains the visual center of the base.

## HUD lock

Persistent gameplay HUD is limited to:
- hero HP / XP / level,
- day/night progress,
- key resources,
- one short objective,
- pause.

No permanent attack / heavy / dodge / block buttons.
No permanent minimap.

## Combat lock

- Readable enemy silhouettes.
- Short telegraphs and short hit FX.
- Effects explain actions and disappear immediately.
- No permanent weapon trails, giant glows or particle storms.

## Source priority

1. This production lock.
2. Correction pass C1–C7.
3. Approved production sprite sheets.
4. Earlier concept sheets only as non-binding reference.

If an older asset or implementation conflicts with this document, the older version is rejected.
