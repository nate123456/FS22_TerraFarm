
---@class TerraFarmSettingsMachineFrame : TabbedMenuFrameElement
---@field boxLayout BoxLayoutElement
---@field headerText TextElement
---@field descriptionText TextElement
---@field terraformStrength MultiTextOptionElement
---@field terraformRadius MultiTextOptionElement
---@field dischargeStrength MultiTextOptionElement
---@field dischargeRadius MultiTextOptionElement
---@field flattenStrength MultiTextOptionElement
---@field flattenRadius MultiTextOptionElement
---@field smoothStrength MultiTextOptionElement
---@field smoothRadius MultiTextOptionElement
---@field terraformPaintLayer MultiTextOptionElement
---@field dischargePaintLayer MultiTextOptionElement
---@field paintRadius MultiTextOptionElement
---@field disableDischarge CheckedOptionElement
---@field disablePaint CheckedOptionElement
---@field fillType MultiTextOptionElement
---@field clearDensityMap CheckedOptionElement
---@field enabled CheckedOptionElement
---@field disableClearDeco CheckedOptionElement
---@field disableClearWeed CheckedOptionElement
---@field disableRemoveField CheckedOptionElement
---@field useFillTypeMassPerLiter CheckedOptionElement
TerraFarmSettingsMachineFrame = {}
local TerraFarmSettingsMachineFrame_mt = Class(TerraFarmSettingsMachineFrame, TabbedMenuFrameElement)

TerraFarmSettingsMachineFrame.CONTROLS = {
    'boxLayout',
    'headerText',
    -- 'descriptionText',

    'enabled',
    'terraformStrength',
    'terraformRadius',
    'dischargeStrength',
    'dischargeRadius',
    'flattenStrength',
    'flattenRadius',
    'smoothStrength',
    'smoothRadius',

    'terraformPaintLayer',
    'dischargePaintLayer',
    'disableDischarge',
    'disablePaint',
    'fillType',
    'paintRadius',
    'useFillTypeMassPerLiter',

    'clearDensityMap',
    'disableClearDeco',
    'disableClearWeed',
    'disableRemoveField',
}

function TerraFarmSettingsMachineFrame.new(target, mt)
    local self = TabbedMenuFrameElement.new(target, mt or TerraFarmSettingsMachineFrame_mt)

    self:registerControls(TerraFarmSettingsMachineFrame.CONTROLS)

    return self
end

function TerraFarmSettingsMachineFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
    self:updateLocaleText()
end

function TerraFarmSettingsMachineFrame:updateLocaleText()
    local allChildren = self:getDescendants()
    for _, element in pairs(allChildren) do
            if element:isa(TextElement) then
                if string.sub(element:getText(), 1, 5) == 'I18N_' then
                    local key = string.sub(element:getText(), 6)
                    element:setText(g_i18n:getText(key) or '')
                end
            end
    end
end

function TerraFarmSettingsMachineFrame:onFrameOpen()
    ---@diagnostic disable-next-line: undefined-field
    TerraFarmSettingsMachineFrame:superClass().onFrameOpen(self)
    self:updateSettings()

    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function TerraFarmSettingsMachineFrame:updateSettings()
    local machine = g_machineManager:getCurrentMachine()
    local isVisible = not not machine

    if not isVisible then
        for _, control in pairs(TerraFarmSettingsMachineFrame.CONTROLS) do
            local element = self[control]
            if element and (element:isa(CheckedOptionElement) or element:isa(MultiTextOptionElement)) then
                element:setVisible(false)
            end
        end
        self.headerText:setText(g_i18n:getText('GUI_TITLE_NO_MACHINE'))
        -- self.headerText:setText('No machine')
        -- self.descriptionText:setText('')
        return
    end

    -- self.headerText:setText('Machine')
    self.headerText:setText(machine:getDescription() .. ' (ID# ' .. tostring(machine:getId()) .. ')')
    -- self.descriptionText:setText(machine:getDescription())

    self.enabled:setVisible(true)
    self.enabled:setIsChecked(machine.enabled)

    if machine.type.hasDischargeMode then
        self.disableDischarge:setVisible(true)
        self.disableDischarge:setIsChecked(machine.disableDischarge)

        self.dischargePaintLayer:setVisible(true)
        self.dischargePaintLayer:setState(TerraFarmGroundTypes:getStateIndex(machine.dischargePaintLayerId))

        self.dischargeStrength:setVisible(true)
        self.dischargeStrength:setState(machine.dischargeStrengthPct)

        self.dischargeRadius:setVisible(true)
        self.dischargeRadius:setState(machine.dischargeRadiusPct)
    else
        self.disableDischarge:setVisible(false)
        self.dischargePaintLayer:setVisible(false)
        self.dischargeStrength:setVisible(false)
        self.dischargeRadius:setVisible(false)
    end

    if machine.type.hasTerraformMode then
        self.terraformStrength:setVisible(true)
        self.terraformStrength:setState(machine.terraformStrengthPct)
        self.terraformRadius:setVisible(true)
        self.terraformRadius:setState(machine.terraformRadiusPct)
        self.terraformPaintLayer:setVisible(true)
        self.terraformPaintLayer:setState(TerraFarmGroundTypes:getStateIndex(machine.terraformPaintLayerId))
    else
        self.terraformPaintLayer:setVisible(false)
        self.terraformStrength:setVisible(false)
        self.terraformRadius:setVisible(false)
    end

    if machine.type.hasFillUnit then
        self.fillType:setVisible(true)
        self.fillType:setState(TerraFarmFillTypes:getStateIndex(machine.fillTypeIndex))
    else
        self.fillType:setVisible(false)
    end

    if machine:hasMode(TerraFarmMachine.MODE.FLATTEN) then
        self.flattenStrength:setVisible(true)
        self.flattenStrength:setState(machine.flattenStrengthPct)
        self.flattenRadius:setVisible(true)
        self.flattenRadius:setState(machine.flattenRadiusPct)
    else
        self.flattenStrength:setVisible(false)
        self.flattenRadius:setVisible(false)
    end

    if machine:hasMode(TerraFarmMachine.MODE.SMOOTH) then
        self.smoothStrength:setVisible(true)
        self.smoothStrength:setState(machine.smoothStrengthPct)
        self.smoothRadius:setVisible(true)
        self.smoothRadius:setState(machine.smoothRadiusPct)
    else
        self.smoothStrength:setVisible(false)
        self.smoothRadius:setVisible(false)
    end

    self.clearDensityMap:setVisible(true)
    self.clearDensityMap:setIsChecked(machine.clearDensityMap)

    self.disableClearDeco:setVisible(true)
    self.disableClearDeco:setIsChecked(machine.disableClearDeco)

    self.disableClearWeed:setVisible(true)
    self.disableClearWeed:setIsChecked(machine.disableClearWeed)

    self.disableRemoveField:setVisible(true)
    self.disableRemoveField:setIsChecked(machine.disableRemoveField)

    self.disablePaint:setVisible(true)
    self.disablePaint:setIsChecked(machine.disablePaint)

    self.paintRadius:setVisible(true)
    self.paintRadius:setState(machine.paintRadiusPct)

    self.useFillTypeMassPerLiter:setVisible(true)
    self.useFillTypeMassPerLiter:setIsChecked(machine.useFillTypeMassPerLiter)
end

-- Enable machine

function TerraFarmSettingsMachineFrame:onEnableClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setIsEnabled(state == CheckedOptionElement.STATE_CHECKED)
    end
end

-- Disable discharge

function TerraFarmSettingsMachineFrame:onDisableDischargeClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setDisableDischarge(state == CheckedOptionElement.STATE_CHECKED)
    end
end

-- Disable paint

function TerraFarmSettingsMachineFrame:onDisablePaintClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setDisablePaint(state == CheckedOptionElement.STATE_CHECKED)
    end
end

-- Clear density map

function TerraFarmSettingsMachineFrame:onClearDensityMapClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setClearDensityMap(state == CheckedOptionElement.STATE_CHECKED)
    end
end

-- Disable clear deco

function TerraFarmSettingsMachineFrame:onDisableClearDecoClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setDisableClearDeco(state == CheckedOptionElement.STATE_CHECKED)
    end
end

-- Disable clear weed

function TerraFarmSettingsMachineFrame:onDisableClearWeedClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setDisableClearWeed(state == CheckedOptionElement.STATE_CHECKED)
    end
end

-- Disable remove field area

function TerraFarmSettingsMachineFrame:onDisableRemoveFieldClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setDisableRemoveField(state == CheckedOptionElement.STATE_CHECKED)
    end
end

-- Use mass per liter from fillType

function TerraFarmSettingsMachineFrame:onUseFillTypeMassPerLiterClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setUseFillTypeMassPerLiter(state == CheckedOptionElement.STATE_CHECKED)
    end
end

-- Fill type

function TerraFarmSettingsMachineFrame:onCreateFillType(element)
    element:setTexts(TerraFarmFillTypes:getFillTypeTexts())
end

function TerraFarmSettingsMachineFrame:onFillTypeClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setFillTypeIndex(TerraFarmFillTypes:getFillTypeIndexByStateIndex(state))
    end
end

-- Terraform paint layer

function TerraFarmSettingsMachineFrame:onCreateTerraformPaintLayer(element)
    element:setTexts(TerraFarmGroundTypes:getGroundTypeTexts())
end

function TerraFarmSettingsMachineFrame:onTerraformPaintLayerClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setTerraformPaintLayerId(TerraFarmGroundTypes:getLayerIdByStateIndex(state))
    end
end

-- Discharge paint layer

function TerraFarmSettingsMachineFrame:onCreateDischargePaintLayer(element)
    element:setTexts(TerraFarmGroundTypes:getGroundTypeTexts())
end

function TerraFarmSettingsMachineFrame:onDischargePaintLayerClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setDischargePaintLayerId(TerraFarmGroundTypes:getLayerIdByStateIndex(state))
    end
end



-- Terraform strength

function TerraFarmSettingsMachineFrame:onCreateTerraformStrength(element)
    element:setTexts(TerraFarmMachine.STRENGTH_MODIFIER_TEXTS)
end

function TerraFarmSettingsMachineFrame:onTerraformStrengthClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setTerraformStrength(state)
    end
end

-- Terraform radius

function TerraFarmSettingsMachineFrame:onCreateTerraformRadius(element)
    element:setTexts(TerraFarmMachine.RADIUS_MODIFIER_TEXTS)
end

function TerraFarmSettingsMachineFrame:onTerraformRadiusClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setTerraformRadius(state)
    end
end

-- Discharge strength

function TerraFarmSettingsMachineFrame:onCreateDischargeStrength(element)
    element:setTexts(TerraFarmMachine.STRENGTH_MODIFIER_TEXTS)
end

function TerraFarmSettingsMachineFrame:onDischargeStrengthClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setDischargeStrength(state)
    end
end

-- Discharge radius

function TerraFarmSettingsMachineFrame:onCreateDischargeRadius(element)
    element:setTexts(TerraFarmMachine.RADIUS_MODIFIER_TEXTS)
end

function TerraFarmSettingsMachineFrame:onDischargeRadiusClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setDischargeRadius(state)
    end
end

-- Flatten strength

function TerraFarmSettingsMachineFrame:onCreateFlattenStrength(element)
    element:setTexts(TerraFarmMachine.STRENGTH_MODIFIER_TEXTS)
end

function TerraFarmSettingsMachineFrame:onFlattenStrengthClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setFlattenStrength(state)
    end
end

-- Flatten radius

function TerraFarmSettingsMachineFrame:onCreateFlattenRadius(element)
    element:setTexts(TerraFarmMachine.RADIUS_MODIFIER_TEXTS)
end

function TerraFarmSettingsMachineFrame:onFlattenRadiusClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setFlattenRadius(state)
    end
end

-- Smooth strength

function TerraFarmSettingsMachineFrame:onCreateSmoothStrength(element)
    element:setTexts(TerraFarmMachine.STRENGTH_MODIFIER_TEXTS)
end

function TerraFarmSettingsMachineFrame:onSmoothStrengthClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setSmoothStrength(state)
    end
end

-- Smooth radius

function TerraFarmSettingsMachineFrame:onCreateSmoothRadius(element)
    element:setTexts(TerraFarmMachine.RADIUS_MODIFIER_TEXTS)
end

function TerraFarmSettingsMachineFrame:onSmoothRadiusClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setSmoothRadius(state)
    end
end

-- Paint radius

function TerraFarmSettingsMachineFrame:onCreatePaintRadius(element)
    element:setTexts(TerraFarmMachine.RADIUS_MODIFIER_TEXTS)
end

function TerraFarmSettingsMachineFrame:onPaintRadiusClick(state)
    local machine = g_machineManager:getCurrentMachine()
    if machine then
        machine:setPaintRadius(state)
    end
end