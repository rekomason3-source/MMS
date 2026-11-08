-- Placeholder sprite system.
-- Sprites are authored as character grids + palettes and baked into
-- nearest-filtered Images at first use. To swap in final art, replace a
-- grid with love.graphics.newImage("assets/...png") — callers only use
-- Sprite.get(name) and draw the returned Image.

local Sprite = { cache = {}, defs = {} }

function Sprite.define(name, rows, palette)
  Sprite.defs[name] = { rows = rows, palette = palette }
  Sprite.cache[name] = nil
end

function Sprite.bake(rows, palette)
  local h, w = #rows, #rows[1]
  local id = love.image.newImageData(w, h)
  for y = 1, h do
    local row = rows[y]
    assert(#row == w, "sprite row " .. y .. " has width " .. #row .. ", expected " .. w)
    for x = 1, w do
      local c = palette[row:sub(x, x)]
      if c then id:setPixel(x - 1, y - 1, c[1], c[2], c[3], c[4] or 1) end
    end
  end
  local img = love.graphics.newImage(id)
  img:setFilter("nearest", "nearest")
  return img
end

function Sprite.get(name)
  local img = Sprite.cache[name]
  if not img then
    local d = assert(Sprite.defs[name], "unknown sprite " .. tostring(name))
    img = Sprite.bake(d.rows, d.palette)
    Sprite.cache[name] = img
  end
  return img
end

return Sprite
