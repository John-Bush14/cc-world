for k, i in pairs(commands) do
    if string.sub(k, 0, 1) ~= "@@@" then
        print(k, i)
    end
end
