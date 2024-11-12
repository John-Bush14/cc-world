local toolsFile, fileToolsFile, portsFile, gcnaFile = ...
local tools, fileTools, ports, gcna = require(toolsFile), require(fileToolsFile), require(portsFile), require(gcnaFile)


gcna.init({
   LAN = {"bottom", ports.item}
})


local jobs = {
   "wheat",
   "potatos",
   "carrots",
   "beetroots",
   "melon planting",
   "melon harvesting",
   "pumpking planting",
   "pumpking harvesting"
}


local place = 21-tonumber(string.sub(peripheral.wrap("bottom").getNameLocal() or "turtle_14", 8, 9)) + 1

local job = jobs[place]


   
