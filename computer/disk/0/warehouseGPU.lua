---@diagnostic disable: undefined-field
local screen = peripheral.wrap("monitor_23") or error("no screen found")
local screenSize = {x = 100, y = 67}
local selfFile = fs.find("*/warehouseGPU.lua")[1]
local tools, fileTools, ports, gcna, graphicTools = ...

fileTools, tools, ports, gcna, graphicTools = require(fileTools), require(tools), require(ports), require(gcna), require(graphicTools)

graphicTools.extend_screen(screen)

local favoritePlaceholder = fileTools.read(fs.getDir(selfFile) .. "/placeholder.nfp")

gcna.init({
   LAN = {"top", ports.warehouseGPU}
})

-- constants
    -- visual constants
    local bgColor = colors.yellow
    local txtColor = colors.black

    local title = {
      txt = "Warehouse Inventory",
      padding = { x = screenSize.x/2-(#"Warehouse Inventory"*1.5-1), y = 5 }, -- title.txt
      color = colors.black
    }

    local bar = {
      barSize = 3,
      borderSize = 1,
      borderColor = colors.black,
      barColor = colors.white,
      barColorFull = colors.red,
      padding = {x = 9, y = 4},
      length = screenSize.x - ((9*2)+3), -- 9 = bar.padding.x
   }

   local barTxt = {
      txt = "%s (%s%%) items out of %s stored",
      color = colors.black,
      bgColor = colors.white,
   }

   local itmGrid = {
      grid = {x=4, y=3},
      paddingY = 4,
      size = {x=15, y=12},
      spacing = 4,
   }

   local sideBar = {
      width = 4,
      color = colors.black,
      padding = {x = 4, y = 3},
   }

while true do -- Main loop
    local inventory = gcna.receive(0, {LAN = {ports.warehouseGPU}})

    print("update!")

    local favorites = inventory.favorites

    screen.setTextScale(0.5)
    screen.setCursorBlink(false)
    screen.setBackgroundColor(bgColor)
    screen.setTextColor(txtColor)
    screen.setCursorPos(1, 1)
    screen.clear()

     -- title 
    screen.setCursorPos(title.padding.x, title.padding.y)
    screen.setTextColor(title.color)
    screen.printBig(title.txt)

    -- bar
    bar.size = bar.barSize + (bar.borderSize*2)
    screen.setCursorPosX(bar.padding.x)
    screen.moveCursor(1, bar.padding.y)

    screen.drawLineV(bar.size, bar.borderColor)
    screen.moveCursor(1, -bar.size)

    for i=1,bar.length do
        local progress = i/bar.length
        screen.drawLineV(bar.borderSize, bar.borderColor)
        if progress <= inventory.usedSize/inventory.size then
            screen.drawLineV(bar.barSize, bar.barColorFull)
        else
            screen.drawLineV(bar.barSize, bar.barColor)
        end
        screen.drawLineV(bar.borderSize, bar.borderColor)
        screen.moveCursor(1, -bar.size)
    end

    screen.drawLineV(bar.size, bar.borderColor)

    -- barTxt
    barTxt.txtF = string.format(barTxt.txt, inventory.usedSize, math.floor((inventory.usedSize/inventory.size)*100+0.5), inventory.size)
    screen.moveCursor((-bar.length-#barTxt.txtF)/2, -bar.size/2)
    screen.setBackgroundColor(barTxt.bgColor)
    screen.setTextColor(barTxt.color)
    screen.write(barTxt.txtF)
    -- move Y back for padding
    screen.moveCursor(0, bar.size/2)

    -- itmGrid
    itmGrid.leftLinePosX = (screenSize.x-(itmGrid.size.x*itmGrid.grid.x + itmGrid.spacing*(itmGrid.grid.x-1)))/2
    screen.moveCursor(0, itmGrid.paddingY)
    screen.setCursorPosX(itmGrid.leftLinePosX)
    itmGrid.basePos = {}
    itmGrid.basePos.x, itmGrid.basePos.y = screen.getCursorPos()
    for y=0,itmGrid.grid.y-1 do
        for x=0,itmGrid.grid.x-1 do
            local localBase = {itmGrid.basePos.x+(itmGrid.size.x+itmGrid.spacing)*x, itmGrid.basePos.y+(itmGrid.size.y+itmGrid.spacing)*y}

    	    -- Box
    	      screen.setCursorPos(localBase[1], localBase[2])
            screen.drawRect(itmGrid.size.x, itmGrid.size.y)

            -- Content
            screen.setCursorPos(localBase[1]+1, localBase[2]+1)
            local favorite = {}
            local favoriteName = "empty"
            local favoriteCount = "NaN"
            if favorites[y+1][x+1] ~= "empty" and inventory[favorites[y+1][x+1].name] ~= nil then
                favorite = favorites[y+1][x+1]
                favoriteName = inventory[favorite.name].displayName
                favoriteCount = inventory[favorite.name].count
            end

            screen.moveCursor(1, 0)
            screen.drawPicture(favorite.icon or favoritePlaceholder)
            if favorite.icon == "" then
                screen.moveCursor(0, 7)
            end
            screen.moveCursor(0, 2)

            screen.setBackgroundColor(bgColor)
            screen.setCursorPosX(localBase[1]+itmGrid.size.x/2-#favoriteName/2)

            screen.write(favoriteName)
            screen.moveCursor(0, 1)
            screen.setCursorPosX(localBase[1]+itmGrid.size.x/2-#(tostring(favoriteCount))/2)
            screen.write(tostring(favoriteCount))
        end
    end

    -- sideBars
    screen.setCursorPos(sideBar.padding.x, sideBar.padding.y)
    sideBar.length = screenSize.y - (sideBar.padding.y*2)
   screen.drawLineV(sideBar.length, sideBar.color, sideBar.width)

    screen.setCursorPos(screenSize.x - sideBar.padding.x - sideBar.width, sideBar.padding.y)
    sideBar.length = screenSize.y - (sideBar.padding.y*2)
   screen.drawLineV(sideBar.length, sideBar.color, sideBar.width)
end
