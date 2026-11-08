local U = {}

function U.clamp(v, a, b)
  if v < a then return a elseif v > b then return b end
  return v
end

function U.lerp(a, b, t) return a + (b - a) * t end

function U.approach(v, target, step)
  if v < target then return math.min(v + step, target) end
  return math.max(v - step, target)
end

function U.dist(x1, y1, x2, y2)
  local dx, dy = x2 - x1, y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

function U.aabb(ax, ay, aw, ah, bx, by, bw, bh)
  return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end

function U.deepcopy(t)
  if type(t) ~= "table" then return t end
  local r = {}
  for k, v in pairs(t) do r[k] = U.deepcopy(v) end
  return r
end

-- Recursively fill keys missing from `t` with copies from `defaults`.
-- Existing values are never overwritten (used for forward-compatible saves).
function U.fill_defaults(t, defaults)
  for k, v in pairs(defaults) do
    if t[k] == nil then
      t[k] = U.deepcopy(v)
    elseif type(v) == "table" and type(t[k]) == "table" then
      U.fill_defaults(t[k], v)
    end
  end
  return t
end

function U.count(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

-- Deterministic hash in [0,1) for tile variation without RNG state.
function U.hash2(x, y)
  local s = math.sin(x * 12.9898 + y * 78.233) * 43758.5453
  return s - math.floor(s)
end

function U.format_time(sec)
  sec = math.floor(sec or 0)
  return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

return U
