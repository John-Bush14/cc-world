local toolsFile, fileToolsFile, portsFile, gcnaFile = ...
local tools, fileTools, ports, gcna = require(toolsFile), require(fileToolsFile), require(portsFile), require(gcnaFile)


local localName = peripheral.call("bottom", "getNameLocal")


local fuel = "minecraft:coal_block"
local fuelSlot = 1

local seedSlot = 2


gcna.init({
   LAN = {"bottom", ports.itemResult}
})


local jobs = {
   {"wheat_seeds", "wheat"},
   {"potato", "potatoes"},
   {"carrot", "carrot"},
   {"beetroot_seeds", "beetroots"},
   {"melon_seeds", "nothing"},
   {"nothing", "melon_block"},
   {"pumpkin_seeds", "nothing"},
   {"nothing", "pumpkin"}
}


local place = 21-tonumber(string.sub(peripheral.wrap("bottom").getNameLocal() or "turtle_14", 8, 9)) + 1

local job = jobs[place]

while true do
   local blockPresent, block = turtle.inspectDown()
   print("tick!")

   if block.name == "computercraft:wired_modem_full" then
      while turtle.getItemCount(fuelSlot) < 64 do
         gcna.transmit("LAN", ports.item, {
            request = "send",
            item = fuel,
            count = 64-turtle.getItemCount(fuelSlot),
            dest = localName
         })

         sleep(0.5)
      end

      turtle.select(1)
      turtle.refuel(64)

      if job[1] ~= "nothing" then
         print("getting seeds!")

         while turtle.getItemCount(seedSlot) < 64 do
            gcna.transmit("LAN", ports.item, {
               request = "send",
               item = "minecraft:" .. job[1],
               count = 64-turtle.getItemCount(seedSlot),
               dest = localName
            })

            sleep(0.5)
         end
      end
   end

   if block.name == "minecraft:"..job[2] and block.state.age >= 7 then
      turtle.digDown("right")
      blockPresent = false
   end

   if not blockPresent and job[1] ~= "nothing" then
      turtle.select(2)
      turtle.digDown()
      turtle.placeDown()
      print("dig!")
   end

   if turtle.detect() then
      turtle.turnLeft()
      turtle.turnLeft()
      print("turn!")
   end

   turtle.forward()
   print("forawrd!")
end
