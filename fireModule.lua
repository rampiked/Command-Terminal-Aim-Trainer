--LOCAL SCRIPT--

--fireModule
local tool = script.Parent
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local shootEvent = tool:WaitForChild("ShootEvent")
local bulletVisualEvent = tool:WaitForChild("BulletVisual")
local holding = false

local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local fastPing = SoundService:WaitForChild("FastPing")
local CursorManager = require(game.ReplicatedStorage:WaitForChild("CursorManager"))

-- Only allow shooting if tool is currently equipped
local function canShoot()
	return tool.Parent == player.Character
end

-- Apply cursor
local function applyCursor()
	if canShoot() then
		UserInputService.MouseIcon = CursorManager:GetCursor()
	end
end

-- Listen for cursor changes
CursorManager.ChangedConnection = CursorManager.ChangedConnection or {}
table.insert(CursorManager.ChangedConnection, applyCursor)

-- Equipped event
tool.Equipped:Connect(function()
	task.wait() -- ensure tool is parented
	applyCursor() -- apply latest cursor

	local function startShooting()
		if holding then return end
		if not canShoot() then return end
		holding = true
		task.spawn(function()
			while holding and canShoot() do
				if mouse.Hit then
					shootEvent:FireServer(mouse.Hit.Position, mouse.Target)
				end
				task.wait(0.075)
			end
			holding = false
		end)
	end

	local function stopShooting()
		holding = false
	end

	mouse.Button1Down:Connect(startShooting)
	mouse.Button1Up:Connect(stopShooting)
end)

-- Unequipped event
tool.Unequipped:Connect(function()
	UserInputService.MouseIcon = "" -- reset cursor
	holding = false
end)

-- Bullet visuals and humanoid hit sound
bulletVisualEvent.OnClientEvent:Connect(function(finalHitPos, hitCounted)
	local rayOrigin = tool:FindFirstChild("RayOrigin")
	if not rayOrigin then return end

	local origin = rayOrigin.Position
	local direction = finalHitPos - origin

	-- Bullet visual
	local gunRay = Instance.new("Part")
	gunRay.Color = Color3.fromRGB(181, 121, 0)
	gunRay.Size = Vector3.new(0.1, 0.1, direction.Magnitude)
	gunRay.CFrame = CFrame.new(origin, finalHitPos) * CFrame.new(0, 0, -direction.Magnitude / 2)
	gunRay.Anchored = true
	gunRay.CanCollide = false
	gunRay.Material = Enum.Material.Neon
	gunRay.Parent = workspace
	game:GetService("Debris"):AddItem(gunRay, 0.025)

	-- Play sound only if humanoid was alive when hit
	if hitCounted then
		local pingClone = fastPing:Clone()
		pingClone.Parent = workspace
		pingClone:Play()
		game:GetService("Debris"):AddItem(pingClone, pingClone.TimeLength)
	end
end)
