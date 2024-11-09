while true do
    local player = false
    player = commands.testfor("@p[y=83,r=4]") or player
    local pos1 = "~ ~2 ~1"
    local pos2 = "~ ~4 ~-1"
    if peripheral.wrap("bottom") == nil then
        pos1 = "~1 ~2 ~"
        pos2 = "~-1 ~4 ~"
    end
    if player then
        commands.fill(pos1 .. " " .. pos2 .. " air")
    else
    	commands.fill(pos1 .. " " .. pos2 .. " concrete 15")
    end
end
