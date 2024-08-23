---@class MachineRotation
---@field nodeIndex string
---@field axis number
---@field threshold number
---@field min number
---@field max number
---@field offsetFactor number
local MachineRotation = {}

---@class MachineTerraform
---@field nodeIndex string
---@field offset Position
---@field nodes Position[]
---@field availableModes number[]
---@field radius number
local MachineTerraform = {}

---@class MachineCollision
---@field nodeIndex string
---@field offset Position
---@field nodes Position[]
local MachineCollision = {}

---@class MachineDischarge
---@field nodeIndex number
---@field offset Position
---@field nodes Position[]
---@field lines LinePosition[]
---@field availableModes number[]
---@field radius number
---@field rate number
local MachineDischarge = {}

---@class MachinePaint
---@field nodes Position[]
---@field radius number
local MachinePaint = {}

---@class MachineXMLConfiguration
---@field xmlFilePath string
---@field xmlFile XMLFile
---@field machineTypeName string
---@field machineType MachineType
---@field modNames table<string, boolean>
---@field typeName string
---@field xmlName string
---@field terraform MachineTerraform
---@field collision MachineCollision
---@field discharge MachineDischarge
---@field rotation MachineRotation
---@field flattenRadius number
---@field smoothRadius number
---@field paintRadius number
---@field volumeFillRatio number
---@field fillUnitIndex number
MachineXMLConfiguration = {}
local MachineXMLConfiguration_mt = Class(MachineXMLConfiguration)

function MachineXMLConfiguration.new(xmlFilePath)
    ---@type MachineXMLConfiguration
    local self = setmetatable({}, MachineXMLConfiguration_mt)
    self.xmlFilePath = xmlFilePath
    self:load()
    return self
end

function MachineXMLConfiguration:load()
    self.xmlFile = loadXMLFile('config_load', self.xmlFilePath)
    if self.xmlFile == nil or self.xmlFile == 0 then
        Logging.error('[MachineXMLConfiguration:load] Failed to read xml file: %s', tostring(self.xmlFilePath))
        return
    end

    self:loadAttributes()
    self:loadCollision()
    self:loadTerraform()
    self:loadDischarge()
    self:loadRotation()
    self:loadPaint()
    self:loadSettings()

    delete(self.xmlFile)
    self.xmlFile = nil
end

---@return Position
function MachineXMLConfiguration:getNodeOffset(path)
    local result = {
        x = Utils.getNoNil(getXMLFloat(self.xmlFile, path .. '#x'), 0),
        y = Utils.getNoNil(getXMLFloat(self.xmlFile, path .. '#y'), 0),
        z = Utils.getNoNil(getXMLFloat(self.xmlFile, path .. '#z'), 0),
    }
    return result
end

---@return LinePosition
function MachineXMLConfiguration:getNodeLine(path)
    local result = {
        x1 = Utils.getNoNil(getXMLFloat(self.xmlFile, path .. '#x1'), 0),
        y1 = Utils.getNoNil(getXMLFloat(self.xmlFile, path .. '#y1'), 0),
        z1 = Utils.getNoNil(getXMLFloat(self.xmlFile, path .. '#z1'), 0),
        x2 = Utils.getNoNil(getXMLFloat(self.xmlFile, path .. '#x2'), 0),
        y2 = Utils.getNoNil(getXMLFloat(self.xmlFile, path .. '#y2'), 0),
        z2 = Utils.getNoNil(getXMLFloat(self.xmlFile, path .. '#z2'), 0),
    }
    return result
end

function MachineXMLConfiguration:loadTerraform()
    ---@type MachineTerraform
    local result = {
        nodes = {},
        availableModes = {}
    }
    local xmlPath = 'configuration.terraform.'

    result.nodeIndex = getXMLString(self.xmlFile, xmlPath .. 'i3d#parent')
    if not result.nodeIndex then
        return
    end
    result.offset = self:getNodeOffset(xmlPath .. 'i3d')

    local i = 0
    while true do
        local key = string.format(xmlPath .. 'i3d.node(%d)', i)
        if not hasXMLProperty(self.xmlFile, key) then
            break
        end
        local node = self:getNodeOffset(key)
        table.insert(result.nodes, node)
        i = i + 1
    end

    i = 0
    while true do
        local key = string.format(xmlPath .. 'modes.mode(%d)', i)
        if not hasXMLProperty(self.xmlFile, key) then
            break
        end
        local name = getXMLString(self.xmlFile, key)
        local mode = g_terraFarm:getMachineModeByName(name)
        if mode then
            table.insert(result.availableModes, mode)
        else
            Logging.warning('[MachineConfiguration:loadTerraformSpec] Unknown mode: %s', tostring(name))
        end
        i = i + 1
    end

    result.radius = getXMLFloat(self.xmlFile, xmlPath .. 'radius')
    self.terraform = result

    -- TODO: Refactor these old properties
    self.terraformRadius = result.radius
    return true
end

function MachineXMLConfiguration:loadPaint()
    ---@type MachinePaint
    local result = {
        nodes = {}
    }
    local xmlPath = 'configuration.paint.'

    result.nodeIndex = getXMLString(self.xmlFile, xmlPath .. 'i3d#parent')
    if not result.nodeIndex then
        return
    end
    result.offset = self:getNodeOffset(xmlPath .. 'i3d')

    local i = 0
    while true do
        local key = string.format(xmlPath .. 'i3d.node(%d)', i)
        if not hasXMLProperty(self.xmlFile, key) then
            break
        end
        local node = self:getNodeOffset(key)
        table.insert(result.nodes, node)
        i = i + 1
    end

    result.radius = getXMLFloat(self.xmlFile, xmlPath .. 'radius')

    self.paint = result

    -- TODO: Refactor these old properties
    self.paintRadius = result.radius
    return true
end

function MachineXMLConfiguration:loadCollision()
    ---@type MachineCollision
    local result = {
        nodes = {}
    }
    local xmlPath = 'configuration.collision.'

    result.nodeIndex = getXMLString(self.xmlFile, xmlPath .. 'i3d#parent')
    if not result.nodeIndex then
        return
    end
    result.offset = self:getNodeOffset(xmlPath .. 'i3d')

    local i = 0
    while true do
        local key = string.format(xmlPath .. 'i3d.node(%d)', i)
        if not hasXMLProperty(self.xmlFile, key) then
            break
        end
        local node = self:getNodeOffset(key)
        table.insert(result.nodes, node)
        i = i + 1
    end

    self.collision = result

    return true
end

function MachineXMLConfiguration:loadDischarge()
    ---@type MachineDischarge
    local result = {
        nodes = {},
        lines = {},
        availableModes = {}
    }
    local xmlPath = 'configuration.discharge.'

    result.nodeIndex = getXMLString(self.xmlFile, xmlPath .. 'i3d#parent')
    if result.nodeIndex then

        result.offset = self:getNodeOffset(xmlPath .. 'i3d')

        local i = 0
        while true do
            local key = string.format(xmlPath .. 'i3d.line(%d)', i)
            if not hasXMLProperty(self.xmlFile, key) then
                break
            end
            local line = self:getNodeLine(key)
            table.insert(result.lines, line)
            i = i + 1
        end

        i = 0
        while true do
            local key = string.format(xmlPath .. 'i3d.node(%d)', i)
            if not hasXMLProperty(self.xmlFile, key) then
                break
            end
            local node = self:getNodeOffset(key)
            table.insert(result.nodes, node)
            i = i + 1
        end
    end

    local i = 0
    while true do
        local key = string.format(xmlPath .. 'modes.mode(%d)', i)
        if not hasXMLProperty(self.xmlFile, key) then
            break
        end
        local name = getXMLString(self.xmlFile, key)
        local mode = g_terraFarm:getMachineModeByName(name)
        if mode then
            table.insert(result.availableModes, mode)
        else
            Logging.warning('[MachineConfiguration:loadDischargeSpec] Unknown mode: %s', tostring(name))
        end
        i = i + 1
    end

    result.radius = getXMLFloat(self.xmlFile, xmlPath .. 'radius')
    result.rate = Utils.getNoNil(getXMLFloat(self.xmlFile, xmlPath .. 'rate'), 1.0)

    self.discharge = result

    -- TODO: Refactor these old properties
    self.dischargeRadius = result.radius
    return true
end

function MachineXMLConfiguration:loadRotation()
    ---@type MachineRotation
    local result = {}
    local xmlPath = 'configuration.rotation.'

    result.nodeIndex = getXMLString(self.xmlFile, xmlPath .. 'i3d#parent')
    if not result.nodeIndex then
        return
    end

    result.axis = getXMLInt(self.xmlFile, xmlPath .. 'axis')
    result.min = getXMLFloat(self.xmlFile, xmlPath .. 'min')
    result.max = getXMLFloat(self.xmlFile, xmlPath .. 'max')
    result.threshold = Utils.getNoNil(getXMLFloat(self.xmlFile, xmlPath .. 'threshold'), 20)
    result.offsetFactor = Utils.getNoNil(getXMLFloat(self.xmlFile, xmlPath .. 'offsetFactor'), 1.0)

    self.rotation = result

    return true
end

function MachineXMLConfiguration:loadSettings()
    local xmlPath = 'configuration.settings.'

    self.flattenRadius = getXMLFloat(self.xmlFile, xmlPath .. 'flattenRadius')
    self.smoothRadius = getXMLFloat(self.xmlFile, xmlPath .. 'smoothRadius')

    self.volumeFillRatio = Utils.getNoNil(getXMLFloat(self.xmlFile, xmlPath .. 'volumeFillRatio'), 1.0)
    self.fillUnitIndex = getXMLInt(self.xmlFile, xmlPath .. 'fillUnitIndex')
end

function MachineXMLConfiguration:loadAttributes()
    self.machineTypeName = getXMLString(self.xmlFile, 'configuration#machineType')
    self.machineType = g_machineTypeManager:getMachineTypeByName(self.machineTypeName)
    if not self.machineType then
        Logging.error('[MachineXMLConfiguration:loadAttributes] Unknown machineType: %s', tostring(self.machineTypeName))
    end
    local modNameStr = Utils.getNoNil(getXMLString(self.xmlFile, 'configuration#modName'), '')
    local modNames = modNameStr:split(',')
    self.modNames = {}
    for _, name in pairs(modNames) do
        self.modNames[name:lower()] = true
    end

    self.typeName = getXMLString(self.xmlFile, 'configuration#typeName'):lower()
    self.xmlName = getXMLString(self.xmlFile, 'configuration#xmlName'):lower()
end

---@param machine TerraFarmMachine
function MachineXMLConfiguration:apply(machine)
    self:applyCollisionConfiguration(machine)
    self:applyTerraformConfiguration(machine)
    self:applyDischargeConfiguration(machine)
    self:applyRotationConfiguration(machine)
    self:applyPaintConfiguration(machine)
end

---@param machine TerraFarmMachine
function MachineXMLConfiguration:applyTerraformConfiguration(machine)
    Logging.info('[MachineXMLConfiguration:applyTerraformConfiguration()]')
    if not self.terraform then
        Logging.warning('[MachineXMLConfiguration:applyTerraformConfiguration] Terraform configuration not loaded')
        return
    end
    local root = I3DUtil.indexToObject(machine.object.components, self.terraform.nodeIndex, machine.object.i3dMappings)
    if not root then
        Logging.error('[MachineXMLConfiguration:applyTerraformConfiguration] Could not find i3d node: %s', tostring(self.terraform.nodeIndex))
        return
    end

    local parent = createTransformGroup('terraform')
    link(root, parent)
    machine.rootNodes.terraform = parent

    setTranslation(parent,
        self.terraform.offset.x,
        self.terraform.offset.y,
        self.terraform.offset.z
    )

    for i, position in ipairs(self.terraform.nodes) do
        local node = createTransformGroup('terraformNode' .. i)
        link(parent, node)
        setTranslation(node,
            position.x,
            position.y,
            position.z
        )
        table.insert(machine.terraformNodes, node)
    end
end

---@param machine TerraFarmMachine
function MachineXMLConfiguration:applyPaintConfiguration(machine)
    Logging.info('[MachineXMLConfiguration:applyPaintConfiguration()]')
    if not self.paint then
        Logging.warning('[MachineXMLConfiguration:applyPaintConfiguration] Paint configuration not loaded')
        return
    end
    local root = I3DUtil.indexToObject(machine.object.components, self.paint.nodeIndex, machine.object.i3dMappings)
    if not root then
        Logging.error('[MachineXMLConfiguration:applyPaintConfiguration] Could not find i3d node: %s', tostring(self.paint.nodeIndex))
        return
    end

    local parent = createTransformGroup('paint')
    link(root, parent)
    machine.rootNodes.paint = parent

    setTranslation(parent,
        self.paint.offset.x,
        self.paint.offset.y,
        self.paint.offset.z
    )

    for i, position in ipairs(self.paint.nodes) do
        local node = createTransformGroup('paintNode' .. i)
        link(parent, node)
        setTranslation(node,
            position.x,
            position.y,
            position.z
        )
        table.insert(machine.paintNodes, node)
    end
end

---@param machine TerraFarmMachine
function MachineXMLConfiguration:applyCollisionConfiguration(machine)
    Logging.info('[MachineXMLConfiguration:applyCollisionConfiguration()]')
    if not self.collision then
        Logging.warning('[MachineXMLConfiguration:applyCollisionConfiguration] Collision configuration not loaded')
        return
    end
    local root = I3DUtil.indexToObject(machine.object.components, self.collision.nodeIndex, machine.object.i3dMappings)
    if not root then
        Logging.error('[MachineXMLConfiguration:applyCollisionConfiguration] Could not find i3d node: %s', tostring(self.collision.nodeIndex))
        return
    end

    local parent = createTransformGroup('collision')
    link(root, parent)
    machine.rootNodes.collision = parent

    setTranslation(parent,
        self.collision.offset.x,
        self.collision.offset.y,
        self.collision.offset.z
    )

    for i, position in ipairs(self.collision.nodes) do
        local node = createTransformGroup('collisionNode' .. i)
        link(parent, node)
        setTranslation(node,
            position.x,
            position.y,
            position.z
        )
        table.insert(machine.collisionNodes, node)
    end
end

---@param machine TerraFarmMachine
function MachineXMLConfiguration:applyDischargeConfiguration(machine)
    Logging.info('[MachineXMLConfiguration:applyDischargeConfiguration()]')
    if not self.discharge then
        Logging.warning('[MachineXMLConfiguration:applyDischargeConfiguration] discharge configuration not loaded')
        return
    end
    if not self.discharge.nodeIndex then
        return
    end
    local root = I3DUtil.indexToObject(machine.object.components, self.discharge.nodeIndex, machine.object.i3dMappings)
    if not root then
        Logging.error('[MachineXMLConfiguration:applyDischargeConfiguration] Could not find i3d node: %s', tostring(self.discharge.nodeIndex))
        return
    end

    local parent = createTransformGroup('discharge')
    link(root, parent)
    machine.rootNodes.discharge = parent

    setTranslation(parent,
        self.discharge.offset.x,
        self.discharge.offset.y,
        self.discharge.offset.z
    )

    for i, position in ipairs(self.discharge.lines) do
        local startNode = createTransformGroup('startNode' .. i)
        link(parent, startNode)

        setTranslation(startNode,
            position.x1,
            position.y1,
            position.z1
        )

        local endNode = createTransformGroup('endNode' .. i)
        link(startNode, endNode)

        setTranslation(endNode,
            position.x2,
            position.y2,
            position.z2
        )

        local line = { startNode = startNode, endNode = endNode }
        table.insert(machine.dischargeLines, line)
    end
end

---@param machine TerraFarmMachine
function MachineXMLConfiguration:applyRotationConfiguration(machine)
    Logging.info('[MachineXMLConfiguration:applyRotationConfiguration()]')
    if not self.rotation then
        return
    end
    machine.rootNodes.rotation = I3DUtil.indexToObject(machine.object.components, self.rotation.nodeIndex, machine.object.i3dMappings)
    if not machine.rootNodes.rotation then
        Logging.error('[MachineXMLConfiguration:applyRotationConfiguration] Could not find i3d node: %s', tostring(self.rotation.nodeIndex))
        return
    end
end