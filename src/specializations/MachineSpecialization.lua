---@class MachineSpecialization
MachineSpecialization = {}

MachineSpecialization.OVERRIDE_TIP_TO_GROUND = false

---@param object Vehicle
---@param machineType MachineType
---@param name string
---@param filePath string
--function MachineSpecialization.add(object, machineType, name, filePath)

---@param object Vehicle
---@param config MachineXMLConfiguration
function MachineSpecialization.add(object, config)
    local machineType = config.machineType
    local spec_name = 'spec_machine'
    local spec = {}

    setmetatable(spec, { __index = object })

    spec.actionEvents = {}
    spec.onLoadFinished = MachineSpecialization.onLoadFinished
    spec.onRegisterActionEvents = MachineSpecialization.onRegisterActionEvents
    spec.onDelete = MachineSpecialization.onDelete

    spec.type = machineType
    spec.machineConfig = config
    spec.name = object.configFileNameClean
    spec.filePath = config.xmlFilePath

    object[spec_name] = spec

    table.insert(object.eventListeners.onLoadFinished, spec)
    table.insert(object.eventListeners.onRegisterActionEvents, spec)
    table.insert(object.eventListeners.onDelete, spec)

    if machineType.hasShovelFunctions then
        object.getIsDischargeNodeActive = Utils.overwrittenFunction(object.getIsDischargeNodeActive, MachineSpecialization.getIsDischargeNodeActive)
        object.handleDischarge = Utils.overwrittenFunction(object.handleDischarge, MachineSpecialization.handleDischarge)
        object.handleDischargeRaycast = Utils.overwrittenFunction(object.handleDischargeRaycast, MachineSpecialization.handleDischargeRaycast)
    end

    if machineType.isVehicle then
        spec.onEnterVehicle = MachineSpecialization.onEnterVehicle
        table.insert(object.eventListeners.onEnterVehicle, spec)
        spec.onLeaveVehicle = MachineSpecialization.onLeaveVehicle
        table.insert(object.eventListeners.onLeaveVehicle, spec)
    end

    if machineType.hasLevelerFunctions then
        object.onLevelerRaycastCallback = Utils.overwrittenFunction(object.onLevelerRaycastCallback, MachineSpecialization.onLevelerRaycastCallback)
        object.getIsLevelerPickupNodeActive = Utils.overwrittenFunction(object.getIsLevelerPickupNodeActive, MachineSpecialization.getIsLevelerPickupNodeActive)
    end
end

---@param typeName string
function MachineSpecialization.getFileTypeName(typeName)
    assert(type(typeName) == 'string', 'getFileTypeName: typeName is not a string')
    return typeName:lower()
end

---@param vehicle Vehicle
function MachineSpecialization.afterVehicleLoad(vehicle)
    Logging.info('vehicle.typeName: %s', tostring(vehicle.typeName))
    local config = g_machineConfigurationManager:getVehicleConfig(vehicle)

    if not config then
        return
    end

    Logging.info('Got machineType: %s', tostring(config.machineType.name))

    MachineSpecialization.add(vehicle, config)
end

---@param vehicle Vehicle
function MachineSpecialization.onLoadFinished(vehicle)
    if not vehicle.spec_machine then
        Logging.error('[MachineSpecialization.onLoadFinished] spec_machine is nil')
        Logging.info('Vehicle: %s', tostring(vehicle:getFullName()))
        return
    end
    -- assert(vehicle.spec_machine, '[MachineSpecialization.onLoadFinished] spec_machine is nil')

    if not vehicle.propertyState or vehicle.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG or vehicle.propertyState == Vehicle.PROPERTY_STATE_NONE then
        return
    end

    local spec = vehicle.spec_machine

    local machine = g_machineManager:register(vehicle, spec.machineConfig)

    if machine then
        spec.machine = machine
    end
end

---@param vehicle Vehicle
function MachineSpecialization.onDelete(vehicle)
    local spec = vehicle.spec_machine
    if spec then
        if spec.machine then
            if g_machineManager:getCurrentMachine() == spec.machine then
                g_machineManager:setCurrentMachine()
            end
            g_machineManager.machineToObject[spec.machine] = nil
            if spec.machine.object then
                g_machineManager.objectToMachine[spec.machine.object] = nil
            end
        end
    end
end

function MachineSpecialization.onEnterVehicle() end
function MachineSpecialization.onLeaveVehicle() end

---@type function
MachineSpecialization.OVERRIDE_TIP_TO_GROUND_FUNC = nil

function MachineSpecialization.onLevelerUpdate(self, func, ...)
    if g_terraFarm:getIsEnabled() then
        local machine = g_machineManager:getMachineByObject(self)
        if machine and machine.enabled and machine.type.hasLevelerFunctions then
            if machine:getDrivingDirection() < 0 and self.lastSpeed > 0.0001 then
                MachineSpecialization.OVERRIDE_TIP_TO_GROUND = true
                func(self, ...)
                MachineSpecialization.OVERRIDE_TIP_TO_GROUND = false
                return
            else
                if machine.onLevelerUpdate then
                    machine:onLevelerUpdate(self, func, ...)
                    return
                end
            end
        end
    end

    func(self, ...)
end

Leveler.onUpdate = Utils.overwrittenFunction(Leveler.onUpdate, MachineSpecialization.onLevelerUpdate)

DensityMapHeightUtil.tipToGroundAroundLine = Utils.overwrittenFunction(DensityMapHeightUtil.tipToGroundAroundLine,
    function(self, func, fillLevel, ...)
        if MachineSpecialization.OVERRIDE_TIP_TO_GROUND then
            if fillLevel >= 500 then
                local overrideFillLevel = fillLevel * 0.05
                return func(self, overrideFillLevel, ...)
            end
        end

        return func(self, fillLevel, ...)
    end
)

function MachineSpecialization.onLevelerRaycastCallback(self, func, ...)
    if g_terraFarm:getIsEnabled() then
        local machine = g_machineManager:getMachineByObject(self)
        if machine and machine.enabled and machine.onLevelerRaycastCallback then
            machine:onLevelerRaycastCallback(self, func, ...)
        end
    end
    func(self, ...)
end

function MachineSpecialization.getIsLevelerPickupNodeActive(self, func, ...)
    if g_terraFarm:getIsEnabled() then
        local machine = g_machineManager:getMachineByObject(self)
        if machine and machine.enabled and machine.levelerGetIsLevelerPickupNodeActive then
            return machine:levelerGetIsLevelerPickupNodeActive(self, func, ...)
        end
    end
    return func(self, ...)
end

function MachineSpecialization.actionEventOpenMenu()
    g_terraFarm:openMenu()
end

---@param vehicle Vehicle
function MachineSpecialization.actionEventToggleEnabled(vehicle)
    local machine = vehicle.spec_machine.machine
    machine:setIsEnabled(not machine.enabled)
    MachineSpecialization.updateActionEvents(vehicle)
end

---@param vehicle Vehicle
function MachineSpecialization.actionEventToggleTerraformMode(vehicle)
    local machine = vehicle.spec_machine.machine
    machine:toggleTerraformMode()
    MachineSpecialization.updateActionEvents(vehicle)
end

---@param vehicle Vehicle
function MachineSpecialization.actionEventToggleDischargeMode(vehicle)
    local machine = vehicle.spec_machine.machine
    machine:toggleDischargeMode()
    MachineSpecialization.updateActionEvents(vehicle)
end

MachineSpecialization.INPUT_ACTION_BINDINGS = {
    enableState = 'TERRAFARM_TOGGLE_ENABLE',
    openMenu = 'TERRAFARM_OPEN_MENU',
    toggleTerraformMode = 'TERRAFARM_TOGGLE_TERRAFORM_MODE',
    toggleDischargeMode = 'TERRAFARM_TOGGLE_DISCHARGE_MODE'
}

MachineSpecialization.INPUT_ACTION_TEXT = {
    enableMachine = 'ENABLE_MACHINE',
    disableMachine = 'DISABLE_MACHINE',
    toggleTerraformMode = 'TOGGLE_TERRAFORM_MODE',
    toggleDischargeMode = 'TOGGLE_DISCHARGE_MODE',
    openMenu = 'OPEN_MENU'
}

---@param name InputActionBindingName
function MachineSpecialization.getActionBinding(name)
    return InputAction[MachineSpecialization.INPUT_ACTION_BINDINGS[name]]
end

---@param name InputActionText
function MachineSpecialization.getActionText(name)
    return g_i18n:getText(MachineSpecialization.INPUT_ACTION_TEXT[name]) or name
end

---@param vehicle Vehicle
---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
function MachineSpecialization.onRegisterActionEvents(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
    if vehicle.isClient then
        local spec = vehicle.spec_machine

        if not spec then
            Logging.warning('[MachineSpecialization.onRegisterActionEvents] vehicle.spec_machine is nil')
            return
        end

        vehicle:clearActionEventsTable()

        local machine = spec.machine
        local addActionEvents = isActiveForInputIgnoreSelection

        if machine:getIsAttachable() and machine:getNumMachinesOnVehicle() > 1 then
            addActionEvents = isActiveForInput
        end

        if addActionEvents then
            MachineSpecialization.addActionEvent(vehicle, spec, 'enableState', MachineSpecialization.actionEventToggleEnabled, MachineSpecialization.getActionText('enableMachine'))

            if spec.type.hasTerraformMode then
                MachineSpecialization.addActionEvent(vehicle, spec, 'toggleTerraformMode', MachineSpecialization.actionEventToggleTerraformMode, MachineSpecialization.getActionText('toggleTerraformMode'))
            end
            if spec.type.hasDischargeMode then
                MachineSpecialization.addActionEvent(vehicle, spec, 'toggleDischargeMode', MachineSpecialization.actionEventToggleDischargeMode, MachineSpecialization.getActionText('toggleDischargeMode'))
            end

            MachineSpecialization.addActionEvent(vehicle, spec, 'openMenu', MachineSpecialization.actionEventOpenMenu, MachineSpecialization.getActionText('openMenu'))
        end

        MachineSpecialization.updateActionEvents(vehicle)
    end
end

---@param vehicle Vehicle
function MachineSpecialization.updateActionEvents(vehicle)
    local spec = vehicle.spec_machine
    local machine = spec.machine

    if not machine then
        Logging.info('[MachineSpecialization.updateActionEvents] machine is nil')
        Logging.info(tostring(vehicle.configFileNameClean))
        return
    end

    local isActiveForInputIgnoreSelection = vehicle:getIsActiveForInput(true)
    local isActiveForInput = vehicle:getIsActiveForInput()

    local isActive = isActiveForInputIgnoreSelection

    if machine:getIsAttachable() and machine:getNumMachinesOnVehicle() > 1 then
        isActive = isActiveForInput
    end

    if not isActive or not g_terraFarm:getIsEnabled() then
        if spec.type.hasDischargeMode then
            MachineSpecialization.updateActionEvent(spec, 'toggleDischargeMode', false)
        end
        if spec.type.hasTerraformMode then
            MachineSpecialization.updateActionEvent(spec, 'toggleTerraformMode', false)
        end
        MachineSpecialization.updateActionEvent(spec, 'enableState', false)
        MachineSpecialization.updateActionEvent(spec, 'openMenu', false)

        if machine == g_machineManager:getCurrentMachine() then
            g_machineManager:setCurrentMachine()
        end

        return
    end

    if machine ~= g_machineManager:getCurrentMachine() then
        g_machineManager:setCurrentMachine(machine)
    end

    if machine.enabled then
        MachineSpecialization.updateActionEvent(spec, 'enableState', true, MachineSpecialization.getActionText('disableMachine'))
    else
        MachineSpecialization.updateActionEvent(spec, 'enableState', true, MachineSpecialization.getActionText('enableMachine'))
    end

    if machine.type.hasDischargeMode then
        MachineSpecialization.updateActionEvent(spec, 'toggleDischargeMode', true)
    end

    if machine.type.hasTerraformMode then
        MachineSpecialization.updateActionEvent(spec, 'toggleTerraformMode', true)
    end

    MachineSpecialization.updateActionEvent(spec, 'openMenu', true)

end

---@param spec MachineSpec
---@param name InputActionBindingName
---@param active boolean
---@param text string
function MachineSpecialization.updateActionEvent(spec, name, active, text)
    local action = MachineSpecialization.getActionBinding(name)
    if action then
        local actionEvent = spec.actionEvents[action]
        if actionEvent then
            g_inputBinding:setActionEventActive(actionEvent.actionEventId, active)

            if text then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
            end
        end
    end
end

---@param vehicle Vehicle
---@param spec MachineSpec
---@param name InputActionBindingName
---@param text string
function MachineSpecialization.addActionEvent(vehicle, spec, name, func, text, priority)
    local action = MachineSpecialization.getActionBinding(name)
    if action then
        local _, eventId = vehicle:addActionEvent(spec.actionEvents, action, vehicle, func, false, true, false, true)
        g_inputBinding:setActionEventText(eventId, text)
        g_inputBinding:setActionEventTextPriority(eventId, priority or GS_PRIO_NORMAL)
    end
end

function MachineSpecialization.getIsDischargeNodeActive(self, func, ...)
    if g_terraFarm:getIsEnabled() then
        local machine = g_machineManager:getMachineByObject(self)
        if machine and machine.enabled and machine.shovelGetIsDischargeNodeActive then
            return machine:shovelGetIsDischargeNodeActive(self, func, ...)
        end
    end
    return func(self, ...)
end
function MachineSpecialization.handleDischarge(self, func, ...)
    if g_terraFarm:getIsEnabled() then
        local machine = g_machineManager:getMachineByObject(self)
        if machine and machine.enabled and machine.shovelHandleDischarge then
            return machine:shovelHandleDischarge(self, func, ...)
        end
    end
    return func(self, ...)
end
function MachineSpecialization.handleDischargeRaycast(self, func, ...)
    if g_terraFarm:getIsEnabled() then
        local machine = g_machineManager:getMachineByObject(self)
        if machine and machine.enabled and machine.shovelHandleDischargeRaycast then
            return machine:shovelHandleDischargeRaycast(self, func, ...)
        end
    end
    return func(self, ...)
end


Vehicle.load = Utils.appendedFunction(Vehicle.load, MachineSpecialization.afterVehicleLoad)