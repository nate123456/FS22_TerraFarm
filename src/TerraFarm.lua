local modFolder = g_currentModDirectory

---@class TerraFarm
---@field enabled boolean
---@field debug boolean
---@field isReady boolean
---@field isDedicatedServer boolean
---@field isServer boolean
---@field isClient boolean
TerraFarm = {}
local TerraFarm_mt = Class(TerraFarm)

---@return TerraFarm
function TerraFarm.new()
    ---@type TerraFarm
    local self = setmetatable({}, TerraFarm_mt)

    self.enabled = true
    self.debug = true

    self.isDedicatedServer = not not g_dedicatedServer
    self.isServer = g_server ~= nil
    self.isClient = g_client ~= nil

    self.isReady = false

    return self
end

function TerraFarm:setIsEnabled(state)
    self.enabled = state
end

function TerraFarm:getIsEnabled()
    return self.enabled
end

function TerraFarm:onReady()
    TerraFarmFillTypes:initialize()
    self:setupGUI()
    self.isReady = true
    self:debug_print()
end

local dialogTimerId

function TerraFarm:doCheck()
    local densityMapSize = getDensityMapSize(g_currentMission.terrainDetailHeightId)
    if densityMapSize ~= 4096 then
        Logging.info('terrain densityMapSize: ' .. tostring(densityMapSize))
        if not g_dedicatedServer then
            dialogTimerId = addTimer(2500, 'dialogTimerCallback', self)
        else
            Logging.warning("This map does not have a terrain density size supported by TerraFarm, terrain deformation may not work as intended.")
        end
    end
end

function TerraFarm:dialogTimerCallback()
    dialogTimerId = nil
    g_gui:showInfoDialog({
        text = "This map does not have a terrain density size supported by TerraFarm, terrain deformation may not work as intended."
    })
end

function TerraFarm:debug_print()
    print('   ')
    print('getDensityMapSize: ' .. tostring(getDensityMapSize(g_currentMission.terrainDetailHeightId)))
    print('   ')
    DebugUtil.printTableRecursively({
        worldToDensityMap = g_densityMapHeightManager.worldToDensityMap,
        fillToGroundScale = g_densityMapHeightManager.fillToGroundScale,
        volumePerPixel = g_densityMapHeightManager.volumePerPixel,
        literPerPixel = g_densityMapHeightManager.literPerPixel,
        minValidLiterValue = g_densityMapHeightManager.minValidLiterValue,
        minValidVolumeValue = g_densityMapHeightManager.minValidVolumeValue,
        heightToDensityValue = g_densityMapHeightManager.heightToDensityValue,
    })
    print('   ')
    print('   ')
end

function TerraFarm:onMapLoaded()
    self:loadConfigurations()
end

function TerraFarm:onUpdate(dt)
    if not self.isReady then return end
    if self.isDedicatedServer then return end

    local machine = g_machineManager.currentMachine
    if machine then
        if machine.enabled then
            machine:onUpdate(dt)
        end

        if self.debug then
            if not machine.enabled then
                machine:updateNodes()
            end
            MachineDebug.draw()
        end
    end
end

function TerraFarm:onDraw()
    g_machineHUD:draw()
    self:drawNodeLevels()
end

function TerraFarm:drawNodeLevels()
    local machine = g_machineManager:getCurrentMachine()

    if not machine then
        return
    end

    local vehicle = machine:getVehicle()

    if vehicle then
        local x, y, z = getWorldTranslation(vehicle.rootNode)
        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

        Utils.renderTextAtWorldPosition(x, height, z, "B", getCorrectTextSize(0.1), 0, TerraFarm.colorBelow)
    end
end

function TerraFarm:getMachineModeByName(name)
    return TerraFarmMachine.NAME_TO_MODE[name]
end

function TerraFarm:getInterval()
    return 100
end

function TerraFarm:openMenu()
    if g_terraFarmSettingsScreen then
        g_gui:showGui('TerraFarmSettingsScreen')
    end
end

function TerraFarm:loadConfigurations()
    g_machineConfigurationManager:init(modFolder .. 'xml_configurations/')
end

function TerraFarm:setupGUI()
    ---@diagnostic disable-next-line: lowercase-global
    g_terraFarmSettingsScreen = TerraFarmSettingsScreen.new(nil, nil, g_messageCenter, g_i18n, g_inputBinding)

    -- Load frames first
    g_gui:loadGui(modFolder .. 'xml/TerraFarmSettingsGlobalFrame.xml', 'TerraFarmSettingGlobalFrame', TerraFarmSettingsGlobalFrame.new(), true)
    g_gui:loadGui(modFolder .. 'xml/TerraFarmSettingsMachineFrame.xml', 'TerraFarmSettingsMachineFrame', TerraFarmSettingsMachineFrame.new(), true)

    -- Load screen last
    g_gui:loadGui(modFolder .. 'xml/TerraFarmSettingsScreen.xml', 'TerraFarmSettingsScreen', g_terraFarmSettingsScreen)
end

function TerraFarm:getMachineManager()
    return g_machineManager
end

FSBaseMission.onStartMission = Utils.appendedFunction(FSBaseMission.onStartMission,
    function()
        if not g_server and g_currentMission and g_client then
            local event = MachineRequestStateSyncEvent.new()
            g_client:getServerConnection():sendEvent(event)
        end
        g_terraFarm:doCheck()
    end
)

---@diagnostic disable-next-line: lowercase-global
g_terraFarm = TerraFarm.new()