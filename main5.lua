--[[
    ESP + HUD — versão final blindada
    - Funciona com ou sem Drawing (fallback pra BillboardGui)
    - Auto-refresh (pega o HallowenDoor mesmo que spawne depois)
    - Logs no HUD
    - Botão Recarregar
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
    ScanInterval  = 2, -- segundos
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

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 340, 0, 470)
panel.Position = UDim2.new(0, 10, 0, 10)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Parent = gui

local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 10)
pc.Parent = panel

local ps = Instance.new("UIStroke")
ps.Color = Color3.fromRGB(255, 80, 80)
ps.Thickness = 1.5
ps.Transparency = 0.3
ps.Parent = panel

-- Título
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 26)
title.Position = UDim2.new(0, 10, 0, 6)
title.BackgroundTransparency = 1
title.Text = "🎃 ESP HALLOWEEN"
title.TextColor3 = Color3.fromRGB(255, 220, 220)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

-- Botão recarregar
local reloadBtn = Instance.new("TextButton")
reloadBtn.Size = UDim2.new(0, 100, 0, 24)
reloadBtn.Position = UDim2.new(1, -110, 0, 7)
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

-- Info
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 18)
info.Position = UDim2.new(0, 10, 0, 36)
info.BackgroundTransparency = 1
info.Text = "Doors: 0 | Players: 0 | Drawing: " .. (HAS_DRAWING and "SIM" or "NÃO")
info.TextColor3 = HAS_DRAWING and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 180, 100)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel

-- Toggles
local doorBtn = Instance.new("TextButton")
doorBtn.Size = UDim2.new(0.5, -15, 0, 30)
doorBtn.Position = UDim2.new(0, 10, 0, 58)
doorBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
doorBtn.BorderSizePixel = 0
doorBtn.Font = Enum.Font.GothamBold
doorBtn.TextSize = 12
doorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
doorBtn.Text = "DOOR: ON"
doorBtn.Parent = panel
local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(0, 6)
dc.Parent = doorBtn

local playerBtn = Instance.new("TextButton")
playerBtn.Size = UDim2.new(0.5, -15, 0, 30)
playerBtn.Position = UDim2.new(0.5, 5, 0, 58)
playerBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
playerBtn.BorderSizePixel = 0
playerBtn.Font = Enum.Font.GothamBold
playerBtn.TextSize = 12
playerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playerBtn.Text = "PLAYER: ON"
playerBtn.Parent = panel
local plc = Instance.new("UICorner")
plc.CornerRadius = UDim.new(0, 6)
plc.Parent = playerBtn

-- Separador
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -20, 0, 1)
sep.Position = UDim2.new(0, 10, 0, 96)
sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sep.BackgroundTransparency = 0.8
sep.BorderSizePixel = 0
sep.Parent = panel

-- Logs
local logTitle = Instance.new("TextLabel")
logTitle.Size = UDim2.new(1, -20, 0, 16)
logTitle.Position = UDim2.new(0, 10, 0, 102)
logTitle.BackgroundTransparency = 1
logTitle.Text = "📋 LOGS"
logTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
logTitle.Font = Enum.Font.GothamBold
logTitle.TextSize = 11
logTitle.TextXAlignment = Enum.TextXAlignment.Left
logTitle.Parent = panel

local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(1, -20, 0, 340)
logFrame.Position = UDim2.new(0, 10, 0, 120)
logFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
logFrame.BorderSizePixel = 0
logFrame.ScrollBarThickness = 6
logFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logFrame.Parent = panel
local lfc = Instance.new("UICorner")
lfc.CornerRadius = UDim.new(0, 6)
lfc.Parent = logFrame

local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0, 2)
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Parent = logFrame

local logPad = Instance.new("UIPadding")
logPad.PaddingLeft = UDim.new(0, 6)
logPad.PaddingTop = UDim.new(0, 4)
logPad.PaddingRight = UDim.new(0, 6)
logPad.Parent = logFrame

local logCount = 0
local function log(msg, col)
    logCount = logCount + 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = "▸ " .. tostring(msg)
    lbl.TextColor3 = col or Color3.fromRGB(200, 220, 200)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = false
    lbl.LayoutOrder = logCount
    lbl.Parent = logFrame
    logFrame.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 8)
    logFrame.CanvasPosition = Vector2.new(0, math.max(0, logLayout.AbsoluteContentSize.Y - 300))
end

-- =========================================================
-- TEXTO (Drawing OU BillboardGui)
-- =========================================================
local function makeText(text, color, size)
    if HAS_DRAWING then
        local d = Drawing.new("Text")
        d.Text = text
        d.Size = size or 14
        d.Center = true
        d.Outline = true
        d.Color = color
        d.Visible = false
        return {
            kind = "drawing",
            obj = d,
            setVisible = function(v) d.Visible = v end,
            setPosition = function(v2) d.Position = v2 end,
            setText = function(t) d.Text = t end,
            remove = function() d:Remove() end,
        }
    else
        -- Fallback: BillboardGui
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 120, 0, 30)
        bb.AlwaysOnTop = true
        bb.Enabled = false
        bb.Parent = gui

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color
        lbl.TextScaled = true
        lbl.Font = Enum.Font.GothamBold
        lbl.TextStrokeTransparency = 0.3
        lbl.Parent = bb

        return {
            kind = "billboard",
            obj = bb,
            setVisible = function(v) bb.Enabled = v end,
            setPosition = function(v2)
                -- não usado diretamente; usamos Adornee
            end,
            setAdornee = function(part)
                bb.Adornee = part
            end,
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
            destroyPlayerESP(d)
            playerESPs[pl] = nil
        else
            d.highlight.Adornee = pl.Character
        end
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player and pl.Character then
            if not playerESPs[pl] then
                playerESPs[pl] = createPlayerESP(pl)
            end
        end
    end
end

-- =========================================================
-- DOOR ESP
-- =========================================================
local doorESPs = {}
local doorEnabled = true
local doorCount = 0

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

-- Scan recursivo dentro de Effects, procurando por nome "HallowenDoor"
local function scanDoors(silent)
    if not silent then log("━━━ SCAN ━━━", Color3.fromRGB(255, 200, 100)) end

    local effects = Workspace:FindFirstChild("Effects")
    if not effects then
        if not silent then log("❌ Workspace.Effects não existe", Color3.fromRGB(255, 100, 100)) end
        return {}
    end

    local found = {}
    local function walk(obj, depth)
        if depth > 5 then return end
        for _, k in ipairs(obj:GetChildren()) do
            if k.Name == "HallowenDoor" and k:IsA("Model") then
                local frame = k:FindFirstChild("Frame")
                if frame and frame:IsA("Model") then
                    local mainPart
                    for _, pp in ipairs(frame:GetChildren()) do
                        if pp:IsA("BasePart") then mainPart = pp break end
                    end
                    if mainPart then
                        table.insert(found, {model = k, part = mainPart})
                    end
                end
            end
            if k:IsA("Model") or k:IsA("Folder") then
                walk(k, depth + 1)
            end
        end
    end
    walk(effects, 0)

    if not silent then
        log(string.format("🔍 Achou %d HallowenDoor(s)", #found),
            #found > 0 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 180, 100))
    end
    return found
end

local function refreshDoors(silent)
    local found = scanDoors(silent)
    local current = {}
    for _, e in ipairs(found) do current[e.model] = e.part end

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
                d.nameT.setVisible(vis)
                d.distT.setVisible(vis)
                if vis then
                    d.nameT.setPosition(Vector2.new(pos.X, pos.Y - 30))
                    d.distT.setText(string.format("[%d]", math.floor(dist)))
                    d.distT.setPosition(Vector2.new(pos.X, pos.Y + 4))
                end
            else
                d.highlight.Enabled = false
                d.nameT.setVisible(false)
                d.distT.setVisible(false)
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
                d.nameT.setVisible(vis)
                d.distT.setVisible(vis)
                if vis and d.nameT.kind == "drawing" then
                    d.nameT.setPosition(Vector2.new(pos.X, pos.Y - 20))
                    d.distT.setText(string.format("[%d]", math.floor(dist)))
                    d.distT.setPosition(Vector2.new(pos.X, pos.Y + 4))
                elseif vis and d.nameT.kind == "billboard" then
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
    info.Text = string.format("Doors: %d | Players: %d | Drawing: %s",
        doorCount, math.max(0, #Players:GetPlayers() - 1),
        HAS_DRAWING and "SIM" or "NÃO")
end

local function setDoorEnabled(state)
    doorEnabled = state
    doorBtn.Text = doorEnabled and "DOOR: ON" or "DOOR: OFF"
    TweenService:Create(doorBtn, TweenInfo.new(0.2), {
        BackgroundColor3 = doorEnabled and Color3.fromRGB(60, 200, 100)
                                        or Color3.fromRGB(200, 60, 60)
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
        BackgroundColor3 = playerEnabled and Color3.fromRGB(60, 200, 100)
                                          or Color3.fromRGB(200, 60, 60)
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
    log("", Color3.new(1,1,1))
    refreshDoors(false)
    refreshPlayers()
    updateInfo()
end)

doorBtn.MouseButton1Click:Connect(function()
    setDoorEnabled(not doorEnabled)
end)

playerBtn.MouseButton1Click:Connect(function()
    setPlayerEnabled(not playerEnabled)
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == CONFIG.ToggleKey then
        setDoorEnabled(not doorEnabled)
    end
end)

-- =========================================================
-- INIT
-- =========================================================
log("🚀 Iniciado", Color3.fromRGB(100, 255, 100))
log("Drawing: " .. (HAS_DRAWING and "SIM ✅" or "NÃO (usando BillboardGui) ⚠️"),
    HAS_DRAWING and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 180, 100))

refreshPlayers()
refreshDoors(false)
updateInfo()

-- Auto-refresh (pega HallowenDoor que spawna depois)
task.spawn(function()
    while task.wait(CONFIG.ScanInterval) do
        refreshPlayers()
        local before = doorCount
        refreshDoors(true)
        if doorCount ~= before then
            log("🔄 Doors atualizaram: " .. before .. " → " .. doorCount,
                Color3.fromRGB(150, 255, 150))
        end
        updateInfo()
    end
end)

-- Watcher: se Effects aparecer depois, pega
Workspace.ChildAdded:Connect(function(c)
    if c.Name == "Effects" then
        log("📥 Workspace.Effects apareceu", Color3.fromRGB(180, 255, 180))
        task.wait(0.5)
        refreshDoors(false)
    end
end)
