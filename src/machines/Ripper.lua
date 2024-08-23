---@class TerraFarmBulldozerRipper : TerraFarmMachine
TerraFarmRipper = {}
local TerraFarmRipper_mt = Class(TerraFarmRipper, TerraFarmMachine)

local _machineType = g_machineTypeManager:register(TerraFarmRipper, 'ripper', true, true)

---@return TerraFarmBulldozerRipper
function TerraFarmRipper.new(object, config, mt)
    local self = TerraFarmMachine.new(object, _machineType, config, mt or TerraFarmRipper_mt)
    return self
end

function TerraFarmRipper:getIsAttachable()
    return true
end

function TerraFarmRipper:onVolumeDisplacement(volume)
    if self:getDrivingDirection() < 0 then return end

    if self.disableDischarge ~= true then
        self:dischargeFillTypeToNodeLines(self:volumeToFillAmount(volume))
    end
end

function TerraFarmRipper:onUpdate(dt)
    self:updateNodes()

    local isUpdatePending = self.lastUpdate >= g_terraFarm:getInterval()

    if self.terraformNodesIsTouchingTerrain and isUpdatePending then
        if self.terraformMode == TerraFarmMachine.MODE.SMOOTH then
            self:applyTerraformSmooth()
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

function TerraFarmRipper:getRemoveStoneArea()
    return false
end

function TerraFarmRipper:getClearDensityMapHeightArea()
    if self.clearDensityMap == true then
        return true
    end
    return false
end

function TerraFarmRipper:getClearDecoArea(operation)
    if self.disableClearDeco == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmRipper:getRemoveWeedArea(operation)
    if self.disableClearWeed == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmRipper:getRemoveFieldArea(operation)
    if self.disableRemoveField == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end