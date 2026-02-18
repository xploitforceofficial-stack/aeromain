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

-- // LAUNCHER LOGO SETUP (Gambar baru: 101243997945630)
local LauncherGui = Instance.new("ScreenGui", (gethui and gethui()) or Player:WaitForChild("PlayerGui"))
LauncherGui.Name = "AERO_Launcher"
LauncherGui.DisplayOrder = 9999
LauncherGui.ResetOnSpawn = false

-- Variabel untuk drag functionality
local LogoDragging = false
local LogoDragStartPos
local LogoStartPos

-- Logo Button
local LogoBtn = Instance.new("ImageButton", LauncherGui)
LogoBtn.Size = UDim2.new(0, 70, 0, 70)
LogoBtn.Position = UDim2.new(0, 20, 0.5, -35)
LogoBtn.Image = "rbxassetid://101243997945630"
LogoBtn.BackgroundTransparency = 1
LogoBtn.ImageTransparency = 0.2
LogoBtn.ScaleType = Enum.ScaleType.Fit
LogoBtn.Active = true
LogoBtn.Selectable = true

-- Buat logo menjadi lingkaran
local LogoCorner = Instance.new("UICorner", LogoBtn)
LogoCorner.CornerRadius = UDim.new(1, 0)

-- UI Stroke untuk border ringan
local LogoStroke = Instance.new("UIStroke", LogoBtn)
LogoStroke.Thickness = 1
LogoStroke.Color = Color3.fromRGB(100, 100, 100)
LogoStroke.Transparency = 0.7

-- // FUNGSI DRAG LOGO
local function StartLogoDrag(input)
    LogoDragging = true
    LogoDragStartPos = input.Position
    LogoStartPos = LogoBtn.Position
    
    -- Hover effect saat drag
    LogoBtn.ImageTransparency = 0
    LogoStroke.Transparency = 0.3
end

local function EndLogoDrag()
    LogoDragging = false
    
    -- Kembalikan transparansi normal
    LogoBtn.ImageTransparency = 0.2
    LogoStroke.Transparency = 0.7
end

LogoBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        StartLogoDrag(input)
    end
end)

LogoBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        EndLogoDrag()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if LogoDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - LogoDragStartPos
        LogoBtn.Position = UDim2.new(
            LogoStartPos.X.Scale, 
            LogoStartPos.X.Offset + delta.X,
            LogoStartPos.Y.Scale, 
            LogoStartPos.Y.Offset + delta.Y
        )
    end
end)

-- Hover effect normal
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

-- // GUI SETUP
local ScreenGui = Instance.new("ScreenGui", (gethui and gethui()) or Player:WaitForChild("PlayerGui"))
ScreenGui.Name = "AERO_V1"
ScreenGui.Enabled = false  -- AWALNYA DISEMBUNYIKAN
ScreenGui.DisplayOrder = 10000
ScreenGui.ResetOnSpawn = false

-- Perbesar ukuran MainFrame untuk tombol tambahan
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 220, 0, 250)  -- Diperbesar sedikit
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BackgroundTransparency = 1  -- AWALNYA TRANSPARAN
MainFrame.Visible = false  -- AWALNYA TIDAK TERLIHAT

local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Thickness = 2
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Transparency = 1  -- AWALNYA TRANSPARAN

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "AERO V2"
Title.TextSize = 22 
Title.TextColor3 = Color3.new(1, 1, 1)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.SourceSansBold
Title.TextTransparency = 1  -- AWALNYA TRANSPARAN

local ModeBtn = Instance.new("TextButton", MainFrame)
ModeBtn.Size = UDim2.new(0.9, 0, 0, 30)
ModeBtn.Position = UDim2.new(0.05, 0, 0.16, 0)
ModeBtn.Text = "MODE: HELI"
ModeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ModeBtn.TextColor3 = Color3.new(1, 1, 1)
ModeBtn.BackgroundTransparency = 1
ModeBtn.TextTransparency = 1

-- Frame untuk tombol target dan navigasi
local TargetFrame = Instance.new("Frame", MainFrame)
TargetFrame.Size = UDim2.new(0.9, 0, 0, 40)
TargetFrame.Position = UDim2.new(0.05, 0, 0.32, 0)
TargetFrame.BackgroundTransparency = 1
TargetFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

-- Tombol Back <
local BackBtn = Instance.new("TextButton", TargetFrame)
BackBtn.Size = UDim2.new(0, 30, 1, 0)
BackBtn.Position = UDim2.new(0, 0, 0, 0)
BackBtn.Text = "<"
BackBtn.TextSize = 18
BackBtn.Font = Enum.Font.SourceSansBold
BackBtn.TextColor3 = Color3.new(1, 1, 1)
BackBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
BackBtn.BackgroundTransparency = 1
BackBtn.TextTransparency = 1

-- Tombol Target di tengah
local TargetBtn = Instance.new("TextButton", TargetFrame)
TargetBtn.Size = UDim2.new(0, 110, 1, 0)
TargetBtn.Position = UDim2.new(0.5, -55, 0, 0)
TargetBtn.Text = "SELECT TARGET"
TargetBtn.TextSize = 14
TargetBtn.TextColor3 = Color3.new(1, 1, 1)
TargetBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TargetBtn.BackgroundTransparency = 1
TargetBtn.TextTransparency = 1

-- Tombol Next >
local NextBtn = Instance.new("TextButton", TargetFrame)
NextBtn.Size = UDim2.new(0, 30, 1, 0)
NextBtn.Position = UDim2.new(1, -30, 0, 0)
NextBtn.Text = ">"
NextBtn.TextSize = 18
NextBtn.Font = Enum.Font.SourceSansBold
NextBtn.TextColor3 = Color3.new(1, 1, 1)
NextBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
NextBtn.BackgroundTransparency = 1
NextBtn.TextTransparency = 1

-- Corner untuk tombol
local backCorner = Instance.new("UICorner", BackBtn)
backCorner.CornerRadius = UDim.new(0, 5)

local targetCorner = Instance.new("UICorner", TargetBtn)
targetCorner.CornerRadius = UDim.new(0, 5)

local nextCorner = Instance.new("UICorner", NextBtn)
nextCorner.CornerRadius = UDim.new(0, 5)

local ViewBtn = Instance.new("TextButton", MainFrame)
ViewBtn.Size = UDim2.new(0.9, 0, 0, 30)
ViewBtn.Position = UDim2.new(0.05, 0, 0.52, 0)  -- Disesuaikan posisinya
ViewBtn.Text = "VIEW: OFF"
ViewBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ViewBtn.TextColor3 = Color3.new(1, 1, 1)
ViewBtn.BackgroundTransparency = 1
ViewBtn.TextTransparency = 1

local FlingBtn = Instance.new("TextButton", MainFrame)
FlingBtn.Size = UDim2.new(0.9, 0, 0, 45)
FlingBtn.Position = UDim2.new(0.05, 0, 0.74, 0)  -- Disesuaikan posisinya
FlingBtn.Text = "LAUNCH"
FlingBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 80)
FlingBtn.TextColor3 = Color3.new(1, 1, 1)
FlingBtn.BackgroundTransparency = 1
FlingBtn.TextTransparency = 1

-- Close Button (Tombol X di pojok kanan atas)
local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.Text = "X"
CloseBtn.TextSize = 18
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseBtn.BorderSizePixel = 0
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextTransparency = 1

-------------------------------------------------------------------------------
-- // FUNGSI TOGGLE GUI
-------------------------------------------------------------------------------

local function OpenGUI()
    if GuiVisible then return end
    
    GuiVisible = true
    ScreenGui.Enabled = true
    MainFrame.Visible = true
    
    -- Update player list saat GUI dibuka
    UpdatePlayerList()
    
    -- Animasi fade in
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
    
    -- Animasikan semua komponen GUI
    local components = {Title, ModeBtn, TargetFrame, BackBtn, TargetBtn, NextBtn, ViewBtn, FlingBtn, CloseBtn}
    for _, component in ipairs(components) do
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
            local tween = TweenService:Create(component, tweenInfo, targetProps)
            tween:Play()
        end
    end
end

local function CloseGUI()
    if not GuiVisible then return end
    
    -- Animasikan semua komponen GUI terlebih dahulu
    local components = {Title, ModeBtn, TargetFrame, BackBtn, TargetBtn, NextBtn, ViewBtn, FlingBtn, CloseBtn}
    for _, component in ipairs(components) do
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
            local tween = TweenService:Create(component, tweenInfo, targetProps)
            tween:Play()
        end
    end
    
    -- Kemudian animasikan frame dan stroke
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
    
    -- Tunggu animasi selesai lalu sembunyikan
    fadeOutFrame.Completed:Wait()
    
    GuiVisible = false
    MainFrame.Visible = false
    ScreenGui.Enabled = false
    
    -- Reset semua tombol ke kondisi default saat ditutup
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

-- Logo click untuk buka GUI (PERBAIKAN: Trigger saat click, bukan saat drag selesai)
LogoBtn.MouseButton1Click:Connect(function()
    -- Cek apakah ini benar-benar click, bukan drag
    if not LogoDragging then
        ToggleGUI()
    else
        -- Jika sedang drag, set flag drag ke false
        LogoDragging = false
        LogoBtn.ImageTransparency = 0.2
        LogoStroke.Transparency = 0.7
    end
end)

-- Tambahkan event untuk mendeteksi click tanpa drag
local logoClickTime = 0
LogoBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        logoClickTime = tick()
        StartLogoDrag(input)
    end
end)

LogoBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local clickDuration = tick() - logoClickTime
        EndLogoDrag()
        
        -- Jika click duration sangat singkat (< 0.2 detik), anggap sebagai click
        if clickDuration < 0.2 then
            ToggleGUI()
        end
    end
end)

-- Close button untuk tutup GUI
CloseBtn.MouseButton1Click:Connect(function()
    CloseGUI()
end)

-------------------------------------------------------------------------------
-- // FUNGSI NAVIGASI PLAYER
-------------------------------------------------------------------------------

local function SelectTargetPlayer()
    local playerCount = UpdatePlayerList()
    
    if playerCount == 0 then
        TargetPlayer = nil
        TargetBtn.Text = "NO PLAYERS"
        return false
    end
    
    -- Pastikan index tidak out of bounds
    if CurrentPlayerIndex > playerCount then
        CurrentPlayerIndex = 1
    end
    if CurrentPlayerIndex < 1 then
        CurrentPlayerIndex = playerCount
    end
    
    TargetPlayer = PlayerList[CurrentPlayerIndex]
    local displayName = TargetPlayer.Name
    
    -- Potong nama jika terlalu panjang
    if #displayName > 12 then
        displayName = displayName:sub(1, 10) .. ".."
    end
    
    TargetBtn.Text = displayName
    
    -- Update view jika sedang aktif
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
        CurrentPlayerIndex = 1  -- Kembali ke pemain pertama
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
        CurrentPlayerIndex = playerCount  -- Pindah ke pemain terakhir
    end
    
    SelectTargetPlayer()
end

-- // BUTTON ACTIONS
BackBtn.MouseButton1Click:Connect(function()
    PreviousPlayer()
end)

NextBtn.MouseButton1Click:Connect(function()
    NextPlayer()
end)

TargetBtn.MouseButton1Click:Connect(function()
    NextPlayer()
end)

-------------------------------------------------------------------------------
-- // VEHICLE LOGIC
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- // MAIN LOOP (RGB & FLING)
-------------------------------------------------------------------------------

RunService.PostSimulation:Connect(function()
    -- RGB Border untuk GUI dan Logo
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

-------------------------------------------------------------------------------
-- // BUTTON ACTIONS LAINNYA
-------------------------------------------------------------------------------

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
            -- 1. Hentikan semua gerakan fisik
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            
            -- 2. Lepas dari kursi
            hum.Sit = false
            
            -- 3. Teleport dulu baru lompat (agar posisi stabil)
            hrp.CFrame = LastPosition
            task.wait(0.05)
            hum.Jump = true 
            
            LastPosition = nil
        end

        workspace.FallenPartsDestroyHeight = -500 
    end
end)

-- Auto update player list saat ada pemain baru/keluar
Players.PlayerAdded:Connect(function()
    UpdatePlayerList()
    if TargetPlayer and not table.find(PlayerList, TargetPlayer) then
        SelectTargetPlayer()  -- Reset target jika pemain keluar
    end
end)

Players.PlayerRemoving:Connect(function(player)
    UpdatePlayerList()
    if TargetPlayer == player then
        SelectTargetPlayer()  -- Pilih pemain lain jika target keluar
    end
end)

-- Inisialisasi pertama
UpdatePlayerList()

-- Pesan debug
print("AERO V2 Loaded Successfully!")
