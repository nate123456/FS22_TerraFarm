---@class TerraFarmFillTypes
TerraFarmFillTypes = {}

TerraFarmFillTypes.FILLUNIT_FILLTYPE_NAME = 'STONE'
TerraFarmFillTypes.DEFAULT_FILLTYPE_NAME = 'STONE'
TerraFarmFillTypes.LOOKUP_NAMES = {}
TerraFarmFillTypes.EXCLUDE = {
    ['WHEAT'] = true,
    ['BARLEY'] = true,
    ['OAT'] = true,
    ['CANOLA'] = true,
    ['SUNFLOWER'] = true,
    ['SOYBEAN'] = true,
    ['MAIZE'] = true,
    ['POTATO'] = true,
    ['SUGARBEET'] = true,
    ['SUGARBEET_CUT'] = true,
    ['SEEDS'] = true,
    ['FORAGE'] = true,
    ['FORAGE_MIXING'] = true,
    ['CHAFF'] = true,
    ['WOODCHIPS'] = true,
    ['SILAGE'] = true,
    ['STRAW'] = true,
    ['GRASS_WINDROW'] = true,
    ['DRYGRASS_WINDROW'] = true,
    ['SUGARCANE'] = true,
    ['FERTILIZER'] = true,
    ['PIGFOOD'] = true,
    ['SORGHUM'] = true,
    ['OLIVE'] = true,
    ['MINERAL_FEED'] = true,
    --[''] = true,
}

TerraFarmFillTypes.list = {}

function TerraFarmFillTypes:initialize()
    for _, index in pairs(g_fillTypeManager:getFillTypesByCategoryNames('BULK')) do
        local fillType = g_fillTypeManager:getFillTypeByIndex(index)
        if not self.EXCLUDE[fillType.name] then
            self:add(fillType)
        end
    end
end

function TerraFarmFillTypes:add(fillType)
    local entry = {
        title = fillType.title,
        fillType = fillType,
        name = fillType.name,
        fillTypeIndex = fillType.index,
        stateIndex = #self.list
    }
    table.insert(self.list, entry)
end

function TerraFarmFillTypes:getFillTypeIndexByStateIndex(stateIndex)
    if self.list[stateIndex] then
        return self.list[stateIndex].fillTypeIndex
    end
    return 0
end

function TerraFarmFillTypes:getTitleByStateIndex(stateIndex)
    if self.list[stateIndex] then
        return self.list[stateIndex].title
    end
    return 'nil'
end

function TerraFarmFillTypes:getStateIndex(fillTypeIndex)
    for index, entry in ipairs(self.list) do
        if entry.fillTypeIndex == fillTypeIndex then
            return index
        end
    end
    return 0
end

function TerraFarmFillTypes:getFillTypeTexts()
    local result = {}

    for _, entry in ipairs(self.list) do
        table.insert(result, entry.title)
    end

    return result
end