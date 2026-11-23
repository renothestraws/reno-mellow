-- @noindex
-- ReNo Mellow - IR Buddy : met à jour l'index des IR (navigateur de RM1982Verb)
local r = reaper
local _, script_path, sec_id, cmd_id = r.get_action_context()
if cmd_id and cmd_id > 0 then
  r.SetToggleCommandState(sec_id, cmd_id, 0)
  r.RefreshToolbar2(sec_id, cmd_id)
end
local dir = script_path:match("^(.*[\\/])") or ""
local ok, IX = pcall(dofile, dir .. "IRBuddy_index.lua")
if not ok or not IX then r.MB("IRBuddy_index.lua is missing. Reinstall IR Buddy.", "IR Buddy - Rescan RM IR", 0) return end
local n, nd = IX.rescan()
if not n then
  r.MB(nd, "IR Buddy - Rescan RM IR", 0)
else
  r.MB(string.format("IR index updated: %d IR in %d folder(s).\n\nIn RM1982Verb, click the IR name to browse them.", n, nd), "IR Buddy - Rescan RM IR", 0)
end
