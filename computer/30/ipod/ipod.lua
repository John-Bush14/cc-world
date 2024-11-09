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
   "iron_xylophone", -- unsupported in 1.12
   "cow_bell",
   "didgeridoo",
   "harp", -- bit,
   "banjo",
   "pling"
}

local pause = keys.space
local nextK = keys.right
local previous = keys.left
local volumeUp = keys.up
local volumeDown = keys.down

local maxX = 20
local paddingY = 15
local paddingYV = 24
local paddingX = 1
local width = 3
local widthV = 0.150
local color = colors.blue

local function map(tbl, fn)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = fn(v)
    end
    return result
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

local k = nil
local note = nil

local ticks = 0

local volumes = {}
local pitches = {}

local paused = false

local song, instruments = parseSong(songs[songI])

function table.size(tbl)
    local x = 0
    for _,_ in pairs(tbl) do x = x + 1 end
    return x
end

function math.clamp(int, min, max) return math.min(math.max(int, min), max) end

while true do
    local start = os.time()
    os.startTimer(0)
    while os.time() - start <= 0 do
        for _, key in pairs(getKeys()) do
            if key == pause then
                paused = not paused
            elseif key == nextK then
                songI = songI + 1
                if songI > #songs then songI = 1 end
                song, instruments = parseSong(songs[songI])
                ticks = 0
                k, note = nil, nil
                volumes = {}
                pitches = {}
            elseif key == previous then
                songI = songI - 1
                if songI < 1 then songI = #songs end
                song, instruments = parseSong(songs[songI])
                ticks = 0
                k, note = nil, nil
                volumes = {}
                pitches = {}
            elseif key == volumeUp then
                volumeMod = volumeMod*1.01
            elseif key == volumeDown then
                volumeMod = volumeMod/1.01
            end
        end
    end

    if not paused then

    if type(note) ~= nil then ticks = ticks + 1 end

    k, note = next(song.notes, k)
    local AVvolume = nil
    local AVpitch = nil

    local layerI = 1

    if type(note) == "table" then ticks = ticks-1 end

    while type(note) == "table" do
        --print(instruments[note.instrument + 1], note.velocity/(10/3), math.floor(math.min(math.max(((note.key-33)/87*24)+(note.pitch/100), 0), 24)))
        layerI = layerI + (note["jumps-tick"] or 0)
        local layer = {volume = 1.0}
        if song.layers ~= nil then layer = song.layers[layerI] or error(textutils.serialize(song.layers) .. " fuck: " .. layerI) end

        local pitch  = math.clamp((note.key-33)+((note.pitch or 0)/100), 0, 24)
        local volume = math.clamp(((note.velocity or 50)*(layer.volume/100)*volumeMod)/(100/3), 0, 3)
        local instrument = instruments[note.instrument + 1] or error("Custom Instrument Not Supported!")

        AVpitch = (pitch  + (AVpitch or pitch))/2
        AVvolume = (volume + (AVvolume or volume))/2

        local sides = {"left", "right", "bottom", "top"}
        local i = 1
        while not peripheral.call(sides[i], "playNote", instrument, volume*10, pitch) do
           i = i + 1
        end
        k, note = next(song.notes, k)
    end

    --if layerI ~= 0 then k, note = next(song.notes, k) end

    table.insert(volumes, AVvolume or 0)
    table.insert(pitches, AVpitch or 0)

    if note == nil then
        songI = songI + 1
        if songI > #songs then songI = 1 end
        parseSong(songs[songI])
    end

    term.clear()

    if song.layers ~= nil then for _, layer in pairs(song.layers) do if layer.volume ~= 100 then print(layer.volume) end end end

    term.setCursorPos(paddingX-1, paddingY)
    term.setTextColor(color)
    term.setBackgroundColor(color)
    for pitchk,pitch in pairs(pitches) do if pitchk >= #pitches-maxX then
        local x,_ = term.getCursorPos()

        term.setCursorPos(x+1, paddingY-(pitch/width))
    end end

   term.setCursorPos(paddingX-1, paddingYV)
    term.setTextColor(colors.green)
    term.setBackgroundColor(colors.green)
    for volk,volume in pairs(volumes) do if volk >= #volumes-maxX then
        local x,_ = term.getCursorPos()

        term.setCursorPos(x+1, paddingYV-(volume/widthV))
        term.write("0")
    end end
        term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.setCursorPos(1, 1)

    if song.header.name == "" then song.header.name = song.header["OG-filename"] end
    if song.header.author == "" then song.header.author = song.header["OG-author"] end

    print(" - " .. song.header.name .. " - from " .. song.header.author .. " playing for " .. math.floor(ticks or 0) .. "/" .. math.floor(song.header.length) .. " ticks")
end end
