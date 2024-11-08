gcna = {}

function table.len(tbl) 
    local x = 0 
    for _, _ in pairs(tbl) do x = x + 1 end
    return x
end

function getNetworkEvents()
    local timer = os.startTimer(0)
    local events = { os.pullEvent() }
    local message = nil
    
    for _, event in pairs(events) do
        if message ~= nil then 
            if type(event) == "table" then
                message.message = event
            elseif type(event) == "string" and peripheral.isPresent(event) then
                message.modem = event
            elseif message.port == nil and type(event) == "number" then
                message.port = event
            end
            if table.len(message) >= 3 then
                table.insert(gcna.messages, message)
                message = nil
            end
        end
        if event == "modem_message" then
            message = {}
        end
    end
end

function gcna.init(modems)
    gcna.modems = {}
    gcna.messages = {}
    gcna.modemNames = {}
    
    for name, ports in pairs(modems) do         
        local localName = ports[1]
    
        gcna.modems[localName] = {}
        
        gcna.modemNames[name] = localName
        gcna.modems[localName].peripheral = localName
        ports[1] = nil -- peripheral
        
        gcna.modems[localName] = ports
        
        peripheral.call(localName, "closeAll")
        for _, port in pairs(ports) do if type(port) == "number" then peripheral.call(localName, "open", port) end end
        
        gcna.modems[localName].name = name
    end
end

function gcna.transmit(modem, port, message) 
    if type(modem) == "string" then modem = peripheral.wrap(gcna.modemNames[modem]) end
    
    modem.transmit(port, 128, message)
end

function gcna.receive(timeout, modems)
    timeout = timeout or 0
    
    for modem, ports in pairs(modems or {}) do
        modems[gcna.modemNames[modem]] = ports
        modems[gcna.modemNames[modem]].id = modem
    end
    
    local start = os.time()
    while timeout <= 0 or os.time()-start < timeout do
        getNetworkEvents()
        if modems == nil and table.len(gcna.messages) > 0 then
            for k, message in pairs(gcna.messages) do
                gcna.messages[k] = nil
                return message.message, message.port, message.modem
            end
        end
        
        for k, message in pairs(gcna.messages) do
            if modems[message.modem] ~= nil then
                for _, port in pairs(modems[message.modem]) do
                    if port == message.port then 
                        gcna.messages[k] = nil
                        return message.message, message.port, modems[message.modem].id
                    end
                end
            end
        end
    end
    
    print("timeout!")
    
    return nil, nil, nil
end

return gcna
