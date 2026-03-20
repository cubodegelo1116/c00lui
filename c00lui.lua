--[[ 
    c00lUI v3 - COM SIDE TAB DESLIZÁVEL (TIPO c00gui original)
    
    Agora com:
    - AddPage() - páginas normais (navegação < >)
    - AddSideTab() - aba lateral que desliza com > (abre) e < (fecha)
    - Elementos S: SButton, SLabel, STextbox, SToggle, SSlider, SDivider, SSpacing
]]

local c00lui = {}

function c00lui:Window(config)
    config = config or {}
    local win = {}

    win.title  = config.Title or "c00lgui"
    win.accent = config.AccentColor or Color3.fromRGB(255,0,0)
    win.bg     = Color3.fromRGB(0,0,0)
    win.text   = Color3.fromRGB(255,255,255)
    win.pages  = {}
    win.current = 1
    win.hasSideTab = false
    win.sideTabOpen = false
    win.TweenService = game:GetService("TweenService")

    ------------------------------------------------
    -- REMOVE GUIS ANTIGAS
    ------------------------------------------------

    for _,v in ipairs(game.CoreGui:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name == "c00lUI" then
            v:Destroy()
        end
    end

    ------------------------------------------------
    -- BASE
    ------------------------------------------------

    local sg = Instance.new("ScreenGui")
    sg.Name = "c00lUI"
    sg.Parent = game.CoreGui
    sg.ResetOnSpawn = false

    local mf = Instance.new("Frame", sg)
    mf.Size = UDim2.new(0,300,0,400)
    mf.Position = UDim2.new(0,10,0.3,0)
    mf.BackgroundColor3 = win.bg
    mf.BorderColor3 = win.accent
    mf.BorderSizePixel = 3

    local title = Instance.new("TextLabel", mf)
    title.Size = UDim2.new(1,0,0,30)
    title.Text = win.title
    title.BackgroundColor3 = win.bg
    title.BorderSizePixel = 0
    title.TextColor3 = win.text
    title.TextSize = 15
    title.TextWrapped = true

    ------------------------------------------------
    -- NAV
    ------------------------------------------------

    local nav = Instance.new("Frame", mf)
    nav.Size = UDim2.new(1,0,0,40)
    nav.Position = UDim2.new(0,0,0,30)
    nav.BackgroundColor3 = win.bg
    nav.BorderSizePixel = 0

    local left = Instance.new("TextButton", nav)
    left.Size = UDim2.new(0.5,0,1,0)
    left.Text = "<"
    left.TextScaled = true
    left.BackgroundColor3 = win.bg
    left.BorderColor3 = win.accent
    left.BorderSizePixel = 3
    left.TextColor3 = win.text

    local right = Instance.new("TextButton", nav)
    right.Size = UDim2.new(0.5,0,1,0)
    right.Position = UDim2.new(0.5,0,0,0)
    right.Text = ">"
    right.TextScaled = true
    right.BackgroundColor3 = win.bg
    right.BorderColor3 = win.accent
    right.BorderSizePixel = 3
    right.TextColor3 = win.text

    local container = Instance.new("Frame", mf)
    container.Size = UDim2.new(1,0,1,-70)
    container.Position = UDim2.new(0,0,0,70)
    container.BackgroundTransparency = 1

    ------------------------------------------------
    -- SIDE TAB (DESLIZÁVEL - COMO c00gui)
    ------------------------------------------------

    local sideTabFrame = Instance.new("Frame", mf)
    sideTabFrame.Size = UDim2.new(1,0,1,0)
    sideTabFrame.Position = UDim2.new(1, 3, 0, 0)  -- Começa FORA da tela (direita)
    sideTabFrame.BackgroundColor3 = win.bg
    sideTabFrame.BorderColor3 = win.accent
    sideTabFrame.BorderSizePixel = 3
    sideTabFrame.ZIndex = 1
    sideTabFrame.Visible = false

    local sideTitle = Instance.new("TextLabel", sideTabFrame)
    sideTitle.Size = UDim2.new(1,0,0,30)
    sideTitle.BackgroundColor3 = win.bg
    sideTitle.BorderColor3 = win.accent
    sideTitle.BorderSizePixel = 3
    sideTitle.TextColor3 = win.text
    sideTitle.TextSize = 14
    sideTitle.TextWrapped = true

    local sideContent = Instance.new("ScrollingFrame", sideTabFrame)
    sideContent.Size = UDim2.new(1,0,1,-30)
    sideContent.Position = UDim2.new(0,0,0,30)
    sideContent.BackgroundTransparency = 1
    sideContent.BorderSizePixel = 0
    sideContent.CanvasSize = UDim2.new(0,0,0,0)
    sideContent.ScrollBarThickness = 6

    local sideListLayout = Instance.new("UIListLayout", sideContent)
    sideListLayout.FillDirection = Enum.FillDirection.Vertical
    sideListLayout.Padding = UDim.new(0, 3)

    sideContent.ChildAdded:Connect(function()
        sideContent.CanvasSize = UDim2.new(0, 0, 0, sideListLayout.AbsoluteContentSize.Y + 10)
    end)

    ------------------------------------------------
    -- TOGGLE FECHAR/ABRIR
    ------------------------------------------------

    local toggleBtn = Instance.new("TextButton", sg)
    toggleBtn.Size = UDim2.new(0,300,0,20)
    toggleBtn.Position = UDim2.new(0,10,0.3,400)
    toggleBtn.Text = "Close"
    toggleBtn.BackgroundColor3 = win.bg
    toggleBtn.BorderColor3 = win.accent
    toggleBtn.BorderSizePixel = 3
    toggleBtn.TextColor3 = win.text
    toggleBtn.TextSize = 9
    toggleBtn.TextWrapped = true

    toggleBtn.MouseButton1Click:Connect(function()
        local st = not mf.Visible
        mf.Visible = st

        for i,v in ipairs(win.pages) do
            v.frame.Visible = st and (i == win.current)
        end

        toggleBtn.Text = st and "Close" or "Open"
    end)

    ------------------------------------------------
    -- FUNÇÃO TWEEN PARA SIDE TAB
    ------------------------------------------------

    local function toggleSideTab()
        if not win.hasSideTab then return end
        
        win.sideTabOpen = not win.sideTabOpen
        sideTabFrame.Visible = true

        local targetPos = win.sideTabOpen and UDim2.new(0, 0, 0, 0) or UDim2.new(1, 3, 0, 0)
        
        local tweenInfo = TweenInfo.new(
            0.3,  -- Duração
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.InOut
        )
        
        local tween = win.TweenService:Create(sideTabFrame, tweenInfo, {Position = targetPos})
        tween:Play()

        tween.Completed:Connect(function()
            if not win.sideTabOpen then
                sideTabFrame.Visible = false
            end
        end)
    end

    ------------------------------------------------
    -- ADD PAGE (NORMAL - COMO ANTES)
    ------------------------------------------------

    function win:AddPage()
        local pageframe = Instance.new("Frame", container)
        pageframe.Size = UDim2.new(1,0,1,0)
        pageframe.BackgroundTransparency = 1
        pageframe.Visible = (#win.pages == 0)

        local page = {frame = pageframe, sectionCount = 0}

        function page:AddSection(name)
            page.sectionCount += 1
            local leftSide = (page.sectionCount % 2 == 1)

            local sec = Instance.new("Frame", pageframe)
            sec.Size = UDim2.new(0.5,0,1,0)
            sec.Position = leftSide and UDim2.new(0,0,0,0) or UDim2.new(0.5,0,0,0)
            sec.BackgroundColor3 = win.bg
            sec.BorderColor3 = win.accent
            sec.BorderSizePixel = 3

            local tit = Instance.new("TextLabel", sec)
            tit.Size = UDim2.new(1,0,0,25)
            tit.Text = name
            tit.BackgroundColor3 = win.bg
            tit.BorderSizePixel = 0
            tit.TextColor3 = win.text
            tit.TextSize = 12
            tit.TextWrapped = true

            local content = Instance.new("Frame", sec)
            content.Size = UDim2.new(1,0,1,-25)
            content.Position = UDim2.new(0,0,0,25)
            content.BackgroundTransparency = 1

            local cursorY, col = 0, 0
            local padding, height = 4, 30

            local function colWidth()
                return (content.AbsoluteSize.X - padding) / 2
            end

            local function styleText(obj)
                obj.TextWrapped = true
                obj.TextXAlignment = Enum.TextXAlignment.Center
                obj.TextYAlignment = Enum.TextYAlignment.Center

                local pad = Instance.new("UIPadding", obj)
                pad.PaddingLeft = UDim.new(0,6)
                pad.PaddingRight = UDim.new(0,6)
            end

            local section = {}

            function section:AddButton(text, callback)
                local w = colWidth()
                local btn = Instance.new("TextButton", content)
                btn.Size = UDim2.new(0,w,0,height)
                btn.Position = UDim2.new(0,col*(w+padding),0,cursorY)
                btn.Text = text
                btn.BackgroundColor3 = win.bg
                btn.BorderColor3 = win.accent
                btn.BorderSizePixel = 3
                btn.TextColor3 = win.text
                btn.TextSize = 9
                styleText(btn)

                if callback then
                    btn.MouseButton1Click:Connect(callback)
                end

                col += 1
                if col >= 2 then col = 0 cursorY += height + padding end
            end

            function section:AddLabel(text)
                col = 0
                local lbl = Instance.new("TextLabel", content)
                lbl.Size = UDim2.new(1,0,0,height)
                lbl.Position = UDim2.new(0,0,0,cursorY)
                lbl.Text = text
                lbl.BackgroundColor3 = win.bg
                lbl.BorderColor3 = win.accent
                lbl.BorderSizePixel = 3
                lbl.TextColor3 = win.text
                lbl.TextSize = 9
                styleText(lbl)

                cursorY += height + padding
            end

            function section:AddSmallTextbox(placeholder, callback)
                local w = colWidth()
                local box = Instance.new("TextBox", content)
                box.Size = UDim2.new(0,w,0,height)
                box.Position = UDim2.new(0,col*(w+padding),0,cursorY)
                box.PlaceholderText = placeholder or "Digite..."
                box.Text = ""
                box.ClearTextOnFocus = false
                box.BackgroundColor3 = win.bg
                box.BorderColor3 = win.accent
                box.BorderSizePixel = 3
                box.TextColor3 = win.text
                box.TextSize = 10
                styleText(box)

                box.FocusLost:Connect(function(e)
                    if callback then callback(box.Text, e) end
                end)

                col += 1
                if col >= 2 then col = 0 cursorY += height + padding end
            end

            function section:AddBigTextbox(placeholder, callback)
                col = 0
                local box = Instance.new("TextBox", content)
                box.Size = UDim2.new(1,0,0,height)
                box.Position = UDim2.new(0,0,0,cursorY)
                box.PlaceholderText = placeholder or "Digite aqui..."
                box.Text = ""
                box.ClearTextOnFocus = false
                box.BackgroundColor3 = win.bg
                box.BorderColor3 = win.accent
                box.BorderSizePixel = 3
                box.TextColor3 = win.text
                box.TextSize = 10
                styleText(box)

                box.FocusLost:Connect(function(e)
                    if callback then callback(box.Text, e) end
                end)

                cursorY += height + padding
            end

            return section
        end

        table.insert(win.pages, page)
        return page
    end

    ------------------------------------------------
    -- ADD SIDE TAB (NOVO)
    ------------------------------------------------

    function win:AddSideTab(title)
        win.hasSideTab = true
        sideTitle.Text = title or "Settings"

        local sideTab = {}

        local function styleText(obj)
            obj.TextWrapped = true
            obj.TextXAlignment = Enum.TextXAlignment.Center
            obj.TextYAlignment = Enum.TextYAlignment.Center

            local pad = Instance.new("UIPadding", obj)
            pad.PaddingLeft = UDim.new(0,6)
            pad.PaddingRight = UDim.new(0,6)
        end

        ---- SButton ----
        function sideTab:SButton(text, callback)
            local btn = Instance.new("TextButton", sideContent)
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Text = text
            btn.BackgroundColor3 = win.bg
            btn.BorderColor3 = win.accent
            btn.BorderSizePixel = 3
            btn.TextColor3 = win.text
            btn.TextSize = 9
            styleText(btn)

            if callback then
                btn.MouseButton1Click:Connect(callback)
            end

            return btn
        end

        ---- SLabel ----
        function sideTab:SLabel(text)
            local lbl = Instance.new("TextLabel", sideContent)
            lbl.Size = UDim2.new(1, -10, 0, 25)
            lbl.Text = text
            lbl.BackgroundColor3 = win.bg
            lbl.BorderColor3 = win.accent
            lbl.BorderSizePixel = 3
            lbl.TextColor3 = win.text
            lbl.TextSize = 9
            styleText(lbl)

            return lbl
        end

        ---- SDivider ----
        function sideTab:SDivider()
            local div = Instance.new("Frame", sideContent)
            div.Size = UDim2.new(1, -10, 0, 2)
            div.BackgroundColor3 = win.accent
            div.BorderSizePixel = 0

            return div
        end

        ---- SSpacing ----
        function sideTab:SSpacing(height)
            local spacer = Instance.new("Frame", sideContent)
            spacer.Size = UDim2.new(1, -10, 0, height or 10)
            spacer.BackgroundTransparency = 1
            spacer.BorderSizePixel = 0

            return spacer
        end

        ---- STextbox ----
        function sideTab:STextbox(placeholder, callback)
            local box = Instance.new("TextBox", sideContent)
            box.Size = UDim2.new(1, -10, 0, 30)
            box.PlaceholderText = placeholder or "Digite..."
            box.Text = ""
            box.ClearTextOnFocus = false
            box.BackgroundColor3 = win.bg
            box.BorderColor3 = win.accent
            box.BorderSizePixel = 3
            box.TextColor3 = win.text
            box.TextSize = 10
            styleText(box)

            if callback then
                box.FocusLost:Connect(function(e)
                    callback(box.Text, e)
                end)
            end

            return box
        end

        ---- SToggle ----
        function sideTab:SToggle(text, default, callback)
            local container = Instance.new("Frame", sideContent)
            container.Size = UDim2.new(1, -10, 0, 30)
            container.BackgroundColor3 = win.bg
            container.BorderColor3 = win.accent
            container.BorderSizePixel = 3

            local lbl = Instance.new("TextLabel", container)
            lbl.Size = UDim2.new(0.6, 0, 1, 0)
            lbl.Text = text
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = win.text
            lbl.TextSize = 9
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextWrapped = true

            local toggleBtn = Instance.new("TextButton", container)
            toggleBtn.Size = UDim2.new(0.4, 0, 1, 0)
            toggleBtn.Position = UDim2.new(0.6, 0, 0, 0)
            toggleBtn.BackgroundColor3 = win.bg
            toggleBtn.BorderSizePixel = 0
            toggleBtn.TextSize = 8

            local toggled = default or false
            toggleBtn.Text = toggled and "ON" or "OFF"
            toggleBtn.TextColor3 = toggled and win.text or Color3.fromRGB(100,100,100)

            toggleBtn.MouseButton1Click:Connect(function()
                toggled = not toggled
                toggleBtn.Text = toggled and "ON" or "OFF"
                toggleBtn.TextColor3 = toggled and win.text or Color3.fromRGB(100,100,100)

                if callback then
                    callback(toggled)
                end
            end)

            return {button = toggleBtn, getValue = function() return toggled end, setValue = function(v) 
                toggled = v
                toggleBtn.Text = toggled and "ON" or "OFF"
                toggleBtn.TextColor3 = toggled and win.text or Color3.fromRGB(100,100,100)
            end}
        end

        ---- SSlider ----
        function sideTab:SSlider(text, min, max, default, callback)
            local container = Instance.new("Frame", sideContent)
            container.Size = UDim2.new(1, -10, 0, 55)
            container.BackgroundColor3 = win.bg
            container.BorderColor3 = win.accent
            container.BorderSizePixel = 3

            local lbl = Instance.new("TextLabel", container)
            lbl.Size = UDim2.new(1, 0, 0, 20)
            lbl.Text = text .. ": " .. (default or min)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = win.text
            lbl.TextSize = 8
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextWrapped = true

            local slider = Instance.new("Frame", container)
            slider.Size = UDim2.new(1, -10, 0, 4)
            slider.Position = UDim2.new(0, 5, 0, 25)
            slider.BackgroundColor3 = Color3.fromRGB(50,50,50)
            slider.BorderColor3 = win.accent
            slider.BorderSizePixel = 1

            local fill = Instance.new("Frame", slider)
            fill.BackgroundColor3 = win.accent
            fill.BorderSizePixel = 0

            local value = default or min
            local percentage = (value - min) / (max - min)
            fill.Size = UDim2.new(percentage, 0, 1, 0)

            local function updateSlider(input)
                local relX = math.clamp(input.Position.X - slider.AbsolutePosition.X, 0, slider.AbsoluteSize.X)
                percentage = relX / slider.AbsoluteSize.X
                value = math.floor(min + (max - min) * percentage)
                fill.Size = UDim2.new(percentage, 0, 1, 0)
                lbl.Text = text .. ": " .. value
                if callback then callback(value) end
            end

            slider.InputBegan:Connect(function(input, gp)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and not gp then
                    updateSlider(input)
                end
            end)

            slider.InputChanged:Connect(function(input, gp)
                if input.UserInputType == Enum.UserInputType.MouseMovement and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    updateSlider(input)
                end
            end)

            return {slider = slider, getValue = function() return value end, setValue = function(v)
                value = math.clamp(v, min, max)
                percentage = (value - min) / (max - min)
                fill.Size = UDim2.new(percentage, 0, 1, 0)
                lbl.Text = text .. ": " .. value
            end}
        end

        return sideTab
    end

    ------------------------------------------------
    -- NAVEGAÇÃO
    ------------------------------------------------

    left.MouseButton1Click:Connect(function()
        if win.sideTabOpen then
            toggleSideTab()
        elseif win.current > 1 then
            win.pages[win.current].frame.Visible = false
            win.current -= 1
            win.pages[win.current].frame.Visible = true
        end
    end)

    right.MouseButton1Click:Connect(function()
        if win.hasSideTab then
            toggleSideTab()
        elseif win.current < #win.pages then
            win.pages[win.current].frame.Visible = false
            win.current += 1
            win.pages[win.current].frame.Visible = true
        end
    end)

    return win
end

return c00lui
