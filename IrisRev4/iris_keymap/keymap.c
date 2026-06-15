#include QMK_KEYBOARD_H

enum layers {
    _BASE,
    _LOWER,
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
        KC_GRV,  KC_1,    KC_2,    KC_3,    KC_4,    KC_5,                      KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_MINS,
        KC_TAB,  KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,                      KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_BSLS,
        MT_ESC,  KC_A,    KC_S,    KC_D,    KC_F,    KC_G,                      KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT,
        KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,                      KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, KC_RCTL,
                                   KC_SPC,  KC_BSPC, KC_LBRC, KC_LGUI, LT_ENT, KC_LALT, KC_RBRC, KC_LGUI
    ),

    /* LOWER LAYER — Mouse (left) + Numpad (right)
     * ,--------------------------------------------.                    ,--------------------------------------------.
     * |      |      |      |      |      |        |                    |      |      |      |      |      |        |
     * |------+------+------+------+------+---------|                    |------+------+------+------+------+--------|
     * |      |      |      |MsUp  |      | =/+    |                    |  +   |  7   |  8   |  9   |      |        |
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
        RGB_TOG, _______, _______, _______, _______, _______,                   _______, _______, _______, _______, _______, _______,
        RGB_MOD, _______, _______, KC_MS_U, _______, MT(MOD_LSFT, KC_EQL),     KC_PLUS, KC_7,    KC_8,    KC_9,    _______, _______,
        KC_BTN1, KC_MS_L, KC_BTN3, KC_MS_R, _______, KC_BTN2,                  _______, KC_4,    KC_5,    KC_6,    _______, _______,
        _______, _______, _______, KC_MS_D, _______, MT(MOD_LSFT, KC_MINS),    KC_PLUS, KC_1,    KC_2,    KC_3,    KC_PLUS, _______,
                                   _______, _______, _______, KC_LGUI, _______, KC_DOT,  KC_0,    _______
    ),
};

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
