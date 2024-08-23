---@class TerraFarmGroundTypes
TerraFarmGroundTypes = {}
TerraFarmGroundTypes.list = {}

local function isValidGroundTypeName(name)
    return name == string.upper(name)
end

function TerraFarmGroundTypes:initialize()
    for name, layerId in pairs(g_groundTypeManager.terrainLayerMapping) do
        if isValidGroundTypeName(name) then
            local entry = {
                name = name,
                layerId = layerId,
                stateIndex = #self.list
            }
            table.insert(self.list, entry)
        end
    end
end

function TerraFarmGroundTypes:getDefaultLayerId()
    return self:getLayerIdByName('DIRT')
end

function TerraFarmGroundTypes:getLayerIdByName(name)
    for _, entry in ipairs(self.list) do
        if entry.name == name then
            return entry.layerId
        end
    end
    if self.list[1] then
        return self.list[1].layerId
    end
    return 0
end

function TerraFarmGroundTypes:getLayerIdByStateIndex(stateIndex)
    if self.list[stateIndex] then
        return self.list[stateIndex].layerId
    end
    return 0
end

function TerraFarmGroundTypes:getStateIndex(layerId)
    for index, entry in ipairs(self.list) do
        if entry.layerId == layerId then
            return index
        end
    end
    return 0
end

function TerraFarmGroundTypes:getGroundTypeTexts()
    local result = {}

    for _, entry in ipairs(self.list) do
        table.insert(result, entry.name)
    end

    return result
end

GroundTypeManager.initTerrain = Utils.appendedFunction(GroundTypeManager.initTerrain,
    function ()
        TerraFarmGroundTypes:initialize()
    end
)