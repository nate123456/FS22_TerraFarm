---@class TerraFarmRoadRoller : TerraFarmMachine
TerraFarmRoadCompactor = {}
local TerraFarmRoadCompactor_mt = Class(TerraFarmRoadCompactor, TerraFarmMachine)

local _machineType = g_machineTypeManager:register(TerraFarmRoadCompactor, 'roadCompactor', true, false, false, false, false, true, false)

function TerraFarmRoadCompactor.new(object, config)
    local self = TerraFarmMachine.new(object, _machineType, config, TerraFarmRoadCompactor_mt)
    return self
end

function TerraFarmRoadCompactor:getIsAttachable()
    return false
end

function TerraFarmRoadCompactor:onUpdate(dt)
    self:updateNodes()

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

function TerraFarmRoadCompactor:getClearDecoArea(operation)
    if self.disableClearDeco == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmRoadCompactor:getRemoveWeedArea(operation)
    if self.disableClearWeed == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmRoadCompactor:getRemoveFieldArea(operation)
    if self.disableRemoveField == true then
        return false
    end
    return operation == TerraFarmLandscaping.OPERATION.PAINT
end

function TerraFarmRoadCompactor:getClearDensityMapHeightArea()
    if self.clearDensityMap == true then
        return true
    end
    return false
end

function TerraFarmRoadCompactor:getRemoveStoneArea(operation)
    return operation ~= TerraFarmLandscaping.OPERATION.PAINT and operation ~= TerraFarmLandscaping.OPERATION.TERRAFORM_PAINT
end
