local runService = game:GetService("RunService")

local QuickChaser = {}
QuickChaser.__index = QuickChaser

local function log(str, callback)
	callback(("[%s] %s"):format(script.Name, str))	
end

function QuickChaser.newChaser(dronesInformation, speed, period, orderGroup)
	local self = setmetatable({
		speed = speed,
		period = period,
		orderGroup = orderGroup,
		currentPosition = dronesInformation[1],
		currentDrones = dronesInformation[2],
		renderStepped = nil,
		theta = 0
	}, QuickChaser)
	
	self.renderStepped = runService.RenderStepped:Connect(function()
		self.theta += self.speed
		for index = 1, 50 do
			
			for drIndex,drone in self.currentDrones do
				if self.currentPosition[drIndex].Orders[orderGroup] == index then
					drone.Light.Transparency = .5 + math.sin(self.theta - index / self.period) * .5
					drone.Light.PointLight.Brightness = 1 + math.sin(self.theta - index / self.period) * -1
				end
			end
		end
	end)
	
	return self
end

function QuickChaser:Destroy()
	if self.renderStepped then 
		self.renderStepped:Disconnect()
		self.renderStepped = nil
		
		for _,drone in self.currentDrones do
			drone.Light.Transparency = 1
			drone.Light.PointLight.Brightness = 0
		end
	else
		log("no chaser to destroy", warn)
	end
end

return QuickChaser