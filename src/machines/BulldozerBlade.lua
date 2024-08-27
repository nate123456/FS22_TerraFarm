---@class TerraFarmBulldozerBlade : TerraFarmMachine
---@field dischargeBuffer number
TerraFarmBulldozerBlade = {}
local TerraFarmBulldozerBlade_mt = Class(TerraFarmBulldozerBlade, TerraFarmMachine)

local _machineType = g_machineTypeManager:register(TerraFarmBulldozerBlade, 'bulldozerBlade', true, true, true, true, false, false, false)

function TerraFarmBulldozerBlade.new(object, config, mt)
    ---@type TerraFarmBulldozerBlade
    local self = TerraFarmMachine.new(object, _machineType, config, mt or TerraFarmBulldozerBlade_mt)
    self.dischargeBuffer = 0
    return self
end

function TerraFarmBulldozerBlade:getIsAttachable()
    return true
end

function TerraFarmBulldozerBlade:onVolumeDisplacement(fillDelta)
    if self:getDrivingDirection() < 0 then return end

    if self:getIsFull() then
        if self.disableDischarge ~= true then
            self:dischargeFillTypeToNodeLines(fillDelta)
        end
    else
        self:applyFillDelta(fillDelta)
    end
end

function TerraFarmBulldozerBlade:getIsAvailable()
    if self:getIsEmpty() then
        return true
    end
    return self:getIsCorrectFillType()
end

function TerraFarmBulldozerBlade:onUpdate(dt)
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

function TerraFarmBulldozerBlade:getTipFactor()
    return 0.01
end

function TerraFarmBulldozerBlade:getRemoveStoneArea()
    return false
end

function TerraFarmBulldozerBlade:getClearDensityMapHeightArea()
    if self.clearDensityMap == true then
        return true
    end
    return false
end

function TerraFarmBulldozerBlade:getClearDecoArea(operation)
    if self.disableClearDeco == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmBulldozerBlade:getRemoveWeedArea(operation)
    if self.disableClearWeed == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmBulldozerBlade:getRemoveFieldArea(operation)
    if self.disableRemoveField == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

---@return number
function TerraFarmBulldozerBlade:getFillMassRatio()
    return 0.5
end

---@param vehicle Vehicle
---@param func function
---@param dt number
function TerraFarmBulldozerBlade:onLevelerUpdate(vehicle, func, dt)
    TerraFarmRoadScraper.onLevelerUpdate(self, vehicle, func, dt)
end

function TerraFarmBulldozerBlade:onLevelerRaycastCallback(vehicle, func, ...)
    if self:getIsTouchingTerrain() then
        return
    end
    -- MachineSpecialization.OVERRIDE_TIP_TO_GROUND = true
    func(vehicle, ...)
    -- MachineSpecialization.OVERRIDE_TIP_TO_GROUND = false
end

function TerraFarmBulldozerBlade:updateNodeRotation()
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

function TerraFarmBulldozerBlade:getSideDischargeAmount(total)
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

function TerraFarmBulldozerBlade:dischargeFillTypeToNodeLines(amount)
    if #self.dischargeLines ~= 2 then return end

    local litersPerNode = self:getFillLitersFromBuffer(amount)

    if litersPerNode == 0 then
        return
    end

    local litersLeft, litersRight, rotation = self:getSideDischargeAmount(litersPerNode * 2)

    self:updateNodeRotation()

    --local xOffset = math.abs(rotation) * self.config.rotation.offsetFactor + 0.5
    local xOffset = 0

    self:dischargeFillTypeAlongNodeLine(self.dischargeLines[1], litersLeft, xOffset)
    self:dischargeFillTypeAlongNodeLine(self.dischargeLines[2], litersRight, -xOffset)
end

---@return number
---@return number
---@return number
function TerraFarmBulldozerBlade:getBladeRotation()
    local rot = {getRotation(self.rootNodes.rotation)}
    local axis = self.config.rotation.axis

    return rot[axis], axis, self.rootNodes.rotation
end