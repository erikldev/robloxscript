--[[
    ESP + HUD para HallowenDoor (com BOTÃO de ativar/desativar)
    LocalScript em StarterPlayerScripts
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- =========================================================
-- CONFIG
-- =========================================================
local CONFIG = {
    ESPColor      = Color3.fromRGB(255, 80, 80),
    ESPFillColor  = Color3.fromRGB(255, 80, 80),
    FillTransp    = 0.85,
    ShowName      = true,
    ShowDistance  = true,
    MaxDistance   = 500,
    ToggleKey     = Enum.KeyCode.E,
}

-- =========================================================
-- HUD
-- =========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ESP_HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Painel principal
local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 240, 0, 150)
panel.Position = UDim2.new(0, 20, 0, 20)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(255, 80, 80)
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.3
panelStroke.Parent = panel

local panelGradient = Instance.new("UIGradient")
panelGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20)),
}
panelGradient.Rotation = 90
panelGradient.Parent = panel

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "🎃  ESP — HALLOWEN DOOR"
title.TextColor3 = Color3.fromRGB(255, 220, 220)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

-- Info
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 18)
info.Position = UDim2.new(0, 10, 0, 38)
info.BackgroundTransparency = 1
info.Text = "Objetos: 0  |  Tecla: E"
info.TextColor3 = Color3.fromRGB(200, 200, 210)
info.Font = Enum.Font.Gotham
info.TextSize = 12
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel

-- Linha separadora
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -20, 0, 1)
sep.Position = UDim2.new(0, 10, 0, 62)
sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sep.BackgroundTransparency = 0.85
sep.BorderSizePixel = 0
sep.Parent = panel

-- =========================================================
-- BOTÃO DE ATIVAR/DESATIVAR
-- =========================================================
local btn = Instance.new("TextButton")
btn.Name = "ToggleButton"
btn.Size = UDim2.new(1, -20, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 72)
btn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
btn.BorderSizePixel = 0
btn.AutoButtonColor = false
btn.Font = Enum.Font.GothamBold
btn.TextSize = 15
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Text = "✔  ESP ATIVADO"
btn.Parent = panel

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = btn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(255, 255, 255)
btnStroke.Thickness = 1
btnStroke.Transparency = 0.6
btnStroke.Parent = btn

-- Nome do player
local owner = Instance.new("TextLabel")
owner.Size = UDim2.new(1, -20, 0, 20)
owner.Position = UDim2.new(0, 10, 0, 120)
owner.BackgroundTransparency = 1
owner.Text = "LocalPlayer: " .. player.Name
owner.TextColor3 = Color3.fromRGB(255, 120, 120)
owner.Font = Enum.Font.GothamSemibold
owner.TextSize = 12
owner.TextXAlignment = Enum.TextXAlignment.Left
owner.Parent = panel

-- =========================================================
-- ESP
-- =========================================================
local espObjects = {}
local enabled = true

local function makeDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function createESP(instance, mainPart)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = CONFIG.ESPFillColor
    highlight.OutlineColor = CONFIG.ESPColor
    highlight.FillTransparency = CONFIG.FillTransp
    highlight.OutlineTransparency = 0
    highlight.Adornee = instance
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = gui

    local nameDrawing, distDrawing
    if CONFIG.ShowName then
        nameDrawing = makeDrawing("Text", {
            Text = instance.Name,
            Size = 14,
            Center = true,
            Outline = true,
            Color = CONFIG.ESPColor,
            Visible = false,
        })
    end
    if CONFIG.ShowDistance then
        distDrawing = makeDrawing("Text", {
            Text = "",
            Size = 12,
            Center = true,
            Outline = true,
            Color = Color3.fromRGB(255, 200, 200),
            Visible = false,
        })
    end

    return {
        highlight = highlight,
        nameDrawing = nameDrawing,
        distDrawing = distDrawing,
        mainPart = mainPart,
        instance = instance,
    }
end

local function destroyESP(data)
    if not data then return end
    if data.highlight then data.highlight:Destroy() end
    if data.nameDrawing then data.nameDrawing:Remove() end
    if data.distDrawing then data.distDrawing:Remove() end
end

local function findHallowenDoors()
    local effects = Workspace:FindFirstChild("Effects")
    if not effects then return {} end
    local result = {}
    for _, door in ipairs(effects:GetChildren()) do
        if door:IsA("Model") and door.Name == "HallowenDoor" then
            local frame = door:FindFirstChild("Frame")
            if frame and frame:IsA("Model") then
                table.insert(result, door)
            end
        end
    end
    return result
end

local function refreshList()
    local doors = findHallowenDoors()
    local current = {}

    for _, door in ipairs(doors) do
        local frame = door:FindFirstChild("Frame")
        local mainPart
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("BasePart") then
                mainPart = child
                break
            end
        end
        if mainPart then
            current[door] = mainPart
        end
    end

    for instance, data in pairs(espObjects) do
        if not current[instance] then
            destroyESP(data)
            espObjects[instance] = nil
        end
    end

    for door, mainPart in pairs(current) do
        if not espObjects[door] then
            espObjects[door] = createESP(door, mainPart)
        end
    end

    info.Text = string.format("Objetos: %d  |  Tecla: %s",
        #doors, CONFIG.ToggleKey.Name)
end

-- =========================================================
-- TOGGLE (função unificada pro botão + tecla)
-- =========================================================
local function setEnabled(state)
    enabled = state

    -- Anima cor/texto do botão
    local targetColor = enabled
        and Color3.fromRGB(60, 200, 100)
        or  Color3.fromRGB(200, 60, 60)

    TweenService:Create(btn, TweenInfo.new(0.2), {
        BackgroundColor3 = targetColor,
    }):Play()

    btn.Text = enabled and "✔  ESP ATIVADO" or "✖  ESP DESATIVADO"

    for _, data in pairs(espObjects) do
        if data.highlight then data.highlight.Enabled = enabled end
        if not enabled then
            if data.nameDrawing then data.nameDrawing.Visible = false end
            if data.distDrawing then data.distDrawing.Visible = false end
        end
    end
end

-- Clique no botão
btn.MouseButton1Click:Connect(function()
    setEnabled(not enabled)
end)

-- Hover do botão (feedback visual)
btn.MouseEnter:Connect(function()
    TweenService:Create(btn, TweenInfo.new(0.15), {
        Size = UDim2.new(1, -20, 0, 42),
    }):Play()
end)
btn.MouseLeave:Connect(function()
    TweenService:Create(btn, TweenInfo.new(0.15), {
        Size = UDim2.new(1, -20, 0, 40),
    }):Play()
end)

-- Tecla E
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CONFIG.ToggleKey then
        setEnabled(not enabled)
    end
end)

-- =========================================================
-- LOOP (posição dos textos + visibilidade)
-- =========================================================
RunService.RenderStepped:Connect(function()
    if not enabled then return end

    for door, data in pairs(espObjects) do
        local mainPart = data.mainPart
        if not mainPart or not mainPart.Parent then
            local frame = door:FindFirstChild("Frame")
            if frame then
                for _, child in ipairs(frame:GetChildren()) do
                    if child:IsA("BasePart") then
                        data.mainPart = child
                        mainPart = child
                        break
                    end
                end
            end
            continue
        end

        local pos, onScreen = camera:WorldToViewportPoint(mainPart.Position)
        local dist = (camera.CFrame.Position - mainPart.Position).Magnitude
        local visible = onScreen and dist <= CONFIG.MaxDistance

        if data.highlight then
            data.highlight.Enabled = visible
        end

        if data.nameDrawing then
            data.nameDrawing.Visible = visible and CONFIG.ShowName
            if visible then
                data.nameDrawing.Position = Vector2.new(pos.X, pos.Y - 20)
            end
        end

        if data.distDrawing then
            data.distDrawing.Visible = visible and CONFIG.ShowDistance
            if visible then
                data.distDrawing.Text = string.format("[%d studs]", math.floor(dist))
                data.distDrawing.Position = Vector2.new(pos.X, pos.Y + 4)
            end
        end
    end
end)

-- =========================================================
-- INICIALIZAÇÃO
-- =========================================================
refreshList()

local effects = Workspace:WaitForChild("Effects", 10)
if effects then
    effects.ChildAdded:Connect(function()
        task.wait(0.1)
        refreshList()
    end)
    effects.ChildRemoved:Connect(function()
        task.wait(0.1)
        refreshList()
    end)
end

task.spawn(function()
    while task.wait(3) do
        refreshList()
    end
end)
