local M = {}

function M.read(file)
    local fileHandler = fs.open(file, "r")
    local content = fileHandler.readAll()
    fileHandler.close()
    return content
end

function M.write(file, content)
    local fileHandler = fs.open(file, "w")
    fileHandler.write(content)
    fileHandler.close()
end

function M.append(file, content)
    local fileHandler = fs.open(file, "a")
    fileHandler.write(content)
    fileHandler.close()
end

local function escapePattern(text)
    return text:gsub("([%(%)%%%+%-%*%?%[%^%$%|])", "%%%1")
end

function M.remove(file, removable)
    print(string.gsub(M.read(file), escapePattern(removable), ""))
    M.write(file, string.gsub(M.read(file), escapePattern(removable), ""))
end

function len(tbl)
    local len = 0
    for _,_ in pairs(tbl) do len = len + 1 end
    return len
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
