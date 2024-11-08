local speaker = peripheral.wrap("left")
local speakerBackup = peripheral.wrap("right")

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
   "bit",
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

function map(tbl, fn)
    local result = {}
    for i, v in ipairs(tbl) do
        result[i] = fn(v)
    end
    return result
end

function playSong(songFile)
   print(songFile)
    song = require("nbsParser")(io.open(songFile, "rb"))
    
    if song == nil then error(songFile .. " is invalid or corrupted (check if it is of NBS version 5)") end
    
    local paused = false
    
    local tempo = song.header.tempo/100
    local spt = 1/tempo
    
    instruments = instrumentsVanilla
    for _, instrument in pairs(song.instruments) do if type(instrument) == "table" then table.insert(instruments, instrument.substitute) end end

    k, note = nil
    ticks = 0
    volumes = {}
    pitches = {}
end

function getKeys()
   local events = {os.pullEvent()}
   local keys = {}
   local key = false

   for _, event in pairs(events) do
      if event == "key" then key = true
      elseif key and type(event) == "number" then 
          key = event
      elseif type(key) == "number" and type(event) == "boolean" then
          if not event then table.insert(keys, key) end
          key = nil
      end
   end

   return keys
end

local songsFolder = "ipod/songs"

local songI = 1
local volumeMod = 1

songs = map(fs.list(songsFolder), function(file) return fs.combine(songsFolder, file) end)
instruments = nil
song = nil

k = nil 
note = nil

ticks = nil

volumes = nil
pitches = nil

playSong(songs[songI])

local keys = {}

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
                playSong(songs[songI])
            elseif key == previous then
                songI = songI - 1
                if songI < 1 then songI = #songs end
                playSong(songs[songI])
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
    
    local layerI = 0
    
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
        while not peripheral.call(sides[i], "playSound", instrument, volume, pitch) do i = i + 1 end
        k, note = next(song.notes, k)
    end
    
    --if layerI ~= 0 then k, note = next(song.notes, k) end
    
    table.insert(volumes, AVvolume or 0)
    table.insert(pitches, AVpitch or 0)
    
    if note == nil then
        songI = songI + 1
        if songI > #songs then songI = 1 end
        playSong(songs[songI])
    end
   
    term.clear()
 
    if song.layers ~= nil then for _, layer in pairs(song.layers) do if layer.volume ~= 100 then print(layer.volume) end end end

    term.setCursorPos(paddingX-1, paddingY)
    term.setTextColor(color)
    term.setBackgroundColor(color)
    for k,pitch in pairs(pitches) do if k >= #pitches-maxX then
        local x,y = term.getCursorPos()
        
        term.setCursorPos(x+1, paddingY-(pitch/width))
        term.write("0")
    end end
    
   term.setCursorPos(paddingX-1, paddingYV)
    term.setTextColor(colors.green)
    term.setBackgroundColor(colors.green)
    for k,volume in pairs(volumes) do if k >= #volumes-maxX then
        local x,y = term.getCursorPos()
        
        term.setCursorPos(x+1, paddingYV-(volume/widthV))
        term.write("0")
    end end
        term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    term.setCursorPos(1, 1)
    
    if song.header.name == "" then song.header.name = song.header["OG-filename"] end
    if song.header.author == "" then song.header.author = song.header["OG-author"] end
    
    print(" - " .. song.header.name .. " - from " .. song.header.author .. " playing for " .. math.floor(ticks) .. "/" .. math.floor(song.header.length) .. " ticks")
end end
