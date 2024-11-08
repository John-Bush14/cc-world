local sizes = {}
local favorites = {}
local clusters = {"computer_33", "computer_40", "computer_39", "computer_38"}
local playerInventory = peripheral.find("manipulator").getInventory()

local chests = {}
local _ = {peripheral.find("minecraft:chest", function(name, chest) 
    if name == "minecraft:chest_120" or name == "minecraft:chest_121" or name == "minecraft:chest_165" then return end
    
    table.insert(chests, name)
end)}

print(#chests)

local tools, fileTools, ports, gcna = ...
local tools, fileTools, ports, gcna = require(tools), require(fileTools), require(ports), require(gcna)

gcna.init {
    LAN = {"top", ports.item, ports.itemManager, ports.inventory, ports.inputManager},
    WWN = {"back", ports.itemRemote}
}

gcna.transmit("LAN", ports.inventoryHubInit, {})

function updateFavorites()
    for y=1,3 do
        favorites[y] = {}
        for x=1,4 do
            favorites[y][x] = "empty"
        end
    end

    if not fs.exists("favorites") then
        fileTools.write("favorites", "")
    else
        local favoritesFile = fileTools.decodeFavorites(fileTools.read("favorites"))
        
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

for x=1,4 do
    local inventoryChests = {}

    for i=1,#chests/4 do
        table.insert(inventoryChests, chests[#chests])
        chests[#chests] = nil
    end

    table.insert(clusterChests, inventoryChests)
end

inventory = {usedSize = 0, size = 0}

function change(changes)
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
end

while true do
    local message, port, modem = gcna.receive()
    
    if port == ports.inventory then -- message from inventoryCluster
        if message.request == "inventoryInit" then 
            gcna.transmit("LAN", ports.inventory, {chests=clusterChests[inventories], id = message.id})
            inventories = inventories + 1
        else
            change(message)
            inventory.favorites = favorites
            gcna.transmit("LAN", ports.warehouseGPU, inventory)
        end
    else local requestMatch = {
    
        get = function()
            gcna.transmit("WWN", ports.itemRemote, inventory)
        end,
    
        send = function()
            for _, source in pairs(inventory[message.item].sources) do
                if tonumber(source.count) > 0 and tonumber(message.count) > 0 then
                    print("check")
                    source.count = math.min(math.max(source.count, 0), math.max(message.count, 0))
                    print(source.count, message.count)
                
                    playerInventory.pullItems(source.chestName, source.slot, source.count)
                    message.count = message.count - source.count
                     print(source.count, message.count, "2")
                end
            end
        
            gcna.transmit("WWN", ports.itemRemote, 0)
    
        end,
    
        receive = function()
            print("receiving")
        
            for k, cluster in pairs(clusters) do if tools.tblLen(message.sources) > 0 then
                gcna.transmit("LAN", ports.itemManager, {sources = message.sources, cluster=cluster, request="receive", chests=clusterChests[k]})
                message.sources = gcna.receive(5, {LAN = {ports.itemManager}})[1]
            end end
            
            gcna.transmit("LAN", ports.inputManager, {})
            print("done!")
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
            fileTools.remove("favorites", codedFavoritePattern)
            
            if message.operation == "add" then
                fileTools.append("favorites", codedFavorite)
            end
            
            updateFavorites()
            inventory.favorites = favorites
            gcna.transmit("LAN", ports.warehouseGPU, inventory)
        end
    }
    
    requestMatch[message.request]() end
end
