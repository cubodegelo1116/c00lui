local RunService = game:GetService("RunService")

local function fvControl(state, mode)
    if state then
        if activeEffects.fv.active then return end
        activeEffects.fv.active     = true
        activeEffects.fv.lastCFrame = nil

        if mode then activeEffects.fv.mode = mode end

        local modeText = activeEffects.fv.mode == "rg" and "Automático" or "Smooth"
        print("[FV] ATIVADO - Modo: " .. modeText .. " | Raio: " .. activeEffects.fv.radius)

        createCircleGui()

        -- RenderStepped: roda junto com o frame, sem flicker
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

        -- desconecta o RenderStepped
        if activeEffects.fv.connection then
            activeEffects.fv.connection:Disconnect()
            activeEffects.fv.connection = nil
        end

        print("[FV] DESATIVADO")
        removeCircleGui()
        activeEffects.fv.currentTarget = nil
        activeEffects.fv.lastCFrame    = nil
    end
end
