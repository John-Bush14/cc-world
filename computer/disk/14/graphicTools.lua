local M = {}

local bigfont = require("../" .. fs.getDir(fs.find("*/bigfont.lua")[1]) .. "/bigfont")

function M.extend_screen(screen)
    function screen.setCursorPosX(x)
        local _, y = screen.getCursorPos()
        screen.setCursorPos(x, y)
    end

    function screen.setCursorPosY(y)
        local x, _ = screen.getCursorPos()
        screen.setCursorPos(x, y)
    end

    function screen.moveCursor(x, y)
        if type(x) == "table" then
        y = x.y
        x = x.x
        end
        local ox, oy = screen.getCursorPos()
        screen.setCursorPos(ox+x, oy+y)
    end

    function screen.printm(text)
        screen.write(text)
    end

    function screen.printBig(text, size)
        local x, y = screen.getCursorPos()
        bigfont.writeOn(screen, size or 1, text, x, y)
    end

    function screen.drawPixel(color)
        local oldBg = screen.getBackgroundColor()
        local oldTxt = screen.getTextColor()
        screen.setBackgroundColor(color or screen.getTextColor())
        screen.setTextColor(color or screen.getTextColor())
        screen.printm("o")
        screen.setBackgroundColor(oldBg)
        screen.setTextColor(oldTxt)
    end

    function screen.drawLineV(len, color)
        for _= 1,len do
            screen.drawPixel(color)
            screen.moveCursor(-1, 1)
        end
    end

    function screen.drawLineH(len, color)
        for _=1,len do
            screen.drawPixel(color)
        end
    end

    function screen.drawPicture(picture)
        local lineLength = 0
        for c in picture:gmatch(".") do
            if c ~= " " and c ~= "\n" then
                screen.drawPixel(2^tonumber(c, 16))
            elseif c == "\n" then
                screen.moveCursor(-lineLength, 1)
                lineLength = -1
            else
                screen.moveCursor(1, 0)
            end
            lineLength = lineLength + 1
        end
    end

   function screen.drawRect(width, height)
      local basex, basey = screen.getCursorPos()

      screen.drawLineV(height)
      screen.drawLineH(width)
      screen.moveCursor(-1, -height)
      screen.drawLineV(height)

      screen.setCursorPos(basex, basey)
      screen.drawLineH(width)
   end
end

return M
