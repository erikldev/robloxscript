-- =========================================================
-- TELEPORTE COM NOCLIP TEMPORÁRIO (desativa colisão no caminho)
-- =========================================================
local tpRunning = false

-- ✅ Lista de partes que tiveram colisão desativada (pra restaurar)
local colisoesDesativadas = {}

local function desativarColisaoNoCaminho(startPos, endPos, char)
    colisoesDesativadas = {}

    -- Raycast amplo pegando TUDO entre start e end
    local direction = endPos - startPos
    local distancia = direction.Magnitude
    if distancia < 0.1 then return end
    local unit = direction.Unit

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char}
    rayParams.IgnoreWater = true

    -- Faz vários raycasts em linha pra pegar blocos em sequência
    local posAtual = startPos
    local restante = distancia
    local hits = {}

    while restante > 0 do
        local step = math.min(restante, 8)
        local result = Workspace:Raycast(posAtual, unit * step, rayParams)
        if result and result.Instance then
            table.insert(hits, result.Instance)
            -- Continua do ponto do hit + offset pra não pegar o mesmo
            posAtual = result.Position + unit * 0.5
            restante = (endPos - posAtual).Magnitude
        else
            posAtual = posAtual + unit * step
            restante = restante - step
        end
    end

    -- Desativa colisão de cada hit (só BasePart)
    for _, hit in ipairs(hits) do
        if hit:IsA("BasePart") and hit.CanCollide then
            hit.CanCollide = false
            colisoesDesativadas[hit] = true
        end
    end
end

local function restaurarColisoes()
    for part in pairs(colisoesDesativadas) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = true
            end)
        end
    end
    colisoesDesativadas = {}
end

tpBtn.MouseButton1Click:Connect(function()
    if tpRunning then return end

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
        status.Text = "❌ Nenhuma HalloweenDoor encontrada"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        task.delay(2, function() status.Text = "" end)
        return
    end

    local doorPos = nearest.part.Position
    local direction = (hrp.Position - doorPos).Unit
    if direction.Magnitude < 0.1 then direction = Vector3.new(0, 0, 1) end
    local finalPos = doorPos + direction * CONFIG.TeleportOffset + Vector3.new(0, 3, 0)
    local startPos = hrp.Position
    local lookAt = Vector3.new(doorPos.X, finalPos.Y, doorPos.Z)
    local distancia = (finalPos - startPos).Magnitude

    if distancia < 0.5 then
        status.Text = "✅ Já está na porta"
        status.TextColor3 = Color3.fromRGB(150, 255, 150)
        task.delay(2, function() status.Text = "" end)
        return
    end

    tpRunning = true
    tpBtn.Active = false
    tpBtn.Text = "⏳ ..."
    status.Text = "🚶 Preparando caminho..."
    status.TextColor3 = Color3.fromRGB(255, 200, 100)

    task.spawn(function()
        -- ✅ 1. Desativa colisão de tudo entre start e final
        desativarColisaoNoCaminho(startPos, finalPos, char)

        -- ✅ 2. Step teleport normal (agora sem colisão bloqueando)
        local stepSize = math.max(2, CONFIG.TeleportSpeed * CONFIG.StepDelay)
        stepSize = math.min(stepSize, CONFIG.StepSize * 3)

        local direcao = finalPos - startPos
        local dirHorizontal = Vector3.new(direcao.X, 0, direcao.Z)
        if dirHorizontal.Magnitude < 0.1 then
            dirHorizontal = Vector3.new(0, 0, 1)
        else
            dirHorizontal = dirHorizontal.Unit
        end

        local atual = startPos
        local passos = 0
        local maxPassos = math.ceil(distancia / 1) + 100

        while passos < maxPassos do
            if not char or not char.Parent or not hrp or not hrp.Parent then break end

            local restante = (finalPos - atual).Magnitude
            if restante < stepSize then
                pcall(function()
                    char:PivotTo(CFrame.new(finalPos, lookAt))
                end)
                break
            end

            atual = atual + dirHorizontal * stepSize
            pcall(function()
                char:PivotTo(CFrame.new(atual, lookAt))
            end)

            passos = passos + 1
            task.wait(CONFIG.StepDelay)
        end

        -- ✅ 3. Garante posição final
        pcall(function()
            char:PivotTo(CFrame.new(finalPos, lookAt))
        end)

        -- ✅ 4. Restaura TODAS as colisões
        restaurarColisoes()

        status.Text = string.format("✅ Chegou (%d passos)", passos)
        status.TextColor3 = Color3.fromRGB(150, 255, 150)
        tpBtn.Active = true
        tpBtn.Text = "⚡ TELEPORTAR"
        task.delay(2.5, function() status.Text = "" end)
        tpRunning = false
    end)
end)
