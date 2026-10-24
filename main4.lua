local Players = game:GetService("Players")
local p = Players.LocalPlayer

local sg = Instance.new("ScreenGui")
sg.Name = "DIAG"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.Parent = p:WaitForChild("PlayerGui")

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 320, 0, 380)
f.Position = UDim2.new(0, 10, 0, 10)
f.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
f.BorderSizePixel = 0
f.Parent = sg
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, 10)
c.Parent = f

local lf = Instance.new("ScrollingFrame")
lf.Size = UDim2.new(1, -20, 1, -20)
lf.Position = UDim2.new(0, 10, 0, 10)
lf.BackgroundTransparency = 1
lf.BorderSizePixel = 0
lf.ScrollBarThickness = 6
lf.CanvasSize = UDim2.new(0, 0, 0, 0)
lf.Parent = f

local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 4)
lay.Parent = lf

local n = 0
local function L(msg, col)
    n = n + 1
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -8, 0, 0)
    t.AutomaticSize = Enum.AutomaticSize.Y
    t.BackgroundTransparency = 1
    t.Text = "▸ " .. tostring(msg)
    t.TextColor3 = col or Color3.fromRGB(200, 220, 200)
    t.Font = Enum.Font.Code
    t.TextSize = 13
    t.TextWrapped = true
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.LayoutOrder = n
    t.Parent = lf
    lf.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 10)
end

-- TESTE 1
L("══ TESTE 1: GitHub ══", Color3.fromRGB(255, 200, 100))
local ok, result = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/erikldev/robloxscript/main/main.lua", true)
end)
if ok then
    L("✅ Baixou: " .. #result .. " bytes", Color3.fromRGB(100, 255, 100))
    L("Início: " .. result:sub(1, 60):gsub("\n", " "), Color3.fromRGB(180, 220, 180))
else
    L("❌ FALHOU: " .. tostring(result), Color3.fromRGB(255, 100, 100))
end

-- TESTE 2
L("══ TESTE 2: Drawing ══", Color3.fromRGB(255, 200, 100))
if Drawing then
    L("✅ Drawing existe", Color3.fromRGB(100, 255, 100))
    local ok2, err2 = pcall(function()
        local txt = Drawing.new("Text")
        txt.Text = "DRAWING OK"
        txt.Position = Vector2.new(400, 500)
        txt.Size = 20
        txt.Color = Color3.new(1, 1, 0)
        txt.Visible = true
        task.delay(8, function() txt:Remove() end)
    end)
    if ok2 then
        L("✅ Criou texto amarelo no meio da tela", Color3.fromRGB(100, 255, 100))
    else
        L("❌ Erro: " .. tostring(err2), Color3.fromRGB(255, 100, 100))
    end
else
    L("❌ Drawing NÃO existe", Color3.fromRGB(255, 100, 100))
end

-- TESTE 3
L("══ TESTE 3: Effects ══", Color3.fromRGB(255, 200, 100))
local ws = game:GetService("Workspace")
local effects = ws:FindFirstChild("Effects")
if effects then
    L("✅ Workspace.Effects existe", Color3.fromRGB(100, 255, 100))
    local kids = effects:GetChildren()
    L("📦 " .. #kids .. " filhos:", Color3.fromRGB(200, 200, 255))
    for i, k in ipairs(kids) do
        if i <= 15 then
            L("  • " .. k.Name .. " (" .. k.ClassName .. ")", Color3.fromRGB(180, 180, 220))
        end
    end
else
    L("❌ Workspace.Effects NÃO existe", Color3.fromRGB(255, 100, 100))
    L("Filhos do Workspace:", Color3.fromRGB(200, 200, 255))
    for i, k in ipairs(ws:GetChildren()) do
        if i <= 15 and k.Name ~= "Camera" then
            L("  • " .. k.Name .. " (" .. k.ClassName .. ")", Color3.fromRGB(180, 180, 220))
        end
    end
end

-- TESTE 4
L("══ TESTE 4: HallowenDoor ══", Color3.fromRGB(255, 200, 100))
local function scanFolder(folder, depth, maxDepth)
    if depth > maxDepth then return end
    for _, k in ipairs(folder:GetChildren()) do
        if k.Name:lower():find("hallowen") or k.Name:lower():find("halloween") then
            L("🎯 " .. k:GetFullName() .. " (" .. k.ClassName .. ")", Color3.fromRGB(255, 200, 100))
        end
        if k:IsA("Model") or k:IsA("Folder") then
            scanFolder(k, depth + 1, maxDepth)
        end
    end
end
scanFolder(ws, 0, 4)
L("Busca completa (até 4 níveis)", Color3.fromRGB(150, 150, 180))
