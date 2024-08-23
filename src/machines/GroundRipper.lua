---@class TerraFarmGroundRipper : TerraFarmMachine
TerraFarmGroundRipper = {}
local TerraFarmGroundRipper_mt = Class(TerraFarmGroundRipper, TerraFarmMachine)

local _machineType = g_machineTypeManager:register(TerraFarmGroundRipper, 'groundRipper', true, false, true, false, false, true)

---@return TerraFarmGroundRipper
function TerraFarmGroundRipper.new(object, config, mt)
    local self = TerraFarmMachine.new(object, _machineType, config, mt or TerraFarmGroundRipper_mt)
    ---@diagnostic disable-next-line: return-type-mismatch
    return self
end

function TerraFarmGroundRipper:onVolumeDisplacement(volume, isDischarging)
    self:addFillAmount(self:volumeToFillAmount(volume), isDischarging)
end

function TerraFarmGroundRipper:getIsAvailable()
    if self:getIsFull() then
        return false
    elseif self:getIsEmpty() then
        return true
    end

    return self:getIsCorrectFillType()
end

function TerraFarmGroundRipper:getIsAttachable()
    return false
end

function TerraFarmGroundRipper:onUpdate(dt)
    self:updateNodes()

    if not self:getIsAvailable() then
        return
    end

    local isUpdatePending = self.lastUpdate >= g_terraFarm:getInterval()

    if self.terraformNodesIsTouchingTerrain and isUpdatePending then
        if self.terraformMode == TerraFarmMachine.MODE.SMOOTH then
            self:applyTerraformSmooth()
        elseif self.terraformMode == TerraFarmMachine.MODE.LOWER then
            self:applyTerraformLower()
        elseif self.terraformMode == TerraFarmMachine.MODE.PAINT then
            self:applyTerraformPaint(self:getPaintRadius())
        elseif self.terraformMode == TerraFarmMachine.MODE.FLATTEN then
            local x, _, z, height = self:getVehiclePosition()

            if x and height then
                local target = { x = x, y = height, z = z }
                self:applyTerraformFlatten(target)
            end
        end

        if self.disablePaint ~= true and self.terraformMode ~= TerraFarmMachine.MODE.PAINT then
            self:applyPaint()
        end

        self.lastUpdate = 0
    else
        self.lastUpdate = self.lastUpdate + dt
    end
end

function TerraFarmGroundRipper:getRemoveStoneArea()
    return false
end

function TerraFarmGroundRipper:getClearDensityMapHeightArea()
    if self.clearDensityMap == true then
        return true
    end
    return false
end

function TerraFarmGroundRipper:getClearDecoArea(operation)
    if self.disableClearDeco == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmGroundRipper:getRemoveWeedArea(operation)
    if self.disableClearWeed == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmGroundRipper:getRemoveFieldArea(operation)
    if self.disableRemoveField == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end
