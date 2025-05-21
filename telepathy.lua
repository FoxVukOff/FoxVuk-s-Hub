--[[
    Концепт скрипта "Телепатия" для Roblox (группа c00lfox)
    Метод передачи данных: чат с кодированием через ";"
    ПРЕДУПРЕЖДЕНИЕ: Использование подобных скриптов может привести к бану.
]]

local GROUP_PREFIX = "_CFXv1_" -- Префикс для идентификации сообщений группы
local PlayersService = game:GetService("Players")
local LocalPlayer = PlayersService.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace") -- Добавлено для создания деталей
local Debris = game:GetService("Debris") -- Для автоматического удаления деталей

-- Попытка найти событие чата. МОЖЕТ ТРЕБОВАТЬ ИЗМЕНЕНИЙ ИЛИ НЕ РАБОТАТЬ
-- В зависимости от инжектора и обновлений Roblox, путь к SayMessageRequest может отличаться.
-- Это одна из самых ненадежных частей, если вы не знаете точный путь для вашего эксплойта.
local ChatEvent
local successChatEvent, errChatEvent = pcall(function()
    -- Попытка для старой системы чата (LegacyChatService)
    local legacyChatService = game:GetService("LegacyChatService")
    if legacyChatService and legacyChatService:FindFirstChild("SayMessageRequest") then
        ChatEvent = legacyChatService:FindFirstChild("SayMessageRequest")
        return
    end
    -- Попытка для новой системы чата (TextChatService) - но это событие клиента для отправки,
    -- а не прямое серверное событие, которое легко вызвать.
    -- Для TextChatService обычно используется TextChatService.MessageReceived для чтения,
    -- а отправка делается через TextChannel:SendAsync().
    -- Эта часть требует более глубокой интеграции с API инжектора.
    -- Пока оставим как есть, но с высоким шансом, что это не сработает "из коробки".
    if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and
       ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest") then
        ChatEvent = ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
    else
        -- Если ничего не найдено, создаем "пустышку" чтобы скрипт не ломался сразу,
        -- но отправка не будет работать.
        ChatEvent = {
            FireServer = function(...)
                print("CFX Error: ChatEvent не найден или не сконфигурирован. Отправка сообщений невозможна.")
            end
        }
        error("ChatEvent (SayMessageRequest) не найден. Скрипт не сможет отправлять сообщения.")
    end
end)

if not successChatEvent then
    print("CFX Critical Error: Не удалось инициализировать ChatEvent. " .. tostring(errChatEvent))
    -- Можно добавить return здесь, если без ChatEvent работа невозможна
end


-- ==================================================
-- КОДИРОВАНИЕ / ДЕКОДИРОВАНИЕ ДАННЫХ (метод с точкой с запятой)
-- ==================================================
function encodeData_semicolon(dataString)
    local result = ""
    if type(dataString) ~= "string" then
        warn("encodeData_semicolon: dataString is not a string, got: "..tostring(dataString))
        return "" -- или вызвать ошибку
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
        return "" -- или вызвать ошибку
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
        -- Убедимся, что все аргументы - строки для корректного table.concat
        local stringArgs = {}
        for i, v in ipairs(args) do
            table.insert(stringArgs, tostring(v))
        end
        dataPayload = dataPayload .. ":" .. table.concat(stringArgs, ",")
    end

    local encodedPayload = encodeData_semicolon(dataPayload)
    local messageToSend = GROUP_PREFIX .. encodedPayload

    if #messageToSend > 199 then -- Ограничение чата Roblox, лучше чуть меньше максимума
        print("CFX Ошибка: Закодированное сообщение слишком длинное! (" .. #messageToSend .. " символов). Сообщение: " .. messageToSend)
        return
    end

    if ChatEvent and ChatEvent.FireServer then
        ChatEvent:FireServer(messageToSend, "All") -- Отправляем сообщение всем
        print("CFX: Отправлено действие: " .. dataPayload .. " (как: " .. messageToSend .. ")")
    else
        print("CFX Ошибка: ChatEvent.FireServer недоступен. Не могу отправить сообщение.")
    end
end

-- ==================================================
-- ПРИЕМ И ОБРАБОТКА ДЕЙСТВИЙ
-- ==================================================
function processIncomingMessage(senderPlayerName, message)
    if not senderPlayerName or senderPlayerName == LocalPlayer.Name then return end -- Не обрабатываем свои же сообщения или без имени

    if type(message) ~= "string" or #message < #GROUP_PREFIX then return end -- Проверка типа и длины

    if string.sub(message, 1, #GROUP_PREFIX) == GROUP_PREFIX then
        local encodedPayload = string.sub(message, #GROUP_PREFIX + 1)
        print("CFX: Получено сырое сообщение: " .. encodedPayload .. " от " .. senderPlayerName)

        local decodedPayload
        local success, resultOrError = pcall(function()
            return decodeData_semicolon(encodedPayload)
        end)

        if not success or resultOrError == nil then
            print("CFX: Ошибка декодирования сообщения от " .. senderPlayerName .. ": " .. tostring(resultOrError))
            return
        end
        decodedPayload = resultOrError
        print("CFX: Декодировано: " .. decodedPayload)

        -- Разбираем команду и аргументы
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
    print("CFX: Обработка команды '" .. command .. "' от " .. senderName .. " с аргументами: " .. table.concat(args, ", "))
    if command == "CREATE_PART" then
        -- Ожидаемые аргументы: x, y, z, sizeX, sizeY, sizeZ, r, g, b
        if #args == 9 then
            local numArgs = {}
            for i, v in ipairs(args) do
                local n = tonumber(v)
                if n == nil then
                    print("CFX: CREATE_PART - нечисловой аргумент: " .. tostring(v))
                    return
                end
                table.insert(numArgs, n)
            end

            local pos = Vector3.new(numArgs[1], numArgs[2], numArgs[3])
            local size = Vector3.new(numArgs[4], numArgs[5], numArgs[6])
            local color = Color3.fromRGB(math.clamp(numArgs[7],0,255), math.clamp(numArgs[8],0,255), math.clamp(numArgs[9],0,255))

            local newPart = Instance.new("Part", Workspace)
            newPart.Position = pos
            newPart.Size = size
            newPart.Color = color
            newPart.Anchored = true
            newPart.CanCollide = false
            newPart.Name = "CFX_SharedPart_" .. senderName
            Debris:AddItem(newPart, 60) -- Удалить через 60 секунд
            print("CFX: Создана деталь по команде от " .. senderName .. " в " .. tostring(pos))
        else
            print("CFX: CREATE_PART - неверное количество аргументов (" .. #args .. "), ожидалось 9.")
        end
    elseif command == "DELETE_MY_PARTS" then
        print("CFX: Команда на удаление своих деталей от " .. senderName)
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("BasePart") and child.Name == "CFX_SharedPart_" .. senderName then
                child:Destroy()
                print("CFX: Удалена деталь " .. child.Name)
            end
        end
    end
end

-- ==================================================
-- ПОДПИСКА НА СОБЫТИЯ ЧАТА
-- ==================================================
-- Способ 1: Player.Chatted (менее надежный для всех сообщений, но прост)
function onPlayerChatted(chattedPlayer, message)
    -- Убедимся, что chattedPlayer существует и имеет Name
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

-- Подключаемся к существующим игрокам
for _, player in ipairs(PlayersService:GetPlayers()) do
    if player ~= LocalPlayer then
        onPlayerAdded(player)
    end
end
-- Подключаемся к новым игрокам
PlayersService.PlayerAdded:Connect(onPlayerAdded)

-- Способ 2: TextChatService (более современный, если доступен и используется игрой)
-- Этот код нужно адаптировать/проверить, так как API может меняться или быть недоступным.
pcall(function()
    local TextChatService = game:GetService("TextChatService")
    if TextChatService and TextChatService:FindFirstChild("MessageReceived") then
        TextChatService.MessageReceived:Connect(function(messageProperties)
            --[[
                Структура messageProperties может быть:
                messageProperties.TextSource (Instance, может быть nil, например, для системных сообщений)
                messageProperties.Text (string)
                messageProperties.SenderUserId (string, UserId отправителя)
            ]]
            if messageProperties and messageProperties.TextSource and messageProperties.TextSource:IsA("Player") then
                local senderPlayer = messageProperties.TextSource
                if senderPlayer and senderPlayer.Name ~= LocalPlayer.Name then
                    processIncomingMessage(senderPlayer.Name, messageProperties.Text)
                end
            elseif messageProperties and messageProperties.SenderUserId then -- Если нет TextSource, но есть SenderUserId
                 local senderPlayer = PlayersService:GetPlayerByUserId(tonumber(messageProperties.SenderUserId))
                 if senderPlayer and senderPlayer.Name ~= LocalPlayer.Name then
                    processIncomingMessage(senderPlayer.Name, messageProperties.Text)
                 end
            end
        end)
        print("CFX: Подключен к TextChatService.MessageReceived")
    else
        print("CFX: TextChatService.MessageReceived не найден, используется только Player.Chatted.")
    end
end)


-- ==================================================
-- ПРИМЕР ИСПОЛЬЗОВАНИЯ (например, через команды в чате)
-- ==================================================
LocalPlayer.Chatted:Connect(function(msg)
    if not msg or type(msg) ~= "string" then return end

    if string.sub(msg, 1, 7) == "/cfxadd" then -- Пример команды /cfxadd x,y,z,sx,sy,sz,r,g,b
        local data = string.sub(msg, 9) -- Убираем "/cfxadd "
        local args = {}
        if data then
            for v in string.gmatch(data, "[^,]+") do
                 local num = tonumber(v)
                 if num == nil then
                    print("CFX: Ошибка в /cfxadd - нечисловой аргумент: "..tostring(v))
                    return
                 end
                 table.insert(args, num)
            end
            if #args == 9 then
                sendAction("CREATE_PART", unpack(args))
            else
                print("CFX: Неверный формат для /cfxadd. Нужно 9 числовых аргументов, разделенных запятыми. Пример: /cfxadd 10,20,30,4,4,4,255,0,0")
            end
        else
            print("CFX: /cfxadd требует аргументы.")
        end
    elseif string.sub(msg, 1, 10) == "/cfxclear" then
        sendAction("DELETE_MY_PARTS") -- Отправит команду всем (включая себя), чтобы другие удалили "мои" парты
        -- И локально тоже удалим, если вдруг сообщение не дошло до себя через сервер
        handleCommand("DELETE_MY_PARTS", {}, LocalPlayer.Name)
        print("CFX: Запрошено удаление моих деталей.")
    end
end)

print("CFX: Скрипт 'Телепатия' (метод ';') загружен.")
print("CFX: Используйте /cfxadd x,y,z,sizeX,sizeY,sizeZ,r,g,b для создания деталей.")
print("CFX: Используйте /cfxclear для удаления созданных вами деталей у всех.")

-- Тест кодирования/декодирования
local originalTest = "CREATE_PART:10.5,20.2,30.3:5,5,5:255,128,0"
print("CFX Semicolon Тест: Оригинал: " .. originalTest)
local encodedTestSemicolon = encodeData_semicolon(originalTest)
print("CFX Semicolon Тест: Закодировано: " .. encodedTestSemicolon .. " (Длина: " .. #encodedTestSemicolon .. ")")
local decodedTestSemicolon = decodeData_semicolon(encodedTestSemicolon)
print("CFX Semicolon Тест: Декодировано: " .. decodedTestSemicolon)
if decodedTestSemicolon ~= originalTest then
    print("CFX Semicolon Тест: ОШИБКА в кодировании/декодировании!")
else
    print("CFX Semicolon Тест: Тест кодирования/декодирования успешен.")
end

local testShort = "HI"
local encodedShort = encodeData_semicolon(testShort)
local decodedShort = decodeData_semicolon(encodedShort)
print("CFX Short Test: " .. testShort .. " -> " .. encodedShort .. " -> " .. decodedShort)
