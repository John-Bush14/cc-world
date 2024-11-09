local query, x, y, remove = ...

local item, modem, _, itemRemotePort = require("getItem")(query)

local iconFile = item .. ".nfp"
if not fs.exists(iconFile) then
    fs.copy("template.nfp", iconFile)
    shell.run("paint", iconFile)
end

local iconHandler = fs.open(iconFile, "r") or error("no icon file magically!")
local icon = iconHandler.readAll()
iconHandler.close()

if item ~= nil then
    modem.transmit(itemRemotePort, 128, {
        request="favorite", itemKey=item, position = {x=tonumber(x), y=tonumber(y)}, operation=(remove and "remove" or "add"), icon = icon
    })
else
    print("Item not found!")
end
