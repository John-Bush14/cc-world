local tools = {}

function tools.getInventory(chests, inventoryPeripheral)
    local inventory = {}
    local size = 0
    chests = chests or {peripheral.find(inventoryPeripheral or "minecraft:chest")}
    for _, chestName in pairs(chests) do
        local chest = peripheral.wrap(chestName) or error("unreachable!")
        size = size + chest.size()*64
        for slot, item in pairs(chest.list()) do
            if item ~= nil then

               ---@diagnostic disable-next-line: undefined-field -- item.nbtHash gone in newer version
               local name = item.nbtHash or item.name or print(textutils.serialize(item))

                if inventory[name] == nil then
                  ---@diagnostic disable-next-line: undefined-field -- getItemMeta renamed in newer version
                    inventory[name] = chest.getItemMeta(slot)
                    inventory[name].sources = {}
                else
                    inventory[name].count = item.count + inventory[name].count
                end

                table.insert(inventory[name].sources, {name=name,slot=slot,count=item.count,chestName = chestName,clusterName = selfName})
            end
        end
    end
    return inventory, size
end

function tools.combine(t1, t2)
    local t3 = {}
    for k, i in pairs(t1) do
        t3[k] = {i, nil}
    end
    for k, i in pairs(t2) do
        if t3[k] ~= nil then
            t3[k][2] = i
        else
            t3[k] = {nil, i}
        end
    end
    return t3
end

function tools.tblLen(tbl)
    local x = 0
    for _,_ in pairs(tbl) do x = x + 1 end
    return x
end

function tools.tblContains(tbl, element)
    for _, e in pairs(tbl) do
        if element == e then
            return true
        end
    end
    return false
end

function tools.tblSubstract(tbl1, tbl2)
    for k, i in pairs(tbl1) do
        if tools.tblContains(tbl2, i) then
            tbl1[k] = nil
        end
    end
end

function tools.tblAdd(tbl1, tbl2)
    for _, i in pairs(tbl2) do
        table.insert(tbl1, i)
    end
end

function tools.getNetworkEvents()
    local _ = os.startTimer(0)
    local events = { os.pullEventRaw() }
    local modemMessage = false
    local modemEvents = {}

    for _, event in pairs(events) do
        if type(event) == "table" and modemMessage then
            event.event = "modemMessage"
            table.insert(modemEvents, event)
        end
        if event == "modem_message" then
            modemMessage = true
        end
    end
    return modemEvents
end

return tools
