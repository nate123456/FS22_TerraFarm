---@class TerraFarmBucket : TerraFarmMachine
TerraFarmBucket = {}
local TerraFarmBucket_mt = Class(TerraFarmBucket, TerraFarmMachine)

local _machineType = g_machineTypeManager:register(TerraFarmBucket, 'bucket', true, true, true, false, true, false)

---@return TerraFarmBucket
function TerraFarmBucket.new(object, config, mt)
    ---@type TerraFarmBucket
    local self = TerraFarmMachine.new(object, _machineType, config, mt or TerraFarmBucket_mt)
    return self
end

function TerraFarmBucket:onVolumeDisplacement(fillDelta)
    self:applyFillDelta(fillDelta)
end

function TerraFarmBucket:getIsAttachable()
    return true
end

function TerraFarmBucket:getTipFactor()
    return self.object:getShovelTipFactor()
end

function TerraFarmBucket:onDischarge()
    if self.dischargeMode == TerraFarmMachine.MODE.NORMAL then return end
    if self:getIsEmpty() or self:getIsTouchingTerrain() then return end

    if self:getTipFactor() <= 0 then return end

    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    if self.dischargeMode == TerraFarmMachine.MODE.SMOOTH then
        self:applyDischargeSmooth()
    elseif self.dischargeMode == TerraFarmMachine.MODE.RAISE or self.dischargeMode == TerraFarmMachine.MODE.FLATTEN then
        self:applyDischargeRaise()
    elseif self.dischargeMode == TerraFarmMachine.MODE.PAINT then
        -- self:applyDischargePaint(self:getPaintRadius())
        self:applyDischargePaint()
    end

    if self.disablePaint ~= true and self.dischargeMode ~= TerraFarmMachine.MODE.PAINT then
    -- if self.dischargeMode ~= TerraFarmMachine.MODE.PAINT then
        self:applyPaint(true)
    end
end

function TerraFarmBucket:getIsAvailable()
    if self:getIsFull() then
        return false
    elseif self:getIsEmpty() then
        return true
    end

    return self:getIsCorrectFillType()
end

function TerraFarmBucket:onUpdate(dt)
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
            self:applyTerraformPaint()
        end

        if self.disablePaint ~= true and self.terraformMode ~= TerraFarmMachine.MODE.PAINT then
        -- if self.terraformMode ~= TerraFarmMachine.MODE.PAINT then
           self:applyPaint()
        end

        self.lastUpdate = 0
    else
        self.lastUpdate = self.lastUpdate + dt
    end
end

function TerraFarmBucket:getClearDecoArea(operation)
    if self.disableClearDeco == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmBucket:getRemoveWeedArea(operation)
    if self.disableClearWeed == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmBucket:getRemoveFieldArea(operation)
    if self.disableRemoveField == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmBucket:getClearDensityMapHeightArea()
    if self.clearDensityMap == true then
        return true
    end
    return false
end

function TerraFarmBucket:getRemoveStoneArea(operation)
    return operation ~= TerraFarmLandscaping.OPERATION.PAINT and operation ~= TerraFarmLandscaping.OPERATION.TERRAFORM_PAINT
end