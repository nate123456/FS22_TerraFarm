---@class TerraFarmRoadScraper : TerraFarmMachine
TerraFarmRoadScraper = {}
local TerraFarmRoadScraper_mt = Class(TerraFarmRoadScraper, TerraFarmMachine)

local _machineType = g_machineTypeManager:register(TerraFarmRoadScraper, 'roadScraper', true, true, true, true, false, true, true)

function TerraFarmRoadScraper.new(object, config)
    local self = TerraFarmMachine.new(object, _machineType, config, TerraFarmRoadScraper_mt)
    self.dischargeBuffer = 0
    return self
end

function TerraFarmRoadScraper:getIsAttachable()
    return false
end

function TerraFarmRoadScraper:updateNodeRotation()
    local rotation, axis = self:getBladeRotation()
    local nodeRotation = 0
    if rotation > 0 then
        nodeRotation = -rotation
    else
        nodeRotation = -1 * rotation
    end
    local rot = {0, 0, 0}
    rot[axis] = nodeRotation

    for _, line in ipairs(self.dischargeLines) do
        setRotation(line.startNode, unpack(rot))
    end
end

function TerraFarmRoadScraper:getSideDischargeAmount(total)
    local litersPerSide = total / 2
    local rotation = self:getBladeRotation()
    local rotationDeg = math.abs(math.deg(rotation))
    local min = self.config.rotation.min
    local max = self.config.rotation.max
    local thresholdPct = self.config.rotation.threshold
    local minAngleThreshold = math.abs((min / 100) * thresholdPct)
    local maxAngleThreshold = math.abs((max / 100) * thresholdPct)

    local litersLeft = litersPerSide
    local litersRight = litersPerSide

    if rotation < 0 then
        litersRight = math.min(
            total,
            math.max(
                litersPerSide,
                litersPerSide * ((2.0 / minAngleThreshold) * rotationDeg)
            )
        )
        litersLeft = total - litersRight
    elseif rotation > 0 then
        litersLeft = math.min(
            total,
            math.max(
                litersPerSide,
                litersPerSide * ((2.0 / maxAngleThreshold) * rotationDeg)
            )
        )
        litersRight = total - litersLeft
    end

    return litersLeft, litersRight, rotation
end


function TerraFarmRoadScraper:dischargeFillTypeToNodeLines(amount)
    if #self.dischargeLines ~= 2 then return end

    local litersPerNode = self:getFillLitersFromBuffer(amount)

    if litersPerNode == 0 then
        return
    end

    local litersLeft, litersRight, rotation = self:getSideDischargeAmount(litersPerNode * 2)

    self:updateNodeRotation()

    -- local xOffset = math.abs(rotation) * self.config.rotation.offsetFactor + 0.5
    local xOffset = 0

    self:dischargeFillTypeAlongNodeLine(self.dischargeLines[1], litersLeft, xOffset)
    self:dischargeFillTypeAlongNodeLine(self.dischargeLines[2], litersRight, -xOffset)
end


---@return number
---@return number
---@return number
function TerraFarmRoadScraper:getBladeRotation()
    local rot = {getRotation(self.rootNodes.rotation)}
    local axis = self.config.rotation.axis

    return rot[axis], axis, self.rootNodes.rotation
end

function TerraFarmRoadScraper:onVolumeDisplacement(fillDelta)
    if self:getDrivingDirection() < 0 then return end

    if self:getIsFull() then
        if self.disableDischarge ~= true then
            self:dischargeFillTypeToNodeLines(fillDelta)
        end
    else
        self:applyFillDelta(fillDelta)
    end
end

function TerraFarmRoadScraper:getIsAvailable()
    if self:getIsEmpty() then
        return true
    end
    return self:getIsCorrectFillType()
end

function TerraFarmRoadScraper:getTipFactor()
    return 0.01
end

function TerraFarmRoadScraper:onUpdate(dt)
    self:updateNodes()

    if self.terraformMode == TerraFarmMachine.MODE.NORMAL then
        return
    end

    if not self:getIsAvailable() then
        return
    end

    local isUpdatePending = self.lastUpdate >= g_terraFarm:getInterval()

    if self.terraformNodesIsTouchingTerrain and isUpdatePending then
        if self.terraformMode == TerraFarmMachine.MODE.SMOOTH then
            self:applyTerraformSmooth()
        elseif self.terraformMode == TerraFarmMachine.MODE.FLATTEN then
            local x, _, z, height = self:getVehiclePosition()

            if x and height then
                local target = { x = x, y = height, z = z }
                self:applyTerraformFlatten(target)
            end
        elseif self.terraformMode == TerraFarmMachine.MODE.LOWER then
            self:applyTerraformLower()
        elseif self.terraformMode == TerraFarmMachine.MODE.PAINT then
            self:applyTerraformPaint(self:getPaintRadius())
        end

        if self.disablePaint ~= true and self.terraformMode ~= TerraFarmMachine.MODE.PAINT then
            self:applyPaint()
        end

        self.lastUpdate = 0
    else
        self.lastUpdate = self.lastUpdate + dt
    end
end

function TerraFarmRoadScraper:getRemoveStoneArea()
    return false
end

function TerraFarmRoadScraper:getClearDensityMapHeightArea()
    if self.clearDensityMap == true then
        return true
    end
    return false
end

function TerraFarmRoadScraper:getClearDecoArea(operation)
    if self.disableClearDeco == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmRoadScraper:getRemoveWeedArea(operation)
    if self.disableClearWeed == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmRoadScraper:getRemoveFieldArea(operation)
    if self.disableRemoveField == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end



---@param vehicle Vehicle
---@param func function
---@param dt number
function TerraFarmRoadScraper:onLevelerUpdate(vehicle, func, dt)
    local spec = vehicle.spec_leveler

    if vehicle.isClient then
        g_effectManager:setFillType(spec.effects, self.fillTypeIndex)
		g_effectManager:startEffects(spec.effects)

        if self:getFillPercentage() > 0 then
            for _, effect in pairs(spec.effects) do
                if effect:isa(LevelerEffect) then
                    effect:setFillLevel(self:getFillPercentage())
                    effect:setLastVehicleSpeed(vehicle.movingDirection * vehicle:getLastSpeed())
                end
            end
        else
            for _, effect in pairs(spec.effects) do
                effect:setFillLevel(0)
            end
            g_effectManager:stopEffects(spec.effects)
        end
    end

    if vehicle.isServer then
        for _, levelerNode in pairs(spec.nodes) do
			local x0, y0, z0 = localToWorld(levelerNode.node, -levelerNode.halfWidth, levelerNode.yOffset, levelerNode.maxDropDirOffset)
			local x1, y1, z1 = localToWorld(levelerNode.node, levelerNode.halfWidth, levelerNode.yOffset, levelerNode.maxDropDirOffset)

			local pickedUpFillLevel = 0
			local fillType = vehicle:getFillUnitFillType(spec.fillUnitIndex)
			local fillLevel = vehicle:getFillUnitFillLevel(spec.fillUnitIndex)
			local didDischarge = false

			if fillType == FillType.UNKNOWN or fillLevel < g_densityMapHeightManager:getMinValidLiterValue(fillType) + 0.001 then
				local newFillType = DensityMapHeightUtil.getFillTypeAtLine(x0, y0, z0, x1, y1, z1, 0.5 * levelerNode.maxDropDirOffset)

				if newFillType ~= FillType.UNKNOWN and newFillType ~= fillType and vehicle:getFillUnitSupportsFillType(spec.fillUnitIndex, newFillType) then
					vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), spec.fillUnitIndex, -math.huge)

					fillType = newFillType
				end
			end

			local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillType)

			if fillType ~= FillType.UNKNOWN and heightType ~= nil then
				local innerRadius = 0.5
				local outerRadius = 2
				local capacity = vehicle:getFillUnitCapacity(spec.fillUnitIndex)
				local dirY = 0

				if levelerNode.alignToWorldY then
					local dirX, dirZ = nil
					dirX, dirY, dirZ = localDirectionToWorld(levelerNode.referenceFrame, 0, 0, 1)

					I3DUtil.setWorldDirection(levelerNode.node, dirX, math.max(dirY, 0), dirZ, 0, 1, 0)
				end

				if vehicle:getIsLevelerPickupNodeActive(levelerNode) and spec.pickUpDirection == vehicle.movingDirection and vehicle.lastSpeed > 0.0001 then
					local sx, sy, sz = localToWorld(levelerNode.node, -levelerNode.halfWidth, levelerNode.yOffset, levelerNode.zOffset)
					local ex, ey, ez = localToWorld(levelerNode.node, levelerNode.halfWidth, levelerNode.yOffset, levelerNode.zOffset)

					if dirY >= 0 then
						local _, sy2, _ = localToWorld(levelerNode.node, -levelerNode.halfWidth, levelerNode.yOffset, levelerNode.zOffset + innerRadius)
						local _, ey2, _ = localToWorld(levelerNode.node, levelerNode.halfWidth, levelerNode.yOffset, levelerNode.zOffset + innerRadius)
						sy = math.max(sy, sy2)
						ey = math.max(ey, ey2)
					end

					fillLevel = vehicle:getFillUnitFillLevel(spec.fillUnitIndex)
					local delta = -(capacity - fillLevel)
					local numHeightLimitChecks = levelerNode.numHeightLimitChecks

					if numHeightLimitChecks > 0 then
						local movementY = 0

						for i = 0, numHeightLimitChecks do
							local t = i / numHeightLimitChecks
							local xi = sx + (ex - sx) * t
							local yi = sy + (ey - sy) * t
							local zi = sz + (ez - sz) * t
							local hi = DensityMapHeightUtil.getHeightAtWorldPos(xi, yi, zi)
							movementY = math.max(movementY, hi - 0.05 - yi)
						end

						if movementY > 0 then
							sy = sy + movementY
							ey = ey + movementY
						end
					end


                    if self:getIsFull() then
						delta = -(capacity - fillLevel - g_densityMapHeightManager.minValidLiterValue * 10)
					end
                    if -1.0 * delta < g_densityMapHeightManager.minValidLiterValue then
                        delta = -500
                    end

                    levelerNode.lastPickUp, levelerNode.lineOffsetPickUp = DensityMapHeightUtil.tipToGroundAroundLine(vehicle, delta, fillType, sx, sy, sz, ex, ey, ez, innerRadius, outerRadius, levelerNode.lineOffsetPickUp, true, nil)

                    if levelerNode.lastPickUp < 0 then
                        if vehicle.notifiyBunkerSilo ~= nil then
                            vehicle:notifiyBunkerSilo(levelerNode.lastPickUp, fillType, (sx + ex) * 0.5, (sy + ey) * 0.5, (sz + ez) * 0.5)
                        end

                        levelerNode.lastPickUp = levelerNode.lastPickUp + spec.litersToPickup
                        spec.litersToPickup = 0

                        if self:getIsFull() then
                            self:dischargeFillTypeToNodeLines(math.abs(levelerNode.lastPickUp))
                        else
                            vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), spec.fillUnitIndex, -levelerNode.lastPickUp, fillType, ToolType.UNDEFINED, nil)
                        end

                        pickedUpFillLevel = levelerNode.lastPickUp
                    end
				end

				local lastPickUpPerMS = -pickedUpFillLevel
				spec.lastFillLevelMovedBuffer = spec.lastFillLevelMovedBuffer + lastPickUpPerMS
				spec.lastFillLevelMovedBufferTimer = spec.lastFillLevelMovedBufferTimer + dt

				if spec.lastFillLevelMovedBufferTime < spec.lastFillLevelMovedBufferTimer then
					spec.lastFillLevelMovedTarget = spec.lastFillLevelMovedBuffer / spec.lastFillLevelMovedBufferTimer
					spec.lastFillLevelMovedBufferTimer = 0
					spec.lastFillLevelMovedBuffer = 0
				end

				if vehicle.movingDirection < 0 and vehicle.lastSpeed * 3600 > 0.5 then
					spec.lastFillLevelMovedBuffer = 0
				end

				fillLevel = vehicle:getFillUnitFillLevel(spec.fillUnitIndex)

				if fillLevel > 0 then
					local f = fillLevel / capacity
					local width = MathUtil.lerp(levelerNode.halfMinDropWidth, levelerNode.halfMaxDropWidth, f)
					local sx, sy, sz = localToWorld(levelerNode.node, -width, levelerNode.yOffset, levelerNode.zOffset)
					local ex, ey, ez = localToWorld(levelerNode.node, width, levelerNode.yOffset, levelerNode.zOffset)
					local yOffset = -0.15
					levelerNode.lastDrop1, levelerNode.lineOffsetDrop1 = DensityMapHeightUtil.tipToGroundAroundLine(vehicle, fillLevel, fillType, sx, sy + yOffset, sz, ex, ey + yOffset, ez, innerRadius, outerRadius, levelerNode.lineOffsetDrop1, true, nil)

					if levelerNode.lastDrop1 > 0 then
						local leftOver = fillLevel - levelerNode.lastDrop1

						if leftOver <= g_densityMapHeightManager:getMinValidLiterValue(fillType) then
							levelerNode.lastDrop1 = fillLevel
							spec.litersToPickup = spec.litersToPickup + leftOver
						end

						vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), spec.fillUnitIndex, -levelerNode.lastDrop1, fillType, ToolType.UNDEFINED, nil)
					end
				end

				fillLevel = vehicle:getFillUnitFillLevel(spec.fillUnitIndex)
			else
				spec.lastFillLevelMovedBuffer = 0
				spec.lastFillLevelMovedTarget = 0
			end

			if pickedUpFillLevel < 0 and fillType ~= FillType.UNKNOWN then
				vehicle:notifiyBunkerSilo(pickedUpFillLevel, fillType)
			end
		end

		local smoothFactor = 0.05

		if spec.lastFillLevelMovedTarget == 0 then
			smoothFactor = 0.2
		end

		spec.lastFillLevelMoved = spec.lastFillLevelMoved * (1 - smoothFactor) + spec.lastFillLevelMovedTarget * smoothFactor

		if spec.lastFillLevelMoved < 0.005 then
			spec.lastFillLevelMoved = 0
		end

		local oldPercentage = spec.lastFillLevelMovedPct
		spec.lastFillLevelMovedPct = math.max(math.min(spec.lastFillLevelMoved / spec.maxFillLevelPerMS, 1), 0)

		if spec.lastFillLevelMovedPct ~= oldPercentage then
			vehicle:raiseDirtyFlags(spec.dirtyFlag)
		end
    end
end

function TerraFarmRoadScraper:onLevelerRaycastCallback(vehicle, func, ...)
    if self:getIsTouchingTerrain() then
        return
    end
    func(vehicle, ...)
end