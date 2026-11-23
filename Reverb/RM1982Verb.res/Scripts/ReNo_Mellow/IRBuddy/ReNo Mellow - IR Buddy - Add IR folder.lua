-- @noindex
-- ReNo Mellow - IR Buddy : ajoute un dossier personnel d'IR à REAPER/Data/RM IR
-- (lien : jonction sous Windows, lien symbolique sous macOS / Linux). Le dossier d'origine n'est ni copié ni modifié.
local r = reaper
local TITLE = "IR Buddy - Add IR folder"
local EXT = "ReNo_IRBuddy"

local _, script_path, sec_id, cmd_id = r.get_action_context()
if cmd_id and cmd_id > 0 then
  r.SetToggleCommandState(sec_id, cmd_id, 0)
  r.RefreshToolbar2(sec_id, cmd_id)
end

local SEP = package.config:sub(1, 1)
local WIN = r.GetOS():match("Win") ~= nil
local rm_dir = r.GetResourcePath() .. SEP .. "Data" .. SEP .. "RM IR"
r.RecursiveCreateDirectory(rm_dir, 0)

local function msg(s) r.MB(s, TITLE, 0) end
local function strip_sep(p) return (p:gsub("[\\/]+$", "")) end
local function dir_exists(p)
  if r.EnumerateFiles(p, 0) or r.EnumerateSubdirectories(p, 0) then return true end
  local ok, _, code = os.rename(p, p)
  return ok or code == 13
end

-- 1. choix du dossier
local last = r.GetExtState(EXT, "lastfolder")
local folder
if r.JS_Dialog_BrowseForFolder then
  local rv, path = r.JS_Dialog_BrowseForFolder("Choose your IR folder", last ~= "" and last or "")
  if rv ~= 1 or not path or path == "" then return end
  folder = path
else
  local ok, file = r.GetUserFileNameForRead(last ~= "" and (last .. SEP) or "", "Pick any .wav file INSIDE your IR folder", "wav")
  if not ok or not file or file == "" then return end
  folder = file:match("^(.*)[\\/][^\\/]*$")
end
if not folder or folder == "" then return end
folder = strip_sep(folder)
r.SetExtState(EXT, "lastfolder", folder, true)

-- refus : le dossier RM IR lui-même ou un de ses sous-dossiers
local lf = folder:lower():gsub("\\", "/")
local lr = rm_dir:lower():gsub("\\", "/")
if lf == lr or lf:sub(1, #lr + 1) == lr .. "/" then
  msg("This folder is already inside REAPER/Data/RM IR: RM1982Verb lists it already.")
  return
end

-- 2. nom affiché dans RM1982Verb
local base = folder:match("([^\\/]+)$") or "My IRs"
local ok, name = r.GetUserInputs(TITLE, 1, "Name in the RM1982Verb list:,extrawidth=160", base)
if not ok then return end
name = name:gsub('[\\/:%*%?"<>|]', "_"):gsub("^%s+", ""):gsub("%s+$", "")
if name == "" then return end
local link = rm_dir .. SEP .. name
if dir_exists(link) then
  msg("\"" .. name .. "\" already exists in REAPER/Data/RM IR.\nChoose another name, or delete the old link first (use the Open RM IR folder action).")
  return
end

-- 3. création du lien
local cmd
if WIN then
  cmd = 'cmd.exe /C mklink /J "' .. link .. '" "' .. folder .. '"'
else
  cmd = '/bin/ln -s "' .. folder .. '" "' .. link .. '"'
end
local out = r.ExecProcess(cmd, 10000) or ""

if dir_exists(link) then
  local sdir = script_path:match("^(.*[\\/])") or ""
  local okx, IX = pcall(dofile, sdir .. "IRBuddy_index.lua")
  if okx and IX then IX.rescan() end
  msg("Done: \"" .. name .. "\" now points to\n" .. folder ..
      "\n\nIn RM1982Verb, click the IR name to browse them (the \"IR file\" list above the panel shows them after reopening the window)." ..
      "\n\nTo remove it later, delete the \"" .. name .. "\" shortcut in REAPER/Data/RM IR: only the link is removed, your files stay where they are.")
else
  msg("The link could not be created.\n\n" .. cmd .. "\n\n" .. out ..
      (WIN and "\nNote: Windows links (junctions) only work with local drives, not network drives." or ""))
end
