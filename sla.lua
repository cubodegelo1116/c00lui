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
    
    -- remove highlights antigos desse player pra essa cor
    if activeEffects.highlights[player] and activeEffects.highlights[player][colorName] then
        for _, highlight in pairs(activeEffects.highlights[player][colorName]) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        activeEffects.highlights[player][colorName] = nil
    end
    
    local character = player.Character
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
        -- remove apenas os highlights de uma cor específica
        if activeEffects.highlights[player][colorName] then
            for _, highlight in pairs(activeEffects.highlights[player][colorName]) do
                if highlight and highlight.Parent then
                    highlight:Destroy()
                end
            end
            activeEffects.highlights[player][colorName] = nil
        end
    else
        -- remove todos os highlights do player
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
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                applyHighlight(player, color, colorName)
            end
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

-- observador para players
local function setupCharacterObserver(player, color, colorName, stateTable)
    if not player or player == game.Players.LocalPlayer then 
        return 
    end
    
    -- se já tem observer pra essa cor, não cria de novo
    if activeEffects.observers[player] and activeEffects.observers[player][colorName] then
        return
    end
    
    local function onCharacterAdded(character)
        wait(0.5)
        if stateTable[colorName] and player.Character == character and character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            applyHighlight(player, color, colorName)
        end
    end
    
    local function onCharacterRemoving()
        if stateTable[colorName] then
            removeHighlights(player, colorName)
        end
    end
    
    -- cria os observers
    if not activeEffects.observers[player] then
        activeEffects.observers[player] = {}
    end
    
    activeEffects.observers[player][colorName] = {
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
        
        applyToAllPlayers(colors.R, "R")
        
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                setupCharacterObserver(player, colors.R, "R", states)
            end
        end
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
        
        applyToAllPlayers(colors.G, "G")
        
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                setupCharacterObserver(player, colors.G, "G", states)
            end
        end
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
        
        applyToAllPlayers(colors.B, "B")
        
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                setupCharacterObserver(player, colors.B, "B", states)
            end
        end
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
    
    if states.RChams then
        setupCharacterObserver(player, colors.R, "R", states)
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            applyHighlight(player, colors.R, "R")
        end
    end
    
    if states.GChams then
        setupCharacterObserver(player, colors.G, "G", states)
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            applyHighlight(player, colors.G, "G")
        end
    end
    
    if states.BChams then
        setupCharacterObserver(player, colors.B, "B", states)
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            applyHighlight(player, colors.B, "B")
        end
    end
end

local function onPlayerRemoving(player)
    if activeEffects.observers[player] then
        for _, observers in pairs(activeEffects.observers[player]) do
            if observers.added then
                observers.added:Disconnect()
            end
            if observers.removing then
                observers.removing:Disconnect()
            end
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
