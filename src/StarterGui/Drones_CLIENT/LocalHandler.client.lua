local rs = game:GetService("ReplicatedStorage")
local ts = game:GetService("TweenService")
local drones = rs:WaitForChild("Drones_REPLICATEDSTORAGE")
local runService = game:GetService("RunService")

local droneClass = require(drones:WaitForChild("DroneClass"))
local positions = require(drones:WaitForChild("Positions"))
local event = drones:WaitForChild("StartDrones")

local mainDrones = droneClass.new()
mainDrones.originPart = workspace.originPart --calibration part
mainDrones.spawnPart = workspace.spawningPart --part where the drones spawn
mainDrones.droneReference = workspace.DroneCopy --the reference for the drone model, can be edited

function droneSequence()
	local speed = 10
	mainDrones:SetPositions(true, {positions.cube1, positions.cube2})
	mainDrones:ProgressPosition({speed = speed, willTween = true})
	mainDrones:SetColorGroup({color = Color3.fromRGB(255, 197, 102), groupId = 1})
	mainDrones:SetColorGroup({color = Color3.fromRGB(0, 255, 255), groupId = 2})
	
	task.wait(1)
	
	--local a = mainDrones:QuickChaserT({orderGroup = "Order1", speed = .1, period = .25})
	local b = mainDrones:QuickChaserC({
		orderGroup = "Order1", speed = .1,
		period = .5,
		colors = {color1 = Color3.fromRGB(0, 255, 0), color2 = Color3.fromRGB(255, 255, 255)}
	})
    
	task.wait(10)
	
	mainDrones:ProgressPosition({speed = speed})
	b:Destroy()
end

event.OnClientEvent:Connect(function(progress)
	droneSequence()
end)
