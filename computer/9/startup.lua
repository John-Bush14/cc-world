local monitor = peripheral.find("monitor")

monitor.clear()
print(monitor.getCursorPos())
monitor.setCursorPos(1, 2)
print(monitor.getSize())
monitor.write("test\ntest")
print(type(monitor.getCursorPos()))
for k, i in pairs(monitor) do
  --  print(k, i)    
end
