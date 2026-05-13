-- LISTENER GLOBAL (executa uma vez)

if getgenv().ListenerLoaded then
    warn("Listener já tá rodando")
    return
end

getgenv().ListenerLoaded = true

-- cria evento isolado
local event = Instance.new("BindableEvent")
getgenv().ListenerEvent = event

-- armazenamento dos efeitos ativos
local activeEffects = {
    highlights = {},
    observers = {}
}

-- função para criar highlight em um player com cor específica
local function applyHighlight(player, color, colorName)
    if not player or not player.Character then 
        return 
    end
    
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    
    -- só aplica se o player estiver vivo
    if not humanoid or humanoid.Health <= 0 then
        return
    end
    
    -- remove highlights antigos desse player pra essa cor
    if activeEffects.highlights[player] and activeEffects.highlights[player][colorName] then
        for _, highlight in pairs(activeEffects.highlights[player][colorName]) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
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
    
    -- armazena o highlight
    if not activeEffects.highlights[player] then
        activeEffects.highlights[player] = {}
    end
    if not activeEffects.highlights[player][colorName] then
        activeEffects.highlights[player][colorName] = {}
    end
    table.insert(activeEffects.highlights[player][colorName], highlight)
end

-- função para remover highlights
local function removeHighlights(player, colorName)
    if not activeEffects.highlights[player] then 
        return 
    end
    
    if colorName then
        if activeEffects.highlights[player][colorName] then
            for _, highlight in pairs(activeEffects.highlights[player][colorName]) do
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
            end
            activeEffects.highlights[player][colorName] = nil
        end
    else
        for _, colorHighlights in pairs(activeEffects.highlights[player]) do
            if colorHighlights then
                for _, highlight in pairs(colorHighlights) do
                    if highlight and highlight.Parent then
                        highlight:Destroy()
                    end
                end
            end
        end
        activeEffects.highlights[player] = nil
    end
end

-- função para aplicar em todos os players
local function applyToAllPlayers(color, colorName)
    local localPlayer = game.Players.LocalPlayer
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            applyHighlight(player, color, colorName)
        end
    end
end

-- função para remover de todos os players
local function removeFromAllPlayers(colorName)
    local localPlayer = game.Players.LocalPlayer
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer then
            removeHighlights(player, colorName)
        end
    end
end

-- função pra reaplicar highlights em um player (todas as cores ativas)
local function reapplyHighlightsToPlayer(player)
    if not player or player == game.Players.LocalPlayer then
        return
    end
    
    if states.RChams then
        applyHighlight(player, colors.R, "R")
    end
    if states.GChams then
        applyHighlight(player, colors.G, "G")
    end
    if states.BChams then
        applyHighlight(player, colors.B, "B")
    end
end

-- observador para players (melhorado)
local function setupCharacterObserver(player)
    if not player or player == game.Players.LocalPlayer then 
        return 
    end
    
    -- se já tem observer, não cria de novo
    if activeEffects.observers[player] then
        return
    end
    
    local function onCharacterAdded(character)
        -- espera o personagem carregar completamente
        wait(0.5)
        
        -- verifica se o player ainda existe e se tem humanoid vivo
        if player and player.Character == character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- reaplica todas as cores ativas
                reapplyHighlightsToPlayer(player)
            end
        end
    end
    
    local function onCharacterRemoving()
        -- remove os highlights quando o personagem morre/é removido
        if states.RChams then
            removeHighlights(player, "R")
        end
        if states.GChams then
            removeHighlights(player, "G")
        end
        if states.BChams then
            removeHighlights(player, "B")
        end
    end
    
    -- cria os observers
    activeEffects.observers[player] = {
        added = player.CharacterAdded:Connect(onCharacterAdded),
        removing = player.CharacterRemoving:Connect(onCharacterRemoving)
    }
end

-- estados das features
local states = {
    RChams = false,
    GChams = false,
    BChams = false
}

-- cores
local colors = {
    R = Color3.fromRGB(255, 0, 0),
    G = Color3.fromRGB(0, 255, 0),
    B = Color3.fromRGB(0, 0, 255)
}

-- função principal do RChams
local function rChamsControl(state)
    if state then
        if states.RChams then return end
        states.RChams = true
        
        print("[RChams] ATIVADO - inimigos em vermelho brilhante")
        
        -- configura observers pra todos os players
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                setupCharacterObserver(player)
            end
        end
        
        -- aplica em todos os players vivos
        applyToAllPlayers(colors.R, "R")
    else
        if not states.RChams then return end
        states.RChams = false
        
        print("[RChams] DESATIVADO - removendo efeito vermelho")
        removeFromAllPlayers("R")
    end
end

-- função do GChams
local function gChamsControl(state)
    if state then
        if states.GChams then return end
        states.GChams = true
        
        print("[GChams] ATIVADO - inimigos em verde brilhante")
        
        -- configura observers pra todos os players
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                setupCharacterObserver(player)
            end
        end
        
        applyToAllPlayers(colors.G, "G")
    else
        if not states.GChams then return end
        states.GChams = false
        
        print("[GChams] DESATIVADO - removendo efeito verde")
        removeFromAllPlayers("G")
    end
end

-- função do BChams
local function bChamsControl(state)
    if state then
        if states.BChams then return end
        states.BChams = true
        
        print("[BChams] ATIVADO - inimigos em azul brilhante")
        
        -- configura observers pra todos os players
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                setupCharacterObserver(player)
            end
        end
        
        applyToAllPlayers(colors.B, "B")
    else
        if not states.BChams then return end
        states.BChams = false
        
        print("[BChams] DESATIVADO - removendo efeito azul")
        removeFromAllPlayers("B")
    end
end

-- eventos globais
local function onPlayerAdded(player)
    if player == game.Players.LocalPlayer then return end
    
    -- configura observer pro novo player
    setupCharacterObserver(player)
    
    -- aplica os efeitos ativos nele
    wait(0.5)
    if states.RChams then
        applyHighlight(player, colors.R, "R")
    end
    if states.GChams then
        applyHighlight(player, colors.G, "G")
    end
    if states.BChams then
        applyHighlight(player, colors.B, "B")
    end
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

-- conecta eventos
game.Players.PlayerAdded:Connect(onPlayerAdded)
game.Players.PlayerRemoving:Connect(onPlayerRemoving)

-- tabela de features
local features = {
    RChams = rChamsControl,
    GChams = gChamsControl,
    BChams = bChamsControl
}

-- listener principal
event.Event:Connect(function(feature, cmd)
    if type(feature) ~= "string" or type(cmd) ~= "string" then 
        return 
    end
    
    local featureFunc = features[feature]
    if not featureFunc then
        warn("Feature não existe:", feature)
        return
    end
    
    if cmd == "ON" then
        featureFunc(true)
    elseif cmd == "OFF" then
        featureFunc(false)
    elseif cmd == "TOGGLE" then
        if feature == "RChams" then
            featureFunc(not states.RChams)
        elseif feature == "GChams" then
            featureFunc(not states.GChams)
        elseif feature == "BChams" then
            featureFunc(not states.BChams)
        end
    else
        warn("Comando inválido:", cmd)
        return
    end
    
    print("[LISTENER]", feature, cmd)
end)

print("[LISTENER] carregado e escutando 🔥")
print("[COMANDOS] RChams, GChams, BChams: ON, OFF, TOGGLE")
print("[INFO] Efeitos reaplicam automaticamente quando o player revive!")
