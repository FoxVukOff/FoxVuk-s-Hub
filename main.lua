-- FoxVuk Hub v1.1.1 — Полный код с вкладкой About, подсказкой по RightShift и поддержкой перетаскивания

local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local CoreGui             = game:GetService("CoreGui")

-- Таблица со скриптами (только запрошенные)
local scripts = {
    {
        displayName = "Forsaken",
        placeId     = 18687417158,
        scriptName  = "Forsaken",
        author      = "ivannetta",
        url         = "https://raw.githubusercontent.com/ivannetta/ShitScripts/main/forsaken.lua",
        description = "Категории: aimbot, visuals, misc, generators и т.д."
    },
    {
        displayName = "Starlight",
        placeId     = 0,
        scriptName  = "Starlight",
        author      = "—",
        url         = "https://starlightrbx.netlify.app/",
        description = "Backdoor finder for places"
    },
    {
        displayName = "Infinite Yield",
        placeId     = 0,
        scriptName  = "Infinite Yield",
        author      = "EdgeIY",
        url         = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
        description = "Мощный админ-скрипт с тысячами команд"
    },
    {
        displayName = "Dex Explorer",
        placeId     = 0,
        scriptName  = "Dex",
        author      = "infyiff",
        url         = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua",
        description = "Полный эксплорер элементов и скриптов игры"
    }
}

-- Проверка устройства: если телефон — показываем предупреждение и выходим
local function showMobileWarning()
    local warnGui = Instance.new("ScreenGui", CoreGui)
    warnGui.Name = "FoxVukHub_MobileWarn"
    local frame = Instance.new("Frame", warnGui)
    frame.Size = UDim2.new(0,300,0,150)
    frame.Position = UDim2.new(0.5,-150,0.5,-75)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,-20,0,60)
    label.Position = UDim2.new(0,10,0,10)
    label.BackgroundTransparency = 1
    label.Text = "Скрипт пока не поддерживается на телефоне.\nСкоро выйдет поддержка!"
    label.TextWrapped = true
    label.Font = Enum.Font.Gotham
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(255,255,255)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0,100,0,30)
    btn.Position = UDim2.new(0.5,-50,1,-40)
    btn.Text = "OK"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function()
        warnGui:Destroy()
    end)
end

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    showMobileWarning()
    return
end

-- Создаём главный GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "FoxVukHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = CoreGui
ScreenGui.Enabled = true

-- Основной фрейм
local Main = Instance.new("Frame", ScreenGui)
Main.AnchorPoint    = Vector2.new(0.5,0.5)
Main.Position       = UDim2.new(0.5,0,0.5,0)
Main.Size           = UDim2.new(0,520,0,480)
Main.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

-- TitleBar (за него тянем)
local TitleBar = Instance.new("Frame", Main)
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1,0,0,40)
TitleBar.Position         = UDim2.new(0,0,0,0)
TitleBar.BackgroundColor3 = Color3.fromRGB(40,40,40)
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,12)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size               = UDim2.new(1,-10,1,0)
TitleLabel.Position           = UDim2.new(0,5,0,0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text               = "FoxVuk Hub v1.1.1 - Made by FoxVuk"
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextSize           = 18
TitleLabel.TextColor3         = Color3.fromRGB(255,255,255)
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left

-- Подсказка по RightShift
local HintLabel = Instance.new("TextLabel", TitleBar)
HintLabel.Size               = UDim2.new(0,200,1,0)
HintLabel.Position           = UDim2.new(1,-205,0,0)
HintLabel.BackgroundTransparency = 1
HintLabel.Text               = "[RightShift] toggle GUI"
HintLabel.Font               = Enum.Font.Gotham
HintLabel.TextSize           = 14
HintLabel.TextColor3         = Color3.fromRGB(200,200,200)
HintLabel.TextXAlignment     = Enum.TextXAlignment.Right

-- Перетаскивание окна
do
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)
end

-- Левая панель: список кнопок
local ListFrame = Instance.new("Frame", Main)
ListFrame.Position        = UDim2.new(0,10,0,50)
ListFrame.Size            = UDim2.new(0,160,1,-60)
ListFrame.BackgroundTransparency = 1
local ListLayout = Instance.new("UIListLayout", ListFrame)
ListLayout.Padding        = UDim.new(0,8)
ListLayout.SortOrder      = Enum.SortOrder.LayoutOrder

-- Правая панель: детали
local Details = Instance.new("ScrollingFrame", Main)
Details.Position          = UDim2.new(0,180,0,50)
Details.Size              = UDim2.new(1,-190,1,-60)
Details.BackgroundTransparency = 1
Details.ScrollBarThickness = 6
Details.AutomaticCanvasSize = Enum.AutomaticSize.Y
local DetailLayout = Instance.new("UIListLayout", Details)
DetailLayout.Padding      = UDim.new(0,8)
DetailLayout.SortOrder    = Enum.SortOrder.LayoutOrder

-- Очистка деталей (не трогая Layout)
local function clearDetails()
    for _, c in ipairs(Details:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

-- Создание лейбла
local function makeLabel(text, font, size, color)
    local lbl = Instance.new("TextLabel", Details)
    lbl.BackgroundTransparency = 1
    lbl.Size               = UDim2.new(1,0,0,0)
    lbl.AutomaticSize      = Enum.AutomaticSize.Y
    lbl.Text               = text
    lbl.Font               = font
    lbl.TextSize           = size
    lbl.TextColor3         = color
    lbl.TextWrapped        = true
    return lbl
end

-- Отображение вкладки About
local function showAbout()
    clearDetails()
    makeLabel("FoxVuk Hub", Enum.Font.GothamBold, 22, Color3.new(1,1,1))
    makeLabel("Версия: 1.1.1 (добавлена подсказка о RightShift)", Enum.Font.Gotham, 16, Color3.new(0.8,0.8,0.8))
    makeLabel("Made by FoxVuk", Enum.Font.Gotham, 16, Color3.new(0.8,0.8,0.8))
    makeLabel("Поддержка на телефоне пока не готова, но скоро выйдет!", Enum.Font.Gotham, 14, Color3.new(0.8,0.8,0.8))
end

-- Отображение деталей выбранного скрипта
local function showDetails(data)
    clearDetails()
    makeLabel(data.displayName, Enum.Font.GothamBold, 22, Color3.new(1,1,1))
    makeLabel((data.placeId~=0 and "Place ID: "..data.placeId) or "Place ID: Universal",
              Enum.Font.Gotham, 16, Color3.new(0.8,0.8,0.8))
    makeLabel("Script: "..data.scriptName,
              Enum.Font.Gotham, 16, Color3.new(0.8,0.8,0.8))
    makeLabel("Author: "..data.author,
              Enum.Font.Gotham, 16, Color3.new(0.8,0.8,0.8))
    makeLabel("Description: "..data.description,
              Enum.Font.Gotham, 14, Color3.new(0.8,0.8,0.8))
    local btn = Instance.new("TextButton", Details)
    btn.Size             = UDim2.new(0,220,0,40)
    btn.AutoButtonColor  = false
    btn.Text             = "Execute"
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 18
    btn.TextColor3       = Color3.new(1,1,1)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(60,60,60)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(50,50,50)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if data.placeId==0 or game.PlaceId==data.placeId then
            if getgenv then
                getgenv().BloxtrapRPC      = "true"
                getgenv().DebugNotifications = "false"
                getgenv().TrackMePlease     = "true"
            end
            pcall(function() loadstring(game:HttpGetAsync(data.url))() end)
        end
    end)
end

-- Создаём кнопку About первой
do
    local btn = Instance.new("TextButton", ListFrame)
    btn.Size             = UDim2.new(1,0,0,40)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.AutoButtonColor  = false
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 18
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Text             = "About"
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.LayoutOrder      = 0
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(80,80,80)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(60,60,60)}):Play()
    end)
    btn.MouseButton1Click:Connect(showAbout)
end

-- Создаём кнопки для каждого скрипта
for i,data in ipairs(scripts) do
    local btn = Instance.new("TextButton", ListFrame)
    btn.Size             = UDim2.new(1,0,0,40)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.AutoButtonColor  = false
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 18
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Text             = data.displayName
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.LayoutOrder      = i

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(55,55,55)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(40,40,40)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        showDetails(data)
    end)
end

-- Переключение видимости GUI по RightShift
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode==Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- Отображаем вкладку About по умолчанию
showAbout()

print("[FoxVukHub] v1.1.1 Loaded successfully — добавлена подсказка про RightShift")
