--[[
    Концепт скрипта "Телепатия" для Roblox (группа c00lfox)
    Метод передачи данных: чат с кодированием через ";"
    Версия с GUI для управления.
    ПРЕДУПРЕЖДЕНИЕ: Использование подобных скриптов может привести к бану.
]]

local GROUP_PREFIX = "_CFXv1_" -- Префикс для идентификации сообщений группы
local PlayersService = game:GetService("Players")
local LocalPlayer = PlayersService.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui") -- Используем CoreGui для большей надежности

-- Попытка найти событие чата (может требовать адаптации)
local ChatEvent
local successChatEvent, errChatEvent = pcall(function()
    local legacyChatService = game:GetService("LegacyChatService")
    if legacyChatService and legacyChatService:FindFirstChild("SayMessageRequest") then
        ChatEvent = legacyChatService:FindFirstChild("SayMessageRequest")
        print("CFX: Используется LegacyChatService SayMessageRequest.")
        return
    end
    if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and
       ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest") then
        ChatEvent = ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
        print("CFX: Используется DefaultChatSystemChatEvents SayMessageRequest.")
        return
    else
        ChatEvent = {
            FireServer = function(...)
                warn("CFX Warning: ChatEvent (SayMessageRequest) не найден или не сконфигурирован. Отправка сообщений не будет работать.")
            end
        }
        warn("CFX Warning: ChatEvent (SayMessageRequest) не был найден. Отправка через чат не будет работать.")
    end
end)

if not successChatEvent then
    warn("CFX Warning: Ошибка при инициализации ChatEvent: " .. tostring(errChatEvent))
end

-- ==================================================
-- КОДИРОВАНИЕ / ДЕКОДИРОВАНИЕ ДАННЫХ (метод с точкой с запятой)
-- ==================================================
function encodeData_semicolon(dataString)
    local result = ""
    if type(dataString) ~= "string" then
        warn("encodeData_semicolon: dataString is not a string, got: "..tostring(dataString))
        return ""
    end
    for i = 1, #dataString do
        result = result .. string.sub(dataString, i, i)
        if i < #dataString then
            result = result .. ";"
        end
    end
    return result
end

function decodeData_semicolon(encodedString)
    if type(encodedString) ~= "string" then
        warn("decodeData_semicolon: encodedString is not a string, got: "..tostring(encodedString))
        return ""
    end
    local result = string.gsub(encodedString, ";", "")
    return result
end

-- ==================================================
-- ОТПРАВКА ДЕЙСТВИЙ
-- ==================================================
function sendAction(command, ...)
    local args = {...}
    local dataPayload = command
    if #args > 0 then
        local stringArgs = {}
        for i, v in ipairs(args) do
            table.insert(stringArgs, tostring(v))
        end
        dataPayload = dataPayload .. ":" .. table.concat(stringArgs, ",")
    end

    local encodedPayload = encodeData_semicolon(dataPayload)
    local messageToSend = GROUP_PREFIX .. encodedPayload

    if #messageToSend > 199 then
        print("CFX Ошибка: Закодированное сообщение слишком длинное! (" .. #messageToSend .. " символов). Сообщение: " .. messageToSend)
        if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: Message too long!", Color3.fromRGB(255,50,50)) end
        return
    end

    if ChatEvent and ChatEvent.FireServer and typeof(ChatEvent.FireServer) == "function" then
         pcall(function() ChatEvent:FireServer(messageToSend, "All") end)
        print("CFX: Отправлено действие: " .. dataPayload .. " (как: " .. messageToSend .. ")")
        if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Action Sent: " .. command, Color3.fromRGB(50,255,50)) end
    else
        print("CFX Ошибка: ChatEvent.FireServer недоступен. Не могу отправить сообщение.")
        if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: ChatEvent not working!", Color3.fromRGB(255,50,50)) end
    end
end

-- ==================================================
-- ПРИЕМ И ОБРАБОТКА ДЕЙСТВИЙ
-- ==================================================
function processIncomingMessage(senderPlayerName, message)
    if not senderPlayerName or senderPlayerName == LocalPlayer.Name then return end
    if type(message) ~= "string" or #message < #GROUP_PREFIX then return end

    if string.sub(message, 1, #GROUP_PREFIX) == GROUP_PREFIX then
        local encodedPayload = string.sub(message, #GROUP_PREFIX + 1)
        -- print("CFX: Получено сырое сообщение: " .. encodedPayload .. " от " .. senderPlayerName)

        local decodedPayload
        local success, resultOrError = pcall(function()
            return decodeData_semicolon(encodedPayload)
        end)

        if not success or resultOrError == nil then
            print("CFX: Ошибка декодирования сообщения от " .. senderPlayerName .. ": " .. tostring(resultOrError))
            return
        end
        decodedPayload = resultOrError
        print("CFX: Декодировано от " .. senderPlayerName .. ": " .. decodedPayload)
        if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Received: " .. decodedPayload:sub(1,20) .. "...", Color3.fromRGB(50,150,255)) end


        local parts = {}
        for part in string.gmatch(decodedPayload, "[^:]+") do
            table.insert(parts, part)
        end

        if #parts == 0 then return end

        local command = parts[1]
        local argsStr = parts[2]
        local args = {}
        if argsStr then
            for arg in string.gmatch(argsStr, "[^,]+") do
                table.insert(args, arg)
            end
        end

        handleCommand(command, args, senderPlayerName)
    end
end

function handleCommand(command, args, senderName)
    print("CFX: Обработка команды '" .. command .. "' от " .. senderName)
    if command == "CREATE_PART" then
        if #args == 9 then
            local numArgs = {}
            local conversionOk = true
            for i, v in ipairs(args) do
                local n = tonumber(v)
                if n == nil then
                    print("CFX: CREATE_PART - нечисловой аргумент: " .. tostring(v) .. " от " .. senderName)
                    conversionOk = false
                    break
                end
                table.insert(numArgs, n)
            end

            if not conversionOk then return end

            local pos = Vector3.new(numArgs[1], numArgs[2], numArgs[3])
            local size = Vector3.new(math.max(0.05, numArgs[4]), math.max(0.05, numArgs[5]), math.max(0.05, numArgs[6])) -- Min size
            local color = Color3.fromRGB(math.clamp(numArgs[7],0,255), math.clamp(numArgs[8],0,255), math.clamp(numArgs[9],0,255))

            local newPart = Instance.new("Part", Workspace)
            newPart.Position = pos
            newPart.Size = size
            newPart.Color = color
            newPart.Anchored = true
            newPart.CanCollide = false
            newPart.Name = "CFX_SharedPart_" .. senderName
            Debris:AddItem(newPart, 120) -- Удалить через 120 секунд
            print("CFX: Создана деталь по команде от " .. senderName .. " в " .. tostring(pos))
        else
            print("CFX: CREATE_PART от " .. senderName .. " - неверное количество аргументов (" .. #args .. "), ожидалось 9.")
        end
    elseif command == "DELETE_MY_PARTS" then
        print("CFX: Команда на удаление деталей от " .. senderName)
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("BasePart") and child.Name == "CFX_SharedPart_" .. senderName then
                child:Destroy()
                print("CFX: Удалена деталь " .. child.Name .. " (запрос от " .. senderName .. ")")
            end
        end
    end
end

-- ==================================================
-- ПОДПИСКА НА СОБЫТИЯ ЧАТА (ДЛЯ ПРИЕМА СООБЩЕНИЙ)
-- ==================================================
function onPlayerChatted(chattedPlayer, message)
    if chattedPlayer and chattedPlayer.Name then
        processIncomingMessage(chattedPlayer.Name, message)
    end
end

function onPlayerAdded(player)
    if player then
        player.Chatted:Connect(function(message)
            onPlayerChatted(player, message)
        end)
    end
end

for _, player in ipairs(PlayersService:GetPlayers()) do
    if player ~= LocalPlayer then
        onPlayerAdded(player)
    end
end
PlayersService.PlayerAdded:Connect(onPlayerAdded)

pcall(function()
    local TextChatService = game:GetService("TextChatService")
    if TextChatService and TextChatService.MessageReceived then
        TextChatService.MessageReceived:Connect(function(messageProperties)
            if messageProperties and messageProperties.TextSource and messageProperties.TextSource:IsA("Player") then
                local senderPlayer = messageProperties.TextSource
                if senderPlayer and senderPlayer.Name ~= LocalPlayer.Name then
                    processIncomingMessage(senderPlayer.Name, messageProperties.Text)
                end
            elseif messageProperties and messageProperties.MessageSender and messageProperties.MessageSender.Player then -- Newer API?
                 local senderPlayer = messageProperties.MessageSender.Player
                 if senderPlayer and senderPlayer.Name ~= LocalPlayer.Name then
                    processIncomingMessage(senderPlayer.Name, messageProperties.Text)
                 end
            end
        end)
        print("CFX: Подключен к TextChatService.MessageReceived")
    else
        print("CFX: TextChatService.MessageReceived не найден, используется только Player.Chatted для приема.")
    end
end)


-- ==================================================
-- ГРАФИЧЕСКИЙ ИНТЕРФЕЙС (GUI)
-- ==================================================
local guiConnections = {} -- Для хранения соединений GUI, чтобы можно было их очистить

function ClearGuiConnections()
    for i, conn in ipairs(guiConnections) do
        if conn and typeof(conn.Disconnect) == "function" then
            conn:Disconnect()
        end
    end
    guiConnections = {}
end

function CreateExecutorGUI()
    ClearGuiConnections() -- Очищаем старые соединения перед созданием нового GUI

    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        playerGui = CoreGui -- Фоллбэк на CoreGui, если PlayerGui нет (например, очень ранний запуск)
        if not playerGui then
            warn("CFX: PlayerGui and CoreGui not found. Cannot create GUI.")
            return
        end
    end
    
    if playerGui:FindFirstChild("CFX_ExecutorGui") then
        playerGui.CFX_ExecutorGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CFX_ExecutorGui"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Чтобы быть поверх других стандартных GUI

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    mainFrame.BorderColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BorderSizePixel = 1
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Size = UDim2.new(0, 320, 0, 390) -- Немного шире и выше
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -195) -- Центрирование

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Parent = mainFrame
    titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    titleLabel.Size = UDim2.new(1, 0, 0, 28)
    titleLabel.Font = Enum.Font.SourceSansSemibold
    titleLabel.Text = "CFX Part Telepathy"
    titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    titleLabel.TextSize = 16

    local notificationLabel = Instance.new("TextLabel")
    notificationLabel.Name = "NotificationLabel"
    notificationLabel.Parent = mainFrame
    notificationLabel.Size = UDim2.new(1, -10, 0, 20)
    notificationLabel.Position = UDim2.new(0, 5, 0, 30)
    notificationLabel.Font = Enum.Font.SourceSans
    notificationLabel.Text = "Status: Idle"
    notificationLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    notificationLabel.TextSize = 12
    notificationLabel.TextXAlignment = Enum.TextXAlignment.Left
    notificationLabel.BackgroundTransparency = 1
    
    _G.CFX_ShowNotification = function(message, color)
        if notificationLabel and notificationLabel.Parent then
            notificationLabel.Text = message
            notificationLabel.TextColor = color or Color3.fromRGB(180,180,180)
            Debris:AddItem(notificationLabel, 0) -- Clear previous timer if any
            notificationLabel.Visible = true
            local clearNotif = task.delay(3, function()
                 if notificationLabel and notificationLabel.Parent and notificationLabel.Text == message then -- Clear only if it's the same message
                    notificationLabel.Text = "Status: Idle"
                    notificationLabel.TextColor = Color3.fromRGB(180,180,180)
                 end
            end)
            table.insert(guiConnections, {Disconnect = function() task.cancel(clearNotif) end})
        end
    end


    local padding = 8
    local inputStartY = 55 -- Начальная Y позиция для полей ввода, после notificationLabel
    local currentY = inputStartY

    local inputFields = {}
    local defaultValues = {
        PosX = "0", PosY = "15", PosZ = "0",
        SizeX = "4", SizeY = "4", SizeZ = "4",
        ColorR = "255", ColorG = "0", ColorB = "0"
    }
    local fieldOrder = {"PosX", "PosY", "PosZ", "SizeX", "SizeY", "SizeZ", "ColorR", "ColorG", "ColorB"}

    for i, fieldName in ipairs(fieldOrder) do
        local label = Instance.new("TextLabel")
        label.Name = fieldName .. "Label"
        label.Parent = mainFrame
        label.Size = UDim2.new(0.25, 0, 0, 22)
        label.Position = UDim2.new(0, padding, 0, currentY)
        label.Font = Enum.Font.SourceSans
        label.Text = fieldName .. ":"
        label.TextColor3 = Color3.fromRGB(210, 210, 210)
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1

        local textBox = Instance.new("TextBox")
        textBox.Name = fieldName .. "Input"
        textBox.Parent = mainFrame
        textBox.Size = UDim2.new(0.75, -padding*2, 0, 22)
        textBox.Position = UDim2.new(0.25, padding, 0, currentY)
        textBox.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        textBox.BorderColor3 = Color3.fromRGB(30, 30, 35)
        textBox.Font = Enum.Font.SourceSans
        textBox.PlaceholderText = defaultValues[fieldName]
        textBox.Text = defaultValues[fieldName]
        textBox.TextColor3 = Color3.fromRGB(230, 230, 230)
        textBox.TextSize = 13
        textBox.ClearTextOnFocus = false
        inputFields[fieldName] = textBox
        
        currentY = currentY + 22 + padding / 2
        if fieldName == "PosZ" or fieldName == "SizeZ" then currentY = currentY + padding / 2 end -- Доп. отступ после групп
    end
    
    currentY = currentY + padding

    local createButton = Instance.new("TextButton")
    createButton.Name = "CreatePartButton"
    createButton.Parent = mainFrame
    createButton.BackgroundColor3 = Color3.fromRGB(70, 140, 80)
    createButton.BorderColor3 = Color3.fromRGB(40, 90, 50)
    createButton.Size = UDim2.new(1, -padding*2, 0, 30)
    createButton.Position = UDim2.new(0, padding, 0, currentY)
    createButton.Font = Enum.Font.SourceSansSemibold
    createButton.Text = "Create Shared Part"
    createButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    createButton.TextSize = 15
    currentY = currentY + 30 + padding

    table.insert(guiConnections, createButton.MouseButton1Click:Connect(function()
        local args = {}
        local allFieldsValid = true
        for _, fieldName in ipairs(fieldOrder) do
            local numVal = tonumber(inputFields[fieldName].Text)
            if numVal == nil then
                _G.CFX_ShowNotification("Error: Invalid number in " .. fieldName, Color3.fromRGB(255,50,50))
                inputFields[fieldName].BorderColor3 = Color3.fromRGB(150,50,50)
                allFieldsValid = false
            else
                table.insert(args, numVal)
                inputFields[fieldName].BorderColor3 = Color3.fromRGB(30,30,35)
            end
        end

        if allFieldsValid and #args == 9 then
            sendAction("CREATE_PART", unpack(args))
        elseif not allFieldsValid then
             print("CFX GUI: CREATE_PART - Validation failed.")
        end
    end))

    local clearButton = Instance.new("TextButton")
    clearButton.Name = "ClearMyPartsButton"
    clearButton.Parent = mainFrame
    clearButton.BackgroundColor3 = Color3.fromRGB(140, 70, 80)
    clearButton.BorderColor3 = Color3.fromRGB(90, 40, 50)
    clearButton.Size = UDim2.new(1, -padding*2, 0, 30)
    clearButton.Position = UDim2.new(0, padding, 0, currentY)
    clearButton.Font = Enum.Font.SourceSansSemibold
    clearButton.Text = "Clear My Shared Parts"
    clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearButton.TextSize = 15
    currentY = currentY + 30 + padding

    table.insert(guiConnections, clearButton.MouseButton1Click:Connect(function()
        _G.CFX_ShowNotification("Sending DELETE_MY_PARTS...", Color3.fromRGB(255,150,50))
        sendAction("DELETE_MY_PARTS")
        handleCommand("DELETE_MY_PARTS", {}, LocalPlayer.Name) -- Локально тоже
    end))
    
    mainFrame.Size = UDim2.new(0, 320, 0, currentY) -- Обновляем высоту фрейма
    mainFrame.Position = UDim2.new(0.5, -mainFrame.AbsoluteSize.X/2, 0.5, -mainFrame.AbsoluteSize.Y/2) -- Перецентрируем

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Parent = titleLabel -- Внутри заголовка для лучшего позиционирования
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -28, 0.5, -12)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 70, 80)
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255,255,255)
    closeButton.TextSize = 14
    closeButton.ZIndex = titleLabel.ZIndex + 1
    table.insert(guiConnections, closeButton.MouseButton1Click:Connect(function()
        screenGui.Enabled = not screenGui.Enabled
    end))

    print("CFX: Executor GUI created and enabled.")
    screenGui.Enabled = true
end

-- Вызов создания GUI
if LocalPlayer then
    if LocalPlayer:IsDescendantOf(PlayersService) and LocalPlayer.PlayerGui then
         CreateExecutorGUI()
    else
        -- Если PlayerGui еще не загружен или игрок не полностью добавлен
        local playerAddedConn
        playerAddedConn = PlayersService.ChildAdded:Connect(function(child)
            if child == LocalPlayer and LocalPlayer.PlayerGui then
                CreateExecutorGUI()
                if playerAddedConn then playerAddedConn:Disconnect() end -- Отключаем, т.к. дело сделано
            end
        end)
        -- На случай, если игрок уже добавлен, но PlayerGui не было
        if not LocalPlayer.PlayerGui then
             local playerGuiAddedConn
             playerGuiAddedConn = LocalPlayer.ChildAdded:Connect(function(child)
                if child.Name == "PlayerGui" then
                    CreateExecutorGUI()
                    if playerGuiAddedConn then playerGuiAddedConn:Disconnect() end
                end
             end)
             table.insert(guiConnections, playerGuiAddedConn)
        end
        table.insert(guiConnections, playerAddedConn)
    end
else
    warn("CFX: LocalPlayer not found at GUI creation. GUI might not appear.")
end

print("CFX: Скрипт 'Телепатия' (метод ';', с GUI) загружен.")
print("CFX: Используйте GUI для управления.")

-- Тест кодирования/декодирования
local originalTest = "CREATE_PART:10.5,20.2,30.3:5,5,5:255,128,0"
local encodedTestSemicolon = encodeData_semicolon(originalTest)
local decodedTestSemicolon = decodeData_semicolon(encodedTestSemicolon)
if decodedTestSemicolon ~= originalTest then
    print("CFX Semicolon Тест: ОШИБКА в кодировании/декодировании!")
else
    print("CFX Semicolon Тест: Тест кодирования/декодирования успешен.")
end
