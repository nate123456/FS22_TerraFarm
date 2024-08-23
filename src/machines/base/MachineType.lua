---@class MachineType
---@field name string
---@field index number
---@field hasTerraformMode boolean
---@field hasDischargeMode boolean
---@field hasFillUnit boolean
---@field hasLevelerFunctions boolean
---@field hasShovelFunctions boolean
---@field hasDischargeSide boolean
---@field isVehicle boolean
MachineType = {}
local MachineType_mt = Class(MachineType)

---@return MachineType
function MachineType.new(name, index, hasTerraformMode, hasDischargeMode, hasFillUnit, hasLevelerFunctions, hasShovelFunctions, isVehicle, hasDischargeSide)
    ---@type MachineType
    local self = setmetatable({}, MachineType_mt)

    self.name = name
    self.index = index
    self.hasTerraformMode = hasTerraformMode
    self.hasDischargeMode = hasDischargeMode
    self.hasFillUnit = hasFillUnit
    self.hasLevelerFunctions = hasLevelerFunctions
    self.hasShovelFunctions = hasShovelFunctions
    self.isVehicle = isVehicle
    self.hasDischargeSide = hasDischargeSide

    return self
end