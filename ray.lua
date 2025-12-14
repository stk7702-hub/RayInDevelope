local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/stk7702-hub/Uilibrary/refs/heads/main/library.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local customTheme = {
    Accent = Color3.fromRGB(255, 255, 255),
    Background = Color3.fromRGB(0, 0, 0),
    Header = Color3.fromRGB(0, 0, 0),
    Panel = Color3.fromRGB(10, 10, 10),
    Field = Color3.fromRGB(20, 20, 20),
    Stroke = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(255, 255, 255),
    Warning = Color3.fromRGB(255, 160, 92),
    Shadow = Color3.fromRGB(0, 0, 0),
    SliderAccent = Color3.fromRGB(255, 255, 255),
    ToggleAccent = Color3.fromRGB(255, 255, 255),
    TabSelected = Color3.fromRGB(255, 255, 255),
    TabUnselected = Color3.fromRGB(75, 75, 75),
    ProfileStroke = Color3.fromRGB(255, 255, 255),
	LogoText = Color3.fromRGB(229, 229, 229),
	UsernameText = Color3.fromRGB(255, 255, 255),
}

local Window = Fatality.new({
	Name = "RAY",
	Keybind = Enum.KeyCode.Insert,
	Scale = UDim2.new(0, 750, 0, 500),
	Expire = "Never",
	SidebarWidth = 200,
	TabHeight = 40,
	HeaderHeight = 50,
	BottomHeight = 30,
	Theme = customTheme,
})

local Legit = Window:AddMenu({
	Name = "Legit",
	Icon = "lucide-mouse",
	AutoFill = false
})

local Rage = Window:AddMenu({
	Name = "Rage",
	Icon = "lucide-skull",
	AutoFill = false
})

local Visuals = Window:AddMenu({
	Name = "Visuals",
	Icon = "eye",
	AutoFill = false
})

local Misc = Window:AddMenu({
	Name = "Misc",
	Icon = "package",
	AutoFill = false
})

local PlayersTab = Window:AddMenu({
	Name = "Players",
	Icon = "users",
	AutoFill = false
})

local Settings = Window:AddMenu({
	Name = "Settings",
	Icon = "settings",
	AutoFill = false
})

local flyEnabled = false
local flySpeed = 50

local function startFly()
	-- Заглушка
end

local function stopFly()
	-- Заглушка
end

local walkSpeedEnabled = false
local jumpPowerEnabled = false
local customWalkSpeed = 16
local customJumpPower = 50
local walkSpeedConnection = nil

local function updateCharacterStats()
	local character = LocalPlayer.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	humanoid.WalkSpeed = walkSpeedEnabled and customWalkSpeed or 16
	humanoid.JumpPower = jumpPowerEnabled and customJumpPower or 50
end

local Movement = Misc:AddSection({
	Name = "Movement",
	Side = "left",
	ShowTitle = true,
	Height = 0
})

local FlySpeedSlider = Movement:AddSlider({
	Name = "Fly Speed",
	Type = "",
	Default = 50,
	Min = 0,
	Max = 100,
	Round = 0,
	Callback = function(value)
		flySpeed = value
	end,
	Flag = "FlySpeed"
})

FlySpeedSlider:SetVisible(false)

local FlyToggle = Movement:AddToggle({
	Name = "Fly",
	Default = false,
	Option = true,
	Callback = function(enabled)
		flyEnabled = enabled
		if enabled then
			startFly()
		else
			stopFly()
		end
		FlySpeedSlider:SetVisible(enabled)
	end,
	Flag = "FlyEnabled"
})

if FlyToggle.Option then
	FlyToggle.Option:AddKeybind({
		Name = "Keybind",
		Default = nil,
		Callback = function(key) end,
		Flag = "FlyKeybind"
	})
end

local Human = Misc:AddSection({
	Name = "Human",
	Side = "left",
	ShowTitle = true,
	Height = 0
})

local WalkSpeedSlider = Human:AddSlider({
	Name = "Speed",
	Type = "",
	Default = 16,
	Min = 16,
	Max = 200,
	Round = 0,
	Callback = function(value)
		customWalkSpeed = value
		if walkSpeedEnabled then updateCharacterStats() end
	end,
	Flag = "WalkSpeedValue"
})

WalkSpeedSlider:SetVisible(false)

local WalkSpeedToggle = Human:AddToggle({
	Name = "WalkSpeed",
	Default = false,
	Option = true,
	Callback = function(enabled)
		walkSpeedEnabled = enabled
		updateCharacterStats()
		WalkSpeedSlider:SetVisible(enabled)
		
		if enabled then
			if walkSpeedConnection then
				walkSpeedConnection:Disconnect()
			end
			
			walkSpeedConnection = RunService.RenderStepped:Connect(function()
				local character = LocalPlayer.Character
				if not character then return end
				
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if not humanoid then return end
				
				if walkSpeedEnabled and humanoid.WalkSpeed ~= customWalkSpeed then
					humanoid.WalkSpeed = customWalkSpeed
				end
			end)
		else
			if walkSpeedConnection then
				walkSpeedConnection:Disconnect()
				walkSpeedConnection = nil
			end
		end
	end,
	Flag = "WalkSpeedEnabled"
})

if WalkSpeedToggle.Option then
	WalkSpeedToggle.Option:AddKeybind({
		Name = "Keybind",
		Default = nil,
		Callback = function(key) end,
		Flag = "WalkSpeedKeybind"
	})
end

local JumpPowerSlider = Human:AddSlider({
	Name = "Power",
	Type = "",
	Default = 50,
	Min = 50,
	Max = 200,
	Round = 0,
	Callback = function(value)
		customJumpPower = value
		if jumpPowerEnabled then updateCharacterStats() end
	end,
	Flag = "JumpPowerValue"
})

JumpPowerSlider:SetVisible(false)

local JumpPowerToggle = Human:AddToggle({
	Name = "JumpPower",
	Default = false,
	Option = true,
	Callback = function(enabled)
		jumpPowerEnabled = enabled
		updateCharacterStats()
		JumpPowerSlider:SetVisible(enabled)
	end,
	Flag = "JumpPowerEnabled"
})

if JumpPowerToggle.Option then
	JumpPowerToggle.Option:AddKeybind({
		Name = "Keybind",
		Default = nil,
		Callback = function(key) end,
		Flag = "JumpPowerKeybind"
	})
end

local UI = Settings:AddSection({
	Name = "UI",
	Side = "left",
	ShowTitle = true,
	Height = 0
})

local ToggleKeybind = UI:AddKeybind({
	Name = "Toggle Menu",
	Default = Enum.KeyCode.Insert,
	Option = false,
	Flag = "ToggleMenu",
	Callback = function(key)
		if typeof(key) == "EnumItem" then
			Window:SetToggleKeybind(key)
		elseif typeof(key) == "string" then
			pcall(function()
				Window:SetToggleKeybind(Enum.KeyCode[key])
			end)
		end
	end
})

local MainColor = UI:AddColorPicker({
	Name = "Background Color",
	Default = customTheme.Background,
	Callback = function(color, transparency)
		Window:SetTheme({ Background = color, Panel = color })
	end,
	Flag = "MainColor"
})

local AccentColor = UI:AddColorPicker({
	Name = "Accent Color",
	Default = customTheme.Accent,
	Callback = function(color, transparency)
		Window:SetTheme({
			Accent = color,
			SliderAccent = color,
			ToggleAccent = color,
			TabSelected = color,
			ProfileStroke = color
		})
	end,
	Flag = "AccentColor"
})

local SliderColor = UI:AddColorPicker({
	Name = "Slider Color",
	Default = customTheme.SliderAccent,
	Callback = function(color)
		Window:SetTheme({ SliderAccent = color })
	end,
	Flag = "SliderColor"
})

local ToggleColor = UI:AddColorPicker({
	Name = "Toggle Color",
	Default = customTheme.ToggleAccent,
	Callback = function(color)
		Window:SetTheme({ ToggleAccent = color })
	end,
	Flag = "ToggleColorPicker"
})

local TabSelectedColor = UI:AddColorPicker({
	Name = "Tab Selected",
	Default = customTheme.TabSelected,
	Callback = function(color)
		Window:SetTheme({ TabSelected = color })
	end,
	Flag = "TabSelectedColor"
})

local TabUnselectedColor = UI:AddColorPicker({
	Name = "Tab Unselected",
	Default = customTheme.TabUnselected,
	Callback = function(color)
		Window:SetTheme({ TabUnselected = color })
	end,
	Flag = "TabUnselectedColor"
})

local TextColor = UI:AddColorPicker({
	Name = "Text Color",
	Default = customTheme.Text,
	Callback = function(color)
		Window:SetTheme({ Text = color })
	end,
	Flag = "TextColor"
})

local HeaderColor = UI:AddColorPicker({
	Name = "Header Color",
	Default = customTheme.Header,
	Callback = function(color)
		Window:SetTheme({ Header = color })
	end,
	Flag = "HeaderColor"
})

local PanelColor = UI:AddColorPicker({
	Name = "Panel Color",
	Default = customTheme.Panel,
	Callback = function(color)
		Window:SetTheme({ Panel = color })
	end,
	Flag = "PanelColor"
})

local FieldColor = UI:AddColorPicker({
	Name = "Field Color",
	Default = customTheme.Field,
	Callback = function(color)
		Window:SetTheme({ Field = color })
	end,
	Flag = "FieldColor"
})

local StrokeColor = UI:AddColorPicker({
	Name = "Stroke Color",
	Default = customTheme.Stroke,
	Callback = function(color)
		Window:SetTheme({ Stroke = color })
	end,
	Flag = "StrokeColor"
})

local TextDimColor = UI:AddColorPicker({
	Name = "Text Dim Color",
	Default = customTheme.TextDim,
	Callback = function(color)
		Window:SetTheme({ TextDim = color })
	end,
	Flag = "TextDimColor"
})

local WarningColor = UI:AddColorPicker({
	Name = "Warning Color",
	Default = customTheme.Warning,
	Callback = function(color)
		Window:SetTheme({ Warning = color })
	end,
	Flag = "WarningColor"
})

local ShadowColor = UI:AddColorPicker({
	Name = "Shadow Color",
	Default = customTheme.Shadow,
	Callback = function(color)
		Window:SetTheme({ Shadow = color })
	end,
	Flag = "ShadowColor"
})

local ProfileStrokeColor = UI:AddColorPicker({
	Name = "Profile Stroke Color",
	Default = customTheme.ProfileStroke,
	Callback = function(color)
		Window:SetTheme({ ProfileStroke = color })
	end,
	Flag = "ProfileStrokeColor"
})

local LogoTextColor = UI:AddColorPicker({
	Name = "Logo Text Color",
	Default = customTheme.LogoText,
	Callback = function(color)
		Window:SetTheme({ LogoText = color })
	end,
	Flag = "LogoTextColor"
})

local UsernameTextColor = UI:AddColorPicker({
	Name = "Username Text Color",
	Default = customTheme.UsernameText,
	Callback = function(color)
		Window:SetTheme({ UsernameText = color })
	end,
	Flag = "UsernameTextColor"
})

LocalPlayer.CharacterAdded:Connect(function(character)
	if flyEnabled then
		stopFly()
		task.wait(0.5)
		startFly()
	end
	
	task.wait(0.1)
	updateCharacterStats()
end)

task.spawn(function()
	task.wait(0.5)
	updateCharacterStats()
end)

print("RAY UI Loaded! Press Insert to toggle menu")
