---@class MachineRequestStateSyncEvent
MachineRequestStateSyncEvent = {}
local MachineRequestStateSyncEvent_mt = Class(MachineRequestStateSyncEvent, Event)

InitEventClass(MachineRequestStateSyncEvent, 'MachineRequestStateSyncEvent')

function MachineRequestStateSyncEvent.emptyNew()
    local self = Event.new(MachineRequestStateSyncEvent_mt)
    return self
end

function MachineRequestStateSyncEvent.new()
    local self = MachineRequestStateSyncEvent.emptyNew()
    return self
end

function MachineRequestStateSyncEvent:writeStream(streamId)
end

function MachineRequestStateSyncEvent:readStream(streamId, connection)
    self:run(connection)
end

function MachineRequestStateSyncEvent:run(connection)
    if g_currentMission and g_currentMission:getIsServer() then
        for _, machine in pairs(g_machineManager.machines) do
            local event = MachineStateEvent.new(machine)
            Logging.info('[MachineRequestStateSyncEvent:run] Sending state for: %s', tostring(machine:getDescription()))
            connection:sendEvent(event)
        end
    end
end