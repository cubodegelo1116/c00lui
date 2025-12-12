--[[
c00lgui Library v2 - FINAL FIX (AddSection funcionando + tabs visíveis)
]]

local c00lgui = {}
c00lgui.__index = c00lgui

local Window = {}
Window.__index = Window

function Window.new(config)
    local self = setmetatable({}, Window)
    self.title = config.Title or "c00lgui"
    self.position = config.Position or UDim2.new(0, 3, 0.3, 0)
    self.width = config.Width or 300
    self.height = config.Height or 400
    self.bgColor = config.BackgroundColor or Color3.fromRGB(0, 0, 0)
    self.accentColor = config.AccentColor or Color3.fromRGB(255, 0, 0)
    self.textColor = config.TextColor or Color3.fromRGB(255, 255, 255)
    self.pages = {}
    self.currentPage = 1
    self.visible = true
    self:_createGui()
    return self
end

function Window:_createGui()
    local coreGui = game:GetService("CoreGui")
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "c00lGuiWindow"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.Parent = coreGui

    self.mainFrame = Instance.new("Frame")
    self.mainFrame.BackgroundColor3 = self.bgColor
    self.mainFrame.BorderColor3 = self.accentColor
    self.mainFrame.BorderSizePixel = 3
    self.mainFrame.Position = self.position
    self.mainFrame.Size = UDim2.new(0, self.width, 0, self.height)
    self.mainFrame.Parent = self.screenGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundColor3 = self.bgColor
    titleLabel.BorderColor3 = self.accentColor
    titleLabel.BorderSizePixel = 3
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Font = Enum.Font.SourceSans
    titleLabel.TextScaled = true
    titleLabel.Text = self.title
    titleLabel.TextColor3 = self.textColor
    titleLabel.Parent = self.mainFrame
    self.titleLabel = titleLabel

    self.tabsContainer = Instance.new("Frame")
    self.tabsContainer.BackgroundColor3 = self.bgColor
    self.tabsContainer.BorderColor3 = self.accentColor
    self.tabsContainer.BorderSizePixel = 3
    self.tabsContainer.Position = UDim2.new(0, 0, 0, 40)
    self.tabsContainer.Size = UDim2.new(1, 0, 0, 40)
    self.tabsContainer.Parent = self.mainFrame

    local leftButton = Instance.new("TextButton")
    leftButton.BackgroundColor3 = self.bgColor
    leftButton.BorderColor3 = self.accentColor
    leftButton.BorderSizePixel = 3
    leftButton.Position = UDim2.new(0, 0, 0, 0)
    leftButton.Size = UDim2.new(0.5, -2, 1, 0)
    leftButton.Text = "<"
    leftButton.TextColor3 = self.textColor
    leftButton.TextScaled = true
    leftButton.Parent = self.tabsContainer
    leftButton.MouseButton1Down:Connect(function() self:PreviousPage() end)

    local rightButton = Instance.new("TextButton")
    rightButton.BackgroundColor3 = self.bgColor
    rightButton.BorderColor3 = self.accentColor
    rightButton.BorderSizePixel = 3
    rightButton.Position = UDim2.new(0.5, 2, 0, 0)
    rightButton.Size = UDim2.new(0.5, -2, 1, 0)
    rightButton.Text = ">"
    rightButton.TextColor3 = self.textColor
    rightButton.TextScaled = true
    rightButton.Parent = self.tabsContainer
    rightButton.MouseButton1Down:Connect(function() self:NextPage() end)

    self.pagesContainer = Instance.new("Frame")
    self.pagesContainer.BackgroundColor3 = self.bgColor
    self.pagesContainer.BorderColor3 = self.accentColor
    self.pagesContainer.BorderSizePixel = 3
    self.pagesContainer.Position = UDim2.new(0, 0, 0, 80)
    self.pagesContainer.Size = UDim2.new(1, 0, 1, -80)
    self.pagesContainer.Parent = self.mainFrame

    self.toggleButton = Instance.new("TextButton")
    self.toggleButton.BackgroundColor3 = self.bgColor
    self.toggleButton.BorderColor3 = self.accentColor
    self.toggleButton.BorderSizePixel = 3
    self.toggleButton.Position = UDim2.new(0, 3, 0.3, self.height)
    self.toggleButton.Size = UDim2.new(0, self.width, 0, 20)
    self.toggleButton.Text = "Close"
    self.toggleButton.TextColor3 = self.textColor
    self.toggleButton.Parent = self.screenGui
    self.toggleButton.MouseButton1Down:Connect(function() self:Toggle() end)
end

function Window:AddPage(name)
    local pageIndex = #self.pages + 1
    local pageFrame = Instance.new("Frame")
    pageFrame.Name = name
    pageFrame.BackgroundColor3 = self.bgColor
    pageFrame.BorderColor3 = self.accentColor
    pageFrame.BorderSizePixel = 3
    pageFrame.Position = UDim2.new(0, 0, 0, 0)
    pageFrame.Size = UDim2.new(1, 0, 1, 0)
    pageFrame.Visible = (pageIndex == 1)
    pageFrame.Parent = self.pagesContainer

    local page = setmetatable({frame = pageFrame, sections = {}, window = self}, Page)
    table.insert(self.pages, page)
    return page
end

function Window:NextPage()
    if self.currentPage < #self.pages then
        self.pages[self.currentPage].frame.Visible = false
        self.currentPage = self.currentPage + 1
        self.pages[self.currentPage].frame.Visible = true
    end
end

function Window:PreviousPage()
    if self.currentPage > 1 then
        self.pages[self.currentPage].frame.Visible = false
        self.currentPage = self.currentPage - 1
        self.pages[self.currentPage].frame.Visible = true
    end
end

function Window:Toggle()
    self.visible = not self.visible
    self.mainFrame.Visible = self.visible
    self.toggleButton.Text = self.visible and "Close" or "Open"
end

function Window:Show() self.visible = true self.mainFrame.Visible = true self.toggleButton.Text = "Close" end
function Window:Hide() self.visible = false self.mainFrame.Visible = false self.toggleButton.Text = "Open" end
function Window:Destroy() self.screenGui:Destroy() end

local Page = {}
Page.__index = Page

function Page:AddSection(name, config)
    config = config or {}
    local idx = #self.sections + 1
    local secFrame = Instance.new("Frame")
    secFrame.Name = name
    secFrame.BackgroundColor3 = config.BackgroundColor or self.window.bgColor
    secFrame.BorderColor3 = config.BorderColor or self.window.accentColor
    secFrame.BorderSizePixel = config.BorderSize or 3
    secFrame.Position = UDim2.new(idx == 1 and 0 or 0.5, idx == 1 and 0 or 3, 0, 0)
    secFrame.Size = UDim2.new(0.5, -6, 1, 0)
    secFrame.ClipsDescendants = true
    secFrame.Parent = self.frame

    local title = Instance.new("TextLabel")
    title.BackgroundColor3 = secFrame.BackgroundColor3
    title.BorderColor3 = secFrame.BorderColor3
    title.BorderSizePixel = 3
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = name
    title.TextColor3 = self.window.textColor
    title.TextScaled = true
    title.Parent = secFrame

    local section = setmetatable({frame = secFrame, elementCount = 0, window = self.window}, Section)
    table.insert(self.sections, section)
    return section
end

local Section = {}
Section.__index = Section

function Section:AddButton(name, config)
    config = config or {}
    local y = 30 + (self.elementCount * 35)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = config.BackgroundColor or self.window.bgColor
    btn.BorderColor3 = config.BorderColor or self.window.accentColor
    btn.BorderSizePixel = 3
    btn.Position = UDim2.new(0, 3, 0, y)
    btn.Size = UDim2.new(1, -6, 0, 30)
    btn.Text = name
    btn.TextColor3 = self.window.textColor
    btn.TextScaled = true
    btn.Parent = self.frame
    if config.OnClick then btn.MouseButton1Down:Connect(config.OnClick) end
    self.elementCount = self.elementCount + 1
    return btn
end

function Section:AddToggle(name, config)
    config = config or {}
    local y = 30 + (self.elementCount * 35)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, -6, 0, 30)
    frame.Position = UDim2.new(0, 3, 0, y)
    frame.Parent = self.frame

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Text = name
    label.TextColor3 = self.window.textColor
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local check = Instance.new("TextButton")
    check.BackgroundColor3 = config.Default and self.window.accentColor or self.window.bgColor
    check.BorderColor3 = self.window.accentColor
    check.BorderSizePixel = 2
    check.Size = UDim2.new(0.2, 0, 0.8, 0)
    check.Position = UDim2.new(0.8, 0, 0.1, 0)
    check.Text = config.Default and "ON" or "OFF"
    check.TextColor3 = self.window.textColor
    check.Parent = frame

    local state = config.Default or false
    check.MouseButton1Down:Connect(function()
        state = not state
        check.BackgroundColor3 = state and self.window.accentColor or self.window.bgColor
        check.Text = state and "ON" or "OFF"
        if config.OnChange then config.OnChange(state) end
    end)

    self.elementCount = self.elementCount + 1
    return {getValue = function() return state end}
end

function Section:AddTextInput(placeholder, config)
    config = config or {}
    local y = 30 + (self.elementCount * 35)
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = config.BackgroundColor or self.window.bgColor
    frame.BorderColor3 = config.BorderColor or self.window.accentColor
    frame.BorderSizePixel = 3
    frame.Position = UDim2.new(0, 3, 0, y)
    frame.Size = UDim2.new(1, -6, 0, 30)
    frame.Parent = self.frame

    local box = Instance.new("TextBox")
    box.BackgroundColor3 = self.window.bgColor
    box.BorderColor3 = self.window.accentColor
    box.BorderSizePixel = 1
    box.Position = UDim2.new(0, 3, 0.1, 0)
    box.Size = UDim2.new(1, -6, 0.8, 0)
    box.PlaceholderText = placeholder
    box.Text = config.DefaultText or ""
    box.TextColor3 = self.window.textColor
    box.Parent = frame

    if config.OnChange then
        box:GetPropertyChangedSignal("Text"):Connect(function() config.OnChange(box.Text) end)
    end

    self.elementCount = self.elementCount + 1
    return {input = box, getText = function() return box.Text end, setText = function(t) box.Text = t end}
end

function c00lgui.Window(config) return Window.new(config) end
return c00lgui
