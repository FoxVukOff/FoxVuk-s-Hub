--[[
    Концепт скрипта "Телепатия" для Roblox (группа c00lfox)
    Версия с исправлением ошибки MessageSender при приеме через TextChatService
    и использованием только SayMessageRequest для отправки данных.
    ПРЕДУПРЕЖДЕНИЕ: Использование подобных скриптов может привести к бану.
]]

local GROUP_PREFIX = "_CFXv1_"
local PlayersService = game:GetService("Players")
local LocalPlayer = PlayersService.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Очистка старых глобальных переменных
if _G.CFX_ShowNotification_Connection then _G.CFX_ShowNotification_Connection:Disconnect() end; _G.CFX_ShowNotification_Connection = nil
_G.CFX_ShowNotification = nil
if _G.CFX_GuiConnections then for _, conn in ipairs(_G.CFX_GuiConnections) do if conn and typeof(conn.Disconnect) == "function" then pcall(function() conn:Disconnect() end) end end end
_G.CFX_GuiConnections = {}

local ChatEvent
local successChatEventInit, errChatEventInit = pcall(function()
    -- 1. Попытка LegacyChatService
    local legacyChatService = game:GetService("LegacyChatService")
    if legacyChatService and legacyChatService:FindFirstChild("SayMessageRequest") then
        ChatEvent = legacyChatService:FindFirstChild("SayMessageRequest")
        print("CFX: Используется LegacyChatService SayMessageRequest для отправки.")
        return -- Успех
    end

    -- 2. Попытка DefaultChatSystemChatEvents
    if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and
       ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest") then
        ChatEvent = ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
        print("CFX: Используется DefaultChatSystemChatEvents SayMessageRequest для отправки.")
        return -- Успех
    end
    
    -- 3. Если старые методы не найдены, отправка через чат будет отключена.
    -- TextChatService:SendAsync показал проблемы с искажением данных (отправлял "{}"), поэтому пока не используется для этого.
    ChatEvent = {
        FireServer = function(messageContent, targetChannelName) -- targetChannelName ("All") будет проигнорирован
            warn("CFX Warning: No reliable chat sending method (SayMessageRequest) found. Telepathy sending disabled. Message was: " .. messageContent:sub(1,50) .. "...")
            if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: Chat sending disabled!", Color3.fromRGB(255,100,50)) end
        end
    }
    print("CFX: SayMessageRequest (Legacy or Default) не найден. Отправка данных телепатии через чат будет отключена.")
end)

if not successChatEventInit then
    warn("CFX Critical Error при инициализации ChatEvent: " .. tostring(errChatEventInit))
    -- Создаем пустышку, чтобы скрипт не ломался, если pcall сам по себе вызвал ошибку
    ChatEvent = { FireServer = function(...) warn("CFX Error: Инициализация ChatEvent провалилась полностью.") end }
end


function encodeData_semicolon(dataString)
    local result = ""
    if type(dataString) ~= "string" then warn("encodeData_semicolon: dataString is not a string, got: "..tostring(dataString)) return "" end
    for i = 1, #dataString do
        result = result .. string.sub(dataString, i, i)
        if i < #dataString then result = result .. ";" end
    end
    return result
end

function decodeData_semicolon(encodedString)
    if type(encodedString) ~= "string" then warn("decodeData_semicolon: encodedString is not a string, got: "..tostring(encodedString)) return "" end
    return string.gsub(encodedString, ";", "")
end

function sendAction(command, ...)
    local args = {...}
    local dataPayload = command
    if #args > 0 then
        local stringArgs = {}
        for i, v in ipairs(args) do table.insert(stringArgs, tostring(v)) end
        dataPayload = dataPayload .. ":" .. table.concat(stringArgs, ",")
    end

    local encodedPayload = encodeData_semicolon(dataPayload)
    local messageToSend = GROUP_PREFIX .. encodedPayload

    if #messageToSend > 199 then
        print("CFX Ошибка: Закодированное сообщение слишком длинное! (" .. #messageToSend .. " символов).")
        if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: Message too long!", Color3.fromRGB(255,50,50)) end
        return
    end

    if ChatEvent and ChatEvent.FireServer and typeof(ChatEvent.FireServer) == "function" then
        local success, err = pcall(function() ChatEvent:FireServer(messageToSend, "All") end) -- "All" is for legacy compatibility
        
        -- Проверяем, не является ли ChatEvent.FireServer нашей "пустышкой"
        -- (которая сама выводит предупреждение и уведомление)
        local isDummyFireServer = false
        if type(ChatEvent.FireServer) == "function" then
            -- Сравнить с функцией-пустышкой сложно напрямую, но если сработал pcall,
            -- и это не настоящий RemoteEvent, то наша пустышка уже вывела свои сообщения.
            -- Если это настоящий RemoteEvent, то пустышка не вызывалась.
            -- Поэтому, если pcall(ChatEvent:FireServer) был успешен и это НЕ пустышка, то выводим свое сообщение об успехе.
            -- Если это пустышка, она уже вывела свое предупреждение.
            -- Допущение: если ChatEvent - это RemoteEvent, то у него нет поля _isDummy (которое мы не ставили).
            -- Более простой способ: если сообщение об ошибке от пустышки НЕ появилось, значит, это был реальный RemoteEvent.
        end

        if success then
            -- Сообщение об успешной отправке или попытке (если это не пустышка)
            -- Пустышка сама выводит свое предупреждение, поэтому здесь дополнительное сообщение не всегда нужно, если это была пустышка.
            -- Если это настоящий RemoteEvent, то выводим "Action Sent".
             local isRealRemoteEvent = (ChatEvent ~= nil and ChatEvent.ClassName == "RemoteEvent") -- Проверка, если это настоящий RemoteEvent
             if isRealRemoteEvent then
                print("CFX: Отправлено действие: " .. dataPayload .. " (как: " .. messageToSend .. ")")
                if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Action Sent: " .. command, Color3.fromRGB(50,255,50)) end
             end
             -- Если это была наша таблица-пустышка, она уже вывела свое уведомление "Error: Chat sending disabled!"
        else
            warn("CFX Error во время ChatEvent:FireServer (вероятно, настоящий RemoteEvent): " .. tostring(err))
            if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: FireServer call failed!", Color3.fromRGB(255,50,50)) end
        end
    else
        print("CFX Ошибка: ChatEvent.FireServer недоступен или неверно сконфигурирован. Не могу отправить сообщение.")
        if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: Chat sending not configured!", Color3.fromRGB(255,50,50)) end
    end
end

function processIncomingMessage(senderPlayerName, message)
    -- DEBUG: Раскомментируйте для отладки содержимого входящих сообщений
    -- print("CFX DEBUG: processIncomingMessage from " .. senderPlayerName .. " with raw message: [" .. message .. "] (length: " .. #message .. ")")

    if not senderPlayerName or senderPlayerName == LocalPlayer.Name then return end
    if type(message) ~= "string" or #message < #GROUP_PREFIX then
        return
    end

    if string.sub(message, 1, #GROUP_PREFIX) == GROUP_PREFIX then
        local encodedPayload = string.sub(message, #GROUP_PREFIX + 1)
        local decodedPayload
        local success, resultOrError = pcall(function() return decodeData_semicolon(encodedPayload) end)

        if not success or resultOrError == nil then
            print("CFX: Ошибка декодирования сообщения от " .. senderPlayerName .. ": " .. tostring(resultOrError))
            return
        end
        decodedPayload = resultOrError
        print("CFX: Декодировано от " .. senderPlayerName .. ": " .. decodedPayload)
        if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Received: " .. decodedPayload:sub(1,20) .. "...", Color3.fromRGB(50,150,255)) end

        local parts = {}
        for part in string.gmatch(decodedPayload, "[^:]+") do table.insert(parts, part) end
        if #parts == 0 then return end
        local command, argsStr = parts[1], parts[2]
        local args = {}
        if argsStr then for arg in string.gmatch(argsStr, "[^,]+") do table.insert(args, arg) end end
        handleCommand(command, args, senderPlayerName)
    end
end

function handleCommand(command, args, senderName)
    print("CFX: Обработка команды '" .. command .. "' от " .. senderName)
    if command == "CREATE_PART" then
        if #args == 9 then
            local numArgs, conversionOk = {}, true
            for i, v in ipairs(args) do
                local n = tonumber(v)
                if n == nil then print("CFX: CREATE_PART - нечисловой аргумент: " .. tostring(v) .. " от " .. senderName) conversionOk = false break end
                table.insert(numArgs, n)
            end
            if not conversionOk then return end
            local pos = Vector3.new(numArgs[1], numArgs[2], numArgs[3])
            local size = Vector3.new(math.max(0.05, numArgs[4]), math.max(0.05, numArgs[5]), math.max(0.05, numArgs[6]))
            local color = Color3.fromRGB(math.clamp(numArgs[7],0,255), math.clamp(numArgs[8],0,255), math.clamp(numArgs[9],0,255))
            local newPart = Instance.new("Part", Workspace)
            newPart.Position, newPart.Size, newPart.Color, newPart.Anchored, newPart.CanCollide = pos, size, color, true, false
            newPart.Name = "CFX_SharedPart_" .. senderName
            Debris:AddItem(newPart, 120)
            print("CFX: Создана деталь по команде от " .. senderName .. " в " .. tostring(pos))
        else print("CFX: CREATE_PART от " .. senderName .. " - неверное количество аргументов (" .. #args .. "), ожидалось 9.") end
    elseif command == "DELETE_MY_PARTS" then
        print("CFX: Команда на удаление деталей от " .. senderName)
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("BasePart") and child.Name == "CFX_SharedPart_" .. senderName then child:Destroy() print("CFX: Удалена деталь " .. child.Name) end
        end
    end
end

-- Listener for Legacy Chat (Player.Chatted)
function onPlayerChatted(chattedPlayer, message) if chattedPlayer and chattedPlayer.Name then processIncomingMessage(chattedPlayer.Name, message) end end
function onPlayerAdded(player) if player then table.insert(_G.CFX_GuiConnections, player.Chatted:Connect(function(m) onPlayerChatted(player,m) end)) end end
for _,p in ipairs(PlayersService:GetPlayers()) do if p~=LocalPlayer then onPlayerAdded(p) end end
table.insert(_G.CFX_GuiConnections, PlayersService.PlayerAdded:Connect(onPlayerAdded))

-- Listener for TextChatService (More robust sender identification)
pcall(function()
    local TextChatService = game:GetService("TextChatService")
    if TextChatService and TextChatService.MessageReceived then
        table.insert(_G.CFX_GuiConnections, TextChatService.MessageReceived:Connect(function(messageObject) -- messageObject is a TextChatMessage
            if not (messageObject and messageObject:IsA("TextChatMessage")) then return end -- Проверка типа

            local senderPlayer = nil
            local messageText = messageObject.Text or "" -- Гарантируем, что messageText это строка

            -- Сначала пытаемся получить Player из TextSource (это должен быть объект Player)
            if messageObject.TextSource and messageObject.TextSource:IsA("Player") then
                senderPlayer = messageObject.TextSource
            -- Если TextSource не Player (или nil), пытаемся через MessageSender.UserId
            elseif messageObject.MessageSender and type(messageObject.MessageSender.UserId) == "number" and messageObject.MessageSender.UserId ~= 0 then
                senderPlayer = PlayersService:GetPlayerByUserId(messageObject.MessageSender.UserId)
            end
            
            -- Если отправитель определен, это не локальный игрок, то обрабатываем
            if senderPlayer and senderPlayer.Name ~= LocalPlayer.Name then
                processIncomingMessage(senderPlayer.Name, messageText)
            end
        end))
        print("CFX: Listener TextChatService.MessageReceived active (MessageSender error fixed).")
    else
        print("CFX: TextChatService.MessageReceived не найден. Только Player.Chatted будет использоваться для приема, если доступен.")
    end
end)

-- ==================================================
-- ГРАФИЧЕСКИЙ ИНТЕРФЕЙС (GUI) - без изменений в этой секции
-- ==================================================
function CreateExecutorGUI()
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") or CoreGui
    if playerGui:FindFirstChild("CFX_ExecutorGui") then playerGui.CFX_ExecutorGui:Destroy() end
    if _G.CFX_InternalGuiConnections then for _,c in ipairs(_G.CFX_InternalGuiConnections) do if c and typeof(c.Disconnect)=="function" then pcall(function() c:Disconnect() end) end end end
    _G.CFX_InternalGuiConnections = {}

    local screenGui = Instance.new("ScreenGui"); screenGui.Name = "CFX_ExecutorGui"; screenGui.Parent = playerGui; screenGui.ResetOnSpawn = false; screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local mainFrame = Instance.new("Frame"); mainFrame.Name = "MainFrame"; mainFrame.Parent = screenGui; mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45); mainFrame.BorderColor3 = Color3.fromRGB(20, 20, 25); mainFrame.BorderSizePixel = 1; mainFrame.Active = true; mainFrame.Draggable = true; mainFrame.Size = UDim2.new(0, 320, 0, 450); mainFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
    local titleLabel = Instance.new("TextLabel"); titleLabel.Name = "Title"; titleLabel.Parent = mainFrame; titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60); titleLabel.Size = UDim2.new(1, 0, 0, 28); titleLabel.Font = Enum.Font.SourceSansSemibold; titleLabel.Text = "CFX Part Telepathy"; titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230); titleLabel.TextSize = 16
    local notificationLabel = Instance.new("TextLabel"); notificationLabel.Name = "NotificationLabel"; notificationLabel.Parent = mainFrame; notificationLabel.Size = UDim2.new(1, -10, 0, 20); notificationLabel.Position = UDim2.new(0, 5, 0, 30); notificationLabel.Font = Enum.Font.SourceSans; notificationLabel.Text = "Status: Idle"; notificationLabel.TextColor3 = Color3.fromRGB(180, 180, 180); notificationLabel.TextSize = 12; notificationLabel.TextXAlignment = Enum.TextXAlignment.Left; notificationLabel.BackgroundTransparency = 1
    local notifClearTimer; _G.CFX_ShowNotification = function(message, color)
        if notificationLabel and notificationLabel.Parent then notificationLabel.Text = message; notificationLabel.TextColor3 = color or Color3.fromRGB(180,180,180)
            if notifClearTimer then task.cancel(notifClearTimer); notifClearTimer = nil end
            notifClearTimer = task.delay(3, function() if notificationLabel and notificationLabel.Parent and notificationLabel.Text == message then notificationLabel.Text = "Status: Idle"; notificationLabel.TextColor3 = Color3.fromRGB(180,180,180) end end)
        end
    end; table.insert(_G.CFX_InternalGuiConnections, {Disconnect = function() if notifClearTimer then task.cancel(notifClearTimer) end end})
    local padding = 8; local inputStartY = 55; local currentY = inputStartY
    local playerPosTitle = Instance.new("TextLabel"); playerPosTitle.Parent = mainFrame; playerPosTitle.Size = UDim2.new(1, -padding*2, 0, 18); playerPosTitle.Position = UDim2.new(0, padding, 0, currentY); playerPosTitle.Font = Enum.Font.SourceSansSemibold; playerPosTitle.Text = "Your Position (X, Y, Z):"; playerPosTitle.TextColor3 = Color3.fromRGB(200, 200, 200); playerPosTitle.TextSize = 13; playerPosTitle.TextXAlignment = Enum.TextXAlignment.Left; playerPosTitle.BackgroundTransparency = 1; currentY = currentY + 18
    local playerPosXLabel, playerPosYLabel, playerPosZLabel = Instance.new("TextLabel"), Instance.new("TextLabel"), Instance.new("TextLabel")
    local posLabels_gui = {{playerPosXLabel, "X: "}, {playerPosYLabel, "Y: "}, {playerPosZLabel, "Z: "}} -- Изменено имя переменной, чтобы избежать конфликта
    for i, pLabelData in ipairs(posLabels_gui) do local pLabel, prefix = pLabelData[1], pLabelData[2]
        pLabel.Parent = mainFrame; pLabel.Size = UDim2.new(0.333, -padding, 0, 18); pLabel.Position = UDim2.new(0 + (i-1)*0.333, padding, 0, currentY); pLabel.Font = Enum.Font.SourceSans; pLabel.Text = prefix .. "N/A"; pLabel.TextColor3 = Color3.fromRGB(190, 190, 190); pLabel.TextSize = 12; pLabel.TextXAlignment = Enum.TextXAlignment.Left; pLabel.BackgroundTransparency = 1
    end; currentY = currentY + 18 + padding
    local inputFields, defaultValues = {}, {PosX = "0", PosY = "15", PosZ = "0", SizeX = "4", SizeY = "4", SizeZ = "4", ColorR = "255", ColorG = "0", ColorB = "0"}
    local fieldOrder = {"PosX", "PosY", "PosZ", "SizeX", "SizeY", "SizeZ", "ColorR", "ColorG", "ColorB"}
    for i, fieldName in ipairs(fieldOrder) do
        local label = Instance.new("TextLabel"); label.Parent = mainFrame; label.Size = UDim2.new(0.25, 0, 0, 22); label.Position = UDim2.new(0, padding, 0, currentY); label.Font = Enum.Font.SourceSans; label.Text = fieldName .. ":"; label.TextColor3 = Color3.fromRGB(210, 210, 210); label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.BackgroundTransparency = 1
        local textBox = Instance.new("TextBox"); textBox.Parent = mainFrame; textBox.Size = UDim2.new(0.75, -padding*2, 0, 22); textBox.Position = UDim2.new(0.25, padding, 0, currentY); textBox.BackgroundColor3 = Color3.fromRGB(55, 55, 65); textBox.BorderColor3 = Color3.fromRGB(30, 30, 35); textBox.Font = Enum.Font.SourceSans; textBox.PlaceholderText = defaultValues[fieldName]; textBox.Text = defaultValues[fieldName]; textBox.TextColor3 = Color3.fromRGB(230, 230, 230); textBox.TextSize = 13; textBox.ClearTextOnFocus = false; inputFields[fieldName] = textBox
        currentY = currentY + 22 + padding / 2; if fieldName == "PosZ" or fieldName == "SizeZ" then currentY = currentY + padding / 2 end
    end; currentY = currentY + padding
    local createButton = Instance.new("TextButton"); createButton.Parent = mainFrame; createButton.BackgroundColor3 = Color3.fromRGB(70, 140, 80); createButton.Size = UDim2.new(1, -padding*2, 0, 30); createButton.Position = UDim2.new(0, padding, 0, currentY); createButton.Font = Enum.Font.SourceSansSemibold; createButton.Text = "Create Shared Part"; createButton.TextColor3 = Color3.fromRGB(255, 255, 255); currentY = currentY + 30 + padding
    table.insert(_G.CFX_InternalGuiConnections, createButton.MouseButton1Click:Connect(function() local args, allFieldsValid = {}, true
        for _, fieldName in ipairs(fieldOrder) do local numVal = tonumber(inputFields[fieldName].Text)
            if numVal == nil then _G.CFX_ShowNotification("Error: Invalid " .. fieldName, Color3.fromRGB(255,50,50)); inputFields[fieldName].BorderColor3 = Color3.fromRGB(150,50,50); allFieldsValid = false else table.insert(args, numVal); inputFields[fieldName].BorderColor3 = Color3.fromRGB(30,30,35) end
        end; if allFieldsValid and #args == 9 then sendAction("CREATE_PART", unpack(args)) elseif not allFieldsValid then print("CFX GUI: Validation failed.") end
    end))
    local clearButton = Instance.new("TextButton"); clearButton.Parent = mainFrame; clearButton.BackgroundColor3 = Color3.fromRGB(140, 70, 80); clearButton.Size = UDim2.new(1, -padding*2, 0, 30); clearButton.Position = UDim2.new(0, padding, 0, currentY); clearButton.Font = Enum.Font.SourceSansSemibold; clearButton.Text = "Clear My Shared Parts"; clearButton.TextColor3 = Color3.fromRGB(255, 255, 255); currentY = currentY + 30 + padding
    table.insert(_G.CFX_InternalGuiConnections, clearButton.MouseButton1Click:Connect(function() _G.CFX_ShowNotification("Sending DELETE_MY_PARTS...", Color3.fromRGB(255,150,50)); sendAction("DELETE_MY_PARTS"); handleCommand("DELETE_MY_PARTS", {}, LocalPlayer.Name) end))
    mainFrame.Size = UDim2.new(0, 320, 0, currentY); mainFrame.Position = UDim2.new(0.5, -mainFrame.AbsoluteSize.X/2, 0.5, -mainFrame.AbsoluteSize.Y/2)
    local closeButton = Instance.new("TextButton"); closeButton.Parent = titleLabel; closeButton.Size = UDim2.new(0, 24, 0, 24); closeButton.Position = UDim2.new(1, -28, 0.5, -12); closeButton.BackgroundColor3 = Color3.fromRGB(180, 70, 80); closeButton.Font = Enum.Font.SourceSansBold; closeButton.Text = "X"; closeButton.TextColor3 = Color3.fromRGB(255,255,255); closeButton.ZIndex = titleLabel.ZIndex + 1
    table.insert(_G.CFX_InternalGuiConnections, closeButton.MouseButton1Click:Connect(function() screenGui.Enabled = not screenGui.Enabled end))
    local playerPosUpdateConnection; playerPosUpdateConnection = RunService.RenderStepped:Connect(function()
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then local pos = LocalPlayer.Character.PrimaryPart.Position
            playerPosXLabel.Text = posLabels_gui[1][2] .. string.format("%.1f", pos.X); playerPosYLabel.Text = posLabels_gui[2][2] .. string.format("%.1f", pos.Y); playerPosZLabel.Text = posLabels_gui[3][2] .. string.format("%.1f", pos.Z)
        else for i, pLabelData in ipairs(posLabels_gui) do pLabelData[1].Text = pLabelData[2] .. "N/A" end end
    end); table.insert(_G.CFX_InternalGuiConnections, playerPosUpdateConnection)
    print("CFX: Executor GUI created."); screenGui.Enabled = true
end

if LocalPlayer then
    if LocalPlayer:IsDescendantOf(PlayersService) and LocalPlayer.PlayerGui then CreateExecutorGUI()
    else
        local playerAddedConn_gui; playerAddedConn_gui = PlayersService.ChildAdded:Connect(function(child) if child == LocalPlayer and LocalPlayer.PlayerGui then CreateExecutorGUI() if playerAddedConn_gui then playerAddedConn_gui:Disconnect() end end end)
        if not LocalPlayer.PlayerGui then local playerGuiAddedConn_gui; playerGuiAddedConn_gui = LocalPlayer.ChildAdded:Connect(function(child) if child.Name == "PlayerGui" then CreateExecutorGUI() if playerGuiAddedConn_gui then playerGuiAddedConn_gui:Disconnect() end end end)
             table.insert(_G.CFX_GuiConnections, playerGuiAddedConn_gui) end
        table.insert(_G.CFX_GuiConnections, playerAddedConn_gui)
    end
else warn("CFX: LocalPlayer not found at GUI creation.") end
print("CFX: Скрипт 'Телепатия' (vGUI, PosDisplay, TCS Receive Fix, SayMessageRequest Send Only) загружен.")
