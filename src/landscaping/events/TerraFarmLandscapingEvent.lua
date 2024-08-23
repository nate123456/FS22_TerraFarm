---@class TerraFarmLandscapingEvent
---@field runConnection Connection
---@field machine TerraFarmMachine
---@field terraformMode number
---@field dischargeMode number
---@field operation number
---@field position Position
---@field radius number
---@field strength number
---@field hardness number
---@field brushShape number
---@field terraformLayerId number
---@field dischargeLayerId number
---@field target Position
---@field isDischarging boolean
---@field disableVolumeDisplacement boolean
--- SERVER TO CLIENT
---@field errorCode number
---@field displacedVolumeOrArea number
TerraFarmLandscapingEvent = {}
local TerraFarmLandscapingEvent_mt = Class(TerraFarmLandscapingEvent, Event)

InitEventClass(TerraFarmLandscapingEvent, 'TerraFarmLandscapingEvent')

---@return TerraFarmLandscapingEvent
function TerraFarmLandscapingEvent.emptyNew()
    local self = Event.new(TerraFarmLandscapingEvent_mt)
    return self
end

---@param machine TerraFarmMachine
---@return TerraFarmLandscapingEvent
function TerraFarmLandscapingEvent.new(machine, operation, position, radius, strength, hardness, brushShape, target, isDischarging, disableVolumeDisplacement)
    local self = TerraFarmLandscapingEvent.emptyNew()

    self.runConnection = nil

    self.machine = machine

    self.terraformMode = machine.terraformMode or 0
    self.dischargeMode = machine.dischargeMode or 0

    self.terraformLayerId = machine.terraformPaintLayerId or 0
    self.dischargeLayerId = machine.dischargePaintLayerId or 0

    self.operation = operation
    self.brushShape = brushShape or Landscaping.BRUSH_SHAPE.CIRCLE

    self.radius = radius or 0
    self.strength = strength or 0
    self.hardness = hardness or 1.0
    self.isDischarging = isDischarging or false
    self.disableVolumeDisplacement = disableVolumeDisplacement or false

    self.position = position
    self.target = target

    return self
end

---@return TerraFarmLandscapingEvent
function TerraFarmLandscapingEvent.newServerToClient(errorCode, displacedVolumeOrArea)
    local self = TerraFarmLandscapingEvent.emptyNew()

    self.errorCode = errorCode
    self.displacedVolumeOrArea = displacedVolumeOrArea

    return self
end

---@param streamId number
---@param connection Connection
function TerraFarmLandscapingEvent:writeStream(streamId, connection)
    if connection:getIsServer() then
        NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.machine.object))

        streamWriteUIntN(streamId, self.terraformMode, TerraFarmMachine.MODE_NUM_BITS)
        streamWriteUIntN(streamId, self.dischargeMode, TerraFarmMachine.MODE_NUM_BITS)

        streamWriteFloat32(streamId, self.terraformLayerId)
        streamWriteFloat32(streamId, self.dischargeLayerId)

        streamWriteUIntN(streamId, self.operation, TerraFarmLandscaping.OPERATION_NUM_SEND_BITS)
        streamWriteUIntN(streamId, self.brushShape, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)

        streamWriteFloat32(streamId, self.radius)
        streamWriteFloat32(streamId, self.strength)
        streamWriteFloat32(streamId, self.hardness)

        streamWriteFloat32(streamId, self.position.x)
        streamWriteFloat32(streamId, self.position.y)
        streamWriteFloat32(streamId, self.position.z)

        if streamWriteBool(streamId, self.target ~= nil) then
            streamWriteFloat32(streamId, self.target.x)
            streamWriteFloat32(streamId, self.target.y)
            streamWriteFloat32(streamId, self.target.z)
        end

        streamWriteBool(streamId, self.isDischarging)
        streamWriteBool(streamId, self.disableVolumeDisplacement)
    else
        streamWriteUIntN(streamId, self.errorCode, TerrainDeformation.STATE_SEND_NUM_BITS)
        if streamWriteBool(streamId, self.errorCode == TerrainDeformation.STATE_SUCCESS) then
            streamWriteFloat32(streamId, self.displacedVolumeOrArea or 0)
        end
    end
end

---@param streamId number
---@param connection Connection
function TerraFarmLandscapingEvent:readStream(streamId, connection)
    if not connection:getIsServer() then
        local objectId = NetworkUtil.readNodeObjectId(streamId)
        local object = NetworkUtil.getObject(objectId)

        assert(object, '[TerraFarmLandscapingEvent:readStream] getObject() returned nil')

        self.machine = g_machineManager:getMachineByObject(object)

        assert(self.machine, '[TerraFarmLandscapingEvent:readStream] getMachineByObject() returned nil')

        self.terraformMode = streamReadUIntN(streamId, TerraFarmMachine.MODE_NUM_BITS)
        self.dischargeMode = streamReadUIntN(streamId, TerraFarmMachine.MODE_NUM_BITS)

        self.terraformLayerId = streamReadFloat32(streamId)
        self.dischargeLayerId = streamReadFloat32(streamId)

        self.operation = streamReadUIntN(streamId, TerraFarmLandscaping.OPERATION_NUM_SEND_BITS)
        self.brushShape = streamReadUIntN(streamId, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)

        self.radius = streamReadFloat32(streamId)
        self.strength = streamReadFloat32(streamId)
        self.hardness = streamReadFloat32(streamId)

        self.position = {}
        self.position.x = streamReadFloat32(streamId)
        self.position.y = streamReadFloat32(streamId)
        self.position.z = streamReadFloat32(streamId)

        if streamReadBool(streamId) then
            self.target = {}
            self.target.x = streamReadFloat32(streamId)
            self.target.y = streamReadFloat32(streamId)
            self.target.z = streamReadFloat32(streamId)
        end

        self.isDischarging = streamReadBool(streamId)
        self.disableVolumeDisplacement = streamReadBool(streamId)
    else
        self.errorCode = streamReadUIntN(streamId, TerrainDeformation.STATE_SEND_NUM_BITS)

        if streamReadBool(streamId) then
            self.displacedVolumeOrArea = streamReadFloat32(streamId)
        else
            self.displacedVolumeOrArea = 0
        end
    end

    self:run(connection)
end

---@param connection Connection
function TerraFarmLandscapingEvent:run(connection)
    if not connection:getIsServer() and g_currentMission then
        self.runConnection = connection
        local landscaping = TerraFarmLandscaping.new(self.onSculptingFinished, self)

        landscaping:apply()
    else
        g_messageCenter:publish(TerraFarmLandscapingEvent, self.errorCode, self.displacedVolumeOrArea)
    end
end

function TerraFarmLandscapingEvent:onSculptingFinished(errorCode, displacedVolumeOrArea)
    if self.runConnection and self.runConnection.isConnected then
        local response = TerraFarmLandscapingEvent.newServerToClient(errorCode, displacedVolumeOrArea)
        self.runConnection:sendEvent(response)
    end
end