local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")

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

-- создать GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "FoxVukHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = CoreGui

-- основной фрейм
local Main = Instance.new("Frame", ScreenGui)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.Position    = UDim2.new(0.5,0,0.5,0)
Main.Size        = UDim2.new(0, 520, 0, 440)
Main.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

-- заголовок
local Title = Instance.new("TextLabel", Main)
Title.Name               = "Title"
Title.AnchorPoint        = Vector2.new(0.5,0)
Title.Position           = UDim2.new(0.5,0,0,10)
Title.Size               = UDim2.new(1,-20,0,30)
Title.BackgroundTransparency = 1
Title.Text               = "FoxVuk Hub"
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 24
Title.TextColor3         = Color3.fromRGB(255,255,255)

-- подзаголовок
local Subtitle = Instance.new("TextLabel", Main)
Subtitle.Name            = "Subtitle"
Subtitle.AnchorPoint     = Vector2.new(0.5,0)
Subtitle.Position        = UDim2.new(0.5,0,0,45)
Subtitle.Size            = UDim2.new(1,-20,0,18)
Subtitle.BackgroundTransparency = 1
Subtitle.Text            = "Made by FoxVuk"
Subtitle.Font            = Enum.Font.Gotham
Subtitle.TextSize        = 14
Subtitle.TextColor3      = Color3.fromRGB(200,200,200)

-- список скриптов слева
local ListFrame = Instance.new("Frame", Main)
ListFrame.Name            = "List"
ListFrame.Position        = UDim2.new(0,10,0,70)
ListFrame.Size            = UDim2.new(0,160,1,-80)
ListFrame.BackgroundTransparency = 1
local ListLayout = Instance.new("UIListLayout", ListFrame)
ListLayout.Padding       = UDim.new(0,8)
ListLayout.SortOrder     = Enum.SortOrder.LayoutOrder

-- окно деталей справа со скроллом
local Details = Instance.new("ScrollingFrame", Main)
Details.Name               = "Details"
Details.Position           = UDim2.new(0,180,0,70)
Details.Size               = UDim2.new(1,-190,1,-80)
Details.BackgroundTransparency = 1
Details.CanvasSize         = UDim2.new(0,0,0,0) -- авто-скролл
Details.ScrollBarThickness = 6
Details.AutomaticCanvasSize = Enum.AutomaticSize.Y

local DetailLayout = Instance.new("UIListLayout", Details)
DetailLayout.Padding       = UDim.new(0,8)
DetailLayout.SortOrder     = Enum.SortOrder.LayoutOrder

-- функция для создания лейблов
local function makeLabel(parent, text, font, size, textColor)
    local lbl = Instance.new("TextLabel", parent)
    lbl.BackgroundTransparency = 1
    lbl.Size               = UDim2.new(1,0,0,0)
    lbl.AutomaticSize      = Enum.AutomaticSize.Y
    lbl.Text               = text
    lbl.Font               = font
    lbl.TextSize           = size
    lbl.TextColor3         = textColor
    lbl.TextWrapped        = true
    lbl.LayoutOrder        = #parent:GetChildren()
    return lbl
end

-- показать детали выбранного скрипта
local function showDetails(data)
    Details:ClearAllChildren()
    -- создаём заголовки
    makeLabel(Details, data.displayName, Enum.Font.GothamBold, 22, Color3.fromRGB(255,255,255))
    makeLabel(Details, (data.placeId~=0 and "Place ID: "..data.placeId) or "Place ID: Universal",
              Enum.Font.Gotham, 16, Color3.fromRGB(200,200,200))
    makeLabel(Details, "Script: "..data.scriptName,
              Enum.Font.Gotham, 16, Color3.fromRGB(200,200,200))
    makeLabel(Details, "Author: "..data.author,
              Enum.Font.Gotham, 16, Color3.fromRGB(200,200,200))
    makeLabel(Details, "Description: "..data.description,
              Enum.Font.Gotham, 14, Color3.fromRGB(200,200,200))

    -- кнопка Execute
    local btn = Instance.new("TextButton", Details)
    btn.Size               = UDim2.new(0,220,0,40)
    btn.AutoButtonColor    = false
    btn.Text               = "Execute"
    btn.Font               = Enum.Font.GothamBold
    btn.TextSize           = 18
    btn.TextColor3         = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3   = Color3.fromRGB(50,50,50)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.LayoutOrder        = #Details:GetChildren()+1

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50,50,50)}):Play()
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

-- заполняем список кнопок
for idx, data in ipairs(scripts) do
    local btn = Instance.new("TextButton", ListFrame)
    btn.Size               = UDim2.new(1,0,0,40)
    btn.Position           = UDim2.new(0,0,0,0)
    btn.BackgroundColor3   = Color3.fromRGB(40,40,40)
    btn.AutoButtonColor    = false
    btn.Text               = data.displayName
    btn.Font               = Enum.Font.Gotham
    btn.TextSize           = 18
    btn.TextColor3         = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.LayoutOrder        = idx

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55,55,55)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        showDetails(data)
    end)
end

-- переключение GUI клавишей RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

print("[FoxVukHub] Loaded successfully")
