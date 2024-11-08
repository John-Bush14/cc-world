local test = peripheral.find("monitor")

test.clear()
test.setCursorPos(1, 1)
test.write("test")
test.setTextScale(3)
print(test.getTextScale())
