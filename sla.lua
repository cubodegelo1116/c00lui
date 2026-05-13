-- LISTENER GLOBAL (executa uma vez)

local ok, genv = pcall(getgenv)
if not ok or not genv then
    warn("[LISTENER] getgenv() não suportado neste executor")
    return
end

if genv.ListenerLoaded then
    warn("Listener já tá rodando")
    return
end

genv.ListenerLoaded = true

local event = Instance.new("BindableEvent")
genv.ListenerEvent = event

-- ==================== ESTADOS E CORES (declarados primeiro) ====================

local states = {
    RChams = false,
    GChams = false,
    BChams = false
}

local colors = {
    R = Color3.fromRGB(255, 0, 0),
    G = Color3.fromRGB(0, 255, 0),
    B = Color3.fromRGB(0, 0, 255)
}

local activeEffects = {
    highlights = {},
    observers = {},
    fv = {
        active = false,
        mode = "rg",
        radius = 100,
        currentTarget = nil,
        connection = nil,
        circleGui = nil,
        circleFrame = nil
    }
}

-- ==================== FUNÇÕES DO FV ====================

local function createCircleGui()
    local player = game.Players.LocalPlayer
    if not player then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FVCircleGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.Size = UDim2.new(0, activeEffects.fv.radius, 0, activeEffects.fv.radius)
    circle.Position = UDim2.new(0.5, -activeEffects.fv.radius/2, 0.5, -activeEffects.fv.radius/2)
    circle.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    circle.BackgroundTransparency = 0.7
    circle.BorderSizePixel = 2
    circle.BorderColor3 = Color3.fromRGB(255, 255, 255)
    circle.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle

    activeEffects.fv.circleGui = screenGui
    activeEffects.fv.circleFrame = circle
end

local function updateCircleSize(radius)
    activeEffects.fv.radius = radius
    if activeEffects.fv.circleFrame then
        activeEffects.fv.circleFrame.Size = UDim2.new(0, radius, 0, radius)
        activeEffects.fv.circleFrame.Position = UDim2.new(0.5, -radius/2, 0.5, -radius/2)
    end
end

local function removeCircleGui()
    if activeEffects.fv.circleGui then
        activeEffects.fv.circleGui:Destroy()
        activeEffects.fv.circleGui = nil
        activeEffects.fv.circleFrame = nil
    end
end

local function getHeadPosition(player)
    if not player or not player.Character then return nil end
    local character = player.Character
    local head = character:FindFirstChild("Head")
    if head then return head.Position end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position + Vector3.new(0, 2, 0) end
    return nil
end

local function smoothCamera(targetCFrame, speed)
    local camera = workspace.CurrentCamera
    local currentCFrame = camera.CFrame
    camera.CFrame = currentCFrame:Lerp(targetCFrame, speed)
end

local function fvLoop()
    while activeEffects.fv.active do
        task.wait(0.05)

        local localPlayer = game.Players.LocalPlayer
        if not localPlayer or not localPlayer.Character then
            activeEffects.fv.currentTarget = nil
            continue
        end

        local localPosition = getHeadPosition(localPlayer)
        if not localPosition then
            activeEffects.fv.currentTarget = nil
            continue
        end

        local closestPlayer = nil
        local closestDistance = activeEffects.fv.radius

        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= localPlayer then
                local headPos = getHeadPosition(player)
                if headPos then
                    local distance = (localPosition - headPos).Magnitude
                    if distance <= activeEffects.fv.radius and distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end

        if closestPlayer then
            activeEffects.fv.currentTarget = closestPlayer
            local targetHead = getHeadPosition(closestPlayer)
            if targetHead then
                local camera = workspace.CurrentCamera
                -- CORRIGIDO: aponta a câmera DE onde ela está PARA o alvo
                local cameraPos = camera.CFrame.Position
                local targetCFrame = CFrame.new(cameraPos, targetHead)

                if activeEffects.fv.mode == "rg" then
                    camera.CFrame = targetCFrame
                elseif activeEffects.fv.mode == "lg" then
                    smoothCamera(targetCFrame, 0.3)
                end
            end
        else
            activeEffects.fv.currentTarget = nil
        end
    end
end

local function fvControl(state, mode, radius)
    if state then
        if activeEffects.fv.active then return end
        activeEffects.fv.active = true

        if mode then activeEffects.fv.mode = mode end
        if type(radius) == "number" then activeEffects.fv.radius = radius end

        local modeText = activeEffects.fv.mode == "rg" and "Automático" or "Smooth"
        print("[FV] ATIVADO - Modo: " .. modeText .. " | Raio: " .. activeEffects.fv.radius)

        createCircleGui()
        task.spawn(fvLoop)
    else
        if not activeEffects.fv.active then return end
        activeEffects.fv.active = false
        print("[FV] DESATIVADO")
        removeCircleGui()
        activeEffects.fv.currentTarget = nil
    end
end

local function fvSetRadius(radius)
    if type(radius) == "number" and radius > 0 then
        activeEffects.fv.radius = radius
        updateCircleSize(radius)
        print("[FV] Raio atualizado para: " .. radius)
    else
        warn("[FV] Raio inválido:", radius)
    end
end

local function fvSetMode(mode)
    if mode == "rg" or mode == "lg" then
        activeEffects.fv.mode = mode
        local modeText = mode == "rg" and "Automático" or "Smooth"
        print("[FV] Modo alterado para: " .. modeText)
    else
        warn("[FV] Modo inválido:", mode)
    end
end

-- ==================== FUNÇÕES DOS CHAMS ====================

local function applyHighlight(player, color, colorName)
    if not player or not player.Character then return end
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    if activeEffects.highlights[player] and activeEffects.highlights[player][colorName] then
        for _, h in pairs(activeEffects.highlights[player][colorName]) do
            if h and h.Parent then h:Destroy() end
        end
        activeEffects.highlights[player][colorName] = nil
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = colorName .. "_Highlight"
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

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
            if colorHighlights then
                for _, h in pairs(colorHighlights) do
                    if h and h.Parent then h:Destroy() end
                end
            end
        end
        activeEffects.highlights[player] = nil
    end
end

local function applyToAllPlayers(color, colorName)
    local localPlayer = game.Players.LocalPlayer
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            applyHighlight(player, color, colorName)
        end
    end
end

local function removeFromAllPlayers(colorName)
    local localPlayer = game.Players.LocalPlayer
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
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

local function onPlayerAdded(player)
    if player == game.Players.LocalPlayer then return end
    setupCharacterObserver(player)
    task.wait(0.5)
    if states.RChams then applyHighlight(player, colors.R, "R") end
    if states.GChams then applyHighlight(player, colors.G, "G") end
    if states.BChams then applyHighlight(player, colors.B, "B") end
end

local function onPlayerRemoving(player)
    if activeEffects.observers[player] then
        if activeEffects.observers[player].added then
            activeEffects.observers[player].added:Disconnect()
        end
        if activeEffects.observers[player].removing then
            activeEffects.observers[player].removing:Disconnect()
        end
        activeEffects.observers[player] = nil
    end
    removeHighlights(player)
end

game.Players.PlayerAdded:Connect(onPlayerAdded)
game.Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==================== TABELA DE FEATURES ====================

local features = {
    RChams   = rChamsControl,
    GChams   = gChamsControl,
    BChams   = bChamsControl,
    FV       = fvControl,
    FVRadius = fvSetRadius,
    FVMode   = fvSetMode
}

-- ==================== LISTENER PRINCIPAL ====================

event.Event:Connect(function(feature, cmd, extra)
    if type(feature) ~= "string" or type(cmd) ~= "string" then return end

    local featureFunc = features[feature]
    if not featureFunc then
        warn("Feature não existe:", feature)
        return
    end

    if feature == "FV" then
        if cmd == "ON" then
            featureFunc(true, extra, activeEffects.fv.radius)
        elseif cmd == "OFF" then
            featureFunc(false)
        elseif cmd == "TOGGLE" then
            featureFunc(not activeEffects.fv.active, extra, activeEffects.fv.radius)
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

print("[LISTENER] carregado e escutando 🔥")
print("[COMANDOS] RChams, GChams, BChams: ON, OFF, TOGGLE")
print("[COMANDOS] FV: ON, OFF, TOGGLE | FVRadius: [numero] | FVMode: rg / lg")
