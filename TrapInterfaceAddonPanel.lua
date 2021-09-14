
local function debugPrint(...)
    print(...);
end

TrapInterfaceAddonPanel = CreateFrame("Frame","TrapMainPanel")
TrapInterfaceAddonPanel.name = "Trap Raid Roller"

function TrapInterfaceAddonPanel:OnLoad()
    self:RegisterEvent("ADDON_LOADED")
    self:addPanel(TrapInterfaceAddonPanel)
    self:setupOptions()
end

TrapInterfaceAddonPanel:SetScript("OnEvent", function(self,event,...)
    if event ~= "ADDON_LOADED" then
        return --Not right event
    end
    local addon = ...
    if addon ~= "TrapRaidRoller" then
        return --Not right
    end
    self:setupDefaults()
    self:setupInitialCheck(self.showHide.tradeList.button, TrapRaidRollerHidePickupFrame)
    self:setupInitialCheck(self.showHide.leadList.button, TrapRaidRollerHideRolloutFrame)
    UIDropDownMenu_SetText(self.colorMenu.dropdownMenu,TrapRaidRollerPanelColor)
end)


function TrapInterfaceAddonPanel:setupDefaults()
    if not TrapRaidRollerPanelColor then
        TrapRaidRollerPanelColor = TrapRaidRollerPanelColor or "Alternating Blue"
    end
end

function TrapInterfaceAddonPanel:addPanel(panel)
    InterfaceOptions_AddCategory(panel)
end

function TrapInterfaceAddonPanel:setupOptions()
    self:setupColorOptions()
    self:setupShowHideOptions()
end

function TrapInterfaceAddonPanel:setupColorOptions()
    self.colorMenu = {}
    self:createColorTextbox()
    self:createDropdown()
    UIDropDownMenu_SetText(self.colorMenu.dropdownMenu, TrapRaidRollerPanelColor)
end

function TrapInterfaceAddonPanel:createColorTextbox()
    self.colorMenu.textBox = CreateFrame("Frame",nil,self)
    self.colorMenu.textBox:SetPoint("TOPLEFT",self,"TOPLEFT",25,-20)
    self.colorMenu.textBox.text = self.colorMenu.textBox:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    self.colorMenu.textBox.text:SetPoint("LEFT",self.colorMenu.textBox,"LEFT")
    self.colorMenu.textBox.text:SetText("Panel Background Color")
    local textW = self.colorMenu.textBox.text:GetWidth()
    local textH = self.colorMenu.textBox.text:GetHeight()
    self.colorMenu.textBox:SetSize(textW,textH)
end

function TrapInterfaceAddonPanel:createDropdown()
    self.colorMenu.dropdownMenu = CreateFrame("Frame","ColorDropdown",self,"UIDropDownMenuTemplate")
    self.colorMenu.dropdownMenu:SetPoint("TOPLEFT",self.colorMenu.textBox,"BOTTOMLEFT",-18,0)
    --debugPrint(TrapRaidRollerPanelColor)
    UIDropDownMenu_SetWidth(self.colorMenu.dropdownMenu,200)
    UIDropDownMenu_Initialize(self.colorMenu.dropdownMenu,InitalizeDropdownList)
end

local function DropdownMenu_OnClick(self,arg1,arg2,checked)
    if arg1 == 1 then
        TrapRaidRollerDarkColor = {0.0588, 0.0549, 0.102, 0.85}
        TrapRaidRollerLightColor = {0.1388,0.1349,0.182,0.85}
        TrapRaidRollerPanelColor = "Alternating Blue"
        TrapRaidRoller:updateVisual()
        TrapLeadList:updateVisual()
        --UIDropDownMenu_SetSelectedID(TrapInterfaceAddonPanel.colorMenu.dropdownMenu,1,1)
        --UIDropDownMenu_SetText(TrapInterfaceAddonPanel.colorMenu.dropdownMenu,TrapRaidRollerPanelColor)
    elseif arg1 == 2 then
        TrapRaidRollerDarkColor = {0.0588, 0.102, 0.0549, 0.85}
        TrapRaidRollerLightColor = {0.1388,0.182,0.1349,0.85}
        TrapRaidRollerPanelColor = "Alternating Green"
        TrapRaidRoller:updateVisual()
        TrapLeadList:updateVisual()
        --UIDropDownMenu_SetSelectedID(TrapInterfaceAddonPanel.colorMenu.dropdownMenu,2)
        --UIDropDownMenu_SetText(TrapInterfaceAddonPanel.colorMenu.dropdownMenu,TrapRaidRollerPanelColor)
    end
    UIDropDownMenu_SetText(TrapInterfaceAddonPanel.colorMenu.dropdownMenu, TrapRaidRollerPanelColor)
end

function InitalizeDropdownList(frame,level,menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.func = DropdownMenu_OnClick
    info.text, info.arg1, info.checked = "Alternating Blue", 1, TrapRaidRollerPanelColor == "Alternating Blue"
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1, info.checked = "Alternating Green", 2, TrapRaidRollerPanelColor == "Alternating Green"
    UIDropDownMenu_AddButton(info)
end

function TrapInterfaceAddonPanel:setupShowHideOptions()
    self.showHide = {}
    self.showHide.tradeList = {}
    self.showHide.leadList = {}
    self:createTextAndButtons(self.showHide.tradeList,"Pop up Roll Out confirmation on Loot Pickup")
    self:createTextAndButtons(self.showHide.leadList, "Pop up Lead List as Leadership")
    
    self:positionTextButtonPair(self.showHide.tradeList,nil)
    self:positionTextButtonPair(self.showHide.leadList, self.showHide.tradeList)

    self:setupButtonScripts()
end

function TrapInterfaceAddonPanel:createTextAndButtons(list,text)
    list.textBox = CreateFrame("Frame",nil,self)
    list.button = CreateFrame("CheckButton",nil,self,"ChatConfigCheckButtonTemplate")
    list.button:SetSize(25,25)

    list.textBox.text = list.textBox:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    list.textBox.text:SetText(text)
    list.textBox.text:SetPoint("LEFT",list.textBox,"LEFT")
    local textW = list.textBox.text:GetWidth()
    local textH = list.textBox.text:GetHeight()
    list.textBox:SetSize(textW,textH)
end

function TrapInterfaceAddonPanel:positionTextButtonPair(list, lastPair)
    if not lastPair then
        list.textBox:SetPoint("TOPLEFT",self,"TOPLEFT",50,-70)
    else
        list.textBox:SetPoint("TOPLEFT",lastPair.textBox,"BOTTOMLEFT",0,-10)
    end
    list.button:SetPoint("RIGHT",list.textBox,"LEFT",-5,-1)
end

function TrapInterfaceAddonPanel:setupButtonScripts()
    self.showHide.tradeList.button:HookScript("OnClick", function()
        if not TrapRaidRollerHidePickupFrame then
            TrapRaidRollerHidePickupFrame = true
        else
            TrapRaidRollerHidePickupFrame = false
        end
    end)

    self.showHide.leadList.button:HookScript("OnClick", function()
        if not TrapRaidRollerHideRolloutFrame then
            TrapRaidRollerHideRolloutFrame = true
        else
            TrapRaidRollerHideRolloutFrame = false
        end
    end)
end

function TrapInterfaceAddonPanel:setupInitialCheck(button, variable)
    if variable then
        button:SetChecked(false)
    else
        button:SetChecked(true)
    end
end

TrapInterfaceAddonPanel:OnLoad()