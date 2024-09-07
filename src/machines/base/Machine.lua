---@alias StrengthModifierProperty string | "'terraformStrength'" | "'dischargeStrength'" | "'flattenStrength'" | "'smoothStrength'"
---@alias RadiusModifierProperty string | "'terraformRadius'" | "'dischargeRadius'" | "'flattenRadius'" | "'smoothRadius'" | "'paintRadius'"

---@class TerraFarmMachine
---@field lastUpdate number
---@field type MachineType
---@field object Vehicle
---@field config MachineXMLConfiguration
---@field fillUnit FillUnit
--- BUFFERS
---@field dischargeFillBuffer number
---@field terraformVolumeBuffer number
---@field dischargeVolumeBuffer number
--- MACHINE STATE
---@field enabled boolean
---@field terraformMode number
---@field dischargeMode number
---@field disableDischarge boolean
---@field disablePaint boolean
---@field disableClearDeco boolean
---@field disableClearWeed boolean
---@field disableRemoveField boolean
---@field clearDensityMap boolean
---@field fillTypeIndex number
---@field terraformPaintLayerId number
---@field dischargePaintLayerId number
---@field useFillTypeMassPerLiter boolean
--- MACHINE MODIFIERS STATE
---@field terraformStrengthPct number
---@field terraformRadiusPct number
---@field dischargeStrengthPct number
---@field dischargeRadiusPct number
---@field flattenStrengthPct number
---@field flattenRadiusPct number
---@field smoothStrengthPct number
---@field smoothRadiusPct number
---@field paintRadiusPct number
--- NODES
---@field nodeIsTouchingTerrain boolean[]
---@field nodeTerrainHeight number[]
---@field nodePosition Position[]
---@field terraformNodesIsTouchingTerrain boolean
---@field collisionNodesIsTouchingTerrain boolean
---@field terraformNodes number[]
---@field collisionNodes number[]
---@field dischargeLines NodeLine[]
---@field paintNodes number[]
----@field dischargeNodes number[]
---@field rootNodes MachineRootNodes
--- SHOVEL FUNCTIONS
---@field shovelGetIsDischargeNodeActive function
---@field shovelHandleDischarge function
---@field shovelHandleDischargeRaycast function
--- LEVELER FUNCTIONS
---@field onLevelerRaycastCallback function
---@field levelerGetIsLevelerPickupNodeActive function
---@field onLevelerUpdate function
--- HEIGHT LOCKING
--- @field heightLockEnabled boolean
--- @field heightLockHeight number
TerraFarmMachine = {}
local TerraFarmMachine_mt = Class(TerraFarmMachine)

TerraFarmMachine.MODE_NUM_BITS = 3
TerraFarmMachine.MODIFIER_NUM_BITS = 4

TerraFarmMachine.MODE = {
    NORMAL = 1,
    RAISE = 2,
    LOWER = 3,
    SMOOTH = 4,
    FLATTEN = 5,
    PAINT = 6
}

TerraFarmMachine.NAME_TO_MODE = {
    ['NORMAL'] = TerraFarmMachine.MODE.NORMAL,
    ['RAISE'] = TerraFarmMachine.MODE.RAISE,
    ['LOWER'] = TerraFarmMachine.MODE.LOWER,
    ['SMOOTH'] = TerraFarmMachine.MODE.SMOOTH,
    ['FLATTEN'] = TerraFarmMachine.MODE.FLATTEN,
    ['PAINT'] = TerraFarmMachine.MODE.PAINT
}

TerraFarmMachine.MODE_TO_NAME = {
    [TerraFarmMachine.MODE.NORMAL] = 'NORMAL',
    [TerraFarmMachine.MODE.RAISE] = 'RAISE',
    [TerraFarmMachine.MODE.LOWER] = 'LOWER',
    [TerraFarmMachine.MODE.SMOOTH] = 'SMOOTH',
    [TerraFarmMachine.MODE.FLATTEN] = 'FLATTEN',
    [TerraFarmMachine.MODE.PAINT] = 'PAINT',
}

TerraFarmMachine.DEFAULT = {
    terraformRadius = 3.5,
    terraformStrength = 0.8,
    dischargeRadius = 3.5,
    dischargeStrength = 0.8,
    flattenRadius = 3.5,
    flattenStrength = 0.8,
    smoothRadius = 3.5,
    --smoothStrength = 0.8,
    smoothStrength = 0.1,
    paintRadius = 5,

    radiusPctIndex = 4,
    strengthPctIndex = 10,
}

TerraFarmMachine.RADIUS_MODIFIERS = {
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0
}

TerraFarmMachine.RADIUS_MODIFIER_TEXTS = {
    '25%',
    '50%',
    '75%',
    '100%',
    '125%',
    '150%',
    '175%',
    '200%'
}

TerraFarmMachine.STRENGTH_MODIFIERS = {
    0.1,
    0.2,
    0.3,
    0.4,
    0.5,
    0.6,
    0.7,
    0.8,
    0.9,
    1.0,
    1.25,
    1.50,
    1.75,
    2.0
}

TerraFarmMachine.STRENGTH_MODIFIER_TEXTS = {
    '10%',
    '20%',
    '30%',
    '40%',
    '50%',
    '60%',
    '70%',
    '80%',
    '90%',
    '100%',
    '125%',
    '150%',
    '175%',
    '200%'
}

---@return TerraFarmMachine
function TerraFarmMachine.new(object, machineType, config, mt)
    ---@type TerraFarmMachine
    local self = setmetatable({}, mt or TerraFarmMachine_mt)

    self.lastUpdate = 0
    self.type = machineType
    self.object = object
    self.config = config

    self:initFillUnit()
    self:initFillType()

    -- Machine state
    self.enabled = false
    self.terraformMode = self.config.terraform and self.config.terraform.availableModes[1] or TerraFarmMachine.MODE.NORMAL
    self.dischargeMode = self.config.discharge and self.config.discharge.availableModes[1] or TerraFarmMachine.MODE.NORMAL
    self.disableDischarge = false
    self.disablePaint = false
    self.clearDensityMap = false
    self.terraformPaintLayerId = TerraFarmGroundTypes:getDefaultLayerId()
    self.dischargePaintLayerId = TerraFarmGroundTypes:getDefaultLayerId()
    self.disableClearDeco = false
    self.disableClearWeed = false
    self.disableRemoveField = false
    self.useFillTypeMassPerLiter = true

    -- Machine modifiers state
    self.terraformStrengthPct = TerraFarmMachine.DEFAULT.strengthPctIndex
    self.terraformRadiusPct = TerraFarmMachine.DEFAULT.radiusPctIndex
    self.dischargeStrengthPct = TerraFarmMachine.DEFAULT.strengthPctIndex
    self.dischargeRadiusPct = TerraFarmMachine.DEFAULT.radiusPctIndex
    self.flattenStrengthPct = TerraFarmMachine.DEFAULT.strengthPctIndex
    self.flattenRadiusPct = TerraFarmMachine.DEFAULT.radiusPctIndex
    self.smoothStrengthPct = TerraFarmMachine.DEFAULT.strengthPctIndex
    self.smoothRadiusPct = TerraFarmMachine.DEFAULT.radiusPctIndex
    self.paintRadiusPct = TerraFarmMachine.DEFAULT.radiusPctIndex

    -- Nodes
    self.nodeIsTouchingTerrain = {}
    self.nodeTerrainHeight = {}
    self.nodePosition = {}
    self.terraformNodesIsTouchingTerrain = false
    self.collisionNodesIsTouchingTerrain = false
    self.terraformNodes = {}
    self.collisionNodes = {}
    self.dischargeLines = {}
    -- self.dischargeNodes = {}
    self.rootNodes = {}
    self.paintNodes = {}

    -- Buffers
    self.dischargeFillBuffer = 0
    self.terraformVolumeBuffer = 0
    self.dischargeVolumeBuffer = 0

    -- Height Lock Mode
    self.heightLockEnabled = false
    self.heightLockHeight = 0

    return self
end

function TerraFarmMachine:sendStateEvent()
    if not g_dedicatedServer and g_client then
        if g_server then
            local event = MachineStateEvent.newServerToClient(self)
            g_server:broadcastEvent(event)
        else
            local event = MachineStateEvent.new(self)
            g_client:getServerConnection():sendEvent(event)
        end
    end
end

function TerraFarmMachine:getId()
    return NetworkUtil.getObjectId(self.object)
end

function TerraFarmMachine:setStateValue(property, value)
    self[property] = value
    self:sendStateEvent()
end

function TerraFarmMachine:onStateUpdated()
    if g_dedicatedServer or g_machineManager:getCurrentMachine() ~= self then
        return
    end

    self:updateFillType()
end

---@param property StrengthModifierProperty
---@param pctIndex number
---@return number
function TerraFarmMachine:getStrength(property, pctIndex)
    return TerraFarmMachine.DEFAULT[property] * TerraFarmMachine.STRENGTH_MODIFIERS[pctIndex]
end

---@param property RadiusModifierProperty
---@param pctIndex number
---@return number
function TerraFarmMachine:getRadius(property, pctIndex)
    local value = TerraFarmMachine.DEFAULT[property]
    if self.config[property] then
        value = self.config[property]
    end
    return value * TerraFarmMachine.RADIUS_MODIFIERS[pctIndex]
end

function TerraFarmMachine:initFillUnit()
    if self.type.hasFillUnit then
        self.fillUnit = self:getFillUnit()
        assert(self.fillUnit, '[TerraFarmMachine:initFillUnit] Machine type hasFillUnit but unable to find suitable fillUnit')
    end
end

function TerraFarmMachine:initFillType()
    self.fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(TerraFarmFillTypes.DEFAULT_FILLTYPE_NAME)
end

function TerraFarmMachine:updateFillType()
    if not self.fillTypeIndex then
        self:initFillType()
    end

    if self.type.hasFillUnit then
        self.object:setFillUnitFillType(
            self.fillUnit.fillUnitIndex,
            self.fillTypeIndex
        )
        self:applyFillDelta(0)
    end
end

---@return Vehicle
function TerraFarmMachine:getVehicle()
    if self:getIsAttachable() then
        return self:getAttacherVehicle()
    end
    return self.object
end

function TerraFarmMachine:getIsAttachable()
    return false
end

function TerraFarmMachine:getAttacherVehicle()
    if self.object.findRootVehicle then
        return self.object:findRootVehicle()
    elseif self.object.getAttacherVehicle then
        return self.object:getAttacherVehicle()
    end
end

function TerraFarmMachine:getNumMachinesOnVehicle()
    if self:getIsAttachable() then
        local vehicle = self:getVehicle()
        if vehicle then
            local machines = g_machineManager:getVehicleAttachedMachines(vehicle)
            return #machines
        end
    end
    return 0
end

---@return FillUnit
---@return Vehicle
function TerraFarmMachine:getVehicleFillUnit()
    local vehicle = self:getVehicle()
    if not vehicle or not vehicle.getFillUnits then return end

    local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(TerraFarmFillTypes.FILLUNIT_FILLTYPE_NAME)

    for _, fillUnit in ipairs(vehicle:getFillUnits()) do
        if fillUnit.supportedFillTypes[fillTypeIndex] == true then
            return fillUnit, vehicle
        end
    end
end

function TerraFarmMachine:getFillUnit()
    if not self.type.hasFillUnit or not self.object or not self.object.spec_fillUnit or not self.object.getFillUnits then
        return
    end

    if self.config.fillUnitIndex then
        local spec = self.object.spec_fillUnit
        local fillUnit = spec.fillUnits[self.config.fillUnitIndex]
        if fillUnit then
            return fillUnit
        end
    end

    local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(TerraFarmFillTypes.FILLUNIT_FILLTYPE_NAME)

    for _, fillUnit in ipairs(self.object:getFillUnits()) do
        if fillUnit.supportedFillTypes[fillTypeIndex] == true then
            return fillUnit
        end
    end
end

---@return number x
---@return number y
---@return number z
---@return number height
---@return number rootNode
function TerraFarmMachine:getVehiclePosition()
    local vehicle = self:getVehicle()
    if vehicle then
        local x, y, z = getWorldTranslation(vehicle.rootNode)
        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

        return x, y, z, height, vehicle.rootNode
    end
end

---@return number
function TerraFarmMachine:getDrivingDirection()
    local vehicle = self:getVehicle()
    if vehicle then
        ---@diagnostic disable-next-line: undefined-field
        return vehicle:getDrivingDirection()
    end
    return 0
end

---@return string
function TerraFarmMachine:getDescription()
    return self.object:getFullName()
end

function TerraFarmMachine:hasMode(mode)
    if self.config.terraform then
        for _, m in pairs(self.config.terraform.availableModes) do
            if m == mode then return true end
        end
    end
    if self.config.discharge then
        for _, m in pairs(self.config.discharge.availableModes) do
            if m == mode then return true end
        end 
    end
    return false
end

function TerraFarmMachine:setTerraformMode(mode)
    if not self.type.hasTerraformMode then return end
    self:setStateValue('terraformMode', mode)
end

function TerraFarmMachine:toggleTerraformMode()
    if not self.config.terraform or #self.config.terraform.availableModes <= 1 or not self.terraformMode then
        return
    end

    local index = table.indexOf(self.config.terraform.availableModes, self.terraformMode) + 1
    self:setTerraformMode(self.config.terraform.availableModes[index] or self.config.terraform.availableModes[1])
end

function TerraFarmMachine:setDischargeMode(mode)
    if not self.type.hasDischargeMode then return end
    self:setStateValue('dischargeMode', mode)
end

function TerraFarmMachine:toggleHeightLock()
    local newEnabled = not self.heightLockEnabled

    self:setStateValue('heightLockEnabled', newEnabled)

    if newEnabled then
        self:setStateValue('heightLockHeight', self:getCurrentHeight())
    end
end

function TerraFarmMachine:getCurrentHeight()
    local x, _, z, height = self:getVehiclePosition()
    return tonumber(string.format("%.2f", height))
    -- local totalY = 0
    -- local numNodes = 0

    -- for i, node in pairs(self.collisionNodes) do
    --     local position = self.nodePosition[node]
    --     totalY = totalY + position.y
    --     numNodes = numNodes + 1
    -- end

    -- return totalY / numNodes
end

function TerraFarmMachine:toggleDischargeMode()
    if not self.config.discharge or #self.config.discharge.availableModes <= 1 or not self.dischargeMode then
        return
    end

    local index = table.indexOf(self.config.discharge.availableModes, self.dischargeMode) + 1
    self:setDischargeMode(self.config.discharge.availableModes[index] or self.config.discharge.availableModes[1])
end

function TerraFarmMachine:setDisablePaint(value)
    self:setStateValue('disablePaint', value)
end

function TerraFarmMachine:setDisableDischarge(value)
    self:setStateValue('disableDischarge', value)
end

function TerraFarmMachine:setClearDensityMap(value)
    self:setStateValue('clearDensityMap', value)
end

function TerraFarmMachine:setIsEnabled(value)
    self:setStateValue('enabled', value)
end

function TerraFarmMachine:setTerraformStrength(pctIndex)
    self:setStateValue('terraformStrengthPct', pctIndex)
end

function TerraFarmMachine:getTerraformStrength()
    return self:getStrength('terraformStrength', self.terraformStrengthPct)
end

function TerraFarmMachine:setTerraformRadius(pctIndex)
    self:setStateValue('terraformRadiusPct', pctIndex)
end

function TerraFarmMachine:getTerraformRadius()
    return self:getRadius('terraformRadius', self.terraformRadiusPct)
end

function TerraFarmMachine:setDischargeStrength(pctIndex)
    self:setStateValue('dischargeStrengthPct', pctIndex)
end

function TerraFarmMachine:getDischargeStrength()
    return self:getStrength('dischargeStrength', self.dischargeStrengthPct)
end

function TerraFarmMachine:setDischargeRadius(pctIndex)
    self:setStateValue('dischargeRadiusPct', pctIndex)
end

function TerraFarmMachine:getDischargeRadius()
    return self:getRadius('dischargeRadius', self.dischargeRadiusPct)
end

function TerraFarmMachine:setFlattenStrength(pctIndex)
    self:setStateValue('flattenStrengthPct', pctIndex)
end

function TerraFarmMachine:getFlattenStrength()
    return self:getStrength('flattenStrength', self.flattenStrengthPct)
end

function TerraFarmMachine:setFlattenRadius(pctIndex)
    self:setStateValue('flattenRadiusPct', pctIndex)
end

function TerraFarmMachine:getFlattenRadius()
    return self:getRadius('flattenRadius', self.flattenRadiusPct)
end

function TerraFarmMachine:setSmoothStrength(pctIndex)
    self:setStateValue('smoothStrengthPct', pctIndex)
end

function TerraFarmMachine:getSmoothStrength()
    return self:getStrength('smoothStrength', self.smoothStrengthPct)
end

function TerraFarmMachine:setSmoothRadius(pctIndex)
    self:setStateValue('smoothRadiusPct', pctIndex)
end

function TerraFarmMachine:getSmoothRadius()
    return self:getRadius('smoothRadius', self.smoothRadiusPct)
end

function TerraFarmMachine:setPaintRadius(pctIndex)
    self:setStateValue('paintRadiusPct', pctIndex)
end

function TerraFarmMachine:getPaintRadius()
    return self:getRadius('paintRadius', self.paintRadiusPct)
end

function TerraFarmMachine:setTerraformPaintLayerId(id)
    if self.type.hasTerraformMode then
        self:setStateValue('terraformPaintLayerId', id)
    end
end

function TerraFarmMachine:setTerraformPaintLayer(name)
    if not self.type.hasTerraformMode then return end

    local layerId = g_groundTypeManager.terrainLayerMapping[name]
    if layerId then
        self:setTerraformPaintLayerId(layerId)
    end
end

function TerraFarmMachine:setDischargePaintLayerId(id)
    if self.type.hasDischargeMode then
        self:setStateValue('dischargePaintLayerId', id)
    end
end

function TerraFarmMachine:setDischargePaintLayer(name)
    if not self.type.hasDischargeMode then return end

    local layerId = g_groundTypeManager.terrainLayerMapping[name]
    if layerId then
        self:setDischargePaintLayerId(layerId)
    end
end

function TerraFarmMachine:setDisableClearDeco(value)
    self:setStateValue('disableClearDeco', value)
end

function TerraFarmMachine:setDisableClearWeed(value)
    self:setStateValue('disableClearWeed', value)
end

function TerraFarmMachine:setDisableRemoveField(value)
    self:setStateValue('disableRemoveField', value)
end

function TerraFarmMachine:setUseFillTypeMassPerLiter(value)
    self:setStateValue('useFillTypeMassPerLiter', value)
end

-- FillType functionality --

function TerraFarmMachine:getFillTypeMassPerLiter()
    if not self.useFillTypeMassPerLiter or not self.fillTypeIndex then
        return 1.0
    end
    local fillType = g_fillTypeManager:getFillTypeByIndex(self.fillTypeIndex)
    if not fillType then
        return 1.0
    end
    return fillType.massPerLiter * 1000  -- The value read from XML is divided by 1000
end

function TerraFarmMachine:applyFillDelta(fillDelta)
    if not self.type.hasFillUnit then return 0 end

    return self.object:addFillUnitFillLevel(
        self.object:getOwnerFarmId(),
        self.fillUnit.fillUnitIndex,
        fillDelta,
        self.fillTypeIndex,
        ToolType.UNDEFINED
    )
end

function TerraFarmMachine:setFillTypeIndex(index)
    if self.type.hasFillUnit or self.type.hasDischargeMode then
        if not g_fillTypeManager.fillTypes[index] then
            Logging.warning('[TerraFarmMachine:setFillTypeIndex] FillType index not found: %s', tostring(index))
            return
        end
        self:setStateValue('fillTypeIndex', index)
        self:updateFillType()
    end
end

function TerraFarmMachine:setFillType(name)
    if not self.type.hasFillUnit or not self.fillUnit or not self.type.hasDischargeMode then return end

    local fillType = g_fillTypeManager.nameToFillType[name]

    if not fillType then
        Logging.warning('[TerraFarmMachine:setFillType] Failed to get fillType by name: %s', tostring(name))
        if name ~= TerraFarmFillTypes.DEFAULT_FILLTYPE_NAME then
            Logging.info('[TerraFarmMachine:setFillType] Reverting to default fillType')
            return self:setFillType(TerraFarmFillTypes.DEFAULT_FILLTYPE_NAME)
        end
        return
    end

    return self:setFillTypeIndex(fillType.index)
end

function TerraFarmMachine:getCurrentFillType()
    if not self.type.hasFillUnit or not self.fillUnit then return end

    return self.fillUnit.fillType
end

function TerraFarmMachine:getIsCorrectFillType()
    if not self.type.hasFillUnit or not self.fillUnit then return false end

    return self.fillUnit.fillType == self.fillTypeIndex
end

function TerraFarmMachine:getFillLevel()
    if not self.type.hasFillUnit or not self.fillUnit then return 0 end

    return self.fillUnit.fillLevel
end

function TerraFarmMachine:getFillCapacity()
    if not self.type.hasFillUnit or not self.fillUnit then return 0 end

    return self.fillUnit.capacity
end

function TerraFarmMachine:getFreeFillCapacity()
    if not self.type.hasFillUnit or not self.fillUnit then return 0 end

    return self.fillUnit.capacity - self.fillUnit.fillLevel
end

function TerraFarmMachine:getIsEmpty()
    return self:getFillLevel() == 0
end

function TerraFarmMachine:getIsFull()
    local freeCapacity = self:getFreeFillCapacity()
    if freeCapacity and freeCapacity > 0 then
        return false
    end
    return true
end

function TerraFarmMachine:getFillPercentage()
    if not self.type.hasFillUnit or not self.fillUnit then return 0 end

    return (1.0 / self.fillUnit.capacity) * self.fillUnit.fillLevel
end

function TerraFarmMachine:getFillMassPerLiter()
    if not self.useFillTypeMassPerLiter then
        return 1.0 * 1000
    end
    if not self.fillTypeIndex then return 0 end
    local fillType = g_fillTypeManager:getFillTypeByIndex(self.fillTypeIndex)
    if not fillType then return 0 end
    return fillType.massPerLiter * 1000 * 1000
end

function TerraFarmMachine:getVolumeFillRatio()
    return self.config.volumeFillRatio or 1.0
end

function TerraFarmMachine:getDischargeRate()
    return self.config.discharge and self.config.discharge.rate or 1.0
end

-- Node functionality

function TerraFarmMachine:getIsTouchingTerrain()
    local isTouchingTerrain = self.terraformNodesIsTouchingTerrain or self.collisionNodesIsTouchingTerrain
    return isTouchingTerrain
end

function TerraFarmMachine:updateNodes()
    self.terraformNodesIsTouchingTerrain = self:updateTerrainNodes(self.terraformNodes)
    self.collisionNodesIsTouchingTerrain = self:updateTerrainNodes(self.collisionNodes)
    self:updatePositionNodes(self.paintNodes)
    self:updateDischargeLines()
end

function TerraFarmMachine:updateTerrainNodes(nodes)
    local result = false

    for _, node in ipairs(nodes) do
        local x, y, z = localToWorld(node, 0, 0, 0)
        local position = { x = x, y = y, z = z }
        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

        self.nodePosition[node] = position
        self.nodeTerrainHeight[node] = height

        if height and y <= height then
            self.nodeIsTouchingTerrain[node] = true
            result = true
        else
            self.nodeIsTouchingTerrain[node] = false
        end
    end

    return result
end

function TerraFarmMachine:updatePositionNodes(nodes)
    for _, node in ipairs(nodes) do
        local x, y, z = localToWorld(node, 0, 0, 0)
        local position = { x = x, y = y, z = z }
        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

        self.nodePosition[node] = position
        self.nodeTerrainHeight[node] = height
    end
end

function TerraFarmMachine:updateDischargeLines()
    for _, lineNodes in ipairs(self.dischargeLines) do
        local x1, y1, z1 = localToWorld(lineNodes.startNode, 0, 0, 0)
        local startPosition = { x = x1, y = y1, z = z1 }
        local startHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1)

        self.nodePosition[lineNodes.startNode] = startPosition
        self.nodeTerrainHeight[lineNodes.startNode] = startHeight

        local x2, y2, z2 = localToWorld(lineNodes.endNode, 0, 0, 0)
        local endPosition = { x = x2, y = y2, z = z2 }
        local endHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2)

        self.nodePosition[lineNodes.endNode] = endPosition
        self.nodeTerrainHeight[lineNodes.endNode] = endHeight
    end
end

---@return Position[]
function TerraFarmMachine:getTerrainPositions(nodes)
    local result = {}

    for _, node in pairs(nodes) do
        local position = self.nodePosition[node]
        local height = self.nodeTerrainHeight[node]

        if position and height then
            local entry = { x = position.x, y = height, z = position.z }
            table.insert(result, entry)
        end
    end

    return result
end

------

---@param dt number
function TerraFarmMachine:onUpdate(dt)
end

function TerraFarmMachine:onVolumeDisplacement(fillDelta, isDischarging)
end

function TerraFarmMachine:onDischarge()
end

function TerraFarmMachine:getTipFactor()
    return 0
end

function TerraFarmMachine:getRemoveFieldArea(operation, isDischarging)
    if self.disableRemoveField == true then
        return false
    end
    return true
end

function TerraFarmMachine:getRemoveWeedArea(operation, isDischarging)
    if self.disableClearWeed == true then
        return false
    end
    return true
end

function TerraFarmMachine:getRemoveTireTracks(operation, isDischarging)
    return true
end

function TerraFarmMachine:getRemoveStoneArea(operation, isDischarging)
    return true
end

function TerraFarmMachine:getClearDensityMapHeightArea(operation, isDischarging)
    if self.clearDensityMap == true then
        return true
    end
    return true
end

function TerraFarmMachine:getClearDecoArea(operation, isDischarging)
    if self.disableClearDeco == true then
        return false
    end
    return false
end

-- Landscaping functions --

function TerraFarmMachine:sendTerraformRequest(operation, brushShape, nodePositions, radius, strength, target, isDischarging, disableVolumeDisplacement)
    for _, position in pairs(nodePositions) do
        local event = TerraFarmLandscapingEvent.new(self, operation, position, radius, strength, 0.2, brushShape, target, isDischarging, disableVolumeDisplacement)
        g_client:getServerConnection():sendEvent(event)
    end
end

function TerraFarmMachine:applyTerraformRaise()
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.RAISE

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getTerraformRadius(),
        self:getTerraformStrength()
    )
end

function TerraFarmMachine:applyTerraformRaise()
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.RAISE

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getTerraformRadius(),
        self:getTerraformStrength()
    )
end

function TerraFarmMachine:applyDischargeRaise()
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.RAISE
    local tipFactor = self:getTipFactor()

    if tipFactor < 0.1 then
        return
    end

    local strength = (self:getDischargeStrength() * self:getTipFactor() * self:getDischargeRate()) / #nodePositions

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getDischargeRadius(),
        strength,
        nil,
        true
    )
end

function TerraFarmMachine:applyTerraformLower()
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.LOWER

    local strength = self:getTerraformStrength() / #nodePositions

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getTerraformRadius(),
        strength
    )
end

function TerraFarmMachine:applyTerraformSmooth()
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.SMOOTH

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getSmoothRadius(),
        self:getSmoothStrength()
    )
end

function TerraFarmMachine:applyDischargeSmooth()
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.SMOOTH

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getSmoothRadius(),
        self:getSmoothStrength(),
        nil,
        true
    )
end

function TerraFarmMachine:applyTerraformFlatten(target)
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.FLATTEN
    local strength = self:getFlattenStrength() / #nodePositions

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getFlattenRadius(),
        strength,
        target
    )
end

function TerraFarmMachine:applyDischargeFlatten(target)
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.FLATTEN

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getFlattenRadius(),
        self:getFlattenStrength(),
        target,
        true
    )
end

function TerraFarmMachine:applyTerraformPaint(radius)
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.TERRAFORM_PAINT

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        radius or self:getTerraformRadius(),
        self:getPaintRadius()
    )
end

function TerraFarmMachine:applyDischargePaint()
    local nodePositions = self:getTerrainPositions(self.terraformNodes)
    if #nodePositions == 0 then return end

    local mode = TerraFarmLandscaping.OPERATION.TERRAFORM_PAINT

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getDischargeRadius(),
        1.0,
        nil,
        true
    )
end

function TerraFarmMachine:applyPaint(isDischarging)
    local nodePositions = self:getTerrainPositions(self.paintNodes)
    if #nodePositions == 0 then
        return
        -- nodePositions = self:getTerrainPositions(self.config.terraformNodes)
        -- if #nodePositions == 0 then
        --     return
        -- end
    end

    local mode = TerraFarmLandscaping.OPERATION.PAINT
    local radius = self:getPaintRadius() / 2
    local strength = 1.0

    self:sendTerraformRequest(
        mode,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        radius,
        strength,
        nil,
        isDischarging
    )
end

-- Shovel functionality

function TerraFarmMachine:shovelGetIsDischargeNodeActive(shovel, func, ...)
    if g_terraFarm.enabled and self:getIsTouchingTerrain() then
        -- if self.terraformMode ~= TerraFarmMachine.MODE.NORMAL then
            return false
        -- end
    end
    return func(shovel, ...)
end

function TerraFarmMachine:shovelHandleDischarge(shovel, func, ...)
    if g_terraFarm.enabled then
        if self.enabled and self:getIsTouchingTerrain() then
            return
        elseif self.disableDischarge then
            local dischargeNode = unpack({...})
            if not dischargeNode and not dischargeNode.dischargeHitObject then
                return
            end
        end
    end
    return func(shovel, ...)
end

function TerraFarmMachine:shovelHandleDischargeRaycast(shovel, func, ...)
    if g_terraFarm.enabled then
        if self.enabled then
            if self.dischargeMode ~= TerraFarmMachine.MODE.NORMAL and self:getIsCorrectFillType() then
                self:onDischarge()
                return
            elseif self:getIsTouchingTerrain() then
                return
            end
        elseif self.disableDischarge then
            local dischargeNode = unpack({...})
            if not dischargeNode and not dischargeNode.dischargeHitObject then
                return
            end
        end
    end
    return func(shovel, ...)
end

-- Buffer functionality --

function TerraFarmMachine:getLitersFromAmount(amount)
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(self.fillTypeIndex)
    local fillToGroundScale = g_densityMapHeightManager.fillToGroundScale * heightType.fillToGroundScale
    return amount * fillToGroundScale
end

function TerraFarmMachine:getMinimumValidDischargeFillLiters()
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(self.fillTypeIndex)
    local fillToGroundScale = g_densityMapHeightManager.fillToGroundScale * heightType.fillToGroundScale
    return g_densityMapHeightManager.minValidLiterValue * fillToGroundScale
end

---@param amount number
---@return number
function TerraFarmMachine:getFillLitersFromBuffer(amount)
    local minimumLiters = self:getMinimumValidDischargeFillLiters()
    local nodeLines = self.dischargeLines

    self.dischargeFillBuffer = self.dischargeFillBuffer + amount
    local amountPerNode = self.dischargeFillBuffer / #nodeLines
    local litersPerNode = self:getLitersFromAmount(amountPerNode)

    if litersPerNode >= minimumLiters then
        self.dischargeFillBuffer = 0
        return litersPerNode
    end

    return 0
end

function TerraFarmMachine:getDischargeLines()
    return self.dischargeLines
end

function TerraFarmMachine:dischargeFillTypeToNodeLines(amount)
    if #self.dischargeLines == 0 then return end

    local litersPerNode = self:getFillLitersFromBuffer(amount)

    if litersPerNode > 0 then
        local nodeLines = self:getDischargeLines()
        for _, line in ipairs(nodeLines) do
            self:dischargeFillTypeAlongNodeLine(line, litersPerNode)
        end
    end
end

---@param line NodeLine
---@param liters any
function TerraFarmMachine:dischargeFillTypeAlongNodeLine(line, liters, xOffset)
    local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(self.fillTypeIndex)
    local sX, sY, sZ = localToWorld(line.startNode, xOffset or 0, 0, 0)
    local eX, eY, eZ = localToWorld(line.endNode, xOffset or 0, 0, 0)

    local radius = self:getDischargeRadius()
    local innerRadius = radius / 3

    addDensityMapHeightAtWorldLine(
        g_densityMapHeightManager:getTerrainDetailHeightUpdater(),
        sX, sY, sZ, eX, eY, eZ,
        liters, heightType.index, innerRadius, radius, false, 0, true
    )
end