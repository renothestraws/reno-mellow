-- @noindex
-- ReNo Mellow - IR Buddy - Capture for NAM
-- Prépare un entraînement Neural Amp Modeler (NAM) à partir d'un plug-in d'ampli :
--  1. le signal de capture officiel (T3K sweep v3 = « v3_0_0.wav » de NAM, 3 min 10 s, 48 kHz) passe dans une copie
--     de la chaîne d'effets de la piste sélectionnée (hors temps réel), ou dans les effets d'origine en temps réel
--     (plug-ins sur DSP externe : UAD...) ;
--  2. la sortie est écrite en WAV 24 bits mono, de la même longueur que le signal d'entrée, dans
--     REAPER/Data/RM Amp/Captures (à entraîner) ;
--  3. ce fichier s'envoie sur TONE3000 (capture « standard », signal v3) ; le modèle A2 obtenu (.nam) se range dans
--     REAPER/Data/RM Amp, puis « IR Buddy - Rescan RM IR » le rend utilisable dans RMampsim.

local r = reaper
local EXT = "ReNo_IRBuddy_NAM"
local TITLE = "IR Buddy - Capture for NAM"
local SEP = package.config:sub(1, 1)
local SR = 48000
local SWEEP_LEN = 9120000            -- longueur du signal v3 (190 s à 48 kHz)

local _, _, sec_id, cmd_id = r.get_action_context()
if cmd_id and cmd_id > 0 then
  r.SetToggleCommandState(sec_id, cmd_id, 0)
  r.RefreshToolbar2(sec_id, cmd_id)
end

local function msg(s) r.MB(s, TITLE, 0) end
local function sanitize(s)
  s = (s or ""):gsub('[\\/:%*%?"<>|,]', "_")
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end
local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close() return true end
  return false
end
local function project_srate()
  local s = tonumber(r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)) or 0
  if s < 8000 then s = tonumber(r.format_timestr_pos(1, "", 4)) or 0 end
  return math.floor(s + 0.5)
end
local function open_folder(dir)
  if r.CF_ShellExecute then r.CF_ShellExecute(dir) return end
  local os_name = r.GetOS()
  if os_name:match("Win") then os.execute('explorer "' .. dir .. '"')
  elseif os_name:match("OSX") or os_name:match("mac") then os.execute('open "' .. dir .. '"')
  else os.execute('xdg-open "' .. dir .. '" &') end
end

-- ---------------------------------------------------------------------------------------
local src_tr = r.GetSelectedTrack(0, 0)
if not src_tr then
  msg("Select the track that holds the amp plug-in first.\n\nSet the amp as you want it captured, with no noise gate.\nAmp only: cabinet / IR OFF. Full rig: cabinet / IR ON.")
  return
end
local nfx = r.TrackFX_GetCount(src_tr)
if nfx < 1 then msg("The selected track has no FX.\n\nInsert your amp plug-in on it, then run this action again.") return end

local psr = project_srate()
if psr ~= SR then
  if r.MB(string.format("NAM captures are made at 48 kHz, the project runs at %.1f kHz.\n\nSet the project sample rate to 48 kHz (Project settings), then run the action again.\n\nContinue anyway?", psr / 1000), TITLE, 4) ~= 6 then return end
end

-- signal de capture (choisi une fois, mémorisé)
local sweep = r.GetExtState(EXT, "sweep")
-- signal livré avec le paquet : REAPER/Data/RM Amp/Capture signal/T3K-sweep-v3.wav
local bundled = r.GetResourcePath() .. SEP .. "Data" .. SEP .. "RM Amp" .. SEP .. "Capture signal" .. SEP .. "T3K-sweep-v3.wav"
if (sweep == "" or not file_exists(sweep)) and file_exists(bundled) then sweep = bundled end
if sweep == "" or not file_exists(sweep) then
  msg("Choose the NAM capture signal: \"T3K-sweep-v3.wav\" (= NAM \"v3_0_0.wav\", 3 min 10 s), from tone3000.com/capture.\n\nIt is asked only once.")
  local ok, p = r.GetUserFileNameForRead("", "NAM capture signal (T3K sweep v3 / v3_0_0.wav)", ".wav")
  if not ok or p == "" then return end
  sweep = p
end
local src0 = r.PCM_Source_CreateFromFile(sweep)
local slen = src0 and r.GetMediaSourceLength(src0) or 0
local n_len = math.floor(slen * SR + 0.5)
if src0 then r.PCM_Source_Destroy(src0) end
if math.abs(n_len - SWEEP_LEN) > 2 then
  msg(string.format("This file is %.2f s long: it is not the NAM v3 capture signal (190.00 s).\n\nChoose \"T3K-sweep-v3.wav\" / \"v3_0_0.wav\".", slen))
  r.DeleteExtState(EXT, "sweep", true)
  return
end
n_len = SWEEP_LEN
r.SetExtState(EXT, "sweep", sweep, true)

-- nom proposé = premier effet actif
local default_name = ""
for i = 0, nfx - 1 do
  if r.TrackFX_GetEnabled(src_tr, i) then
    local _, fxn = r.TrackFX_GetFXName(src_tr, i, "")
    default_name = fxn:gsub("^[%w]+i?:%s*", ""):gsub("%s*%(.-%)%s*$", ""):gsub(",", " ")
    break
  end
end
local last_rt = r.GetExtState(EXT, "realtime"); if last_rt == "" then last_rt = "N" end
local last_cab = r.GetExtState(EXT, "cab"); if last_cab == "" then last_cab = "N" end
local ok, csv = r.GetUserInputs(TITLE, 3,
  "Capture name,Cab in capture (Y = full rig / N = amp only),Real time (Y/N; DSP plug-ins: UAD...),extrawidth=200",
  default_name .. "," .. last_cab .. "," .. last_rt)
if not ok then return end
local f_name, f_cab, f_rt = csv:match("^(.-),(.-),(.-)$")
f_name = sanitize(f_name)
local realtime = (f_rt or ""):upper():find("Y") ~= nil
local full_rig = (f_cab or ""):upper():find("Y") ~= nil
if f_name == "" then msg("Please type a name for the capture.") return end
r.SetExtState(EXT, "realtime", realtime and "Y" or "N", true)
r.SetExtState(EXT, "cab", full_rig and "Y" or "N", true)
-- capture avec baffle : « Full Rig » dans le nom (reconnu par le Rescan d'IR Buddy, CAB coupé dans RMampsim)
if full_rig then
  local l = f_name:lower():gsub("[_%-%.]", " ")
  if not (l:find("full rig") or l:find("fullrig") or l:find("amp %+ cab") or l:find("amp%+cab") or l:find("amp cab")) then
    f_name = f_name .. " Full Rig"
  end
end

local out_dir = r.GetResourcePath() .. SEP .. "Data" .. SEP .. "RM Amp" .. SEP .. "Captures (to train)"
r.RecursiveCreateDirectory(out_dir, 0)
local out_path = out_dir .. SEP .. f_name .. " - output.wav"
if file_exists(out_path) and r.MB("\"" .. f_name .. " - output.wav\" already exists.\n\nReplace it?", TITLE, 4) ~= 6 then return end

-- ---------------------------------------------------------------------------------------
local sel_items, sel_tracks = {}, {}
local function save_selection()
  sel_items, sel_tracks = {}, {}
  for i = 0, r.CountSelectedMediaItems(0) - 1 do sel_items[#sel_items + 1] = r.GetSelectedMediaItem(0, i) end
  for i = 0, r.CountSelectedTracks(0) - 1 do sel_tracks[#sel_tracks + 1] = r.GetSelectedTrack(0, i) end
end
local function restore_selection()
  for i = 0, r.CountTracks(0) - 1 do r.SetTrackSelected(r.GetTrack(0, i), false) end
  for _, t in ipairs(sel_tracks) do if r.ValidatePtr(t, "MediaTrack*") then r.SetTrackSelected(t, true) end end
  r.SelectAllMediaItems(0, false)
  for _, it in ipairs(sel_items) do if r.ValidatePtr(it, "MediaItem*") then r.SetMediaItemSelected(it, true) end end
end
local function add_item(tr, pos)
  local it = r.AddMediaItemToTrack(tr)
  local tk = r.AddTakeToMediaItem(it)
  r.SetMediaItemTake_Source(tk, r.PCM_Source_CreateFromFile(sweep))
  r.SetMediaItemInfo_Value(it, "D_POSITION", pos)
  r.SetMediaItemInfo_Value(it, "D_LENGTH", n_len / SR)
  r.SetMediaItemInfo_Value(it, "B_LOOPSRC", 0)
  for _, k in ipairs({ "D_FADEINLEN", "D_FADEOUTLEN", "D_FADEINLEN_AUTO", "D_FADEOUTLEN_AUTO" }) do r.SetMediaItemInfo_Value(it, k, 0) end
  return it, tk
end

-- lit la prise (moyenne des canaux) par blocs ; pass 1 = crête, pass 2 = écriture WAV 24 bits mono
local function write_take(tk, offs)
  local src = tk and r.GetMediaItemTake_Source(tk)
  local nch = src and math.max(1, math.min(2, r.GetMediaSourceNumChannels(src))) or 0
  if nch < 1 then return nil, "nothing was rendered" end
  local acc = r.CreateTakeAudioAccessor(tk)
  local blk = 65536
  local buf = r.new_array(blk * nch)
  local function each_block(fn)
    local pos = 0
    while pos < n_len do
      local n = math.min(blk, n_len - pos)
      buf.clear()
      r.GetAudioAccessorSamples(acc, SR, nch, offs + pos / SR, n, buf)
      fn(buf.table(1, n * nch), n)
      pos = pos + n
    end
  end
  local pk = 0
  each_block(function(t, n)
    for i = 1, n do
      local v = t[(i - 1) * nch + 1] or 0
      if nch > 1 then v = 0.5 * (v + (t[(i - 1) * nch + 2] or 0)) end
      v = math.abs(v); if v > pk then pk = v end
    end
  end)
  if pk < 0.00001 then r.DestroyAudioAccessor(acc) return nil, "silence" end
  local g = (pk > 0.98) and (0.98 / pk) or 1
  local f = io.open(out_path, "wb")
  if not f then r.DestroyAudioAccessor(acc) return nil, "cannot write " .. out_path end
  local bytes = n_len * 3
  f:write("RIFF", string.pack("<I4", 36 + bytes), "WAVE")
  f:write("fmt ", string.pack("<I4I2I2I4I4I2I2", 16, 1, 1, SR, SR * 3, 3, 24))
  f:write("data", string.pack("<I4", bytes))
  each_block(function(t, n)
    local out = {}
    for i = 1, n do
      local v = t[(i - 1) * nch + 1] or 0
      if nch > 1 then v = 0.5 * (v + (t[(i - 1) * nch + 2] or 0)) end
      local s = math.floor(v * g * 8388607 + 0.5)
      if s > 8388607 then s = 8388607 elseif s < -8388608 then s = -8388608 end
      if s < 0 then s = s + 16777216 end
      out[i] = string.char(s & 255, (s >> 8) & 255, (s >> 16) & 255)
    end
    f:write(table.concat(out))
  end)
  f:close()
  r.DestroyAudioAccessor(acc)
  return pk, g
end

local function report(pk, g)
  if not pk then
    if g == "silence" and not realtime then
      if r.MB("The FX chain returned silence.\n\nSome plug-ins running on external DSP (UAD...) do not work offline.\nCapture again in real time? (about 3 min 15 s, the transport will record)", TITLE, 4) == 6 then
        r.SetExtState(EXT, "realtime", "Y", true); realtime = true
        return "again"
      end
      return
    end
    msg("The capture did not work: " .. tostring(g))
    return
  end
  local txt = "Capture ready:\n" .. out_path .. "\n\n"
  if g < 1 then txt = txt .. string.format("The amp output peaked at %+.1f dBFS: lowered by %.1f dB to avoid clipping (no problem for NAM).\n\n", 20 * math.log(pk, 10), -20 * math.log(g, 10)) end
  if full_rig then
    txt = txt .. "Next steps:\n1. tone3000.com: create a capture (signal \"T3K sweep v3\"), type \"Amp + Cab\" (or \"Full Rig / Combo\"), and upload this file as the output.\n"
      .. "2. When the training is done, download the .nam (A2) into REAPER/Data/RM Amp. Keep \"Full Rig\" in its name or folder:\n   RMampsim then switches its CAB off for it.\n"
  else
    txt = txt .. "Next steps:\n1. tone3000.com: create a capture (signal \"T3K sweep v3\"), type \"Amp Head\", and upload this file as the output.\n"
      .. "2. When the training is done, download the .nam (A2) into REAPER/Data/RM Amp.\n"
  end
  txt = txt
    .. "3. Run \"IR Buddy - Rescan RM IR\": the model appears in RMampsim.\n\nOpen the folder now?"
  if r.MB(txt, TITLE, 4) == 6 then open_folder(out_dir) end
end

local function capture_offline()
  save_selection()
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, false)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "IR Buddy NAM (temp)", true)
  r.SetMediaTrackInfo_Value(tr, "I_NCHAN", math.max(2, r.GetMediaTrackInfo_Value(src_tr, "I_NCHAN")))
  for i = 0, nfx - 1 do r.TrackFX_CopyToTrack(src_tr, i, tr, i, false) end
  local it, tk = add_item(tr, 0)
  r.SelectAllMediaItems(0, false)
  r.SetMediaItemSelected(it, true)
  r.UpdateArrange()
  r.Main_OnCommand(40209, 0)              -- Apply track/take FX to items
  local rtake = r.GetActiveTake(it)
  local rsrc = rtake and r.GetMediaItemTake_Source(rtake)
  local path = rsrc and r.GetMediaSourceFileName(rsrc, "") or ""
  local pk, g
  if rtake and rtake ~= tk then pk, g = write_take(rtake, 0) else g = "the FX could not be rendered" end
  r.DeleteTrack(tr)
  restore_selection()
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("IR Buddy: capture for NAM", -1)
  if path ~= "" and path ~= sweep then os.remove(path) end
  return pk, g
end

local function capture_realtime(done)
  if r.GetPlayState() ~= 0 then r.OnStopButton() end
  save_selection()
  local armed = {}
  for i = 0, r.CountTracks(0) - 1 do
    local t = r.GetTrack(0, i)
    if r.GetMediaTrackInfo_Value(t, "I_RECARM") > 0 then armed[#armed + 1] = t; r.SetMediaTrackInfo_Value(t, "I_RECARM", 0) end
  end
  local cur0 = r.GetCursorPosition()
  local main0 = r.GetMediaTrackInfo_Value(src_tr, "B_MAINSEND")
  r.Undo_BeginBlock()
  local P = r.GetProjectLength(0) + 3
  local it = add_item(src_tr, P)
  r.SetMediaTrackInfo_Value(src_tr, "B_MAINSEND", 0)
  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, false)
  local rec_tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(rec_tr, "P_NAME", "IR Buddy NAM (rec)", true)
  r.SetMediaTrackInfo_Value(rec_tr, "B_MAINSEND", 0)
  local snd = r.CreateTrackSend(src_tr, rec_tr)
  r.SetTrackSendInfo_Value(src_tr, 0, snd, "I_SENDMODE", 3)
  r.SetTrackSendInfo_Value(src_tr, 0, snd, "D_VOL", 1)
  r.SetMediaTrackInfo_Value(rec_tr, "I_RECMODE", 3)
  r.SetMediaTrackInfo_Value(rec_tr, "I_RECMON", 0)
  r.SetMediaTrackInfo_Value(rec_tr, "I_RECARM", 1)
  r.Undo_EndBlock("IR Buddy: real-time NAM capture (setup)", -1)
  r.UpdateArrange()
  r.SetEditCurPos(P - 2, true, false)
  local t_end = P + n_len / SR + 0.5
  local t_start = r.time_precise()
  r.CSurf_OnRecord()
  local function finish_rt()
    r.Main_OnCommand(40667, 0)
    r.Undo_BeginBlock()
    local rec = nil
    for i = 0, r.CountTrackMediaItems(rec_tr) - 1 do rec = r.GetTrackMediaItem(rec_tr, i) end
    local pk, g, path = nil, "nothing was recorded", ""
    if rec then
      local rtk = r.GetActiveTake(rec)
      local offs = P - r.GetMediaItemInfo_Value(rec, "D_POSITION")
      if rtk and offs >= 0 then pk, g = write_take(rtk, offs) end
      local s2 = rtk and r.GetMediaItemTake_Source(rtk)
      path = s2 and r.GetMediaSourceFileName(s2, "") or ""
    end
    r.DeleteTrack(rec_tr)
    if r.ValidatePtr(it, "MediaItem*") then r.DeleteTrackMediaItem(src_tr, it) end
    r.SetMediaTrackInfo_Value(src_tr, "B_MAINSEND", main0)
    for _, t in ipairs(armed) do if r.ValidatePtr(t, "MediaTrack*") then r.SetMediaTrackInfo_Value(t, "I_RECARM", 1) end end
    restore_selection()
    r.SetEditCurPos(cur0, true, false)
    r.UpdateArrange()
    r.Undo_EndBlock("IR Buddy: capture for NAM (real time)", -1)
    if path ~= "" and path ~= sweep then os.remove(path) end
    done(pk, g)
  end
  local function wait_rt()
    local rec_on = (r.GetPlayState() & 4) == 4
    if rec_on and r.GetPlayPosition() < t_end then r.defer(wait_rt) return end
    if not rec_on and r.time_precise() - t_start < 15 then r.defer(wait_rt) return end
    finish_rt()
  end
  r.defer(wait_rt)
end

local function done(pk, g)
  if report(pk, g) == "again" then capture_realtime(function(a, b) report(a, b) end) end
end

if realtime then
  capture_realtime(done)
else
  done(capture_offline())
end
