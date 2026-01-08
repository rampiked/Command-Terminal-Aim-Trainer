--Server Script--

-- botScript
local gameSettings = require(game.ServerStorage:WaitForChild("gameSettings"))
local botTemplate = game.ReplicatedStorage:WaitForChild("Bot")
local toolTemplate = game.ReplicatedStorage:WaitForChild("GPR")

-- Events to update wall distance or bot quantity
local wallDistChanged = Instance.new("BindableEvent")
wallDistChanged.Name = "WallDistChanged"
wallDistChanged.Parent = script

local botQuantityChanged = Instance.new("BindableEvent")
botQuantityChanged.Name = "BotQuantityChanged"
botQuantityChanged.Parent = script

local botQuantity = gameSettings.botQuantity or 1

-- Random position helpers
local function getRandomPosition()
	local range = gameSettings.wallDistValue or 75
	local cushion = 4
	local x = math.random(-range + cushion, range - cushion)
	local z = math.random(-range + cushion, range - cushion)
	return Vector3.new(x, 0, z)
end

local function clampPosition(pos)
	local range = gameSettings.wallDistValue or 75
	local cushion = 4
	return Vector3.new(
		math.clamp(pos.X, -range + cushion, range - cushion),
		pos.Y,
		math.clamp(pos.Z, -range + cushion, range - cushion)
	)
end

-- Ensure R6 Motor6Ds (guarantees consistent limb setup)
local function ensureR6Motors(bot)
	local torso = bot:FindFirstChild("Torso")
	if not torso then return end
	local leftArm = bot:FindFirstChild("Left Arm")
	local rightArm = bot:FindFirstChild("Right Arm")
	local leftLeg = bot:FindFirstChild("Left Leg")
	local rightLeg = bot:FindFirstChild("Right Leg")
	local head = bot:FindFirstChild("Head")

	local function attachMotor(name, part0, part1, c0, c1)
		if not part0 or not part1 then return end
		if not part0:FindFirstChild(name) then
			local motor = Instance.new("Motor6D")
			motor.Name = name
			motor.Part0 = part0
			motor.Part1 = part1
			motor.C0 = c0 or CFrame.new()
			motor.C1 = c1 or CFrame.new()
			motor.Parent = part0
		end
	end

	attachMotor("Left Shoulder", torso, leftArm, CFrame.new(-1,0.5,0), CFrame.new())
	attachMotor("Right Shoulder", torso, rightArm, CFrame.new(1,0.5,0), CFrame.new())
	attachMotor("Left Hip", torso, leftLeg, CFrame.new(-0.5,-1,0), CFrame.new())
	attachMotor("Right Hip", torso, rightLeg, CFrame.new(0.5,-1,0), CFrame.new())
	attachMotor("Neck", torso, head, CFrame.new(0,1,0), CFrame.new())
end

-- Pose arms and attach GPR (matches Owen’s orientation)
local function poseArmsWithGPR(bot)
	local torso = bot:FindFirstChild("Torso")
	local leftArm = bot:FindFirstChild("Left Arm")
	local rightArm = bot:FindFirstChild("Right Arm")
	if not (torso and leftArm and rightArm) then return end

	-- Remove default shoulders temporarily
	local shL = torso:FindFirstChild("Left Shoulder")
	local shR = torso:FindFirstChild("Right Shoulder")
	if shL then shL.Part1 = nil end
	if shR then shR.Part1 = nil end

	-- Custom left arm weld (same as Owen’s)
	local weldL = torso:FindFirstChild("LeftArmWeld")
	if not weldL then
		weldL = Instance.new("Weld")
		weldL.Name = "LeftArmWeld"
		weldL.Part0 = torso
		weldL.Part1 = leftArm
		weldL.C1 = CFrame.new(0.8, 0.5, 0.4) * CFrame.Angles(math.rad(270), math.rad(40), 0)
		weldL.Parent = torso
	end

	-- Custom right arm weld (same as Owen’s)
	local weldR = torso:FindFirstChild("RightArmWeld")
	if not weldR then
		weldR = Instance.new("Weld")
		weldR.Name = "RightArmWeld"
		weldR.Part0 = torso
		weldR.Part1 = rightArm
		weldR.C1 = CFrame.new(-1.2, 0.5, 0.4) * CFrame.Angles(math.rad(270), math.rad(-5), 0)
		weldR.Parent = torso
	end

	-- Clone GPR as display object (no Tool behavior)
	local gpr = toolTemplate:Clone()
	gpr.Parent = bot
	local handle = gpr:FindFirstChild("Handle")

	if handle then
		handle.Anchored = false
		handle.CanCollide = false
		handle.Massless = true

		-- Attach to right arm with precise alignment
		local weld = Instance.new("Weld")
		weld.Name = "GPRWeld"
		weld.Part0 = rightArm
		weld.Part1 = handle
		weld.C0 = CFrame.new(-0.1, -0.55, -0.25) * CFrame.Angles(math.rad(-90), math.rad(90), 0)
		weld.Parent = rightArm
	end
end

-- Enable humanoid movement and walking animation
local function enableHumanoidPhysics(bot)
	local humanoid = bot:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	for _, part in ipairs(bot:GetChildren()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = true
		end
	end

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn

	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local walkAnim = Instance.new("Animation")
	walkAnim.AnimationId = "rbxassetid://507771019" -- R6 walk
	local walkTrack = animator:LoadAnimation(walkAnim)
	walkTrack.Priority = Enum.AnimationPriority.Movement
	walkTrack:Play()
end

-- Get first player root for movement reference
local function getFirstPlayerRoot()
	local player = game.Players:GetPlayers()[1]
	if player then
		if player.Character then
			return player.Character:WaitForChild("Torso")
		else
			return player.CharacterAdded:Wait():WaitForChild("Torso")
		end
	end
	player = game.Players.PlayerAdded:Wait()
	return player.CharacterAdded:Wait():WaitForChild("Torso")
end

-- Movement behavior
local function startErraticMovement(bot, humanoid)
	local root = bot:FindFirstChild("Torso")
	if not root then return end
	local playerRoot = getFirstPlayerRoot()

	task.spawn(function()
		while bot.Parent and humanoid.Health > 0 do
			local strafeDir = (math.random(0,1) == 0) and -1 or 1
			local burstLength
			local r = math.random()
			if r < 0.2 then
				burstLength = math.random(16,25)
			elseif r < 0.7 then
				burstLength = math.random(11,15)
			else
				burstLength = math.random(6,10)
			end

			local jumpThisBurst = (math.random() < 0.2)
			local jumpStepChance = 0.25

			for _ = 1, burstLength do
				if not bot.Parent or humanoid.Health <= 0 then break end
				local toPlayer = playerRoot.Position - root.Position
				toPlayer = Vector3.new(toPlayer.X,0,toPlayer.Z)
				local tangent = Vector3.new(-toPlayer.Z,0,toPlayer.X).Unit * strafeDir
				local stepDist = math.random(2,6)
				local movePos = clampPosition(root.Position + tangent * stepDist)
				movePos = Vector3.new(movePos.X, root.Position.Y, movePos.Z)

				local direction = movePos - root.Position
				direction = Vector3.new(direction.X,0,direction.Z)
				if direction.Magnitude > 0.1 then
					humanoid:Move(direction.Unit, false)
				end

				if jumpThisBurst and math.random() < jumpStepChance then
					humanoid.Jump = true
				end

				task.wait(math.random(0.15,0.3))
			end
			humanoid:Move(Vector3.new(0,0,0), false)
			task.wait(math.random(0.3,0.6))
		end
	end)
end

-- Spawn bot
local function spawnBot(oldBot)
	if oldBot and oldBot.Parent then oldBot:Destroy() end

	local bot = botTemplate:Clone()
	bot.Parent = workspace

	local torso = bot:FindFirstChild("Torso")
	if not torso then warn("Bot missing Torso") return end
	bot.PrimaryPart = torso
	bot:SetPrimaryPartCFrame(CFrame.new(getRandomPosition() + Vector3.new(0,5,0)))

	local humanoid = bot:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true

		ensureR6Motors(bot)
		enableHumanoidPhysics(bot)
		poseArmsWithGPR(bot)

		humanoid.Died:Connect(function()
			task.wait(1)
			spawnBot(bot)
		end)

		startErraticMovement(bot, humanoid)
	end
end

-- Initial spawn
for i = 1, botQuantity do
	spawnBot(nil)
end

-- Wall distance update
wallDistChanged.Event:Connect(function()
	for _, bot in ipairs(workspace:GetChildren()) do
		if bot.Name == botTemplate.Name then bot:Destroy() end
	end
	for i = 1, botQuantity do
		spawnBot(nil)
	end
end)

-- Bot quantity update
botQuantityChanged.Event:Connect(function(newQuantity)
	botQuantity = newQuantity
	gameSettings.botQuantity = botQuantity
	for _, bot in ipairs(workspace:GetChildren()) do
		if bot.Name == botTemplate.Name then bot:Destroy() end
	end
	for i = 1, botQuantity do
		spawnBot(nil)
	end
end)
