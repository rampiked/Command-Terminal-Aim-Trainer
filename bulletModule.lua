--Server Script--

--bulletModule
local tool = script.Parent
local shootEvent = tool:WaitForChild("ShootEvent")
local bulletVisualEvent = tool:WaitForChild("BulletVisual")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("CommandRemote")
local updateAccuracyEvent = ReplicatedStorage:WaitForChild("UpdateAccuracy") -- NEW

-- GLOBAL STATS
_G.TotalShots = _G.TotalShots or 0
_G.TotalHits = _G.TotalHits or 0

shootEvent.OnServerEvent:Connect(function(player, clickPos, clickTarget)
	_G.TotalShots += 1

	local toolInstance = player.Backpack:FindFirstChild("GPR") or player.Character:FindFirstChild("GPR")
	if not toolInstance then return end

	local rayOrigin = toolInstance:FindFirstChild("RayOrigin")
	if not rayOrigin then return end

	local origin = rayOrigin.Position
	local direction = clickPos - origin
	local hitHumanoid = nil
	local finalHitPos = clickPos
	local hitCounted = false

	local character = clickTarget and clickTarget:FindFirstAncestorOfClass("Model")
	if character then
		hitHumanoid = character:FindFirstChildOfClass("Humanoid")
		if hitHumanoid and clickTarget.Position then
			finalHitPos = clickTarget.Position
		end
	end

	if not hitHumanoid then
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {player.Character, toolInstance}
		rayParams.IgnoreWater = true
		local result = workspace:Raycast(origin, direction, rayParams)
		if result then
			local hitPart = result.Instance
			local char2 = hitPart and hitPart:FindFirstAncestorOfClass("Model")
			if char2 then
				hitHumanoid = char2:FindFirstChildOfClass("Humanoid")
			end
			finalHitPos = result.Position
		end
	end

	if hitHumanoid and hitHumanoid.Health > 0 then
		hitHumanoid:TakeDamage(10)
		_G.TotalHits += 1
		hitCounted = true
	end

	-- Fire bullet visuals
	bulletVisualEvent:FireAllClients(finalHitPos, hitCounted)

	-- 🔹 Send updated accuracy to the player’s GUI
	local accuracy = 0
	if _G.TotalShots > 0 then
		accuracy = math.floor((_G.TotalHits / _G.TotalShots) * 100)
	end
	updateAccuracyEvent:FireClient(player, accuracy)
end)
