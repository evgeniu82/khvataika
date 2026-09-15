# KHVATAIKA 1.18.49 — Brown UI Accent Audit

Base: 1.18.48.

## UI direction
- Brown remains the dominant interface color.
- Secondary accents are deliberately muted: terracotta, brass/olive gold, patina, dusty blue-grey and plum.
- Accents are used for semantic emphasis, not for recoloring gameplay content.
- Hover/focus/pressed states stay within the warm brown/gold family.

## Central implementation
- `scripts/main.gd`
- `apply_global_brown_ui_theme()` — global Godot control theme.
- `ui_accent()` — subdued accent normalization.
- `semantic_ui_accent()` — semantic color selection for buttons.
- `style_button()` — common button rendering.
- `style_check_button_brown()` / `style_option_button_brown()` — local control styles.
- `assets/ui_toggle_off.svg` and `assets/ui_toggle_on.svg` — brown toggle graphics.

Gameplay rarity/toy/material colors are intentionally not modified.
