# Iris Rev 4 — QMK Keymap

## Setup & compile

1. Copy this folder into your QMK keyboards directory:
   ```
   cp -r ~/UsefulScripts.mmcrockett/IrisRev4/iris_keymap ~/qmk_firmware/keyboards/keebio/iris/keymaps/mykeymap
   ```
2. Compile:
   ```
   qmk compile -kb keebio/iris/rev4 -km mykeymap
   ```
3. Flash (put keyboard into bootloader mode first, then flash each half separately):
   ```
   qmk flash -kb keebio/iris/rev4 -km mykeymap
   ```

---

## Layout — Base layer

### Left half
| Row        | Keys (outer → inner)                          |
|------------|-----------------------------------------------|
| Number     | `` ` ``~  1  2  3  4  5                       |
| Alpha      | Tab  Q  W  E  R  T                            |
| Home       | CT/ESC  A  S  D  F  G                         |
| Bottom     | Shift  Z  X  C  V  B                          |
| Thumb      | Space  Backspace  [{  Encoder (click=GUI)      |

### Right half
| Row        | Keys (inner → outer)                          |
|------------|-----------------------------------------------|
| Number     | 6  7  8  9  0  -_                             |
| Alpha      | Y  U  I  O  P  \|                             |
| Home       | H  J  K  L  ;:  '"                            |
| Bottom     | N  M  ,  .  /  RCtrl                          |
| Thumb      | ENT/LOWER  Alt  ]}  GUI                       |

### Encoder (left)
- Base layer: rotate = ← →
- Lower layer: rotate = ↑ ↓
- Click = GUI (⌘ on Mac, Super on Linux, Win on Windows)

---

## Layout — Lower layer
*To be filled in — currently all transparent (passes through to base layer)*

---

## Features
- **CT/ESC**: tap = Escape, hold = Left Ctrl
- **ENT/LOWER**: tap = Enter, hold = activate Lower layer
- **Auto Shift**: hold any key slightly longer (~175ms) to get its shifted version
- **Mouse keys**: available for use on lower layer

---

## Tuning tips
- Adjust `TAPPING_TERM` in `config.h` to change hold-tap sensitivity (CT/ESC and ENT/LOWER)
- Auto Shift timeout follows the same `TAPPING_TERM` value by default; override with `#define AUTO_SHIFT_TIMEOUT 200` in `config.h` if you want them independent
