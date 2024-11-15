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

   function screen.printBig(text, size)
      local x, y = screen.getCursorPos()
      bigfont.writeOn(screen, size or 1, text, x, y)
   end

   function screen.drawPixel(color)
      color = string.lower(string.format("%X", math.log(color, 2)))

      screen.blit("o", color, color)
   end

   function screen.drawLineV(len, color, width)
      if width ~= nil then
         for _=1,width do
            screen.drawLineV(len, color)
            screen.moveCursor(1, -len)
         end

         return
      end

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

   function screen.drawRect(width, height, color)
      color = color or colors.black

      local basex, basey = screen.getCursorPos()

      screen.drawLineV(height, color)
      screen.drawLineH(width, color)
      screen.moveCursor(-1, -height)
      screen.drawLineV(height, color)

      screen.setCursorPos(basex, basey)
      screen.drawLineH(width, color)
   end
end

return M
