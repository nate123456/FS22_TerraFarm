---@class TerraFarmBulldozer : TerraFarmBulldozerBlade
TerraFarmBulldozer = {}
local TerraFarmBulldozer_mt = Class(TerraFarmBulldozer, TerraFarmBulldozerBlade)

local _machineType = g_machineTypeManager:register(TerraFarmBulldozer, 'bulldozer', true, true, true, true, false, true)

function TerraFarmBulldozer.new(object, config, mt)
    local self = TerraFarmMachine.new(object, _machineType, config, mt or TerraFarmBulldozer_mt)
    return self
end

function TerraFarmBulldozer:getIsAttachable()
    return false
end

function TerraFarmBulldozer:dischargeFillTypeToNodeLines(amount)
    if #self.dischargeLines ~= 2 then return end

    local litersPerNode = self:getFillLitersFromBuffer(amount)

    if litersPerNode == 0 then
        return
    end

    self:dischargeFillTypeAlongNodeLine(self.dischargeLines[1], litersPerNode)
    self:dischargeFillTypeAlongNodeLine(self.dischargeLines[2], litersPerNode)
end