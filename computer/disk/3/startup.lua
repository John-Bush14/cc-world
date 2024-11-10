local toolfiles = {
    "tools",
    "fileTools",
    "ports",
    "gcna",
    "graphicTools"
}


local utilityFiles = {}

for _, toolfile in pairs(toolfiles) do
    table.insert(utilityFiles, "../" .. string.gsub(string.gsub(fs.find("*/" .. toolfile .. ".lua")[1], "%.lua", ""), "%/", "."))
end


print("find passion!")
shell.run(fs.find("*/" .. (os.getComputerLabel() or "inventory") .. ".lua")[1], table.unpack(utilityFiles))
error("passion ended!")
