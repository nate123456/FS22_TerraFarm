local modFolder = g_currentModDirectory
local ICON_SIZE = 36

TERRAFORM_MODE_IMAGE_FILE = {
    [TerraFarmMachine.MODE.NORMAL] = modFolder .. 'textures/hud_mode_normal.png',
    [TerraFarmMachine.MODE.RAISE] = modFolder .. 'textures/hud_mode_raise.png',
    [TerraFarmMachine.MODE.LOWER] = modFolder .. 'textures/hud_mode_lower.png',
    [TerraFarmMachine.MODE.SMOOTH] = modFolder .. 'textures/hud_mode_smooth.png',
    [TerraFarmMachine.MODE.FLATTEN] = modFolder .. 'textures/hud_mode_flatten.png',
    [TerraFarmMachine.MODE.PAINT] = modFolder .. 'textures/hud_mode_paint.png',
}

TERRAFORM_MODE_IMAGE_DISABLED_FILE = {
    [TerraFarmMachine.MODE.NORMAL] = modFolder .. 'textures/hud_mode_normal_disabled.png',
    [TerraFarmMachine.MODE.RAISE] = modFolder .. 'textures/hud_mode_raise_disabled.png',
    [TerraFarmMachine.MODE.LOWER] = modFolder .. 'textures/hud_mode_lower_disabled.png',
    [TerraFarmMachine.MODE.SMOOTH] = modFolder .. 'textures/hud_mode_smooth_disabled.png',
    [TerraFarmMachine.MODE.FLATTEN] = modFolder .. 'textures/hud_mode_flatten_disabled.png',
    [TerraFarmMachine.MODE.PAINT] = modFolder .. 'textures/hud_mode_paint_disabled.png',
}

TERRAFORM_STATE_DISABLED_IMAGE_FILE = modFolder .. 'textures/hud_mode_blank.png'

---@class MachineHUD
---@field uiScale number
---@field uiTextColor any
---@field uiTextSize number
---@field disabledIcon table
---@field modeIcon table
---@field disabledModeIcon table
---@field terraformModeOverlay Overlay
---@field dischargeModeOverlay Overlay
---@field backgroundOverlay Overlay
---@field iconWidth number
MachineHUD = {}
local MachineHUD_mt = Class(MachineHUD)

---@return MachineHUD
function MachineHUD.new()
    ---@type MachineHUD
    local self = setmetatable({}, MachineHUD_mt)

    self.uiScale = g_gameSettings:getValue("uiScale")
    self.uiTextColor = GameInfoDisplay.COLOR.TEXT
    self.uiTextSize = getCorrectTextSize(0.014)

    self.modeIcon = {}
    for mode, path in pairs(TERRAFORM_MODE_IMAGE_FILE) do
        local overlay = {
            filename = path,
            overlayId = createImageOverlay(path)
        }
        self.modeIcon[mode] = overlay
    end

    self.disabledModeIcon = {}
    for mode, path in pairs(TERRAFORM_MODE_IMAGE_DISABLED_FILE) do
        local overlay = {
            filename = path,
            overlayId = createImageOverlay(path)
        }
        self.disabledModeIcon[mode] = overlay
    end

    self.disabledIcon = {
        filename = TERRAFORM_STATE_DISABLED_IMAGE_FILE,
        overlayId = createImageOverlay(TERRAFORM_STATE_DISABLED_IMAGE_FILE)
    }

    self:createBackgroundOverlay()
    self:createTerraformModeOverlay()
    self:createDischargeModeOverlay()

    self.iconWidth = getNormalizedScreenValues(ICON_SIZE, 0)
    self.padding = getNormalizedScreenValues(8, 0)

    return self
end

function MachineHUD:getModeText(mode)
    local name = TerraFarmMachine.MODE_TO_NAME[mode]
    if not name then
        name = 'INVALID'
    end
    return g_i18n:getText('MACHINE_MODE_' .. name)
end

function MachineHUD:createBackgroundOverlay()
    local posX, posY = GameInfoDisplay.getBackgroundPosition(1)
    local width, height = getNormalizedScreenValues(unpack(GameInfoDisplay.SIZE.SELF))
    height = height * 0.75
	width = width + g_safeFrameOffsetX
	local overlay = Overlay.new(g_baseUIFilename, posX - width, posY - height, width, height)

    overlay:setUVs(g_colorBgUVs)
	overlay:setColor(0, 0, 0, 0.75)

    self.backgroundOverlay = overlay
end

function MachineHUD:createTerraformModeOverlay()
    local width, height = getNormalizedScreenValues(ICON_SIZE * self.uiScale, ICON_SIZE * self.uiScale)
    self.terraformModeOverlay = Overlay.new(g_baseUIFilename, 0, 0, width, height)
end

function MachineHUD:createDischargeModeOverlay()
    local width, height = getNormalizedScreenValues(ICON_SIZE * self.uiScale, ICON_SIZE * self.uiScale)
    self.dischargeModeOverlay = Overlay.new(g_baseUIFilename, 0, 0, width, height)
end

function MachineHUD:setOverlayIcon(overlay, mode, enabled)
    if not mode or not TerraFarmMachine.MODE_TO_NAME[mode] then
        overlay.filename = self.disabledIcon.filename
        overlay.overlayId = self.disabledIcon.overlayId
    else
        local icon
        if enabled then
            icon = self.modeIcon[mode]
        else
            icon = self.disabledModeIcon[mode]
        end
        if icon and overlay.filename ~= icon.filename then
            overlay.filename = icon.filename
            overlay.overlayId = icon.overlayId
        end
    end
end

function MachineHUD:draw()
    local machine = g_machineManager:getCurrentMachine()
    if not machine then return end

    setTextAlignment(RenderText.ALIGN_RIGHT)

    local totalWidth = 0

    ---@type GameInfoDisplay
    local g_hud = g_currentMission.hud.gameInfoDisplay

    local hud_x, hud_y = g_hud:getPosition()

    local terraformWidth, terraformText = self:getTerraformModeWidth(machine)
    local dischargeWidth, dischargeText = self:getDischargeModeWidth(machine)

    totalWidth = terraformWidth + dischargeWidth

    --local posX, posY = GameInfoDisplay.getBackgroundPosition(self.uiScale)

    local posY = hud_y - g_hud:getHeight() * 0.75 - self.padding
    local height = g_hud:getHeight() * 0.75
    local centerPosY = posY + height / 2 - self.uiTextSize / 2 + self.padding / 2

    self:drawBackground(g_hud:getWidth(), height, 1 - g_hud:getWidth(), posY)

    if terraformWidth > 0 then
        -- self:drawTerraformMode(terraformText, terraformWidth, 0.98, posY)
        self:drawTerraformMode(terraformText, terraformWidth, 0.98 - dischargeWidth - self.padding * 4, posY, centerPosY, machine)
    end
    if dischargeWidth > 0 then
        -- self:drawDischargeMode(dischargeText, dischargeWidth, 0.98 - terraformWidth - self.padding * 4, posY)
        self:drawDischargeMode(dischargeText, dischargeWidth, 0.98, posY, centerPosY, machine)
    end

    -- if machine.type.hasTerraformMode then
    --     totalWidth = totalWidth + self:drawTerraformMode(machine, 0.98, 0.5)
    -- end
    -- if machine.type.hasDischargeMode then
    --     totalWidth = totalWidth + self:drawDischargeMode(machine, 0.09, 0.4)
    -- end

    setTextAlignment(RenderText.ALIGN_LEFT)

    -- renderText(hud_x, posY, self.uiTextSize, 'Terraform strength: ' .. tostring(machine:getTerraformStrength()))
    -- renderText(hud_x, posY - self.uiTextSize, self.uiTextSize, 'Flatten strength: ' .. tostring(machine:getFlattenStrength()))
    -- renderText(hud_x, posY, self.uiTextSize, 'flatten radius: ' .. tostring(machine:getFlattenRadius()))
    -- renderText(hud_x, posY - self.uiTextSize, self.uiTextSize, 'terraform radius: ' .. tostring(machine:getTerraformRadius()))

    setTextWrapWidth(self.backgroundOverlay.width - terraformWidth - dischargeWidth - self.padding * 8)

    if g_terraFarm and machine.enabled then
        -- setTextColor(0, 0.776, 0.992, 1)
        setTextColor(0, 0.729, 1, 1)
    else
        setTextColor(0.8, 0.8, 0.8, 0.5)
    end

    renderText(hud_x + self.padding * 4, centerPosY, self.uiTextSize, machine:getDescription())

    setTextWrapWidth(0)
    setTextColor(unpack(GameInfoDisplay.COLOR.TEXT))
end

function MachineHUD:drawBackground(width, height, posX, posY)
    self.backgroundOverlay:setPosition(posX, posY)
    self.backgroundOverlay:setDimension(width, height)
    self.backgroundOverlay:render()
end


---@param machine TerraFarmMachine
function MachineHUD:getTerraformModeWidth(machine)
    if not machine.type.hasTerraformMode then return 0, '' end

    local modeText = self:getModeText(machine.terraformMode)
    local titleText = g_i18n:getText('MODE_TERRAFORM')
    self:setOverlayIcon(self.terraformModeOverlay, machine.terraformMode, g_terraFarm.enabled and machine.enabled)

    return math.max(getTextWidth(self.uiTextSize, modeText), getTextWidth(self.uiTextSize, titleText)) + self.terraformModeOverlay.width, modeText
end

---@param machine TerraFarmMachine
function MachineHUD:getDischargeModeWidth(machine)
    if not machine.type.hasDischargeMode then return 0, '' end

    local modeText = self:getModeText(machine.dischargeMode)
    local titleText = g_i18n:getText('MODE_DISCHARGE')
    self:setOverlayIcon(self.dischargeModeOverlay, machine.dischargeMode, g_terraFarm.enabled and machine.enabled)

    return math.max(getTextWidth(self.uiTextSize, modeText), getTextWidth(self.uiTextSize, titleText)) + self.dischargeModeOverlay.width, modeText
end

---@param machine TerraFarmMachine
function MachineHUD:drawTerraformMode(modeText, textWidth, rightPosX, posY, centerPosY, machine)
    local titleText = g_i18n:getText('MODE_TERRAFORM')
    setTextBold(true)
    renderText(rightPosX - self.padding, posY + self.uiTextSize * 2, self.uiTextSize, titleText)

    setTextBold(false)
    renderText(rightPosX - self.padding, posY + self.uiTextSize * 1, self.uiTextSize, modeText)

    local iconPosY = posY + (self.backgroundOverlay.height / 2) - self.terraformModeOverlay.height / 2
    -- local iconPosY = centerPosY - self.terraformModeOverlay.height / 2

    self.terraformModeOverlay:setPosition(rightPosX, iconPosY)
    self.terraformModeOverlay:render()
end

---@param machine TerraFarmMachine
function MachineHUD:drawDischargeMode(modeText, textWidth, rightPosX, posY, centerPosY, machine)
    local titleText = g_i18n:getText('MODE_DISCHARGE')

    setTextBold(true)
    renderText(rightPosX - self.padding, centerPosY + self.uiTextSize / 2 + self.padding / 4, self.uiTextSize, titleText)

    setTextBold(false)
    renderText(rightPosX - self.padding, centerPosY - self.uiTextSize / 2 - self.padding / 4, self.uiTextSize, modeText)

    local iconPosY = posY + (self.backgroundOverlay.height / 2) - self.dischargeModeOverlay.height / 2
    -- local iconPosY = centerPosY - self.dischargeModeOverlay.height / 2

    self.dischargeModeOverlay:setPosition(rightPosX, iconPosY)
    self.dischargeModeOverlay:render()
end

---@diagnostic disable-next-line: lowercase-global
g_machineHUD = MachineHUD.new()