---@class MachineTypeManager
---@field machineTypes MachineType[]
---@field nameToMachineType table<string, MachineType>
---@field machineTypeToClass table<MachineType, TerraFarmMachine>
MachineTypeManager = {}
local MachineTypeManager_mt = Class(MachineTypeManager)

---@return MachineTypeManager
function MachineTypeManager.new()
    ---@type MachineTypeManager
    local self = setmetatable({}, MachineTypeManager_mt)

    self.typeCount = 0
    self.machineTypes = {}
    self.nameToMachineType = {}
    self.machineTypeToClass = {}

    return self
end

function MachineTypeManager:register(class, name, hasTerraformMode, hasDischargeMode, hasFillUnit, hasLevelerFunctions, hasShovelFunctions, isVehicle, hasDischargeSide)
    if self.nameToMachineType[name] then
        Logging.error('[MachineTypeManager:register] Machine type already registered: %s', tostring(name))
        return
    end

    local index = #self.machineTypes + 1

    local machineType = MachineType.new(name, index, hasTerraformMode, hasDischargeMode, hasFillUnit, hasLevelerFunctions, hasShovelFunctions, isVehicle, hasDischargeSide)

    table.insert(self.machineTypes, machineType)
    self.nameToMachineType[name] = machineType
    self.machineTypeToClass[machineType] = class

    class.machineType = machineType

    return machineType
end

---@return MachineType
function MachineTypeManager:getMachineTypeByName(name)
    return self.nameToMachineType[name]
end

function MachineTypeManager:getMachineClass(machineType)
    return self.machineTypeToClass[machineType]
end

---@diagnostic disable-next-line: lowercase-global
g_machineTypeManager = MachineTypeManager.new()