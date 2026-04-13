# xyz_lib

Standalone FiveM UI library with clean visuals, simple exports and low overhead.

Includes:

- Notify
- Progress Bar
- Text UI

No framework required.

---

## Installation

Make sure `xyz_lib` starts before any resource that uses it.

```cfg
ensure xyz_lib
```
## EXPORTS
**Notify**

```
exports['xyz_lib']:Notify({
    title = 'TITLE',
    description = 'Text...',
    type = 'info',
    duration = 4000
})
```
```
exports['xyz_lib']:Success('Done')
exports['xyz_lib']:Error('Error')
exports['xyz_lib']:Info('Info')
exports['xyz_lib']:Warning('Warning')
```
**Progress Bar**
```
local finished = exports['xyz_lib']:Progress({
    title = 'SEARCHING',
    label = 'Checking vehicle...',
    duration = 5000,
    canCancel = true,
    disableMovement = true,
    disableCarMovement = true,
    disableMouse = false,
    disableCombat = true
})
```
```
local active = exports['xyz_lib']:IsProgressActive()
exports['xyz_lib']:CancelProgress()
```
**TEXT UI**
```
exports['xyz_lib']:ShowTextUI({
    key = 'E',
    text = 'Open storage',
    subtext = 'Press to interact',
    position = 'right',
    accent = '#8a2bff'
})
```
```
exports['xyz_lib']:UpdateTextUI({
    key = 'G',
    text = 'Pick up weapon',
    subtext = 'Ground item',
    position = 'left',
    accent = '#8a2bff'
})
```
```
exports['xyz_lib']:HideTextUI()
local visible = exports['xyz_lib']:IsTextUIVisible()
local pressed = exports['xyz_lib']:WasTextUIPressed()
```
