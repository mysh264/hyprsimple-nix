# Changing settings

There are two kinds of settings:

1. **What your computer installs.** These go in your NixOS configuration,
   `/etc/nixos/configuration.nix`. After changing one, you rebuild.
2. **How your desktop looks and behaves.** These are hyprsimple's own files
   in your home folder, mostly in `~/.config/hypr`. You change them like any
   text file, and they work right away (sometimes after `hyprctl reload`).

This page is about the first kind. For the second kind, see
[your desktop's own settings](#your-desktops-own-settings) at the end.

---

## How to change a setting in your NixOS configuration

Every time, it is the same three steps:

1. Open the file: `sudo nano /etc/nixos/configuration.nix`
2. Add or change a line. Lines go inside the outer `{ }`, for example right
   above the last `}`. Every line ends with `;`.
3. Save (**Ctrl + O**, **Enter**), close (**Ctrl + X**), and rebuild:
   `sudo nixos-rebuild switch` (or with `--flake`, as in the
   [install guide](install.md#step-2-rebuild)).

---

## The settings

### Turn hyprsimple on

```nix
  programs.hyprsimple.enable = true;
```

This is the one you added while installing. It installs everything
hyprsimple needs. Set it to `false` (or remove it) to turn hyprsimple off; see
[Removing hyprsimple](uninstall.md) for the whole story.

### Choose the first theme

```nix
  programs.hyprsimple.defaultTheme = "tokyo-night";
```

The theme `hyprsimple-install` starts with. The normal one is `deep-sea`.
This only matters the first time a user runs `hyprsimple-install`. After
that, press **SUPER + SHIFT + T** to pick any theme you like, any time.

The theme names are the folder names in `~/.config/hypr/themes`, for example
`catppuccin`, `dracula`, `gruvbox`, `nord`, `rosepine` or `tokyo-night`.

### Leave out programs you do not want

hyprsimple comes with Firefox, Neovim, Ghostty, Nautilus and more. To leave
some out:

```nix
  programs.hyprsimple.excludePackages = [ pkgs.firefox pkgs.neovim ];
```

The things that use them stop working. For example, **SUPER + B** opens
Firefox; without Firefox it does nothing.

> 💡 Need `pkgs` for this? The first line of `configuration.nix` should list
> it: `{ config, pkgs, ... }:`. It usually does.

### Name your workspaces

```nix
  programs.hyprsimple.workspaces.names = [ "Web" "Code" "Term" "Files" ];
```

Your workspaces get names, in order: the first name is workspace 1, the
second is workspace 2, and so on. The bar at the top shows the names instead
of small dots, and it always shows the workspaces you named, even when they
are empty, so you always know where everything goes.

1. Add the line to `configuration.nix`, with your own names, and rebuild.
2. Type `hyprctl reload` (or log out and in). The names appear on the bar.

Good to know:

- **SUPER + 1** to **SUPER + 0** go to workspaces 1 to 10. A workspace after
  10 has no key, but you can click it on the bar, or scroll over the bar to
  walk through all of them. Want a key anyway? Add a line like this to
  `~/.config/hypr/bindings/applications.lua`:

  ```lua
  hl.bind("SUPER + F11", hl.dsp.focus({ workspace = "11" }), { description = "Workspace 11" })
  ```

- Naming workspaces the Hyprland way, with `hl.workspace_rule` and
  `default_name` in your own files in `~/.config/hypr`, works too. The bar
  shows those names the same way.

### Put apps on their own workspace

```nix
  programs.hyprsimple.workspaces.apps = {
    "1" = [ "firefox" "brave" "chrome" "chromium" ];
    "2" = [ "claude" "cursor" ];
    "4" = [ "kate" "gedit" ];
    "6" = [ "mpv" ];
    "7" = [ "viewnior" ];
    "8" = [ "jellyfin" ];
    "9" = [ "steam" ];
  };
```

Every app in a list always opens on that workspace, and that workspace
comes to the front. Here, Firefox always opens on workspace 1, mpv on 6, and
Steam on 9.

1. Add the lines to `configuration.nix`, with your own apps. The workspace
   number goes in quotes (`"6"`), the apps in the list after it.
2. Rebuild, then type `hyprctl reload` (or log out and in).

**How do I find an app's name?** hyprsimple-nix looks at the app's *window
class*, the name the app gives its windows. A part of it is enough, and big
or small letters do not matter: `"firefox"` also finds `org.mozilla.firefox`.
To see the class:

1. Open the app.
2. Open a terminal (**SUPER + T**) and type `hyprctl clients`.
3. Find your app in the list, and look at the line that starts with
   `class:`. That word, or a part of it, goes in your list.

> 💡 A part matches anything that contains it. `"steam"` also matches Steam's
> games (their class starts with `steam_app_`), so they open on workspace 9
> too. And a very short part can catch apps you did not mean: `"zen"`, for
> the Zen browser, also catches `zenity`, the small dialog windows hyprsimple
> shows. If that happens, write more of the class, as `hyprctl clients`
> shows it.

### Keys for workspaces 11 and 12

```nix
  programs.hyprsimple.keys.workspaces11and12.enable = true;
```

**SUPER + 1** to **SUPER + 0** go to workspaces 1 to 10. This line adds the
two keys right after **0**:

| Press | What happens |
|---|---|
| **SUPER + -** | You go to workspace 11 |
| **SUPER + =** | You go to workspace 12 |
| **SUPER + SHIFT + -** | The window you are on moves to workspace 11 |
| **SUPER + SHIFT + =** | The window you are on moves to workspace 12 |

1. Add the line to `configuration.nix`.
2. Rebuild, then type `hyprctl reload` (or log out and back in).

What counts is the keys' **place**: on a keyboard that is not English, they
are still the two keys right of **0**.

> 💡 Workspaces 11 and 12 can have names too: write 12 names in
> [`workspaces.names`](#name-your-workspaces).

### The number pad

```nix
  programs.hyprsimple.keys.numpad.enable = true;
```

The number pad (the block of number keys on the right of big keyboards)
becomes a remote control for your workspaces and windows, the way many i3
users set it up:

| Number pad key | What happens |
|---|---|
| **4** | The workspace before |
| **6** | The workspace after |
| **8** | The first workspace |
| **2** | The last workspace |
| **5** or **0** | Back to the workspace you were on before |
| **1** | Focus the window on the left |
| **3** | Focus the window on the right |
| **7** | Move the window to the left |
| **9** | Move the window to the right |
| **SHIFT + 1** … **SHIFT + 9** | Workspace 1 … 9 |
| **SHIFT + 0** | Workspace 10 |

"First" and "last" mean the first and the last workspace that has windows
(or that you are on). The keys work with Num Lock on and off.

1. Add the line to `configuration.nix`.
2. Rebuild, then type `hyprctl reload` (or log out and back in).

> ⚠️ With this on, the number pad does not type numbers any more, in any
> program. The number keys above the letters still do. If you want the
> number pad for numbers, leave this off: [the number pad, by
> hand](keys.md#the-number-pad-by-hand) shows how to give it jobs only while
> you hold **SUPER**.

To change other keys, mouse buttons and the touchpad, see
[Keys, mouse buttons and the touchpad](keys.md).

### Window groups (tabs)

```nix
  programs.hyprsimple.groups.enable = true;
```

A group is several windows stacked in one place, like the tabs in a web
browser: you see one window, and a bar of tabs above it shows the others.
These are Hyprland's own groups; for the real i3 layout, with tabs *and*
splits, see the next section. hyprsimple has no keys for groups; this line
adds them. The tabs take the colours of your theme.

1. Add the line to `configuration.nix`, and rebuild.
2. Type `hyprctl reload` (or log out and in).
3. Press **SUPER + /** to see the new keys among the others.

| Press | What happens |
|---|---|
| **SUPER + G** | The window you are on becomes a group, with a tab bar. Press it again to undo the group. |
| *(open a window)* | A window you open while you are in a group joins that group. |
| **SUPER + ALT + ←** (or →, ↑, ↓) | Moves the window you are on into the group on that side. **H, L, K, J** work too. |
| **SUPER + ALT + G** | Takes the window you are on out of its group. |
| **SUPER + ALT + TAB** | Next window in the group. Add **SHIFT** for the one before. The mouse wheel works too, with **SUPER + ALT**. |
| **SUPER + ALT + 1** … **9** | Window 1 … 9 of the group. |
| **SUPER + H** / **L** | Go through the group's windows first, then on to the windows next to it, like i3. |
| **SUPER + Q** | Closes the window you are on, and only that one. |

With the mouse: click a tab to see that window, click a tab with the middle
mouse button to close that window, and drag a window onto a group (hold
**SUPER** and the left mouse button) to put it in.

**Closing a window never closes the rest of its group.** It does not matter
which one you close, the first one or any other: the others stay, as a
group. Our tests check exactly that.

> 💡 One thing is not about groups. A program you start by typing its name
> in a terminal can belong to that terminal, and then it closes when you
> close the terminal. To keep it open, start it from the app menu, or start
> it like this: `setsid -f nautilus` (with your program instead of
> `nautilus`).

### The i3 layout (tabs and splits, like i3)

```nix
  programs.hyprsimple.i3 = {
    enable = true;
    workspaces = [ 2 3 ];
  };
```

Hyprland arranges your windows by itself: each new window takes half of the
space. i3 lets you choose: windows in tabs, side by side, or on top of each
other. With this setting you get both, workspace by workspace. It uses
[hy3](https://github.com/outfoxxed/hy3), the plugin that brings i3's layout
to Hyprland.

1. Add the lines to `configuration.nix`. `workspaces` lists the workspaces
   that start in the i3 layout (here 2 and 3). The others start in
   Hyprland's.
2. Rebuild, then log out and back in.
3. Press **SUPER + /** to see the new keys among the others.

**SUPER + CTRL + SPACE** switches the workspace you are on between the two
layouts, at any time. The switch stays until you log out.

On a workspace in the i3 layout:

- **One window** fills the whole screen: no tab bar, no gaps, no border.
- **A second window** turns them into tabs, with a tab bar on top, like i3
  with tabs as its default.
- **Back to one window**, the tab bar goes away again.

| Press | What happens on an i3 workspace |
|---|---|
| **SUPER + G** | Tabs become side by side, and back again. |
| **SUPER + ALT + TAB** | Next tab. Add **SHIFT** for the one before. The mouse wheel works too, with **SUPER + ALT**. |
| **SUPER + ALT + 1** … **9** | Tab 1 … 9. |
| **SUPER + H** / **J** / **K** / **L** | Go to the window or tab on that side. |
| **SUPER + ALT + ←** (or →, ↑, ↓, or **H**, **L**, **K**, **J**) | Move the window you are on that way: next to another one, or into its tabs. |
| **SUPER + CTRL + H** | The next window you open goes **beside** this one. |
| **SUPER + CTRL + J** | The next window you open goes **below** this one. |
| **SUPER + CTRL + E** | Turn the split: side by side becomes on top of each other, and back. |
| **SUPER + Q** | Closes the window you are on, and only that one. |

Have both this and window groups on? The same keys (**SUPER + G**,
**SUPER + ALT + ...**) work Hyprland's groups on a Hyprland workspace, and
i3's tabs on an i3 workspace. **SUPER + /** says both.

### Keys in i3's style

```nix
  programs.hyprsimple.keys.i3Style.enable = true;
```

The keys of an i3 user: the maintainer of hyprsimple-nix. Many keys move to
where i3 has them:

| Keys | What they do now | Before |
|---|---|---|
| **SUPER + ←, →, ↑, ↓** | Focus the window that way | SUPER + H, L, K, J |
| **SUPER + CTRL + arrows** | Window bigger or smaller | SUPER + SHIFT + arrows |
| **SUPER + SHIFT + arrows** | Move the window into a group (i3 layout: move it) | SUPER + ALT + arrows |
| **SUPER + ALT + arrows** | Move the workspace to another screen | SUPER + CTRL + arrows |
| **SUPER + ENTER** | Terminal (SUPER + T still works too) | nothing |
| **SUPER + D** | App launcher | SUPER + A |
| **SUPER + P** | Colour picker | SUPER + M |
| **SUPER + Z** | Float the window, or tile it again | SUPER + W |
| **SUPER + SHIFT + F** | Full screen, and back | nothing |
| **SUPER + TAB**, **SUPER + SHIFT + TAB** | Next or previous workspace, and round again | nothing |
| **SUPER + S** | Show or hide the scratchpad | sound panel |
| **SUPER + SHIFT + S** | The window into the scratchpad, or back out of it | into the scratchpad |
| **SUPER + SHIFT + G** | Take the window out of its group | SUPER + ALT + G |
| **SUPER + A** | Switch the workspace: Hyprland's layout or i3's | SUPER + CTRL + SPACE |
| **SUPER + H**, **SUPER + J**, **SUPER + E** | i3 layout: next window beside, below, turn the split | SUPER + CTRL + H, J, E |
| **SUPER + SHIFT + A** | Sound panel | SUPER + S |
| **SUPER + ALT + D** | Notifications panel | SUPER + SHIFT + D |
| **SUPER + SHIFT + D** | Clear the notifications | SUPER + D |
| **SUPER + SHIFT + E** | Power menu (SUPER + ESC still works too) | nothing |
| **SUPER + L** | Lock the screen | SUPER + SHIFT + L |
| **SUPER + M** | Hide or show the bar (CTRL + ESC still works too) | colour picker |
| **SUPER + PRINT** | Screenshot of the whole screen, at once | nothing |
| **SHIFT + PRINT** | Screenshot of the window you are in, at once | nothing |
| mouse **back** button | Back to the workspace you were on before | nothing |
| **SUPER + X** | Nothing (the power menu has Log out) | log out |

And **SUPER + the number of the workspace you are on**, or a click on its name
on the bar, takes you back to the workspace before, like i3's
`workspace_auto_back_and_forth`.

1. Add the line to `configuration.nix`. It works best with
   [window groups](#window-groups-tabs) and [the i3 layout](#the-i3-layout-tabs-and-splits-like-i3)
   on as well.
2. Rebuild, then type `hyprctl reload` (or log out and back in).

[Every shortcut in mysh264's setup](shortcuts-mysh264.md) lists every key
with it on.

**Want another key for one of its jobs?** Bind the key yourself in
`~/.config/hypr/bindings/applications.lua`. Your line wins over this
setting's, with no `hl.unbind` needed:
[Keys that come from your NixOS settings](keys.md#keys-that-come-from-your-nixos-settings)
shows how, with the jobs' names.

### A drop-down terminal

```nix
  programs.hyprsimple.dropdownTerminal.enable = true;
```

Press **F12**, and a terminal slides down from the top of the screen, over
your windows, with what is behind it blurred. Press **F12** again, and it
slides away. What you typed in it stays there, for the next time. It is
Ghostty's own drop-down terminal, so it has your theme and your font.

> ⚠️ It needs Ghostty 1.4 or newer. nixos-unstable has it; NixOS 26.05 has
> Ghostty 1.3, where the key does nothing yet (the rebuild warns you).

1. Add the line to `configuration.nix`, and rebuild.
2. Type `hyprctl reload` (or log out and back in).

**Other keys?** List them, in the way Hyprland writes keys:

```nix
  programs.hyprsimple.dropdownTerminal.keys = [ "F12" "code:91" "mouse:276" ];
```

Here **F12**, the **.** on the number pad (`code:91`) and the mouse's
**forward** button (`mouse:276`) all do it.
[What is a key's name?](keys.md#what-is-a-keys-name) helps you find a key's
name, and [Every button's name](keys.md#every-buttons-name) a mouse button's.

**Its size,** and whether it slides away by itself when you click elsewhere,
are Ghostty settings, in `~/.config/ghostty/config`:

```
quick-terminal-size = 50%
quick-terminal-autohide = true
```

### Hot corners

```nix
  programs.hyprsimple.corners.enable = true;
```

Push the mouse pointer into a corner of the screen: the top left corner hides
or shows the bar, the top right corner shows the desktop, and the bottom
right corner goes back to the workspace before. You choose what each corner
does: [Hot corners](corners.md) shows how, step by step.

### The bar at the bottom

```nix
  programs.hyprsimple.bar.position = "bottom";
```

1. Add the line to `configuration.nix`, and rebuild.
2. Log out and back in.

The bar now sits at the bottom of the screen. Its panels (calendar, sound,
Wi-Fi and the others), the notifications and the little hints all open
upwards out of it. To put it back at the top, write `"top"` instead, or take
the line out, rebuild, and log out and in.

### The hidden bar back at the edge

```nix
  programs.hyprsimple.bar.peek.enable = true;
```

1. Add the line to `configuration.nix`, and rebuild.
2. Log out and back in. (The bar reads this setting when you log in.)

Hide the bar (its key, or the top left [hot corner](corners.md)): your
windows take the whole screen. Now push the mouse pointer against the bar's
edge of the screen, the bottom one with the bar at the bottom: the bar comes
back, over your windows, which stay where they are. Use it, open its panels,
then move the pointer away, and it goes again. Show it with its key, and it
stays, as before.

The edge is the last 2 pixels of the screen, all along it but for its two
ends, which stay [hot corners](corners.md) when those are on. While the bar
is hidden, those 2 pixels of a window under them do not take a click. A
window in full screen (a film, a game) covers the edge, so the bar never
comes over it. To turn it off, take the line out, rebuild, and log out and
in.

### Every workspace the same width on the bar

```nix
  programs.hyprsimple.bar.workspaceWidth = 65;
```

With [names](#name-your-workspaces), each workspace on the bar is as wide
as its name: "Web" is small, "Theater" is wide. This line makes them all the
same width, here 65 pixels, so they stand in neat, even boxes. A name too
long for its box ends in "…".

1. Add the line to `configuration.nix`. Pick your own number: bigger
   numbers make wider boxes.
2. Rebuild.
3. Log out and back in. (The bar reads this setting when you log in.)

Too small, or too wide? Change the number, rebuild, and log in again.

### Prayer times on the bar

hyprsimple shows prayer times on the bar, through a plugin called
muslimtify. It is on unless you turn it off:

```nix
  programs.hyprsimple.muslimtify.enable = false;
```

This stops it from being installed for **new** users. If you already ran
`hyprsimple-install`, also remove the plugin from your bar:

```sh
hyprsimple-plugin remove muslimtify
```

**To set your city for the prayer times,** click the prayer time on the bar
and press **s** for its settings. Or type, with your own city's numbers:

```sh
muslimtify location set --auto
```

`--auto` guesses your place from your internet connection. You can also
give it exactly: `muslimtify location set --lat=-6.2 --long=106.8 --timezone=Asia/Jakarta --city=Jakarta`.

**To move the prayer time to the right side of the bar,** next to the icons
there (it starts on the left, next to the workspaces), open a terminal on
your desktop (**SUPER + T**) and type these three lines:

```sh
f=~/.config/hyprsimple/plugins.json
jq '.plugins.muslimtify.placement = "right"' "$f" > "$f.new" && mv "$f.new" "$f"
~/.local/bin/hyprsimple-restart-bar.sh
```

The first two lines change the setting. The last one restarts the bar, so
you see the change right away. Instead of `"right"` you can also write
`"left"` (next to the workspaces, where it started) or `"center"` (next to
the clock). This is your own setting, so updates keep it.

Other plugins move the same way: write the plugin's name instead of
`muslimtify`. `hyprsimple-plugin list` shows the names.

**Or let your NixOS configuration choose the place,** so it is the same on
every computer, also after a new install:

```nix
  programs.hyprsimple.muslimtify.placement = "right";
```

`"left"`, `"center"` or `"right"`, as above. Rebuild, then type
`hyprsimple-update` in a terminal on your desktop: it moves the prayer time
and restarts the bar. `hyprsimple-install` sets it the first time by itself.

> 💡 Type the lines in a terminal on your desktop, not on a text screen or
> over SSH. From there, the restarted bar cannot find your desktop.

### LocalSend

```nix
  programs.hyprsimple.localsend.openFirewall = false;
```

hyprsimple opens network port 53317 in the firewall, so that
[LocalSend](https://localsend.org) can send files between your devices. If
you do not use LocalSend, you can close it with this line.

### Viewnior, the photo viewer, mended for Wayland

```nix
  programs.hyprsimple.viewnior.enable = true;
```

[Viewnior](https://siyanpanayotov.com/project/viewnior/) has three problems
on Wayland:

- Two fingers on the touchpad can neither zoom a photo nor go to the next
  one. Only a mouse wheel works.
- When you zoom in and drag the photo to see another part of it, it stands
  still. (Zoomed out, all seems fine, because there is nothing to drag.)
- When you crop, you do not see the rectangle you are choosing.

On X11 all of this works, which is why some people start Viewnior with
`GDK_BACKEND=x11`. This line installs a mended Viewnior instead, which
hyprsimple-nix fixed for Wayland.

1. Add the line to `configuration.nix`. If `viewnior` is also in your
   `environment.systemPackages`, you can leave it there: the mended one is
   used either way.
2. Rebuild.
3. Close Viewnior if it is open, and open a photo again.
4. Put two fingers on the touchpad and move them up or down: the photo
   zooms in and out. A mouse wheel works as before: one click, one step.
5. Zoom in, then hold the left button on the photo and move the mouse: the
   photo moves with it.

If you set Viewnior's wheel to **Navigate images** (in its Preferences),
two fingers go to the next and the previous photo instead.

> 💡 Did you make Viewnior start with `GDK_BACKEND=x11`? Undo it, so it runs
> on Wayland again: delete your copy of its start file,
> `rm ~/.local/share/applications/viewnior.desktop`, if you made one. On
> Wayland it is sharp on a scaled screen and follows your theme.

Rather have a photo viewer made for Wayland, with Viewnior's keys? See
[Viewnior's keys in swayimg and imv](#viewniors-keys-in-swayimg-and-imv).

**Make Viewnior the app that opens your photos.** In a terminal:

```sh
xdg-mime default viewnior.desktop image/jpeg image/png image/gif image/webp image/bmp image/tiff
```

Now a double click on a photo in the file manager opens it in Viewnior.

### Viewnior's keys in swayimg and imv

```nix
  programs.hyprsimple.viewniorKeys.enable = true;
```

swayimg is hyprsimple's photo viewer. imv is another one, small and fast.
Both are made for Wayland, so the touchpad, dragging a photo and sharp
pictures just work. This line gives both of them Viewnior's keys, so your
fingers do not have to learn new ones. It installs imv as well.

1. Add the line to `configuration.nix`.
2. Rebuild.
3. Open a photo with swayimg: in the file manager, right-click the photo,
   pick **Open With**, then **swayimg**. Or in a terminal:
   `swayimg photo.jpg` (or `imv-dir photo.jpg`).
4. The other photos in the same folder come along, so you can turn through
   them with the keys below.

| Press | What happens |
|---|---|
| **Space**, **Page Down** | The next photo |
| **Backspace**, **Page Up** | The previous photo |
| **→** and **↓** / **←** and **↑** | The next / the previous photo. In a zoomed-in photo (in swayimg), they move about in it instead, as in Viewnior |
| **SHIFT + an arrow** | Move about in a zoomed-in photo |
| **Home** / **End** | The first / the last photo in the folder |
| **+** or **=** | Zoom in |
| **-** | Zoom out |
| **1**, **2**, **3** | 100%, 200%, 300% (imv: only **1**) |
| **f** or **0** | Fit the photo to the window |
| **CTRL + R** | Turn it right |
| **CTRL + SHIFT + R** | Turn it left |
| **h** / **v** | Flip it left-right / upside down |
| **F11** | Full screen |
| **F5** | Slideshow, a new photo every 5 seconds (imv: **SHIFT + F5** stops it) |
| **Delete** | Move the photo to the trash. It is not gone: the file manager's **Trash** has it |
| **Esc** or **CTRL + W** | Close. In swayimg, in full screen, **Esc** leaves full screen first |
| The mouse wheel | Zoom in and out where the pointer is |
| **SHIFT** + the mouse wheel | The next / the previous photo (swayimg) |
| Hold the left button and move | Move a zoomed-in photo |
| The mouse's side buttons | The previous / the next photo (swayimg) |

**Make it the app that opens your photos.** In a terminal:

```sh
xdg-mime default swayimg.desktop image/jpeg image/png image/gif image/webp image/bmp image/tiff
```

For imv, write `imv-dir.desktop` instead of `swayimg.desktop`: it opens the
photo's whole folder, so you can turn through it.

**Change a key.** The keys are in a file hyprsimple-nix makes. Copy it to
your home folder, and change your copy: yours is read instead.

- swayimg on NixOS unstable (swayimg 5):
  ```sh
  mkdir -p ~/.config/swayimg
  cp /etc/xdg/swayimg/init.lua ~/.config/swayimg/init.lua
  ```
- swayimg on NixOS 26.05 (swayimg 4):
  ```sh
  mkdir -p ~/.config/swayimg
  cp /etc/xdg/swayimg/config ~/.config/swayimg/config
  ```
- imv:
  ```sh
  mkdir -p ~/.config/imv
  cp /etc/imv_config ~/.config/imv/config
  ```

Each key has a note above it in the file. (Your copy does not change when a
new hyprsimple-nix improves the original.)

### A "Hyprsimple" entry on the login screen

```nix
  programs.hyprsimple.loginEntry.enable = true;
```

Your login screen lists **Hyprland (UWSM)**, and with this line also
**Hyprsimple**. Both start exactly the same desktop. The new name is only a
label, the one hyprsimple's `install.sh --session-entry` adds on Arch.

1. Add the line to `configuration.nix`, and rebuild.
2. Log out. On a login screen with a list of sessions (SDDM, GDM, LightDM),
   pick **Hyprsimple**.
3. Do you log in with greetd and tuigreet, like the
   [install guide](install.md)'s example? That login has no list. It starts
   one command, the one after `--cmd`. Change that command to
   `uwsm start hyprsimple.desktop`:

   ```nix
     services.greetd.settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprsimple.desktop'";
   ```

   The same command starts it from a text console.

To take it away, remove the line (or set it to `false`) and rebuild. On NixOS,
hyprsimple's own `hyprsimple-session.sh` points here instead of changing
anything.

### The Conky panel

```nix
  programs.hyprsimple.conky.enable = true;
```

A clean panel on the desktop, on the right of the screen: the time, the
weather, and how busy your computer is. It is the original Lean Conky Config,
made to run on Wayland. It starts at every login, from your own copy in
`~/.config/lean-conky-config`, which you can change as you like:
[The Conky panel](conky.md) shows how, and how to move it and change its
background.

The wallpaper behind it is blurred. To turn that off:

```nix
  programs.hyprsimple.conky.blur = false;
```

### Your own lines for Hyprland

```nix
  programs.hyprsimple.extraConfig = ''
    hl.config({ general = { gaps_in = 5, gaps_out = 0, border_size = 3 } })
  '';
```

Lines for Hyprland's configuration, written in Lua, the same language as the
files in `~/.config/hypr`. The example puts 5 pixels between windows, none at
the edge of the screen, and makes the border 3 pixels wide.

Why here, and not in `~/.config/hypr`? Lines in your NixOS configuration come
back by themselves on a new computer, or after a new install. A file in
`~/.config/hypr` stays only on the computer where you wrote it.

1. Put your lines between the two `''`.
2. Rebuild, and type `hyprctl reload`.

They run after hyprsimple-nix's own additions, and before your files in
`~/.config/hypr`: a file there still wins. A key bound here takes the place of
the same key from a setting on this page. Any line from
[Keys, mouse buttons and the touchpad](keys.md) works here too. A mistake in
a line shows as a red message when Hyprland starts, and the lines after it
stop working: check with `hyprctl configerrors`.

### A whole setup at once: mysh264's

```nix
      "${builtins.fetchTarball "https://github.com/mysh264/hyprsimple-nix/archive/main.tar.gz"}/profiles/mysh264.nix"
```

The maintainer's whole setup, every setting on this page chosen, in one file.
That line goes in the `imports` list of `configuration.nix`:
[mysh264's setup](mysh264.md) explains it step by step.

### Your graphics card

Graphics settings live in their own file, `gpu.nix`. See the
[graphics guide](gpu.md).

---

## What hyprsimple turns on for you

When you set `programs.hyprsimple.enable = true;`, your NixOS gets what
hyprsimple has on Arch: what its installer sets up, and also what a fresh
Arch install already had before hyprsimple came. (We check this by building
exactly that Arch system and comparing; see
[How it works](how-it-works.md#how-we-know-nothing-is-missing).) You do not
have to do anything, but it is good to know:

- **Hyprland**, the desktop itself, with its helpers. Hyprland starts as on
  Arch: NixOS 26.05 would start it through a special "capability" wrapper,
  which made every program in your session lose its time zone information
  (prayer times and clocks in other apps could be hours off).
  nixos-unstable has already dropped that wrapper; hyprsimple-nix turns it
  off on 26.05 too.
- **The apps and tools** hyprsimple uses: about 80 of them. They are listed in
  [`modules/arch-packages.nix`](../modules/arch-packages.nix).
- **Firmware** for graphics cards, Wi-Fi and Bluetooth chips.
- **Fonts** for the bar, the icons, GTK programs and many languages.
- **Wi-Fi** (NetworkManager), **Bluetooth**, **sound** (PipeWire, also for
  JACK programs), **battery** information, and **power modes**.
- **Your home folders**: Documents, Downloads, Music, Pictures, Videos and the
  others, made at every login in your language, and listed in the file
  manager's sidebar.
- **The file manager's extras**: USB sticks, the trash can, search, and
  previews of pictures, videos and documents.
- **Opening files**: PDFs open in Firefox, videos in mpv, pictures in
  swayimg. Programs that run in a terminal (btop, yazi, Neovim...) open in
  Ghostty, from the app menu or the file manager.
- **A password keyring**, so programs can remember your passwords, and
  **GnuPG**.
- **Everyday commands** an Arch system has: `htop`, `vim`, `wget`,
  `killall`, `python3`, `openssl`, `sensors`, `smartctl`, `gpg` and more.
- **A mouse cursor** for every program, and the **accessibility** service
  screen readers use.
- **The firewall port** for LocalSend.
- **The lock screen's password check.**

Most of these are *defaults*: if you set one yourself, your choice wins. For
example:

```nix
  services.tlp.enable = true;                   # TLP instead of power modes
  services.gnome.localsearch.enable = false;    # no file index for search
  services.gnome.gnome-keyring.enable = false;  # no password keyring
  programs.hyprsimple.excludePackages = [ pkgs.mpv pkgs.vim ];  # leave apps out
```

---

## Using hyprsimple's development version

> ⚠️ For experienced people. hyprsimple's author recommends the normal
> releases. The development version can break.

hyprsimple-nix uses hyprsimple's latest release. To use a newer, unreleased
version from hyprsimple's `main` branch instead, save this as a new file,
`/etc/nixos/hyprsimple-main.nix`, with a commit from
[hyprsimple's history](https://github.com/rizukirr/hyprsimple/commits/main):

```nix
{ options, pkgs, ... }:
{
  programs.hyprsimple.package =
    options.programs.hyprsimple.package.default.overrideAttrs {
      version = "0.4.9-unstable-2026-11-03";
      src = pkgs.fetchFromGitHub {
        owner = "rizukirr";
        repo = "hyprsimple";
        rev = "PUT-THE-COMMIT-HERE";
        hash = "";
      };
    };
}
```

Add `./hyprsimple-main.nix` to the `imports` list in `configuration.nix`, the
same way as [`gpu.nix`](gpu.md#step-3-tell-nixos-to-read-the-file), and
rebuild. It stops and prints the right `hash`; put it between the quotes and
rebuild again. If one of hyprsimple-nix's NixOS fixes does not fit the newer
version, the rebuild tells you which one.

---

## Packages of your own

> ⚠️ For experienced people. The packages hyprsimple-nix picks are built for
> your system and tested together.

A few settings name the package a part comes from. You can give another
build, for example one you patched yourself:

| Setting | The package | It has to |
|---|---|---|
| `programs.hyprsimple.package` | hyprsimple itself (see above) | be hyprsimple, prepared for NixOS like the default |
| `programs.hyprsimple.i3.package` | hy3, the plugin behind the i3 layout | be built for the Hyprland you run: a plugin built for another version does not load |
| `programs.hyprsimple.qt.hyprqt6engine` | hyprqt6engine, which gives Qt programs hyprsimple's look | be built with the same Qt as your apps |
| `programs.hyprsimple.muslimtify.package` | muslimtify, behind the prayer times | have hyprsimple-nix's NixOS fixes (its `pkgs/muslimtify`) |
| `programs.hyprsimple.conky.package` | The Conky panel | have the `lean-conky-config` command |

For example, hy3 from a commit of your choice:

```nix
{ options, pkgs, ... }:
{
  programs.hyprsimple.i3.package =
    options.programs.hyprsimple.i3.package.default.overrideAttrs {
      src = pkgs.fetchFromGitHub {
        owner = "outfoxxed";
        repo = "hy3";
        rev = "PUT-THE-COMMIT-HERE";
        hash = "";
      };
    };
}
```

Save it as its own file, add it to `imports`, and rebuild, as above.

---

## Your desktop's own settings

These are hyprsimple's files, in your home folder. hyprsimple never
overwrites your changes to them.

| To change | Edit this file |
|---|---|
| Screens (size, position, scaling) | `~/.config/hypr/monitors.lua` |
| Keyboard layout, mouse, touchpad | `~/.config/hypr/input.lua` |
| Your own key combinations and mouse buttons | `~/.config/hypr/bindings/applications.lua` |
| Gaps, borders, animations | `~/.config/hypr/looknfeel.lua` |
| Programs that start when you log in | `~/.config/hypr/autostart.lua` |
| Your default terminal, browser, file manager | `~/.config/hypr/vars.lua` |

Each file explains itself with notes at the top. After saving, type
`hyprctl reload` in a terminal. For keys, mouse buttons and the touchpad,
[Keys, mouse buttons and the touchpad](keys.md) shows you how, step by step.

> ⚠️ Don't change the files in `~/.local/share/hyprsimple`. Those are
> hyprsimple's own, and `hyprsimple-update` replaces them with every new
> version. While they have changes of yours, it stops, and you get no
> updates. Put your changes in the files above instead. hyprsimple's own
[README](https://github.com/rizukirr/hyprsimple#readme) tells you much more.
