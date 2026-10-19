-- ============================================================================
-- SILNIK RAMEK ODLICZANIA DBM (WoW 3.3.5) - DBM-CustomAlertsSignsis.lua
-- ============================================================================

DBM.DefaultOptions = DBM.DefaultOptions or {}
DBM.DefaultOptions.CustomAlertFontSize        = 20
DBM.DefaultOptions.CustomAlertPosY            = 110
DBM.DefaultOptions.CustomAlertPosX            = 0
DBM.DefaultOptions.CustomAlertEnable          = true
DBM.DefaultOptions.CustomAlertShowRightIcon   = false
DBM.DefaultOptions.CustomAlertFont            = "Fonts\\FRIZQT__.TTF"
DBM.DefaultOptions.CustomAlertFontFlags       = "OUTLINE"
DBM.DefaultOptions.CustomAlertThreshold       = 5
DBM.DefaultOptions.CustomAlertTextColor       = { r = 1, g = 0.8, b = 0 }
DBM.DefaultOptions.CustomAlertTimerColor      = { r = 1, g = 1, b = 1 }

DBM.DefaultOptions.CustomAlertSoundFolder     = "Interface\\AddOns\\DBM-VPVEM\\countsignsis\\"
DBM.DefaultOptions.CustomAlertSoundExt        = ".ogg"

-- BAZA USTAWIEŃ KOLORYSTYCZNYCH DLA POSZCZEGÓLNYCH CZARÓW:
DBM.DefaultOptions.CustomAlertOverrides = {
    ["Itchy Spores"] = {
        textColor   = { r = 1, g = 0.61, b = 0 },
        timerColor  = { r = 1, g = 1, b = 1 },
    },
    ["Decimate"] = {
        textColor   = { r = 1, g = 0.82, b = 0 },
        timerColor  = { r = 1, g = 1, b = 1 },
    },
    ["Locust Swarm"] = {
        textColor   = { r = 0, g = 1, b = 0 },
        timerColor  = { r = 1, g = 1, b = 1 },
    },
    ["Web Spray"] = {
        textColor   = { r = 1, g = 0.61, b = 0 },
        timerColor  = { r = 1, g = 1, b = 1 },
    },
    ["Spiderlings"] = {
        textColor   = { r = 0.2, g = 0.6, b = 1 },
        timerColor  = { r = 1, g = 1, b = 1 },
    },
    --["Teleport"] = {
    --    textColor   = { r = 1, g = 0.8, b = 0 },
    --    timerColor  = { r = 1, g = 1, b = 1 },
    --},
    ["Frenzy"] = {
        textColor   = { r = 1, g = 0.88, b = 0 },
        timerColor  = { r = 1, g = 1, b = 1 },
    },
	["Static Field"] = {
        textColor   = { r = 1, g = 0.88, b = 0 },
        timerColor  = { r = 1, g = 1, b = 1 },
    }
}

local alertFrame = CreateFrame("Frame", "DBMCustomAlertFrame", UIParent)
alertFrame:SetSize(200, 22)
alertFrame:Hide()

local alertTexture = alertFrame:CreateTexture(nil, "BACKGROUND")
alertTexture:SetPoint("LEFT", alertFrame, "LEFT", 0, 0)

local alertLabel = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
alertLabel:SetPoint("LEFT", alertTexture, "RIGHT", 6, 0)

local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
alertText:SetPoint("LEFT", alertLabel, "RIGHT", 4, 0)

local alertRightTexture = alertFrame:CreateTexture(nil, "BACKGROUND")
alertRightTexture:SetPoint("LEFT", alertText, "RIGHT", 6, 0)

local alertEndTime = 0
local isActive = false
local fadeDuration = 0.3
local activeTimerColor = { r = 1, g = 1, b = 1 }
local activeTextColor  = { r = 1, g = 0.8, b = 0 }
local activeSoundFolder = "Interface\\AddOns\\DBM-VPVEM\\countsignsis\\"
local activeSoundExt    = ".ogg"
local activePlaySound   = false
local holdOnZeroState = false
local soundsPlayed = { [5] = false, [4] = false, [3] = false, [2] = false, [1] = false }
local baseAlertWidth = 0
local updateThrottle = 0

function DBM:UpdateCustomAlertFont()
    local fontSize  = DBM.Options.CustomAlertFontSize or 16
    local fontPath  = DBM.Options.CustomAlertFont or "Fonts\\FRIZQT__.TTF"
    local fontFlags = DBM.Options.CustomAlertFontFlags or "OUTLINE"

    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and LSM:IsValid("font", fontPath) then
        fontPath = LSM:Fetch("font", fontPath)
    end

    if fontFlags == "NONE" or fontFlags == "" then 
        fontFlags = nil 
    end

    alertLabel:SetFont(fontPath, fontSize, fontFlags)
    alertText:SetFont(fontPath, fontSize, fontFlags)

    local iconSize = fontSize + 4
    alertTexture:SetSize(iconSize, iconSize)
    alertRightTexture:SetSize(iconSize, iconSize)
    alertFrame:SetHeight(iconSize)

    local showRightIcon = DBM.Options.CustomAlertShowRightIcon
    baseAlertWidth = iconSize + 6 + alertLabel:GetStringWidth() + 4
    if showRightIcon then
        baseAlertWidth = baseAlertWidth + 6 + iconSize
        alertRightTexture:Show()
    else
        alertRightTexture:Hide()
    end
end

alertFrame:SetScript("OnUpdate", function(self, elapsed)
    if not isActive then return end

    local remaining = alertEndTime - GetTime()
    local threshold = DBM.Options.CustomAlertThreshold or 5

    if remaining > 0 then
        if remaining <= threshold then
            local timePassed = threshold - remaining
            local alpha = math.min(1, math.max(0, timePassed / fadeDuration))

            alertFrame:SetAlpha(alpha)

            updateThrottle = updateThrottle + elapsed
            if updateThrottle >= 0.05 then
                updateThrottle = 0
                alertText:SetFormattedText("%.1f", remaining)
                alertFrame:SetWidth(baseAlertWidth + alertText:GetStringWidth())
            end

            if activePlaySound == true then
                for sec = 3, 1, -1 do      -- zmiana odliczania SIGNSIS
                    if sec <= threshold and remaining <= sec and not soundsPlayed[sec] then
                        soundsPlayed[sec] = true
                        local soundFilePath = activeSoundFolder .. sec .. activeSoundExt
                        PlaySoundFile(soundFilePath, "Master")
                        break
                    end
                end
            end
        else
            alertFrame:SetAlpha(0)
        end
    else
        if holdOnZeroState then
            alertFrame:SetAlpha(1)
            alertText:SetText("Ready")
            alertFrame:SetWidth(baseAlertWidth + alertText:GetStringWidth())
        else
            alertFrame:Hide()
            alertFrame:SetAlpha(0)
            isActive = false
        end
    end
end)

function DBM:ShowCustomAlert(icon, text, duration, holdOnZero, playSoundOverride)
    if not DBM.Options.CustomAlertEnable then return end
    if not duration or duration <= 0 then return end

    local cleanText = (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local overrides = DBM.Options.CustomAlertOverrides or {}
    local customRule = overrides[cleanText]

    if customRule then
        activeTextColor   = customRule.textColor or DBM.Options.CustomAlertTextColor or { r = 1, g = 0.8, b = 0 }
        activeTimerColor  = customRule.timerColor or DBM.Options.CustomAlertTimerColor or { r = 1, g = 1, b = 1 }
        activeSoundFolder = customRule.soundFolder or DBM.Options.CustomAlertSoundFolder or "Interface\\AddOns\\DBM-VPVEM\\countsignsis\\"
        activeSoundExt    = customRule.soundExt or DBM.Options.CustomAlertSoundExt or ".ogg"
    else
        activeTextColor   = DBM.Options.CustomAlertTextColor or { r = 1, g = 0.8, b = 0 }
        activeTimerColor  = DBM.Options.CustomAlertTimerColor or { r = 1, g = 1, b = 1 }
        activeSoundFolder = DBM.Options.CustomAlertSoundFolder or "Interface\\AddOns\\DBM-VPVEM\\countsignsis\\"
        activeSoundExt    = DBM.Options.CustomAlertSoundExt or ".ogg"
    end

    -- Dźwięk zagra TYLKO wtedy, gdy moduł bossa przekazał bezpośrednio true
    if playSoundOverride == true then
        activePlaySound = true
    else
        activePlaySound = false
    end

    holdOnZeroState = holdOnZero or false
    
    soundsPlayed = { [5] = false, [4] = false, [3] = false, [2] = false, [1] = false }
    for i = 1, 5 do
        if duration < i then
            soundsPlayed[i] = true
        end
    end

    local posX = DBM.Options.CustomAlertPosX or 0
    local posY = DBM.Options.CustomAlertPosY or 100

    alertFrame:ClearAllPoints()
    alertFrame:SetPoint("CENTER", UIParent, "CENTER", posX, posY)

    local iconTex = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
    alertTexture:SetTexture(iconTex)
    alertRightTexture:SetTexture(iconTex)

    alertLabel:SetText(cleanText)
    alertLabel:SetTextColor(activeTextColor.r, activeTextColor.g, activeTextColor.b)
    alertText:SetTextColor(activeTimerColor.r, activeTimerColor.g, activeTimerColor.b)

    DBM:UpdateCustomAlertFont()

    updateThrottle = 0.05
    alertEndTime = GetTime() + duration
    isActive = true
    alertFrame:SetAlpha(0)
    alertFrame:Show()
end

function DBM:HideCustomAlert()
    alertFrame:Hide()
    alertFrame:SetAlpha(0)
    isActive = false
    holdOnZeroState = false
end

function DBM:ShowCustomAlertTest()
    local threshold = DBM.Options.CustomAlertThreshold or 5
    self:ShowCustomAlert("Interface\\AddOns\\DBM-VPVEM\\Icons\\LoathebSporeSignsis", "Itchy Spores", threshold, nil, false)
end

-- ============================================================================
-- GUI & KONTROLKI
-- ============================================================================

local function CreateSliderControl(parent, name, title, minVal, maxVal, step, defaultVal, posX, posY, callback, width)
    local ctrlWidth = width or 205
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", posX, posY)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetWidth(ctrlWidth)
    slider:SetValue(defaultVal)

    local titleText = _G[name .. "Text"]
    local lowText   = _G[name .. "Low"]
    local highText  = _G[name .. "High"]

    if lowText then lowText:SetText(tostring(minVal)) end
    if highText then highText:SetText(tostring(maxVal)) end
    if titleText then titleText:SetText(title .. ": " .. defaultVal) end

    slider:SetScript("OnValueChanged", function(self, val)
        local value = math.floor(val)
        if titleText then titleText:SetText(title .. ": " .. value) end
        callback(value)
    end)
    return slider
end

local function CreateColorPickerControl(parent, name, title, currentVal, posX, posY, callback, width)
    local ctrlWidth = width or 180
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", posX, posY)
    label:SetText(title)

    local btn = CreateFrame("Button", name, parent, "UIMenuButtonStretchTemplate")
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", posX, posY - 14)
    btn:SetSize(ctrlWidth, 20)

    local swatch = btn:CreateTexture(nil, "OVERLAY")
    swatch:SetSize(12, 12)
    swatch:SetPoint("LEFT", btn, "LEFT", 6, 0)
    swatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")

    local col = currentVal or { r = 1, g = 1, b = 1 }
    swatch:SetVertexColor(col.r, col.g, col.b)

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btnText:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    btnText:SetText("Zmień kolor")

    btn:SetScript("OnClick", function()
        local r, g, b = col.r, col.g, col.b
        ColorPickerFrame.func = function()
            col.r, col.g, col.b = ColorPickerFrame:GetColorRGB()
            swatch:SetVertexColor(col.r, col.g, col.b)
            callback(col)
        end
        ColorPickerFrame.cancelFunc = function(prev)
            col.r, col.g, col.b = prev.r, prev.g, prev.b
            swatch:SetVertexColor(col.r, col.g, col.b)
            callback(col)
        end
        ColorPickerFrame.previousValues = { r = r, g = g, b = b }
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame:Hide()
        ColorPickerFrame:Show()
    end)

    return btn
end

local function CreateScrollableDropdown(parent, name, title, items, currentVal, posX, posY, callback, isFontDropdown, width)
    local ctrlWidth = width or 205
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", posX, posY)
    label:SetText(title)

    local button = CreateFrame("Button", name .. "Btn", parent, "UIMenuButtonStretchTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", posX, posY - 15)
    button:SetSize(ctrlWidth, 22)

    local btnText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btnText:SetPoint("LEFT", button, "LEFT", 8, 0)
    btnText:SetPoint("RIGHT", button, "RIGHT", -20, 0)
    btnText:SetJustifyH("LEFT")

    local arrow = button:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture("Interface\\Buttons\\SquareButton-AlignBelow-Up")
    arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", button, "RIGHT", -4, 0)

    local function ApplyFontPreview(fontString, itemValue)
        if not isFontDropdown then return end
        
        local fontPath = itemValue
        local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
        if LSM and LSM:IsValid("font", fontPath) then
            fontPath = LSM:Fetch("font", fontPath)
        end

        if fontPath and type(fontPath) == "string" then
            local ok = pcall(fontString.SetFont, fontString, fontPath, 13, "OUTLINE")
            if not ok then
                fontString:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
            end
        end
    end

    local function GetTextForVal(val)
        for _, item in ipairs(items) do
            if item.value == val then return item.text end
        end
        return items[1] and items[1].text or ""
    end

    btnText:SetText(GetTextForVal(currentVal))
    ApplyFontPreview(btnText, currentVal)

    local listFrame = CreateFrame("Frame", name .. "List", UIParent)
    listFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    listFrame:SetSize(ctrlWidth + 20, 155)
    listFrame:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    listFrame:Hide()

    listFrame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    local numVisibleRows = 7
    local rowHeight = 20

    local scrollFrame = CreateFrame("ScrollFrame", name .. "Scroll", listFrame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -24, 4)

    local rows = {}
    for i = 1, numVisibleRows do
        local row = CreateFrame("Button", nil, listFrame)
        row:SetSize(ctrlWidth - 10, rowHeight)
        row:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 6, -4 - (i - 1) * rowHeight)

        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetBlendMode("ADD")

        local rText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rText:SetPoint("LEFT", row, "LEFT", 4, 0)
        rText:SetJustifyH("LEFT")
        row.text = rText

        rows[i] = row
    end

    local function UpdateScroll()
        FauxScrollFrame_Update(scrollFrame, #items, numVisibleRows, rowHeight)
        local offset = FauxScrollFrame_GetOffset(scrollFrame)
        for i = 1, numVisibleRows do
            local index = offset + i
            local row = rows[i]
            if index <= #items then
                local item = items[index]
                row.text:SetText(item.text)
                ApplyFontPreview(row.text, item.value)
                
                row:SetScript("OnClick", function()
                    btnText:SetText(item.text)
                    ApplyFontPreview(btnText, item.value)
                    listFrame:Hide()
                    callback(item.value)
                end)
                row:Show()
            else
                row:Hide()
            end
        end
    end

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, rowHeight, UpdateScroll)
    end)

    button:SetScript("OnClick", function()
        if listFrame:IsShown() then
            listFrame:Hide()
        else
            listFrame:Show()
            UpdateScroll()
        end
    end)

    return button
end

local function InitCustomAlertGUI()
    if not DBM_GUI then return end
    
    local panel = DBM_GUI:CreateNewPanel("Announcements NEW", "option")
    local area  = panel:CreateArea("Ustawienia Wyglądu Ramek Odliczania - Signsis")

    area:CreateCheckButton("Włącz uniwersalne odliczanie na ekranie", true, nil, "CustomAlertEnable")
    area:CreateCheckButton("Pokaż drugą ikonę po prawej stronie", true, nil, "CustomAlertShowRightIcon")

    local parentFrame = area.frame or panel.frame

    CreateSliderControl(parentFrame, "DBMCustomFontSlider", "Rozmiar Czcionki", 10, 32, 1, DBM.Options.CustomAlertFontSize or 16, 20, -70, function(val)
        DBM.Options.CustomAlertFontSize = val
        DBM:UpdateCustomAlertFont()
        DBM:ShowCustomAlertTest()
    end, 205)

    CreateSliderControl(parentFrame, "DBMCustomPosYSlider", "Pozycja Y (Góra/Dół)", -400, 400, 5, DBM.Options.CustomAlertPosY or 100, 245, -70, function(val)
        DBM.Options.CustomAlertPosY = val
        DBM:ShowCustomAlertTest()
    end, 205)

    CreateSliderControl(parentFrame, "DBMCustomPosXSlider", "Pozycja X (Lewo/Prawo)", -400, 400, 5, DBM.Options.CustomAlertPosX or 0, 20, -125, function(val)
        DBM.Options.CustomAlertPosX = val
        DBM:ShowCustomAlertTest()
    end, 205)

    CreateSliderControl(parentFrame, "DBMCustomThresholdSlider", "Pokaż gdy zostanie (s)", 1, 10, 1, DBM.Options.CustomAlertThreshold or 5, 245, -125, function(val)
        DBM.Options.CustomAlertThreshold = val
        DBM:ShowCustomAlertTest()
    end, 205)

    local fonts = {
        { text = "Friz Quadrata", value = "Fonts\\FRIZQT__.TTF" },
        { text = "Arial Narrow",  value = "Fonts\\ARIALN.TTF" },
        { text = "Skurri",        value = "Fonts\\SKURRI.TTF" },
        { text = "Morpheus",      value = "Fonts\\MORPHEUS.TTF" }
    }
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        for _, fontName in ipairs(LSM:List("font")) do
            table.insert(fonts, { text = fontName, value = fontName })
        end
    end

    CreateScrollableDropdown(parentFrame, "CustomAlertFont", "Wybór czcionki (Font)", fonts, DBM.Options.CustomAlertFont or "Fonts\\FRIZQT__.TTF", 20, -175, function(val)
        DBM.Options.CustomAlertFont = val
        DBM:UpdateCustomAlertFont()
        DBM:ShowCustomAlertTest()
    end, true, 205)

    local fontFlags = {
        { text = "Brak (NONE)",         value = "NONE" },
        { text = "Obrys (OUTLINE)",      value = "OUTLINE" },
        { text = "Gruby obrys (THICK)",  value = "THICKOUTLINE" },
        { text = "Monochrome",           value = "MONOCHROME" }
    }

    CreateScrollableDropdown(parentFrame, "CustomAlertFontFlags", "Styl obrysu (Font Flags)", fontFlags, DBM.Options.CustomAlertFontFlags or "OUTLINE", 245, -175, function(val)
        DBM.Options.CustomAlertFontFlags = val
        DBM:UpdateCustomAlertFont()
        DBM:ShowCustomAlertTest()
    end, false, 205)

    -- SEKCJA DEDYKOWANYCH USTAWIEŃ DLA CZARÓW BOSSA
    DBM.Options.CustomAlertOverrides = DBM.Options.CustomAlertOverrides or {}

    local customTimerList = {
        { key = "Itchy Spores", label = "Loatheb - Itchy Spores", icon = "Interface\\AddOns\\DBM-VPVEM\\Icons\\LoathebSporeSignsis" },
        { key = "Decimate",     label = "Gluth - Decimate",        icon = "Interface\\Icons\\Spell_Nature_Purge" },
        { key = "Locust Swarm", label = "Anub'Rekhan - Locust Swarm", icon = "Interface\\Icons\\Spell_Nature_InsectSwarm" },
        { key = "Web Spray",    label = "Maexxna - Web Spray",    icon = "Interface\\Icons\\Spell_Nature_Web" },
        { key = "Spiderlings",  label = "Maexxna - Spiderlings",  icon = "Interface\\Icons\\INV_Misc_MonsterSpiderCarapace_01" },
        --{ key = "Teleport",     label = "Heigan - Teleport",      icon = "Interface\\Icons\\Spell_Arcane_Blink" },
        { key = "Frenzy",       label = "Faerlina - Frenzy",      icon = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy" },
		{ key = "Static Field", label = "Malygos - Static Field", icon = "Interface\\Icons\\Spell_Arcane_MassDispel" },
    }

    local cardHeight  = 65
    local cardSpacing = 8
    local totalStep   = cardHeight + cardSpacing

    local scrollContainer = CreateFrame("Frame", "DBMCustomAlertScrollContainer", parentFrame)
    scrollContainer:SetSize(430, 220)
    scrollContainer:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 20, -225)

    local scrollFrame = CreateFrame("ScrollFrame", "DBMCustomAlertScrollFrame", scrollContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints(scrollContainer)

    local contentFrame = CreateFrame("Frame", "DBMCustomAlertScrollContent", scrollFrame)
    local totalHeight = math.max(220, #customTimerList * totalStep)
    contentFrame:SetSize(400, totalHeight)
    scrollFrame:SetScrollChild(contentFrame)

    local currentY = 0

    for index, item in ipairs(customTimerList) do
        local defaultRule = DBM.DefaultOptions.CustomAlertOverrides and DBM.DefaultOptions.CustomAlertOverrides[item.key]
        if not DBM.Options.CustomAlertOverrides[item.key] then
            DBM.Options.CustomAlertOverrides[item.key] = {
                textColor  = defaultRule and defaultRule.textColor or { r = 1, g = 0.8, b = 0 },
                timerColor = defaultRule and defaultRule.timerColor or { r = 1, g = 1, b = 1 }
            }
        end

        local itemData = DBM.Options.CustomAlertOverrides[item.key]

        local card = CreateFrame("Frame", "DBMCustomAlertCard_" .. index, contentFrame)
        card:SetSize(395, cardHeight)
        card:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 2, currentY)
        card:SetBackdrop({
            bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 16, edgeSize = 10,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        card:SetBackdropColor(0, 0, 0, 0.45)
        card:SetBackdropBorderColor(0.35, 0.35, 0.45, 0.8)

        local iconTex = card:CreateTexture(nil, "ARTWORK")
        iconTex:SetSize(20, 20)
        iconTex:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
        iconTex:SetTexture(item.icon)

        local labelText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        labelText:SetPoint("LEFT", iconTex, "RIGHT", 6, 0)
        labelText:SetText(item.label)

        CreateColorPickerControl(card, "CustomTextColorPicker_" .. index, "Kolor napisu", itemData.textColor, 8, -32, function(col)
            itemData.textColor = col
            DBM:ShowCustomAlert(item.icon, item.key, DBM.Options.CustomAlertThreshold or 5, nil, false)
        end, 185)

        CreateColorPickerControl(card, "CustomTimerColorPicker_" .. index, "Kolor liczby", itemData.timerColor, 200, -32, function(col)
            itemData.timerColor = col
            DBM:ShowCustomAlert(item.icon, item.key, DBM.Options.CustomAlertThreshold or 5, nil, false)
        end, 185)

        currentY = currentY - totalStep
    end
end

if DBM_GUI then
    InitCustomAlertGUI()
else
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, event, addon)
        if addon == "DBM-GUI" then
            InitCustomAlertGUI()
            self:UnregisterAllEvents()
        end
    end)
end