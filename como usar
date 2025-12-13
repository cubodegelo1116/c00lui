# c00lUI - Simple Roblox UI Library

A lightweight, no-dependency UI library for Roblox executors that creates draggable windows with tabs, sections, buttons, labels, and textboxes directly in `CoreGui`.

GitHub: https://github.com/cubodegelo1116/c00lui  
Raw file: https://raw.githubusercontent.com/cubodegelo1116/c00lui/main/c00lui.lua

## Installation

```lua
local c00lui = loadstring(game:HttpGet("https://raw.githubusercontent.com/cubodegelo1116/c00lui/main/c00lui.lua"))()
Creating a Window
Lualocal ui = c00lui:Window({
    Title = "My Executor",                    -- Window title (default: "c00lgui")
    AccentColor = Color3.fromRGB(0, 170, 255) -- Accent/border color (default: red)
})
The window is draggable and can be toggled with the keybind shown in the top-right corner (default: RightControl).
Adding Pages (Tabs)
Lualocal mainPage   = ui:AddPage()  -- First page (visible by default)
local settingsPage = ui:AddPage() -- Additional pages
Switch pages using the < and > buttons at the top.
Adding Sections
Sections are automatically placed in two columns.
Lualocal executorSection = mainPage:AddSection("Script Executor")
local infoSection     = mainPage:AddSection("Information")
Section Functions
AddButton(text: string, callback: function)
Adds a button (two columns layout).
LuaexecutorSection:AddButton("Clear", function()
    -- your code
end)
AddLabel(text: string)
Adds a full-width label.
LuainfoSection:AddLabel("Super Natural Executor v1.0")
infoSection:AddLabel("Made with c00lUI")
AddSmallTextbox(placeholder: string, callback: function(text))
Adds a half-width textbox (two per row). Callback fires on Enter or focus loss.
LuaexecutorSection:AddSmallTextbox("Target player...", function(name)
    print("Target:", name)
end)
AddBigTextbox(placeholder: string, callback: function(text))
Adds a full-width multiline textbox - perfect for script execution.
LuaexecutorSection:AddBigTextbox("Paste your script here...", function(script)
    if script ~= "" then
        loadstring(script)()
    end
end)
executorSection:AddButton("Execute", function()
-- Optional extra logic before execution
end)
Full Example
Lualocal c00lui = loadstring(game:HttpGet("https://raw.githubusercontent.com/cubodegelo1116/c00lui/main/c00lui.lua"))()

local window = c00lui:Window({
    Title = "Super Natural",
    AccentColor = Color3.fromRGB(0, 255, 255)
})

local page = window:AddPage()

local exec = page:AddSection("Executor")
exec:AddBigTextbox("Paste script here...", function(code)
    if code ~= "" then loadstring(code)() end
end)
exec:AddButton("Execute", function() end) -- placeholder or additional logic

local info = page:AddSection("Info")
info:AddLabel("Super Natural Executor")
info:AddLabel("UI Library: c00lUI")
info:AddLabel("Enjoy!")
That's it! The library is intentionally minimal, fast, and works on every modern executor (including your Super Natural made in Visual Studio).
Need toggles, sliders, color pickers or better drag? Just ask - happy to help extend it.
