
## UI quality bar (applies to every milestone)

Visual quality is a first-class requirement, not end-of-project polish. Every new component must pass the question: could Apple ship this in a premium first-party app?

- Typography is clean and readable, with clear hierarchy. Spacing and alignment are precise and use the tokens.
- Cards, controls, and navigation form one coherent visual system. Corner radii, borders, shadows, materials, and opacity are deliberate.
- Colors feel sophisticated, not generic. Avoid random colors and excessive gradients.
- Dark Mode is the preferred primary experience and must feel premium and atmospheric, not "black background plus colored cards". Light Mode must still look excellent.
- Glass/material is used only where it genuinely improves the interface (for example the floating Add Food button), with a solid fallback for Reduce Transparency.
- Rings, charts, and bars look refined and balanced, not like default system controls.
- Icons (SF Symbols) are chosen for meaning, visual weight, and consistency.
- Animations are subtle, smooth, and purposeful, and are skipped when Reduce Motion is on.
- Accessibility is never traded for visual effect: VoiceOver, Dynamic Type, contrast, 44 pt targets, and color-independent meaning.
- Prefer the more elegant solution when it adds no unnecessary complexity. Avoid decoration for its own sake.

## Milestone 5 additions

- Components: `CalorieRing`, `EmptyState`, `FloatingAddButton` (glass capsule with a solid Reduce Transparency fallback).
- Macros are shown as text-labeled columns that stack into rows at large Dynamic Type sizes.

## UI quality bar (applies to every milestone)

Visual quality is a first-class requirement, not end-of-project polish. Every new component must pass the question: could Apple ship this in a premium first-party app?

- Typography is clean and readable, with clear hierarchy. Spacing and alignment are precise and use the tokens.
- Cards, controls, and navigation form one coherent visual system. Corner radii, borders, shadows, materials, and opacity are deliberate.
- Colors feel sophisticated, not generic. Avoid random colors and excessive gradients.
- Dark Mode is the preferred primary experience and must feel premium and atmospheric, not "black background plus colored cards". Light Mode must still look excellent.
- Glass/material is used only where it genuinely improves the interface (for example the floating Add Food button), with a solid fallback for Reduce Transparency.
- Rings, charts, and bars look refined and balanced, not like default system controls.
- Icons (SF Symbols) are chosen for meaning, visual weight, and consistency.
- Animations are subtle, smooth, and purposeful, and are skipped when Reduce Motion is on.
- Accessibility is never traded for visual effect: VoiceOver, Dynamic Type, contrast, 44 pt targets, and color-independent meaning.
- Prefer the more elegant solution when it adds no unnecessary complexity. Avoid decoration for its own sake.

## Milestone 5 additions

- Components: `CalorieRing`, `EmptyState`, `FloatingAddButton` (glass capsule with a solid Reduce Transparency fallback).
- Macros are shown as text-labeled columns that stack into rows at large Dynamic Type sizes.

## Indigo Dusk palette (Phase 2)

- Dark Mode uses a deep ink-indigo base with indigo-tinted surfaces and warm ivory text. Light Mode uses warm ivory with ink-indigo text.
- The accent is a restrained ember (terracotta), used for interactive and emphasis elements only.
- Fiber has its own color token (olive in Light, sage in Dark), distinct from protein, carbs, and fat, and is always shown with a text label.
- Contrast is enforced by `DesignSystemContrastTests`, including Fiber. If a color fails, change the color, not the standard.
- Phase 2 changes color tokens only. Background depth, hairline card edges, the refined ring, and the glass treatment arrive in later phases.

## Dark Mode refinement (Phase 2 adjustment)

- The dark base is now a near-black ink with only a faint indigo cast, replacing the more saturated navy. Surfaces are separated by small tonal steps, not by visible blue.
- The accent is an antique copper (more amber and less salmon) so interactive elements feel integrated with the dark palette. It is used sparingly.
- Light Mode values are unchanged.
- Known follow-ups: the over-target ring switches from the copper accent to the amber warning color and the two are close, and the Light accent is redder than the Dark accent. Both are for the ring and brand work in later phases.
