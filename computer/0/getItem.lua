local modem = peripheral.find("modem") or error("no modem!")
local itemRemotePort = 50

modem.open(itemRemotePort)

return function(query)

modem.transmit(itemRemotePort, 128, {request = "get"})

local _,_,_,_,inventory,_ = os.pullEvent("modem_message")

for name, item in pairs(inventory) do
    if type(item)  == "table" then
        local possibilitys = {[name or ""]=true, [string.match(name, ":(.*)") or ""]=true, [item.displayName or ""]=true}
        if possibilitys[query] ~= nil then
            return name, modem, inventory, itemRemotePort
        end
    end
end

print("Item Not Found!")

return nil, modem, inventory, itemRemotePort

end
