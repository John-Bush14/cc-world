local modem = peripheral.wrap("back")
local inputChests = {"minecraft:chest_120", "minecraft:chest_121"}

local tools, fileTools, ports, gcna = ...

local fileTools, tools, ports, gcna = require(fileTools), require(tools), require(ports), require(gcna)

gcna.init {
    LAN = {"back", ports.inputManager}
}

while true do
    
    input = tools.getInventory(inputChests)
    
    for name, item in pairs(input) do
        gcna.transmit("LAN", ports.inputManager, {request="receive", sources=item.sources})
        gcna.receive(0, {LAN={ports.inputManager}})
    end
end
