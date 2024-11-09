local modem = peripheral.wrap("top") or error("No internet connection")

local screen = peripheral.wrap("monitor_23") or error("no screen found")
local screenSize = {x = 100, y = 67}
local selfFile = fs.find("*/warehouseGPU.lua")[1]
local tools, fileTools, ports = ...

fileTools, tools, ports = require(fileTools), require(tools), require(ports)

local favoritePlaceholder = fileTools.read(fs.getDir(selfFile) .. "/placeholder.nfp")

local bigfont = require("bigfont")

modem.closeAll()
modem.open(ports.warehouseGPU)

-- constants
    -- tables
    local title = {}
    local bar = {}
    local barTxt = {}
    local itmGrid = {}
    local sideBar = {}

    -- visual constants
    local bgColor = colors.yellow
    local txtColor = colors.black

    -- title
    title.txt = "Warehouse Inventory"
    title.padding = { x = screenSize.x/2-(#title.txt*1.5-1), y = 5 }
    title.color = colors.black

    -- bar
    bar.barSize = 3
    bar.borderSize = 1
    bar.borderColor = colors.black
    bar.barColor = colors.white
    bar.barColorFull = colors.red
    bar.padding = {x = 9, y = 4}
    bar.length = screenSize.x - ((bar.padding.x*2)+3)

    --barTxt
    barTxt.txt = "%s (%s%%) items out of %s stored"
    barTxt.color = colors.black
    barTxt.bgColor = colors.white

    -- itemGrid
    itmGrid.grid = {x=4, y=3}
    itmGrid.paddingY = 4
    itmGrid.size = {x=15, y=12}
    itmGrid.spacing = 4

    -- sideBars
    sideBar.width = 4
    sideBar.color = colors.black
    sideBar.padding = {x = 4, y = 3}

-- Helper functions
    local function setCursorPosX(x)
        local _, y = screen.getCursorPos()
        screen.setCursorPos(x, y)
    end

    local function setCursorPosY(y)
        local x, _ = screen.getCursorPos()
        screen.setCursorPos(x, y)
    end

    local function moveCursor(x, y)
        if type(x) == "table" then
        y = x.y
        x = x.x
        end
        local ox, oy = screen.getCursorPos()
        screen.setCursorPos(ox+x, oy+y)
    end

    local function printm(text)
        screen.write(text)
    end

    local function printBig(text, size)
        local x, y = screen.getCursorPos()
        bigfont.writeOn(screen, size or 1, text, x, y)
    end

    local function drawPixel(color)
        local oldBg = screen.getBackgroundColor()
        local oldTxt = screen.getTextColor()
        screen.setBackgroundColor(color or screen.getTextColor())
        screen.setTextColor(color or screen.getTextColor())
        printm("o")
        screen.setBackgroundColor(oldBg)
        screen.setTextColor(oldTxt)
    end

    local function drawLineV(len, color)
        for _= 1,len do
            drawPixel(color)
            moveCursor(-1, 1)
        end
    end

    local function drawLineH(len, color)
        for _=1,len do
            drawPixel(color)
        end
    end

    local function drawPicture(picture)
        local lineLength = 0
        for c in picture:gmatch(".") do
            if c ~= " " and c ~= "\n" then
                drawPixel(2^tonumber(c, 16))
            elseif c == "\n" then
                moveCursor(-lineLength, 1)
                lineLength = -1
            else
                moveCursor(1, 0)
            end
            lineLength = lineLength + 1
        end
    end

while true do -- Main loop
    local _, _, _, _, inventory, _ = os.pullEvent("modem_message")

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
    printBig(title.txt)

    -- bar
    bar.size = bar.barSize + (bar.borderSize*2)
    setCursorPosX(bar.padding.x)
    moveCursor(1, bar.padding.y)

    drawLineV(bar.size, bar.borderColor)
    moveCursor(1, -bar.size)

    for i=1,bar.length do
        local progress = i/bar.length
        drawLineV(bar.borderSize, bar.borderColor)
        if progress <= inventory.usedSize/inventory.size then
            drawLineV(bar.barSize, bar.barColorFull)
        else
            drawLineV(bar.barSize, bar.barColor)
        end
        drawLineV(bar.borderSize, bar.borderColor)
        moveCursor(1, -bar.size)
    end

    drawLineV(bar.size, bar.borderColor)

    -- barTxt
    barTxt.txtF = string.format(barTxt.txt, inventory.usedSize, math.floor((inventory.usedSize/inventory.size)*100+0.5), inventory.size)
    moveCursor((-bar.length-#barTxt.txtF)/2, -bar.size/2)
    screen.setBackgroundColor(barTxt.bgColor)
    screen.setTextColor(barTxt.color)
    printm(barTxt.txtF)
    -- move Y back for padding
    moveCursor(0, bar.size/2)

    -- itmGrid
    itmGrid.leftLinePosX = (screenSize.x-(itmGrid.size.x*itmGrid.grid.x + itmGrid.spacing*(itmGrid.grid.x-1)))/2
    moveCursor(0, itmGrid.paddingY)
    setCursorPosX(itmGrid.leftLinePosX)
    itmGrid.basePos = {}
    itmGrid.basePos.x, itmGrid.basePos.y = screen.getCursorPos()
    for y=0,itmGrid.grid.y-1 do
        for x=0,itmGrid.grid.x-1 do
            local localBase = {itmGrid.basePos.x+(itmGrid.size.x+itmGrid.spacing)*x, itmGrid.basePos.y+(itmGrid.size.y+itmGrid.spacing)*y}

    	    -- Box
    	    screen.setCursorPos(localBase[1], localBase[2])
            drawLineV(itmGrid.size.y)
            drawLineH(itmGrid.size.x)
            moveCursor(-1, -itmGrid.size.y)
            drawLineV(itmGrid.size.y)
            screen.setCursorPos(localBase[1], localBase[2])
            drawLineH(itmGrid.size.x)

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

            moveCursor(1, 0)
            drawPicture(favorite.icon or favoritePlaceholder)
            if favorite.icon == "" then
                moveCursor(0, 7)
            end
            moveCursor(0, 2)

            screen.setBackgroundColor(bgColor)
            setCursorPosX(localBase[1]+itmGrid.size.x/2-#favoriteName/2)

            printm(favoriteName)
            moveCursor(0, 1)
            setCursorPosX(localBase[1]+itmGrid.size.x/2-#(tostring(favoriteCount))/2)
            printm(tostring(favoriteCount))
        end
    end

    -- sideBars
    screen.setCursorPos(sideBar.padding.x, sideBar.padding.y)
    sideBar.length = screenSize.y - (sideBar.padding.y*2)
    for _=1,sideBar.width do
        drawLineV(sideBar.length, sideBar.color)
        moveCursor(1, -sideBar.length)
    end

    screen.setCursorPos(screenSize.x - sideBar.padding.x, sideBar.padding.y)
    sideBar.length = screenSize.y - (sideBar.padding.y*2)
    for _=1,sideBar.width do
        drawLineV(sideBar.length, sideBar.color)
        moveCursor(-1, -sideBar.length)
    end
end
