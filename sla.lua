-- LISTENER GLOBAL

local ok, genv = pcall(getgenv)
if not ok or not genv then
    warn("[LISTENER] getgenv() não suportado")
    return
end

if genv.ListenerLoaded then
    warn("Listener já tá rodando")
    return
end

genv.ListenerLoaded = true

local event      = Instance.new("BindableEvent")
local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local Camera     = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
genv.ListenerEvent = event

-- ==================== ESTADOS ====================

local states = {
    RChams = false,
    GChams = false,
    BChams = false,
    WCK    = false,
    Line   = false,
    Box    = false,
    HP     = false,
    Fly    = false  -- Fly unificado (float + voo)
}

local colors = {
    R = Color3.fromRGB(255, 0, 0),
    G = Color3.fromRGB(0, 255, 0),
    B = Color3.fromRGB(0, 0, 255)
}

-- ==================== FLY + FLOAT UNIFICADO ====================
-- Uma função só: 
-- - Quando ativado, fica parado no ar (float)
-- - Apertou WASD = voa (fly)
-- - Soltou WASD = para no ar de novo

local flyData = {
    active = false,
    speed = 50,
    bodyVelocity = nil,
    originalGravity = nil,
    connection = nil,
    movingDirections = {
        forward = false,
        backward = false,
        left = false,
        right = false,
        up = false,
        down = false
    }
}

local function createFlyBodyVelocity(character)
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    if flyData.bodyVelocity and flyData.bodyVelocity.Parent then
        flyData.bodyVelocity:Destroy()
    end
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = humanoidRootPart
    
    return bodyVelocity
end

local function setupFlyInputs()
    local context = "FlyContext"
    
    local function handleAction(actionName, inputState, inputObject)
        if not flyData.active then return Enum.ContextActionResult.Pass end
        
        if inputState == Enum.UserInputState.Begin then
            if actionName == "Forward" then
                flyData.movingDirections.forward = true
            elseif actionName == "Backward" then
                flyData.movingDirections.backward = true
            elseif actionName == "Left" then
                flyData.movingDirections.left = true
            elseif actionName == "Right" then
                flyData.movingDirections.right = true
            elseif actionName == "Up" then
                flyData.movingDirections.up = true
            elseif actionName == "Down" then
                flyData.movingDirections.down = true
            end
        elseif inputState == Enum.UserInputState.End then
            if actionName == "Forward" then
                flyData.movingDirections.forward = false
            elseif actionName == "Backward" then
                flyData.movingDirections.backward = false
            elseif actionName == "Left" then
                flyData.movingDirections.left = false
            elseif actionName == "Right" then
                flyData.movingDirections.right = false
            elseif actionName == "Up" then
                flyData.movingDirections.up = false
            elseif actionName == "Down" then
                flyData.movingDirections.down = false
            end
        end
        
        return Enum.ContextActionResult.Sink
    end
    
    ContextActionService:BindActionAtPriority(context .. "Forward", handleAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.W)
    ContextActionService:BindActionAtPriority(context .. "Backward", handleAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.S)
    ContextActionService:BindActionAtPriority(context .. "Left", handleAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.A)
    ContextActionService:BindActionAtPriority(context .. "Right", handleAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.D)
    ContextActionService:BindActionAtPriority(context .. "Up", handleAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space)
    ContextActionService:BindActionAtPriority(context .. "Down", handleAction, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.LeftControl)
end

local function removeFlyInputs()
    ContextActionService:UnbindAction("FlyContextForward")
    ContextActionService:UnbindAction("FlyContextBackward")
    ContextActionService:UnbindAction("FlyContextLeft")
    ContextActionService:UnbindAction("FlyContextRight")
    ContextActionService:UnbindAction("FlyContextUp")
    ContextActionService:UnbindAction("FlyContextDown")
end

local function updateFlyVelocity()
    if not flyData.active then return end
    
    local player = Players.LocalPlayer
    if not player or not player.Character then return end
    
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if not flyData.bodyVelocity or not flyData.bodyVelocity.Parent then
        flyData.bodyVelocity = createFlyBodyVelocity(player.Character)
    end
    
    -- Verifica se tem alguma tecla pressionada
    local hasInput = false
    for _, v in pairs(flyData.movingDirections) do
        if v then hasInput = true break end
    end
    
    if not hasInput then
        -- Nenhuma tecla: fica PARADO no ar (FLOAT)
        if flyData.bodyVelocity then
            flyData.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        return
    end
    
    -- Tem tecla pressionada: VOA (FLY)
    local moveDirection = Vector3.new(0, 0, 0)
    local cameraCFrame = Camera.CFrame
    
    if flyData.movingDirections.forward then
        moveDirection = moveDirection + cameraCFrame.LookVector
    end
    if flyData.movingDirections.backward then
        moveDirection = moveDirection - cameraCFrame.LookVector
    end
    if flyData.movingDirections.left then
        moveDirection = moveDirection - cameraCFrame.RightVector
    end
    if flyData.movingDirections.right then
        moveDirection = moveDirection + cameraCFrame.RightVector
    end
    if flyData.movingDirections.up then
        moveDirection = moveDirection + Vector3.new(0, 1, 0)
    end
    if flyData.movingDirections.down then
        moveDirection = moveDirection - Vector3.new(0, 1, 0)
    end
    
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit * flyData.speed
    end
    
    if flyData.bodyVelocity then
        flyData.bodyVelocity.Velocity = moveDirection
    end
end

local function startFly()
    if flyData.active then return end
    
    local player = Players.LocalPlayer
    if not player or not player.Character then
        warn("[FLY] Personagem não encontrado")
        return
    end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then
        warn("[FLY] Humanoid não encontrado")
        return
    end
    
    -- Salvar gravidade original e zerar
    flyData.originalGravity = workspace.Gravity
    workspace.Gravity = 0
    
    -- Criar BodyVelocity
    flyData.bodyVelocity = createFlyBodyVelocity(player.Character)
    
    if not flyData.bodyVelocity then
        warn("[FLY] Falha ao criar BodyVelocity")
        return
    end
    
    -- Desabilitar estados do humanoid
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    humanoid.PlatformStand = true
    
    flyData.active = true
    
    -- Configurar inputs
    setupFlyInputs()
    
    -- Conectar loop de atualização
    flyData.connection = RunService.RenderStepped:Connect(updateFlyVelocity)
    
    print("[FLY] ATIVADO - Modo UNIFICADO (Float + Fly)")
    print("[FLY] Velocidade:", flyData.speed)
    print("[FLY] Sem teclas = flutua | WASD = voa | Espaço/Ctrl = sobe/desce")
end

local function stopFly()
    if not flyData.active then return end
    
    -- Remover BodyVelocity
    if flyData.bodyVelocity then
        flyData.bodyVelocity:Destroy()
        flyData.bodyVelocity = nil
    end
    
    -- Restaurar gravidade
    if flyData.originalGravity then
        workspace.Gravity = flyData.originalGravity
        flyData.originalGravity = nil
    else
        workspace.Gravity = 196.2
    end
    
    local player = Players.LocalPlayer
    if player and player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid.PlatformStand = false
        end
    end
    
    -- Remover inputs
    removeFlyInputs()
    
    -- Desconectar loop
    if flyData.connection then
        flyData.connection:Disconnect()
        flyData.connection = nil
    end
    
    -- Resetar direções
    for k in pairs(flyData.movingDirections) do
        flyData.movingDirections[k] = false
    end
    
    flyData.active = false
    print("[FLY] DESATIVADO")
end

local function flyControl(state)
    if state then
        startFly()
    else
        stopFly()
    end
end

local function setFlySpeed(speed)
    if type(speed) == "number" and speed > 0 then
        flyData.speed = math.clamp(speed, 10, 500)
        print("[FLY] Velocidade ajustada para:", flyData.speed)
    end
end

-- ==================== ESP ====================

local ESP = {}

local function createESP(player)
    if player == Players.LocalPlayer then return end
    if ESP[player] then return end

    ESP[player] = {
        Tracer = Drawing.new("Line"),
        Lines  = {},
        HpBg   = Drawing.new("Square"),
        Hp     = Drawing.new("Square"),
        HpText = Drawing.new("Text")
    }

    local d = ESP[player]

    d.Tracer.Color        = Color3.fromRGB(255, 50, 50)
    d.Tracer.Thickness    = 1
    d.Tracer.Transparency = 1
    d.Tracer.Visible      = false

    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Color        = Color3.fromRGB(255, 50, 50)
        line.Thickness    = 1
        line.Transparency = 1
        line.Visible      = false
        table.insert(d.Lines, line)
    end

    d.HpBg.Filled       = true
    d.HpBg.Color        = Color3.fromRGB(30, 30, 30)
    d.HpBg.Transparency = 1
    d.HpBg.Thickness    = 0
    d.HpBg.Visible      = false

    d.Hp.Filled       = true
    d.Hp.Color        = Color3.fromRGB(0, 255, 0)
    d.Hp.Transparency = 1
    d.Hp.Thickness    = 0
    d.Hp.Visible      = false

    d.HpText.Size    = 13
    d.HpText.Color   = Color3.fromRGB(255, 255, 255)
    d.HpText.Outline = true
    d.HpText.Visible = false
end

local function removeESP(player)
    if not ESP[player] then return end
    local d = ESP[player]
    d.Tracer:Remove()
    d.HpBg:Remove()
    d.Hp:Remove()
    d.HpText:Remove()
    for _, l in pairs(d.Lines) do l:Remove() end
    ESP[player] = nil
end

local function hideESP(player)
    if not ESP[player] then return end
    local d = ESP[player]
    d.Tracer.Visible  = false
    d.HpBg.Visible    = false
    d.Hp.Visible      = false
    d.HpText.Visible  = false
    for _, l in pairs(d.Lines) do l.Visible = false end
end

for _, p in pairs(Players:GetPlayers()) do
    createESP(p)
end

-- ==================== RENDER LOOP ESP ====================

RunService.RenderStepped:Connect(function()
    for player, data in pairs(ESP) do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")

        if root then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then
                local x     = pos.X
                local y     = pos.Y
                local size  = math.clamp(2000 / pos.Z, 20, 500)
                local halfW = size * 0.4

                local tl = Vector2.new(x - halfW, y - size)
                local tr = Vector2.new(x + halfW, y - size)
                local bl = Vector2.new(x - halfW, y + size * 0.1)
                local br = Vector2.new(x + halfW, y + size * 0.1)

                -- TRACER
                if states.Line then
                    data.Tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    data.Tracer.To      = Vector2.new(x, y)
                    data.Tracer.Visible = true
                else
                    data.Tracer.Visible = false
                end

                -- BOX
                if states.Box then
                    data.Lines[1].From = tl  data.Lines[1].To = tr  data.Lines[1].Visible = true
                    data.Lines[2].From = tr  data.Lines[2].To = br  data.Lines[2].Visible = true
                    data.Lines[3].From = br  data.Lines[3].To = bl  data.Lines[3].Visible = true
                    data.Lines[4].From = bl  data.Lines[4].To = tl  data.Lines[4].Visible = true
                else
                    for _, l in pairs(data.Lines) do l.Visible = false end
                end

                -- HP
                if states.HP then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then
                        local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local r     = math.floor(255 * (1 - ratio))
                        local g     = math.floor(255 * ratio)
                        local barW  = 4
                        local barX  = tl.X - barW - 3
                        local barH  = bl.Y - tl.Y
                        local fillH = math.max(1, barH * ratio)

                        data.HpBg.Position = Vector2.new(barX, tl.Y)
                        data.HpBg.Size     = Vector2.new(barW, barH)
                        data.HpBg.Visible  = true

                        data.Hp.Color    = Color3.fromRGB(r, g, 0)
                        data.Hp.Position = Vector2.new(barX, tl.Y + (barH - fillH))
                        data.Hp.Size     = Vector2.new(barW, fillH)
                        data.Hp.Visible  = true

                        data.HpText.Text     = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                        data.HpText.Position = Vector2.new(tl.X, tl.Y - 16)
                        data.HpText.Visible  = true
                    end
                else
                    data.HpBg.Visible   = false
                    data.Hp.Visible     = false
                    data.HpText.Visible = false
                end

            else
                hideESP(player)
            end
        else
            hideESP(player)
        end
    end
end)

-- ==================== FV ====================

local fv = {
    active        = false,
    mode          = "rg",
    radius        = 150,
    currentTarget = nil,
    lastTarget    = nil,
    circle        = nil,
    connection    = nil
}

local function createCircle()
    if fv.circle then fv.circle:Remove() end
    local c = Drawing.new("Circle")
    c.Radius       = fv.radius
    c.Thickness    = 2
    c.Color        = Color3.fromRGB(255, 50, 50)
    c.Filled       = false
    c.Visible      = true
    c.Transparency = 1
    c.NumSides     = 64
    c.Position     = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fv.circle = c
end

local function removeCircle()
    if fv.circle then
        fv.circle:Remove()
        fv.circle = nil
    end
end

-- ==================== HELPERS ====================

local function getHeadPos(player)
    if not player or not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head")
    if head then return head.Position end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position + Vector3.new(0, 2, 0) end
    return nil
end

local function getScreenPos(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function hasLOS(from, to, targetChar)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ex = {}
    local lc = Players.LocalPlayer.Character
    if lc then table.insert(ex, lc) end
    if targetChar then table.insert(ex, targetChar) end
    params.FilterDescendantsInstances = ex
    return workspace:Raycast(from, to - from, params) == nil
end

-- ==================== FV CONTROL ====================

local function fvControl(state, mode)
    if state then
        if fv.active then return end
        fv.active     = true
        fv.lastTarget = nil
        if mode then fv.mode = mode end
        print("[FV] ATIVADO - Modo:", fv.mode, "| Raio:", fv.radius)
        createCircle()

        fv.connection = RunService.RenderStepped:Connect(function()
            if not fv.active then return end

            local lp = Players.LocalPlayer
            if not lp or not lp.Character then
                fv.currentTarget = nil
                return
            end

            local localPos = getHeadPos(lp)
            if not localPos then
                fv.currentTarget = nil
                return
            end

            local closest, closestDist = nil, fv.radius

            for _, player in pairs(Players:GetPlayers()) do
                if player ~= lp then
                    local hp = getHeadPos(player)
                    if hp then
                        local sp = getScreenPos(hp)
                        if sp then
                            local dist = (sp - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                            if dist <= fv.radius and dist < closestDist then
                                local canTarget = true
                                if states.WCK then
                                    canTarget = hasLOS(localPos, hp, player.Character)
                                end
                                if canTarget then
                                    closestDist = dist
                                    closest     = player
                                end
                            end
                        end
                    end
                end
            end

            if closest then
                fv.currentTarget = closest
                local hp = getHeadPos(closest)
                if hp then
                    local cf = CFrame.new(Camera.CFrame.Position, hp)

                    if fv.mode == "rg" then
                        Camera.CFrame = cf

                        if closest ~= fv.lastTarget then
                            fv.lastTarget = closest
                            mouse1click()
                        end

                    elseif fv.mode == "lg" then
                        Camera.CFrame = Camera.CFrame:Lerp(cf, 0.3)
                    end
                end
            else
                fv.currentTarget = nil
                fv.lastTarget    = nil
            end
        end)
    else
        if not fv.active then return end
        fv.active     = false
        fv.lastTarget = nil
        if fv.connection then
            fv.connection:Disconnect()
            fv.connection = nil
        end
        print("[FV] DESATIVADO")
        removeCircle()
        fv.currentTarget = nil
    end
end

local function fvSetRadius(radius)
    if type(radius) == "number" and radius > 0 then
        fv.radius = radius
        if fv.circle then fv.circle.Radius = radius end
        print("[FV] Raio:", radius)
    end
end

local function fvSetMode(mode)
    if mode == "rg" or mode == "lg" then
        fv.mode = mode
        print("[FV] Modo:", mode == "rg" and "Automático" or "Smooth")
    end
end

-- ==================== CHAMS ====================

local highlights = {}

local function applyHighlight(player, color, colorName)
    if not player or not player.Character then return end
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end

    if highlights[player] and highlights[player][colorName] then
        for _, h in pairs(highlights[player][colorName]) do
            if h and h.Parent then h:Destroy() end
        end
        highlights[player][colorName] = nil
    end

    local hl = Instance.new("Highlight")
    hl.Name                = colorName .. "_Highlight"
    hl.FillColor           = color
    hl.FillTransparency    = 0.5
    hl.OutlineColor        = color
    hl.OutlineTransparency = 0.3
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = player.Character

    if not highlights[player] then highlights[player] = {} end
    if not highlights[player][colorName] then highlights[player][colorName] = {} end
    table.insert(highlights[player][colorName], hl)
end

local function removeHighlights(player, colorName)
    if not highlights[player] then return end
    if colorName then
        if highlights[player][colorName] then
            for _, h in pairs(highlights[player][colorName]) do
                if h and h.Parent then h:Destroy() end
            end
            highlights[player][colorName] = nil
        end
    else
        for _, ch in pairs(highlights[player]) do
            for _, h in pairs(ch) do
                if h and h.Parent then h:Destroy() end
            end
        end
        highlights[player] = nil
    end
end

local function applyToAll(color, colorName)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then applyHighlight(p, color, colorName) end
    end
end

local function removeFromAll(colorName)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then removeHighlights(p, colorName) end
    end
end

-- ==================== OBSERVERS ====================

local observers = {}

local function reapply(player)
    if states.RChams then applyHighlight(player, colors.R, "R") end
    if states.GChams then applyHighlight(player, colors.G, "G") end
    if states.BChams then applyHighlight(player, colors.B, "B") end
end

local function setupObserver(player)
    if player == Players.LocalPlayer then return end
    if observers[player] then return end

    observers[player] = {
        added = player.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if player.Character == char then
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then reapply(player) end
            end
        end),
        removing = player.CharacterRemoving:Connect(function()
            if states.RChams then removeHighlights(player, "R") end
            if states.GChams then removeHighlights(player, "G") end
            if states.BChams then removeHighlights(player, "B") end
            hideESP(player)
        end)
    }
end

for _, p in pairs(Players:GetPlayers()) do
    if p ~= Players.LocalPlayer then setupObserver(p) end
end

Players.PlayerAdded:Connect(function(player)
    if player == Players.LocalPlayer then return end
    createESP(player)
    setupObserver(player)
    task.wait(0.5)
    if states.RChams then applyHighlight(player, colors.R, "R") end
    if states.GChams then applyHighlight(player, colors.G, "G") end
    if states.BChams then applyHighlight(player, colors.B, "B") end
end)

Players.PlayerRemoving:Connect(function(player)
    if observers[player] then
        if observers[player].added   then observers[player].added:Disconnect()   end
        if observers[player].removing then observers[player].removing:Disconnect() end
        observers[player] = nil
    end
    removeHighlights(player)
    removeESP(player)
end)

-- ==================== FEATURE CONTROLS ====================

local function rChamsControl(state)
    if state then
        if states.RChams then return end
        states.RChams = true
        print("[RChams] ATIVADO")
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer then setupObserver(p) end
        end
        applyToAll(colors.R, "R")
    else
        if not states.RChams then return end
        states.RChams = false
        print("[RChams] DESATIVADO")
        removeFromAll("R")
    end
end

local function gChamsControl(state)
    if state then
        if states.GChams then return end
        states.GChams = true
        print("[GChams] ATIVADO")
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer then setupObserver(p) end
        end
        applyToAll(colors.G, "G")
    else
        if not states.GChams then return end
        states.GChams = false
        print("[GChams] DESATIVADO")
        removeFromAll("G")
    end
end

local function bChamsControl(state)
    if state then
        if states.BChams then return end
        states.BChams = true
        print("[BChams] ATIVADO")
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= Players.LocalPlayer then setupObserver(p) end
        end
        applyToAll(colors.B, "B")
    else
        if not states.BChams then return end
        states.BChams = false
        print("[BChams] DESATIVADO")
        removeFromAll("B")
    end
end

local function lineControl(state)
    states.Line = state
    print("[LINE]", state and "ATIVADO" or "DESATIVADO")
    if not state then
        for _, d in pairs(ESP) do d.Tracer.Visible = false end
    end
end

local function boxControl(state)
    states.Box = state
    print("[BOX]", state and "ATIVADO" or "DESATIVADO")
    if not state then
        for _, d in pairs(ESP) do
            for _, l in pairs(d.Lines) do l.Visible = false end
        end
    end
end

local function hpControl(state)
    states.HP = state
    print("[HP]", state and "ATIVADO" or "DESATIVADO")
    if not state then
        for _, d in pairs(ESP) do
            d.HpBg.Visible   = false
            d.Hp.Visible     = false
            d.HpText.Visible = false
        end
    end
end

local function wckControl(state)
    states.WCK = state
    print("[WCK]", state and "ATIVADO" or "DESATIVADO")
end

-- ==================== FEATURES ====================

local features = {
    RChams   = rChamsControl,
    GChams   = gChamsControl,
    BChams   = bChamsControl,
    FV       = fvControl,
    FVRadius = fvSetRadius,
    FVMode   = fvSetMode,
    WCK      = wckControl,
    Line     = lineControl,
    Box      = boxControl,
    HP       = hpControl,
    Fly      = flyControl,
    FlySpeed = setFlySpeed
}

-- ==================== LISTENER ====================

event.Event:Connect(function(feature, cmd, extra)
    if type(feature) ~= "string" or type(cmd) ~= "string" then return end

    local fn = features[feature]
    if not fn then warn("Feature não existe:", feature) return end

    if feature == "FV" then
        if cmd == "ON"         then fn(true, extra)
        elseif cmd == "OFF"    then fn(false)
        elseif cmd == "TOGGLE" then fn(not fv.active, extra) end
    elseif feature == "FVRadius" then
        local r = tonumber(cmd)
        if r then fn(r) end
    elseif feature == "FVMode" then
        fn(cmd)
    elseif feature == "Fly" then
        if cmd == "ON" then
            fn(true)
            states.Fly = true
        elseif cmd == "OFF" then
            fn(false)
            states.Fly = false
        elseif cmd == "TOGGLE" then
            fn(not states.Fly)
            states.Fly = not states.Fly
        end
    elseif feature == "FlySpeed" then
        local s = tonumber(cmd)
        if s then fn(s) end
    else
        if cmd == "ON"         then fn(true)
        elseif cmd == "OFF"    then fn(false)
        elseif cmd == "TOGGLE" then fn(not states[feature])
        else warn("Comando inválido:", cmd) end
    end

    print("[LISTENER]", feature, cmd, extra or "")
end)

print("[LISTENER] carregado 🔥")
print("[COMANDOS] RChams, GChams, BChams, WCK, Line, Box, HP: ON, OFF, TOGGLE")
print("[COMANDOS] FV: ON, OFF, TOGGLE | FVRadius: [numero] | FVMode: rg / lg")
print("[COMANDOS] Fly: ON, OFF, TOGGLE | FlySpeed: [numero]")
print("[FLY UNIFICADO] Sem teclas = flutua (FLOAT) | WASD = voa (FLY) | Espaço/Ctrl = sobe/desce")
