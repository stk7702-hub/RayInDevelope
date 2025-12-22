-- =====================================================
-- RAY SCRIPT - OOP REWRITE (SECURE VERSION)
-- =====================================================

local Fatality = loadstring(game:HttpGet("https://raw.githubusercontent.com/stk7702-hub/Uilibrary/refs/heads/main/library.lua"))()

-- =====================================================
-- SERVICES (LOCAL)
-- =====================================================
local Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	TweenService = game:GetService("TweenService"),
	Stats = game:GetService("Stats"),
	TextChatService = game:GetService("TextChatService"),
	CoreGui = game:GetService("CoreGui"),
	StarterGui = game:GetService("StarterGui"),
	Workspace = game:GetService("Workspace"),
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local MainEvent = Services.ReplicatedStorage:WaitForChild("MainEvent")

-- =====================================================
-- CONFIG (LOCAL)
-- =====================================================
local Config = {
	Theme = {
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
		LogoStroke = Color3.fromRGB(205, 67, 218),
		UsernameText = Color3.fromRGB(255, 255, 255),
		DropdownSelected = Color3.fromRGB(255, 106, 133),
	},
	
	Weapons = {
		NoHoldFire = {
			["GLOCK"] = true, ["SILENCER"] = true, ["DOUBLE BARREL"] = true,
			["SHOTGUN"] = true, ["TACTICAL SHOTGUN"] = true, ["REVOLVER"] = true, ["AUG"] = true,
		},
		NoSilent = {
			["GRENADE"] = true, ["RPG"] = true, ["FLAMETHROWER"] = true,
		},
		Melee = {
			["PITCHFORK"] = true, ["KNIFE"] = true, ["BAT"] = true, ["STOP SIGN"] = true,
			["SHOVEL"] = true, ["SLEDGEHAMMER"] = true, ["KICKBOXING"] = true, ["BOXING"] = true,
		},
		FireRates = {
			["GLOCK"] = 0.15, ["SILENCER"] = 0.15, ["DOUBLE BARREL"] = 0.8,
			["SHOTGUN"] = 0.6, ["TACTICAL SHOTGUN"] = 0.4, ["REVOLVER"] = 0.5,
			["AUG"] = 0.1, ["AK47"] = 0.1, ["AR"] = 0.1, ["SMG"] = 0.08,
			["UZI"] = 0.07, ["TEC9"] = 0.07, ["LMG"] = 0.09, ["RIFLE"] = 0.12,
		},
		Combat = {"Combat", "[BOXING]", "[KICKBOXING]", "Fists", "Brass Knuckles", "[COMBAT]"},
	},
	
	Prediction = {
		Base = 0.095,
		Tau = 0.15,
		ServerTick = 1/60,
		MaxVelocity = 150,
		JumpMultiplier = 1.0,
	},
	
	Speed = {
		FlyMin = 0.5, FlyMax = 5,
		CFrameMin = 0.1, CFrameMax = 2,
	},
}

-- =====================================================
-- UTILS MODULE (LOCAL)
-- =====================================================
local Utils = {}

function Utils.GetCharacterParts(player)
	player = player or LocalPlayer
	local character = player.Character
	if not character then return nil, nil, nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil, nil, nil end
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("LowerTorso")
	if not rootPart then return nil, nil, nil end
	return character, humanoid, rootPart
end

function Utils.GetMousePosition()
	return Services.UserInputService:GetMouseLocation()
end

function Utils.WorldToScreen(position)
	local screenPos, onScreen = Camera:WorldToViewportPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

function Utils.GetDistanceFromCrosshair(position)
	local screenPos, onScreen = Utils.WorldToScreen(position)
	if not onScreen then return math.huge end
	return (screenPos - Utils.GetMousePosition()).Magnitude
end

function Utils.GetWorldDistance(fromPos, toPos)
	return (fromPos - toPos).Magnitude
end

function Utils.IsVisible(origin, targetPart)
	if not targetPart then return false end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {
		LocalPlayer.Character, Camera,
		workspace:FindFirstChild("Bush"),
		workspace:FindFirstChild("Ignored"),
	}
	local direction = (targetPart.Position - origin)
	local result = workspace:Raycast(origin, direction, rayParams)
	if not result then return true end
	local targetChar = targetPart:FindFirstAncestorOfClass("Model")
	return targetChar and result.Instance:IsDescendantOf(targetChar)
end

function Utils.IsCharacterAlive(character)
	if not character or not character.Parent then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	local bodyEffects = character:FindFirstChild("BodyEffects")
	if bodyEffects then
		local ko = bodyEffects:FindFirstChild("K.O")
		if ko and ko.Value then return false end
		local dead = bodyEffects:FindFirstChild("Dead")
		if dead and dead.Value then return false end
	end
	return true
end

function Utils.GetHitboxPart(character, hitboxName)
	if not character then return nil end
	hitboxName = hitboxName or "Head"
	
	if hitboxName == "Nearest" then
		local mousePos = Utils.GetMousePosition()
		local parts = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}
		local closestPart, closestDist = nil, math.huge
		for _, partName in ipairs(parts) do
			local part = character:FindFirstChild(partName)
			if part then
				local screenPos, onScreen = Utils.WorldToScreen(part.Position)
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

function Utils.CalculateFlySpeed(sliderValue)
	return Config.Speed.FlyMin + (sliderValue / 100) * (Config.Speed.FlyMax - Config.Speed.FlyMin)
end

function Utils.CalculateCFrameSpeed(sliderValue)
	return Config.Speed.CFrameMin + (sliderValue / 100) * (Config.Speed.CFrameMax - Config.Speed.CFrameMin)
end

function Utils.CalculateSmoothAlpha(deltaTime, tau)
	return 1 - math.exp(-deltaTime / tau)
end

-- =====================================================
-- AIMBOT MODULE (LOCAL)
-- =====================================================
local Aimbot = {
	Enabled = false,
	VisibleCheck = false,
	Hitbox = "Head",
	
	CameraLock = {
		Active = false,
		FOV = 100,
		Smoothness = 0.1,
		Prediction = 0.1,
		CurrentTarget = nil,
		Connection = nil,
		LastTime = 0,
	},
	
	Silent = {
		Enabled = false,
		FOV = 100,
		CurrentTarget = nil,
		Resolver = false,
		JumpOffset = 0,
		AutoPrediction = false,
		AutoPredictionDivisor = 250,
		Tau = 0.15,
		UpdateConnection = nil,
		HooksSetup = false,
	},
	
	Trigger = {
		Active = false,
		Connection = nil,
		LastShot = 0,
		Delay = 0.05,
		MinDelay = 0.05,
		LastTarget = nil,
		HasShotTarget = false,
		LastGun = nil,
	},
	
	Cache = {
		Ping = 100,
		PreviousPositions = {},
		SmoothedVelocities = {},
		LastUpdateTimes = {},
		Acceleration = {},
	},
	
	ESP = {
		ShowCameraLockFOV = true,
		ShowSilentFOV = true,
		CameraLockFOVColor = Color3.fromRGB(255, 255, 255),
		SilentFOVColor = Color3.fromRGB(0, 255, 255),
		LockedColor = Color3.fromRGB(255, 70, 70),
		CameraLockCircle = nil,
		SilentCircle = nil,
	},
}

function Aimbot:GetPing()
	return self.Cache.Ping
end

function Aimbot:UpdatePing()
	task.spawn(function()
		while true do
			local success, ping = pcall(function()
				return Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			if success and ping then
				self.Cache.Ping = ping
			end
			task.wait(0.5)
		end
	end)
end

function Aimbot:GetSmoothedVelocity(character, useResolver)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return Vector3.zero, Vector3.zero end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local player = Services.Players:GetPlayerFromCharacter(character)
	local tau = self.Silent.Tau or Config.Prediction.Tau
	
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
		if velocity.Magnitude > Config.Prediction.MaxVelocity then
			velocity = velocity.Unit * Config.Prediction.MaxVelocity
		end
		return velocity, Vector3.zero
	end
	
	local currentTime = tick()
	local currentPos = rootPart.Position
	local lastPos = self.Cache.PreviousPositions[player] or currentPos
	local lastTime = self.Cache.LastUpdateTimes[player] or (currentTime - 0.016)
	local deltaTime = math.max(currentTime - lastTime, 0.001)
	
	local rawVelocity = (currentPos - lastPos) / deltaTime
	if rawVelocity.Magnitude > Config.Prediction.MaxVelocity then
		rawVelocity = rawVelocity.Unit * Config.Prediction.MaxVelocity
	end
	
	local alpha = Utils.CalculateSmoothAlpha(deltaTime, tau)
	local prevSmoothed = self.Cache.SmoothedVelocities[player] or rawVelocity
	local smoothed = prevSmoothed:Lerp(rawVelocity, alpha)
	
	local prevVelocity = self.Cache.SmoothedVelocities[player] or smoothed
	local rawAccel = (smoothed - prevVelocity) / deltaTime
	local prevAccel = self.Cache.Acceleration[player] or rawAccel
	local accelAlpha = Utils.CalculateSmoothAlpha(deltaTime, tau * 2)
	local smoothedAccel = prevAccel:Lerp(rawAccel, accelAlpha)
	
	self.Cache.Acceleration[player] = smoothedAccel
	self.Cache.SmoothedVelocities[player] = smoothed
	self.Cache.PreviousPositions[player] = currentPos
	self.Cache.LastUpdateTimes[player] = currentTime
	
	return smoothed, smoothedAccel
end

function Aimbot:GetJumpOffset(character, baseOffset)
	if baseOffset == 0 then return 0 end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return 0 end
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
		return baseOffset * Config.Prediction.JumpMultiplier
	end
	return 0
end

function Aimbot:PredictPositionSilent(character, hitbox)
	if not hitbox then return nil end
	
	local velocity, acceleration = self:GetSmoothedVelocity(character, self.Silent.Resolver)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	
	local ping = self:GetPing()
	local t_net = (ping / 1000) / 2
	
	if not myRoot then
		return hitbox.Position + velocity * t_net
	end
	
	local targetPos = hitbox.Position
	local t_tick = Config.Prediction.ServerTick / 2
	local t_proj
	
	if self.Silent.AutoPrediction then
		local divisor = self.Silent.AutoPredictionDivisor or 250
		t_proj = Config.Prediction.Base + (ping / divisor) * 0.1
	else
		t_proj = Config.Prediction.Base
	end
	
	local t = t_net + t_tick + t_proj
	local yOffset = self:GetJumpOffset(character, self.Silent.JumpOffset)
	
	return targetPos + (velocity * t) + (acceleration * 0.5 * t * t) + Vector3.new(0, yOffset, 0)
end

function Aimbot:PredictPosition(character, hitbox, prediction)
	if not hitbox then return nil end
	if prediction <= 0 then return hitbox.Position end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		return hitbox.Position + (rootPart.AssemblyLinearVelocity * prediction)
	end
	return hitbox.Position
end

function Aimbot:GetTarget(fov, useVisibleCheck, forSilent)
	if not self.Enabled then return nil end
	local myChar, myHum, myRoot = Utils.GetCharacterParts()
	if not myRoot then return nil end
	
	local bestTarget, bestScore = nil, math.huge
	
	for _, player in ipairs(Services.Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		local char, hum = Utils.GetCharacterParts(player)
		if not char or not hum then continue end
		
		local bodyEffects = char:FindFirstChild("BodyEffects")
		if bodyEffects then
			local ko = bodyEffects:FindFirstChild("K.O")
			if ko and ko.Value then continue end
			local dead = bodyEffects:FindFirstChild("Dead")
			if dead and dead.Value then continue end
		end
		
		local hitbox = Utils.GetHitboxPart(char, self.Hitbox)
		if not hitbox then continue end
		
		local crosshairDist = Utils.GetDistanceFromCrosshair(hitbox.Position)
		if crosshairDist > fov then continue end
		
		if useVisibleCheck or forSilent then
			if not Utils.IsVisible(Camera.CFrame.Position, hitbox) then continue end
		end
		
		local worldDist = Utils.GetWorldDistance(myRoot.Position, hitbox.Position)
		local score = (crosshairDist * 0.7) + (worldDist * 0.3)
		
		if score < bestScore then
			bestScore = score
			bestTarget = player
		end
	end
	
	return bestTarget
end

function Aimbot:GetEquippedGun()
	local char = LocalPlayer.Character
	if not char then return nil end
	local tool = char:FindFirstChildWhichIsA("Tool")
	if not tool then return nil end
	if not tool:FindFirstChild("Handle") then return nil end
	if not tool:FindFirstChild("RemoteEvent") then return nil end
	if not tool:FindFirstChild("Ammo") then return nil end
	return tool
end

function Aimbot:IsMeleeWeapon(gun)
	if not gun then return false end
	return Config.Weapons.Melee[gun.Name:upper()] == true
end

function Aimbot:CanHoldFire(gun)
	if not gun then return false end
	return Config.Weapons.NoHoldFire[gun.Name:upper()] ~= true
end

function Aimbot:IsNoSilentWeapon(gun)
	if not gun then return false end
	return Config.Weapons.NoSilent[gun.Name:upper()] == true
end

function Aimbot:GetWeaponFireRate(gun)
	if not gun then return 0.1 end
	local fireRate = gun:FindFirstChild("FireRate")
	if fireRate and fireRate:IsA("NumberValue") then
		return math.max(fireRate.Value, 0.05)
	end
	return Config.Weapons.FireRates[gun.Name:upper()] or 0.1
end

function Aimbot:CanShoot(forSilent)
	local char, hum = Utils.GetCharacterParts()
	if not char or not hum then return false, nil end
	
	local gun = self:GetEquippedGun()
	if not gun then return false, nil end
	
	if forSilent then
		if self:IsMeleeWeapon(gun) then return false, nil end
		if self:IsNoSilentWeapon(gun) then return false, nil end
	end
	
	local ammo = gun:FindFirstChild("Ammo")
	if ammo and ammo.Value <= 0 then return false, nil end
	
	local bodyEffects = char:FindFirstChild("BodyEffects")
	if not bodyEffects then return false, nil end
	
	if bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value then return false, nil end
	if bodyEffects:FindFirstChild("Dead") and bodyEffects.Dead.Value then return false, nil end
	if bodyEffects:FindFirstChild("Reload") and bodyEffects.Reload.Value then return false, nil end
	
	if not forSilent then
		if bodyEffects:FindFirstChild("Cuff") and bodyEffects.Cuff.Value then return false, nil end
		if bodyEffects:FindFirstChild("Attacking") and bodyEffects.Attacking.Value then return false, nil end
		if bodyEffects:FindFirstChild("Grabbed") and bodyEffects.Grabbed.Value then return false, nil end
		if gun:GetAttribute("Cooldown") then return false, nil end
		if char:FindFirstChild("FORCEFIELD") then return false, nil end
		if not char:FindFirstChild("FULLY_LOADED_CHAR") then return false, nil end
		if char:FindFirstChild("GRABBING_CONSTRAINT") then return false, nil end
	end
	
	return true, gun
end

function Aimbot:SetupSilentHooks()
	if self.Silent.HooksSetup then return true end
	if not hookmetamethod or not getnamecallmethod then
		warn("[Silent] Hooks not available!")
		return false
	end
	
	self.Silent.HooksSetup = true
	local OriginalNamecall
	local AimbotRef = self -- Захватываем ссылку для closure
	
	OriginalNamecall = hookmetamethod(game, "__namecall", newcclosure(function(selfObj, ...)
		local method = getnamecallmethod()
		local args = {...}
		
		if method == "FireServer" and (selfObj == MainEvent or selfObj.Name == "MainEvent") and args[1] == "ShootGun" then
			if AimbotRef.Silent.Enabled and AimbotRef.Silent.CurrentTarget then
				local target = AimbotRef.Silent.CurrentTarget
				local targetChar = target and target.Character
				
				if targetChar and Utils.IsCharacterAlive(targetChar) then
					local hbox = Utils.GetHitboxPart(targetChar, AimbotRef.Hitbox)
					if hbox and Utils.IsVisible(Camera.CFrame.Position, hbox) then
						local newPos = AimbotRef:PredictPositionSilent(targetChar, hbox)
						if newPos then
							local handle, startPos, normal = args[2], args[3], args[6]
							if typeof(normal) ~= "Vector3" then normal = Vector3.new(0, 1, 0) end
							setnamecallmethod("FireServer")
							return OriginalNamecall(selfObj, "ShootGun", handle, startPos, newPos, hbox, normal)
						end
					end
				end
			end
		end
		
		return OriginalNamecall(selfObj, ...)
	end))
	
	return true
end

function Aimbot:StartSilent()
	if self.Silent.Enabled then return end
	self.Silent.Enabled = true
	
	if not self.Silent.HooksSetup then
		if not self:SetupSilentHooks() then
			self.Silent.Enabled = false
			return
		end
	end
	
	self.Silent.UpdateConnection = Services.RunService.RenderStepped:Connect(function()
		if not self.Silent.Enabled or not self.Enabled then
			self.Silent.CurrentTarget = nil
			return
		end
		self.Silent.CurrentTarget = self:GetTarget(self.Silent.FOV, true, true)
	end)
end

function Aimbot:StopSilent()
	self.Silent.Enabled = false
	if self.Silent.UpdateConnection then
		self.Silent.UpdateConnection:Disconnect()
		self.Silent.UpdateConnection = nil
	end
	self.Silent.CurrentTarget = nil
end

function Aimbot:StartCameraLock()
	if self.CameraLock.Connection then return end
	self.CameraLock.LastTime = tick()
	
	self.CameraLock.Connection = Services.RunService.RenderStepped:Connect(function()
		if not self.CameraLock.Active then return end
		
		-- Если меню открыто - не двигаем камеру, чтобы не мешать пользователю
		if menuOpen then
			self.CameraLock.CurrentTarget = nil
			return
		end
		
		local currentTime = tick()
		local deltaTime = math.clamp(currentTime - self.CameraLock.LastTime, 0.001, 0.1)
		self.CameraLock.LastTime = currentTime
		
		local target = self:GetTarget(self.CameraLock.FOV, self.VisibleCheck, false)
		self.CameraLock.CurrentTarget = target
		
		if not target or not target.Character then return end
		
		local hitbox = Utils.GetHitboxPart(target.Character, self.Hitbox)
		if not hitbox then return end
		
		local targetPos = self:PredictPosition(target.Character, hitbox, self.CameraLock.Prediction)
		if not targetPos then return end
		
		local screenPos, onScreen = Utils.WorldToScreen(targetPos)
		if not onScreen then return end
		
		local mousePos = Utils.GetMousePosition()
		local delta = screenPos - mousePos
		local distance = delta.Magnitude
		if distance < 1 then return end
		
		local smoothness = self.CameraLock.Smoothness
		local smoothFactor = smoothness <= 0.01 and 1 or (1 - smoothness) ^ 0.7
		smoothFactor = smoothFactor * (deltaTime / (1/60))
		smoothFactor = math.clamp(smoothFactor * math.clamp(distance / 200, 0.3, 1.5), 0.02, 1)
		
		local moveX = delta.X * smoothFactor
		local moveY = delta.Y * smoothFactor
		
		if mousemoverel then
			mousemoverel(moveX, moveY)
		end
	end)
end

function Aimbot:StopCameraLock()
	self.CameraLock.CurrentTarget = nil
	if self.CameraLock.Connection then
		self.CameraLock.Connection:Disconnect()
		self.CameraLock.Connection = nil
	end
end

function Aimbot:StartTrigger()
	if self.Trigger.Connection then return end
	self.Trigger.LastShot = 0
	self.Trigger.LastTarget = nil
	self.Trigger.HasShotTarget = false
	self.Trigger.LastGun = nil
	
	self.Trigger.Connection = Services.RunService.RenderStepped:Connect(function()
		if not self.Trigger.Active then return end
		
		local currentTime = tick()
		if currentTime - self.Trigger.LastShot < self.Trigger.Delay then return end
		
		local target
		if self.Silent.Enabled and self.Silent.CurrentTarget then
			target = self.Silent.CurrentTarget
		else
			target = self:GetTarget(self.Silent.FOV, true, true)
		end
		
		local canShootResult, gun = self:CanShoot(self.Silent.Enabled)
		if not canShootResult or not gun then return end
		
		if target ~= self.Trigger.LastTarget then
			self.Trigger.HasShotTarget = false
			self.Trigger.LastTarget = target
		end
		
		if gun ~= self.Trigger.LastGun then
			self.Trigger.HasShotTarget = false
			self.Trigger.LastGun = gun
		end
		
		if not target then return end
		
		local isSemiAuto = not self:CanHoldFire(gun)
		if isSemiAuto and self.Trigger.HasShotTarget then return end
		
		self.Trigger.Delay = math.max(self:GetWeaponFireRate(gun) + 0.02, self.Trigger.MinDelay)
		
		pcall(function()
			if mouse1click then mouse1click() end
		end)
		
		self.Trigger.LastShot = currentTime
		self.Trigger.HasShotTarget = isSemiAuto
	end)
end

function Aimbot:StopTrigger()
	if self.Trigger.Connection then
		self.Trigger.Connection:Disconnect()
		self.Trigger.Connection = nil
	end
end

function Aimbot:CreateFOVCircles()
	if not Drawing then return end
	
	if not self.ESP.CameraLockCircle then
		self.ESP.CameraLockCircle = Drawing.new("Circle")
		self.ESP.CameraLockCircle.Thickness = 1
		self.ESP.CameraLockCircle.NumSides = 64
		self.ESP.CameraLockCircle.Filled = false
		self.ESP.CameraLockCircle.Visible = false
		self.ESP.CameraLockCircle.Transparency = 0.7
	end
	
	if not self.ESP.SilentCircle then
		self.ESP.SilentCircle = Drawing.new("Circle")
		self.ESP.SilentCircle.Thickness = 1
		self.ESP.SilentCircle.NumSides = 64
		self.ESP.SilentCircle.Filled = false
		self.ESP.SilentCircle.Visible = false
		self.ESP.SilentCircle.Transparency = 0.7
	end
end

function Aimbot:UpdateFOVCircles()
	local mousePos = Utils.GetMousePosition()
	
	if self.ESP.CameraLockCircle then
		self.ESP.CameraLockCircle.Position = mousePos
		self.ESP.CameraLockCircle.Radius = self.CameraLock.FOV
		self.ESP.CameraLockCircle.Visible = self.ESP.ShowCameraLockFOV and self.CameraLock.Active
		self.ESP.CameraLockCircle.Color = self.CameraLock.CurrentTarget and self.ESP.LockedColor or self.ESP.CameraLockFOVColor
	end
	
	if self.ESP.SilentCircle then
		self.ESP.SilentCircle.Position = mousePos
		self.ESP.SilentCircle.Radius = self.Silent.FOV
		self.ESP.SilentCircle.Visible = self.ESP.ShowSilentFOV and self.Silent.Enabled
		self.ESP.SilentCircle.Color = self.Silent.CurrentTarget and self.ESP.LockedColor or self.ESP.SilentFOVColor
	end
end

function Aimbot:ClearCache()
	self.Cache.PreviousPositions = {}
	self.Cache.SmoothedVelocities = {}
	self.Cache.LastUpdateTimes = {}
	self.Cache.Acceleration = {}
end

-- =====================================================
-- MOVEMENT MODULE (LOCAL)
-- =====================================================
local Movement = {
	Fly = { Enabled = false, Speed = 50, Connection = nil, Active = false },
	CFrameSpeed = { Enabled = false, Value = 50, Connection = nil, Active = false },
	BunnyHop = { Enabled = false, Speed = 50, Connection = nil },
	WalkSpeed = { Enabled = false, Value = 16, Connection = nil },
	JumpPower = { Enabled = false, Value = 50, Connection = nil },
	Spin360 = { Enabled = false, Speed = 25, Connection = nil },
	FlyCar = { Enabled = false, Speed = 50, Connection = nil },
}

function Movement:StartFly()
	if self.Fly.Active then return end
	local char, hum, root = Utils.GetCharacterParts()
	if not char then return end
	
	self.Fly.Active = true
	
	if self.CFrameSpeed.Connection then
		self.CFrameSpeed.Connection:Disconnect()
		self.CFrameSpeed.Connection = nil
	end
	self.CFrameSpeed.Active = false
	
	if self.BunnyHop.Connection then
		self.BunnyHop.Connection:Disconnect()
		self.BunnyHop.Connection = nil
	end
	
	self.Fly.Connection = Services.RunService.Heartbeat:Connect(function()
		if not self.Fly.Enabled or not self.Fly.Active then return end
		local c, h, r = Utils.GetCharacterParts()
		if not c or not r then
			self:StopFly()
			return
		end
		
		local cam = workspace.CurrentCamera
		local moveDir = Vector3.zero
		local UIS = Services.UserInputService
		
		if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
		
		if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
		
		r.AssemblyLinearVelocity = Vector3.zero
		r.CFrame = r.CFrame + moveDir * Utils.CalculateFlySpeed(self.Fly.Speed)
	end)
end

function Movement:StopFly()
	self.Fly.Active = false
	if self.Fly.Connection then
		self.Fly.Connection:Disconnect()
		self.Fly.Connection = nil
	end
	
	if self.CFrameSpeed.Enabled and not self.CFrameSpeed.Active then
		self:StartCFrameSpeed()
	end
	if self.BunnyHop.Enabled and not self.BunnyHop.Connection then
		self:StartBunnyHop()
	end
end

function Movement:StartCFrameSpeed()
	if self.CFrameSpeed.Active then return end
	if self.Fly.Enabled and self.Fly.Active then return end
	
	local char = Utils.GetCharacterParts()
	if not char then return end
	
	self.CFrameSpeed.Active = true
	self.CFrameSpeed.Connection = Services.RunService.Stepped:Connect(function()
		if not self.CFrameSpeed.Enabled or not self.CFrameSpeed.Active then return end
		if self.Fly.Enabled and self.Fly.Active then
			self:StopCFrameSpeed()
			return
		end
		
		local c, h, r = Utils.GetCharacterParts()
		if not c or not r or not h then return end
		
		local moveDir = h.MoveDirection
		if moveDir.Magnitude > 0 then
			r.CFrame = r.CFrame + moveDir * Utils.CalculateCFrameSpeed(self.CFrameSpeed.Value)
		end
	end)
end

function Movement:StopCFrameSpeed()
	self.CFrameSpeed.Active = false
	if self.CFrameSpeed.Connection then
		self.CFrameSpeed.Connection:Disconnect()
		self.CFrameSpeed.Connection = nil
	end
end

function Movement:StartBunnyHop()
	if self.BunnyHop.Connection then return end
	if self.Fly.Enabled and self.Fly.Active then return end
	
	self.BunnyHop.Connection = Services.RunService.Stepped:Connect(function()
		if not self.BunnyHop.Enabled then return end
		if self.Fly.Enabled and self.Fly.Active then
			self:StopBunnyHop()
			return
		end
		
		local c, h, r = Utils.GetCharacterParts()
		if not c or not h or not r then return end
		
		if h.FloorMaterial == Enum.Material.Air then
			local moveDir = h.MoveDirection
			if moveDir.Magnitude > 0 then
				r.CFrame = r.CFrame + moveDir * (self.BunnyHop.Speed / 100)
			end
		end
	end)
end

function Movement:StopBunnyHop()
	if self.BunnyHop.Connection then
		self.BunnyHop.Connection:Disconnect()
		self.BunnyHop.Connection = nil
	end
end

function Movement:StartWalkSpeed()
	if self.WalkSpeed.Connection then return end
	self.WalkSpeed.Connection = Services.RunService.RenderStepped:Connect(function()
		if not self.WalkSpeed.Enabled then return end
		local c, h = Utils.GetCharacterParts()
		if h and h.WalkSpeed ~= self.WalkSpeed.Value then
			h.WalkSpeed = self.WalkSpeed.Value
		end
	end)
end

function Movement:StopWalkSpeed()
	if self.WalkSpeed.Connection then
		self.WalkSpeed.Connection:Disconnect()
		self.WalkSpeed.Connection = nil
	end
end

function Movement:StartJumpPower()
	if self.JumpPower.Connection then return end
	self.JumpPower.Connection = Services.RunService.RenderStepped:Connect(function()
		if not self.JumpPower.Enabled then return end
		local c, h = Utils.GetCharacterParts()
		if h and h.JumpPower ~= self.JumpPower.Value then
			h.JumpPower = self.JumpPower.Value
		end
	end)
end

function Movement:StopJumpPower()
	if self.JumpPower.Connection then
		self.JumpPower.Connection:Disconnect()
		self.JumpPower.Connection = nil
	end
end

function Movement:Start360Spin()
	if self.Spin360.Connection then return end
	self.Spin360.Connection = Services.RunService.RenderStepped:Connect(function(dt)
		if not self.Spin360.Enabled then return end
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = hrp.CFrame * CFrame.Angles(0, self.Spin360.Speed * dt, 0)
		end
	end)
end

function Movement:Stop360Spin()
	if self.Spin360.Connection then
		self.Spin360.Connection:Disconnect()
		self.Spin360.Connection = nil
	end
end

-- Функция для получения корня (Машины или Персонажа)
-- Возвращает: rootPart, vehicleModel (или nil если не в машине)
local function GetMovementRoot()
	local char = LocalPlayer.Character
	if not char then return nil, nil end
	
	local hum = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	
	if not hum or not root then return nil, nil end
	
	-- Проверяем, сидит ли игрок (VFly логика)
	if hum.SeatPart then
		-- Машина в этой игре - это Model в workspace.Vehicles
		-- Структура: Model (имя игрока) -> Center, Driver, Ride, etc.
		local vehicleModel = hum.SeatPart.Parent
		if vehicleModel and vehicleModel:IsA("Model") then
			-- Ищем основную часть машины для позиции: Center или PrimaryPart или сиденье
			local mainPart = vehicleModel:FindFirstChild("Center") 
				or vehicleModel.PrimaryPart 
				or hum.SeatPart
			return mainPart, vehicleModel
		end
		return hum.SeatPart, nil
	else
		-- Если не сидим, возвращаем персонажа (обычный Fly)
		return root, nil
	end
end

-- =====================================================
-- IMPROVED FLY CAR (CAMERA BASED ROTATION & STRAFE)
-- =====================================================

function Movement:StartFlyCar()
	if self.FlyCar.Connection then return end
	
	-- 1. Ищем транспорт
	local vehicle = workspace.Vehicles:FindFirstChild(LocalPlayer.Name)
	if not vehicle then 
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if hum and hum.SeatPart then
			local current = hum.SeatPart
			while current.Parent and current.Parent ~= workspace.Vehicles do
				current = current.Parent
			end
			if current.Parent == workspace.Vehicles then
				vehicle = current
			end
		end
	end

	if not vehicle then return end

	-- 2. Ищем VectorForce
	local vf = vehicle:FindFirstChildOfClass("VectorForce")
	if not vf then return end

	-- 3. Создаем BodyGyro для жесткой привязки к повороту камеры
	local gyro = Instance.new("BodyGyro")
	gyro.Name = "FlyGyro"
	gyro.P = 50000 -- Высокая мощность для мгновенного отклика
	gyro.D = 500   -- Демпфирование для плавности
	gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	gyro.CFrame = vehicle.CFrame
	gyro.Parent = vehicle

	-- Множитель скорости (настраивай если медленно/быстро)
	local SPEED_MULTIPLIER = 300 
	
	self.FlyCar.Connection = Services.RunService.RenderStepped:Connect(function(deltaTime)
		if not vehicle or not vehicle.Parent or not vehicle:FindFirstChildOfClass("VectorForce") then
			self:StopFlyCar()
			return
		end

		local UIS = Services.UserInputService
		local camera = workspace.CurrentCamera
		
		-- === АНТИ-ГРАВИТАЦИЯ ===
		local totalMass = vehicle.AssemblyMass
		local gravity = workspace.Gravity
		local hoverForce = Vector3.new(0, totalMass * gravity, 0)
		
		-- === ПОВОРОТ (Как в обычном флае) ===
		-- Машина всегда смотрит туда же, куда и камера
		gyro.CFrame = camera.CFrame
		
		-- === ДВИЖЕНИЕ (Относительно камеры) ===
		local speed = self.FlyCar.Speed * SPEED_MULTIPLIER
		local moveVector = Vector3.new(0, 0, 0)
		
		-- W / S - Вперед / Назад (по вектору взгляда)
		if UIS:IsKeyDown(Enum.KeyCode.W) then
			moveVector = moveVector + camera.CFrame.LookVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.S) then
			moveVector = moveVector - camera.CFrame.LookVector
		end
		
		-- A / D - Стрейф Влево / Вправо (по вектору "право" камеры)
		if UIS:IsKeyDown(Enum.KeyCode.D) then
			moveVector = moveVector + camera.CFrame.RightVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) then
			moveVector = moveVector - camera.CFrame.RightVector
		end
		
		-- Q / E - Вертикальный взлет / спуск (в мировых координатах)
		local verticalBonus = Vector3.new(0, 0, 0)
		if UIS:IsKeyDown(Enum.KeyCode.Q) then
			verticalBonus = Vector3.new(0, speed, 0)
		elseif UIS:IsKeyDown(Enum.KeyCode.E) then
			verticalBonus = Vector3.new(0, -speed, 0)
		end
		
		-- Применяем силу
		-- Если нажаты кнопки движения, нормализуем вектор и умножаем на скорость
		if moveVector.Magnitude > 0 then
			moveVector = moveVector.Unit * speed
		end
		
		vf.Force = hoverForce + moveVector + verticalBonus
	end)
end

function Movement:StopFlyCar()
	if self.FlyCar.Connection then
		self.FlyCar.Connection:Disconnect()
		self.FlyCar.Connection = nil
	end
	
	local vehicle = workspace.Vehicles:FindFirstChild(LocalPlayer.Name)
	if not vehicle then
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if hum and hum.SeatPart then
			local current = hum.SeatPart
			while current.Parent and current.Parent ~= workspace.Vehicles do
				current = current.Parent
			end
			if current.Parent == workspace.Vehicles then
				vehicle = current
			end
		end
	end

	if vehicle then
		local gyro = vehicle:FindFirstChild("FlyGyro")
		if gyro then gyro:Destroy() end
		
		local vf = vehicle:FindFirstChildOfClass("VectorForce")
		if vf then
			vf.Force = Vector3.new(0, 0, 0)
		end
	end
end

function Movement:CleanupAll()
	self:StopFly()
	self:StopCFrameSpeed()
	self:StopBunnyHop()
	self:StopWalkSpeed()
	self:StopJumpPower()
	self:Stop360Spin()
	self:StopFlyCar()
end

-- =====================================================
-- CHARACTER MODULE (LOCAL)
-- =====================================================
local Character = {
	Noclip = { Enabled = false, Connection = nil },
	AntiFling = { Enabled = false, Connection = nil },
	AutoReload = { Enabled = false, Connection = nil },
	NoSlow = { Enabled = false, Connection = nil },
	NoJumpCooldown = { Enabled = false, Connection = nil },
	NoSeat = { Enabled = false, Connection = nil },
	InfiniteZoom = { Enabled = false, DefaultMax = 128, DefaultMin = 0.5 },
	Fell = { Enabled = false, Thread = nil },
}

function Character:EnableNoclip()
	if self.Noclip.Connection then return end
	self.Noclip.Connection = Services.RunService.Stepped:Connect(function()
		local char = LocalPlayer.Character
		if char then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end)
end

function Character:DisableNoclip()
	if self.Noclip.Connection then
		self.Noclip.Connection:Disconnect()
		self.Noclip.Connection = nil
	end
end

function Character:EnableAntiFling()
	if self.AntiFling.Connection then return end
	self.AntiFling.Connection = Services.RunService.Heartbeat:Connect(function()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			if hrp.AssemblyLinearVelocity.Magnitude > 50 then
				hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity.Unit * 50
			end
			if hrp.AssemblyAngularVelocity.Magnitude > 10 then
				hrp.AssemblyAngularVelocity = hrp.AssemblyAngularVelocity.Unit * 10
			end
		end
	end)
end

function Character:DisableAntiFling()
	if self.AntiFling.Connection then
		self.AntiFling.Connection:Disconnect()
		self.AntiFling.Connection = nil
	end
end

function Character:EnableAutoReload()
	if self.AutoReload.Connection then return end
	self.AutoReload.Connection = Services.RunService.Stepped:Connect(function()
		if not self.AutoReload.Enabled then return end
		local char = LocalPlayer.Character
		if not char then return end
		
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			local ammo = tool:FindFirstChild("Ammo")
			if ammo and ammo.Value <= 0 then
				MainEvent:FireServer("Reload", tool)
			end
		end
		task.wait(1)
	end)
end

function Character:DisableAutoReload()
	if self.AutoReload.Connection then
		self.AutoReload.Connection:Disconnect()
		self.AutoReload.Connection = nil
	end
end

function Character:EnableNoSlow()
	if self.NoSlow.Connection then return end
	self.NoSlow.Connection = Services.RunService.Stepped:Connect(function()
		if not self.NoSlow.Enabled then return end
		local char = LocalPlayer.Character
		local bodyEffects = char and char:FindFirstChild("BodyEffects")
		if bodyEffects then
			local movement = bodyEffects:FindFirstChild("Movement")
			if movement then
				for _, effect in pairs(movement:GetChildren()) do
					effect:Destroy()
				end
			end
		end
	end)
end

function Character:DisableNoSlow()
	if self.NoSlow.Connection then
		self.NoSlow.Connection:Disconnect()
		self.NoSlow.Connection = nil
	end
end

function Character:EnableNoJumpCooldown()
	if self.NoJumpCooldown.Connection then return end
	self.NoJumpCooldown.Connection = Services.RunService.Stepped:Connect(function()
		if not self.NoJumpCooldown.Enabled then return end
		local c, h = Utils.GetCharacterParts()
		if h then h.UseJumpPower = false end
	end)
end

function Character:DisableNoJumpCooldown()
	if self.NoJumpCooldown.Connection then
		self.NoJumpCooldown.Connection:Disconnect()
		self.NoJumpCooldown.Connection = nil
	end
	local c, h = Utils.GetCharacterParts()
	if h then h.UseJumpPower = true end
end

function Character:EnableNoSeat()
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
			obj.Disabled = true
		end
	end
	
	self.NoSeat.Connection = workspace.DescendantAdded:Connect(function(obj)
		if self.NoSeat.Enabled and (obj:IsA("Seat") or obj:IsA("VehicleSeat")) then
			obj.Disabled = true
		end
	end)
end

function Character:DisableNoSeat()
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
			obj.Disabled = false
		end
	end
	if self.NoSeat.Connection then
		self.NoSeat.Connection:Disconnect()
		self.NoSeat.Connection = nil
	end
end

function Character:EnableInfiniteZoom()
	self.InfiniteZoom.DefaultMax = LocalPlayer.CameraMaxZoomDistance
	self.InfiniteZoom.DefaultMin = LocalPlayer.CameraMinZoomDistance
	LocalPlayer.CameraMaxZoomDistance = 9999
	LocalPlayer.CameraMinZoomDistance = 0.5
end

function Character:DisableInfiniteZoom()
	LocalPlayer.CameraMaxZoomDistance = self.InfiniteZoom.DefaultMax
	LocalPlayer.CameraMinZoomDistance = self.InfiniteZoom.DefaultMin
end

function Character:StartFell()
	self.Fell.Thread = task.spawn(function()
		while self.Fell.Enabled do
			local char = LocalPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				hum:ChangeState(Enum.HumanoidStateType.FallingDown)
				task.wait(1.5)
				if not self.Fell.Enabled then break end
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				task.wait(1)
			else
				task.wait(0.5)
			end
		end
	end)
end

function Character:StopFell()
	self.Fell.Enabled = false
	if self.Fell.Thread then
		task.cancel(self.Fell.Thread)
		self.Fell.Thread = nil
	end
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

function Character:CleanupAll()
	self:DisableNoclip()
	self:DisableAntiFling()
	self:DisableAutoReload()
	self:DisableNoSlow()
	self:DisableNoJumpCooldown()
	self:StopFell()
end

-- =====================================================
-- DETECTIONS MODULE (LOCAL)
-- =====================================================
-- Настройки
getgenv().ModDetectionEnabled = false -- true = включено, false = выключено

local Detections = {
	RPGDetection = { Enabled = false, Loop = nil },
	GranadeDetection = { Enabled = false },
	ModDetection = { Enabled = false, Connection = nil },
	
	ModDetectionSettings = {
		GroupID = 4698921, -- ID группы Da Hood Entertainment
		KickReason = "Moderator on server (Security Kick)", -- Причина кика
		BlacklistedRoles = {
			-- Список опасных ролей (названия должны точь-в-точь совпадать с ролями в группе)
			"Testers",
			"Moderators",
			"Contributed",
			"Monetization",
			"ADMlN", -- Как ты указал (с буквой l вместо I), но лучше добавить и нормальное написание ниже
			"Admin", -- На случай если там обычное написание
			"Administrator",
			"Owner"
		},
	},
}

local function IsThreatNear(threatName)
	local threat = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild(threatName)
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	return threat and hrp and (threat.Position - hrp.Position).Magnitude < 16
end

function Detections:StartThreatDetection()
	if self.RPGDetection.Loop then return end
	
	self.RPGDetection.Loop = Services.RunService.PostSimulation:Connect(function()
		local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
		if not hrp or not humanoid then return end
		
		local rpgThreat = workspace.Ignored:FindFirstChild("Model") and workspace.Ignored.Model:FindFirstChild("Launcher")
		local grenadeThreat = IsThreatNear("Handle")
		
		if (self.RPGDetection.Enabled and rpgThreat) or (self.GranadeDetection.Enabled and grenadeThreat) then
			local offset = Vector3.new(math.random(-100, 100), math.random(50, 150), math.random(-100, 100))
			humanoid.CameraOffset = -offset
			local oldCFrame = hrp.CFrame
			hrp.CFrame = CFrame.new(hrp.CFrame.Position + offset)
			Services.RunService.RenderStepped:Wait()
			hrp.CFrame = oldCFrame
		end
	end)
	
	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(1)
		if self.RPGDetection.Enabled or self.GranadeDetection.Enabled then
			self:StartThreatDetection()
		end
	end)
end

function Detections:StopThreatDetection()
	if self.RPGDetection.Loop then
		self.RPGDetection.Loop:Disconnect()
		self.RPGDetection.Loop = nil
	end
end

function Detections:CheckPlayer(player)
	-- Если функция выключена или проверяем сами себя -> пропускаем
	if not getgenv().ModDetectionEnabled or player == LocalPlayer then return end
	
	local success, role = pcall(function() 
		return player:GetRoleInGroup(self.ModDetectionSettings.GroupID) 
	end)
	
	if success and role then
		-- Проверяем, есть ли роль в нашем черном списке
		for _, bannedRole in pairs(self.ModDetectionSettings.BlacklistedRoles) do
			if role == bannedRole then
				-- Если совпадение найдено -> кикаем себя
				warn("Обнаружен модератор: " .. player.Name .. " [" .. role .. "]")
				LocalPlayer:Kick(self.ModDetectionSettings.KickReason)
				break
			end
		end
	end
end

function Detections:StartModDetection()
	if self.ModDetection.Connection then return end
	
	-- 1. Проверяем всех игроков, которые УЖЕ на сервере при запуске скрипта
	for _, player in pairs(Services.Players:GetPlayers()) do
		task.spawn(function()
			self:CheckPlayer(player)
		end)
	end
	
	-- 2. Подписываемся на событие входа новых людей
	self.ModDetection.Connection = Services.Players.PlayerAdded:Connect(function(player)
		self:CheckPlayer(player)
	end)
end

function Detections:StopModDetection()
	if self.ModDetection.Connection then
		self.ModDetection.Connection:Disconnect()
		self.ModDetection.Connection = nil
	end
end

-- =====================================================
-- PLAYER SYSTEM MODULE (LOCAL) - REWORKED WITH SILENT SHOT
-- =====================================================
local PlayerSystem = {
	KnockActive = {},
	KillActive = {},
	AutoKillActive = false,
	AutoKillTargets = {},
	SpectatingPlayer = nil,
	SelectedPlayer = nil,
	Dropdown = nil,
	
	-- Настройки Silent Shot для системы игроков
	SilentShot = {
		LastShot = 0,
		TeleportDistance = 30, -- Расстояние для телепортации
		AutoReload = true,
	},
}

-- Получить огнестрельное оружие (не мили)
function PlayerSystem:GetGun()
	local char = LocalPlayer.Character
	if not char then return nil end
	
	local tool = char:FindFirstChildWhichIsA("Tool")
	if not tool then return nil end
	if not tool:FindFirstChild("Handle") then return nil end
	if not tool:FindFirstChild("RemoteEvent") then return nil end
	if not tool:FindFirstChild("Ammo") then return nil end
	
	-- Исключаем мили оружие и несовместимое
	if Config.Weapons.Melee[tool.Name:upper()] then return nil end
	if Config.Weapons.NoSilent[tool.Name:upper()] then return nil end
	
	return tool
end

-- Проверка возможности стрельбы
function PlayerSystem:CanShoot()
	local char, hum = Utils.GetCharacterParts()
	if not char or not hum then return false, nil end
	
	local gun = self:GetGun()
	if not gun then return false, nil end
	
	local ammo = gun:FindFirstChild("Ammo")
	if ammo and ammo.Value <= 0 then return false, gun end
	
	local bodyEffects = char:FindFirstChild("BodyEffects")
	if not bodyEffects then return false, nil end
	
	if bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value then return false, nil end
	if bodyEffects:FindFirstChild("Dead") and bodyEffects.Dead.Value then return false, nil end
	if bodyEffects:FindFirstChild("Reload") and bodyEffects.Reload.Value then return false, gun end
	
	return true, gun
end

-- Выстрел через Silent в цель
function PlayerSystem:SilentShootAt(targetPlayer, hitboxName)
	local canShoot, gun = self:CanShoot()
	
	if not canShoot then
		-- Авто перезарядка если нет патронов
		if gun and self.SilentShot.AutoReload then
			local ammo = gun:FindFirstChild("Ammo")
			if ammo and ammo.Value <= 0 then
				MainEvent:FireServer("Reload", gun)
				task.wait(0.5)
			end
		end
		return false
	end
	
	local targetChar = targetPlayer.Character
	if not targetChar then return false end
	if not Utils.IsCharacterAlive(targetChar) then return false end
	
	local hitbox = Utils.GetHitboxPart(targetChar, hitboxName or "Head")
	if not hitbox then return false end
	
	-- Проверяем видимость
	if not Utils.IsVisible(Camera.CFrame.Position, hitbox) then return false end
	
	local handle = gun:FindFirstChild("Handle")
	if not handle then return false end
	
	-- Предсказание позиции через Aimbot модуль
	local predictedPos = Aimbot:PredictPositionSilent(targetChar, hitbox)
	if not predictedPos then 
		predictedPos = hitbox.Position 
	end
	
	-- Отправляем выстрел напрямую
	local startPos = Camera.CFrame.Position
	local normal = (predictedPos - startPos).Unit
	if normal.Magnitude == 0 then normal = Vector3.new(0, 1, 0) end
	
	MainEvent:FireServer("ShootGun", handle, startPos, predictedPos, hitbox, normal)
	
	self.SilentShot.LastShot = tick()
	return true
end

-- Телепортация к цели на безопасное расстояние для стрельбы
function PlayerSystem:TeleportForShot(targetRoot, myRoot)
	if not targetRoot or not myRoot then return end
	
	local distance = (myRoot.Position - targetRoot.Position).Magnitude
	if distance > self.SilentShot.TeleportDistance then
		local direction = (targetRoot.Position - myRoot.Position).Unit
		local newPos = targetRoot.Position - direction * (self.SilentShot.TeleportDistance - 5)
		myRoot.CFrame = CFrame.new(newPos)
		task.wait(0.05)
	end
end

-- Наведение на цель (поворот персонажа)
function PlayerSystem:LookAt(targetPos)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local dir = (targetPos - root.Position)
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude > 0.1 then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
	end
end

-- KNOCK через Silent Shot (стрельба в голову до K.O)
function PlayerSystem:Knock(target)
	if not target or self.KnockActive[target] then return end
	local targetChar = target.Character
	if not targetChar then return end
	
	local bodyEffects = targetChar:FindFirstChild("BodyEffects")
	local koValue = bodyEffects and bodyEffects:FindFirstChild("K.O")
	if not koValue or koValue.Value then return end
	
	self.KnockActive[target] = true
	
	task.spawn(function()
		local myChar = LocalPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myRoot then self.KnockActive[target] = nil return end
		
		local savedPos = myRoot.CFrame
		local shotsFired = 0
		local maxShots = 100 -- Лимит выстрелов
		
		while self.KnockActive[target] and shotsFired < maxShots do
			-- Проверяем состояние цели
			targetChar = target.Character
			if not targetChar or not targetChar.Parent then break end
			
			bodyEffects = targetChar:FindFirstChild("BodyEffects")
			koValue = bodyEffects and bodyEffects:FindFirstChild("K.O")
			if not koValue or koValue.Value then break end -- Уже в K.O
			
			local deadValue = bodyEffects:FindFirstChild("Dead")
			if deadValue and deadValue.Value then break end -- Уже мертв
			
			-- Проверяем себя
			myChar = LocalPlayer.Character
			myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myRoot then break end
			
			local gun = self:GetGun()
			if gun then
				local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					-- Телепортируемся на дистанцию стрельбы
					self:TeleportForShot(targetRoot, myRoot)
					self:LookAt(targetRoot.Position)
				end
				
				-- Стреляем в голову
				if self:SilentShootAt(target, "Head") then
					shotsFired = shotsFired + 1
				end
				
				-- Задержка между выстрелами
				local fireRate = Aimbot:GetWeaponFireRate(gun)
				task.wait(math.max(fireRate + 0.02, 0.08))
			else
				-- Нет оружия - ждем
				task.wait(0.3)
			end
		end
		
		-- Возвращаемся на исходную позицию
		task.wait(0.1)
		myChar = LocalPlayer.Character
		myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if myRoot and myRoot.Parent then 
			myRoot.CFrame = savedPos 
		end
		self.KnockActive[target] = nil
	end)
end

-- KILL через Silent Shot (стрельба + добивание)
function PlayerSystem:Kill(target)
	if not target or self.KillActive[target] then return end
	local targetChar = target.Character
	if not targetChar then return end
	
	self.KillActive[target] = true
	
	task.spawn(function()
		local myChar = LocalPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if not myRoot then self.KillActive[target] = nil return end
		
		local savedPos = myRoot.CFrame
		local shotsFired = 0
		local maxShots = 150
		local stompCount = 0
		local maxStomps = 20
		
		-- Фаза 1: Стреляем до K.O
		while self.KillActive[target] and shotsFired < maxShots do
			targetChar = target.Character
			if not targetChar or not targetChar.Parent then break end
			
			myChar = LocalPlayer.Character
			myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myRoot then break end
			
			local bodyEffects = targetChar:FindFirstChild("BodyEffects")
			if not bodyEffects then break end
			
			local deadValue = bodyEffects:FindFirstChild("Dead")
			if deadValue and deadValue.Value then break end -- Уже мертв
			
			local koValue = bodyEffects:FindFirstChild("K.O")
			if koValue and koValue.Value then break end -- В K.O - переходим к добиванию
			
			local gun = self:GetGun()
			if gun then
				local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					self:TeleportForShot(targetRoot, myRoot)
					self:LookAt(targetRoot.Position)
				end
				
				if self:SilentShootAt(target, "Head") then
					shotsFired = shotsFired + 1
				end
				
				local fireRate = Aimbot:GetWeaponFireRate(gun)
				task.wait(math.max(fireRate + 0.02, 0.08))
			else
				task.wait(0.3)
			end
		end
		
		-- Фаза 2: Добивание (Stomp) когда в K.O
		task.wait(0.1)
		while self.KillActive[target] and stompCount < maxStomps do
			targetChar = target.Character
			if not targetChar or not targetChar.Parent then break end
			
			myChar = LocalPlayer.Character
			myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if not myRoot then break end
			
			local bodyEffects = targetChar:FindFirstChild("BodyEffects")
			if not bodyEffects then break end
			
			local deadValue = bodyEffects:FindFirstChild("Dead")
			if deadValue and deadValue.Value then break end -- Убит!
			
			local koValue = bodyEffects:FindFirstChild("K.O")
			if not koValue or not koValue.Value then 
				-- Вышел из K.O - продолжаем стрелять
				local gun = self:GetGun()
				if gun then
					local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
					if targetRoot then
						self:TeleportForShot(targetRoot, myRoot)
						self:LookAt(targetRoot.Position)
					end
					self:SilentShootAt(target, "Head")
					local fireRate = Aimbot:GetWeaponFireRate(gun)
					task.wait(math.max(fireRate + 0.02, 0.08))
				else
					task.wait(0.3)
				end
				continue
			end
			
			-- Добиваем через Stomp
			local targetTorso = targetChar:FindFirstChild("UpperTorso") or 
			                   targetChar:FindFirstChild("Torso") or 
			                   targetChar:FindFirstChild("HumanoidRootPart")
			if targetTorso then
				myRoot.CFrame = CFrame.new(targetTorso.Position + Vector3.new(0, 3, 0))
				task.wait(0.05)
				MainEvent:FireServer("Stomp")
				stompCount = stompCount + 1
				task.wait(0.25)
			else
				task.wait(0.2)
			end
		end
		
		-- Возвращаемся
		task.wait(0.1)
		myChar = LocalPlayer.Character
		myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if myRoot and myRoot.Parent then 
			myRoot.CFrame = savedPos 
		end
		self.KillActive[target] = nil
	end)
end

function PlayerSystem:Fling(target)
	if not target or not target.Character then return end
	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return end
	
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local originalPos = root.CFrame
	local startTime = tick()
	local noclipConn, flingConn
	
	noclipConn = Services.RunService.Stepped:Connect(function()
		if char then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end)
	
	flingConn = Services.RunService.Heartbeat:Connect(function()
		if tick() - startTime > 1.5 or not targetRoot.Parent or not root.Parent then
			noclipConn:Disconnect()
			flingConn:Disconnect()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			task.wait(0.1)
			if root.Parent then root.CFrame = originalPos + Vector3.new(0, 5, 0) end
		else
			root.CFrame = targetRoot.CFrame
			root.AssemblyLinearVelocity = Vector3.new(9e5, 9e5, 9e5)
			root.AssemblyAngularVelocity = Vector3.new(9e5, 9e5, 9e5)
		end
	end)
end

function PlayerSystem:Teleport(target)
	if not target or not target.Character then return end
	local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if targetRoot and root then
		root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
	end
end

function PlayerSystem:Spectate(target)
	if not target or not target.Character then return end
	local hum = target.Character:FindFirstChild("Humanoid")
	if hum then
		self.SpectatingPlayer = target
		Camera.CameraSubject = hum
	end
end

function PlayerSystem:StopSpectate()
	self.SpectatingPlayer = nil
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if hum then Camera.CameraSubject = hum end
end

function PlayerSystem:StartAutoKill()
	if self.AutoKillActive then return end
	self.AutoKillActive = true
	
	task.spawn(function()
		while self.AutoKillActive do
			if #self.AutoKillTargets == 0 then task.wait(0.5) continue end
			
			for i = #self.AutoKillTargets, 1, -1 do
				if not self.AutoKillActive then break end
				local target = self.AutoKillTargets[i]
				
				if not target or not target.Parent then
					table.remove(self.AutoKillTargets, i)
					continue
				end
				
				local targetChar = target.Character
				if not targetChar then continue end
				
				local bodyEffects = targetChar:FindFirstChild("BodyEffects")
				local dead = bodyEffects and bodyEffects:FindFirstChild("Dead")
				if dead and dead.Value then
					table.remove(self.AutoKillTargets, i)
					continue
				end
				
				if not self.KillActive[target] then
					self:Kill(target)
					-- Ждем завершения
					while self.KillActive[target] do
						task.wait(0.1)
					end
					task.wait(0.5)
				end
			end
			task.wait(0.3)
		end
	end)
end

function PlayerSystem:StopAutoKill()
	self.AutoKillActive = false
	self.AutoKillTargets = {}
	for p in pairs(self.KillActive) do self.KillActive[p] = nil end
	for p in pairs(self.KnockActive) do self.KnockActive[p] = nil end
end

function PlayerSystem:GetPlayerNames()
	local names = {"None"}
	for _, player in ipairs(Services.Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(names, player.Name)
		end
	end
	return names
end

function PlayerSystem:RefreshDropdown()
	if self.Dropdown and self.Dropdown.SetValues then
		pcall(function() self.Dropdown:SetValues(self:GetPlayerNames()) end)
	end
end

-- =====================================================
-- MAIN STATE (LOCAL)
-- =====================================================
local State = {
	MenuToggleKey = Enum.KeyCode.Insert,
	IsResetting = false,
}

-- Переменная для отслеживания состояния меню
local menuOpen = true

-- Объявляем Window заранее, чтобы он был доступен в функциях модулей
local Window

-- =====================================================
-- INITIALIZE
-- =====================================================
Aimbot:UpdatePing()
Aimbot:CreateFOVCircles()

Services.RunService.RenderStepped:Connect(function()
	pcall(function() Aimbot:UpdateFOVCircles() end)
end)

local function OnCharacterAdded(char)
	State.IsResetting = true
	Movement:CleanupAll()
	Character:CleanupAll()
	Aimbot:StopTrigger()
	if Aimbot.Silent.Enabled then Aimbot:StopSilent() end
	Aimbot:ClearCache()
	
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then State.IsResetting = false return end
	char:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.5)
	State.IsResetting = false
	
	if Movement.Fly.Enabled then Movement:StartFly()
	else
		if Movement.CFrameSpeed.Enabled then Movement:StartCFrameSpeed() end
		if Movement.BunnyHop.Enabled then Movement:StartBunnyHop() end
	end
	if Movement.WalkSpeed.Enabled then Movement:StartWalkSpeed() end
	if Movement.JumpPower.Enabled then Movement:StartJumpPower() end
	if Movement.Spin360.Enabled then Movement:Start360Spin() end
	
	if Character.Noclip.Enabled then Character:EnableNoclip() end
	if Character.AntiFling.Enabled then Character:EnableAntiFling() end
	if Character.AutoReload.Enabled then Character:EnableAutoReload() end
	if Character.NoSlow.Enabled then Character:EnableNoSlow() end
	if Character.NoJumpCooldown.Enabled then Character:EnableNoJumpCooldown() end
	if Character.InfiniteZoom.Enabled then Character:EnableInfiniteZoom() end
	if Character.Fell.Enabled then Character:StartFell() end
	
	if Aimbot.Trigger.Active then Aimbot:StartTrigger() end
	if Aimbot.Silent.Enabled then Aimbot:StartSilent() end
	
	hum.Died:Connect(function()
		Movement:CleanupAll()
		Character:CleanupAll()
		Aimbot:StopTrigger()
	end)
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
if LocalPlayer.Character then task.spawn(function() OnCharacterAdded(LocalPlayer.Character) end) end


Services.Players.PlayerAdded:Connect(function()
	task.wait(0.5)
	PlayerSystem:RefreshDropdown()
end)

Services.Players.PlayerRemoving:Connect(function(player)
	local idx = table.find(PlayerSystem.AutoKillTargets, player)
	if idx then
		table.remove(PlayerSystem.AutoKillTargets, idx)
		PlayerSystem.KillActive[player] = nil
		PlayerSystem.KnockActive[player] = nil
	end
	if PlayerSystem.SpectatingPlayer == player then PlayerSystem:StopSpectate() end
	if PlayerSystem.SelectedPlayer == player then PlayerSystem.SelectedPlayer = nil end
	task.wait(0.1)
	PlayerSystem:RefreshDropdown()
end)

-- =====================================================
-- UI SETUP
-- =====================================================
Window = Fatality.new({
	Name = "RAY",
	Keybind = Enum.KeyCode.Insert,
	Scale = UDim2.new(0, 750, 0, 500),
	Expire = "Never",
	SidebarWidth = 200,
	TabHeight = 40,
	HeaderHeight = 50,
	BottomHeight = 30,
	Theme = Config.Theme,
})

-- Библиотека теперь поддерживает LogoStroke и DropdownSelected напрямую через BindTheme

-- Подписываемся на сигнал библиотеки для отслеживания состояния меню
-- Библиотека сама обрабатывает нажатие Insert, поэтому НЕ нужно слушать InputBegan
if Window and Window.Signal then
	Window.Signal.Event:Connect(function(isVisible)
		menuOpen = isVisible
	end)
	-- Устанавливаем начальное состояние из библиотеки
	menuOpen = Window.Toggle
end

local Menus = {
	Legit = Window:AddMenu({ Name = "Legit", Icon = "lucide-mouse", AutoFill = false }),
	Rage = Window:AddMenu({ Name = "Rage", Icon = "lucide-skull", AutoFill = false }),
	Visuals = Window:AddMenu({ Name = "Visuals", Icon = "eye", AutoFill = false }),
	Misc = Window:AddMenu({ Name = "Misc", Icon = "package", AutoFill = false }),
	Players = Window:AddMenu({ Name = "Players", Icon = "users", AutoFill = false }),
	Settings = Window:AddMenu({ Name = "Settings", Icon = "settings", AutoFill = false }),
}

-- LEGIT TAB
do
	local GlobalSection = Menus.Legit:AddSection({ Name = "Global", Side = "left", ShowTitle = true, Height = 0 })
	GlobalSection:AddToggle({ Name = "Aimbot", Default = false, Flag = "AimbotEnabled",
		Callback = function(v) Aimbot.Enabled = v end })
	GlobalSection:AddToggle({ Name = "Visible Check", Default = false, Flag = "VisibleCheck",
		Callback = function(v) Aimbot.VisibleCheck = v end })
	GlobalSection:AddDropdown({ Name = "Hitbox", Values = {"Head", "UpperTorso", "HumanoidRootPart", "Nearest"},
		Default = "Head", Flag = "Hitbox", Callback = function(v) Aimbot.Hitbox = v end })
	
	local CamSection = Menus.Legit:AddSection({ Name = "Camera Lock", Side = "left", ShowTitle = true, Height = 0 })
	local camToggle = CamSection:AddToggle({ Name = "Enabled", Default = false, Option = true, Flag = "CameraLockEnabled",
		Callback = function(v)
			Aimbot.CameraLock.Active = v
			if v then Aimbot:StartCameraLock() else Aimbot:StopCameraLock() end
		end })
	if camToggle.Option then camToggle.Option:AddKeybind({ Name = "Keybind", Flag = "CameraLockKeybind" }) end
	CamSection:AddSlider({ Name = "FOV", Type = "px", Default = 100, Min = 10, Max = 500, Round = 0, Flag = "CameraLockFOV",
		Callback = function(v) Aimbot.CameraLock.FOV = v end })
	CamSection:AddSlider({ Name = "Smoothness", Default = 0.1, Min = 0, Max = 0.95, Round = 2, Flag = "CameraLockSmooth",
		Callback = function(v) Aimbot.CameraLock.Smoothness = v end })
	CamSection:AddSlider({ Name = "Prediction", Default = 0.5, Min = 0, Max = 0.95, Round = 2, Flag = "CameraLockPrediction",
		Callback = function(v) Aimbot.CameraLock.Prediction = v end })
	
	local SilentSection = Menus.Legit:AddSection({ Name = "Silent", Side = "right", ShowTitle = true, Height = 0 })
	local silentToggle = SilentSection:AddToggle({ Name = "Enabled", Default = false, Option = true, Flag = "SilentEnabled",
		Callback = function(v) if v then Aimbot:StartSilent() else Aimbot:StopSilent() end end })
	if silentToggle.Option then silentToggle.Option:AddKeybind({ Name = "Keybind", Flag = "SilentKeybind" }) end
	SilentSection:AddSlider({ Name = "FOV", Type = "px", Default = 100, Min = 10, Max = 500, Round = 0, Flag = "SilentFOV",
		Callback = function(v) Aimbot.Silent.FOV = v end })
	SilentSection:AddSlider({ Name = "Smoothing Tau", Type = "s", Default = 0.15, Min = 0.05, Max = 0.50, Round = 2, Flag = "SilentTau",
		Callback = function(v) Aimbot.Silent.Tau = v end })
	SilentSection:AddToggle({ Name = "Velocity Resolver", Default = false, Flag = "SilentResolver",
		Callback = function(v) Aimbot.Silent.Resolver = v end })
	SilentSection:AddSlider({ Name = "Jump Offset", Default = 0, Min = -1, Max = 1, Round = 2, Flag = "SilentJumpOffset",
		Callback = function(v) Aimbot.Silent.JumpOffset = v end })
	SilentSection:AddToggle({ Name = "Auto Prediction", Default = false, Flag = "SilentAutoPrediction",
		Callback = function(v) Aimbot.Silent.AutoPrediction = v end })
	SilentSection:AddSlider({ Name = "Auto Pred Divisor", Default = 250, Min = 200, Max = 350, Round = 0, Flag = "SilentAutoPredDivisor",
		Callback = function(v) Aimbot.Silent.AutoPredictionDivisor = v end })
	
	local TriggerSection = Menus.Legit:AddSection({ Name = "Triggerbot", Side = "right", ShowTitle = true, Height = 0 })
	local triggerToggle = TriggerSection:AddToggle({ Name = "Enabled", Default = false, Option = true, Flag = "TriggerEnabled",
		Callback = function(v)
			Aimbot.Trigger.Active = v
			if v then Aimbot:StartTrigger() else Aimbot:StopTrigger() end
		end })
	if triggerToggle.Option then triggerToggle.Option:AddKeybind({ Name = "Keybind", Flag = "TriggerKeybind" }) end
	TriggerSection:AddSlider({ Name = "Min Delay", Type = "ms", Default = 50, Min = 0, Max = 200, Round = 0, Flag = "TriggerMinDelay",
		Callback = function(v) Aimbot.Trigger.MinDelay = v / 1000 end })
end

-- VISUALS TAB
do
	local FOVSection = Menus.Visuals:AddSection({ Name = "FOV Circles", Side = "left", ShowTitle = true, Height = 0 })
	FOVSection:AddToggle({ Name = "Show Camera Lock FOV", Default = true, Flag = "ShowCameraLockFOV",
		Callback = function(v) Aimbot.ESP.ShowCameraLockFOV = v end })
	FOVSection:AddColorPicker({ Name = "Camera Lock Color", Default = Color3.fromRGB(255, 255, 255), Flag = "CameraLockFOVColor",
		Callback = function(c) Aimbot.ESP.CameraLockFOVColor = c end })
	FOVSection:AddToggle({ Name = "Show Silent FOV", Default = true, Flag = "ShowSilentFOV",
		Callback = function(v) Aimbot.ESP.ShowSilentFOV = v end })
	FOVSection:AddColorPicker({ Name = "Silent Color", Default = Color3.fromRGB(0, 255, 255), Flag = "SilentFOVColor",
		Callback = function(c) Aimbot.ESP.SilentFOVColor = c end })
	FOVSection:AddColorPicker({ Name = "Locked Color", Default = Color3.fromRGB(255, 70, 70), Flag = "LockedColor",
		Callback = function(c) Aimbot.ESP.LockedColor = c end })
end

-- MISC TAB
do
	local MovementSection = Menus.Misc:AddSection({ Name = "Movement", Side = "left", ShowTitle = true, Height = 0 })
	
	local flySlider = MovementSection:AddSlider({ Name = "Fly Speed", Default = 50, Min = 1, Max = 100, Round = 0, Flag = "FlySpeed",
		Callback = function(v) Movement.Fly.Speed = v end })
	flySlider:SetVisible(false)
	
	local flyToggle = MovementSection:AddToggle({ Name = "Fly", Default = false, Option = true, Flag = "FlyEnabled",
		Callback = function(v)
			if State.IsResetting then return end
			Movement.Fly.Enabled = v
			if v then Movement:StartFly() else Movement:StopFly() end
			flySlider:SetVisible(v)
		end })
	if flyToggle.Option then flyToggle.Option:AddKeybind({ Name = "Keybind", Flag = "FlyKeybind" }) end
	
	local flyCarSlider = MovementSection:AddSlider({ Name = "Fly Car Speed", Default = 50, Min = 1, Max = 100, Round = 0, Flag = "FlyCarSpeed",
		Callback = function(v) Movement.FlyCar.Speed = v end })
	flyCarSlider:SetVisible(false)
	
	local flyCarToggle = MovementSection:AddToggle({ Name = "Fly Car", Default = false, Option = true, Flag = "FlyCarEnabled",
		Callback = function(v)
			if State.IsResetting then return end
			Movement.FlyCar.Enabled = v
			if v then Movement:StartFlyCar() else Movement:StopFlyCar() end
			flyCarSlider:SetVisible(v)
		end })
	if flyCarToggle.Option then flyCarToggle.Option:AddKeybind({ Name = "Keybind", Flag = "FlyCarKeybind" }) end
	
	local cframeSlider = MovementSection:AddSlider({ Name = "CFrame Speed", Default = 50, Min = 1, Max = 100, Round = 0, Flag = "CFrameSpeedValue",
		Callback = function(v) Movement.CFrameSpeed.Value = v end })
	cframeSlider:SetVisible(false)
	
	local cframeToggle = MovementSection:AddToggle({ Name = "CFrame Speed", Default = false, Option = true, Flag = "CFrameSpeedEnabled",
		Callback = function(v)
			if State.IsResetting then return end
			Movement.CFrameSpeed.Enabled = v
			if v then Movement:StartCFrameSpeed() else Movement:StopCFrameSpeed() end
			cframeSlider:SetVisible(v)
		end })
	if cframeToggle.Option then cframeToggle.Option:AddKeybind({ Name = "Keybind", Flag = "CFrameSpeedKeybind" }) end
	
	local bhopSlider = MovementSection:AddSlider({ Name = "Hop Speed", Default = 50, Min = 1, Max = 100, Round = 0, Flag = "BunnyHopSpeed",
		Callback = function(v) Movement.BunnyHop.Speed = v end })
	bhopSlider:SetVisible(false)
	
	local bhopToggle = MovementSection:AddToggle({ Name = "Bunny Hop", Default = false, Option = true, Flag = "BunnyHopEnabled",
		Callback = function(v)
			if State.IsResetting then return end
			Movement.BunnyHop.Enabled = v
			if v then Movement:StartBunnyHop() else Movement:StopBunnyHop() end
			bhopSlider:SetVisible(v)
		end })
	if bhopToggle.Option then bhopToggle.Option:AddKeybind({ Name = "Keybind", Flag = "BunnyHopKeybind" }) end
	
	local HumanSection = Menus.Misc:AddSection({ Name = "Human", Side = "left", ShowTitle = true, Height = 0 })
	
	local wsSlider = HumanSection:AddSlider({ Name = "Speed", Default = 16, Min = 16, Max = 200, Round = 0, Flag = "WalkSpeedValue",
		Callback = function(v) Movement.WalkSpeed.Value = v end })
	wsSlider:SetVisible(false)
	
	local wsToggle = HumanSection:AddToggle({ Name = "WalkSpeed", Default = false, Option = true, Flag = "WalkSpeedEnabled",
		Callback = function(v)
			if State.IsResetting then return end
			Movement.WalkSpeed.Enabled = v
			wsSlider:SetVisible(v)
			if v then Movement:StartWalkSpeed() else Movement:StopWalkSpeed() end
		end })
	if wsToggle.Option then wsToggle.Option:AddKeybind({ Name = "Keybind", Flag = "WalkSpeedKeybind" }) end
	
	local jpSlider = HumanSection:AddSlider({ Name = "Power", Default = 50, Min = 50, Max = 200, Round = 0, Flag = "JumpPowerValue",
		Callback = function(v) Movement.JumpPower.Value = v end })
	jpSlider:SetVisible(false)
	
	local jpToggle = HumanSection:AddToggle({ Name = "JumpPower", Default = false, Option = true, Flag = "JumpPowerEnabled",
		Callback = function(v)
			if State.IsResetting then return end
			Movement.JumpPower.Enabled = v
			jpSlider:SetVisible(v)
			if v then Movement:StartJumpPower() else Movement:StopJumpPower() end
		end })
	if jpToggle.Option then jpToggle.Option:AddKeybind({ Name = "Keybind", Flag = "JumpPowerKeybind" }) end
	
	local FunSection = Menus.Misc:AddSection({ Name = "Fun", Side = "left", ShowTitle = true, Height = 0 })
	FunSection:AddToggle({ Name = "360", Default = false, Flag = "360Spin",
		Callback = function(v)
			Movement.Spin360.Enabled = v
			if v then Movement:Start360Spin() else Movement:Stop360Spin() end
		end })
	FunSection:AddToggle({ Name = "Fell", Default = false, Flag = "Fell",
		Callback = function(v)
			Character.Fell.Enabled = v
			if v then Character:StartFell() else Character:StopFell() end
		end })
	
	local CharSection = Menus.Misc:AddSection({ Name = "Character", Side = "right", ShowTitle = true, Height = 0 })
	CharSection:AddToggle({ Name = "Noclip", Default = false, Flag = "NoclipEnabled",
		Callback = function(v)
			Character.Noclip.Enabled = v
			if v then Character:EnableNoclip() else Character:DisableNoclip() end
		end })
	CharSection:AddToggle({ Name = "Anti Fling", Default = false, Flag = "AntiFlingEnabled",
		Callback = function(v)
			Character.AntiFling.Enabled = v
			if v then Character:EnableAntiFling() else Character:DisableAntiFling() end
		end })
	CharSection:AddToggle({ Name = "Auto Reload", Default = false, Flag = "AutoReloadEnabled",
		Callback = function(v)
			Character.AutoReload.Enabled = v
			if v then Character:EnableAutoReload() else Character:DisableAutoReload() end
		end })
	CharSection:AddToggle({ Name = "No Slow", Default = false, Flag = "NoSlowEnabled",
		Callback = function(v)
			Character.NoSlow.Enabled = v
			if v then Character:EnableNoSlow() else Character:DisableNoSlow() end
		end })
	CharSection:AddToggle({ Name = "No Jump Cooldown", Default = false, Flag = "NoJumpCooldownEnabled",
		Callback = function(v)
			Character.NoJumpCooldown.Enabled = v
			if v then Character:EnableNoJumpCooldown() else Character:DisableNoJumpCooldown() end
		end })
	CharSection:AddToggle({ Name = "No Seat", Default = false, Flag = "NoSeatEnabled",
		Callback = function(v)
			Character.NoSeat.Enabled = v
			if v then Character:EnableNoSeat() else Character:DisableNoSeat() end
		end })
	CharSection:AddToggle({ Name = "Infinite Zoom", Default = false, Flag = "InfiniteZoomEnabled",
		Callback = function(v)
			Character.InfiniteZoom.Enabled = v
			if v then Character:EnableInfiniteZoom() else Character:DisableInfiniteZoom() end
		end })
	
	local DetectionsSection = Menus.Misc:AddSection({ Name = "Detections", Side = "right", ShowTitle = true, Height = 0 })
	
	DetectionsSection:AddToggle({ Name = "RPG Detection", Default = false, Flag = "RPGDetectionEnabled",
		Callback = function(v)
			Detections.RPGDetection.Enabled = v
			if v or Detections.GranadeDetection.Enabled then
				Detections:StartThreatDetection()
			else
				Detections:StopThreatDetection()
			end
		end })
	
	DetectionsSection:AddToggle({ Name = "Granade Detection", Default = false, Flag = "GranadeDetectionEnabled",
		Callback = function(v)
			Detections.GranadeDetection.Enabled = v
			if v or Detections.RPGDetection.Enabled then
				Detections:StartThreatDetection()
			else
				Detections:StopThreatDetection()
			end
		end })
	
	DetectionsSection:AddToggle({ Name = "Mod Detection", Default = false, Flag = "ModDetectionEnabled",
		Callback = function(v)
			getgenv().ModDetectionEnabled = v
			Detections.ModDetection.Enabled = v
			if v then
				Detections:StartModDetection()
			else
				Detections:StopModDetection()
			end
		end })
end

-- PLAYERS TAB
do
	local PlayerSection = Menus.Players:AddSection({ Name = "Player List", Side = "left", ShowTitle = true, Height = 0 })
	
	PlayerSystem.Dropdown = PlayerSection:AddDropdown({
		Name = "Select Player",
		Values = PlayerSystem:GetPlayerNames(),
		Default = "None",
		Flag = "PlayerSelect",
		Callback = function(v)
			PlayerSystem.SelectedPlayer = v == "None" and nil or Services.Players:FindFirstChild(v)
		end
	})
	
	PlayerSection:AddButton({ Name = "Refresh List", Flag = "RefreshPlayerList",
		Callback = function() PlayerSystem:RefreshDropdown() end })
	PlayerSection:AddButton({ Name = "Knock (Silent Shot)", Flag = "PlayerKnock",
		Callback = function() if PlayerSystem.SelectedPlayer then PlayerSystem:Knock(PlayerSystem.SelectedPlayer) end end })
	PlayerSection:AddButton({ Name = "Kill (Silent Shot)", Flag = "PlayerKill",
		Callback = function() if PlayerSystem.SelectedPlayer then PlayerSystem:Kill(PlayerSystem.SelectedPlayer) end end })
	PlayerSection:AddButton({ Name = "Stop Knock/Kill", Flag = "StopKnockKill",
		Callback = function()
			if PlayerSystem.SelectedPlayer then
				PlayerSystem.KnockActive[PlayerSystem.SelectedPlayer] = nil
				PlayerSystem.KillActive[PlayerSystem.SelectedPlayer] = nil
			end
		end })
	PlayerSection:AddButton({ Name = "Fling", Flag = "PlayerFling",
		Callback = function() if PlayerSystem.SelectedPlayer then PlayerSystem:Fling(PlayerSystem.SelectedPlayer) end end })
	PlayerSection:AddButton({ Name = "Teleport", Flag = "PlayerTeleport",
		Callback = function() if PlayerSystem.SelectedPlayer then PlayerSystem:Teleport(PlayerSystem.SelectedPlayer) end end })
	PlayerSection:AddButton({ Name = "Spectate", Flag = "PlayerSpectate",
		Callback = function() if PlayerSystem.SelectedPlayer then PlayerSystem:Spectate(PlayerSystem.SelectedPlayer) end end })
	PlayerSection:AddButton({ Name = "Stop Spectate", Flag = "StopSpectate",
		Callback = function() PlayerSystem:StopSpectate() end })
	
	-- Настройки Silent Shot
	local SettingsSection = Menus.Players:AddSection({ Name = "Silent Shot Settings", Side = "right", ShowTitle = true, Height = 0 })
	
	SettingsSection:AddSlider({ 
		Name = "Teleport Distance", 
		Default = 30, 
		Min = 10, 
		Max = 100, 
		Round = 0, 
		Flag = "TeleportDistance",
		Callback = function(v) PlayerSystem.SilentShot.TeleportDistance = v end 
	})
	
	SettingsSection:AddToggle({ 
		Name = "Auto Reload", 
		Default = true, 
		Flag = "AutoReloadKill",
		Callback = function(v) PlayerSystem.SilentShot.AutoReload = v end 
	})
	
	-- Auto Kill секция
	local AutoSection = Menus.Players:AddSection({ Name = "Auto Kill", Side = "right", ShowTitle = true, Height = 0 })
	
	AutoSection:AddButton({ Name = "Add to Auto Kill", Flag = "AddAutoKill",
		Callback = function()
			if PlayerSystem.SelectedPlayer and not table.find(PlayerSystem.AutoKillTargets, PlayerSystem.SelectedPlayer) then
				table.insert(PlayerSystem.AutoKillTargets, PlayerSystem.SelectedPlayer)
				PlayerSystem:StartAutoKill()
			end
		end })
	AutoSection:AddButton({ Name = "Remove from Auto Kill", Flag = "RemoveAutoKill",
		Callback = function()
			if PlayerSystem.SelectedPlayer then
				local idx = table.find(PlayerSystem.AutoKillTargets, PlayerSystem.SelectedPlayer)
				if idx then
					table.remove(PlayerSystem.AutoKillTargets, idx)
					PlayerSystem.KillActive[PlayerSystem.SelectedPlayer] = nil
				end
			end
		end })
	AutoSection:AddToggle({ Name = "Auto Kill All", Default = false, Flag = "AutoKillAll",
		Callback = function(v)
			if v then
				for _, p in ipairs(Services.Players:GetPlayers()) do
					if p ~= LocalPlayer and not table.find(PlayerSystem.AutoKillTargets, p) then
						table.insert(PlayerSystem.AutoKillTargets, p)
					end
				end
				PlayerSystem:StartAutoKill()
			else
				PlayerSystem:StopAutoKill()
			end
		end })
end

-- SETTINGS TAB
do
	local UI = Menus.Settings:AddSection({ Name = "UI", Side = "left", ShowTitle = true, Height = 0 })

	UI:AddKeybind({
		Name = "Toggle Menu",
		Default = Enum.KeyCode.Insert,
		Option = false,
		Flag = "ToggleMenu",
		Callback = function(key)
			if typeof(key) == "EnumItem" then
				State.MenuToggleKey = key
				Window:SetToggleKeybind(key)
			elseif typeof(key) == "string" then
				pcall(function()
					State.MenuToggleKey = Enum.KeyCode[key]
					Window:SetToggleKeybind(Enum.KeyCode[key])
				end)
			end
		end
	})

	UI:AddColorPicker({
		Name = "Background",
		Default = Config.Theme.Background,
		Callback = function(c)
			Window:SetTheme({ Background = c, Panel = c })
		end,
		Flag = "MainColor"
	})

	UI:AddColorPicker({
		Name = "Accent",
		Default = Config.Theme.Accent,
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
		Default = Config.Theme.Text,
		Callback = function(c)
			Window:SetTheme({ Text = c })
		end,
		Flag = "TextColor"
	})

	UI:AddColorPicker({
		Name = "Slider",
		Default = Config.Theme.SliderAccent,
		Callback = function(c)
			Window:SetTheme({ SliderAccent = c })
		end,
		Flag = "SliderColor"
	})

	UI:AddColorPicker({ 
		Name = "Toggle", 
		Default = Config.Theme.ToggleAccent, 
		Callback = function(c) Window:SetTheme({ ToggleAccent = c }) end, 
		Flag = "ToggleColor" 
	})

	UI:AddColorPicker({ 
		Name = "Tab Selected", 
		Default = Config.Theme.TabSelected, 
		Callback = function(c) Window:SetTheme({ TabSelected = c }) end, 
		Flag = "TabSelectedColor" 
	})

	UI:AddColorPicker({ 
		Name = "Tab Unselected", 
		Default = Config.Theme.TabUnselected, 
		Callback = function(c) Window:SetTheme({ TabUnselected = c }) end, 
		Flag = "TabUnselectedColor" 
	})

	UI:AddColorPicker({ 
		Name = "Header", 
		Default = Config.Theme.Header, 
		Callback = function(c) Window:SetTheme({ Header = c }) end, 
		Flag = "HeaderColor" 
	})

	UI:AddColorPicker({ 
		Name = "Panel", 
		Default = Config.Theme.Panel, 
		Callback = function(c) Window:SetTheme({ Panel = c }) end, 
		Flag = "PanelColor" 
	})

	UI:AddColorPicker({ 
		Name = "Field", 
		Default = Config.Theme.Field, 
		Callback = function(c) Window:SetTheme({ Field = c }) end, 
		Flag = "FieldColor" 
	})

	UI:AddColorPicker({ 
		Name = "Stroke", 
		Default = Config.Theme.Stroke, 
		Callback = function(c) Window:SetTheme({ Stroke = c }) end, 
		Flag = "StrokeColor" 
	})

	UI:AddColorPicker({ 
		Name = "Text Dim", 
		Default = Config.Theme.TextDim, 
		Callback = function(c) Window:SetTheme({ TextDim = c }) end, 
		Flag = "TextDimColor" 
	})

	UI:AddColorPicker({ 
		Name = "Warning", 
		Default = Config.Theme.Warning, 
		Callback = function(c) Window:SetTheme({ Warning = c }) end, 
		Flag = "WarningColor" 
	})

	UI:AddColorPicker({ 
		Name = "Shadow", 
		Default = Config.Theme.Shadow, 
		Callback = function(c) Window:SetTheme({ Shadow = c }) end, 
		Flag = "ShadowColor" 
	})

	UI:AddColorPicker({ 
		Name = "Profile Stroke", 
		Default = Config.Theme.ProfileStroke, 
		Callback = function(c) Window:SetTheme({ ProfileStroke = c }) end, 
		Flag = "ProfileStrokeColor" 
	})

	UI:AddColorPicker({ 
		Name = "Logo Text", 
		Default = Config.Theme.LogoText, 
		Callback = function(c) Window:SetTheme({ LogoText = c }) end, 
		Flag = "LogoTextColor" 
	})

	UI:AddColorPicker({ 
		Name = "Logo Stroke", 
		Default = Config.Theme.LogoStroke, 
		Callback = function(c) 
			Config.Theme.LogoStroke = c
			Window:SetTheme({ LogoStroke = c }) 
		end, 
		Flag = "LogoStrokeColor" 
	})

	UI:AddColorPicker({ 
		Name = "Username Text", 
		Default = Config.Theme.UsernameText, 
		Callback = function(c) 
			Config.Theme.UsernameText = c
			Window:SetTheme({ UsernameText = c }) 
		end, 
		Flag = "UsernameTextColor" 
	})

	UI:AddColorPicker({ 
		Name = "Dropdown Selected", 
		Default = Config.Theme.DropdownSelected, 
		Callback = function(c) 
			Config.Theme.DropdownSelected = c
			Window:SetTheme({ DropdownSelected = c }) 
		end, 
		Flag = "DropdownSelectedColor" 
	})
end

print("[RAY] Loaded!")
