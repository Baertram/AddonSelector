local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name

local constants = AS.constants
local utility = AS.utility

local SEARCH_TYPE_NAME = constants.SEARCH_TYPE_NAME
local stringConstants = constants.strings
local prefixStrings = stringConstants.prefixStrings
local ZOsControls = constants.ZOsControls
local LSMconstants = constants.LSM
local LSM_defaultAddonPackMenuOptions = LSMconstants.defaultAddonPackMenuOptions

local narration = AS.narration
local narrateOnMouseEnterHandlerName = narration.narrateOnMouseEnterHandlerName

local narrationBlackList = narration.blacklist
local ZOAddOns_BlacklistedNarrationChilds = narrationBlackList.ZOAddOns_BlacklistedNarrationChilds
local ZOAddOns_AddonSelector_BlacklistedNarrationChilds = narrationBlackList.ZOAddOns_AddonSelector_BlacklistedNarrationChilds

local GLOBAL_PACK_NAME = constants.GLOBAL_PACK_NAME

local chatNarrationUpdaterName = constants.updaterNames.chatNarrationUpdaterName
local isAddonPackDropdownOpen = utility.isAddonPackDropdownOpen
local getAddonNameFromData = utility.getAddonNameFromData
local getAddonNameAndData = utility.getAddonNameAndData

local AddonSelector_GetLocalizedText = AddonSelector_GetLocalizedText


--ZOs reference variables
local tos = tostring
local strfor = string.format

local EM = EVENT_MANAGER
local SNM = SCREEN_NARRATION_MANAGER

local narrateComboBoxOnMouseEnter, narrateDropdownOnMouseExit, narrateDropdownOnOpened, narrateDropdownOnClosed
local narrateDropdownOnSubmenuShown, narrateDropdownOnSubmenuHidden, narrateDropdownOnEntryMouseEnter, narrateDropdownOnEntryMouseExit
local narrateDropdownOnEntrySelected, narrateDropdownOnCheckboxUpdated
local entryMouseEnterTextForSubmenuOpen, entryOnMouseEnterDone, entryOnSelectedDone

--Strings
local newStateText = AddonSelector_GetLocalizedText("newStateText")


local suppressOnMouseEnterNarration = false
local wasSearchNextDoneByReturnKey = false --variable to suppress the OnMouseEnter narration on addon rows if return key was used to jump to next search result
AS.lastData.selectedAddonSearchResult = nil

local onMouseEnterHandlers_ZOAddOns_done = {}


------------------------------------------------------------------------------------------------------------------------
-- Accessibility - Narration
------------------------------------------------------------------------------------------------------------------------


local function IsAccessibilitySettingEnabled(settingId)
    return GetSetting_Bool(SETTING_TYPE_ACCESSIBILITY, settingId)
end

--[[
local function ChangeAccessibilitySetting(settingId, newValue)
    SetSetting(SETTING_TYPE_ACCESSIBILITY, settingId, tonumber(newValue))
end
]]

local function IsAccessibilityModeEnabled()
	return IsAccessibilitySettingEnabled(ACCESSIBILITY_SETTING_ACCESSIBILITY_MODE)
end

--[[
local function IsAccessibilityChatReaderEnabled()
	return IsAccessibilityModeEnabled() and IsAccessibilitySettingEnabled(ACCESSIBILITY_SETTING_TEXT_CHAT_NARRATION)
end
]]

local function IsAccessibilityUIReaderEnabled()
	return IsAccessibilityModeEnabled() and IsAccessibilitySettingEnabled(ACCESSIBILITY_SETTING_SCREEN_NARRATION)
end

local function checkActiveSearchByReturnKey()
--d("[AddonSelector]wasSearchNextDoneByReturnKey: " ..tos(wasSearchNextDoneByReturnKey))
    if wasSearchNextDoneByReturnKey == true then
--d(">>Search active!")
        --wasSearchNextDoneByReturnKey = false
        return false
    end
    return true
end
narration.IsAccessibilityUIReaderEnabled = IsAccessibilityUIReaderEnabled

--[[
local function StopNarration(UItoo)
--d(">StopNarration-UItoo: " ..tostring(UItoo))
    UItoo = UItoo or false
    if IsAccessibilityChatReaderEnabled() then
        RequestReadPendingNarrationTextToClient(NARRATION_TYPE_TEXT_CHAT)
        ClearNarrationQueue(NARRATION_TYPE_TEXT_CHAT)
    end
    if UItoo == true and IsAccessibilityUIReaderEnabled() then
        RequestReadPendingNarrationTextToClient(NARRATION_TYPE_UI_SCREEN)
        ClearNarrationQueue(NARRATION_TYPE_UI_SCREEN)
    end
end
]]

local customNarrateEntryNumber = 0
local function AddNewChatNarrationText(newText, stopCurrent)
    if suppressOnMouseEnterNarration == true or IsAccessibilityUIReaderEnabled() == false then return end
    stopCurrent = stopCurrent or false
--d(">AddNewChatNarrationText-stopCurrent: " ..tostring(stopCurrent) ..", text: " ..tostring(newText))
    if stopCurrent == true then
        --StopNarration(true)
        ClearActiveNarration()
    end

    --Remove any - from the text as it seems to make the text not "always" be read?
    local newTextClean = string.gsub(newText, "-", "")

    if newTextClean == nil or newTextClean == "" then return end
    --PlaySound(SOUNDS.TREE_HEADER_CLICK)
    --[[
    if LibDebugLogger == nil and DebugLogViewer == nil then
        --Using this API does no always properly work
        RequestReadTextChatToClient(newText)
        --Adding it to the chat as debug message works better/more reliably
        --But this will add a timestamp which is read, too :-(
        --CHAT_ROUTER:AddDebugMessage(newText)
    else
        --Using this API does no always properly work
        RequestReadTextChatToClient(newText)
        --Adding it to the chat as debug message works better/more reliably
        --But this will add a timestamp which is read, too :-(
        --Disable DebugLogViewer capture of debug messages?
        --LibDebugLogger:SetBlockChatOutputEnabled(false)
        --CHAT_ROUTER:AddDebugMessage(newText)
        --LibDebugLogger:SetBlockChatOutputEnabled(true)
    end
    ]]
    --RequestReadTextChatToClient(newTextClean)

    -- this current works when the addon manager is opened and the script is ran in chat
    local addOnNarationData = {
        canNarrate = function()
            return true --ADDONS_FRAGMENT:IsShowing() -->Is currently showing
        end,
        selectedNarrationFunction = function()
            return SNM:CreateNarratableObject(newText)
        end,
    }
    customNarrateEntryNumber = customNarrateEntryNumber + 1
    local customNarrateEntryName = "ADD_ON_MANAGER_" .. tostring(customNarrateEntryNumber)
    SNM:RegisterCustomObject(customNarrateEntryName, addOnNarationData)
	SNM:QueueCustomEntry(customNarrateEntryName)
    RequestReadPendingNarrationTextToClient(NARRATION_TYPE_UI_SCREEN)
end
narration.AddNewChatNarrationText = AddNewChatNarrationText

local function GetKeybindNarration(keybindButtonInfoTable)
    local keybindNarration = SNM:CreateNarratableObject(nil, 100)
    for i, buttonInfo in ipairs(keybindButtonInfoTable) do
        local narrationText
        if buttonInfo.name then
            local formatter
            if i == 1 then
                formatter = buttonInfo.enabled and SI_SCREEN_NARRATION_FIRST_KEYBIND_FORMATTER or SI_SCREEN_NARRATION_DISABLED_FIRST_KEYBIND_FORMATTER
            else
                formatter = buttonInfo.enabled and SI_SCREEN_NARRATION_KEYBIND_FORMATTER or SI_SCREEN_NARRATION_DISABLED_KEYBIND_FORMATTER
            end
            narrationText = zo_strformat(formatter, buttonInfo.keybindName, buttonInfo.name)
        else
            local formatter
            if i == 1 then
                formatter = buttonInfo.enabled and SI_SCREEN_NARRATION_FIRST_KEYBIND_FORMATTER_NO_LABEL or SI_SCREEN_NARRATION_DISABLED_FIRST_KEYBIND_FORMATTER_NO_LABEL
            else
                formatter = buttonInfo.enabled and SI_SCREEN_NARRATION_KEYBIND_FORMATTER_NO_LABEL or SI_SCREEN_NARRATION_DISABLED_KEYBIND_FORMATTER_NO_LABEL
            end
            narrationText = zo_strformat(formatter, buttonInfo.keybindName)
        end
        keybindNarration:AddNarrationText(narrationText)
    end
    return keybindNarration
end


local function narrateKeybindButtonsInfoTable(keybindButtonInfoTable, narrationStart)
    narrationStart = narrationStart or ""
    local keybindNarrationOfDialog = GetKeybindNarration(keybindButtonInfoTable)
    local narrations = {}
    ZO_AppendNarration(narrations, SNM:CreateNarratableObject(narrationStart, 250))
    ZO_AppendNarration(narrations, keybindNarrationOfDialog)
    SNM:NarrateText(narrations, NARRATION_TYPE_UI_SCREEN)
end

local function AddDialogTitleBodyKeybindNarration(title, body, onlyConfirmButton)
    if IsAccessibilityUIReaderEnabled() == false then return end
    onlyConfirmButton = onlyConfirmButton or false
    local narrationStart
    if body ~= nil then
        narrationStart = string.format("Dialog: %q,    %s", title, body)
    else
        narrationStart = title
    end
    local keybindButtonInfoTable = {
        [1] = {
            enabled = true,
            keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("DIALOG_PRIMARY") or GetString(SI_ACTION_IS_NOT_BOUND),--Primary keybind
            name = GetString(SI_DIALOG_CONFIRM),
        },
        [2] = {
            enabled = function() if onlyConfirmButton == true then return false else return true end end,
            keybindName = ZO_Keybindings_GetHighestPriorityNarrationStringFromAction("DIALOG_NEGATIVE") or GetString(SI_ACTION_IS_NOT_BOUND),--Secondary keybind,
            name = GetString(SI_DIALOG_DISMISS),
        }
    }
    narrateKeybindButtonsInfoTable(keybindButtonInfoTable, narrationStart)
end
narration.AddDialogTitleBodyKeybindNarration = AddDialogTitleBodyKeybindNarration

local function OnUpdateDoNarrate(uniqueId, delay, callbackFunc)
    local updaterName = chatNarrationUpdaterName ..tostring(uniqueId)
    EM:UnregisterForUpdate(updaterName)
    if IsAccessibilityUIReaderEnabled() == false or callbackFunc == nil then return end
    delay = delay or 1000
    EM:RegisterForUpdate(updaterName, delay, function()
        if IsAccessibilityUIReaderEnabled() == false then EM:UnregisterForUpdate(updaterName) return end
        callbackFunc()
        EM:UnregisterForUpdate(updaterName)
    end)
end
narration.OnUpdateDoNarrate = OnUpdateDoNarrate

--Only count submenu entries which aren't a header or divider
local function countSubmenuEntries(entries)
    if ZO_IsTableEmpty(entries) then return 0 end
    local dividerEntry = AS.LSM.DIVIDER
    local count = 0
    for k, v in ipairs(entries) do
        if not v.disabled and not v.isDivider and not v.isHeader and v.name ~= dividerEntry then
            count = count + 1
        end
    end
    return count
end

local function getDropdownEntryPackEntryText(entryControl, data, hasSubmenu)
    local entryText = data.label or data.name
    local charName = data.charName
    local isGlobalPack        = (charName == GLOBAL_PACK_NAME and true) or false
    local globalOrCharPackStr = ""
    if isGlobalPack == true then
        globalOrCharPackStr = AddonSelector_GetLocalizedText("packGlobal") .. ", " .. AddonSelector_GetLocalizedText("selectedPackName")
    else
        globalOrCharPackStr = AddonSelector_GetLocalizedText("packCharName")
        if not data.isCharacterPackHeader then
            globalOrCharPackStr = globalOrCharPackStr .. ": '"..charName.."' - "
        end
    end
    return globalOrCharPackStr .. ": " .. entryText
end
narration.getDropdownEntryPackEntryText = getDropdownEntryPackEntryText

local function getAddonEntryByScrollToIndex(scrollToIndex)
    if scrollToIndex == nil then
        wasSearchNextDoneByReturnKey = false
        return
    end
    local addonList = ZOsControls.ZOAddOnsList.data
    if addonList == nil then
        wasSearchNextDoneByReturnKey = false
        return
    end
    local addonEntry = addonList[scrollToIndex]
    if addonEntry == nil then
        wasSearchNextDoneByReturnKey = false
        return
    end
    return addonEntry
end
narration.getAddonEntryByScrollToIndex = getAddonEntryByScrollToIndex

local function getAddonNarrateTextByData(addonData, prefixStr)
    if addonData == nil then return end

    local addonName = getAddonNameFromData(addonData)
    if addonName == nil then return end

    local narrateAboutAddonText = addonName
    local hasDependencyError = false
    local isLibrary = false
    if addonData.hasDependencyError ~= nil and addonData.hasDependencyError == true then
        narrateAboutAddonText = narrateAboutAddonText .. string.format("["..AddonSelector_GetLocalizedText("stateText").."] %s", GetString(SI_ADDONLOADSTATE5) .. " " .. GetString(SI_GAMEPAD_ARMORY_MISSING_ENTRY_NARRATION)) -- Dependency missing
        hasDependencyError = true
    end
    if hasDependencyError == false then
        if addonData.addOnEnabled ~= nil and addonData.addOnEnabled == false then
            narrateAboutAddonText = narrateAboutAddonText .. string.format("["..AddonSelector_GetLocalizedText("stateText").."] %s", GetString(SI_ADDONLOADSTATE3)) --Disabled
        elseif addonData.addOnEnabled ~= nil and addonData.addOnEnabled == true then
            narrateAboutAddonText = narrateAboutAddonText .. string.format("["..AddonSelector_GetLocalizedText("stateText").."] %s", GetString(SI_ADDONLOADSTATE2)) --Enabled
        end
    end
    if addonData.isLibrary ~= nil and addonData.isLibrary == true then
        narrateAboutAddonText = "[" .. AddonSelector_GetLocalizedText("libraryText") .. "] " .. narrateAboutAddonText
        isLibrary = true
    end
    if isLibrary == false and zo_strfind(addonName, "Lib", 1, true) ~= nil then
        narrateAboutAddonText = "[" .. AddonSelector_GetLocalizedText("libraryText") .. "] " .. narrateAboutAddonText
    end

    if prefixStr ~= nil and prefixStr ~= "" then
        narrateAboutAddonText = prefixStr .. narrateAboutAddonText
    end

    return narrateAboutAddonText
end
narration.getAddonNarrateTextByData = getAddonNarrateTextByData

local function OnAddonRowMouseEnterStartNarrate(control, prefixStr)
    --d("[AddonSelector]OnAddonRowMouseEnterStartNarrate")
    if control == nil then return end
    if checkActiveSearchByReturnKey() == false then return end
    if isAddonPackDropdownOpen() then return end
    if not IsAccessibilityUIReaderEnabled() then return end

    --Did the control below the mouse change?
    local mocCtrl = moc()
    if mocCtrl == nil or control ~= mocCtrl then return end


    --Get the addon name at the control
    local addonName, addonData = getAddonNameAndData(control)
    if addonName == nil or addonData == nil then return end

    local narrateAboutAddonText = getAddonNarrateTextByData(addonData, prefixStr)
    if narrateAboutAddonText == nil then return end

    --d(">>Text: " .. tos(narrateAboutAddonText))
    OnUpdateDoNarrate("OnAddonRowMouseEnter", 75, function() AddNewChatNarrationText(narrateAboutAddonText, true, control)  end)
end
narration.OnAddonRowMouseEnterStartNarrate = OnAddonRowMouseEnterStartNarrate

local function narrateCurrentlyScrolledToAddonName(scrollToIndex, wasLastFoundReached, searchValue)
    --d("[AddonSelector]narrateCurrentlyScrolledToAddonName-scrollIndex: " ..tos(scrollToIndex))
    wasLastFoundReached = wasLastFoundReached or false
    local addonEntry = getAddonEntryByScrollToIndex(scrollToIndex)
    if addonEntry == nil then
        return
    end

    local addonData = addonEntry.data
    local addonName = getAddonNameFromData(addonData)
    --d(">addonName: " ..tos(addonName))
    if addonName == nil or addonName == "" then
        wasSearchNextDoneByReturnKey = false
        return
    end

    local foundText = ""
    if wasLastFoundReached == true then
        foundText = AddonSelector_GetLocalizedText("foundSearchLast") .. " "
    else
        foundText = AddonSelector_GetLocalizedText("foundSearch") .. " "
    end

    if searchValue ~= nil and searchValue ~= "" then
        foundText = AddonSelector_GetLocalizedText("searchedForStr") .. "  " ..searchValue .. "  -  " .. foundText
    end

    local narrateAboutAddonText = getAddonNarrateTextByData(addonData, foundText)
    if narrateAboutAddonText == nil or narrateAboutAddonText == foundText then
        wasSearchNextDoneByReturnKey = false
        return
    end

    --Higher delay as pressing the return key will narrate "return" and stops the found addon name then from playing...
    OnUpdateDoNarrate("OnAddonSelector_AddonSearch", 75, function()
        wasSearchNextDoneByReturnKey = false
        AddNewChatNarrationText(narrateAboutAddonText, false)
    end)
end
narration.narrateCurrentlyScrolledToAddonName = narrateCurrentlyScrolledToAddonName

local function getZOAddOnsUI_ControlText(control)
    if control == nil then return end
    local retText
    local retTextSuffix
    --Checkbox at parent?
    local parentCtrl = control:GetParent()
    if parentCtrl.GetState ~= nil then
        local currentState = parentCtrl:GetState()
        if currentState == BSTATE_PRESSED then
            retTextSuffix = " [" .. AddonSelector_GetLocalizedText("checkBox") .. " " .. AddonSelector_GetLocalizedText("currently") .. "]   " .. GetString(SI_SCREEN_NARRATION_TOGGLE_ON)
        else
            retTextSuffix = " [" .. AddonSelector_GetLocalizedText("checkBox") .. " " .. AddonSelector_GetLocalizedText("currently") .. "]   " .. GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
        end
    end

    if control.GetText ~= nil then --Label
--d(">GetText")
        retText = control:GetText()
    end
    if retText == nil or retText == "" then
        if control.nameText ~= nil then --keybind
--d(">nameText")
            retText = control.nameText
        elseif control.label ~= nil and control.label.GetText ~= nil then --label/checkbox label
--d(">label:GetText")
            retText = control.label:GetText()
        elseif control.GetLabelControl ~= nil then --button label
--d(">button.label:GetText")
            local buttonlabel = control:GetLabelControl()
            if buttonlabel ~= nil and buttonlabel.GetText ~= nil then
                retText = buttonlabel:GetText()
            end
        elseif control.m_comboBox and control.m_comboBox.m_selectedItemText ~= nil and control.m_comboBox.m_selectedItemText.GetText ~= nil then --dropdown combobox selected label
--d(">m_comboBox.m_selectedItemText:GetText")
            retText = control.m_comboBox.m_selectedItemText:GetText()
        end
    end

--d(">>retText: " ..tos(retText))
    if retTextSuffix ~= nil then
        if retText ~= nil then
            return retText .. retTextSuffix
        else
            return retTextSuffix
        end
    else
        return retText
    end
end
narration.getZOAddOnsUI_ControlText = getZOAddOnsUI_ControlText

local function getNarrateTextOfControlAndNarrateFunc(control, narrateTextTemplate, narrateTextFunc)
    local narrateText
    --is the control a kybind?
    if control.GetKeybind ~= nil then
        --Get the keybind and the narrateText and narrate both
        --local keyBind = control:GetKeybind()
        local narrationData = {}
        table.insert(narrationData, control:GetKeybindButtonNarrationData())
        narrateKeybindButtonsInfoTable(narrationData, "")
        return

    else
        if isAddonPackDropdownOpen() then return end
        if narrateTextTemplate ~= nil and narrateTextTemplate ~= "" and narrateTextFunc ~= nil and type(narrateTextFunc) == "function" then
            narrateText = string.format(narrateTextTemplate, unpack({narrateTextFunc()}))
        elseif narrateTextTemplate ~= nil and narrateTextTemplate ~= "" and narrateTextFunc == nil then
            narrateText = narrateTextTemplate
        elseif narrateTextTemplate == nil and narrateTextFunc ~= nil and type(narrateTextFunc) == "function" then
            narrateTextFunc()
            return
        end
    end
    if narrateText == nil or narrateText == "" then
        narrateText = getZOAddOnsUI_ControlText(control)
    end
    return narrateText
end
narration.getNarrateTextOfControlAndNarrateFunc = getNarrateTextOfControlAndNarrateFunc

local function narrateAddonsEnabledTotal()
    local numAddonsEnabled = AS.numbers.numAddonsEnabled
    local numAddonsTotal = AS.numAddonsTotal
    --AddonSelector.numAddonsTotal = 0
    AddNewChatNarrationText("[" ..GetString(SI_WINDOW_TITLE_ADDON_MANAGER) .. "] - " ..tostring(numAddonsEnabled) .. " - " ..GetString(SI_ADDON_MANAGER_ENABLED)
            .. "   [" ..GetString(SI_TRADINGHOUSESORTFIELD2) .. "] - "..tos(numAddonsTotal), false)
end
narration.narrateAddonsEnabledTotal = narrateAddonsEnabledTotal

local function onMouseEnterDoNarrate(control, narrateTextTemplate, narrateTextFunc, stopNarration)
    if control == nil then return end
    if stopNarration == nil then stopNarration = true else stopNarration = false end
    if not onMouseEnterHandlers_ZOAddOns_done[control] then
        local onMouseEnterHandler = control:GetHandler("OnMouseEnter")
        if onMouseEnterHandler == nil then
            control:SetHandler("OnMouseEnter", function(ctrl)
                --d("[AddonSelector]OnMouseEnter - 1 - name: " ..ctrl:GetName())
                local narrateAddonUIControlText = getNarrateTextOfControlAndNarrateFunc(control, narrateTextTemplate, narrateTextFunc)
                if narrateAddonUIControlText ~= nil then
                    OnUpdateDoNarrate("OnZOAddOnsUI_ControlMouseEnter", 75, function() AddNewChatNarrationText(narrateAddonUIControlText, stopNarration)  end)
                end
            end, narrateOnMouseEnterHandlerName)
            onMouseEnterHandlers_ZOAddOns_done[control] = true
        else
            ZO_PostHookHandler(control, "OnMouseEnter", function(ctrl)
                --d("[AddonSelector]OnMouseEnter - 2 - name: " ..ctrl:GetName())
                local narrateAddonUIControlText = getNarrateTextOfControlAndNarrateFunc(control, narrateTextTemplate, narrateTextFunc)
                if narrateAddonUIControlText ~= nil then
                    OnUpdateDoNarrate("OnZOAddOnsUI_ControlMouseEnter", 75, function() AddNewChatNarrationText(narrateAddonUIControlText, stopNarration)  end)
                end
            end)
            onMouseEnterHandlers_ZOAddOns_done[control] = true
        end
    end
end
narration.onMouseEnterDoNarrate = onMouseEnterDoNarrate


--[[
local function onMenuItemMouseEnterNarrate(menuItem)
    --Get the ZO_Menu.items[i] text and narrate it OnMouseEnter
    local narrateText = menuItem.name
    onMouseEnterDoNarrate(menuItem, narrateText, nil, true)
end
]]

function narrateComboBoxOnMouseEnter()
    onMouseEnterDoNarrate(AS.controls.ddl, "["..AddonSelector_GetLocalizedText("selectPack") .. " %s]   -   " .. AddonSelector_GetLocalizedText("openDropdownStr"), function() return getZOAddOnsUI_ControlText(AS.controls.ddl) end)
    AS.narrateSelectedPackEntryStr = nil
   --return "Test text", false
end
narration.narrateComboBoxOnMouseEnter = narrateComboBoxOnMouseEnter


function narrateDropdownOnSubmenuHidden(scrollHelper, ctrl)
--d("Submenu closed: " ..tos(entryOnSelectedDone) .. ", entryOnMouseEnterDone: " ..tos(entryOnMouseEnterDone))
    local submenuClosedText = "["..AddonSelector_GetLocalizedText("submenuClosedStr").."]"
    return submenuClosedText, false
end
narration.narrateDropdownOnSubmenuHidden = narrateDropdownOnSubmenuHidden

function narrateDropdownOnSubmenuShown(scrollHelper, ctrl, anchorPoint)
    --d("OnSubmenuOpened - anchorPoint: " ..tos(anchorPoint))
    --This will unfortunately fire AFTER the entry was selected which opens the submenu (only logical ;-) ) so we need to
    --add the text of this here, to the last text of the narrateDropdownOnEntryMouseEnter
    local anchoredToStr = ""
    if anchorPoint == LEFT then
        anchoredToStr = "   - " .. GetString(SI_KEYCODE_NARRATIONTEXTPS4125)
    elseif anchorPoint == RIGHT then
        anchoredToStr = "   -" .. GetString(SI_KEYCODE_NARRATIONTEXTPS4126)
    end
    local submenuOpenedText = "["..AddonSelector_GetLocalizedText("submenuOpenedStr").."]" .. anchoredToStr

    --Add text from narrateDropdownOnEntryMouseEnter?
    if entryMouseEnterTextForSubmenuOpen ~= nil then
        submenuOpenedText = entryMouseEnterTextForSubmenuOpen .. "   -   " .. submenuOpenedText
        entryMouseEnterTextForSubmenuOpen = nil
    end
    return submenuOpenedText, false --do not stop any other narration (e.g. OnMousEnter on a menu entry)
end
narration.narrateDropdownOnSubmenuShown = narrateDropdownOnSubmenuShown

function narrateDropdownOnEntryMouseEnter(scrollhelperObject, entryControl, data, hasSubmenu, comingFromCheckbox)
--d("OnEntryMouseEnter - hasSubmenu: " ..tos(hasSubmenu) .. ", comingFomrCheckbox: " ..tos(comingFromCheckbox) .. ", name: " ..tos(data.label or data.name))
    entryOnMouseEnterDone = true
    entryMouseEnterTextForSubmenuOpen = nil
    local entryTextWithoutPrefix = getDropdownEntryPackEntryText(entryControl, data, hasSubmenu)

    local entryMouseEnterText = "["..AddonSelector_GetLocalizedText("entryMouseEnter").."]" .. entryTextWithoutPrefix

    --Was a checkbox OnMouseEnter raised?
    comingFromCheckbox = true
    if comingFromCheckbox == true and entryControl.GetState ~= nil then
        local currentStateText = ""
        local currentCheckboxState = entryControl:GetState()
        if currentCheckboxState == BSTATE_PRESSED then
            currentStateText = GetString(SI_SCREEN_NARRATION_TOGGLE_ON)
        else
            currentStateText = GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
        end
        currentStateText = AddonSelector_GetLocalizedText("currentText") ..":   " .. currentStateText
        entryMouseEnterText = entryMouseEnterText .. "  [" .. AddonSelector_GetLocalizedText("checkBox") .. "] " .. currentStateText
    end

    --Got a submenu that opens?
    if hasSubmenu == true and data and data.entries ~= nil then
        local submenuEntriesCount = tos(countSubmenuEntries(data.entries))
        entryMouseEnterText = entryMouseEnterText .. " (" .. submenuEntriesCount .. AddonSelector_GetLocalizedText("entries") .. ")"

        --If a submenu opens: The narrateDropdownOnSubmenuShown will be called. So narrate the total text of the entry selected here, and the
        --submenu opened right/left at this function!
        entryMouseEnterTextForSubmenuOpen = entryMouseEnterText
        --Do not narrate here, but do this together with the OnSubmenuOpen text at narrateDropdownOnSubmenuShown
        return
    end

    return entryMouseEnterText, false --do not stop narration of e.g. submenu opened
end
narration.narrateDropdownOnEntryMouseEnter = narrateDropdownOnEntryMouseEnter

function narrateDropdownOnEntrySelected(scrollhelperObject, entryControl, data, hasSubmenu)
    entryOnSelectedDone = true
    --d("OnEntrySelected - hasSubmenu: " ..tos(hasSubmenu))
    local entryTextWithoutPrefix = getDropdownEntryPackEntryText(entryControl, data, hasSubmenu)
    local entrySelectedText = "["..AddonSelector_GetLocalizedText("entrySelected").."]" .. entryTextWithoutPrefix
    return entrySelectedText, true --stop narration of others, if you select an entry
end
narration.narrateDropdownOnEntrySelected = narrateDropdownOnEntrySelected

function narrateDropdownOnCheckboxUpdated(scrollhelperObject, checkboxControl, data)
    --d("OnCHeckboxUpdated")
    return narrateDropdownOnEntryMouseEnter(scrollhelperObject, checkboxControl, data, nil, true)
end
narration.narrateDropdownOnCheckboxUpdated = narrateDropdownOnCheckboxUpdated

local function enableZO_AddOnsUI_controlNarration()
    --Enable all addons checkbox
    if ZOsControls.enableAllAddonsCheckboxCtrl ~= nil then
        local function narrateTextFunc()
            --As the same row ZO_AddOnsList2Row1 will contain the "Libraries" text, if you scroll down (due to the row control pool) we need to check for the checkbox's visibility!
            if ZOsControls.enableAllAddonsCheckboxCtrl:IsHidden() then
                OnUpdateDoNarrate("OnZOAddOnsUI_ControlMouseEnter", 75, function() AddNewChatNarrationText(GetString(SI_ADDON_MANAGER_SECTION_LIBRARIES), true)  end)
            else
                local currentStateText1 = ""
                local currentStateText2 = ""
                local currentState = ZOsControls.enableAllAddonsCheckboxCtrl:GetState()
                if currentState == BSTATE_PRESSED then
                    currentStateText1 = AddonSelector_GetLocalizedText("enableText")
                    currentStateText2 = GetString(SI_SCREEN_NARRATION_TOGGLE_ON)
                else
                    currentStateText1 = AddonSelector_GetLocalizedText("disableText")
                    currentStateText2 = GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
                end
                local narrateText = strfor(AddonSelector_GetLocalizedText("enDisableCurrentStateTemplate"), currentStateText1, currentStateText2) --"%s all addons. Current state   -   %s"
                OnUpdateDoNarrate("OnZOAddOnsUI_ControlMouseEnter", 75, function() AddNewChatNarrationText(narrateText, true)  end)
            end
        end
        onMouseEnterDoNarrate(ZOsControls.enableAllAddonsCheckboxCtrl, nil, narrateTextFunc)
        onMouseEnterDoNarrate(ZOsControls.enableAllAddonTextCtrl, nil, narrateTextFunc)
    end

    --Title
    if ZOsControls.ZOAddOnsTitle ~= nil then
        ZOsControls.ZOAddOnsTitle:SetMouseEnabled(true)
        onMouseEnterDoNarrate(ZOsControls.ZOAddOnsTitle, nil, narrateAddonsEnabledTotal)
    end

    --Search box
    if AS.controls.searchBox ~= nil then
        onMouseEnterDoNarrate(AS.controls.searchBox, "["..AddonSelector_GetLocalizedText("searchMenuStr") .. " %s]", function() return getZOAddOnsUI_ControlText(AS.controls.searchBox)  end)
    end

    --Pack name edit box
    if AS.controls.editBox ~= nil then
        onMouseEnterDoNarrate(AS.controls.editBox, "["..AddonSelector_GetLocalizedText("packName") .. " %s]", function() return getZOAddOnsUI_ControlText(AS.controls.editBox) end)
    end

    --Pack name dropdown box
    --[[
    if AddonSelector.ddl ~= nil then
        onMouseEnterDoNarrate(AddonSelector.ddl, "["..selectPackStr .. " %s]   -   " .. openDropdownStr, function() return getZOAddOnsUI_ControlText(AddonSelector.ddl) end)
    end
    ]]

    local controlsParent = ZOsControls.ZOAddOns
    if controlsParent ~= nil then
--d("enableZO_AddOnsUI_controlNarration")
        for i=1, controlsParent:GetNumChildren(), 1 do
            local childCtrl = controlsParent:GetChild(i)
            if childCtrl ~= nil and childCtrl.GetName ~= nil then
                local childName = childCtrl:GetName()
                if not ZOAddOns_BlacklistedNarrationChilds[childName] then
--d(">>childName: " .. tos(childName))
                    onMouseEnterDoNarrate(childCtrl)
                    ZOAddOns_BlacklistedNarrationChilds[childName] = true
                end
            end
        end
    end

    controlsParent = AS.controls.addonSelectorControl
    if controlsParent ~= nil then
--d("~~~~~ AddonSelector ~~~~~")
        for i=1, controlsParent:GetNumChildren(), 1 do
            local childCtrl = controlsParent:GetChild(i)
            if childCtrl ~= nil and childCtrl.GetName ~= nil then
                local childName = childCtrl:GetName()
                if not ZOAddOns_AddonSelector_BlacklistedNarrationChilds[childName] then
--d(">>AS childName: " .. tos(childName))
                    onMouseEnterDoNarrate(childCtrl)
                    ZOAddOns_AddonSelector_BlacklistedNarrationChilds[childName] = true
                end
            end
        end
    end
end
narration.enableZO_AddOnsUI_controlNarration = enableZO_AddOnsUI_controlNarration

local function OnControlClickedNarrate(control, stopNarration)
    if control == nil then return end
    if not IsAccessibilityUIReaderEnabled() then return end
    if isAddonPackDropdownOpen() then return end

    stopNarration = stopNarration or false
    local narrateAddonUIControlText = getNarrateTextOfControlAndNarrateFunc(control, nil, nil)
    if narrateAddonUIControlText ~= nil then
        OnUpdateDoNarrate("OnZOAddOnsUI_ControlMouseEnter", 75, function() AddNewChatNarrationText(narrateAddonUIControlText, stopNarration)  end)
    end
end
narration.OnControlClickedNarrate = OnControlClickedNarrate


local function OnAddonRowClickedNarrateNewState(control, newState, addonData)
--d("[AddonSelector]OnAddonRowClickedNarrateNewState-newState: " ..tos(newState))
    if control == nil then return end
    if not IsAccessibilityUIReaderEnabled() then return end

    local addonName
    if addonData ~= nil then
        addonName = getAddonNameFromData(addonData)
    else
        addonName, addonData = getAddonNameAndData(control)
    end
    if addonName == nil or addonData == nil then return end

    local narrateAddonStateText
    if newState ~= nil then
        if newState == TRISTATE_CHECK_BUTTON_UNCHECKED then
            narrateAddonStateText = "[" .. newStateText .. "] " .. GetString(SI_ADDONLOADSTATE3) .. ",   " ..addonName -- disabled
        else
            narrateAddonStateText = "[" .. newStateText .. "] " .. GetString(SI_ADDONLOADSTATE2) ..",   " ..addonName --enabled
        end
--d(">addon state: " .. tos(narrateAddonStateText))
        OnUpdateDoNarrate("OnAddonRowClicked", 75, function() AddNewChatNarrationText(narrateAddonStateText, true)  end)
    else
--d(">addonName: " ..tos(addonName))
        zo_callLater(function()
            --addonName, addonData = getAddonNameAndData(control)
            local oldIndex = addonData.index
            --local name, title, author, description, enabled, state, isOutOfDate, isLibrary = AddOnManager:GetAddOnInfo(i)
            local newName, _, _, _, isEnabledNow = ADDON_MANAGER:GetAddOnInfo(oldIndex)
--d(">newName: " ..tos(newName))
            if isEnabledNow == false then
                narrateAddonStateText = "[" .. newStateText .. "] " .. GetString(SI_ADDONLOADSTATE3) ..",   " ..addonName
            else
                narrateAddonStateText = "[" .. newStateText .. "] " .. GetString(SI_ADDONLOADSTATE2) ..",   " ..addonName
            end
--d(">DELAYED: addon state: " .. tos(narrateAddonStateText))
            OnUpdateDoNarrate("OnAddonRowClicked", 75, function() AddNewChatNarrationText(narrateAddonStateText, true)  end)
        end, 50)
    end
end
narration.OnAddonRowClickedNarrateNewState = OnAddonRowClickedNarrateNewState


