print("TESTE 2: criando HUD")

local Players = game:GetService("Players")
local p = Players.LocalPlayer

local sg = Instance.new("ScreenGui")
sg.Name = "TESTE_HUD"
sg.ResetOnSpawn = false
sg.Parent = p:WaitForChild("PlayerGui")

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 300, 0, 80)
f.Position = UDim2.new(0, 100, 0, 100)
f.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
f.Parent = sg

local t = Instance.new("TextLabel")
t.Size = UDim2.new(1, 0, 1, 0)
t.BackgroundTransparency = 1
t.Text = "✅ TESTE 2 OK"
t.TextColor3 = Color3.new(1,1,1)
t.TextScaled = true
t.Font = Enum.Font.GothamBold
t.Parent = f

print("TESTE 2: HUD criado")
