-- c00lui.lua - VERSÃO IDIOTA E INFALÍVEL (sem metatable zuado)
local c00lgui = {}

function c00lgui.Window(config)
    config = config or {}
    local win = {
        pages = {},
        currentPage = 1,
        accent = config.AccentColor or Color3.fromRGB(255,0,0),
        bg = Color3.fromRGB(0,0,0),
        text = Color3.fromRGB(255,255,255)
    }

    -- cria a gui (mesmo código de sempre, só simplificado)
    local sg = Instance.new("ScreenGui", game.CoreGui)
    sg.ResetOnSpawn = false
    local mf = Instance.new("Frame", sg)
    mf.Size = UDim2.new(0,300,0,400)
    mf.Position = UDim2.new(0,10,0.3,0)
    mf.BackgroundColor3 = win.bg
    mf.BorderColor3 = win.accent
    mf.BorderSizePixel = 3

    local title = Instance.new("TextLabel", mf)
    title.Size = UDim2.new(1,0,0,40)
    title.BackgroundColor3 = win.bg
    title.BorderColor3 = win.accent
    title.BorderSizePixel = 3
    title.Text = config.Title or "Super Natural"
    title.TextColor3 = win.text
    title.TextScaled = true

    -- navegação < > (mesmo de sempre)
    local nav = Instance.new("Frame", mf)
    nav.Size = UDim2.new(1,0,0,40)
    nav.Position = UDim2.new(0,0,0,40)
    nav.BackgroundColor3 = win.bg
    nav.BorderColor3 = win.accent
    nav.BorderSizePixel = 3

    local left = Instance.new("TextButton", nav)
    left.Size = UDim2.new(0.5,0,1,0)
    left.Text = "<"
    left.TextScaled = true
    left.BackgroundColor3 = win.bg
    left.TextColor3 = win.text
    left.MouseButton1Click:Connect(function()
        if win.currentPage > 1 then
            win.pages[win.currentPage].frame.Visible = false
            win.currentPage = win.currentPage - 1
            win.pages[win.currentPage].frame.Visible = true
        end
    end)

    local right = Instance.new("TextButton", nav)
    right.Size = UDim2.new(0.5,0,1,0)
    right.Position = UDim2.new(0.5,0,0,0)
    right.Text = ">"
    right.TextScaled = true
    right.BackgroundColor3 = win.bg
    right.TextColor3 = win.text
    right.MouseButton1Click:Connect(function()
        if win.currentPage < #win.pages then
            win.pages[win.currentPage].frame.Visible = false
            win.currentPage = win.currentPage + 1
            win.pages[win.currentPage].frame.Visible = true
        end
    end)

    local container = Instance.new("Frame", mf)
    container.Size = UDim2.new(1,0,1,-80)
    container.Position = UDim2.new(0,0,0,80)
    container.BackgroundTransparency = 1

    -- FUNÇÃO ADD PAGE (aqui que tava o problema)
    function win:AddPage(name)
        local pageframe = Instance.new("Frame", container)
        pageframe.Size = UDim2.new(1,0,1,0)
        pageframe.BackgroundTransparency = 1
        pageframe.Visible = (#win.pages == 0)

        local page = {
            frame = pageframe,
            AddSection = function(self, secname)
                local coluna = #pageframe:GetChildren() % 2 == 1 and 0 or 0.5
                local sec = Instance.new("Frame", pageframe)
                sec.Size = UDim2.new(0.5,-6,1,0)
                sec.Position = UDim2.new(coluna, coluna == 0 and 0 or 3,0,0)
                sec.BackgroundColor3 = win.bg
                sec.BorderColor3 = win.accent
                sec.BorderSizePixel = 3

                local sectitle = Instance.new("TextLabel", sec)
                sectitle.Size = UDim2.new(1,0,0,30)
                sectitle.Text = secname
                sectitle.TextColor3 = win.text
                sectitle.BackgroundColor3 = win.bg
                sectitle.BorderColor3 = win.accent
                sectitle.BorderSizePixel = 3
                sectitle.TextScaled = true

                local y = 30
                local section = {}

                function section:AddButton(txt, cb)
                    y = y + 35
                    local btn = Instance.new("TextButton", sec)
                    btn.Size = UDim2.new(1,-6,0,30)
                    btn.Position = UDim2.new(0,3,0,y)
                    btn.Text = txt
                    btn.BackgroundColor3 = win.bg
                    btn.BorderColor3 = win.accent
                    btn.BorderSizePixel = 3
                    btn.TextColor3 = win.text
                    btn.TextScaled = true
                    if cb then btn.MouseButton1Click:Connect(cb) end
                end

                function section:AddToggle(txt, default, cb)
                    y = y + 35
                    local state = default or false
                    local frame = Instance.new("Frame", sec)
                    frame.Size = UDim2.new(1,-6,0,30)
                    frame.Position = UDim2.new(0,3,0,y)
                    frame.BackgroundTransparency = 1

                    local label = Instance.new("TextLabel", frame)
                    label.Size = UDim2.new(0.75,0,1,0)
                    label.Text = txt
                    label.TextColor3 = win.text
                    label.BackgroundTransparency = 1
                    label.TextXAlignment = Enum.TextXAlignment.Left

                    local toggle = Instance.new("TextButton", frame)
                    toggle.Size = UDim2.new(0.2,0,0.8,0)
                    toggle.Position = UDim2.new(0.8,0,0.1,0)
                    toggle.Text = state and "ON" or "OFF"
                    toggle.BackgroundColor3 = state and win.accent or win.bg
                    toggle.TextColor3 = win.text
                    toggle.MouseButton1Click:Connect(function()
                        state = not state
                        toggle.Text = state and "ON" or "OFF"
                        toggle.BackgroundColor3 = state and win.accent or win.bg
                        if cb then cb(state) end
                    end)
                end

                return section
            end
        }

        table.insert(win.pages, {frame = pageframe})
        return page
    end

    function win:Toggle()
        mf.Visible = not mf.Visible
    end

    return win
end

return c00lgui
