--[[
    ESP + HUD com Logs e Recarregar (CORRIGIDO)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local CONFIG = {
    DoorColor     = Color3.fromRGB(255, 80, 80),
    DoorFill      = 0.85,
    DoorMaxDist   = 1000,
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
local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(0, 6)
dc.Parent = doorBtn

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
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 6)
pc.Parent = playerBtn

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -20, 0, 1)
sep.Position = UDim2.new(0, 10, 0, 102)
sep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
sep.BackgroundTransparency = 0.8
sep.BorderSizePixel = 0
sep.Parent = panel

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
logFrame.Parent = panel
local lfc = Instance.new("UICorner")
lfc.CornerRadius = UDim.new(0, 6)
lfc.Parent = logFrame

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
    logCount = logCount + 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 16)  -- ✅ fixo, sem AutomaticSize
    lbl.BackgroundTransparency = 1
    lbl.Text = "▸ " .. tostring(msg)
    lbl.TextColor3 = color or Color3.fromRGB(200, 220, 200)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = false
    lbl.LayoutOrder = logCount
    lbl.Parent = logFrame
    -- Atualiza canvas manualmente
    logFrame.CanvasSize = UDim2.new(0, 0, 0, logLayout.AbsoluteContentSize.Y + 8)
    logFrame.CanvasPosition = Vector2.new(0, math.max(0, logLayout.AbsoluteContentSize.Y - 300))
end

-- =========================================================
-- DRAWINGS
-- =========================================================
local function makeDrawing(class, props)
    local d = Drawing.new(class)
    for k, v in pairs(props) do d[k] = v end
    return d
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
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            if not playerESPs[p] then
                playerESPs[p] = createPlayerESP(p)
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
    log("━━━ SCAN ━━━", Color3.fromRGB(255, 200, 100))

    local effects = Workspace:FindFirstChild("Effects")
    if not effects then
        log("❌ Workspace.Effects não existe", Color3.fromRGB(255, 100, 100))
        return {}
    end
    log("✅ Workspace.Effects ok", Color3.fromRGB(100, 255, 100))

    local found = {}
    local children = effects:GetChildren()
    log(string.format("📦 Effects tem %d filhos", #children))

    for _, child in ipairs(children) do
        log(string.format("  • %s (%s)", child.Name, child.ClassName),
            Color3.fromRGB(180, 180, 200))
    end

    for _, child in ipairs(children) do
        if child.Name == "HallowenDoor" then
            log(string.format("🎯 HallowenDoor: %s (%s)",
                child.Name, child.ClassName), Color3.fromRGB(255, 200, 100))

            if not child:IsA("Model") then
                log("  ⚠️ Não é Model", Color3.fromRGB(255, 150, 100))
            else
                local frame = child:FindFirstChild("Frame")
                if not frame then
                    log("  ❌ Sem 'Frame'", Color3.fromRGB(255, 100, 100))
                    for _, c2 in ipairs(child:GetChildren()) do
                        log(string.format("     - %s (%s)", c2.Name, c2.ClassName),
                            Color3.fromRGB(200, 150, 150))
                    end
                else
                    local mainPart, partCount = nil, 0
                    for _, p in ipairs(frame:GetChildren()) do
                        if p:IsA("BasePart") then
                            partCount = partCount + 1
                            if not mainPart then mainPart = p end
                        end
                    end
                    log(string.format("  ✅ Frame: %d Parts", partCount),
                        Color3.fromRGB(100, 255, 100))
                    if mainPart then
                        table.insert(found, {model = child, part = mainPart})
                    else
                        log("  ❌ Frame sem BasePart", Color3.fromRGB(255, 100, 100))
                    end
                end
            end
        end
    end

    log(string.format("🏁 %d válidas", #found), Color3.fromRGB(255, 200, 100))
    return found
end

local function refreshDoors()
    local found = scanDoors()
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
-- INFO / HELPERS
-- =========================================================
local function updateInfo()
    info.Text = string.format("Doors: %d | Players: %d",
        doorCount, math.max(0, #Players:GetPlayers() - 1))
end

-- =========================================================
-- LOOP
-- =========================================================
RunService.RenderStepped:Connect(function()
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
-- TOGGLES
-- =========================================================
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
            d.nameDrawing.Visible = false
            d.distDrawing.Visible = false
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
            d.nameDrawing.Visible = false
            d.distDrawing.Visible = false
        end
    end
end

reloadBtn.MouseButton1Click:Connect(function()
    log("", Color3.fromRGB(255, 255, 255))
    refreshDoors()
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
log("LocalPlayer: " .. player.Name, Color3.fromRGB(200, 200, 255))

refreshPlayers()
refreshDoors()
updateInfo()

local effects = Workspace:WaitForChild("Effects", 10)
if effects then
    effects.ChildAdded:Connect(function(c)
        log("📥 + " .. c.Name, Color3.fromRGB(180, 255, 180))
        task.wait(0.2)
        refreshDoors()
        updateInfo()
    end)
    effects.ChildRemoved:Connect(function(c)
        log("📤 - " .. c.Name, Color3.fromRGB(255, 180, 180))
        task.wait(0.2)
        refreshDoors()
        updateInfo()
    end)
end

Players.PlayerAdded:Connect(function(p)
    log("👤 " .. p.Name, Color3.fromRGB(150, 200, 255))
    task.wait(1)
    refreshPlayers()
    updateInfo()
end)

task.spawn(function()
    while task.wait(2) do
        refreshPlayers()
        updateInfo()
    end
end)
