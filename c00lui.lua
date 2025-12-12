--[[
c00lgui Library v2.1 - Mesma visual, só com AddTab no lugar de AddPage
Mantém os botões < > pra navegar tabs
]]

local c00lgui = {}
c00lgui.__index = c00lgui

-- Window Object
local Window = {}
Window.__index = Window

function Window.new(config)
    local self = setmetatable({}, Window)
    -- Default Configuration
    self.title = config.Title or "c00lgui"
    self.position = config.Position or UDim2.new(0, 3, 0.3, 0)
    self.width = config.Width or 300
    self.height = config.Height or 400
    -- Colors
    self.bgColor = config.BackgroundColor or Color3.fromRGB(0, 0, 0)
    self.accentColor = config.AccentColor or Color3.fromRGB(255, 0, 0)
    self.textColor = config.TextColor or Color3.fromRGB(255, 255, 255)
    
    self.tabs = {}  -- Agora chama tabs
    self.currentTab = 1
    self.visible = true
    
    self:_createGui()
    return self
end

function Window:_createGui()
    local coreGui = game:GetService("CoreGui")
    
    -- Main ScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "c00lGuiWindow"
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
    
    -- Title Bar
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundColor3 = self.bgColor
    titleLabel.BorderColor3 = self.accentColor
    titleLabel.BorderSizePixel = 3
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Font = Enum.Font.SourceSans
    titleLabel.TextSize = 24
    titleLabel.Text = self.title
    titleLabel.TextColor3 = self.textColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = self.mainFrame
    self.titleLabel = titleLabel
    
    -- Left Button (<)
    local leftButton = Instance.new("TextButton")
    leftButton.BackgroundColor3 = self.bgColor
    leftButton.BorderColor3 = self.accentColor
    leftButton.BorderSizePixel = 3
    leftButton.Position = UDim2.new(0, 0, 0, 40)
    leftButton.Size = UDim2.new(0.5, -2, 0, 40)
    leftButton.Font = Enum.Font.SourceSans
    leftButton.TextSize = 48
    leftButton.Text = "<"
    leftButton.TextColor3 = self.textColor
    leftButton.Parent = self.mainFrame
    leftButton.MouseButton1Click:Connect(function()
        self:PreviousTab()
    end)
    
    -- Right Button (>)
    local rightButton = Instance.new("TextButton")
    rightButton.BackgroundColor3 = self.bgColor
    rightButton.BorderColor3 = self.accentColor
    rightButton.BorderSizePixel = 3
    rightButton.Position = UDim2.new(0.5, 2, 0, 40)
    rightButton.Size = UDim2.new(0.5, -2, 0, 40)
    rightButton.Font = Enum.Font.SourceSans
    rightButton.TextSize = 48
    rightButton.Text = ">"
    rightButton.TextColor3 = self.textColor
    rightButton.Parent = self.mainFrame
    rightButton.MouseButton1Click:Connect(function()
        self:NextTab()
    end)
    
    -- Tabs Container (mesmo que pages antes)
    self.tabsContainer = Instance.new("Frame")
    self.tabsContainer.BackgroundColor3 = self.bgColor
    self.tabsContainer.BorderColor3 = self.accentColor
    self.tabsContainer.BorderSizePixel = 3
    self.tabsContainer.Position = UDim2.new(0, 0, 0, 80)
    self.tabsContainer.Size = UDim2.new(1, 0, 1, -80)
    self.tabsContainer.ClipsDescendants = false
    self.tabsContainer.Parent = self.mainFrame
    
    -- Toggle Button
    self.toggleButton = Instance.new("TextButton")
    self.toggleButton.BackgroundColor3 = self.bgColor
    self.toggleButton.BorderColor3 = self.accentColor
    self.toggleButton.BorderSizePixel = 3
    self.toggleButton.Position = UDim2.new(0, 3, 0.3, self.height)  -- Ajustado pra ficar logo abaixo
    self.toggleButton.Size = UDim2.new(0, self.width, 0, 20)
    self.toggleButton.Font = Enum.Font.SourceSans
    self.toggleButton.TextSize = 18
    self.toggleButton.Text = "Close"
    self.toggleButton.TextColor3 = self.textColor
    self.toggleButton.Parent = self.screenGui
    self.toggleButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
end

-- Adiciona Tab (mesma coisa que AddPage antes)
function Window:AddTab(name)
    local tabIndex = #self.tabs + 1
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = name
    tabFrame.BackgroundColor3 = self.bgColor
    tabFrame.BorderColor3 = self.accentColor
    tabFrame.BorderSizePixel = 3
    tabFrame.Position = UDim2.new(0, 0, 0, 0)
    tabFrame.Size = UDim2.new(1, 0, 1, 0)
    tabFrame.Visible = (tabIndex == 1)
    tabFrame.Parent = self.tabsContainer
    
    local tab = {
        name = name,
        frame = tabFrame,
        sections = {},
        window = self
    }
    setmetatable(tab, {__index = Tab})
    table.insert(self.tabs, tab)
    return tab
end

function Window:NextTab()
    if self.currentTab < #self.tabs then
        self.tabs[self.currentTab].frame.Visible = false
        self.currentTab = self.currentTab + 1
        self.tabs[self.currentTab].frame.Visible = true
    end
end

function Window:PreviousTab()
    if self.currentTab > 1 then
        self.tabs[self.currentTab].frame.Visible = false
        self.currentTab = self.currentTab - 1
        self.tabs[self.currentTab].frame.Visible = true
    end
end

function Window:Toggle()
    self.visible = not self.visible
    self.mainFrame.Visible = self.visible
    self.toggleButton.Text = self.visible and "Close" or "Open"
end

-- As outras funções (Show, Hide, SetTitle, Destroy) ficam iguais...

-- Tab Object (igual Page)
local Tab = {}
Tab.__index = Tab

function Tab:AddSection(name, config)
    -- EXATAMENTE o mesmo código de AddSection da Page original
    config = config or {}
    local sectionIndex = #self.sections + 1
    local window = self.window
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Name = name
    sectionFrame.BackgroundColor3 = config.BackgroundColor or window.bgColor
    sectionFrame.BorderColor3 = config.BorderColor or window.accentColor
    sectionFrame.BorderSizePixel = config.BorderSize or 3
    sectionFrame.Position = UDim2.new((sectionIndex == 1 and 0 or 0.5), (sectionIndex == 1 and 0 or 3), 0, 0)
    sectionFrame.Size = UDim2.new(0.5, (sectionIndex == 1 and -3 or -3), 1, 0)
    sectionFrame.ClipsDescendants = false
    sectionFrame.Parent = self.frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundColor3 = config.BackgroundColor or window.bgColor
    titleLabel.BorderColor3 = config.BorderColor or window.accentColor
    titleLabel.BorderSizePixel = config.BorderSize or 3
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Font = config.TitleFont or Enum.Font.SourceSans
    titleLabel.TextSize = config.TitleFontSize or 14
    titleLabel.Text = name
    titleLabel.TextColor3 = config.TextColor or window.textColor
    titleLabel.Parent = sectionFrame
    
    local section = {
        name = name,
        frame = sectionFrame,
        elements = {},
        elementCount = 0,
        window = window,
        tab = self
    }
    setmetatable(section, {__index = Section})
    table.insert(self.sections, section)
    return section
end

-- Section, AddButton, AddLabel, AddToggle, AddTextInput -> COPIA EXATAMENTE os da tua lib original (não mudei nada)

-- (Cola aqui os objetos Section com todas as funções AddButton, AddLabel, etc. da tua mensagem original, são idênticos)

-- Library Functions
function c00lgui.Window(config)
    return Window.new(config)
end

return c00lgui
