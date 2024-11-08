local ports = {}

-- global LAN = 0-9
-- global WWN = 10-19
-- local LAN = 20-59
-- local WWN = 60-89
-- special = 90-100

-- global LAN interactions with inventoryHub
ports.item = 0

-- global WWN interactions with inventoryHub
ports.itemRemote = 10

-- global WWN hub reboot signal
ports.hubReboot = 11

-- local coms between inventoryHub and inventory
ports.inventory = 20

-- local coms between inventoryHub and itemManager
ports.itemManager = 21

-- local init signal from inventoryHub to hub
ports.inventoryHubInit = 22

-- local coms from inventoryHub to warehouseGPU 
ports.warehouseGPU = 23

-- local coms between inventoryHub and inputManager
ports.inputManager = 24

-- for when return port is unnecesary
ports.empty = 128

return ports
