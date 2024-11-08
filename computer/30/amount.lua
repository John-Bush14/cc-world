local query = ...

local item, modem, inventory, itemRemotePort = require("getItem")(query)

print(inventory[item].count)
