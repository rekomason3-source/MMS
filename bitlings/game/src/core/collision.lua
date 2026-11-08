-- Axis-separated AABB movement against static solids.
-- Entities expose x (center), y (feet), w, h. Their box is
-- [x - w/2, y - h] .. [x + w/2, y]. dt is clamped upstream so per-frame
-- movement stays far below the thinnest solid (no tunneling).

local U = require("src.core.util")

local Collision = {}

local function box(e) return e.x - e.w / 2, e.y - e.h, e.w, e.h end

function Collision.overlaps(e, solids)
  local bx, by, bw, bh = box(e)
  for _, r in ipairs(solids) do
    if U.aabb(bx, by, bw, bh, r.x, r.y, r.w, r.h) then return r end
  end
  return nil
end

-- Returns hit_x, hit_y booleans.
function Collision.move(e, dx, dy, solids)
  local hit_x, hit_y = false, false
  if dx ~= 0 then
    e.x = e.x + dx
    local bx, by, bw, bh = box(e)
    for _, r in ipairs(solids) do
      if U.aabb(bx, by, bw, bh, r.x, r.y, r.w, r.h) then
        if dx > 0 then e.x = r.x - e.w / 2 else e.x = r.x + r.w + e.w / 2 end
        bx = e.x - e.w / 2
        hit_x = true
      end
    end
  end
  if dy ~= 0 then
    e.y = e.y + dy
    local bx, by, bw, bh = box(e)
    for _, r in ipairs(solids) do
      if U.aabb(bx, by, bw, bh, r.x, r.y, r.w, r.h) then
        if dy > 0 then e.y = r.y else e.y = r.y + r.h + e.h end
        by = e.y - e.h
        hit_y = true
      end
    end
  end
  return hit_x, hit_y
end

return Collision
