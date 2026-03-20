--[[ 
    c00lUI
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
    -- TOGGLE
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
    -- ADD PAGE
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

    left.MouseButton1Click:Connect(function()
        if win.current > 1 then
            win.pages[win.current].frame.Visible = false
            win.current -= 1
            win.pages[win.current].frame.Visible = true
        end
    end)

    right.MouseButton1Click:Connect(function()
        if win.current < #win.pages then
            win.pages[win.current].frame.Visible = false
            win.current += 1
            win.pages[win.current].frame.Visible = true
        end
    end)

    return win
end

return c00lui
