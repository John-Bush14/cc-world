local query, amount = ...

local item, modem, _, itemRemotePort = require("getItem")(query)

modem.open(itemRemotePort)

if item == nil then return end

modem.transmit(itemRemotePort, 128, {count=amount or 1, item=item, request="send"})

print("Transmiting...")

os.pullEvent("modem_message")

print("Here!")
