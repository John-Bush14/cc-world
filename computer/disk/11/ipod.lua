print(textutils.serialize(require("nbsParser")(io.open("disk/Undertale.nbs", "rb")).notes))

if true then return end

local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

local pause = keys.space
local nextK = keys.right
local previous = keys.left
local volumeUp = keys.up
local volumeDown = keys.down

local soundFile = "test.wav"
local chunkSize = 16

local paused = false
local volume = 1

local decoder = dfpwm.make_decoder()
local soundIterator = function() return nil end

function getKeys()
   os.startTimer(0)
   local events = {os.pullEvent()}
   local keys = {}

   for _, event in pairs(events) do
      if tonumber(event) == nil then print(event, "event") end
   end

   return keys
end

while true do
    if not paused then local buffer = soundIterator() else buffer = nil end
    
    for _, key in pairs(keys) do
        if key == pause then
            paused = -paused
        elseif key == nextK then

        elseif key == previous then

        elseif key == volumeUp then
            volume = math.min(volume + 1, 3)
        elseif key == volumeDown then
            volume = math.max(volume - 1, 0)
        end
    end

    while buffer ~= nil and not speaker.playAudio(buffer) do
        os.pullEvent("speaker_audio_empty")
    end
end
