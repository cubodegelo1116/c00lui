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
    drawings       = {},
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

    local camera = workspace.CurrentCamera
    local circle = Drawing.new("Circle")
    circle.Radius        = activeEffects.fv.radius
    circle.Thickness     = 2
    circle.Color         = Color3.fromRGB(255, 50, 50)
    circle.Filled        = false
    circle.Visible       = true
    circle.Transparency  = 0.7
    circle.NumSides      = 64
    circle.Position      = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
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
    local camera = workspace.CurrentCamera
    local screenPos, onScreen = camera:WorldToViewportPoint(position)
    if not onScreen then return nil end
    return Vector2.new(screenPos.X, screenPos.Y)
end

local function getDistanceFromCenter(screenPos)
    local camera = workspace.CurrentCamera
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
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
    local result = workspace:Raycast(fromPos, toPos - fromPos, params)
    return result == nil
end

local function getPlayerHealth(player)
    if not player or not player.Character then return 0, 100 end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return 0, 100 end
    return humanoid.Health, humanoid.MaxHealth
end

local function getSimpleBounds(player)
    if not player or not player.Character then return nil, nil end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end

    local camera = workspace.CurrentCamera
    local pos    = hrp.Position
    local w      = 2.0

    local points = {
        pos + Vector3.new( w,  3.5, 0),
        pos + Vector3.new(-w,  3.5, 0),
        pos + Vector3.new( w, -3.5, 0),
        pos + Vector3.new(-w, -3.5, 0),
    }

    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyOnScreen = false

    for _, point in pairs(points) do
        local sp, onScreen = camera:WorldToViewportPoint(point)
        if onScreen then
            anyOnScreen = true
            minX = math.min(minX, sp.X)
            minY = math.min(minY, sp.Y)
            maxX = math.max(maxX, sp.X)
            maxY = math.max(maxY, sp.Y)
        end
    end

    if not anyOnScreen then return nil, nil end
    return Vector2.new(minX, minY), Vector2.new(maxX, maxY)
end

-- ==================== DRAWINGS ====================

local function removeDrawingsForPlayer(player)
    if not activeEffects.drawings[player] then return end
    local d = activeEffects.drawings[player]
    if d.line  then d.line:Remove()  end
    if d.hp    then d.hp:Remove()    end
    if d.hpBg  then d.hpBg:Remove() end
    for _, l in pairs(d.box) do l:Remove() end
    activeEffects.drawings[player] = nil
end

local function ensureDrawings(player)
    if not activeEffects.drawings[player] then
        activeEffects.drawings[player] = { line = nil, box = {}, hp = nil, hpBg = nil }
    end
    local d = activeEffects.drawings[player]

    -- LINE
    if states.Line and not d.line then
        local l = Drawing.new("Line")
        l.Thickness    = 1
        l.Color        = Color3.fromRGB(255, 50, 50)
        l.Transparency = 0
        l.Visible      = false
        d.line = l
    elseif not states.Line and d.line then
        d.line:Remove()
        d.line = nil
    end

    -- BOX (4 linhas)
    if states.Box and #d.box == 0 then
        for i = 1, 4 do
            local l = Drawing.new("Line")
            l.Thickness    = 1
            l.Color        = Color3.fromRGB(255, 50, 50)
            l.Transparency = 0
            l.Visible      = false
            table.insert(d.box, l)
        end
    elseif not states.Box and #d.box > 0 then
        for _, l in pairs(d.box) do l:Remove() end
        d.box = {}
    end

    -- HP
    if states.HP and not d.hp then
        local bg = Drawing.new("Line")
        bg.Thickness    = 4
        bg.Color        = Color3.fromRGB(30, 30, 30)
        bg.Transparency = 0
        bg.Visible      = false
        d.hpBg = bg

        local hp = Drawing.new("Line")
        hp.Thickness    = 4
        hp.Color        = Color3.fromRGB(0, 255, 0)
        hp.Transparency = 0
        hp.Visible      = false
        d.hp = hp
    elseif not states.HP then
        if d.hp   then d.hp:Remove()   d.hp   = nil end
        if d.hpBg then d.hpBg:Remove() d.hpBg = nil end
    end
end

local function updateDrawingsForPlayer(player)
    if not player or player == game.Players.LocalPlayer then return end

    if not player.Character then
        if activeEffects.drawings[player] then
            local d = activeEffects.drawings[player]
            if d.line  then d.line.Visible  = false end
            if d.hp    then d.hp.Visible    = false end
            if d.hpBg  then d.hpBg.Visible  = false end
            for _, l in pairs(d.box) do l.Visible = false end
        end
        return
    end

    ensureDrawings(player)
    local d = activeEffects.drawings[player]
    if not d then return end

    local camera    = workspace.CurrentCamera
    local headPos   = getHeadPosition(player)
    local screenHead = headPos and getScreenPosition(headPos)

    -- LINE
    if d.line then
        if screenHead then
            d.line.From    = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            d.line.To      = screenHead
            d.line.Visible = true
        else
            d.line.Visible = false
        end
    end

    -- BOX + HP (precisam dos bounds)
    if #d.box == 4 or d.hp then
        local tl, br = getSimpleBounds(player)

        if #d.box == 4 then
            if tl and br then
                local tr = Vector2.new(br.X, tl.Y)
                local bl = Vector2.new(tl.X, br.Y)
                d.box[1].From = tl  d.box[1].To = tr  d.box[1].Visible = true
                d.box[2].From = bl  d.box[2].To = br  d.box[2].Visible = true
                d.box[3].From = tl  d.box[3].To = bl  d.box[3].Visible = true
                d.box[4].From = tr  d.box[4].To = br  d.box[4].Visible = true
            else
                for _, l in pairs(d.box) do l.Visible = false end
            end
        end

        if d.hp and d.hpBg then
            if tl and br then
                local health, maxHealth = getPlayerHealth(player)
                local ratio     = maxHealth > 0 and (health / maxHealth) or 0
                local barX      = tl.X - 6
                local barTop    = tl.Y
                local barBot    = br.Y
                local barHeight = barBot - barTop
                local r         = math.floor(255 * (1 - ratio))
                local g         = math.floor(255 * ratio)

                d.hpBg.From    = Vector2.new(barX, barTop)
                d.hpBg.To      = Vector2.new(barX, barBot)
                d.hpBg.Visible = true

                d.hp.Color   = Color3.fromRGB(r, g, 0)
                d.hp.From    = Vector2.new(barX, barBot)
                d.hp.To      = Vector2.new(barX, barBot - barHeight * ratio)
                d.hp.Visible = true
            else
                d.hp.Visible   = false
                d.hpBg.Visible = false
            end
        end
    end
end

local function startDrawLoop()
    if activeEffects.drawConnection then return end
    activeEffects.drawConnection = RunService.RenderStepped:Connect(function()
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                updateDrawingsForPlayer(player)
            end
        end
    end)
end

local function stopDrawLoopIfUnused()
    if states.Line or states.Box or states.HP then return end
    if activeEffects.drawConnection then
        activeEffects.drawConnection:Disconnect()
        activeEffects.drawConnection = nil
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
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    reapplyHighlightsToPlayer(player)
                    if states.Line or states.Box or states.HP then
                        removeDrawingsForPlayer(player)
                        ensureDrawings(player)
                    end
                end
            end
        end),
        removing = player.CharacterRemoving:Connect(function()
            if states.RChams then removeHighlights(player, "R") end
            if states.GChams then removeHighlights(player, "G") end
            if states.BChams then removeHighlights(player, "B") end
            if activeEffects.drawings[player] then
                local d = activeEffects.drawings[player]
                if d.line  then d.line.Visible  = false end
                if d.hp    then d.hp.Visible    = false end
                if d.hpBg  then d.hpBg.Visible  = false end
                for _, l in pairs(d.box) do l.Visible = false end
            end
        end)
    }
end

-- ==================== CHAMS ====================

local function applyHighlight(player, color, colorName)
    if not player or not player.Character then return end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

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

    if not activeEffects.highlights[player] then
        activeEffects.highlights[player] = {}
    end
    if not activeEffects.highlights[player][colorName] then
        activeEffects.highlights[player][colorName] = {}
    end
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
        for _, colorHighlights in pairs(activeEffects.highlights[player]) do
            for _, h in pairs(colorHighlights) do
                if h and h.Parent then h:Destroy() end
            end
        end
        activeEffects.highlights[player] = nil
    end
end

local function applyToAllPlayers(color, colorName)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            applyHighlight(player, color, colorName)
        end
    end
end

local function removeFromAllPlayers(colorName)
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            removeHighlights(player, colorName)
        end
    end
end

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

-- ==================== LINE / BOX / HP ====================

local function lineControl(state)
    if state then
        if states.Line then return end
        states.Line = true
        print("[LINE] ATIVADO")
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer then
                setupCharacterObserver(p)
                ensureDrawings(p)
            end
        end
        startDrawLoop()
    else
        if not states.Line then return end
        states.Line = false
        print("[LINE] DESATIVADO")
        for _, p in pairs(game.Players:GetPlayers()) do
            if activeEffects.drawings[p] and activeEffects.drawings[p].line then
                activeEffects.drawings[p].line:Remove()
                activeEffects.drawings[p].line = nil
            end
        end
        stopDrawLoopIfUnused()
    end
end

local function boxControl(state)
    if state then
        if states.Box then return end
        states.Box = true
        print("[BOX] ATIVADO")
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer then
                setupCharacterObserver(p)
                ensureDrawings(p)
            end
        end
        startDrawLoop()
    else
        if not states.Box then return end
        states.Box = false
        print("[BOX] DESATIVADO")
        for _, p in pairs(game.Players:GetPlayers()) do
            if activeEffects.drawings[p] then
                for _, l in pairs(activeEffects.drawings[p].box) do l:Remove() end
                activeEffects.drawings[p].box = {}
            end
        end
        stopDrawLoopIfUnused()
    end
end

local function hpControl(state)
    if state then
        if states.HP then return end
        states.HP = true
        print("[HP] ATIVADO")
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= game.Players.LocalPlayer then
                setupCharacterObserver(p)
                ensureDrawings(p)
            end
        end
        startDrawLoop()
    else
        if not states.HP then return end
        states.HP = false
        print("[HP] DESATIVADO")
        for _, p in pairs(game.Players:GetPlayers()) do
            if activeEffects.drawings[p] then
                local d = activeEffects.drawings[p]
                if d.hp   then d.hp:Remove()   d.hp   = nil end
                if d.hpBg then d.hpBg:Remove() d.hpBg = nil end
            end
        end
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
                    local camera   = workspace.CurrentCamera
                    local targetCF = CFrame.new(camera.CFrame.Position, targetHead)
                    if activeEffects.fv.mode == "rg" then
                        camera.CFrame = targetCF
                    else
                        camera.CFrame = camera.CFrame:Lerp(targetCF, 0.3)
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

-- ==================== PLAYER ADDED/REMOVING ====================

game.Players.PlayerAdded:Connect(function(player)
    if player == game.Players.LocalPlayer then return end
    setupCharacterObserver(player)
    task.wait(0.5)
    if states.RChams then applyHighlight(player, colors.R, "R") end
    if states.GChams then applyHighlight(player, colors.G, "G") end
    if states.BChams then applyHighlight(player, colors.B, "B") end
    if states.Line or states.Box or states.HP then ensureDrawings(player) end
end)

game.Players.PlayerRemoving:Connect(function(player)
    if activeEffects.observers[player] then
        if activeEffects.observers[player].added   then activeEffects.observers[player].added:Disconnect()   end
        if activeEffects.observers[player].removing then activeEffects.observers[player].removing:Disconnect() end
        activeEffects.observers[player] = nil
    end
    removeHighlights(player)
    removeDrawingsForPlayer(player)
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
