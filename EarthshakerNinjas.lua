local debug = false
local frame = CreateFrame("Frame")
local ninjaText = "NINJA"
local ninjaAlertMsg = "ES Ninja Warning: '$shitter$' is in this group."
local alertedFor = {}
local shitlist = {}
local _, EarthshakerNinjasData = ...
function Log(text)
    if debug then print("DEBUG " .. date('%T') .. ": " .. text) end
end

frame.defaults = {
    soundEnabled = true,
    alertsEnabled = true,
    nameplatesEnabled = true,
    tooltipEnabled = true,
    defaultShitlist = {},
    customShitlist,
}

-- https://www.wowinterface.com/forums/showthread.php?t=55498
-- ketho is a fucking chad ngl
function KethoEditBox_Show(text, label)
    if not KethoEditBox then
        local f = CreateFrame("Frame", "KethoEditBox", UIParent, "DialogBoxFrame")
        f:SetPoint("CENTER")
        f:SetSize(600, 500)

        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
            edgeSize = 16,
            insets = { left = 8, right = 6, top = 8, bottom = 8 },
        })
        f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue

        -- Movable
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self:StartMoving()
            end
        end)
        f:SetScript("OnMouseUp", f.StopMovingOrSizing)

        -- ScrollFrame
        local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame", KethoEditBox, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -16)
        sf:SetPoint("BOTTOM", KethoEditBoxButton, "TOP", 0, 0)

        -- EditBox
        local eb = CreateFrame("EditBox", "KethoEditBoxEditBox", KethoEditBoxScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(true) -- dont automatically focus
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)

        f:SetScript("OnHide", function()
            ModifyCustomShitlist(_G["KethoEditBoxEditBox"]:GetText())
        end)

        -- Resizable
        f:SetResizable(true)
        f:SetMinResize(150, 100)

        local rb = CreateFrame("Button", "KethoEditBoxResizeButton", KethoEditBox)
        rb:SetPoint("BOTTOMRIGHT", -6, 7)
        rb:SetSize(16, 16)

        rb:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        rb:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        rb:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

        rb:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                f:StartSizing("BOTTOMRIGHT")
                self:GetHighlightTexture():Hide() -- more noticeable
            end
        end)
        rb:SetScript("OnMouseUp", function(self, button)
            f:StopMovingOrSizing()
            self:GetHighlightTexture():Show()
            eb:SetWidth(sf:GetWidth())
        end)
        if label then
            f.Label = f:CreateFontString(nil, "BORDER", "GameFontNormal")
            f.Label:SetJustifyH("CENTER")
            f.Label:SetPoint("CENTER", f, "TOP")
            f.Label:SetTextColor(1, 0, 0)
            f.Label:SetText(label)
        end
        f:Show()
    end
    if text then
        KethoEditBoxEditBox:SetText(text)
    end
    KethoEditBox:Show()
end

function TableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function GetNamesForEditShitlistText()
    Log("Getting custom shitlist")
    if not ESNinjaDB.customShitlist then
        return ""
    end
    return table.concat(ESNinjaDB.customShitlist, "\n")
end

function ModifyCustomShitlist(names)
    if names == "" or names == "\n" then ESNinjaDB.customShitlist = {}; return end
    Log("Adding name to shitlist")

    local splitNames = { strsplit("\n", names) }

    -- remove empty lines
    for i = #splitNames, 1, -1 do
        if splitNames[i] == " " or splitNames[i] == "" or splitNames[i] == "\n" or splitNames[i] == "\r\n" then
            table.remove(splitNames, i)
        end
    end

    if table.getn(splitNames) > 0 then
        ESNinjaDB.customShitlist = splitNames
    end
end

function frame:InitializeOptions()
    Log("Initializing ESN")
    self.panel = CreateFrame("Frame")
    self.panel.name = "ES Ninjas"
    ESNinjaDB.defaultShitlist = shitlist
    if not ESNinjaDB.customShitlist and not ESNinjaDB.customShitlist == {} then
        ESNinjaDB.customShitlist = self.defaults.customShitlist
    end


    local soundCb = CreateFrame("CheckButton", nil, self.panel, "InterfaceOptionsCheckButtonTemplate")
    soundCb:SetPoint("TOPLEFT", 20, -20)
    soundCb.Text:SetText("Enable sound alerts")
    soundCb:SetScript("OnClick", function()
        ESNinjaDB.soundEnabled = not ESNinjaDB.soundEnabled
    end)
    soundCb:SetChecked(ESNinjaDB.soundEnabled) -- set the initial checked state


    local textAlertCb = CreateFrame("CheckButton", nil, self.panel, "InterfaceOptionsCheckButtonTemplate")
    textAlertCb:SetPoint("TOPLEFT", 20, -60)
    textAlertCb.Text:SetText("Enable text alerts")
    textAlertCb:SetScript("OnClick", function()
        ESNinjaDB.alertsEnabled = not ESNinjaDB.alertsEnabled
    end)
    textAlertCb:SetChecked(ESNinjaDB.alertsEnabled) -- set the initial checked state

    local nameplateCb = CreateFrame("CheckButton", nil, self.panel, "InterfaceOptionsCheckButtonTemplate")
    nameplateCb:SetPoint("TOPLEFT", 20, -100)
    nameplateCb.Text:SetText("Enable nameplate mark")
    nameplateCb:SetScript("OnClick", function()
        ESNinjaDB.nameplatesEnabled = not ESNinjaDB.nameplatesEnabled
    end)
    nameplateCb:SetChecked(ESNinjaDB.nameplatesEnabled) -- set the initial checked state

    local tooltipCb = CreateFrame("CheckButton", nil, self.panel, "InterfaceOptionsCheckButtonTemplate")
    tooltipCb:SetPoint("TOPLEFT", 20, -140)
    tooltipCb.Text:SetText("Enable tooltip text")
    tooltipCb:SetScript("OnClick", function()
        ESNinjaDB.tooltipEnabled = not ESNinjaDB.tooltipEnabled
    end)
    tooltipCb:SetChecked(ESNinjaDB.tooltipEnabled) -- set the initial checked state

    local shitlistEditBoxBtn = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
    shitlistEditBoxBtn:SetPoint("TOPLEFT", 20, -180)
    shitlistEditBoxBtn:SetText("Edit custom ninja list")
    shitlistEditBoxBtn:SetSize(150, 35)
    shitlistEditBoxBtn:SetScript("OnClick", function()
        KethoEditBox_Show(GetNamesForEditShitlistText(), "Enter one name per line")
    end)

    InterfaceOptions_AddCategory(self.panel)
    if not EarthshakerNinjasData.ESN_DATA_SHITLIST then
        shitlist = {};
    else
        shitlist = EarthshakerNinjasData.ESN_DATA_SHITLIST
    end
end

-- Sets tooltip line
function OnTooltipSetUnit(unit)
    if not ESNinjaDB.tooltipEnabled then return end
    local _, u = unit:GetUnit()
    if isInAnyShitlist(u) then
        GameTooltip:AddLine(ninjaText, 1, 0, 0)
        GameTooltip:Show()
    end
end

function tablefind(tab, el)
    for index, value in pairs(tab) do
        if value == el then
            return index
        end
    end
end

function isInAnyShitlist(unitID)
    return tablefind(shitlist, UnitName(unitID)) or tablefind(ESNinjaDB.customShitlist, UnitName(unitID))
end

function createFrameForNameplate(nameplate)
    if not nameplate.frame then
        nameplate.frame = CreateFrame("Frame", nil, nameplate)
        nameplate.frame:SetWidth(10)
        nameplate.frame:SetHeight(10)
        nameplate.frame:SetAlpha(1)
        nameplate.frame:SetPoint("CENTER", 0, 25)
        nameplate.frame.text = nameplate.frame:CreateFontString(nil, "ARTWORK")
        nameplate.frame.text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
        nameplate.frame.text:SetPoint("CENTER", 0, 0)
        nameplate.frame.text:SetText(ninjaText)
        nameplate.frame.text:SetTextColor(1, 0, 0)
    end
    nameplate.frame:Show()
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "EarthshakerNinjas" then
            if ESNinjaDB == nil then
                ESNinjaDB = CopyTable(self.defaults)
            end
            self:InitializeOptions()
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if not ESNinjaDB.nameplatesEnabled then return end
        local unitID = ...
        if isInAnyShitlist(unitID) then
            local nameplate = C_NamePlate.GetNamePlateForUnit(unitID)
            createFrameForNameplate(nameplate)
        end

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unitID = ...
        local nameplate = C_NamePlate.GetNamePlateForUnit(unitID)
        if nameplate and nameplate.frame then
            nameplate.frame:Hide()
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        if not ESNinjaDB.soundEnabled and not ESNinjaDB.alertsEnabled then return end
        local numMembers = GetNumGroupMembers()
        if numMembers == 0 then return end

        local chatType
        local unit

        if UnitInRaid("player") == 1 then
            unit = "raid"
            chatType = "RAID"
        else
            unit = "party"
            chatType = "PARTY"
        end

        local localRoster = {}

        for i = 1, numMembers do
            local unitID = "" .. unit .. i .. ""
            local unitName = UnitName(unitID)
            if unitName then
                -- add to local roster if not already present
                if not tablefind(localRoster, unitName) then table.insert(localRoster, unitName) end

                if isInAnyShitlist(unitID) then
                    if not tablefind(alertedFor, unitName) then
                        local msg = ninjaAlertMsg:gsub("%$shitter%$", unitName)
                        if ESNinjaDB.soundEnabled then PlaySound(8959, "Master") end
                        if ESNinjaDB.alertsEnabled then SELECTED_CHAT_FRAME:AddMessage(msg, 1, 0, 0) end
                        table.insert(alertedFor, unitName)
                    end
                end
            end
        end

        -- clear name from alerts when ninja has left raid/group
        for j = 1, table.getn(alertedFor) do
            local alertedName = alertedFor[j]
            if not tablefind(localRoster, alertedName) then
                table.remove(alertedFor, j)
            end
        end

        -- clear all when player leaves group
        if not IsInGroup() then
            alertedFor = {}
        end
    end
end)

function OpenSettings(msg, editBox)
    InterfaceOptionsFrame_Show()
    InterfaceOptionsFrame_OpenToCategory("ES Ninjas")
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("GROUP_LEFT")
GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)

RegisterNewSlashCommand(OpenSettings, "esn", "esninjas")
