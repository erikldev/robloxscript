--[[
    TESTE: fireproximityprompt em TODAS as HalloweenDoors
    Mostra HUD com resultado
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- =========================================================
-- HUD
-- =========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "FireAllDoors"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 400)
panel.Position = UDim2.new(0, 10, 0, 10)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = panel
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(255, 80, 80); ps.Thickness = 1.5; ps.Transparency = 0.3; ps.Parent = panel

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundTransparency = 1
header.Active = true
header.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 0, 26)
title.Position = UDim2.new(0, 10, 0, 4)
title.BackgroundTransparency = 1
title.Text = "🔥 FIRE ALL DOORS"
title.TextColor3 = Color3.fromRGB(255, 200, 200)
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

-- Botão FIRE
local fireBtn = Instance.new("TextButton")
fireBtn.Size = UDim2.new(1, -20, 0, 50)
fireBtn.Position = UDim2.new(0, 10, 0, 44)
fireBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
fireBtn.BorderSizePixel = 0
fireBtn.Font = Enum.Font.GothamBold
fireBtn.TextSize = 16
fireBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
fireBtn.Text = "🔥 DISPARAR TODAS AS PORTAS"
fireBtn.Parent = panel
local fbc = Instance.new("UICorner"); fbc.CornerRadius = UDim.new(0, 8); fbc.Parent = fireBtn
local fbs = Instance.new("UIStroke"); fbs.Color = Color3.fromRGB(255, 255, 255); fbs.Thickness = 1; fbs.Transparency = 0.6; fbs.Parent = fireBtn

-- Info
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 20)
info.Position = UDim2.new(0, 10, 0, 100)
info.BackgroundTransparency = 1
info.Text = "Portas encontradas: 0"
info.TextColor3 = Color3.fromRGB(200, 200, 220)
info.Font = Enum.Font.GothamBold
info.TextSize = 12
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel

-- Lista
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 1, -140)
listFrame.Position = UDim2.new(0, 10, 0, 124)
listFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.Parent = panel
local lfc = Instance.new("UICorner"); lfc.CornerRadius = UDim.new(0, 6); lfc.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

local listPad = Instance.new("UIPadding")
listPad.PaddingLeft = UDim.new(0, 6)
listPad.PaddingTop = UDim.new(0, 6)
listPad.PaddingRight = UDim.new(0, 6)
listPad.Parent = listFrame

-- =========================================================
-- LOG
-- =========================================================
local logCount = 0
local function log(msg, col)
    logCount = logCount + 1
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = "▸ " .. tostring(msg)
    lbl.TextColor3 = col or Color3.fromRGB(200, 220, 200)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 11
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = logCount
    lbl.Parent = listFrame
    task.defer(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
        listFrame.CanvasPosition = Vector2.new(0, math.max(0, listLayout.AbsoluteContentSize.Y - 250))
    end)
end

-- =========================================================
-- SCAN E FIRE
-- =========================================================
local function encontrarPrompts()
    local prompts = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            -- sobe a árvore pra ver se tá dentro de HalloweenDoor
            local pai = d
            local estaNaPorta = false
            for _ = 1, 10 do
                pai = pai.Parent
                if not pai then break end
                if pai.Name == "HalloweenDoor" then
                    estaNaPorta = true
                    break
                end
            end
            if estaNaPorta then
                table.insert(prompts, {prompt = d, porta = pai})
            end
        end
    end
    return prompts
end

fireBtn.MouseButton1Click:Connect(function()
    -- limpa lista
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    logCount = 0

    log("━━━ SCAN ━━━", Color3.fromRGB(255, 200, 100))
    local prompts = encontrarPrompts()
    info.Text = "Portas encontradas: " .. #prompts
    log("Prompts encontrados: " .. #prompts,
        #prompts > 0 and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 100, 100))

    if #prompts == 0 then
        log("❌ Nenhuma HalloweenDoor com ProximityPrompt", Color3.fromRGB(255, 100, 100))
        return
    end

    -- verifica se fireproximityprompt existe
    if not fireproximityprompt then
        log("❌ fireproximityprompt NÃO existe neste executor", Color3.fromRGB(255, 100, 100))
        return
    end

    log("✅ fireproximityprompt disponível", Color3.fromRGB(150, 255, 150))
    log("━━━ DISPARANDO ━━━", Color3.fromRGB(255, 200, 100))

    local sucesso = 0
    local falha = 0

    for i, entry in ipairs(prompts) do
        local p = entry.prompt
        local nome = entry.porta.Name
        local caminho = p:GetFullName()

        -- tenta disparar
        local ok, err = pcall(function()
            fireproximityprompt(p)
        end)

        if ok then
            sucesso = sucesso + 1
            log(string.format("[%d] ✅ %s", i, caminho:sub(-50)), Color3.fromRGB(150, 255, 150))
        else
            falha = falha + 1
            log(string.format("[%d] ❌ %s — %s", i, nome, tostring(err):sub(1, 40)),
                Color3.fromRGB(255, 100, 100))
        end

        task.wait(0.1) -- pequeno delay entre disparos
    end

    log("━━━ FIM ━━━", Color3.fromRGB(255, 200, 100))
    log(string.format("✅ %d sucesso | ❌ %d falha", sucesso, falha),
        falha == 0 and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 180, 100))
end)

-- =========================================================
-- CLOSE
-- =========================================================
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- =========================================================
-- DRAG
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

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- =========================================================
-- AUTO-INIT: mostra quantas portas tem sem disparar
-- =========================================================
task.spawn(function()
    task.wait(1)
    local prompts = encontrarPrompts()
    info.Text = "Portas encontradas: " .. #prompts
    log("📦 Mapa tem " .. #prompts .. " prompts em HalloweenDoors", Color3.fromRGB(200, 200, 255))
    if fireproximityprompt then
        log("✅ fireproximityprompt disponível", Color3.fromRGB(150, 255, 150))
    else
        log("❌ fireproximityprompt NÃO existe", Color3.fromRGB(255, 100, 100))
    end
end)
