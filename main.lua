local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local scripts = {
    {
        displayName = "Forsaken",
        placeId = 18687417158,
        scriptName = "Forsaken",
        author = "ivannetta",
        url = "https://raw.githubusercontent.com/ivannetta/ShitScripts/main/forsaken.lua",
        description = "Категории: aimbot, visuals, misc, generators и т.д."
    },
    {
        displayName = "Starlight",
        placeId = 0, -- универсальный режим, PlaceId не проверяется
        scriptName = "Starlight",
        author = "—",
        url = "https://starlightrbx.netlify.app/",
        description = "Backdoor finder for places"
    }
}

local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FoxVukHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = true  -- видимость GUI

local Main = Instance.new("Frame", ScreenGui)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.Position = UDim2.new(0.5,0,0.5,0)
Main.Size = UDim2.new(0, 500, 0, 350)
Main.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,12)

-- Заголовок
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,0,0,40)
Title.Position = UDim2.new(0,0,0,0)
Title.BackgroundTransparency = 1
Title.Text = "FoxVuk Hub"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextColor3 = Color3.fromRGB(255,255,255)

-- Подзаголовок
local Subtitle = Instance.new("TextLabel", Main)
Subtitle.Size = UDim2.new(1,0,0,20)
Subtitle.Position = UDim2.new(0,0,0,40)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Made by FoxVuk"
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 14
Subtitle.TextColor3 = Color3.fromRGB(200,200,200)

local ListFrame = Instance.new("Frame", Main)
ListFrame.Position = UDim2.new(0,10,0,70)
ListFrame.Size = UDim2.new(0,150,1,-80)
ListFrame.BackgroundTransparency = 1
local UIList = Instance.new("UIListLayout", ListFrame)
UIList.Padding = UDim.new(0,8)
UIList.SortOrder = Enum.SortOrder.Name

local Details = Instance.new("Frame", Main)
Details.Position = UDim2.new(0,170,0,70)
Details.Size = UDim2.new(1,-180,1,-80)
Details.BackgroundTransparency = 1

local function showDetails(data)
    Details:ClearAllChildren()

    local title = Instance.new("TextLabel", Details)
    title.Size = UDim2.new(1,0,0,30)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = data.displayName
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.BackgroundTransparency = 1

    local idLabel = Instance.new("TextLabel", Details)
    idLabel.Size = UDim2.new(1,0,0,20)
    idLabel.Position = UDim2.new(0,0,0,35)
    idLabel.Text = (data.placeId ~= 0 and "Place ID: "..data.placeId) or "Place ID: Universal"
    idLabel.Font = Enum.Font.Gotham
    idLabel.TextSize = 16
    idLabel.TextColor3 = Color3.fromRGB(200,200,200)
    idLabel.BackgroundTransparency = 1

    local scriptLabel = Instance.new("TextLabel", Details)
    scriptLabel.Size = UDim2.new(1,0,0,20)
    scriptLabel.Position = UDim2.new(0,0,0,60)
    scriptLabel.Text = "Script: "..data.scriptName
    scriptLabel.Font = Enum.Font.Gotham
    scriptLabel.TextSize = 16
    scriptLabel.TextColor3 = Color3.fromRGB(200,200,200)
    scriptLabel.BackgroundTransparency = 1

    local authorLabel = Instance.new("TextLabel", Details)
    authorLabel.Size = UDim2.new(1,0,0,20)
    authorLabel.Position = UDim2.new(0,0,0,85)
    authorLabel.Text = "Author: "..data.author
    authorLabel.Font = Enum.Font.Gotham
    authorLabel.TextSize = 16
    authorLabel.TextColor3 = Color3.fromRGB(200,200,200)
    authorLabel.BackgroundTransparency = 1

    local descLabel = Instance.new("TextLabel", Details)
    descLabel.Size = UDim2.new(1,0,0,40)
    descLabel.Position = UDim2.new(0,0,0,110)
    descLabel.Text = "Description: "..data.description
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 14
    descLabel.TextWrapped = true
    descLabel.TextColor3 = Color3.fromRGB(200,200,200)
    descLabel.BackgroundTransparency = 1

    local execBtn = Instance.new("TextButton", Details)
    execBtn.Size = UDim2.new(0,200,0,40)
    execBtn.Position = UDim2.new(0,0,0,160)
    execBtn.Text = "Execute"
    execBtn.Font = Enum.Font.GothamBold
    execBtn.TextSize = 18
    execBtn.TextColor3 = Color3.fromRGB(255,255,255)
    execBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Instance.new("UICorner", execBtn).CornerRadius = UDim.new(0,6)

    execBtn.MouseEnter:Connect(function()
        TweenService:Create(execBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play()
    end)
    execBtn.MouseLeave:Connect(function()
        TweenService:Create(execBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50,50,50)}):Play()
    end)
    execBtn.MouseButton1Click:Connect(function()
        if data.placeId == 0 or game.PlaceId == data.placeId then
            if getgenv then
                getgenv().BloxtrapRPC = "true"
                getgenv().DebugNotifications = "false"
                getgenv().TrackMePlease = "true"
            end
            loadstring(game:HttpGetAsync(data.url))()
        end
    end)
end

for _, data in ipairs(scripts) do
    local btn = Instance.new("TextButton", ListFrame)
    btn.Size = UDim2.new(1,0,0,40)
    btn.Text = data.displayName
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 18
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(55,55,55)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40,40,40)}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        for _, other in ipairs(ListFrame:GetChildren()) do
            if other:IsA("TextButton") then
                TweenService:Create(other, TweenInfo.new(0.2), {Size = UDim2.new(1,0,0,40)}):Play()
            end
        end
        TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(1,0,0,60)}):Play()
        showDetails(data)
    end)
end

-- Переключение видимости GUI клавишей RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)
