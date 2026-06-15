#include QMK_KEYBOARD_H

enum layers {
    _BASE,
    _LOWER,
};

enum custom_keycodes {
    K_EQL_PLUS = SAFE_RANGE,   // tap: =, hold: +
    K_MINS_UNDS,               // tap: -, hold: _
};

// Tap = Escape, Hold = Left Ctrl
#define MT_ESC  MT(MOD_LCTL, KC_ESC)
// Tap = Enter, Hold = LOWER layer
#define LT_ENT  LT(_LOWER, KC_ENT)

const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {

    /* BASE LAYER
     * ,--------------------------------------------.                    ,--------------------------------------------.
     * |  ` ~ |  1   |  2   |  3   |  4   |  5     |                    |  6   |  7   |  8   |  9   |  0   |  - _  |
     * |------+------+------+------+------+---------|                    |------+------+------+------+------+--------|
     * |  Tab |  Q   |  W   |  E   |  R   |  T     |                    |  Y   |  U   |  I   |  O   |  P   |  \ |  |
     * |------+------+------+------+------+---------|                    |------+------+------+------+------+--------|
     * |CT/ESC|  A   |  S   |  D   |  F   |  G     |                    |  H   |  J   |  K   |  L   |  ;   |  ' "  |
     * |------+------+------+------+------+---------|                    |------+------+------+------+------+--------|
     * | Shft |  Z   |  X   |  C   |  V   |  B     |                    |  N   |  M   |  ,   |  .   |  /   | RCtrl |
     * `--------------------------------------------/                    \--------------------------------------------'
     *              | Spc  | Bspc |  [{  | ENC  |                        | ENT▼ | LAlt |  ]}  | GUI  |
     *              |      |      |      | GUI  |                        | LWR  |      |      |      |
     *              `----------------------------------'              `----------------------------------'
     */
    [_BASE] = LAYOUT(
        KC_GRV,  KC_1,    KC_2,    KC_3,    KC_4,    KC_5,                               KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_MINS,
        KC_TAB,  KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,                               KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_BSLS,
        MT_ESC,  KC_A,    KC_S,    KC_D,    KC_F,    KC_G,                               KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT,
        KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,    KC_LGUI,         KC_RGUI,  KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, KC_RCTL,
                                            KC_SPC,  KC_BSPC, KC_LBRC,         KC_RBRC,  KC_RALT, LT_ENT
    ),

    /* LOWER LAYER — Mouse (left) + Numpad (right)
     * ,--------------------------------------------.                    ,--------------------------------------------.
     * |      |      |      |      |      |        |                    |      |      |      |      |      |        |
     * |------+------+------+------+------+---------|                    |------+------+------+------+------+--------|
     * |RGBMod|      |      |MsUp  |      | =/+    |                    |  +   |  7   |  8   |  9   |      |        |
     * |------+------+------+------+------+---------|                    |------+------+------+------+------+--------|
     * |LClick|MsLeft|MidClk|MsRght|      |RClick  |                    |      |  4   |  5   |  6   |      |        |
     * |------+------+------+------+------+---------|                    |------+------+------+------+------+--------|
     * |      |      |      |MsDn  |      | -/_    |                    |  +   |  1   |  2   |  3   |  +   |        |
     * `--------------------------------------------/                    \--------------------------------------------'
     *              |      |      |      | ENC  |                        |      |  .   |  0   |      |
     *              |      |      |      | ↑↓   |                        |      |      |      |      |
     *              `----------------------------------'              `----------------------------------'
     */
    [_LOWER] = LAYOUT(
        UG_TOGG, _______, _______, _______, _______, _______,                                       _______, _______, _______, _______, _______, _______,
        UG_NEXT, _______, _______, MS_UP,   _______, K_EQL_PLUS,                                   KC_PLUS, KC_7,    KC_8,    KC_9,    _______, _______,
        _______, MS_BTN1, MS_LEFT, MS_BTN3, MS_RGHT, MS_BTN2,                                       _______, KC_4,    KC_5,    KC_6,    _______, _______,
        _______, _______, _______, MS_DOWN, _______, K_MINS_UNDS,           _______,       _______, KC_PLUS, KC_1,    KC_2,    KC_3,    KC_PLUS, _______,
                                            _______, _______, _______,                    _______, KC_DOT,  KC_0
    ),
};

// Custom tap/hold: tap emits the unshifted key, hold emits the shifted key.
bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    static uint16_t eql_timer;
    static uint16_t mins_timer;
    switch (keycode) {
        case K_EQL_PLUS:
            if (record->event.pressed) {
                eql_timer = timer_read();
            } else {
                if (timer_elapsed(eql_timer) < TAPPING_TERM) {
                    tap_code16(KC_EQL);
                } else {
                    tap_code16(S(KC_EQL));   // shift+= → +
                }
            }
            return false;
        case K_MINS_UNDS:
            if (record->event.pressed) {
                mins_timer = timer_read();
            } else {
                if (timer_elapsed(mins_timer) < TAPPING_TERM) {
                    tap_code16(KC_MINS);
                } else {
                    tap_code16(S(KC_MINS));  // shift+- → _
                }
            }
            return false;
    }
    return true;
}

// Encoder: base layer = left/right arrows, lower layer = up/down arrows
bool encoder_update_user(uint8_t index, bool clockwise) {
    if (index == 0) { // Left encoder
        if (IS_LAYER_ON(_LOWER)) {
            tap_code(clockwise ? KC_DOWN : KC_UP);
        } else {
            tap_code(clockwise ? KC_RGHT : KC_LEFT);
        }
    }
    return false;
}
