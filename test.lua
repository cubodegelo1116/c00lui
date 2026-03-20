--[=[
	GUI Library v3.0 - COM SIDE TABS ANIMADAS (ESTILO C00GUI)
	
	Sistema de abas laterais que deslizam com Tween suave
	Similar ao c00gui v3rx mas com API modular
	
	Estrutura:
	- Abas na esquerda (< e >)
	- Páginas que deslizam com Tween
	- Botões, labels, toggles, sliders, etc
]=]

local Library = {}
Library.__index = Library

local CONFIG = {
	COLORS = {
		BLACK = Color3.new(0, 0, 0),
		RED = Color3.new(1, 0, 0),
		WHITE = Color3.new(1, 1, 1),
		DARK_GRAY = Color3.fromRGB(30, 30, 30),
	},
	FONT = "SourceSans",
	WINDOW_WIDTH = 300,
	WINDOW_HEIGHT = 400,
	BUTTON_HEIGHT = 30,
	ELEMENT_SPACING = 5,
	TWEEN_DURATION = 0.3,
	TWEEN_STYLE = Enum.EasingStyle.Quad,
	TWEEN_DIRECTION = Enum.EasingDirection.InOut,
}

-- ====== WINDOW CLASS ======
local Window = {}
Window.__index = Window

function Window:new(title)
	local self = setmetatable({}, Window)
	
	self.Title = title
	self.Tabs = {}
	self.CurrentTabIndex = 0
	self.TweenService = game:GetService("TweenService")
	self.RunningTween = nil
	
	self:_createUI()
	
	return self
end

function Window:_createUI()
	-- ScreenGui
	self.ScreenGui = Instance.new("ScreenGui", game.CoreGui)
	self.ScreenGui.Name = "C00lGuiLibrary"
	self.ScreenGui.ResetOnSpawn = false
	
	-- MainFrame
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "MainFrame"
	self.MainFrame.Parent = self.ScreenGui
	self.MainFrame.BackgroundColor3 = CONFIG.COLORS.BLACK
	self.MainFrame.BorderColor3 = CONFIG.COLORS.RED
	self.MainFrame.BorderSizePixel = 3
	self.MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
	self.MainFrame.Size = UDim2.new(0, CONFIG.WINDOW_WIDTH, 0, CONFIG.WINDOW_HEIGHT)
	self.MainFrame.Active = true
	self.MainFrame.Draggable = true
	
	-- TitleBar
	local titleBar = Instance.new("TextLabel")
	titleBar.Parent = self.MainFrame
	titleBar.BackgroundColor3 = CONFIG.COLORS.BLACK
	titleBar.BorderColor3 = CONFIG.COLORS.RED
	titleBar.BorderSizePixel = 3
	titleBar.Position = UDim2.new(0, 0, 0, 0)
	titleBar.Size = UDim2.new(1, 0, 0, 40)
	titleBar.Font = CONFIG.FONT
	titleBar.FontSize = Enum.FontSize.Size18
	titleBar.Text = self.Title
	titleBar.TextColor3 = CONFIG.COLORS.WHITE
	titleBar.ZIndex = 5
	
	-- PagesFrame (contém todas as páginas sobrepostas)
	self.PagesFrame = Instance.new("Frame")
	self.PagesFrame.Name = "PagesFrame"
	self.PagesFrame.Parent = self.MainFrame
	self.PagesFrame.BackgroundColor3 = CONFIG.COLORS.BLACK
	self.PagesFrame.BorderColor3 = CONFIG.COLORS.RED
	self.PagesFrame.BorderSizePixel = 3
	self.PagesFrame.Position = UDim2.new(0, 0, 0, 40)
	self.PagesFrame.Size = UDim2.new(1, 0, 1, -80)
	self.PagesFrame.ZIndex = 2
	
	-- SettingsFrame (slider lateral - inicialmente oculto)
	self.SettingsFrame = Instance.new("Frame")
	self.SettingsFrame.Name = "SettingsFrame"
	self.SettingsFrame.Parent = self.MainFrame
	self.SettingsFrame.BackgroundColor3 = CONFIG.COLORS.BLACK
	self.SettingsFrame.BorderColor3 = CONFIG.COLORS.RED
	self.SettingsFrame.BorderSizePixel = 3
	self.SettingsFrame.Position = UDim2.new(1, 3, 0, 0)  -- Começa fora da tela
	self.SettingsFrame.Size = UDim2.new(1, 0, 1, 0)
	self.SettingsFrame.ZIndex = 1
	
	-- ====== BOTÕES DE NAVEGAÇÃO ======
	-- Botão ESQUERDA (<)
	self.LeftButton = Instance.new("TextButton")
	self.LeftButton.Parent = self.MainFrame
	self.LeftButton.Name = "<"
	self.LeftButton.BackgroundColor3 = CONFIG.COLORS.BLACK
	self.LeftButton.BorderColor3 = CONFIG.COLORS.RED
	self.LeftButton.BorderSizePixel = 3
	self.LeftButton.Position = UDim2.new(0, 0, 0, 40)
	self.LeftButton.Size = UDim2.new(0.5, -3, 0, 40)
	self.LeftButton.Font = CONFIG.FONT
	self.LeftButton.FontSize = Enum.FontSize.Size48
	self.LeftButton.Text = "<"
	self.LeftButton.TextColor3 = CONFIG.COLORS.WHITE
	self.LeftButton.ZIndex = 4
	
	-- Botão DIREITA (>)
	self.RightButton = Instance.new("TextButton")
	self.RightButton.Parent = self.MainFrame
	self.RightButton.Name = ">"
	self.RightButton.BackgroundColor3 = CONFIG.COLORS.BLACK
	self.RightButton.BorderColor3 = CONFIG.COLORS.RED
	self.RightButton.BorderSizePixel = 3
	self.RightButton.Position = UDim2.new(0.5, 3, 0, 40)
	self.RightButton.Size = UDim2.new(0.5, -3, 0, 40)
	self.RightButton.Font = CONFIG.FONT
	self.RightButton.FontSize = Enum.FontSize.Size48
	self.RightButton.Text = ">"
	self.RightButton.TextColor3 = CONFIG.COLORS.WHITE
	self.RightButton.ZIndex = 4
	
	-- Botão FECHAR/ABRIR
	self.CloseButton = Instance.new("TextButton")
	self.CloseButton.Parent = self.ScreenGui
	self.CloseButton.Name = "CloseButton"
	self.CloseButton.BackgroundColor3 = CONFIG.COLORS.BLACK
	self.CloseButton.BorderColor3 = CONFIG.COLORS.RED
	self.CloseButton.BorderSizePixel = 3
	self.CloseButton.Position = UDim2.new(0.5, -150, 0.5, 200)
	self.CloseButton.Size = UDim2.new(0, CONFIG.WINDOW_WIDTH, 0, 20)
	self.CloseButton.Font = CONFIG.FONT
	self.CloseButton.FontSize = Enum.FontSize.Size18
	self.CloseButton.Text = "Fechar"
	self.CloseButton.TextColor3 = CONFIG.COLORS.WHITE
	self.CloseButton.ZIndex = 3
	
	local isClosed = false
	self.CloseButton.MouseButton1Down:Connect(function()
		isClosed = not isClosed
		self.MainFrame.Visible = not isClosed
		self.CloseButton.Text = isClosed and "Abrir" or "Fechar"
	end)
	
	-- ====== CONEXÕES DOS BOTÕES ======
	self.LeftButton.MouseButton1Down:Connect(function()
		self:NavigatePrevious()
	end)
	
	self.RightButton.MouseButton1Down:Connect(function()
		self:NavigateNext()
	end)
end

function Window:AddTab(tabName)
	local tabIndex = #self.Tabs + 1
	
	-- Criar página para esse tab
	local page = Instance.new("Frame")
	page.Name = "Page" .. tabIndex
	page.Parent = self.PagesFrame
	page.BackgroundColor3 = CONFIG.COLORS.BLACK
	page.BorderColor3 = CONFIG.COLORS.RED
	page.BorderSizePixel = 3
	page.Position = UDim2.new(0, 0, 0, 83)  -- Abaixo dos botões
	page.Size = UDim2.new(1, 0, 1, -106)
	page.ZIndex = 2
	page.Visible = (tabIndex == 1)  -- Primeira página visível
	
	-- ScrollFrame para elementos
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Parent = page
	scrollFrame.BackgroundColor3 = CONFIG.COLORS.BLACK
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Position = UDim2.new(0, 0, 0, 0)
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ZIndex = 3
	
	-- UIListLayout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = scrollFrame
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding = UDim.new(0, CONFIG.ELEMENT_SPACING)
	
	scrollFrame.ChildAdded:Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
	
	local tab = {
		Name = tabName,
		Index = tabIndex,
		Page = page,
		ScrollFrame = scrollFrame,
		ListLayout = listLayout,
		ElementCount = 0,
	}
	
	table.insert(self.Tabs, tab)
	
	if tabIndex == 1 then
		self.CurrentTabIndex = 1
	end
	
	return tab
end

function Window:NavigateNext()
	if self.RunningTween then
		self.RunningTween:Cancel()
	end
	
	local nextIndex = self.CurrentTabIndex + 1
	if nextIndex > #self.Tabs then
		nextIndex = 1
	end
	
	self:SwitchToTab(nextIndex)
end

function Window:NavigatePrevious()
	if self.RunningTween then
		self.RunningTween:Cancel()
	end
	
	local prevIndex = self.CurrentTabIndex - 1
	if prevIndex < 1 then
		prevIndex = #self.Tabs
	end
	
	self:SwitchToTab(prevIndex)
end

function Window:SwitchToTab(tabIndex)
	if tabIndex == self.CurrentTabIndex or tabIndex < 1 or tabIndex > #self.Tabs then
		return
	end
	
	local currentPage = self.Tabs[self.CurrentTabIndex].Page
	local nextPage = self.Tabs[tabIndex].Page
	
	-- Animar a página atual saindo
	local tweenOut = self.TweenService:Create(
		currentPage,
		TweenInfo.new(
			CONFIG.TWEEN_DURATION,
			CONFIG.TWEEN_STYLE,
			CONFIG.TWEEN_DIRECTION
		),
		{Position = UDim2.new(-1, 0, 0, 83)}
	)
	
	-- Animar a próxima página entrando
	local tweenIn = self.TweenService:Create(
		nextPage,
		TweenInfo.new(
			CONFIG.TWEEN_DURATION,
			CONFIG.TWEEN_STYLE,
			CONFIG.TWEEN_DIRECTION
		),
		{Position = UDim2.new(0, 0, 0, 83)}
	)
	
	nextPage.Position = UDim2.new(1, 0, 0, 83)  -- Começa fora da tela à direita
	nextPage.Visible = true
	
	tweenOut:Play()
	tweenIn:Play()
	
	self.RunningTween = tweenIn
	
	tweenIn.Completed:Connect(function()
		currentPage.Visible = false
		currentPage.Position = UDim2.new(0, 0, 0, 83)
		self.CurrentTabIndex = tabIndex
		self.RunningTween = nil
	end)
end

-- ====== MÉTODOS DE ELEMENTO ======

function AddElement(tab, element)
	element.Parent = tab.ScrollFrame
	tab.ElementCount = tab.ElementCount + 1
	return element
end

function Tab:AddButton(text, callback)
	local button = Instance.new("TextButton")
	button.Name = "Button_" .. self.ElementCount + 1
	button.BackgroundColor3 = CONFIG.COLORS.BLACK
	button.BorderColor3 = CONFIG.COLORS.RED
	button.BorderSizePixel = 2
	button.Size = UDim2.new(1, -10, 0, CONFIG.BUTTON_HEIGHT)
	button.Font = CONFIG.FONT
	button.FontSize = Enum.FontSize.Size14
	button.Text = text
	button.TextColor3 = CONFIG.COLORS.WHITE
	button.ZIndex = 3
	
	button.MouseButton1Down:Connect(function()
		if callback then
			pcall(callback)
		end
	end)
	
	button.Parent = self.ScrollFrame
	self.ElementCount = self.ElementCount + 1
	
	return button
end

function Tab:AddLabel(text)
	local label = Instance.new("TextLabel")
	label.Name = "Label_" .. self.ElementCount + 1
	label.BackgroundColor3 = CONFIG.COLORS.BLACK
	label.BorderColor3 = CONFIG.COLORS.RED
	label.BorderSizePixel = 1
	label.Size = UDim2.new(1, -10, 0, 25)
	label.Font = CONFIG.FONT
	label.FontSize = Enum.FontSize.Size12
	label.Text = text
	label.TextColor3 = CONFIG.COLORS.WHITE
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 3
	
	label.Parent = self.ScrollFrame
	self.ElementCount = self.ElementCount + 1
	
	return label
end

function Tab:AddDivider()
	local divider = Instance.new("Frame")
	divider.Name = "Divider_" .. self.ElementCount + 1
	divider.BackgroundColor3 = CONFIG.COLORS.RED
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, -10, 0, 2)
	divider.ZIndex = 3
	
	divider.Parent = self.ScrollFrame
	self.ElementCount = self.ElementCount + 1
	
	return divider
end

function Tab:AddSpacing(height)
	local spacer = Instance.new("Frame")
	spacer.Name = "Spacer_" .. self.ElementCount + 1
	spacer.BackgroundColor3 = CONFIG.COLORS.BLACK
	spacer.BorderSizePixel = 0
	spacer.Size = UDim2.new(1, -10, 0, height or 10)
	spacer.ZIndex = 2
	
	spacer.Parent = self.ScrollFrame
	self.ElementCount = self.ElementCount + 1
	
	return spacer
end

function Tab:AddTextbox(placeholder, callback)
	local textbox = Instance.new("TextBox")
	textbox.Name = "Textbox_" .. self.ElementCount + 1
	textbox.BackgroundColor3 = CONFIG.COLORS.BLACK
	textbox.BorderColor3 = CONFIG.COLORS.RED
	textbox.BorderSizePixel = 2
	textbox.Size = UDim2.new(1, -10, 0, 30)
	textbox.Font = CONFIG.FONT
	textbox.FontSize = Enum.FontSize.Size12
	textbox.PlaceholderText = placeholder or "Digite aqui..."
	textbox.TextColor3 = CONFIG.COLORS.WHITE
	textbox.ZIndex = 3
	
	textbox.FocusLost:Connect(function(enterPressed)
		if enterPressed and callback then
			pcall(function() callback(textbox.Text) end)
		end
	end)
	
	textbox.Parent = self.ScrollFrame
	self.ElementCount = self.ElementCount + 1
	
	return textbox
end

function Tab:AddToggle(text, default, callback)
	local container = Instance.new("Frame")
	container.Name = "Toggle_" .. self.ElementCount + 1
	container.BackgroundColor3 = CONFIG.COLORS.BLACK
	container.BorderColor3 = CONFIG.COLORS.RED
	container.BorderSizePixel = 1
	container.Size = UDim2.new(1, -10, 0, 30)
	container.ZIndex = 3
	
	local label = Instance.new("TextLabel")
	label.Parent = container
	label.BackgroundColor3 = CONFIG.COLORS.BLACK
	label.BorderSizePixel = 0
	label.Position = UDim2.new(0, 5, 0, 5)
	label.Size = UDim2.new(0.7, 0, 0, 20)
	label.Font = CONFIG.FONT
	label.FontSize = Enum.FontSize.Size12
	label.Text = text
	label.TextColor3 = CONFIG.COLORS.WHITE
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 4
	
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Parent = container
	toggleButton.BackgroundColor3 = CONFIG.COLORS.BLACK
	toggleButton.BorderColor3 = CONFIG.COLORS.RED
	toggleButton.BorderSizePixel = 2
	toggleButton.Position = UDim2.new(0.7, 5, 0.25, 0)
	toggleButton.Size = UDim2.new(0.25, 0, 0.5, 0)
	toggleButton.Font = CONFIG.FONT
	toggleButton.FontSize = Enum.FontSize.Size10
	toggleButton.ZIndex = 4
	
	local toggled = default or false
	toggleButton.Text = toggled and "ON" or "OFF"
	toggleButton.TextColor3 = toggled and CONFIG.COLORS.WHITE or CONFIG.COLORS.DARK_GRAY
	
	toggleButton.MouseButton1Down:Connect(function()
		toggled = not toggled
		toggleButton.Text = toggled and "ON" or "OFF"
		toggleButton.TextColor3 = toggled and CONFIG.COLORS.WHITE or CONFIG.COLORS.DARK_GRAY
		
		if callback then
			pcall(function() callback(toggled) end)
		end
	end)
	
	container.Parent = self.ScrollFrame
	self.ElementCount = self.ElementCount + 1
	
	return {
		Container = container,
		GetValue = function() return toggled end,
		SetValue = function(val)
			toggled = val
			toggleButton.Text = toggled and "ON" or "OFF"
			toggleButton.TextColor3 = toggled and CONFIG.COLORS.WHITE or CONFIG.COLORS.DARK_GRAY
		end
	}
end

-- ====== LIBRARY MAIN ======

function Library:CreateWindow(title)
	return Window:new(title)
end

return Library
