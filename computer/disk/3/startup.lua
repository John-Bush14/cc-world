local toolfiles = {
    "tools",
    "fileTools",
    "ports",
    "gcna"
}
local utilityFiles = {}

for _, toolfile in pairs(toolfiles) do
    table.insert(utilityFiles, "../" .. string.gsub(string.gsub(fs.find("*/" .. toolfile .. ".lua")[1], "%.lua", ""), "%/", "."))
end

if os.getComputerLabel() ~= "hub" then
    print("find passion!")
    shell.run(fs.find("*/" .. (os.getComputerLabel() or "inventory") .. ".lua")[1], table.unpack(utilityFiles))
    error("passion ended!")
end

local toolsFile, fileToolsFile, portsFile, gcnaFile = table.unpack(utilityFiles)

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
end

print("rebooting!")
reboot()

print("starting loop!")
while true do
    gcna.receive(0, {WWN = {ports.hubReboot}})
    print("rebooting again!")
    reboot()
end
