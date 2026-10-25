--[[
    ESP HALLOWEEN v37
    - Interface nova: arrastável, minimizável, com rolagem, toggles e sliders
    - Código orientado a eventos (bem menos lag) e limpeza total ao reexecutar
    - Bugs da v36 corrigidos
    Tecla RightControl: mostrar / ocultar o painel
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local env = (getgenv and getgenv()) or _G

-- =========================================================
-- LIMPEZA DE EXECUÇÕES ANTERIORES
-- =========================================================
if env.__ESP_HALLOWEEN_CLEANUP then
    pcall(env.__ESP_HALLOWEEN_CLEANUP)
end

local function purgeOld(container)
    if not container then return end
    for _, g in ipairs(container:GetChildren()) do
        if g.Name == "TestePorta" or g.Name == "ESP_Halloween" or g.Name == "ESP_HUD" then
            g:Destroy()
        end
    end
end
purgeOld(PlayerGui)
if gethui then pcall(function() purgeOld(gethui()) end) end

-- =========================================================
-- CONFIG
-- =========================================================
local CONFIG = {
    DoorName = "HalloweenDoor",
    DoorColor = Color3.fromRGB(255, 80, 80),
    DoorFill = 0.95,
    DoorMaxDist = 800,
    DoorMinDist = 15,
    TimerName = "Timer",     -- nome do objeto do timer (TextLabel ou valor)
    TimerMaxDist = 30,       -- se o timer estiver em Workspace.Effects: distância máx. até a porta
    PlayerColor = Color3.fromRGB(80, 180, 255),
    PlayerFill = 0.7,
    PlayerMaxDist = 2000,
    MaxHighlights = 28,      -- o Roblox só renderiza ~31 Highlights ao mesmo tempo
    RescanInterval = 10,     -- varredura de segurança (portas novas já são detectadas por evento)

    -- carregamento lento (evita crash ao executar)
    StartDelay = 2,          -- espera inicial (s) depois que o jogo carrega
    LoadDelay = 0.15,        -- pausa entre as etapas / lotes (s)
    ChunkSize = 600,         -- instâncias varridas por fatia antes de ceder o frame
    BatchEntries = 3,        -- ESPs (Highlight + texto) criados por lote

    StandOffset = 6,         -- distância da porta ao teleportar/grudar
    StickOffset = 4,         -- grudar em jogador: distância atrás dele (studs)
    RiseHeight = 150,
    RiseSpeed = 80,
    CruiseSpeed = 150,
    FallSpeed = 300,

    VoidUp = 400,            -- VOIDAR: quanto sobe (studs)
    VoidSide = 8000,         -- VOIDAR: quanto vai para o lado (direita da câmera)
    VoidRiseSpeed = 1000,    -- VOIDAR: velocidade da subida (studs/s) — 400 sobe em ~0,4 s
    VoidSideSpeed = 20000,   -- VOIDAR: velocidade do lado (studs/s) — 8000 vai em ~0,4 s
    VoidAnchor = true,       -- prende o personagem durante o voo e lá em cima

    ReduceHold = true,
    HoldValue = 0,
    AutoOpen = true,
    AutoOpenRange = 15,
    AntiAFK = true,

    FlyVel = 100,
    FlyTurbo = 3,
    VelBase = 16,
    VelMax = 150,            -- velocidades muito altas costumam ser detectadas

    ToggleKey = Enum.KeyCode.RightControl,
}

local THEME = {
    bg = Color3.fromRGB(16, 16, 22),
    item = Color3.fromRGB(30, 30, 40),
    text = Color3.fromRGB(235, 235, 245),
    sub = Color3.fromRGB(140, 140, 165),
    accent = Color3.fromRGB(255, 140, 50),
    on = Color3.fromRGB(70, 200, 120),
    off = Color3.fromRGB(70, 70, 88),
    purple = Color3.fromRGB(140, 90, 255),
    blue = Color3.fromRGB(70, 140, 230),
    red = Color3.fromRGB(210, 70, 70),
    ok = Color3.fromRGB(130, 255, 160),
    warn = Color3.fromRGB(255, 200, 100),
    err = Color3.fromRGB(255, 110, 110),
    info = Color3.fromRGB(190, 200, 255),
}

-- estado em tempo de execução
local S = {
    playerESP = true,
    doorESP = true,
    autoOpen = CONFIG.AutoOpen,
    reduceHold = CONFIG.ReduceHold,
    fly = false,
    noclip = false,
    flyVel = CONFIG.FlyVel,
    speed = CONFIG.VelBase,
}

-- carregamento lento: espera o jogo terminar de carregar antes de mexer em qualquer coisa
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(CONFIG.StartDelay)

-- =========================================================
-- GERENCIAMENTO DE CONEXÕES / LIMPEZA
-- =========================================================
local alive = true
local connections, cleanups = {}, {}

local function bind(conn)
    connections[#connections + 1] = conn
    return conn
end

local function onCleanup(fn)
    cleanups[#cleanups + 1] = fn
end

local function weak()
    return setmetatable({}, { __mode = "k" })
end

-- =========================================================
-- HELPERS
-- =========================================================
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function round(o, r)
    new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
end

local function tween(o, t, props)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad), props):Play()
end

local function getHRP()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function guiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return PlayerGui
end

-- =========================================================
-- ESTADO COMPARTILHADO (declarado cedo pois a UI usa)
-- =========================================================
local doors, doorCount = {}, 0
local playerESP = {}
local btnTP, grabToggle

-- =========================================================
-- INTERFACE
-- =========================================================
local gui = new("ScreenGui", {
    Name = "ESP_HUD",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100,
}, guiParent())

local HEADER_H, STATUS_H, WIDTH = 50, 32, 300
local viewport = (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
local BODY_H = math.clamp(viewport.Y - HEADER_H - STATUS_H - 90, 180, 470)
local FULL_H = HEADER_H + BODY_H + STATUS_H

local main = new("Frame", {
    Name = "Main",
    Size = UDim2.new(0, WIDTH, 0, FULL_H),
    Position = UDim2.new(0, 12, 0, 48),
    BackgroundColor3 = THEME.bg,
    BorderSizePixel = 0,
}, gui)
round(main, 12)
new("UIStroke", { Color = THEME.off, Thickness = 1, Transparency = 0.4 }, main)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, HEADER_H),
    BackgroundTransparency = 1,
}, main)

new("TextLabel", {
    Position = UDim2.new(0, 14, 0, 8),
    Size = UDim2.new(1, -60, 0, 20),
    BackgroundTransparency = 1,
    Text = "🎃 ESP HALLOWEEN  v37",
    TextColor3 = THEME.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local infoLabel = new("TextLabel", {
    Position = UDim2.new(0, 14, 0, 28),
    Size = UDim2.new(1, -60, 0, 16),
    BackgroundTransparency = 1,
    Text = "Portas: 0  •  Jogadores: 0",
    TextColor3 = THEME.sub,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local minBtn = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 10),
    Size = UDim2.new(0, 30, 0, 30),
    BackgroundColor3 = THEME.item,
    AutoButtonColor = false,
    Text = "–",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    BorderSizePixel = 0,
}, header)
round(minBtn, 8)

new("Frame", {
    Position = UDim2.new(0, 10, 1, -1),
    Size = UDim2.new(1, -20, 0, 1),
    BackgroundColor3 = THEME.off,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
}, header)

local body = new("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, HEADER_H),
    Size = UDim2.new(1, 0, 0, BODY_H),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = THEME.off,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, main)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, body)
new("UIPadding", {
    PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 13),
}, body)

local statusBar = new("Frame", {
    Position = UDim2.new(0, 0, 0, HEADER_H + BODY_H),
    Size = UDim2.new(1, 0, 0, STATUS_H),
    BackgroundTransparency = 1,
}, main)
new("Frame", {
    Position = UDim2.new(0, 10, 0, 0),
    Size = UDim2.new(1, -20, 0, 1),
    BackgroundColor3 = THEME.off,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
}, statusBar)
local statusLabel = new("TextLabel", {
    Position = UDim2.new(0, 14, 0, 2),
    Size = UDim2.new(1, -28, 1, -4),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = THEME.info,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextWrapped = true,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextXAlignment = Enum.TextXAlignment.Left,
}, statusBar)

local statusColors = { ok = THEME.ok, warn = THEME.warn, err = THEME.err, info = THEME.info }
local function log(msg, kind)
    statusLabel.Text = msg
    statusLabel.TextColor3 = statusColors[kind or "info"]
end

local function updateInfo()
    local n = 0
    for _ in pairs(playerESP) do n = n + 1 end
    infoLabel.Text = string.format("Portas: %d  •  Jogadores: %d", doorCount, n)
end

-- tela de carregamento
local loaded = false
local loadOverlay = new("Frame", {
    Position = UDim2.new(0, 0, 0, HEADER_H),
    Size = UDim2.new(1, 0, 0, BODY_H + STATUS_H),
    BackgroundColor3 = THEME.bg,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 20,
}, main)
round(loadOverlay, 12)
new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, -26),
    Size = UDim2.new(1, -40, 0, 20),
    BackgroundTransparency = 1,
    Text = "Carregando…",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ZIndex = 21,
}, loadOverlay)
local loadBarBg = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(1, -60, 0, 8),
    BackgroundColor3 = THEME.off,
    BorderSizePixel = 0,
    ZIndex = 21,
}, loadOverlay)
round(loadBarBg, 4)
local loadBar = new("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = THEME.accent,
    BorderSizePixel = 0,
    ZIndex = 22,
}, loadBarBg)
round(loadBar, 4)
local loadHint = new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 24),
    Size = UDim2.new(1, -40, 0, 30),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = THEME.sub,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextWrapped = true,
    ZIndex = 21,
}, loadOverlay)

local function setProgress(p, msg)
    tween(loadBar, 0.2, { Size = UDim2.new(math.clamp(p, 0, 1), 0, 1, 0) })
    if msg then loadHint.Text = msg end
end

local function stage(p, msg)
    setProgress(p, msg)
    task.wait(CONFIG.LoadDelay)
end

-- minimizar
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    statusBar.Visible = not minimized
    minBtn.Text = minimized and "+" or "–"
    main.Size = UDim2.new(0, WIDTH, 0, minimized and HEADER_H or FULL_H)
end)

-- arrastar pelo cabeçalho
do
    local dragging, dragStart, startPos = false, nil, nil
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    bind(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end

-- componentes
local order = 0
local function nextOrder()
    order = order + 1
    return order
end

local function section(text)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.sub,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = nextOrder(),
    }, body)
end

local function addButton(text, color, callback)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = color,
        AutoButtonColor = false,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(),
    }, body)
    round(b, 8)
    b.MouseEnter:Connect(function()
        tween(b, 0.12, { BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.14) })
    end)
    b.MouseLeave:Connect(function()
        tween(b, 0.12, { BackgroundColor3 = color })
    end)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function addToggle(label, default, callback)
    local row = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = THEME.item,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(),
    }, body)
    round(row, 8)
    new("TextLabel", {
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -64, 1, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = THEME.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.new(0, 38, 0, 20),
        BackgroundColor3 = THEME.off,
        BorderSizePixel = 0,
    }, row)
    round(track, 10)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.new(0, 16, 0, 16),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, track)
    round(knob, 8)

    local state = false
    local obj = {}
    function obj.set(v, silent)
        state = v
        tween(track, 0.15, { BackgroundColor3 = v and THEME.on or THEME.off })
        tween(knob, 0.15, { Position = v and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
        if not silent and callback then
            if callback(v) == false then obj.set(not v, true) end -- callback recusou
        end
    end
    function obj.get() return state end
    row.MouseButton1Click:Connect(function() obj.set(not state) end)
    obj.set(default, false)
    return obj
end

local activeSlider = nil
bind(UserInputService.InputChanged:Connect(function(i)
    if activeSlider and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
        activeSlider(i.Position.X)
    end
end))
bind(UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        activeSlider = nil
    end
end))

local function addSlider(label, min, max, default, callback)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = THEME.item,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(),
    }, body)
    round(row, 8)
    new("TextLabel", {
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -70, 0, 16),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = THEME.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local val = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 6),
        Size = UDim2.new(0, 56, 0, 16),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = THEME.accent,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    local track = new("Frame", {
        Position = UDim2.new(0, 10, 0, 32),
        Size = UDim2.new(1, -20, 0, 6),
        BackgroundColor3 = THEME.off,
        BorderSizePixel = 0,
    }, row)
    round(track, 3)
    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = THEME.accent,
        BorderSizePixel = 0,
    }, track)
    round(fill, 3)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, track)
    round(knob, 7)
    local hit = new("TextButton", {
        Position = UDim2.new(0, -6, 0.5, -12),
        Size = UDim2.new(1, 12, 0, 24),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 3,
    }, track)

    local function setRel(rel, fire)
        rel = math.clamp(rel, 0, 1)
        local v = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        val.Text = tostring(v)
        if fire and callback then callback(v) end
    end
    local function fromX(x)
        local w = track.AbsoluteSize.X
        if w > 0 then setRel((x - track.AbsolutePosition.X) / w, true) end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            activeSlider = fromX
            fromX(i.Position.X)
        end
    end)
    setRel((default - min) / (max - min), false) -- só visual, não dispara callback
end

-- =========================================================
-- ESP (texto + highlight)
-- =========================================================
local HAS_DRAWING = false
pcall(function() HAS_DRAWING = (Drawing ~= nil and Drawing.new ~= nil) end)

local function makeTag(color)
    if HAS_DRAWING then
        local d = Drawing.new("Text")
        d.Size = 14; d.Center = true; d.Outline = true
        d.Color = color; d.Visible = false; d.Text = ""
        return {
            show = function(v) d.Visible = v end,
            place = function(x, y) d.Position = Vector2.new(x, y) end,
            text = function(t) d.Text = t end,
            target = function() end,
            destroy = function() pcall(function() d:Remove() end) end,
        }
    end
    local bb = new("BillboardGui", {
        Size = UDim2.new(0, 170, 0, 22),
        StudsOffset = Vector3.new(0, 3, 0),
        AlwaysOnTop = true,
        Enabled = false,
    }, gui)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = color,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextStrokeTransparency = 0.4,
    }, bb)
    return {
        show = function(v) bb.Enabled = v end,
        place = function() end,
        text = function(t) lbl.Text = t end,
        target = function(p) if bb.Adornee ~= p then bb.Adornee = p end end,
        destroy = function() bb:Destroy() end,
    }
end

local function makeEntry(color, fill)
    local hl = new("Highlight", {
        FillColor = color,
        OutlineColor = color,
        FillTransparency = fill,
        OutlineTransparency = 0,
        DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        Enabled = false,
    }, gui)
    return { hl = hl, tag = makeTag(color) }
end

local function destroyEntry(e)
    pcall(function() e.hl:Destroy() end)
    pcall(e.tag.destroy)
end

local function hideEntry(e)
    e.hl.Enabled = false
    e.tag.show(false)
end

-- jogadores
local function addPlayer(pl)
    if pl == player or playerESP[pl] then return end
    playerESP[pl] = makeEntry(CONFIG.PlayerColor, CONFIG.PlayerFill)
    updateInfo()
end

local function removePlayer(pl)
    local e = playerESP[pl]
    if e then
        destroyEntry(e)
        playerESP[pl] = nil
        updateInfo()
    end
end

-- portas
local currentDoor = nil
local requestRescan          -- definido depois de rescanDoors
local doorPending = weak()   -- portas sem peças ainda (sendo recriadas)

local function findFirstPart(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

local function applyHold(p, orig)
    if S.reduceHold then
        if p.HoldDuration ~= CONFIG.HoldValue then
            pcall(function() p.HoldDuration = CONFIG.HoldValue end)
        end
    elseif orig ~= nil and p.HoldDuration ~= orig then
        pcall(function() p.HoldDuration = orig end)
    end
end

local function addPrompt(d, p)
    if d.prompts[p] ~= nil then return end
    d.prompts[p] = p.HoldDuration
    applyHold(p, d.prompts[p])
    d.conns[#d.conns + 1] = p:GetPropertyChangedSignal("HoldDuration"):Connect(function()
        if S.reduceHold and p.HoldDuration ~= CONFIG.HoldValue then
            pcall(function() p.HoldDuration = CONFIG.HoldValue end)
        end
    end)
end

local function scanPrompts(d)
    for _, x in ipairs(d.model:GetDescendants()) do
        if x:IsA("ProximityPrompt") then addPrompt(d, x) end
    end
end

local function registerDoor(inst, tries)
    if doors[inst] or inst.Name ~= CONFIG.DoorName then return end
    local part = findFirstPart(inst)
    if not part then
        -- porta ainda sem peças (está sendo recriada): tenta de novo em instantes
        tries = tries or 0
        if tries < 12 and not doorPending[inst] then
            doorPending[inst] = true
            task.delay(0.5, function()
                doorPending[inst] = nil
                if alive and inst.Parent then registerDoor(inst, tries + 1) end
            end)
        end
        return
    end
    local d = {
        model = inst,
        part = part,
        entry = makeEntry(CONFIG.DoorColor, CONFIG.DoorFill),
        prompts = {},
        conns = {},
    }
    d.entry.hl.Adornee = (inst:IsA("Model") or inst:IsA("BasePart")) and inst or part
    doors[inst] = d
    doorCount = doorCount + 1
    scanPrompts(d)
    updateInfo()
end

local function unregisterDoor(model)
    local d = doors[model]
    if not d then return end
    doors[model] = nil
    doorCount = doorCount - 1
    for _, c in ipairs(d.conns) do pcall(function() c:Disconnect() end) end
    destroyEntry(d.entry)
    if currentDoor == model then currentDoor = nil end
    updateInfo()
    if requestRescan and alive then requestRescan(1) end
end

local function refreshDoorPart(d)
    local now = os.clock()
    if d.nextCheck and now < d.nextCheck then return false end
    d.nextCheck = now + 0.25
    local np = findFirstPart(d.model)
    if not np then return false end
    d.part = np
    if not (d.model:IsA("Model") or d.model:IsA("BasePart")) then
        d.entry.hl.Adornee = np
    end
    return true
end

-- timer da porta (TextLabel/TextBox ou Value). Se não achar, mostra 0.
local function isTimerObj(o)
    return o.Name == CONFIG.TimerName and (o:IsA("TextLabel") or o:IsA("TextBox")
        or o:IsA("TextButton") or o:IsA("ValueBase"))
end

local function timerPos(t)
    local a = t:FindFirstAncestorWhichIsA("Attachment")
    if a then return a.WorldPosition end
    local bp = t:FindFirstAncestorWhichIsA("BasePart")
    if bp then return bp.Position end
    return nil
end

local function findTimer(d)
    -- 1) dentro da própria porta
    for _, x in ipairs(d.model:GetDescendants()) do
        if isTimerObj(x) then return x end
    end
    -- 2) em Workspace.Effects: pega o timer mais perto da porta
    local fx = Workspace:FindFirstChild("Effects")
    if fx and d.part and d.part.Parent then
        local best, bestDist = nil, CONFIG.TimerMaxDist
        for _, c in ipairs(fx:GetChildren()) do
            for _, x in ipairs(c:GetDescendants()) do
                if isTimerObj(x) then
                    local pos = timerPos(x)
                    if pos then
                        local dist = (pos - d.part.Position).Magnitude
                        if dist <= bestDist then best, bestDist = x, dist end
                    end
                end
            end
        end
        return best
    end
    return nil
end

local function readTimer(t)
    if not t or not t.Parent then return "0" end
    local ok, v = pcall(function()
        if t:IsA("ValueBase") then return tostring(t.Value) end
        return t.Text
    end)
    if not ok or v == nil then return "0" end
    local clean = tostring(v):gsub("<[^>]+>", "")
    clean = clean:match("^%s*(.-)%s*$")
    if clean == "" or not clean:find("%d") then return "0" end
    return clean
end

local function doorTimerText(d)
    local t = d.timer
    if not t or not t.Parent then
        local now = os.clock()
        if now >= (d.nextTimerCheck or 0) then
            d.nextTimerCheck = now + 1
            d.timer = findTimer(d)
            t = d.timer
        end
    end
    return readTimer(t)
end

local rescanning = false

local function doRescan()
    local n, made = 0, 0
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if not alive then return end
        if inst.Name == CONFIG.DoorName and not doors[inst] then
            registerDoor(inst)
            made = made + 1
            if made % CONFIG.BatchEntries == 0 then task.wait(CONFIG.LoadDelay) end
        end
        n = n + 1
        if n % CONFIG.ChunkSize == 0 then task.wait() end
    end
    local list = {}
    for model in pairs(doors) do list[#list + 1] = model end
    for i, model in ipairs(list) do
        local d = doors[model]
        if d then
            if not model.Parent then
                unregisterDoor(model)
            else
                if not d.part.Parent then
                    d.nextCheck = nil
                    refreshDoorPart(d)
                end
                scanPrompts(d)
            end
        end
        if i % 10 == 0 then task.wait() end
    end
end

local rescanAgain = false

local function rescanDoors()
    if rescanning then
        rescanAgain = true -- pedido durante uma varredura: roda mais uma vez no fim
        return
    end
    rescanning = true
    repeat
        rescanAgain = false
        pcall(doRescan)
    until not rescanAgain or not alive
    rescanning = false
end

local rescanQueued = false
requestRescan = function(delay)
    if rescanQueued then return end
    rescanQueued = true
    task.delay(delay or 1, function()
        rescanQueued = false
        if alive then rescanDoors() end
    end)
end

local function setReduceHold(v)
    S.reduceHold = v
    for _, d in pairs(doors) do
        for p, orig in pairs(d.prompts) do
            if p.Parent then applyHold(p, orig) end
        end
    end
end

bind(Workspace.DescendantAdded:Connect(function(inst)
    if inst.Name == CONFIG.DoorName then
        registerDoor(inst)
    elseif inst:IsA("ProximityPrompt") then
        local anc = inst:FindFirstAncestor(CONFIG.DoorName)
        local d = anc and doors[anc]
        if d then addPrompt(d, inst) end
    end
end))

bind(Workspace.DescendantRemoving:Connect(function(inst)
    if doors[inst] then unregisterDoor(inst) end
end))

bind(Players.PlayerAdded:Connect(addPlayer))
bind(Players.PlayerRemoving:Connect(removePlayer))

-- loop de renderização (um só para tudo)
bind(RunService.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if not loaded then return end
    local camPos = cam.CFrame.Position
    local used = 0

    for pl, e in pairs(playerESP) do
        local char = pl.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if S.playerESP and hrp then
            local dist = (camPos - hrp.Position).Magnitude
            local inRange = dist <= CONFIG.PlayerMaxDist
            if inRange and used < CONFIG.MaxHighlights then
                used = used + 1
                if e.hl.Adornee ~= char then e.hl.Adornee = char end
                e.hl.Enabled = true
            else
                e.hl.Enabled = false
            end
            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            local vis = inRange and onScreen
            e.tag.target(hrp)
            e.tag.show(vis)
            if vis then
                e.tag.place(pos.X, pos.Y - 30)
                e.tag.text(string.format("%s [%d]", pl.Name, math.floor(dist)))
            end
        else
            hideEntry(e)
        end
    end

    for model, d in pairs(doors) do
        local part = d.part
        if not model.Parent then
            unregisterDoor(model)
        elseif not part.Parent and not refreshDoorPart(d) then
            hideEntry(d.entry) -- porta resetando: espera as novas peças aparecerem
        else
            part = d.part
            local e = d.entry
            local dist = (camPos - part.Position).Magnitude
            local inRange = S.doorESP and dist <= CONFIG.DoorMaxDist and dist >= CONFIG.DoorMinDist
            if inRange and used < CONFIG.MaxHighlights then
                used = used + 1
                e.hl.Enabled = true
            else
                e.hl.Enabled = false
            end
            local pos, onScreen = cam:WorldToViewportPoint(part.Position)
            local vis = inRange and onScreen
            e.tag.target(part)
            e.tag.show(vis)
            if vis then
                e.tag.place(pos.X, pos.Y - 20)
                e.tag.text(string.format("Porta [%d]  |  Timer: %s", math.floor(dist), doorTimerText(d)))
            end
        end
    end
end))

-- =========================================================
-- ANTI-AFK
-- =========================================================
if CONFIG.AntiAFK then
    if getconnections then
        pcall(function()
            for _, c in ipairs(getconnections(player.Idled)) do
                pcall(function() c:Disable() end)
            end
        end)
    end
    bind(player.Idled:Connect(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end))
end

-- =========================================================
-- ABRIR PORTAS PRÓXIMAS
-- =========================================================
local function firePrompt(p)
    if fireproximityprompt then
        pcall(fireproximityprompt, p)
    else
        pcall(function()
            p:InputHoldBegin()
            task.wait(0.05)
            p:InputHoldEnd()
        end)
    end
end

local function promptPos(p, d)
    local pp = p.Parent
    if pp and pp:IsA("BasePart") then return pp.Position end
    if pp and pp:IsA("Attachment") then return pp.WorldPosition end
    return d.part.Position
end

task.spawn(function()
    local last = weak()
    while alive do
        task.wait(0.25)
        if S.autoOpen and loaded then
            local hrp = getHRP()
            if hrp then
                local now = os.clock()
                for _, d in pairs(doors) do
                    for p in pairs(d.prompts) do
                        if not p.Parent then
                            d.prompts[p] = nil
                        elseif p.Enabled then
                            local near = (hrp.Position - promptPos(p, d)).Magnitude <= CONFIG.AutoOpenRange
                            if near and (not last[p] or now - last[p] > 0.6) then
                                last[p] = now
                                firePrompt(p)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- =========================================================
-- FLY
-- =========================================================
local flyBV, flyBG, flyConn = nil, nil, nil
local flyInput = { w = false, a = false, s = false, d = false, space = false, shift = false, q = false }
local keyMap = {
    [Enum.KeyCode.W] = "w", [Enum.KeyCode.A] = "a", [Enum.KeyCode.S] = "s", [Enum.KeyCode.D] = "d",
    [Enum.KeyCode.Space] = "space", [Enum.KeyCode.LeftShift] = "shift", [Enum.KeyCode.Q] = "q",
}

local function destroyFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local hrp = getHRP()
    if hrp then pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end) end
end

local function createFly()
    local hrp = getHRP()
    if not hrp then return false end
    destroyFly()
    flyBV = new("BodyVelocity", { Velocity = Vector3.zero, MaxForce = Vector3.new(1e5, 1e5, 1e5), P = 1250 }, hrp)
    flyBG = new("BodyGyro", { MaxTorque = Vector3.new(1e5, 1e5, 1e5), P = 3000, D = 500, CFrame = hrp.CFrame }, hrp)
    flyConn = RunService.Heartbeat:Connect(function()
        local h, hum, cam = getHRP(), getHum(), Workspace.CurrentCamera
        if not h or not cam or not flyBV or not flyBV.Parent then return end
        local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
        local dir = Vector3.zero
        if flyInput.w then dir = dir + look end
        if flyInput.s then dir = dir - look end
        if flyInput.d then dir = dir + right end
        if flyInput.a then dir = dir - right end
        if flyInput.space then dir = dir + Vector3.new(0, 1, 0) end
        if flyInput.shift then dir = dir - Vector3.new(0, 1, 0) end
        -- mobile / controle: usa o analógico do Humanoid
        if dir.Magnitude == 0 and hum and hum.MoveDirection.Magnitude > 0 then
            local flat = Vector3.new(look.X, 0, look.Z)
            local fwd = flat.Magnitude > 0 and hum.MoveDirection:Dot(flat.Unit) or 0
            dir = hum.MoveDirection + Vector3.new(0, look.Y * fwd, 0)
        end
        if hum and hum.Jump then dir = dir + Vector3.new(0, 1, 0) end
        local speed = S.flyVel * (flyInput.q and CONFIG.FlyTurbo or 1)
        if dir.Magnitude > 0 then dir = dir.Unit * speed end
        flyBV.Velocity = dir
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 0.01 then
            flyBG.CFrame = CFrame.new(h.Position, h.Position + flat) -- só gira no eixo Y
        end
    end)
    return true
end

local function setFly(on)
    if on then
        if not createFly() then
            log("Sem personagem", "err")
            return false
        end
        S.fly = true
        log("Fly ligado  (WASD • Espaço/Shift • Q turbo)", "ok")
    else
        S.fly = false
        destroyFly()
        log("Fly desligado", "warn")
    end
    return true
end
onCleanup(destroyFly)

bind(UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == CONFIG.ToggleKey then main.Visible = not main.Visible end
    local k = keyMap[i.KeyCode]
    if k then flyInput[k] = true end
end))
bind(UserInputService.InputEnded:Connect(function(i)
    local k = keyMap[i.KeyCode]
    if k then flyInput[k] = false end
end))

bind(player.CharacterAdded:Connect(function()
    task.wait(1)
    if S.fly then createFly() end
end))

-- =========================================================
-- NOCLIP
-- =========================================================
local noclipConn = nil
local noclipParts = weak()

local function setNoclip(on)
    S.noclip = on
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            local c = player.Character
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    noclipParts[p] = true
                    p.CanCollide = false
                end
            end
        end)
    else
        for p in pairs(noclipParts) do
            if p.Parent then pcall(function() p.CanCollide = true end) end
        end
        noclipParts = weak()
    end
end
onCleanup(function() setNoclip(false) end)

-- =========================================================
-- VELOCIDADE
-- =========================================================
local function setSpeed(v)
    S.speed = v
    local hum = getHum()
    if hum then pcall(function() hum.WalkSpeed = v end) end
end

bind(RunService.Heartbeat:Connect(function()
    if S.speed ~= CONFIG.VelBase then
        local hum = getHum()
        if hum and hum.WalkSpeed ~= S.speed then
            pcall(function() hum.WalkSpeed = S.speed end)
        end
    end
end))
onCleanup(function()
    if S.speed ~= CONFIG.VelBase then setSpeed(CONFIG.VelBase) end
end)

-- =========================================================
-- PORTA: posição, mais próxima, grudar
-- =========================================================
local function standPosition(part)
    local dir = part.CFrame.RightVector
    local flat = Vector3.new(dir.X, 0, dir.Z)
    if flat.Magnitude < 0.1 then
        local lk = part.CFrame.LookVector
        flat = Vector3.new(lk.X, 0, lk.Z)
    end
    if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, 1) end
    flat = flat.Unit
    local pos = part.Position + flat * CONFIG.StandOffset
    pos = Vector3.new(pos.X, part.Position.Y, pos.Z)
    return pos, Vector3.new(part.Position.X, pos.Y, part.Position.Z)
end

local function nearestDoor(from, skipSet)
    local best, bestD = nil, math.huge
    for model, d in pairs(doors) do
        if d.part.Parent and not (skipSet and skipSet[model]) then
            local dist = (d.part.Position - from).Magnitude
            if dist < bestD then best, bestD = d, dist end
        end
    end
    return best, bestD
end

local grabConn, grabDoor = nil, nil

local function setGrab(on)
    if grabConn then grabConn:Disconnect(); grabConn = nil end
    grabDoor = nil
    if not on then return true end
    local hrp = getHRP()
    if not hrp then
        log("Sem personagem", "err")
        return false
    end
    local d = nearestDoor(hrp.Position)
    if not d then
        log("Nenhuma porta encontrada", "err")
        return false
    end
    grabDoor = d
    grabConn = RunService.Heartbeat:Connect(function()
        local h = getHRP()
        if not h or not grabDoor then return end
        if not grabDoor.part.Parent or not grabDoor.model.Parent then
            local nd = nearestDoor(h.Position)
            if not nd then return end -- espera as novas portas aparecerem
            grabDoor = nd
            log("Portas mudaram — grudando na mais próxima", "info")
        end
        local pos, look = standPosition(grabDoor.part)
        h.CFrame = CFrame.new(pos, look)
        h.AssemblyLinearVelocity = Vector3.zero
    end)
    log("Grudado na porta mais próxima", "ok")
    return true
end
onCleanup(function() setGrab(false) end)

-- =========================================================
-- GRUDAR NO JOGADOR MAIS PRÓXIMO
-- =========================================================
local stickConn, stickTarget, stickToggle = nil, nil, nil

local function nearestPlayerTarget(from)
    local best, bestD = nil, math.huge
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player then
            local c = pl.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if h and hum and hum.Health > 0 then
                local d = (h.Position - from).Magnitude
                if d < bestD then best, bestD = pl, d end
            end
        end
    end
    return best, bestD
end

local function setStick(on)
    if stickConn then stickConn:Disconnect(); stickConn = nil end
    stickTarget = nil
    if not on then return true end
    local hrp = getHRP()
    if not hrp then
        log("Sem personagem", "err")
        return false
    end
    local pl, dist = nearestPlayerTarget(hrp.Position)
    if not pl then
        log("Nenhum outro jogador no servidor", "err")
        return false
    end
    stickTarget = pl
    stickConn = RunService.Heartbeat:Connect(function()
        local h = getHRP()
        if not h or not stickTarget then return end
        local c = stickTarget.Character
        local th = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not th or not hum or hum.Health <= 0 then
            -- alvo morreu/saiu: passa para o jogador mais próximo
            local np = nearestPlayerTarget(h.Position)
            if not np then return end
            stickTarget = np
            log("Grudando em " .. np.Name, "info")
            return
        end
        h.CFrame = th.CFrame * CFrame.new(0, 0, CONFIG.StickOffset)
        h.AssemblyLinearVelocity = Vector3.zero
    end)
    log(string.format("Grudado em %s (%d studs)", pl.Name, math.floor(dist)), "ok")
    return true
end
onCleanup(function() setStick(false) end)

-- =========================================================
-- TELEPORTE + CAIR
-- =========================================================
local skipped = weak()
local tpRunning, tpCancel, tpTween = false, false, nil

local function flyTo(dest, lookAt, speed)
    local hrp = getHRP()
    if not hrp or tpCancel then return false end
    local dist = (dest - hrp.Position).Magnitude
    if dist < 0.1 then return true end
    tpTween = TweenService:Create(hrp,
        TweenInfo.new(dist / speed, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(dest, lookAt) })
    tpTween:Play()
    tpTween.Completed:Wait()
    tpTween = nil
    return not tpCancel
end

local function teleportAndFall(d)
    local hrp = getHRP()
    if not hrp then return end
    local finalPos, lookAt = standPosition(d.part)
    local start = hrp.Position
    local high = start.Y + CONFIG.RiseHeight

    if not flyTo(Vector3.new(start.X, high, start.Z), lookAt, CONFIG.RiseSpeed) then return end
    if not flyTo(Vector3.new(finalPos.X, high, finalPos.Z), lookAt, CONFIG.CruiseSpeed) then return end

    hrp = getHRP()
    if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.new(0, -CONFIG.FallSpeed, 0)
    local t0, lastY = os.clock(), hrp.Position.Y
    while (os.clock() - t0) < 5 and not tpCancel do
        task.wait(0.1)
        local h = getHRP()
        if not h then return end
        local y = h.Position.Y
        if math.abs(y - lastY) < 0.5 then break end
        if h.AssemblyLinearVelocity.Y > -50 then
            h.AssemblyLinearVelocity = Vector3.new(0, -CONFIG.FallSpeed, 0)
        end
        lastY = y
    end
    local h = getHRP()
    if h and not tpCancel then
        h.CFrame = CFrame.new(Vector3.new(finalPos.X, h.Position.Y, finalPos.Z), lookAt)
    end
end

local function startTeleport()
    if tpRunning then
        tpCancel = true
        if tpTween then tpTween:Cancel() end
        log("Cancelando…", "warn")
        return
    end
    local hrp = getHRP()
    if not hrp then
        log("Sem personagem", "err")
        return
    end
    local d, dist = nearestDoor(hrp.Position, skipped)
    if not d then
        log("Nenhuma porta disponível — use RESETAR PULADAS", "err")
        return
    end
    currentDoor = d.model
    tpRunning, tpCancel = true, false
    btnTP.Text = "⛔ CANCELAR TELEPORTE"
    log(string.format("Indo até a porta (%d studs)", math.floor(dist)), "info")
    task.spawn(function()
        local ok, err = pcall(teleportAndFall, d)
        tpRunning, tpTween = false, nil
        btnTP.Text = "✈️ TELEPORTAR + CAIR"
        if not ok then
            log("Erro no teleporte: " .. tostring(err), "err")
        elseif tpCancel then
            log("Teleporte cancelado", "warn")
        else
            log("Chegou na porta", "ok")
        end
    end)
end

local function skipDoor()
    if currentDoor then
        skipped[currentDoor] = true
        currentDoor = nil
        log("Porta pulada", "warn")
    else
        log("Nenhuma porta atual", "err")
    end
end

local function resetSkipped()
    skipped = weak()
    currentDoor = nil
    log("Portas puladas resetadas", "ok")
end

-- =========================================================
-- OTIMIZAR (com restauração completa)
-- =========================================================
local opt = { on = false, conn = nil, lighting = {}, quality = nil, enabled = weak(), transp = weak() }

local function optimizeInstance(o)
    if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke")
        or o:IsA("Fire") or o:IsA("Sparkles") then
        if opt.enabled[o] == nil then opt.enabled[o] = o.Enabled end
        o.Enabled = false
    elseif o:IsA("Decal") or o:IsA("Texture") then
        if opt.transp[o] == nil then opt.transp[o] = o.Transparency end
        o.Transparency = 1
    end
end

local function setOptimize(on)
    if on == opt.on then return end
    opt.on = on
    if on then
        opt.lighting = { GlobalShadows = Lighting.GlobalShadows, ShadowSoftness = Lighting.ShadowSoftness }
        pcall(function() opt.quality = settings().Rendering.QualityLevel end)
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.ShadowSoftness = 0
        end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("PostEffect") then
                opt.enabled[e] = e.Enabled
                pcall(function() e.Enabled = false end)
            end
        end
        opt.conn = Workspace.DescendantAdded:Connect(function(o)
            if opt.on then pcall(optimizeInstance, o) end
        end)
        task.spawn(function()
            local n = 0
            for _, o in ipairs(Workspace:GetDescendants()) do
                if not opt.on or not alive then return end
                pcall(optimizeInstance, o)
                n = n + 1
                if n % CONFIG.ChunkSize == 0 then task.wait(0.03) end
            end
        end)
        log("Gráficos otimizados", "ok")
    else
        if opt.conn then opt.conn:Disconnect(); opt.conn = nil end
        pcall(function()
            Lighting.GlobalShadows = opt.lighting.GlobalShadows
            Lighting.ShadowSoftness = opt.lighting.ShadowSoftness
        end)
        if opt.quality then
            pcall(function() settings().Rendering.QualityLevel = opt.quality end)
        end
        for o, v in pairs(opt.enabled) do
            if o.Parent then pcall(function() o.Enabled = v end) end
        end
        for o, v in pairs(opt.transp) do
            if o.Parent then pcall(function() o.Transparency = v end) end
        end
        opt.enabled, opt.transp = weak(), weak()
        log("Gráficos restaurados", "ok")
    end
end
onCleanup(function() setOptimize(false) end)

-- =========================================================
-- VOIDAR (sobe rápido e depois vai pro lado; desligar volta ao ponto de origem)
-- =========================================================
local voidActive, voidBusy, voidCancel = false, false, false
local voidOrigin, voidTween, voidBtn = nil, nil, nil

local function refreshVoidBtn()
    if not voidBtn then return end
    if voidBusy then
        voidBtn.Text = "⛔ CANCELAR VOID"
    elseif voidActive then
        voidBtn.Text = "↩ VOLTAR DO VOID"
    else
        voidBtn.Text = "🕳️ VOIDAR"
    end
end

local function voidMove(char, hrp, dest, speed)
    if player.Character ~= char or not hrp.Parent then return false end
    local dist = (dest - hrp.Position).Magnitude
    if dist < 0.1 then return true end
    local tw = TweenService:Create(hrp,
        TweenInfo.new(dist / speed, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(dest) * hrp.CFrame.Rotation })
    voidTween = tw
    tw:Play()
    local state = tw.Completed:Wait()
    voidTween = nil
    return state == Enum.PlaybackState.Completed and not voidCancel
end

local function voidRestore(hrp)
    if hrp and hrp.Parent then
        hrp.Anchored = false
        hrp.AssemblyLinearVelocity = Vector3.zero
        if voidOrigin then hrp.CFrame = voidOrigin end
    end
    voidActive, voidBusy, voidCancel, voidOrigin = false, false, false, nil
    refreshVoidBtn()
end

local function setVoid(on)
    if on then
        if voidActive then return true end
        if voidBusy then return false end -- ainda terminando o cancelamento anterior
        local char, hrp = player.Character, getHRP()
        if not hrp then
            log("Sem personagem", "err")
            return false
        end
        local cam = Workspace.CurrentCamera
        local right = cam and cam.CFrame.RightVector or hrp.CFrame.RightVector
        local flat = Vector3.new(right.X, 0, right.Z)
        if flat.Magnitude < 0.01 then flat = Vector3.new(1, 0, 0) end
        flat = flat.Unit
        voidOrigin = hrp.CFrame
        local up = hrp.Position + Vector3.new(0, CONFIG.VoidUp, 0)
        local side = up + flat * CONFIG.VoidSide
        voidBusy, voidCancel = true, false
        hrp.AssemblyLinearVelocity = Vector3.zero
        if CONFIG.VoidAnchor then hrp.Anchored = true end
        log("Subindo…", "info")
        refreshVoidBtn()
        task.spawn(function()
            local ok = voidMove(char, hrp, up, CONFIG.VoidRiseSpeed)
            if ok then
                log("Indo para o lado…", "info")
                ok = voidMove(char, hrp, side, CONFIG.VoidSideSpeed)
            end
            if ok then
                voidBusy, voidActive = false, true
                log("Voidado! Aperte de novo para voltar", "ok")
                refreshVoidBtn()
            else
                -- cancelado (ou o personagem trocou): volta ao ponto de origem
                if player.Character == char then
                    voidRestore(hrp)
                    log("Voidar cancelado", "warn")
                else
                    voidActive, voidBusy, voidCancel, voidOrigin = false, false, false, nil
                end
                refreshVoidBtn()
            end
        end)
    else
        if voidBusy then
            voidCancel = true
            if voidTween then voidTween:Cancel() end
        elseif voidActive then
            voidRestore(getHRP())
            log("De volta ao ponto de origem", "ok")
        end
    end
    return true
end

onCleanup(function()
    if voidBusy then
        voidCancel = true
        if voidTween then voidTween:Cancel() end
    elseif voidActive then
        pcall(setVoid, false)
    end
end)

bind(player.CharacterAdded:Connect(function()
    if voidBusy then
        voidCancel = true
        if voidTween then voidTween:Cancel() end
    elseif voidActive then
        voidActive, voidOrigin = false, nil -- morreu/renasceu: não há para onde voltar
        refreshVoidBtn()
    end
end))

-- =========================================================
-- TROCAR DE SERVIDOR
-- =========================================================
local hopping = false

local function httpGet(url)
    local ok, r = pcall(function() return game:HttpGet(url) end)
    if ok and r then return r end
    local req = request or http_request or (syn and syn.request)
    if req then
        local ok2, res = pcall(req, { Url = url, Method = "GET" })
        if ok2 and res and res.Body then return res.Body end
    end
    return nil
end

local function autoHop()
    if hopping then
        log("Já procurando servidor…", "warn")
        return
    end
    hopping = true
    task.spawn(function()
        log("Procurando servidor com poucos jogadores…", "info")
        local best, cursor, pages, failed = nil, "", 0, false
        while pages < 2 do
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
                .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end
            local body = httpGet(url)
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if not ok or type(data) ~= "table" or not data.data then
                failed = true
                log("Falha ao listar servidores (limite de requisições?)", "err")
                break
            end
            for _, sv in ipairs(data.data) do
                if sv.id ~= game.JobId and sv.playing < sv.maxPlayers then
                    if not best or sv.playing < best.playing then best = sv end
                end
            end
            pages = pages + 1
            if type(data.nextPageCursor) ~= "string" then break end
            cursor = data.nextPageCursor
        end
        if best then
            log(string.format("Entrando em servidor (%d/%d)", best.playing, best.maxPlayers), "ok")
            local ok, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, player)
            end)
            if not ok then log("Erro ao teleportar: " .. tostring(err), "err") end
            task.delay(15, function() hopping = false end)
        else
            if not failed then log("Nenhum servidor disponível", "err") end
            hopping = false
        end
    end)
end

bind(TeleportService.TeleportInitFailed:Connect(function(_, _, msg)
    hopping = false
    log("Teleporte falhou: " .. tostring(msg), "err")
end))

-- =========================================================
-- CONTROLES (monta o menu)
-- =========================================================
stage(0.1, "Montando menu…")
section("VISUAL")
addToggle("ESP Jogadores", S.playerESP, function(v) S.playerESP = v end)
addToggle("ESP Portas", S.doorESP, function(v) S.doorESP = v end)

section("AUTOMAÇÃO")
addToggle("Abrir portas próximas", S.autoOpen, function(v) S.autoOpen = v end)
addToggle("Hold instantâneo", S.reduceHold, setReduceHold)
grabToggle = addToggle("Grudar na porta mais próxima", false, function(v)
    if v and stickToggle and stickToggle.get() then stickToggle.set(false) end
    return setGrab(v)
end)
stickToggle = addToggle("Grudar no jogador mais próximo", false, function(v)
    if v and grabToggle and grabToggle.get() then grabToggle.set(false) end
    return setStick(v)
end)

stage(0.25, "Montando menu…")
section("TELEPORTE")
btnTP = addButton("✈️ TELEPORTAR + CAIR", THEME.purple, startTeleport)
voidBtn = addButton("🕳️ VOIDAR", Color3.fromRGB(90, 90, 125), function()
    if voidActive or voidBusy then setVoid(false) else setVoid(true) end
end)
addButton("⏭️ Pular porta", Color3.fromRGB(235, 140, 50), skipDoor)
addButton("🔄 Resetar puladas", THEME.blue, resetSkipped)

section("MOVIMENTO")
addToggle("Fly  (Q = turbo)", false, setFly)
addSlider("Velocidade do fly", 20, 250, CONFIG.FlyVel, function(v) S.flyVel = v end)
addToggle("Noclip", false, setNoclip)
addSlider("Velocidade de corrida", CONFIG.VelBase, CONFIG.VelMax, CONFIG.VelBase, setSpeed)

stage(0.4, "Montando menu…")
section("SISTEMA")
addButton("🔍 Escanear agora", THEME.blue, function()
    log("Escaneando…", "info")
    rescanDoors()
    updateInfo()
    log(string.format("%d portas encontradas", doorCount), "ok")
end)
addToggle("Otimizar gráficos", false, setOptimize)
addButton("🌐 Trocar de servidor (poucos jogadores)", THEME.red, autoHop)

-- =========================================================
-- INICIALIZAÇÃO
-- =========================================================
local function cleanup()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for _, fn in ipairs(cleanups) do pcall(fn) end
    for _, e in pairs(playerESP) do pcall(destroyEntry, e) end
    for _, d in pairs(doors) do
        for _, c in ipairs(d.conns) do pcall(function() c:Disconnect() end) end
        pcall(destroyEntry, d.entry)
    end
    pcall(function() gui:Destroy() end)
    env.__ESP_HALLOWEEN_CLEANUP = nil
end
env.__ESP_HALLOWEEN_CLEANUP = cleanup -- registrado cedo: reexecutar durante o carregamento também limpa

-- carregamento em etapas
stage(0.5, "Carregando jogadores…")
if not alive then return end
do
    local made = 0
    for _, pl in ipairs(Players:GetPlayers()) do
        if not alive then return end
        addPlayer(pl)
        made = made + 1
        if made % CONFIG.BatchEntries == 0 then task.wait(CONFIG.LoadDelay) end
    end
end
updateInfo()

setProgress(0.65, "Procurando portas… (pode demorar em mapas grandes)")
rescanDoors()
if not alive then return end
updateInfo()

stage(0.9, "Finalizando…")
if not alive then return end

task.spawn(function()
    while alive do
        task.wait(CONFIG.RescanInterval)
        if alive then pcall(rescanDoors) end
    end
end)

loaded = true
setProgress(1, "Pronto!")
task.wait(0.3)
loadOverlay:Destroy()

log(string.format("v37 pronta  •  %d portas  •  RightCtrl oculta o painel", doorCount), "ok")
