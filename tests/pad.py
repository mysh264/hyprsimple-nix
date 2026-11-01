"""A pretend touchpad and mouse for the VM test, made through /dev/uinput.
Each command plugs its device in, waits for the compositor to find it, acts,
and unplugs it.

  pad.py [--wait SECONDS] fingers N DX DY
      N fingers touch the pad, move by DX, DY (12 units to the mm) and lift:
      a scroll with 2 fingers, a swipe with 3 or 4
  pad.py [--wait SECONDS] wheel CLICKS
      a mouse wheel turned CLICKS clicks, up if positive
  pad.py [--wait SECONDS] drag DX DY
      the left mouse button held down while the mouse moves by DX, DY
"""

import sys
import time

from evdev import AbsInfo, UInput
from evdev import ecodes as e

TOOLS = {
    1: e.BTN_TOOL_FINGER,
    2: e.BTN_TOOL_DOUBLETAP,
    3: e.BTN_TOOL_TRIPLETAP,
    4: e.BTN_TOOL_QUADTAP,
}


def touchpad():
    axis = lambda top: AbsInfo(value=0, min=0, max=top, fuzz=0, flat=0, resolution=12)
    capabilities = {
        e.EV_KEY: [e.BTN_LEFT, e.BTN_TOUCH, *TOOLS.values()],
        e.EV_ABS: [
            (e.ABS_X, axis(1200)),
            (e.ABS_Y, axis(800)),
            (e.ABS_MT_SLOT, AbsInfo(0, 0, 3, 0, 0, 0)),
            (e.ABS_MT_TRACKING_ID, AbsInfo(0, 0, 65535, 0, 0, 0)),
            (e.ABS_MT_POSITION_X, axis(1200)),
            (e.ABS_MT_POSITION_Y, axis(800)),
        ],
    }
    return UInput(
        capabilities,
        name="hyprsimple-nix test touchpad",
        vendor=0x1234,
        product=0x5678,
        input_props=[e.INPUT_PROP_POINTER, e.INPUT_PROP_BUTTONPAD],
    )


# How long to give the compositor to find a device just plugged in. Hyprland
# 0.55 needed more than 2 seconds in a VM; events before that are lost.
WAIT = 5.0


def mouse():
    capabilities = {
        e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT, e.BTN_MIDDLE],
        e.EV_REL: [e.REL_X, e.REL_Y, e.REL_WHEEL],
    }
    return UInput(capabilities, name="hyprsimple-nix test mouse")


def nudge(ui):
    """The pointer one pixel aside and back. A compositor may only tell a
    window that the pointer is over it once the pointer moves; a hand always
    moves it, a test does not."""
    for step in (1, -1):
        ui.write(e.EV_REL, e.REL_X, step)
        ui.syn()
        time.sleep(0.1)
    time.sleep(0.3)


def fingers(count, dx, dy, steps=40):
    ui = touchpad()
    pointer = mouse()
    time.sleep(WAIT)  # for the compositor to find the new devices
    nudge(pointer)
    starts = [(450 + 150 * i, 300) for i in range(count)]

    def place(fraction):
        for slot, (x, y) in enumerate(starts):
            ui.write(e.EV_ABS, e.ABS_MT_SLOT, slot)
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_X, int(x + dx * fraction))
            ui.write(e.EV_ABS, e.ABS_MT_POSITION_Y, int(y + dy * fraction))
        ui.write(e.EV_ABS, e.ABS_X, int(starts[0][0] + dx * fraction))
        ui.write(e.EV_ABS, e.ABS_Y, int(starts[0][1] + dy * fraction))

    for slot in range(count):
        ui.write(e.EV_ABS, e.ABS_MT_SLOT, slot)
        ui.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, 100 + slot)
    place(0)
    ui.write(e.EV_KEY, e.BTN_TOUCH, 1)
    ui.write(e.EV_KEY, TOOLS[count], 1)
    ui.syn()
    time.sleep(0.05)
    for step in range(1, steps + 1):
        place(step / steps)
        ui.syn()
        time.sleep(0.012)
    for slot in range(count):
        ui.write(e.EV_ABS, e.ABS_MT_SLOT, slot)
        ui.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, -1)
    ui.write(e.EV_KEY, e.BTN_TOUCH, 0)
    ui.write(e.EV_KEY, TOOLS[count], 0)
    ui.syn()
    time.sleep(1)
    ui.close()
    pointer.close()


def wheel(clicks):
    ui = mouse()
    time.sleep(WAIT)
    nudge(ui)
    for _ in range(abs(clicks)):
        ui.write(e.EV_REL, e.REL_WHEEL, 1 if clicks > 0 else -1)
        ui.syn()
        time.sleep(0.3)
    time.sleep(1)
    ui.close()


def drag(dx, dy, steps=30):
    ui = mouse()
    time.sleep(WAIT)
    nudge(ui)
    ui.write(e.EV_KEY, e.BTN_LEFT, 1)
    ui.syn()
    time.sleep(0.1)
    for step in range(steps):
        ui.write(e.EV_REL, e.REL_X, round(dx * (step + 1) / steps) - round(dx * step / steps))
        ui.write(e.EV_REL, e.REL_Y, round(dy * (step + 1) / steps) - round(dy * step / steps))
        ui.syn()
        time.sleep(0.02)
    time.sleep(0.2)
    ui.write(e.EV_KEY, e.BTN_LEFT, 0)
    ui.syn()
    time.sleep(1)
    ui.close()


if __name__ == "__main__":
    if sys.argv[1] == "--wait":
        WAIT = float(sys.argv[2])
        del sys.argv[1:3]
    if sys.argv[1] == "fingers":
        fingers(int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]))
    elif sys.argv[1] == "wheel":
        wheel(int(sys.argv[2]))
    elif sys.argv[1] == "drag":
        drag(int(sys.argv[2]), int(sys.argv[3]))
    else:
        sys.exit(__doc__)
