local byte = 1
local short = 2
local int = 4
local str = 999

local fields = { 
   header = { 
		{"classic", short},
      {"NBSversion", byte},
		{"vanilla-instrument-count", byte},
		{"length", short},
		{"Layer count", short},
   	{"name", str},
   	{"author", str},
   	{"OG-author", str},
   	{"description", str},
   	{"tempo", short},
   	{"auto-saving", byte},
   	{"auto-saving-dur", byte},
   	{"time-signature", byte},
   	{"minutes-spent", int},
   	{"leftclick", int},
   	{"rightclick", int},
   	{"noteblocks-added", int},
   	{"noteblocks-removed", int},
   	{"OG-filename", str},
   	{"loop", byte},
   	{"loop-count", byte},
   	{"loop-start", short}
   },
   notes = {
	   {"jumps-tick", short},
      {"jumps-layer", short},
		{"instrument", byte},
		{"key", byte},
		{"velocity", byte},
		{"panning", byte},
		{"pitch", short}
   }
}

function bytesToInt(str)
   local bytes = {}
   for char in str:gmatch(".") do table.insert(bytes, string.byte(char)) end
   
   local multiplier = 1
   local int = 0

   for _, byte in pairs(bytes) do
      int = int + byte * multiplier
      multiplier = multiplier * 256
   end
   
   local max = math.pow(2, #bytes*8-1)
   if int > max then
        int = int - max*2
    end

   return int
end

return function(file) 
   local data = {header = {}, notes = {}}
    
   -- header
   for k, field in pairs(fields.header) do
      if field[2] ~= str then
         data.header[field[1]] = bytesToInt(file:read(field[2]))
      else
         data.header[field[1]] = ""
         for _=1,bytesToInt(file:read(int)) do data.header[field[1]] = (data.header[field[1]] or "") .. file:read(byte) end
      end
   end
 
   -- notes
   local i = 1
   local note = {}
   local b = file:read(short)

   while b ~= nil do
      note[fields.notes[i][1]] = bytesToInt(b)

      if i == 1 then for _=1,string.byte(b) do table.insert(data.notes, {}) end end
      if i == 1 and bytesToInt(b) == 0 then return data end
      
      if i == 2 and b == bytesToInt(b) == 0 then 
         i = 1
      elseif i == 7 then 
         i = 2
         print(textutils.serialize(note))
         table.insert(data.notes, note)
         note = {}
      else
         i = i + 1
      end

      b = file:read(fields.notes[i][2])
   end

   return data
end
