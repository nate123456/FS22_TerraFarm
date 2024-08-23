---@class TerraFarmBucketExcavator : TerraFarmBucket
TerraFarmBucketExcavator = {}
local TerraFarmBucketExcavator_mt = Class(TerraFarmBucketExcavator, TerraFarmBucket)

local _machineType = g_machineTypeManager:register(TerraFarmBucketExcavator, 'bucketExcavator', true, true, true, false, true, true)

---@return TerraFarmBucketExcavator
function TerraFarmBucketExcavator.new(object, config, mt)
    local self = TerraFarmMachine.new(object, _machineType, config, mt or TerraFarmBucketExcavator_mt)
    return self
end

function TerraFarmBucketExcavator:getIsAttachable()
    return false
end

function TerraFarmBucketExcavator:getTipFactor()
    local vehicle = self:getVehicle()
    if vehicle.getShovelTipFactor then
        return vehicle:getShovelTipFactor()
    end
    return 0
end