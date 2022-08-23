--[[Copyright (c) 2021, David Segal All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. Neither the name of the addon nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

local function debugPrint(...)
    print(...)
end

TrapTradeLoot = CreateFrame("Frame",nil,UIParent)
PREFIX = "TrapRaidRoller"

--Size of trade frame
TrapTradeLoot.WIDTH = 210
TrapTradeLoot.HEIGHT = 100

--Starting position of trade frame
TrapTradeLoot.START_X = 0
TrapTradeLoot.START_Y = 0

--Other Constants
local minimumQuality = 4 --4 is Epic

function TrapTradeLoot:OnLoad()
    self:setupFrame()
    self:setupSettings()
    self.textFrame = CreateFrame("Frame",nil,self)
    self.lootFrame = CreateFrame("Frame",nil,self)
    self:setupTextFrame(self.textFrame)
    self:setupLootFrame(self.lootFrame)
    self:setupButtons()
    self:setupMainScripts()
end

function TrapTradeLoot:setupFrame()
    self:SetSize(self.WIDTH, self.HEIGHT)
    self:SetPoint("CENTER", UIParent, "CENTER", self.START_X, self.START_Y)
    self.Background = self:CreateTexture(nil,"DIALOGUE")
    self.Background:SetAllPoints(self)
    self.Background:SetColorTexture(TrapRaidRoller.BACKGROUND_COLORS[1],TrapRaidRoller.BACKGROUND_COLORS[2],TrapRaidRoller.BACKGROUND_COLORS[3])
end

function TrapTradeLoot:setupSettings()
    self:RegisterEvent("CHAT_MSG_LOOT")
    self:RegisterEvent("TRADE_ACCEPT_UPDATE")
    self:RegisterEvent("UI_INFO_MESSAGE")
    self:Hide()
end

function TrapTradeLoot:setupTextFrame(frame)
    frame:SetPoint("TOP",self,"TOP")
    frame:SetSize(210,40)
    frame.text = self.textFrame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    frame.text:SetPoint("TOP",self.textFrame,"TOP",0,-5)
    frame.text:SetText("Do you want to let Raid Assists\nknow to roll out this item?")
end

function TrapTradeLoot:setupLootFrame(frame)
    frame:SetPoint("TOP",self.textFrame,"BOTTOM",0,0)
    frame.text = self.lootFrame:CreateFontString(nil,"ARTWORK","GameFontNormal",nil)
    frame.text:SetPoint("TOP",self.lootFrame,"CENTER",0,10)
    frame:EnableMouse(false)
end

function TrapTradeLoot:setupButtons()
    self:setupCheckmark()
    self:setupxMark()
    
end

function TrapTradeLoot:setupCheckmark()
    self.checkmark = CreateFrame("Button",nil,self)
    self.checkmark:SetNormalTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    self.checkmark:SetPoint("BOTTOMLEFT",self,"BOTTOMLEFT",40,10)
    self.checkmark:SetSize(30,30)
end

function TrapTradeLoot:setupxMark()
    self.xMark = CreateFrame("Button",nil,self)
    self.xMark:SetNormalTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    self.xMark:SetPoint("BOTTOMRIGHT",self,"BOTTOMRIGHT",-40,10)
    self.xMark:SetSize(30,30)
end

function TrapTradeLoot:setupMainScripts()
    self:SetScript("OnEvent", function (self,event,...)
        self:setupLootScripts(event,...)
        self:setupTradeUpdaterScript(event,...)
    end)
end

function TrapTradeLoot:setupLootScripts(event,...)
    if event ~= "CHAT_MSG_LOOT" and event~="UI_INFO_MESSAGE" then
        return --Early out: Not the right event
    end
    if TrapRaidRollerHidePickupFrame then
        return --User doesn't want this to show
    end
    if not IsInRaid() then
        return --Early out: Not in raid
    end
    
    self:setupPickupScript(event,...)
    self:setupTradedScript(event,...)
end

function TrapTradeLoot:setupPickupScript(event,...)
    if event ~= "CHAT_MSG_LOOT" then
        return --Early out: Not right event
    end
    local text = ...;
    local pickedUpLoot = string.match(text, "You receive loot: (.+|r)")
    if not pickedUpLoot then
        return --Early out: No picked up loot
    end
    if not IsEquippableItem(pickedUpLoot) then
        return --Early out: Not equippable loot
    end
    if not self:checkIfGoodQuality(pickedUpLoot) then
        return --Early out: loot isn't high enough quality
    end

    local itemIsLoweriLvl, checkSecondSlotFlag = self:compareLootToEquipped(pickedUpLoot)
    if itemIsLoweriLvl and checkSecondSlotFlag then
        itemIsLoweriLvl = self:compareLootToSecond(pickedUpLoot)
    end

    if itemIsLoweriLvl then
        self:editLootFrameForItem(pickedUpLoot)
        self:editButtonsForItem(pickedUpLoot,false)
        self:Show()
    end
end

function TrapTradeLoot:checkIfGoodQuality(item)
    local _,_,itemQuality = GetItemInfo(item)
    if itemQuality >= minimumQuality then
        return true
    end

    return false
end

function TrapTradeLoot:compareLootToEquipped(loot)
    local _,_,_,acquirediLvl,_,  _,_,_,acquiredLocation = GetItemInfo(loot)
    local acquiredSlotID = self:getItemSlotID(acquiredLocation)
    local _,_,_,equippediLvl,_,  _,_,_,equippedLocation = GetItemInfo(GetInventoryItemLink("player",acquiredSlotID))
    local checkSecondSlotFlag = self:checkIfSecondSlot(loot,acquiredLocation,equippedLocation)

    local equippedItemIsBetter
    if acquirediLvl > equippediLvl then
        equippedItemIsBetter = false
    else
        equippedItemIsBetter = true
    end

    return equippedItemIsBetter, checkSecondSlotFlag
end

function TrapTradeLoot:getItemSlotID(location)
    if location == "INVTYPE_HEAD" then
        return 1
    elseif location == "INVTYPE_NECK" then
        return 2
    elseif location == "INVTYPE_SHOULDER" then
        return 3
    elseif location == "INVTYPE_BODY" then
        return 4
    elseif location == "INVTYPE_CHEST" then
        return 5
    elseif location == "INVTYPE_WAIST" then
        return 6
    elseif location == "INVTYPE_LEGS" then
        return 7
    elseif location == "INVTYPE_FEET" then
        return 8
    elseif location == "INVTYPE_WRIST" then
        return 9
    elseif location == "INVTYPE_HAND" then
        return 10
    elseif location == "INVTYPE_FINGER" then
        return 11 --Remember to check 12 for second ring
    elseif location == "INVTYPE_TRINKET" then
        return 13 --Remember to check 14 for other trinket
    elseif location == "INVTYPE_WEAPON" then
        return 16 --Remember to check 17 if needed
    elseif location == "INVTYPE_SHIELD" then
        return 17
    elseif location == "INVTYPE_RANGED" then
        return 16
    elseif location == "INVTYPE_CLOAK" then
        return 15
    elseif location == "INVTYPE_2HWEAPON" then
        return 16
    elseif location == "INVTYPE_TABARD" then
        return 19
    elseif location == "INVTYPE_ROBE" then
        return 5
    elseif location == "INVTYPE_WEAPONMAINHAND" then
        return 16
    elseif location == "INVTYPE_WEAPONOFFHAND" then
        return 16
    elseif location == "INVTYPE_HOLDABLE" then
        return 17
    elseif location == "INVTYPE_RANGEDRIGHT" then
        return 16
    end
end

function TrapTradeLoot:checkIfSecondSlot(loot,acquiredLocation, equippedLocation)
    if acquiredLocation == "INVTYPE_FINGER" or acquiredLocation == "INVTYPE_TRINKET" then
        return true --Early out: Always return true for finger/trinkets
    end
    if not TrapRaidRoller:checkIfWeapon(loot) then
        return false --Early out: Not a weapon and not finger/trinket? Doesn't need second
    end

    if equippedLocation == "INVTYPE_2HWEAPON" or equippedLocation == "INVTYPE_RANGED" then
        return false --Don't need to check if it's a two handed weapon/ranged weapon (since they take up two slots)
    end

    return true
end

function TrapTradeLoot:compareLootToSecond(loot)
    local _,_,_,acquirediLvl,_, _,_,_,acquiredLocation = GetItemInfo(loot)
    local acquiredSlotID = self:getItemSlotID(acquiredLocation)
    local _,_,_,equippediLvl = GetItemInfo(GetInventoryItemLink("player",acquiredSlotID+1))

    local equippedItemIsBetter
    if acquirediLvl > equippediLvl then
        equippedItemIsBetter = false
    else
        equippedItemIsBetter = true
    end

    return equippedItemIsBetter
end

function TrapTradeLoot:editLootFrameForItem(item)
    self.lootFrame.text:SetText(item)
    local width = self.lootFrame.text:GetWidth()
    local height = self.lootFrame.text:GetHeight()
    self.lootFrame:SetSize(width,height)
    self.lootFrame:HookScript("OnEnter", function()
        GameTooltip:SetOwner(self.lootFrame.text,"ANCHOR_TOP")
        GameTooltip:SetHyperlink(item)
        GameTooltip:Show()
    end)
    self.lootFrame:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function TrapTradeLoot:editButtonsForItem(item,fromList)
    self:setCheckmarkScript(item,fromList)
    self:setxMarkScript(fromList)
end

function TrapTradeLoot:setCheckmarkScript(item,fromList)
    self.checkmark:SetScript("OnClick", function()
        C_ChatInfo.SendAddonMessage(PREFIX, "add " .. item, "RAID")
        if fromList then
            table.remove(self.tradedTable,1)
        end
        self:Hide()
        self.tradedTable = self.tradedTable or {}
        if #self.tradedTable > 0 then
            self:editLootFrameForItem(self.tradedTable[1].item)
            self:editButtonsForItem(self.tradedTable[1].item,true)
            self:Show()
        end
    end)
end

function TrapTradeLoot:setxMarkScript(fromList)
    self.xMark:SetScript("OnClick", function()
        if fromList and self.tradedTable then
            table.remove(self.tradedTable,1)
        end
        self:Hide()
        if self.tradedTable and #self.tradedTable > 0 then
            self:editLootFrameForItem(self.tradedTable[1].item)
            self:editButtonsForItem(self.tradedTable[1].item,true)
            self:Show()
        end
    end)
end

function TrapTradeLoot:setupTradedScript(event,...)
    if event ~= "UI_INFO_MESSAGE" then
        return --Early out: Not right event
    end
    local errorType, message = ...;
    if errorType ~= 229 then --Trade Complete
        return --Early out: Not right ui message
    end
    self.items = self.items or {}
    local isInList = false
    local itemAddedToQueue = false
    for i = 1, #self.items, 1 do

        if self.items[i] and IsEquippableItem(self.items[i]) and self:checkIfGoodQuality(self.items[i]) then
            isInList = false
            if TrapLeadList.playerLoot then
                isInList = self:checkIfInList(self.items[i])
            end
            if not isInList then
                self.tradedTable = self.tradedTable or {}
                table.insert(self.tradedTable, {["name"] = self.tradedFrom, ["item"] = self.items[i]})
                itemAddedToQueue = true
            end
        end
    end
    if itemAddedToQueue and not self:IsVisible() then
        self:editLootFrameForItem(self.tradedTable[1].item)
        self:editButtonsForItem(self.tradedTable[1].item,true)
        self:Show()
    end
end

function TrapTradeLoot:checkIfInList(item)
    for i = 1, #TrapLeadList.playerLoot, 1 do
        if item == TrapLeadList.playerLoot[i].item and self.tradedFrom == TrapLeadList.playerLoot[i].sender then
            return true
        end
    end

    return false
end

function TrapTradeLoot:setupTradeUpdaterScript(event,...)
    if not IsInRaid() then
        return --Early out: Not in a raid
    end
    if not (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) then
        return --Early out: User is not leadership
    end
    if event ~= "TRADE_ACCEPT_UPDATE" then
        return --Early out: Not the right event
    end
    if TrapRaidRollerHidePickupFrame then
        return --Early out: User opted out of this frame appearing
    end

    local playerAccepted, targetAccepted = ...;

    if playerAccepted ~= 1 then
        return --Early out: Only trigger when player accepted the trade
    end

    local tradedFrom = GetUnitName("NPC",true)
    tradedFrom = TrapLeadList:addServerName(tradedFrom)
    self.tradedFrom = tradedFrom
    self.items = {}
    self.items[1] = GetTradeTargetItemLink(1)
    self.items[2] = GetTradeTargetItemLink(2)
    self.items[3] = GetTradeTargetItemLink(3)
    self.items[4] = GetTradeTargetItemLink(4)
    self.items[5] = GetTradeTargetItemLink(5)
    self.items[6] = GetTradeTargetItemLink(6)
end

TrapTradeLoot:OnLoad()