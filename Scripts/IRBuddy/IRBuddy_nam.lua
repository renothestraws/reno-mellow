-- @noindex
-- ReNo Mellow - IR Buddy : conversion des modèles NAM (.nam, JSON) pour RMampsim
-- RMampsim (JSFX) ne sait pas lire le JSON : chaque .nam de REAPER/Data/RM Amp est converti en un fichier
-- « RMNAM » (WAV float 32 bits mono) dans REAPER/Data/RMIRIndex/NAM, lu tel quel par le plug-in.
-- Format : en-tête de 16 valeurs (4242, version 1, nombre de sous-modèles, 0...), puis pour chaque sous-modèle
--   8 valeurs (canaux C, nombre de poids, loudness, input_level_dbu, output_level_dbu, fréquence, 0, 0)
--   suivies des poids dans l'ordre du fichier .nam. -999 = valeur absente.
-- Seule l'architecture A2 est acceptée (WaveNet 23 couches, C = 3 « Lite » ou C = 8 « Full », seule ou dans
-- un SlimmableContainer) : c'est celle que RMampsim sait faire tourner.
local M = {}

-- ---------------------------------------------------------------------------------------
-- décodeur JSON minimal (objets, tableaux, chaînes, nombres, true / false / null)
local function decode(s)
  local pos = 1
  local find, sub, byte = string.find, string.sub, string.byte
  local skip, value
  skip = function()
    local _, e = find(s, "^[ \t\r\n]*", pos)
    pos = e + 1
  end
  local function str()
    local out, i = {}, pos + 1
    while true do
      local a = find(s, '["\\]', i)
      if not a then error("unterminated string") end
      out[#out + 1] = sub(s, i, a - 1)
      if byte(s, a) == 34 then pos = a + 1 break end
      local c = sub(s, a + 1, a + 1)
      if c == "u" then
        local code = tonumber(sub(s, a + 2, a + 5), 16) or 63
        out[#out + 1] = code < 128 and string.char(code) or "?"
        i = a + 6
      else
        local map = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f" }
        out[#out + 1] = map[c] or c
        i = a + 2
      end
    end
    return table.concat(out)
  end
  value = function()
    skip()
    local c = byte(s, pos)
    if c == 123 then -- {
      local t = {}
      pos = pos + 1; skip()
      if byte(s, pos) == 125 then pos = pos + 1 return t end
      while true do
        skip()
        local k = str()
        skip(); pos = pos + 1 -- :
        t[k] = value()
        skip()
        local d = byte(s, pos); pos = pos + 1
        if d == 125 then return t end
      end
    elseif c == 91 then -- [
      local t, n = {}, 0
      pos = pos + 1; skip()
      if byte(s, pos) == 93 then pos = pos + 1 return t end
      while true do
        n = n + 1; t[n] = value()
        skip()
        local d = byte(s, pos); pos = pos + 1
        if d == 93 then return t end
      end
    elseif c == 34 then
      return str()
    elseif c == 116 then pos = pos + 4 return true
    elseif c == 102 then pos = pos + 5 return false
    elseif c == 110 then pos = pos + 4 return M.null
    else
      local a, e = find(s, "^-?[%d%.]+[eE]?[-+]?%d*", pos)
      if not a then error("bad JSON at " .. pos) end
      pos = e + 1
      return tonumber(sub(s, a, e))
    end
  end
  return value()
end
M.null = setmetatable({}, { __tostring = function() return "null" end })
M.decode = decode

-- ---------------------------------------------------------------------------------------
local KS = { 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 15, 15, 6, 6, 6, 6, 6, 6, 6 }
local DIL = { 1, 3, 7, 17, 41, 101, 239, 1, 3, 7, 17, 41, 101, 239, 1, 13, 1, 3, 7, 17, 41, 101, 239 }

local function same(a, b)
  if type(a) ~= "table" or #a ~= #b then return false end
  for i = 1, #b do if a[i] ~= b[i] then return false end end
  return true
end

-- renvoie C (3 ou 8) si le modèle a la forme A2, sinon nil + raison
local function a2_channels(m)
  if type(m) ~= "table" or m.architecture ~= "WaveNet" then return nil, "architecture " .. tostring(m and m.architecture) end
  local c = m.config or {}
  if type(c.layers) ~= "table" or #c.layers ~= 1 then return nil, "not A2 (" .. (type(c.layers) == "table" and #c.layers or 0) .. " layer arrays: A1?)" end
  if c.head ~= nil and c.head ~= M.null then return nil, "post head" end
  if c.condition_dsp ~= nil and c.condition_dsp ~= M.null then return nil, "condition DSP" end
  local la = c.layers[1]
  if not same(la.kernel_sizes, KS) or not same(la.dilations, DIL) then return nil, "not the A2 layer pattern" end
  local ch = la.channels
  if (ch ~= 3 and ch ~= 8) or la.bottleneck ~= ch then return nil, "channels " .. tostring(ch) end
  if la.condition_size ~= 1 or la.input_size ~= 1 then return nil, "input size" end
  for _, a in ipairs(la.activation or {}) do
    if type(a) ~= "table" or a.type ~= "LeakyReLU" or math.abs((a.negative_slope or 0) - 0.01) > 1e-6 then return nil, "activation" end
  end
  if type(la.gating_mode) == "table" then for _, g in ipairs(la.gating_mode) do if g ~= "none" then return nil, "gating" end end end
  if la.gated == true then return nil, "gating" end
  if type(la.layer1x1) ~= "table" or not la.layer1x1.active then return nil, "layer1x1" end
  if type(la.head1x1) == "table" and la.head1x1.active then return nil, "head1x1" end
  if type(la.head) ~= "table" or la.head.kernel_size ~= 16 or la.head.out_channels ~= 1 then return nil, "head" end
  for _, k in ipairs({ "conv_pre_film", "conv_post_film", "input_mixin_pre_film", "input_mixin_post_film",
    "activation_pre_film", "activation_post_film", "layer1x1_post_film", "head1x1_post_film" }) do
    local f = la[k]
    if f == true or (type(f) == "table" and f.active) then return nil, "FiLM" end
  end
  -- nombre de poids attendu
  local n = ch
  for i = 1, 23 do n = n + KS[i] * ch * ch + ch + ch + ch * ch + ch end
  n = n + ch * 16 + 1 + 1
  if type(m.weights) ~= "table" or #m.weights ~= n then return nil, "weights " .. (type(m.weights) == "table" and #m.weights or 0) .. " / " .. n end
  return ch
end

local function num(v) return (type(v) == "number") and v or -999 end

-- convertit src (.nam) en dst (RMNAM .wav) ; renvoie true ou nil + raison
function M.convert(src, dst)
  local f = io.open(src, "rb")
  if not f then return nil, "cannot open" end
  local txt = f:read("a"); f:close()
  local ok, d = pcall(decode, txt)
  if not ok or type(d) ~= "table" then return nil, "not a JSON .nam file" end
  local subs = {}
  if d.architecture == "SlimmableContainer" then
    local list = (d.config and d.config.submodels) or {}
    table.sort(list, function(a, b) return (a.max_value or 0) < (b.max_value or 0) end)
    for _, s in ipairs(list) do subs[#subs + 1] = s.model end
  else
    subs[1] = d
  end
  if #subs == 0 then return nil, "empty container" end
  local vals = { 4242, 1, #subs }
  for i = 4, 16 do vals[i] = 0 end
  -- capture avec baffle (full rig / amp + cab) : métadonnée gear_type « ..._cab » ou nom du fichier / dossier
  local has_cab = false
  local function gt(md) return type(md) == "table" and type(md.gear_type) == "string" and md.gear_type:lower():find("cab") ~= nil end
  if gt(d.metadata) then has_cab = true end
  for _, m in ipairs(subs) do if gt(m.metadata) then has_cab = true end end
  local lname = src:lower()
  local ia = lname:find("rm amp[/\\]")
  if ia then lname = lname:sub(ia + 7) end            -- seulement le chemin sous Data/RM Amp
  lname = lname:gsub("[_%-%.]", " ")
  for _, k in ipairs({ "full rig", "fullrig", "amp %+ cab", "amp%+cab", "amp & cab", "amp and cab", "amp cab", "combo" }) do
    if lname:find(k) then has_cab = true end
  end
  if has_cab then vals[4] = 1 end
  for _, m in ipairs(subs) do
    local ch, why = a2_channels(m)
    if not ch then return nil, why end
    local md = (type(m.metadata) == "table") and m.metadata or {}
    local w = m.weights
    local top = (type(d.metadata) == "table") and d.metadata or {}   -- niveaux du conteneur si le sous-modèle n'en a pas
    local h = { ch, #w, num(md.loudness or top.loudness), num(md.input_level_dbu or top.input_level_dbu),
                num(md.output_level_dbu or top.output_level_dbu), num(m.sample_rate or d.sample_rate), 0, 0 }
    for i = 1, 8 do vals[#vals + 1] = h[i] end
    for i = 1, #w do vals[#vals + 1] = w[i] end
  end
  -- WAV float 32 bits, mono
  local n = #vals
  local out = io.open(dst, "wb")
  if not out then return nil, "cannot write " .. dst end
  out:write("RIFF", string.pack("<I4", 4 + 26 + 12 + 8 + n * 4), "WAVE")
  out:write("fmt ", string.pack("<I4I2I2I4I4I2I2I2", 18, 3, 1, 48000, 48000 * 4, 4, 32, 0))
  out:write("fact", string.pack("<I4I4", 4, n))
  out:write("data", string.pack("<I4", n * 4))
  local buf, k = {}, 0
  for i = 1, n do
    k = k + 1; buf[k] = string.pack("<f", vals[i])
    if k >= 4096 then out:write(table.concat(buf, "", 1, k)); k = 0 end
  end
  if k > 0 then out:write(table.concat(buf, "", 1, k)) end
  out:close()
  return true, #subs
end

return M
