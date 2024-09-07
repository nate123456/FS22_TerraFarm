---@class TerraFarmLandscaping
---@field terrainDeformationQueue TerrainDeformationQueue
---@field terrainRootNode number
---@field terrainUnit number
---@field halfTerrainUnit number
---@field modifiedAreas table
---@field currentTerrainDeformation TerrainDeformation
---@field callbackFunction function
---@field callbackFunctionTarget TerraFarmLandscapingEvent
---@field preTerraformHeights table
---@field action string
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
    self.preTerraformHeights = {}
    self.callbackFunction = callbackFunction
    self.callbackFunctionTarget = callbackFunctionTarget
    self.action = nil

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
    local machine = self.callbackFunctionTarget.machine
    local isDischarging = self.callbackFunctionTarget.isDischarging

    if isDischarging then
        self.action = 'raise'
        deform:enableAdditiveDeformationMode()
        deform:setAdditiveHeightChangeAmount(0.0025)
    else
        if machine.heightLockEnabled then
            self.action = 'flatten'
            local y = machine.heightLockHeight
            deform:setHeightTarget(y, y, 0, 1, 0, -y)
            deform:setAdditiveHeightChangeAmount(0.75)
            deform:enableSetDeformationMode()
        else
            self.action = 'lower'
            deform:enableAdditiveDeformationMode()
            deform:setAdditiveHeightChangeAmount(-0.0025)
        end
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

        self.terrainDeformationQueue:queueJob(deform, true, 'onSculptingValidated', self)
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

        self.terrainDeformationQueue:queueJob(deform, true, 'onSculptingValidated', self)
    end
end

function TerraFarmLandscaping:onSculptingValidated(errorCode, displacedVolumeOrArea, blocked)
    local machine = self.callbackFunctionTarget.machine
    local maxHeight = machine.heightLockHeight

    if errorCode ~= TerrainDeformation.STATE_SUCCESS then
        Logging.warning('Validation failed, terraform did not succeed')
        self:abortSculpting()
        return
    end

    if #self.modifiedAreas == 0 then
        Logging.warning('Validation failed, terraform did not have any modified areas')
        self:abortSculpting()
        return
    end

    if displacedVolumeOrArea == 0 then
        Logging.warning('Validation failed, terraform did not displace any volume or area')
        self:abortSculpting()
        return
    end

    for i, area in ipairs(self.modifiedAreas) do
        local x1, z1, x2, z2, x3, z3 = unpack(area)
        local height1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1)
        local height2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2)
        local height3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, 0, z3)

        self.preTerraformHeights[i] = {height1, height2, height3 }
    end

    local fillAmount = self:volumeToFillDelta(displacedVolumeOrArea)
    local fillLevel = machine:getFillLevel()
    local fillCapacity = machine:getFillCapacity()

    if self.action == 'raise' then
        if fillAmount > fillLevel then
            Logging.warning('Validation failed, terraform raised more volume than available in the bucket')
            self:abortSculpting()
            return
        end
    elseif self.action == 'lower' then
        if fillAmount > fillCapacity then
            Logging.warning('Validation failed, terraform lowered more volume than available in the bucket')
            self:abortSculpting()
            return
        end
    elseif self.action == 'flatten' then
        local overs = 0
        local unders = 0
        for _, heights in ipairs(self.preTerraformHeights) do
            for _, height in ipairs(heights) do
                if height > maxHeight then
                    overs = overs + 1
                elseif height < maxHeight then
                    unders = unders + 1
                end
            end
        end

        if overs ~= 0 or unders ~= 0 then
            local totalVertices = overs + unders
            local raiseVolumeCost = (unders / totalVertices * fillAmount) * -1
            local lowerVolumeCost = overs / totalVertices * fillAmount
            local fillDelta = raiseVolumeCost + lowerVolumeCost

            local newFillLevel = fillLevel + fillDelta
            Logging.info('Flatten Fill: ' .. fillAmount .. ', Overs: ' .. overs .. ', Unders: ' .. unders .. ', Raise: ' .. raiseVolumeCost .. ', Lower: ' .. lowerVolumeCost .. ', Delta: ' .. fillDelta .. ', New Fill: ' .. newFillLevel)

            if newFillLevel < 0 then
                Logging.info('Validation failed, not enough material in the bucket')
                self:abortSculpting()
                return
            elseif newFillLevel > fillCapacity then
                Logging.info('Validation failed, not enough room in the bucket')
                self:abortSculpting()
                return
            end
        else
            Logging.warning('Validation failed, terraform did not have any vertices to flatten')
            self:abortSculpting()
            return
        end
    end

    self.terrainDeformationQueue:queueJob(self.currentTerrainDeformation, false, "onSculptingApplied", self)
end

function TerraFarmLandscaping:abortSculpting()
    self.currentTerrainDeformation:cancel()
    self.currentTerrainDeformation:delete()
    self.currentTerrainDeformation = nil
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
            if displacedVolumeOrArea > g_densityMapHeightManager.minValidVolumeValue and #self.modifiedAreas > 0 then
                if #self.modifiedAreas ~= #self.preTerraformHeights then
                    Logging.warning('Modified areas and pre terraform heights do not match by length: ' .. #self.modifiedAreas .. ' vs ' .. #self.preTerraformHeights)
                    DebugUtil.printTableRecursively(self.modifiedAreas, "modifiedAreas")
                    DebugUtil.printTableRecursively(self.preTerraformHeights, "preTerraformHeights")
                    DebugUtil.printTableRecursively(self.currentTerrainDeformation, "currentTerrainDeformation")
                    print('volume: ' .. displacedVolumeOrArea)
                    print('errorCode: ' .. errorCode)
                else
                    local raisedVerticeCount = 0
                    local loweredVerticeCount = 0
        
                    for i, area in ipairs(self.modifiedAreas) do
                        local x1, z1, x2, z2, x3, z3 = unpack(area)
                        local preHeight1, preHeight2, preHeight3 = unpack(self.preTerraformHeights[i])
                        
                        local postHeight1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1)
                        local postHeight2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2)
                        local postHeight3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, 0, z3)
            
                        local heightChange1 = postHeight1 - preHeight1
                        local heightChange2 = postHeight2 - preHeight2
                        local heightChange3 = postHeight3 - preHeight3
        
                        if heightChange1 > 0 then
                            raisedVerticeCount = raisedVerticeCount + 1
                        elseif heightChange1 < 0 then
                            loweredVerticeCount = loweredVerticeCount + 1
                        end
                        if heightChange2 > 0 then
                            raisedVerticeCount = raisedVerticeCount + 1
                        elseif heightChange2 < 0 then
                            loweredVerticeCount = loweredVerticeCount + 1
                        end
                        if heightChange3 > 0 then
                            raisedVerticeCount = raisedVerticeCount + 1
                        elseif heightChange3 < 0 then
                            loweredVerticeCount = loweredVerticeCount + 1
                        end
                    end
        
                    -- there is sometimes volume reported when with no vertices raised or lowered.
                    if raisedVerticeCount ~= 0 or loweredVerticeCount ~= 0 then
                        local totalVertices = raisedVerticeCount + loweredVerticeCount
                        local raiseVolume = (raisedVerticeCount / totalVertices * displacedVolumeOrArea) * -1
                        local lowerVolume = loweredVerticeCount / totalVertices * displacedVolumeOrArea
                        local volumeDelta = raiseVolume + lowerVolume
        
                        Logging.info(self.action .. ' Raw: ' .. displacedVolumeOrArea .. ', Raises: ' .. raisedVerticeCount .. ', Lowers: ' .. loweredVerticeCount .. ', Total: ' .. totalVertices .. ', Ratioed: ' .. volumeDelta)
        
                        local machine = self.callbackFunctionTarget.machine
        
                        -- makes bucket fill amount more effective the lower the cost of the material.
                        local finalVolumeDelta = volumeDelta * .75
        
                        if self.action == 'raise' then
                        elseif self.action == 'lower' then
                        elseif self.action == 'flatten' then
                            -- flattenening a full bucket of material after it was dumped to raise the land
                            -- only returns about half the material.
                            finalVolumeDelta = finalVolumeDelta * 2
                        end

                        local fillDelta = self:volumeToFillDelta(finalVolumeDelta)
                        
                        machine:onVolumeDisplacement(fillDelta)
                        self:applyDensityMapChanges()
                    end
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

function TerraFarmLandscaping:volumeToFillDelta(volume)
    local amount = 0
    -- local ratio = g_densityMapHeightManager.minValidLiterValue / g_densityMapHeightManager.minValidVolumeValue
    -- return volume * ratio * self:getVolumeFillRatio()

    -- return volume / (g_densityMapHeightManager.fillToGroundScale * g_densityMapHeightManager.minValidLiterValue)
    -- return volume / g_densityMapHeightManager.fillToGroundScale
    amount = (volume / (g_densityMapHeightManager.volumePerPixel / g_densityMapHeightManager.literPerPixel)) * g_densityMapHeightManager.worldToDensityMap
    -- amount = amount * .3333
    --print(string.format('Volume to Amount: %.2f -> %.2f', volume, amount))
    return amount
end