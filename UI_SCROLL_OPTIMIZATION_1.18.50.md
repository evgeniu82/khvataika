# UI Scroll & Performance Optimization 1.18.50

- All ScrollContainer scrollbar widths standardized to 10px.
- Vertical and horizontal scrollbars use the same brown/copper/gold style.
- Achievement category horizontal scrollbar explicitly uses the shared style.
- Touch scrolling now supports both vertical and horizontal ScrollContainers and locks the axis after the gesture direction is established.
- Scroll target is captured at touch start, so buttons/labels inside a window do not steal the scroll gesture.
- Expensive visible-panel refreshes (season pass, rating, return bonus, promo) are throttled to once per second instead of every frame.
- Connection status label is no longer rewritten every frame.
- Gameplay animation and claw processing remain frame-based. No game content or UI elements were added/removed.

Primary source changed: `scripts/main.gd`.
