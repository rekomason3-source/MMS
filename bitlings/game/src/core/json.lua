-- Minimal JSON encoder/decoder (pure Lua, LuaJIT-safe).
-- Used for the Bitcore save so desktop/web Bitlings tools can read it too.
-- Saves are data only: nothing from disk is ever executed.

local json = {}

local escapes = {
  ['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
  ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
}

local function esc(s)
  return (s:gsub('[%c"\\]', function(c)
    return escapes[c] or string.format("\\u%04x", c:byte())
  end))
end

local function is_array(t)
  local n = 0
  for k in pairs(t) do
    if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then return false, 0 end
    n = n + 1
  end
  for i = 1, n do if t[i] == nil then return false, 0 end end
  return true, n
end

local function encode(v, indent, depth, out)
  local tv = type(v)
  if tv == "nil" then
    out[#out + 1] = "null"
  elseif tv == "boolean" then
    out[#out + 1] = tostring(v)
  elseif tv == "number" then
    if v ~= v or v == math.huge or v == -math.huge then
      error("json: cannot encode non-finite number")
    end
    if v % 1 == 0 and math.abs(v) < 1e15 then
      out[#out + 1] = string.format("%d", v)
    else
      out[#out + 1] = string.format("%.14g", v)
    end
  elseif tv == "string" then
    out[#out + 1] = '"' .. esc(v) .. '"'
  elseif tv == "table" then
    local arr, n = is_array(v)
    local nl = indent and "\n" or ""
    local pad = indent and string.rep(indent, depth + 1) or ""
    local padc = indent and string.rep(indent, depth) or ""
    if arr then
      if n == 0 then out[#out + 1] = "[]" return end
      out[#out + 1] = "[" .. nl
      for i = 1, n do
        out[#out + 1] = pad
        encode(v[i], indent, depth + 1, out)
        if i < n then out[#out + 1] = "," end
        out[#out + 1] = nl
      end
      out[#out + 1] = padc .. "]"
    else
      local keys = {}
      for k in pairs(v) do
        if type(k) ~= "string" then error("json: object keys must be strings") end
        keys[#keys + 1] = k
      end
      table.sort(keys)
      out[#out + 1] = "{" .. nl
      for i, k in ipairs(keys) do
        out[#out + 1] = pad .. '"' .. esc(k) .. '":' .. (indent and " " or "")
        encode(v[k], indent, depth + 1, out)
        if i < #keys then out[#out + 1] = "," end
        out[#out + 1] = nl
      end
      out[#out + 1] = padc .. "}"
    end
  else
    error("json: cannot encode type " .. tv)
  end
end

function json.encode(v, pretty)
  local out = {}
  encode(v, pretty and "  " or nil, 0, out)
  return table.concat(out)
end

-- Decoder ---------------------------------------------------------------

local function derr(i, msg) error(string.format("json: %s at position %d", msg, i), 0) end

local function skip(str, i)
  local _, e = str:find("^[ \n\r\t]*", i)
  return e + 1
end

local function utf8char(cp)
  if cp < 0x80 then return string.char(cp) end
  if cp < 0x800 then
    return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
  end
  return string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
end

local unesc = { ['"'] = '"', ['\\'] = '\\', ['/'] = '/', b = '\b', f = '\f', n = '\n', r = '\r', t = '\t' }

local parse

local function parse_string(str, i)
  local buf, j = {}, i + 1
  while true do
    local c = str:sub(j, j)
    if c == "" then derr(j, "unterminated string") end
    if c == '"' then return table.concat(buf), j + 1 end
    if c == "\\" then
      local n = str:sub(j + 1, j + 1)
      if unesc[n] then
        buf[#buf + 1] = unesc[n]
        j = j + 2
      elseif n == "u" then
        local hex = str:sub(j + 2, j + 5)
        if not hex:match("^%x%x%x%x$") then derr(j, "bad unicode escape") end
        buf[#buf + 1] = utf8char(tonumber(hex, 16))
        j = j + 6
      else
        derr(j, "bad escape")
      end
    else
      buf[#buf + 1] = c
      j = j + 1
    end
  end
end

function parse(str, i)
  i = skip(str, i)
  local c = str:sub(i, i)
  if c == "{" then
    local obj = {}
    i = skip(str, i + 1)
    if str:sub(i, i) == "}" then return obj, i + 1 end
    while true do
      if str:sub(i, i) ~= '"' then derr(i, "expected key") end
      local k
      k, i = parse_string(str, i)
      i = skip(str, i)
      if str:sub(i, i) ~= ":" then derr(i, "expected ':'") end
      local v
      v, i = parse(str, i + 1)
      obj[k] = v
      i = skip(str, i)
      local d = str:sub(i, i)
      if d == "}" then return obj, i + 1 end
      if d ~= "," then derr(i, "expected ',' or '}'") end
      i = skip(str, i + 1)
    end
  elseif c == "[" then
    local arr, n = {}, 0
    i = skip(str, i + 1)
    if str:sub(i, i) == "]" then return arr, i + 1 end
    while true do
      local v
      v, i = parse(str, i)
      n = n + 1
      arr[n] = v
      i = skip(str, i)
      local d = str:sub(i, i)
      if d == "]" then return arr, i + 1 end
      if d ~= "," then derr(i, "expected ',' or ']'") end
      i = i + 1
    end
  elseif c == '"' then
    return parse_string(str, i)
  elseif c == "-" or c:match("%d") then
    local s, e = str:find("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
    local num = tonumber(str:sub(s, e))
    if not num then derr(i, "bad number") end
    return num, e + 1
  elseif str:sub(i, i + 3) == "true" then return true, i + 4
  elseif str:sub(i, i + 4) == "false" then return false, i + 5
  elseif str:sub(i, i + 3) == "null" then return nil, i + 4
  end
  derr(i, "unexpected character '" .. c .. "'")
end

function json.decode(str)
  if type(str) ~= "string" then error("json: expected string", 0) end
  local v, i = parse(str, 1)
  i = skip(str, i)
  if i <= #str then derr(i, "trailing data") end
  return v
end

return json
