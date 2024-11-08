local modem = peripheral.wrap("bottom")
local id = modem.getNameLocal()
local playerInventory = peripheral.find("manipulator").getInventory()

local tools, fileTools, ports, gcna = ...

local fileTools, tools, ports, gcna = require(fileTools), require(tools), require(ports), require(gcna)

gcna.init {
    LAN = {"bottom", ports.itemManager}
}

while true do
    message = gcna.receive()
    if message.request == "receive" and message.cluster == id then
        print("recieving!")
        local curSource = 1

        local returnable = function(message)
        
            for _, chest in pairs(message.chests) do
                local loop = true
                while loop do
                    loop = false
                    local source = message.sources[curSource]
                    source.count = source.count - peripheral.call(chest, "pullItems", source.chestName, source.slot, source.count)
                    if source.count <= 0 then 
                        message.sources[curSource] = nil
                        curSource = curSource + 1
                        loop = true
                    end
                    if tools.tblLen(message.sources) <= 0 then return end
                end
            end
        end
        
        returnable(message)
        
        gcna.transmit("LAN", ports.itemManager, {[1]=message.sources})
    end
end
