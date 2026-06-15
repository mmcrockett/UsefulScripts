#pragma once

// ─── Hold-tap timing ──────────────────────────────────────────────────────────
#define TAPPING_TERM 200

// ─── RGB underglow ────────────────────────────────────────────────────────────
#define RGBLIGHT_LAYERS

// ─── Auto Shift ───────────────────────────────────────────────────────────────
#define AUTO_SHIFT_TIMEOUT 160

// ─── Mouse keys ───────────────────────────────────────────────────────────────
#ifdef MOUSEKEY_ENABLE
    #define MOUSEKEY_INTERVAL       25
    #define MOUSEKEY_DELAY          0
    #define MOUSEKEY_TIME_TO_MAX    40
    #define MOUSEKEY_MAX_SPEED      5
    #define MOUSEKEY_WHEEL_DELAY    0
#endif
