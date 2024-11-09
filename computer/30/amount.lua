local query = ...

local item, _, inventory, _ = require("getItem")(query)

print(inventory[item].count)
