local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")


local Util, UtilMD, ConfigureMD, AirDensity, Bindings, ignore, elevatorAddition, EngineOn, EnginePower, pushbackPower, Flaps, flapStatus

local prevY, boost = 0,0
local parts, hinges = {},{}

local previousALT = 0 

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")


local connection, seat

local throttle = 0
local thrust = 0


local oDensity = nil
local Mouse = nil

local Pushbacking = false
local isOnGround = false
local OnControlDuty = true

local currentModel = nil

local momentum = 0
local maxMomentum = 100
local gravity = game.Workspace.Gravity

local verticalSpeed = 0

local isAutoPilot = false

function calculateMomentum(mass, speed, angleDegrees, gravity)
	local angleRadians = math.rad(angleDegrees)
	local vx = speed * math.cos(angleRadians)
	local vy = speed * math.sin(angleRadians)
	local momentumHorizontal = mass * vx
	local momentumVertical = mass * vy
	local momentum = math.sqrt(momentumHorizontal^2 + momentumVertical^2)
	return momentum
end

local function GetTouchingParts(part)
	local connection = part.Touched:Connect(function() end)
	local results = part:GetTouchingParts()
	connection:Disconnect()
	return results
end

local function checkOnGround()
	local groundDetector = seat.Parent.GroundDetector
	local touchingParts = GetTouchingParts(groundDetector)

	for _,v in pairs(touchingParts) do
		if not v:IsDescendantOf(seat.Parent) then
			isOnGround = true

			return
		end
	end
	isOnGround = false
end

UserInputService.InputBegan:Connect(function(keycode)
	if keycode.KeyCode == Enum.KeyCode.M then
		OnControlDuty = not OnControlDuty
	end
end)

local function GPSAltitude()
	--local diff = require(game.Workspace.TerrainRenderer).getTerrainDifference(seat)
	--return math.round(diff * 0.91863517)
	return 0
end

local function updateStatus(speed)
	local fixedSpeed = math.floor(speed.Magnitude * 0.28 * 1.943844)
	UtilMD.Status.Speed = fixedSpeed
	local fixedSpeed2 = speed.Magnitude * 0.28 * 1.943844
	UtilMD.Status.DecimalSpeed = fixedSpeed2
	local fixedAltitude = math.round(seat.Position.Y * 0.91863517)
	UtilMD.Status.Altitude = fixedAltitude
	UtilMD.Status.AltitudeTerrainLevel = GPSAltitude()
	UtilMD.Status.IsOnGround = isOnGround
end


local function Start()
	oDensity = seat.Parent.Fuselage.CustomPhysicalProperties.Density
	local VisualForces = {}
	local model = seat:FindFirstAncestorOfClass("Model")
	Mouse = game.Players.LocalPlayer:GetMouse()
	for index, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local A0 = Instance.new("Attachment", descendant)
			local A1 = Instance.new("Attachment", descendant)

			local VectorForce = Instance.new("VectorForce")
			VectorForce.Attachment0 = A0
			VectorForce.Parent = descendant

			local beam = Instance.new("Beam")
			beam.Parent = descendant
			beam.FaceCamera = true
			beam.Segments = 1
			beam.Width0 = 0.5
			beam.Width1 = 0.5
			beam.Color = ColorSequence.new(Color3.fromRGB(106, 230, 141))
			beam.Attachment0 = A0
			beam.Attachment1 = A1
			beam.Enabled = false
			table.insert(VisualForces, beam)
	
			

			if descendant.Name == "Motor" then
				if EngineOn then
					descendant.Idle:Play()
				end
			end

			table.insert(parts, {
				Part = descendant,
				Attachment0 = A0,
				Attachment1 = A1,
				Beam = beam,
				VectorForce = VectorForce,
				AreaX = descendant.Size.Y * descendant.Size.Z,
				AreaY = descendant.Size.X * descendant.Size.Z,
				AreaZ = descendant.Size.X * descendant.Size.Y
			})
		elseif descendant.ClassName == "HingeConstraint" then
			table.insert(hinges, descendant)

		end

	end
	currentModel = model
	game:GetService("UserInputService").InputBegan:Connect(function(Input)
		if Input.KeyCode == Enum.KeyCode.Zero then
			for i, v in pairs(VisualForces) do
				v.Enabled = not v.Enabled
			end
		end
	end)
	local VSFGLOBAL
	local PREVIOUSTOUCH = true
	
	task.spawn(function()
		while true do

	
		local currentY = seat.Parent.Fuselage.Position.Y
		local VS = currentY - prevY
		local VSF = math.round(0.91863517 * VS) * 60
		prevY = currentY
		VSFGLOBAL = VSF
		wait(1)
		end
	end)

	task.spawn(function()
		RunService.RenderStepped:Connect(function(deltaTime)
			currentModel = model
			if model.Name == "Cessna172" then

				model.Parent:SetAttribute("OnControlDuty", OnControlDuty)
			elseif model.Name == "A32000" then
			
				model:SetAttribute("OnControlDuty", OnControlDuty)
			end
			
			currentModel = model
		if PREVIOUSTOUCH ~= isOnGround then
			-- the plane has changed status
			if isOnGround == false then
			--	print("Plane took off")
			else
				
				local currentY = seat.Parent.Fuselage.Position.Y
				local FPM = currentY - prevY
				local FPMF = math.round(FPM * 0.28 * 3.2808399 ) * deltaTime
					local CameraShaker =  require(script.CameraShaker)
					local CurrentCamera = game.Workspace.CurrentCamera
					local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
						CurrentCamera.CFrame *= shakeCf
					end)

				--	camShake:Start()

				--	camShake:ShakeOnce(5,1 * FPMF / 100,0,1.5,Vector3.new(0.25, 0.25, 0.25),Vector3.new(4, 1, 1))
					
					require(Util.Ui).Popup("Info", "Landed at "..FPM.." FPM")
				
			--	print("Landing FPM: ", FPMF)
			end
		else
		end
		PREVIOUSTOUCH = isOnGround
		wait(0.001)
	end)
	end)
end

local function Stop()
	for index, data in parts do
		data.Attachment0:Destroy()
		data.Attachment1:Destroy()
		data.Beam:Destroy()
	end
	table.clear(parts)
	table.clear(hinges)
end

local bufferSize: number = 10 
local record: {Vector3} = table.create(10, Vector3.zero)
count = 0

local lastVelocity: Vector3 = Vector3.zero

local function CalculateGForce(dt, vel)	
	local dv: Vector3 = (vel - lastVelocity) / dt

	count += 1 
	record[count] = dv
	if count == bufferSize then
		count = 0
	end
	local av: Vector3 = Vector3.zero
	for _, entry in record do
		av += entry
	end
	av /= bufferSize 

	local acc = math.round((av.Magnitude / game.Workspace.Gravity) + 1)
	lastVelocity = vel
	return(acc)
end


local function Loop(deltaTime)
	--[[ BACK-END ]]--
	--12500
	checkOnGround()
	


	if UserInputService:IsKeyDown(Bindings.ThrottleUp) then throttle += 30 * deltaTime end
	if UserInputService:IsKeyDown(Bindings.ThrottleDown) then throttle -= 30 * deltaTime end
	
	if UserInputService:IsKeyDown(Enum.KeyCode.B) then
		if isOnGround then
			--seat.Parent.Fuselage.CustomPhysicalProperties = PhysicalProperties.new(100, 0, 0)
			game.Workspace.Gravity = 100
			Util.Ui:SetAttribute("Braking", true)
		--	print("Brakes!!!")
		end
	else
		game.Workspace.Gravity = 36
		Util.Ui:SetAttribute("Braking", false)
		--seat.Parent.Fuselage.CustomPhysicalProperties = PhysicalProperties.new(oDensity, 0, 0)
	end
	local fixedThrottle = math.round(throttle)
	
	if currentModel ~= nil then
		if currentModel.Name == "A320 NEO" then
			require(currentModel.Util).Status.Throttle = fixedThrottle

		end
		
		--KUZEY DONT DELETE I NEED THROTTLE TO BE MANGAGED FORM THE AIRCRAFT COCKPIT UTIL
		if currentModel.Name == "Cessna172" then
			fixedThrottle = tonumber(currentModel.Util.Cockpit.buttons_c172:GetAttribute("Throttle"))
		end

	end
	

	
	
	

	if Pushbacking then
		fixedThrottle = pushbackPower
	else
		if fixedThrottle > 100 then
			fixedThrottle = 100
		elseif fixedThrottle < 0 then
			fixedThrottle = 0
		end
	end
	
	if currentModel ~= nil then
		if currentModel.Name == "Cessna172" then
			fixedThrottle = tonumber(currentModel.Util.Cockpit.buttons_c172:GetAttribute("Throttle"))
		end

	end
	
	
	throttle = fixedThrottle
	if thrust < throttle * EnginePower then
		thrust += EnginePower
	elseif thrust > throttle * EnginePower then
		thrust -= EnginePower
	end

	local velocity
	for index, data in parts do 
		velocity = -data.Part:GetVelocityAtPosition(data.Part.Position)
		velocity += game.Workspace.GlobalWind
	if data.Part.Name == "Motor" then
		if EngineOn == true then 
		--	print("SPD: " .. velocity.Magnitude * 0.28 * 1.943844 .. " kts")
		--	print("ALT: " .. math.round(seat.Parent.Fuselage.Position.Y * 0.28 * 3.2808399) .. " ft")
			local TargetBoost = calculateMomentum(seat.Parent.Fuselage.Mass, velocity.Magnitude, seat.Parent.Fuselage.Orientation.Z, game.Workspace.Gravity)
			AirDensity = 0.01 - ((seat.Parent.Fuselage.Position.Y * 0.28) / 500000)
			--print("AIR DENSITY: " .. AirDensity)
			local a = 120
			if isOnGround == true  then
				a = 80
			else
				a = 120
			end
			TargetBoost = math.clamp(TargetBoost, 0, seat.Parent.Fuselage.Mass * 120)
			
			data.VectorForce.Force = Vector3.new(0,0,(thrust + TargetBoost))
			if EngineOn then
				if Pushbacking then
					fixedThrottle = 1
				end
				data.Part.Idle.PlaybackSpeed = 1 + (fixedThrottle / 100)
				data.Part.Buzzsaw.Volume = .1 + (fixedThrottle / 15)
				data.Part.Buzzsaw.PlaybackSpeed = .45 + (fixedThrottle / 200)
				data.Part.BuzzsawHI.Volume = .1 + (fixedThrottle / 10)
				data.Part.BuzzsawHI.PlaybackSpeed = .5 + (fixedThrottle / 200)
			end
		end
		else
			data.VectorForce.Force = Vector3.zero
	
	end


		if table.find(ignore, data.Part.Name) then 

		else

			if velocity.Magnitude > 0 then


				local currentY = seat.Parent.Fuselage.Position.Y

				-- Adjust this factor based on how much momentum you want to gain or lose
		
				-- Update the previous Y position for the next frame
	


				local dotRight = data.Part.CFrame.RightVector:Dot(velocity.Unit)

				data.VectorForce.Force += (Vector3.xAxis * AirDensity * dotRight * data.AreaX * velocity.Magnitude^2)

				local dotUp = data.Part.CFrame.UpVector:Dot(velocity.Unit)
				data.VectorForce.Force += (Vector3.yAxis * AirDensity * dotUp * data.AreaY * velocity.Magnitude^2)

				local dotLook = data.Part.CFrame.LookVector:Dot(velocity.Unit)
				data.VectorForce.Force -= (Vector3.zAxis * AirDensity * dotLook * data.AreaZ * velocity.Magnitude^2)

			end
			data.Attachment1.Position = data.VectorForce.Force / 400
			if data.Part == seat.Parent.Fuselage then
				local currentALT = seat.Parent.Fuselage.Position.Y * 0.28 * 3.2808399
				local deltaAltitude = currentALT - previousALT
				verticalSpeed = math.round(((deltaAltitude / deltaTime) * 60))


				previousALT = currentALT

				--print("V/S " .. verticalSpeed)
			end
		end
		updateStatus(velocity)
		local gForce = CalculateGForce(deltaTime,velocity)
	end
	for index, hinge in hinges do
		hinge.TargetAngle = 0

		for index, value in hinge:GetAttributes() do



			if hinge:GetAttributes()["Type"] == "Flap" then
				hinge.TargetAngle += Flaps[flapStatus]
			end
			local SCREEN_WIDTH = game.Workspace.Camera.ViewportSize.X
			local SCREEN_LENGTH =  game.Workspace.Camera.ViewportSize.Y
			local MouseX = UserInputService:GetMouseLocation().X
			local MouseY = UserInputService:GetMouseLocation().Y

			local normalizedX = (MouseX/SCREEN_WIDTH * 2) - 1 
			local normalizedY = (MouseY/SCREEN_LENGTH * 2) - 1 
			if isOnGround and velocity.Magnitude > 0.1 then
				local minLimit, maxLimit = -20, 20
			end
			if OnControlDuty == false then
				if index ~= "Type" then
					if hinge:GetAttributes()["Type"] == "Aileron" then
						hinge.TargetAngle = 0
					elseif hinge:GetAttributes()["Type"] == "Elevator" then
						hinge.TargetAngle = 0
						hinge.TargetAngle = 0
					elseif hinge:GetAttributes()["Type"] == "Rudder" then
						if isOnGround == false then
							hinge.TargetAngle = 0
						else
							hinge.TargetAngle = 0
						end

					elseif hinge:GetAttributes()["Type"] == "Motor" then
						if isOnGround == true then
							hinge.TargetAngle = 0
						else
							hinge.TargetAngle = 0
						end

					end
				end
			else
				

				local TargetAltitude = script.Altitude.Value
				local currentAlt = previousALT



				local VSCalcHelper = 500
				local TargetVS = script.VerticalSpeed.Value + VSCalcHelper
				local diff = TargetVS - verticalSpeed
				local diffFix = -((diff / (velocity.Magnitude * 0.28)) / 50) * 1.52671755725 * 2
			
				diffFix = math.clamp(diffFix, -1, 1)
			--	normalizedY = diffFix
			--	print("NY: " .. diffFix)


				if index ~= "Type" then
					if hinge:GetAttributes()["Type"] == "Aileron" then
						hinge.TargetAngle += (normalizedX * value)
					elseif hinge:GetAttributes()["Type"] == "Elevator" then
						hinge.TargetAngle += normalizedY * value
						hinge.TargetAngle += elevatorAddition
					elseif hinge:GetAttributes()["Type"] == "Rudder" then
						if isOnGround == false then
							hinge.TargetAngle += seat["SteerFloat"] * value
						else
							hinge.TargetAngle += (normalizedX * value)
						end

					elseif hinge:GetAttributes()["Type"] == "Motor" then
						if isOnGround == true then
							hinge.TargetAngle += -((normalizedX * value))
						else
							hinge.TargetAngle = 0
						end

					end
				end
			end
	
		end

		--hinge.TargetAngle += -math.clamp(calculateServoAngle(hinge, Mouse.Hit.Position), -20,20)
		--[[
		for index, value in hinge:GetAttributes() do
			hinge.TargetAngle += seat[index] * value
		end--]]
	end
end

game.ReplicatedStorage.RemoteEvents.GetMutliplayerAircraftData.OnClientInvoke = function()
--	print("tonka")
	if currentModel.Name == "Cessna172" then
	--	print("big ol tonka")
		local Table = {AircraftPos = currentModel.MultiplayerMove.Position,AircraftRot = currentModel.MultiplayerMove.CFrame, Aircraft = "Cessna172", UserId = game.Players.LocalPlayer.UserId}
	--	print(Table)
		game.ReplicatedStorage.RemoteEvents.GotData:FireServer(Table)
		return Table
	end
	return nil
end

UserInputService.InputBegan:Connect(function(input, gameProc)
	if gameProc == false then
		if connection ~= nil then
			if input.KeyCode == Bindings.Flaps then
				if flapStatus == #Flaps then
					flapStatus = 1
				else
					flapStatus += 1
				end
			elseif input.KeyCode == Bindings.Pushback then
				Pushbacking = not Pushbacking
			end
		end
	end
end)


local function setAircraftData()
	Bindings = ConfigureMD.Keybinds
	AirDensity = ConfigureMD.Atmosphere.AirDensity
	ignore = UtilMD.Ignore
	elevatorAddition = ConfigureMD.Aircraft.CoreTrimAddition
	EngineOn = UtilMD.Status.EngineOn
	EnginePower = ConfigureMD.Aircraft.EnginePower
	pushbackPower = ConfigureMD.Aircraft.pushbackPower
	Flaps = ConfigureMD.Aircraft.Flaps
	flapStatus = 1
end

local function Seated(active, currentSeat)

	if active == false then 
		if connection == nil then return end
		connection:Disconnect()
		connection = nil
		Stop()
	elseif currentSeat.Name == "Plane" then
		seat = currentSeat
		Util = seat.Parent:WaitForChild("Util")
		UtilMD = require(Util)
		UtilMD.Initialize()
		ConfigureMD = require(Util.Configure)
		setAircraftData()
		Start()
		connection = RunService.PostSimulation:Connect(Loop)
	
	end
end

humanoid.Seated:Connect(Seated)

