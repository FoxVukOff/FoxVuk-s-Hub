--[[
    Концепт скрипта "Телепатия" для Roblox (группа c00lfox)
    Метод передачи данных: чат с кодированием через ";"
    Версия с GUI, удалением старого GUI и отображением позиции игрока.
    ПРЕДУПРЕЖДЕНИЕ: Использование подобных скриптов может привести к бану.
]]

local GROUP_PREFIX = "_CFXv1_"
local PlayersService = game:GetService("Players")
local LocalPlayer = PlayersService.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService") -- Для обновления позиции игрока

-- Очистка старых глобальных переменных, если они были
if _G.CFX_ShowNotification_Connection then _G.CFX_ShowNotification_Connection:Disconnect() end
_G.CFX_ShowNotification_Connection = nil
_G.CFX_ShowNotification = nil
if _G.CFX_GuiConnections then
    for _, conn in ipairs(_G.CFX_GuiConnections) do
        if conn and typeof(conn.Disconnect) == "function" then
            pcall(function() conn:Disconnect() end)
        end
    end
end
_G.CFX_GuiConnections = {} -- Инициализируем как глобальную таблицу для соединений

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
-- КОДИРОВАНИЕ / ДЕКОДИРОВАНИЕ ДАННЫХ
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
        print("CFX Ошибка: Закодированное сообщение слишком длинное! (" .. #messageToSend .. " символов).")
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

-- ==================================================
-- ПОДПИСКА НА СОБЫТИЯ ЧАТА (ДЛЯ ПРИЕМА СООБЩЕНИЙ)
-- ==================================================
function onPlayerChatted(chattedPlayer, message)
    if chattedPlayer and chattedPlayer.Name then processIncomingMessage(chattedPlayer.Name, message) end
end
function onPlayerAdded(player)
    if player then table.insert(_G.CFX_GuiConnections, player.Chatted:Connect(function(message) onPlayerChatted(player, message) end)) end
end
for _, player in ipairs(PlayersService:GetPlayers()) do if player ~= LocalPlayer then onPlayerAdded(player) end end
table.insert(_G.CFX_GuiConnections, PlayersService.PlayerAdded:Connect(onPlayerAdded))

pcall(function()
    local TextChatService = game:GetService("TextChatService")
    if TextChatService and TextChatService.MessageReceived then
        table.insert(_G.CFX_GuiConnections, TextChatService.MessageReceived:Connect(function(messageProperties)
            local senderPlayer
            if messageProperties and messageProperties.TextSource and messageProperties.TextSource:IsA("Player") then
                senderPlayer = messageProperties.TextSource
            elseif messageProperties and messageProperties.MessageSender and messageProperties.MessageSender.Player then
                 senderPlayer = messageProperties.MessageSender.Player
            end
            if senderPlayer and senderPlayer.Name ~= LocalPlayer.Name then
                processIncomingMessage(senderPlayer.Name, messageProperties.Text)
            end
        end))
        print("CFX: Подключен к TextChatService.MessageReceived")
    else print("CFX: TextChatService.MessageReceived не найден, используется только Player.Chatted для приема.") end
end)

-- ==================================================
-- ГРАФИЧЕСКИЙ ИНТЕРФЕЙС (GUI)
-- ==================================================
function CreateExecutorGUI()
    -- Удаляем старый GUI, если он существует
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") or CoreGui
    if playerGui:FindFirstChild("CFX_ExecutorGui") then
        playerGui.CFX_ExecutorGui:Destroy()
    end
    -- Очищаем старые соединения GUI (кроме слушателей чата, они в _G.CFX_GuiConnections)
    if _G.CFX_InternalGuiConnections then
        for _, conn in ipairs(_G.CFX_InternalGuiConnections) do
            if conn and typeof(conn.Disconnect) == "function" then pcall(function() conn:Disconnect() end) end
        end
    end
    _G.CFX_InternalGuiConnections = {}


    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CFX_ExecutorGui"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    mainFrame.BorderColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BorderSizePixel = 1
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Size = UDim2.new(0, 320, 0, 450) -- Увеличена высота для PlayerPos
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -225) -- Перецентровка

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
    
    local notifClearTimer
    _G.CFX_ShowNotification = function(message, color)
        if notificationLabel and notificationLabel.Parent then
            notificationLabel.Text = message
            notificationLabel.TextColor = color or Color3.fromRGB(180,180,180)
            if notifClearTimer then task.cancel(notifClearTimer); notifClearTimer = nil end
            notifClearTimer = task.delay(3, function()
                 if notificationLabel and notificationLabel.Parent and notificationLabel.Text == message then
                    notificationLabel.Text = "Status: Idle"
                    notificationLabel.TextColor = Color3.fromRGB(180,180,180)
                 end
            end)
        end
    end
    table.insert(_G.CFX_InternalGuiConnections, {Disconnect = function() if notifClearTimer then task.cancel(notifClearTimer) end end})


    local padding = 8
    local inputStartY = 55
    local currentY = inputStartY

    -- Поля для отображения позиции игрока
    local playerPosTitle = Instance.new("TextLabel")
    playerPosTitle.Parent = mainFrame
    playerPosTitle.Size = UDim2.new(1, -padding*2, 0, 18)
    playerPosTitle.Position = UDim2.new(0, padding, 0, currentY)
    playerPosTitle.Font = Enum.Font.SourceSansSemibold
    playerPosTitle.Text = "Your Position (X, Y, Z):"
    playerPosTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    playerPosTitle.TextSize = 13
    playerPosTitle.TextXAlignment = Enum.TextXAlignment.Left
    playerPosTitle.BackgroundTransparency = 1
    currentY = currentY + 18

    local playerPosXLabel = Instance.new("TextLabel")
    local playerPosYLabel = Instance.new("TextLabel")
    local playerPosZLabel = Instance.new("TextLabel")
    local posLabels = {playerPosXLabel, playerPosYLabel, playerPosZLabel}
    local posLabelPrefixes = {"X: ", "Y: ", "Z: "}

    for i, pLabel in ipairs(posLabels) do
        pLabel.Parent = mainFrame
        pLabel.Size = UDim2.new(0.333, -padding, 0, 18)
        pLabel.Position = UDim2.new(0 + (i-1)*0.333, padding, 0, currentY)
        pLabel.Font = Enum.Font.SourceSans
        pLabel.Text = posLabelPrefixes[i] .. "N/A"
        pLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
        pLabel.TextSize = 12
        pLabel.TextXAlignment = Enum.TextXAlignment.Left
        pLabel.BackgroundTransparency = 1
    end
    currentY = currentY + 18 + padding

    local inputFields = {}
    local defaultValues = {
        PosX = "0", PosY = "15", PosZ = "0",
        SizeX = "4", SizeY = "4", SizeZ = "4",
        ColorR = "255", ColorG = "0", ColorB = "0"
    }
    local fieldOrder = {"PosX", "PosY", "PosZ", "SizeX", "SizeY", "SizeZ", "ColorR", "ColorG", "ColorB"}

    for i, fieldName in ipairs(fieldOrder) do
        local label = Instance.new("TextLabel")
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
        if fieldName == "PosZ" or fieldName == "SizeZ" then currentY = currentY + padding / 2 end
    end
    currentY = currentY + padding

    local createButton = Instance.new("TextButton")
    createButton.Parent = mainFrame
    createButton.BackgroundColor3 = Color3.fromRGB(70, 140, 80)
    createButton.Size = UDim2.new(1, -padding*2, 0, 30)
    createButton.Position = UDim2.new(0, padding, 0, currentY)
    createButton.Font = Enum.Font.SourceSansSemibold
    createButton.Text = "Create Shared Part"
    createButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    currentY = currentY + 30 + padding
    table.insert(_G.CFX_InternalGuiConnections, createButton.MouseButton1Click:Connect(function()
        local args, allFieldsValid = {}, true
        for _, fieldName in ipairs(fieldOrder) do
            local numVal = tonumber(inputFields[fieldName].Text)
            if numVal == nil then _G.CFX_ShowNotification("Error: Invalid number in " .. fieldName, Color3.fromRGB(255,50,50)) inputFields[fieldName].BorderColor3 = Color3.fromRGB(150,50,50) allFieldsValid = false else table.insert(args, numVal) inputFields[fieldName].BorderColor3 = Color3.fromRGB(30,30,35) end
        end
        if allFieldsValid and #args == 9 then sendAction("CREATE_PART", unpack(args)) elseif not allFieldsValid then print("CFX GUI: CREATE_PART - Validation failed.") end
    end))

    local clearButton = Instance.new("TextButton")
    clearButton.Parent = mainFrame
    clearButton.BackgroundColor3 = Color3.fromRGB(140, 70, 80)
    clearButton.Size = UDim2.new(1, -padding*2, 0, 30)
    clearButton.Position = UDim2.new(0, padding, 0, currentY)
    clearButton.Font = Enum.Font.SourceSansSemibold
    clearButton.Text = "Clear My Shared Parts"
    clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    currentY = currentY + 30 + padding
    table.insert(_G.CFX_InternalGuiConnections, clearButton.MouseButton1Click:Connect(function()
        _G.CFX_ShowNotification("Sending DELETE_MY_PARTS...", Color3.fromRGB(255,150,50))
        sendAction("DELETE_MY_PARTS")
        handleCommand("DELETE_MY_PARTS", {}, LocalPlayer.Name)
    end))
    
    mainFrame.Size = UDim2.new(0, 320, 0, currentY)
    mainFrame.Position = UDim2.new(0.5, -mainFrame.AbsoluteSize.X/2, 0.5, -mainFrame.AbsoluteSize.Y/2)

    local closeButton = Instance.new("TextButton")
    closeButton.Parent = titleLabel
    closeButton.Size = UDim2.new(0, 24, 0, 24)
    closeButton.Position = UDim2.new(1, -28, 0.5, -12)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 70, 80)
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255,255,255)
    closeButton.ZIndex = titleLabel.ZIndex + 1
    table.insert(_G.CFX_InternalGuiConnections, closeButton.MouseButton1Click:Connect(function() screenGui.Enabled = not screenGui.Enabled end))

    -- Обновление позиции игрока
    local playerPosUpdateConnection
    playerPosUpdateConnection = RunService.RenderStepped:Connect(function()
        if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
            local pos = LocalPlayer.Character.PrimaryPart.Position
            playerPosXLabel.Text = posLabelPrefixes[1] .. string.format("%.1f", pos.X)
            playerPosYLabel.Text = posLabelPrefixes[2] .. string.format("%.1f", pos.Y)
            playerPosZLabel.Text = posLabelPrefixes[3] .. string.format("%.1f", pos.Z)
        else
            for i, pLabel in ipairs(posLabels) do pLabel.Text = posLabelPrefixes[i] .. "N/A" end
        end
    end)
    table.insert(_G.CFX_InternalGuiConnections, playerPosUpdateConnection) -- Добавляем для очистки

    print("CFX: Executor GUI created and enabled.")
    screenGui.Enabled = true
end

-- Вызов создания GUI
if LocalPlayer then
    if LocalPlayer:IsDescendantOf(PlayersService) and LocalPlayer.PlayerGui then
         CreateExecutorGUI()
    else
        local playerAddedConn_gui
        playerAddedConn_gui = PlayersService.ChildAdded:Connect(function(child)
            if child == LocalPlayer and LocalPlayer.PlayerGui then
                CreateExecutorGUI()
                if playerAddedConn_gui then playerAddedConn_gui:Disconnect() end
            end
        end)
        if not LocalPlayer.PlayerGui then
             local playerGuiAddedConn_gui
             playerGuiAddedConn_gui = LocalPlayer.ChildAdded:Connect(function(child)
                if child.Name == "PlayerGui" then
                    CreateExecutorGUI()
                    if playerGuiAddedConn_gui then playerGuiAddedConn_gui:Disconnect() end
                end
             end)
             table.insert(_G.CFX_GuiConnections, playerGuiAddedConn_gui) -- Эти соединения общие
        end
        table.insert(_G.CFX_GuiConnections, playerAddedConn_gui) -- Эти соединения общие
    end
else warn("CFX: LocalPlayer not found at GUI creation. GUI might not appear.") end

print("CFX: Скрипт 'Телепатия' (vGUI, PosDisplay) загружен.")
