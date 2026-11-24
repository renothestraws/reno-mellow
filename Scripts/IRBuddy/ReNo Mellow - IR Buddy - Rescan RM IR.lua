-- @noindex
-- ReNo Mellow - IR Buddy : met à jour l'index des IR (RM1982Verb, RMampsim) et des modèles NAM (RMampsim)
local r = reaper
local _, script_path, sec_id, cmd_id = r.get_action_context()
if cmd_id and cmd_id > 0 then
  r.SetToggleCommandState(sec_id, cmd_id, 0)
  r.RefreshToolbar2(sec_id, cmd_id)
end
local dir = script_path:match("^(.*[\\/])") or ""
local ok, IX = pcall(dofile, dir .. "IRBuddy_index.lua")
if not ok or not IX then r.MB("IRBuddy_index.lua is missing. Reinstall IR Buddy.", "IR Buddy - Rescan RM IR", 0) return end
local n, nd, na = IX.rescan()
if not n then
  r.MB(nd, "IR Buddy - Rescan RM IR", 0)
else
  local txt = string.format("Index updated:\n- %d IR in %d folder(s) (REAPER/Data/RM IR)\n- %d NAM model(s) (REAPER/Data/RM Amp)", n, nd, na or 0)
  if IX.skipped and #IX.skipped > 0 then
    txt = txt .. string.format("\n\n%d .nam file(s) not usable by RMampsim (only A2 models are supported):", #IX.skipped)
    for i = 1, math.min(#IX.skipped, 12) do txt = txt .. "\n- " .. IX.skipped[i] end
    if #IX.skipped > 12 then txt = txt .. "\n..." end
  end
  r.MB(txt .. "\n\nIn RM1982Verb or RMampsim, click the IR name / amp name to browse them.", "IR Buddy - Rescan RM IR", 0)
end
