local TweenService      = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

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

-- Создаём GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "FoxVukHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame", ScreenGui)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.Position    = UDim2.new(0.5,0,0.5,0)
Main.Size        = UDim2.new(0, 520, 0, 440)
Main.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

-- Заголовок
local Title = Instance.new("TextLabel", Main)
Title.Size               = UDim2.new(1,0,0,40)
Title.Position           = UDim2.new(0,0,0,0)
Title.BackgroundTransparency = 1
Title.Text               = "FoxVuk Hub"
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 24
Title.TextColor3         = Color3.fromRGB(255,255,255)

-- Подзаголовок
local Subtitle = Instance.new("TextLabel", Main)
Subtitle.Size            = UDim2.new(1,0,0,20)
Subtitle.Position        = UDim2.new(0,0,0,40)
Subtitle.BackgroundTransparency = 1
Subtitle.Text            = "Made by FoxVuk"
Subtitle.Font            = Enum.Font.Gotham
Subtitle.TextSize        = 14
Subtitle.TextColor3      = Color3.fromRGB(200,200,200)

-- Список скриптов
local ListFrame = Instance.new("Frame", Main)
ListFrame.Position       = UDim2.new(0,10,0,70)
ListFrame.Size           = UDim2.new(0,160,1,-80)
ListFrame.BackgroundTransparency = 1
local UIList = Instance.new("UIListLayout", ListFrame)
UIList.Padding           = UDim.new(0,8)
UIList.SortOrder         = Enum.SortOrder.Name

-- Окно деталей (scrollable)
local Details = Instance.new("ScrollingFrame", Main)
Details.Position         = UDim2.new(0,180,0,70)
Details.Size             = UDim2.new(1,-190,1,-80)
Details.CanvasSize       = UDim2.new(0,0,2,0)  -- даст возможность скроллить вниз
Details.ScrollBarThickness = 6
Details.BackgroundTransparency = 1
local DetailLayout = Instance.new("UIListLayout", Details)
DetailLayout.Padding = UDim.new(0,8)
DetailLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function showDetails(data)
    Details:ClearAllChildren()

    local function newLabel(text, size)
        local lbl = Instance.new("TextLabel", Details)
        lbl.Size               = UDim2.new(1,0,0,size)
        lbl.BackgroundTransparency = 1
        lbl.Text               = text
        lbl.Font               = size > 16 and Enum.Font.GothamBold or Enum.Font.Gotham
        lbl.TextSize           = size
        lbl.TextColor3         = size > 16 and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
        lbl.TextWrapped        = true
        lbl.LayoutOrder        = #Details:GetChildren()
        return lbl
    end

    newLabel(data.displayName, 24)
    newLabel((data.placeId~=0 and "Place ID: "..data.placeId) or "Place ID: Universal", 16)
    newLabel("Script: "..data.scriptName, 16)
    newLabel("Author: "..data.author, 16)
    newLabel("Description: "..data.description, 14)

    local execBtn = Instance.new("TextButton", Details)
    execBtn.Size           = UDim2.new(0,220,0,40)
    execBtn.Text           = "Execute"
    execBtn.Font           = Enum.Font.GothamBold
    execBtn.TextSize       = 18
    execBtn.TextColor3     = Color3.fromRGB(255,255,255)
    execBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    execBtn.LayoutOrder    = #Details:GetChildren()+1
    Instance.new("UICorner", execBtn).CornerRadius = UDim.new(0,6)

    execBtn.MouseEnter:Connect(function()
        TweenService:Create(execBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(60,60,60)}):Play()
    end)
    execBtn.MouseLeave:Connect(function()
        TweenService:Create(execBtn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(50,50,50)}):Play()
    end)
    execBtn.MouseButton1Click:Connect(function()
        if data.placeId==0 or game.PlaceId==data.placeId then
            if getgenv then
                getgenv().BloxtrapRPC      = "true"
                getgenv().DebugNotifications = "false"
                getgenv().TrackMePlease     = "true"
            end
            pcall(function()
                loadstring(game:HttpGetAsync(data.url))()
            end)
        end
    end)
end

-- Заполняем кнопки списка
for _, data in ipairs(scripts) do
    local btn = Instance.new("TextButton", ListFrame)
    btn.Size           = UDim2.new(1,0,0,40)
    btn.Text           = data.displayName
    btn.Font           = Enum.Font.Gotham
    btn.TextSize       = 18
    btn.TextColor3     = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

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

-- Переключение GUI по RightShift
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode==Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

print("[FoxVukHub] Loaded successfully")
