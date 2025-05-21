--[[
    Концепт скрипта "Телепатия" для Roblox (группа c00lfox)
    Версия с попыткой отправки через TextChatService.
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
        return -- Успех, выходим из pcall
    end

    -- 2. Попытка DefaultChatSystemChatEvents
    if ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") and
       ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest") then
        ChatEvent = ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
        print("CFX: Используется DefaultChatSystemChatEvents SayMessageRequest для отправки.")
        return -- Успех, выходим из pcall
    end

    -- 3. Попытка TextChatService для отправки
    local tcs = game:GetService("TextChatService")
    local textChannelInstance
    if tcs and tcs:FindFirstChild("TextChannels") then
        local channelsFolder = tcs.TextChannels
        if channelsFolder:FindFirstChild("RBXGeneral") then textChannelInstance = channelsFolder.RBXGeneral
        elseif channelsFolder:FindFirstChild("All") then textChannelInstance = channelsFolder.All
        elseif channelsFolder:FindFirstChild("RBXSystem") then textChannelInstance = channelsFolder.RBXSystem
        else -- Последняя попытка: найти первый попавшийся TextChannel
            for _, ch in ipairs(channelsFolder:GetChildren()) do
                if ch:IsA("TextChannel") then textChannelInstance = ch; print("CFX: Используется первый доступный TextChannel: " .. ch.Name); break end
            end
        end
    end

    if textChannelInstance then
        print("CFX: Настроен для отправки через TextChatService:SendAsync на канале: " .. textChannelInstance.Name)
        ChatEvent = {
            FireServer = function(messageContent, targetChannelName) -- targetChannelName ("All") будет проигнорирован
                local success, err = pcall(function()
                    textChannelInstance:SendAsync(messageContent)
                end)
                if not success then
                    warn("CFX Warning: TextChatService:SendAsync не удалось: " .. tostring(err))
                    if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: SendAsync failed!", Color3.fromRGB(255,50,50)) end
                else
                    -- Уведомление об успешной отправке уже есть в sendAction
                    print("CFX: Сообщение отправлено через TextChatService:SendAsync.")
                end
            end
        }
        return -- Успех, выходим из pcall
    end
    
    -- 4. Если все методы не сработали
    ChatEvent = {
        FireServer = function(...)
            -- Предупреждение в GUI будет показано из функции sendAction
            warn("CFX Warning: ChatEvent (SayMessageRequest или TextChatService) не найден или не сконфигурирован.")
        end
    }
    warn("CFX Critical Warning: Не найден валидный метод отправки сообщений (SayMessageRequest или TextChatService). Отправка через чат не будет работать.")
end)

if not successChatEventInit then
    warn("CFX Critical Error при инициализации ChatEvent: " .. tostring(errChatEventInit))
    -- Создаем пустышку, чтобы скрипт не ломался, если pcall сам по себе вызвал ошибку
    ChatEvent = { FireServer = function(...) warn("CFX Error: Инициализация ChatEvent провалилась полностью.") end }
end


function encodeData_semicolon(dataString)
    local result = ""
    if type(dataString) ~= "string" then warn("encodeData: not a string: "..tostring(dataString)) return "" end
    for i = 1, #dataString do result = result .. string.sub(dataString, i, i); if i < #dataString then result = result .. ";" end end
    return result
end

function decodeData_semicolon(encodedString)
    if type(encodedString) ~= "string" then warn("decodeData: not a string: "..tostring(encodedString)) return "" end
    return string.gsub(encodedString, ";", "")
end

function sendAction(command, ...)
    local args = {...}; local dataPayload = command
    if #args > 0 then local strArgs = {}; for _, v in ipairs(args) do table.insert(strArgs, tostring(v)) end; dataPayload = dataPayload .. ":" .. table.concat(strArgs, ",") end
    local encodedPayload = encodeData_semicolon(dataPayload); local messageToSend = GROUP_PREFIX .. encodedPayload
    if #messageToSend > 199 then print("CFX Error: Message too long!"); if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: Msg too long!", Color3.fromRGB(255,50,50)) end return end

    if ChatEvent and ChatEvent.FireServer and typeof(ChatEvent.FireServer) == "function" then
        local success, err = pcall(function() ChatEvent:FireServer(messageToSend, "All") end)
        if success then
            print("CFX: Отправлено действие: " .. dataPayload .. " (как: " .. messageToSend .. ")")
            if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Action Sent: " .. command, Color3.fromRGB(50,255,50)) end
        else
            warn("CFX Error во время ChatEvent:FireServer: " .. tostring(err))
            if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: FireServer call failed!", Color3.fromRGB(255,50,50)) end
        end
    else
        print("CFX Ошибка: ChatEvent.FireServer недоступен или неверно сконфигурирован. Не могу отправить сообщение.")
        if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Error: Chat sending not configured!", Color3.fromRGB(255,50,50)) end
    end
end

function processIncomingMessage(senderPlayerName, message)
    if not senderPlayerName or senderPlayerName == LocalPlayer.Name then return end
    if type(message) ~= "string" or #message < #GROUP_PREFIX then return end
    if string.sub(message, 1, #GROUP_PREFIX) == GROUP_PREFIX then
        local encodedPayload = string.sub(message, #GROUP_PREFIX + 1); local decodedPayload
        local success, res = pcall(function() return decodeData_semicolon(encodedPayload) end)
        if not success or res == nil then print("CFX: Decode error from "..senderPlayerName..": "..tostring(res)) return end
        decodedPayload = res; print("CFX: Decoded from "..senderPlayerName..": "..decodedPayload)
        if _G.CFX_ShowNotification then _G.CFX_ShowNotification("Received: "..decodedPayload:sub(1,20).."...", Color3.fromRGB(50,150,255)) end
        local parts = {}; for part in string.gmatch(decodedPayload, "[^:]+") do table.insert(parts, part) end
        if #parts == 0 then return end; local command, argsStr = parts[1], parts[2]; local args = {}
        if argsStr then for arg in string.gmatch(argsStr, "[^,]+") do table.insert(args, arg) end end
        handleCommand(command, args, senderPlayerName)
    end
end

function handleCommand(command, args, senderName)
    print("CFX: Handling '"..command.."' from "..senderName)
    if command == "CREATE_PART" and #args == 9 then
        local numArgs, ok = {}, true; for _, v in ipairs(args) do local n=tonumber(v); if n==nil then print("CFX: Non-numeric arg: "..tostring(v)); ok=false; break end table.insert(numArgs,n) end
        if not ok then return end
        local p,s,c=Vector3.new(numArgs[1],numArgs[2],numArgs[3]),Vector3.new(math.max(.05,numArgs[4]),math.max(.05,numArgs[5]),math.max(.05,numArgs[6])),Color3.fromRGB(math.clamp(numArgs[7],0,255),math.clamp(numArgs[8],0,255),math.clamp(numArgs[9],0,255))
        local pt=Instance.new("Part",Workspace); pt.Position,pt.Size,pt.Color,pt.Anchored,pt.CanCollide=p,s,c,true,false; pt.Name="CFX_SharedPart_"..senderName; Debris:AddItem(pt,120)
        print("CFX: Created part by "..senderName)
    elseif command == "DELETE_MY_PARTS" then
        print("CFX: Delete parts from "..senderName); for _,c in ipairs(Workspace:GetChildren()) do if c:IsA("BasePart") and c.Name=="CFX_SharedPart_"..senderName then c:Destroy() print("CFX: Deleted "..c.Name) end end
    end
end

function onPlayerChatted(chattedPlayer, message) if chattedPlayer and chattedPlayer.Name then processIncomingMessage(chattedPlayer.Name, message) end end
function onPlayerAdded(player) if player then table.insert(_G.CFX_GuiConnections, player.Chatted:Connect(function(m) onPlayerChatted(player,m) end)) end end
for _,p in ipairs(PlayersService:GetPlayers()) do if p~=LocalPlayer then onPlayerAdded(p) end end
table.insert(_G.CFX_GuiConnections, PlayersService.PlayerAdded:Connect(onPlayerAdded))

pcall(function() local tcs=game:GetService("TextChatService"); if tcs and tcs.MessageReceived then table.insert(_G.CFX_GuiConnections,tcs.MessageReceived:Connect(function(mp) local sp; if mp and mp.TextSource and mp.TextSource:IsA("Player") then sp=mp.TextSource elseif mp and mp.MessageSender and mp.MessageSender.Player then sp=mp.MessageSender.Player end if sp and sp.Name~=LocalPlayer.Name then processIncomingMessage(sp.Name,mp.Text) end end)) print("CFX: Listener TextChatService.MessageReceived active.") else print("CFX: TextChatService.MessageReceived not found.") end end)

function CreateExecutorGUI()
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") or CoreGui
    if playerGui:FindFirstChild("CFX_ExecutorGui") then playerGui.CFX_ExecutorGui:Destroy() end
    if _G.CFX_InternalGuiConnections then for _,c in ipairs(_G.CFX_InternalGuiConnections) do if c and typeof(c.Disconnect)=="function" then pcall(function() c:Disconnect() end) end end end
    _G.CFX_InternalGuiConnections = {}
    local screenGui=Instance.new("ScreenGui");screenGui.Name="CFX_ExecutorGui";screenGui.Parent=playerGui;screenGui.ResetOnSpawn=false;screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    local mainFrame=Instance.new("Frame");mainFrame.Name="MainFrame";mainFrame.Parent=screenGui;mainFrame.BackgroundColor3=Color3.fromRGB(35,35,45);mainFrame.BorderColor3=Color3.fromRGB(20,20,25);mainFrame.BorderSizePixel=1;mainFrame.Active=true;mainFrame.Draggable=true;mainFrame.Size=UDim2.new(0,320,0,450);mainFrame.Position=UDim2.new(.5,-160,.5,-225)
    local titleLabel=Instance.new("TextLabel");titleLabel.Name="Title";titleLabel.Parent=mainFrame;titleLabel.BackgroundColor3=Color3.fromRGB(50,50,60);titleLabel.Size=UDim2.new(1,0,0,28);titleLabel.Font=Enum.Font.SourceSansSemibold;titleLabel.Text="CFX Part Telepathy";titleLabel.TextColor3=Color3.fromRGB(230,230,230);titleLabel.TextSize=16
    local notificationLabel=Instance.new("TextLabel");notificationLabel.Name="NotificationLabel";notificationLabel.Parent=mainFrame;notificationLabel.Size=UDim2.new(1,-10,0,20);notificationLabel.Position=UDim2.new(0,5,0,30);notificationLabel.Font=Enum.Font.SourceSans;notificationLabel.Text="Status: Idle";notificationLabel.TextColor3=Color3.fromRGB(180,180,180);notificationLabel.TextSize=12;notificationLabel.TextXAlignment=Enum.TextXAlignment.Left;notificationLabel.BackgroundTransparency=1
    local notifTimer;_G.CFX_ShowNotification=function(msg,c) if notificationLabel and notificationLabel.Parent then notificationLabel.Text=msg;notificationLabel.TextColor3=c or Color3.fromRGB(180,180,180) if notifTimer then task.cancel(notifTimer) end;notifTimer=task.delay(3,function()if notificationLabel and notificationLabel.Parent and notificationLabel.Text==msg then notificationLabel.Text="Status: Idle";notificationLabel.TextColor3=Color3.fromRGB(180,180,180)end end)end end;table.insert(_G.CFX_InternalGuiConnections,{Disconnect=function()if notifTimer then task.cancel(notifTimer)end end})
    local pad,startY,cY=8,55,55;local posTitle=Instance.new("TextLabel");posTitle.Parent=mainFrame;posTitle.Size=UDim2.new(1,-pad*2,0,18);posTitle.Position=UDim2.new(0,pad,0,cY);posTitle.Font=Enum.Font.SourceSansSemibold;posTitle.Text="Your Position (X,Y,Z):";posTitle.TextColor3=Color3.fromRGB(200,200,200);posTitle.TextSize=13;posTitle.TextXAlignment=Enum.TextXAlignment.Left;posTitle.BackgroundTransparency=1;cY=cY+18
    local xL,yL,zL=Instance.new("TextLabel"),Instance.new("TextLabel"),Instance.new("TextLabel");local pLs,pLprefs={{xL,"X: "},{yL,"Y: "},{zL,"Z: "}}
    for i,d in ipairs(pLs) do local l,pref=d[1],d[2];l.Parent=mainFrame;l.Size=UDim2.new(.333,-pad,0,18);l.Position=UDim2.new(0+(i-1)*.333,pad,0,cY);l.Font=Enum.Font.SourceSans;l.Text=pref.."N/A";l.TextColor3=Color3.fromRGB(190,190,190);l.TextSize=12;l.TextXAlignment=Enum.TextXAlignment.Left;l.BackgroundTransparency=1 end;cY=cY+18+pad
    local inF,defV={}, {PosX="0",PosY="15",PosZ="0",SizeX="4",SizeY="4",SizeZ="4",ColorR="255",ColorG="0",ColorB="0"}
    local fOrder={"PosX","PosY","PosZ","SizeX","SizeY","SizeZ","ColorR","ColorG","ColorB"}
    for _,fN in ipairs(fOrder) do local lb=Instance.new("TextLabel");lb.Parent=mainFrame;lb.Size=UDim2.new(.25,0,0,22);lb.Position=UDim2.new(0,pad,0,cY);lb.Font=Enum.Font.SourceSans;lb.Text=fN..":";lb.TextColor3=Color3.fromRGB(210,210,210);lb.TextSize=13;lb.TextXAlignment=Enum.TextXAlignment.Left;lb.BackgroundTransparency=1;local tb=Instance.new("TextBox");tb.Parent=mainFrame;tb.Size=UDim2.new(.75,-pad*2,0,22);tb.Position=UDim2.new(.25,pad,0,cY);tb.BackgroundColor3=Color3.fromRGB(55,55,65);tb.BorderColor3=Color3.fromRGB(30,30,35);tb.Font=Enum.Font.SourceSans;tb.PlaceholderText=defV[fN];tb.Text=defV[fN];tb.TextColor3=Color3.fromRGB(230,230,230);tb.TextSize=13;tb.ClearTextOnFocus=false;inF[fN]=tb;cY=cY+22+pad/2;if fN=="PosZ" or fN=="SizeZ" then cY=cY+pad/2 end end;cY=cY+pad
    local crB=Instance.new("TextButton");crB.Parent=mainFrame;crB.BackgroundColor3=Color3.fromRGB(70,140,80);crB.Size=UDim2.new(1,-pad*2,0,30);crB.Position=UDim2.new(0,pad,0,cY);crB.Font=Enum.Font.SourceSansSemibold;crB.Text="Create Shared Part";crB.TextColor3=Color3.fromRGB(255,255,255);cY=cY+30+pad;table.insert(_G.CFX_InternalGuiConnections,crB.MouseButton1Click:Connect(function()local a,ok={},true;for _,fN in ipairs(fOrder) do local nV=tonumber(inF[fN].Text);if nV==nil then _G.CFX_ShowNotification("Error: Invalid "..fN,Color3.fromRGB(255,50,50));inF[fN].BorderColor3=Color3.fromRGB(150,50,50);ok=false else table.insert(a,nV);inF[fN].BorderColor3=Color3.fromRGB(30,30,35)end end;if ok and #a==9 then sendAction("CREATE_PART",unpack(a))elseif not ok then print("CFX GUI: Validation failed.")end end))
    local clB=Instance.new("TextButton");clB.Parent=mainFrame;clB.BackgroundColor3=Color3.fromRGB(140,70,80);clB.Size=UDim2.new(1,-pad*2,0,30);clB.Position=UDim2.new(0,pad,0,cY);clB.Font=Enum.Font.SourceSansSemibold;clB.Text="Clear My Shared Parts";clB.TextColor3=Color3.fromRGB(255,255,255);cY=cY+30+pad;table.insert(_G.CFX_InternalGuiConnections,clB.MouseButton1Click:Connect(function()_G.CFX_ShowNotification("Sending DELETE_MY_PARTS...",Color3.fromRGB(255,150,50));sendAction("DELETE_MY_PARTS");handleCommand("DELETE_MY_PARTS",{},LocalPlayer.Name)end))
    mainFrame.Size=UDim2.new(0,320,0,cY);mainFrame.Position=UDim2.new(.5,-mainFrame.AbsoluteSize.X/2,.5,-mainFrame.AbsoluteSize.Y/2)
    local xB=Instance.new("TextButton");xB.Parent=titleLabel;xB.Size=UDim2.new(0,24,0,24);xB.Position=UDim2.new(1,-28,.5,-12);xB.BackgroundColor3=Color3.fromRGB(180,70,80);xB.Font=Enum.Font.SourceSansBold;xB.Text="X";xB.TextColor3=Color3.fromRGB(255,255,255);xB.ZIndex=titleLabel.ZIndex+1;table.insert(_G.CFX_InternalGuiConnections,xB.MouseButton1Click:Connect(function()screenGui.Enabled=not screenGui.Enabled end))
    local pPosUpd;pPosUpd=RunService.RenderStepped:Connect(function()if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then local p=LocalPlayer.Character.PrimaryPart.Position;xL.Text=pLs[1][2]..string.format("%.1f",p.X);yL.Text=pLs[2][2]..string.format("%.1f",p.Y);zL.Text=pLs[3][2]..string.format("%.1f",p.Z)else for _,d in ipairs(pLs)do d[1].Text=d[2].."N/A"end end end);table.insert(_G.CFX_InternalGuiConnections,pPosUpd)
    print("CFX: Executor GUI created.");screenGui.Enabled=true
end

if LocalPlayer then if LocalPlayer:IsDescendantOf(PlayersService) and LocalPlayer.PlayerGui then CreateExecutorGUI() else local pA_g;pA_g=PlayersService.ChildAdded:Connect(function(c)if c==LocalPlayer and LocalPlayer.PlayerGui then CreateExecutorGUI()if pA_g then pA_g:Disconnect()end end end);if not LocalPlayer.PlayerGui then local pGA_g;pGA_g=LocalPlayer.ChildAdded:Connect(function(c)if c.Name=="PlayerGui" then CreateExecutorGUI()if pGA_g then pGA_g:Disconnect()end end end) table.insert(_G.CFX_GuiConnections,pGA_g)end table.insert(_G.CFX_GuiConnections,pA_g)end else warn("CFX: LocalPlayer not found.")end
print("CFX: Скрипт 'Телепатия' (vGUI, PosDisplay, TextColorFix, TCS Send Attempt) загружен.")
