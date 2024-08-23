---@class TerraFarmBucketWheelLoader : TerraFarmBucket
TerraFarmBucketWheelLoader = {}
local TerraFarmBucketWheelLoader_mt = Class(TerraFarmBucketWheelLoader, TerraFarmBucket)

local _machineType = g_machineTypeManager:register(TerraFarmBucketWheelLoader, 'bucketWheelLoader', true, true, true, false, true, true)

function TerraFarmBucketWheelLoader.new(object, config, mt)
    local self = TerraFarmMachine.new(object, _machineType, config, mt or TerraFarmBucketWheelLoader_mt)
    return self
end

function TerraFarmBucketWheelLoader:getIsAttachable()
    return false
end

function TerraFarmBucketWheelLoader:getTipFactor()
    local vehicle = self:getVehicle()
    if vehicle.getShovelTipFactor then
        return vehicle:getShovelTipFactor()
    end
    return 0
end