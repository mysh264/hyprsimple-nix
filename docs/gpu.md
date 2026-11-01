# Setting up your graphics card

Your **graphics card** (also called a **GPU**) is the part of the computer
that draws everything you see on the screen. Hyprland, the desktop
hyprsimple is built on, uses it a lot. So it is worth a few minutes to set it
up right.

Here is the short story:

| You have | Does it work without setup? | What this guide adds |
|---|---|---|
| **Intel** graphics | ✅ Yes | Smooth video playback. Cooler laptops. |
| **AMD** graphics | ✅ Yes | A nicer boot screen. A fix for very old cards. |
| **NVIDIA** graphics | ❌ **No.** You must set it up. | The NVIDIA driver, turned on the right way. |
| A **laptop with two** graphics chips | ❌ **No**, if one of them is NVIDIA. | Both chips, working together. |

> 🛟 **Nothing here can break your computer for good.** NixOS keeps every
> older version of your system. If your computer does not start properly
> after a change, restart it. In the menu that appears while it starts, pick
> an older entry (one with a smaller "Generation" number). Everything is back
> as it was. Then fix the file and try again.

---

## The easy way: let the computer find out

You need to have done steps 1 and 2 of the [install guide](install.md)
first, so that the `hyprsimple-nixos` command exists.

### Step 1: Ask what graphics you have

Open a terminal and type:

```sh
hyprsimple-nixos gpu
```

It shows you two things:

1. **What it found**, like `NVIDIA GeForce RTX 3060`.
2. **A file called `gpu.nix`.** These are the settings your computer needs.

You do not need to understand the file. The next steps save it for you.

> 💡 **It says "You do not need a gpu.nix"?** Then your computer needs no
> graphics settings. You are done here: go on with
> [step 4 of the install guide](install.md#step-4-set-up-hyprsimple-for-your-user).

### Step 2: Save the file

Type:

```sh
hyprsimple-nixos gpu --file | sudo tee /etc/nixos/gpu.nix
```

This writes the file into `/etc/nixos`, the folder where your NixOS
settings live. It asks for your password, because that folder belongs to the
system. It also shows the file on the screen once more; that is normal.

> 💡 If your NixOS settings live in a different folder (some people keep them
> in their home folder), write that folder instead of `/etc/nixos`.

### Step 3: Tell NixOS to read the file

Open your main settings file:

```sh
sudo nano /etc/nixos/configuration.nix
```

`nano` is a simple text editor that runs in the terminal. Move around with
the arrow keys.

Near the top, find the `imports` list. It looks like this:

```nix
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
```

Add a new line with `./gpu.nix` inside the square brackets, like this:

```nix
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./gpu.nix
    ];
```

Now save: press **Ctrl + O**, then **Enter**. Close nano: press **Ctrl + X**.

> 💡 **Using a flake, and your `/etc/nixos` folder is a git repository?**
> Then git has to know about the new file, or NixOS will not see it:
> `sudo git -C /etc/nixos add gpu.nix`

### Step 4: Rebuild

```sh
sudo nixos-rebuild switch
```

This makes the new settings real. For NVIDIA it downloads the driver, so it
can take a few minutes. When it is done, the last lines have no red `error`.

> 💡 Using a flake whose name is not your computer's name? Then type
> `sudo nixos-rebuild switch --flake /etc/nixos#NAME`, with the name from
> `nixosConfigurations.NAME` in your `flake.nix`.

### Step 5: Restart

```sh
sudo reboot
```

Graphics drivers start when the computer starts, so this matters.

### Step 6: Check that it worked

- **NVIDIA:** type `nvidia-smi`. You should see a table with your card's
  name in it.
- **Intel or AMD:** if Hyprland starts and feels smooth, it works.

That's it. 🎉 Go on with [step 4 of the install guide](install.md#step-4-set-up-hyprsimple-for-your-user).

---

## The manual way: what goes in the file, and why

Read this if you want to know what the easy way did, or if you want to write
`gpu.nix` yourself. Save your file as `/etc/nixos/gpu.nix`, then do steps 3
to 6 above.

Every `gpu.nix` has the same frame. Your settings go between the curly
brackets:

```nix
{ config, pkgs, ... }:
{
  # your settings go here
}
```

Lines that start with `#` are notes for people. The computer skips them.

### Find out what graphics you have

Type:

```sh
lspci -nn | grep -E 'VGA|3D|Display'
```

You get one line per graphics chip. The words tell you the maker:

- `Intel Corporation ...` → Intel. Read [Intel](#intel).
- `Advanced Micro Devices, Inc. [AMD/ATI] ...` → AMD. Read [AMD](#amd).
- `NVIDIA Corporation ...` → NVIDIA. Read [NVIDIA](#nvidia).

**Two lines?** Then you have two graphics chips. That is normal for laptops.
If one of them is NVIDIA, read [A computer with two graphics chips](#a-computer-with-two-graphics-chips).

### Intel

Intel graphics work without any setup. These settings make two things
better:

- **Videos** play on the graphics chip instead of the main processor, so they
  use less battery and stay smooth.
- **Laptops** stay cooler, thanks to a helper called `thermald`. hyprsimple
  turns it on for Intel laptops on Arch too. On a desktop, leave that part
  out.

This is the whole `gpu.nix` for a laptop with Intel graphics:

```nix
# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: Intel UHD Graphics 620.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # Intel graphics. Lets videos play on the graphics chip, so they use less power.
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver # Intel chips from 2015 and newer
    intel-vaapi-driver # older Intel chips
  ];

  # Keeps an Intel laptop cool and quiet. hyprsimple turns this on for Intel laptops too.
  services.thermald.enable = true;
}
```

### AMD

AMD graphics work without any setup, including games (Vulkan) and video
playback. One small extra makes the screen look right from the very first
moment of booting:

```nix
# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: AMD Radeon RX 6700/6700 XT/6750 XT / 6800M/6850M XT.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # AMD graphics already works. This starts the AMD driver earlier,
  # so the screen looks right from the very start of the boot.
  hardware.amdgpu.initrd.enable = true;
}
```

**A very old AMD card?** The Radeon HD 7000 and HD 8000 series, and the R7 and
R9 200 series (from around 2012 to 2014), work better with this extra line
next to the other one:

```nix
  # Old AMD cards (Radeon HD 7000 and 8000, R7 and R9 200): use the newer amdgpu driver.
  hardware.amdgpu.legacySupport.enable = true;
```

### NVIDIA

NVIDIA cards need NVIDIA's own driver, and you must turn it on. Which driver
depends on how new your card is. Find your card in this table:

| Your card | Which kind | What to do |
|---|---|---|
| GTX 1600 series, RTX 2000, 3000, 4000, 5000 series, MX 450 and newer | **Newer** | [Newer NVIDIA card](#newer-nvidia-card) |
| GTX 900 series, GTX 1000 series, MX 100 to MX 300, Titan X, Xp, V | **Older** | [Older NVIDIA card](#older-nvidia-card) |
| GTX 700 series and anything older | **Too old** | Nothing. See below. |

**Too old:** NVIDIA's driver for these cards cannot run Hyprland. NixOS uses
the free `nouveau` driver for them by itself. It works, but slowly.

**Laptop?** Most laptops with NVIDIA also have Intel or AMD graphics. Then
read [A computer with two graphics chips](#a-computer-with-two-graphics-chips)
instead.

#### Newer NVIDIA card

This is the whole `gpu.nix` for a desktop with a newer NVIDIA card:

```nix
# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: NVIDIA GeForce RTX 3060 Lite Hash Rate.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # NVIDIA graphics card: GeForce GTX 1600, RTX 2000 or newer.
  nixpkgs.config.allowUnfree = true; # NVIDIA's driver is not open source; this says that is OK
  services.xserver.videoDrivers = [ "nvidia" ]; # says "xserver", but this is what turns the driver on
  hardware.nvidia = {
    open = true; # these cards use NVIDIA's open kernel module
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  # hyprsimple sets these on Arch when NVIDIA is the only graphics card.
  environment.sessionVariables = {
    NVD_BACKEND = "direct";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
```

What the lines do:

- `allowUnfree` says it is OK to install NVIDIA's driver, which is not open
  source. Without it, the rebuild stops with an error about an "unfree
  license".
- `videoDrivers = [ "nvidia" ]` turns the NVIDIA driver on. The word
  `xserver` is old naming; this is needed for Hyprland too.
- `open = true` picks NVIDIA's open kernel module, which these cards use.
- `stable` is the newest driver NVIDIA recommends.
- The `sessionVariables` are the same three settings hyprsimple writes on
  Arch when NVIDIA is the only graphics card. They make videos and older
  programs use the NVIDIA card.

#### Older NVIDIA card

The newest NVIDIA drivers stopped supporting these cards, so they use the
last driver that does (version 580). This is the whole `gpu.nix`:

```nix
# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: NVIDIA GeForce GTX 1070.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # Older NVIDIA graphics card: GeForce GTX 900 or GTX 1000 (and the Titans of those years).
  nixpkgs.config.allowUnfree = true; # NVIDIA's driver is not open source; this says that is OK
  services.xserver.videoDrivers = [ "nvidia" ]; # says "xserver", but this is what turns the driver on
  hardware.nvidia = {
    open = false; # these cards need NVIDIA's closed kernel module
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580; # the last driver for these cards
  };
  # hyprsimple sets these on Arch when NVIDIA is the only graphics card.
  environment.sessionVariables = {
    NVD_BACKEND = "egl";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
```

The differences from a newer card: `open = false` (these cards need NVIDIA's
closed kernel module), the `legacy_580` driver, and the session settings
hyprsimple uses for these cards on Arch.

### A computer with two graphics chips

Most laptops with NVIDIA have two graphics chips:

- a **built-in** one (Intel or AMD), which is small and saves battery, and
- the **NVIDIA** card, which is strong but uses a lot of power.

The best setup, and the one hyprsimple uses on Arch: the built-in chip draws
your desktop, and the NVIDIA card sleeps until you need it. To run a game or
a heavy program on the NVIDIA card, start it with `nvidia-offload`:

```sh
nvidia-offload blender
```

For Steam games, right-click the game → **Properties** → **Launch options**,
and type `nvidia-offload %command%`.

This is the whole `gpu.nix` for a laptop with Intel graphics and a newer
NVIDIA card:

```nix
# Graphics settings for this computer, written by 'hyprsimple-nixos gpu'.
# Found: Intel Iris Xe Graphics, NVIDIA GeForce RTX 4060 Max-Q / Mobile.
# Guide: https://github.com/mysh264/hyprsimple-nix/blob/main/docs/gpu.md
{ config, pkgs, ... }:
{
  # Intel graphics. Lets videos play on the graphics chip, so they use less power.
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver # Intel chips from 2015 and newer
    intel-vaapi-driver # older Intel chips
  ];

  # Keeps an Intel laptop cool and quiet. hyprsimple turns this on for Intel laptops too.
  services.thermald.enable = true;

  # Two graphics chips: the built-in one draws your desktop, and the NVIDIA card
  # (GTX 1600, RTX 2000 or newer) helps only programs you start with `nvidia-offload`.
  nixpkgs.config.allowUnfree = true; # NVIDIA's driver is not open source; this says that is OK
  services.xserver.videoDrivers = [ "nvidia" ]; # says "xserver", but this is what turns the driver on
  hardware.nvidia = {
    open = true; # these cards use NVIDIA's open kernel module
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.finegrained = true; # laptops: switches the NVIDIA card off when nothing uses it
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # gives you the `nvidia-offload` command
      intelBusId = "PCI:0:2:0"; # the built-in graphics chip
      nvidiaBusId = "PCI:1:0:0"; # the NVIDIA card
    };
  };
}
```

**Your laptop is different? Change these things:**

- **AMD instead of Intel built-in graphics:** leave out the two Intel parts
  at the top, put the [AMD](#amd) line there, and write `amdgpuBusId` instead
  of `intelBusId`.
- **Older NVIDIA card:** write `open = false;` and use `legacy_580` instead
  of `stable`, and leave out the `powerManagement.finegrained` line. Older
  cards cannot switch themselves off.
- **A desktop computer:** leave out the `thermald` part and the
  `powerManagement.finegrained` line.
- **The two bus IDs.** They tell NixOS which chip is which, and yours may be
  different. Read on.

#### Finding the bus IDs

The easy way finds them for you. To find them by hand, type:

```sh
lspci -D | grep -E 'VGA|3D|Display'
```

You get lines like these:

```
0000:00:02.0 VGA compatible controller: Intel Corporation Raptor Lake-P [Iris Xe Graphics]
0000:01:00.0 3D controller: NVIDIA Corporation AD107M [GeForce RTX 4060 Max-Q / Mobile]
```

The address at the start of each line, after `0000:`, is what you need.
`00:02.0` becomes `PCI:0:2:0`, and `01:00.0` becomes `PCI:1:0:0`. Take the
three numbers, drop the zeros in front, and put `PCI:` in front.

⚠️ **One catch:** these numbers are written in *hexadecimal*, a way of
counting that also uses the letters a to f. NixOS wants normal numbers.
If you see a letter, or a number of 10 or more, convert it with this
command (here for `65:00.0`):

```sh
printf 'PCI:%d:%d:%d\n' 0x65 0x00 0x0
```

It prints `PCI:101:0:0`.

---

## Games and Steam

To play games with Steam, add this to `configuration.nix`:

```nix
  programs.steam.enable = true;
  nixpkgs.config.allowUnfree = true; # Steam is not open source either
```

It also turns on 32-bit graphics, which many games need, for every kind of
graphics card.

## Virtual machines

Inside a virtual machine (VirtualBox, VMware, GNOME Boxes, virt-manager),
nothing needs to go in `gpu.nix`. But Hyprland needs **3D acceleration**.
Turn it on in your virtual machine's display settings. In virt-manager, pick
the **Virtio** video model and tick **3D acceleration**, then set the display
to **OpenGL**. Without it, Hyprland still runs, but slowly, and your
wallpaper does not show.

## ARM computers

ARM computers (like a Raspberry Pi, or an Apple Silicon Mac running Asahi
Linux) have not been tested with hyprsimple-nix yet. Their graphics drivers
come from NixOS's normal settings for those machines. If you try it, please
[tell us how it went](https://github.com/mysh264/hyprsimple-nix/issues).

---

## When something goes wrong

**The screen stays black after the rebuild, or the computer does not start.**
Restart. In the start menu, pick an older entry. Then look at your
`gpu.nix` again. The usual mistakes: the wrong kind of NVIDIA card (newer or
older), or wrong bus IDs on a laptop.

**The rebuild stops with "has an unfree license" and "refusing to evaluate".**
The `nixpkgs.config.allowUnfree = true;` line is missing.

**The rebuild says `nixpkgs.config` is ignored, or that the system "configures
nixpkgs with an externally created instance".** Your flake makes its own
`pkgs`. Put `config.allowUnfree = true;` where your flake writes
`import nixpkgs { ... }`, and take the `allowUnfree` line out of `gpu.nix`.

**The rebuild says `attribute 'legacy_580' missing`.** Your NixOS is too old
for this guide. Update it to 26.05 or newer first.

**NVIDIA: after the computer sleeps and wakes up, the picture is broken.**
Add this line inside the `hardware.nvidia = { ... };` part of `gpu.nix`, and
rebuild:

```nix
    powerManagement.enable = true;
```

**Something else?** See [When something goes wrong](troubleshooting.md), or
[ask](https://github.com/mysh264/hyprsimple-nix/issues). Paste what
`hyprsimple-nixos gpu` prints; it helps.
