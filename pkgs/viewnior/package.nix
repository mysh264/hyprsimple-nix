{ viewnior }:

# Viewnior, the photo viewer, mended for Wayland. Running it with
# GDK_BACKEND=x11 was the usual way around both of these.
viewnior.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    # Viewnior only read the scrolling that comes in clicks, like a mouse
    # wheel's. On Wayland, GTK hands a touchpad's two-finger scrolling over
    # as smooth scrolling only, so two fingers did nothing: no zoom, no next
    # photo. Now smooth scrolling makes the steps a wheel makes: each whole
    # unit is one step, as X11 counts a touchpad, and a wheel's click stays
    # exactly one step.
    ./0001-touchpad-scrolling-on-wayland.patch
    # Dragging a zoomed-in photo, and the crop dialog's rectangle, drew
    # straight onto the window, outside GTK's drawing. That only shows on
    # X11: on Wayland the photo stood still while dragged. Now both are
    # redrawn through GTK.
    ./0002-draw-through-gtk-on-wayland.patch
  ];
})
