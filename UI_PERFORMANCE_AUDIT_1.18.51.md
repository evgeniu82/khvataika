# Хватайка 1.18.51 — UI Performance Audit

- Vertical and horizontal scrollbars: 5px, unified brown style.
- Gameplay 3D simulation is suspended while any UI panel/modal is open; workshop jobs and UI timers continue.
- Workshop, collection and achievement lists are prebuilt/cached so reopening does not mass-create/free Controls.
- Achievement refresh updates existing rows instead of queue_free/add_child.
- Removed duplicate per-frame remote auth timer decrement.
- No gameplay content, windows or menu sections were removed.
