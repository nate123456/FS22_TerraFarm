local modFolder = g_currentModDirectory

---@param filename string
---@return string path
---@return string fileName
---@return string fileExt
local function splitFilename(filename)
    return string.match(filename, "(.-)([^\\]-([^\\%.]+))$")
end

---@class MachineConfigurationManager
---@field xmlConfigurations MachineXMLConfiguration[]
---@field fileNameToConfig table<string, MachineXMLConfiguration>
MachineConfigurationManager = {}

local MachineConfigurationManager_mt = Class(MachineConfigurationManager)

function MachineConfigurationManager.new()
    ---@type MachineConfigurationManager
    local self = setmetatable({}, MachineConfigurationManager_mt)

    self.xmlConfigurations = {}
    self.fileNameToConfig = {}

    return self
end

---@param vehicle Vehicle
function MachineConfigurationManager:getVehicleConfig(vehicle)
    local modFilename, isMod, isDlc = Utils.removeModDirectory(vehicle.configFileName)
    local xmlName = vehicle.configFileNameClean:lower()

    if isMod then
        local vehicleTypeName = vehicle.typeName:split('.')
        local modName, typeName, path

        if #vehicleTypeName == 1 then
            modName, path = Utils.getModNameAndBaseDirectory(vehicle.configFileName)
            if not modName then
                return
            end
            modName = modName:lower()
            typeName = vehicleTypeName[1]:lower()
        else
            modName = vehicleTypeName[1]:lower()
            typeName = vehicleTypeName[2]:lower()
        end

        return self:find(modName, typeName, xmlName)
    else
        local vehicleTypeName = vehicle.typeName:lower()
        local modName = 'giants'

        return self:find(modName, vehicleTypeName, xmlName)
    end
end

---@return MachineXMLConfiguration
function MachineConfigurationManager:find(modName, typeName, xmlName)
    -- print('MachineConfigurationManager:find()')
    DebugUtil.printTableRecursively({
        modName = modName, typeName = typeName, xmlName = xmlName
    })
    for _, config in pairs(self.xmlConfigurations) do
        if config.modNames[modName] and config.typeName == typeName and config.xmlName == xmlName then
            return config
        end
    end
end

function MachineConfigurationManager:loadXMLFile(xmlFilePath)
    -- print('[MachineConfigurationManager:loadXMLFile()]')
    local success, config = pcall(MachineXMLConfiguration.new, xmlFilePath)
    if success and config then
        self:register(config, xmlFilePath)
    elseif not success then
        print('ERROR - PCALL FAILED: ' .. tostring(config))
    end
end

---@param path string
function MachineConfigurationManager:iterateDirectoryFiles(path, isBase)
    local files = Files.new(path)
    for _, file in pairs(files.files) do
        local xmlFilePath = path .. file.filename
        if file.isDirectory then
            self:iterateDirectoryFiles(path .. file.filename .. '/')
        else
            self:loadXMLFile(xmlFilePath)
        end
    end
end

function MachineConfigurationManager:register(config, filename)
    local _, fileName = splitFilename(filename)
    self.fileNameToConfig[fileName:lower()] = config
    table.insert(self.xmlConfigurations, config)
    DebugUtil.printTableRecursively(config, '    ', 0, 0)
end

function MachineConfigurationManager:loadIndexFile()
    local path = modFolder .. 'xml_configurations/index.xml'
    local xmlFile = loadXMLFile('config_index', path)
    if xmlFile == nil or xmlFile == 0 then
        return
    end

    local i = 0
    while true do
        local key = string.format('configurations.entry(%d)', i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local fileName = getXMLString(xmlFile, key)
        if fileName then
            local xmlFilePath = modFolder .. 'xml_configurations/' .. fileName
            self:loadXMLFile(xmlFilePath)
        end
        i = i + 1
    end

    delete(xmlFile)
end

function MachineConfigurationManager:init(path)
    if fileExists(path) then
        self:iterateDirectoryFiles(path, true)
    else
        self:loadIndexFile()
    end
    if #self.xmlConfigurations == 0 then
        Logging.error('MachineConfigurationManager: No configurations found')
    end
end

---@diagnostic disable-next-line: lowercase-global
g_machineConfigurationManager = MachineConfigurationManager.new()