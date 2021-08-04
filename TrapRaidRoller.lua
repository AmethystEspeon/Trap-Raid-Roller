--[[Copyright (c) 2021, David Segal All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. Neither the name of the addon nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

local function debugPrint(...)
    print(...)
end

RaidRollerFrame = CreateFrame("Frame", nil, UIParent);
TrapLootListFrame = CreateFrame("Frame", nil, UIParent);
TrapTradeLootFrame = CreateFrame("Frame",nil, UIParent);
local Prefix = "TrapRaidRoller"
C_ChatInfo.RegisterAddonMessagePrefix(Prefix)

--Used to see if you can roll out an item (if someone had rolled out an item right before you)
local rerollReadyCheck = true 

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
    elseif msg == "list" then
        if TrapLootListFrame:IsVisible() then
            TrapLootListFrame:Hide()
            elseif not TrapLootListFrame:IsVisible() then
            TrapLootListFrame:Show()
        end
    elseif msg == "togglePickup" then
        if not TrapRaidRollerHidePickupFrame then
            TrapRaidRollerHidePickupFrame = true
        else
            TrapRaidRollerHidePickupFrame = false
        end
    elseif msg == "toggleLootList" then
        if not TrapRaidRollerHideRolloutFrame then
            TrapRaidRollerHideRolloutFrame = true
        else
            TrapRaidRollerHideRolloutFrame = false
        end
    elseif msg == "reset" then
        RaidRollerFrame:resetForRoll()
    elseif msg == "help" or msg == "h" then
        print("|cFFFFFF00Trap Raid Roller V2.0.3")
        print("|cFF67BCFFShow this dialogue -- |r/trr h or /trr help")
        print("|cFF67BCFFShow or Hide Raid Roller-- |r/trr")
        print("|cFF67BCFFShow Raid Roller -- |r/trr show")
        print("|cFF67BCFFHide Raid Roller -- |r/trr hide")
        print("|cFF67BCFFReset Raid Roller -- |r/trr reset")
        print("|cFF67BCFFRoll out loot -- |r/trr [Link an item with shift+click]")
        print("|cFF67BCFFToggle popup of On Pickup frame -- |r/trr togglePickup")
        print("|cFF67BCFFToggle popup of Loot List frame -- |r/trr toggleLootList")
    else
        if IsInRaid() and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) then
            RaidRollerFrame:resetForRoll()
            RaidRollerFrame:parseItemInfo(msg)
        end
    end
end

BINDING_HEADER_TRAPRAIDROLLERKEYBINDS = "Trap Raid Roller"
BINDING_NAME_SHOWHIDEROLLS="Show/Hide Rolls"
BINDING_NAME_RESETROLLS="Reset Rolls"
BINDING_NAME_SHOWHIDELIST="Show or Hide Loot List"
--TODO:
--create a frame on load for officers to see loot on
--create a yes/no frame for giving loot
--RegisterEvent for picking up an item (Use CHAT_MSG_LOOT, look for "You receive loot: (%.+)|r.") then add the |r?
--When you pick up an item: Check if it's equipable
--If it is equipable, check its ilvl against currently equipped ilvl in the same slot
--       Special case for trinkets
--





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

            if statTable.ITEM_MOD_INTELLECT_SHORT ~= nil then
                itemEdited = "Intellect "
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

--In: Location. Out: InvSlotId
function TrapTradeLootFrame:getItemSlot(pickedLoc)
    --It is in the exact order of https://wowpedia.fandom.com/wiki/Enum.InventoryType
    --debugPrint("pickedItemLoc in getItemSlot", pickedLoc)
    if pickedLoc == "INVTYPE_HEAD" then
        return 1
    elseif pickedLoc == "INVTYPE_NECK" then
        return 2
    elseif pickedLoc == "INVTYPE_SHOULDER" then
        return 3
    elseif pickedLoc == "INVTYPE_BODY" then
        return 4
    elseif pickedLoc == "INVTYPE_CHEST" then
        return 5
    elseif pickedLoc == "INVTYPE_WAIST" then
        return 6
    elseif pickedLoc == "INVTYPE_LEGS" then
        return 7
    elseif pickedLoc == "INVTYPE_FEET" then
        return 8
    elseif pickedLoc == "INVTYPE_WRIST" then
        return 9
    elseif pickedLoc == "INVTYPE_HAND" then
        return 10
    elseif pickedLoc == "INVTYPE_FINGER" then
        return 11 --Remember to check 12 for second ring
    elseif pickedLoc == "INVTYPE_TRINKET" then
        return 13 --Remember to check 14 for other trinket
    elseif pickedLoc == "INVTYPE_WEAPON" then
        return 16 --Remember to check 17 if dual wielding
    elseif pickedLoc == "INVTYPE_SHIELD" then
        return 17
    elseif pickedLoc == "INVTYPE_RANGED" then
        return 16
    elseif pickedLoc == "INVTYPE_CLOAK" then
        return 15
    elseif pickedLoc == "INVTYPE2HWEAPON" then
        return 16
    elseif pickedLoc == "INVTYPE_TABARD" then
        return 19
    elseif pickedLoc == "INVTYPE_ROBE" then
        return 5
    elseif pickedLoc == "INVTYPE_WEAPONMAINHAND" then
        return 16
    elseif pickedLoc == "INVTYPE_WEAPONOFFHAND" then
        return 16
    elseif pickedLoc == "INVTYPE_HOLDABLE" then
        return 17
    elseif pickedLoc == "INVTYPE_RANGEDRIGHT" then
        return 16 --what even is this?
    else
        return 0 --If it's not one of these then it will just stop
    end
end

--RaidRollerFrame.TEST_NAME = GetUnitName("player") This is for testing

--GUI
--------------------------------------------------------------
--------------------------------------------------------------

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

--Roll Frame Creation
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
    self.titleFrame.title:SetText("TRR Rolls")



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

--Loot List Frame Creation
function TrapLootListFrame:OnLoad()
    self.titleFrame = CreateFrame("Frame",nil,self)
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
    self.titleFrame.title:SetText("TRR Loot List")
    self:SetSize(450,430);
    self:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -300, -200);
    self.Background = self:CreateTexture(nil,"BACKGROUND");
    self.Background:SetAllPoints(self);
    self.Background:SetColorTexture(0.0588, 0.0549, 0.102, 0.85);
    self:Hide()

    self.exitButton = CreateFrame("Button",nil,self)
    self.exitButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    self.exitButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    self.exitButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    self.exitButton:SetPoint("TOPRIGHT",self,"TOPRIGHT")
    self.exitButton:SetSize(30,30)
    self.exitButton:SetScript('OnClick', function()
        self:Hide()
    end)


    self:RegisterEvent("CHAT_MSG_ADDON")
end

TrapLootListFrame:OnLoad();

TrapLootListFrame.PlayerLoot = {}
TrapLootListFrame.ListFrames = {}
TrapLootListFrame.ButtonBackgrounds = {}
TrapLootListFrame.RollButtons = {}
--TrapLootListFrame.RemoveButtons = {}

--Loot List Getting Info
TrapLootListFrame:SetScript("OnEvent",function(self,event,...)
    if( event == "CHAT_MSG_ADDON" ) then
        local recPrefix, text, _, sender = ...;
        if recPrefix == Prefix then
            if string.match(text, "add (.+)") then --If we're adding something, add it
                self:addPlayerLoot(sender, string.match(text, "add (.+)"))
                if IsInRaid() and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) and not TrapRaidRollerHideRolloutFrame then
                    self:Show()
                end
                --debugPrint("Incoming Text: ", text)
                --debugPrint("From Player: ", sender)    
            end
            if string.match(text, "roll (.+)") then --If someone rolled something out, reset the roll list
                RaidRollerFrame:resetForRoll()
                rerollReadyCheck = false
                C_Timer.After(2, function() rerollReadyCheck = true end)
            end

        end
    end
end)

function TrapLootListFrame:addPlayerLoot(player, item)
    --debugPrint("player to add:", player)
    --debugPrint("item to add:", item)
    if #self.PlayerLoot >= 8 then
        table.remove(TrapLootListFrame.PlayerLoot,1)
    end
    table.insert(TrapLootListFrame.PlayerLoot, {["sender"] = player, ["item"] = item});
    self:checkLootFrame()

end

--Updates loot list frame
function TrapLootListFrame:checkLootFrame()
    while #self.ListFrames < #self.PlayerLoot and #self.ListFrames < 8 do --If there are more things to show than frames
        self.ListFrames[#self.ListFrames + 1] = self:createListFrame()
        self.ButtonBackgrounds[#self.ButtonBackgrounds+1] = self:createButtonBackground()
        self.RollButtons[#self.RollButtons+1] = self:createListRollButton()
        if #self.ListFrames == 1 then
            self.ListFrames[1]:SetPoint("TOP",self.titleFrame,"BOTTOMLEFT", 55,0)
            self.ButtonBackgrounds[1]:SetPoint("LEFT",self.ListFrames[1],"RIGHT",0,0)
            self.RollButtons[1]:SetPoint("LEFT", self.ButtonBackgrounds[1],"LEFT", 0,-4)
        else
            self.ListFrames[#self.ListFrames]:SetPoint("TOP",self.ListFrames[#self.ListFrames-1],"BOTTOM",0,0)
            self.ButtonBackgrounds[#self.ButtonBackgrounds]:SetPoint("LEFT",self.ListFrames[#self.ListFrames],"RIGHT",0,0)
            self.RollButtons[#self.RollButtons]:SetPoint("LEFT", self.ButtonBackgrounds[#self.ButtonBackgrounds],"LEFT", 0,-4)
        end
    end
    for i = #self.ListFrames, 1, -1 do
        if self.ListFrames[i].nameString == nil then
            self.ListFrames[i]:Hide()
            self.ButtonBackgrounds[i]:Hide()
            self.RollButtons[i]:Hide()
        end
    end
    for i = 1, #self.PlayerLoot, 1 do
        if i%2 == 0 then
            self.ListFrames[i].Background:SetColorTexture(0.1388,0.1349,0.182,0.85)
            self.ButtonBackgrounds[i].Background:SetColorTexture(0.1388,0.1349,0.182,0.85)
        else
            self.ListFrames[i].Background:SetColorTexture(0.0588, 0.0549, 0.102, 0.85);
            self.ButtonBackgrounds[i].Background:SetColorTexture(0.0588, 0.0549, 0.102, 0.85);

        end
        self.ListFrames[i].nameString:SetText(self.PlayerLoot[i].sender)
        self.ListFrames[i].itemString:SetText(self.PlayerLoot[i].item)
        self.ListFrames[i]:HookScript("OnEnter",function()
            GameTooltip:SetOwner(TrapLootListFrame.ListFrames[i], "ANCHOR_TOP")
            GameTooltip:SetHyperlink(self.PlayerLoot[i].item)
            GameTooltip:Show()
        end)
        
        TrapLootListFrame.ListFrames[i]:HookScript("OnLeave",function()
            GameTooltip:Hide()
        end)
        
        --LINKING ROLL BUTTON TO ITEM PARSING
        self.RollButtons[i]:SetScript('OnClick', function()
            if not rerollReadyCheck then
                PlaySound(846)
            elseif IsInRaid() and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) and rerollReadyCheck then
                RaidRollerFrame:parseItemInfo(self.PlayerLoot[i].item)
                C_ChatInfo.SendAddonMessage(Prefix,"roll " .. self.PlayerLoot[i].item, "RAID")
            end
        end)

    end
end

--Creating a list frame to put loot in.
function TrapLootListFrame:createListFrame()
    local listFrame = CreateFrame("Frame",nil,self)
    listFrame.nameString = listFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge",nil)
    listFrame.itemString = listFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge",nil)
    listFrame.nameString:SetPoint("LEFT",listFrame,"LEFT",5,0)
    listFrame.itemString:SetPoint("CENTER",listFrame,"CENTER",50,0)
    listFrame:SetSize(400,50)
    listFrame.Background = listFrame:CreateTexture(nil, "BACKGROUND")
    listFrame.Background:SetAllPoints(listFrame)
    return listFrame    
end

--Creating a background for the buttons on the loot list frame
function TrapLootListFrame:createButtonBackground()
    local buttonBackground = CreateFrame("Frame",nil,self)
    buttonBackground:SetSize(48,50)
    buttonBackground.Background = buttonBackground:CreateTexture(nil, "BACKGROUND")
    buttonBackground.Background:SetAllPoints(buttonBackground)
    return buttonBackground
end

--Creating the Roll button for the LootListFrame
function TrapLootListFrame:createListRollButton()
    --debugPrint("Roll Button for List was created")
    local rollButton = CreateFrame("Button",nil,self)
    rollButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
    rollButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Highlight")
    rollButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Down")
    rollButton:SetSize(35,35)

    return rollButton
end


--[[UNUSED
--Creating the remove button for the LootListFrame
function TrapLootListFrame:createRemoveButton()
    local removeButton = CreateFrame("Button",nil,self)
    removeButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    removeButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
    removeButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
    removeButton:SetSize(35,35)

    return removeButton
end
--]]

--Trade Confirmation Frame Creation
function TrapTradeLootFrame:OnLoad()
    --Main Text (with drag)
    self.lootLink = "";
    self.textFrame = CreateFrame("Frame",nil,self)
    self.textFrame:SetPoint("TOP",self,"TOP")
    self.textFrame:SetSize(210,40)
    self.textFrame:EnableMouse(true)
    self.textFrame:RegisterForDrag("LeftButton")
    self.textFrame:SetScript("OnDragStart", function ()
        self:StartMoving()
    end)
    self.textFrame:SetScript("OnDragStop", function()
        self:StopMovingOrSizing()
    end)
    self.textFrame.text = self.textFrame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    self.textFrame.text:SetPoint("TOP",self.textFrame,"TOP",0,-5)
    self.textFrame.text:SetText("Do you want to let Raid Assists\nknow to roll out this item?")
    --Main Options
    self:RegisterEvent("CHAT_MSG_LOOT")
    self:SetClampedToScreen(true)
    self:SetMovable(true)
    self:SetSize(210,100);
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    self.Background = self:CreateTexture(nil,"DIALOGUE");
    self.Background:SetAllPoints(self);
    self.Background:SetColorTexture(0.0588, 0.0549, 0.102, 0.85);
    self:Hide()
    
    --Acquired item text frame
    self.acquiredTextFrame = CreateFrame("Frame",nil,self)
    self.acquiredTextFrame:SetPoint("TOP",self.textFrame,"BOTTOM",0,0)
    self.acquiredTextFrame.text = self.acquiredTextFrame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    self.acquiredTextFrame.text:SetPoint("TOP",self.acquiredTextFrame,"CENTER",0,10)
    self.acquiredTextFrame:EnableMouse(false)

    --Yes Checkmark Button/eve
    self.checkmark = CreateFrame("Button",nil,self)
    self.checkmark:SetNormalTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    self.checkmark:SetPoint("BOTTOMLEFT",self,"BOTTOMLEFT",40,10)
    self.checkmark:SetSize(30,30)
    self.checkmark:SetScript('OnClick', function()
        --debugPrint("Attempt message through addon: ", UnitName("player") .. " " .. self.lootLink)
        C_ChatInfo.SendAddonMessage(Prefix, "add " .. self.lootLink, "RAID")
        self:Hide()
    end)

    --No Checkmark Button
    self.xMark = CreateFrame("Button",nil,self)
    self.xMark:SetNormalTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    self.xMark:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",-40,10)
    self.xMark:SetSize(30,30)
    self.xMark:SetScript('OnClick', function()
        self:Hide()
    end)

end

--Trade Confirmation Frame Event to pop up and ask
TrapTradeLootFrame:SetScript("OnEvent", function(self,event,...)
    if ( event == "CHAT_MSG_LOOT") and not TrapRaidRollerHidePickupFrame then
        --Ignore the entire script if the player isn't in a raid.
        if not IsInRaid() then
            return
        end
        --debugPrint("Got CHAT MESSAGE")
        local text = ...;
        self.lootLink = string.match(text, "You receive loot: (.+|r)")
        --self.lootLink = string.match(text, "You receive item: (.+|r)") --USED FOR BUY TESTING
        local skip = true
        local equipped1ItemLink, equipped1iLvl, equipped1Location
        local equipped2ItemLink, equipped2iLvl, equipped2Location
        if IsEquippableItem(self.lootLink) then
            --debugPrint("this item is equippable", self.lootLink)
            local _, pickedItemLink, pickedItemQuality, pickediLvl, _, _, _, _, pickedLocation = GetItemInfo(self.lootLink)

            --If the item isn't epic or higher, exit the script
            if pickedItemQuality >= 4 then
                return
            end

            --Find what slot it is
            --debugPrint("pickedLocation right before changing to slotID", pickedLocation)
            local pickedSlotID = self:getItemSlot(pickedLocation)
            --debugPrint("pickedSlotID",pickedSlotID)
            --If it isn't a slot that isn't comparable (ie: a bag, which is equippable) then skip this
            if pickedSlotID ~= 0 then 
                _, equipped1ItemLink, _, equipped1iLvl, _, _, _, _, equipped1Location = GetItemInfo(GetInventoryItemLink("player",pickedSlotID))
                 --if it's a trinket/ring you need to compare both
                if pickedSlotID == 11 or pickedSlotID == 13 or (IsDualWielding() and pickedSlotID == 16) then    
                    skip = false
                    --Print("Entering weapon dual wield",skip, pickedSlotID)
                    _, equipped2ItemLink, _, equipped2iLvl, _, _, _, equipped2Location = GetItemInfo(GetInventoryItemLink("player",pickedSlotID+1))
                end

                --debugPrint("Is it seeing an empty slot?", skip)
                if pickediLvl <= equipped1iLvl or (skip == false and pickediLvl <= equipped1iLvl and pickediLvl <= equipped2iLvl) then
                    self.acquiredTextFrame.text:SetText(self.lootLink)
                    local width = self.acquiredTextFrame.text:GetWidth()
                    local height = self.acquiredTextFrame.text:GetHeight()
                    --debugPrint("Width and Height of text for TTLF", width, height)
                    TrapTradeLootFrame.acquiredTextFrame:SetSize(width,height)
                    self:Show()
                    self.acquiredTextFrame:HookScript("OnEnter",function()
                        --debugPrint("On Enter Being Called. This is lootLink", TrapTradeLootFrame.lootLink)
                        if(TrapTradeLootFrame.lootLink ~= nil) then
                            GameTooltip:SetOwner(TrapTradeLootFrame.acquiredTextFrame.text, "ANCHOR_TOP")
                            GameTooltip:SetHyperlink(TrapTradeLootFrame.lootLink)
                            GameTooltip:Show()
                        end
                    end)
                    
                    TrapTradeLootFrame.acquiredTextFrame:HookScript("OnLeave",function()
                        GameTooltip:Hide()
                    end)
                end
            end
        end
    end
end)

TrapTradeLootFrame:OnLoad();

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
