local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/stk7702-hub/Uilibrary/refs/heads/main/library.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent")

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

local Legit = Window:AddMenu({ Name = "Legit", Icon = "lucide-mouse", AutoFill = false })
local Rage = Window:AddMenu({ Name = "Rage", Icon = "lucide-skull", AutoFill = false })
local Visuals = Window:AddMenu({ Name = "Visuals", Icon = "eye", AutoFill = false })
local Misc = Window:AddMenu({ Name = "Misc", Icon = "package", AutoFill = false })
local PlayersTab = Window:AddMenu({ Name = "Players", Icon = "users", AutoFill = false })
local Settings = Window:AddMenu({ Name = "Settings", Icon = "settings", AutoFill = false })

local HitboxOptions = {"Head", "UpperTorso", "HumanoidRootPart", "Nearest"}

local Aimbot = {
	Enabled = false,
	VisibleCheck = false,
	Hitbox = "Head",
}

local CameraLock = {
	Enabled = false,
	Active = false,
	FOV = 100,
	Smoothness = 0.1,
	Prediction = 0.1,
	CurrentTarget = nil,
	Connection = nil,
}

local Silent = {
	Enabled = false,
	Active = false,
	FOV = 100,
	CurrentTarget = nil,
	BlockedConnections = {},
	InputConnection = nil,
	InputEndConnection = nil,
	RenderConnection = nil,
	CharacterConnection = nil,
	Resolver = false,
	JumpOffset = 0,
	AutoPrediction = false,
	AutoPredictionDivisor = 250,
	UseInterceptModel = true,
	ProjectileSpeed = 1000,
	Tau = 0.15,
}

local PREDICTION_BASE = 0.095
local PREDICTION_TAU = 0.15
local PROJECTILE_SPEED = 1000
local SERVER_TICK_INTERVAL = 1/60
local MAX_INTERCEPT_TIME = 2.0
local VELOCITY_SMOOTH_ALPHA = 0.4
local VELOCITY_MAX_MAGNITUDE = 150
local JUMP_STATE_OFFSET_MULTIPLIER = 1.0

local previousPositions = {}
local smoothedVelocities = {}
local lastUpdateTimes = {}
local accelerationCache = {}

local ESP = {
	ShowCameraLockFOV = true,
	ShowSilentFOV = true,
	CameraLockFOVColor = Color3.fromRGB(255, 255, 255),
	SilentFOVColor = Color3.fromRGB(0, 255, 255),
	LockedColor = Color3.fromRGB(255, 70, 70),
	CameraLockCircle = nil,
	SilentCircle = nil,
}

local movementKeys = {w = false, a = false, s = false, d = false}
local isResetting = false
local menuOpen = true
local menuToggleKey = Enum.KeyCode.Insert

local flyEnabled = false
local flySpeed = 50
local flyConnection = nil
local flyActive = false

local cframeSpeedEnabled = false
local cframeSpeedValue = 1
local cframeSpeedConnection = nil
local cframeSpeedActive = false

local HitSound = {
	Enabled = false,
	Volume = 1,
	SelectedSound = "Bubble",
	Sounds = {
		["Bubble"] = "rbxassetid://6534947588",
		["Lazer"] = "rbxassetid://130791043",
		["Pick"] = "rbxassetid://1347140027",
		["Pop"] = "rbxassetid://198598793",
		["Rust"] = "rbxassetid://1255040462",
		["Sans"] = "rbxassetid://152745539",
		["Fart"] = "rbxassetid://449860068",
		["Big"] = "rbxassetid://554081908",
		["Vine"] = "rbxassetid://352543648",
		["UwU"] = "rbxassetid://4841131517",
		["Bruh"] = "rbxassetid://5734063719",
		["Skeet"] = "rbxassetid://1265316264",
		["Neverlose"] = "rbxassetid://4817809188",
		["Fatality"] = "rbxassetid://5424968049",
		["Bonk"] = "rbxassetid://4606604453",
		["Minecraft"] = "rbxassetid://4018616850",
		["Gamesense"] = "rbxassetid://4018616850",
		["RIFK7"] = "rbxassetid://318620857",
		["Bamboo"] = "rbxassetid://5022625084",
		["Crowbar"] = "rbxassetid://1321060532",
		["Weeb"] = "rbxassetid://718613635",
		["Beep"] = "rbxassetid://8327813988",
		["Osu"] = "rbxassetid://7147454322",
		["Mario"] = "rbxassetid://187011839",
	},
	Connection = nil,
	LastSoundTime = 0,
	SoundCooldown = 0.1,
}
local lastTargetHealth = {}

local isMouseHeld = false
local silentHoldConnection = nil

local walkSpeedEnabled = false
local jumpPowerEnabled = false
local customWalkSpeed = 16
local customJumpPower = 50
local walkSpeedConnection = nil
local jumpPowerConnection = nil

local spin360Enabled = false
local spin360Connection = nil
local spin360Speed = 25

local fellEnabled = false
local fellThread = nil

local noclipEnabled = false
local noclipConnection = nil

local antiflingEnabled = false
local antiflingConnection = nil

local UIElements = {}

local FLY_MIN_SPEED = 0.5
local FLY_MAX_SPEED = 5
local CFRAME_MIN_SPEED = 0.1
local CFRAME_MAX_SPEED = 2

local function calculateFlySpeed(sliderValue)
	return FLY_MIN_SPEED + (sliderValue / 100) * (FLY_MAX_SPEED - FLY_MIN_SPEED)
end

local function calculateCFrameSpeed(sliderValue)
	return CFRAME_MIN_SPEED + (sliderValue / 100) * (CFRAME_MAX_SPEED - CFRAME_MIN_SPEED)
end

local function playHitSound()
	if not HitSound.Enabled then return end
	local currentTime = tick()
	if currentTime - HitSound.LastSoundTime < HitSound.SoundCooldown then return end
	HitSound.LastSoundTime = currentTime
	local soundId = HitSound.Sounds[HitSound.SelectedSound]
	if not soundId then return end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = HitSound.Volume
	sound.Parent = workspace
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local function getCurrentTarget()
	if CameraLock.Active and CameraLock.CurrentTarget then
		return CameraLock.CurrentTarget
	end
	if Silent.Active and Silent.CurrentTarget then
		return Silent.CurrentTarget
	end
	return nil
end

local function startHitSoundMonitor()
	if HitSound.Connection then return end
	HitSound.Connection = RunService.Heartbeat:Connect(function()
		if not HitSound.Enabled then return end
		local target = getCurrentTarget()
		if not target or not target.Character then return end
		local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		local playerName = target.Name
		local currentHealth = humanoid.Health
		if not lastTargetHealth[playerName] then
			lastTargetHealth[playerName] = currentHealth
			return
		end
		if currentHealth < lastTargetHealth[playerName] then
			playHitSound()
		end
		lastTargetHealth[playerName] = currentHealth
	end)
end

local function stopHitSoundMonitor()
	if HitSound.Connection then
		HitSound.Connection:Disconnect()
		HitSound.Connection = nil
	end
end

local function GetCharacterParts(player)
	player = player or LocalPlayer
	local character = player.Character
	if not character then return nil, nil, nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil, nil, nil end
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("LowerTorso")
	if not rootPart then return nil, nil, nil end
	return character, humanoid, rootPart
end

local function GetMousePosition()
	return UserInputService:GetMouseLocation()
end

local function WorldToScreen(position)
	local screenPos, onScreen = Camera:WorldToViewportPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

local function GetDistanceFromCrosshair(position)
	local screenPos, onScreen = WorldToScreen(position)
	if not onScreen then return math.huge end
	return (screenPos - GetMousePosition()).Magnitude
end

local function GetWorldDistance(fromPos, toPos)
	return (fromPos - toPos).Magnitude
end

local function IsVisible(origin, targetPart)
	if not targetPart then return false end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {
		LocalPlayer.Character,
		Camera,
		workspace:FindFirstChild("Bush"),
		workspace:FindFirstChild("Ignored"),
	}
	local direction = (targetPart.Position - origin)
	local result = workspace:Raycast(origin, direction, rayParams)
	if not result then return true end
	local targetChar = targetPart:FindFirstAncestorOfClass("Model")
	return targetChar and result.Instance:IsDescendantOf(targetChar)
end

local function GetHitboxPart(character, hitboxName)
	if not character then return nil end
	hitboxName = hitboxName or "Head"
	if hitboxName == "Nearest" then
		local mousePos = GetMousePosition()
		local parts = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}
		local closestPart, closestDist = nil, math.huge
		for _, partName in ipairs(parts) do
			local part = character:FindFirstChild(partName)
			if part then
				local screenPos, onScreen = WorldToScreen(part.Position)
				if onScreen then
					local dist = (screenPos - mousePos).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestPart = part
					end
				end
			end
		end
		return closestPart or character:FindFirstChild("HumanoidRootPart")
	end
	local part = character:FindFirstChild(hitboxName)
	if part then return part end
	if hitboxName == "UpperTorso" or hitboxName == "LowerTorso" then
		return character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function GetPing()
	local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	return ping
end

local function CalculateSmoothAlpha(deltaTime, tau)
	return 1 - math.exp(-deltaTime / tau)
end

local function GetSmoothedVelocity(character, useResolver)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return Vector3.zero, Vector3.zero end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local player = Players:GetPlayerFromCharacter(character)
	local tau = Silent.Tau or PREDICTION_TAU
	if useResolver and humanoid then
		local moveDir = humanoid.MoveDirection
		local walkSpeed = humanoid.WalkSpeed
		if moveDir.Magnitude > 0 then
			return moveDir * walkSpeed, Vector3.zero
		end
		return Vector3.zero, Vector3.zero
	end
	if not player then 
		local velocity = rootPart.AssemblyLinearVelocity
		if velocity.Magnitude > VELOCITY_MAX_MAGNITUDE then
			velocity = velocity.Unit * VELOCITY_MAX_MAGNITUDE
		end
		return velocity, Vector3.zero
	end
	local currentTime = tick()
	local currentPos = rootPart.Position
	local lastPos = previousPositions[player] or currentPos
	local lastTime = lastUpdateTimes[player] or (currentTime - 0.016)
	local deltaTime = math.max(currentTime - lastTime, 0.001)
	local rawVelocity = (currentPos - lastPos) / deltaTime
	if rawVelocity.Magnitude > VELOCITY_MAX_MAGNITUDE then
		rawVelocity = rawVelocity.Unit * VELOCITY_MAX_MAGNITUDE
	end
	local alpha = CalculateSmoothAlpha(deltaTime, tau)
	local prevSmoothed = smoothedVelocities[player] or rawVelocity
	local smoothed = prevSmoothed:Lerp(rawVelocity, alpha)
	local prevVelocity = smoothedVelocities[player] or smoothed
	local rawAccel = (smoothed - prevVelocity) / deltaTime
	local prevAccel = accelerationCache[player] or rawAccel
	local accelAlpha = CalculateSmoothAlpha(deltaTime, tau * 2)
	local smoothedAccel = prevAccel:Lerp(rawAccel, accelAlpha)
	accelerationCache[player] = smoothedAccel
	smoothedVelocities[player] = smoothed
	previousPositions[player] = currentPos
	lastUpdateTimes[player] = currentTime
	return smoothed, smoothedAccel
end

local function GetJumpOffset(character, baseOffset)
	if baseOffset == 0 then return 0 end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return 0 end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
		return baseOffset * JUMP_STATE_OFFSET_MULTIPLIER
	end
	return 0
end

local function CalculateInterceptTime(targetPos, targetVel, shooterPos, projectileSpeed)
	local r = targetPos - shooterPos
	local a = targetVel:Dot(targetVel) - projectileSpeed * projectileSpeed
	local b = 2 * r:Dot(targetVel)
	local c = r:Dot(r)
	if math.abs(a) < 0.0001 then
		if math.abs(b) < 0.0001 then
			return r.Magnitude / math.max(projectileSpeed, 1)
		end
		local t = -c / b
		if t > 0 then
			return math.clamp(t, 0, MAX_INTERCEPT_TIME)
		end
		return r.Magnitude / math.max(projectileSpeed, 1)
	end
	local discriminant = b * b - 4 * a * c
	if discriminant < 0 then
		return r.Magnitude / math.max(projectileSpeed, 1)
	end
	local sqrtDisc = math.sqrt(discriminant)
	local t1 = (-b - sqrtDisc) / (2 * a)
	local t2 = (-b + sqrtDisc) / (2 * a)
	local t = math.huge
	if t1 > 0.001 and t1 < t then t = t1 end
	if t2 > 0.001 and t2 < t then t = t2 end
	if t == math.huge or t ~= t then
		return r.Magnitude / math.max(projectileSpeed, 1)
	end
	return math.clamp(t, 0, MAX_INTERCEPT_TIME)
end

local function PredictPositionSilent(character, hitbox)
	if not hitbox then return nil end
	local useResolver = Silent.Resolver
	local jumpOffset = Silent.JumpOffset
	local useInterceptModel = Silent.UseInterceptModel
	local projectileSpeed = Silent.ProjectileSpeed or PROJECTILE_SPEED
	local velocity, acceleration = GetSmoothedVelocity(character, useResolver)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		local ping = GetPing()
		local t_net = (ping / 1000) / 2
		return hitbox.Position + velocity * t_net
	end
	local shooterPos = myRoot.Position + Vector3.new(0, 2, 0)
	local targetPos = hitbox.Position
	local ping = GetPing()
	local t_net = (ping / 1000) / 2
	local t_tick = SERVER_TICK_INTERVAL / 2
	local t_proj
	if useInterceptModel and projectileSpeed > 0 then
		t_proj = CalculateInterceptTime(targetPos, velocity, shooterPos, projectileSpeed)
	else
		if Silent.AutoPrediction then
			local divisor = Silent.AutoPredictionDivisor or 250
			t_proj = PREDICTION_BASE + (ping / divisor) * 0.1
		else
			local distance = (targetPos - shooterPos).Magnitude
			t_proj = distance / math.max(projectileSpeed, 1)
		end
	end
	local t = t_net + t_tick + t_proj
	local yOffset = GetJumpOffset(character, jumpOffset)
	local predictedPos = targetPos + (velocity * t) + (acceleration * 0.5 * t * t) + Vector3.new(0, yOffset, 0)
	return predictedPos
end

local function PredictPosition(character, hitbox, prediction)
	if not hitbox then return nil end
	if prediction <= 0 then return hitbox.Position end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return hitbox.Position + (rootPart.AssemblyLinearVelocity * prediction)
	end
	return hitbox.Position
end

local function GetTarget(fov, useVisibleCheck, forSilent)
	if not Aimbot.Enabled then return nil end
	local myChar, myHum, myRoot = GetCharacterParts()
	if not myRoot then return nil end
	local bestTarget, bestScore = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		local char, hum = GetCharacterParts(player)
		if not char or not hum then continue end
		local bodyEffects = char:FindFirstChild("BodyEffects")
		if bodyEffects then
			local ko = bodyEffects:FindFirstChild("K.O")
			if ko and ko.Value then continue end
			local dead = bodyEffects:FindFirstChild("Dead")
			if dead and dead.Value then continue end
		end
		local hitbox = GetHitboxPart(char, Aimbot.Hitbox)
		if not hitbox then continue end
		local crosshairDist = GetDistanceFromCrosshair(hitbox.Position)
		if crosshairDist > fov then continue end
		local checkVisible = useVisibleCheck or forSilent
		if checkVisible then
			if not IsVisible(Camera.CFrame.Position, hitbox) then continue end
		end
		local worldDist = GetWorldDistance(myRoot.Position, hitbox.Position)
		local score = (crosshairDist * 0.7) + (worldDist * 0.3)
		if score < bestScore then
			bestScore = score
			bestTarget = player
		end
	end
	return bestTarget
end

local function GetEquippedGun()
	local char = LocalPlayer.Character
	if not char then return nil end
	local tool = char:FindFirstChildWhichIsA("Tool")
	if not tool then return nil end
	if not tool:FindFirstChild("Handle") then return nil end
	if not tool:FindFirstChild("RemoteEvent") then return nil end
	if not tool:FindFirstChild("Ammo") then return nil end
	return tool
end

local function CanShootSilent()
	local char, hum = GetCharacterParts()
	if not char or not hum then return false, nil end
	local gun = GetEquippedGun()
	if not gun then return false, nil end
	local ammo = gun:FindFirstChild("Ammo")
	if ammo and ammo.Value <= 0 then return false, nil end
	local bodyEffects = char:FindFirstChild("BodyEffects")
	if not bodyEffects then return false, nil end
	if bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value then return false, nil end
	if bodyEffects:FindFirstChild("Dead") and bodyEffects.Dead.Value then return false, nil end
	if bodyEffects:FindFirstChild("Reload") and bodyEffects.Reload.Value then return false, nil end
	return true, gun
end

local function CanShoot()
	local char, hum = GetCharacterParts()
	if not char or not hum then return false, nil end
	local gun = GetEquippedGun()
	if not gun then return false, nil end
	local ammo = gun:FindFirstChild("Ammo")
	if ammo and ammo.Value <= 0 then return false, nil end
	local bodyEffects = char:FindFirstChild("BodyEffects")
	if not bodyEffects then return false, nil end
	if bodyEffects:FindFirstChild("Cuff") and bodyEffects.Cuff.Value then return false, nil end
	if bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value then return false, nil end
	if bodyEffects:FindFirstChild("Reload") and bodyEffects.Reload.Value then return false, nil end
	if bodyEffects:FindFirstChild("Dead") and bodyEffects.Dead.Value then return false, nil end
	if bodyEffects:FindFirstChild("Attacking") and bodyEffects.Attacking.Value then return false, nil end
	if bodyEffects:FindFirstChild("Grabbed") and bodyEffects.Grabbed.Value then return false, nil end
	if gun:GetAttribute("Cooldown") then return false, nil end
	if char:FindFirstChild("FORCEFIELD") then return false, nil end
	if not char:FindFirstChild("FULLY_LOADED_CHAR") then return false, nil end
	if char:FindFirstChild("GRABBING_CONSTRAINT") then return false, nil end
	return true, gun
end

local function FireModifiedShot(target)
	local canShootResult, gun = CanShootSilent()
	if not canShootResult or not gun then return false end
	local char = LocalPlayer.Character
	local myHRP = char:FindFirstChild("HumanoidRootPart")
	if not myHRP then return false end
	local targetChar = target.Character
	if not targetChar then return false end
	local hitbox = GetHitboxPart(targetChar, Aimbot.Hitbox)
	if not hitbox then return false end
	local targetPos = PredictPositionSilent(targetChar, hitbox)
	if not targetPos then return false end
	local startPos = myHRP.Position + Vector3.new(0, 2, 0)
	local gunRange = gun:FindFirstChild("Range")
	if gunRange then
		local distance = (targetPos - startPos).Magnitude
		if distance > gunRange.Value then
			return false
		end
	end
	MainEvent:FireServer("UpdateMousePosI2", targetPos)
	local gunRemote = gun:FindFirstChild("RemoteEvent")
	if gunRemote then
		gunRemote:FireServer("Shoot")
	end
	MainEvent:FireServer("ShootGun", gun.Handle, startPos, targetPos, hitbox, Vector3.new(0, 1, 0))
	local shootSound = gun.Handle:FindFirstChild("Fire") or gun.Handle:FindFirstChild("ShootSound")
	if shootSound and shootSound:IsA("Sound") then
		shootSound:Play()
	end
	return true
end

local function FireNormalShot()
	local canShootResult, gun = CanShootSilent()
	if not canShootResult or not gun then return false end
	local char = LocalPlayer.Character
	local myHRP = char:FindFirstChild("HumanoidRootPart")
	if not myHRP then return false end
	local mouse = LocalPlayer:GetMouse()
	local targetPos = mouse.Hit.Position
	local startPos = myHRP.Position + Vector3.new(0, 2, 0)
	MainEvent:FireServer("UpdateMousePosI2", targetPos)
	local gunRemote = gun:FindFirstChild("RemoteEvent")
	if gunRemote then
		gunRemote:FireServer("Shoot")
	end
	MainEvent:FireServer("ShootGun", gun.Handle, startPos, targetPos, mouse.Target or workspace.Terrain, mouse.TargetSurface and Vector3.FromNormalId(mouse.TargetSurface) or Vector3.new(0, 1, 0))
	return true
end

local function BlockGunInput(gun)
	if not gun then return end
	local localScript = gun:FindFirstChild("LocalScript")
	if localScript and localScript:IsA("LocalScript") then
		localScript.Disabled = true
		table.insert(Silent.BlockedConnections, {script = localScript, wasDisabled = false})
	end
	if getconnections then
		local success, connections = pcall(function()
			return getconnections(gun.Activated)
		end)
		if success and connections then
			for _, conn in ipairs(connections) do
				pcall(function() conn:Disable() end)
				table.insert(Silent.BlockedConnections, {connection = conn})
			end
		end
	end
end

local function UnblockGunInput()
	for _, data in ipairs(Silent.BlockedConnections) do
		if data.script then
			data.script.Disabled = data.wasDisabled or false
		end
		if data.connection then
			pcall(function() data.connection:Enable() end)
		end
	end
	Silent.BlockedConnections = {}
end

local function OnSilentInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	if not Silent.Active then return end
	isMouseHeld = true
	local gun = GetEquippedGun()
	if not gun then return end
	local target = GetTarget(Silent.FOV, true, true)
	if target then
		FireModifiedShot(target)
	else
		FireNormalShot()
	end
end

local function OnSilentInputEnded(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isMouseHeld = false
	end
end

local function OnSilentHoldUpdate()
	if not Silent.Active then return end
	if not isMouseHeld then return end
	local gun = GetEquippedGun()
	if not gun then return end
	local canShootResult = CanShootSilent()
	if not canShootResult then return end
	local target = GetTarget(Silent.FOV, true, true)
	if target then
		FireModifiedShot(target)
	else
		FireNormalShot()
	end
end

local function OnSilentRenderStep()
	if not Silent.Active then return end
	Silent.CurrentTarget = GetTarget(Silent.FOV, true, true)
end

local function EnableSilent()
	if Silent.Active then return end
	Silent.Active = true
	isMouseHeld = false
	local gun = GetEquippedGun()
	if gun then
		BlockGunInput(gun)
	end
	if LocalPlayer.Character then
		Silent.CharacterConnection = LocalPlayer.Character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and Silent.Active then
				task.wait(0.1)
				BlockGunInput(child)
			end
		end)
	end
	Silent.InputConnection = UserInputService.InputBegan:Connect(OnSilentInputBegan)
	Silent.InputEndConnection = UserInputService.InputEnded:Connect(OnSilentInputEnded)
	Silent.RenderConnection = RunService.RenderStepped:Connect(OnSilentRenderStep)
	silentHoldConnection = RunService.Heartbeat:Connect(OnSilentHoldUpdate)
end

local function DisableSilent()
	if not Silent.Active then return end
	Silent.Active = false
	Silent.CurrentTarget = nil
	isMouseHeld = false
	UnblockGunInput()
	if Silent.CharacterConnection then
		Silent.CharacterConnection:Disconnect()
		Silent.CharacterConnection = nil
	end
	if Silent.InputConnection then
		Silent.InputConnection:Disconnect()
		Silent.InputConnection = nil
	end
	if Silent.InputEndConnection then
		Silent.InputEndConnection:Disconnect()
		Silent.InputEndConnection = nil
	end
	if Silent.RenderConnection then
		Silent.RenderConnection:Disconnect()
		Silent.RenderConnection = nil
	end
	if silentHoldConnection then
		silentHoldConnection:Disconnect()
		silentHoldConnection = nil
	end
end

local function CalculateSmoothFactor(smoothness, deltaTime)
	if smoothness <= 0.01 then
		return 1
	end
	local baseFactor = 1 - smoothness
	local expFactor = baseFactor ^ 0.7
	local targetDelta = 1 / 60
	local deltaScale = deltaTime / targetDelta
	local eased = expFactor * expFactor * (3 - 2 * expFactor)
	local finalFactor = math.clamp(eased * deltaScale, 0.02, 1)
	return finalFactor
end

local lastCameraLockTime = tick()

local function StartCameraLock()
	if CameraLock.Connection then return end
	lastCameraLockTime = tick()
	CameraLock.Connection = RunService.RenderStepped:Connect(function()
		if not CameraLock.Active then return end
		if menuOpen then
			CameraLock.CurrentTarget = nil
			return
		end
		local currentTime = tick()
		local deltaTime = math.clamp(currentTime - lastCameraLockTime, 0.001, 0.1)
		lastCameraLockTime = currentTime
		local target = GetTarget(CameraLock.FOV, Aimbot.VisibleCheck, false)
		CameraLock.CurrentTarget = target
		if not target or not target.Character then return end
		local hitbox = GetHitboxPart(target.Character, Aimbot.Hitbox)
		if not hitbox then return end
		local targetPos = PredictPosition(target.Character, hitbox, CameraLock.Prediction)
		if not targetPos then return end
		local screenPos, onScreen = WorldToScreen(targetPos)
		if not onScreen then return end
		local mousePos = GetMousePosition()
		local delta = screenPos - mousePos
		local distance = delta.Magnitude
		if distance < 1 then return end
		local smoothFactor = CalculateSmoothFactor(CameraLock.Smoothness, deltaTime)
		local distanceScale = math.clamp(distance / 200, 0.3, 1.5)
		smoothFactor = smoothFactor * distanceScale
		local moveX = delta.X * smoothFactor
		local moveY = delta.Y * smoothFactor
		if math.abs(moveX) < 0.5 and math.abs(delta.X) > 0.5 then
			moveX = delta.X > 0 and 0.5 or -0.5
		end
		if math.abs(moveY) < 0.5 and math.abs(delta.Y) > 0.5 then
			moveY = delta.Y > 0 and 0.5 or -0.5
		end
		if mousemoverel then
			mousemoverel(moveX, moveY)
		end
	end)
end

local function StopCameraLock()
	CameraLock.CurrentTarget = nil
	if CameraLock.Connection then
		CameraLock.Connection:Disconnect()
		CameraLock.Connection = nil
	end
end

local function CreateFOVCircles()
	if not Drawing then return end
	if not ESP.CameraLockCircle then
		ESP.CameraLockCircle = Drawing.new("Circle")
		ESP.CameraLockCircle.Thickness = 1
		ESP.CameraLockCircle.NumSides = 64
		ESP.CameraLockCircle.Filled = false
		ESP.CameraLockCircle.Visible = false
		ESP.CameraLockCircle.Transparency = 0.7
	end
	if not ESP.SilentCircle then
		ESP.SilentCircle = Drawing.new("Circle")
		ESP.SilentCircle.Thickness = 1
		ESP.SilentCircle.NumSides = 64
		ESP.SilentCircle.Filled = false
		ESP.SilentCircle.Visible = false
		ESP.SilentCircle.Transparency = 0.7
	end
end

local function UpdateFOVCircles()
	local mousePos = GetMousePosition()
	if ESP.CameraLockCircle then
		ESP.CameraLockCircle.Position = mousePos
		ESP.CameraLockCircle.Radius = CameraLock.FOV
		ESP.CameraLockCircle.Visible = ESP.ShowCameraLockFOV and CameraLock.Active
		local hasTarget = CameraLock.CurrentTarget ~= nil
		local isVisibleTarget = true
		if hasTarget and Aimbot.VisibleCheck then
			local targetChar = CameraLock.CurrentTarget.Character
			if targetChar then
				local hitbox = GetHitboxPart(targetChar, Aimbot.Hitbox)
				isVisibleTarget = hitbox and IsVisible(Camera.CFrame.Position, hitbox)
			end
		end
		if hasTarget and isVisibleTarget then
			ESP.CameraLockCircle.Color = ESP.LockedColor
		else
			ESP.CameraLockCircle.Color = ESP.CameraLockFOVColor
		end
	end
	if ESP.SilentCircle then
		ESP.SilentCircle.Position = mousePos
		ESP.SilentCircle.Radius = Silent.FOV
		ESP.SilentCircle.Visible = ESP.ShowSilentFOV and Silent.Active
		local hasTarget = Silent.CurrentTarget ~= nil
		if hasTarget then
			ESP.SilentCircle.Color = ESP.LockedColor
		else
			ESP.SilentCircle.Color = ESP.SilentFOVColor
		end
	end
end

CreateFOVCircles()

RunService.RenderStepped:Connect(function()
	pcall(UpdateFOVCircles)
end)

local function cleanupFly()
	flyActive = false
	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
end

local function cleanupCFrameSpeed()
	cframeSpeedActive = false
	if cframeSpeedConnection then
		cframeSpeedConnection:Disconnect()
		cframeSpeedConnection = nil
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

local function startFly()
	if flyActive then return end
	if cframeSpeedActive or cframeSpeedEnabled then
		cleanupCFrameSpeed()
		cframeSpeedEnabled = false
		if UIElements.CFrameSpeedToggle then
			UIElements.CFrameSpeedToggle:SetValue(false)
		end
		if UIElements.CFrameSpeedSlider then
			UIElements.CFrameSpeedSlider:SetVisible(false)
		end
	end
	local character, humanoid, rootPart = GetCharacterParts()
	if not character then return end
	flyActive = true
	flyConnection = RunService.Heartbeat:Connect(function()
		if not flyEnabled or not flyActive then return end
		local char, hum, root = GetCharacterParts()
		if not char or not root then
			cleanupFly()
			return
		end
		local camera = workspace.CurrentCamera
		local moveDirection = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDirection = moveDirection + camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDirection = moveDirection - camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDirection = moveDirection + camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDirection = moveDirection - camera.CFrame.RightVector
		end
		if moveDirection.Magnitude > 0 then
			moveDirection = moveDirection.Unit
		end
		local actualSpeed = calculateFlySpeed(flySpeed)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = root.CFrame + moveDirection * actualSpeed
	end)
end

local function stopFly()
	cleanupFly()
end

local function startCFrameSpeed()
	if cframeSpeedActive then return end
	if flyEnabled or flyActive then
		cframeSpeedEnabled = false
		if UIElements.CFrameSpeedToggle then
			UIElements.CFrameSpeedToggle:SetValue(false)
		end
		if UIElements.CFrameSpeedSlider then
			UIElements.CFrameSpeedSlider:SetVisible(false)
		end
		return
	end
	local character, humanoid, rootPart = GetCharacterParts()
	if not character then return end
	cframeSpeedActive = true
	cframeSpeedConnection = RunService.Stepped:Connect(function()
		if not cframeSpeedEnabled or not cframeSpeedActive then return end
		if flyEnabled or flyActive then
			cleanupCFrameSpeed()
			cframeSpeedEnabled = false
			if UIElements.CFrameSpeedToggle then
				UIElements.CFrameSpeedToggle:SetValue(false)
			end
			if UIElements.CFrameSpeedSlider then
				UIElements.CFrameSpeedSlider:SetVisible(false)
			end
			return
		end
		local char, hum, root = GetCharacterParts()
		if not char or not root or not hum then
			cleanupCFrameSpeed()
			return
		end
		local moveDirection = hum.MoveDirection
		if moveDirection.Magnitude > 0 then
			local actualSpeed = calculateCFrameSpeed(cframeSpeedValue)
			root.CFrame = root.CFrame + moveDirection * actualSpeed
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
		local character, humanoid = GetCharacterParts()
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
		local character, humanoid = GetCharacterParts()
		if not humanoid then return end
		if humanoid.JumpPower ~= customJumpPower then
			humanoid.JumpPower = customJumpPower
		end
	end)
end

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
			humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			task.wait(1.5)
			if not fellEnabled then break end
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
	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

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

local function resetCharacterStats()
	local character, humanoid = GetCharacterParts()
	if not humanoid then return end
	if not walkSpeedEnabled then
		humanoid.WalkSpeed = 16
	end
	if not jumpPowerEnabled then
		humanoid.JumpPower = 50
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

local function onCharacterAdded(character)
	isResetting = true
	cleanupAll()
	isMouseHeld = false
	if Silent.Active then
		UnblockGunInput()
		Silent.BlockedConnections = {}
	end
	previousPositions = {}
	smoothedVelocities = {}
	lastUpdateTimes = {}
	accelerationCache = {}
	lastTargetHealth = {}
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
	if Silent.Active then
		if Silent.CharacterConnection then
			Silent.CharacterConnection:Disconnect()
		end
		Silent.CharacterConnection = character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and Silent.Active then
				task.wait(0.1)
				BlockGunInput(child)
			end
		end)
		local gun = GetEquippedGun()
		if gun then
			BlockGunInput(gun)
		end
	end
	humanoid.Died:Connect(function()
		cleanupAll()
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode == menuToggleKey then
		menuOpen = not menuOpen
	end
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

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
	task.spawn(function()
		onCharacterAdded(LocalPlayer.Character)
	end)
end

local GlobalSection = Legit:AddSection({ Name = "Global", Side = "left", ShowTitle = true, Height = 0 })

GlobalSection:AddToggle({
	Name = "Aimbot",
	Default = false,
	Callback = function(v)
		Aimbot.Enabled = v
		if not v then
			CameraLock.CurrentTarget = nil
			Silent.CurrentTarget = nil
		end
	end,
	Flag = "AimbotEnabled"
})

GlobalSection:AddToggle({
	Name = "Visible Check",
	Default = false,
	Callback = function(v)
		Aimbot.VisibleCheck = v
	end,
	Flag = "VisibleCheck"
})

GlobalSection:AddDropdown({
	Name = "Hitbox",
	Values = HitboxOptions,
	Default = "Head",
	Callback = function(v)
		Aimbot.Hitbox = v
	end,
	Flag = "Hitbox"
})

GlobalSection:AddToggle({
	Name = "Hit Sound",
	Default = false,
	Callback = function(v)
		HitSound.Enabled = v
		if v then
			startHitSoundMonitor()
		else
			stopHitSoundMonitor()
		end
	end,
	Flag = "HitSoundEnabled"
})

local HitSoundOptions = {}
for name, _ in pairs(HitSound.Sounds) do
	table.insert(HitSoundOptions, name)
end
table.sort(HitSoundOptions)

GlobalSection:AddDropdown({
	Name = "Sound Type",
	Values = HitSoundOptions,
	Default = "Bubble",
	Callback = function(v)
		HitSound.SelectedSound = v
	end,
	Flag = "HitSoundType"
})

GlobalSection:AddSlider({
	Name = "Sound Volume",
	Type = "",
	Default = 1,
	Min = 0.1,
	Max = 5,
	Round = 1,
	Callback = function(v)
		HitSound.Volume = v
	end,
	Flag = "HitSoundVolume"
})

local CameraLockSection = Legit:AddSection({ Name = "Camera Lock", Side = "left", ShowTitle = true, Height = 0 })

local CameraLockToggle = CameraLockSection:AddToggle({
	Name = "Enabled",
	Default = false,
	Option = true,
	Callback = function(v)
		CameraLock.Active = v
		if v then
			StartCameraLock()
		else
			StopCameraLock()
		end
	end,
	Flag = "CameraLockEnabled"
})

if CameraLockToggle.Option then
	CameraLockToggle.Option:AddKeybind({
		Name = "Keybind",
		Default = nil,
		Callback = function() end,
		Flag = "CameraLockKeybind"
	})
end

CameraLockSection:AddSlider({
	Name = "FOV",
	Type = "px",
	Default = 100,
	Min = 10,
	Max = 500,
	Round = 0,
	Callback = function(v) CameraLock.FOV = v end,
	Flag = "CameraLockFOV"
})

CameraLockSection:AddSlider({
	Name = "Smoothness",
	Type = "",
	Default = 0.1,
	Min = 0,
	Max = 0.95,
	Round = 2,
	Callback = function(v) CameraLock.Smoothness = v end,
	Flag = "CameraLockSmooth"
})

CameraLockSection:AddSlider({
	Name = "Prediction",
	Type = "",
	Default = 0.5,
	Min = 0,
	Max = 0.95,
	Round = 2,
	Callback = function(v) CameraLock.Prediction = v end,
	Flag = "CameraLockPrediction"
})

local SilentSection = Legit:AddSection({ Name = "Silent", Side = "right", ShowTitle = true, Height = 0 })

local SilentToggle = SilentSection:AddToggle({
	Name = "Enabled",
	Default = false,
	Option = true,
	Callback = function(v)
		Silent.Enabled = v
		if v then
			EnableSilent()
		else
			DisableSilent()
		end
	end,
	Flag = "SilentEnabled"
})

if SilentToggle.Option then
	SilentToggle.Option:AddKeybind({
		Name = "Keybind",
		Default = nil,
		Callback = function() end,
		Flag = "SilentKeybind"
	})
end

SilentSection:AddSlider({
	Name = "FOV",
	Type = "px",
	Default = 100,
	Min = 10,
	Max = 500,
	Round = 0,
	Callback = function(v) Silent.FOV = v end,
	Flag = "SilentFOV"
})

SilentSection:AddToggle({
	Name = "Intercept Model",
	Default = true,
	Callback = function(v) Silent.UseInterceptModel = v end,
	Flag = "SilentInterceptModel"
})

SilentSection:AddSlider({
	Name = "Projectile Speed",
	Type = "u/s",
	Default = 1000,
	Min = 100,
	Max = 5000,
	Round = 0,
	Callback = function(v) Silent.ProjectileSpeed = v end,
	Flag = "SilentProjectileSpeed"
})

SilentSection:AddSlider({
	Name = "Smoothing Tau",
	Type = "s",
	Default = 0.15,
	Min = 0.05,
	Max = 0.50,
	Round = 2,
	Callback = function(v) Silent.Tau = v end,
	Flag = "SilentTau"
})

SilentSection:AddToggle({
	Name = "Velocity Resolver",
	Default = false,
	Callback = function(v) Silent.Resolver = v end,
	Flag = "SilentResolver"
})

SilentSection:AddSlider({
	Name = "Jump Offset",
	Type = "",
	Default = 0,
	Min = -1,
	Max = 1,
	Round = 2,
	Callback = function(v) Silent.JumpOffset = v end,
	Flag = "SilentJumpOffset"
})

SilentSection:AddToggle({
	Name = "Auto Prediction",
	Default = false,
	Callback = function(v) Silent.AutoPrediction = v end,
	Flag = "SilentAutoPrediction"
})

SilentSection:AddSlider({
	Name = "Auto Pred Divisor",
	Type = "",
	Default = 250,
	Min = 200,
	Max = 350,
	Round = 0,
	Callback = function(v) Silent.AutoPredictionDivisor = v end,
	Flag = "SilentAutoPredDivisor"
})

local FOVVisualsSection = Visuals:AddSection({ Name = "FOV Circles", Side = "left", ShowTitle = true, Height = 0 })

FOVVisualsSection:AddToggle({
	Name = "Show Camera Lock FOV",
	Default = true,
	Callback = function(v) ESP.ShowCameraLockFOV = v end,
	Flag = "ShowCameraLockFOV"
})

FOVVisualsSection:AddColorPicker({
	Name = "Camera Lock Color",
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(c) ESP.CameraLockFOVColor = c end,
	Flag = "CameraLockFOVColor"
})

FOVVisualsSection:AddToggle({
	Name = "Show Silent FOV",
	Default = true,
	Callback = function(v) ESP.ShowSilentFOV = v end,
	Flag = "ShowSilentFOV"
})

FOVVisualsSection:AddColorPicker({
	Name = "Silent Color",
	Default = Color3.fromRGB(0, 255, 255),
	Callback = function(c) ESP.SilentFOVColor = c end,
	Flag = "SilentFOVColor"
})

FOVVisualsSection:AddColorPicker({
	Name = "Locked Color",
	Default = Color3.fromRGB(255, 70, 70),
	Callback = function(c) ESP.LockedColor = c end,
	Flag = "LockedColor"
})

local Movement = Misc:AddSection({ Name = "Movement", Side = "left", ShowTitle = true, Height = 0 })

UIElements.FlySlider = Movement:AddSlider({
	Name = "Fly Speed",
	Type = "",
	Default = 50,
	Min = 1,
	Max = 100,
	Round = 0,
	Callback = function(value)
		flySpeed = value
	end,
	Flag = "FlySpeed"
})
UIElements.FlySlider:SetVisible(false)

UIElements.FlyToggle = Movement:AddToggle({
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
		UIElements.FlySlider:SetVisible(enabled)
	end,
	Flag = "FlyEnabled"
})

if UIElements.FlyToggle.Option then
	UIElements.FlyToggle.Option:AddKeybind({
		Name = "Keybind",
		Default = nil,
		Callback = function(key) end,
		Flag = "FlyKeybind"
	})
end

UIElements.CFrameSpeedSlider = Movement:AddSlider({
	Name = "CFrame Speed",
	Type = "",
	Default = 50,
	Min = 1,
	Max = 100,
	Round = 0,
	Callback = function(value)
		cframeSpeedValue = value
	end,
	Flag = "CFrameSpeedValue"
})
UIElements.CFrameSpeedSlider:SetVisible(false)

UIElements.CFrameSpeedToggle = Movement:AddToggle({
	Name = "CFrame Speed",
	Default = false,
	Option = true,
	Callback = function(enabled)
		if isResetting then return end
		cframeSpeedEnabled = enabled
		if enabled then
			if flyEnabled or flyActive then
				cframeSpeedEnabled = false
				if UIElements.CFrameSpeedToggle then
					task.defer(function()
						UIElements.CFrameSpeedToggle:SetValue(false)
					end)
				end
				return
			end
			startCFrameSpeed()
		else
			stopCFrameSpeed()
		end
		UIElements.CFrameSpeedSlider:SetVisible(cframeSpeedEnabled)
	end,
	Flag = "CFrameSpeedEnabled"
})

if UIElements.CFrameSpeedToggle.Option then
	UIElements.CFrameSpeedToggle.Option:AddKeybind({
		Name = "Keybind",
		Default = nil,
		Callback = function(key) end,
		Flag = "CFrameSpeedKeybind"
	})
end

local Human = Misc:AddSection({ Name = "Human", Side = "left", ShowTitle = true, Height = 0 })

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

local Fun = Misc:AddSection({ Name = "Fun", Side = "left", ShowTitle = true, Height = 0 })

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

local Character = Misc:AddSection({ Name = "Character", Side = "right", ShowTitle = true, Height = 0 })

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

local UI = Settings:AddSection({ Name = "UI", Side = "left", ShowTitle = true, Height = 0 })

UI:AddKeybind({
	Name = "Toggle Menu",
	Default = Enum.KeyCode.Insert,
	Option = false,
	Flag = "ToggleMenu",
	Callback = function(key)
		if typeof(key) == "EnumItem" then
			menuToggleKey = key
			Window:SetToggleKeybind(key)
		elseif typeof(key) == "string" then
			pcall(function()
				menuToggleKey = Enum.KeyCode[key]
				Window:SetToggleKeybind(Enum.KeyCode[key])
			end)
		end
	end
})

UI:AddColorPicker({
	Name = "Background",
	Default = customTheme.Background,
	Callback = function(c)
		Window:SetTheme({ Background = c, Panel = c })
	end,
	Flag = "MainColor"
})

UI:AddColorPicker({
	Name = "Accent",
	Default = customTheme.Accent,
	Callback = function(c)
		Window:SetTheme({
			Accent = c,
			SliderAccent = c,
			ToggleAccent = c,
			TabSelected = c,
			ProfileStroke = c
		})
	end,
	Flag = "AccentColor"
})

UI:AddColorPicker({
	Name = "Text",
	Default = customTheme.Text,
	Callback = function(c)
		Window:SetTheme({ Text = c })
	end,
	Flag = "TextColor"
})

UI:AddColorPicker({
	Name = "Slider",
	Default = customTheme.SliderAccent,
	Callback = function(c)
		Window:SetTheme({ SliderAccent = c })
	end,
	Flag = "SliderColor"
})

UI:AddColorPicker({ 
	Name = "Toggle", 
	Default = customTheme.ToggleAccent, 
	Callback = function(c) Window:SetTheme({ ToggleAccent = c }) end, 
	Flag = "ToggleColor" 
})

UI:AddColorPicker({ 
	Name = "Tab Selected", 
	Default = customTheme.TabSelected, 
	Callback = function(c) Window:SetTheme({ TabSelected = c }) end, 
	Flag = "TabSelectedColor" 
})

UI:AddColorPicker({ 
	Name = "Tab Unselected", 
	Default = customTheme.TabUnselected, 
	Callback = function(c) Window:SetTheme({ TabUnselected = c }) end, 
	Flag = "TabUnselectedColor" 
})

UI:AddColorPicker({ 
	Name = "Header", 
	Default = customTheme.Header, 
	Callback = function(c) Window:SetTheme({ Header = c }) end, 
	Flag = "HeaderColor" 
})

UI:AddColorPicker({ 
	Name = "Panel", 
	Default = customTheme.Panel, 
	Callback = function(c) Window:SetTheme({ Panel = c }) end, 
	Flag = "PanelColor" 
})

UI:AddColorPicker({ 
	Name = "Field", 
	Default = customTheme.Field, 
	Callback = function(c) Window:SetTheme({ Field = c }) end, 
	Flag = "FieldColor" 
})

UI:AddColorPicker({ 
	Name = "Stroke", 
	Default = customTheme.Stroke, 
	Callback = function(c) Window:SetTheme({ Stroke = c }) end, 
	Flag = "StrokeColor" 
})

UI:AddColorPicker({ 
	Name = "Text Dim", 
	Default = customTheme.TextDim, 
	Callback = function(c) Window:SetTheme({ TextDim = c }) end, 
	Flag = "TextDimColor" 
})

UI:AddColorPicker({ 
	Name = "Warning", 
	Default = customTheme.Warning, 
	Callback = function(c) Window:SetTheme({ Warning = c }) end, 
	Flag = "WarningColor" 
})

UI:AddColorPicker({ 
	Name = "Shadow", 
	Default = customTheme.Shadow, 
	Callback = function(c) Window:SetTheme({ Shadow = c }) end, 
	Flag = "ShadowColor" 
})

UI:AddColorPicker({ 
	Name = "Profile Stroke", 
	Default = customTheme.ProfileStroke, 
	Callback = function(c) Window:SetTheme({ ProfileStroke = c }) end, 
	Flag = "ProfileStrokeColor" 
})

UI:AddColorPicker({ 
	Name = "Logo Text", 
	Default = customTheme.LogoText, 
	Callback = function(c) Window:SetTheme({ LogoText = c }) end, 
	Flag = "LogoTextColor" 
})

UI:AddColorPicker({ 
	Name = "Username Text", 
	Default = customTheme.UsernameText, 
	Callback = function(c) Window:SetTheme({ UsernameText = c }) end, 
	Flag = "UsernameTextColor" 
})

print("[RAY] Loaded!")
