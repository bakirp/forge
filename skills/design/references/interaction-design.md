<!-- Adapted from pbakaus/impeccable (Apache 2.0). Substantially rewritten for FORGE. -->
<!-- last-reviewed: 2026-04 -->

# Interaction Design Reference

Actionable interaction patterns for `/design-audit` and design skills that define component behavior.

## Eight Interactive States

Every interactive component must define all applicable states:

| State | Visual treatment | Notes |
|-------|-----------------|-------|
| **Default** | Resting appearance | The baseline. Must be clearly interactive (affordance). |
| **Hover** | Subtle change — color shift, elevation, underline | Only on pointer devices. Use `@media (hover: hover)`. |
| **Focus** | Visible ring or outline | Required for keyboard accessibility. Use `:focus-visible`. |
| **Active / Pressed** | Compressed or depressed — scale down, darken | Brief (100-150ms). Must feel responsive. |
| **Disabled** | Reduced opacity (0.4-0.5), no pointer events | Include `aria-disabled="true"`. Tooltip explaining why is better than silent gray. |
| **Loading** | Spinner, skeleton, or progress indicator | Replace the action label, not the whole component. Keep layout stable. |
| **Error** | Red border, icon, inline message | Never color alone. Provide text explanation + next step. |
| **Success** | Green indicator, checkmark, confirmation | Brief (auto-dismiss after 3-5s) or persistent based on importance. |

**Not every state applies to every component.** A static card has no disabled state. A toggle has no loading state. Apply the states that are semantically meaningful.

## Focus Management

### Focus Rings

```css
:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}

/* Remove outline for mouse clicks, keep for keyboard */
:focus:not(:focus-visible) {
  outline: none;
}
```

- Width: 2-3px
- Offset: 2px (so it does not overlap the element)
- Color: high contrast against the background (not brand color if it is low contrast)
- Shape: follows the element's border-radius

### Focus Order

- Matches visual reading order (top-to-bottom, leading-to-trailing)
- No `tabindex` values greater than 0 — they break natural flow
- Skip links at the top of the page: `<a href="#main" class="skip-link">Skip to content</a>`
- After dynamic content insertion (modal open, toast, inline error), move focus to the new content

### Focus Trapping

Modals and dialogs must trap focus within themselves:

```html
<dialog>  <!-- Native dialog traps focus automatically -->
  <form method="dialog">
    <button>Close</button>
  </form>
</dialog>
```

Prefer native `<dialog>` over custom implementations. It handles focus trapping, backdrop, escape key, and `inert` on background content.

## Form Patterns

### Labels

- Every input has a visible `<label>` associated via `for`/`id`
- Placeholders are NOT labels — they disappear on input
- Required fields: mark with `*` or "(required)". Prefer marking optional fields as "(optional)" when most fields are required

### Validation

| Timing | When to use |
|--------|-------------|
| **On blur** | Default for most fields. Validates when user leaves the field. |
| **On input** | Only for format feedback (character count, password strength). |
| **On submit** | Last resort. Scrolls to first error, focuses it. |

Never validate on focus (user has not typed yet). Never validate required fields as empty while user is still on the page for the first time.

### Error Messages

Formula: **What happened** + **Why** + **How to fix**

```
✗ Email address is invalid. Enter a valid email like name@example.com.
✗ Password must be at least 8 characters. You entered 5.
✗ This email is already registered. Log in instead or reset your password.
```

Bad: "Invalid input." "Error." "Please try again."

### Error Announcement

Use `aria-live="polite"` for inline validation errors so screen readers announce them:

```html
<input aria-describedby="email-error" aria-invalid="true">
<p id="email-error" role="alert">Email address is invalid.</p>
```

## Modals & Dialogs

### Use Native `<dialog>`

```javascript
const dialog = document.querySelector('dialog');
dialog.showModal();  // modal with backdrop
dialog.show();       // non-modal
dialog.close();      // closes
```

Benefits: automatic focus trapping, `Escape` to close, `::backdrop` styling, `inert` on background.

### Modal Rules

- Close on Escape key (native `<dialog>` does this)
- Close on backdrop click (add handler)
- Return focus to trigger element on close
- Heading as first content (screen readers announce it)
- No nested modals — use progressive disclosure instead

## Popover API

For tooltips, dropdowns, and non-modal overlays:

```html
<button popovertarget="menu">Options</button>
<div id="menu" popover>
  <!-- dropdown content -->
</div>
```

Benefits: auto-dismissal on outside click, escape key, top-layer rendering (no z-index issues), accessible by default.

## Destructive Actions

**Prefer undo over confirm.** A confirmation dialog ("Are you sure?") is muscle-memory-defeated — users click "Yes" without reading. Undo is safer:

```
✓ "Item deleted. Undo (5s)"     — user can recover without interruption
✗ "Are you sure?" → "Yes"       — user clicks through reflexively
```

When undo is impossible (data permanently destroyed, external side effects), use a confirmation that requires deliberate input: type the item name, or a short delay before the confirm button activates.

## Touch & Pointer

### Touch Targets

Minimum: 44×44px (CSS pixels). Apply to:
- Buttons, links, toggles, checkboxes, radio buttons
- Close buttons on modals and toasts
- Navigation items
- List items that are clickable

Small visual elements can have large tap targets via padding or `::after` pseudo-elements.

### Input Method Detection

```css
/* Hover effects only for pointer devices */
@media (hover: hover) and (pointer: fine) {
  .card:hover { ... }
}

/* Larger targets for coarse pointers (touch) */
@media (pointer: coarse) {
  .action-button { min-height: 48px; }
}
```

## Keyboard Shortcuts

- Discoverable: show in tooltips or a help modal
- Do not override browser/OS shortcuts
- Provide visual feedback when a shortcut fires
- Use `roving tabindex` for composite widgets (tab groups, toolbars, menus): Tab enters the group, arrow keys navigate within

## Anti-Pattern Checklist

- [ ] No `<div>` or `<span>` as interactive elements — use `<button>`, `<a>`, `<input>`
- [ ] No `outline: none` without `:focus-visible` replacement
- [ ] No disabled zoom (`user-scalable=no`, `maximum-scale=1`)
- [ ] No disappearing input labels (placeholder as sole label)
- [ ] No validation only on submit — validate on blur
- [ ] No confirmation dialogs for reversible actions — use undo
- [ ] No custom modal implementations when `<dialog>` is available
- [ ] No `tabindex > 0`
- [ ] All interactive elements reachable by keyboard
- [ ] All error messages include what happened + how to fix
