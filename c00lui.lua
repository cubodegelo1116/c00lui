--[[
	c00lgui Library v3 - Refatorado com estrutura de abas laterais
	Uma poderosa biblioteca para criar GUIs customizáveis com o visual c00lgui
	
	Estrutura:
	Window -> Tab -> Section -> Elements (Button, Toggle, Label, Input)
	
	Usage:
	local c00l = loadstring(game:HttpGet("URL"))()
	local window = c00l.Window({Title = "Meu GUI"})
	local tab = window:AddTab("Admin")
	local section = tab:AddSection("Tools")
	section:AddButton("Kill All", {OnClick = function() ... end})
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
	self.width = config.Width or 550
	self.height = config.Height or 400
	
	-- Colors
	self.bgColor = config.BackgroundColor or Color3.fromRGB(0, 0, 0)
	self.accentColor = config.AccentColor or Color3.fromRGB(255, 0, 0)
	self.textColor = config.TextColor or Color3.fromRGB(255, 255, 255)
	
	self.tabs = {}
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
	self.mainFrame.Name = "MainFrame"
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
	titleLabel.FontSize = Enum.FontSize.Size24
	titleLabel.Text = self.title
	titleLabel.TextColor3 = self.textColor
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = self.mainFrame
	self.titleLabel = titleLabel
	
	-- Left Tab Container (scrollável)
	self.tabsScroll = Instance.new("ScrollingFrame")
	self.tabsScroll.Name = "TabsScroll"
	self.tabsScroll.BackgroundColor3 = self.bgColor
	self.tabsScroll.BorderColor3 = self.accentColor
	self.tabsScroll.BorderSizePixel = 3
	self.tabsScroll.Position = UDim2.new(0, 0, 0, 40)
	self.tabsScroll.Size = UDim2.new(0, 160, 1, -40)
	self.tabsScroll.ScrollBarThickness = 1.5
	self.tabsScroll.ScrollBarImageTransparency = 0.2
	self.tabsScroll.ScrollBarImageColor3 = self.accentColor
	self.tabsScroll.CanvasSize = UDim2.new()
	self.tabsScroll.AutomaticCanvasSize = "Y"
	self.tabsScroll.ScrollingDirection = "Y"
	self.tabsScroll.BorderSizePixel = 3
	self.tabsScroll.Parent = self.mainFrame
	
	-- Tabs Layout
	local tabsList = Instance.new("UIListLayout")
	tabsList.Padding = UDim.new(0, 3)
	tabsList.SortOrder = Enum.SortOrder.LayoutOrder
	tabsList.Parent = self.tabsScroll
	
	local tabsPadding = Instance.new("UIPadding")
	tabsPadding.PaddingLeft = UDim.new(0, 3)
	tabsPadding.PaddingRight = UDim.new(0, 3)
	tabsPadding.PaddingTop = UDim.new(0, 5)
	tabsPadding.PaddingBottom = UDim.new(0, 5)
	tabsPadding.Parent = self.tabsScroll
	
	-- Content Container
	self.contentContainer = Instance.new("Frame")
	self.contentContainer.Name = "Content"
	self.contentContainer.BackgroundColor3 = self.bgColor
	self.contentContainer.BorderColor3 = self.accentColor
	self.contentContainer.BorderSizePixel = 3
	self.contentContainer.Position = UDim2.new(0, 160, 0, 40)
	self.contentContainer.Size = UDim2.new(1, -160, 1, -40)
	self.contentContainer.Parent = self.mainFrame
	
	-- Close/Open Button (FORA da GUI)
	self.toggleButton = Instance.new("TextButton")
	self.toggleButton.Name = "Close/Open"
	self.toggleButton.Active = true
	self.toggleButton.AutoButtonColor = true
	self.toggleButton.BackgroundColor3 = self.bgColor
	self.toggleButton.BorderColor3 = self.accentColor
	self.toggleButton.BorderSizePixel = 3
	self.toggleButton.Position = UDim2.new(0, 3, 0.3, 400) -- MUDE AQUI A POSIÇÃO
	self.toggleButton.Size = UDim2.new(0, self.width - 6, 0, 20)
	self.toggleButton.Font = Enum.Font.SourceSans
	self.toggleButton.FontSize = Enum.FontSize.Size18
	self.toggleButton.Text = "Close"
	self.toggleButton.TextColor3 = self.textColor
	self.toggleButton.TextXAlignment = Enum.TextXAlignment.Center
	self.toggleButton.Parent = self.screenGui
	self.toggleButton.MouseButton1Down:Connect(function()
		self:Toggle()
	end)
end

function Window:AddTab(name)
	local tabIndex = #self.tabs + 1
	
	-- Tab Button
	local tabButton = Instance.new("TextButton")
	tabButton.Name = name
	tabButton.BackgroundColor3 = self.bgColor
	tabButton.BorderColor3 = self.accentColor
	tabButton.BorderSizePixel = 3
	tabButton.Size = UDim2.new(1, 0, 0, 30)
	tabButton.Font = Enum.Font.SourceSans
	tabButton.FontSize = Enum.FontSize.Size14
	tabButton.Text = name
	tabButton.TextColor3 = self.textColor
	tabButton.LayoutOrder = tabIndex
	tabButton.Parent = self.tabsScroll
	
	-- Tab Content Frame
	local tabFrame = Instance.new("ScrollingFrame")
	tabFrame.Name = name
	tabFrame.BackgroundColor3 = self.bgColor
	tabFrame.BorderColor3 = self.accentColor
	tabFrame.BorderSizePixel = 3
	tabFrame.Size = UDim2.new(1, 0, 1, 0)
	tabFrame.ScrollBarThickness = 1.5
	tabFrame.ScrollBarImageTransparency = 0.2
	tabFrame.ScrollBarImageColor3 = self.accentColor
	tabFrame.CanvasSize = UDim2.new()
	tabFrame.AutomaticCanvasSize = "Y"
	tabFrame.ScrollingDirection = "Y"
	tabFrame.Visible = (tabIndex == 1)
	tabFrame.Parent = self.contentContainer
	
	-- Content Layout
	local contentList = Instance.new("UIListLayout")
	contentList.Padding = UDim.new(0, 3)
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Parent = tabFrame
	
	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingLeft = UDim.new(0, 5)
	contentPadding.PaddingRight = UDim.new(0, 5)
	contentPadding.PaddingTop = UDim.new(0, 5)
	contentPadding.PaddingBottom = UDim.new(0, 5)
	contentPadding.Parent = tabFrame
	
	local tab = {
		name = name,
		button = tabButton,
		frame = tabFrame,
		sections = {},
		window = self
	}
	
	-- Tab Click Handler
	tabButton.MouseButton1Down:Connect(function()
		self:SelectTab(tabIndex)
	end)
	
	setmetatable(tab, {__index = Tab})
	table.insert(self.tabs, tab)
	
	return tab
end

function Window:SelectTab(index)
	-- Hide all tabs
	for _, tab in ipairs(self.tabs) do
		tab.frame.Visible = false
		tab.button.BackgroundColor3 = self.bgColor
		tab.button.BorderSizePixel = 3
	end
	
	-- Show selected tab
	if self.tabs[index] then
		self.currentTab = index
		self.tabs[index].frame.Visible = true
		self.tabs[index].button.BackgroundColor3 = self.accentColor
		self.tabs[index].button.BorderSizePixel = 1
	end
end

function Window:Toggle()
	self.visible = not self.visible
	self.mainFrame.Visible = self.visible
	self.toggleButton.Text = self.visible and "Close" or "Open"
end

function Window:Show()
	self.visible = true
	self.mainFrame.Visible = true
	self.toggleButton.Text = "Close"
end

function Window:Hide()
	self.visible = false
	self.mainFrame.Visible = false
	self.toggleButton.Text = "Open"
end

function Window:SetTitle(title)
	self.titleLabel.Text = title
end

function Window:Destroy()
	self.screenGui:Destroy()
end

-- Tab Object
local Tab = {}
Tab.__index = Tab

function Tab:AddSection(name, config)
	config = config or {}
	local sectionIndex = #self.sections + 1
	local window = self.window
	
	local sectionFrame = Instance.new("Frame")
	sectionFrame.Name = name
	sectionFrame.BackgroundColor3 = config.BackgroundColor or window.bgColor
	sectionFrame.BorderColor3 = config.BorderColor or window.accentColor
	sectionFrame.BorderSizePixel = config.BorderSize or 3
	sectionFrame.Size = UDim2.new(1, 0, 0, 30)
	sectionFrame.AutomaticSize = "Y"
	sectionFrame.LayoutOrder = sectionIndex
	sectionFrame.Parent = self.frame
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "SectionTitle"
	titleLabel.BackgroundColor3 = config.BackgroundColor or window.bgColor
	titleLabel.BorderColor3 = config.BorderColor or window.accentColor
	titleLabel.BorderSizePixel = config.BorderSize or 3
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Font = config.TitleFont or Enum.Font.SourceSansBold
	titleLabel.FontSize = Enum.FontSize.Size14
	titleLabel.Text = name
	titleLabel.TextColor3 = config.TextColor or window.textColor
	titleLabel.Parent = sectionFrame
	
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "Content"
	contentFrame.BackgroundTransparency = 1
	contentFrame.Size = UDim2.new(1, 0, 1, -30)
	contentFrame.Position = UDim2.new(0, 0, 0, 30)
	contentFrame.Parent = sectionFrame
	
	local contentList = Instance.new("UIListLayout")
	contentList.Padding = UDim.new(0, 3)
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Parent = contentFrame
	
	local section = {
		name = name,
		frame = sectionFrame,
		contentFrame = contentFrame,
		elements = {},
		elementCount = 0,
		window = window,
		tab = self
	}
	
	setmetatable(section, {__index = Section})
	table.insert(self.sections, section)
	return section
end

-- Section Object
local Section = {}
Section.__index = Section

function Section:AddButton(name, config)
	config = config or {}
	local elementIndex = self.elementCount
	local window = self.window
	
	local button = Instance.new("TextButton")
	button.Name = name
	button.BackgroundColor3 = config.BackgroundColor or window.bgColor
	button.BorderColor3 = config.BorderColor or window.accentColor
	button.BorderSizePixel = config.BorderSize or 3
	button.Size = UDim2.new(1, 0, 0, 30)
	button.Font = config.Font or Enum.Font.SourceSans
	button.FontSize = config.FontSize or Enum.FontSize.Size14
	button.Text = name
	button.TextColor3 = config.TextColor or window.textColor
	button.LayoutOrder = elementIndex
	button.Parent = self.contentFrame
	
	if config.OnClick then
		button.MouseButton1Down:Connect(config.OnClick)
	end
	
	self.elementCount = elementIndex + 1
	return button
end

function Section:AddLabel(text, config)
	config = config or {}
	local elementIndex = self.elementCount
	local window = self.window
	
	local label = Instance.new("TextLabel")
	label.Name = text
	label.BackgroundColor3 = config.BackgroundColor or window.bgColor
	label.BorderColor3 = config.BorderColor or window.bgColor
	label.BorderSizePixel = config.BorderSize or 0
	label.Size = UDim2.new(1, 0, 0, 30)
	label.Font = config.Font or Enum.Font.SourceSans
	label.FontSize = config.FontSize or Enum.FontSize.Size14
	label.Text = text
	label.TextColor3 = config.TextColor or window.textColor
	label.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.LayoutOrder = elementIndex
	label.Parent = self.contentFrame
	
	self.elementCount = elementIndex + 1
	return label
end

function Section:AddToggle(name, config)
	config = config or {}
	local elementIndex = self.elementCount
	local window = self.window
	
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Name = name
	toggleFrame.BackgroundColor3 = config.BackgroundColor or window.bgColor
	toggleFrame.BorderColor3 = config.BorderColor or window.accentColor
	toggleFrame.BorderSizePixel = config.BorderSize or 3
	toggleFrame.Size = UDim2.new(1, 0, 0, 30)
	toggleFrame.LayoutOrder = elementIndex
	toggleFrame.Parent = self.contentFrame
	
	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = config.BackgroundColor or window.bgColor
	label.BorderSizePixel = 0
	label.Position = UDim2.new(0, 5, 0, 0)
	label.Size = UDim2.new(0.7, 0, 1, 0)
	label.Font = Enum.Font.SourceSans
	label.FontSize = Enum.FontSize.Size14
	label.Text = name
	label.TextColor3 = config.TextColor or window.textColor
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = toggleFrame
	
	local checkBox = Instance.new("TextButton")
	checkBox.BackgroundColor3 = config.CheckBoxColor or window.accentColor
	checkBox.BorderColor3 = config.BorderColor or window.accentColor
	checkBox.BorderSizePixel = 1
	checkBox.Position = UDim2.new(0.75, 0, 0.15, 0)
	checkBox.Size = UDim2.new(0.2, 0, 0.7, 0)
	checkBox.Font = Enum.Font.SourceSans
	checkBox.FontSize = Enum.FontSize.Size12
	checkBox.Text = config.Default and "ON" or "OFF"
	checkBox.TextColor3 = window.textColor
	checkBox.Parent = toggleFrame
	
	local state = config.Default or false
	checkBox.MouseButton1Down:Connect(function()
		state = not state
		checkBox.Text = state and "ON" or "OFF"
		if config.OnChange then
			config.OnChange(state)
		end
	end)
	
	self.elementCount = elementIndex + 1
	
	return {frame = toggleFrame, checkBox = checkBox, getValue = function() return state end}
end

function Section:AddTextInput(placeholder, config)
	config = config or {}
	local elementIndex = self.elementCount
	local window = self.window
	
	local inputFrame = Instance.new("Frame")
	inputFrame.Name = placeholder
	inputFrame.BackgroundColor3 = config.BackgroundColor or window.bgColor
	inputFrame.BorderColor3 = config.BorderColor or window.accentColor
	inputFrame.BorderSizePixel = config.BorderSize or 3
	inputFrame.Size = UDim2.new(1, 0, 0, 30)
	inputFrame.LayoutOrder = elementIndex
	inputFrame.Parent = self.contentFrame
	
	local input = Instance.new("TextBox")
	input.BackgroundColor3 = window.bgColor
	input.BorderColor3 = window.accentColor
	input.BorderSizePixel = 1
	input.Position = UDim2.new(0, 5, 0.1, 0)
	input.Size = UDim2.new(1, -10, 0.8, 0)
	input.Font = Enum.Font.SourceSans
	input.FontSize = Enum.FontSize.Size12
	input.PlaceholderText = placeholder
	input.PlaceholderColor3 = window.textColor
	input.Text = ""
	input.TextColor3 = window.textColor
	input.Parent = inputFrame
	
	self.elementCount = elementIndex + 1
	
	return {frame = inputFrame, input = input, getText = function() return input.Text end}
end

-- Library Functions
function c00lgui.Window(config)
	return Window.new(config)
end

c00lgui.new = Window.new

return c00lgui
