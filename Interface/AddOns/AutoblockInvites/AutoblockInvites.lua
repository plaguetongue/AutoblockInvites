local AutoblockInvites = CreateFrame("Frame")
AutoblockInvites:RegisterEvent("PARTY_INVITE_REQUEST")
AutoblockInvites:RegisterEvent("WHO_LIST_UPDATE")
AutoblockInvites:RegisterEvent("ADDON_LOADED")
AutoblockInvites:RegisterEvent("PLAYER_LOGOUT")

AutoblockInvites.pendingInvite = nil

AutoblockInvites:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "AutoblockInvites" then
        if AutoblockDB == nil then
            AutoblockDB = { enabled = true, minLevel = 11, inviterCache = {} }
        end
        AutoblockInvites.inviterCache = AutoblockDB.inviterCache or {}
        AutoblockInvites:CreateOptionsPanel()
    elseif event == "PARTY_INVITE_REQUEST" then
        AutoblockInvites:HandleInviteRequest(...)
    elseif event == "PLAYER_LOGOUT" then
        AutoblockDB.inviterCache = AutoblockInvites.inviterCache
    elseif event == "WHO_LIST_UPDATE" then
        AutoblockInvites:CheckWhoList()
    end
end)

function AutoblockInvites:HandleInviteRequest(inviter)
    if not AutoblockDB.enabled then return end

    local level = AutoblockInvites.inviterCache[inviter]
    if not level then
        self.pendingInvite = inviter
        FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
        SetWhoToUI(1)
        SendWho("n-" .. inviter)
        FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
    else
        self:CheckInviteLevel(inviter, level)
    end
end

function AutoblockInvites:CheckInviteLevel(inviter, level)
    if level < AutoblockDB.minLevel then
        DeclineGroup()
        StaticPopup_Hide("PARTY_INVITE")
        print("Declined group invite from " .. inviter .. " (Level " .. level .. ")")
    end
end

function AutoblockInvites:CheckWhoList()
    if not self.pendingInvite then return end

    local numWhos, totalCount = GetNumWhoResults()
    for i = 1, numWhos do
        local name, _, level = GetWhoInfo(i)
        if name == self.pendingInvite then
            AutoblockInvites.inviterCache[name] = level
            self:CheckInviteLevel(name, level)
            self.pendingInvite = nil
            return
        end
    end

    self.pendingInvite = nil
end

function AutoblockInvites:CreateOptionsPanel()
    local panel = CreateFrame("Frame", "AutoblockInvitesPanel", UIParent)
    panel.name = "Autoblock Invites"
    InterfaceOptions_AddCategory(panel)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Autoblock Invites")

    local enableCheckbox = CreateFrame("CheckButton", "AutoblockEnableCheckbox", panel, "UICheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    _G[enableCheckbox:GetName() .. "Text"]:SetText("Enable/Disable addon")
    enableCheckbox:SetChecked(AutoblockDB.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        AutoblockDB.enabled = self:GetChecked()
    end)

    local slider = CreateFrame("Slider", "AutoblockLevelSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -20)
    slider:SetMinMaxValues(10, 70)
    slider:SetValueStep(1)
    slider:SetValue(AutoblockDB.minLevel)
    slider:SetWidth(200)

    slider:SetScript("OnValueChanged", function(self, value)
        AutoblockDB.minLevel = math.floor(value)
        slider.Text:SetText("Minimum Level: " .. AutoblockDB.minLevel)
    end)

    slider.Text = slider:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slider.Text:SetPoint("TOP", slider, "BOTTOM", 0, -5)
    slider.Text:SetText("Minimum Level: " .. AutoblockDB.minLevel)
end
