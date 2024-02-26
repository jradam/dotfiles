import time
from winput import (
    VK_2, VK_4, VK_7, VK_A, VK_B, VK_BACK, VK_C, VK_DELETE, VK_DOWN, VK_E, VK_F, VK_F13, VK_G, VK_H, VK_I, VK_J, VK_K, VK_L, VK_LEFT, VK_M, VK_N, VK_OEM_1, VK_OEM_4, VK_OEM_6, VK_OEM_MINUS, VK_OEM_PLUS, VK_Q, VK_RETURN, VK_RIGHT, VK_S, VK_SHIFT, VK_UP, VK_X, VK_D, VK_9, VK_0, VK_LSHIFT, press_key, release_key, hook_keyboard, wait_messages, KeyboardEvent, WP_DONT_PASS_INPUT_ON, WM_KEYDOWN, WM_KEYUP, WP_UNHOOK, WP_STOP
)

# KeyChef adds a new keyboard layer, accessed by holding the activate_key (default `;`)
# It can also send an on_activate key (default `F13`)

# TODO: add user configuration
# TODO: package as an exe
# TODO: mouse movement

# USER SETTINGS HERE

activate_key = VK_OEM_1
on_activate = VK_F13

# END USER SETTINGS

cooking, shifted, sending_replacement = False, False, False
last_key_time, last_key = 0, None


def toggle_cooking(event: KeyboardEvent):
    global cooking
    if event.action == WM_KEYDOWN:
        cooking = True
        press_key(on_activate)
    elif event.action == WM_KEYUP:
        cooking = False
        release_key(on_activate)
    return WP_DONT_PASS_INPUT_ON


def toggle_shifted(event: KeyboardEvent):
    global shifted
    if event.action == WM_KEYDOWN:
        shifted = True
    elif event.action == WM_KEYUP:
        shifted = False


def hit(key):
    press_key(key)
    release_key(key)


def shift_hit(key):
    press_key(VK_SHIFT)
    hit(key)
    release_key(VK_SHIFT)


def press(key, shift=False):
    if shift == True:
        shift_hit(key)
    else:
        hit(key)


def double(key1, key2):
    global last_key_time, last_key
    current_time = time.time()
    if last_key == key1[0] and (current_time - last_key_time) < 0.2:
        hit(VK_BACK)
        press(*key2)
    else:
        press(*key1)
    last_key_time = current_time
    last_key = key1[0]


def activate_replacement():
    global sending_replacement
    sending_replacement = True
    hit(activate_key)
    sending_replacement = False


def handle_ingredients(event: KeyboardEvent):
    global sending_replacement
    key_map = {
        VK_F: lambda: double((VK_OEM_4, True), (VK_OEM_6, True)),
        VK_D: lambda: double((VK_9, True), (VK_0, True)),
        VK_S: lambda: double((VK_OEM_4, False), (VK_OEM_6, False)),
        VK_G: lambda: double((VK_OEM_MINUS, False), (VK_OEM_MINUS, True)),
        VK_A: lambda: press(VK_7, True),
        VK_M: lambda: press(VK_4, True),
        VK_I: lambda: press(VK_2, True),
        VK_E: lambda: press(VK_OEM_PLUS),
        VK_N: lambda: press(VK_RETURN),
        VK_B: lambda: press(VK_BACK),
        VK_X: lambda: press(VK_DELETE),
        VK_H: lambda: press(VK_LEFT),
        VK_J: lambda: press(VK_DOWN),
        VK_K: lambda: press(VK_UP),
        VK_L: lambda: press(VK_RIGHT),
        VK_C: lambda: activate_replacement(),
    }
    if event.action == WM_KEYDOWN:
        if event.vkCode == VK_Q:
            return WP_UNHOOK | WP_STOP
        action = key_map.get(event.vkCode)
        if action:
            action()
            return WP_DONT_PASS_INPUT_ON


def keyboard_callback(event: KeyboardEvent):
    if event.vkCode == VK_LSHIFT:
        return toggle_shifted(event)
    if event.vkCode == activate_key and not shifted and not sending_replacement:
        return toggle_cooking(event)
    elif cooking:
        return handle_ingredients(event)


hook_keyboard(keyboard_callback)
wait_messages()
