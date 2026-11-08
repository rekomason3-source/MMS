-- Procedural UI/feedback sounds generated at boot (no audio files to ship).
-- Fails silently when no audio device exists.

local Sfx = { enabled = false, muted = false, sounds = {} }

local RATE = 22050

local function tone(f0, f1, dur, vol, wave)
  local n = math.floor(RATE * dur)
  local sd = love.sound.newSoundData(n, RATE, 16, 1)
  local phase = 0
  for i = 0, n - 1 do
    local p = i / n
    local f = f0 + (f1 - f0) * p
    phase = phase + f / RATE
    local s
    if wave == "square" then
      s = (phase % 1 < 0.5) and 1 or -1
    else
      s = math.sin(phase * 2 * math.pi)
    end
    local env = math.min(1, i / (RATE * 0.004)) * (1 - p) ^ 1.6
    sd:setSample(i, s * vol * env)
  end
  return love.audio.newSource(sd, "static")
end

function Sfx.init()
  if not (love.audio and love.sound) then return end
  local ok = pcall(function()
    Sfx.sounds.blip    = tone(660, 660, 0.04, 0.10, "square")
    Sfx.sounds.confirm = tone(520, 880, 0.08, 0.12, "square")
    Sfx.sounds.pickup  = tone(700, 1500, 0.15, 0.22, "sine")
    Sfx.sounds.hurt    = tone(320, 90, 0.22, 0.14, "square")
    Sfx.sounds.pet     = tone(880, 1180, 0.14, 0.18, "sine")
    Sfx.sounds.level   = tone(440, 1320, 0.45, 0.12, "square")
    Sfx.sounds.error   = tone(200, 150, 0.12, 0.12, "square")
    Sfx.sounds.seal    = tone(300, 640, 0.20, 0.20, "sine")
    Sfx.sounds.good    = tone(600, 900, 0.07, 0.16, "sine")
  end)
  Sfx.enabled = ok
end

function Sfx.play(name)
  if not Sfx.enabled or Sfx.muted then return end
  local s = Sfx.sounds[name]
  if s then s:stop(); s:play() end
end

return Sfx
