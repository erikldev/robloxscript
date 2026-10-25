--[[
    ESP + HUD — v34 (voo 200↑ 150↓ + auto-hold loop 1s + direção da porta)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local HAS_DRAWING = (Drawing ~= nil)

local CONFIG = {
    DoorColor     = Color3.fromRGB(255, 80, 80),
    DoorFill      = 0.95,
    DoorMaxDist   = 800,
    DoorMinDist   = 15,
    DoorName      = "HalloweenDoor",
    PlayerColor   = Color3.fromRGB(80, 180, 255),
    PlayerFill    = 0.7,
    PlayerMaxDist = 2000,
    ToggleKey     = Enum.KeyCode.E,
    ScanInterval  = 2,
    TeleportOffset = 5,
    SpeedVeryClose = 1000,
    SpeedClose     = 350,
    SpeedMedium    = 350,
    SpeedFar       = 300,
    SubirHeight   = 200,
    DescerHeight  = 150,
    UsarVoo       = true,
    ReduceHold    = true,
    HoldValue     = 0.1,
    AutoFire      = true,
    AutoHold      = true,
    AutoHoldRange = 15,
    NoclipEnabled = false,
    AntiAFK       = true,
}

-- Anti-AFK
if CONFIG.AntiAFK then
    for _, v in pairs(getconnections(player.Idled)) do
        v:Disable()
    end
    player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- Estado do grude
local grudado = false
local posGrude = nil
local lookGrude = nil
local grudeConn = nil

-- =========================================================
-- HUD BASE
-- =========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ESP_HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local reopenBtn = Instance.new("TextButton")
reopenBtn.Size = UDim2.new(0, 50, 0, 50)
reopenBtn.Position = UDim2.new(0, 10, 0, 60)
reopenBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
reopenBtn.BorderSizePixel = 0
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.TextSize = 22
reopenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
reopenBtn.Text = "🎃"
reopenBtn.Visible = false
reopenBtn.Parent = gui
local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(1, 0); rbc.Parent = reopenBtn

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 830)
panel.Position = UDim2.new(0, 10, 0, 50)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = panel
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(255, 80, 80); ps.Thickness = 1.5; ps.Transparency = 0.3; ps.Parent = panel

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 0, 26)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Text = "🎃 ESP HALLOWEEN"
title.TextColor3 = Color3.fromRGB(255, 220, 220)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -34, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✖"
closeBtn.Parent = header
local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 6); cbc.Parent = closeBtn

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 18)
info.Position = UDim2.new(0, 10, 0, 38)
info.BackgroundTransparency = 1
info.Text = "Doors: 0 | Players: 0"
info.TextColor3 = Color3.fromRGB(200, 200, 210)
info.Font = Enum.Font.Gotham
info.TextSize = 12
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel

local doorBtn = Instance.new("TextButton")
doorBtn.Size = UDim2.new(0.5, -15, 0, 30)
doorBtn.Position = UDim2.new(0, 10, 0, 62)
doorBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
doorBtn.BorderSizePixel = 0
doorBtn.Font = Enum.Font.GothamBold
doorBtn.TextSize = 11
doorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
doorBtn.Text = "DOOR: ON"
doorBtn.Parent = panel
local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0, 6); dc.Parent = doorBtn

local playerBtn = Instance.new("TextButton")
playerBtn.Size = UDim2.new(0.5, -15, 0, 30)
playerBtn.Position = UDim2.new(0.5, 5, 0, 62)
playerBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
playerBtn.BorderSizePixel = 0
playerBtn.Font = Enum.Font.GothamBold
playerBtn.TextSize = 11
playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playerBtn.Text = "PLAYER: ON"
playerBtn.Parent = panel
local plc = Instance.new("UICorner"); plc.CornerRadius = UDim.new(0, 6); plc.Parent = playerBtn

local reloadBtn = Instance.new("TextButton")
reloadBtn.Size = UDim2.new(0.5, -15, 0, 32)
reloadBtn.Position = UDim2.new(0, 10, 0, 100)
reloadBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 60)
reloadBtn.BorderSizePixel = 0
reloadBtn.Font = Enum.Font.GothamBold
reloadBtn.TextSize = 11
reloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
reloadBtn.Text = "🔄 RECARREGAR"
reloadBtn.Parent = panel
local rlc = Instance.new("UICorner"); rlc.CornerRadius = UDim.new(0, 6); rlc.Parent = reloadBtn

local grudeBtn = Instance.new("TextButton")
grudeBtn.Size = UDim2.new(0.5, -15, 0, 32)
grudeBtn.Position = UDim2.new(0.5, 5, 0, 100)
grudeBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 255)
grudeBtn.BorderSizePixel = 0
grudeBtn.Font = Enum.Font.GothamBold
grudeBtn.TextSize = 11
grudeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
grudeBtn.Text = "⚡ GRUDAR"
grudeBtn.Parent = panel
local gdc = Instance.new("UICorner"); gdc.CornerRadius = UDim.new(0, 6); gdc.Parent = grudeBtn

local trazerBtn = Instance.new("TextButton")
trazerBtn.Size = UDim2.new(0.5, -15, 0, 32)
trazerBtn.Position = UDim2.new(0, 10, 0, 138)
trazerBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
trazerBtn.BorderSizePixel = 0
trazerBtn.Font = Enum.Font.GothamBold
trazerBtn.TextSize = 11
trazerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
trazerBtn.Text = "📦 TRAZER PORTA"
trazerBtn.Parent = panel
local tzc = Instance.new("UICorner"); tzc.CornerRadius = UDim.new(0, 6); tzc.Parent = trazerBtn

local teleportarBtn = Instance.new("TextButton")
teleportarBtn.Size = UDim2.new(0.5, -15, 0, 32)
teleportarBtn.Position = UDim2.new(0.5, 5, 0, 138)
teleportarBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 150)
teleportarBtn.BorderSizePixel = 0
teleportarBtn.Font = Enum.Font.GothamBold
teleportarBtn.TextSize = 11
teleportarBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportarBtn.Text = "✈️ VOAR ATÉ"
teleportarBtn.Parent = panel
local tlc = Instance.new("UICorner"); tlc.CornerRadius = UDim.new(0, 6); tlc.Parent = teleportarBtn

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 16)
speedLabel.Position = UDim2.new(0, 10, 0, 178)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "VELOCIDADE: adaptativa"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 10
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = panel

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, -20, 0, 8)
sliderBg.Position = UDim2.new(0, 10, 0, 198)
sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = panel
local sbgC = Instance.new("UICorner"); sbgC.CornerRadius = UDim.new(1, 0); sbgC.Parent = sliderBg

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(150, 80, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
local sfc = Instance.new("UICorner"); sfc.CornerRadius = UDim.new(1, 0); sfc.Parent = sliderFill

local sliderKnob = Instance.new("Frame")
sliderKnob.Size = UDim2.new(0, 18, 0, 18)
sliderKnob.Position = UDim2.new(0.5, -9, 0.5, -9)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sliderKnob.BorderSizePixel = 0
sliderKnob.ZIndex = 2
sliderKnob.Parent = sliderBg
local skc = Instance.new("UICorner"); skc.CornerRadius = UDim.new(1, 0); skc.Parent = sliderKnob

local sliderHit = Instance.new("TextButton")
sliderHit.Size = UDim2.new(1, 0, 0, 24)
sliderHit.Position = UDim2.new(0, 0, 0.5, -12)
sliderHit.BackgroundTransparency = 1
sliderHit.Text = ""
sliderHit.ZIndex = 3
sliderHit.Parent = sliderBg

local sep1 = Instance.new("Frame")
sep1.Size = UDim2.new(1, -20, 0, 1)
sep1.Position = UDim2.new(0, 10, 0, 220)
sep1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sep1.BackgroundTransparency = 0.85
sep1.BorderSizePixel = 0
sep1.Parent = panel

local holdTitle = Instance.new("TextLabel")
holdTitle.Size = UDim2.new(1, -20, 0, 16)
holdTitle.Position = UDim2.new(0, 10, 0, 228)
holdTitle.BackgroundTransparency = 1
holdTitle.Text = "HOLD DURATION"
holdTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
holdTitle.Font = Enum.Font.GothamBold
holdTitle.TextSize = 10
holdTitle.TextXAlignment = Enum.TextXAlignment.Left
holdTitle.Parent = panel

local holdToggle = Instance.new("TextButton")
holdToggle.Size = UDim2.new(0.5, -15, 0, 28)
holdToggle.Position = UDim2.new(0, 10, 0, 248)
holdToggle.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
holdToggle.BorderSizePixel = 0
holdToggle.Font = Enum.Font.GothamBold
holdToggle.TextSize = 10
holdToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
holdToggle.Text = "HOLD: ON"
holdToggle.Parent = panel
local htcc = Instance.new("UICorner"); htcc.CornerRadius = UDim.new(0, 6); htcc.Parent = holdToggle

local holdInput = Instance.new("TextBox")
holdInput.Size = UDim2.new(0.5, -15, 0, 28)
holdInput.Position = UDim2.new(0.5, 5, 0, 248)
holdInput.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
holdInput.BorderSizePixel = 0
holdInput.Font = Enum.Font.GothamBold
holdInput.TextSize = 11
holdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
holdInput.Text = tostring(CONFIG.HoldValue)
holdInput.Parent = panel
local hic = Instance.new("UICorner"); hic.CornerRadius = UDim.new(0, 6); hic.Parent = holdInput

local holdStroke = Instance.new("UIStroke")
holdStroke.Color = Color3.fromRGB(150, 80, 255)
holdStroke.Thickness = 1
holdStroke.Transparency = 0.5
holdStroke.Parent = holdInput

local sep2 = Instance.new("Frame")
sep2.Size = UDim2.new(1, -20, 0, 1)
sep2.Position = UDim2.new(0, 10, 0, 286)
sep2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sep2.BackgroundTransparency = 0.85
sep2.BorderSizePixel = 0
sep2.Parent = panel

local autoHoldToggle = Instance.new("TextButton")
autoHoldToggle.Size = UDim2.new(1, -20, 0, 28)
autoHoldToggle.Position = UDim2.new(0, 10, 0, 294)
autoHoldToggle.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
autoHoldToggle.BorderSizePixel = 0
autoHoldToggle.Font = Enum.Font.GothamBold
autoHoldToggle.TextSize = 10
autoHoldToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoHoldToggle.Text = "AUTO-HOLD: ON (loop 1s)"
autoHoldToggle.Parent = panel
local ahc = Instance.new("UICorner"); ahc.CornerRadius = UDim.new(0, 6); ahc.Parent = autoHoldToggle

local noclipToggle = Instance.new("TextButton")
noclipToggle.Size = UDim2.new(1, -20, 0, 28)
noclipToggle.Position = UDim2.new(0, 10, 0, 330)
noclipToggle.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
noclipToggle.BorderSizePixel = 0
noclipToggle.Font = Enum.Font.GothamBold
noclipToggle.TextSize = 10
noclipToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipToggle.Text = "NOCLIP: OFF"
noclipToggle.Parent = panel
local ncc = Instance.new("UICorner"); ncc.CornerRadius = UDim.new(0, 6); ncc.Parent = noclipToggle

local autoFireToggle = Instance.new("TextButton")
autoFireToggle.Size = UDim2.new(1, -20, 0, 28)
autoFireToggle.Position = UDim2.new(0, 10, 0, 366)
autoFireToggle.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
autoFireToggle.BorderSizePixel = 0
autoFireToggle.Font = Enum.Font.GothamBold
autoFireToggle.TextSize = 10
autoFireToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoFireToggle.Text = "AUTO-FIRE: ON"
autoFireToggle.Parent = panel
local afc = Instance.new("UICorner"); afc.CornerRadius = UDim.new(0, 6); afc.Parent = autoFireToggle

local vooToggle = Instance.new("TextButton")
vooToggle.Size = UDim2.new(1, -20, 0, 28)
vooToggle.Position = UDim2.new(0, 10, 0, 402)
vooToggle.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
vooToggle.BorderSizePixel = 0
vooToggle.Font = Enum.Font.GothamBold
vooToggle.TextSize = 10
vooToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
vooToggle.Text = "VOO (200↑ 150↓): ON"
vooToggle.Parent = panel
local vtc = Instance.new("UICorner"); vtc.CornerRadius = UDim.new(0, 6); vtc.Parent = vooToggle

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 18)
status.Position = UDim2.new(0, 10, 0, 440)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(150, 255, 150)
status.Font = Enum.Font.GothamSemibold
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

-- ✅ Label de direção da porta
local dirLabel = Instance.new("TextLabel")
dirLabel.Size = UDim2.new(1, -20, 0, 16)
dirLabel.Position = UDim2.new(0, 10, 0, 462)
dirLabel.BackgroundTransparency = 1
dirLabel.Text = "🧭 Direção: —"
dirLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
dirLabel.Font = Enum.Font.GothamBold
dirLabel.TextSize = 11
dirLabel.TextXAlignment = Enum.TextXAlignment.Left
dirLabel.Parent = panel

-- =========================================================
-- FUNÇÕES GRUDE
-- =========================================================
local function soltar()
    grudado = false
    posGrude = nil
    lookGrude = nil
    if grudeConn then
        grudeConn:Disconnect()
        grudeConn = nil
    end
    grudeBtn.Text = "⚡ GRUDAR"
    TweenService:Create(grudeBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(150, 80, 255)
    }):Play()
end

local function grudar(char, pos, lookAt)
    soltar()
    grudado = true
    posGrude = pos
    lookGrude = lookAt
    grudeBtn.Text = "🔓 SOLTAR"
    TweenService:Create(grudeBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = Color3.fromRGB(60, 200, 100)
    }):Play()

    grudeConn = RunService.Heartbeat:Connect(function()
        if not grudado then return end
        local c = player.Character
        if not c or not c.Parent then return end
        pcall(function()
            c:PivotTo(CFrame.new(posGrude, lookGrude))
        end)
    end)

    status.Text = "🔒 Grudado!"
    status.TextColor3 = Color3.fromRGB(150, 255, 150)
end

-- =========================================================
-- DIREÇÃO DA PORTA
-- =========================================================
local function getDirecaoPorta(doorPart)
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not doorPart then return "—" end

    local myPos = hrp.Position
    local doorPos = doorPart.Position
    local diff = Vector3.new(doorPos.X - myPos.X, 0, doorPos.Z - myPos.Z)
    if diff.Magnitude < 0.1 then return "AQUI" end
    diff = diff.Unit

    local look = hrp.CFrame.LookVector
    local lookFlat = Vector3.new(look.X, 0, look.Z).Unit
    local right = hrp.CFrame.RightVector
    local rightFlat = Vector3.new(right.X, 0, right.Z).Unit

    local dotFrente = lookFlat:Dot(diff)
    local dotLado = rightFlat:Dot(diff)
    local angulo = math.deg(math.acos(math.clamp(dotFrente, -1, 1)))

    local direcao = ""
    if dotFrente > 0.7 then direcao = "FRENTE"
    elseif dotFrente < -0.7 then direcao = "ATRÁS"
    elseif dotLado > 0.7 then direcao = "DIREITA"
    elseif dotLado < -0.7 then direcao = "ESQUERDA"
    elseif dotFrente > 0 and dotLado > 0 then direcao = "FRENTE-DIREITA"
    elseif dotFrente > 0 and dotLado < 0 then direcao = "FRENTE-ESQUERDA"
    elseif dotFrente < 0 and dotLado > 0 then direcao = "ATRÁS-DIREITA"
    elseif dotFrente < 0 and dotLado < 0 then direcao = "ATRÁS-ESQUERDA"
    else direcao = "?" end

    local dist = (doorPos - myPos).Magnitude
    return string.format("%s (%.0f° | %.0f studs)", direcao, angulo, dist)
end

-- =========================================================
-- NOCLIP
-- =========================================================
local noclipConn = nil

local function aplicarNoclip()
    if noclipConn then noclipConn:Disconnect() end
    if CONFIG.NoclipEnabled then
        noclipConn = RunService.Stepped:Connect(function()
            local c = player.Character
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    else
        local c = player.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and not p.CanCollide then
                    pcall(function() p.CanCollide = true end)
                end
            end
        end
    end
end

noclipToggle.MouseButton1Click:Connect(function()
    CONFIG.NoclipEnabled = not CONFIG.NoclipEnabled
    noclipToggle.Text = CONFIG.NoclipEnabled and "NOCLIP: ON" or "NOCLIP: OFF"
    TweenService:Create(noclipToggle, TweenInfo.new(0.2), {
        BackgroundColor3 = CONFIG.NoclipEnabled and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(200, 60, 60)
    }):Play()
    aplicarNoclip()
end)

-- =========================================================
-- AUTO HOLD (loop 1s, tenta até coletar)
-- =========================================================
local autoHoldThread = nil

local function iniciarAutoHold()
    if autoHoldThread then
        pcall(function() task.cancel(autoHoldThread) end)
        autoHoldThread = nil
    end
    if not CONFIG.AutoHold then return end

    autoHoldThread = task.spawn(function()
        while CONFIG.AutoHold do
            task.wait(1)
            if not CONFIG.AutoHold then break end

            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, d in ipairs(Workspace:GetDescendants()) do
                    if d:IsA("ProximityPrompt") then
                        local pai = d
                        local porta = nil
                        local estaNaPorta = false
                        for _ = 1, 10 do
                            pai = pai.Parent
                            if not pai then break end
                            if pai.Name == CONFIG.DoorName then
                                estaNaPorta = true
                                porta = pai
                                break
                            end
                        end

                        if estaNaPorta and porta and porta.Parent then
                            local promptPart = d.Parent
                            if promptPart and promptPart:IsA("BasePart") then
                                local dist = (hrp.Position - promptPart.Position).Magnitude
                                if dist <= CONFIG.AutoHoldRange then
                                    if fireproximityprompt then
                                        pcall(function() fireproximityprompt(d) end)
                                    else
                                        pcall(function()
                                            d:InputHoldBegin()
                                            task.wait(0.05)
                                            d:InputHoldEnd()
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

autoHoldToggle.MouseButton1Click:Connect(function()
    CONFIG.AutoHold = not CONFIG.AutoHold
    autoHoldToggle.Text = CONFIG.AutoHold and "AUTO-HOLD: ON (loop 1s)" or "AUTO-HOLD: OFF"
    TweenService:Create(autoHoldToggle, TweenInfo.new(0.2), {
        BackgroundColor3 = CONFIG.AutoHold and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(200, 60, 60)
    }):Play()
    if CONFIG.AutoHold then
        iniciarAutoHold()
    else
        if autoHoldThread then
            pcall(function() task.cancel(autoHoldThread) end)
            autoHoldThread = nil
        end
    end
end)

-- =========================================================
-- HOLD LOGIC
-- =========================================================
local holdMonitors = {}

local function aplicarHoldEmPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    if CONFIG.ReduceHold then
        pcall(function() prompt.HoldDuration = CONFIG.HoldValue end)
    end
end

local function aplicarHold()
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local pai = d
            local estaNaPorta = false
            for _ = 1, 10 do
                pai = pai.Parent
                if not pai then break end
                if pai.Name == CONFIG.DoorName then
                    estaNaPorta = true
                    break
                end
            end

            if estaNaPorta then
                aplicarHoldEmPrompt(d)
                if not holdMonitors[d] then
                    holdMonitors[d] = true
                    d:GetPropertyChangedSignal("HoldDuration"):Connect(function()
                        if CONFIG.ReduceHold and d.HoldDuration ~= CONFIG.HoldValue then
                            task.wait(0.05)
                            pcall(function()
                                d.HoldDuration = CONFIG.HoldValue
                            end)
                        end
                    end)
                end
            end
        end
    end
end

holdToggle.MouseButton1Click:Connect(function()
    CONFIG.ReduceHold = not CONFIG.ReduceHold
    holdToggle.Text = CONFIG.ReduceHold and "HOLD: ON" or "HOLD: OFF"
    TweenService:Create(holdToggle, TweenInfo.new(0.2), {
        BackgroundColor3 = CONFIG.ReduceHold and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(200, 60, 60)
    }):Play()
    if CONFIG.ReduceHold then aplicarHold() end
end)

holdInput.FocusLost:Connect(function()
    local valor = tonumber(holdInput.Text)
    if valor and valor >= 0 and valor <= 10 then
        CONFIG.HoldValue = valor
        if CONFIG.ReduceHold then
            for prompt in pairs(holdMonitors) do
                aplicarHoldEmPrompt(prompt)
            end
        end
    else
        holdInput.Text = tostring(CONFIG.HoldValue)
    end
end)

autoFireToggle.MouseButton1Click:Connect(function()
    CONFIG.AutoFire = not CONFIG.AutoFire
    autoFireToggle.Text = CONFIG.AutoFire and "AUTO-FIRE: ON" or "AUTO-FIRE: OFF"
    TweenService:Create(autoFireToggle, TweenInfo.new(0.2), {
        BackgroundColor3 = CONFIG.AutoFire and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(200, 60, 60)
    }):Play()
end)

vooToggle.MouseButton1Click:Connect(function()
    CONFIG.UsarVoo = not CONFIG.UsarVoo
    vooToggle.Text = CONFIG.UsarVoo and "VOO (200↑ 150↓): ON" or "VOO (200↑ 150↓): OFF"
    TweenService:Create(vooToggle, TweenInfo.new(0.2), {
        BackgroundColor3 = CONFIG.UsarVoo and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(200, 60, 60)
    }):Play()
end)

-- =========================================================
-- SLIDER
-- =========================================================
local function setSpeedFromRel(rel)
    rel = math.clamp(rel, 0, 1)
    local mult = 0.2 + rel * 1.8
    CONFIG.SpeedClose = 350 * mult
    CONFIG.SpeedMedium = 350 * mult
    CONFIG.SpeedFar = 300 * mult
    sliderFill.Size = UDim2.new(rel, 0, 1, 0)
    sliderKnob.Position = UDim2.new(rel, -9, 0.5, -9)
    speedLabel.Text = string.format("VELOCIDADE: %d studs/s", math.floor(CONFIG.SpeedFar))
end

local function updateFromX(mouseX)
    local barAbsX = sliderBg.AbsolutePosition.X
    local barW = sliderBg.AbsoluteSize.X
    if barW <= 0 then return end
    setSpeedFromRel((mouseX - barAbsX) / barW)
end

local draggingSlider = false

sliderHit.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateFromX(input.Position.X)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        updateFromX(input.Position.X)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

setSpeedFromRel(0.5)

-- =========================================================
-- DRAG PAINEL
-- =========================================================
local dragging, dragStart, startPos = false, nil, nil

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- =========================================================
-- TEXTO
-- =========================================================
local function makeText(text, color, size)
    if HAS_DRAWING then
        local d = Drawing.new("Text")
        d.Text = text; d.Size = size or 14; d.Center = true
        d.Outline = true; d.Color = color; d.Visible = false
        return {
            kind = "drawing", obj = d,
            setVisible = function(v) d.Visible = v end,
            setPosition = function(v2) d.Position = v2 end,
            setText = function(t) d.Text = t end,
            remove = function() d:Remove() end,
        }
    else
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 120, 0, 30)
        bb.AlwaysOnTop = true
        bb.Enabled = false
        bb.Parent = gui
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text; lbl.TextColor3 = color
        lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold
        lbl.TextStrokeTransparency = 0.3; lbl.Parent = bb
        return {
            kind = "billboard", obj = bb,
            setVisible = function(v) bb.Enabled = v end,
            setPosition = function(v2) end,
            setAdornee = function(part) bb.Adornee = part end,
            setText = function(t) lbl.Text = t end,
            remove = function() bb:Destroy() end,
        }
    end
end

-- =========================================================
-- PLAYER ESP
-- =========================================================
local playerESPs = {}
local playerEnabled = true

local function createPlayerESP(target)
    local hl = Instance.new("Highlight")
    hl.FillColor = CONFIG.PlayerColor
    hl.OutlineColor = CONFIG.PlayerColor
    hl.FillTransparency = CONFIG.PlayerFill
    hl.OutlineTransparency = 0
    hl.Adornee = target.Character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = gui
    local nameT = makeText(target.Name, CONFIG.PlayerColor, 14)
    local distT = makeText("", Color3.fromRGB(180, 220, 255), 12)
    return { highlight = hl, nameT = nameT, distT = distT, target = target }
end

local function destroyPlayerESP(d)
    if d.highlight then d.highlight:Destroy() end
    if d.nameT then d.nameT.remove() end
    if d.distT then d.distT.remove() end
end

local function refreshPlayers()
    for pl, d in pairs(playerESPs) do
        if not pl.Parent or not pl.Character then
            destroyPlayerESP(d); playerESPs[pl] = nil
        else
            d.highlight.Adornee = pl.Character
        end
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player and pl.Character and not playerESPs[pl] then
            playerESPs[pl] = createPlayerESP(pl)
        end
    end
end

-- =========================================================
-- DOOR ESP
-- =========================================================
local doorESPs = {}
local doorEnabled = true
local doorCount = 0

local function findFirstPart(obj)
    if obj:IsA("BasePart") then return obj end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function createDoorESP(model, mainPart)
    local hl = Instance.new("Highlight")
    hl.FillColor = CONFIG.DoorColor
    hl.OutlineColor = CONFIG.DoorColor
    hl.FillTransparency = CONFIG.DoorFill
    hl.OutlineTransparency = 0
    hl.Adornee = model
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = gui
    local nameT = makeText(model.Name, CONFIG.DoorColor, 14)
    local distT = makeText("", Color3.fromRGB(255, 200, 200), 12)
    if nameT.kind == "billboard" then
        nameT.setAdornee(mainPart)
        distT.setAdornee(mainPart)
    end
    return { highlight = hl, nameT = nameT, distT = distT,
             mainPart = mainPart, model = model }
end

local function destroyDoorESP(d)
    if d.highlight then d.highlight:Destroy() end
    if d.nameT then d.nameT.remove() end
    if d.distT then d.distT.remove() end
end

local function scanDoors()
    local found = {}
    local visited = {}
    local function walk(obj, depth)
        if depth > 8 or visited[obj] then return end
        visited[obj] = true
        for _, k in ipairs(obj:GetChildren()) do
            if k.Name == CONFIG.DoorName then
                local part = findFirstPart(k)
                if part then
                    table.insert(found, {model = k, part = part})
                end
            end
            if k:IsA("Model") or k:IsA("Folder") then
                pcall(walk, k, depth + 1)
            end
        end
    end
    walk(Workspace, 0)
    return found
end

local function refreshDoors()
    local found = scanDoors()
    local current = {}
    for _, e in ipairs(found) do current[e.model] = e.part end

    for model, d in pairs(doorESPs) do
        if not current[model] then
            destroyDoorESP(d); doorESPs[model] = nil
        end
    end
    for model, part in pairs(current) do
        if not doorESPs[model] then
            doorESPs[model] = createDoorESP(model, part)
        end
    end
    doorCount = #found
end

-- =========================================================
-- GET NEAREST DOOR (definida ANTES do loop)
-- =========================================================
local function getNearestDoor()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local myPos = hrp.Position
    local nearest, nearestDist = nil, math.huge
    for model, d in pairs(doorESPs) do
        local part = d.mainPart
        if part and part.Parent then
            local dist = (part.Position - myPos).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = {model = model, part = part, dist = dist}
            end
        end
    end
    return nearest
end

-- =========================================================
-- LOOP (ESP + direção)
-- =========================================================
RunService.RenderStepped:Connect(function()
    if playerEnabled then
        for pl, d in pairs(playerESPs) do
            local char = pl.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                d.highlight.Adornee = char
                d.highlight.Enabled = true
                local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                local dist = (camera.CFrame.Position - hrp.Position).Magnitude
                local vis = onScreen and dist <= CONFIG.PlayerMaxDist
                d.nameT.setVisible(vis); d.distT.setVisible(vis)
                if vis then
                    if d.nameT.kind == "drawing" then
                        d.nameT.setPosition(Vector2.new(pos.X, pos.Y - 30))
                        d.distT.setPosition(Vector2.new(pos.X, pos.Y + 4))
                    end
                    d.distT.setText(string.format("[%d]", math.floor(dist)))
                end
            else
                d.highlight.Enabled = false
                d.nameT.setVisible(false); d.distT.setVisible(false)
            end
        end
    end

    if doorEnabled then
        local myPos = camera.CFrame.Position
        for model, d in pairs(doorESPs) do
            local part = d.mainPart
            if part and part.Parent then
                d.highlight.Adornee = model
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                local dist = (myPos - part.Position).Magnitude
                local vis = onScreen
                    and dist <= CONFIG.DoorMaxDist
                    and dist >= CONFIG.DoorMinDist
                d.highlight.Enabled = vis
                d.nameT.setVisible(vis); d.distT.setVisible(vis)
                if vis then
                    if d.nameT.kind == "drawing" then
                        d.nameT.setPosition(Vector2.new(pos.X, pos.Y - 20))
                        d.distT.setPosition(Vector2.new(pos.X, pos.Y + 4))
                    end
                    d.distT.setText(string.format("[%d]", math.floor(dist)))
                end
            end
        end
    end
end)

-- =========================================================
-- LOOP DE DIREÇÃO (separado, 5x/seg)
-- =========================================================
task.spawn(function()
    while task.wait(0.2) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local nearest = getNearestDoor()
            if nearest and nearest.part then
                dirLabel.Text = "🧭 Direção: " .. getDirecaoPorta(nearest.part)
                dirLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
            else
                dirLabel.Text = "🧭 Direção: — (sem porta)"
                dirLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
            end
        end
    end
end)

-- =========================================================
-- TOGGLES
-- =========================================================
local function updateInfo()
    info.Text = string.format("Doors: %d | Players: %d",
        doorCount, math.max(0, #Players:GetPlayers() - 1))
end

local function setDoorEnabled(state)
    doorEnabled = state
    doorBtn.Text = doorEnabled and "DOOR: ON" or "DOOR: OFF"
    TweenService:Create(doorBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = doorEnabled and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(200, 60, 60)
    }):Play()
    if not doorEnabled then
        for _, d in pairs(doorESPs) do
            d.highlight.Enabled = false
            d.nameT.setVisible(false)
            d.distT.setVisible(false)
        end
    end
end

local function setPlayerEnabled(state)
    playerEnabled = state
    playerBtn.Text = playerEnabled and "PLAYER: ON" or "PLAYER: OFF"
    TweenService:Create(playerBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = playerEnabled and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(200, 60, 60)
    }):Play()
    if not playerEnabled then
        for _, d in pairs(playerESPs) do
            d.highlight.Enabled = false
            d.nameT.setVisible(false)
            d.distT.setVisible(false)
        end
    end
end

reloadBtn.MouseButton1Click:Connect(function()
    refreshDoors(); refreshPlayers(); updateInfo()
    aplicarHold()
    status.Text = "🔄 Recarregado"
    status.TextColor3 = Color3.fromRGB(150, 255, 150)
    task.delay(2, function() status.Text = "" end)
end)

doorBtn.MouseButton1Click:Connect(function() setDoorEnabled(not doorEnabled) end)
playerBtn.MouseButton1Click:Connect(function() setPlayerEnabled(not playerEnabled) end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CONFIG.ToggleKey then setDoorEnabled(not doorEnabled) end
end)

-- =========================================================
-- TELEPORTE
-- =========================================================
local function getPromptFromDoor(doorModel)
    for _, d in ipairs(doorModel:GetDescendants()) do
        if d:IsA("ProximityPrompt") then return d end
    end
    return nil
end

local function calcularVelocidade(distancia)
    if distancia < 10 then return CONFIG.SpeedVeryClose
    elseif distancia < 170 then return CONFIG.SpeedClose
    elseif distancia < 1000 then return CONFIG.SpeedMedium
    else return CONFIG.SpeedFar end
end

local function tweenPara(hrp, destino, lookAt)
    local distancia = (destino - hrp.Position).Magnitude
    if distancia < 0.1 then return end
    local velocidade = calcularVelocidade(distancia)
    local duracao = distancia / velocidade

    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duracao, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(destino, lookAt)}
    )
    tween:Play()
    tween.Completed:Wait()
end

local function voarAte(hrp, finalPos, lookAt)
    local startPos = hrp.Position
    local alturaSubir = startPos.Y + CONFIG.SubirHeight
    local alturaDescer = finalPos.Y + CONFIG.DescerHeight

    local p1 = Vector3.new(startPos.X, alturaSubir, startPos.Z)
    local p2 = Vector3.new(finalPos.X, alturaSubir, finalPos.Z)
    local p3 = Vector3.new(finalPos.X, alturaDescer, finalPos.Z)
    local p4 = finalPos

    tweenPara(hrp, p1, lookAt)
    tweenPara(hrp, p2, lookAt)
    tweenPara(hrp, p3, lookAt)
    tweenPara(hrp, p4, lookAt)
end

local tpRunning = false

grudeBtn.MouseButton1Click:Connect(function()
    if grudado then
        soltar()
        status.Text = "🔓 Solto"
        status.TextColor3 = Color3.fromRGB(255, 180, 100)
        task.delay(2, function() status.Text = "" end)
        return
    end

    if tpRunning then return end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local nearest = getNearestDoor()
    if not nearest then
        status.Text = "❌ Nenhuma porta"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.delay(2, function() status.Text = "" end)
        return
    end

    local doorPos = nearest.part.Position
    local direction = (hrp.Position - doorPos).Unit
    if direction.Magnitude < 0.1 then direction = Vector3.new(0, 0, 1) end

    local finalPos = doorPos + direction * CONFIG.TeleportOffset
    finalPos = Vector3.new(finalPos.X, doorPos.Y, finalPos.Z)
    local lookAt = Vector3.new(doorPos.X, finalPos.Y, doorPos.Z)

    tpRunning = true
    grudeBtn.Active = false
    grudeBtn.Text = "⏳ ..."

    task.spawn(function()
        if CONFIG.UsarVoo then
            status.Text = "✈️ Voando (200↑ 150↓)..."
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            voarAte(hrp, finalPos, lookAt)
        else
            status.Text = "⚡ Voando direto..."
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            tweenPara(hrp, finalPos, lookAt)
        end

        if CONFIG.ReduceHold then aplicarHold() end
        grudar(char, finalPos, lookAt)

        if CONFIG.AutoFire then
            local prompt = getPromptFromDoor(nearest.model)
            if prompt then
                if CONFIG.ReduceHold then
                    pcall(function() prompt.HoldDuration = CONFIG.HoldValue end)
                end
                if fireproximityprompt then
                    pcall(function() fireproximityprompt(prompt) end)
                else
                    pcall(function()
                        prompt:InputHoldBegin()
                        prompt:InputHoldEnd()
                    end)
                end
            end
        end

        status.Text = "🔥 Grudado + ativado!"
        status.TextColor3 = Color3.fromRGB(150, 255, 150)
        grudeBtn.Active = true
        grudeBtn.Text = "🔓 SOLTAR"
        tpRunning = false
    end)
end)

trazerBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local nearest = getNearestDoor()
    if not nearest then
        status.Text = "❌ Nenhuma porta"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.delay(2, function() status.Text = "" end)
        return
    end

    local myPos = hrp.Position
    local myLook = hrp.CFrame.LookVector
    local novaPos = myPos + myLook * CONFIG.TeleportOffset + Vector3.new(0, 1, 0)
    local posOriginal = nearest.part.Position

    pcall(function()
        nearest.model:PivotTo(CFrame.new(novaPos, myPos))
    end)

    status.Text = "📦 Tentando trazer porta..."
    status.TextColor3 = Color3.fromRGB(255, 200, 100)

    task.wait(0.4)

    local dist = (nearest.part.Position - myPos).Magnitude
    if dist > 15 then
        status.Text = "⚠️ Porta voltou. Voando até ela..."
        status.TextColor3 = Color3.fromRGB(255, 180, 100)

        local direction = (hrp.Position - posOriginal).Unit
        if direction.Magnitude < 0.1 then direction = Vector3.new(0, 0, 1) end
        local finalPos = posOriginal + direction * CONFIG.TeleportOffset
        finalPos = Vector3.new(finalPos.X, posOriginal.Y, finalPos.Z)
        local lookAt = Vector3.new(posOriginal.X, finalPos.Y, posOriginal.Z)

        voarAte(hrp, finalPos, lookAt)
        grudar(char, finalPos, lookAt)

        if CONFIG.AutoFire then
            local prompt = getPromptFromDoor(nearest.model)
            if prompt and fireproximityprompt then
                pcall(function() fireproximityprompt(prompt) end)
            end
        end

        status.Text = "⚡ Voou até a porta + ativou"
        status.TextColor3 = Color3.fromRGB(150, 255, 150)
    else
        status.Text = "✅ Porta trouxe até você!"
        status.TextColor3 = Color3.fromRGB(150, 255, 150)
    end
    task.delay(3, function() status.Text = "" end)
end)

teleportarBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local nearest = getNearestDoor()
    if not nearest then
        status.Text = "❌ Nenhuma porta"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.delay(2, function() status.Text = "" end)
        return
    end

    local doorPos = nearest.part.Position
    local direction = (hrp.Position - doorPos).Unit
    if direction.Magnitude < 0.1 then direction = Vector3.new(0, 0, 1) end
    local finalPos = doorPos + direction * CONFIG.TeleportOffset
    finalPos = Vector3.new(finalPos.X, doorPos.Y, finalPos.Z)
    local lookAt = Vector3.new(doorPos.X, finalPos.Y, doorPos.Z)

    status.Text = "✈️ Voando (200↑ 150↓)..."
    status.TextColor3 = Color3.fromRGB(255, 200, 100)

    voarAte(hrp, finalPos, lookAt)

    if CONFIG.ReduceHold then aplicarHold() end
    if CONFIG.AutoFire then
        local prompt = getPromptFromDoor(nearest.model)
        if prompt and fireproximityprompt then
            pcall(function() fireproximityprompt(prompt) end)
        end
    end

    status.Text = "✅ Chegou + ativou"
    status.TextColor3 = Color3.fromRGB(150, 255, 150)
    task.delay(2, function() status.Text = "" end)
end)

-- =========================================================
-- FECHAR / REABRIR
-- =========================================================
closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
    reopenBtn.Visible = true
    reopenBtn.Position = panel.Position
end)

reopenBtn.MouseButton1Click:Connect(function()
    panel.Visible = true
    reopenBtn.Visible = false
end)

-- =========================================================
-- INIT
-- =========================================================
refreshPlayers()
refreshDoors()
updateInfo()
aplicarHold()

if CONFIG.AutoHold then iniciarAutoHold() end
if CONFIG.NoclipEnabled then aplicarNoclip() end

task.spawn(function()
    while task.wait(CONFIG.ScanInterval) do
        refreshPlayers()
        refreshDoors()
        updateInfo()
        if CONFIG.ReduceHold then
            aplicarHold()
        end
    end
end)
