--[[
    ESP + HUD com Logs e Recarregar
    - ESP Players (teste)
    - ESP HallowenDoor (com diagnóstico)
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
    -- HallowenDoor
    DoorColor     = Color3.fromRGB(255, 80, 80),
    DoorFill      = 0.85,
    DoorMaxDist   = 1000,
    -- Players
    PlayerColor   = Color3.fromRGB(80, 180, 255),
    PlayerFill    = 0.7,
    PlayerMaxDist = 1000,
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

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 340, 0, 460)
panel.Position = UDim2.new(0, 20, 0, 20)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
panel.BackgroundTransparency = 0.1
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

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "🎃  ESP + LOGS"
title.TextColor3 = Color3.fromRGB(255, 220, 220)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

-- Botão Recarregar
local reloadBtn = Instance.new("TextButton")
reloadBtn.Size = UDim2.new(0, 100, 0, 26)
reloadBtn.Position = UDim2.new(1, -110, 0, 9)
reloadBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 60)
reloadBtn.BorderSizePixel = 0
reloadBtn.Font = Enum.Font.GothamBold
reloadBtn.TextSize = 12
reloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
reloadBtn.Text = "🔄 RECARREGAR"
reloadBtn.Parent = panel
local rc = Instance.new("UICorner")
rc.CornerRadius = UDim.new(0, 6)
rc.Parent = reloadBtn

-- Linha 1: contadores
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 18)
info.Position = UDim2.new(0, 10, 0, 40)
info.BackgroundTransparency = 1
info.Text = "Doors: 0 | Players: 0"
info.TextColor3 = Color3.fromRGB(200, 200, 210)
info.Font = Enum.Font.Gotham
info.TextSize = 12
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel

-- Botões de toggle separados
local doorBtn = Instance.new("TextButton")
doorBtn.Size = UDim2.new(0.5, -15, 0, 32)
doorBtn.Position = UDim2.new(0, 10, 0, 62)
doorBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
doorBtn.BorderSizePixel = 0
doorBtn.Font = Enum.Font.GothamBold
doorBtn.TextSize = 12
doorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
doorBtn.Text = "DOOR: ON"
doorBtn.Parent = panel
Instance.new("UICorner", doorBtn).CornerRadius = UDim.new(0, 6)

local playerBtn = Instance.new("TextButton")
playerBtn.Size = UDim2.new(0.5, -15, 0, 32)
playerBtn.Position = UDim2.new(0.5, 5, 0, 62)
playerBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
playerBtn.BorderSizePixel = 0
playerBtn.Font = Enum.Font.GothamBold
playerBtn.TextSize = 12
playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playerBtn.Text = "PLAYER: ON"
playerBtn.Parent = panel
Instance.new("UICorner", playerBtn).CornerRadius = UDim.new(0, 6)

-- Separador
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -20, 0, 1)
sep.Position = UDim2.new(0, 10, 0, 102)
sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sep.BackgroundTransparency = 0.8
sep.BorderSizePixel = 0
sep.Parent = panel

-- Logs (ScrollingFrame)
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -20, 0, 16)
logLabel.Position = UDim2.new(0, 10, 0, 108)
logLabel.BackgroundTransparency = 1
logLabel.Text = "📋 LOGS:"
logLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
logLabel.Font = Enum.Font.GothamBold
logLabel.TextSize = 11
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.Parent = panel

local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(1, -20, 0, 320)
logFrame.Position = UDim2.new(0, 10, 0, 126)
logFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 6
logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
logFrame.Parent = panel
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 6)

local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 2)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Parent = logFrame

local logPadding = Instance.new("UIPadding")
logPadding.PaddingLeft = UDim.new(0, 6)
logPadding.PaddingTop = UDim.new(0, 4)
logPadding.PaddingRight = UDim.new(0, 6)
logPadding.Parent = logFrame

local logCount = 0
local function log(msg, color)
    logCount += 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = "▸ " .. tostring(msg)
    lbl.TextColor3 = color or Color3.fromRGB(200, 220, 200)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.LayoutOrder = logCount
    lbl.Parent = logFrame
    logFrame.CanvasPosition = Vector2.new(0, logLayout.AbsoluteContentSize.Y)
end

-- =========================================================
-- ESP DRAWINGS
-- =========================================================
local function makeDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
end

-- =========================================================
-- ESP PLAYERS (teste)
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

    local nameD = makeDrawing("Text", {
        Text = target.Name, Size = 14, Center = true,
        Outline = true, Color = CONFIG.PlayerColor, Visible = false,
    })
    local distD = makeDrawing("Text", {
        Text = "", Size = 12, Center = true,
        Outline = true, Color = Color3.fromRGB(180, 220, 255), Visible = false,
    })

    return { highlight = hl, nameDrawing = nameD, distDrawing = distD, target = target }
end

local function destroyPlayerESP(d)
    if d.highlight then d.highlight:Destroy() end
    if d.nameDrawing then d.nameDrawing:Remove() end
    if d.distDrawing then d.distDrawing:Remove() end
end

local function refreshPlayers()
    for p, d in pairs(playerESPs) do
        if not p.Parent or not p.Character then
            destroyPlayerESP(d)
            playerESPs[p] = nil
        else
            d.highlight.Adornee = p.Character
        end
    end
    local count = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            count += 1
            if not playerESPs[p] then
                playerESPs[p] = createPlayerESP(p)
            end
        end
    end
    return count
end

-- =========================================================
-- ESP HALLOWENDOOR
-- =========================================================
local doorESPs = {}
local doorEnabled = true

local function createDoorESP(model, mainPart)
    local hl = Instance.new("Highlight")
    hl.FillColor = CONFIG.DoorColor
    hl.OutlineColor = CONFIG.DoorColor
    hl.FillTransparency = CONFIG.DoorFill
    hl.OutlineTransparency = 0
    hl.Adornee = model
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = gui

    local nameD = makeDrawing("Text", {
        Text = model.Name, Size = 14, Center = true,
        Outline = true, Color = CONFIG.DoorColor, Visible = false,
    })
    local distD = makeDrawing("Text", {
        Text = "", Size = 12, Center = true,
        Outline = true, Color = Color3.fromRGB(255, 200, 200), Visible = false,
    })

    return { highlight = hl, nameDrawing = nameD, distDrawing = distD,
             mainPart = mainPart, model = model }
end

local function destroyDoorESP(d)
    if d.highlight then d.highlight:Destroy() end
    if d.nameDrawing then d.nameDrawing:Remove() end
    if d.distDrawing then d.distDrawing:Remove() end
end

local function scanDoors()
    log("━━━ SCAN INICIADO ━━━", Color3.fromRGB(255, 200, 100))

    local effects = Workspace:FindFirstChild("Effects")
    if not effects then
        log("❌ Workspace.Effects NÃO EXISTE", Color3.fromRGB(255, 100, 100))
        return {}
    end
    log("✅ Workspace.Effects encontrado", Color3.fromRGB(100, 255, 100))

    local found = {}
    local allChildren = effects:GetChildren()
    log(string.format("📦 Effects tem %d filhos", #allChildren))

    for _, child in ipairs(allChildren) do
        log(string.format("  • %s (%s)", child.Name, child.ClassName),
            Color3.fromRGB(180, 180, 200))
    end

    for _, child in ipairs(allChildren) do
        if child.Name == "HallowenDoor" then
            log(string.format("🎯 Achou HallowenDoor: %s (%s)",
                child.Name, child.ClassName), Color3.fromRGB(255, 200, 100))

            if not child:IsA("Model") then
                log("  ⚠️ Não é Model, ignorando", Color3.fromRGB(255, 150, 100))
            else
                local frame = child:FindFirstChild("Frame")
                if not frame then
                    log("  ❌ Não achou 'Frame' dentro", Color3.fromRGB(255, 100, 100))
                    -- lista os filhos pra ajudar a debugar
                    for _, c2 in ipairs(child:GetChildren()) do
                        log(string.format("     - filho: %s (%s)", c2.Name, c2.ClassName),
                            Color3.fromRGB(200, 150, 150))
                    end
                elseif not frame:IsA("Model") then
                    log("  ⚠️ Frame não é Model", Color3.fromRGB(255, 150, 100))
                else
                    local mainPart
                    local partCount = 0
                    for _, p in ipairs(frame:GetChildren()) do
                        if p:IsA("BasePart") then
                            partCount += 1
                            if not mainPart then mainPart = p end
                        end
                    end
                    log(string.format("  ✅ Frame tem %d Parts", partCount),
                        Color3.fromRGB(100, 255, 100))
                    if mainPart then
                        table.insert(found, {model = child, part = mainPart})
                    else
                        log("  ❌ Frame sem nenhuma BasePart", Color3.fromRGB(255, 100, 100))
                    end
                end
            end
        end
    end

    log(string.format("🏁 Scan finalizado: %d doors válidas", #found),
        Color3.fromRGB(255, 200, 100))
    return found
end

local function refreshDoors()
    local found = scanDoors()
    local current = {}

    for _, entry in ipairs(found) do
        current[entry.model] = entry.part
    end

    for model, d in pairs(doorESPs) do
        if not current[model] then
            destroyDoorESP(d)
            doorESPs[model] = nil
        end
    end
    for model, part in pairs(current) do
        if not doorESPs[model] then
            doorESPs[model] = createDoorESP(model, part)
        end
    end
end

-- =========================================================
-- LOOP
-- =========================================================
RunService.RenderStepped:Connect(function()
    -- Players
    if playerEnabled then
        for p, d in pairs(playerESPs) do
            local char = p.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                d.highlight.Adornee = char
                d.highlight.Enabled = true
                local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
                local dist = (camera.CFrame.Position - hrp.Position).Magnitude
                local vis = onScreen and dist <= CONFIG.PlayerMaxDist
                d.nameDrawing.Visible = vis
                d.distDrawing.Visible = vis
                if vis then
                    d.nameDrawing.Position = Vector2.new(pos.X, pos.Y - 30)
                    d.distDrawing.Text = string.format("[%d]", math.floor(dist))
                    d.distDrawing.Position = Vector2.new(pos.X, pos.Y + 4)
                end
            else
                d.highlight.Enabled = false
                d.nameDrawing.Visible = false
                d.distDrawing.Visible = false
            end
        end
    end

    -- Doors
    if doorEnabled then
        for model, d in pairs(doorESPs) do
            local part = d.mainPart
            if part and part.Parent then
                d.highlight.Adornee = model
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                local dist = (camera.CFrame.Position - part.Position).Magnitude
                local vis = onScreen and dist <= CONFIG.DoorMaxDist
                d.highlight.Enabled = vis
                d.nameDrawing.Visible = vis
                d.distDrawing.Visible = vis
                if vis then
                    d.nameDrawing.Position = Vector2.new(pos.X, pos.Y - 20)
                    d.distDrawing.Text = string.format("[%d]", math.floor(dist))
                    d.distDrawing.Position = Vector2.new(pos.X, pos.Y + 4)
                end
            end
        end
    end
end)

-- =========================================================
-- BOTÕES
-- =========================================================
local function updateInfo()
    info.Text = string.format("Doors: %d | Players: %d",
        #scanCountDoors, #Players:GetPlayers() - 1)
end

-- Contagem rápida só pra exibir
local scanCountDoors = 0
local function quickCount()
    scanCountDoors = 0
    local effects = Workspace:FindFirstChild("Effects")
    if effects then
        for _, c in ipairs(effects:GetChildren()) do
            if c.Name == "HallowenDoor" then scanCountDoors += 1 end
        end
    end
    updateInfo()
end

-- Botão RECARREGAR
reloadBtn.MouseButton1Click:Connect(function()
    log("", Color3.fromRGB(255, 255, 255))
    refreshDoors()
    quickCount()
end)

-- Botão DOOR toggle
doorBtn.MouseButton1Click:Connect(function()
    doorEnabled = not doorEnabled
    doorBtn.Text = doorEnabled and "DOOR: ON" or "DOOR: OFF"
    TweenService:Create(doorBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = doorEnabled and Color3.fromRGB(60, 200, 100)
                                        or Color3.fromRGB(200, 60, 60)
    }):Play()
    if not doorEnabled then
        for _, d in pairs(doorESPs) do
            d.highlight.Enabled = false
            d.nameDrawing.Visible = false
            d.distDrawing.Visible = false
        end
    end
end)

-- Botão PLAYER toggle
playerBtn.MouseButton1Click:Connect(function()
    playerEnabled = not playerEnabled
    playerBtn.Text = playerEnabled and "PLAYER: ON" or "PLAYER: OFF"
    TweenService:Create(playerBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = playerEnabled and Color3.fromRGB(60, 200, 100)
                                          or Color3.fromRGB(200, 60, 60)
    }):Play()
    if not playerEnabled then
        for _, d in pairs(playerESPs) do
            d.highlight.Enabled = false
            d.nameDrawing.Visible = false
            d.distDrawing.Visible = false
        end
    end
end)

-- Tecla E = toggle doors
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CONFIG.ToggleKey then
        doorBtn:FireClickEvent and doorBtn:FireClickEvent() or doorBtn.MouseButton1Click:Connect(function() end)
        doorEnabled = not doorEnabled
        doorBtn.Text = doorEnabled and "DOOR: ON" or "DOOR: OFF"
        TweenService:Create(doorBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = doorEnabled and Color3.fromRGB(60, 200, 100)
                                            or Color3.fromRGB(200, 60, 60)
        }):Play()
    end
end)

-- =========================================================
-- INICIALIZAÇÃO
-- =========================================================
log("🚀 Script iniciado", Color3.fromRGB(100, 255, 100))
log("LocalPlayer: " .. player.Name, Color3.fromRGB(200, 200, 255))

refreshPlayers()
refreshDoors()
quickCount()

-- Watchers
local effects = Workspace:WaitForChild("Effects", 10)
if effects then
    effects.ChildAdded:Connect(function(c)
        log("📥 Effects.ChildAdded: " .. c.Name, Color3.fromRGB(180, 255, 180))
        task.wait(0.2)
        refreshDoors()
        quickCount()
    end)
    effects.ChildRemoved:Connect(function(c)
        log("📤 Effects.ChildRemoved: " .. c.Name, Color3.fromRGB(255, 180, 180))
        task.wait(0.2)
        refreshDoors()
        quickCount()
    end)
end

Players.PlayerAdded:Connect(function(p)
    log("👤 Player entrou: " .. p.Name, Color3.fromRGB(150, 200, 255))
    task.wait(1)
    refreshPlayers()
end)

-- Loop de refresh automático (só players, doors é manual)
task.spawn(function()
    while task.wait(2) do
        refreshPlayers()
        quickCount()
    end
end)
