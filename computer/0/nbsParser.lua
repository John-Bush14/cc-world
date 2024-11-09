local byteT = 1
local shortT = 2
local intT = 4
local strT = 999

local fields = {
   header = {
		{"classic", shortT},
      {"NBSversion", byteT},
		{"vanilla-instrument-count", byteT},
		{"length", shortT},
		{"Layer count", shortT},
   	{"name", strT},
   	{"author", strT},
   	{"OG-author", strT},
   	{"description", strT},
   	{"tempo", shortT},
   	{"auto-saving", byteT},
   	{"auto-saving-dur", byteT},
   	{"time-signature", byteT},
   	{"minutes-spent", intT},
   	{"leftclick", intT},
   	{"rightclick", intT},
   	{"noteblocks-added", intT},
   	{"noteblocks-removed", intT},
   	{"OG-filename", strT},
   	{"loop", byteT},
   	{"loop-count", byteT},
   	{"loop-start", shortT}
   },
   notes = {
	   {"jumps-tick", shortT},
      {"jumps-layer", shortT},
		{"instrument", byteT},
		{"key", byteT},
		{"velocity", byteT},
		{"panning", byteT},
		{"pitch", shortT}
   }
}

local function bytesToInt(str)
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
   for _, field in pairs(fields.header) do
      if field[2] ~= strT then
         data.header[field[1]] = bytesToInt(file:read(field[2]))
      else
         data.header[field[1]] = ""
         for _=1,bytesToInt(file:read(intT)) do data.header[field[1]] = (data.header[field[1]] or "") .. file:read(byteT) end
      end
   end

   -- notes
   local i = 1
   local note = {}
   local b = file:read(shortT)

   while b ~= nil do
      note[fields.notes[i][1]] = bytesToInt(b)

      if i == 1 then for _=1,bytesToInt(b) do table.insert(data.notes, "tick!") end end
      if i == 1 and bytesToInt(b) == 0 then return data end

      if i == 2 and bytesToInt(b) == 0 then
         i = 1
         table.insert(data.notes, "tick!")
      elseif i == 7 then
         i = 2
         table.insert(data.notes, note)
         note = {}
      else
         i = i + 1
      end

      b = file:read(fields.notes[i][2])
   end

   return data
end
