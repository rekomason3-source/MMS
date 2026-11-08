-- Stack-based state manager.
-- Only the top state updates. Drawing starts at the highest opaque state;
-- states with `transparent = true` draw the state beneath them first.

local SM = { stack = {} }

function SM.top() return SM.stack[#SM.stack] end

function SM.push(s, ...)
  SM.stack[#SM.stack + 1] = s
  if s.enter then s:enter(...) end
end

function SM.pop()
  local s = table.remove(SM.stack)
  if s and s.exit then s:exit() end
  local t = SM.top()
  if t and t.resume then t:resume(s) end
  return s
end

function SM.switch(s, ...)
  for i = #SM.stack, 1, -1 do
    local old = SM.stack[i]
    if old.exit then old:exit() end
  end
  SM.stack = {}
  SM.push(s, ...)
end

function SM.update(dt)
  local t = SM.top()
  if t then t:update(dt) end
end

function SM.draw()
  local n = #SM.stack
  local i = n
  while i > 1 and SM.stack[i].transparent do i = i - 1 end
  for j = i, n do SM.stack[j]:draw() end
end

function SM.name()
  local t = SM.top()
  return t and t.name or "-"
end

return SM
