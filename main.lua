-- // SECURITY CHECK (PLACE LOCK)
local AllowedPlaceId = 4924922222
if game.PlaceId ~= AllowedPlaceId then
    game.Players.LocalPlayer:Kick("\n[AERO SECURITY]\nThis script can only be used in:\nBrookhaven RP (ID: " .. AllowedPlaceId .. ")")
    return 
end

-- // SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TouchInputService = game:GetService("TouchInputService")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // VARIABLES
local TargetPlayer = nil
local IsFlinging = false
local IsViewing = false
local CurrentMode = "HELI"
local Angle = 0
local LastPosition = nil 
local GuiVisible = false

-- Variables untuk player navigation
local PlayerList = {}
local CurrentPlayerIndex = 1

-- // SETTINGS
local FlingPower = 9e7 
local RotPower = 9e8

-- // DETECT MOBILE
local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- // LAUNCHER LOGO SETUP
local LauncherGui = Instance.new("ScreenGui")
LauncherGui.Name = "AERO_Launcher"
LauncherGui.DisplayOrder = 9999
LauncherGui.ResetOnSpawn = false
LauncherGui.Parent = (gethui and gethui()) or Player:WaitForChild("PlayerGui")
LauncherGui.IgnoreGuiInset = true -- Penting untuk mobile

-- Variabel untuk drag functionality
local LogoDragging = false
local LogoDragStartPos
local LogoStartPos
local LogoDragTouchId = nil

-- Logo Button
local LogoBtn = Instance.new("ImageButton")
LogoBtn.Name = "LogoButton"
LogoBtn.Size = UDim2.new(0, 70, 0, 70)
LogoBtn.Position = UDim2.new(0, 20, 0.5, -35)
LogoBtn.Image = "rbxassetid://101243997945630"
LogoBtn.BackgroundTransparency = 1
LogoBtn.ImageTransparency = 0.2
LogoBtn.ScaleType = Enum.ScaleType.Fit
LogoBtn.Active = true
LogoBtn.Selectable = true
LogoBtn.Parent = LauncherGui
LogoBtn.AutoButtonColor = false -- Matikan efek auto untuk mobile

-- Buat logo menjadi lingkaran
local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(1, 0)
LogoCorner.Parent = LogoBtn

-- UI Stroke untuk border ringan
local LogoStroke = Instance.new("UIStroke")
LogoStroke.Thickness = 1
LogoStroke.Color = Color3.fromRGB(100, 100, 100)
LogoStroke.Transparency = 0.7
LogoStroke.Parent = LogoBtn

-- // FUNGSI DRAG LOGO (SUPPORT MOBILE)
local function StartLogoDrag(input)
    LogoDragging = true
    if input.UserInputType == Enum.UserInputType.Touch then
        LogoDragTouchId = input.KeyCode -- Simpan touch ID
        LogoDragStartPos = input.Position
    else
        LogoDragStartPos = input.Position
    end
    LogoStartPos = LogoBtn.Position
    LogoBtn.ImageTransparency = 0
    LogoStroke.Transparency = 0.3
end

local function EndLogoDrag()
    LogoDragging = false
    LogoDragTouchId = nil
    LogoBtn.ImageTransparency = 0.2
    LogoStroke.Transparency = 0.7
end

-- Handle input untuk mouse dan touch
LogoBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        StartLogoDrag(input)
    end
end)

LogoBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- Cek apakah ini touch yang sama
        if input.UserInputType == Enum.UserInputType.Touch and input.KeyCode ~= LogoDragTouchId then
            return
        end
        EndLogoDrag()
    end
end)

-- Handle drag movement untuk mouse dan touch
UserInputService.InputChanged:Connect(function(input, processed)
    if not LogoDragging then return end
    
    -- Skip jika input diproses oleh game
    if processed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        -- Mouse drag
        local delta = input.Position - LogoDragStartPos
        LogoBtn.Position = UDim2.new(
            LogoStartPos.X.Scale, 
            LogoStartPos.X.Offset + delta.X,
            LogoStartPos.Y.Scale, 
            LogoStartPos.Y.Offset + delta.Y
        )
    elseif input.UserInputType == Enum.UserInputType.Touch then
        -- Touch drag - pastikan touch ID sama
        if input.KeyCode == LogoDragTouchId then
            local delta = input.Position - LogoDragStartPos
            LogoBtn.Position = UDim2.new(
                LogoStartPos.X.Scale, 
                LogoStartPos.X.Offset + delta.X,
                LogoStartPos.Y.Scale, 
                LogoStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

-- Hover effect hanya untuk desktop
if not IsMobile() then
    LogoBtn.MouseEnter:Connect(function()
        if not LogoDragging then
            LogoBtn.ImageTransparency = 0
            LogoStroke.Transparency = 0.3
        end
    end)

    LogoBtn.MouseLeave:Connect(function()
        if not LogoDragging then
            LogoBtn.ImageTransparency = 0.2
            LogoStroke.Transparency = 0.7
        end
    end)
end

-- // FUNGSI UNTUK UPDATE PLAYER LIST
local function UpdatePlayerList()
    PlayerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            table.insert(PlayerList, player)
        end
    end
    return #PlayerList
end

-- // FUNGSI UNTUK MENAMPILKAN TIPS NOTIFICATION
local function ShowTipNotification()
    local TipGui = Instance.new("ScreenGui")
    TipGui.Name = "AERO_Tip"
    TipGui.DisplayOrder = 10001
    TipGui.ResetOnSpawn = false
    TipGui.IgnoreGuiInset = true
    TipGui.Parent = (gethui and gethui()) or Player:WaitForChild("PlayerGui")
    
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(0, 400, 0, 140)
    Notification.Position = UDim2.new(0.5, -200, 0.5, -70)
    Notification.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Parent = TipGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 15)
    Corner.Parent = Notification
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 2
    Stroke.Color = Color3.fromRGB(255, 100, 0)
    Stroke.Transparency = 1
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = Notification
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 50, 0, 50)
    Icon.Position = UDim2.new(0, 10, 0.5, -25)
    Icon.Text = "⚠️"
    Icon.TextSize = 40
    Icon.TextColor3 = Color3.fromRGB(255, 200, 0)
    Icon.BackgroundTransparency = 1
    Icon.TextTransparency = 1
    Icon.Font = Enum.Font.GothamBold
    Icon.Parent = Notification
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -80, 0, 30)
    Title.Position = UDim2.new(0, 70, 0, 25)
    Title.Text = "IMPORTANT TIP!"
    Title.TextSize = 24
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.TextTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextStrokeTransparency = 0.8
    Title.TextStrokeColor3 = Color3.fromRGB(255, 100, 0)
    Title.Parent = Notification
    
    local Message = Instance.new("TextLabel")
    Message.Size = UDim2.new(1, -80, 0, 50)
    Message.Position = UDim2.new(0, 70, 0, 50)
    Message.Text = "You must sit in a vehicle or helicopter first\nfor the fling to work!"
    Message.TextSize = 16
    Message.TextColor3 = Color3.fromRGB(200, 200, 200)
    Message.TextXAlignment = Enum.TextXAlignment.Left
    Message.TextYAlignment = Enum.TextYAlignment.Top
    Message.BackgroundTransparency = 1
    Message.TextTransparency = 1
    Message.Font = Enum.Font.Gotham
    Message.RichText = true
    Message.Parent = Notification
    
    local Timer = Instance.new("TextLabel")
    Timer.Size = UDim2.new(0, 30, 0, 30)
    Timer.Position = UDim2.new(1, -40, 1, -40)
    Timer.Text = "5s"
    Timer.TextSize = 14
    Timer.TextColor3 = Color3.fromRGB(255, 200, 0)
    Timer.BackgroundTransparency = 1
    Timer.TextTransparency = 1
    Timer.Font = Enum.Font.GothamBold
    Timer.Parent = Notification
    
    local fadeInDuration = 0.5
    local displayDuration = 5
    local fadeOutDuration = 0.5
    
    local fadeObjects = {
        {obj = Notification, props = {BackgroundTransparency = 0}},
        {obj = Stroke, props = {Transparency = 0}},
        {obj = Icon, props = {TextTransparency = 0}},
        {obj = Title, props = {TextTransparency = 0}},
        {obj = Message, props = {TextTransparency = 0}},
        {obj = Timer, props = {TextTransparency = 0}}
    }
    
    for _, data in ipairs(fadeObjects) do
        local tween = TweenService:Create(
            data.obj,
            TweenInfo.new(fadeInDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            data.props
        )
        tween:Play()
    end
    
    local startTime = tick()
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local remaining = math.max(0, displayDuration - elapsed)
        Timer.Text = math.ceil(remaining) .. "s"
        
        if remaining <= 0 then
            connection:Disconnect()
        end
    end)
    
    task.wait(displayDuration)
    
    for _, data in ipairs(fadeObjects) do
        local revertProps = {}
        for prop, _ in pairs(data.props) do
            if prop == "BackgroundTransparency" then revertProps[prop] = 1
            elseif prop == "Transparency" then revertProps[prop] = 1
            elseif prop == "TextTransparency" then revertProps[prop] = 1
            end
        end
        
        local tween = TweenService:Create(
            data.obj,
            TweenInfo.new(fadeOutDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            revertProps
        )
        tween:Play()
    end
    
    task.wait(fadeOutDuration)
    TipGui:Destroy()
end

-- // FUNGSI UNTUK MENAMPILKAN CREDIT NOTIFICATION
local function ShowCreditNotification()
    local CreditGui = Instance.new("ScreenGui")
    CreditGui.Name = "AERO_Credit"
    CreditGui.DisplayOrder = 10002
    CreditGui.ResetOnSpawn = false
    CreditGui.IgnoreGuiInset = true
    CreditGui.Parent = (gethui and gethui()) or Player:WaitForChild("PlayerGui")
    
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(0, 400, 0, 140)
    Notification.Position = UDim2.new(0.5, -200, 0.5, -70)
    Notification.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Parent = CreditGui
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 15)
    Corner.Parent = Notification
    
    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 2
    Stroke.Color = Color3.fromRGB(100, 200, 255)
    Stroke.Transparency = 1
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = Notification
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 50, 0, 50)
    Icon.Position = UDim2.new(0, 10, 0.5, -25)
    Icon.Text = "⭐"
    Icon.TextSize = 40
    Icon.TextColor3 = Color3.fromRGB(255, 215, 0)
    Icon.BackgroundTransparency = 1
    Icon.TextTransparency = 1
    Icon.Font = Enum.Font.GothamBold
    Icon.Parent = Notification
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -80, 0, 30)
    Title.Position = UDim2.new(0, 70, 0, 20)
    Title.Text = "⭐ CREDITS ⭐"
    Title.TextSize = 24
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.TextTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextStrokeTransparency = 0.7
    Title.TextStrokeColor3 = Color3.fromRGB(100, 200, 255)
    Title.Parent = Notification
    
    local Creator = Instance.new("TextLabel")
    Creator.Size = UDim2.new(1, -80, 0, 30)
    Creator.Position = UDim2.new(0, 70, 0, 50)
    Creator.Text = "This script has been created by"
    Creator.TextSize = 16
    Creator.TextColor3 = Color3.fromRGB(200, 200, 200)
    Creator.TextXAlignment = Enum.TextXAlignment.Left
    Creator.BackgroundTransparency = 1
    Creator.TextTransparency = 1
    Creator.Font = Enum.Font.Gotham
    Creator.Parent = Notification
    
    local Username = Instance.new("TextLabel")
    Username.Size = UDim2.new(1, -80, 0, 30)
    Username.Position = UDim2.new(0, 70, 0, 75)
    Username.Text = "@viunze on TikTok"
    Username.TextSize = 18
    Username.TextColor3 = Color3.fromRGB(0, 200, 255)
    Username.TextXAlignment = Enum.TextXAlignment.Left
    Username.BackgroundTransparency = 1
    Username.TextTransparency = 1
    Username.Font = Enum.Font.GothamBold
    Username.TextStrokeTransparency = 0.5
    Username.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    Username.Parent = Notification
    
    local Timer = Instance.new("TextLabel")
    Timer.Size = UDim2.new(0, 30, 0, 30)
    Timer.Position = UDim2.new(1, -40, 1, -40)
    Timer.Text = "3s"
    Timer.TextSize = 14
    Timer.TextColor3 = Color3.fromRGB(150, 150, 150)
    Timer.BackgroundTransparency = 1
    Timer.TextTransparency = 1
    Timer.Font = Enum.Font.GothamBold
    Timer.Parent = Notification
    
    local fadeInDuration = 0.5
    local displayDuration = 3
    local fadeOutDuration = 0.5
    
    local fadeObjects = {
        {obj = Notification, props = {BackgroundTransparency = 0}},
        {obj = Stroke, props = {Transparency = 0}},
        {obj = Icon, props = {TextTransparency = 0}},
        {obj = Title, props = {TextTransparency = 0}},
        {obj = Creator, props = {TextTransparency = 0}},
        {obj = Username, props = {TextTransparency = 0}},
        {obj = Timer, props = {TextTransparency = 0}}
    }
    
    for _, data in ipairs(fadeObjects) do
        local tween = TweenService:Create(
            data.obj,
            TweenInfo.new(fadeInDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            data.props
        )
        tween:Play()
    end
    
    local startTime = tick()
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local remaining = math.max(0, displayDuration - elapsed)
        Timer.Text = math.ceil(remaining) .. "s"
        
        if remaining <= 0 then
            connection:Disconnect()
        end
    end)
    
    task.wait(displayDuration)
    
    for _, data in ipairs(fadeObjects) do
        local revertProps = {}
        for prop, _ in pairs(data.props) do
            if prop == "BackgroundTransparency" then revertProps[prop] = 1
            elseif prop == "Transparency" then revertProps[prop] = 1
            elseif prop == "TextTransparency" then revertProps[prop] = 1
            end
        end
        
        local tween = TweenService:Create(
            data.obj,
            TweenInfo.new(fadeOutDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            revertProps
        )
        tween:Play()
    end
    
    task.wait(fadeOutDuration)
    CreditGui:Destroy()
end

-- // GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AERO_V2"
ScreenGui.Enabled = false
ScreenGui.DisplayOrder = 10000
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or Player:WaitForChild("PlayerGui")
ScreenGui.IgnoreGuiInset = true -- Penting untuk mobile

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 250)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Active = true
MainFrame.Draggable = not IsMobile() -- Non-draggable di mobile karena akan mengganggu
MainFrame.BackgroundTransparency = 1
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Transparency = 1
UIStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "AERO V2"
Title.TextSize = 22 
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSansBold
Title.TextTransparency = 1
Title.Parent = MainFrame

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0.9, 0, 0, 30)
ModeBtn.Position = UDim2.new(0.05, 0, 0.16, 0)
ModeBtn.Text = "MODE: HELI"
ModeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ModeBtn.TextColor3 = Color3.new(1, 1, 1)
ModeBtn.BackgroundTransparency = 1
ModeBtn.TextTransparency = 1
ModeBtn.Parent = MainFrame
ModeBtn.AutoButtonColor = false

local TargetFrame = Instance.new("Frame")
TargetFrame.Size = UDim2.new(0.9, 0, 0, 40)
TargetFrame.Position = UDim2.new(0.05, 0, 0.32, 0)
TargetFrame.BackgroundTransparency = 1
TargetFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TargetFrame.Parent = MainFrame

local BackBtn = Instance.new("TextButton")
BackBtn.Size = UDim2.new(0, 30, 1, 0)
BackBtn.Position = UDim2.new(0, 0, 0, 0)
BackBtn.Text = "<"
BackBtn.TextSize = 18
BackBtn.Font = Enum.Font.SourceSansBold
BackBtn.TextColor3 = Color3.new(1, 1, 1)
BackBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
BackBtn.BackgroundTransparency = 1
BackBtn.TextTransparency = 1
BackBtn.Parent = TargetFrame
BackBtn.AutoButtonColor = false

local TargetBtn = Instance.new("TextButton")
TargetBtn.Size = UDim2.new(0, 110, 1, 0)
TargetBtn.Position = UDim2.new(0.5, -55, 0, 0)
TargetBtn.Text = "SELECT TARGET"
TargetBtn.TextSize = 14
TargetBtn.TextColor3 = Color3.new(1, 1, 1)
TargetBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TargetBtn.BackgroundTransparency = 1
TargetBtn.TextTransparency = 1
TargetBtn.Parent = TargetFrame
TargetBtn.AutoButtonColor = false

local NextBtn = Instance.new("TextButton")
NextBtn.Size = UDim2.new(0, 30, 1, 0)
NextBtn.Position = UDim2.new(1, -30, 0, 0)
NextBtn.Text = ">"
NextBtn.TextSize = 18
NextBtn.Font = Enum.Font.SourceSansBold
NextBtn.TextColor3 = Color3.new(1, 1, 1)
NextBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
NextBtn.BackgroundTransparency = 1
NextBtn.TextTransparency = 1
NextBtn.Parent = TargetFrame
NextBtn.AutoButtonColor = false

local backCorner = Instance.new("UICorner")
backCorner.CornerRadius = UDim.new(0, 5)
backCorner.Parent = BackBtn

local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 5)
targetCorner.Parent = TargetBtn

local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0, 5)
nextCorner.Parent = NextBtn

local ViewBtn = Instance.new("TextButton")
ViewBtn.Size = UDim2.new(0.9, 0, 0, 30)
ViewBtn.Position = UDim2.new(0.05, 0, 0.52, 0)
ViewBtn.Text = "VIEW: OFF"
ViewBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ViewBtn.TextColor3 = Color3.new(1, 1, 1)
ViewBtn.BackgroundTransparency = 1
ViewBtn.TextTransparency = 1
ViewBtn.Parent = MainFrame
ViewBtn.AutoButtonColor = false

local FlingBtn = Instance.new("TextButton")
FlingBtn.Size = UDim2.new(0.9, 0, 0, 45)
FlingBtn.Position = UDim2.new(0.05, 0, 0.74, 0)
FlingBtn.Text = "LAUNCH"
FlingBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 80)
FlingBtn.TextColor3 = Color3.new(1, 1, 1)
FlingBtn.BackgroundTransparency = 1
FlingBtn.TextTransparency = 1
FlingBtn.Parent = MainFrame
FlingBtn.AutoButtonColor = false

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.Text = "X"
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.BorderSizePixel = 0
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextTransparency = 1
CloseBtn.Parent = MainFrame
CloseBtn.AutoButtonColor = false

-- Tambahkan UICorner untuk FlingBtn
local flingCorner = Instance.new("UICorner")
flingCorner.CornerRadius = UDim.new(0, 8)
flingCorner.Parent = FlingBtn

-- Tambahkan UICorner untuk semua tombol
local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 5)
modeCorner.Parent = ModeBtn

local viewCorner = Instance.new("UICorner")
viewCorner.CornerRadius = UDim.new(0, 5)
viewCorner.Parent = ViewBtn

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = CloseBtn

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = MainFrame

-- // FUNGSI TOGGLE GUI
local function OpenGUI()
    if GuiVisible then return end
    
    GuiVisible = true
    ScreenGui.Enabled = true
    MainFrame.Visible = true
    
    UpdatePlayerList()
    
    local fadeInFrame = TweenService:Create(
        MainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0}
    )
    
    local fadeInStroke = TweenService:Create(
        UIStroke,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Transparency = 0}
    )
    
    fadeInFrame:Play()
    fadeInStroke:Play()
    
    local components = {Title, ModeBtn, TargetFrame, BackBtn, TargetBtn, NextBtn, ViewBtn, FlingBtn, CloseBtn}
    for _, component in ipairs(components) do
        local targetProps = {}
        
        if component:IsA("TextButton") then
            targetProps.BackgroundTransparency = 0
            targetProps.TextTransparency = 0
        elseif component:IsA("TextLabel") then
            targetProps.TextTransparency = 0
        elseif component:IsA("Frame") and component ~= TargetFrame then
            targetProps.BackgroundTransparency = 0
        end
        
        if next(targetProps) then
            local tween = TweenService:Create(
                component,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                targetProps
            )
            tween:Play()
        end
    end
end

local function CloseGUI()
    if not GuiVisible then return end
    
    local components = {Title, ModeBtn, TargetFrame, BackBtn, TargetBtn, NextBtn, ViewBtn, FlingBtn, CloseBtn}
    for _, component in ipairs(components) do
        local targetProps = {}
        
        if component:IsA("TextButton") then
            targetProps.BackgroundTransparency = 1
            targetProps.TextTransparency = 1
        elseif component:IsA("TextLabel") then
            targetProps.TextTransparency = 1
        elseif component:IsA("Frame") and component ~= TargetFrame then
            targetProps.BackgroundTransparency = 1
        end
        
        if next(targetProps) then
            local tween = TweenService:Create(
                component,
                TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                targetProps
            )
            tween:Play()
        end
    end
    
    local fadeOutFrame = TweenService:Create(
        MainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 1}
    )
    
    local fadeOutStroke = TweenService:Create(
        UIStroke,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Transparency = 1}
    )
    
    fadeOutFrame:Play()
    fadeOutStroke:Play()
    
    fadeOutFrame.Completed:Wait()
    
    GuiVisible = false
    MainFrame.Visible = false
    ScreenGui.Enabled = false
    
    FlingBtn.Text = "LAUNCH"
    FlingBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 80)
end

local function ToggleGUI()
    if GuiVisible then
        CloseGUI()
    else
        OpenGUI()
    end
end

local logoClickTime = 0
LogoBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        logoClickTime = tick()
        StartLogoDrag(input)
    end
end)

LogoBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- Cek apakah ini touch yang sama
        if input.UserInputType == Enum.UserInputType.Touch and input.KeyCode ~= LogoDragTouchId then
            return
        end
        
        local clickDuration = tick() - logoClickTime
        EndLogoDrag()
        
        if clickDuration < 0.2 then
            ToggleGUI()
        end
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    CloseGUI()
end)

-- Untuk mobile, tambahkan touch event juga
CloseBtn.TouchTap:Connect(function()
    CloseGUI()
end)

-- // FUNGSI NAVIGASI PLAYER
local function SelectTargetPlayer()
    local playerCount = UpdatePlayerList()
    
    if playerCount == 0 then
        TargetPlayer = nil
        TargetBtn.Text = "NO PLAYERS"
        return false
    end
    
    if CurrentPlayerIndex > playerCount then
        CurrentPlayerIndex = 1
    end
    if CurrentPlayerIndex < 1 then
        CurrentPlayerIndex = playerCount
    end
    
    TargetPlayer = PlayerList[CurrentPlayerIndex]
    local displayName = TargetPlayer.Name
    
    if #displayName > 12 then
        displayName = displayName:sub(1, 10) .. ".."
    end
    
    TargetBtn.Text = displayName
    
    if IsViewing and TargetPlayer.Character then
        local hum = TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraSubject = hum
        end
    end
    
    return true
end

local function NextPlayer()
    local playerCount = UpdatePlayerList()
    
    if playerCount == 0 then
        TargetBtn.Text = "NO PLAYERS"
        return
    end
    
    CurrentPlayerIndex = CurrentPlayerIndex + 1
    if CurrentPlayerIndex > playerCount then
        CurrentPlayerIndex = 1
    end
    
    SelectTargetPlayer()
end

local function PreviousPlayer()
    local playerCount = UpdatePlayerList()
    
    if playerCount == 0 then
        TargetBtn.Text = "NO PLAYERS"
        return
    end
    
    CurrentPlayerIndex = CurrentPlayerIndex - 1
    if CurrentPlayerIndex < 1 then
        CurrentPlayerIndex = playerCount
    end
    
    SelectTargetPlayer()
end

BackBtn.MouseButton1Click:Connect(function()
    PreviousPlayer()
end)

NextBtn.MouseButton1Click:Connect(function()
    NextPlayer()
end)

TargetBtn.MouseButton1Click:Connect(function()
    NextPlayer()
end)

-- Untuk mobile
BackBtn.TouchTap:Connect(function()
    PreviousPlayer()
end)

NextBtn.TouchTap:Connect(function()
    NextPlayer()
end)

TargetBtn.TouchTap:Connect(function()
    NextPlayer()
end)

-- // VEHICLE LOGIC
local function GetVehicleBase()
    local char = Player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if CurrentMode == "HELI" then
        local folder = workspace:FindFirstChild("Helicopters")
        if folder then
            for _, heli in ipairs(folder:GetChildren()) do
                local seat = heli:FindFirstChild("PilotSeat", true)
                if seat and seat:IsA("VehicleSeat") then return seat end
            end
        end
    else
        if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then return hum.SeatPart end
        local vehFolder = workspace:FindFirstChild("Vehicles")
        if vehFolder then
            for _, v in ipairs(vehFolder:GetChildren()) do
                local s = v:FindFirstChildWhichIsA("VehicleSeat", true)
                if s then return s end
            end
        end
    end
    return nil
end

-- // MAIN LOOP (RGB & FLING)
RunService.PostSimulation:Connect(function()
    local hue = tick() % 5 / 5
    local rgbColor = Color3.fromHSV(hue, 1, 1)
    
    UIStroke.Color = rgbColor
    LogoStroke.Color = rgbColor

    if IsFlinging and TargetPlayer and TargetPlayer.Character then
        local seat = GetVehicleBase()
        local TChar = TargetPlayer.Character
        local TRoot = TChar:FindFirstChild("HumanoidRootPart")
        local THum = TChar:FindFirstChildOfClass("Humanoid")
        local MyChar = Player.Character

        if seat and TRoot and THum and MyChar then
            local vehicleModel = seat:FindFirstAncestorOfClass("Model") or seat.Parent
            
            if MyChar.Humanoid.SeatPart ~= seat then
                seat:Sit(MyChar.Humanoid)
            end

            Angle = Angle + 100
            local MoveDir = THum.MoveDirection * (TRoot.Velocity.Magnitude / 1.25)
            local OrbitPos = TRoot.Position + MoveDir + Vector3.new(0, 1, 0)
            local FinalCF = CFrame.new(OrbitPos) * CFrame.Angles(math.rad(Angle), math.rad(Angle), 0)
            
            if vehicleModel:IsA("Model") and vehicleModel.PrimaryPart then
                vehicleModel:SetPrimaryPartCFrame(FinalCF)
            else
                seat.CFrame = FinalCF
            end

            seat.AssemblyLinearVelocity = Vector3.new(FlingPower, FlingPower, FlingPower)
            seat.AssemblyAngularVelocity = Vector3.new(RotPower, RotPower, RotPower)

            for _, p in ipairs(vehicleModel:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                    p.Velocity = seat.AssemblyLinearVelocity
                end
            end
        end
    end
end)

ModeBtn.MouseButton1Click:Connect(function()
    CurrentMode = (CurrentMode == "HELI" and "CAR" or "HELI")
    ModeBtn.Text = "MODE: " .. CurrentMode
end)

ViewBtn.MouseButton1Click:Connect(function()
    if not TargetPlayer then 
        TargetBtn.Text = "NO TARGET!"
        return 
    end
    IsViewing = not IsViewing
    ViewBtn.Text = IsViewing and "VIEW: ON" or "VIEW: OFF"
    
    if IsViewing and TargetPlayer.Character then
        local hum = TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraSubject = hum
        end
    else
        if Player.Character then
            local hum = Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                Camera.CameraSubject = hum
            end
        end
    end
end)

FlingBtn.MouseButton1Click:Connect(function()
    if not TargetPlayer then 
        TargetBtn.Text = "NO TARGET!"
        return 
    end
    
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    IsFlinging = not IsFlinging
    
    if IsFlinging then
        if hrp then LastPosition = hrp.CFrame end
        workspace.FallenPartsDestroyHeight = 0/0 
        FlingBtn.Text = "STOP"
        FlingBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    else
        FlingBtn.Text = "LAUNCH"
        FlingBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 80)
        
        if hum and hrp and LastPosition then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hum.Sit = false
            hrp.CFrame = LastPosition
            task.wait(0.05)
            hum.Jump = true 
            LastPosition = nil
        end

        workspace.FallenPartsDestroyHeight = -500 
    end
end)

-- Untuk mobile
ModeBtn.TouchTap:Connect(function()
    CurrentMode = (CurrentMode == "HELI" and "CAR" or "HELI")
    ModeBtn.Text = "MODE: " .. CurrentMode
end)

ViewBtn.TouchTap:Connect(function()
    if not TargetPlayer then 
        TargetBtn.Text = "NO TARGET!"
        return 
    end
    IsViewing = not IsViewing
    ViewBtn.Text = IsViewing and "VIEW: ON" or "VIEW: OFF"
    
    if IsViewing and TargetPlayer.Character then
        local hum = TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraSubject = hum
        end
    else
        if Player.Character then
            local hum = Player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                Camera.CameraSubject = hum
            end
        end
    end
end)

FlingBtn.TouchTap:Connect(function()
    if not TargetPlayer then 
        TargetBtn.Text = "NO TARGET!"
        return 
    end
    
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")

    IsFlinging = not IsFlinging
    
    if IsFlinging then
        if hrp then LastPosition = hrp.CFrame end
        workspace.FallenPartsDestroyHeight = 0/0 
        FlingBtn.Text = "STOP"
        FlingBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    else
        FlingBtn.Text = "LAUNCH"
        FlingBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 80)
        
        if hum and hrp and LastPosition then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hum.Sit = false
            hrp.CFrame = LastPosition
            task.wait(0.05)
            hum.Jump = true 
            LastPosition = nil
        end

        workspace.FallenPartsDestroyHeight = -500 
    end
end)

Players.PlayerAdded:Connect(function()
    UpdatePlayerList()
    if TargetPlayer and not table.find(PlayerList, TargetPlayer) then
        SelectTargetPlayer()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    UpdatePlayerList()
    if TargetPlayer == player then
        SelectTargetPlayer()
    end
end)

UpdatePlayerList()
task.wait(0.5)
ShowTipNotification()
ShowCreditNotification()

print("AERO V2 Loaded Successfully!")
