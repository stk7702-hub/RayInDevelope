local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/stk7702-hub/Uilibrary/refs/heads/main/library.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local TextChatService = game:GetService("TextChatService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
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
	Tau = 0.15,
}

local Trigger = {
	Enabled = false,
	Active = false,
	Connection = nil,
	LastShot = 0,
	Delay = 0.05,
	MinDelay = 0.05,
	LastTarget = nil,
	HasShotTarget = false,
	LastGun = nil,
}

local PREDICTION_BASE = 0.095
local PREDICTION_TAU = 0.15
local SERVER_TICK_INTERVAL = 1/60
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
	ShowTriggerFOV = true,
	CameraLockFOVColor = Color3.fromRGB(255, 255, 255),
	SilentFOVColor = Color3.fromRGB(0, 255, 255),
	TriggerFOVColor = Color3.fromRGB(255, 165, 0),
	LockedColor = Color3.fromRGB(255, 70, 70),
	CameraLockCircle = nil,
	SilentCircle = nil,
	TriggerCircle = nil,
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

local isMouseHeld = false
local silentHoldConnection = nil
local silentSpeedFixConnection = nil
local savedWalkSpeed = 16

local NO_HOLD_FIRE_WEAPONS = {
	["GLOCK"] = true,
	["SILENCER"] = true,
	["DOUBLE BARREL"] = true,
	["SHOTGUN"] = true,
	["TACTICAL SHOTGUN"] = true,
	["REVOLVER"] = true,
	["AUG"] = true,
}

local NO_SILENT_WEAPONS = {
	["GRENADE"] = true,
	["RPG"] = true,
	["FLAMETHROWER"] = true,
}

local MELEE_WEAPONS = {
	["PITCHFORK"] = true,
	["KNIFE"] = true,
	["BAT"] = true,
	["STOP SIGN"] = true,
	["SHOVEL"] = true,
	["SLEDGEHAMMER"] = true,
	["KICKBOXING"] = true,
	["BOXING"] = true,
}

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

local infiniteZoomEnabled = false
local defaultMaxZoom = 128
local defaultMinZoom = 0.5

local chatSpyEnabled = false
local chatSpyInstance = 0
local chatSpyConnections = {}
local chatSpyUI = nil
local chatSpyFrame = nil
local chatSpyScrollFrame = nil
local chatSpyMessages = {}
local maxChatSpyMessages = 100
local chatSpyMinimized = false
local spyOnMyself = false

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

local function getCurrentTarget()
	if CameraLock.Active and CameraLock.CurrentTarget then
		return CameraLock.CurrentTarget
	end
	if Silent.Active and Silent.CurrentTarget then
		return Silent.CurrentTarget
	end
	return nil
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

local function PredictPositionSilent(character, hitbox)
	if not hitbox then return nil end
	local useResolver = Silent.Resolver
	local jumpOffset = Silent.JumpOffset
	local velocity, acceleration = GetSmoothedVelocity(character, useResolver)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		local ping = GetPing()
		local t_net = (ping / 1000) / 2
		return hitbox.Position + velocity * t_net
	end
	local targetPos = hitbox.Position
	local ping = GetPing()
	local t_net = (ping / 1000) / 2
	local t_tick = SERVER_TICK_INTERVAL / 2
	local t_proj
	if Silent.AutoPrediction then
		local divisor = Silent.AutoPredictionDivisor or 250
		t_proj = PREDICTION_BASE + (ping / divisor) * 0.1
	else
		t_proj = PREDICTION_BASE
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

local function IsCharacterAlive(character)
	if not character or not character.Parent then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	if humanoid.Health <= 0 then return false end
	local bodyEffects = character:FindFirstChild("BodyEffects")
	if bodyEffects then
		local ko = bodyEffects:FindFirstChild("K.O")
		if ko and ko.Value then return false end
		local dead = bodyEffects:FindFirstChild("Dead")
		if dead and dead.Value then return false end
	end
	return true
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

local function IsMeleeWeapon(gun)
	if not gun then return false end
	local gunName = gun.Name:upper()
	return MELEE_WEAPONS[gunName] == true
end

local function CanHoldFire(gun)
	if not gun then return false end
	local gunName = gun.Name:upper()
	return NO_HOLD_FIRE_WEAPONS[gunName] ~= true
end

local function IsNoSilentWeapon(gun)
	if not gun then return false end
	local gunName = gun.Name:upper()
	return NO_SILENT_WEAPONS[gunName] == true
end

local function CanShootSilent()
	local char, hum = GetCharacterParts()
	if not char or not hum then return false, nil end
	local gun = GetEquippedGun()
	if not gun then return false, nil end
	if IsMeleeWeapon(gun) then return false, nil end
	if IsNoSilentWeapon(gun) then return false, nil end
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

local function StartSpeedFix()
	if silentSpeedFixConnection then return end
	local char, hum = GetCharacterParts()
	if hum then
		savedWalkSpeed = hum.WalkSpeed
	end
	silentSpeedFixConnection = RunService.Heartbeat:Connect(function()
		if not Silent.Active then return end
		local character, humanoid = GetCharacterParts()
		if not humanoid then return end
		if humanoid.WalkSpeed < savedWalkSpeed and not walkSpeedEnabled then
			humanoid.WalkSpeed = savedWalkSpeed
		end
	end)
end

local function StopSpeedFix()
	if silentSpeedFixConnection then
		silentSpeedFixConnection:Disconnect()
		silentSpeedFixConnection = nil
	end
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
	if not CanHoldFire(gun) then return end
	local canShootResult = CanShootSilent()
	if not canShootResult then return end
	local target = GetTarget(Silent.FOV, true, true)
	if target then
		FireModifiedShot(target)
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
	StartSpeedFix()
end

local function DisableSilent()
	if not Silent.Active then return end
	Silent.Active = false
	Silent.CurrentTarget = nil
	isMouseHeld = false
	UnblockGunInput()
	StopSpeedFix()
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

local function GetTriggerTarget()
	local myChar = LocalPlayer.Character
	if not myChar then return nil end
	
	-- Если сайлент активен, используем его цель или его FOV логику
	if Silent.Active then
		-- Сначала проверяем, есть ли уже цель у сайлента
		if Silent.CurrentTarget then
			local targetChar = Silent.CurrentTarget.Character
			if targetChar and IsCharacterAlive(targetChar) then
				return Silent.CurrentTarget
			end
		end
		-- Если нет, ищем через FOV сайлента
		return GetTarget(Silent.FOV, true, true)
	end
	
	-- Когда сайлент не активен - используем raycast под курсором
	local mouse = LocalPlayer:GetMouse()
	local ray = Camera:ScreenPointToRay(mouse.X, mouse.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {myChar, Camera, workspace:FindFirstChild("Bush"), workspace:FindFirstChild("Ignored")}
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	
	if result and result.Instance then
		local hit = result.Instance
		local targetPlayer = Players:GetPlayerFromCharacter(hit.Parent) or Players:GetPlayerFromCharacter(hit.Parent.Parent)
		if targetPlayer and targetPlayer ~= LocalPlayer then
			local targetChar = targetPlayer.Character
			if targetChar and IsCharacterAlive(targetChar) then
				return targetPlayer
			end
		end
	end
	return nil
end

local function GetWeaponFireRate(gun)
	if not gun then return 0.1 end
	local fireRate = gun:FindFirstChild("FireRate")
	if fireRate and fireRate:IsA("NumberValue") then
		return math.max(fireRate.Value, 0.05)
	end
	-- Дефолтные значения для известного оружия
	local gunName = gun.Name:upper()
	local defaultRates = {
		["GLOCK"] = 0.15,
		["SILENCER"] = 0.15,
		["DOUBLE BARREL"] = 0.8,
		["SHOTGUN"] = 0.6,
		["TACTICAL SHOTGUN"] = 0.4,
		["REVOLVER"] = 0.5,
		["AUG"] = 0.1,
		["AK47"] = 0.1,
		["AR"] = 0.1,
		["SMG"] = 0.08,
		["UZI"] = 0.07,
		["TEC9"] = 0.07,
		["LMG"] = 0.09,
		["RIFLE"] = 0.12,
	}
	return defaultRates[gunName] or 0.1
end

local function TriggerShoot()
	-- Проверка задержки между выстрелами
	local currentTime = tick()
	if currentTime - Trigger.LastShot < Trigger.Delay then
		return
	end
	
	local target = GetTriggerTarget()
	
	-- Получаем оружие в зависимости от состояния сайлента
	local gun = nil
	if Silent.Active then
		local canShootResult, gunResult = CanShootSilent()
		if not canShootResult or not gunResult then 
			-- Если не можем стрелять, сбрасываем состояние если цель изменилась
			if target ~= Trigger.LastTarget then
				Trigger.HasShotTarget = false
				Trigger.LastTarget = target
			end
			return 
		end
		gun = gunResult
	else
		local canShootResult, gunResult = CanShoot()
		if not canShootResult or not gunResult then 
			-- Если не можем стрелять, сбрасываем состояние если цель изменилась
			if target ~= Trigger.LastTarget then
				Trigger.HasShotTarget = false
				Trigger.LastTarget = target
			end
			return 
		end
		gun = gunResult
	end
	
	-- Сбрасываем флаг если цель сменилась или стала nil
	if target ~= Trigger.LastTarget then
		Trigger.HasShotTarget = false
		Trigger.LastTarget = target
	end
	
	-- Сбрасываем флаг если оружие сменилось
	if gun ~= Trigger.LastGun then
		Trigger.HasShotTarget = false
		Trigger.LastGun = gun
	end
	
	-- Если нет цели, выходим (состояние уже сброшено выше)
	if not target then
		return
	end
	
	-- Для полуавтоматического оружия проверяем, не стреляли ли мы уже по этой цели
	local isSemiAuto = not CanHoldFire(gun)
	if isSemiAuto and Trigger.HasShotTarget and target == Trigger.LastTarget then
		-- Уже стреляли по этой цели полуавтоматом, пропускаем
		return
	end
	
	-- Устанавливаем задержку на основе скорострельности оружия
	local fireRate = GetWeaponFireRate(gun)
	Trigger.Delay = math.max(fireRate + 0.02, Trigger.MinDelay)
	
	local shotSuccess = false
	
	if Silent.Active then
		-- Когда сайлент активен, используем его логику выстрела
		if FireModifiedShot(target) then
			Trigger.LastShot = currentTime
			shotSuccess = true
		end
	else
		-- Когда сайлент не активен, используем обычный клик
		pcall(function()
			if mouse1click then
				mouse1click()
				Trigger.LastShot = currentTime
				shotSuccess = true
			end
		end)
	end
	
	-- После успешного выстрела обновляем состояние
	if shotSuccess then
		Trigger.LastTarget = target
		Trigger.LastGun = gun
		-- Для полуавтомата устанавливаем флаг, что уже стреляли по этой цели
		if isSemiAuto then
			Trigger.HasShotTarget = true
		else
			-- Для автоматического оружия сбрасываем флаг, чтобы стрелять непрерывно
			Trigger.HasShotTarget = false
		end
	end
end

local function StartTrigger()
	if Trigger.Connection then return end
	Trigger.LastShot = 0
	-- Сбрасываем состояние при старте
	Trigger.LastTarget = nil
	Trigger.HasShotTarget = false
	Trigger.LastGun = nil
	
	Trigger.Connection = RunService.RenderStepped:Connect(function()
		if not Trigger.Active then return end
		if menuOpen then return end
		
		-- Не стрелять если уже держим мышку (сайлент сам стреляет)
		if Silent.Active and isMouseHeld then return end
		
		TriggerShoot()
	end)
end

local function StopTrigger()
	if Trigger.Connection then
		Trigger.Connection:Disconnect()
		Trigger.Connection = nil
	end
	-- Сбрасываем состояние триггербота
	Trigger.LastTarget = nil
	Trigger.HasShotTarget = false
	Trigger.LastGun = nil
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
	if not ESP.TriggerCircle then
		ESP.TriggerCircle = Drawing.new("Circle")
		ESP.TriggerCircle.Thickness = 1
		ESP.TriggerCircle.NumSides = 64
		ESP.TriggerCircle.Filled = false
		ESP.TriggerCircle.Visible = false
		ESP.TriggerCircle.Transparency = 0.7
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
	if ESP.TriggerCircle then
		-- Триггер работает через raycast или FOV сайлента
		ESP.TriggerCircle.Visible = false
	end
end

CreateFOVCircles()

RunService.RenderStepped:Connect(function()
	pcall(UpdateFOVCircles)
end)

local function enableInfiniteZoom()
	defaultMaxZoom = LocalPlayer.CameraMaxZoomDistance
	defaultMinZoom = LocalPlayer.CameraMinZoomDistance
	LocalPlayer.CameraMaxZoomDistance = 9999
	LocalPlayer.CameraMinZoomDistance = 0.5
end

local function disableInfiniteZoom()
	LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
	LocalPlayer.CameraMinZoomDistance = defaultMinZoom
end

local function createChatSpyUI()
	if chatSpyUI then
		chatSpyUI:Destroy()
	end
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ChatSpyUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999
	
	pcall(function()
		screenGui.Parent = CoreGui
	end)
	if not screenGui.Parent then
		screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	
	chatSpyUI = screenGui
	
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 350, 0, 300)
	mainFrame.Position = UDim2.new(1, -370, 0.5, -150)
	mainFrame.BackgroundColor3 = customTheme.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = mainFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = customTheme.Accent
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = mainFrame
	
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0, -15, 0, -15)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6014261993"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.ZIndex = -1
	shadow.Parent = mainFrame
	
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 35)
	header.BackgroundColor3 = customTheme.Header
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = header
	
	local headerFix = Instance.new("Frame")
	headerFix.Name = "HeaderFix"
	headerFix.Size = UDim2.new(1, 0, 0, 10)
	headerFix.Position = UDim2.new(0, 0, 1, -10)
	headerFix.BackgroundColor3 = customTheme.Header
	headerFix.BorderSizePixel = 0
	headerFix.Parent = header
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -80, 1, 0)
	title.Position = UDim2.new(0, 12, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🔍 Chat Spy"
	title.TextColor3 = customTheme.Accent
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	local statusDot = Instance.new("Frame")
	statusDot.Name = "StatusDot"
	statusDot.Size = UDim2.new(0, 8, 0, 8)
	statusDot.Position = UDim2.new(0, 95, 0.5, -4)
	statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	statusDot.BorderSizePixel = 0
	statusDot.Parent = header
	
	local statusDotCorner = Instance.new("UICorner")
	statusDotCorner.CornerRadius = UDim.new(1, 0)
	statusDotCorner.Parent = statusDot
	
	local msgCount = Instance.new("TextLabel")
	msgCount.Name = "MsgCount"
	msgCount.Size = UDim2.new(0, 50, 1, 0)
	msgCount.Position = UDim2.new(1, -120, 0, 0)
	msgCount.BackgroundTransparency = 1
	msgCount.Text = "0"
	msgCount.TextColor3 = customTheme.TextDim
	msgCount.TextSize = 12
	msgCount.Font = Enum.Font.Gotham
	msgCount.TextXAlignment = Enum.TextXAlignment.Right
	msgCount.Parent = header
	
	local minimizeBtn = Instance.new("TextButton")
	minimizeBtn.Name = "MinimizeBtn"
	minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
	minimizeBtn.Position = UDim2.new(1, -60, 0, 5)
	minimizeBtn.BackgroundColor3 = customTheme.Field
	minimizeBtn.BorderSizePixel = 0
	minimizeBtn.Text = "−"
	minimizeBtn.TextColor3 = customTheme.Text
	minimizeBtn.TextSize = 18
	minimizeBtn.Font = Enum.Font.GothamBold
	minimizeBtn.Parent = header
	
	local minimizeBtnCorner = Instance.new("UICorner")
	minimizeBtnCorner.CornerRadius = UDim.new(0, 4)
	minimizeBtnCorner.Parent = minimizeBtn
	
	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearBtn"
	clearBtn.Size = UDim2.new(0, 25, 0, 25)
	clearBtn.Position = UDim2.new(1, -30, 0, 5)
	clearBtn.BackgroundColor3 = customTheme.Field
	clearBtn.BorderSizePixel = 0
	clearBtn.Text = "🗑"
	clearBtn.TextColor3 = customTheme.Text
	clearBtn.TextSize = 12
	clearBtn.Font = Enum.Font.Gotham
	clearBtn.Parent = header
	
	local clearBtnCorner = Instance.new("UICorner")
	clearBtnCorner.CornerRadius = UDim.new(0, 4)
	clearBtnCorner.Parent = clearBtn
	
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -10, 1, -45)
	content.Position = UDim2.new(0, 5, 0, 40)
	content.BackgroundColor3 = customTheme.Panel
	content.BorderSizePixel = 0
	content.ClipsDescendants = true
	content.Parent = mainFrame
	
	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 6)
	contentCorner.Parent = content
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, -6, 1, -6)
	scrollFrame.Position = UDim2.new(0, 3, 0, 3)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = customTheme.Accent
	scrollFrame.ScrollBarImageTransparency = 0.3
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = content
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = scrollFrame
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 3)
	padding.PaddingBottom = UDim.new(0, 3)
	padding.PaddingLeft = UDim.new(0, 3)
	padding.PaddingRight = UDim.new(0, 3)
	padding.Parent = scrollFrame
	
	chatSpyFrame = mainFrame
	chatSpyScrollFrame = scrollFrame
	
	local dragging = false
	local dragStart = nil
	local startPos = nil
	
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end)
	
	header.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	
	minimizeBtn.MouseButton1Click:Connect(function()
		chatSpyMinimized = not chatSpyMinimized
		if chatSpyMinimized then
			TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 350, 0, 35)}):Play()
			minimizeBtn.Text = "+"
			content.Visible = false
		else
			content.Visible = true
			TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 350, 0, 300)}):Play()
			minimizeBtn.Text = "−"
		end
	end)
	
	clearBtn.MouseButton1Click:Connect(function()
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		chatSpyMessages = {}
		msgCount.Text = "0"
	end)
	
	local function addHover(button)
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = customTheme.Stroke}):Play()
		end)
		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = customTheme.Field}):Play()
		end)
	end
	
	addHover(minimizeBtn)
	addHover(clearBtn)
	
	return screenGui
end

local function addChatSpyMessage(sender, message, isHidden)
	if not chatSpyScrollFrame then return end
	
	local msgFrame = Instance.new("Frame")
	msgFrame.Name = "Message"
	msgFrame.Size = UDim2.new(1, 0, 0, 0)
	msgFrame.AutomaticSize = Enum.AutomaticSize.Y
	msgFrame.BackgroundColor3 = isHidden and Color3.fromRGB(40, 20, 20) or customTheme.Field
	msgFrame.BorderSizePixel = 0
	msgFrame.LayoutOrder = #chatSpyMessages + 1
	
	local msgCorner = Instance.new("UICorner")
	msgCorner.CornerRadius = UDim.new(0, 4)
	msgCorner.Parent = msgFrame
	
	local msgPadding = Instance.new("UIPadding")
	msgPadding.PaddingTop = UDim.new(0, 5)
	msgPadding.PaddingBottom = UDim.new(0, 5)
	msgPadding.PaddingLeft = UDim.new(0, 8)
	msgPadding.PaddingRight = UDim.new(0, 8)
	msgPadding.Parent = msgFrame
	
	local typeColor = isHidden and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
	local typeIcon = isHidden and "🔒" or "💬"
	local typeText = isHidden and "HIDDEN" or "PUBLIC"
	
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "Time"
	timeLabel.Size = UDim2.new(0, 45, 0, 14)
	timeLabel.Position = UDim2.new(0, 0, 0, 0)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = os.date("%H:%M")
	timeLabel.TextColor3 = customTheme.TextDim
	timeLabel.TextSize = 10
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = msgFrame
	
	local typeBadge = Instance.new("TextLabel")
	typeBadge.Name = "TypeBadge"
	typeBadge.Size = UDim2.new(0, 60, 0, 14)
	typeBadge.Position = UDim2.new(0, 48, 0, 0)
	typeBadge.BackgroundColor3 = typeColor
	typeBadge.BackgroundTransparency = 0.7
	typeBadge.Text = typeText
	typeBadge.TextColor3 = typeColor
	typeBadge.TextSize = 9
	typeBadge.Font = Enum.Font.GothamBold
	typeBadge.Parent = msgFrame
	
	local typeBadgeCorner = Instance.new("UICorner")
	typeBadgeCorner.CornerRadius = UDim.new(0, 3)
	typeBadgeCorner.Parent = typeBadge
	
	local senderLabel = Instance.new("TextLabel")
	senderLabel.Name = "Sender"
	senderLabel.Size = UDim2.new(1, -115, 0, 14)
	senderLabel.Position = UDim2.new(0, 115, 0, 0)
	senderLabel.BackgroundTransparency = 1
	senderLabel.Text = typeIcon .. " " .. sender
	senderLabel.TextColor3 = typeColor
	senderLabel.TextSize = 11
	senderLabel.Font = Enum.Font.GothamBold
	senderLabel.TextXAlignment = Enum.TextXAlignment.Left
	senderLabel.TextTruncate = Enum.TextTruncate.AtEnd
	senderLabel.Parent = msgFrame
	
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageText"
	messageLabel.Size = UDim2.new(1, 0, 0, 0)
	messageLabel.Position = UDim2.new(0, 0, 0, 18)
	messageLabel.AutomaticSize = Enum.AutomaticSize.Y
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = message
	messageLabel.TextColor3 = customTheme.Text
	messageLabel.TextSize = 12
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextWrapped = true
	messageLabel.Parent = msgFrame
	
	msgFrame.Parent = chatSpyScrollFrame
	
	table.insert(chatSpyMessages, msgFrame)
	
	local msgCountLabel = chatSpyFrame:FindFirstChild("Header"):FindFirstChild("MsgCount")
	if msgCountLabel then
		msgCountLabel.Text = tostring(#chatSpyMessages)
	end
	
	if #chatSpyMessages > maxChatSpyMessages then
		local oldMsg = table.remove(chatSpyMessages, 1)
		if oldMsg then oldMsg:Destroy() end
	end
	
	task.defer(function()
		chatSpyScrollFrame.CanvasPosition = Vector2.new(0, chatSpyScrollFrame.AbsoluteCanvasSize.Y)
	end)
	
	msgFrame.BackgroundTransparency = 1
	TweenService:Create(msgFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
end

local function setupChatSpy()
	for _, conn in ipairs(chatSpyConnections) do
		pcall(function() conn:Disconnect() end)
	end
	chatSpyConnections = {}
	
	createChatSpyUI()
	
	chatSpyInstance = chatSpyInstance + 1
	local currentInstance = chatSpyInstance
	
	local saymsg = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
	local getmsg = saymsg and saymsg:FindFirstChild("OnMessageDoneFiltering")
	
	if not getmsg then
		pcall(function()
			saymsg = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 5)
			if saymsg then
				getmsg = saymsg:WaitForChild("OnMessageDoneFiltering", 5)
			end
		end)
	end
	
	local function onChatted(player, msg)
		if currentInstance ~= chatSpyInstance then return end
		if not chatSpyEnabled then return end
		if not spyOnMyself and player == LocalPlayer then return end
		
		msg = msg:gsub("[\n\r]", ''):gsub("\t", ' '):gsub("[ ]+", ' ')
		
		local hidden = true
		
		if getmsg then
			local conn
			conn = getmsg.OnClientEvent:Connect(function(packet, channel)
				if packet.SpeakerUserId == player.UserId then
					if packet.Message == msg:sub(#msg - #packet.Message + 1) then
						if channel == "All" then
							hidden = false
						elseif channel == "Team" then
							local teamPlayer = Players:FindFirstChild(packet.FromSpeaker)
							if teamPlayer and teamPlayer.Team == LocalPlayer.Team then
								hidden = false
							end
						end
					end
				end
			end)
			
			task.wait(1)
			conn:Disconnect()
		end
		
		if chatSpyEnabled and currentInstance == chatSpyInstance then
			addChatSpyMessage(player.Name, msg, hidden)
			
			if hidden then
				pcall(function()
					StarterGui:SetCore("ChatMakeSystemMessage", {
						Text = "[SPY] " .. player.Name .. ": " .. msg,
						Color = Color3.fromRGB(255, 200, 0),
						Font = Enum.Font.SourceSansBold,
						TextSize = 18
					})
				end)
			end
		end
	end
	
	for _, player in ipairs(Players:GetPlayers()) do
		local conn = player.Chatted:Connect(function(msg)
			onChatted(player, msg)
		end)
		table.insert(chatSpyConnections, conn)
	end
	
	local playerAddedConn = Players.PlayerAdded:Connect(function(player)
		local conn = player.Chatted:Connect(function(msg)
			onChatted(player, msg)
		end)
		table.insert(chatSpyConnections, conn)
	end)
	table.insert(chatSpyConnections, playerAddedConn)
	
	pcall(function()
		local channels = TextChatService:FindFirstChild("TextChannels")
		if channels then
			local function connectChannel(channel)
				if not channel:IsA("TextChannel") then return end
				local conn = channel.MessageReceived:Connect(function(msg)
					if not chatSpyEnabled then return end
					if currentInstance ~= chatSpyInstance then return end
					
					pcall(function()
						if msg.TextSource then
							local player = Players:GetPlayerByUserId(msg.TextSource.UserId)
							if player and (spyOnMyself or player ~= LocalPlayer) then
								local channelName = channel.Name
								if channelName ~= "RBXGeneral" and channelName ~= "RBXSystem" then
									addChatSpyMessage(player.Name .. " [" .. channelName .. "]", msg.Text, true)
								end
							end
						end
					end)
				end)
				table.insert(chatSpyConnections, conn)
			end
			
			for _, channel in pairs(channels:GetChildren()) do
				connectChannel(channel)
			end
			
			local addedConn = channels.ChildAdded:Connect(function(channel)
				task.wait(0.1)
				connectChannel(channel)
			end)
			table.insert(chatSpyConnections, addedConn)
		end
	end)
	
	addChatSpyMessage("SYSTEM", "Chat Spy enabled - monitoring messages...", false)
end

local function cleanupChatSpy()
	for _, conn in ipairs(chatSpyConnections) do
		pcall(function() conn:Disconnect() end)
	end
	chatSpyConnections = {}
	
	if chatSpyUI then
		chatSpyUI:Destroy()
		chatSpyUI = nil
		chatSpyFrame = nil
		chatSpyScrollFrame = nil
	end
	
	chatSpyMessages = {}
end

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
	cleanupChatSpy()
	StopTrigger()
end

local function onCharacterAdded(character)
	isResetting = true
	cleanupFly()
	cleanupCFrameSpeed()
	cleanupWalkSpeed()
	cleanupJumpPower()
	stop360Spin()
	stopFellLoop()
	disableNoclip()
	disableAntiFling()
	StopTrigger()
	isMouseHeld = false
	if Silent.Active then
		UnblockGunInput()
		Silent.BlockedConnections = {}
	end
	previousPositions = {}
	smoothedVelocities = {}
	lastUpdateTimes = {}
	accelerationCache = {}
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
	if infiniteZoomEnabled then
		enableInfiniteZoom()
	end
	if Trigger.Active then
		StartTrigger()
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
		cleanupFly()
		cleanupCFrameSpeed()
		cleanupWalkSpeed()
		cleanupJumpPower()
		stop360Spin()
		stopFellLoop()
		disableNoclip()
		disableAntiFling()
		StopTrigger()
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

local TriggerSection = Legit:AddSection({ Name = "Triggerbot", Side = "right", ShowTitle = true, Height = 0 })

local TriggerToggle = TriggerSection:AddToggle({
	Name = "Enabled",
	Default = false,
	Option = true,
	Callback = function(v)
		Trigger.Active = v
		if v then
			StartTrigger()
		else
			StopTrigger()
		end
	end,
	Flag = "TriggerEnabled"
})

if TriggerToggle.Option then
	TriggerToggle.Option:AddKeybind({
		Name = "Keybind",
		Default = nil,
		Callback = function() end,
		Flag = "TriggerKeybind"
	})
end

TriggerSection:AddSlider({
	Name = "Min Delay",
	Type = "ms",
	Default = 50,
	Min = 0,
	Max = 200,
	Round = 0,
	Callback = function(v) 
		Trigger.MinDelay = v / 1000
	end,
	Flag = "TriggerMinDelay"
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

Character:AddToggle({
	Name = "Infinite Zoom",
	Default = false,
	Option = false,
	Callback = function(enabled)
		infiniteZoomEnabled = enabled
		if enabled then
			enableInfiniteZoom()
		else
			disableInfiniteZoom()
		end
	end,
	Flag = "InfiniteZoomEnabled"
})

Character:AddToggle({
	Name = "Chat Spy",
	Default = false,
	Option = false,
	Callback = function(enabled)
		chatSpyEnabled = enabled
		if enabled then
			setupChatSpy()
		else
			cleanupChatSpy()
		end
	end,
	Flag = "ChatSpyEnabled"
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
