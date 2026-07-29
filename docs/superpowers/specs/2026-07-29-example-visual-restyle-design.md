# Example Visual Restyle

## Goal

Make the interactive example visually distinct from its current warm
operations-app-inspired treatment without changing its functionality, content,
layout, timing, or interaction behavior.

## Scope

The change is limited to the example application under `example/`. The package
API and the capsule toast implementation remain unchanged.

The example will adopt a cool blue/slate visual direction:

- Replace the warm beige page background with a pale blue-gray background.
- Replace warm cream supporting surfaces with crisp white and cool slate-tinted
  surfaces.
- Replace brown text colors with navy and slate equivalents that preserve
  readable contrast.
- Replace amber and sage accents with indigo and teal equivalents.
- Restyle control-panel buttons with a 10 px corner radius and a visible
  1.5 px blue-gray border. Secondary buttons use a light surface and darker
  outline; primary buttons keep a dark fill and gain a contrasting outline.

## Architecture

Palette changes belong in `example/lib/lab/lab_tokens.dart`, which already
centralizes the example's shared colors. The button-border treatment belongs in
`LabButton` in `example/lib/lab/lab_panel.dart`.

No callback, state, animation, layout, label, semantic, or package-level code
will change. Dark-mode switching remains supported. The phone preview continues
to use the example background token in light mode and its existing dark-mode
surface treatment in dark mode.

## Verification

- Update or add focused widget assertions for the new background and button
  decoration.
- Run the example widget tests.
- Run static analysis for the example.
- Format changed Dart files.

## Success Criteria

- The example reads as a cool blue/slate design rather than a warm
  beige/brown design.
- Primary and secondary buttons both have visibly changed borders.
- The page background and supporting surface colors are changed cohesively.
- Existing controls and toast demonstrations behave exactly as before.
