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
    WCK    = false
}

local colors = {
    R = Color3.fromRGB(255, 0, 0),
    G = Color3.fromRGB(0, 255, 0),
    B = Color3.fromRGB(0, 0, 255)
}

local activeEffects = {
    highlights = {},
    observers  = {},
    fv = {
        active        = false,
        mode          = "rg",
        radius        = 150,
        currentTarget = nil,
        circleGui     = nil,
        connection    = nil
    }
}

-- ==================== FV CIRCLE (Drawing) ====================

local function createCircleGui()
    if activeEffects.fv.circleGui then
        activeEffects.fv.circleGui:Remove()
        activeEffects.fv.circleGui = nil
    end

    local camera = workspace.CurrentCamera
    local circle = Drawing.new("Circle")
    circle.Radius       = activeEffects.fv.radius
    circle.Thickness    = 2
    circle.Color        = Color3.fromRGB(255, 50, 50)
    circle.Filled       = false
    circle.Visible      = true
    circle.Transparency = 0.7
    circle.NumSides     = 64
    circle.Position     = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

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

-- ==================== FV LÓGICA ====================

local function getHeadPosition(player)
    if not player or not player.Character then return nil end
    local head = player.Character:FindFirstChild("Head")
    if head then return head.Position end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position + Vector3.new(0, 2, 0) end
    return nil
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
                        local dist = (localPos - headPos).Magnitude
                        if dist <= activeEffects.fv.radius and dist < closestDist then
                            local canTarget = true
                            if states.WCK then
                                canTarget = hasLineOfSight(localPos, headPos, player.Character)
                            end
                            if canTarget then
                                closestDist   = dist
                                closestPlayer = player
                            end
                        end
                    end
                end
            end

            if closestPlayer then
                activeEffects.fv.currentTarget = closestPlayer
                local targetHead = getHeadPosition(closestPlayer)
                if targetHead then
                    local camera    = workspace.CurrentCamera
                    local cameraPos = camera.CFrame.Position
                    local targetCF  = CFrame.new(cameraPos, targetHead)

                    if activeEffects.fv.mode == "rg" then
                        camera.CFrame = targetCF
                    elseif activeEffects.fv.mode == "lg" then
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

-- ==================== WCK ====================

local function wckControl(state)
    if state then
        if states.WCK then return end
        states.WCK = true
        print("[WCK] ATIVADO - ignora alvos atrás de paredes")
    else
        if not states.WCK then return end
        states.WCK = false
        print("[WCK] DESATIVADO")
    end
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
                end
            end
        end),
        removing = player.CharacterRemoving:Connect(function()
            if states.RChams then removeHighlights(player, "R") end
            if states.GChams then removeHighlights(player, "G") end
            if states.BChams then removeHighlights(player, "B") end
        end)
    }
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

game.Players.PlayerAdded:Connect(function(player)
    if player == game.Players.LocalPlayer then return end
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
end)

-- ==================== FEATURES ====================

local features = {
    RChams   = rChamsControl,
    GChams   = gChamsControl,
    BChams   = bChamsControl,
    FV       = fvControl,
    FVRadius = fvSetRadius,
    FVMode   = fvSetMode,
    WCK      = wckControl
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
print("[COMANDOS] RChams, GChams, BChams, WCK: ON, OFF, TOGGLE")
print("[COMANDOS] FV: ON, OFF, TOGGLE | FVRadius: [numero] | FVMode: rg / lg")
