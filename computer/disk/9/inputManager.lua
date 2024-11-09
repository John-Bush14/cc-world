local inputChests = {"minecraft:chest_120", "minecraft:chest_121"}

local toolsFile, fileToolsFile, portsFile, gcnaFile = ...

local _, tools, ports, gcna = require(fileToolsFile), require(toolsFile), require(portsFile), require(gcnaFile)

gcna.init {
    LAN = {"back", ports.inputManager}
}

while true do
    local input = tools.getInventory(inputChests)

    for name, item in pairs(input) do
        gcna.transmit("LAN", ports.inputManager, {request="receive", sources=item.sources})
        gcna.receive(0, {LAN={ports.inputManager}})
    end
end
