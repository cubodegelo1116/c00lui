--[[
	c00lgui Library v2
	Uma poderosa biblioteca para criar GUIs customizáveis com o visual c00lgui
	
	Usage:
	local c00l = loadstring(game:HttpGet("https://raw.githubusercontent.com/..."))()
	local window = c00l.Window({
		Title = "Meu GUI",
		BackgroundColor = Color3.fromRGB(0, 0, 0),
		AccentColor = Color3.fromRGB(255, 0, 0)
	})
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
	
	self.pages = {}
	self.currentPage = 1
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
	
	-- Main Frame (a GUI em si)
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
	
	-- Tabs Container
	self.tabsContainer = Instance.new("Frame")
	self.tabsContainer.Name = "TabsContainer"
	self.tabsContainer.BackgroundColor3 = self.bgColor
	self.tabsContainer.BorderColor3 = self.accentColor
	self.tabsContainer.BorderSizePixel = 3
	self.tabsContainer.Position = UDim2.new(0, 0, 0, 40)
	self.tabsContainer.Size = UDim2.new(1, 0, 0, 40)
	self.tabsContainer.ClipsDescendants = false
	self.tabsContainer.Parent = self.mainFrame
	
	-- Left Button (<)
	local leftButton = Instance.new("TextButton")
	leftButton.Name = "<"
	leftButton.BackgroundColor3 = self.bgColor
	leftButton.BorderColor3 = self.accentColor
	leftButton.BorderSizePixel = 3
	leftButton.Position = UDim2.new(0, 0, 0, 0)
	leftButton.Size = UDim2.new(0.5, -2, 1, 0)
	leftButton.Font = Enum.Font.SourceSans
	leftButton.FontSize = Enum.FontSize.Size48
	leftButton.Text = "<"
	leftButton.TextColor3 = self.textColor
	leftButton.Parent = self.tabsContainer
	leftButton.MouseButton1Down:Connect(function()
		self:PreviousPage()
	end)
	self.leftButton = leftButton
	
	-- Right Button (>)
	local rightButton = Instance.new("TextButton")
	rightButton.Name = ">"
	rightButton.BackgroundColor3 = self.bgColor
	rightButton.BorderColor3 = self.accentColor
	rightButton.BorderSizePixel = 3
	rightButton.Position = UDim2.new(0.5, 2, 0, 0)
	rightButton.Size = UDim2.new(0.5, -2, 1, 0)
	rightButton.Font = Enum.Font.SourceSans
	rightButton.FontSize = Enum.FontSize.Size48
	rightButton.Text = ">"
	rightButton.TextColor3 = self.textColor
	rightButton.Parent = self.tabsContainer
	rightButton.MouseButton1Down:Connect(function()
		self:NextPage()
	end)
	self.rightButton = rightButton
	
	-- Pages Container
	self.pagesContainer = Instance.new("Frame")
	self.pagesContainer.Name = "Pages"
	self.pagesContainer.BackgroundColor3 = self.bgColor
	self.pagesContainer.BorderColor3 = self.accentColor
	self.pagesContainer.BorderSizePixel = 3
	self.pagesContainer.Position = UDim2.new(0, 0, 0, 80)
	self.pagesContainer.Size = UDim2.new(1, 0, 1, -80)
	self.pagesContainer.ClipsDescendants = false
	self.pagesContainer.Parent = self.mainFrame
	
	-- Close/Open Button (FORA da GUI, embaixo) - MUDE A POSIÇÃO AQUI
	self.toggleButton = Instance.new("TextButton")
	self.toggleButton.Name = "Close/Open"
	self.toggleButton.Active = true
	self.toggleButton.AutoButtonColor = true
	self.toggleButton.BackgroundColor3 = self.bgColor
	self.toggleButton.BorderColor3 = self.accentColor
	self.toggleButton.BorderSizePixel = 3
	self.toggleButton.Position = UDim2.new(0, 3, 0.3, 400) -- MUDE AQUI
	self.toggleButton.Size = UDim2.new(0, self.width, 0, 20)
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
	
	local page = {
		name = name,
		frame = pageFrame,
		sections = {},
		window = self
	}
	
	setmetatable(page, {__index = Page})
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
	self.title = title
end

function Window:Destroy()
	self.screenGui:Destroy()
end

-- Page Object
local Page = {}
Page.__index = Page

function Page:AddSection(name, config)
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
	titleLabel.Name = "SectionTitle"
	titleLabel.BackgroundColor3 = config.BackgroundColor or window.bgColor
	titleLabel.BorderColor3 = config.BorderColor or window.accentColor
	titleLabel.BorderSizePixel = config.BorderSize or 3
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Font = config.TitleFont or Enum.Font.SourceSans
	titleLabel.FontSize = config.TitleFontSize or Enum.FontSize.Size14
	titleLabel.Text = name
	titleLabel.TextColor3 = config.TextColor or window.textColor
	titleLabel.Parent = sectionFrame
	
	local section = {
		name = name,
		frame = sectionFrame,
		elements = {},
		elementCount = 0,
		window = window,
		page = self
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
	button.Position = UDim2.new(0, 0, 0, 30 + (elementIndex * 35))
	button.Size = UDim2.new(config.Width or 1, 0, 0, config.Height or 30)
	button.Font = config.Font or Enum.Font.SourceSans
	button.FontSize = config.FontSize or Enum.FontSize.Size14
	button.Text = name
	button.TextColor3 = config.TextColor or window.textColor
	button.Parent = self.frame
	
	if config.OnClick then
		button.MouseButton1Down:Connect(config.OnClick)
	end
	
	table.insert(self.elements, button)
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
	label.Position = UDim2.new(0, 5, 0, 30 + (elementIndex * 35))
	label.Size = UDim2.new(1, -10, 0, config.Height or 30)
	label.Font = config.Font or Enum.Font.SourceSans
	label.FontSize = config.FontSize or Enum.FontSize.Size14
	label.Text = text
	label.TextColor3 = config.TextColor or window.textColor
	label.TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = self.frame
	
	table.insert(self.elements, label)
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
	toggleFrame.Position = UDim2.new(0, 0, 0, 30 + (elementIndex * 35))
	toggleFrame.Size = UDim2.new(1, 0, 0, 30)
	toggleFrame.Parent = self.frame
	
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
	checkBox.Position = UDim2.new(0.75, 0, 0.2, 0)
	checkBox.Size = UDim2.new(0.2, 0, 0.6, 0)
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
	
	table.insert(self.elements, toggleFrame)
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
	inputFrame.Position = UDim2.new(0, 0, 0, 30 + (elementIndex * 35))
	inputFrame.Size = UDim2.new(1, 0, 0, 30)
	inputFrame.Parent = self.frame
	
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
	
	table.insert(self.elements, inputFrame)
	self.elementCount = elementIndex + 1
	
	return {frame = inputFrame, input = input, getText = function() return input.Text end}
end

-- Library Functions
function c00lgui.Window(config)
	return Window.new(config)
end

c00lgui.new = Window.new

return c00lgui
