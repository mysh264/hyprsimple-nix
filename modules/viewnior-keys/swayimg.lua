-- Viewnior's keys and mouse for swayimg 5, from hyprsimple-nix
-- (programs.hyprsimple.viewniorKeys.enable). swayimg reads a
-- ~/.config/swayimg/init.lua of your own instead of this file: copy this one
-- there to change it.

local viewer = swayimg.viewer
local slideshow = swayimg.slideshow

-- Opens the next photo in a direction: "next", "prev", "first" or "last".
-- open() since swayimg 5.7, switch_image() before.
local open = viewer.open or viewer.switch_image

-- As in Viewnior, the other photos in the same folder come along, so the
-- keys below can turn to them. (A setting since swayimg 5.5.)
pcall(function()
  swayimg.imagelist.adjacent = true
end)

-- A slideshow turns to the next photo every 5 seconds, as in Viewnior.
slideshow.timeout = 5

local function keys(names, action)
  for _, name in ipairs(names) do
    viewer.on_key(name, action)
  end
end

local function go(direction)
  return function()
    open(direction)
  end
end

-- Whether the whole photo is in the window. Viewnior's arrow keys turn to
-- the next photo then, and move about in a zoomed-in photo otherwise.
local function fits()
  local image = viewer.get_image()
  if not image then
    return true
  end
  local window = swayimg.get_window_size()
  local scale = viewer.scale
  return image.width * scale <= window.width and image.height * scale <= window.height
end

-- Moves the photo by a part of the window.
local function pan(dx, dy)
  local window = swayimg.get_window_size()
  local position = viewer.get_position()
  viewer.set_abs_position(position.x + math.floor(window.width * dx), position.y + math.floor(window.height * dy))
end

local function arrow(direction, dx, dy)
  return function()
    if fits() then
      open(direction)
    else
      pan(dx, dy)
    end
  end
end

local function zoom(factor)
  return function()
    viewer.scale = viewer.scale * factor
  end
end

local function scale(value)
  return function()
    viewer.set_abs_scale(value)
  end
end

-- The next and the previous photo, the first and the last.
keys({ "space", "Next", "Alt+Right" }, go("next"))
keys({ "BackSpace", "Prior", "Alt+Left" }, go("prev"))
keys({ "Home", "Alt+Home" }, go("first"))
keys({ "End", "Alt+End" }, go("last"))
viewer.on_key("Left", arrow("prev", 0.1, 0))
viewer.on_key("Right", arrow("next", -0.1, 0))
viewer.on_key("Up", arrow("prev", 0, 0.1))
viewer.on_key("Down", arrow("next", 0, -0.1))
viewer.on_key("Shift+Left", function()
  pan(0.9, 0)
end)
viewer.on_key("Shift+Right", function()
  pan(-0.9, 0)
end)
viewer.on_key("Shift+Up", function()
  pan(0, 0.9)
end)
viewer.on_key("Shift+Down", function()
  pan(0, -0.9)
end)

-- Zoom. + on most keyboards is typed with Shift, so both are here.
keys({
  "plus",
  "Shift+plus",
  "equal",
  "KP_Add",
  "Shift+KP_Add",
  "Ctrl+plus",
  "Ctrl+Shift+plus",
  "Ctrl+equal",
  "Ctrl+KP_Add",
}, zoom(1.1))
keys({ "minus", "KP_Subtract", "Ctrl+minus", "Ctrl+KP_Subtract" }, zoom(1 / 1.1))
keys({ "1", "KP_1", "Ctrl+0" }, scale(1))
keys({ "2", "KP_2" }, scale(2))
keys({ "3", "KP_3" }, scale(3))
keys({ "f", "0", "KP_0" }, function()
  viewer.set_fix_scale("fit")
end)

-- Full screen, slideshow, closing.
viewer.on_key("F11", function()
  swayimg.fullscreen = not swayimg.fullscreen
end)
viewer.on_key("Escape", function()
  if swayimg.fullscreen then
    swayimg.fullscreen = false
  else
    swayimg.exit()
  end
end)
viewer.on_key("Ctrl+w", function()
  swayimg.exit()
end)
viewer.on_key("F5", function()
  swayimg.mode = "slideshow"
end)
slideshow.on_key("F5", function()
  swayimg.mode = "viewer"
end)
slideshow.on_key("Escape", function()
  swayimg.mode = "viewer"
end)

-- Turn and flip.
viewer.on_key("Ctrl+r", function()
  viewer.rotate(90)
end)
keys({ "Ctrl+Shift+r", "Ctrl+Shift+R" }, function()
  viewer.rotate(270)
end)
viewer.on_key("h", function()
  viewer.flip_horizontal()
end)
viewer.on_key("v", function()
  viewer.flip_vertical()
end)

-- Delete moves the photo to the trash, where you can get it back.
viewer.on_key("Delete", function()
  local image = viewer.get_image()
  if not image then
    return
  end
  local quoted = "'" .. image.path:gsub("'", "'\\''") .. "'"
  local done = os.execute("@gio@ trash -- " .. quoted)
  if done == true or done == 0 then
    swayimg.imagelist.remove(image.path)
    swayimg.text.status = "Moved to the trash"
  else
    swayimg.text.status = "Could not move it to the trash"
  end
end)

-- The mouse: the side buttons turn photos, the wheel zooms where the pointer
-- is, and with Shift it turns photos. Dragging with the left button moves a
-- zoomed-in photo, as swayimg already does.
viewer.on_mouse("MouseSide", go("prev"))
viewer.on_mouse("MouseExtra", go("next"))
if viewer.on_scroll then
  -- Scrolling comes in parts of a step on a touchpad. These count up to
  -- whole steps before the photo turns.
  local turned = 0
  local function turn(amount)
    turned = turned + amount
    while turned >= 1 do
      open("next")
      turned = turned - 1
    end
    while turned <= -1 do
      open("prev")
      turned = turned + 1
    end
  end
  viewer.on_scroll(function(mods, horizontal, vertical)
    if mods == "Shift" then
      turn(vertical)
    elseif math.abs(horizontal) > math.abs(vertical) then
      -- Sideways, as on a tilting wheel or with two fingers.
      turn(horizontal)
    else
      local mouse = swayimg.get_mouse_pos()
      local current = viewer.scale
      viewer.set_abs_scale(current - current * vertical / 10, mouse.x, mouse.y)
    end
  end)
end
