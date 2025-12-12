local c00lgui = {}

local Window = {}
Window.__index = Window

function c00lgui.Window(config)
    local self = setmetatable({}, Window)
    config = config or {}
    self.title = config.Title or "Super Natural"
    self.accent = config.AccentColor or Color3.fromRGB(255,0,0)
    self.bg = Color3.fromRGB(0,0,0)
    self.text = Color3.fromRGB(255,255,255)
    self.pages = {}
    self.current = 1

    local sg = Instance.new("ScreenGui", game.CoreGui)
    sg.ResetOnSpawn = false

    local mf = Instance.new("Frame", sg)
    mf.Size = UDim2.new(0,300,0,400)
    mf.Position = UDim2.new(0,10,0.3,0)
    mf.BackgroundColor3 = self.bg
    mf.BorderColor3 = self.accent
    mf.BorderSizePixel = 3
    self.mainFrame = mf

    local title = Instance.new("TextLabel", mf)
    title.Size = UDim2.new(1,0,0,40)
    title.Text = self.title
    title.BackgroundColor3 = self.bg
    title.BorderColor3 = self.accent
    title.BorderSizePixel = 3
    title.TextColor3 = self.text
    title.TextScaled = true

    local nav = Instance.new("Frame", mf)
    nav.Size = UDim2.new(1,0,0,40)
    nav.Position = UDim2.new(0,0,0,40)
    nav.BackgroundColor3 = self.bg
    nav.BorderColor3 = self.accent
    nav.BorderSizePixel = 3

    local left = Instance.new("TextButton", nav)
    left.Size = UDim2.new(0.5,0,1,0)
    left.Text = "<"
    left.TextScaled = true
    left.BackgroundColor3 = self.bg
    left.TextColor3 = self.text
    left.MouseButton1Click:Connect(function() self:PrevPage() end)

    local right = Instance.new("TextButton", nav)
    right.Size = UDim2.new(0.5,0,1,0)
    right.Position = UDim2.new(0.5,0,0,0)
    right.Text = ">"
    right.TextScaled = true
    right.BackgroundColor3 = self.bg
    right.TextColor3 = self.text
    right.MouseButton1Click:Connect(function() self:NextPage() end)

    self.container = Instance.new("Frame", mf)
    self.container.Size = UDim2.new(1,0,1,-80)
    self.container.Position = UDim2.new(0,0,0,80)
    self.container.BackgroundTransparency = 1

    -- BOTÃO DE CLOSE/OPEN FORA DA GUI (em baixo)
    local toggleBtn = Instance.new("TextButton", sg)
    toggleBtn.Size = UDim2.new(0,300,0,20)
    toggleBtn.Position = UDim2.new(0,10,0.3,400)  -- embaixo da GUI
    toggleBtn.BackgroundColor3 = self.bg
    toggleBtn.BorderColor3 = self.accent
    toggleBtn.BorderSizePixel = 3
    toggleBtn.Text = "Close"
    toggleBtn.TextColor3 = self.text
    toggleBtn.TextScaled = true
    toggleBtn.MouseButton1Click:Connect(function()
        mf.Visible = not mf.Visible
        toggleBtn.Text = mf.Visible and "Close" or "Open"
    end)
    self.toggleBtn = toggleBtn

    function self:AddPage()
        local pageframe = Instance.new("Frame", self.container)
        pageframe.Size = UDim2.new(1,0,1,0)
        pageframe.BackgroundTransparency = 1
        pageframe.Visible = (#self.pages == 0)

        local page = setmetatable({frame = pageframe}, Page)
        page.window = self
        table.insert(self.pages, page)
        return page
    end

    function self:NextPage()
        if self.current < #self.pages then
            self.pages[self.current].frame.Visible = false
            self.current = self.current + 1
            self.pages[self.current].frame.Visible = true
        end
    end

    function self:PrevPage()
        if self.current > 1 then
            self.pages[self.current].frame.Visible = false
            self.current = self.current - 1
            self.pages[self.current].frame.Visible = true
        end
    end

    function self:Toggle()
        mf.Visible = not mf.Visible
        self.toggleBtn.Text = mf.Visible and "Close" or "Open"
    end

    return self
end

-- Page e Section igual antes (copia da última versão que eu te passei, com coluna dupla)

local Page = {}
Page.__index = Page

function Page:AddSection(name)
    local col = (#self.frame:GetChildren() % 2 == 1) and 0 or 0.5
    local sec = Instance.new("Frame", self.frame)
    sec.Size = UDim2.new(0.5,-6,1,0)
    sec.Position = UDim2.new(col, col == 0 and 0 or 3,0,0)
    sec.BackgroundColor3 = self.window.bg
    sec.BorderColor3 = self.window.accent
    sec.BorderSizePixel = 3

    local tit = Instance.new("TextLabel", sec)
    tit.Size = UDim2.new(1,0,0,30)
    tit.Text = name
    tit.TextColor3 = self.window.text
    tit.BackgroundColor3 = self.window.bg
    tit.BorderColor3 = self.window.accent
    tit.BorderSizePixel = 3
    tit.TextScaled = true

    local y = 30
    local section = {}

    function section:AddButton(txt, cb)
        y = y + 35
        local btn = Instance.new("TextButton", sec)
        btn.Size = UDim2.new(1,-6,0,30)
        btn.Position = UDim2.new(0,3,0,y)
        btn.Text = txt
        btn.BackgroundColor3 = self.window.bg
        btn.BorderColor3 = self.window.accent
        btn.BorderSizePixel = 3
        btn.TextColor3 = self.window.text
        btn.TextScaled = true
        if cb then btn.MouseButton1Click:Connect(cb) end
    end

    -- AddToggle e outros aqui se quiser

    return section
end

return c00lgui
