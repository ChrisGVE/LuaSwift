# UI Module

Present native alert and confirmation dialogs from Lua and block until the user responds.

## Overview

The UI module exposes native platform dialogs to Lua scripts: `NSAlert` on macOS and
`UIAlertController` on iOS/visionOS/tvOS/Mac Catalyst. Each call presents a dialog and blocks
the calling Lua code until the user dismisses it, returning the 1-indexed position of the button
that was pressed.

> Important:
> This module is **not** included in ``ModuleRegistry/install(in:)``. It requires UI
> framework access and a running main run loop, so it must be registered explicitly with
> ``UIModule/install(in:)``. It is unavailable on platforms without AppKit or UIKit.

## Installation

```swift
// The UI module is opt-in — it is NOT part of ModuleRegistry.install(in:).
try UIModule.install(in: engine)
```

## Basic Usage

```lua
local ui = require("luaswift.ui")

-- Simple alert (single OK button); returns 1
local result = ui.alert("Title", "Message")

-- Alert with custom buttons; returns the 1-indexed button number
local choice = ui.alert("Save?", "Changes will be lost.", {"Save", "Don't Save", "Cancel"})
if choice == 1 then
    -- Save was pressed
end

-- Confirmation dialog (action-sheet style on iOS; same as an alert on macOS)
local confirmed = ui.confirm("Delete?", "This cannot be undone.", {"Delete", "Cancel"})
```

## API Reference

### alert(title, message, buttons?)

Presents an alert dialog and blocks until the user responds.

**Parameters:**
- `title` (string) — the dialog title.
- `message` (string) — the dialog body text.
- `buttons` (table, optional) — the buttons to display. When omitted, a single `"OK"` button is
  shown. May be either an array of strings or an array of button-spec tables (see
  [Button Specifications](#Button-Specifications)).

**Returns:** the 1-indexed position of the button that was pressed (number).

### confirm(title, message, buttons?)

Identical to ``alert`` but presented as an action sheet on iOS (on macOS it behaves the same as
`alert`). Use it for confirmation choices such as Delete / Cancel.

**Parameters:** same as `alert`.

**Returns:** the 1-indexed position of the button that was pressed (number).

## Button Specifications

`buttons` accepts two forms:

```lua
-- 1. Array of strings (all default style)
ui.alert("Title", "Message", {"Yes", "No"})

-- 2. Array of {text, role} tables, to assign roles
ui.alert("Delete?", "This is permanent.", {
    {text = "Delete", role = "destructive"},
    {text = "Cancel", role = "cancel"},
})
```

Recognized roles:
- `"destructive"` — displayed in a red / destructive style.
- `"cancel"` — the keyboard cancel action (Escape on macOS).
- (no role) — a normal button.

The return value is the 1-indexed position of the pressed button in the `buttons` array.

> Note:
> On iOS, an action sheet can be dismissed without choosing an action (for example, an iPad
> popover dismissed by tapping outside it). In that case `alert`/`confirm` returns the index of
> the `"cancel"`-role button if one is present, otherwise `0` ("dismissed without selection").
> Always include a cancel button for action sheets so the result is unambiguous.

## Threading

The dialog must be presented on the main thread. When called from the main thread, the module
spins the run loop until the user responds (so it does not deadlock the thread that presents the
dialog); when called from a background thread it presents on the main thread and waits. Either
way the Lua call returns only after the user has dismissed the dialog.

## Platform Support

| Platform | Backend |
|----------|---------|
| macOS | `NSAlert` (modal) |
| iOS / iPadOS / visionOS / tvOS / Mac Catalyst | `UIAlertController` |

On platforms without AppKit or UIKit the module's calls raise a Lua error.

## See Also

- <doc:JSONModule>
