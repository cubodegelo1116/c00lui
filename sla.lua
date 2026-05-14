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
local Camera     = workspace.CurrentCamera
genv.ListenerEvent = event

-- ==================== ESTADOS E CORES ====================

local states = {
    RChams = false,
    GChams = false,
    BChams = false,
    WCK    = false,
    Line   = false,
    Box    = false,
    HP     = false
}

local colors = {
    R = Color3.fromRGB(255, 0, 0),
    G = Color3.fromRGB(0, 255, 0),
    B = Color3.fromRGB(0, 0, 255)
}

local activeEffects = {
    highlights     = {},
    observers      = {},
    esp            = {},   -- { [player] = { tracer, lines={}, hpBg, hp, hpText } }
    drawConnection = nil,
    fv = {
        active        = false,
        mode          = "rg",
        radius        = 150,
        currentTarget = nil,
        circleGui     = nil,
        connection    = nil
    }
}

-- ==================== FV CIRCLE ====================

local function createCircleGui()
    if activeEffects.fv.circleGui then
        activeEffects.fv.circleGui:Remove()
        activeEffects.fv.circleGui = nil
    end
    local circle = Drawing.new("Circle")
    circle.Radius       = activeEffects.fv.radius
    circle.Thickness    = 2
    circle.Color        = Color3.fromRGB(255, 50, 50)
    circle.Filled       = false
    circle.Visible      = true
    circle.Transparency = 0.7
    circle.NumSides     = 64
    circle.Position     = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    activeEffects.fv.circleGui = circle
end

local function updateCircleSize(radius)
    activeEffects.fv.radius = radius
    if activeEffects.fv.circleGui then
        activeEffects.fv.circleGui.Radius = radius
    end
end

local function removeCircleGui()
    if activeEffects.fv.circleGui then
        activeEffects.fv.circleGui:Remove()
        activeEffects.fv.circleGui = nil
    end
end

-- ==================== HELPERS ====================

local function getHeadPosition(player)
    if not player or not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head")
    if head then return head.Position end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position + Vector3.new(0, 2, 0) end
    return nil
end

local function getScreenPosition(position)
    local sp, onScreen = Camera:WorldToViewportPoint(position)
    if not onScreen then return nil end
    return Vector2.new(sp.X, sp.Y)
end

local function getDistanceFromCenter(screenPos)
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    return (screenPos - center).Magnitude
end

local function hasLineOfSight(fromPos, toPos, targetCharacter)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    local localChar = game.Players.LocalPlayer.Character
    if localChar then table.insert(exclude, localChar) end
    if targetCharacter then table.insert(exclude, targetCharacter) end
    params.FilterDescendantsInstances = exclude
    return workspace:Raycast(fromPos, toPos - fromPos, params) == nil
end

local function getPlayerHealth(player)
    if not player or not player.Character then return 0, 100 end
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hum then return 0, 100 end
    return hum.Health, hum.MaxHealth
end

-- ==================== ESP CREATE / REMOVE ====================

local function createESP(player)
    if player == game.Players.LocalPlayer then return end
    if activeEffects.esp[player] then return end

    local data = {
        tracer  = Drawing.new("Line"),
        lines   = {},
        hpBg    = Drawing.new("Square"),
        hp      = Drawing.new("Square"),
        hpText  = Drawing.new("Text")
    }

    -- tracer
    data.tracer.Color        = Color3.fromRGB(255, 50, 50)
    data.tracer.Thickness    = 1
    data.tracer.Transparency = 0
    data.tracer.Visible      = false

    -- box (4 linhas)
    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Color        = Color3.fromRGB(255, 50, 50)
        l.Thickness    = 1
        l.Transparency = 0
        l.Visible      = false
        table.insert(data.lines, l)
    end

    -- hp bg
    data.hpBg.Filled       = true
    data.hpBg.Color        = Color3.fromRGB(30, 30, 30)
    data.hpBg.Transparency = 0
    data.hpBg.Thickness    = 0
    data.hpBg.Visible      = false

    -- hp bar
    data.hp.Filled       = true
    data.hp.Color        = Color3.fromRGB(0, 255, 0)
    data.hp.Transparency = 0
    data.hp.Thickness    = 0
    data.hp.Visible      = false

    -- hp text
    data.hpText.Size    = 13
    data.hpText.Color   = Color3.fromRGB(255, 255, 255)
    data.hpText.Outline = true
    data.hpText.Visible = false

    activeEffects.esp[player] = data
end

local function removeESP(player)
    if not activeEffects.esp[player] then return end
    local data = activeEffects.esp[player]
    data.tracer:Remove()
    data.hpBg:Remove()
    data.hp:Remove()
    data.hpText:Remove()
    for _, l in pairs(data.lines) do l:Remove() end
    activeEffects.esp[player] = nil
end

local function hideESP(player)
    if not activeEffects.esp[player] then return end
    local data = activeEffects.esp[player]
    data.tracer.Visible  = false
    data.hpBg.Visible    = false
    data.hp.Visible      = false
    data.hpText.Visible  = false
    for _, l in pairs(data.lines) do l.Visible = false end
end

-- ==================== ESP UPDATE ====================

local function updateESP(player)
    if player == game.Players.LocalPlayer then return end

    local data = activeEffects.esp[player]
    if not data then return end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if not root then
        hideESP(player)
        return
    end

    local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

    if not onScreen then
        hideESP(player)
        return
    end

    local screenPos = Vector2.new(pos.X, pos.Y)

    -- calcula tamanho da box baseado na distância (depth = pos.Z)
    local depth    = pos.Z
    local boxH     = math.clamp(2000 / depth, 20, 500)
    local boxW     = boxH * 0.6

    local cx = screenPos.X
    local cy = screenPos.Y

    local tl = Vector2.new(cx - boxW / 2, cy - boxH / 2)
    local tr = Vector2.new(cx + boxW / 2, cy - boxH / 2)
    local bl = Vector2.new(cx - boxW / 2, cy + boxH / 2)
    local br = Vector2.new(cx + boxW / 2, cy + boxH / 2)

    -- LINE
    if states.Line then
        data.tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        data.tracer.To      = screenPos
        data.tracer.Visible = true
    else
        data.tracer.Visible = false
    end

    -- BOX
    if states.Box then
        data.lines[1].From = tl  data.lines[1].To = tr  data.lines[1].Visible = true
        data.lines[2].From = tr  data.lines[2].To = br  data.lines[2].Visible = true
        data.lines[3].From = br  data.lines[3].To = bl  data.lines[3].Visible = true
        data.lines[4].From = bl  data.lines[4].To = tl  data.lines[4].Visible = true
    else
        for _, l in pairs(data.lines) do l.Visible = false end
    end

    -- HP
    if states.HP then
        local health, maxHealth = getPlayerHealth(player)
        local ratio  = maxHealth > 0 and (health / maxHealth) or 0
        local r      = math.floor(255 * (1 - ratio))
        local g      = math.floor(255 * ratio)
        local barW   = 4
        local barX   = tl.X - barW - 3
        local barH   = br.Y - tl.Y
        local fillH  = math.max(1, barH * ratio)

        data.hpBg.Position = Vector2.new(barX, tl.Y)
        data.hpBg.Size     = Vector2.new(barW, barH)
        data.hpBg.Visible  = true

        data.hp.Color    = Color3.fromRGB(r, g, 0)
        data.hp.Position = Vector2.new(barX, tl.Y + (barH - fillH))
        data.hp.Size     = Vector2.new(barW, fillH)
        data.hp.Visible  = true

        data.hpText.Text     = math.floor(health) .. "/" .. math.floor(maxHealth)
        data.hpText.Position = Vector2.new(tl.X, tl.Y - 16)
        data.hpText.Visible  = true
    else
        data.hpBg.Visible   = false
        data.hp.Visible     = false
        data.hpText.Visible = false
    end
end

-- ==================== DRAW LOOP ====================

local function startDrawLoop()
    if activeEffects.drawConnection then return end
    activeEffects.drawConnection = RunService.RenderStepped:Connect(function()
        for _, player in pairs(game.Players:GetPlayers()) do
            updateESP(player)
        end
    end)
end

local function stopDrawLoopIfUnused()
    if states.Line or states.Box or states.HP then return end
    if activeEffects.drawConnection then
        activeEffects.drawConnection:Disconnect()
        activeEffects.drawConnection = nil
    end
    -- esconde tudo
    for _, player in pairs(game.Players:GetPlayers()) do
        hideESP(player)
    end
end

-- ==================== CHAMS ====================

local function applyHighlight(player, color, colorName)
    if not player or not player.Character then return end
    local hum = player.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end

    if activeEffects.highlights[player] and activeEffects.highlights[player][colorName] then
        for _, h in pairs(activeEffects.highlights[player][colorName]) do
            if h and h.Parent then h:Destroy() end
        end
        activeEffects.highlights[player][colorName] = nil
    end

    local highlight = Instance.new("Highlight")
    highlight.Name                = colorName .. "_Highlight"
    highlight.FillColor           = color
    highlight.FillTransparency    = 0.5
    highlight.OutlineColor        = color
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent              = player.Character

    if not activeEffects.highlights[player] then activeEffects.highlights[player] = {} end
    if not activeEffects.highlights[player][colorName] then activeEffects.highlights[player][colorName] = {} end
    table.insert(activeEffects.highlights[player][colorName], highlight)
end

local function removeHighlights(player, colorName)
    if not activeEffects.highlights[player] then return end
    if colorName then
        if activeEffects.highlights[player][colorName] then
            for _, h in pairs(activeEffects.highlights[player][colorName]) do
                if h and h.Parent then h:Destroy() end
            end
            activeEffects.highlights[player][colorName] = nil
        end
    else
        for _, ch in pairs(activeEffects.highlights[player]) do
            for _, h in pairs(ch) do
                if h and h.Parent then h:Destroy() end
            end
        end
        activeEffects.highlights[player] = nil
    end
end

local function applyToAllPlayers(color, colorName)
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer then applyHighlight(p, color, colorName) end
    end
end

local function removeFromAllPlayers(colorName)
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= game.Players.LocalPlayer then removeHighlights(p, colorName) end
    end
end

-- ==================== OBSERVER ====================

local function reapplyHighlightsToPlayer(player)
    if not player or player == game.Players.LocalPlayer then return end
    if states.RChams then applyHighlight(player, colors.R, "R") end
    if states.GChams then applyHighlight(player, colors.G, "G") end
    if states.BChams then applyHighlight(player, colors.B, "B") end
end

local function setupCharacterObserver(player)
    if not player or player == game.Players.LocalPlayer then return end
    if activeEffects.observers[player] then return end

    activeEffects.observers[player] = {
        added = player.CharacterAdded:Connect(function(character)
            task.wait(0.5)
            if player and player.Character == character then
                local hum = character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    reapplyHighlightsToPlayer(player)
                end
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

-- ==================== CHAMS CONTROLS ====================

local function rChamsControl(state)
    if state then
        if states.RChams then return end
        states.RChams = true
        print("[RChams] ATIVADO")
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer then setupCharacterObserver(p) end
        end
        applyToAllPlayers(colors.R, "R")
    else
        if not states.RChams then return end
        states.RChams = false
        print("[RChams] DESATIVADO")
        removeFromAllPlayers("R")
    end
end

local function gChamsControl(state)
    if state then
        if states.GChams then return end
        states.GChams = true
        print("[GChams] ATIVADO")
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer then setupCharacterObserver(p) end
        end
        applyToAllPlayers(colors.G, "G")
    else
        if not states.GChams then return end
        states.GChams = false
        print("[GChams] DESATIVADO")
        removeFromAllPlayers("G")
    end
end

local function bChamsControl(state)
    if state then
        if states.BChams then return end
        states.BChams = true
        print("[BChams] ATIVADO")
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer then setupCharacterObserver(p) end
        end
        applyToAllPlayers(colors.B, "B")
    else
        if not states.BChams then return end
        states.BChams = false
        print("[BChams] DESATIVADO")
        removeFromAllPlayers("B")
    end
end

-- ==================== LINE / BOX / HP CONTROLS ====================

local function lineControl(state)
    if state then
        if states.Line then return end
        states.Line = true
        print("[LINE] ATIVADO")
        startDrawLoop()
    else
        if not states.Line then return end
        states.Line = false
        print("[LINE] DESATIVADO")
        stopDrawLoopIfUnused()
    end
end

local function boxControl(state)
    if state then
        if states.Box then return end
        states.Box = true
        print("[BOX] ATIVADO")
        startDrawLoop()
    else
        if not states.Box then return end
        states.Box = false
        print("[BOX] DESATIVADO")
        stopDrawLoopIfUnused()
    end
end

local function hpControl(state)
    if state then
        if states.HP then return end
        states.HP = true
        print("[HP] ATIVADO")
        startDrawLoop()
    else
        if not states.HP then return end
        states.HP = false
        print("[HP] DESATIVADO")
        stopDrawLoopIfUnused()
    end
end

-- ==================== WCK ====================

local function wckControl(state)
    if state then
        if states.WCK then return end
        states.WCK = true
        print("[WCK] ATIVADO")
    else
        if not states.WCK then return end
        states.WCK = false
        print("[WCK] DESATIVADO")
    end
end

-- ==================== FV ====================

local function fvControl(state, mode)
    if state then
        if activeEffects.fv.active then return end
        activeEffects.fv.active = true
        if mode then activeEffects.fv.mode = mode end

        local modeText = activeEffects.fv.mode == "rg" and "Automático" or "Smooth"
        print("[FV] ATIVADO - Modo: " .. modeText .. " | Raio: " .. activeEffects.fv.radius)
        createCircleGui()

        activeEffects.fv.connection = RunService.RenderStepped:Connect(function()
            if not activeEffects.fv.active then return end

            local localPlayer = game.Players.LocalPlayer
            if not localPlayer or not localPlayer.Character then
                activeEffects.fv.currentTarget = nil
                return
            end

            local localPos = getHeadPosition(localPlayer)
            if not localPos then
                activeEffects.fv.currentTarget = nil
                return
            end

            local closestPlayer = nil
            local closestDist   = activeEffects.fv.radius

            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= localPlayer then
                    local headPos = getHeadPosition(player)
                    if headPos then
                        local screenPos = getScreenPosition(headPos)
                        if screenPos then
                            local distFromCenter = getDistanceFromCenter(screenPos)
                            if distFromCenter <= activeEffects.fv.radius and distFromCenter < closestDist then
                                local canTarget = true
                                if states.WCK then
                                    canTarget = hasLineOfSight(localPos, headPos, player.Character)
                                end
                                if canTarget then
                                    closestDist   = distFromCenter
                                    closestPlayer = player
                                end
                            end
                        end
                    end
                end
            end

            if closestPlayer then
                activeEffects.fv.currentTarget = closestPlayer
                local targetHead = getHeadPosition(closestPlayer)
                if targetHead then
                    local targetCF = CFrame.new(Camera.CFrame.Position, targetHead)
                    if activeEffects.fv.mode == "rg" then
                        Camera.CFrame = targetCF
                    else
                        Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.3)
                    end
                end
            else
                activeEffects.fv.currentTarget = nil
            end
        end)
    else
        if not activeEffects.fv.active then return end
        activeEffects.fv.active = false
        if activeEffects.fv.connection then
            activeEffects.fv.connection:Disconnect()
            activeEffects.fv.connection = nil
        end
        print("[FV] DESATIVADO")
        removeCircleGui()
        activeEffects.fv.currentTarget = nil
    end
end

local function fvSetRadius(radius)
    if type(radius) == "number" and radius > 0 then
        activeEffects.fv.radius = radius
        updateCircleSize(radius)
        print("[FV] Raio: " .. radius)
    else
        warn("[FV] Raio inválido:", radius)
    end
end

local function fvSetMode(mode)
    if mode == "rg" or mode == "lg" then
        activeEffects.fv.mode = mode
        print("[FV] Modo: " .. (mode == "rg" and "Automático" or "Smooth"))
    else
        warn("[FV] Modo inválido:", mode)
    end
end

-- ==================== PLAYER ADDED / REMOVING ====================

for _, p in pairs(game.Players:GetPlayers()) do
    if p ~= game.Players.LocalPlayer then
        createESP(p)
        setupCharacterObserver(p)
    end
end

game.Players.PlayerAdded:Connect(function(player)
    if player == game.Players.LocalPlayer then return end
    createESP(player)
    setupCharacterObserver(player)
    task.wait(0.5)
    if states.RChams then applyHighlight(player, colors.R, "R") end
    if states.GChams then applyHighlight(player, colors.G, "G") end
    if states.BChams then applyHighlight(player, colors.B, "B") end
end)

game.Players.PlayerRemoving:Connect(function(player)
    if activeEffects.observers[player] then
        if activeEffects.observers[player].added   then activeEffects.observers[player].added:Disconnect()   end
        if activeEffects.observers[player].removing then activeEffects.observers[player].removing:Disconnect() end
        activeEffects.observers[player] = nil
    end
    removeHighlights(player)
    removeESP(player)
end)

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
    HP       = hpControl
}

-- ==================== LISTENER ====================

event.Event:Connect(function(feature, cmd, extra)
    if type(feature) ~= "string" or type(cmd) ~= "string" then return end

    local featureFunc = features[feature]
    if not featureFunc then
        warn("Feature não existe:", feature)
        return
    end

    if feature == "FV" then
        if cmd == "ON" then
            featureFunc(true, extra)
        elseif cmd == "OFF" then
            featureFunc(false)
        elseif cmd == "TOGGLE" then
            featureFunc(not activeEffects.fv.active, extra)
        end
    elseif feature == "FVRadius" then
        local radius = tonumber(cmd)
        if radius then featureFunc(radius) end
    elseif feature == "FVMode" then
        featureFunc(cmd)
    else
        if cmd == "ON" then
            featureFunc(true)
        elseif cmd == "OFF" then
            featureFunc(false)
        elseif cmd == "TOGGLE" then
            featureFunc(not states[feature])
        else
            warn("Comando inválido:", cmd)
        end
    end

    print("[LISTENER]", feature, cmd, extra or "")
end)

print("[LISTENER] carregado 🔥")
print("[COMANDOS] RChams, GChams, BChams, WCK, Line, Box, HP: ON, OFF, TOGGLE")
print("[COMANDOS] FV: ON, OFF, TOGGLE | FVRadius: [numero] | FVMode: rg / lg")
