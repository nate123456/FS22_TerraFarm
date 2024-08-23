---@class TerraFarmSuctionAttachment : TerraFarmBucket
TerraFarmSuctionAttachment = {}
local TerraFarmSuctionAttachment_mt = Class(TerraFarmSuctionAttachment, TerraFarmBucket)

local _machineType = g_machineTypeManager:register(TerraFarmSuctionAttachment, 'suctionAttachment', true, false, false, false, false, false)

function TerraFarmSuctionAttachment.new(object, config, mt)
    local self = TerraFarmMachine.new(object, _machineType, config, mt or TerraFarmSuctionAttachment_mt)
    return self
end

function TerraFarmSuctionAttachment:onDischarge()
end

function TerraFarmSuctionAttachment:getTipFactor()
    return 0
end

function TerraFarmSuctionAttachment:updateFillType()
    if not self.fillTypeIndex then
        self:initFillType()
    end

    local fillUnit, vehicle = self:getVehicleFillUnit()

    if fillUnit then
        vehicle:setFillUnitFillType(
            fillUnit.fillUnitIndex,
            self.fillTypeIndex
        )
        self:addFillAmount(0)
    end
end

function TerraFarmSuctionAttachment:addFillAmount(amount)
    local fillUnit, vehicle = self:getVehicleFillUnit()

    if fillUnit then
        vehicle:addFillUnitFillLevel(
            vehicle:getOwnerFarmId(),
            fillUnit.fillUnitIndex,
            amount,
            self.fillTypeIndex,
            ToolType.UNDEFINED
        )
    end
end

function TerraFarmSuctionAttachment:setFillTypeIndex(index)
    if not g_fillTypeManager.fillTypes[index] then
        Logging.warning('[TerraFarmMachine:setFillTypeIndex] FillType index not found: %s', tostring(index))
        return
    end
    self:setStateValue('fillTypeIndex', index)
    self:updateFillType()
end

function TerraFarmSuctionAttachment:setFillType(name)
    local fillType = g_fillTypeManager.nameToFillType[name]

    if not fillType then
        Logging.warning('[TerraFarmSuctionAttachment:setFillType] Failed to get fillType by name: %s', tostring(name))
        if name ~= TerraFarmFillTypes.DEFAULT_FILLTYPE_NAME then
            Logging.info('[TerraFarmSuctionAttachment:setFillType] Reverting to default fillType')
            return self:setFillType(TerraFarmFillTypes.DEFAULT_FILLTYPE_NAME)
        end
        return
    end

    return self:setFillTypeIndex(fillType.index)
end

function TerraFarmSuctionAttachment:getCurrentFillType()
    local fillUnit = self:getVehicleFillUnit()
    if fillUnit then
        return fillUnit.fillType
    end
end

function TerraFarmSuctionAttachment:getIsCorrectFillType()
    local fillUnit = self:getVehicleFillUnit()
    if fillUnit then
        return fillUnit.fillType == self.fillTypeIndex
    end
    return false
end

function TerraFarmSuctionAttachment:getFillLevel()
    local fillUnit = self:getVehicleFillUnit()
    if fillUnit then
        return fillUnit.fillLevel
    end
    return 0
end

function TerraFarmSuctionAttachment:getFillCapacity()
    local fillUnit = self:getVehicleFillUnit()
    if fillUnit then
        return fillUnit.capacity
    end
    return 0
end

function TerraFarmSuctionAttachment:getFreeFillCapacity()
    local fillUnit = self:getVehicleFillUnit()
    if fillUnit then
        return fillUnit.capacity - fillUnit.fillLevel
    end
    return 0
end

function TerraFarmSuctionAttachment:getFillPercentage()
    local fillUnit = self:getVehicleFillUnit()
    if fillUnit then
        return (1.0 / fillUnit.capacity) * fillUnit.fillLevel
    end
    return 0
end

function TerraFarmSuctionAttachment:onVolumeDisplacement(volume)
    self:addFillAmount(self:volumeToFillAmount(volume))
end