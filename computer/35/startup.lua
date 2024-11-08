local text = "Warehouse"
local monitor = peripheral.find("monitor")

monitor.setTextScale(2)
monitor.clear()
screenSizeX, screenSizeY = monitor.getSize()
monitor.setCursorPos(screenSizeX/2-(#text/2), screenSizeY/2)
monitor.write(text)
