-- @noindex
-- ReNo Mellow - IR Buddy : index des IR (RM1982Verb, RMampsim) et des modèles NAM (RMampsim)
-- Parcourt REAPER/Data/RM IR (sous-dossiers et liens compris) et écrit REAPER/Data/RMIRIndex/index.txt ;
-- parcourt REAPER/Data/RM Amp (*.nam), convertit chaque modèle A2 en REAPER/Data/RMIRIndex/NAM/*.wav (IRBuddy_nam.lua)
-- et écrit REAPER/Data/RMIRIndex/amps.txt (même format, en-tête RMAMPINDEX 2, chemin absolu = fichier converti) :
--   RMIRINDEX 1
--   D<tab>nom du dossier            (un par dossier contenant des .wav, dans l'ordre ; "(root)" = RM IR lui-même)
--   F<tab>n° du dossier<tab>nom affiché<tab>chemin relatif à RM IR<tab>chemin absolu
local r = reaper
local M = {}
local SEP = package.config:sub(1, 1)

local function lower_sort(a, b) return a:lower() < b:lower() end

local function rescan_dir(sub, ext, header, outname, xform)
  local res = r.GetResourcePath()
  local root = res .. SEP .. "Data" .. SEP .. sub
  r.RecursiveCreateDirectory(root, 0)
  local folders = {}            -- { rel = "A/B", files = { {name, rel, abs} } }
  local seen = 0

  local function scan(dir, rel, depth)
    if depth > 8 then return end
    local files = {}
    local i = 0
    while true do
      local f = r.EnumerateFiles(dir, i)
      if not f then break end
      if f:lower():sub(-#ext) == ext then files[#files + 1] = f end
      i = i + 1
    end
    table.sort(files, lower_sort)
    if #files > 0 then
      local fo = { rel = rel, files = {} }
      for _, f in ipairs(files) do
        local frel = (rel == "") and f or (rel .. "/" .. f)
        local abs = dir .. SEP .. f
        if xform then abs = xform(abs, frel) end
        if abs then
          fo.files[#fo.files + 1] = { name = f:sub(1, #f - #ext), rel = frel, abs = abs }
          seen = seen + 1
        end
      end
      if #fo.files > 0 then folders[#folders + 1] = fo end
    end
    local subs = {}
    i = 0
    while true do
      local d = r.EnumerateSubdirectories(dir, i)
      if not d then break end
      if d:sub(1, 1) ~= "." then subs[#subs + 1] = d end
      i = i + 1
    end
    table.sort(subs, lower_sort)
    for _, d in ipairs(subs) do
      scan(dir .. SEP .. d, (rel == "") and d or (rel .. "/" .. d), depth + 1)
    end
  end

  r.EnumerateFiles(root, -1)            -- vide le cache d'énumération de REAPER
  r.EnumerateSubdirectories(root, -1)
  scan(root, "", 0)

  local idx_dir = res .. SEP .. "Data" .. SEP .. "RMIRIndex"
  r.RecursiveCreateDirectory(idx_dir, 0)
  local f = io.open(idx_dir .. SEP .. outname, "wb")
  if not f then return nil, "Cannot write " .. idx_dir .. SEP .. outname end
  f:write(header, "\n")
  for _, fo in ipairs(folders) do
    f:write("D\t", (fo.rel == "") and "(root)" or fo.rel, "\n")
  end
  for k, fo in ipairs(folders) do
    for _, it in ipairs(fo.files) do
      f:write("F\t", tostring(k - 1), "\t", it.name, "\t", it.rel, "\t", it.abs, "\n")
    end
  end
  f:close()
  return seen, #folders
end

local function fsize(p)
  local f = io.open(p, "rb")
  if not f then return -1 end
  local n = f:seek("end"); f:close()
  return n
end

-- conversion des .nam (avec cache : un modèle déjà converti et de même taille n'est pas refait)
M.skipped = {}
local function nam_xform_factory()
  local here = debug.getinfo(1, "S").source:match("^@(.*[\\/])") or ""
  local ok, N = pcall(dofile, here .. "IRBuddy_nam.lua")
  if not ok then return nil end
  local res = r.GetResourcePath()
  local cdir = res .. SEP .. "Data" .. SEP .. "RMIRIndex" .. SEP .. "NAM"
  r.RecursiveCreateDirectory(cdir, 0)
  local cache = {}
  local cf = io.open(cdir .. SEP .. "cache3.txt", "rb")
  if cf then
    for line in cf:lines() do
      local rel, sz = line:match("^(.-)\t(%-?%d+)$")
      if rel then cache[rel] = tonumber(sz) end
    end
    cf:close()
  end
  local newcache = {}
  M.skipped = {}
  local function xform(abs, rel)
    local dst = cdir .. SEP .. rel:gsub("[/\\:]", "__") .. ".wav"
    local sz = fsize(abs)
    if cache[rel] == sz and fsize(dst) > 0 then
      newcache[#newcache + 1] = rel .. "\t" .. sz
      return dst
    end
    local okc, why = N.convert(abs, dst)
    if okc then
      newcache[#newcache + 1] = rel .. "\t" .. sz
      return dst
    end
    M.skipped[#M.skipped + 1] = rel .. ": " .. tostring(why)
    return nil
  end
  local function save()
    local w = io.open(cdir .. SEP .. "cache3.txt", "wb")
    if w then w:write(table.concat(newcache, "\n"), "\n"); w:close() end
  end
  return xform, save
end

function M.rescan()
  local a, b = rescan_dir("RM IR", ".wav", "RMIRINDEX 1", "index.txt")
  r.RecursiveCreateDirectory(r.GetResourcePath() .. SEP .. "Data" .. SEP .. "RM Amp", 0)
  local xform, save = nam_xform_factory()
  local c = 0
  if xform then
    c = rescan_dir("RM Amp", ".nam", "RMAMPINDEX 2", "amps.txt", xform) or 0
    save()
  end
  return a, b, c
end

return M
