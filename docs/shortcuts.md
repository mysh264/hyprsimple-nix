# Every shortcut

Everything a key, a mouse button or the touchpad does on a new hyprsimple,
one on each line. Some keys come with a [NixOS setting](settings.md): their
part says which.

* To see the keys you have now, press **SUPER + /**.
* To change any of them, see [Keys, mouse buttons and the touchpad](keys.md).
* The maintainer's setup, with [keys in i3's style](settings.md#keys-in-i3s-style),
  has a list of its own: [Every shortcut in mysh264's setup](shortcuts-mysh264.md).

Key names: **SUPER** is the Windows key. **← → ↑ ↓** are the arrow keys.
**Numpad 4** is the 4 on the number pad, the block of numbers on the right of
big keyboards.

**On this page:**
[Apps](#apps) ·
[Windows](#windows) ·
[Workspaces](#workspaces) ·
[Workspaces 11 and 12](#workspaces-11-and-12) ·
[Window groups and the i3 layout](#window-groups-and-the-i3-layout) ·
[Panels on the bar](#panels-on-the-bar) ·
[The system](#the-system) ·
[Media keys](#media-keys) ·
[The number pad](#the-number-pad) ·
[The drop-down terminal](#the-drop-down-terminal) ·
[The mouse](#the-mouse) ·
[Hot corners](#hot-corners) ·
[The mouse on the bar](#the-mouse-on-the-bar) ·
[The touchpad](#the-touchpad) ·
[Photo viewers](#photo-viewers)

## Apps

| Keys | What happens |
|---|---|
| **SUPER + T** | Opens the terminal |
| **SUPER + B** | Opens the browser |
| **SUPER + F** | Opens the file manager |
| **SUPER + A** | App launcher: type to find any app |
| **SUPER + V** | Clipboard history: paste something you copied before |
| **SUPER + M** | Colour picker: click any spot, and its colour is copied |
| **SUPER + SHIFT + T** | Theme switcher |
| **SUPER + SHIFT + W** | Wallpaper picker |

## Windows

| Keys | What happens |
|---|---|
| **SUPER + Q** | Closes the window |
| **SUPER + W** | Floats the window, or puts it back with the others |
| **SUPER + H** | Focus the window on the left |
| **SUPER + J** | Focus the window below |
| **SUPER + K** | Focus the window above |
| **SUPER + L** | Focus the window on the right |
| **SUPER + SHIFT + →** | Window 30 pixels wider (hold the keys to keep going) |
| **SUPER + SHIFT + ←** | Window 30 pixels narrower |
| **SUPER + SHIFT + ↑** | Window 30 pixels shorter |
| **SUPER + SHIFT + ↓** | Window 30 pixels taller |

With [the i3 layout](settings.md#the-i3-layout-tabs-and-splits-like-i3) on, SUPER + H, J, K and L also go through its tabs and splits.

## Workspaces

| Keys | What happens |
|---|---|
| **SUPER + 1** | Go to workspace 1 |
| **SUPER + 2** | Go to workspace 2 |
| **SUPER + 3** | Go to workspace 3 |
| **SUPER + 4** | Go to workspace 4 |
| **SUPER + 5** | Go to workspace 5 |
| **SUPER + 6** | Go to workspace 6 |
| **SUPER + 7** | Go to workspace 7 |
| **SUPER + 8** | Go to workspace 8 |
| **SUPER + 9** | Go to workspace 9 |
| **SUPER + 0** | Go to workspace 10 |
| **SUPER + SHIFT + 1** | Move the window to workspace 1 |
| **SUPER + SHIFT + 2** | Move the window to workspace 2 |
| **SUPER + SHIFT + 3** | Move the window to workspace 3 |
| **SUPER + SHIFT + 4** | Move the window to workspace 4 |
| **SUPER + SHIFT + 5** | Move the window to workspace 5 |
| **SUPER + SHIFT + 6** | Move the window to workspace 6 |
| **SUPER + SHIFT + 7** | Move the window to workspace 7 |
| **SUPER + SHIFT + 8** | Move the window to workspace 8 |
| **SUPER + SHIFT + 9** | Move the window to workspace 9 |
| **SUPER + SHIFT + 0** | Move the window to workspace 10 |
| **SUPER + SHIFT + S** | Moves the window to the scratchpad, a workspace that is hidden |
| **SUPER + CTRL + ←** | Moves this whole workspace to the screen on the left |
| **SUPER + CTRL + →** | Moves this whole workspace to the screen on the right |
| **SUPER + CTRL + ↑** | Moves this whole workspace to the screen above |
| **SUPER + CTRL + ↓** | Moves this whole workspace to the screen below |

Nothing shows the scratchpad again yet: [What a key can do](keys.md#what-a-key-can-do) has the line for a key that does.

## Workspaces 11 and 12

With [keys for workspaces 11 and 12](settings.md#keys-for-workspaces-11-and-12) on. `-` and `=` are the two keys after 0.

| Keys | What happens |
|---|---|
| **SUPER + -** | Go to workspace 11 |
| **SUPER + =** | Go to workspace 12 |
| **SUPER + SHIFT + -** | Move the window to workspace 11 |
| **SUPER + SHIFT + =** | Move the window to workspace 12 |

## Window groups and the i3 layout

With [window groups](settings.md#window-groups-tabs) or [the i3 layout](settings.md#the-i3-layout-tabs-and-splits-like-i3) on, or both. On a workspace in the i3 layout, these keys work on its tabs.

| Keys | What happens |
|---|---|
| **SUPER + G** | Makes the windows a group of tabs, or undoes it. i3 layout: tabs, or side by side |
| **SUPER + ALT + G** | Takes the window out of its group (groups only) |
| **SUPER + ALT + →** | Moves the window into the group on the right. i3 layout: moves the window right |
| **SUPER + ALT + ←** | Moves the window into the group on the left. i3 layout: moves the window left |
| **SUPER + ALT + ↑** | Moves the window into the group above. i3 layout: moves the window up |
| **SUPER + ALT + ↓** | Moves the window into the group below. i3 layout: moves the window down |
| **SUPER + ALT + H** | The same as SUPER + ALT + ← |
| **SUPER + ALT + L** | The same as SUPER + ALT + → |
| **SUPER + ALT + K** | The same as SUPER + ALT + ↑ |
| **SUPER + ALT + J** | The same as SUPER + ALT + ↓ |
| **SUPER + ALT + TAB** | The next window in the group, or tab |
| **SUPER + ALT + SHIFT + TAB** | The window before in the group, or tab |
| **SUPER + ALT + 1** | Window 1 of the group, or tab 1 |
| **SUPER + ALT + 2** | Window 2 of the group, or tab 2 |
| **SUPER + ALT + 3** | Window 3 of the group, or tab 3 |
| **SUPER + ALT + 4** | Window 4 of the group, or tab 4 |
| **SUPER + ALT + 5** | Window 5 of the group, or tab 5 |
| **SUPER + ALT + 6** | Window 6 of the group, or tab 6 |
| **SUPER + ALT + 7** | Window 7 of the group, or tab 7 |
| **SUPER + ALT + 8** | Window 8 of the group, or tab 8 |
| **SUPER + ALT + 9** | Window 9 of the group, or tab 9 |
| **SUPER + CTRL + SPACE** | Switches the workspace between Hyprland's layout and i3's (i3 layout only) |
| **SUPER + CTRL + H** | i3 layout: the next window you open goes beside this one |
| **SUPER + CTRL + J** | i3 layout: the next window you open goes below this one |
| **SUPER + CTRL + E** | i3 layout: side by side becomes on top of each other, and back |

## Panels on the bar

| Keys | What happens |
|---|---|
| **SUPER + S** | Sound: volume, and which speakers |
| **SUPER + ALT + S** | Microphone: level, and which microphone |
| **SUPER + SHIFT + N** | Network (Wi-Fi) |
| **SUPER + SHIFT + B** | Bluetooth |
| **SUPER + SHIFT + D** | Notifications |
| **SUPER + C** | Calendar |
| **SUPER + I** | System |
| **SUPER + /** | Shows all the keys you have now, on the screen |

## The system

| Keys | What happens |
|---|---|
| **SUPER + ESC** | Power menu: shut down, restart, log out |
| **SUPER + X** | Logs out at once (your windows are closed first) |
| **SUPER + SHIFT + L** | Locks the screen |
| **CTRL + ESC** | Hides the bar, or shows it again |
| **SUPER + N** | Night light on or off (warmer colours) |
| **SUPER + SHIFT + I** | Keep awake on or off (no screen lock, no sleep) |
| **SUPER + D** | Clears the notifications from the screen |
| **SUPER + SHIFT + M** | A second screen: the same picture as this one, or its own |
| **SUPER + CTRL + V** | A window with a copy of your screen, for sharing it |
| **PRINT** | Screenshot: drag over an area, or click a window or the screen |
| **SUPER + R** | Records the screen: a menu asks what to record, and which sound |

## Media keys

The special keys on top of the keyboard.

| Keys | What happens |
|---|---|
| **Volume Up key** | Louder |
| **Volume Down key** | Quieter |
| **Mute key** | Sound off, or on again |
| **Microphone Mute key** | Microphone off, or on again |
| **Play key** | Play or pause |
| **Pause key** | Play or pause |
| **Next key** | The next song or video |
| **Previous key** | The song or video before |
| **Brightness Up key** | Screen brighter |
| **Brightness Down key** | Screen darker |
| **Keyboard Light Up key** | Keyboard light brighter |
| **Keyboard Light Down key** | Keyboard light darker |

## The number pad

With [the number pad](settings.md#the-number-pad) on. No SUPER is needed, and the number pad does not type numbers then.

| Keys | What happens |
|---|---|
| **Numpad 4** | The workspace before |
| **Numpad 6** | The workspace after |
| **Numpad 8** | The first workspace with windows |
| **Numpad 2** | The last workspace with windows |
| **Numpad 5** | Back to the workspace you were on before |
| **Numpad 0** | Back to the workspace you were on before |
| **Numpad 1** | Focus the window on the left |
| **Numpad 3** | Focus the window on the right |
| **Numpad 7** | Moves the window to the left |
| **Numpad 9** | Moves the window to the right |
| **SHIFT + Numpad 1** | Go to workspace 1 |
| **SHIFT + Numpad 2** | Go to workspace 2 |
| **SHIFT + Numpad 3** | Go to workspace 3 |
| **SHIFT + Numpad 4** | Go to workspace 4 |
| **SHIFT + Numpad 5** | Go to workspace 5 |
| **SHIFT + Numpad 6** | Go to workspace 6 |
| **SHIFT + Numpad 7** | Go to workspace 7 |
| **SHIFT + Numpad 8** | Go to workspace 8 |
| **SHIFT + Numpad 9** | Go to workspace 9 |
| **SHIFT + Numpad 0** | Go to workspace 10 |

## The drop-down terminal

With [the drop-down terminal](settings.md#a-drop-down-terminal) on. Its setting can give it other keys.

| Keys | What happens |
|---|---|
| **F12** | A terminal slides down from the top of the screen, or away again |

## The mouse

| Keys | What happens |
|---|---|
| **SUPER + left button, drag** | Moves the window |
| **SUPER + right button, drag** | Changes the window's size |
| **SUPER + wheel down** | The next workspace |
| **SUPER + wheel up** | The workspace before |
| **SUPER + ALT + wheel down** | The next window in the group, or tab (with groups or the i3 layout) |
| **SUPER + ALT + wheel up** | The window before in the group, or tab (with groups or the i3 layout) |

The window under the pointer gets the keyboard: focus follows the mouse. The side buttons (back and forward) do nothing yet: [Give a button a job](keys.md#give-a-button-a-job) shows how.

## Hot corners

With [hot corners](corners.md) on: push the pointer into a corner of the screen. A corner works once; move away from it, and it works again. Corners rest while a window is full screen.

| Keys | What happens |
|---|---|
| **Top left corner** | Hides the bar, or shows it again |
| **Top right corner** | Shows the desktop (an empty workspace); there again, back to where you were |
| **Bottom right corner** | Back to the workspace you were on before |
| **Bottom left corner** | Nothing |

## The mouse on the bar

| Keys | What happens |
|---|---|
| **Click a workspace** | Go to that workspace |
| **Wheel over the workspaces** | The next or the previous workspace |
| **Click the date and time** | Calendar |
| **Click the memory number** | System panel |
| **Click the microphone** | Microphone panel |
| **Right-click the microphone** | Microphone off, or on again |
| **Wheel over the microphone** | Microphone louder or quieter |
| **Click the speaker** | Sound panel |
| **Right-click the speaker** | Sound off, or on again |
| **Wheel over the speaker** | Louder or quieter |
| **Click the Wi-Fi icon** | Network panel |
| **Click the Bluetooth icon** | Bluetooth panel |
| **Click the bell** | Notifications panel |
| **Click the keep-awake icon** | Keep awake on or off |
| **Click the power icon** | Power menu |
| **Click the red record button** | Stops the recording (it is there only while recording) |
| **Click the prayer time** | Prayer times panel (with the prayer times plugin) |
| **Right-click the prayer time** | The prayer's time, or the time left until it |

## The touchpad

| Keys | What happens |
|---|---|
| **Tap with 1 finger** | Left click |
| **Tap with 2 fingers** | Right click |
| **Tap with 3 fingers** | Middle click: pastes the text you selected |
| **Tap, tap again and slide** | Drags; lift the finger to let go |
| **Slide 2 fingers up or down** | Scrolls. The page follows your fingers, like on a phone |
| **Slide 2 fingers left or right** | Scrolls sideways |
| **Press down at the bottom right** | Right click |
| **Press down anywhere else** | Left click |

While you type, the touchpad rests, so your palm cannot move the pointer. Swipes with 3 or 4 fingers do nothing yet: [Touchpad swipes](keys.md#touchpad-swipes) shows how to give them jobs.

## Photo viewers

In swayimg and imv, with [Viewnior's keys](settings.md#viewniors-keys-in-swayimg-and-imv) on. The keys are the same in both, unless the line says otherwise.

| Keys | What happens |
|---|---|
| **SPACE** | The next photo |
| **PAGE DOWN** | The next photo |
| **ALT + →** | The next photo |
| **→** | The next photo (swayimg: when zoomed in, moves the photo instead) |
| **↓** | The next photo (swayimg: when zoomed in, moves the photo instead) |
| **BACKSPACE** | The photo before |
| **PAGE UP** | The photo before |
| **ALT + ←** | The photo before |
| **←** | The photo before (swayimg: when zoomed in, moves the photo instead) |
| **↑** | The photo before (swayimg: when zoomed in, moves the photo instead) |
| **HOME** | The first photo |
| **END** | The last photo |
| **SHIFT + arrows** | Look around a zoomed-in photo |
| **+** | Zoom in (CTRL + + too) |
| **=** | Zoom in (CTRL + = too) |
| **-** | Zoom out (CTRL + - too) |
| **1** | Real size, 100% (CTRL + 0 too) |
| **2** | Twice the size, 200% (swayimg) |
| **3** | Three times the size, 300% (swayimg) |
| **F** | Fits the photo to the window |
| **0** | Fits the photo to the window |
| **F11** | Full screen |
| **F5** | Starts the slideshow (swayimg: F5 again stops it) |
| **SHIFT + F5** | Stops the slideshow (imv) |
| **ESC** | Closes the viewer (swayimg: first leaves full screen or the slideshow) |
| **CTRL + W** | Closes the viewer |
| **Q** | Closes the viewer (imv) |
| **CTRL + R** | Turns the photo right |
| **CTRL + SHIFT + R** | Turns the photo left |
| **H** | Flips the photo left to right |
| **V** | Flips the photo upside down |
| **DELETE** | Moves the photo to the trash, where you can get it back |
| **Mouse wheel** | Zoom in or out, where the pointer is |
| **Left button, drag** | Moves a zoomed-in photo |
| **SHIFT + mouse wheel** | The next photo or the one before (swayimg) |
| **Sideways scroll** | The next photo or the one before (swayimg) |
| **Mouse back button** | The photo before (swayimg) |
| **Mouse forward button** | The next photo (swayimg) |

On the number pad, + and - zoom too, and 0 to 3 do what 0 to 3 do above, unless [the number pad](settings.md#the-number-pad) setting is on: then those switch workspaces.
