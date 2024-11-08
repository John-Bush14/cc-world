local speaker = peripheral.find("speaker")

local instruments = {
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
   "xylophone", -- unsupported in 1.12
   "xylophone",
   "bass",
   "guitar",
   "guitar", 
   "guitar"
}

local pause = keys.space
local nextK = keys.right
local previous = keys.left
local volumeUp = keys.up
local volumeDown = keys.down

print("Parsing song!")
local songFile = "Undertale.nbs"
local song = require("nbsParser")(io.open(songFile, "rb"))

local paused = false
local volume = 1

speedMod = 1

local tempo = song.header.tempo/100 * speedMod

local spt = 1/tempo

function getKeys()
   os.startTimer(0)
   local events = {os.pullEvent()}
   local keys = {}

   for _, event in pairs(events) do
      --if tonumber(event) == nil then print(event, "event") end
   end

   return keys
end

print("Starting song!")

local k, note

while true do 
    local startTick = os.clock()
     
    for _, key in pairs({}) do
        if key == pause then
            paused = not paused
        elseif key == nextK then

        elseif key == previous then

        elseif key == volumeUp then
            volume = math.min(volume + 1, 3)
        elseif key == volumeDown then
            volume = math.max(volume - 1, 0)
        end
    end
    
    k, note = next(song.notes, k)
    while type(note) == "table" and not paused do
        print(instruments[note.instrument + 1], note.velocity/(10/3), math.floor(math.min(math.max(((note.key-33)/87*24)+(note.pitch/100), 0), 24)))
        if not speaker.playNote(instruments[note.instrument + 1] or "guitar", note.velocity/(10/3), math.min(math.max((note.key-33)+(note.pitch/100), 0), 24)) then print("oof") end
        k, note = next(song.notes, k)
    end

    if note == nil then
        print("END!")
        return
    end
    
    local endTick = os.clock()

    sleep(math.max(spt - endTick-startTick, 0))
end
