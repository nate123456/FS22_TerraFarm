---@class TerraFarmSettingsGlobalFrame : TabbedMenuFrameElement
---@field boxLayout BoxLayoutElement
---@field enabled CheckedOptionElement
---@field enableDebug CheckedOptionElement
TerraFarmSettingsGlobalFrame = {}
local TerraFarmSettingsGlobalFrame_mt = Class(TerraFarmSettingsGlobalFrame, TabbedMenuFrameElement)

TerraFarmSettingsGlobalFrame.CONTROLS = {
    'boxLayout',
    'enabled',
    'enableDebug'
}

function TerraFarmSettingsGlobalFrame.new(target, mt)
    ---@type TerraFarmSettingsGlobalFrame
    local self = TabbedMenuFrameElement.new(target, mt or TerraFarmSettingsGlobalFrame_mt)

    self:registerControls(TerraFarmSettingsGlobalFrame.CONTROLS)

    return self
end

function TerraFarmSettingsGlobalFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
    self:updateLocaleText()
end

function TerraFarmSettingsGlobalFrame:updateLocaleText()
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

function TerraFarmSettingsGlobalFrame:onFrameOpen()
    ---@diagnostic disable-next-line: undefined-field
    TerraFarmSettingsGlobalFrame:superClass().onFrameOpen(self)
    self:updateSettings()

    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function TerraFarmSettingsGlobalFrame:updateSettings()
    self.enabled:setIsChecked(g_terraFarm:getIsEnabled())
    self.enableDebug:setIsChecked(g_terraFarm.debug)
end

function TerraFarmSettingsGlobalFrame:onEnableCheckClick(state)
    g_terraFarm:setIsEnabled(state == CheckedOptionElement.STATE_CHECKED)
end

function TerraFarmSettingsGlobalFrame:onDebugCheckClick(state)
    g_terraFarm.debug = state == CheckedOptionElement.STATE_CHECKED
end
