local instrumentsVanilla = {
   "harp",
   "bass",
   "basedrum",
   "snare",
   "hat",
   "guitar",
   "flute",
   "bell",
   "chime",
   "xylophone",
   "xylophone", -- iron_xylophone
   "harp", -- cow_bell
   "flute", -- didgeridoo
   "harp", -- bit,
   "harp", -- banjo
   "harp", -- pling
   "Tempo Changer"
}

local speakers = {peripheral.find("speaker")}

function math.clamp(int, min, max) return math.min(math.max(int, min), max) end
local pause = keys.space
local nextK = keys.right
local previous = keys.left
local volumeUp = keys.up
local volumeDown = keys.down

MaxX = 0
PaddingY = 0
PaddingYV = 0 -- 24
local paddingX = 0
Width = 0 -- 3
WidthV = 0 -- 0.150
local color = colors.blue

local function map(tbl, fn)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = fn(v)
    end
    return result
end

local function drawScreen(graphData, graphDataLength, song, ticks)
    term.clear()

    term.setCursorPos(paddingX-1, PaddingY)
    term.setTextColor(color)
    term.setBackgroundColor(color)
    for pitchk = math.max(graphDataLength-MaxX, 1), graphDataLength,1 do
         local pitch = graphData[pitchk][1]

        local x,_ = term.getCursorPos()

        term.setCursorPos(x+1, PaddingY-(pitch*Width))
        if pitch > 0 then term.write("0") end
   end

   term.setCursorPos(paddingX-1, PaddingYV)
    term.setTextColor(colors.green)
    term.setBackgroundColor(colors.green)
    for volk = math.max(graphDataLength-MaxX, 1), graphDataLength,1 do
         local volume = graphData[volk][2]

        local x,_ = term.getCursorPos()

        term.setCursorPos(x+1, PaddingYV-(volume*WidthV))
        if volume > 0 then term.write("0") end
    end
        term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.setCursorPos(1, 1)

    if song.header.name == "" then song.header.name = song.header["OG-filename"] end
    if song.header.author == "" then song.header.author = song.header["OG-author"] end

    print(" - " .. song.header.name .. " - from " .. song.header.author .. " playing for " .. math.floor(ticks or 0) .. "/" .. math.floor(song.header.length) .. " ticks")
 end

local function calculateDimensions(song)
   MaxX = math.floor(term.getSize()/2+11)

   local layerI = 0

   local AVpitch = 0
   local AVvolume = 0

   local volumeExtremes = {99999, -99999}
   local pitchExtremes = {999999, -99999}

   for _, note in pairs(song.notes) do
      if type(note) == "table" then
         layerI = layerI + (note["jumps-layer"] or 0)
         local layer = {volume = 1.0}
         if song.layers ~= nil then layer = song.layers[layerI] or layer end

         local pitch  = math.clamp((note.key-33)+((note.pitch or 0)/100), 0, 24)
         local volume = math.clamp(((note.velocity or 50)*(layer.volume/100))/(100/3), 0, 3)

         AVpitch = (pitch  + (AVpitch or pitch))/2
         AVvolume = (volume + (AVvolume or volume))/2
      elseif AVpitch ~= 0 and AVpitch ~= 0 then
         layerI = 1

         volumeExtremes = {math.min(volumeExtremes[1], AVvolume), math.max(volumeExtremes[2], AVvolume)}
         pitchExtremes = {math.min(pitchExtremes[1], AVpitch), math.max(pitchExtremes[2], AVpitch)}

         AVpitch = 0
         AVvolume = 0
      end
   end

   local _, height = term.getSize()

   Width = (height-5)/(pitchExtremes[2]-pitchExtremes[1])
   PaddingY = height + pitchExtremes[1]*Width

   WidthV = (height-5)/(volumeExtremes[2]-volumeExtremes[1])
   PaddingYV = height + volumeExtremes[1]*WidthV
end

local function parseSong(songFile)
    local song = require("nbsParser")(io.open(songFile, "rb"))

    if song == nil then error(songFile .. " is invalid or corrupted (check if it is of NBS version 5)") end

    local instruments = instrumentsVanilla
    for _, instrument in pairs(song.instruments) do if type(instrument) == "table" then table.insert(instruments, instrument.substitute) end end

    return song, instruments
end

local function getKeys()
   local events = {os.pullEvent()}
   local keys = {}
   local key = false

   for _, event in pairs(events) do
      if event == "key" then key = true
      elseif key and type(event) == "number" then
---@diagnostic disable-next-line: cast-local-type
          key = event
      elseif type(key) == "number" and type(event) == "boolean" then
          if not event then table.insert(keys, key) end
---@diagnostic disable-next-line: cast-local-type
          key = nil
      end
   end

   return keys
end

local songsFolder = "ipod/songs"

local songI = 1
local volumeMod = 1

local songs = map(fs.list(songsFolder), function(file) return fs.combine(songsFolder, file) end)

function table.size(tbl)
    local x = 0
    for _,_ in pairs(tbl) do x = x + 1 end
    return x
end

local function handleInput(paused)
   local songIChanged = false

   for _, key in pairs(getKeys()) do
      if key == pause then
            paused = not paused
      elseif key == nextK then
            songI = songI + 1
            if songI > #songs then songI = 1 end
            songIChanged = true
      elseif key == previous then
            songI = songI - 1
            if songI < 1 then songI = #songs end
            songIChanged = true
      elseif key == volumeUp then
            volumeMod = volumeMod*1.01
      elseif key == volumeDown then
            volumeMod = volumeMod/1.01
      end
   end

   return paused, songIChanged
end

local function playTick(k, note, song, instruments, tempoChangers)
   local AVpitch = nil
   local AVvolume = nil

   local layerI = 0

   while type(note) == "table" do
      layerI = layerI + (note["jumps-layer"] or 0)
      local layer = {volume = 1.0}
      if song.layers ~= nil then layer = song.layers[layerI] or error(textutils.serialize(song.layers) .. " fuck: " .. layerI) end

      local pitch  = math.clamp((note.key-33)+((note.pitch or 0)/100), 0, 24)
      local volume = math.clamp(((note.velocity or 50)*(layer.volume/100)*volumeMod)/(100/3), 0, 3)
      local instrument = instruments[note.instrument + 1] or error("Custom Instrument Not Supported!")

      AVpitch = (pitch  + (AVpitch or pitch))/2
      AVvolume = (volume + (AVvolume or volume))/2

      local i = 1

      if instrument == "Tempo Changer" then
         tempoChangers[note.key] = math.abs(note.pitch/15.0)
      else
         ---@diagnostic disable-next-line: need-check-nil
         while not speakers[i].playNote(instrument, volume*10, pitch) and i < #speakers do
            i = i + 1
         end
      end

      k, note = next(song.notes, k)
   end

   return AVpitch, AVvolume, k, note
end

local function playSong(songFile)
   local song, instruments = parseSong(songs[songI])


   local ticks = 0

   local paused = false


   calculateDimensions(song)


   local spt = 1/((song.header.tempo or 2000)/100)

   if spt > 0.05 then spt = 0.05 end

   local secSinceTick = 0


   local k, note = nil, nil


   local graphData = {}

   local graphDataLength = 0


   local tempoChangers = {}


   while true do
      local start = os.clock()

      local elapsedTime = 0


      os.startTimer(0)
      while elapsedTime <= 0 do
         local changeSong = false

         paused, changeSong = handleInput(paused)

         if changeSong then return playSong(songs[songI]) end


         elapsedTime = os.clock() - start
      end


      if ticks == 0 then secSinceTick = 0.05 end -- safegaurd


      secSinceTick = secSinceTick + elapsedTime


      while secSinceTick >= spt-0.1  do

         secSinceTick = secSinceTick-spt

         if not paused then

         if type(note) ~= nil then ticks = ticks + 1 end


         if tempoChangers[ticks] ~= nil then spt = 1/tempoChangers[ticks] end


         k, note = next(song.notes, k)


         local AVvolume = nil
         local AVpitch = nil


         if type(note) == "table" then
            ticks = ticks-1

            AVpitch, AVvolume, k, note = playTick(k, note, song, instruments, tempoChangers)
         end


         graphDataLength = graphDataLength+1

         graphData[graphDataLength] = {AVpitch or 0, AVvolume or 0}


         if note == nil then
            songI = songI + 1
            if songI > #songs then songI = 1 end
            return playSong(songs[songI])
         end

         drawScreen(graphData, graphDataLength, song, ticks)
         print(k, note)
         end
      end
   end
end

playSong(songs[1])
