--[[
c00lgui Library v3 - Estilo c00lkidd Reborn com Tabs no Topo
Feito pro mano do SN, fica foda
]]

local c00lgui = {}
c00lgui.__index = c00lgui

-- Window
local Window = {}
Window.__index = Window

function c00lgui.Window(config)
    local self = setmetatable({}, Window)
    
    self.title = config.Title or "c00lgui"
    self.position = config.Position or UDim2.new(0.5, -150, 0.3, 0)
    self.width = config.Width or 500
    self.height = config.Height or 400
    
    self.bgColor = config.BackgroundColor or Color3.fromRGB(20, 20, 20)
    self.accentColor = config.AccentColor or Color3.fromRGB(255, 0, 0)
    self.textColor = config.TextColor or Color3.fromRGB(255, 255, 255)
    
    self.tabs = {}
    self.currentTab = nil
    self.visible = true
    
    self:_createGui()
    return self
end

function Window:_createGui()
    local coreGui = game:GetService("CoreGui")
    local userInput = game:GetService("UserInputService")
    
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "c00lGui"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.Parent = coreGui
    
    -- Main Frame
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.BackgroundColor3 = self.bgColor
    self.mainFrame.BorderColor3 = self.accentColor
    self.mainFrame.BorderSizePixel = 3
    self.mainFrame.Position = self.position
    self.mainFrame.Size = UDim2.new(0, self.width, 0, self.height)
    self.mainFrame.Parent = self.screenGui
    self.mainFrame.Active = true
    self.mainFrame.Draggable = true  -- Draggable pra ficar pro
    
    -- Title Bar
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Text = self.title
    title.TextColor3 = self.textColor
    title.Parent = self.mainFrame
    
    -- Tabs Container
    self.tabsContainer = Instance.new("Frame")
    self.tabsContainer.BackgroundColor3 = self.bgColor
    self.tabsContainer.BorderSizePixel = 0
    self.tabsContainer.Position = UDim2.new(0, 0, 0, 40)
    self.tabsContainer.Size = UDim2.new(1, 0, 0, 40)
    self.tabsContainer.Parent = self.mainFrame
    
    -- Content Container
    self.contentContainer = Instance.new("Frame")
    self.contentContainer.BackgroundColor3 = self.bgColor
    self.contentContainer.BorderSizePixel = 0
    self.contentContainer.Position = UDim2.new(0, 0, 0, 80)
    self.contentContainer.Size = UDim2.new(1, 0, 1, -80)
    self.contentContainer.Parent = self.mainFrame
    
    -- Toggle Button
    self.toggleButton = Instance.new("TextButton")
    self.toggleButton.Size = UDim2.new(0, self.width, 0, 30)
    self.toggleButton.Position = self.position + UDim2.new(0, 0, 0, self.height)
    self.toggleButton.BackgroundColor3 = self.bgColor
    self.toggleButton.BorderColor3 = self.accentColor
    self.toggleButton.BorderSizePixel = 3
    self.toggleButton.Text = "Close"
    self.toggleButton.TextColor3 = self.textColor
    self.toggleButton.Font = Enum.Font.Gotham
    self.toggleButton.Parent = self.screenGui
    
    self.toggleButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

function Window:AddTab(name)
    local tab = {}
    tab.name = name
    tab.window = self
    
    -- Tab Button
    tab.button = Instance.new("TextButton")
    tab.button.BackgroundColor3 = self.bgColor
    tab.button.BorderColor3 = self.accentColor
    tab.button.BorderSizePixel = 2
    tab.button.Size = UDim2.new(0, 100, 1, 0)
    tab.button.Position = UDim2.new(0, (#self.tabs * 100), 0, 0)
    tab.button.Text = name
    tab.button.TextColor3 = self.textColor
    tab.button.Font = Enum.Font.Gotham
    tab.button.Parent = self.tabsContainer
    
    -- Tab Content Frame
    tab.frame = Instance.new("Frame")
    tab.frame.BackgroundColor3 = self.bgColor
    tab.frame.BorderSizePixel = 0
    tab.frame.Size = UDim2.new(1, 0, 1, 0)
    tab.frame.Visible = false
    tab.frame.Parent = self.contentContainer
    
    tab.sections = {}
    
    tab.button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    table.insert(self.tabs, tab)
    
    if #self.tabs == 1 then
        self:SelectTab(tab)
    end
    
    setmetatable(tab, {__index = Tab})
    return tab
end

function Window:SelectTab(tab)
    if self.currentTab then
        self.currentTab.button.BackgroundColor3 = self.bgColor
        self.currentTab.frame.Visible = false
    end
    tab.button.BackgroundColor3 = self.accentColor
    tab.frame.Visible = true
    self.currentTab = tab
end

function Window:Toggle()
    self.visible = not self.visible
    self.mainFrame.Visible = self.visible
    self.toggleButton.Text = self.visible and "Close" or "Open"
end

-- Tab methods
local Tab = {}

function Tab:AddSection(name, side) -- side = "Left" or "Right"
    local section = {}
    section.frame = Instance.new("Frame")
    section.frame.BackgroundColor3 = self.window.bgColor
    section.frame.BorderColor3 = self.window.accentColor
    section.frame.BorderSizePixel = 3
    section.frame.Size = UDim2.new(0.5, -6, 1, -10)
    section.frame.Position = side == "Right" and UDim2.new(0.5, 3, 0, 5) or UDim2.new(0, 3, 0, 5)
    section.frame.Parent = self.frame
    
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = name
    title.TextColor3 = self.window.textColor
    title.Font = Enum.Font.GothamBold
    title.Parent = section.frame
    
    section.elements = {}
    section.elementY = 35
    section.window = self.window
    
    table.insert(self.sections, section)
    setmetatable(section, {__index = Section})
    return section
end

-- Section methods
local Section = {}

function Section:AddButton(name, callback)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = self.window.accentColor
    btn.BorderSizePixel = 0
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, self.elementY)
    btn.Text = name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.Parent = self.frame
    
    btn.MouseButton1Click:Connect(callback or function() end)
    
    self.elementY = self.elementY + 35
    return btn
end

function Section:AddToggle(name, default, callback)
    local state = default or false
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.Position = UDim2.new(0, 0, 0, self.elementY)
    frame.Parent = self.frame
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = name
    label.TextColor3 = self.window.textColor
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local check = Instance.new("TextButton")
    check.BackgroundColor3 = state and self.window.accentColor or Color3.fromRGB(50,50,50)
    check.Size = UDim2.new(0, 40, 0, 20)
    check.Position = UDim2.new(1, -50, 0.5, -10)
    check.Text = state and "ON" or "OFF"
    check.TextColor3 = Color3.new(1,1,1)
    check.Parent = frame
    
    check.MouseButton1Click:Connect(function()
        state = not state
        check.BackgroundColor3 = state and self.window.accentColor or Color3.fromRGB(50,50,50)
        check.Text = state and "ON" or "OFF"
        if callback then callback(state) end
    end)
    
    self.elementY = self.elementY + 35
end

-- Adicione AddLabel e AddTextInput similar se quiser, mas já tá o básico foda

return c00lgui
