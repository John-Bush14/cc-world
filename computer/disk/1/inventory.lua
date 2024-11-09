local modem = peripheral.wrap("bottom") or error("No internet connection")
local id = modem.getNameLocal()
local tickDelay = 0
local toolsFile, fileToolsFile, portsFile, gcnaFile = ...

modem.closeAll()

local _, tools, ports, gcna = require(fileToolsFile), require(toolsFile), require(portsFile), require(gcnaFile)

print("Turned on: Inventory!")

gcna.init {
    LAN = {"bottom", ports.inventory}
}

gcna.transmit("LAN", ports.inventory, {request="inventoryInit", id=id})

local message = {}
while message.id ~= id do
    message = gcna.receive()
end

local chests = message.chests

local inventory = {}
local SerialInventory = ""
local function getChanges()
    local changes = {}
    local newInventory, size = tools.getInventory(chests)
    local newSerialInventory = textutils.serialize(newInventory)

    if SerialInventory ~= newSerialInventory then
        print("Change!")
        for name, items in pairs(tools.combine(inventory, newInventory)) do
            if items[1] == nil then
                changes[name] = items[2]
            elseif items[2] == nil then
                changes[name] = {count = -items[1].count, oldSources = items[1].sources}
            elseif items[1].count ~= items[2].count then
                print(items[2].sources)
                changes[name] = {count = items[2].count - items[1].count, sources = items[2].sources, oldSources = items[1].sources}
            end
        end
        SerialInventory = newSerialInventory
        inventory = newInventory
        return changes, size
    end

    return nil, size
end

repeat
    local changes, size = getChanges()
    if changes ~= nil then
        gcna.transmit("LAN", ports.inventory, {changes = changes, sender = id, size = size, request = "change"})
    end
    sleep(tickDelay)
until false
