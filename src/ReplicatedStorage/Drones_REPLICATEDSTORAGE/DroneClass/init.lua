--[[
	DroneClass
	by usercontent0
	2021-2022
	
	Template:
		propertyName [type]
		:FunctionName(arguments [type]) [returns]
	
	Constructors:
		new()
			> new ting, the usual
			
	Properties:
		originPart [Instance]
			> the part to calibrate the drones positions
		spawnPart [Instance]
			> the part where the drones spawn 
		droneReference [Instance]
			> the original drone model
			
	Methods:	
		:SetPositions(resetIndex [boolean], {...})
			> sets positionTable for drones
			  if resetIndex is set to true, old positionTable gets cleared (default to true)
			
		:SetAppropriateColor()
			> sets colors for drones light as set in positionTable
			
		:SetAppropriateColor_f({ speed [number] })
			> sets CIELUV color fade for drones light as set in positionTable
			  speed is set in 1/speed seconds
		
		:SetColorAll({ color [Color3] })
			> sets customizable color for all active drones
			
		:SetColorAll_f({ color [Color3], speed [number] })
			> sets customizable CIELUV color fade for all active drones
			  speed is set in 1/speed seconds
			
		:SetColorGroup({ color [Color3], groupId [number] })
			> sets customizable color for all active drones in group with id 'groupId'
			
		:SetColorGroup_f({ color [Color3], speed [number], groupId [number] })
			> sets customizable CIELUV color fade for all active drones in group with id 'groupId'
			  speed is set in 1/speed seconds
			
		:ProgressPosition({ speed [number] })
			> moves the drones to the (currentIndex + 1)th position as set in positionTable, currentIndex starting at 0
			  speed is set in seconds
			  can be called #positionTable times
			
		:Orbit({ speed [number], groupId [number], axis [table {x [boolean], y [boolean], z [boolean]}], centerVector [Vector3] (optional) })
			> orbits selected group around its center (default), custom center vector can be defined
			  axis table default to {x=false, y=true, z=false}
			
		:UnOrbit({ groupId [number] })
			> unorbits selected group, resets orientation to (0, 0, 0) (i think)
		
		:QuickChaserT({ speed [number], period [number], attributeName [string] })
			> creates a quick sine function for the drones light transparency
			  works with attributes
			  
		:QuickChaserC({ speed [number], period [number], attributeName [string], colors [table {color1 [Color3], color2 [Color3]}] })
			> creates a quick sine function for the drones light color
			  will create a lerp between two given colors, defaults to {color1=Color3.fromRGB(255, 0, 0), color2=Color3.fromRGB(255, 255, 255)}
			  works with attributes
			  
		:DestroyAllDrones()
			> deletes all drones, cleans up tables
--]]

math.randomseed(os.time())
local CIELUV = require(script.CIELUV)
local CustomTween = require(script.CustomTween)
local QuickChaserT = require(script.Chasers.QuickChaserT)
local QuickChaserC = require(script.Chasers.QuickChaserC)
local runService = game:GetService("RunService")

local droneClass = {}
droneClass.__index = droneClass

local posRange = 750
local liftOffHeight = 125

function droneClass.new()
	local self = setmetatable({
		drones = {},
		positionTable = {},
		renderStepped = {},
		positionIndex = 1,
		isFirstDone = false,
		
		originPart = nil,
		spawnPart = nil,
		droneReference = nil
	}, droneClass)

	init(self)
	return self
end

function init(self)
	if workspace:FindFirstChild("MovementDrones") == nil then
		local folder = Instance.new("Folder", workspace)
		folder.Name = "MovementDrones"
		self.dronesParent = folder
	else
		self.dronesParent = workspace:FindFirstChild("MovementDrones")
	end
end

local function newPart(name: string, parent: Instance): Instance
	local part = Instance.new("Part", parent)
	part.Name = name
	part.Anchored = true
	part.Transparency = 1

	return part
end

local function log(str: string, callback)
	callback(("[%s] %s"):format(script.Name, str))	
end

----public classes----

--/////////////////////////////////////////////////////////////--

function droneClass:NewDrone(): Instance
	local clone = self.droneReference:Clone()
	clone.Parent = self.dronesParent	
	self.drones[#self.drones + 1] = clone

	return clone
end

function droneClass:RemoveDrone(drone: Instance)
	self.drones[drone] = nil

	for _,physicalDrone in self.dronesParent:GetChildren() do
		if physicalDrone == drone then
			physicalDrone:Destroy()
		end
	end
end

function droneClass:SpawnDrones()
	local quantity = #self.positionTable[self.positionIndex]
	local xQuantity, zQuantity = 10, 10
	local x, z = 0, 0
	local distance = 10

	local groupSize = xQuantity * zQuantity
	local currentGroup = 1
	local groupX = 0

	for drone = 1, quantity do
		if drone > currentGroup*groupSize then
			currentGroup += 1
			groupX = (currentGroup - 1) * xQuantity * distance
			x = groupX
			z = 0
		elseif drone ~= 1 then
			if (x + distance < groupX + xQuantity * distance) then
				x += distance
			else
				x = groupX
				z -= distance
			end
		end
		
		local createdDrone = self:NewDrone()
		createdDrone:PivotTo(CFrame.new(self.spawnPart.Position - Vector3.new(x, 0, z)))
	end	

	log("spawned " .. #self.positionTable[self.positionIndex] .. " needed drones", print)
end

function droneClass:LiftOff(speed: number)
	for i = 1, #self.positionTable[self.positionIndex] do
		local value = Instance.new("CFrameValue")
		value.Value = self.drones[i]:GetPivot()

		value.Changed:Connect(function()
			self.drones[i]:PivotTo(value.Value)
		end)

		local tween = CustomTween:Create(value, {
			Time = speed + (math.random(-100, 100) / 1000),
			EasingStyle = "EntranceExpressive",
			EasingDirection = "In",

			StepType = "RenderStepped",

			Goal = {
				Value = value.Value + Vector3.new(
					math.random(-posRange, posRange) / 1000,
					liftOffHeight + math.random(-posRange, posRange) / 1000,
					math.random(-posRange, posRange) / 1000
				)
			}
		})
		tween:Play()
		tween.Completed:Connect(function()
			value:Destroy()
			tween:Destroy()
		end)
	end
end

function droneClass:ProgressPositionIndex()
	if self.positionIndex < #self.positionTable then
		self.positionIndex += 1
	else
		log("no more positions in pos table", warn)
	end
end

--/////////////////////////////////////////////////////////////--

function droneClass:SetPositions(resetIndex: boolean, positions)
	if resetIndex == nil then resetIndex = true end
	if resetIndex then self.positionIndex = 1 end

	for _, value in positions do
		table.insert(self.positionTable, value)
	end
end

function droneClass:SetAppropriateColor()
	for i = 1, #self.positionTable[self.positionIndex] do
		local thatColor = self.positionTable[self.positionIndex][i].Color

		if self.drones[i] ~= nil then		
			self.drones[i].Light.Color = thatColor
			self.drones[i].Light.PointLight.Color = thatColor
		end		
	end
end

function droneClass:SetAppropriateColor_f(givenTable)
	local speed = givenTable.speed

	spawn(function()
		for t = 0, 1, 1/speed do
			for i = 1, #self.positionTable[self.positionIndex] do
				local thatColor = self.positionTable[self.positionIndex][i].Color
				local lerpAB = CIELUV(self.drones[i].Light.Color, thatColor)

				self.drones[i].Light.Color = lerpAB(t)
				self.drones[i].Light.PointLight.Color = lerpAB(t)
			end

			task.wait()
		end
	end)
end

function droneClass:SetColorAll(givenTable)
	local color = givenTable.color

	for _, drone in self.drones do
		drone.Light.Color = color
		drone.Light.PointLight.Color = color
	end
end

function droneClass:SetColorAll_f(givenTable)
	local color = givenTable.color
	local speed = givenTable.speed

	spawn(function()
		for t = 0, 1, 1/speed do
			for _, drone in self.drones do
				local lerpAB = CIELUV(drone.Light.Color, color)
				drone.Light.Color = lerpAB(t)
				drone.Light.PointLight.Color = lerpAB(t)
			end

			task.wait()
		end
	end)
end

function droneClass:SetColorGroup(givenTable)
	local color = givenTable.color
	local groupId = givenTable.groupId

	for i = 1, #self.positionTable[self.positionIndex] do
		if self.positionTable[self.positionIndex][i].GroupId == groupId then
			self.drones[i].Light.Color = color
			self.drones[i].Light.PointLight.Color = color
		end
	end
end

function droneClass:SetColorGroup_f(givenTable)
	local color = givenTable.color
	local speed = givenTable.speed
	local groupId = givenTable.groupId
	local firstColor

	for i = 1, #self.positionTable[self.positionIndex] do
		if self.positionTable[self.positionIndex][i].GroupId == groupId then firstColor = self.drones[i].Light.Color break end
	end
	local lerpAB = CIELUV(firstColor, color)

	spawn(function()
		for t = 0, 1, 1/speed do
			for i = 1, #self.positionTable[self.positionIndex] do
				if self.positionTable[self.positionIndex][i].GroupId == groupId then 
					self.drones[i].Light.Color = lerpAB(t)
					self.drones[i].Light.PointLight.Color = lerpAB(t)
				end
			end

			task.wait()
		end
	end)
end

function droneClass:Orbit(givenTable)
	local speed = givenTable.speed
	local groupId = givenTable.groupId
	local centerVector = givenTable.centerVector
	local axis = givenTable.axis
	if not axis then axis = {x=false, y=true, z=false} end
	if not axis.x then axis.x = false elseif not axis.y then axis.y = true elseif not axis.z then axis.z = false end

	local newGroup = Instance.new("Model", self.dronesParent)
	newGroup.Name = "group_" .. groupId
	speed = speed / 1000

	for i = 1, #self.positionTable[self.positionIndex] do
		if self.positionTable[self.positionIndex][i].GroupId == groupId then self.drones[i].Parent = newGroup end
	end

	centerVector = centerVector or newGroup:GetBoundingBox().Position

	local part = newPart("centerPart.group_" .. groupId, newGroup)
	part.Position = centerVector
	newGroup.PrimaryPart = part

	self.renderStepped["group" .. groupId] = runService.RenderStepped:Connect(function()
		newGroup:PivotTo(newGroup:GetPivot() * CFrame.fromEulerAnglesXYZ(axis.x and speed or 0, axis.y and speed or 0, axis.z and speed or 0))
	end)
end

function droneClass:UnOrbit(givenTable)
	local groupId = givenTable.groupId
	local thatFunction = self.renderStepped["group" .. groupId]

	if thatFunction then
		thatFunction:Disconnect()
		thatFunction = nil
	else
		log("orbit of group " .. groupId .. " does not exist", warn)
		return
	end

	for i = 1, #self.positionTable[self.positionIndex] do
		if self.positionTable[self.positionIndex][i].GroupId == groupId then
			self.drones[i].Parent = self.dronesParent
			self.drones[i]:PivotTo(self.drones[i].CFrame * CFrame.Angles(0, 0, 0)) --this never worked
		end
	end
	self.dronesParent:WaitForChild("group_" .. groupId):Destroy()
end

function droneClass:QuickChaserT(givenTable)
	return QuickChaserT.newChaser({self.positionTable[self.positionIndex], self.drones}, givenTable.speed, givenTable.period, givenTable.orderGroup)
end

function droneClass:QuickChaserC(givenTable)
	return QuickChaserC.newChaser({self.positionTable[self.positionIndex], self.drones}, givenTable.speed, givenTable.period, givenTable.orderGroup, givenTable.colors)	
end

function droneClass:ProgressPosition(givenTable)
	local speed = givenTable.speed
	local willTween = givenTable.willTween
	if willTween == nil then willTween = true end
	
	if not self.isFirstDone then
		self:SpawnDrones()
		self:LiftOff(speed/2)
		self.isFirstDone = true
		
		task.wait(speed/2 + 1)
		log("first position: initiate", print)
	elseif self.isFirstDone then
		self:ProgressPositionIndex()
		
		--if the next position needs more drones (= has more positions in table), it adds the missing drones to it--
		if #self.positionTable[self.positionIndex] > #self.drones then
			local currentDrones = #self.drones
			local missingDrones = #self.positionTable[self.positionIndex] - currentDrones

			for index = 1, missingDrones do
				local newDrone = self:NewDrone()
				newDrone:PivotTo(self.drones[math.random(1, currentDrones)]:GetPivot()) --seamless adding (probably)			
			end

			log("spawned all missing drones", print)

			--if the next position needs less drones (= has less positions in table), it removes the unused drones--
		elseif #self.positionTable[self.positionIndex] < #self.drones then
			for index,drone in self.drones do
				if self.positionTable[self.positionIndex][index] == nil then
					self:RemoveDrone(drone)
				end
			end

			log("removed all unneeded drones", print)
		end
	end
		
	for i = 1, #self.positionTable[self.positionIndex] do
		local newPosition = self.positionTable[self.positionIndex][i].Position
		local oldPosition = self.positionTable[self.positionIndex-1][i].Position or nil

		local thatPosition = self.originPart.Position - newPosition

		if (newPosition ~= oldPosition) then
			if willTween then
				local value = Instance.new("CFrameValue")
				value.Value = self.drones[i]:GetPivot()

				value.Changed:Connect(function()
					self.drones[i]:PivotTo(value.Value)
				end)

				local tween = CustomTween:Create(value, {
					Time = speed + (math.random(-100, 100) / 1000),
					EasingStyle = "Sine",
					EasingDirection = "InOut",

					StepType = "RenderStepped",

					Goal = {
						Value = CFrame.new(thatPosition + Vector3.new(
							math.random(-posRange, posRange) / 1000,
							math.random(-posRange, posRange) / 1000,
							math.random(-posRange, posRange) / 1000
						))
					}
				})
				tween:Play()
				tween.Completed:Connect(function()
					value:Destroy()
					tween:Destroy()
				end)
			else
				self.drones[i]:PivotTo(CFrame.new(thatPosition + Vector3.new(
						math.random(-posRange, posRange) / 1000,
						math.random(-posRange, posRange) / 1000,
						math.random(-posRange, posRange) / 1000
					))
				)
			end
		end
	end	
end

function droneClass:DestroyAllDrones()
	for _,drone in self.dronesParent:GetChildren() do
		drone:Destroy()
	end
	self.drones = {}
	self.positionTable = {}
end

return droneClass