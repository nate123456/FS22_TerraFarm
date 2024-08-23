---@class MachineDebug
MachineDebug = {}

MachineDebug.COLORS = {
    terraformNode = {1, 0, 0, 1},
    terraformNodeActive = {0, 1, 0, 1},
    transformNodeDisabled = {0.3, 0.3, 0.3, 1},
    transformNodeDisabledActive = {0.9, 0.3, 0.3, 1},
    collisionNode = {0, 0, 1, 1},
    collisionNodeActive = {0, 0.8, 0.9, 1},
    collisionNodeDisabled = {0.3, 0.3, 0.3, 1},
    collisionNodeDisabledActive = {0.3, 0.3, 0.9, 1}
}

function MachineDebug.draw()
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        MachineDebug.drawMachineTerraformNodes(machine)
        MachineDebug.drawMachineCollisionNodes(machine)
        MachineDebug.drawMachineDischargeLines(machine)
    end
end

---@param machine TerraFarmMachine
function MachineDebug.drawMachineTerraformNodes(machine)
    local isEnabled = machine.enabled

    for _, node in pairs(machine.terraformNodes) do
        local position = machine.nodePosition[node]
        if position then
            local color = MachineDebug.COLORS.terraformNode

            if machine.nodeIsTouchingTerrain[node] then
                if isEnabled then
                    color = MachineDebug.COLORS.terraformNodeActive
                else
                    color = MachineDebug.COLORS.transformNodeDisabledActive
                end
            elseif not isEnabled then
                color = MachineDebug.COLORS.transformNodeDisabled
            end

            DebugUtil.drawDebugCircleAtNode(node, 0.05, 2, color)
            DebugUtil.drawDebugCircleAtNode(node, 0.05, 2, color, true)

            Utils.renderTextAtWorldPosition(
                position.x, position.y, position.z,
                'o', getCorrectTextSize(0.01), 0, color
            )
        end
    end
end

---@param machine TerraFarmMachine
function MachineDebug.drawMachineCollisionNodes(machine)
    local isEnabled = machine.enabled

    for _, node in pairs(machine.collisionNodes) do
        local position = machine.nodePosition[node]

        if position then
            local color = MachineDebug.COLORS.collisionNode
            if machine.nodeIsTouchingTerrain[node] then
                if isEnabled then
                    color = MachineDebug.COLORS.collisionNodeActive
                else
                    color = MachineDebug.COLORS.collisionNodeDisabledActive
                end
            elseif not isEnabled then
                color = MachineDebug.COLORS.collisionNodeDisabled
            end

            DebugUtil.drawDebugCircleAtNode(node, 0.05, 2, color)
            DebugUtil.drawDebugCircleAtNode(node, 0.05, 2, color, true)

            Utils.renderTextAtWorldPosition(
                position.x, position.y, position.z,
                'o', getCorrectTextSize(0.01), 0, color
            )
        end
    end
end

---@param machine TerraFarmMachine
function MachineDebug.drawMachineDischargeLines(machine)
    local color = {1, 1, 0, 1}
    for _, line in pairs(machine.dischargeLines) do
        local startPosition = machine.nodePosition[line.startNode]
        local endPosition = machine.nodePosition[line.endNode]

        if startPosition and endPosition then
            DebugUtil.drawDebugCircleAtNode(line.startNode, 0.05, 2, color)
            DebugUtil.drawDebugCircleAtNode(line.endNode, 0.05, 2, color)

            DebugUtil.drawDebugLine(
                startPosition.x, startPosition.y, startPosition.z,
                endPosition.x, endPosition.y, endPosition.z, 1, 1, 0, 0.1, true
            )
        end
    end
end