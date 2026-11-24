-- @noindex
-- ReNo Mellow - IR Buddy : ouvre le dossier REAPER/Data/RM Amp (modèles NAM .nam de RMampsim) (le crée s'il n'existe pas)
local r = reaper
local _, _, sec_id, cmd_id = r.get_action_context()
if cmd_id and cmd_id > 0 then
  r.SetToggleCommandState(sec_id, cmd_id, 0)
  r.RefreshToolbar2(sec_id, cmd_id)
end
local SEP = package.config:sub(1, 1)
local dir = r.GetResourcePath() .. SEP .. "Data" .. SEP .. "RM Amp"
r.RecursiveCreateDirectory(dir, 0)
if r.CF_ShellExecute then
  r.CF_ShellExecute(dir)
else
  local os_name = r.GetOS()
  if os_name:match("Win") then
    os.execute('explorer "' .. dir .. '"')
  elseif os_name:match("OSX") or os_name:match("mac") then
    os.execute('open "' .. dir .. '"')
  else
    os.execute('xdg-open "' .. dir .. '" &')
  end
end
