---@class MachineManager
---@field machines TerraFarmMachine[]
---@field machineToObject table<TerraFarmMachine, Vehicle>
---@field objectToMachine table<Vehicle, TerraFarmMachine>
---@field currentMachine TerraFarmMachine
MachineManager = {}
local MachineManager_mt = Class(MachineManager)

---@return MachineManager
function MachineManager.new()
    ---@type MachineManager
    local self = setmetatable({}, MachineManager_mt)

    self.machines = {}
    self.machineToObject = {}
    self.objectToMachine = {}

    return self
end

function MachineManager:getCurrentMachine()
    return self.currentMachine
end

---@param machine TerraFarmMachine
---@param object Vehicle
function MachineManager:setCurrentMachine(machine, object)
    -- NOTE: Do not call this function on server side if dedicated server
    if machine then
        self.currentMachine = machine
    elseif object then
        self.currentMachine = self:getMachineByObject(object)
    else
        self.currentMachine = nil
    end
end

---@param object Vehicle
---@return TerraFarmMachine
function MachineManager:getMachineByObject(object)
    return self.objectToMachine[object]
end

---@param machine TerraFarmMachine
---@return table
function MachineManager:getObjectByMachine(machine)
    return self.machineToObject[machine]
end

---@return TerraFarmMachine[]
function MachineManager:getVehicleAttachedMachines(vehicle)
    local result = {}

    for _, machine in ipairs(self.machines) do
        if machine:getIsAttachable() and vehicle == machine:getVehicle() then
            table.insert(result, machine)
        end
    end

    return result
end

---@param object Vehicle
---@param config MachineXMLConfiguration
---@return TerraFarmMachine
function MachineManager:register(object, config)
    Logging.info('MachineManager:register()')
    local machineClass = g_machineTypeManager:getMachineClass(config.machineType)

    assert(machineClass, '[MachineManager:register] machineClass is nil')

    local machine = machineClass.new(object, config)

    assert(machine, '[MachineManager:register] machine is nil')

    Logging.info('[MachineManager:register] Machine created, applying configuration')
    -- DebugUtil.printTableRecursively(machine, '   ', 0, 0)

    config:apply(machine)

    table.insert(self.machines, machine)
    self.machineToObject[machine] = object
    self.objectToMachine[object] = machine

    return machine
end

---@diagnostic disable-next-line: lowercase-global
g_machineManager = MachineManager.new()