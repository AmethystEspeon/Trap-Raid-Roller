--[[Copyright (c) 2021, David Segal All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. Neither the name of the addon nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

local function debugPrint(...)
    print(...);
end



TrapRaidRoller = CreateFrame("Frame", nil, UIParent);
local PREFIX = "TrapRaidRoller";
C_ChatInfo.RegisterAddonMessagePrefix(PREFIX);

--Size of roll frame
TrapRaidRoller.WIDTH = 200;
TrapRaidRoller.HEIGHT = 150;

--Starting position of roll frame
TrapRaidRoller.START_X = 700;
TrapRaidRoller.START_Y = -200;

--Colors
TrapRaidRoller.BACKGROUND_COLORS = {0.0588, 0.0549, 0.102, 0.85}

local WEAPON_INVTYPES = {"INVTYPE_WEAPON","INVTYPE_RANGED","INVTYPE_2HWEAPON","INVTYPE_RANGEDRIGHT"}
local NO_TYPE_ITEMSUBTYPES = {"INVTYPE_BAG","INVTYPE_TABARD","INVTYPE_SHIRT","INVTYPE_CLOAK", "INVTYPE_SHIELD","INVTYPE_HOLDABLE"}

BINDING_HEADER_TRAPRAIDROLLERKEYBINDS = "Trap Raid Roller";
BINDING_NAME_SHOWHIDEROLLS="Show/Hide Rolls";
BINDING_NAME_RESETROLLS="Reset Rolls";
BINDING_NAME_SHOWHIDELIST="Show or Hide Loot List";

--Slash Commands
SLASH_TRAPRAIDROLLER1= "/trr"
SLASH_TRAPRAIDROLLER2 = "/trapraidroller"
SlashCmdList["TRAPRAIDROLLER"] = function(msg)
    if msg == "leadlist" then
        if TrapLeadList:IsVisible() then
            TrapLeadList:Hide()
        else
            TrapLeadList:Show()
        end
    elseif msg == "options" then
        --Add options menu show/hide
    elseif msg == "rolls" then
        if TrapRaidRoller:IsVisible() then
            TrapRaidRoller:Hide()
        else
            TrapRaidRoller:Show()
        end
    elseif msg == "reset" then
        TrapRaidRoller:resetRolls()
    elseif msg == "toggleColor" or msg == "tc" then
        if TrapRaidRollerDarkColor[1] == 0.0588 and TrapRaidRollerDarkColor[2] == 0.0549 and TrapRaidRollerDarkColor[3] == 0.102 and TrapRaidRollerDarkColor[4] ==  0.85 then
            TrapRaidRollerDarkColor = {0.0588, 0.102, 0.0549, 0.85}
            TrapRaidRollerLightColor = {0.1388,0.182,0.1349,0.85}
            TrapLeadList:updateVisual()
            TrapRaidRoller:updateVisual()
            print("|cFFFFFF00TRR Lists are now Green")
        else
            TrapRaidRollerDarkColor = {0.0588, 0.0549, 0.102, 0.85}
            TrapRaidRollerLightColor = {0.1388,0.1349,0.182,0.85}
            TrapLeadList:updateVisual()
            TrapRaidRoller:updateVisual()
            print("|cFFFFFF00TRR Loots are now Blue")
        end
    elseif msg == "" then
        if not TrapRaidRoller:IsVisibile() and not TrapLeadList:IsVisible() then
            TrapRaidRoller:Show()
            TrapLeadList:Show()
        else
            TrapRaidRoller:Hide()
            TrapLeadList:Hide()
        end
    else --Send something for roll
        local rollMessage, statMessage = TrapRaidRoller:getMessages(msg)
        SendChatMessage(rollMessage,"RAID_WARNING")
        SendChatMessage(statMessage,"RAID_WARNING")
        C_ChatInfo.SendAddonMessage(PREFIX,"roll TEXT_SENT_FROM_CHAT_LINE")
    end

end

function TrapRaidRoller:OnLoad()
    if not TrapRaidRollerDarkColor then
        TrapRaidRollerDarkColor = {0.0588, 0.0549, 0.102, 0.85};
        TrapRaidRollerLightColor = {0.1388,0.1349,0.182,0.85};
    end
    self:setupMainFrame(self);
    self:setupMainSettings(self,"CHAT_MSG_SYSTEM");
    self.titleFrame = CreateFrame("Frame",nil,self);
    self:setupTitleFrame(self,"TRR Rolls");
    self:createUpdater();
    self:createButtons();

    self:Hide();
end

function TrapRaidRoller:setupMainFrame(frame)
    frame:SetSize(frame.WIDTH,frame.HEIGHT);
    --debugPrint("Setting up positioning", frame.START_X, frame.START_Y)
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", frame.START_X, frame.START_Y);
    frame.Background = frame:CreateTexture(nil, "BACKGROUND");
    frame.Background:SetAllPoints(frame);
    frame.Background:SetColorTexture(self.BACKGROUND_COLORS[1],self.BACKGROUND_COLORS[2],self.BACKGROUND_COLORS[3],self.BACKGROUND_COLORS[4]);
end

function TrapRaidRoller:setupMainSettings(frame,event)
    frame:SetMovable(true);
    frame:SetClampedToScreen(true);
    frame:RegisterEvent(event);
    frame:Hide()
end

function TrapRaidRoller:setupTitleFrame(frame,text,mainFrame)
    frame.titleFrame = frame.titleFrame or CreateFrame("Frame",nil,frame)
    frame.titleFrame:SetPoint("TOP",frame,"TOP")
    frame.titleFrame:SetSize(157,20)
    self:setupTitleText(frame,text)
    self:setupDragging(frame.titleFrame,frame)
end

function TrapRaidRoller:setupTitleText(frame,text)
    frame.titleFrame.title = frame.titleFrame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    frame.titleFrame.title:SetPoint("TOP",frame.titleFrame,"CENTER",0,5)
    frame.titleFrame.title:SetText(text)
end

function TrapRaidRoller:setupDragging(frame,movableFrame)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    movableFrame:SetMovable(true)
    frame:SetScript("OnDragStart", function()
        movableFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        movableFrame:StopMovingOrSizing()
    end)

end

function TrapRaidRoller:createUpdater()
    TrapRaidRoller:SetScript("OnEvent", function(self,event,...)
        if ( event == "CHAT_MSG_SYSTEM" ) then
            local text = ...;
            local name, roll, minRoll, maxRoll = string.match(text, "(%S+) rolls (%d+) %((%d+)%-(%d+)%)");
            local numMaxRoll = tonumber( maxRoll );
            if ( tonumber(minRoll) ~= 1) then
                return
            elseif ( numMaxRoll == 100 ) then
                self:addMainRoll(name,roll);
                self:sortTable(self.mainRolls);
                self:updateVisual();
            elseif ( numMaxRoll == 99 ) then
                self:addOffRoll(name,roll);
                self:sortTable(self.offRolls);
                self:updateVisual();
            elseif ( numMaxRoll == 98 ) then
                self:addMogRoll(name,roll);
                self:sortTable(self.mogRolls);
                self:updateVisual();
            end
        end

        --[[
            Resetting rolls when a new roll is posted is done
            in TrapLootList:SetScript() because it's already 
            checking CHAT_MSG_ADDON
        ]]--
    end)
end

function TrapRaidRoller:addMainRoll(name,roll)
    self.mainRolls = self.mainRolls or {}
    for _, value in pairs(self.mainRolls) do
        if value.name == name then
            return --Early out: Name already on list for Main list
        end
    end

    table.insert(self.mainRolls, { ["name"] = name, ["roll"] = roll });
end

function TrapRaidRoller:addOffRoll(name,roll)
    self.offRolls = self.offRolls or {}
    for _, value in pairs(self.offRolls) do
        if value.name == name then
            return --Early out: Name already on list for Main list
        end
    end

    table.insert(self.offRolls, { ["name"] = name, ["roll"] = roll });
end

function TrapRaidRoller:addMogRoll(name,roll)
    self.mogRolls = self.mogRolls or {}
    for _, value in pairs(self.mogRolls) do
        if value.name == name then
            return --Early out: Name already on list for Main list
        end
    end

    table.insert(self.mogRolls, { ["name"] = name, ["roll"] = roll });
end

function TrapRaidRoller:sortTable(tableToSort)
    table.sort(tableToSort, function(value1,value2)
        return tonumber(value1.roll) > tonumber(value2.roll)
    end)
end

function TrapRaidRoller:updateVisual()

    --First we create the list used to loop through to create the roll visual
    self.allRolls = self:getAllRolls() or {}
    --then create the frames depending on the length of the list
    self:createRolls()
    self:assignFrames()
end

function TrapRaidRoller:getAllRolls()
    local allRolls = {}
    self.mainRolls = self.mainRolls or {}
    self.offRolls = self.offRolls or {}
    self.mogRolls = self.mogRolls or {}


    local startLoop = 1 --Start at one
    local endLoop = #self.mainRolls --End after mainspec rolls
    for i = startLoop, endLoop, 1 do
        allRolls[i] = self.mainRolls[i];
        allRolls[i].rollType = "Main";
    end

    startLoop = startLoop + #self.mainRolls --Start after mainspec rolls
    endLoop = endLoop + #self.offRolls --End after offspec rolls
    for i = startLoop, endLoop, 1 do
        allRolls[i] = self.offRolls[i-startLoop+1];
        allRolls[i].rollType = "Off";
    end

    startLoop = startLoop + #self.offRolls --Start after offspec rolls
    endLoop = endLoop + #self.mogRolls --End after transmog rolls
    for i = startLoop, endLoop do
        allRolls[i] = self.mogRolls[i-startLoop+1];
        allRolls[i].rollType = "Mog";
    end

    return allRolls
end

--Create enough frames (up to 8) for the rolls
function TrapRaidRoller:createRolls()
    self.rollFrames = self.rollFrames or {}
    if not self.allRolls then
        return --Early out: No list
    end
    --While we need to create more frames to list rolls, but less than 8 of them
    while #self.rollFrames < #self.allRolls and #self.rollFrames < 8 do
        --Create a frame in the list
        self.rollFrames[#self.rollFrames + 1] = self:createRollFrames()
        --If it's the first one attach it to the title frame in the right place
        if #self.rollFrames == 1 then
            self.rollFrames[1]:SetPoint("Top",self.titleFrame,"BOTTOM",-7,-3)
        --Otherwise just connect it to the bottom of the last one
        else
            self.rollFrames[#self.rollFrames]:SetPoint("TOP",self.rollFrames[#self.rollFrames - 1],"BOTTOM",0,0)
        end
    end
end

function TrapRaidRoller:createRollFrames()
    local frame = CreateFrame("Frame",nil,self);
    frame.nameString = frame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    frame.rollString = frame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    frame.nameString:SetPoint("LEFT",frame,"LEFT",0,0);
    frame.rollString:SetPoint("RIGHT",frame,"RIGHT",-20,0);
    frame.nameString:SetPoint("RIGHT",frame.rollString,"LEFT",-10,0);
    frame.nameString:SetJustifyH("LEFT")
    frame:SetSize(self.WIDTH-26,15)
    frame.Background = frame:CreateTexture(nil, "BACKGROUND")
    frame.Background:SetAllPoints(frame)
    
    --SETUP SCROLLING
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self,delta)
        if delta == 1 then
            self:scrollUp()
        end
        if delta == -1 then
            self:scrollDown()
        end
    end)

    return frame
end

function TrapRaidRoller:assignFrames()
    if not self.rollFrames or not self.allRolls then
        return --No lists
    end
    self.scrollOffset = self.scrollOffset or 0
    for i = 1, #self.rollFrames, 1 do
        if #self.allRolls - self.scrollOffset >= i then
            self.rollFrames[i]:Show()
            if (i + self.scrollOffset)%2 == 0 then
                self.rollFrames[i].Background:SetColorTexture(TrapRaidRollerLightColor[1],TrapRaidRollerLightColor[2],TrapRaidRollerLightColor[3],TrapRaidRollerLightColor[4])
            else
                self.rollFrames[i].Background:SetColorTexture(TrapRaidRollerDarkColor[1],TrapRaidRollerDarkColor[2],TrapRaidRollerDarkColor[3],TrapRaidRollerDarkColor[4])
            end
            self.rollFrames[i].nameString:SetText(self.allRolls[i+self.scrollOffset].name)
            self.rollFrames[i].rollString:SetText(self.allRolls[i+self.scrollOffset].roll)
            if self.allRolls[i+self.scrollOffset].rollType == "Main" then
                self.rollFrames[i].nameString:SetTextColor(0,0.44,0.87,1) --Rare colors
                self.rollFrames[i].rollString:SetTextColor(0,0.44,0.87,1)
            elseif self.allRolls[i+self.scrollOffset].rollType == "Off" then
                self.rollFrames[i].nameString:SetTextColor(0.12,1,0,1) --Uncommon colors
                self.rollFrames[i].rollString:SetTextColor(0.12,1,0,1)
            elseif self.allRolls[i+self.scrollOffset].rollType == "Mog" then
                self.rollFrames[i].nameString:SetTextColor(1,1,1,1) --Common Colors
                self.rollFrames[i].rollString:SetTextColor(1,1,1,1)
            else
                debugPrint("NO COLOR")
            end
        else
            self.rollFrames[i]:Hide()
        end
    end

end

function TrapRaidRoller:createButtons()
    --Scroll Up Button
    self.scrollUpButton = CreateFrame("Button",nil,self)
    self:setButtonTextures(self.scrollUpButton,"Interface\\Buttons\\UI-ScrollBar-ScrollUpButton")
    self.scrollUpButton:SetPoint("TOPRIGHT",self,"TOPRIGHT",0,-20)
    self.scrollUpButton:SetSize(25,25)
    self.scrollUpButton:SetScript('OnClick', function()
        self:scrollUp()
    end)

    --Scroll Down Button
    self.scrollDownButton = CreateFrame("Button",nil,self)
    self:setButtonTextures(self.scrollDownButton,"Interface\\Buttons\\UI-ScrollBar-ScrollDownButton")
    self.scrollDownButton:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT")
    self.scrollDownButton:SetSize(25,25)
    self.scrollDownButton:SetScript('OnClick', function ()
        self:scrollDown()
    end)
  
    --Exit Button
    self.exitButton = CreateFrame("Button",nil,self)
    self:setButtonTextures(self.exitButton,"Interface\\Buttons\\UI-Panel-MinimizeButton")
    self.exitButton:SetPoint("TOPRIGHT",self,"TOPRIGHT")
    self.exitButton:SetSize(25,25)
    self.exitButton:SetScript('OnClick', function()
        self:Hide()
    end)

    --Reset Button
    self.resetButton = CreateFrame("Button",nil,self)
    self.resetButton:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Undo")
    self.resetButton:SetPoint("TOPLEFT",self,"TOPLEFT",2.2,-2.5)
    self.resetButton:SetSize(18,18)
    self.resetButton:SetScript('OnClick', function()
        self:resetRolls()
    end)

end

function TrapRaidRoller:setButtonTextures(button,buttonPath)
    button:SetNormalTexture(buttonPath.."-Up")
    button:SetHighlightTexture(buttonPath.."-Highlight")
    button:SetPushedTexture(buttonPath.."-Down")
end

function TrapRaidRoller:scrollUp()
    if self.scrollOffset > 0 and #self.rollFrames > #self.allRolls - 8 then
        self.scrollOffset = self.scrollOffset - 1
        self:assignFrames()
    end
end

function TrapRaidRoller:scrollDown()
    if self.scrollOffset < #self.allRolls - 8 then
        self.scrollOffset = self.scrollOffset + 1
        self:assignFrames()
    end
end

function TrapRaidRoller:resetRolls()
    self.mainRolls = {}
    self.offRolls = {}
    self.mogRolls = {}
    self.allRolls = {}
    self.scrollOffset = 0
    self.rollFrames = self.rollFrames or {}
    for i = 1, #self.rollFrames, 1 do
        self.rollFrames[i]:Hide()
    end
end

function TrapRaidRoller:getMessages(item)
    local rollMessage = item .. " ROLL 100 Main Spec, 99 Off Spec, 98 Transmog"
    local statMessage = self:getStatMessage(item)
    return rollMessage, statMessage
end

function TrapRaidRoller:getStatMessage(item)
    local message = self:checkItemToken(item)
    if message then
        return message --Early out: It's a token, so we just need the classes
    end

    if self:checkIfWeapon(item) then
        local mainStat = self:getMainStat(item)
        local weaponType = self:getWeaponType(item)
        local secondaries = self:getSecondaryStats(item)
        local tertiaries = self:getTertiaries(item)

        return mainStat .. " " .. weaponType .. " " .. secondaries .. " " .. tertiaries
    end

    --If it's not a weapon or token, it's a normal piece of gear
    local itemType = self:getItemType(item)
    local itemSlot = self:getItemSlotName(item)
    local secondaries = self:getSecondaryStats(item)
    local tertiaries = self:getTertiaries(item)

    return itemType .. itemSlot .. " " .. secondaries .. " " .. tertiaries
end

function TrapRaidRoller:checkItemToken(item)
    local itemName = GetItemInfo(item)
    if itemName == "Mystic Anima Spherule" then --If it's a token
        return "Hunter/Mage/Druid Mainhand"

    elseif itemName == "Abominable Anima Spherule" then
        return "Death Knight/Warlock/Demon Hunter Mainhand"

    elseif itemName == "Apogee Anima Bead" then
        return "Warrior/Paladin/Priest/Monk Shield/Offhand"
        
    elseif itemName == "Venerated Anima Spherule" then
        return "Paladin/Priest/Shaman Mainhand"

    elseif itemName == "Thaumaturgic Anima Bead" then
        return "Shaman/Mage/Warlock/Druid Shield/Offhand"

    elseif itemName == "Zenith Anima Spherule" then
        return "Warrior/Rogue/Monk Mainhand"
    end

    return nil --if it's not a token
end

function TrapRaidRoller:checkIfWeapon(item)
    --debugPrint("item:",item)
    local _,_,_,_,_, _,_,_,_,itemEquipLocation = GetItemInfo(item)

    if TrapRaidRoller:listContains(WEAPON_INVTYPES,itemEquipLocation) then
        return true
    end
    --Else return false
    return false 
end

function TrapRaidRoller:listContains(list, item)
    for index, value in ipairs(list) do
        if value == item then
            return true
        end
    end

    return false
end

function TrapRaidRoller:getMainStat(item)
    local statTable = GetItemStats(item)
    if statTable.ITEM_MOD_STRENGTH_SHORT ~= nil then
        return "Strength"
    elseif statTable.ITEM_MOD_AGILITY_SHORT ~= nil then
        return "Agility"
    elseif statTable.ITEM_MOD_INTELLECT_SHORT ~= nil then
        return "Intellect"
    end

    debugPrint("!!ERROR!! Item did not have a main stat If it is a weapon please contact Dialya-BleedingHollow (Amethyst Espeon#2459 on discord): ",item)
    return ""
end

function TrapRaidRoller:getWeaponType(item)
    local _,_,_,_,_, _,itemSubType = GetItemInfo(item)
    local weaponType = string.match(itemSubType, "((%w-)(%-*)(%w-)(%s*)(%w+))s")
    if weaponType == "Stave" then
        weaponType = "Staff"
    end

    return weaponType
end

function TrapRaidRoller:getSecondaryStats(item)
    local statTable = GetItemStats(item)
    local firstStatObtained = false
    local secondaryStats = ""
    if statTable.ITEM_MOD_CRIT_RATING_SHORT ~= nil then
        secondaryStats = "Crit"
        firstStatObtained = true
    end

    if statTable.ITEM_MOD_HASTE_RATING_SHORT ~= nil then
        if firstStatObtained then
            secondaryStats = secondaryStats .. "/"
        end
        secondaryStats = secondaryStats .. "Haste"
        firstStatObtained = true
    end

    if statTable.ITEM_MOD_MASTERY_RATING_SHORT ~= nil then
        if firstStatObtained then
            secondaryStats = secondaryStats .. "/"
        end
        secondaryStats = secondaryStats .. "Mastery"
        firstStatObtained = true
    end

    if statTable.ITEM_MOD_VERSATILITY ~= nil then
        if firstStatObtained then
            secondaryStats = secondaryStats .. "/"
        end
        secondaryStats = secondaryStats .. "Versatility"
        firstStatObtained = true
    end

    return secondaryStats
end

function TrapRaidRoller:getTertiaries(item)
    local statTable = GetItemStats(item)
    local firstStatObtained = false
    local tertiaryStats = ""
    if statTable.EMPTY_SOCKET_PRISMATIC ~= nil then
        tertiaryStats = " with a socket"
        firstStatObtained = true
    end

    if statTable.ITEM_MOD_CR_LIFESTEAL_SHORT ~= nil then
        if firstStatObtained then
            tertiaryStats = tertiaryStats .. "and leech"
        else
            tertiaryStats = " with leech"
            firstStatObtained = true
        end
    end

    if statTable.ITEM_MOD_CR_AVOIDANCE_SHORT ~= nil then
        if firstStatObtained then
            tertiaryStats = tertiaryStats .. "and avoidance"
        else
            tertiaryStats = " with avoidance"
            firstStatObtained = true
        end
    end

    if statTable.ITEM_MOD_CR_SPEED_SHORT ~= nil then
        if firstStatObtained then
            tertiaryStats = tertiaryStats .. "and speed"
        else
            tertiaryStats = " with speed"
            firstStatObtained = true
        end
    end

    if statTable.EMPTY_SOCKET_DOMINATION ~= nil then
        if firstStatObtained then
            tertiaryStats = tertiaryStats .. "and a domination socket"
        else
            tertiaryStats = " with a domination socket"
            firstStatObtained = true
        end
    end

    return tertiaryStats
end

function TrapRaidRoller:getItemType(item)
    local _,_,_,_,_, _,itemType,_,itemEquipLocation = GetItemInfo(item)
    if itemType == "Miscellaneous" then
        return ""
    end
    if self:listContains(NO_TYPE_ITEMSUBTYPES,itemEquipLocation) then
        return ""
    end
    return itemType .. " "

end

function TrapRaidRoller:getItemSlotName(item)
    local _,_,_,_,_, _,_,_,itemEquipLocation = GetItemInfo(item)
    if itemEquipLocation == "INVTYPE_HEAD" then
        return "Helmet"
    elseif itemEquipLocation == "INVTYPE_NECK" then
        return "Neck"
    elseif itemEquipLocation == "INVTYPE_SHOULDER" then
        return "Shoulders"
    elseif itemEquipLocation == "INVTYPE_BODY" then
        return "Shirt"
    elseif itemEquipLocation == "INVTYPE_CHEST" then
        return "Chest"
    elseif itemEquipLocation == "INVTYPE_WAIST" then
        return "Belt"
    elseif itemEquipLocation == "INVTYPE_LEGS" then
        return "Pants"
    elseif itemEquipLocation == "INVTYPE_FEET" then
        return "Boots"
    elseif itemEquipLocation == "INVTYPE_WRIST" then
        return "Bracers"
    elseif itemEquipLocation == "INVTYPE_HAND" then
        return "Gloves"
    elseif itemEquipLocation == "INVTYPE_FINGER" then
        return "Ring"
    elseif itemEquipLocation == "INVTYPE_TRINKET" then
        return "Trinket"
    elseif itemEquipLocation == "INVTYPE_CLOAK" then
        return "Cloak"
    elseif itemEquipLocation == "INVTYPE_BAG" then
        return "Bag"
    elseif itemEquipLocation == "INVTYPE_TABARD" then
        return "Tabard"
    elseif itemEquipLocation == "INVTYPE_ROBE" then
        return "Robe"
    elseif itemEquipLocation == "INVTYPE_HOLDABLE" then
        return "Offhand? (Need confirmation)"
    elseif itemEquipLocation == "INVTYPE_RANGEDRIGHT" then
        return "Ranged right? (What is this?)"
    elseif itemEquipLocation == "INVTYPE_QUIVER" then
        return "Quiver"
    elseif itemEquipLocation == "INVTYPE_RELIC" then
        return "Relic"
    end
end

TrapRaidRoller:OnLoad()