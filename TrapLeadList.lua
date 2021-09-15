--[[Copyright (c) 2021, David Segal All rights reserved. Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. Neither the name of the addon nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

local function debugPrint(...)
    print(...);
end

TrapLeadList = CreateFrame("Frame",nil,UIParent)
local PREFIX = "TrapRaidRoller"
local MAX_LIST_SIZE = 6
--Size of loot frame
TrapLeadList.WIDTH = 450
TrapLeadList.HEIGHT = 330

--Starting position of loot frame
TrapLeadList.START_X = 1200
TrapLeadList.START_Y = -200


function TrapLeadList:OnLoad()
    TrapRaidRoller:setupMainFrame(self);
    TrapRaidRoller:setupMainSettings(self,"CHAT_MSG_ADDON");
    self.titleFrame = CreateFrame("Frame",nil,self);
    TrapRaidRoller:setupTitleFrame(self,"TRR Lead List");
    self:createMainButtons();    
end

function TrapLeadList:createMainButtons()
    --Exit Button
    self.exitButton = CreateFrame("Button",nil,self)
    TrapRaidRoller:setButtonTextures(self.exitButton,"Interface\\Buttons\\UI-Panel-MinimizeButton")
    self.exitButton:SetPoint("TOPRIGHT",self,"TOPRIGHT")
    self.exitButton:SetSize(30,30)
    self.exitButton:SetScript('OnClick', function()
        self:Hide()
    end)

    --Reset Button
    self.resetButton = CreateFrame("Button",nil,self)
    self.resetButton:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Undo")
    self.resetButton:SetPoint("TOPLEFT",self,"TOPLEFT",2.2,-2.5)
    self.resetButton:SetSize(18,18)
    self.resetButton:SetScript('OnClick', function()
        if self.playerLoot and #self.playerLoot > 0 then
            for k in pairs(self.playerLoot) do
                self.playerLoot[k] = nil
            end 
            self:updateVisual()
        end
    end)
end

--setup Scripts
TrapLeadList:SetScript("OnEvent",function(self,event,...)
    self.readyToRoll = true --Flag to check if it's been too soon to roll again
    if not IsInRaid() then
        return
    end
    if event == "CHAT_MSG_ADDON" then
        local receivedPrefix, text, _, sender = ...;
        sender = self:addServerName(sender) --COMPATABILITY: 2- has different senders
        if receivedPrefix ~= PREFIX then
            return --Early out: Not our addon talking
        end
        --Add something to the list
        if string.match(text, "add (.+)") then
            self:addLoot(sender,string.match(text, "add (.+)"))
            self:updateVisual()
            if (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) and not TrapRaidRollerHideRolloutFrame then
                self:Show()
            end
        end

        --A new roll is sent out
        if string.match(text, "roll (.+)") then
            --Prepare for roll stuff
            TrapRaidRoller:resetRolls();
            self.readyToRoll = false --Too soon to roll again

            --Get roll info to red out what was rolled
            if string.match(text, "roll TEXT_SENT_FROM_CHAT_LINE") then
                C_Timer.After(2, function() self.readyToRoll = true end)
                return
            end
            local rolledLoot, rolledPlayer = string.match(text, "roll (|c.+|r), (.+)") --TODO: START HERE
            self:changeRolledStatus(rolledLoot, rolledPlayer)
            self:updateVisual()
            
            --Allow rerolling after 2 seconds
            C_Timer.After(2, function() self.readyToRoll = true end)
            
        end
    end

end)

function TrapLeadList:addLoot(sender,loot)
    self.playerLoot = self.playerLoot or {}
    if #self.playerLoot >= 6 then
        table.remove(self.playerLoot,1)
    end
    table.insert(self.playerLoot, {["sender"] = sender, ["item"] = loot, ["rolled"] = "No"});
end

function TrapLeadList:changeRolledStatus(loot, player)
    self.playerLoot = self.playerLoot or {}
    for i = 1, #self.playerLoot, 1 do
        if loot == self.playerLoot[i].item and player == self.playerLoot[i].sender then
            self.playerLoot[i].rolled = "yes"
        end
    end
end

function TrapLeadList:updateVisual()
    self:createFrames()
    self:assignLoot()
end

function TrapLeadList:createFrames()
    self.listFrames = self.listFrames or {}
    self.buttonBackgrounds = self.buttonBackgrounds or {}
    self.rollButtons = self.rollButtons or {}
    if not self.playerLoot then
        return --Early out: Error no loot
    end

    --Create the frames, up to 8
    while #self.listFrames < #self.playerLoot and #self.listFrames < MAX_LIST_SIZE do
        self.listFrames[#self.listFrames + 1] = self:createListFrame()
        self.buttonBackgrounds[#self.buttonBackgrounds + 1] = self:createButtonBackground()
        self.rollButtons[#self.rollButtons + 1] = self:createRollButton()
        if #self.listFrames == 1 then
            self.listFrames[1]:SetPoint("TOP",self.titleFrame,"BOTTOMLEFT",55,0)
            self.buttonBackgrounds[1]:SetPoint("LEFT",self.listFrames[1],"RIGHT",0,0)
            self.rollButtons[1]:SetPoint("LEFT", self.buttonBackgrounds[1],"LEFT",0,-4)
        else
            self.listFrames[#self.listFrames]:SetPoint("TOP",self.listFrames[#self.listFrames-1],"BOTTOM",0,0)
            self.buttonBackgrounds[#self.buttonBackgrounds]:SetPoint("LEFT",self.listFrames[#self.listFrames],"RIGHT",0,0)
            self.rollButtons[#self.rollButtons]:SetPoint("LEFT",self.buttonBackgrounds[#self.buttonBackgrounds],"LEFT",0,-4)
        end
    end
end

function TrapLeadList:createListFrame()
    local listFrame = CreateFrame("Frame",nil,self)
    listFrame.nameString = listFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge",nil)
    listFrame.lootString = listFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge",nil)
    listFrame.nameString:SetPoint("LEFT",listFrame,"LEFT",5,0)
    listFrame.lootString:SetPoint("CENTER",listFrame,"CENTER",50,0)
    listFrame:SetSize(400,50)
    listFrame.Background = listFrame:CreateTexture(nil,"BACKGROUND")
    listFrame.Background:SetAllPoints(listFrame)
    return listFrame
end

function TrapLeadList:createButtonBackground()
    local buttonBackground = CreateFrame("Frame",nil,self)
    buttonBackground:SetSize(48,50)
    buttonBackground.Background = buttonBackground:CreateTexture(nil, "BACKGROUND")
    buttonBackground.Background:SetAllPoints(buttonBackground)
    return buttonBackground
end

function TrapLeadList:createRollButton()
    local rollButton = CreateFrame("Button",nil,self)
    TrapRaidRoller:setButtonTextures(rollButton,"Interface\\Buttons\\UI-GroupLoot-Dice")
    rollButton:SetSize(35,35)
    return rollButton
end

function TrapLeadList:assignLoot()
    --If there's no loot, hide everything
    if not self.playerLoot then
        return --Early out: No list
    end
    if next(self.playerLoot) == nil then
        for i = 1, #self.listFrames, 1 do
            self.listFrames[i]:Hide()
            self.buttonBackgrounds[i]:Hide()
            self.rollButtons[i]:Hide()
        end
        return
    end
    
    --Setup colors
    for i = 1, #self.playerLoot, 1 do
        if self.playerLoot[i].rolled == "yes" then
            self.listFrames[i].Background:SetColorTexture(0.2,0.1,0.1,0.85)
            self.buttonBackgrounds[i].Background:SetColorTexture(0.2,0.1,0.1,0.85)
        elseif i%2 == 0 then
            self.listFrames[i].Background:SetColorTexture(TrapRaidRollerLightColor[1],TrapRaidRollerLightColor[2],TrapRaidRollerLightColor[3],TrapRaidRollerLightColor[4])
            self.buttonBackgrounds[i].Background:SetColorTexture(TrapRaidRollerLightColor[1],TrapRaidRollerLightColor[2],TrapRaidRollerLightColor[3],TrapRaidRollerLightColor[4])
        else
            self.listFrames[i].Background:SetColorTexture(TrapRaidRollerDarkColor[1],TrapRaidRollerDarkColor[2],TrapRaidRollerDarkColor[3],TrapRaidRollerDarkColor[4]);
            self.buttonBackgrounds[i].Background:SetColorTexture(TrapRaidRollerDarkColor[1],TrapRaidRollerDarkColor[2],TrapRaidRollerDarkColor[3],TrapRaidRollerDarkColor[4]);
        end

        --For room, remove the server name from the visual part of the list
        local senderNoServer = self:removeServerName(self.playerLoot[i].sender)

        --Change text to item
        self.listFrames[i].nameString:SetText(senderNoServer)
        self.listFrames[i].lootString:SetText(self.playerLoot[i].item)

        --Create hover-over
        self.listFrames[i]:HookScript("OnEnter", function()
            GameTooltip:SetOwner(self.listFrames[i], "ANCHOR_TOP")
            GameTooltip:SetHyperlink(self.playerLoot[i].item)
            GameTooltip:Show()
        end)
        self.listFrames[i]:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        --Hook Roll button
        self.rollButtons[i]:SetScript("OnClick", function()
            if not self.readyToRoll then
                PlaySound(846)
            elseif IsInRaid() and (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) then
                local rollMessage, statMessage = TrapRaidRoller:getMessages(self.playerLoot[i].item)
                TrapRaidRoller:Show()
                SendChatMessage(rollMessage,"RAID_WARNING")
                SendChatMessage(statMessage,"RAID_WARNING")
                C_ChatInfo.SendAddonMessage(PREFIX,"roll " .. self.playerLoot[i].item .. ", " .. self.playerLoot[i].sender, "RAID")
        
            end
        end)
        self.listFrames[i]:Show()
        self.buttonBackgrounds[i]:Show()
        self.rollButtons[i]:Show()
    end


end

function TrapLeadList:addServerName(name)
    if string.match(name,"(.+-.+)") then
        return name --Early out: Already has the correct name type
    end
    --Otherwise they're on your server
    name = name .. "-" .. GetNormalizedRealmName()
    return name
end

function TrapLeadList:removeServerName(name)
    local noServerName = string.match(name,"(.+)-")
    if not noServerName then
        return name --The name already didn't have a server on it
    end

    return noServerName
end

TrapLeadList:OnLoad()
