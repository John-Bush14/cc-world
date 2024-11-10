local toolsFile, fileToolsFile, portsFile, gcnaFile = ...

local _, _, ports, gcna = require(fileToolsFile), require(toolsFile), require(portsFile), require(gcnaFile)

gcna.init {
    LAN = {"top", ports.inventoryHubInit},
    WWN = {"back", ports.hubReboot}
}

local inventoryHub

local function reboot()
    local _ = {peripheral.find("computer", function(_, computer)
        if computer.getLabel() == "hub" then return false end
        if computer.getLabel() == "inventoryHub" then inventoryHub = computer end

        --print(name)    
        computer.shutdown()

        return false
    end)}

    if inventoryHub ~= nil then
        inventoryHub.turnOn()
        gcna.receive(0, {LAN = {ports.inventoryHubInit}})
        print("turned on")
    end

    local _ = {peripheral.find("computer", function(_, computer)
        if computer.getLabel() == "hub" then return false end
        if computer.getLabel() == "manager" then return false end

        computer.turnOn()

        return false
    end)}

   local _ = {peripheral.find("turtle", function(_, turtle)
      turtle.shutdown()

      turtle.turnOn()
   end)}
end

print("rebooting!")
reboot()

print("starting loop!")
while true do
    gcna.receive(0, {WWN = {ports.hubReboot}})
    print("rebooting again!")
    reboot()
end
