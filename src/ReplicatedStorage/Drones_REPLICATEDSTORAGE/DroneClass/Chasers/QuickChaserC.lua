local runService = game:GetService("RunService")

local QuickChaser = {}
QuickChaser.__index = QuickChaser

local function calculateWave(startV: number, endV: number)
	local firstNumber = startV + (endV - startV) / 2
	local secondNumber = firstNumber - startV

	return firstNumber, secondNumber
end

local function log(str, callback)
	callback(("[%s] %s"):format(script.Name, str))	
end

function QuickChaser.newChaser(dronesInformation, speed, period, orderGroup, colors)
	local self = setmetatable({
		speed = speed,
		period = period,
		orderGroup = orderGroup,
		colorTable = colors,
		currentPosition = dronesInformation[1],
		currentDrones = dronesInformation[2],
		renderStepped = nil,
		theta = 0
	}, QuickChaser)
	
	if not self.colorTable.color1 then self.colorTable.color1 = Color3.fromRGB(255, 0, 0) end
	if not self.colorTable.color2 then self.colorTable.color2 = Color3.fromRGB(255, 255, 255) end
	
	local h1, s1, v1 = self.colorTable.color1:ToHSV()
	local h2, s2, v2 = self.colorTable.color2:ToHSV()
	local hue1, hue2 = calculateWave(h1, h2)
	local saturation1, saturation2 = calculateWave(s1, s2)
	local value1, value2 = calculateWave(v1, v2)
	
	self.renderStepped = runService.RenderStepped:Connect(function()
		self.theta += self.speed
		for index = 1, 50 do
			
			for drIndex,drone in self.currentDrones do
				if self.currentPosition[drIndex].Orders[orderGroup] == index then
					drone.Light.Color = Color3.fromHSV(hue1 + math.sin(self.theta - index / self.period) * hue2, saturation1 + math.sin(self.theta - index / self.period) * saturation2, value1 + math.sin(self.theta - index / self.period) * value2)
					drone.Light.PointLight.Color = Color3.fromHSV(hue1 + math.sin(self.theta - index / self.period) * hue2, saturation1 + math.sin(self.theta - index / self.period) * saturation2, value1 + math.sin(self.theta - index / self.period) * value2)
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