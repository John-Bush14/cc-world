local query, amount = ...

local item, modem, inventory, itemRemotePort = require("getItem")(query)

if item == nil then return end

modem.transmit(itemRemotePort, 128, {count=amount, item=item, request="send"})

print("Transmiting...")

os.pullEvent("modem_message")

print("Here!")
