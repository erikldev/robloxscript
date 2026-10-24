--[[
    HUD Spy — mostra remotes disparados na tela
    (mobile friendly, sem console)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- =========================================================
-- HUD
-- =========================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SpyHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Painel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 340, 0, 420)
panel.Position = UDim2.new(0, 10, 0, 10)
panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = panel
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(150, 80, 255); ps.Thickness = 1.5; ps.Transparency = 0.3; ps.Parent = panel

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
title.Text = "🕵️ SPY HUD"
title.TextColor3 = Color3.fromRGB(220, 200, 255)
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

-- Botões
local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0.5, -15, 0, 28)
clearBtn.Position = UDim2.new(0, 10, 0, 38)
clearBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
clearBtn.BorderSizePixel = 0
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 11
clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
clearBtn.Text = "🗑 LIMPAR"
clearBtn.Parent = panel
local clc = Instance.new("UICorner"); clc.CornerRadius = UDim.new(0, 6); clc.Parent = clearBtn

local pauseBtn = Instance.new("TextButton")
pauseBtn.Size = UDim2.new(0.5, -15, 0, 28)
pauseBtn.Position = UDim2.new(0.5, 5, 0, 38)
pauseBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 60)
pauseBtn.BorderSizePixel = 0
pauseBtn.Font = Enum.Font.GothamBold
pauseBtn.TextSize = 11
pauseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pauseBtn.Text = "⏸ PAUSAR"
pauseBtn.Parent = panel
local pbc = Instance.new("UICorner"); pbc.CornerRadius = UDim.new(0, 6); pbc.Parent = pauseBtn

-- Info
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 16)
info.Position = UDim2.new(0, 10, 0, 70)
info.BackgroundTransparency = 1
info.Text = "0 eventos capturados"
info.TextColor3 = Color3.fromRGB(180, 180, 200)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextXAlignment = Enum.TextXAlignment.Left
info.Parent = panel

-- Lista de eventos
local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 1, -100)
listFrame.Position = UDim2.new(0, 10, 0, 88)
listFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.Parent = panel
local lfc = Instance.new("UICorner"); lfc.CornerRadius = UDim.new(0, 6); lfc.Parent = listFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

local listPad = Instance.new("UIPadding")
listPad.PaddingLeft = UDim.new(0, 6)
listPad.PaddingTop = UDim.new(0, 6)
listPad.PaddingRight = UDim.new(0, 6)
listPad.Parent = listFrame

-- =========================================================
-- FILTRO (esconde o spam de camera)
-- =========================================================
local FILTRO = {
    "camera",
    "Camera",
    "Re.camera",
}

local function deveFiltrar(nome)
    for _, f in ipairs(FILTRO) do
        if string.find(nome, f, 1, true) then
            return true
        end
    end
    return false
end

-- =========================================================
-- UTIL: formatar argumentos
-- =========================================================
local function formatarArgs(...)
    local args = {...}
    local out = {}
    for i, v in ipairs(args) do
        local t = typeof(v)
        if t == "string" then
            out[i] = string.format("%q", v)
        elseif t == "Instance" then
            out[i] = v:GetFullName()
        elseif t == "Vector3" then
            out[i] = string.format("Vector3.new(%.1f,%.1f,%.1f)", v.X, v.Y, v.Z)
        elseif t == "CFrame" then
            out[i] = "CFrame.new(...)"
        else
            out[i] = tostring(v)
        end
    end
    return table.concat(out, ", ")
end

-- =========================================================
-- LISTA UI
-- =========================================================
local eventos = {}
local pausado = false
local contador = 0

local function addEvento(nomeRemote, metodo, argsStr)
    contador = contador + 1
    info.Text = string.format("%d eventos capturados", contador)

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    card.BorderSizePixel = 0
    card.LayoutOrder = contador
    card.Parent = listFrame
    local ccard = Instance.new("UICorner"); ccard.CornerRadius = UDim.new(0, 5); ccard.Parent = card

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.Parent = card

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = card

    -- Método + nome
    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, 0, 0, 0)
    titulo.AutomaticSize = Enum.AutomaticSize.Y
    titulo.BackgroundTransparency = 1
    titulo.Text = "▸ " .. metodo .. " → " .. nomeRemote
    titulo.TextColor3 = Color3.fromRGB(200, 180, 255)
    titulo.Font = Enum.Font.Code
    titulo.TextSize = 12
    titulo.TextWrapped = true
    titulo.TextXAlignment = Enum.TextXAlignment.Left
    titulo.Parent = card

    -- Args
    local argsLbl = Instance.new("TextLabel")
    argsLbl.Size = UDim2.new(1, 0, 0, 0)
    argsLbl.AutomaticSize = Enum.AutomaticSize.Y
    argsLbl.BackgroundTransparency = 1
    argsLbl.Text = "   " .. (argsStr ~= "" and argsStr or "(sem args)")
    argsLbl.TextColor3 = Color3.fromRGB(180, 220, 180)
    argsLbl.Font = Enum.Font.Code
    argsLbl.TextSize = 11
    argsLbl.TextWrapped = true
    argsLbl.TextXAlignment = Enum.TextXAlignment.Left
    argsLbl.Parent = card

    -- Botão copiar
    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 70, 0, 20)
    copyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    copyBtn.BorderSizePixel = 0
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 10
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.Text = "📋 COPIAR"
    copyBtn.Parent = card
    local cbc2 = Instance.new("UICorner"); cbc2.CornerRadius = UDim.new(0, 4); cbc2.Parent = copyBtn

    copyBtn.MouseButton1Click:Connect(function()
        local code = string.format('%s:FireServer(%s)', nomeRemote, argsStr)
        if setclipboard then
            setclipboard(code)
            copyBtn.Text = "✅ COPIADO"
            copyBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
            task.delay(1.5, function()
                copyBtn.Text = "📋 COPIAR"
                copyBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
            end)
        end
    end)

    -- Auto-scroll pro fundo
    task.defer(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
        listFrame.CanvasPosition = Vector2.new(0, math.max(0, listLayout.AbsoluteContentSize.Y - 300))
    end)
end

-- =========================================================
-- HOOK
-- =========================================================
local oldNamecall
local hookAtivo = true

oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()

    if (method == "FireServer" or method == "InvokeServer") and not checkcaller() then
        if not pausado and self and typeof(self) == "Instance" then
            local nome = self:GetFullName()
            if not deveFiltrar(nome) then
                local argsStr = formatarArgs(...)
                addEvento(nome, method, argsStr)
            end
        end
    end

    return oldNamecall(self, ...)
end)

-- =========================================================
-- BOTÕES
-- =========================================================
clearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    contador = 0
    info.Text = "0 eventos capturados"
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end)

pauseBtn.MouseButton1Click:Connect(function()
    pausado = not pausado
    pauseBtn.Text = pausado and "▶ RETOMAR" or "⏸ PAUSAR"
    pauseBtn.BackgroundColor3 = pausado and Color3.fromRGB(60, 200, 100) or Color3.fromRGB(255, 160, 60)
end)

closeBtn.MouseButton1Click:Connect(function()
    hookmetamethod(game, "__namecall", oldNamecall)
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
-- INIT
-- =========================================================
print("[Spy HUD] Pronto! Interaja com a porta pra capturar.")
