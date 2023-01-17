local debug = false
local frame = CreateFrame("Frame")
local ninjaAlertMsg = "ES Ninja Warning: '$shitter$' is in this group."
local alertedFor = {}
local shitlist = {}
local _, EarthshakerNinjasData = ...
frame.defaults = {
    soundEnabled = true,
    alertsEnabled = true,
    nameplatesEnabled = true,
    tooltipEnabled = true,
    customNinjaText = "NINJA",
    defaultShitlist = {},
    customShitlist,
}

--#region Base64
-- http://lua-users.org/wiki/BaseSixtyFour

local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function ToBase64(data)
    data = table.concat(data, "|")
    return ((data:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r;
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

-- decoding
function FromBase64(data)
    data = string.gsub(data, '[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r:gsub("%z", ""):gsub("|", "\n");
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c):gsub("%z", ""):gsub("|", "\n")
    end))
end

--#endregion

--#region Helpers

function Log(text)
    if debug then print("DEBUG " .. date('%T') .. ": " .. text) end
end

function TableIsEmptyOrContainsOnlyNewlines(table)
    for i, v in ipairs(table) do
        if v ~= "\n" then -- check if current value is not a newline
            return false
        end
    end
end

function RemoveDuplicatesFromTable(tab)
    local hash = {}
    local res = {}
    for _, v in ipairs(tab) do
        if (not hash[v]) then
            res[#res + 1] = v
            hash[v] = true
        end
    end
    return res
end

--#endregion

--#region Import/Export

function ExportCustomShitlist()
    if ESNinjaDB.customShitlist == {} or TableIsEmptyOrContainsOnlyNewlines(ESNinjaDB.customShitlist) then
        message("Nothing to be exported, custom list is empty or contains only newlines.")
        return nil
    end
    return ToBase64(ESNinjaDB.customShitlist)
end

function ImportCustomShitlist(data)
    if data == "" then return end
    data = FromBase64(data)
    data = data .. "\n" .. table.concat(ESNinjaDB.customShitlist, "\n")
    ModifyCustomShitlist(data)
end

--#endregion


-- https://www.wowinterface.com/forums/showthread.php?t=55498
-- ketho is a fucking chad ngl
function KethoEditBox_Show(text, label, OnHide, frameName)
    local fName = frameName .. "EditBox"
    if not _G[fName] then
        local f = CreateFrame("Frame", fName, UIParent, "DialogBoxFrame")
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
        local sf = CreateFrame("ScrollFrame", (fName .. "ScrollFrame"), _G[fName], "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -16)
        sf:SetPoint("BOTTOM", _G[(fName .. "Button")], "TOP", 0, 0)

        -- EditBox
        local eb = CreateFrame("EditBox", (fName .. "EditBox"), _G[(fName .. "ScrollFrame")])
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(true) -- dont automatically focus
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)

        if OnHide then
            f:SetScript("OnHide", function()
                OnHide(_G[(fName .. "EditBox")]:GetText())
            end)
        end

        -- Resizable
        f:SetResizable(true)
        f:SetMinResize(150, 100)

        local rb = CreateFrame("Button", (fName .. "ResizeButton"), _G[fName])
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
        _G[(fName .. "EditBox")]:SetText(text)
    end
    _G[fName]:Show()
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

    splitNames = RemoveDuplicatesFromTable(splitNames)

    if table.getn(splitNames) > 0 then
        -- chatGPT saving me so much time its insane kekw

        local concatenated_list = {}
        for i, v in ipairs(splitNames) do
            v = string.gsub(string.lower(v), "^%l", string.upper)
            table.insert(concatenated_list, v)
        end
        for i, v in ipairs(shitlist) do
            v = string.gsub(string.lower(v), "^%l", string.upper)
            table.insert(concatenated_list, v)
        end
        -- Create an empty table to store unique elements
        local unique_list = {}

        -- Iterate through the concatenated list and add unique elements to the unique table
        for _, value in ipairs(concatenated_list) do
            if not unique_list[value] and not ESNinjaDB.customShitlist[value] then
                table.insert(unique_list, value)
            end
        end
        local t = {}
        for _, value in ipairs(unique_list) do
            if not tablefind(shitlist, value) then
                value = string.gsub(string.lower(value), "^%l", string.upper)
                table.insert(t, value)
            end
        end
        ESNinjaDB.customShitlist = t
    else
        ESNinjaDB.customShitlist = {}
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
    if ESNinjaDB.customNinjaText == "" or ESNinjaDB.customNinjaText == nil then
        ESNinjaDB.customNinjaText = self.defaults.customNinjaText
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

    local ninjaEditBoxBtn = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
    ninjaEditBoxBtn:SetPoint("TOPLEFT", 20, -180)
    ninjaEditBoxBtn:SetText("Edit custom ninja list")
    ninjaEditBoxBtn:SetSize(150, 35)
    ninjaEditBoxBtn:SetScript("OnClick", function()
        KethoEditBox_Show(GetNamesForEditShitlistText(), "Enter one name per line", ModifyCustomShitlist, "edit")
    end)

    local exportShitlistEditBtn = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
    exportShitlistEditBtn:SetPoint("TOPLEFT", 180, -180)
    exportShitlistEditBtn:SetText("Export")
    exportShitlistEditBtn:SetSize(150, 35)
    exportShitlistEditBtn:SetScript("OnClick", function()
        KethoEditBox_Show(ExportCustomShitlist(), "", nil, "export")
    end)

    local importShitlistEditBtn = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
    importShitlistEditBtn:SetPoint("TOPLEFT", 340, -180)
    importShitlistEditBtn:SetText("Import")
    importShitlistEditBtn:SetSize(150, 35)
    importShitlistEditBtn:SetScript("OnClick", function()
        KethoEditBox_Show("", "Paste exported data and click 'OK' (and pray that it works)", ImportCustomShitlist,
            "import")
    end)


    local ninjaEditBox = CreateFrame("EditBox", "NinjaEditBox", self.panel, "BackdropTemplate")
    ninjaEditBox:SetSize(150, 20)
    ninjaEditBox:SetPoint("TOPLEFT", 20, -240)

    ninjaEditBox:SetMultiLine(false)
    ninjaEditBox:SetAutoFocus(false) -- dont automatically focus

    ninjaEditBox:SetFontObject("ChatFontNormal")
    ninjaEditBox:SetTextInsets(10, 0, 0, 0)

    ninjaEditBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", -- this one is neat
        tile = false,
        tileSize = 20,
        edgeSize = 10,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    ninjaEditBox:SetBackdropBorderColor(1, 1, 1, 1) -- darkblue

    ninjaEditBox.Label = ninjaEditBox:CreateFontString(nil, "BORDER", "GameFontNormal")
    ninjaEditBox.Label:SetJustifyH("RIGHT")
    ninjaEditBox.Label:SetPoint("TOPLEFT", 3, 13)
    ninjaEditBox.Label:SetText("Custom Ninja text")

    ninjaEditBox:SetScript("OnEnterPressed", function()
        ninjaEditBox:ClearFocus()
        local text = ninjaEditBox:GetText()
        if text == "" then
            ninjaEditBox:SetText(ESNinjaDB.customNinjaText)
            return
        end
        ESNinjaDB.customNinjaText = text
        ninjaEditBox:SetText(text)
    end)
    ninjaEditBox:SetScript("OnEscapePressed", function()
        ninjaEditBox:ClearFocus()
        ninjaEditBox:SetText(ESNinjaDB.customNinjaText)
    end)
    ninjaEditBox:SetScript("OnEditFocusGained", function()
        ninjaEditBox:SetText("")
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
        GameTooltip:AddLine(ESNinjaDB.customNinjaText, 1, 0, 0)
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
        nameplate.frame.text:SetText(ESNinjaDB.customNinjaText)
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
    _G["NinjaEditBox"]:SetText(ESNinjaDB.customNinjaText)
    InterfaceOptionsFrame_OpenToCategory("ES Ninjas")
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("GROUP_LEFT")
GameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit)

RegisterNewSlashCommand(OpenSettings, "esn", "esninjas")
