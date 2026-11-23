-- @description ReNo Mellow - IR Buddy (capture an impulse response from a reverb plug-in)
-- @author ReNo Mellow
-- @version 1.1
-- @about Capture la réponse impulsionnelle (IR) des plug-ins de la piste sélectionnée et l'enregistre en WAV dans REAPER/Data/RM IR, prête pour RM1982Verb.
-- @changelog Real-time capture for DSP plug-ins (UAD...) that return silence offline
-- @provides
--   [main] ReNo Mellow - IR Buddy - Open RM IR folder.lua
--   [main] ReNo Mellow - IR Buddy - Add IR folder.lua
--   [main] ReNo Mellow - IR Buddy - Rescan RM IR.lua
--   IRBuddy_index.lua

--[[
  IR Buddy - principe
  1. Une piste temporaire reçoit une copie de la chaîne d'effets de la piste sélectionnée.
  2. On y pose un item WAV : une impulsion (1 échantillon à 0 dBFS, sur les deux canaux) suivie de silence.
  3. "Apply track/take FX to items" (action 40209) fait passer l'item dans les effets, hors temps réel.
  4. Le rendu est lu, la fin silencieuse coupée (-90 dB sous la crête), un court fondu ajouté,
     puis le tout est écrit en WAV 32 bits flottant dans REAPER/Data/RM IR/<sous-dossier>/<nom>.wav.
  5. La piste temporaire et les fichiers temporaires sont supprimés : le projet n'est pas modifié.
]]

local r = reaper
local EXT = "ReNo_IRBuddy"
local TITLE = "IR Buddy"
local SEP = package.config:sub(1, 1)

-- ---------------------------------------------------------------------------------------
-- état de l'icône de barre d'outils : action ponctuelle -> toujours éteinte
local _, script_path, sec_id, cmd_id = r.get_action_context()
if cmd_id and cmd_id > 0 then
  r.SetToggleCommandState(sec_id, cmd_id, 0)
  r.RefreshToolbar2(sec_id, cmd_id)
end

local function msg(s) r.MB(s, TITLE, 0) end

local function sanitize(s)
  s = (s or ""):gsub('[\\/:%*%?"<>|]', "_")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

local function file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close() return true end
  return false
end

-- fréquence d'échantillonnage du projet (1 s exprimée en échantillons)
local function project_srate()
  local s = tonumber(r.format_timestr_pos(1, "", 4))
  if not s or s < 8000 then
    s = tonumber(r.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)) or 0
  end
  if s < 8000 then s = 48000 end
  return math.floor(s + 0.5)
end

-- ---------------------------------------------------------------------------------------
-- écriture d'un WAV 32 bits flottant (format 3 = IEEE float) ; data = tableau de canaux
local function write_wav(path, sr, chans, n)
  local nch = #chans
  local f = io.open(path, "wb")
  if not f then return false end
  local bytes = n * nch * 4
  f:write("RIFF", string.pack("<I4", 4 + 26 + 12 + 8 + bytes), "WAVE")
  f:write("fmt ", string.pack("<I4I2I2I4I4I2I2I2", 18, 3, nch, sr, sr * nch * 4, nch * 4, 32, 0))
  f:write("fact", string.pack("<I4I4", 4, n))
  f:write("data", string.pack("<I4", bytes))
  local buf, k = {}, 0
  for i = 1, n do
    for c = 1, nch do
      k = k + 1
      buf[k] = string.pack("<f", chans[c][i])
    end
    if k >= 8192 then
      f:write(table.concat(buf, "", 1, k))
      k = 0
    end
  end
  if k > 0 then f:write(table.concat(buf, "", 1, k)) end
  f:close()
  return true
end

-- ---------------------------------------------------------------------------------------
-- vérifications de départ
local src_tr = r.GetSelectedTrack(0, 0)
if not src_tr then
  msg("Select the track that holds the reverb plug-in first.\n\nSet the reverb to 100 % wet (dry off).")
  return
end
local nfx = r.TrackFX_GetCount(src_tr)
if nfx < 1 then
  msg("The selected track has no FX.\n\nInsert your reverb plug-in on it (100 % wet), then run IR Buddy again.")
  return
end
local active = 0
for i = 0, nfx - 1 do
  if r.TrackFX_GetEnabled(src_tr, i) and not r.TrackFX_GetOffline(src_tr, i) then active = active + 1 end
end
if active < 1 then
  msg("All FX of the selected track are bypassed or offline.")
  return
end

-- nom proposé : le premier effet actif (sans le préfixe "VST3: " etc.)
local default_name = ""
for i = 0, nfx - 1 do
  if r.TrackFX_GetEnabled(src_tr, i) then
    local _, fxn = r.TrackFX_GetFXName(src_tr, i, "")
    fxn = fxn:gsub("^[%w]+i?:%s*", ""):gsub("%s*%(.-%)%s*$", "")
    default_name = fxn:gsub(",", " ")
    break
  end
end

-- ---------------------------------------------------------------------------------------
-- réglages (mémorisés)
local last_folder = r.GetExtState(EXT, "folder"); if last_folder == "" then last_folder = "Plug-ins" end
local last_len = r.GetExtState(EXT, "maxlen"); if last_len == "" then last_len = "10" end
local last_out = r.GetExtState(EXT, "output"); if last_out == "" then last_out = "S" end
local last_trim = r.GetExtState(EXT, "trimstart"); if last_trim == "" then last_trim = "N" end
local last_rt = r.GetExtState(EXT, "realtime"); if last_rt == "" then last_rt = "N" end

local ok, csv = r.GetUserInputs(TITLE .. " - capture IR", 6,
  "IR name,Sub-folder of RM IR (empty = none),Max length (s, 1-10),Output (S = stereo / M = mono),Trim silence at start (Y/N),Real time (Y/N; DSP plug-ins: UAD...),extrawidth=180",
  default_name .. "," .. last_folder .. "," .. last_len .. "," .. last_out .. "," .. last_trim .. "," .. last_rt)
if not ok then return end

local f_name, f_folder, f_len, f_out, f_trim, f_rt = csv:match("^(.-),(.-),(.-),(.-),(.-),(.-)$")
f_name = sanitize(f_name)
f_folder = sanitize(f_folder)
local maxlen = math.min(math.max(tonumber(f_len) or 10, 1), 10)
local stereo = not ((f_out or ""):upper():find("M"))
local trim_start = (f_trim or ""):upper():find("Y") ~= nil
local realtime = (f_rt or ""):upper():find("Y") ~= nil
if f_name == "" then msg("Please type a name for the IR.") return end

r.SetExtState(EXT, "folder", f_folder, true)
r.SetExtState(EXT, "maxlen", tostring(maxlen), true)
r.SetExtState(EXT, "output", stereo and "S" or "M", true)
r.SetExtState(EXT, "trimstart", trim_start and "Y" or "N", true)
r.SetExtState(EXT, "realtime", realtime and "Y" or "N", true)

local res = r.GetResourcePath()
local ir_dir = res .. SEP .. "Data" .. SEP .. "RM IR"
if f_folder ~= "" then ir_dir = ir_dir .. SEP .. f_folder end
r.RecursiveCreateDirectory(ir_dir, 0)
local out_path = ir_dir .. SEP .. f_name .. ".wav"
if file_exists(out_path) then
  if r.MB("\"" .. f_name .. ".wav\" already exists in this folder.\n\nReplace it?", TITLE, 4) ~= 6 then return end
end

-- ---------------------------------------------------------------------------------------
-- impulsion : 1 échantillon à 0 dBFS sur les deux canaux, puis silence
local sr = project_srate()
local n_len = math.floor(maxlen * sr)
local tmp_dir = res .. SEP .. "Data" .. SEP .. "ReNo_IRBuddy"
r.RecursiveCreateDirectory(tmp_dir, 0)
local imp_path = tmp_dir .. SEP .. "impulse_" .. sr .. "_" .. maxlen .. ".wav"
do
  local a, b = {}, {}
  for i = 1, n_len do a[i] = 0.0; b[i] = 0.0 end
  a[1] = 1.0; b[1] = 1.0
  if not write_wav(imp_path, sr, { a, b }, n_len) then
    msg("Cannot write the temporary file:\n" .. imp_path)
    return
  end
end


-- ---------------------------------------------------------------------------------------
-- outils communs aux deux modes de capture
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

-- piste temporaire à la fin du projet, avec une copie de la chaîne d'effets, et l'impulsion à la position pos
local function make_temp_track(pos)
  local idx = r.CountTracks(0)
  r.InsertTrackAtIndex(idx, false)
  local tr = r.GetTrack(0, idx)
  r.GetSetMediaTrackInfo_String(tr, "P_NAME", "IR Buddy (temp)", true)
  r.SetMediaTrackInfo_Value(tr, "I_NCHAN", math.max(2, r.GetMediaTrackInfo_Value(src_tr, "I_NCHAN")))
  for i = 0, nfx - 1 do r.TrackFX_CopyToTrack(src_tr, i, tr, i, false) end
  local it = r.AddMediaItemToTrack(tr)
  local tk = r.AddTakeToMediaItem(it)
  r.SetMediaItemTake_Source(tk, r.PCM_Source_CreateFromFile(imp_path))
  r.SetMediaItemInfo_Value(it, "D_POSITION", pos)
  r.SetMediaItemInfo_Value(it, "D_LENGTH", n_len / sr)
  r.SetMediaItemInfo_Value(it, "B_LOOPSRC", 0)
  r.SetMediaItemInfo_Value(it, "D_FADEINLEN", 0)
  r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", 0)
  r.SetMediaItemInfo_Value(it, "D_FADEINLEN_AUTO", 0)
  r.SetMediaItemInfo_Value(it, "D_FADEOUTLEN_AUTO", 0)
  return tr, it, tk
end

-- lit n_len échantillons d'une prise à partir de offs secondes (temps de la prise)
local function read_take(tk, offs)
  local L, R = {}, {}
  local src = tk and r.GetMediaItemTake_Source(tk)
  local nch = src and r.GetMediaSourceNumChannels(src) or 0
  if nch < 1 then return L, R, 0 end
  local acc = r.CreateTakeAudioAccessor(tk)
  local blk = 32768
  local buf = r.new_array(blk * 2)
  local pos = 0
  while pos < n_len do
    local n = math.min(blk, n_len - pos)
    buf.clear()
    r.GetAudioAccessorSamples(acc, sr, 2, offs + pos / sr, n, buf)
    local t = buf.table(1, n * 2)
    for i = 1, n do
      L[pos + i] = t[2 * i - 1] or 0
      R[pos + i] = (nch > 1) and (t[2 * i] or 0) or L[pos + i]
    end
    pos = pos + n
  end
  r.DestroyAudioAccessor(acc)
  return L, R, n_len
end

local function peak_of(L, R, got)
  local pk = 0
  for i = 1, got do
    local a, b = math.abs(L[i]), math.abs(R[i])
    if a > pk then pk = a end
    if b > pk then pk = b end
  end
  return pk
end

-- ---------------------------------------------------------------------------------------
-- mode 1 : hors temps réel ("Apply track/take FX to items", action 40209)
local function capture_offline()
  save_selection()
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  local tr, it, tk = make_temp_track(0)
  r.SelectAllMediaItems(0, false)
  r.SetMediaItemSelected(it, true)
  r.UpdateArrange()
  r.Main_OnCommand(40209, 0)
  local rtake = r.GetActiveTake(it)
  local rsrc = rtake and r.GetMediaItemTake_Source(rtake)
  local path = rsrc and r.GetMediaSourceFileName(rsrc, "") or ""
  local L, R, got = {}, {}, 0
  if rtake and rtake ~= tk then L, R, got = read_take(rtake, 0) end
  r.DeleteTrack(tr)
  restore_selection()
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock("IR Buddy: capture IR", -1)
  if path ~= "" and path ~= imp_path then os.remove(path) end
  return L, R, got
end

-- mode 2 : en temps réel (plug-ins sur DSP externe : UAD...) : la piste temporaire enregistre sa propre sortie
local function capture_realtime(done)
  if r.GetPlayState() ~= 0 then r.OnStopButton() end
  save_selection()
  local armed = {}
  for i = 0, r.CountTracks(0) - 1 do
    local t = r.GetTrack(0, i)
    if r.GetMediaTrackInfo_Value(t, "I_RECARM") > 0 then armed[#armed + 1] = t; r.SetMediaTrackInfo_Value(t, "I_RECARM", 0) end
  end
  local cur0 = r.GetCursorPosition()
  -- (pas de bloc d'annulation ouvert pendant l'enregistrement : un bloc pour la préparation, un pour le rangement)
  r.Undo_BeginBlock()
  local P = r.GetProjectLength(0) + 2
  local tr, it = make_temp_track(P)
  r.SetMediaTrackInfo_Value(tr, "B_MAINSEND", 0)   -- rien n'est envoyé au master pendant la capture
  r.SetMediaTrackInfo_Value(tr, "I_RECMODE", 1)    -- Record: output (stereo)
  r.SetMediaTrackInfo_Value(tr, "I_RECMON", 0)
  r.SetMediaTrackInfo_Value(tr, "I_RECARM", 1)
  r.Undo_EndBlock("IR Buddy: real-time capture (setup)", -1)
  r.UpdateArrange()
  r.SetEditCurPos(P - 0.5, true, false)
  local t_end = P + n_len / sr + 0.5
  local t_start = r.time_precise()
  r.CSurf_OnRecord()

  local function finish_rt()
    r.Main_OnCommand(40667, 0)    -- Transport: Stop (save all recorded media)
    r.Undo_BeginBlock()
    local rec, rtk = nil, nil
    for i = 0, r.CountTrackMediaItems(tr) - 1 do
      local x = r.GetTrackMediaItem(tr, i)
      if x ~= it then rec = x end
    end
    local L, R, got = {}, {}, 0
    local path = ""
    if rec then
      rtk = r.GetActiveTake(rec)
      local offs = P - r.GetMediaItemInfo_Value(rec, "D_POSITION")
      if rtk and offs >= 0 then L, R, got = read_take(rtk, offs) end
      local s2 = rtk and r.GetMediaItemTake_Source(rtk)
      path = s2 and r.GetMediaSourceFileName(s2, "") or ""
    end
    r.DeleteTrack(tr)
    for _, t in ipairs(armed) do if r.ValidatePtr(t, "MediaTrack*") then r.SetMediaTrackInfo_Value(t, "I_RECARM", 1) end end
    restore_selection()
    r.SetEditCurPos(cur0, true, false)
    r.UpdateArrange()
    r.Undo_EndBlock("IR Buddy: capture IR (real time)", -1)
    if path ~= "" and path ~= imp_path then os.remove(path) end
    done(L, R, got, true)
  end

  local function wait_rt()
    local st = r.GetPlayState()
    local rec_on = (st & 4) == 4
    if rec_on and r.GetPlayPosition() < t_end then r.defer(wait_rt) return end
    if not rec_on and r.time_precise() - t_start < 15 then r.defer(wait_rt) return end   -- décompte éventuel
    finish_rt()
  end
  r.defer(wait_rt)
end

-- ---------------------------------------------------------------------------------------
-- mise en forme et écriture du WAV
function finish(L, R, got, was_rt)
-- ---------------------------------------------------------------------------------------
-- mise en forme : crête, coupe du silence final (-90 dB), début optionnel, fondu final
if was_rt and got < 1 then
  msg("The real-time recording did not work (no recorded item).\n\nCheck that REAPER can record (audio device running), then try again.")
  return
end
local pk = peak_of(L, R, got)
if pk < 0.000001 then
  if was_rt then
    msg("The FX chain returned silence, even in real time.\n\nIs the reverb at 100 % wet, and not bypassed?")
  elseif r.MB("The FX chain returned silence.\n\nSome plug-ins running on external DSP (UAD...) do not work offline.\nCapture again in real time? (" .. maxlen .. " s, the transport will record)", TITLE, 4) == 6 then
    r.SetExtState(EXT, "realtime", "Y", true)
    capture_realtime(finish)
  end
  return
end

local thr_end = pk * 10 ^ (-90 / 20)
local last = 1
for i = got, 1, -1 do
  if math.abs(L[i]) > thr_end or math.abs(R[i]) > thr_end then last = i break end
end
local first = 1
if trim_start then
  local thr_start = pk * 10 ^ (-60 / 20)
  for i = 1, last do
    if math.abs(L[i]) > thr_start or math.abs(R[i]) > thr_start then first = i break end
  end
end
local n_out = last - first + 1
local fade = math.min(math.floor(0.02 * sr), math.floor(n_out / 4))
local OL, OR = {}, {}
for i = 1, n_out do
  local g = 1
  local k = n_out - i
  if k < fade then g = 0.5 - 0.5 * math.cos(math.pi * k / fade) end
  OL[i] = L[first + i - 1] * g
  OR[i] = R[first + i - 1] * g
end

-- canaux identiques -> l'IR est en fait mono
local same = true
for i = 1, n_out do
  if math.abs(OL[i] - OR[i]) > 0.0000001 then same = false break end
end

local chans
if stereo and not same then
  chans = { OL, OR }
else
  local M = {}
  for i = 1, n_out do M[i] = 0.5 * (OL[i] + OR[i]) end
  chans = { M }
end

if not write_wav(out_path, sr, chans, n_out) then
  msg("Cannot write the IR file:\n" .. out_path)
  return
end

-- mise à jour de l'index du navigateur de RM1982Verb
do
  local dir = script_path:match("^(.*[\\/])") or ""
  local ok, IX = pcall(dofile, dir .. "IRBuddy_index.lua")
  if ok and IX then IX.rescan() end
end

-- début du son (latence éventuelle ou predelay du plug-in)
local onset = 1
local thr_on = pk * 10 ^ (-60 / 20)
for i = 1, n_out do
  if math.abs(OL[i]) > thr_on or math.abs(OR[i]) > thr_on then onset = i break end
end

local info = string.format("IR saved:\n%s\n\n%s, %.2f s, %d Hz",
  out_path, (#chans == 2) and "Stereo" or "Mono", n_out / sr, sr)
if stereo and same then info = info .. "\n(both channels were identical: saved as mono)" end
info = info .. string.format("\nFirst sound after %.1f ms", (onset - 1) / sr * 1000)
if last >= got - 1 then
  info = info .. "\n\nThe tail was still audible at the end: raise Max length (up to 10 s)."
end
info = info .. "\n\nIn RM1982Verb, click the IR name to open the browser (or use the \"IR file\" list above the panel)."
msg(info)
end

-- ---------------------------------------------------------------------------------------
if realtime then
  capture_realtime(finish)
else
  local L, R, got = capture_offline()
  if got < 1 then
    msg("The FX could not be rendered.\n\nCheck that the plug-ins are not offline and try again.")
    return
  end
  finish(L, R, got, false)
end
