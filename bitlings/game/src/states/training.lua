-- Training gyms (Lounge). One minigame per data type; the score becomes data.
--   forge   (Build)   Hammer Timing : stop the sweeping marker in the hot zone (6 strikes)
--   pulse   (Pulse)   Beat Relay    : press the arrow as each note hits the line (12 notes)
--   archive (Archive) Recall Chain  : repeat a growing arrow sequence (5 rounds)
-- Training costs hunger (Growth.TRAIN_HUNGER). Timing windows scale with the
-- Timing setting (Pause menu).

local C = require("src.data.config")
local K = require("src.data.content")
local Growth = require("src.systems.growth")
local Input = require("src.input.input")
local UI = require("src.ui.ui")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Sparkbit = require("src.entities.sparkbit")

local Training = {}
Training.__index = Training
Training.name = "training"

Training.GYMS = {
  forge = { name = "Forge Node", game = "Hammer Timing", type = "build",
    how = "Press A when the marker is inside the hot zone. 6 strikes, faster each time." },
  pulse = { name = "Pulse Tower", game = "Beat Relay", type = "pulse",
    how = "Press the matching arrow as each note reaches the line. 12 notes." },
  archive = { name = "Archive Hall", game = "Recall Chain", type = "archive",
    how = "Watch the arrow sequence, then repeat it. It grows every round." },
}
Training.ORDER = { "forge", "pulse", "archive" }

local DIRS = { "left", "up", "right", "down" }
local PULSE_DIRS = { "left", "up", "right" }
local PULSE_PATTERN = { 1, 2, 3, 2, 1, 3, 3, 1, 2, 1, 3, 2 }
local ARCHIVE_SEED = { 2, 4, 1, 3, 2, 1, 4, 3, 1, 2, 3, 4 }
local FORGE_CENTERS = { 0.5, 0.3, 0.7, 0.42, 0.62, 0.35 }

function Training.new(game, gym, on_done)
  local self = setmetatable({ game = game, data = game.data, gym = gym, G = Training.GYMS[gym],
    on_done = on_done, t = 0, phase = "intro" }, Training)
  self.tm = Growth.timing_mult(game.data)
  self.spark = Sparkbit.new(84, 400)
  self.spark.scale = 3
  self.spark:set_appearance(Growth.appearance(game.data))
  self.spark:set_state("idle")
  self.flash = nil
  return self
end

function Training:feedback(text, color)
  self.flash = { text = text, color = color, t = 0.6 }
end

-- Setup per game ----------------------------------------------------------------
function Training:start()
  self.phase = "play"
  self.pt = 0
  self.points, self.max_points = 0, 1
  if self.gym == "forge" then
    self.strike, self.max_points = 1, 6
    self.p, self.dir = 0, 1
    self.cooldown = 0
  elseif self.gym == "pulse" then
    self.notes = {}
    for i, d in ipairs(PULSE_PATTERN) do
      self.notes[i] = { dir = PULSE_DIRS[d], time = 1.2 + (i - 1) * 0.6, judged = false }
    end
    self.max_points = #self.notes
  elseif self.gym == "archive" then
    self.round, self.rounds = 1, 5
    self.max_points = self.rounds
    self:archive_round()
  end
end

-- Forge ---------------------------------------------------------------------------
function Training:forge_zone()
  return FORGE_CENTERS[self.strike], 0.16 * self.tm
end

function Training:forge_bot_ready()
  if self.gym ~= "forge" or self.phase ~= "play" or self.cooldown > 0 then return false end
  local c, w = self:forge_zone()
  return math.abs(self.p - c) < w / 8
end

function Training:update_forge(dt)
  if self.cooldown > 0 then
    self.cooldown = self.cooldown - dt
    if self.cooldown <= 0 and self.strike > 6 then self:finish() end
    return
  end
  local speed = 0.8 + 0.15 * self.strike
  self.p = self.p + self.dir * speed * dt
  if self.p > 1 then self.p, self.dir = 1, -1 elseif self.p < 0 then self.p, self.dir = 0, 1 end
  if Input.pressed("confirm") then
    local c, w = self:forge_zone()
    local d = math.abs(self.p - c)
    if d <= w / 6 then self.points = self.points + 1; self:feedback("PERFECT", C.colors.amber); Sfx.play("good")
      self.spark:set_state("happy")
    elseif d <= w / 2 then self.points = self.points + 0.6; self:feedback("GOOD", C.colors.green); Sfx.play("blip")
      self.spark:set_state("building", 0.4)
    else self:feedback("MISS", C.colors.glitch); Sfx.play("error") end
    self.strike = self.strike + 1
    self.cooldown = 0.35
  end
end

-- Pulse --------------------------------------------------------------------------------
function Training:pulse_windows() return 0.05 * self.tm, 0.13 * self.tm end

function Training:pulse_bot_dir()
  if self.gym ~= "pulse" or self.phase ~= "play" then return nil end
  for _, n in ipairs(self.notes) do
    if not n.judged and math.abs(n.time - self.pt) < 0.02 then return n.dir end
  end
  return nil
end

function Training:update_pulse(dt)
  self.pt = self.pt + dt
  local perfect, good = self:pulse_windows()
  for _, dir in ipairs(PULSE_DIRS) do
    if Input.pressed(dir) then
      local best, bd
      for _, n in ipairs(self.notes) do
        if not n.judged then
          local d = math.abs(n.time - self.pt)
          if d <= good and (not bd or d < bd) then best, bd = n, d end
        end
      end
      if best then
        best.judged = true
        if best.dir ~= dir then self:feedback("WRONG", C.colors.glitch); Sfx.play("error")
        elseif bd <= perfect then self.points = self.points + 1; self:feedback("PERFECT", C.colors.amber); Sfx.play("good")
          self.spark:set_state("happy")
        else self.points = self.points + 0.6; self:feedback("GOOD", C.colors.green); Sfx.play("blip") end
      end
    end
  end
  for _, n in ipairs(self.notes) do
    if not n.judged and self.pt > n.time + good then n.judged = true; self:feedback("MISS", C.colors.glitch) end
  end
  if self.pt > self.notes[#self.notes].time + 0.6 then self:finish() end
end

-- Archive --------------------------------------------------------------------------------
function Training:archive_round()
  local len = 2 + self.round
  self.seq = {}
  for i = 1, len do self.seq[i] = DIRS[ARCHIVE_SEED[((i + self.round * 3) - 1) % #ARCHIVE_SEED + 1]] end
  self.sub = "show"
  self.show_t = 0
  self.input_i = 1
end

function Training:archive_showing_index()
  local per = 0.6
  local i = math.floor(self.show_t / per) + 1
  if i > #self.seq then return nil end
  if (self.show_t % per) > per * 0.75 then return 0 end
  return i
end

function Training:update_archive(dt)
  if self.sub == "show" then
    self.show_t = self.show_t + dt
    if self.show_t > #self.seq * 0.6 + 0.3 then self.sub = "input" end
    return
  end
  if self.sub == "pause" then
    self.show_t = self.show_t - dt
    if self.show_t <= 0 then
      if self.round > self.rounds or self.failed then self:finish() else self:archive_round() end
    end
    return
  end
  for _, dir in ipairs(DIRS) do
    if Input.pressed(dir) then
      if self.seq[self.input_i] == dir then
        self.input_i = self.input_i + 1
        Sfx.play("blip")
        if self.input_i > #self.seq then
          self.points = self.points + 1
          self:feedback("CHAIN " .. self.round .. " OK", C.colors.green)
          self.spark:set_state("happy")
          self.round = self.round + 1
          self.sub, self.show_t = "pause", 0.7
        end
      else
        self.failed = true
        self:feedback("CHAIN BROKEN", C.colors.glitch)
        Sfx.play("error")
        self.sub, self.show_t = "pause", 0.7
      end
      return
    end
  end
end

-- Flow ------------------------------------------------------------------------------------
function Training:finish()
  self.phase = "result"
  self.score = math.min(1, self.points / self.max_points)
  self.gained = Growth.training_reward(self.data, self.G.type, self.score)
  self.spark:set_state(self.score >= 0.6 and "celebrate" or "idle", 999)
  self.spark:set_appearance(Growth.appearance(self.data))
  Sfx.play("level")
  self.res_t = 0
end

function Training:update(dt)
  self.t = self.t + dt
  self.spark:update(dt, 0, 0, nil)
  self.spark.x, self.spark.y = 84, 400
  if self.flash then
    self.flash.t = self.flash.t - dt
    if self.flash.t <= 0 then self.flash = nil end
  end
  if self.phase == "intro" then
    if Input.pressed("confirm") then Sfx.play("confirm"); self:start()
    elseif Input.pressed("cancel") then SM.pop() end
  elseif self.phase == "play" then
    if self.gym == "forge" then self:update_forge(dt)
    elseif self.gym == "pulse" then self:update_pulse(dt)
    else self:update_archive(dt) end
  elseif self.phase == "result" then
    self.res_t = self.res_t + dt
    if self.res_t > 0.8 and Input.pressed("confirm") then
      Sfx.play("confirm")
      SM.pop()
      if self.on_done then self.on_done({ gym = self.gym, score = self.score, gained = self.gained }) end
    end
  end
end

-- Draw ---------------------------------------------------------------------------------------
local function arrow(dir, x, y, s, col, a)
  UI.setColor(col, a or 1)
  local lg = love.graphics
  if dir == "left" then lg.polygon("fill", x - s, y, x + s, y - s, x + s, y + s)
  elseif dir == "right" then lg.polygon("fill", x + s, y, x - s, y - s, x - s, y + s)
  elseif dir == "up" then lg.polygon("fill", x, y - s, x - s, y + s, x + s, y + s)
  else lg.polygon("fill", x, y + s, x - s, y - s, x + s, y - s) end
end

function Training:draw()
  local lg = love.graphics
  local col = C.hex(K.TYPE_COLOR[self.G.type])
  lg.clear(C.hex("07101c"))
  UI.setColor(col, 0.05)
  for y = 0, C.HEIGHT, 4 do lg.rectangle("fill", 0, y, C.WIDTH, 1) end
  UI.panel(16, 12, C.WIDTH - 32, 40, col)
  UI.text(self.G.name:upper() .. " // " .. self.G.game, 32, 22, col, UI.font)
  UI.text("Trains " .. K.TYPE_NAME[self.G.type] .. " data", 0, 22, C.colors.dim, UI.font_small, "right", C.WIDTH - 36)

  if self.phase ~= "intro" then
    if self.gym == "forge" then self:draw_forge(col)
    elseif self.gym == "pulse" then self:draw_pulse(col)
    else self:draw_archive(col) end
  end
  self.spark:draw()
  if self.flash then
    local c = self.flash.color
    UI.text(self.flash.text, 0, 330, { c[1], c[2], c[3], math.min(1, self.flash.t * 3) }, UI.font_big, "center", C.WIDTH)
  end

  if self.phase == "intro" then
    UI.panel(90, 120, 460, 220, col)
    UI.text(self.G.game, 90, 136, col, UI.font_big, "center", 460)
    UI.text(self.G.how, 114, 180, C.colors.text, UI.font, "center", 412)
    UI.text("Costs " .. Growth.TRAIN_HUNGER .. " hunger. Score becomes " .. K.TYPE_NAME[self.G.type] .. " data.", 90, 252,
      C.colors.dim, UI.font_small, "center", 460)
    UI.prompts({ { "confirm", "Start" }, { "cancel", "Back" } }, 530, 304, true)
  elseif self.phase == "result" then
    UI.setColor(C.colors.bg, 0.75)
    lg.rectangle("fill", 0, 0, C.WIDTH, C.HEIGHT)
    UI.panel(140, 140, 360, 190, col)
    local pct = math.floor(self.score * 100)
    UI.text(pct >= 90 and "PERFECT TRAINING" or "TRAINING DONE", 140, 156, col, UI.font_big, "center", 360)
    UI.text("Score " .. pct .. "%", 140, 200, C.colors.text, UI.font, "center", 360)
    UI.text("+" .. self.gained .. " " .. K.TYPE_NAME[self.G.type] .. " data absorbed", 140, 228, col, UI.font, "center", 360)
    UI.text("-" .. Growth.TRAIN_HUNGER .. " hunger, +3 mood", 140, 254, C.colors.dim, UI.font_small, "center", 360)
    if self.res_t > 0.8 then UI.prompts({ { "confirm", "Done" } }, 480, 296, true) end
  end
end

function Training:draw_forge(col)
  local lg = love.graphics
  local x0, y0, w, h = 80, 200, 480, 40
  UI.setColor(C.colors.outline)
  lg.rectangle("fill", x0, y0, w, h, 6, 6)
  if self.strike <= 6 then
    local c, zw = self:forge_zone()
    UI.setColor(col, 0.35)
    lg.rectangle("fill", x0 + (c - zw / 2) * w, y0, zw * w, h)
    UI.setColor(col, 0.9)
    lg.rectangle("fill", x0 + (c - zw / 6) * w, y0, zw / 3 * w, h)
  end
  UI.setColor(C.colors.white)
  lg.rectangle("fill", x0 + self.p * w - 3, y0 - 10, 6, h + 20)
  UI.text(string.format("Strike %d/6", math.min(6, self.strike)), 0, 260, C.colors.text, UI.font, "center", C.WIDTH)
  -- anvil
  UI.setColor(C.colors.wall_top)
  lg.rectangle("fill", 280, 120, 80, 30, 4, 4)
  UI.setColor(col)
  lg.rectangle("fill", 300, 100 - (self.cooldown > 0 and 0 or 12), 40, 14, 3, 3)
end

function Training:draw_pulse(col)
  local lg = love.graphics
  local line_y = 300
  local lanes = { left = 220, up = 320, right = 420 }
  for dir, x in pairs(lanes) do
    UI.setColor(C.colors.outline)
    lg.rectangle("fill", x - 30, 70, 60, 260, 6, 6)
    arrow(dir, x, line_y, 16, col, 0.35)
  end
  UI.setColor(col, 0.8)
  lg.rectangle("fill", 180, line_y + 22, 280, 3)
  for _, n in ipairs(self.notes) do
    if not n.judged then
      local y = line_y - (n.time - self.pt) * 220
      if y > 60 and y < 340 then arrow(n.dir, lanes[n.dir], y, 14, C.colors.white) end
    end
  end
  local left = 0
  for _, n in ipairs(self.notes) do if not n.judged then left = left + 1 end end
  UI.text("Notes left " .. left, 480, 90, C.colors.text, UI.font_small)
end

function Training:draw_archive(col)
  local lg = love.graphics
  UI.text("Round " .. math.min(self.round, self.rounds) .. "/" .. self.rounds .. "   length " .. #self.seq, 0, 74, C.colors.text, UI.font, "center", C.WIDTH)
  if self.sub == "show" then
    local i = self:archive_showing_index()
    UI.text("WATCH", 0, 110, col, UI.font_big, "center", C.WIDTH)
    if i and i > 0 then arrow(self.seq[i], 320, 220, 40, col) end
  elseif self.sub == "input" then
    UI.text("REPEAT IT", 0, 110, C.colors.white, UI.font_big, "center", C.WIDTH)
    for k = 1, #self.seq do
      local x = 320 - (#self.seq - 1) * 26 + (k - 1) * 52
      if k < self.input_i then arrow(self.seq[k], x, 220, 16, col)
      else
        UI.setColor(C.colors.outline)
        lg.circle("fill", x, 220, 14)
      end
    end
  end
end

return Training
