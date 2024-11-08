local toolfiles = {
    "tools",
    "fileTools",
    "ports",
    "gcna"
}
local tools = {}

for _, toolfile in pairs(toolfiles) do
    table.insert(tools, "../" .. string.gsub(string.gsub(fs.find("*/" .. toolfile .. ".lua")[1], "%.lua", ""), "%/", "."))
end

if os.getComputerLabel() ~= "hub" then
    print("find passion!")
    shell.run(fs.find("*/" .. (os.getComputerLabel() or "inventory") .. ".lua")[1], table.unpack(tools))
    error("passion ended!")
end

local tools, fileTools, ports, gcna = table.unpack(tools)

local fileTools, tools, ports, gcna = require(fileTools), require(tools), require(ports), require(gcna)

gcna.init {
    LAN = {"top", ports.inventoryHubInit},
    WWN = {"back", ports.hubReboot}
}

local inventoryHub

function reboot()
    local computers = {peripheral.find("computer", function(name, computer)
        if computer.getLabel() == "hub" then return end
        if computer.getLabel() == "inventoryHub" then inventoryHub = computer end
        
        --print(name)    
        computer.shutdown()
    end)}

    if inventoryHub ~= nil then 
        inventoryHub.turnOn()
        gcna.receive(0, {LAN = {ports.inventoryHubInit}})
        print("turned on")
    end
    
    local computers = {peripheral.find("computer", function(name, computer)
        if computer.getLabel() == "hub" then return end
        if computer.getLabel() == "manager" then return end
            
        computer.turnOn()
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
