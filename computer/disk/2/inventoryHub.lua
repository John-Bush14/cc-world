local sizes = {}
local favorites = {}
local clusters = {"computer_33", "computer_40", "computer_39", "computer_38"}
---@diagnostic disable-next-line: param-type-mismatch, undefined-field -- manipulator is from mod and not in lsp
local playerInventory = peripheral.find("manipulator").getInventory()

local chests = {}
---@diagnostic disable-next-line: param-type-mismatch -- lsp in newer version where "inventory" is correct
local _ = {peripheral.find("minecraft:chest", function(name, _)
    if name == "minecraft:chest_120" or name == "minecraft:chest_121" or name == "minecraft:chest_165" then return false end

    table.insert(chests, name)

    return false
end)}

print(#chests)

local toolsFile, fileToolsFile, portsFile, gcnaFile = ...
local tools, fileTools, ports, gcna = require(toolsFile), require(fileToolsFile), require(portsFile), require(gcnaFile)

local selfDisk = fs.getDir(fs.find("*/" .. (os.getComputerLabel() or "inventory") .. ".lua")[1])

gcna.init {
    LAN = {"top", ports.item, ports.itemManager, ports.inventory, ports.inputManager},
    WWN = {"back", ports.itemRemote}
}

gcna.transmit("LAN", ports.inventoryHubInit, {})

local function updateFavorites()
    for y=1,3 do
        favorites[y] = {}
        for x=1,4 do
            favorites[y][x] = "empty"
        end
    end

    if not fs.exists(selfDisk.."/favorites") then
        fileTools.write(selfDisk.."/favorites", "")
    else
        local favoritesFile = fileTools.decodeFavorites(fileTools.read(selfDisk.."/favorites"))

        for _, data in pairs(favoritesFile) do
            if tonumber(data.y) > 0 and tonumber(data.y) < 4 and tonumber(data.x) > 0 and tonumber(data.x) < 5 then
                favorites[tonumber(data.y)][tonumber(data.x)] = {name=data.name, icon=data.icon}
            end
        end
    end
end

updateFavorites()

local inventories = 1
local clusterChests = {}

for _=1,4 do
    local inventoryChests = {}

    for _=1,#chests/4 do
        table.insert(inventoryChests, chests[#chests])
        chests[#chests] = nil
    end

    table.insert(clusterChests, inventoryChests)
end

local inventory = {usedSize = 0, size = 0, favorites = favorites}
local virtualInventory = tools.tblCopy(inventory)

local function change(changes)
    if sizes[changes.sender] == nil then
        inventory.size = changes.size + inventory.size
    end

    sizes[changes.sender] = changes.size

    print("Changement!")
    changes = changes.changes
    for name, item in pairs(changes) do
       if inventory[name] == nil then
           inventory[name] = item
       else
           print(item.count)
           inventory[name].count = item.count + inventory[name].count
           if item.sources ~= nil then
               tools.tblSubstract(inventory[name].sources, item.oldSources or {})
               tools.tblAdd(inventory[name].sources, item.sources or {})
           end
       end
       inventory.usedSize = inventory.usedSize + item.count
    end

    virtualInventory = tools.tblCopy(inventory)
end

while true do
    local message, port, _ = gcna.receive()

    if port == ports.inventory then -- message from inventoryCluster
        if message.request == "inventoryInit" then
            gcna.transmit("LAN", ports.inventory, {chests=clusterChests[inventories], id = message.id})
            inventories = inventories + 1
        else
            inventory.favorites = favorites
            change(message)
            gcna.transmit("LAN", ports.warehouseGPU, inventory)
        end
    else local requestMatch = {

        get = function()
            gcna.transmit("WWN", ports.itemRemote, inventory)
        end,

        send = function()
           print("sending!")

            for k, source in pairs(virtualInventory[message.item].sources) do
                if tonumber(source.count) > 0 and tonumber(message.count) > 0 then
                    print("check")
                    source.count = math.min(math.max(source.count, 0), math.max(message.count, 0))
                    print(source.count, message.count)

                    if port == ports.itemRemote then playerInventory.pullItems(source.chestName, source.slot, source.count)
                     else peripheral.wrap(source.chestName).pushItems(message.dest, source.slot, source.count) end
                    message.count = message.count - source.count
                     print(source.count, message.count, "2")

                     virtualInventory[message.item].count = virtualInventory[message.item].count - source.count

                     virtualInventory.usedSize = virtualInventory.usedSize - source.count

                     virtualInventory[message.item].sources[k].count = inventory[message.item].sources[k].count - source.count
                end
            end

            if port == ports.itemRemote then gcna.transmit("WWN", port, 0)
            else gcna.transmit("LAN", ports.item, 0) end

            gcna.transmit("LAN", ports.warehouseGPU, virtualInventory)
        end,

        receive = function()
            print("receiving")

            for _, source in pairs(message.sources) do
               if virtualInventory[source.name] == nil then
                  ---@diagnostic disable-next-line: undefined-field
                  virtualInventory[source.name] = peripheral.wrap(source.chestName).getItemMeta(source.slot) or {}

                  virtualInventory[source.name].count = 0
                  virtualInventory[source.name].sources = {}
                  virtualInventory[source.name].name = source.name
               end

               virtualInventory[source.name].count = virtualInventory[source.name].count + source.count

               virtualInventory.usedSize = virtualInventory.usedSize + source.count
            end

            for k, cluster in pairs(clusters) do if tools.tblLen(message.sources) > 0 then
                gcna.transmit("LAN", ports.itemManager, {sources = message.sources, cluster=cluster, request="receive", chests=clusterChests[k]})
                message.sources = gcna.receive(5, {LAN = {ports.itemManager}})[1]
            end end

            gcna.transmit("LAN", ports.inputManager, {})
            print("done!")

            gcna.transmit("LAN", ports.warehouseGPU, virtualInventory)
        end,

        favorite = function()
            for y=1,3 do for x=1,4 do
                if favorites[y][x] == "empty" and message.position.x == nil then
                    message.position.y = y
                    message.position.x = x
                end
            end end

            local codedFavorite = fileTools.encodeFavorite({
                y=message.position.y, x=message.position.x, name=message.itemKey, icon=message.icon
            })

            local codedFavoritePattern = string.gsub(codedFavorite, "|"..message.position.y.."|", "|.|")
            codedFavoritePattern = string.gsub(codedFavoritePattern,  "|"..message.position.x.."|", "|.|")
            fileTools.remove(selfDisk .. "/favorites", codedFavoritePattern)

            if message.operation == "add" then
                fileTools.append(selfDisk .. "/favorites", codedFavorite)
            end

            updateFavorites()
            inventory.favorites = favorites
            gcna.transmit("LAN", ports.warehouseGPU, inventory)
        end
    }

    requestMatch[message.request]() end
end
