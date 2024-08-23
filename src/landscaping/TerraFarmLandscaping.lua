---@class TerraFarmLandscaping
---@field terrainDeformationQueue TerrainDeformationQueue
---@field terrainRootNode number
---@field terrainUnit number
---@field halfTerrainUnit number
---@field modifiedAreas table
---@field currentTerrainDeformation TerrainDeformation
---@field callbackFunction function
---@field callbackFunctionTarget TerraFarmLandscapingEvent
TerraFarmLandscaping = {}
local TerraFarmLandscaping_mt = Class(TerraFarmLandscaping)

TerraFarmLandscaping.OPERATION_NUM_SEND_BITS = 4
TerraFarmLandscaping.OPERATION = {
    PAINT = 1,
    RAISE = 2,
    LOWER = 3,
    SMOOTH = 4,
    FLATTEN = 5,
    TERRAFORM_PAINT = 6
}

TerraFarmLandscaping.OPERATION_TO_NAME = {
    [TerraFarmLandscaping.OPERATION.PAINT] = 'PAINT',
    [TerraFarmLandscaping.OPERATION.RAISE] = 'RAISE',
    [TerraFarmLandscaping.OPERATION.LOWER] = 'LOWER',
    [TerraFarmLandscaping.OPERATION.SMOOTH] = 'SMOOTH',
    [TerraFarmLandscaping.OPERATION.FLATTEN] = 'FLATTEN',
    [TerraFarmLandscaping.OPERATION.TERRAFORM_PAINT] = 'TERRAFORM_PAINT',
}

---@param callbackFunction function
---@param callbackFunctionTarget TerraFarmLandscapingEvent
---@return TerraFarmLandscaping
function TerraFarmLandscaping.new(callbackFunction, callbackFunctionTarget)
    ---@type TerraFarmLandscaping
    local self = setmetatable({}, TerraFarmLandscaping_mt)

    self.terrainDeformationQueue = g_terrainDeformationQueue
    self.terrainRootNode = g_currentMission.terrainRootNode
    self.terrainUnit = Landscaping.TERRAIN_UNIT
    self.halfTerrainUnit = Landscaping.TERRAIN_UNIT / 2
    self.modifiedAreas = {}

    self.callbackFunction = callbackFunction
    self.callbackFunctionTarget = callbackFunctionTarget

    return self
end

function TerraFarmLandscaping:assignPaintingModifiedAreaOnly()
    local brushShape = self.callbackFunctionTarget.brushShape
    local position = self.callbackFunctionTarget.position
    local radius = self.callbackFunctionTarget.radius or 1.0

    if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        Landscaping.addModifiedCircleArea(self, position.x, position.z, radius)
    else
        Landscaping.addModifiedSquareArea(self, position.x, position.z, radius * 2)
    end
end

---@param deform TerrainDeformation
function TerraFarmLandscaping:assignPaintingParameters(deform) --, x, z, radius, brushShape, layerId, strength, hardness)
    local brushShape = self.callbackFunctionTarget.brushShape
    local position = self.callbackFunctionTarget.position
    local radius = self.callbackFunctionTarget.radius or 1.0
    local hardness = self.callbackFunctionTarget.hardness or 1.0
    local strength = self.callbackFunctionTarget.strength or 1.0

    local isDischarging = self.callbackFunctionTarget.isDischarging
    local machine = self.callbackFunctionTarget.machine
    local layerId = 0


    if isDischarging then
        layerId = machine.dischargePaintLayerId
    else
        layerId = machine.terraformPaintLayerId
    end

    if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        deform:addSoftCircleBrush(position.x, position.z, radius, hardness, strength, layerId)
        Landscaping.addModifiedCircleArea(self, position.x, position.z, radius)
    else
        deform:addSoftSquareBrush(position.x, position.z, radius * 2, hardness, strength, layerId)
        Landscaping.addModifiedSquareArea(self, position.x, position.z, radius * 2)
    end
end

---@param deform TerrainDeformation
function TerraFarmLandscaping:assignSmoothingParameters(deform) --, x, z, radius, strength, brushShape, hardness)
    local brushShape = self.callbackFunctionTarget.brushShape
    local position = self.callbackFunctionTarget.position
    local radius = self.callbackFunctionTarget.radius or 1.0
    local hardness = self.callbackFunctionTarget.hardness or 0.2
    local strength = self.callbackFunctionTarget.strength or 1.0

    deform:setAdditiveHeightChangeAmount(0.5)

    if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        deform:addSoftCircleBrush(position.x, position.z, radius, hardness, strength)
        Landscaping.addModifiedCircleArea(self, position.x, position.z, radius)
    else
        deform:addSoftSquareBrush(position.x, position.z, radius * 2, hardness, strength)
        Landscaping.addModifiedSquareArea(self, position.x, position.z, radius * 2)
    end

    deform:enableSmoothingMode()
end

---@param deform TerrainDeformation
function TerraFarmLandscaping:assignSculptingParameters(deform)
    local brushShape = self.callbackFunctionTarget.brushShape
    local position = self.callbackFunctionTarget.position
    local radius = self.callbackFunctionTarget.radius or 1.0
    local hardness = self.callbackFunctionTarget.hardness or 0.2
    local strength = self.callbackFunctionTarget.strength or 1.0
    local operation = self.callbackFunctionTarget.operation
    local target = self.callbackFunctionTarget.target

    if operation == TerraFarmLandscaping.OPERATION.LOWER then
        deform:enableAdditiveDeformationMode()
        deform:setAdditiveHeightChangeAmount(-0.005)
    elseif operation == TerraFarmLandscaping.OPERATION.RAISE then
        deform:enableAdditiveDeformationMode()
        deform:setAdditiveHeightChangeAmount(0.005)
    elseif operation == TerraFarmLandscaping.OPERATION.FLATTEN then
        deform:setAdditiveHeightChangeAmount(0.05)
        deform:setHeightTarget(target.y, target.y, 0, 1, 0, -target.y)
        deform:enableSetDeformationMode()
    end

    if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        deform:addSoftCircleBrush(position.x, position.z, radius, hardness, strength)
        Landscaping.addModifiedCircleArea(self, position.x, position.z, radius)
    else
        deform:addSoftSquareBrush(position.x, position.z, radius * 2, hardness, strength)
        Landscaping.addModifiedSquareArea(self, position.x, position.z, radius * 2)
    end

    deform:setOutsideAreaConstraints(0, math.pi * 2, math.pi * 2)
end

function TerraFarmLandscaping.addModifiedSquareArea(self, ...)
    Landscaping.addModifiedSquareArea(self, ...)
end

function TerraFarmLandscaping:apply()
    -- local machine = self.callbackFunctionTarget.machine
    local operation = self.callbackFunctionTarget.operation
    local machine = self.callbackFunctionTarget.machine

    self.isTerrainDeformationPending = true
    local deform = TerrainDeformation.new(self.terrainRootNode)
    self.currentTerrainDeformation = deform

    if operation == TerraFarmLandscaping.OPERATION.SMOOTH then
        self:assignSmoothingParameters(deform)

        deform:setBlockedAreaMaxDisplacement(0.00001)
        deform:setDynamicObjectCollisionMask(0)
        deform:setDynamicObjectMaxDisplacement(0.00003)

        self.terrainDeformationQueue:queueJob(deform, false, 'onSculptingApplied', self)
    elseif operation == TerraFarmLandscaping.OPERATION.PAINT or operation == TerraFarmLandscaping.OPERATION.TERRAFORM_PAINT then
        if machine.disablePaint ~= true then
            self:assignPaintingParameters(deform)
        else
            self:assignPaintingModifiedAreaOnly()
        end
        deform:apply(false, 'onSculptingApplied', self)
    else
        self:assignSculptingParameters(deform)

        deform:setBlockedAreaMaxDisplacement(0.00001)
        deform:setDynamicObjectCollisionMask(0)
        deform:setDynamicObjectMaxDisplacement(0.00003)

        self.terrainDeformationQueue:queueJob(deform, false, 'onSculptingApplied', self)
    end
end

function TerraFarmLandscaping:applyDensityMapChanges()
    local machine = self.callbackFunctionTarget.machine
    local operation = self.callbackFunctionTarget.operation
    local isDischarging = self.callbackFunctionTarget.isDischarging

    local removeFieldArea = machine:getRemoveFieldArea(operation, isDischarging)
    local removeWeedArea = machine:getRemoveWeedArea(operation, isDischarging)
    local removeTireTracks = machine:getRemoveTireTracks(operation, isDischarging)
    local removeStoneArea = machine:getRemoveStoneArea(operation, isDischarging)
    local clearDensityMapHeightArea = machine:getClearDensityMapHeightArea(operation, isDischarging)
    local clearDecoArea = machine:getClearDecoArea(operation, isDischarging)

    if operation == TerraFarmLandscaping.OPERATION.PAINT or operation == TerraFarmLandscaping.OPERATION.TERRAFORM_PAINT then
        removeStoneArea = false
        clearDensityMapHeightArea = false
    end

    for _, area in pairs(self.modifiedAreas) do
        local x, z, x1, z1, x2, z2 = unpack(area)

        if removeFieldArea then
            FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2, false)
        end
        if removeWeedArea then
            FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
        end
        if removeTireTracks then
            FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
        end
        if removeStoneArea then
            FSDensityMapUtil.removeStoneArea(x, z, x1, z1, x2, z2)
        end
        if clearDensityMapHeightArea then
            DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)
        end

        if clearDecoArea then
            FSDensityMapUtil.clearDecoArea(x, z, x1, z1, x2, z2)
        end

        local minX = math.min(x, x1, x2, x2 + x1 - x)
        local maxX = math.max(x, x1, x2, x2 + x1 - x)
        local minZ = math.min(z, z1, z2, z2 + z1 - z)
        local maxZ = math.max(z, z1, z2, z2 + z1 - z)

        g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
    end
end

function TerraFarmLandscaping:onSculptingApplied(errorCode, displacedVolumeOrArea)
    if errorCode == TerrainDeformation.STATE_SUCCESS then
        local operation = self.callbackFunctionTarget.operation
        local disableVolumeDisplacement = self.callbackFunctionTarget.disableVolumeDisplacement

        if operation ~= TerraFarmLandscaping.OPERATION.PAINT and operation ~= TerraFarmLandscaping.OPERATION.TERRAFORM_PAINT and disableVolumeDisplacement ~= true then

            local machine = self.callbackFunctionTarget.machine
            local isDischarging = self.callbackFunctionTarget.isDischarging

            local volume = 0
            if isDischarging then
                machine.dischargeVolumeBuffer = machine.dischargeVolumeBuffer + displacedVolumeOrArea
                volume = machine.dischargeVolumeBuffer
            else
                machine.terraformVolumeBuffer = machine.terraformVolumeBuffer + displacedVolumeOrArea
                volume = machine.terraformVolumeBuffer
            end

            if volume > g_densityMapHeightManager.minValidVolumeValue then
                self:applyDensityMapChanges()

                if operation == TerraFarmLandscaping.OPERATION.RAISE then
                    machine:onVolumeDisplacement(0 - volume, isDischarging)
                elseif operation == TerraFarmLandscaping.OPERATION.LOWER then
                    machine:onVolumeDisplacement(volume, isDischarging)
                elseif operation == TerraFarmLandscaping.OPERATION.FLATTEN then
                    if isDischarging and not machine.type.hasLevelerFunctions then
                        machine:onVolumeDisplacement(-volume, isDischarging)
                    else
                        machine:onVolumeDisplacement(volume, isDischarging)
                    end
                elseif operation == TerraFarmLandscaping.OPERATION.SMOOTH then
                    if isDischarging and not machine.type.hasLevelerFunctions then
                        machine:onVolumeDisplacement(-volume, isDischarging)
                    else
                        machine:onVolumeDisplacement(volume, isDischarging)
                    end
                end

                if isDischarging then
                    machine.dischargeVolumeBuffer = 0
                else
                    machine.terraformVolumeBuffer = 0
                end
            end


        elseif operation == TerraFarmLandscaping.OPERATION.PAINT or operation == TerraFarmLandscaping.OPERATION.TERRAFORM_PAINT then
            self:applyDensityMapChanges()
        end
    end

    self.callbackFunction(self.callbackFunctionTarget, errorCode, displacedVolumeOrArea)

    self.currentTerrainDeformation:delete()
    self.currentTerrainDeformation = nil
end