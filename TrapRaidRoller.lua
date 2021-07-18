--[[Copyright (c) 2021, David Segal All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. Neither the name of the addon nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

RaidRollerFrame = CreateFrame("Frame", nil, UIParent);

SLASH_TRAPRAIDROLLER1 = "/trr"
SLASH_RAIDROLLER2 = "/trapraidroller"
SlashCmdList["TRAPRAIDROLLER"] = function(msg)
    if msg == "show" then
        RaidRollerFrame:Show()
    elseif msg == "hide" then
        RaidRollerFrame:Hide()
    elseif msg == "" then
        if RaidRollerFrame:IsVisible() then
            RaidRollerFrame:Hide()
        elseif not RaidRollerFrame:IsVisible() then
            RaidRollerFrame:Show()
        end
    elseif msg == "reset" then
        RaidRollerFrame:resetForRoll()
    elseif msg == "help" or msg == "h" then
        print("|cFFFFFF00Trap Raid Roller V1.5.0")
        print("|cFF67BCFFShow this dialogue -- |r/trr h or /trr help")
        print("|cFF67BCFFShow or Hide Raid Roller-- |r/trr")
        print("|cFF67BCFFShow Raid Roller -- |r/trr show")
        print("|cFF67BCFFHide Raid Roller -- |r/trr hide")
        print("|cFF67BCFFReset Raid Roller -- |r/trr reset")
        print("|cFF67BCFFRoll out loot -- |r/trr [Link an item with shift+click]")
    else
        if IsInRaid() and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) then
            RaidRollerFrame:resetForRoll()
            RaidRollerFrame:parseItemInfo(msg)
        end
    end
end

BINDING_HEADER_TRAPRAIDROLLERKEYBINDS = "Trap Raid Roller"
BINDING_NAME_SHOWORHIDE="Show/Hide Rolls"
BINDING_NAME_RESETROLLS="Reset Rolls"


function RaidRollerFrame:parseItemInfo(msg)
    --       1          2     3   4    5  6      7                  9           10             15
    local itemName, itemLink, _, ilvl, _, _, itemSubType, _, itemEquipLocation, _, _, _, _, _, _, _, _= GetItemInfo(msg)
    local statTable = GetItemStats(msg)
    local rollMessage = itemLink .. " ROLL 100 Main Spec, 99 Off Spec, 98 Transmog"

    local statMessage = ""
    if itemName == "Mystic Anima Spherule" then --If it's a token...
        statMessage = "Hunter/Mage/Druid Mainhand"

    elseif itemName == "Abominable Anima Spherule" then
        statMessage = "Death Knight/Warlock/Demon Hunter Mainhand"

    elseif itemName == "Apogee Anima Bead" then
        statMessage = "Warrior/Paladin/Priest/Monk Shield/Offhand"
        
    elseif itemName == "Venerated Anima Spherule" then
        statMessage = "Paladin/Priest/Shaman Mainhand"

    elseif itemName == "Thaumaturgic Anima Bead" then
        statMessage = "Shaman/Mage/Warlock/Druid Shield/Offhand"

    elseif itemName == "Zenith Anima Spherule" then
        statMessage = "Warrior/Rogue/Monk Mainhand"

    else --If it's a normal piece of gear
        local itemLocation = self:checkItemLocation(itemEquipLocation)
        local itemEdited
        if itemLocation == "Weapon" then
            --PRIMARY STATS
            if statTable.ITEM_MOD_STRENGTH_SHORT ~= nil then
                itemEdited = "Strength "
            end

            if statTable.ITEM_MOD_AGILITY_SHORT ~= nil then
                itemEdited = "Agility "
            end

            if statTable.ITEM_MOD_INTELLIGENCE_SHORT ~= nil then
                itemEdited = "Intelligence "
            end
            --Get rid of the 's' at the end of the weapon type
            local weaponType,_,_,_,_,_ = string.match(itemSubType, "((%w-)(%-*)(%w-)(%s*)(%w+))s")
            if weaponType == "Stave" then
                itemEdited = itemEdited .. "Staff"
            else
                itemEdited = itemEdited .. weaponType
            end
            statMessage = itemEdited .. " "
        elseif itemSubType == "Miscellaneous" or itemEquipLocation == "INVTYPE_BAG" or itemEquipLocation == "INVTYPE_TABARD" or itemEquipLocation == "INVTYPE_SHIRT" or itemEquipLocation == "INVTYPE_CLOAK" or itemEquipLocation == "INVTYPE_SHIELD" or itemEquipLocation == "INVTYPE_HOLDABLE" then
            statMessage = itemLocation .. " "
        else
            statMessage = itemSubType .. " " .. itemLocation .. " "
        end

        --SECONDARY STATS
        local flag = false
        if statTable.ITEM_MOD_VERSATILITY ~= nil then
            statMessage = statMessage .. "Versatility"
            flag = true
        end

        if statTable.ITEM_MOD_MASTERY_RATING_SHORT ~= nil then
            if flag then
                statMessage = statMessage .. "/"
            end
            statMessage = statMessage .. "Mastery"
            flag = true
        end

        if statTable.ITEM_MOD_CRIT_RATING_SHORT ~= nil then
            if flag then
                statMessage = statMessage .. "/"
            end
            statMessage = statMessage .. "Crit"
            flag = true
        end

        if statTable.ITEM_MOD_HASTE_RATING_SHORT ~= nil then
            if flag then
                statMessage = statMessage .. "/"
            end
            statMessage = statMessage .. "Haste"
        end

        --TERTIARY STATS
        flag = false
        if statTable.EMPTY_SOCKET_PRISMATIC ~= nil then
            statMessage = statMessage .. " with a socket"
            flag = true
        end
        if statTable.ITEM_MOD_CR_LIFESTEAL_SHORT ~= nil then
            if flag then
                statMessage = statMessage .. " and leech"
            else
                statMessage = statMessage .. " with leech"
                flag = true
            end
        end

        if statTable.ITEM_MOD_CR_AVOIDANCE_SHORT ~= nil then
            if flag then
                statMessage = statMessage .. " and avoidance"
            else
                statMessage = statMessage .. " with avoidance"
                flag = true
            end
        end
        if statTable.ITEM_MOD_CR_SPEED_SHORT ~= nil then
            if flag then
                statMessage = statMessage .. " and speed"
            else
                statMessage = statMessage .. " with speed"
                flag = true
            end
        end
        if statTable.EMPTY_SOCKET_DOMINATION ~= nil then
            if flag then
                statMessage = statMessage .. " and a domination socket"
            else
                statMessage = statMessage .. " with a domination socket"
                flag = true
            end
        end
    end
    self:Show()
    SendChatMessage(rollMessage,"RAID_WARNING")
    SendChatMessage(statMessage,"RAID_WARNING")


end

function RaidRollerFrame:checkItemLocation(itemEquipLoc)
    local itemTypeLocation
    if itemEquipLoc == "INVTYPE_HEAD" then
        itemTypeLocation = "Helmet"
    elseif itemEquipLoc == "INVTYPE_NECK" then
        itemTypeLocation = "Neck"
    elseif itemEquipLoc == "INVTYPE_SHOULDER" then
        itemTypeLocation = "Shoulders"
    --elseif itemEquipLoc == "INVTYPE_BODY" then
    --    itemTypeLocation = "Shirt"
    elseif itemEquipLoc == "INVTYPE_CHEST" then
        itemTypeLocation = "Chest"
    elseif itemEquipLoc == "INVTYPE_WAIST" then
        itemTypeLocation = "Belt"
    elseif itemEquipLoc == "INVTYPE_LEGS" then
        itemTypeLocation = "Pants"
    elseif itemEquipLoc == "INVTYPE_FEET" then
        itemTypeLocation = "Boots"
    elseif itemEquipLoc == "INVTYPE_WRIST" then
        itemTypeLocation = "Bracer"
    elseif itemEquipLoc == "INVTYPE_HAND" then
        itemTypeLocation = "Gloves"
    elseif itemEquipLoc == "INVTYPE_FINGER" then
        itemTypeLocation = "Ring"
    elseif itemEquipLoc == "INVTYPE_TRINKET" then
       itemTypeLocation = "Trinket"
    elseif itemEquipLoc == "INVTYPE_CLOAK" then
       itemTypeLocation = "Cloak"
    --elseif itemEquipLoc == "INVTYPE_TABARD" then
    --    itemTypeLocation = "Tabard"
    elseif itemEquipLoc == "INVTYPE_ROBE" then
        itemTypeLocation = "Robe"
    elseif itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_2HWEAPON" then
        itemTypeLocation = "Weapon"
    elseif itemEquipLoc == "INVTYPE_HOLDABLE" then
        itemTypeLocation = "Offhand"
    elseif itemEquipLoc == "INVTYPE_SHIELD" then
        itemTypeLocation = "Shield"
    end
    return itemTypeLocation
end



--RaidRollerFrame.TEST_NAME = GetUnitName("player") This is for testing

--GUI
RaidRollerFrame:SetScript("OnEvent", function(self, event, ...)
    if ( event == "CHAT_MSG_SYSTEM" ) then
        local text = ...;
        local name, roll, minRoll, maxRoll = string.match(text, "(%S+) rolls (%d+) %((%d+)%-(%d+)%)")
        --name = self.TEST_NAME --This is for testing
        local numMaxRoll = tonumber( maxRoll )
        if ( tonumber(minRoll) ~= 1 ) then
            return
        elseif ( numMaxRoll == 100 ) then
            self:addMainRoll(name,roll)
            self:updateResults()
        elseif ( numMaxRoll == 99 ) then
            self:addOffRoll(name,roll)
            self:updateResults()
        elseif ( numMaxRoll == 98 ) then
            self:addMogRoll(name,roll)
            self:updateResults()
        end
    end
end)

function RaidRollerFrame:OnLoad()
    self.titleFrame = CreateFrame("Frame", nil, self)
    self.titleFrame:SetPoint("TOP",self,"TOP")
    self.titleFrame:SetSize(157,20)
    self:SetMovable(true)
    self.titleFrame:EnableMouse(true)
    self.titleFrame:RegisterForDrag("LeftButton")
    self.titleFrame:SetScript("OnDragStart", function ()
    self:StartMoving()
    end)
    self.titleFrame:SetScript("OnDragStop", function()
        self:StopMovingOrSizing()
    end)
    self:SetClampedToScreen(true)
    self.titleFrame.title = self.titleFrame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    self.titleFrame.title:SetPoint("TOP",self.titleFrame,"CENTER",0,5)
    self.titleFrame.title:SetText("Trap Raid Roller")



    RaidRollerFrame:RegisterEvent("CHAT_MSG_SYSTEM");
    local width = 200;
    self:SetSize(width, 150);
    self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 700, -200);
    self.Background = self:CreateTexture(nil, "BACKGROUND");
    self.Background:SetAllPoints(self);
    self.Background:SetColorTexture(0.0588, 0.0549, 0.102, 0.85);

    --Scroll Down Button
    self.scrollDownButton = CreateFrame("Button",nil,self)
    self.scrollDownButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    self.scrollDownButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
    self.scrollDownButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    self.scrollDownButton:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT")
    self.scrollDownButton:SetSize(25,25)
    self.scrollDownButton:SetScript('OnClick', function ()
        self:scrollDown()
    end)
    self:SetMovable(true)
    self:Hide()
    
    --Scroll Up Button
    self.scrollUpButton = CreateFrame("Button",nil,self)
    self.scrollUpButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    self.scrollUpButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
    self.scrollUpButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    self.scrollUpButton:SetPoint("TOPRIGHT",self,"TOPRIGHT",0,-20)
    self.scrollUpButton:SetSize(25,25)
    self.scrollUpButton:SetScript('OnClick', function()
        self:scrollUp()
    end)

    --Exit Button
    self.exitButton = CreateFrame("Button",nil,self)
    self.exitButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    self.exitButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    self.exitButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    self.exitButton:SetPoint("TOPRIGHT",self,"TOPRIGHT")
    self.exitButton:SetSize(25,25)
    self.exitButton:SetScript('OnClick', function()
        self:exitFrame()
    end)

    --Reset Button
    self.resetButton = CreateFrame("Button",nil,self)
    self.resetButton:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Undo")
    self.resetButton:SetPoint("TOPLEFT",self,"TOPLEFT",2.2,-2.5)
    self.resetButton:SetSize(18,18)
    self.resetButton:SetScript('OnClick', function()
        self:resetForRoll()
    end)
end

RaidRollerFrame:OnLoad();

RaidRollerFrame.MainRolls = {}
RaidRollerFrame.OffRolls = {}
RaidRollerFrame.MogRolls = {}
RaidRollerFrame.ResultFrames = {}
RaidRollerFrame.ScrollOffset = 0

function RaidRollerFrame:addMainRoll(name,number)
    for _, value in pairs(self.MainRolls) do
        if ( value.name == name ) then
            return
        end
    end
    table.insert(RaidRollerFrame.MainRolls, { ["name"] = name, ["roll"] = number });
    self:sortRolls(self.MainRolls)
end

function RaidRollerFrame:addOffRoll(name,number)
    for _, value in pairs(self.OffRolls) do
        if ( value.name == name ) then
            return
        end
    end
    table.insert(RaidRollerFrame.OffRolls, { ["name"] = name, ["roll"] = number });
    self:sortRolls(self.OffRolls)
end

function RaidRollerFrame:addMogRoll(name,number)
    for _, value in pairs(self.MogRolls) do
        if ( value.name == name ) then
            return
        end
    end
    table.insert(RaidRollerFrame.MogRolls, { ["name"] = name, ["roll"] = number });
    self:sortRolls(self.MogRolls)
end

function RaidRollerFrame:sortRolls(rollTable)
    table.sort(rollTable, function(value1,value2)
        return tonumber( value1.roll ) > tonumber ( value2.roll )
    end)
end

function RaidRollerFrame:createRollResult()
    local resultFrame = CreateFrame("Frame",nil,self);
    resultFrame.nameString = resultFrame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    resultFrame.rollString = resultFrame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    resultFrame.nameString:SetPoint("LEFT",resultFrame,"LEFT",0,0);
    resultFrame.rollString:SetPoint("RIGHT",resultFrame,"RIGHT",-20,0);
    resultFrame.nameString:SetPoint("RIGHT",resultFrame.rollString,"LEFT",-10,0);
    resultFrame.nameString:SetJustifyH("LEFT")
    resultFrame:SetSize(174,15)
    resultFrame.Background = resultFrame:CreateTexture(nil, "BACKGROUND")
    resultFrame.Background:SetAllPoints(resultFrame)
    resultFrame:EnableMouseWheel(true)
    resultFrame:SetScript('OnMouseWheel', function(self,delta)
        if delta == 1 then
            RaidRollerFrame:scrollUp()
        end
        if delta == -1 then
            RaidRollerFrame:scrollDown()
        end
    end)
    return resultFrame
    
end

function RaidRollerFrame:updateResults()
    local fullResultTable = {}
    for i = 1, #self.MainRolls, 1 do
        fullResultTable[i] = self.MainRolls[i]
        fullResultTable[i].spec = "Main"
    end
    for i = #self.MainRolls+1, #self.MainRolls+#self.OffRolls, 1 do
        fullResultTable[i] = self.OffRolls[i-#self.MainRolls]
        fullResultTable[i].spec = "Off"
    end
    for i = #self.MainRolls+#self.OffRolls+1, #self.MainRolls+#self.OffRolls+#self.MogRolls, 1 do
        fullResultTable[i] = self.MogRolls[i-#self.MainRolls-#self.OffRolls]
        fullResultTable[i].spec = "Mog"
    end
    --Can be changed to append


    --Creating the frames if we don't have them (ie: First roll since reload)
    while #self.ResultFrames < #fullResultTable and #self.ResultFrames < 8 do
        self.ResultFrames[#self.ResultFrames + 1] = self:createRollResult()
        if #self.ResultFrames == 1 then
            self.ResultFrames[1]:SetPoint("TOP",self.titleFrame,"BOTTOM",-7,-3)
        else
            self.ResultFrames[#self.ResultFrames]:SetPoint("TOP",self.ResultFrames[#self.ResultFrames-1],"BOTTOM",0,0)
        end
    end

    --Setting text to frames
    for i = 1, #self.ResultFrames, 1 do
        if #fullResultTable-self.ScrollOffset >= i then
            self.ResultFrames[i]:Show()
            if (i + self.ScrollOffset)%2 == 0 then
                self.ResultFrames[i].Background:SetColorTexture(0.1388,0.1349,0.182,0.85)
            else
                self.ResultFrames[i].Background:SetColorTexture(0.0588, 0.0549, 0.102, 0.85);
            end
            self.ResultFrames[i].nameString:SetText(fullResultTable[i+self.ScrollOffset].name)
            self.ResultFrames[i].rollString:SetText(fullResultTable[i+self.ScrollOffset].roll)
            if fullResultTable[i+self.ScrollOffset].spec == "Main" then
                self.ResultFrames[i].nameString:SetTextColor(0,0.44,0.87,1) --Rare colors
                self.ResultFrames[i].rollString:SetTextColor(0,0.44,0.87,1)
            elseif fullResultTable[i+self.ScrollOffset].spec == "Off" then
                self.ResultFrames[i].nameString:SetTextColor(0.12,1,0,1) --Uncommon colors
                self.ResultFrames[i].rollString:SetTextColor(0.12,1,0,1)
            elseif fullResultTable[i+self.ScrollOffset].spec == "Mog" then
                self.ResultFrames[i].nameString:SetTextColor(1,1,1,1) --Common Colors
                self.ResultFrames[i].rollString:SetTextColor(1,1,1,1)
            end
        else
            self.ResultFrames[i]:Hide()
        end
    end


end

function RaidRollerFrame:scrollUp()
    if self.ScrollOffset > 0 and #self.ResultFrames > #self.MainRolls + #self.OffRolls + #self.MogRolls - 8 then
        self.ScrollOffset = self.ScrollOffset - 1
        self:updateResults();
    end
end

function RaidRollerFrame:scrollDown()
    if self.ScrollOffset < #self.MainRolls + #self.OffRolls + #self.MogRolls - 8 then
        self.ScrollOffset = self.ScrollOffset + 1
        self:updateResults()
    end
end

function RaidRollerFrame:resetForRoll()
    self.MainRolls = {}
    self.OffRolls = {}
    self.MogRolls = {}
    self.ScrollOffset = 0
    for i = 1, #self.ResultFrames, 1 do
        self.ResultFrames[i]:Hide()
    end
end

function RaidRollerFrame:exitFrame()
    RaidRollerFrame:Hide()
end
--[[
TO DO: Add buttons and UI
MAKE SURE SROLL OFFSET = 0 WHEN STARTING ROLL


{
    {["name"] = Guill, ["roll"] = 99},
    {["name"] = Dialya, ["roll"] = 47},
}

for index, value in pairs(myValues) do
    print(index, value);
end

function RaidRollerFrame:ResetRolls()
    RaidRollerFrame.MainRolls = {}
    RaidRollerFrame.OffRolls = {}
    self.MogRolls = {}
end

RaidRollerFrame["MyFunc"] = function(self)
end


foo:bar(baz)
--is same as
foo.bar(foo, baz);

local tab = {
    {
        Guill = "Guill",
        roll = 1000,
    },
    {
        name = ""
    }
}

myRoll = tab[1];
tab.name

local myValues = { 1, 2, 3, 4, 5, foo = "bar" }
local myValues = {
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [7] = 7,
    ["foo"] = "bar",
}

-- Only ordered (not "bar" or 7)
for index, value in ipairs(myValues) do
    print(index, value);
end

-- Everything (including "bar")
for index, value in pairs(myValues) do
    print(index, value);
end


function getOrderedRolls(allRolls)
    local orders = { "Guill", "Dialya" };
    for name, roll in pairs(allRolls) do
        -- table.insert(orders, name);
        orders[#orders + 1] = { name = name, roll = roll };
    end
    table.sort(orders, function(value1, value2)
        return value1 > value2;
    end)
end

getOrderedRolls({
    ["Guill"] = 100,
    ["Dialya"] = 1,
})
]]--
