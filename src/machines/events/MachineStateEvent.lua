---@class MachineStateEvent
---@field machine TerraFarmMachine
MachineStateEvent = {}
local MachineStateEvent_mt = Class(MachineStateEvent, Event)

InitEventClass(MachineStateEvent, 'MachineStateEvent')

---@return MachineStateEvent
function MachineStateEvent.emptyNew()
    local self = Event.new(MachineStateEvent_mt)
    return self
end

---@return MachineStateEvent
function MachineStateEvent.new(machine)
    local self = MachineStateEvent.emptyNew()
    self.machine = machine
    return self
end

---@return MachineStateEvent
function MachineStateEvent.newServerToClient(machine)
    local self = MachineStateEvent.emptyNew()
    self.machine = machine
    return self
end

---@param streamId number
function MachineStateEvent:writeStream(streamId)
    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.machine.object))

    streamWriteBool(streamId, self.machine.enabled)
    streamWriteBool(streamId, self.machine.disableDischarge)
    streamWriteBool(streamId, self.machine.disablePaint)
    streamWriteBool(streamId, self.machine.clearDensityMap)
    streamWriteBool(streamId, self.machine.disableClearDeco)
    streamWriteBool(streamId, self.machine.disableClearWeed)
    streamWriteBool(streamId, self.machine.disableRemoveField)
    streamWriteBool(streamId, self.machine.useFillTypeMassPerLiter)
    streamWriteUIntN(streamId, self.machine.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)

    if streamWriteBool(streamId, self.machine.type.hasTerraformMode) then
        streamWriteUIntN(streamId, self.machine.terraformMode, TerraFarmMachine.MODE_NUM_BITS)
        streamWriteFloat32(streamId, self.machine.terraformPaintLayerId)
        streamWriteUIntN(streamId, self.machine.terraformStrengthPct, TerraFarmMachine.MODIFIER_NUM_BITS)
        streamWriteUIntN(streamId, self.machine.terraformRadiusPct, TerraFarmMachine.MODIFIER_NUM_BITS)
    end

    if streamWriteBool(streamId, self.machine.type.hasDischargeMode) then
        streamWriteUIntN(streamId, self.machine.dischargeMode, TerraFarmMachine.MODE_NUM_BITS)
        streamWriteFloat32(streamId, self.machine.dischargePaintLayerId)
        streamWriteUIntN(streamId, self.machine.dischargeStrengthPct, TerraFarmMachine.MODIFIER_NUM_BITS)
        streamWriteUIntN(streamId, self.machine.dischargeRadiusPct, TerraFarmMachine.MODIFIER_NUM_BITS)
    end

    streamWriteUIntN(streamId, self.machine.flattenStrengthPct, TerraFarmMachine.MODIFIER_NUM_BITS)
    streamWriteUIntN(streamId, self.machine.flattenRadiusPct, TerraFarmMachine.MODIFIER_NUM_BITS)

    streamWriteUIntN(streamId, self.machine.smoothStrengthPct, TerraFarmMachine.MODIFIER_NUM_BITS)
    streamWriteUIntN(streamId, self.machine.smoothRadiusPct, TerraFarmMachine.MODIFIER_NUM_BITS)

    streamWriteUIntN(streamId, self.machine.paintRadiusPct, TerraFarmMachine.MODIFIER_NUM_BITS)

    streamWriteBool(streamId, self.machine.heightLockEnabled)
    streamWriteFloat32(streamId, self.machine.heightLockHeight)
end

function MachineStateEvent:readStream(streamId, connection)
    local objectId = NetworkUtil.readNodeObjectId(streamId)
    local object = NetworkUtil.getObject(objectId)

    assert(object, '[MachineStateEvent:readStream] object is nil')

    self.machine = g_machineManager:getMachineByObject(object)

    self.machine.enabled = streamReadBool(streamId)
    self.machine.disableDischarge = streamReadBool(streamId)
    self.machine.disablePaint = streamReadBool(streamId)
    self.machine.clearDensityMap = streamReadBool(streamId)
    self.machine.disableClearDeco = streamReadBool(streamId)
    self.machine.disableClearWeed = streamReadBool(streamId)
    self.machine.disableRemoveField = streamReadBool(streamId)
    self.machine.useFillTypeMassPerLiter = streamReadBool(streamId)
    self.machine.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

    if streamReadBool(streamId) then
        self.machine.terraformMode = streamReadUIntN(streamId, TerraFarmMachine.MODE_NUM_BITS)
        self.machine.terraformPaintLayerId = streamReadFloat32(streamId)
        self.machine.terraformStrengthPct = streamReadUIntN(streamId, TerraFarmMachine.MODIFIER_NUM_BITS)
        self.machine.terraformRadiusPct = streamReadUIntN(streamId, TerraFarmMachine.MODIFIER_NUM_BITS)
    end

    if streamReadBool(streamId) then
        self.machine.dischargeMode = streamReadUIntN(streamId, TerraFarmMachine.MODE_NUM_BITS)
        self.machine.dischargePaintLayerId = streamReadFloat32(streamId)
        self.machine.dischargeStrengthPct = streamReadUIntN(streamId, TerraFarmMachine.MODIFIER_NUM_BITS)
        self.machine.dischargeRadiusPct = streamReadUIntN(streamId, TerraFarmMachine.MODIFIER_NUM_BITS)
    end

    self.machine.flattenStrengthPct = streamReadUIntN(streamId, TerraFarmMachine.MODIFIER_NUM_BITS)
    self.machine.flattenRadiusPct = streamReadUIntN(streamId, TerraFarmMachine.MODIFIER_NUM_BITS)

    self.machine.smoothStrengthPct = streamReadUIntN(streamId, TerraFarmMachine.MODIFIER_NUM_BITS)
    self.machine.smoothRadiusPct = streamReadUIntN(streamId, TerraFarmMachine.MODIFIER_NUM_BITS)

    self.machine.paintRadiusPct = streamReadUIntN(streamId, TerraFarmMachine.MODIFIER_NUM_BITS)

    self.machine.heightLockEnabled = streamReadBool(streamId)
    self.machine.heightLockHeight = streamReadFloat32(streamId)

    self.machine:onStateUpdated()

    self:run(connection)
end

---@param connection Connection
function MachineStateEvent:run(connection)
    if not connection:getIsServer() and g_currentMission then
        -- Logging.info('[MachineStateEvent:run] broadcast event')
        local event = MachineStateEvent.newServerToClient(self.machine)
        g_server:broadcastEvent(event)
    else
        -- Logging.info('[MachineStateEvent:run] publish event')
        g_messageCenter:publish(MachineStateEvent, self.machine)
    end
end