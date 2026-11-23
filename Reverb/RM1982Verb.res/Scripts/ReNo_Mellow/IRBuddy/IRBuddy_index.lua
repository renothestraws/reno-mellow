-- @noindex
-- ReNo Mellow - IR Buddy : index des IR pour le navigateur de RM1982Verb
-- Parcourt REAPER/Data/RM IR (sous-dossiers et liens compris) et écrit REAPER/Data/RMIRIndex/index.txt :
--   RMIRINDEX 1
--   D<tab>nom du dossier            (un par dossier contenant des .wav, dans l'ordre ; "(root)" = RM IR lui-même)
--   F<tab>n° du dossier<tab>nom affiché<tab>chemin relatif à RM IR<tab>chemin absolu
local r = reaper
local M = {}
local SEP = package.config:sub(1, 1)

local function lower_sort(a, b) return a:lower() < b:lower() end

function M.rescan()
  local res = r.GetResourcePath()
  local root = res .. SEP .. "Data" .. SEP .. "RM IR"
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
      if f:lower():match("%.wav$") then files[#files + 1] = f end
      i = i + 1
    end
    table.sort(files, lower_sort)
    if #files > 0 then
      local fo = { rel = rel, files = {} }
      for _, f in ipairs(files) do
        local frel = (rel == "") and f or (rel .. "/" .. f)
        fo.files[#fo.files + 1] = { name = f:gsub("%.[Ww][Aa][Vv]$", ""), rel = frel, abs = dir .. SEP .. f }
        seen = seen + 1
      end
      folders[#folders + 1] = fo
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
  local f = io.open(idx_dir .. SEP .. "index.txt", "wb")
  if not f then return nil, "Cannot write " .. idx_dir .. SEP .. "index.txt" end
  f:write("RMIRINDEX 1\n")
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

return M
