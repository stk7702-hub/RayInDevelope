local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/XQwart/UILibTest/refs/heads/main/test.lua"))()

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

local movementKeys = {w = false, a = false, s = false, d = false}

local flyEnabled = false
local flySpeed = 0
local flyCore = nil
local flyBodyPosition = nil
local flyBodyGyro = nil
local flyConnection = nil
local flyActive = false

local cframeSpeedEnabled = false
local cframeSpeedValue = 0
local cframeSpeedCore = nil
local cframeSpeedBodyPosition = nil
local cframeSpeedBodyGyro = nil
local cframeSpeedConnection = nil
local cframeSpeedActive = false

local walkSpeedEnabled = false
local jumpPowerEnabled = false
local customWalkSpeed = 16
local customJumpPower = 50
local walkSpeedConnection = nil
local jumpPowerConnection = nil

local isResetting = false

local FlyToggle, FlySpeedSlider, CFrameSpeedToggle, CFrameSpeedSlider

-- Уменьшенные скорости
local FLY_BASE_SPEED = 1
local FLY_MAX_MULTIPLIER = 2
local CFRAME_MIN_SPEED = 0.3
local CFRAME_MAX_SPEED = 1.5

-- Fun section variables
local spin360Enabled = false
local spin360Connection = nil
local spin360Speed = 25

local fellEnabled = false
local fellThread = nil

-- Character section variables
local noclipEnabled = false
local noclipConnection = nil

local antiflingEnabled = false
local antiflingConnection = nil

local function calculateFlySpeed(sliderValue)
	return FLY_BASE_SPEED * (1 + (sliderValue / 100) * (FLY_MAX_MULTIPLIER - 1))
end

local function calculateCFrameSpeed(sliderValue)
	return CFRAME_MIN_SPEED + (sliderValue / 100) * (CFRAME_MAX_SPEED - CFRAME_MIN_SPEED)
end

local function cleanupFly()
	flyActive = false
	
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	
	if flyBodyPosition then
		flyBodyPosition:Destroy()
		flyBodyPosition = nil
	end
	
	if flyBodyGyro then
		flyBodyGyro:Destroy()
		flyBodyGyro = nil
	end
	
	if flyCore then
		flyCore:Destroy()
		flyCore = nil
	end
	
	if workspace:FindFirstChild("FlyCore") then
		workspace.FlyCore:Destroy()
	end
	
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end

local function cleanupCFrameSpeed()
	cframeSpeedActive = false
	
	if cframeSpeedConnection then
		cframeSpeedConnection:Disconnect()
		cframeSpeedConnection = nil
	end
	
	if cframeSpeedBodyPosition then
		cframeSpeedBodyPosition:Destroy()
		cframeSpeedBodyPosition = nil
	end
	
	if cframeSpeedBodyGyro then
		cframeSpeedBodyGyro:Destroy()
		cframeSpeedBodyGyro = nil
	end
	
	if cframeSpeedCore then
		cframeSpeedCore:Destroy()
		cframeSpeedCore = nil
	end
	
	if workspace:FindFirstChild("CFrameSpeedCore") then
		workspace.CFrameSpeedCore:Destroy()
	end
end

local function cleanupWalkSpeed()
	if walkSpeedConnection then
		walkSpeedConnection:Disconnect()
		walkSpeedConnection = nil
	end
end

local function cleanupJumpPower()
	if jumpPowerConnection then
		jumpPowerConnection:Disconnect()
		jumpPowerConnection = nil
	end
end

-- Fun section functions
local function start360Spin()
	if spin360Connection then return end
	
	spin360Connection = RunService.RenderStepped:Connect(function(dt)
		if not spin360Enabled then return end
		
		local character = LocalPlayer.Character
		if not character then return end
		
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end
		
		humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, spin360Speed * dt, 0)
	end)
end

local function stop360Spin()
	if spin360Connection then
		spin360Connection:Disconnect()
		spin360Connection = nil
	end
end

-- Fell loop function
local function startFellLoop()
	fellThread = task.spawn(function()
		while fellEnabled do
			local character = LocalPlayer.Character
			if not character then 
				task.wait(0.5)
				continue 
			end
			
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then 
				task.wait(0.5)
				continue 
			end
			
			-- Падаем
			humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			task.wait(1.5)
			
			if not fellEnabled then break end
			
			-- Встаём
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			task.wait(1)
			
			if not fellEnabled then break end
		end
	end)
end

local function stopFellLoop()
	fellEnabled = false
	if fellThread then
		task.cancel(fellThread)
		fellThread = nil
	end
	
	-- Восстанавливаем нормальное состояние
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

-- Character section functions
local function enableNoclip()
	if noclipConnection then return end
	
	noclipConnection = RunService.Stepped:Connect(function()
		local character = LocalPlayer.Character
		if character and character.Parent then
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end)
end

local function disableNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
	
	local character = LocalPlayer.Character
	if character and character.Parent then
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
end

local function enableAntiFling()
	if antiflingConnection then return end
	
	antiflingConnection = RunService.Heartbeat:Connect(function()
		local character = LocalPlayer.Character
		if not character then return end
		
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end
		
		local velocity = humanoidRootPart.AssemblyLinearVelocity
		local maxVelocity = 50
		
		if velocity.Magnitude > maxVelocity then
			humanoidRootPart.AssemblyLinearVelocity = velocity.Unit * maxVelocity
		end
		
		local angularVelocity = humanoidRootPart.AssemblyAngularVelocity
		local maxAngularVelocity = 10
		
		if angularVelocity.Magnitude > maxAngularVelocity then
			humanoidRootPart.AssemblyAngularVelocity = angularVelocity.Unit * maxAngularVelocity
		end
	end)
end

local function disableAntiFling()
	if antiflingConnection then
		antiflingConnection:Disconnect()
		antiflingConnection = nil
	end
end

local function cleanupAll()
	cleanupFly()
	cleanupCFrameSpeed()
	cleanupWalkSpeed()
	cleanupJumpPower()
	stop360Spin()
	stopFellLoop()
	disableNoclip()
	disableAntiFling()
end

local function getCharacterParts()
	local character = LocalPlayer.Character
	if not character then return nil, nil, nil end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil, nil, nil end
	
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("LowerTorso")
	if not rootPart then return nil, nil, nil end
	
	return character, humanoid, rootPart
end

local function createCore(name)
	local character, humanoid, rootPart = getCharacterParts()
	if not character then return nil end
	
	if workspace:FindFirstChild(name) then
		workspace[name]:Destroy()
	end
	
	local core = Instance.new("Part")
	core.Name = name
	core.Size = Vector3.new(0.05, 0.05, 0.05)
	core.Transparency = 1
	core.CanCollide = false
	core.Anchored = false
	core.Parent = workspace
	
	local weld = Instance.new("Weld")
	weld.Part0 = core
	weld.Part1 = rootPart
	weld.C0 = CFrame.new(0, 0, 0)
	weld.Parent = core
	
	return core
end

local function startFly()
	if flyActive then return end
	
	if cframeSpeedActive or cframeSpeedEnabled then
		cleanupCFrameSpeed()
		cframeSpeedEnabled = false
		if CFrameSpeedToggle then
			CFrameSpeedToggle:SetValue(false)
		end
		if CFrameSpeedSlider then
			CFrameSpeedSlider:SetVisible(false)
		end
	end
	
	local character, humanoid, rootPart = getCharacterParts()
	if not character then return end
	
	flyCore = createCore("FlyCore")
	if not flyCore then return end
	
	task.wait()
	
	flyBodyPosition = Instance.new("BodyPosition")
	flyBodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyBodyPosition.Position = flyCore.Position
	flyBodyPosition.D = 100
	flyBodyPosition.P = 10000
	flyBodyPosition.Parent = flyCore
	
	flyBodyGyro = Instance.new("BodyGyro")
	flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	flyBodyGyro.CFrame = flyCore.CFrame
	flyBodyGyro.D = 100
	flyBodyGyro.Parent = flyCore
	
	flyActive = true
	
	flyConnection = RunService.RenderStepped:Connect(function()
		if not flyEnabled or not flyActive then return end
		
		local char, hum, root = getCharacterParts()
		if not char or not flyCore or not flyCore.Parent then
			cleanupFly()
			return
		end
		
		hum.PlatformStand = true
		
		local camera = workspace.CurrentCamera
		local moveDirection = Vector3.new(0, 0, 0)
		
		if movementKeys.w then
			moveDirection = moveDirection + camera.CFrame.LookVector
		end
		if movementKeys.s then
			moveDirection = moveDirection - camera.CFrame.LookVector
		end
		if movementKeys.d then
			moveDirection = moveDirection + camera.CFrame.RightVector
		end
		if movementKeys.a then
			moveDirection = moveDirection - camera.CFrame.RightVector
		end
		
		if moveDirection.Magnitude > 0 then
			moveDirection = moveDirection.Unit
		end
		
		local actualSpeed = calculateFlySpeed(flySpeed)
		
		if flyBodyPosition then
			flyBodyPosition.Position = flyBodyPosition.Position + moveDirection * actualSpeed
		end
		if flyBodyGyro then
			flyBodyGyro.CFrame = camera.CFrame
		end
	end)
end

local function stopFly()
	cleanupFly()
end

local function startCFrameSpeed()
	if cframeSpeedActive then return end
	
	if flyEnabled or flyActive then
		cframeSpeedEnabled = false
		if CFrameSpeedToggle then
			CFrameSpeedToggle:SetValue(false)
		end
		if CFrameSpeedSlider then
			CFrameSpeedSlider:SetVisible(false)
		end
		return
	end
	
	local character, humanoid, rootPart = getCharacterParts()
	if not character then return end
	
	cframeSpeedCore = createCore("CFrameSpeedCore")
	if not cframeSpeedCore then return end
	
	task.wait()
	
	cframeSpeedBodyPosition = Instance.new("BodyPosition")
	cframeSpeedBodyPosition.MaxForce = Vector3.new(math.huge, 0, math.huge)
	cframeSpeedBodyPosition.Position = cframeSpeedCore.Position
	cframeSpeedBodyPosition.D = 100
	cframeSpeedBodyPosition.P = 10000
	cframeSpeedBodyPosition.Parent = cframeSpeedCore
	
	cframeSpeedBodyGyro = Instance.new("BodyGyro")
	cframeSpeedBodyGyro.MaxTorque = Vector3.new(0, 9e9, 0)
	cframeSpeedBodyGyro.CFrame = cframeSpeedCore.CFrame
	cframeSpeedBodyGyro.D = 100
	cframeSpeedBodyGyro.Parent = cframeSpeedCore
	
	cframeSpeedActive = true
	
	cframeSpeedConnection = RunService.RenderStepped:Connect(function()
		if not cframeSpeedEnabled or not cframeSpeedActive then return end
		
		if flyEnabled or flyActive then
			cleanupCFrameSpeed()
			cframeSpeedEnabled = false
			if CFrameSpeedToggle then
				CFrameSpeedToggle:SetValue(false)
			end
			if CFrameSpeedSlider then
				CFrameSpeedSlider:SetVisible(false)
			end
			return
		end
		
		local char, hum, root = getCharacterParts()
		if not char or not cframeSpeedCore or not cframeSpeedCore.Parent then
			cleanupCFrameSpeed()
			return
		end
		
		local camera = workspace.CurrentCamera
		local moveDirection = Vector3.new(0, 0, 0)
		
		local lookVector = camera.CFrame.LookVector
		local rightVector = camera.CFrame.RightVector
		
		lookVector = Vector3.new(lookVector.X, 0, lookVector.Z)
		if lookVector.Magnitude > 0 then
			lookVector = lookVector.Unit
		end
		
		rightVector = Vector3.new(rightVector.X, 0, rightVector.Z)
		if rightVector.Magnitude > 0 then
			rightVector = rightVector.Unit
		end
		
		if movementKeys.w then
			moveDirection = moveDirection + lookVector
		end
		if movementKeys.s then
			moveDirection = moveDirection - lookVector
		end
		if movementKeys.d then
			moveDirection = moveDirection + rightVector
		end
		if movementKeys.a then
			moveDirection = moveDirection - rightVector
		end
		
		if moveDirection.Magnitude > 0 then
			moveDirection = moveDirection.Unit
		end
		
		local actualSpeed = calculateCFrameSpeed(cframeSpeedValue)
		
		if cframeSpeedBodyPosition then
			local newPos = cframeSpeedBodyPosition.Position + moveDirection * actualSpeed
			cframeSpeedBodyPosition.Position = Vector3.new(newPos.X, cframeSpeedCore.Position.Y, newPos.Z)
		end
		
		if cframeSpeedBodyGyro and moveDirection.Magnitude > 0 then
			cframeSpeedBodyGyro.CFrame = CFrame.lookAt(Vector3.new(0, 0, 0), moveDirection)
		end
	end)
end

local function stopCFrameSpeed()
	cleanupCFrameSpeed()
end

local function startWalkSpeedLoop()
	cleanupWalkSpeed()
	
	walkSpeedConnection = RunService.RenderStepped:Connect(function()
		if not walkSpeedEnabled then return end
		
		local character, humanoid = getCharacterParts()
		if not humanoid then return end
		
		if humanoid.WalkSpeed ~= customWalkSpeed then
			humanoid.WalkSpeed = customWalkSpeed
		end
	end)
end

local function startJumpPowerLoop()
	cleanupJumpPower()
	
	jumpPowerConnection = RunService.RenderStepped:Connect(function()
		if not jumpPowerEnabled then return end
		
		local character, humanoid = getCharacterParts()
		if not humanoid then return end
		
		if humanoid.JumpPower ~= customJumpPower then
			humanoid.JumpPower = customJumpPower
		end
	end)
end

local function resetCharacterStats()
	local character, humanoid = getCharacterParts()
	if not humanoid then return end
	
	if not walkSpeedEnabled then
		humanoid.WalkSpeed = 16
	end
	if not jumpPowerEnabled then
		humanoid.JumpPower = 50
	end
end

local function onCharacterAdded(character)
	isResetting = true
	
	cleanupAll()
	
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		isResetting = false
		return
	end
	
	character:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.5)
	
	isResetting = false
	
	if flyEnabled then
		startFly()
	elseif cframeSpeedEnabled then
		startCFrameSpeed()
	end
	
	if walkSpeedEnabled then
		startWalkSpeedLoop()
	end
	
	if jumpPowerEnabled then
		startJumpPowerLoop()
	end
	
	if spin360Enabled then
		start360Spin()
	end
	
	if fellEnabled then
		startFellLoop()
	end
	
	if noclipEnabled then
		enableNoclip()
	end
	
	if antiflingEnabled then
		enableAntiFling()
	end
	
	humanoid.Died:Connect(function()
		cleanupAll()
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.W then
		movementKeys.w = true
	elseif input.KeyCode == Enum.KeyCode.A then
		movementKeys.a = true
	elseif input.KeyCode == Enum.KeyCode.S then
		movementKeys.s = true
	elseif input.KeyCode == Enum.KeyCode.D then
		movementKeys.d = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		movementKeys.w = false
	elseif input.KeyCode == Enum.KeyCode.A then
		movementKeys.a = false
	elseif input.KeyCode == Enum.KeyCode.S then
		movementKeys.s = false
	elseif input.KeyCode == Enum.KeyCode.D then
		movementKeys.d = false
	end
end)

local Movement = Misc:AddSection({
	Name = "Movement",
	Side = "left",
	ShowTitle = true,
	Height = 0
})

FlySpeedSlider = Movement:AddSlider({
	Name = "Fly Speed",
	Type = "",
	Default = 0,
	Min = 0,
	Max = 100,
	Round = 0,
	Callback = function(value)
		flySpeed = value
	end,
	Flag = "FlySpeed"
})

FlySpeedSlider:SetVisible(false)

FlyToggle = Movement:AddToggle({
	Name = "Fly",
	Default = false,
	Option = true,
	Callback = function(enabled)
		if isResetting then return end
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

CFrameSpeedSlider = Movement:AddSlider({
	Name = "CFrame Speed",
	Type = "",
	Default = 0,
	Min = 0,
	Max = 100,
	Round = 0,
	Callback = function(value)
		cframeSpeedValue = value
	end,
	Flag = "CFrameSpeedValue"
})

CFrameSpeedSlider:SetVisible(false)

CFrameSpeedToggle = Movement:AddToggle({
	Name = "CFrame Speed",
	Default = false,
	Option = true,
	Callback = function(enabled)
		if isResetting then return end
		cframeSpeedEnabled = enabled
		if enabled then
			if flyEnabled or flyActive then
				cframeSpeedEnabled = false
				if CFrameSpeedToggle then
					task.defer(function()
						CFrameSpeedToggle:SetValue(false)
					end)
				end
				return
			end
			startCFrameSpeed()
		else
			stopCFrameSpeed()
		end
		CFrameSpeedSlider:SetVisible(cframeSpeedEnabled)
	end,
	Flag = "CFrameSpeedEnabled"
})

if CFrameSpeedToggle.Option then
	CFrameSpeedToggle.Option:AddKeybind({
		Name = "Keybind",
		Default = nil,
		Callback = function(key) end,
		Flag = "CFrameSpeedKeybind"
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
	end,
	Flag = "WalkSpeedValue"
})

WalkSpeedSlider:SetVisible(false)

local WalkSpeedToggle = Human:AddToggle({
	Name = "WalkSpeed",
	Default = false,
	Option = true,
	Callback = function(enabled)
		if isResetting then return end
		walkSpeedEnabled = enabled
		WalkSpeedSlider:SetVisible(enabled)
		
		if enabled then
			startWalkSpeedLoop()
		else
			cleanupWalkSpeed()
			resetCharacterStats()
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
	end,
	Flag = "JumpPowerValue"
})

JumpPowerSlider:SetVisible(false)

local JumpPowerToggle = Human:AddToggle({
	Name = "JumpPower",
	Default = false,
	Option = true,
	Callback = function(enabled)
		if isResetting then return end
		jumpPowerEnabled = enabled
		JumpPowerSlider:SetVisible(enabled)
		
		if enabled then
			startJumpPowerLoop()
		else
			cleanupJumpPower()
			resetCharacterStats()
		end
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

-- Fun Section (left side)
local Fun = Misc:AddSection({
	Name = "Fun",
	Side = "left",
	ShowTitle = true,
	Height = 0
})

Fun:AddToggle({
	Name = "360",
	Default = false,
	Option = false,
	Callback = function(enabled)
		spin360Enabled = enabled
		if enabled then
			start360Spin()
		else
			stop360Spin()
		end
	end,
	Flag = "360Spin"
})

Fun:AddToggle({
	Name = "Fell",
	Default = false,
	Option = false,
	Callback = function(enabled)
		fellEnabled = enabled
		if enabled then
			startFellLoop()
		else
			stopFellLoop()
		end
	end,
	Flag = "Fell"
})

-- Character Section (right side)
local Character = Misc:AddSection({
	Name = "Character",
	Side = "right",
	ShowTitle = true,
	Height = 0
})

Character:AddToggle({
	Name = "Noclip",
	Default = false,
	Option = false,
	Callback = function(enabled)
		noclipEnabled = enabled
		if enabled then
			enableNoclip()
		else
			disableNoclip()
		end
	end,
	Flag = "NoclipEnabled"
})

Character:AddToggle({
	Name = "Anti Fling",
	Default = false,
	Option = false,
	Callback = function(enabled)
		antiflingEnabled = enabled
		if enabled then
			enableAntiFling()
		else
			disableAntiFling()
		end
	end,
	Flag = "AntiFlingEnabled"
})

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

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if LocalPlayer.Character then
	task.spawn(function()
		onCharacterAdded(LocalPlayer.Character)
	end)
end

print("RAY UI Loaded! Press Insert to toggle menu")
