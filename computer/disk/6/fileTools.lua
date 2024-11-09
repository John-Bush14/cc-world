local M = {}

function M.read(file)
    local fileHandler = fs.open(file, "r") or error("called tools.read on nonexistent file")
    local content = fileHandler.readAll()
    fileHandler.close()
    return content
end

function M.write(file, content)
    local fileHandler = fs.open(file, "w") or error("called tools.write on nonexistent file")
    fileHandler.write(content)
    fileHandler.close()
end

function M.append(file, content)
    local fileHandler = fs.open(file, "a") or error("called tools.append on nonexistent file")
    fileHandler.write(content)
    fileHandler.close()
end

local function escapePattern(text)
    return text:gsub("([%(%)%%%+%-%*%?%[%^%$%|])", "%%%1")
end

function M.remove(file, removable)
    print(string.gsub(M.read(file) or error("called tools.remove on nonexistent file"), escapePattern(removable), ""))
    M.write(file, string.gsub(M.read(file) or error("called tools.remove on nonexistent file"), escapePattern(removable), ""))
end

local function len(tbl)
    local result = 0
    for _,_ in pairs(tbl) do result = result + 1 end
    return result
end

function M.decodeFavorites(code)
    if code == "" then return {} end
    local favorites = {{}}
    local keys = {"y", "x", "name", "icon"}
    for val in string.gmatch(code, "[^|]+") do
        favorites[#favorites][keys[len(favorites[#favorites])+1]] = val

        if len(favorites[#favorites]) == #keys then
            table.insert(favorites, {})
        end
    end
    favorites[#favorites] = nil
    return favorites
end

function M.encodeFavorite(favorite)
    return "|"..favorite.y.."|"..favorite.x.."|"..favorite.name.."|"..favorite.icon
end

return M
