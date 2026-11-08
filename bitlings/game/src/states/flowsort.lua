-- FlowSort: Sparkbit's signature skill as a terminal event.
-- Data packets fall down the stream; send each to its channel before it
-- reaches the floor. Noise packets must be discarded. Deterministic order.
--
--   Left  -> BUILD (amber square)
--   Up    -> KNOWLEDGE (violet diamond)   (Down also accepted)
--   Right -> FOCUS (cyan triangle)
--   B     -> discard NOISE

local C = require("src.data.config")
local UI = require("src.ui.ui")
local Input = require("src.input.input")
local Sfx = require("src.core.sfx")
local SM = require("src.core.state")
local Sparkbit = require("src.entities.sparkbit")

local FlowSort = {}
FlowSort.__index = FlowSort
FlowSort.name = "flowsort"
FlowSort.gameplay = true

FlowSort.CHANNELS = {
  build = { label = "BUILD", x = 150, color = C.colors.amber, shape = "square", action = "left" },
  archive = { label = "ARCHIVE", x = 320, color = C.colors.violet, shape = "diamond", action = "up" },
  pulse = { label = "PULSE", x = 490, color = C.colors.cyan, shape = "triangle", action = "right" },
}
FlowSort.SEQUENCE = {
  "build", "archive", "pulse", "pulse", "build", "noise",
  "archive", "build", "pulse", "noise", "archive", "pulse",
}
FlowSort.NEED = 9
FlowSort.TOP, FlowSort.BOTTOM = 112, 330
FlowSort.BIN_Y = 392

function FlowSort.new(game, on_done)
  local self = setmetatable({ game = game, on_done = on_done, t = 0 }, FlowSort)
  self.spark = Sparkbit.new(70, 230)
  self.spark:set_state("sorting", 999)
  self:reset()
  return self
end

function FlowSort:reset()
  self.phase = "intro"
  self.idx = 0
  self.packet = nil
  self.score, self.wrong, self.misses = 0, 0, 0
  self.sorted = {}
  self.gap = 0
  self.flash = {}
  self.shake = 0
  self.feedback = nil
  self.result = nil
  self.sel = 1
end

function FlowSort:fall_time()
  return math.max(1.8, 3.2 - (self.idx - 1) * 0.13)
end

function FlowSort:spawn()
  self.idx = self.idx + 1
  local kind = FlowSort.SEQUENCE[self.idx]
  if not kind then self:finish() return end
  self.packet = { kind = kind, t = 0, fall = self:fall_time(), x = 320, y = FlowSort.TOP, resolved = false }
end

function FlowSort:resolve(choice)
  local p = self.packet
  if not p or p.resolved then return end
  p.resolved = true
  local correct = (p.kind == "noise" and choice == "discard") or (p.kind == choice)
  local tx, ty = 320, FlowSort.BIN_Y
  if choice == "discard" then tx, ty = 640, p.y
  elseif choice == "miss" then tx, ty = 320, 480
  else tx = FlowSort.CHANNELS[choice].x end
  p.fly = { x0 = p.x, y0 = p.y, x1 = tx, y1 = ty, t = 0 }
  if correct then
    self.score = self.score + 1
    if p.kind ~= "noise" then self.sorted[p.kind] = (self.sorted[p.kind] or 0) + 1 end
    if FlowSort.CHANNELS[choice] then self.flash[choice] = 0.35 end
    self.spark:set_state("happy")
    self.feedback = { text = p.kind == "noise" and "Noise filtered" or "Sorted", color = C.colors.green, t = 0.6 }
    Sfx.play("good")
  else
    if choice == "miss" then self.misses = self.misses + 1 else self.wrong = self.wrong + 1 end
    self.shake = 0.25
    self.spark:set_state("curious")
    self.feedback = { text = choice == "miss" and "Missed!" or "Wrong channel", color = C.colors.glitch, t = 0.7 }
    Sfx.play("error")
  end
end

function FlowSort:finish()
  self.phase = "result"
  self.packet = nil
  local success = self.score >= FlowSort.NEED
  self.result = {
    success = success,
    score = self.score,
    total = #FlowSort.SEQUENCE,
    wrong = self.wrong,
    misses = self.misses,
    perfect = self.score == #FlowSort.SEQUENCE,
    sorted = self.sorted,
  }
  self.spark:set_state(success and "celebrate" or "hurt")
  Sfx.play(success and "level" or "error")
  self.sel = 1
end

function FlowSort:update(dt)
  self.t = self.t + dt
  self.spark:update(dt, 0, 0, nil)
  if self.spark.state == "idle" and self.phase == "play" then self.spark:set_state("sorting", 999) end
  if self.shake > 0 then self.shake = self.shake - dt end
  for k, v in pairs(self.flash) do self.flash[k] = v > dt and v - dt or nil end
  if self.feedback then
    self.feedback.t = self.feedback.t - dt
    if self.feedback.t <= 0 then self.feedback = nil end
  end

  if self.phase == "intro" then
    if Input.pressed("confirm") then
      self.phase = "play"
      Sfx.play("confirm")
      self:spawn()
    elseif Input.pressed("cancel") then
      SM.pop()
      if self.on_done then self.on_done({ success = false, score = 0, misses = 0, aborted = true }) end
    end
    return
  end

  if self.phase == "result" then
    if self.result.success then
      if Input.pressed("confirm") then
        SM.pop()
        if self.on_done then self.on_done(self.result) end
      end
    else
      if Input.repeat_pressed("left") or Input.repeat_pressed("right") then self.sel = 3 - self.sel; Sfx.play("blip") end
      if Input.pressed("confirm") then
        if self.sel == 1 then self:reset(); self.phase = "play"; self:spawn()
        else SM.pop(); if self.on_done then self.on_done(self.result) end end
      elseif Input.pressed("cancel") then
        SM.pop()
        if self.on_done then self.on_done(self.result) end
      end
    end
    return
  end

  -- play
  local p = self.packet
  if p then
    if p.fly then
      p.fly.t = p.fly.t + dt / 0.18
      local f = math.min(1, p.fly.t)
      p.x = p.fly.x0 + (p.fly.x1 - p.fly.x0) * f
      p.y = p.fly.y0 + (p.fly.y1 - p.fly.y0) * f
      if f >= 1 then self.packet = nil; self.gap = 0.22 end
    else
      p.t = p.t + dt
      p.y = FlowSort.TOP + (FlowSort.BOTTOM - FlowSort.TOP) * (p.t / p.fall)
      if Input.pressed("left") then self:resolve("build")
      elseif Input.pressed("up") or Input.pressed("down") then self:resolve("archive")
      elseif Input.pressed("right") then self:resolve("pulse")
      elseif Input.pressed("cancel") then self:resolve("discard")
      elseif p.t >= p.fall then self:resolve("miss") end
    end
  else
    self.gap = self.gap - dt
    if self.gap <= 0 then self:spawn() end
  end
end

local function shape(kind, x, y, r, col, a)
  local lg = love.graphics
  UI.setColor(col, a)
  if kind == "square" then
    lg.rectangle("fill", x - r, y - r, r * 2, r * 2, 3, 3)
  elseif kind == "diamond" then
    lg.polygon("fill", x, y - r * 1.3, x + r * 1.3, y, x, y + r * 1.3, x - r * 1.3, y)
  elseif kind == "triangle" then
    lg.polygon("fill", x, y - r * 1.2, x + r * 1.2, y + r, x - r * 1.2, y + r)
  end
end

function FlowSort:draw_packet(p)
  local lg = love.graphics
  local x, y = p.x, p.y
  if p.kind == "noise" then
    for i = 0, 15 do
      local ox = ((i * 7 + math.floor(self.t * 30)) % 8) * 4 - 14
      local oy = math.floor(i / 4) * 7 - 12
      UI.setColor(i % 3 == 0 and C.colors.white or C.colors.dim, 0.9)
      lg.rectangle("fill", x + ox, y + oy, 4, 4)
    end
    UI.text("NOISE", x - 40, y + 20, C.colors.dim, UI.font_small, "center", 80)
    return
  end
  local ch = FlowSort.CHANNELS[p.kind]
  UI.setColor(ch.color, 0.18)
  lg.circle("fill", x, y, 26)
  shape(ch.shape, x, y, 14, ch.color, 1)
  UI.setColor(C.colors.outline)
  lg.rectangle("fill", x - 3, y - 3, 6, 6)
end

function FlowSort:draw()
  local lg = love.graphics
  local sx = self.shake > 0 and math.sin(self.t * 90) * 4 or 0
  lg.push()
  lg.translate(sx, 0)
  lg.clear(C.hex("07101c"))
  -- scanlines
  UI.setColor(C.colors.cyan, 0.04)
  for y = 0, C.HEIGHT, 4 do lg.rectangle("fill", 0, y, C.WIDTH, 1) end
  UI.panel(16, 12, C.WIDTH - 32, 40, C.colors.cyan)
  UI.text("FLOWSORT // TERMINAL DATA STREAM", 32, 22, C.colors.cyan, UI.font)
  UI.text(string.format("Sorted %d/%d   Need %d", self.score, #FlowSort.SEQUENCE, FlowSort.NEED), 0, 22, C.colors.text, UI.font_small, "right", C.WIDTH - 36)

  -- stream
  UI.setColor(C.colors.grid, 0.8)
  lg.rectangle("line", 270, FlowSort.TOP - 40, 100, FlowSort.BOTTOM - FlowSort.TOP + 70, 6, 6)
  for i = 0, 8 do
    local y = FlowSort.TOP - 30 + ((self.t * 60 + i * 30) % (FlowSort.BOTTOM - FlowSort.TOP + 50))
    UI.setColor(C.colors.cyan, 0.15)
    lg.rectangle("fill", 316, y, 8, 3)
  end
  UI.setColor(C.colors.glitch, 0.5)
  lg.rectangle("fill", 270, FlowSort.BOTTOM + 26, 100, 3)

  -- bins
  for id, ch in pairs(FlowSort.CHANNELS) do
    local f = self.flash[id] or 0
    UI.panel(ch.x - 70, FlowSort.BIN_Y - 30, 140, 68, ch.color, 0.9)
    if f > 0 then
      UI.setColor(ch.color, f * 1.5)
      lg.rectangle("fill", ch.x - 68, FlowSort.BIN_Y - 28, 136, 64, 6, 6)
    end
    shape(ch.shape, ch.x - 40, FlowSort.BIN_Y + 4, 10, ch.color, 1)
    UI.text(ch.label, ch.x - 24, FlowSort.BIN_Y - 6, C.colors.text, UI.font_small)
    local arrow = ({ left = "<", up = "^", right = ">" })[ch.action]
    UI.text(arrow, ch.x - 24, FlowSort.BIN_Y + 12, ch.color, UI.font)
  end
  if self.phase == "play" then UI.prompts({ { "cancel", "Discard noise" } }, C.WIDTH - 24, FlowSort.BIN_Y - 66, true) end

  if self.packet then
    local p = self.packet
    if not p.fly then
      local frac = 1 - p.t / p.fall
      UI.bar(280, FlowSort.TOP - 30, 80, 5, frac, frac > 0.35 and C.colors.cyan or C.colors.glitch)
    end
    self:draw_packet(p)
  end
  if self.feedback then
    local c = self.feedback.color
    UI.text(self.feedback.text, 380, 200, { c[1], c[2], c[3], math.min(1, self.feedback.t * 3) }, UI.font_big)
  end

  self.spark:draw()
  lg.pop()

  if self.phase == "intro" then
    UI.setColor(C.colors.bg, 0.8)
    lg.rectangle("fill", 0, 0, C.WIDTH, C.HEIGHT)
    UI.panel(80, 110, 480, 250, C.colors.cyan)
    UI.text("FLOWSORT", 80, 126, C.colors.cyan, UI.font_big, "center", 480)
    UI.text("Sort each data packet into its channel before it hits the floor.", 104, 166, C.colors.text, UI.font, "center", 432)
    UI.text("LEFT  Build      UP  Archive      RIGHT  Pulse", 80, 226, C.colors.amber, UI.font_small, "center", 480)
    UI.text("Build beats Pulse. Pulse beats Archive. Archive beats Build.", 80, 202, C.colors.cyan, UI.font_small, "center", 480)
    UI.text("Static NOISE packets must be discarded with B.", 80, 250, C.colors.text, UI.font_small, "center", 480)
    UI.text(string.format("Sort %d of %d to stabilize the terminal.", FlowSort.NEED, #FlowSort.SEQUENCE), 80, 274, C.colors.text, UI.font_small, "center", 480)
    UI.prompts({ { "confirm", "Start" }, { "cancel", "Leave" } }, 540, 324, true)
  elseif self.phase == "result" then
    local r = self.result
    UI.setColor(C.colors.bg, 0.8)
    lg.rectangle("fill", 0, 0, C.WIDTH, C.HEIGHT)
    UI.panel(120, 130, 400, 220, r.success and C.colors.green or C.colors.glitch)
    UI.text(r.success and (r.perfect and "PERFECT FLOW" or "STREAM STABILIZED") or "TOO MUCH NOISE", 120, 148,
      r.success and C.colors.green or C.colors.glitch, UI.font_big, "center", 400)
    UI.text(string.format("Sorted %d / %d", r.score, r.total), 120, 196, C.colors.text, UI.font, "center", 400)
    UI.text(string.format("Wrong %d    Missed %d", r.wrong, r.misses), 120, 222, C.colors.dim, UI.font_small, "center", 400)
    if r.success then
      UI.prompts({ { "confirm", "Continue" } }, 500, 312, true)
    else
      for i, l in ipairs({ "Retry", "Leave" }) do
        local bx = 170 + (i - 1) * 170
        UI.text(l, bx, 270, i == self.sel and C.colors.cyan or C.colors.dim, UI.font, "center", 130)
        if i == self.sel then UI.focus(bx, 266, 130, 28, self.t) end
      end
    end
  end
end

return FlowSort
