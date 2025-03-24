# Video

## Web

https://github.com/user-attachments/assets/afa93214-9bb3-4c3c-8881-bdafc223a7c6

## Mobile

### Time Investigating: 6:30h;

## Popup Positioning in Multiline TextFormField

This document explains why one implementation of a popup overlay works correctly in a multiline TextFormField, while another does not. The issue revolves around the dynamic positioning of the popup relative to the cursor in a multiline text field.

This fixed version ensures that the suggestions always appear directly below the cursor, no matter how many lines the text spans.

### Dynamic Positioning with CompositedTransformFollower:

The CompositedTransformFollower widget is used to link the overlay to the TextFormField. This ensures that the overlay follows the text field even when its size or position changes.

This combination enables dynamic positioning of the overlay, regardless of:

- Number of lines
- Scroll position
- Text wrapping

CompositedTransformFollower allows the popup to be "anchored" to a widget — in this case, the TextFormField.

The position is calculated relative to the widget using Offset(dx, dy) — from the actual caret (cursor).

The caret position is retrieved directly from the RenderEditable, which accurately reflects the cursor position even with wrapping, line breaks, and scrolling.

### Broken Version: Manual Positioned with textFieldOffset

- textFieldOffset is the global offset of the entire TextFormField, not the caret.

- caretOffset is calculated using TextPainter, which does not account for automatic line wrapping inside the real render object (RenderEditable).

- When the text wraps, the caret moves to a new line — but this approach never gets the updated position correctly because it treats the entire field as a static box.

### RenderEditable.getLocalRectForCaret

- RenderEditable is the real engine behind the visible TextFormField
- It tracks line breaks, cursor movement, and even internal scroll
- Using extent ensures the popup always aligns with the visible side of a selection or cursor

Always anchor to the caret, not the widget
Avoid manually calculating global positions
Prefer RenderEditable.getLocalRectForCaret(...) for pixel-perfect cursor position
Use CompositedTransformFollower to attach the popup dynamically to the editable area
