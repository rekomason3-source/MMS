-- Abstract input: game code asks for ACTIONS, never keys or buttons.
-- Sources merged every frame: keyboard, any SDL gamepad, and virtual
-- (scripted) input used by the autotest harness.
--
-- Action  | Gamepad (SDL)  | Keyboard
-- --------+----------------+--------------------
-- move    | D-pad / L-stick| Arrows / WASD
-- confirm | A              | Z / Enter / Space
-- cancel  | B              | X / Backspace
-- skill1  | X              | C        (FlowSort)
-- skill2  | Y              | V        (Pet)
-- l1 / r1 | L1 / R1        | Q / E
-- l2 / r2 | L2 / R2 (axis) | 1 / 2
-- pause   | Start          | Esc / P
-- map     | Select         | Tab / M  (objectives)
-- debug   | R3             | F3       (perf overlay)

local Input = {}

Input.swap_ab = false
Input.deadzone = 0.3
Input.last_device = "keyboard"

local ACTIONS = {
  "up", "down", "left", "right", "confirm", "cancel", "skill1", "skill2",
  "l1", "r1", "l2", "r2", "pause", "map", "debug",
}
Input.ACTIONS = ACTIONS

Input.keys = {
  up = { "up", "w" }, down = { "down", "s" }, left = { "left", "a" }, right = { "right", "d" },
  confirm = { "z", "return", "space", "kpenter" }, cancel = { "x", "backspace" },
  skill1 = { "c" }, skill2 = { "v" }, l1 = { "q" }, r1 = { "e" }, l2 = { "1" }, r2 = { "2" },
  pause = { "escape", "p" }, map = { "tab", "m" }, debug = { "f3" },
}

Input.pad = {
  up = { "dpup" }, down = { "dpdown" }, left = { "dpleft" }, right = { "dpright" },
  confirm = { "a" }, cancel = { "b" }, skill1 = { "x" }, skill2 = { "y" },
  l1 = { "leftshoulder" }, r1 = { "rightshoulder" },
  pause = { "start" }, map = { "back" }, debug = { "rightstick" },
}

local PAD_LABEL = {
  confirm = "A", cancel = "B", skill1 = "X", skill2 = "Y", l1 = "L1", r1 = "R1",
  l2 = "L2", r2 = "R2", pause = "START", map = "SELECT", debug = "R3",
}
local KEY_LABEL = {
  confirm = "Z", cancel = "X", skill1 = "C", skill2 = "V", l1 = "Q", r1 = "E",
  l2 = "1", r2 = "2", pause = "ESC", map = "TAB", debug = "F3",
}

local cur, prev, held, blocked, rep_t, rep_fire = {}, {}, {}, {}, {}, {}
local virtual = {}
local stick_x, stick_y = 0, 0

local REPEAT_DELAY, REPEAT_RATE = 0.32, 0.09

local function gamepads()
  local list = {}
  if love and love.joystick then
    for _, j in ipairs(love.joystick.getJoysticks()) do
      if j:isGamepad() then list[#list + 1] = j end
    end
  end
  return list
end
Input.gamepads = gamepads

local function key_down(action)
  local ks = Input.keys[action]
  if ks and love and love.keyboard then
    for _, k in ipairs(ks) do
      if love.keyboard.isDown(k) then return true end
    end
  end
  return false
end

local function pad_down(action, pads)
  local a = action
  if Input.swap_ab then
    if a == "confirm" then a = "cancel" elseif a == "cancel" then a = "confirm" end
  end
  local bs = Input.pad[a]
  if not bs then return false end
  for _, j in ipairs(pads) do
    for _, b in ipairs(bs) do
      if j:isGamepadDown(b) then return true end
    end
  end
  return false
end

function Input.update(dt)
  local pads = gamepads()
  local sx, sy, l2, r2 = 0, 0, false, false
  for _, j in ipairs(pads) do
    local x, y = j:getGamepadAxis("leftx"), j:getGamepadAxis("lefty")
    if math.abs(x) > math.abs(sx) then sx = x end
    if math.abs(y) > math.abs(sy) then sy = y end
    if j:getGamepadAxis("triggerleft") > 0.5 then l2 = true end
    if j:getGamepadAxis("triggerright") > 0.5 then r2 = true end
  end
  local mag = math.sqrt(sx * sx + sy * sy)
  if mag < Input.deadzone then
    sx, sy = 0, 0
  else
    local m = math.min(1, (mag - Input.deadzone) / (1 - Input.deadzone))
    sx, sy = sx / mag * m, sy / mag * m
  end
  stick_x, stick_y = sx, sy

  for _, a in ipairs(ACTIONS) do
    prev[a] = cur[a] or false
    local k = key_down(a)
    local p = pad_down(a, pads)
    if a == "l2" then p = p or l2
    elseif a == "r2" then p = p or r2
    elseif a == "left" then p = p or sx < -0.5
    elseif a == "right" then p = p or sx > 0.5
    elseif a == "up" then p = p or sy < -0.5
    elseif a == "down" then p = p or sy > 0.5 end
    local v = virtual[a] ~= nil
    local d = k or p or v
    cur[a] = d
    if d and not prev[a] then
      if k then Input.last_device = "keyboard" elseif p then Input.last_device = "gamepad" end
    end
    if not d then blocked[a] = nil end
    rep_fire[a] = false
    if d then
      held[a] = (held[a] or 0) + dt
      if held[a] > REPEAT_DELAY then
        rep_t[a] = (rep_t[a] or 0) - dt
        if rep_t[a] <= 0 then rep_fire[a] = true; rep_t[a] = REPEAT_RATE end
      end
    else
      held[a] = 0
      rep_t[a] = 0
    end
  end

  for a, n in pairs(virtual) do
    if type(n) == "number" then
      n = n - 1
      virtual[a] = n > 0 and n or nil
    end
  end
end

function Input.down(a) return cur[a] == true and not blocked[a] end
function Input.pressed(a) return cur[a] == true and not prev[a] and not blocked[a] end
function Input.released(a) return not cur[a] and prev[a] == true end
function Input.held(a) return held[a] or 0 end
function Input.repeat_pressed(a) return Input.pressed(a) or (rep_fire[a] and not blocked[a]) end

-- Ignore every action currently down until it is released (e.g. after
-- remapping A/B so the still-held button doesn't fire its new meaning).
function Input.flush()
  for _, a in ipairs(ACTIONS) do blocked[a] = true end
end

-- Movement vector in [-1,1]^2, magnitude <= 1. Analog stick wins.
function Input.move()
  if stick_x ~= 0 or stick_y ~= 0 then return stick_x, stick_y end
  local x = (Input.down("right") and 1 or 0) - (Input.down("left") and 1 or 0)
  local y = (Input.down("down") and 1 or 0) - (Input.down("up") and 1 or 0)
  if x ~= 0 and y ~= 0 then x, y = x * 0.7071, y * 0.7071 end
  return x, y
end

function Input.label(a)
  if Input.last_device == "keyboard" then return KEY_LABEL[a] or a end
  local l = PAD_LABEL[a] or a
  if Input.swap_ab then
    if a == "confirm" then l = "B" elseif a == "cancel" then l = "A" end
  end
  return l
end

-- Virtual input (autotest / demos) ---------------------------------------
function Input.inject(a, frames) virtual[a] = frames or 1 end
function Input.hold(a, on) virtual[a] = on and "hold" or nil end
function Input.clear_virtual() virtual = {} end

return Input
