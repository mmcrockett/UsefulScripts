#pragma once

// ─── Hold-tap timing ──────────────────────────────────────────────────────────
#define TAPPING_TERM 200

// ─── Auto Shift ───────────────────────────────────────────────────────────────
// AUTO_SHIFT_TIMEOUT left at QMK default (175ms)
// Hold any key slightly longer than the threshold to get its shifted version

// ─── Mouse keys ───────────────────────────────────────────────────────────────
#ifdef MOUSEKEY_ENABLE
    #define MOUSEKEY_INTERVAL       20
    #define MOUSEKEY_DELAY          0
    #define MOUSEKEY_TIME_TO_MAX    40
    #define MOUSEKEY_MAX_SPEED      7
    #define MOUSEKEY_WHEEL_DELAY    0
#endif
