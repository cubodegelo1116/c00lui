local c00lgui = {}

function c00lgui.Window(config)
    config = config or {}
    local win = {}
    win.title = config.Title or "Super Natural"
    win.accent = config.AccentColor or Color3.fromRGB(255,0,0)
    win.bg = Color3.fromRGB(0,0,0)
    win.text = Color3.fromRGB(255,255,255)

    local sg = Instance.new("ScreenGui", game.CoreGui)
    sg.ResetOnSpawn = false

    local mf = Instance.new("Frame", sg)
    mf.Size = UDim2.new(0,300,0,400)
    mf.Position = UDim2.new(0,10,0.3,0)  -- Posição antiga
    mf.BackgroundColor3 = win.bg
    mf.BorderColor3 = win.accent
    mf.BorderSizePixel = 3

    local title = Instance.new("TextLabel", mf)
    title.Size = UDim2.new(1,0,0,30)
    title.Text = win.title
    title.BackgroundColor3 = win.bg
    title.BorderColor3 = win.accent
    title.BorderSizePixel = 3
    title.TextColor3 = win.text
    title.TextSize = 18
    title.Font = Enum.Font.SourceSansBold

    local nav = Instance.new("Frame", mf)
    nav.Size = UDim2.new(1,0,0,40)
    nav.Position = UDim2.new(0,0,0,30)
    nav.BackgroundColor3 = win.bg
    nav.BorderColor3 = win.accent
    nav.BorderSizePixel = 3
    nav.ClipsDescendants = false

    local left = Instance.new("TextButton", nav)
    left.Size = UDim2.new(0.5,-6,1,-6)
    left.Position = UDim2.new(0,3,0,3)
    left.Text = "<"
    left.TextScaled = true
    left.BackgroundColor3 = win.bg
    left.BorderColor3 = win.accent
    left.BorderSizePixel = 3
    left.TextColor3 = win.text

    local right = Instance.new("TextButton", nav)
    right.Size = UDim2.new(0.5,-6,1,-6)
    right.Position = UDim2.new(0.5,3,0,3)
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

    local toggleBtn = Instance.new("TextButton", sg)
    toggleBtn.Size = UDim2.new(0,300,0,20)
    toggleBtn.Position = UDim2.new(0,10,0.3,400)
    toggleBtn.BackgroundColor3 = win.bg
    toggleBtn.BorderColor3 = win.accent
    toggleBtn.BorderSizePixel = 3
    toggleBtn.Text = "Close"
    toggleBtn.TextColor3 = win.text
    toggleBtn.TextScaled = true
    toggleBtn.MouseButton1Click:Connect(function()
        mf.Visible = not mf.Visible
        toggleBtn.Text = mf.Visible and "Close" or "Open"
    end)

    function win:AddSection(name)
        local col = (#container:GetChildren() % 2 == 1) and 0 or 0.5
        local sec = Instance.new("Frame", container)
        sec.Size = UDim2.new(0.5,0,1,0)  -- Encostadas
        sec.Position = UDim2.new(col,0,0,0)
        sec.BackgroundColor3 = win.bg
        sec.BorderColor3 = win.accent
        sec.BorderSizePixel = 3

        local tit = Instance.new("TextLabel", sec)
        tit.Size = UDim2.new(1,0,0,25)
        tit.Text = name
        tit.TextColor3 = win.text
        tit.BackgroundColor3 = win.bg
        tit.BorderColor3 = win.accent
        tit.BorderSizePixel = 3
        tit.TextSize = 16

        local content = Instance.new("Frame", sec)
        content.Size = UDim2.new(1,0,1,-25)
        content.Position = UDim2.new(0,0,0,25)
        content.BackgroundTransparency = 1

        local grid = Instance.new("UIGridLayout", content)
        grid.CellSize = UDim2.new(0.5,0,0,30)
        grid.CellPadding = UDim2.new(0,0,0,0)  -- Encostados total
        grid.SortOrder = Enum.SortOrder.LayoutOrder

        local section = {}

        function section:AddButton(txt, cb)
            local btn = Instance.new("TextButton")
            btn.Text = txt
            btn.BackgroundColor3 = win.bg
            btn.BorderColor3 = win.accent
            btn.BorderSizePixel = 3
            btn.TextColor3 = win.text
            btn.TextSize = 12
            btn.TextWrapped = true
            btn.TextXAlignment = Enum.TextXAlignment.Center
            btn.Parent = content
            if cb then btn.MouseButton1Click:Connect(cb) end
        end

        return section
    end

    return win
end

return c00lgui
