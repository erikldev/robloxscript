--[[
    ESP + HUD — v6 (teleporte suave + arrastar + fechar, sem logs)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local HAS_DRAWING = (Drawing ~= nil)

local CONFIG = {
    DoorColor     = Color3.fromRGB(255, 80, 80),
    DoorFill      = 0.85,
    DoorMaxDist   = 2000,
    PlayerColor   = Color3.fromRGB(80, 180, 255),
    PlayerFill    = 0.7,
    PlayerMaxDist = 2000,
    ToggleKey     = Enum.KeyCode.E,
    ScanInterval  = 2,
    TeleportOffset = 5,
}

-- =========================================================
-- HUD BASE
-- =========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ESP_HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Botão flutuante pra reabrir
local reopenBtn = Instance.new("TextButton")
reopenBtn.Size = UDim2.new(0, 50, 0, 50)
reopenBtn.Position = UDim2.new(0, 10, 0, 10)
reopenBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
reopenBtn.BorderSizePixel = 0
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.TextSize = 22
reopenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
reopenBtn.Text = "🎃"
reopenBtn.Visible = false
reopenBtn.Parent = gui
local rbc = Instance.new("UICorner"); rbc.CornerRadius = UDim.new(1, 0); rbc.Parent = reopenBtn

-- Painel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 340)
panel.Position = UDim2.new(0, 10, 0, 10)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = panel
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(255, 80, 80); ps.Thickness = 1.5; ps.Transparency = 0.3; ps.Parent = panel

-- Cabeçalho (área de arrastar)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = panel

-- Título
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

-- Botão FECHAR
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

-- Info
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

-- Toggles
local doorBtn = Instance.new("TextButton")
doorBtn.Size = UDim2.new(0.5, -15, 0, 30)
doorBtn.Position = UDim2.new(0, 10, 0, 62)
doorBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
doorBtn.BorderSizePixel = 0
doorBtn.Font = Enum.Font.GothamBold
doorBtn.TextSize = 12
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
playerBtn.TextSize = 12
playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playerBtn.Text = "PLAYER: ON"
playerBtn.Parent = panel
local plc = Instance.new("UICorner"); plc.CornerRadius = UDim.new(0, 6); plc.Parent = playerBtn

-- Botão RECARREGAR
local reloadBtn = Instance.new("TextButton")
reloadBtn.Size = UDim2.new(0.5, -15, 0, 34)
reloadBtn.Position = UDim2.new(0, 10, 0, 100)
reloadBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 60)
reloadBtn.BorderSizePixel = 0
reloadBtn.Font = Enum.Font.GothamBold
reloadBtn.TextSize = 12
reloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
reloadBtn.Text = "🔄 RECARREGAR"
reloadBtn.Parent = panel
local rlc = Instance.new("UICorner"); rlc.CornerRadius = UDim.new(0, 6); rlc.Parent = reloadBtn

-- Botão TELEPORTAR
local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(0.5, -15, 0, 34)
tpBtn.Position = UDim2.new(0.5, 5, 0, 100)
tpBtn.BackgroundColor3 = Color3.fromRGB(150, 80, 255)
tpBtn.BorderSizePixel = 0
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextSize = 12
tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBtn.Text = "⚡ TELEPORTAR"
tpBtn.Parent = panel
local tpc = Instance.new("UICorner"); tpc.CornerRadius = UDim.new(0, 6); tpc.Parent = tpBtn

-- Status (feedback do teleporte)
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 18)
status.Position = UDim2.new(0, 10, 0, 142)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(150, 255, 150)
status.Font = Enum.Font.GothamSemibold
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

-- =========================================================
-- DRAG DO PAINEL
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
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- =========================================================
-- TEXTO (Drawing / BillboardGui)
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

local function isHallowenName(name)
    local n = name:lower()
    return n:find("hallowen") ~= nil or n:find("halloween") ~= nil
end

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
            if isHallowenName(k.Name) then
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
-- LOOP
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
                    d.nameT.setPosition(Vector2.new(pos.X, pos.Y - 30))
                    d.distT.setText(string.format("[%d]", math.floor(dist)))
                    d.distT.setPosition(Vector2.new(pos.X, pos.Y + 4))
                end
            else
                d.highlight.Enabled = false
                d.nameT.setVisible(false); d.distT.setVisible(false)
            end
        end
    end

    if doorEnabled then
        for model, d in pairs(doorESPs) do
            local part = d.mainPart
            if part and part.Parent then
                d.highlight.Adornee = model
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                local dist = (camera.CFrame.Position - part.Position).Magnitude
                local vis = onScreen and dist <= CONFIG.DoorMaxDist
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
            d.nameT.setVisible(false); d.distT.setVisible(false)
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
            d.nameT.setVisible(false); d.distT.setVisible(false)
        end
    end
end

reloadBtn.MouseButton1Click:Connect(function()
    refreshDoors(); refreshPlayers(); updateInfo()
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
-- TELEPORTE SUAVE (tween)
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

tpBtn.MouseButton1Click:Connect(function()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        status.Text = "❌ Sem personagem"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.delay(2, function() status.Text = "" end)
        return
    end

    local nearest = getNearestDoor()
    if not nearest then
        status.Text = "❌ Nenhuma porta encontrada"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.delay(2, function() status.Text = "" end)
        return
    end

    local targetPos = nearest.part.Position + Vector3.new(0, 3, 0)
    local direction = (hrp.Position - targetPos).Unit
    if direction.Magnitude < 0.1 then direction = Vector3.new(0, 0, 1) end
    local finalPos = targetPos + direction * CONFIG.TeleportOffset

    -- Duração baseada na distância (min 0.4s, max 2s)
    local distancia = (finalPos - hrp.Position).Magnitude
    local duracao = math.clamp(distancia / 100, 0.4, 2)

    status.Text = string.format("⚡ Teleportando... (%.0f studs)", distancia)
    status.TextColor3 = Color3.fromRGB(255, 200, 100)
    tpBtn.Active = false
    tpBtn.Text = "⏳ ..."

    -- CFrame alvo mantendo a orientação atual
    local targetCFrame = CFrame.new(finalPos) * (hrp.CFrame - hrp.CFrame.Position)

    -- Cria o tween
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(duracao, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { CFrame = targetCFrame }
    )

    tween:Play()
    tween.Completed:Connect(function()
        -- Olha pra porta ao chegar
        if hrp.Parent and nearest.part.Parent then
            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(
                nearest.part.Position.X,
                hrp.Position.Y,
                nearest.part.Position.Z
            ))
        end
        status.Text = string.format("✅ Chegou! (%.0f studs)", distancia)
        status.TextColor3 = Color3.fromRGB(150, 255, 150)
        tpBtn.Active = true
        tpBtn.Text = "⚡ TELEPORTAR"
        task.delay(2, function() status.Text = "" end)
    end)
end)

-- =========================================================
-- FECHAR / REABRIR
-- =========================================================
closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
    reopenBtn.Visible = true
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

task.spawn(function()
    while task.wait(CONFIG.ScanInterval) do
        refreshPlayers()
        refreshDoors()
        updateInfo()
    end
end)
