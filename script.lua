local modFolder = g_currentModDirectory

---@return number
table.indexOf = function(list, value)
    for i, v in ipairs(list) do
        if v == value then
            return i
        end
    end
end

source(modFolder .. 'src/landscaping/TerraFarmFillTypes.lua')
source(modFolder .. 'src/landscaping/TerraFarmGroundTypes.lua')

source(modFolder .. 'src/TerraFarm.lua')
source(modFolder .. 'src/debug/MachineDebug.lua')

source(modFolder .. 'src/machines/base/MachineType.lua')
source(modFolder .. 'src/machines/base/MachineTypeManager.lua')

source(modFolder .. 'src/specializations/MachineSpecialization.lua')

source(modFolder .. 'src/landscaping/TerraFarmLandscaping.lua')
source(modFolder .. 'src/landscaping/events/TerraFarmLandscapingEvent.lua')

source(modFolder .. 'src/machines/base/Machine.lua')
source(modFolder .. 'src/machines/base/MachineManager.lua')
source(modFolder .. 'src/machines/events/MachineStateEvent.lua')
source(modFolder .. 'src/machines/events/MachineRequestStateSyncEvent.lua')

source(modFolder .. 'src/machines/Bucket.lua')
source(modFolder .. 'src/machines/BulldozerBlade.lua')
source(modFolder .. 'src/machines/Bulldozer.lua')
source(modFolder .. 'src/machines/Ripper.lua')
source(modFolder .. 'src/machines/GroundRipper.lua')
source(modFolder .. 'src/machines/RoadCompactor.lua')
source(modFolder .. 'src/machines/RoadScraper.lua')
source(modFolder .. 'src/machines/BucketExcavator.lua')
source(modFolder .. 'src/machines/BucketWheelLoader.lua')
source(modFolder .. 'src/machines/SuctionAttachment.lua')

source(modFolder .. 'src/machines/base/MachineXMLConfiguration.lua')
source(modFolder .. 'src/machines/base/MachineConfigurationManager.lua')

source(modFolder .. 'src/hud/MachineHUD.lua')

source(modFolder .. 'src/gui/TerraFarmSettingsScreen.lua')
source(modFolder .. 'src/gui/TerraFarmSettingsMachineFrame.lua')
source(modFolder .. 'src/gui/TerraFarmSettingsGlobalFrame.lua')


local TerraFarmMod = {}

function TerraFarmMod:update(dt)
    if g_terraFarm then
        g_terraFarm:onUpdate(dt)
    end
end

function TerraFarmMod:loadMap()
    g_terraFarm:onMapLoaded()
end

function TerraFarmMod:draw()
    g_terraFarm:onDraw()
end

FSBaseMission.onFinishedLoading = Utils.appendedFunction(FSBaseMission.onFinishedLoading,
    function()
        g_terraFarm:onReady()
    end
)

addModEventListener(TerraFarmMod)