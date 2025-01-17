--[[
------------------------------------------------------------------------------------------------------------------------
 Changelog
------------------------------------------------------------------------------------------------------------------------
2025-01-17
AddonSelector v2.35


------------------------------------------------------------------------------------------------------------------------
 Known bugs - Max: 15
------------------------------------------------------------------------------------------------------------------------

Feature requests:
20241223 - Add new setting for keybinds to automatically reload the UI directly upon pack loading (regardless the setting "Auto reload UI after pack load" for te dropdown box)

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
]]

--TODO:Remove comment for quicker debugging
--ASG = AddonSelectorGlobal

AddonSelectorGlobal = AddonSelectorGlobal or {} --Should be defined in strings.lua
local AS                            = AddonSelectorGlobal
AS.version                          = "2.35"

local ADDON_NAME	= "AddonSelector"
local addonNamePrefix = "["..ADDON_NAME.."]"

local ADDON_MANAGER
local ADDON_MANAGER_OBJECT

--Addon variables
AS.firstControl                     = nil
AS.firstControlData                 = nil
AS.noAddonNumUpdate                 = false
AS.noAddonCheckBoxUpdate            = false
AS.lastChangedAddOnVars             = {}
AS.alreadyFound                     = {}
AS.activeUpdateControlEvents        = {}

AS.numAddonsEnabled                 = 0
AS.numAddonsTotal                   = 0

AS.AddedAddonsFragment              = false


--ZOs local pointer variables
local EM = EVENT_MANAGER
local SM = SCENE_MANAGER
local SNM = SCREEN_NARRATION_MANAGER

local tos = tostring
local strfor = string.format
local strlow = string.lower
local strgma = string.gmatch
local strsub = string.sub
local zopsf = zo_plainstrfind
local gTab = table
local tins = gTab.insert
--local trem = gTab.remove
local tsor = gTab.sort

local OnClick_Save, OnClick_DeleteWholeCharacter, AddonSelectorUpdateCount, getKeybindingLSMEntriesForPacks

local preventOnClickDDL = false

--Constant for the global packs
local GLOBAL_PACK_NAME = "$G"
--Constant for the charater saved packs
local CHARACTER_PACK_CHARNAME_IDENTIFIER = "_charName"

local GLOBAL_PACK_BACKUP_BEFORE_MASSMARK_NAME = "$BACKUP_BEFORE_MASSMARK"
local SEARCH_TYPE_NAME = "name"

local myDisabledColor = ZO_DISABLED_TEXT

--Other Addons/Libraries which should not be disabled if you use the "disable all" keybind
--> see function AddonSelector_SelectAddons(false)
local addonsWhichShouldNotBeDisabled = {
    ["LibDialog"] =         true,
    ["LibCustomMenu"] =     true,
    ["LibScrollableMenu"] = true,
}

--Settings that need to udate the dropdown entries at the combobox if setting is changed
local settingNeedsToUpdateDDL = {
    ["autoReloadUI"] = true,
    ["showPacksAddonList"] = true,
    ["addPackTooltip"] = true,
    ["showSearchFilterAtPacksList"] = true,
    ["showPacksOfOtherAccountsChars"] = true,
}
--Do not disable mouse on these child conrols of AddonSelector, so one can still use them with all addons disabled
--via ZOs checkbox button
local isExcludedFromChangeEnabledState = {
    ["AddonSelectorSettingsOpenDropdown"] = true,
    ["AddonSelectorSearchBox"] = true,
}

--Get the current addonIndex of the "AddonSelector" addon
local thisAddonIndex = 0
--Needed dependencies index
local addonIndicesOfAddonsWhichShouldNotBeDisabled = {}

local addonListWasOpenedByAddonSelector = false
local skipUpdateDDL = false
local skipOnAddonPackSelected = false

--Textures
local reloadUITexture = "/esoui/art/miscellaneous/eso_icon_warning.dds"
local reloadUITextureStr = "|cFF0000".. zo_iconFormatInheritColor(reloadUITexture, 24, 24) .."|r"

local autoLoadOnLogoutTexture = "/esoui/art/buttons/log_out_up.dds"
--local autoLoadOnLogoutTextureStr = "|c00FF22".. zo_iconFormatInheritColor(autoLoadOnLogoutTexture, 24, 24) .."|r"

--Keybinds
local MAX_ADDON_LOAD_PACK_KEYBINDS = 5
local keybindTexturesLoadPack = {}
--Create the keybinding textures/Strings
local keybindStr = AddonSelector_GetLocalizedText("keybind")
for keybindNr  = 1, MAX_ADDON_LOAD_PACK_KEYBINDS, 1 do
    keybindTexturesLoadPack[keybindNr] = "  " .. keybindStr .. " " .. keybindNr  --does not work: ZO_Keybindings_GenerateIconKeyMarkup(22 + keybindNr, 100, false)
end


--The "Enable all addons" checkbox introduced with API101031
local ZOAddOns                      = ZO_AddOns
local ZOAddOnsList                  = ZO_AddOnsList
local enableAllAddonsCheckboxHooked = false
local enableAllAddonsParent         = ZO_AddOnsList2Row1         --will be re-referenced at event_add_on_loaded or ADDON_MANAGER_OBJECT OnShow
local enableAllAddonTextCtrl        = ZO_AddOnsList2Row1Text     --will be re-referenced at event_add_on_loaded or ADDON_MANAGER_OBJECT OnShow
local enableAllAddonsCheckboxCtrl   = ZO_AddOnsList2Row1Checkbox --will be re-referenced at event_add_on_loaded or ADDON_MANAGER_OBJECT OnShow


--Callback functions
local defaultCallbackFunc = function()  end


------------------------------------------------------------------------------------------------------------------------
--Language and strings - local references to lang/strings.lua
------------------------------------------------------------------------------------------------------------------------
local addonsStr = GetString(SI_GAME_MENU_ADDONS)
local librariesStr = GetString(SI_ADDON_MANAGER_SECTION_LIBRARIES)
local charNamePackColorTemplate = "|cc9b636%s|r"
local charNamePackColorDef = ZO_ColorDef:New("C9B636")
local packNameCharacter = strfor(charNamePackColorTemplate, GetString(SI_ADDON_MANAGER_CHARACTER_SELECT_ALL))
local singleCharNameStr = AddonSelector_GetLocalizedText("singleCharName")
local singleCharNameColoredStr = strfor(charNamePackColorTemplate, singleCharNameStr)
local globalPackColorTemplate = "|c7EC8E3%s|r"
local numAddonsColorTemplate = "|cf9a602%s|r"
local numLibrariesColorTemplate = "|cf9a602%s|r"
local packGlobalStr = AddonSelector_GetLocalizedText("packGlobal")
local packNameGlobal = strfor(globalPackColorTemplate, packGlobalStr)
local packCharNameStr = AddonSelector_GetLocalizedText("packCharName")
local selectPackStr = AddonSelector_GetLocalizedText("selectPack")
local selectedPackNameStr = AddonSelector_GetLocalizedText("selectedPackName")
local deletePackAlertStr = AddonSelector_GetLocalizedText("deletePackAlert")
local deletePackErrorStr = AddonSelector_GetLocalizedText("deletePackError")
local deleteWholeCharacterPacksTitleStr = AddonSelector_GetLocalizedText("deleteWholeCharacterPacksTitle")
local deleteWholeCharacterPacksQuestionStr = AddonSelector_GetLocalizedText("deleteWholeCharacterPacksQuestion")
local savedGroupedByCharNameStr = AddonSelector_GetLocalizedText("SaveGroupedByCharacterName")
local autoReloadUIStr = AddonSelector_GetLocalizedText("autoReloadUIHint")
local searchMenuStr = AddonSelector_GetLocalizedText("AddonSearch")
searchMenuStr = strsub(searchMenuStr, 1, -2) --remove last char
local searchInstructions = AddonSelector_GetLocalizedText("searchInstructions")
local searchFound = AddonSelector_GetLocalizedText("foundSearch")
local searchFoundLast = AddonSelector_GetLocalizedText("foundSearchLast")
local searchedForStr = AddonSelector_GetLocalizedText("searchedForStr")
local clearSearchHistoryStr = AddonSelector_GetLocalizedText("searchClearHistory")
local reloadUIStrWithoutIcon = strlow(AddonSelector_GetLocalizedText("ReloadUI"))
local reloadUIStr = reloadUIStrWithoutIcon .. reloadUITextureStr
local deletePackTitleStr = AddonSelector_GetLocalizedText("deletePackTitle")
local selectSavedText = AddonSelector_GetLocalizedText("SelectAllAddonsSaved")
local overwriteSavePackStr = AddonSelector_GetLocalizedText("OverwriteSavePack")
local selectAllText = AddonSelector_GetLocalizedText("SelectAllAddons")
local packNameStr = AddonSelector_GetLocalizedText("packName")
local addonCategoriesStr = AddonSelector_GetLocalizedText("addonCategories")
local noCategoryStr = AddonSelector_GetLocalizedText("noCategory")
local currentTextStr = AddonSelector_GetLocalizedText("currentText")
local enDisableCurrentStateTemplateText = AddonSelector_GetLocalizedText("enDisableCurrentStateTemplate")
local enableText = AddonSelector_GetLocalizedText("enableText")
local disableText = AddonSelector_GetLocalizedText("disableText")
local stateText = AddonSelector_GetLocalizedText("stateText")
local newStateText = AddonSelector_GetLocalizedText("newStateText")
local libraryText = AddonSelector_GetLocalizedText("libraryText")
local openDropdownStr = AddonSelector_GetLocalizedText("openDropdownStr")
local openedStr = AddonSelector_GetLocalizedText("openedStr")
local closedStr = AddonSelector_GetLocalizedText("closedStr")
--local chosenStr = AddonSelector_GetLocalizedText("chosenStr")
local addPackTooltipStr = AddonSelector_GetLocalizedText("addPackTooltip")
local showPacksAddonListStr = AddonSelector_GetLocalizedText("showPacksAddonList")
local characterWideStr = AddonSelector_GetLocalizedText("characterWide")
local accountWideStr = AddonSelector_GetLocalizedText("accountWide")
local characterWidesStr = AddonSelector_GetLocalizedText("characterWides")
local accountWidesStr = AddonSelector_GetLocalizedText("accountWides")
local settingStr = AddonSelector_GetLocalizedText("settingPattern")
local currentlyStr = GetString(SI_COLOR_PICKER_CURRENT)
local searchHistoryStr = AddonSelector_GetLocalizedText("searchHistoryPattern")
local submenuStr = AddonSelector_GetLocalizedText("submenu")
local submenuOpenedStr = submenuStr .. " " .. openedStr
local submenuClosedStr = submenuStr .. " " .. closedStr
local entriesStr = AddonSelector_GetLocalizedText("entries")
local entryMouseEnterStr = AddonSelector_GetLocalizedText("entryMouseEnter")
local entrySelectedStr = AddonSelector_GetLocalizedText("entrySelected")
local checkboxStr = AddonSelector_GetLocalizedText("checkBox")
local enabledAddonsInPackStr = AddonSelector_GetLocalizedText("enabledAddonsInPack")
local addonsInPackStr = AddonSelector_GetLocalizedText("addonsInPack")
local librariesInPackStr = AddonSelector_GetLocalizedText("librariesInPack")
local showSearchFilterAtPacksListStr = AddonSelector_GetLocalizedText("showSearchFilterAtPacksList")
local disabledStr = AddonSelector_GetLocalizedText("disabledRed")
local missingStr = AddonSelector_GetLocalizedText("missing")
local otherAccStr = AddonSelector_GetLocalizedText("otherAccount")
local changedAddonPackStr = AddonSelector_GetLocalizedText("changedAddonPack")
local saveChangesNowStr = AddonSelector_GetLocalizedText("saveChangesNow")
local packNameLoadNotFoundStr = AddonSelector_GetLocalizedText("packNameLoadNotFound")
local packNameLoadFoundStr = AddonSelector_GetLocalizedText("packNameLoadFound")
local addPackToKeybindStr = AddonSelector_GetLocalizedText("addPackToKeybind")
local removePackFromKeybindStr = AddonSelector_GetLocalizedText("removePackFromKeybind")
local loadOnLogoutOrQuitStr = AddonSelector_GetLocalizedText("loadOnLogoutOrQuit")
local skipLoadAddonPackStr = AddonSelector_GetLocalizedText("skipLoadAddonPack")


--Boolean to on/off texts for narration
local booleanToOnOff = {
    [false] = GetString(SI_CHECK_BUTTON_OFF):upper(),
    [true]  = GetString(SI_CHECK_BUTTON_ON):upper(),
}
--Prefix strings for narration, based on e.g. ZO_Menu Owner control
local prefixStrings = {
    ["AddonSelectorSettingsOpenDropdown"] = settingStr,
    ["AddonSelectorSearchBox"] =            searchHistoryStr,
}

local narrateComboBoxOnMouseEnter, narrateDropdownOnMouseExit, narrateDropdownOnOpened, narrateDropdownOnClosed
local narrateDropdownOnSubmenuShown, narrateDropdownOnSubmenuHidden, narrateDropdownOnEntryMouseEnter, narrateDropdownOnEntryMouseExit
local narrateDropdownOnEntrySelected, narrateDropdownOnCheckboxUpdated

--LibScrollableMenu - Default contextMenu options
local LSM_defaultAddonPackMenuOptions = {
    visibleRowsDropdown = 15,
    visibleRowsSubmenu = 15,
    sortEntries = false,
    enableFilter        = function() return AS.acwsv.showSearchFilterAtPacksList end,
    headerCollapsible   = true,

    narrate = {
        ["OnComboBoxMouseEnter"] =  narrateComboBoxOnMouseEnter,
        --["OnComboBoxMouseExit"] =   narrateDropdownOnMouseExit,
        --["OnMenuShow"] =			narrateDropdownOnOpened,
        --["OnMenuHide"] =			narrateDropdownOnClosed,
        ["OnSubMenuShow"] =			narrateDropdownOnSubmenuShown,
        ["OnSubMenuHide"] =		    narrateDropdownOnSubmenuHidden,
        ["OnEntryMouseEnter"] =		narrateDropdownOnEntryMouseEnter,
        --["OnEntryMouseExit"] =	narrateDropdownOnEntryMouseExit,
        ["OnEntrySelected"] =		narrateDropdownOnEntrySelected,
        ["OnCheckboxUpdated"] =		narrateDropdownOnCheckboxUpdated,
    }
}

local LSM_defaultContextMenuOptions = {
    visibleRowsDropdown = 15,
    visibleRowsSubmenu  = 15,
    sortEntries         = false,
    enableFilter        = function() return AS.acwsv.showSearchFilterAtPacksList end,
    headerCollapsible   = true,
}

------------------------------------------------------------------------------------------------------------------------
-- Helper functions
------------------------------------------------------------------------------------------------------------------------
local function throttledCall(func, delay, updaterName, ...)
    delay = delay or 0
    if updaterName ~= "" then
        EM:UnregisterForUpdate(updaterName)
        if type(func) == "function" then
            local args = {...}
            local function updateNow()
                EM:UnregisterForUpdate(updaterName)
                func(unpack(args))
            end

            EM:RegisterForUpdate(updaterName, delay, updateNow)
        end
    end
end

--Split string at whitespace unless quoted with " or ' or escaped with \"
local spat, epat, escap = [=[^(['"])]=], [=[(['"])$]=], [=[(\*)['"]$]=]
local function splitStringAndRespectQuotes(text)
    local retTab = {}
    if text == nil or text == "" then return retTab end
    local buf, quoted
    for str in text:gmatch("%S+") do
        local squoted = str:match(spat)
        local equoted = str:match(epat)
        local escaped = str:match(escap)
        if squoted and not quoted and not equoted then
            buf, quoted = str, squoted
        elseif buf and equoted == quoted and #escaped % 2 == 0 then
            str, buf, quoted = buf .. ' ' .. str, nil, nil
        elseif buf then
            buf = buf .. ' ' .. str
        end
        if not buf then
            local val = str:gsub(spat,""):gsub(epat,"")
--d(">Found: " .. tos(val))
            retTab[#retTab+1] = val
        end
    end
    return retTab
end
--AS.splitStringAndRespectQuotes = splitStringAndRespectQuotes

local function checkIfMenuOwnerIsZOAddOns()
    local menuOwner = GetMenuOwner()
    if menuOwner ~= nil and menuOwner.GetOwningWindow ~= nil and menuOwner:GetOwningWindow() == ZOAddOns then return true end
    return false
end

local function getOwnerPrefixStr(ownerCtrl)
    if not ownerCtrl or not ownerCtrl.GetName then return "" end
    return prefixStrings[ownerCtrl:GetName()] or ""
end

local function sortNonNumberKeyTableAndBuildSortedLookup(tab)
    local addonPackToIndex = {}
    for k, _ in pairs(tab) do
        tins(addonPackToIndex, k)
    end
    tsor(addonPackToIndex)
    return addonPackToIndex
end

local function updateEnableAllAddonsCtrls()
    enableAllAddonsParent = enableAllAddonsParent or GetControl("ZO_AddOnsList2Row1")
    if enableAllAddonsParent == nil then return end
    enableAllAddonsCheckboxCtrl = enableAllAddonsCheckboxCtrl or GetControl(enableAllAddonsParent, "Checkbox")
    enableAllAddonTextCtrl = enableAllAddonTextCtrl or GetControl(enableAllAddonsParent, "Text")
end
updateEnableAllAddonsCtrls()

--Function to get all characters of the currently logged in @account: server's unique characterID and non unique name.
--Returns a table:nilable with 2 possible variants, either the character ID is key and the name is the value,
--or vice versa.
--Parameter boolean, keyIsCharName:
-->True: the key of the returned table is the character name
-->False: the key of the returned table is the unique character ID (standard)
local function getCharactersOfAccount(keyIsCharName)
    keyIsCharName = keyIsCharName or false
    local charactersOfAccount, charactersOfAccountLower
    --Check all the characters of the account
    for i = 1, GetNumCharacters() do
        local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
        local charName = zo_strformat(SI_UNIT_NAME, name)
        if characterId ~= nil and charName ~= "" then
            if charactersOfAccount == nil then charactersOfAccount = {} end
            if charactersOfAccountLower == nil then charactersOfAccountLower = {} end
            if keyIsCharName then
                charactersOfAccount[charName]   = characterId
                charactersOfAccountLower[strlow(charName)]   = characterId
            else
                charactersOfAccount[characterId]= charName
                charactersOfAccountLower[characterId]= strlow(charName)
            end
        end
    end
    return charactersOfAccount, charactersOfAccountLower
end
AS.charactersOfAccount, AS.charactersOfAccountLower     = getCharactersOfAccount(false)
AS.characterIdsOfAccount, AS.characterIdsOfAccountLower = getCharactersOfAccount(true)
local charactersOfAccount   = AS.charactersOfAccount
local charactersOfAccountLower   = AS.charactersOfAccountLower
local characterIdsOfAccount = AS.characterIdsOfAccount
local characterIdsOfAccountLowerCase = AS.characterIdsOfAccountLower

local function getCharacterIdByName(characterName)
    local characterIdOfCharacterName = characterIdsOfAccount[characterName]
    if characterIdOfCharacterName == nil then
        characterIdOfCharacterName = characterIdsOfAccountLowerCase[strlow(characterName)]
    end
    return characterIdOfCharacterName
end

local function unselectAnyPack(selectedPackLabelToo)
--d("[AS]unselectAnyPack - selectedPackLabelToo: " .. tos(selectedPackLabelToo))
    local AddonSelectorDDL = AS.comboBox
    if AddonSelectorDDL == nil then return end
    AddonSelectorDDL:ClearAllSelections()
    AddonSelectorDDL:SetSelectedItemText("")

    if AS.editBox then
        AS.editBox:Clear()
    end

    if not selectedPackLabelToo then return end
    local selectedPackLabel = AS.selectedPackNameLabel
    if selectedPackLabel ~= nil then
        selectedPackLabel:SetText("")
    end
end
------------------------------------------------------------------------------------------------------------------------
-- Accessibility - Narration
------------------------------------------------------------------------------------------------------------------------
local chatNarrationUpdaterName = "AddonSelector_ChatNarration-"
local suppressOnMouseEnterNarration = false
local wasSearchNextDoneByReturnKey = false --variable to suppress the OnMouseEnter narration on addon rows if return key was used to jump to next search result
AS.selectedAddonSearchResult = nil

local onMouseEnterHandlers_ZOAddOns_done = {}
--Do not narrate any text if mouse is moved above this control at ZO_AddOns
local ZOAddOns_BlacklistedNarrationChilds = {
    ["ZO_AddOnsTitle"]                      = true, --Title
    ["ZO_AddOnsSectionBar"]                 = true, --Top bar where Votans Addon List adds buttons to scroll to addons/libraries
    ["ZO_AddOnsList"]                       = true, --The scroll list with the addon rows
    ["ZO_AddOnsBGLeft"]                     = true, --The left background
    ["ZO_AddOnsDivider"]                    = true, --The divider
    ["ZO_AddOnsCharacterSelectDropdown"]    = true, --Character selection dropdown box
    ["AddOnSelector"]                       = true, --this addon here -> Will be added separately
    ["ZO_AddOnsAdvancedUIErrors"]           = true, --Enhanced UI errors: Checkbox & label
}
--Do not narrate any text if mouse is moved above this control at ZO_AddOns -> AddOnSelector
local ZOAddOns_AddonSelector_BlacklistedNarrationChilds = {
    ["AddonSelector"]                       = true,
    ["AddonSelectorEditBoxBG"]              = true,
    ["AddonSelectorSaveModeTexture"]        = true,
    ["AddonSelectorAutoReloadUITexture"]    = true,
    ["AddonSelectorBottomDivider"]          = true,
    ["AddonSelectorSearchBox"]              = true,
    ["AddonSelectorddl"]                    = true,
    ["AddonSelectorEditBox"]                = true,
    ["AddonSelectorSettingsOpenDropdown"]   = true,
}





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
--AddonSelector.AddNewChatNarrationText = AddNewChatNarrationText

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

local function isAddonPackDropdownOpen()
    return AS.ddl.m_comboBox:IsDropdownVisible()
end

local function getAddonNameFromData(addonData)
    if addonData == nil then return end
    local addonName = addonData.strippedAddOnName
    addonName = addonName or addonData.addOnName
    return addonName
end

local function getAddonNameAndData(control)
    if control == nil then return nil, nil end
    local addonData
    local addonName

    addonData = control.data
    if addonData == nil or addonData.addOnName == nil then
        --Get the parent of the "name", "expand" or "checkbox" controls
        local parent = control:GetParent()
        if parent ~= nil and parent.data == nil then
            if control.GetText == nil then return nil, nil end
            addonName = control:GetText()
        elseif parent.data ~= nil then
            addonData = parent.data
        end
    end

    if addonName == nil and addonData ~= nil then
        addonName = getAddonNameFromData(addonData)
    end
--d(">getAddonNameAndData: " ..tos(addonName) .. ", data: " ..tos(addonData))
    if addonName == nil or addonName == "" then return nil, nil end
    return addonName, addonData
end

local function isAddonRow(rowControl)
    if rowControl == nil then return false, nil end
    if rowControl:GetOwningWindow() ~= ZOAddOns then
--d("<isAddonRow: no ZO_AddOns owner!")
        return false, nil
    end

    local addonName, addonData = getAddonNameAndData(rowControl)
    if addonName ~= nil and addonData ~= nil and addonData.addOnName ~= nil then return true, addonData end
    return false, nil
end

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
        globalOrCharPackStr = packGlobalStr.. ", " .. packNameStr
    else
        globalOrCharPackStr = packCharNameStr
        if not data.isCharacterPackHeader then
            globalOrCharPackStr = globalOrCharPackStr .. ": '"..charName.."' - "
        end
    end
    return globalOrCharPackStr .. ": " .. entryText
end

local function getAddonEntryByScrollToIndex(scrollToIndex)
    if scrollToIndex == nil then
        wasSearchNextDoneByReturnKey = false
        return
    end
    local addonList = ZOAddOnsList.data
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

local function getAddonNarrateTextByData(addonData, prefixStr)
    if addonData == nil then return end

    local addonName = getAddonNameFromData(addonData)
    if addonName == nil then return end

    local narrateAboutAddonText = addonName
    local hasDependencyError = false
    local isLibrary = false
    if addonData.hasDependencyError ~= nil and addonData.hasDependencyError == true then
        narrateAboutAddonText = narrateAboutAddonText .. string.format("["..stateText.."] %s", GetString(SI_ADDONLOADSTATE5) .. " " .. GetString(SI_GAMEPAD_ARMORY_MISSING_ENTRY_NARRATION)) -- Dependency missing
        hasDependencyError = true
    end
    if hasDependencyError == false then
        if addonData.addOnEnabled ~= nil and addonData.addOnEnabled == false then
            narrateAboutAddonText = narrateAboutAddonText .. string.format("["..stateText.."] %s", GetString(SI_ADDONLOADSTATE3)) --Disabled
        elseif addonData.addOnEnabled ~= nil and addonData.addOnEnabled == true then
            narrateAboutAddonText = narrateAboutAddonText .. string.format("["..stateText.."] %s", GetString(SI_ADDONLOADSTATE2)) --Enabled
        end
    end
    if addonData.isLibrary ~= nil and addonData.isLibrary == true then
        narrateAboutAddonText = "[" .. libraryText .. "] " .. narrateAboutAddonText
        isLibrary = true
    end
    if isLibrary == false and zo_strfind(addonName, "Lib", 1, true) ~= nil then
        narrateAboutAddonText = "[" .. libraryText .. "] " .. narrateAboutAddonText
    end

    if prefixStr ~= nil and prefixStr ~= "" then
        narrateAboutAddonText = prefixStr .. narrateAboutAddonText
    end

    return narrateAboutAddonText
end

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
        foundText = searchFoundLast .. " "
    else
        foundText = searchFound .. " "
    end

    if searchValue ~= nil and searchValue ~= "" then
        foundText = searchedForStr .. "  " ..searchValue .. "  -  " .. foundText
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

local function getZOAddOnsUI_ControlText(control)
    if control == nil then return end
    local retText
    local retTextSuffix
    --Checkbox at parent?
    local parentCtrl = control:GetParent()
    if parentCtrl.GetState ~= nil then
        local currentState = parentCtrl:GetState()
        if currentState == BSTATE_PRESSED then
            retTextSuffix = " [" .. checkboxStr .. " " .. currentlyStr .. "]   " .. GetString(SI_SCREEN_NARRATION_TOGGLE_ON)
        else
            retTextSuffix = " [" .. checkboxStr .. " " .. currentlyStr .. "]   " .. GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
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

local function narrateAddonsEnabledTotal()
    local numAddonsEnabled = AS.numAddonsEnabled
    local numAddonsTotal = AS.numAddonsTotal
    --AddonSelector.numAddonsTotal = 0
    AddNewChatNarrationText("[" ..GetString(SI_WINDOW_TITLE_ADDON_MANAGER) .. "] - " ..tostring(numAddonsEnabled) .. " - " ..GetString(SI_ADDON_MANAGER_ENABLED)
            .. "   [" ..GetString(SI_TRADINGHOUSESORTFIELD2) .. "] - "..tos(numAddonsTotal), false)
end

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
            end, "AddonSelector_NarrateUIControlOnMouseEnter")
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

--[[
local function onMenuItemMouseEnterNarrate(menuItem)
    --Get the ZO_Menu.items[i] text and narrate it OnMouseEnter
    local narrateText = menuItem.name
    onMouseEnterDoNarrate(menuItem, narrateText, nil, true)
end
]]

function narrateComboBoxOnMouseEnter()
    onMouseEnterDoNarrate(AS.ddl, "["..selectPackStr .. " %s]   -   " .. openDropdownStr, function() return getZOAddOnsUI_ControlText(AS.ddl) end)
    AS.narrateSelectedPackEntryStr = nil
   --return "Test text", false
end

local entryMouseEnterTextForSubmenuOpen, entryOnMouseEnterDone, entryOnSelectedDone

function narrateDropdownOnSubmenuHidden(scrollHelper, ctrl)
--d("Submenu closed: " ..tos(entryOnSelectedDone) .. ", entryOnMouseEnterDone: " ..tos(entryOnMouseEnterDone))
    local submenuClosedText = "["..submenuClosedStr.."]"
    return submenuClosedText, false
end

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
    local submenuOpenedText = "["..submenuOpenedStr.."]" .. anchoredToStr

    --Add text from narrateDropdownOnEntryMouseEnter?
    if entryMouseEnterTextForSubmenuOpen ~= nil then
        submenuOpenedText = entryMouseEnterTextForSubmenuOpen .. "   -   " .. submenuOpenedText
        entryMouseEnterTextForSubmenuOpen = nil
    end
    return submenuOpenedText, false --do not stop any other narration (e.g. OnMousEnter on a menu entry)
end

function narrateDropdownOnEntryMouseEnter(scrollhelperObject, entryControl, data, hasSubmenu, comingFromCheckbox)
--d("OnEntryMouseEnter - hasSubmenu: " ..tos(hasSubmenu) .. ", comingFomrCheckbox: " ..tos(comingFromCheckbox) .. ", name: " ..tos(data.label or data.name))
    entryOnMouseEnterDone = true
    entryMouseEnterTextForSubmenuOpen = nil
    local entryTextWithoutPrefix = getDropdownEntryPackEntryText(entryControl, data, hasSubmenu)

    local entryMouseEnterText = "["..entryMouseEnterStr.."]" .. entryTextWithoutPrefix

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
        currentStateText = currentTextStr ..":   " .. currentStateText
        entryMouseEnterText = entryMouseEnterText .. "  [" .. checkboxStr .. "] " .. currentStateText
    end

    --Got a submenu that opens?
    if hasSubmenu == true and data and data.entries ~= nil then
        local submenuEntriesCount = tos(countSubmenuEntries(data.entries))
        entryMouseEnterText = entryMouseEnterText .. " (" .. submenuEntriesCount .. entriesStr .. ")"

        --If a submenu opens: The narrateDropdownOnSubmenuShown will be called. So narrate the total text of the entry selected here, and the
        --submenu opened right/left at this function!
        entryMouseEnterTextForSubmenuOpen = entryMouseEnterText
        --Do not narrate here, but do this together with the OnSubmenuOpen text at narrateDropdownOnSubmenuShown
        return
    end

    return entryMouseEnterText, false --do not stop narration of e.g. submenu opened
end

function narrateDropdownOnEntrySelected(scrollhelperObject, entryControl, data, hasSubmenu)
    entryOnSelectedDone = true
    --d("OnEntrySelected - hasSubmenu: " ..tos(hasSubmenu))
    local entryTextWithoutPrefix = getDropdownEntryPackEntryText(entryControl, data, hasSubmenu)
    local entrySelectedText = "["..entrySelectedStr.."]" .. entryTextWithoutPrefix
    return entrySelectedText, true --stop narration of others, if you select an entry
end

function narrateDropdownOnCheckboxUpdated(scrollhelperObject, checkboxControl, data)
    --d("OnCHeckboxUpdated")
    return narrateDropdownOnEntryMouseEnter(scrollhelperObject, checkboxControl, data, nil, true)
end

local function enableZO_AddOnsUI_controlNarration()
    --Enable all addons checkbox
    if enableAllAddonsCheckboxCtrl ~= nil then
        local function narrateTextFunc()
            --As the same row ZO_AddOnsList2Row1 will contain the "Libraries" text, if you scroll down (due to the row control pool) we need to check for the checkbox's visibility!
            if enableAllAddonsCheckboxCtrl:IsHidden() then
                OnUpdateDoNarrate("OnZOAddOnsUI_ControlMouseEnter", 75, function() AddNewChatNarrationText(GetString(SI_ADDON_MANAGER_SECTION_LIBRARIES), true)  end)
            else
                local currentStateText1 = ""
                local currentStateText2 = ""
                local currentState = enableAllAddonsCheckboxCtrl:GetState()
                if currentState == BSTATE_PRESSED then
                    currentStateText1 = enableText
                    currentStateText2 = GetString(SI_SCREEN_NARRATION_TOGGLE_ON)
                else
                    currentStateText1 = disableText
                    currentStateText2 = GetString(SI_SCREEN_NARRATION_TOGGLE_OFF)
                end
                local narrateText = strfor(enDisableCurrentStateTemplateText, currentStateText1, currentStateText2) --"%s all addons. Current state   -   %s"
                OnUpdateDoNarrate("OnZOAddOnsUI_ControlMouseEnter", 75, function() AddNewChatNarrationText(narrateText, true)  end)
            end
        end
        onMouseEnterDoNarrate(enableAllAddonsCheckboxCtrl, nil, narrateTextFunc)
        onMouseEnterDoNarrate(enableAllAddonTextCtrl, nil, narrateTextFunc)
    end

    --Title
    if ZO_AddOnsTitle ~= nil then
        ZO_AddOnsTitle:SetMouseEnabled(true)
        onMouseEnterDoNarrate(ZO_AddOnsTitle, nil, narrateAddonsEnabledTotal)
    end

    --Search box
    if AS.searchBox ~= nil then
        onMouseEnterDoNarrate(AS.searchBox, "["..searchMenuStr .. " %s]", function() return getZOAddOnsUI_ControlText(AS.searchBox)  end)
    end

    --Pack name edit box
    if AS.editBox ~= nil then
        onMouseEnterDoNarrate(AS.editBox, "["..packNameStr .. " %s]", function() return getZOAddOnsUI_ControlText(AS.editBox) end)
    end

    --Pack name dropdown box
    --[[
    if AddonSelector.ddl ~= nil then
        onMouseEnterDoNarrate(AddonSelector.ddl, "["..selectPackStr .. " %s]   -   " .. openDropdownStr, function() return getZOAddOnsUI_ControlText(AddonSelector.ddl) end)
    end
    ]]

    local controlsParent = ZOAddOns
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

    controlsParent = AS.addonSelectorControl
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

------------------------------------------------------------------------------------------------------------------------
-- Addon Selector
---------------------------------------------------------------------------------------------------------------------------
ADDON_MANAGER           = GetAddOnManager()
AS.ADDON_MANAGER        = ADDON_MANAGER
--Maybe nil here
AS.ADDON_MANAGER_OBJECT = ADDON_MANAGER_OBJECT

--The drop down list for the packs -> ZO_ScrollableComboBox
local isAreAddonsEnabledFuncGiven = (ADDON_MANAGER.AreAddOnsEnabled ~= nil) or false

local addonSelectorSelectAddonsButtonNameLabel


local currentCharIdNum = GetCurrentCharacterId()
local currentCharId = tos(currentCharIdNum)
local currentCharName = ZO_CachedStrFormat(SI_UNIT_NAME, GetUnitName("player"))

--Other addons
--[AddonCategory]
local isAddonCategoryEnabled = false
local addonCategoryCategories, addonCategoryIndices


local doNotReloadUI = false


--Clean the color codes from the addon name
--[[
local function stripText(text)
    return text:gsub("|c%x%x%x%x%x%x", "")
end
]]

local function areAddonsCurrentlyEnabled()
    return ADDON_MANAGER:AreAddOnsEnabled()
end

local function getSVTableForPacksOfCharname(charName, characterId)
    if charName == nil and characterId == nil then return end
    local addonPacksOfChar = AS.acwsv.addonPacksOfChar
    if addonPacksOfChar then
        for charId, packsData in pairs(addonPacksOfChar) do
            local addonPacksCharName = packsData[CHARACTER_PACK_CHARNAME_IDENTIFIER]
            if addonPacksCharName ~= GLOBAL_PACK_NAME then
                if charName ~= nil then
                    if addonPacksCharName == charName then
                        return addonPacksOfChar[charId], charId, charName
                    end
                else
                    if charId == characterId then
                        return addonPacksOfChar[charId], charId, addonPacksCharName
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

local function getSVTableForPackBySavedType(globalOrCharName, characterId)
    if globalOrCharName == GLOBAL_PACK_NAME then
        return AS.acwsv.addonPacks, nil
    else
        return getSVTableForPacksOfCharname(globalOrCharName, characterId)
    end
end

local function getCharacterIdFromSVTableByCharacterName(charName)
    local addonPacksOfChar = AS.acwsv.addonPacksOfChar
    for charId, packsData in pairs(addonPacksOfChar) do
        local addonPacksCharName = strlow(packsData[CHARACTER_PACK_CHARNAME_IDENTIFIER])
        if addonPacksCharName ~= strlow(GLOBAL_PACK_NAME) and addonPacksCharName == strlow(charName) then
            return charId
        end
    end
    return
end

local function getCharacterIdAndNameForSV(characterName)
--d("[AS]getCharacterIdAndNameForSV - characterName: " ..tos(characterName))
    local characterIdForSV = currentCharId
    local charNameForSV = currentCharName

    if characterName ~= nil then
        characterIdForSV = nil
        charNameForSV = characterName
        characterIdForSV = getCharacterIdByName(characterName)
--d(">>characterIdForSV: " ..tos(characterIdForSV) .. " / currentCharId: " ..tos(currentCharId))
        local settings = AS.acwsv
        local addonPacksOfChar = settings.addonPacksOfChar

        --Character name could be the one of another account -> Check SV tabe if it exists and get it's id from there
        if characterIdForSV == nil and addonPacksOfChar ~= nil and settings.showPacksOfOtherAccountsChars then
            characterIdForSV = getCharacterIdFromSVTableByCharacterName(characterName)
        end
        if characterIdForSV == nil or addonPacksOfChar == nil or addonPacksOfChar[characterIdForSV] == nil then return nil, nil end
    end
--d("<characterIdForSV: " .. tos(characterIdForSV) .. ", charNameForSV: " ..tos(charNameForSV))
    return characterIdForSV, charNameForSV
end

-- Create the pack table or nil it out if it exists.
-- Distinguish between packs grouped for charactes or general packs
local function createSVTableForPack(packName, characterName, wasPackNameProvided)
    wasPackNameProvided = wasPackNameProvided or false
    local settings = AS.acwsv
    if (wasPackNameProvided == true or settings.saveGroupedByCharacterName == true) and (characterName == nil or (characterName ~= nil and characterName ~= GLOBAL_PACK_NAME)) then
        local characterIdForSV, charNameForSV = getCharacterIdAndNameForSV(characterName)
        if characterIdForSV == nil or charNameForSV == nil then return nil end

        AS.acwsv.addonPacksOfChar[characterIdForSV]           = AS.acwsv.addonPacksOfChar[characterIdForSV] or {}
        AS.acwsv.addonPacksOfChar[characterIdForSV]._charName = charNameForSV
        AS.acwsv.addonPacksOfChar[characterIdForSV][packName] = {}
--d(">>returning the char SV table, charId: " ..tos(characterIdForSV) .. ", packName: " ..tos(packName))
        return AS.acwsv.addonPacksOfChar[characterIdForSV][packName]
    else
--d(">>returning the global SV table, packName: " ..tos(packName))
        AS.acwsv.addonPacks[packName] = {}
        return AS.acwsv.addonPacks[packName]
    end
    return
end

local function getSVTableForPacks(characterName)
--d("[AS]getSVTableForPacks - characterName: " ..tos(characterName))

    local settings = AS.acwsv
    if settings.saveGroupedByCharacterName or (characterName ~= nil and characterName ~= GLOBAL_PACK_NAME) then
        local characterIdForSV, charNameForSV = getCharacterIdAndNameForSV(characterName)
        if characterIdForSV == nil or charNameForSV == nil then return nil end

        --Table for current char does not exist yt, so create it. Else a new saved pack will be compared to the global
        --packs and if the name matches it will be saved as global!
        AS.acwsv.addonPacksOfChar                             = AS.acwsv.addonPacksOfChar or {}
        AS.acwsv.addonPacksOfChar[characterIdForSV]           = AS.acwsv.addonPacksOfChar[characterIdForSV] or {}
        AS.acwsv.addonPacksOfChar[characterIdForSV]._charName = charNameForSV
        return AS.acwsv.addonPacksOfChar[characterIdForSV], charNameForSV
    end
    return AS.acwsv.addonPacks, nil
end

local function saveAddonsAsPackToSV(packName, isPackBeforeMassMark, characterName, wasPackNameProvided)
    isPackBeforeMassMark = isPackBeforeMassMark or false
    local l_svForPack = (not isPackBeforeMassMark and createSVTableForPack(packName, characterName, wasPackNameProvided)) or (isPackBeforeMassMark == true and {})

--d("[AS]saveAddonsAsPackToSV-packName: " ..tos(packName) .. "; isPackBeforeMassMark: " .. tos(isPackBeforeMassMark) .. "; characterName: " ..tos(characterName) .. "; wasPackNameProvided: " ..tos(wasPackNameProvided))
    if l_svForPack == nil then return end
    --#15 If any main-addon was disabled by clicking that addon line, and sub-addons that depend on the main addon were automatically
    --disabled too, the SavedVariables pack here must take the sub-addons into account too: They need to be removed from the pack
    --automatically! Checking only the enabled state will add those to the pack allthough they got dependency errors

    -- Add all of the enabled addOn to the pack table
    local aad = ZO_ScrollList_GetDataList(ZOAddOnsList)
    for _, addonData in pairs(aad) do
        local data = addonData.data
        local isEnabled = data.addOnEnabled
        local hasDependencyError = data.hasDependencyError --#15

        if isEnabled and not hasDependencyError then
            local fileName = data.addOnFileName
            local addonName = data.strippedAddOnName
            --Set the addon to the pack into the SavedVariables
            l_svForPack[fileName] = addonName
        end
    end
--AddonSelector._debugSVForPack = l_svForPack
    --Try to save the addon packs to your SV "NOW" without reloadui
    --Will only work once every 15mins, and only if your SV file is < 50kb and will not happen instantly, but maybe soon within 3 mins (w/o a ReloadUI)
    ADDON_MANAGER:RequestAddOnSavedVariablesPrioritySave(ADDON_NAME)

    return l_svForPack
end

local function saveAddonsAsPackBeforeMassMarking()
    AS.acwsv.lastMassMarkingSavedProfile     = nil
    AS.acwsv.lastMassMarkingSavedProfile     = saveAddonsAsPackToSV("LastAddonsBeforeMassMarking", true)
    AS.acwsv.lastMassMarkingSavedProfileTime = GetTimeStamp()
end


--Deselect the combobox entry
local function deselectComboBoxEntry()
--d("[AS]deselectComboBoxEntry")
    local comboBox = AS.comboBox
    if comboBox then
        comboBox:SetSelectedItem("")
        comboBox.m_selectedItemData = nil
    end
end

local function selectPreviouslySelectedPack(beforeSelectedPackData)
    beforeSelectedPackData = beforeSelectedPackData or AS.currentlySelectedPackData
    AS.comboBox:SelectItem(beforeSelectedPackData, true) --ignore the callback for entry selected!
end

--Check if dependencies of an addon are given and enable them, if not already enabled
--> This function was taken from addon "Votans Addon List". All credits go to Votan!
local dependencyLevel = 0
local function checkDependsOn(data)
--d(">checkDependsOn")
    if not data or (data and not data.dependsOn) then return end
    -- assume success to break recursion
    data.addOnEnabled, data.addOnState = true, ADDON_STATE_ENABLED

    dependencyLevel = dependencyLevel + 1

    local other
    for i = 1, #data.dependsOn do
        other = data.dependsOn[i]
--d(">dependency (level "..tos(dependencyLevel).."): " ..tos(other.strippedAddOnName))
        if other.addOnState ~= ADDON_STATE_ENABLED and not other.missing then
            checkDependsOn(other)
        end
    end
    ADDON_MANAGER:SetAddOnEnabled(data.index, true)
    -- Verify success
    --data.addOnEnabled, data.addOnState = select(5, ADDON_MANAGER:GetAddOnInfo(data.index))
    --return data.addOnState == ADDON_STATE_ENABLED
    dependencyLevel = dependencyLevel - 1
end

--Enable/Disable all the controls of this addon depending on the enabled checkbox for all addons
local function setThisAddonsControlsEnabledState(enabledState)
    local addonSelectorTLC = AS.addonSelectorControl
    local numChildControls = addonSelectorTLC:GetNumChildren()
    if numChildControls <= 0 then return end
    for childindex=1, numChildControls, 1 do
        local childControl = addonSelectorTLC:GetChild(childindex)
        if not isExcludedFromChangeEnabledState[childControl:GetName()] then
            if childControl ~= nil and childControl.SetMouseEnabled and childControl.IsHidden then
                childControl:SetMouseEnabled(enabledState)
            end
        end
    end
    AddonSelectorddlOpenDropdown:SetMouseEnabled(enabledState)
end

--Check if the checkbox to disable all addons is enabled or not
local function areAllAddonsEnabled(noControlUpdate)
    noControlUpdate = noControlUpdate or false
    if not isAreAddonsEnabledFuncGiven then
        --[[
        if not noControlUpdate then
            setThisAddonsControlsEnabledState(true)
        end
        ]]
        return true
    end

    local areAllAddonsCurrentlyEnabled = areAddonsCurrentlyEnabled()
    if not noControlUpdate then
        setThisAddonsControlsEnabledState(areAllAddonsCurrentlyEnabled)
    end
    --d("[CAS]areAllAddonsEnabled: " ..tos(areAllAddonsCurrentlyEnabled) .. ", noControlUpdate: " ..tos(noControlUpdate))
    return areAllAddonsCurrentlyEnabled
end

-- Toggles Enabled state when a row is clicked
-->Using  Votans Addon List function ADD_ON_MANAGER:OnEnabledButtonClicked so that dependencies are enabled too
local function Addon_Toggle_Enabled(rowControl, addonData)
--d("Addon_Toggle_Enabled")
    if not areAllAddonsEnabled(true) then return end

    --local addonIndex 	= rowControl.data.index
    local enabledBtn 	= rowControl:GetNamedChild("Enabled")
    local state 		= ZO_TriStateCheckButton_GetState(enabledBtn)
    local newState

    if state == TRISTATE_CHECK_BUTTON_CHECKED then
        -- changed so it automatically refreshes the multiButton (reload UI)
        --ADDON_MANAGER_OBJECT:ChangeEnabledState(addonIndex, TRISTATE_CHECK_BUTTON_UNCHECKED)
        newState = TRISTATE_CHECK_BUTTON_UNCHECKED
    else
        --ADDON_MANAGER_OBJECT:ChangeEnabledState(addonIndex, TRISTATE_CHECK_BUTTON_CHECKED)
        newState = TRISTATE_CHECK_BUTTON_CHECKED
    end
--d(">newState: " ..tos(newState))
    ADDON_MANAGER_OBJECT:OnEnabledButtonClicked(enabledBtn, newState)

--d(">1")

    --Accessibility
    --Do not narrate if SHIFT key is pressed to "multi-select" addons (set end spot to enable/disable)?
    if not IsShiftKeyDown() then
        OnAddonRowClickedNarrateNewState(rowControl, newState, addonData)
    end
end

local function getCurrentCharsPackNameData()
    --Get the currently selected packname from the SavedVariables
    local packNamesForCharacters = AS.acwsv.selectedPackNameForCharacters
    if not packNamesForCharacters then return nil, nil end
    local currentlySelectedPackData = packNamesForCharacters[currentCharId]
    return currentCharId, currentlySelectedPackData
end

--Update the currently selected packName label
local function UpdateCurrentlySelectedPackName(wasDeleted, packName, packData, isCharacterPack)
--d("[AS]UpdateCurrentlySelectedPackName-wasDeleted: " ..tos(wasDeleted) .. ", packName: " .. tos(packName) .. ", charName: " .. tos(packData ~= nil and packData.charName) .. ", isCharacterPack: " .. tos(isCharacterPack))
    wasDeleted = wasDeleted or false
    local packNameLabel = AS.selectedPackNameLabel
    if not packNameLabel then return end
    local savePackPerCharacter = AS.acwsv.saveGroupedByCharacterName

    local currentlySelectedPackName
    local currentlySelectedPackCharName
    local currentCharacterId = currentCharId
    if packName == nil or packName == "" or packData == nil then
--d(">2")
        local currentlySelectedPackNameData
        currentCharacterId, currentlySelectedPackNameData = getCurrentCharsPackNameData()
        if not currentCharacterId or not currentlySelectedPackNameData then return end
        currentlySelectedPackName = currentlySelectedPackNameData.packName
        if wasDeleted then
--d(">3")
            --If pack was deleted:
            --Reset the pack character to the currently logged in charname if settings to save per character are enabled.
            --Else reset to "Global" name
            currentlySelectedPackCharName = (savePackPerCharacter and currentCharName) or packNameGlobal
        else
--d(">4")
            currentlySelectedPackCharName = (currentlySelectedPackNameData.charName and ((currentlySelectedPackNameData.charName == GLOBAL_PACK_NAME and packNameGlobal) or currentlySelectedPackNameData.charName))
        end
    else
--d(">5")
        currentlySelectedPackName = packName
        currentlySelectedPackCharName = (packData.charName and ((packData.charName == GLOBAL_PACK_NAME and packNameGlobal) or packData.charName)) or "n/a"
    end
--d("[AddonSelector]currentlySelectedPackName: " ..tos(currentlySelectedPackName) ..", currentlySelectedPackCharName: " ..tos(currentlySelectedPackCharName))

    --Pack was not deleted -> normal upate of label?
    if not wasDeleted then
        if not currentlySelectedPackName then return end
    else
        --Pack was deleted. Remove currently selected pack from SV and clear the label
        currentlySelectedPackName                                  = ""
        AS.acwsv.selectedPackNameForCharacters[currentCharacterId] = nil
    end
    if currentlySelectedPackName then
--d(">6")
        --Packs are saved per character? Show the character that belongs to teh currently selected pack
        local packNameText
        packNameText = strfor(selectedPackNameStr, strfor(charNamePackColorTemplate, currentlySelectedPackCharName))
        packNameText = packNameText .. currentlySelectedPackName
        packNameLabel:SetText(packNameText)

        if not wasDeleted then
            AS.currentlySelectedPackData = AS.comboBox:GetSelectedItemData()
        end
    end
end

--Get the currently selected pack name and the character owning the pack for the currently logged in character
--as the user interfaces reloaded and the pack was loaded
local function GetCurrentCharacterSelectedPackname()
--d("GetCurrentCharacterSelectedPackname-currentCharId: " .. tos(currentCharId))
    --Get the current character's uniqueId
    if not currentCharId then return end
    --Set the currently selected packname to the SavedVariables
    return AS.acwsv.selectedPackNameForCharacters[currentCharId]
end


--Set the currently selected pack name and the character owning the pack for the currently logged in character
local function SetCurrentCharacterSelectedPackname(currentlySelectedPackName, packData, isCharacterPack)
--d("SetCurrentCharacterSelectedPackname: " ..tos(currentlySelectedPackName) .. ", charName: " ..tos(packData.charName))
    if not currentlySelectedPackName or currentlySelectedPackName == "" or packData == nil then return end
    --Get the current character's uniqueId
    if not currentCharId then return end
    --Set the currently selected packname to the SavedVariables
    AS.acwsv.selectedPackNameForCharacters[currentCharId] = {
        packName = currentlySelectedPackName,
        charName = ((isCharacterPack ~= nil and packData.charName) or (AS.acwsv.saveGroupedByCharacterName == true and packData.charName)) or GLOBAL_PACK_NAME,
        timestamp = GetTimeStamp()
    }
end

--[[
--Set the currently selected global pack for all characters as default pack ot load
--> This will only affect the currently loged in character and next time you login another char it will also use this selected pack then
local function SetAllCharactersSelectedPackname(currentlySelectedPackName, packData)
--d("SetAllCharactersSelectedPackname: " ..tos(currentlySelectedPackName) .. ", charName: " ..tos(packData.charName))
    if not currentlySelectedPackName or currentlySelectedPackName == "" or packData == nil then return end
    --Get the current character's uniqueId
    if not currentCharId then return end
    charactersOfAccount = charactersOfAccount or getCharactersOfAccount(false)
    characterIdsOfAccount = characterIdsOfAccount or getCharactersOfAccount(true)

    --Set the currently selected packname to the SavedVariables, for all characters of the account
    for characterId, charName in pairs(AddonSelector.charactersOfAccount) do
        local charId = tos(characterId)
        if charId ~= currentCharId then
            AddonSelector.acwsv.selectedPackNameForCharacters[charId] = {
                packName = currentlySelectedPackName,
                charName = (AddonSelector.acwsv.saveGroupedByCharacterName == true and packData.charName) or GLOBAL_PACK_NAME, --todo: Do we need to change the packData.charName here to charName of the charcterLoop? Or would that show new entries for "saved packs" of the charName where this pack never was saved for?
                timestamp = GetTimeStamp()
            }
--d("["..ADDON_NAME.."]Set selected pack \'..tos(currentlySelectedPackName)..\' for char \' " ..tos(charName) .. "\'")
        end
    end
end
]]


--Disable/Enable the delete button's enabled state depending on the autoreloadui after pack change checkbox state
local function ChangeDeleteButtonEnabledState(autoreloadUICheckboxState, skipStateCheck)
--d("[AddonSelector]ChangeDeleteButtonEnabledState-autoreloadUICheckboxState: " ..tos(autoreloadUICheckboxState) .. ", skipStateCheck: " ..tos(skipStateCheck))
    local deleteBtn = AS.deleteBtn
    if not deleteBtn then end
    skipStateCheck = skipStateCheck or false
    local checkedBool = false
    local newDeleteButtonEnabledState
    if not skipStateCheck then
        --autoreloadUICheckboxState = autoreloadUICheckboxState or AddonSelector.autoReloadBtn:GetState()
        if autoreloadUICheckboxState == true then checkedBool = true end
    end
    newDeleteButtonEnabledState = not checkedBool
    --New enabled state of delete button would be enabled?
    if newDeleteButtonEnabledState == true then
        --Check if the user selected any dropdown entry yet. If not, disable the button
        local itemData = AS.comboBox:GetSelectedItemData()
        if itemData == nil then
            --No entry selected: Disable delete button
            newDeleteButtonEnabledState = false
        end
    end
    deleteBtn:SetMouseEnabled(newDeleteButtonEnabledState)
    deleteBtn:SetEnabled(newDeleteButtonEnabledState)
end

--Change the pack save buttons's enabled state
local function ChangeSaveButtonEnabledState(newEnabledState)
    newEnabledState = newEnabledState or false
    --Enable/Disable the "Save" button
    local saveButton = AS.saveBtn
    if saveButton then
        saveButton:SetEnabled(newEnabledState)
        saveButton:SetMouseEnabled(newEnabledState)
    end
end

local function updateDDL(wasDeleted)
--d("[AS]updateDDL")
    AS.UpdateDDL(wasDeleted)
end

local function clearAndUpdateDDL(wasDeleted)
--d("[AddonSelector]clearAndUpdateDDL - wasDeleted: " ..tos(wasDeleted))
    updateDDL(wasDeleted)
    AS.editBox:Clear()
    --Disable the "delete pack" button
    ChangeDeleteButtonEnabledState(nil, false)
end


local ASUpdateAddonCountThrottleName = "AddonSelector_UpdateAddonCount_Updater"
local function updateAddonsEnabledCountThrottled(delay)
    delay = delay or 50
    throttledCall(AddonSelectorUpdateCount, delay, ASUpdateAddonCountThrottleName)
end


local ASUpdateDDLThrottleName = "AddonSelector_UpdateDDL_Updater"
local function updateDDLThrottled(delay)
    delay = delay or 250
    throttledCall(updateDDL, delay, ASUpdateDDLThrottleName)
end

local function onAddonPackSelected(addonPackName, addonPackData, noPackUpdate, isCharacterPack)
    noPackUpdate = noPackUpdate or false
--d("[AS]onAddonPackSelected - RefreshData()")
    ADDON_MANAGER_OBJECT:RefreshData()
    ADDON_MANAGER_OBJECT.isDirty = true
    if ADDON_MANAGER_OBJECT.RefreshMultiButton then
        ADDON_MANAGER_OBJECT:RefreshMultiButton()
    end
    ADDON_MANAGER_OBJECT:RefreshKeybinds()

    if not noPackUpdate then
        --Enable the delete button
        ChangeDeleteButtonEnabledState(nil, true)
        --Set the currently selected packname
        SetCurrentCharacterSelectedPackname(addonPackName, addonPackData, isCharacterPack)
        --Update the currently selected packName label
        UpdateCurrentlySelectedPackName(nil, addonPackName, addonPackData, isCharacterPack)
        --Enable the save pack button
        ChangeSaveButtonEnabledState(true)
    end

    --Delay a bit to overwrite other OnMouseEnter narrate texts!
    --[[
    suppressOnMouseEnterNarration = true
    local narrateAddonSelectedPackText = strfor("["..selectedPackNameStr.. "]", addonPackName)
    OnUpdateDoNarrate("OnAddonPackSelected", 150, function()
        suppressOnMouseEnterNarration = false
        AddNewChatNarrationText(narrateAddonSelectedPackText, true)
    end)
    ]]
end


local function updateAddonsEnabledStateByPackData(packData, noUIShown)
    if not packData then return false end
    noUIShown = noUIShown or false
    local addonTable = packData.addonTable or packData
    if not addonTable or NonContiguousCount(addonTable) == 0 then return false end

    local somethingDone = false
    local changed = true

    -- loop until all dependencies are solved.
    while changed do
        changed = false

        if noUIShown == true then
            --If called from Logout() or Quit() function e.g.
            for addonIndex = 1, ADDON_MANAGER:GetNumAddOns() do
                --fileName, title, author, description, enabled, state, isOutOfDate, isLibrary
                local fileName, _, _, _, enabled, _, _, _ = ADDON_MANAGER:GetAddOnInfo(addonIndex)
                if fileName then
                    local addonShouldBeEnabled = addonTable[fileName] ~= nil
                    if addonShouldBeEnabled ~= enabled then
                        somethingDone = true
                        ADDON_MANAGER:SetAddOnEnabled(addonIndex, addonShouldBeEnabled)
                        changed = true
                    end
                end
            end
        else
            local scrollListData = ZO_ScrollList_GetDataList(ZOAddOnsList)
            local numScrollListData = #scrollListData
            for k = 1, numScrollListData do
                local addonData = scrollListData[k]
                local addondataData = addonData and addonData.data or nil
                local fileName = addondataData and addondataData.addOnFileName or nil
                local addonIndex = addondataData and addondataData.index or nil

                if addonIndex and fileName then
                    local addonShouldBeEnabled = addonTable[fileName] ~= nil
                    if addonShouldBeEnabled ~= addondataData.addOnEnabled then
                        somethingDone = true
                        ADDON_MANAGER:SetAddOnEnabled(addonIndex, addonShouldBeEnabled)
                        local enabled = select(5, ADDON_MANAGER:GetAddOnInfo(addonIndex))
                        addonData.data.addOnEnabled = enabled
                        if enabled then changed = true end
                    end
                end
            end
        end
    end
    return somethingDone
end

local function loadAddonPack(packName, packData, forAllCharsTheSame, noUIShown, isCharacterPack)
--d("[AS]loadAddonPack")
    forAllCharsTheSame = forAllCharsTheSame or false
    -- Clear the edit box:
    AS.editBox:Clear()

    --Prevent that hook to ADDON_MANAGER:SetAddOnEnabled will call updateDDL() and unselect the current selected pack
    skipUpdateDDL = true
    local somethingDone = updateAddonsEnabledStateByPackData(packData, noUIShown, isCharacterPack)
    skipUpdateDDL = false
--d(">somethingDone: " ..tos(somethingDone))

    if not doNotReloadUI and AS.acwsv.autoReloadUI == true then -- and somethingDone == true then
        --Set the currently selected packname
        SetCurrentCharacterSelectedPackname(packName, packData)
        --[[
        if forAllCharsTheSame == true then
            SetAllCharactersSelectedPackname(packName, packData)
        end
        ]]
        AS.acwsv.packChangedBeforeReloadUI = true
        ReloadUI("ingame")
    else
        --[[
        if forAllCharsTheSame == true then
            SetAllCharactersSelectedPackname(packName, packData)
        end
        ]]
        AS.acwsv.packChangedBeforeReloadUI = true
        onAddonPackSelected(packName, packData, skipOnAddonPackSelected, isCharacterPack)
    end
end

--Undo the last mass marking by loading the last saved profile before the mass marking was done
--Mass marking = deselect all, select all, deselect all libraries, select all libraries, shift click mass marking
function AddonSelector_UndoLastMassMarking(clearBackup)
    if AS.acwsv.lastMassMarkingSavedProfile == nil then return end
    clearBackup = clearBackup or false

    if clearBackup then
        AS.acwsv.lastMassMarkingSavedProfile     = nil
        AS.acwsv.lastMassMarkingSavedProfileTime = nil
    else
        --load the last saved addon pack data from AddonSelector.acwsv.lastMassMarkingSavedProfile
--d(">loading last backuped pre-mass-marking pack!")
        local packData = AS.acwsv.lastMassMarkingSavedProfile
        updateAddonsEnabledStateByPackData(packData)
        onAddonPackSelected(GLOBAL_PACK_BACKUP_BEFORE_MASSMARK_NAME, packData, true)
    end
end

--Select/Deselect all addon checkboxes
function AddonSelector_SelectAddons(selectAll, enableAll, onlyLibraries)
    enableAll = enableAll or false
    onlyLibraries = onlyLibraries or false
--d("[AddonSelector]AddonSelector_SelectAddons - selectAll: " ..tos(selectAll) .. ", enableAll: " ..tos(enableAll).. ", onlyLibraries: " ..tos(onlyLibraries))
    if not areAllAddonsEnabled(false) then return end
    if not ZOAddOnsList or not ZOAddOnsList.data then return end

    local selectAllSave = AS.acwsv.selectAllSave

    local selectAddOnsButton = AddonSelectorSelectAddonsButton

    --Save the currently enabled addons as a special "backup pack" so we can restore it later
    saveAddonsAsPackBeforeMassMarking()

    --Copy the AddOns list
    local addonsListCopy = ZO_ShallowTableCopy(ZOAddOnsList.data)
    --TODO: For debugging
    --AddonSelector._addonsListCopy = addonsListCopy
    --local addonsList = ZOAddOnsList.data

    --Only if not all entries should be selected
    if not selectAll then
        addonIndicesOfAddonsWhichShouldNotBeDisabled = {}

        --d(">Sorting addon table and finding index")
        --Sort the copied addons list by type (headlines etc. to the end, sort by addonFileName or cleanAddonName)
        tsor(addonsListCopy, function(a,b)
            --headlines etc: Move to the end
            if a.typeId == nil or a.typeId ~= 1 then
                --d(">>Comp skipped a: " ..tos(a.typeId))
                return false
                --AddonFileName (TXT filename) is provided? Sort by that
            elseif a.data.addOnFileName ~= nil then
                local addonFileName = a.data.addOnFileName
                --d(">>Comp file idx " .. tos(a.data.index) .. " a: " ..tos(addonFileName) .. ", b: " ..tos(b.data.addOnFileName))
                --Find AddonSelector and other dependencies indices
                local addonIndex = a.data.index
                if addonIndex ~= nil then
                    if thisAddonIndex == 0 and addonFileName == ADDON_NAME then
                        thisAddonIndex = addonIndex
--d(">>>Found AddonSelector at addonIdx: " ..tos(addonIndex) .. ", addOnFileName: " ..tos(addonFileName))
                    elseif addonsWhichShouldNotBeDisabled[addonFileName] and not addonIndicesOfAddonsWhichShouldNotBeDisabled[addonIndex] then
                        addonIndicesOfAddonsWhichShouldNotBeDisabled[addonIndex] = true
--d(">>>Found dependency at addonIdx: " ..tos(addonIndex) .. ", addOnFileName: " ..tos(addonFileName))
                    end
                end

                if not b.data.addOnFileName then return true end
                return a.data.addOnFileName < b.data.addOnFileName
            elseif a.data.strippedAddOnName ~= nil then
                --d(">>Comp name a: " ..tos(a.data.strippedAddOnName) .. ", b: " ..tos(b.data.strippedAddOnName))
                if not b.data.strippedAddOnName then return true end
                --Sort by "clean" (no color coding etc.) addon name
                return a.data.strippedAddOnName < b.data.strippedAddOnName
            else
                --Nothing to compare
                return false
            end
        end)

        --Save the currently enabled addons for a later re-enable
        AS.acwsv.selectAllSave = {}
        selectAllSave          = AS.acwsv.selectAllSave
        for _,v in ipairs(addonsListCopy) do
            local vData = v.data
            local vDataIndex = vData ~= nil and vData.index
            if vDataIndex ~= nil then
                selectAllSave[vDataIndex] = vData.addOnEnabled
            end
        end
    end --if not selectAll

    --Restore from saved addons (after some were disabled already -> re-enable them again) or disable all?
    selectAllSave = AS.acwsv.selectAllSave
    local fullHouse = true
    local emptyHouse = true
    if not enableAll then
        for i,v in ipairs(selectAllSave) do
            if i ~= thisAddonIndex and not addonIndicesOfAddonsWhichShouldNotBeDisabled[i] then
                if not v then fullHouse = false
                else emptyHouse = false end
            end
        end
    else
        fullHouse = true
        emptyHouse = false
    end
    if not fullHouse and not emptyHouse then
        selectAddOnsButton:SetText(selectSavedText)
    else
        selectAddOnsButton:SetText(selectAllText)
    end
    local isSelectAddonsButtonTextEqualSelectedSaved = (not enableAll and selectAll == true and addonSelectorSelectAddonsButtonNameLabel:GetText() == selectSavedText and true) or false

--d(">isSelectAddonsButtonTextEqualSelectedSaved: " ..tos(isSelectAddonsButtonTextEqualSelectedSaved))

    --local addonsMasterList = ADDON_MANAGER_OBJECT.masterList
    local numAddons = ADDON_MANAGER:GetNumAddOns()
    for i = 1, numAddons do
        local isProtectedAddonOrDependency = ((i == thisAddonIndex or addonIndicesOfAddonsWhichShouldNotBeDisabled[i]) and true) or false

        --name, title, author, description, enabled, state, isOutOfDate, isLibrary
        local addonName, _, _, _, enabled, _, _, isLibrary = ADDON_MANAGER:GetAddOnInfo(i)
--d(">>addonIdx: " ..tos(i) .. ", addOnFileName: " ..tos(addonName) .. ", isLibrary: " ..tos(isLibrary) .. ", enabled: " ..tos(enabled) ..", isProtectedAddonOrDependency: " ..tos(isProtectedAddonOrDependency))

        if enableAll == true or selectAll == true or not isProtectedAddonOrDependency then
            if not onlyLibraries and isSelectAddonsButtonTextEqualSelectedSaved == true then -- Are we restoring from save?
--d(">>>restoring previously saved addonIdx: " ..tos(i))
                ADDON_MANAGER:SetAddOnEnabled(i, selectAllSave[i])

            elseif not isSelectAddonsButtonTextEqualSelectedSaved and not isProtectedAddonOrDependency then
                -- Otherwise continue as normal: enabled/disable addon via "selectAll" boolean flag
                if (not onlyLibraries or (onlyLibraries == true and isLibrary == true)) and selectAll ~= enabled then
--d(">>>1- changing state to: " ..tos(selectAll))
                    ADDON_MANAGER:SetAddOnEnabled(i, selectAll)
                end
            end

        --Enable the addons/libraries - But only the "must always be enabled ones"? But do not do that if restoring from last saved addons
        elseif enableAll == true and selectAll == true and isProtectedAddonOrDependency == true and not isSelectAddonsButtonTextEqualSelectedSaved then
            if not enabled then
                --if not onlyLibraries or (onlyLibraries == true and isLibrary == true) then
--d(">>>enable must-be-enabled addon '" .. tos(addonName) .."' again")
                    ADDON_MANAGER:SetAddOnEnabled(i, true)
                --end
            end
        end
    end

    --Reset last saved addons for the re-enable as all were enabled now
    if isSelectAddonsButtonTextEqualSelectedSaved == true then
        AS.acwsv.selectAllSave = {}
        --Update the keybind strip's button
        selectAddOnsButton:SetText(selectAllText)
    end

    --Update the flag for the filters and resort of the addon list
    ZO_AddOnManager.isDirty = true
--d("[AddonSelector]Fragment removed")
    --Remove the addons fragment from the scene, to refresh it properly
    SM:RemoveFragment(ADDONS_FRAGMENT)
--d("[AddonSelector]Fragment added")
    --Add the addons fragment to the scene, to refresh it properly
    SM:AddFragment(ADDONS_FRAGMENT)

--Attempt to fix ESC and RETURN key and other global keybinds not woring aftr you have used an AddonManager keybind
    -->Maybe because of the remove and add fragment?
    ADDON_MANAGER_OBJECT:RefreshKeybinds()
end

--Scroll the scrollbar to an index
local function scrollAddonsScrollBarToIndex(index, animateInstantly)
    ADDON_MANAGER_OBJECT = ADDON_MANAGER_OBJECT or ADD_ON_MANAGER
    if ADDON_MANAGER_OBJECT ~= nil and ADDON_MANAGER_OBJECT.list ~= nil and ADDON_MANAGER_OBJECT.list.scrollbar ~= nil then
        --ADDON_MANAGER_OBJECT.list.scrollbar:SetValue((ADDON_MANAGER_OBJECT.list.uniformControlHeight-0.9)*index)
        --ZO_Scroll_ScrollAbsolute(self, value)
        local onScrollCompleteCallback = function() end
        animateInstantly = animateInstantly or false
        ZO_ScrollList_ScrollDataIntoView(ADDON_MANAGER_OBJECT.list, index, onScrollCompleteCallback, animateInstantly)
    end
end
AS.ScrollAddonsScrollBarToIndex = scrollAddonsScrollBarToIndex

function AddonSelector_ScrollTo(toAddOns)
    if toAddOns == nil then end
    ADDON_MANAGER_OBJECT = ADDON_MANAGER_OBJECT or ADD_ON_MANAGER
    local addonManagerObjectList = ADDON_MANAGER_OBJECT.list
    if toAddOns == true then
        --Scroll to AddOns
        ZO_ScrollList_ResetToTop(addonManagerObjectList)
    else
        --Scroll to libraries
        local firstLibData = ADDON_MANAGER_OBJECT.addonTypes[true][1]
        if not firstLibData or not firstLibData.sortIndex then return end
        scrollAddonsScrollBarToIndex(firstLibData.sortIndex, true)
    end
end

local function unregisterOldEventUpdater(p_sortIndexOfControl, p_addSelection)
    --Disable the check for the control for the last index so it will not be skipped and thus active for ever!
    local activeUpdateControlEvents = AS.activeUpdateControlEvents
    if activeUpdateControlEvents ~= nil then
        for index, eventData in ipairs(activeUpdateControlEvents) do
            local lastEventUpdateName
            if p_sortIndexOfControl == nil and p_addSelection == nil then
                lastEventUpdateName = "AddonSelector_ChangeZO_AddOnsList_Row_Index_" ..tos(eventData.sortIndex) .. "_" .. tos(eventData.addSelection)
            else
                if eventData.sortIndex == p_sortIndexOfControl and eventData.addSelection == p_addSelection then
                    lastEventUpdateName = "AddonSelector_ChangeZO_AddOnsList_Row_Index_" ..tos(eventData.sortIndex) .. "_" .. tos(eventData.addSelection)
                end
            end
            if lastEventUpdateName ~= nil then
                --Unregister the update function again now
                EM:UnregisterForUpdate(lastEventUpdateName)
--d("<<Unregistered old events for: " ..tos(eventData.sortIndex) .. ", " ..  tos(eventData.addSelection))
                --Remove the entry from the table again
                activeUpdateControlEvents[index]= nil
            end
        end
    end
end

local function eventUpdateFunc(p_sortIndexOfControl, p_addSelection, p_eventUpdateName)
    if p_eventUpdateName == nil then return end
    if p_sortIndexOfControl == nil then return end
    p_addSelection = p_addSelection or false
    --Change the shown row name and put [ ] around the addon name so one sees the currently selected row
    local addonList = ZOAddOnsList.data
    if addonList == nil then return end
    if addonList[p_sortIndexOfControl] == nil then return false end
    local selectedAddonControl = addonList[p_sortIndexOfControl].control
    if selectedAddonControl ~= nil then
        local selectedAddonControlName = selectedAddonControl:GetNamedChild("Name")
        if selectedAddonControlName.GetText ~= nil and selectedAddonControlName.SetText ~= nil then
            local currentAddonText
            local newAddonText
            if p_addSelection then
                currentAddonText = selectedAddonControlName:GetText()
                newAddonText = "|cFF0000[>|r " .. currentAddonText .. " |cFF0000<]|r"
            else
                local selectedAddonData = addonList[p_sortIndexOfControl].data
                newAddonText = selectedAddonData.addOnName
            end

            if AS.selectedAddonSearchResult ~= nil then
                AS.selectedAddonSearchResult.control = nil
                if p_addSelection == true and AS.selectedAddonSearchResult.sortIndex ~= nil and AS.selectedAddonSearchResult.sortIndex == p_sortIndexOfControl then
                    AS.selectedAddonSearchResult.control = selectedAddonControl
                end
            end

            selectedAddonControlName:SetText(newAddonText)
            --Unregister the update function again now
            EM:UnregisterForUpdate(p_eventUpdateName)
--d("<<Control was found and changed, unregistering event updater: " ..tos(p_eventUpdateName))
            --Remove the entry of enabled event updater again
            unregisterOldEventUpdater(p_sortIndexOfControl, p_addSelection)
        end
    else
--d(">>Control not found: " ..tos(p_sortIndexOfControl))
    end
end

local function changeAddonControlName(sortIndexOfControl, addSelection)
    addSelection = addSelection or false
    if sortIndexOfControl == nil then return false end
    --Disable the update checks for the last control (sortIndices) so it will not be skipped and thus be active for ever!
    unregisterOldEventUpdater()
    --Refresh the visible controls so their names get resetted to standard
    if addSelection then
        ADDON_MANAGER_OBJECT:RefreshVisible()
    end
    --Enable the check function which will try to find the addon list row control every 100ms
    local eventUpdateName = "AddonSelector_ChangeZO_AddOnsList_Row_Index_" ..tos(sortIndexOfControl) .. "_" .. tos(addSelection)
    EM:UnregisterForUpdate(eventUpdateName)
    local eventWasRegistered = EM:RegisterForUpdate(eventUpdateName, 100, function()
--d(">Calling RegisterForUpdateFunc: " ..tos(eventUpdateName))
        eventUpdateFunc(sortIndexOfControl, addSelection, eventUpdateName)
    end)
    if eventWasRegistered then
        local activeUpdateControlEvents = AS.activeUpdateControlEvents
        if activeUpdateControlEvents ~= nil then
            --Add this event to the currently active list
            local eventData = {
                ["sortIndex"]       = sortIndexOfControl,
                ["addSelection"]    = addSelection,
            }
            tins(activeUpdateControlEvents, eventData)
--d(">Event was registeerd: " ..tos(eventUpdateName))
        end
    end
end

local function updateSearchHistory(searchType, searchValue)
    local settings = AS.acwsv
    local maxSearchHistoryEntries = settings.searchHistoryMaxEntries
    local searchHistory = settings.searchHistory
    searchHistory[searchType] = searchHistory[searchType] or {}
    local searchHistoryOfSearchType = searchHistory[searchType]
    local toSearch = strlow(searchValue)
    if not ZO_IsElementInNumericallyIndexedTable(searchHistoryOfSearchType, toSearch) then
        --Only keep the last 10 search entries
        tins(searchHistory[searchType], 1, searchValue)
        local countEntries = #searchHistory[searchType]
        if countEntries > maxSearchHistoryEntries then
            for i=maxSearchHistoryEntries+1, countEntries, 1 do
                searchHistory[searchType][i] = nil
            end
        end
    end
end

local searchHistoryEventUpdaterName = "AddonSelector_SearchHistory_Update"
local function updateSearchHistoryDelayed(searchType, searchValue)
    EM:UnregisterForUpdate(searchHistoryEventUpdaterName)
    EM:RegisterForUpdate(searchHistoryEventUpdaterName, 1500, function()
        EM:UnregisterForUpdate(searchHistoryEventUpdaterName)
        updateSearchHistory(searchType, searchValue)
    end)
end

local function clearSearchHistory(searchType)
    local settings = AS.acwsv
    local searchHistory = settings.searchHistory
    if not searchHistory[searchType] then return end
    settings.searchHistory[searchType] = nil
end


-------------------------------------------------------------------
-- -v- Other addons -v-
-------------------------------------------------------------------
--[AddonCategory]
local function getAddonCategoryCategories()
    if not isAddonCategoryEnabled then return nil, nil end
    local addonCategories, addonCategoriesIndices
    local possibleAddonCategories = AddonCategory.indexCategories
    if possibleAddonCategories ~= nil then
        addonCategories = {}
        addonCategoriesIndices = {}
        local countAdded = 1
        --Add the 1st entry "No category"
        addonCategories[1] = noCategoryStr
        addonCategoriesIndices[noCategoryStr] = -1 --Dummy value to show it schould scroll up to the addons
        --Add the defined categories of the addon AddonCategory
        for categoryName, categorysIndexInAddonsList in pairs(possibleAddonCategories) do
            countAdded = countAdded + 1
            addonCategories[countAdded] = categoryName
            addonCategoriesIndices[categoryName] = categorysIndexInAddonsList
        end
        --Sort the output table by category name
        tsor(addonCategories)
    end
    return addonCategories, addonCategoriesIndices
end
-------------------------------------------------------------------
--  -^- Other addons -^-
-------------------------------------------------------------------


--Search for addons by e.g. name and scroll the list to the found addon, or filter (hide) all non matching addons
function AddonSelector_SearchAddon(searchType, searchValue, doHideNonFound, isAddonCategorySearched)
    searchType = searchType or SEARCH_TYPE_NAME
    doHideNonFound = doHideNonFound or false
    isAddonCategorySearched = isAddonCategorySearched or false
--d("[AddonSelector]SearchAddon, searchType: " .. tos(searchType) .. ", searchValue: " .. tos(searchValue) .. ", hideNonFound: " ..tos(doHideNonFound).. ", isAddonCategorySearched: " ..tos(isAddonCategorySearched))

    local wasAnythingFound = false
    AS.selectedAddonSearchResult = nil
    wasSearchNextDoneByReturnKey = false
--d("[AddonSelector]search done FALSE 1: " ..tos(wasSearchNextDoneByReturnKey))

    if isAddonCategorySearched == true then
        --searchValue is the category name of the addon AddonCategory. The index to scroll to is defined via table
        --AddonCategory.indexCategories[categoryName] = addonsIndexInAddonsList
        --Cached data will be stored in local table addonCategoryIndices[categoryName] where categoryName is searchValue!
        -->Get the index tos croll to now
        if addonCategoryIndices == nil then
            addonCategoryCategories, addonCategoryIndices = getAddonCategoryCategories()
        end
        if addonCategoryIndices == nil then return end
        local indexToScrollTo = addonCategoryIndices[searchValue]
--d(">addoncategory index: " ..tos(indexToScrollTo))
        if indexToScrollTo == nil then return end
        if indexToScrollTo ~= -1 then
            -->Scroll to the searchValue's index now
            wasSearchNextDoneByReturnKey = true
--d("[AddonSelector]search done 2: " ..tos(wasSearchNextDoneByReturnKey))
            scrollAddonsScrollBarToIndex(indexToScrollTo)
            wasSearchNextDoneByReturnKey = true
--d("[AddonSelector]search done 3: " ..tos(wasSearchNextDoneByReturnKey))

            AddNewChatNarrationText("[Scrolled to] Category: " ..tos(searchValue), true)
        else
            --Scroll to the top -> Unassigned addons (no category)
            wasSearchNextDoneByReturnKey = true
--d("[AddonSelector]search done 4: " ..tos(wasSearchNextDoneByReturnKey))
            AddonSelector_ScrollTo(true)
            wasSearchNextDoneByReturnKey = true
--d("[AddonSelector]search done 5: " ..tos(wasSearchNextDoneByReturnKey))

            AddNewChatNarrationText("[Scrolled to] AddOns", true)
        end
        wasSearchNextDoneByReturnKey = false
        return
    end

    local addonList = ZOAddOnsList.data
    if addonList == nil then return end
    local isEmptySearch = searchValue == ""
    local toSearch = (not isEmptySearch and strlow(searchValue)) or searchValue
    local settings = AS.acwsv
    local searchExcludeFilename = settings.searchExcludeFilename
    local searchSaveHistory = settings.searchSaveHistory
    if searchSaveHistory == true and not isEmptySearch then
        updateSearchHistoryDelayed(searchType, searchValue)
    end

    local addonsFound = {}
    local alreadyFound = AS.alreadyFound
    --No search term given
    if isEmptySearch then
        --Refresh the visible controls so their names get resetted to standard
        ADDON_MANAGER_OBJECT:RefreshVisible()
        --Reset the searched table completely
        AS.alreadyFound = {}
        --Unregister all update events
        unregisterOldEventUpdater()
        wasSearchNextDoneByReturnKey = false
--d("[AddonSelector]search done FALSE 2: " ..tos(wasSearchNextDoneByReturnKey))

        AddNewChatNarrationText(searchMenuStr .. " " .. GetString(SI_QUICKSLOTS_EMPTY), true)
        return
    end

    for _, addonDataTable in ipairs(addonList) do
        local addonData = addonDataTable.data
        if addonData and addonData.index ~= nil and addonData.sortIndex ~= nil then
            local stringFindResult
            local stringFindCleanResult
            local stringFindResultFile
            if searchType == SEARCH_TYPE_NAME then
                local addonName = strlow(addonData.addOnName)
                local addonCleanName = strlow(addonData.strippedAddOnName )
                local addonFileName = strlow(addonData.addOnFileName)
                --stringFindResult = (string.find(addonFileName, toSearch) or string.find(addonName, toSearch)) or nil
                --stringFindResult = string.find(addonName, toSearch) or nil
                stringFindResult = zopsf(addonName, toSearch) or nil
                stringFindCleanResult = zopsf(addonCleanName, toSearch) or nil
                stringFindResultFile = (not searchExcludeFilename and zopsf(addonFileName, toSearch)) or nil
--d(">addonName: " .. tos(addonName) .. ", addonFileName: " .. tos(addonFileName) .. ", search: " .. tos(toSearch) .. ", found: " .. tos(stringFindResult))
            end
            --Result of the search
            if stringFindResult ~= nil or stringFindCleanResult ~= nil or stringFindResultFile ~= nil then
                --Hide the non found addons?
                if doHideNonFound then
                    --Add the found addon indices to the "show list"
                    local newEntryIndex = #addonsFound+1
                    addonsFound[newEntryIndex] = {}
                    addonsFound[newEntryIndex] = addonData

                --Scroll to the found addon?
                else
                    local sortIndex = addonData.sortIndex
                    --Check if the addon was found before and scroll to another one then, if there are multiple with the name
                    local wasFoundBefore = false
                    local wasAddedBefore = false
                    if alreadyFound[toSearch] ~= nil then
                        --Check each entry in the list
                        for _, scrolledToData in ipairs(alreadyFound[toSearch]) do
                            if scrolledToData[sortIndex] ~= nil then
                                wasAddedBefore = true
                                if scrolledToData[sortIndex] == true then
                                    wasFoundBefore = true
                                    break -- exit the loop
                                end
                            end
                        end
                    end
                    --Addon was not found before
                    if not wasAddedBefore and not wasFoundBefore then
                        --Add the found addon to the already found, but not scrolled-to list
                        AS.alreadyFound[toSearch] = AS.alreadyFound[toSearch] or {}
                        tins(AS.alreadyFound[toSearch], { [sortIndex] = false})

                        wasAnythingFound = true
                    end
                end
            end
        end
    end
    --All sortIndex entries matching the search string were added to the table alreadyFound[searchTerm] with the value false
    --Check all found sortIndices and use the first one for the next scroll, where the value is false
    if alreadyFound[toSearch] ~= nil then
--d(">found toSearch entries: " ..tos(#alreadyFound[toSearch]))
        local resetWasDone = false
        for index, wasScrolledToBeforeData in ipairs(alreadyFound[toSearch]) do
            for scrollToIndex, wasScrolledToBefore in pairs(wasScrolledToBeforeData) do
                if wasScrolledToBefore == false then
--d(">scrolling to index: " ..tos(scrollToIndex))
                    --Scroll to the found addon now, if it was not found before
                    wasSearchNextDoneByReturnKey = true
--d("[AddonSelector]search done 6: " ..tos(wasSearchNextDoneByReturnKey))
                    scrollAddonsScrollBarToIndex(scrollToIndex)

                    AS.selectedAddonSearchResult                    = {
                        sortIndex   =   scrollToIndex,
                        control     =   ZOAddOnsList.data[scrollToIndex], --Will be re-set at function eventUpdateFunc as the [>  <] surrounding tags will be placed!
                    }

                    wasSearchNextDoneByReturnKey = true
--d("[AddonSelector]search done 7: " ..tos(wasSearchNextDoneByReturnKey))
                    --Set this entry to true so we know a scroll-to has taken place already to this sortIndex
                    AS.alreadyFound[toSearch][index][scrollToIndex] = true
                    --Check if all entries in the list are true now, so we scrolled to all of them already. Clear the list then
                    local trueCounter = 0
                    local entryCounter = 0
                    for _, wasScrolledToBeforeAllTrueData in ipairs(alreadyFound[toSearch]) do
                        for _, wasScrolledToBeforeAllTrue in pairs(wasScrolledToBeforeAllTrueData) do
                            if wasScrolledToBeforeAllTrue == true then trueCounter = trueCounter + 1 end
                            entryCounter = entryCounter + 1
                        end
                    end
                    --Are all entries in this search term table true?
                    resetWasDone = false
                    if trueCounter~=0 and entryCounter~=0 and trueCounter == entryCounter then
                        --Reset the search term table for a new scroll-to from the beginning
                        AS.alreadyFound[toSearch] = nil
                        resetWasDone              = true
--d(">all entries found and scrolled to!")
                    end
                    --Change the shown row name and put [ ] around the addon name so one sees the currently selected row
                    --[[
                    local scrollbar = ZOAddOnsList.scrollbar
                    local delay = 100
                    if scrollbar ~= nil then
                        local currentScrollBarPosition = scrollbar:GetValue()
                        local approximatelyCurrentAddonSortIndex = currentScrollBarPosition / ZOAddOnsList.uniformControlHeight
                        if approximatelyCurrentAddonSortIndex < 0 then approximatelyCurrentAddonSortIndex = 0 end
                        --Scroll to index is bigger than then approximately current selected addon's scrollIndex
                        if scrollToIndex > approximatelyCurrentAddonSortIndex then
                            delay = (scrollToIndex - approximatelyCurrentAddonSortIndex) * 4
                        else
                            --Are we near the end of the list and it needs to scroll up again
                            if resetWasDone then
                                delay = 350
                            else
                                delay = (approximatelyCurrentAddonSortIndex - scrollToIndex) * 4
                            end
                        end
d(">scrollToIndex: " ..tos(scrollToIndex) .. ", approximatelyCurrentAddonSortIndex: " ..tos(approximatelyCurrentAddonSortIndex) .. ", delay: " ..tos(delay))
                        if delay < 0 then delay = 100 end
                        if delay > 500 then delay = 500 end
                    end
                    zo_callLater(function()
                        changeAddonControlName(scrollToIndex, true)
                    end, delay)
                    ]]

                    --Slightly delay the narration as the other narration is active already, telling us the addons enabled count
                    if addonListWasOpenedByAddonSelector == true then
                        zo_callLater(function()
                            narrateCurrentlyScrolledToAddonName(scrollToIndex, resetWasDone, searchValue)
                        end, 3500)
                    else
                        narrateCurrentlyScrolledToAddonName(scrollToIndex, resetWasDone, searchValue)
                    end

                    changeAddonControlName(scrollToIndex, true)

                    --Abort now as scroll-to was done
                    return
                end
            end
        end
    end

    if not wasAnythingFound then
        wasSearchNextDoneByReturnKey = false
        AddNewChatNarrationText(GetString(SI_TRADINGHOUSESEARCHOUTCOME1), true)
    end
end

local function TreeEntryOnSelected(control, data, selected, reselectingDuringRebuild)
    control:SetSelected(selected)
    if not reselectingDuringRebuild then
        if selected then
            if data.callback then
                data.callback(control)
            end
        else
            if data.unselectedCallback then
                data.unselectedCallback(control)
            end
        end
    end
end

local gameMenuHeadersHooked = false
local function hideAddonMenu()
    --Hide the addon's fragment again if it was added by AddonSelector!
    if AS.AddedAddonsFragment == true then
        SM:RemoveFragment(ADDONS_FRAGMENT)
        AS.AddedAddonsFragment = false
    end
end
local function showAddOnsList()
    addonListWasOpenedByAddonSelector = false
    if not SM then return end
    if not ADDONS_FRAGMENT then return end
    if ADDONS_FRAGMENT and ADDONS_FRAGMENT.control and not ADDONS_FRAGMENT.control:IsHidden() then return true end
    --Show the game menu (as if you have pressed ESC key)
    if not SM:IsShowing("gameMenuInGame") then
        ZO_SceneManager_ToggleGameMenuBinding()
    end
    --Show the addons fragment -> Adding the fragment will keep the fragment shown if we change the menus (in gamepad mode), so we need to remove the fragment on
    --game menu change again!
    --SM:AddFragment(ADDONS_FRAGMENT)
    --Call the callback of the game menu entry of "AddOns"
    --ZO_GameMenu_InGameNavigationContainerScrollChildZO_GameMenu_ChildlessHeader_WithSelectedState1.callback()
    local headerControls = ZO_GameMenu_InGame.gameMenu.headerControls
    if headerControls ~= nil then
        local headersHookedCount = 0
        for headerControlText, headerControlData in pairs(headerControls) do
            if headerControlText == addonsStr then
                if headerControlData.data and headerControlData.data.callback then
                    --Is the addnons fragment already added to the current scene?
                    if not SM:GetCurrentScene():HasFragment(ADDONS_FRAGMENT) then
                        TreeEntryOnSelected(headerControlData.control, headerControlData.data, true, nil)
                    end
                    addonListWasOpenedByAddonSelector = true
                    AS.AddedAddonsFragment            = true
                end
            else
                if not gameMenuHeadersHooked then
                    local menuEntryToHook = (headerControlData.data and headerControlData.data.callback) or (headerControlData.control and headerControlData.control.SetSelected)
                    if menuEntryToHook ~= nil then
                        local origHeaderCallback = menuEntryToHook
                        if headerControlData.data.callback ~= nil then
                            headersHookedCount = headersHookedCount + 1
                            headerControlData.data.callback = function(...)
                                hideAddonMenu()
                                return origHeaderCallback(...)
                            end
                        else
                            headersHookedCount = headersHookedCount + 1
                            headerControlData.control.SetSelected = function(...)
                                hideAddonMenu()
                                return origHeaderCallback(...)
                            end
                        end
                    end
                end
            end
        end
        if addonListWasOpenedByAddonSelector == true then
            if headersHookedCount > 0 then gameMenuHeadersHooked = true end
            return true
        end
    end
    return
end

local function openGameMenuAndAddOnsAndThenLoadPack(args, doNotShowAddOnsScene, noReloadUI, charName, wasCalledFromLogout)
--d("[AS]openGameMenuAndAddOnsAndThenLoadPack - args: " .. tos(args) .. ", doNotShowAddOnsScene: " ..tos(doNotShowAddOnsScene) .. ", noReloadUI: " ..tos(noReloadUI) .. ", charName: " ..tos(charName) .. ", wasCalledFromLogout: " ..tos(wasCalledFromLogout))
    if not args or args == "" then return end
    doNotShowAddOnsScene = doNotShowAddOnsScene or false
    wasCalledFromLogout = wasCalledFromLogout or false
    if noReloadUI == nil then noReloadUI = true end

    local packNameLower
    local isCharacterPack = false
    local svForPacks, charId, characterName

    --Parse the arguments string
    local options = {}
    --[[ -- Split only at spaces
    --local searchResult = {} --old: searchResult = { string.match(args, "^(%S*)%s*(.-)$") }
    for param in strgma(args, "([^%s]+)%s*") do
        if (param ~= nil and param ~= "") then
            options[#options+1] = strlow(param)
        end
    end
    ]]
    local charNameForMsg = charName

    --Split and respect quotes and double quotes
    options = splitStringAndRespectQuotes(args)
    if ZO_IsTableEmpty(options) then return end
    local numOptions = #options
--d(">got here, #options: " .. tos(numOptions))
    if numOptions >= 1 then

        local characterIdForSV, charNameForSV = currentCharId, GLOBAL_PACK_NAME

        if numOptions == 1 then
            --Save character packs is enabled at the settings? Assume we load a character pack then
            --if not: Assume we load a global pack then
            isCharacterPack = (not wasCalledFromLogout and charName ~= nil and charName ~= GLOBAL_PACK_NAME and true)
                                or (wasCalledFromLogout == true and ( (charName ~= nil and charName ~= GLOBAL_PACK_NAME and true) or (charName ~= nil and charName == GLOBAL_PACK_NAME and false) ))
                                or AS.acwsv.saveGroupedByCharacterName
            packNameLower = options[1]
        else
            --2 or more params have been enered at the chat.
            --1st param == "string": Character name
            --or 1st param == "number": 1 = global, 2 = character pack
            --2nd param == string: Addon pack
            if charName == nil or charName == "" then
                local firstParamIsNumber = tonumber(options[1])
                local firstParamType = type(firstParamIsNumber)
--d("> " .. options[1] .. ", firstParamType: " ..tos(firstParamType))
                if firstParamType ~= "number" then
                    charName = tos(options[1])
                    charNameForMsg = charName
                end
            end

            isCharacterPack = (((charName ~= nil and charName ~= GLOBAL_PACK_NAME) or tos(options[1]) == "2") and true) or AS.acwsv.saveGroupedByCharacterName
            packNameLower = table.concat(options, " ", 2)
        end

--d(">charName: " .. tos(charName) .. ", packName: " ..tos(packNameLower) .. ", isCharacterPack: " ..tos(isCharacterPack))

        if packNameLower ~= nil then
            --Character is the currentlyLoggedIn or any other?
            if isCharacterPack == true then
                characterIdForSV, charNameForSV = getCharacterIdAndNameForSV(charName)
                charNameForMsg = charNameForSV
            end

            --Search the packname now as character or global pack
            svForPacks, charId, characterName = getSVTableForPackBySavedType((not isCharacterPack and GLOBAL_PACK_NAME) or nil, (isCharacterPack and characterIdForSV) or nil)

            --[[
AS._debugSlashLoadPack = {
    __doNotShowAddOnsScene = doNotShowAddOnsScene,
    __saveGroupedByCharacterName = AS.acwsv.saveGroupedByCharacterName,
    _charName = charName,
    _packNameLower = packNameLower,
    ___options = options,
    _isCharacterPack = isCharacterPack,
    svForPacks = svForPacks,
    charId = charId,
    characterName = characterName,
    characterIdForSV = characterIdForSV,
    charNameForSV = charNameForSV,
}
            ]]

            if svForPacks ~= nil then
                packNameLower = strlow(packNameLower)

                charNameForMsg = characterName
                local addOnsUIwasNotOpened = false
                --Now check if the packname is in the list
                for packName, addonsInPack in pairs(svForPacks) do
                    if strlow(packName) == packNameLower then
                        --Show the game menu and open the AddOns manager now (if not suppressed)
                        if not addOnsUIwasNotOpened and not doNotShowAddOnsScene then
                            if not showAddOnsList() then
                                return
                            end
                            addOnsUIwasNotOpened = true
                        end

                        --d(">pack found -> loading it now!")
                        local packData = ZO_ShallowTableCopy(addonsInPack)
                        packData.charName = packData.charName or ((isCharacterPack == true and characterName) or GLOBAL_PACK_NAME)

                        --Clear the dropdown selected entry
                        doNotReloadUI = noReloadUI
                        --skipOnAddonPackSelected = true
                        --Select this pack now at the dropdown
                        loadAddonPack(packName, packData, false, doNotShowAddOnsScene, isCharacterPack)
                        --skipOnAddonPackSelected = false
                        doNotReloadUI = noReloadUI

                        --We only get here if auto reloadUI pack is disabled
                        if not wasCalledFromLogout and not doNotReloadUI and AS.acwsv.autoReloadUI == false then
                            ReloadUI("ingame")
                        end

                        clearAndUpdateDDL()

                        d(string.format(packNameLoadFoundStr, tos(packName), tos(not isCharacterPack and packNameGlobal or characterName)))
                        return true
                    end
                end
            end
        end
    end
    d(string.format(packNameLoadNotFoundStr, tos(packNameLower), tos((not isCharacterPack and packNameGlobal) or charNameForMsg)))
    return false
end

local function openGameMenuAndAddOnsAndThenSearch(addonName, doNotShowAddOnsScene, isAddonCategorySearched)
--d("[AS]openGameMenuAndAddOnsAndThenSearch-addonName: " ..tos(addonName) .. ", doNotShowAddOnsScene: " ..tos(doNotShowAddOnsScene) .. ", isAddonCategorySearched: " ..tos(isAddonCategorySearched))
    if not addonName or addonName == "" then return end
    doNotShowAddOnsScene = doNotShowAddOnsScene or false
    isAddonCategorySearched = isAddonCategorySearched or false
    if not doNotShowAddOnsScene then
        --Show the game menu and open the AddOns
        if not showAddOnsList() then
--d("<aborted set search!")
            return
        end
    end
    --Set the focus to the addon search box
    local searchBox = AS.searchBox
    if not isAddonCategorySearched then
        if searchBox then
            searchBox:SetText(addonName)
            searchBox:TakeFocus()
        end
    else
        --Do not add the searched category to the search history
        if searchBox then
            searchBox:SetText("")
        end
    end
    --Search for the addonName or category
    AddonSelector_SearchAddon(SEARCH_TYPE_NAME, addonName, false, isAddonCategorySearched)
    addonListWasOpenedByAddonSelector = false
end

local function loadAddonPackNow(packName, charName, doNotShowAddonsList, noReloadUI)
    if packName == nil or packName == "" or charName == nil or charName == "" then return end
    openGameMenuAndAddOnsAndThenLoadPack(packName, doNotShowAddonsList, noReloadUI, charName)
end

--Add the active addon count to the header text
function AddonSelectorUpdateCount(delay, doNarrate)
--d("[AddonSelector]AddonSelectorUpdateCount, noAddonNumUpdate: " .. tos(AddonSelector.noAddonNumUpdate))
    if AS.noAddonNumUpdate then return false end
    delay = delay or 100
    doNarrate = doNarrate or false
    zo_callLater(function()
        if not ZOAddOnsList or not ZOAddOnsList.data then return false end
        local addonRows = ZOAddOnsList.data
        if addonRows == nil then return false end
        local countFound = 0
        local countActive = 0
        AS.numAddonsEnabled     = 0
        AS.numAddonsTotal       = 0
        ADDON_MANAGER           = ADDON_MANAGER or GetAddOnManager()
        ADDON_MANAGER_OBJECT    = ADDON_MANAGER_OBJECT or ADD_ON_MANAGER
        AS.ADDON_MANAGER_OBJECT = ADDON_MANAGER_OBJECT
        if ADDON_MANAGER == nil then return false end

        countFound = ADDON_MANAGER:GetNumAddOns()
        for _, addonRow in ipairs(addonRows) do
            if addonRow.data then
                --countFound = countFound + 1
                if not addonRow.data.hasDependencyError and addonRow.data.addOnEnabled and addonRow.data.addOnEnabled == true then
                    countActive = countActive + 1
                end
            end
        end

        AS.numAddonsEnabled = countActive
        AS.numAddonsTotal   = countFound
        if doNarrate == true then
            narrateAddonsEnabledTotal()
        end

        --Update the addon manager title with the number of active/total addons
        --d("[AddonSelector] active/found: " .. tos(countActive) .. "/" .. tos(countFound))
        local zoAddOnsTitle = ZO_AddOnsTitle
        zoAddOnsTitle:SetText(GetString(SI_WINDOW_TITLE_ADDON_MANAGER) .. " (" .. tos(countActive) .. "/" .. tos(countFound) .. ")")
        zoAddOnsTitle:SetMouseEnabled(true)
    end, delay)
end

--Function to build the reverse lookup table for sortIndex to addonIndex
local function BuildAddOnReverseLookUpTable()
    if ZOAddOnsList ~= nil and ZOAddOnsList.data ~= nil then
        --Build the lookup table for the sortIndex to nrow index of addon rows
        if ZO_IsTableEmpty(ZOAddOnsList.data) then return end
    --d(">>>[AS]BuildAddOnReverseLookUpTable - Running")

        AS.ReverseLookup     = {}
        AS.NameLookup        = {}
        AS.FileNameLookup    = {}
        AS.Libraries         = {}
        local reverseLookup  = AS.ReverseLookup
        local nameLookup     = AS.NameLookup
        local fileNameLookup = AS.FileNameLookup
        local libraries      = AS.Libraries

        for _,v in ipairs(ZOAddOnsList.data) do
            local data = v.data
            if data.sortIndex ~= nil and data.index ~= nil then
                reverseLookup[data.sortIndex] = data.index
                if data.addOnFileName ~= nil or data.strippedAddOnName ~= nil then
                    fileNameLookup[data.strippedAddOnName] = data.addOnFileName
                    if data.isLibrary then
                        libraries[data.addOnFileName] = data
                        libraries[data.strippedAddOnName] = data
                    else
                        nameLookup[data.addOnFileName] = data
                        nameLookup[data.strippedAddOnName] = data
                    end
                end
            end
        end
        --d("<<<[AS]BuildAddOnReverseLookUpTable - ENDED")
    end
end

local function AddonSelector_MultiSelect(control, addonEnabledCBox, button)
--d("AddonSelector_MultiSelect")
    if button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
    if addonEnabledCBox == nil then return false end
    --Get the current's row data
    --local addonRowControl = addonEnabledCBox:GetParent()
    local addonRowControl = control
    if addonRowControl == nil or addonRowControl.data == nil
            or addonRowControl.data.sortIndex == nil or addonRowControl.data.index == nil then return false end
    --Is the shift key pressed on the keyboard?
    local isShiftDown = IsShiftKeyDown()
    --local isAddonEnabled = addonEnabledCBox.checkState
--d("[AddonSelector]AddonSelector_MultiSelect(" .. addonRowControl:GetName() .. ", button: " .. tos(button) .. "), isShiftDown: " ..tos(isShiftDown) .. ", enabled: " .. tos(isAddonEnabled))
    --Shift not pressed: Remember the currently clicked control as first one + remember it's data as table copy so it won't change with the next "scroll" indside the addonlist,
    --as the addon list rows are re-used during scroll (they belong to a control pool)!
    if not isShiftDown then
        --Save the currently enabled addons as a special "backup pack" so we can restore it later
        saveAddonsAsPackBeforeMassMarking()

        AS.firstControl     = addonRowControl
        local currentAddonRowData       = ZO_ShallowTableCopy(addonRowControl.data)
        AS.firstControlData = currentAddonRowData
--d(">no shift key pressed -> First control was set to: " ..tos(ZOAddOnsList.data[currentAddonRowData.sortIndex].data.strippedAddOnName))
        return false
    end

    local firstClickedControl = AS.firstControl
    --Not the current row clicked and shift key was pressed: The actually clicked row is the "to" range row
    if isShiftDown and (firstClickedControl and addonRowControl ~= firstClickedControl) then
--d(">Shift key was pressed and addonRow is not the same as the first pressed one")
        local firstRowData = AS.firstControlData
        if firstRowData == nil or firstRowData.sortIndex == nil then return false end
        --local firstControlAddonName     = ZOAddOnsList.data[firstRowData.sortIndex].data.strippedAddOnName
        local currentRowData = addonRowControl.data
        --local currentControlAddonName   = ZOAddOnsList.data[currentRowData.sortIndex].data.strippedAddOnName
--d(">Trying to mark from \"" .. tos(firstControlAddonName) .. "\" to \"" .. tos(currentControlAddonName).."\"")

        local step = ((firstRowData.sortIndex - currentRowData.sortIndex < 0) and 1) or -1
        --is the reverse addonIndex lookup table empty? Build it.
        if AS.ReverseLookup == nil then
            BuildAddOnReverseLookUpTable()
        end
        --From the first selected row to the currently selected row with SHIFT key pressed:
        -- loop forwards/backwards and simulate the click on the enable/disable checkbox
        local checkBoxNewState = true
        if firstRowData.addOnEnabled == true then checkBoxNewState = false end
--d(">From sortIndex: " .. tos(firstRowData.sortIndex) .. " to sortindex: " .. tos(currentRowData.sortIndex) .. ", step: " .. tos(step) .. ", enabledNew: " .. tos(checkBoxNewState))
        --Disable the update of the addon count during the loop, to avoid lags
        AS.noAddonNumUpdate     = true

        --local checkState = (firstRowData.addOnEnabled == true and TRISTATE_CHECK_BUTTON_CHECKED) or TRISTATE_CHECK_BUTTON_UNCHECKED
        AS.lastChangedAddOnVars = {}
        for addonSortIndex = firstRowData.sortIndex, currentRowData.sortIndex, step do
            local currentAddonListRowData = ZOAddOnsList.data[addonSortIndex].data
            if currentAddonListRowData then
--d(">>currentRowData: " ..tos(currentAddonListRowData.sortIndex) .. ", name: "..tos(currentAddonListRowData.strippedAddOnName))
                --Get the addon index
                local addonIndex = AS.ReverseLookup[addonSortIndex]
                if addonIndex ~= nil and addonIndex >= 0 then
                    --d(">>sortIndex: " .. tos(addonSortIndex) .. ", addonIndex: " .. tos(addonIndex))
                    --Check if the addon got dependencies that need to be enabled if the addon will be enabled
                    local changeCheckboxNow = false
                    --Only if not the last clicked entry was met: Will be always checked and updated after the addonManager data was refreshed as the click on the
                    --name / checkbox changes the row already manually
                    if addonSortIndex ~= currentRowData.sortIndex then
                        if checkBoxNewState == true then
                            if currentAddonListRowData.addOnState ~= ADDON_STATE_ENABLED and not currentAddonListRowData.missing then
                                changeCheckboxNow = true
                                checkDependsOn(currentAddonListRowData)
                            end
                        else
                            if currentAddonListRowData.addOnState == ADDON_STATE_ENABLED and not currentAddonListRowData.missing then
                                changeCheckboxNow = true
                            end
                        end
                    else
                        changeCheckboxNow = true
                    end
                    --Set the state off the addon's enable/disable checkbox the same like first row state
                    if changeCheckboxNow == true then
                        ADDON_MANAGER:SetAddOnEnabled(addonIndex, checkBoxNewState)
                    end
                    --Variables for the check if the last changed AddOn's state is the same as the wished one. If not: Change it accordingly.
                    if changeCheckboxNow == true and addonSortIndex == currentRowData.sortIndex then
--d(">>>lastChangdAddOnVars: " .. tos(addonSortIndex) .. ", addonIndex: " .. tos(addonIndex))
                        AS.lastChangedAddOnVars.sortIndex     = addonSortIndex
                        AS.lastChangedAddOnVars.addonIndex    = addonIndex
                        AS.lastChangedAddOnVars.addonNewState = checkBoxNewState
                    end
                end
            end
        end
        --Enable the update of the addon count after the loop again
        AS.noAddonNumUpdate = false
        --Refresh the visible data
--d("[AS]AddonSelector_MultiSelect - RefreshData()")
        ADDON_MANAGER_OBJECT:RefreshData()
        ZO_ScrollList_RefreshVisible(ZOAddOnsList)
        return true
    else
        --Reset the first clicked data if the SHIFT key was pressed
        if isShiftDown then
--d(">Clicked with SHIFT key. Resetting first clicked data")
            AS.firstControlData    = nil
            AS.firstClickedControl = nil
        end
    end
    return false
end

--Function to check if the last changed AddOn's state is the same as the wished one. If not: Change it accordingly.
local function AddonSelector_CheckLastChangedMultiSelectAddOn(rowControl)
--d("[AddonSelector]AddonSelector_CheckLastChangedMultiSelectAddOn")
    local lastChangedAddOnVars = AS.lastChangedAddOnVars
    if lastChangedAddOnVars ~= nil and lastChangedAddOnVars.addonIndex ~= nil and lastChangedAddOnVars.addonNewState ~= nil and lastChangedAddOnVars.sortIndex ~= nil then
--d(">addonIndex: " .. tos(lastChangedAddOnVars.addonIndex) .. ", newState: " .. tos(lastChangedAddOnVars.addonNewState))
        local preventerVarsWereSet = (AS.noAddonNumUpdate or AS.noAddonCheckBoxUpdate) or false
        if not preventerVarsWereSet then
            AS.noAddonNumUpdate      = true
            AS.noAddonCheckBoxUpdate = true
        end
        local newState = lastChangedAddOnVars.addonNewState
        local currentAddonListRowData = ZOAddOnsList.data[lastChangedAddOnVars.sortIndex].data
        if not currentAddonListRowData then return end
        local changeCheckboxNow = false
        if newState == true then
--d(">newState: true")
            if currentAddonListRowData.addOnState ~= ADDON_STATE_ENABLED and not currentAddonListRowData.missing then
                changeCheckboxNow = true
                checkDependsOn(currentAddonListRowData)
            end
        else
--d(">newState: false")
            if currentAddonListRowData.addOnState == ADDON_STATE_ENABLED and not currentAddonListRowData.missing then
                changeCheckboxNow = true
            end
        end
        if changeCheckboxNow == true then
--d(">Changing last addon now: " ..tos(currentAddonListRowData.strippedAddOnName))
            ADDON_MANAGER:SetAddOnEnabled(lastChangedAddOnVars.addonIndex, newState)
            --Addon_Toggle_Enabled(rowControl)
            if not preventerVarsWereSet then
                AS.noAddonNumUpdate      = false
                AS.noAddonCheckBoxUpdate = false
            end
        end
        --Refresh the visible data
--d("[AS]AddonSelector_CheckLastChangedMultiSelectAddOn - RefreshData()")
        ADDON_MANAGER_OBJECT:RefreshData()
        ZO_ScrollList_RefreshVisible(ZOAddOnsList)
        --Update the active addons count
        if not AS.noAddonNumUpdate then
            AddonSelectorUpdateCount(50)
        end
    end
end

--[[
--Enable the multiselect of addons via the SHIFT key
--Parameters: _ = eventCode,  a = layerIndex,  b = activeLayerIndex
local function AddonSelector_HookForMultiSelectByShiftKey()--eventCode, layerIndex, activeLayerIndex)
--d("[AddonSelector]AddonSelector_HookForMultiSelectByShiftKey")
    --if not (layerIndex == 17 and activeLayerIndex == 5) then return end
    for i, control in pairs(ZOAddOnsList.activeControls) do
        local name = control:GetNamedChild("Name")
        if name ~= nil then
            local enabled = control:GetNamedChild("Enabled")
            if enabled ~= nil then
                ZO_PreHookHandler(enabled, "OnClicked", function(self, button)
--d("[Enabled checkbox - OnClicked]")
                    --Do not run the same code (AddonSelector_MultiSelect) again if we come from the left mouse click on the name control
                    if AddonSelector.noAddonCheckBoxUpdate or button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
                    --Check shift key, or not. If yes: Mark/unmark all addons from first clicked row to SHIFT + clicked row.
                    -- Else save clicked name sortIndex + addonIndex
                    local retVar = AddonSelector_MultiSelect(control, self, button)
                    if retVar == true then
                        zo_callLater(function()
                            AddonSelector_CheckLastChangedMultiSelectAddOn(control)
                        end, 150)
                    end
                    --If the shift key was pressed do not enable the addon's checkbox by the normal function here but via function
                    --AddonSelector_MultiSelect())
                    return IsShiftKeyDown()
                end)
                local enabledClick = enabled:GetHandler("OnClicked")
                name:SetMouseEnabled(true)
                name:SetHandler("OnMouseDown", nil)
                name:SetHandler("OnMouseDown", function(self, button)
                    if button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
                    --Check shift key, or not. If yes: Mark/unmark all addons from first clicked row to SHIFT + clicked row.
                    -- Else save clicked name sortIndex + addonIndex
                    local retVar = AddonSelector_MultiSelect(control, enabled, button)
                    --Simulate a click on the checkbox left to the addon's name
                    AddonSelector.noAddonNumUpdate = true
                    AddonSelector.noAddonCheckBoxUpdate = true
                    enabledClick(enabled, button)
                    if retVar == true then
                        zo_callLater(function()
                            AddonSelector_CheckLastChangedMultiSelectAddOn(control)
                        end, 150)
                    end
                    AddonSelector.noAddonCheckBoxUpdate = false
                    AddonSelector.noAddonNumUpdate = false
                end)
            end
        end
    end
end
]]

local alreadyAddedMultiSelectByShiftKeyHandlers = {}
local function AddonSelector_HookSingleControlForMultiSelectByShiftKey(control)--eventCode, layerIndex, activeLayerIndex)
    if not control or not control.GetName then return end
    local controlName = control:GetName()
    if alreadyAddedMultiSelectByShiftKeyHandlers[controlName] then return end
    alreadyAddedMultiSelectByShiftKeyHandlers[controlName] = true

--d("[AddonSelector]AddonSelector_HookSingleControlForMultiSelectByShiftKey: " ..tos(controlName))
    local name = control:GetNamedChild("Name")
    if name ~= nil then
        local enabled = control:GetNamedChild("Enabled")
        if enabled ~= nil then
            ZO_PreHookHandler(enabled, "OnClicked", function(selfVar, button)
                --d("[Enabled checkbox - OnClicked]")
                --Do not run the same code (AddonSelector_MultiSelect) again if we come from the left mouse click on the name control
                if button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
                if not areAllAddonsEnabled(true) then return end

                --Check shift key, or not. If yes: Mark/unmark all addons from first clicked row to SHIFT + clicked row.
                -- Else save clicked name sortIndex + addonIndex
                --[[
                local retVar = AddonSelector_MultiSelect(control, self, button)
                if retVar == true then
                    zo_callLater(function()
                        AddonSelector_CheckLastChangedMultiSelectAddOn(control)
                    end, 150)
                end
                ]]
                local isShiftKeyPressed = IsShiftKeyDown()
--d("Enabled_Clicked-shiftKey: " ..tos(isShiftKeyPressed))
                --Accessibility
                --Do not narrate if SHIFT key is pressed to "multi-select" addons (set end spot to enable/disable)?
                if not isShiftKeyPressed then
                    OnAddonRowClickedNarrateNewState(control, nil)
                end

                --If the shift key was pressed do not enable the addon's checkbox by the normal function here but via function
                --AddonSelector_MultiSelect())
                return isShiftKeyPressed
            end)
            local enabledClick = enabled:GetHandler("OnClicked")
            name:SetMouseEnabled(true)
            name:SetHandler("OnMouseDown", nil)
            name:SetHandler("OnMouseDown", function(selfVar, button)
                if button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
                if not areAllAddonsEnabled(true) then return end
                --Check shift key, or not. If yes: Mark/unmark all addons from first clicked row to SHIFT + clicked row.
                -- Else save clicked name sortIndex + addonIndex
                local retVar = AddonSelector_MultiSelect(control, enabled, button)

                --Set preventer variables in order to suppress duplicate code run at the checkbox
                AS.noAddonNumUpdate      = true
                AS.noAddonCheckBoxUpdate = true
                --Simulate a click on the checkbox left to the addon's name
                enabledClick(enabled, button)
                if retVar == true then
                    zo_callLater(function()
                        AddonSelector_CheckLastChangedMultiSelectAddOn(control)
                    end, 150)
                end
                AS.noAddonCheckBoxUpdate = false
                AS.noAddonNumUpdate      = false
                AddonSelectorUpdateCount(50)
            end)
        end
    end
end

--Function to show a confirmation dialog
local function ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, callbackSetup, data, forceUpdate)
    --Initialize the library
    if AS.LDIALOG == nil then
        AS.LDIALOG = LibDialog
    end
    if not AS.LDIALOG then
        d("[AddonSelector]".. AddonSelector_GetLocalizedText("LibDialogMissing"))
        return
    end
    local libDialog = AS.LDIALOG
    --Force the dialog to be updated with the title, text, etc.?
    forceUpdate = forceUpdate or false
    --Check if the dialog exists already, and if not register it
    local existingDialogs = libDialog.dialogs
    if forceUpdate or existingDialogs[ADDON_NAME] == nil or existingDialogs[ADDON_NAME][dialogName] == nil then
        libDialog:RegisterDialog(ADDON_NAME, dialogName, title, body, callbackYes, callbackNo, callbackSetup, forceUpdate, callbackNo)
    end
    --Show the dialog now
    libDialog:ShowDialog(ADDON_NAME, dialogName, data)

    AddDialogTitleBodyKeybindNarration(title, body, nil)
end

-- When an item is selected in the comboBox go through all available
-- addons & compare them against the selected addon pack.
-- Enable all addons that are in the selected addon pack, disable the rest.
-->Called by ItemSelectedClickHelper of the dropdown box entries/items
local function OnClickDDL(comboBox, packName, packData, selectionChanged, oldItem, forAllCharsTheSame) --comboBox, itemName, item, selectionChanged, oldItem
--[[
    AddonSelector._onClickDDlData = {
        comboBox = comboBox,
        packName = packName,
        packData = packData,
        selectionChanged = selectionChanged,
        oldItem = oldItem,
    }
]]
--d("OnClickDDL-packName: " ..tos(packName) .. ", doNotReloadUI: " ..tos(doNotReloadUI) ..", autoReloadUI: " ..tos(AddonSelector.acwsv.autoReloadUI))
    if preventOnClickDDL == true then preventOnClickDDL = false return end
    loadAddonPack(packName, packData, forAllCharsTheSame, false)
end

local function OnAbort_Do(wasSave, wasDelete, itemData, charId, beforeSelectedPackData)
    wasSave = wasSave or false
    wasDelete = wasDelete or false
    --AddonSelector._debugItemData = itemData
    --AddonSelector._debugCharId = charId
    --AddonSelector._debugBeforeSelectedPackData = beforeSelectedPackData
    if wasDelete == true and itemData ~= nil and beforeSelectedPackData ~= nil and itemData ~= beforeSelectedPackData then
--d(">OnAbort_Do - Delete")
        --Change the combobox SelectedItemText to beforeSelectedPackData.label or .name
        selectPreviouslySelectedPack(beforeSelectedPackData)
    end
end

local function OnClick_DeleteDo(itemData, charId, beforeSelectedPackData, buttonWasPressed)
    buttonWasPressed = buttonWasPressed or false
    if not itemData then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, deletePackAlertStr)
        return
    end
    local function deleteError(reason)
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, strfor(deletePackErrorStr, reason))
    end
    if not itemData.name or itemData.name == "" then
        deleteError("Pack name")
        return
    end
    if not itemData.charName or itemData.charName == "" then
        deleteError("Pack charName")
        return
    end

    local wasDeleted = false
    local selectedPackName = itemData.name
    local selectedCharName = itemData.charName
    local isGlobalPack = (selectedCharName == GLOBAL_PACK_NAME) or false

    --Save grouped by charactername
    if isGlobalPack == true then
        AS.acwsv.addonPacks[selectedPackName] = nil
        wasDeleted                            = true
--d(">deleted global pack: " ..tos(selectedPackName))
    else
        if charId == nil then
            deleteError("CharId nil")
            return
        end
        local addonPacksOfChar = AS.acwsv.addonPacksOfChar
        if addonPacksOfChar[charId] and addonPacksOfChar[charId][selectedPackName] then
            AS.acwsv.addonPacksOfChar[charId][selectedPackName] = nil
            wasDeleted                                          = true
--d(">deleted char pack, charId: " ..tos(charId))
        end
    end

    if wasDeleted == true then
        --Was the pack deleted which was currently selected, or any other?
        local currentlySelectedPackWasDeleted = (buttonWasPressed == true or (beforeSelectedPackData ~= nil and itemData == beforeSelectedPackData) and true) or false
--d(">currentlySelectedPackWasDeleted: " ..tos(currentlySelectedPackWasDeleted).. ", buttonWasPressed: " ..tos(buttonWasPressed))
        clearAndUpdateDDL(currentlySelectedPackWasDeleted)
        --Select the before selected pack again -> No "selected" callback so it does not accidently reload the UI or changes any enabled/disabled addons
        if not currentlySelectedPackWasDeleted and beforeSelectedPackData ~= nil then
            selectPreviouslySelectedPack(beforeSelectedPackData)
        else
            --Disable the "delete pack" button
            ChangeDeleteButtonEnabledState(nil, false)
            --Disable the "save pack" button
            ChangeSaveButtonEnabledState(false)
        end
    end
end

local function OnClick_DeleteWholeCharacterDo(charName, charId)
--d("[AddonSelector]OnClick_DeleteWholeCharacterDo -charName: " ..tos(charName))
    if not charName then return end
    if charId ~= nil and AS.acwsv.addonPacksOfChar[charId] ~= nil then
        --Empty the SV table in total
        AS.acwsv.addonPacksOfChar[charId] = { _charName = charName }

        clearAndUpdateDDL(true)
        --Disable the "delete pack" button
        ChangeDeleteButtonEnabledState(nil, false)
        --Disable the "save pack" button
        ChangeSaveButtonEnabledState(false)
    end
end

--Delete a whole characterId's saved packs?
function OnClick_DeleteWholeCharacter(characterId)
--d("[AddonSelector]OnClick_DeleteWholeCharacter -characterId: " ..tos(characterId))
    charactersOfAccount = charactersOfAccount or AS.charactersOfAccount
    characterIdsOfAccount = characterIdsOfAccount or AS.characterIdsOfAccount
    local charName = charactersOfAccount[characterId]
    if charName == nil then
        --Do not show packs of other accounts -> So the charname must be in current account chars list!
        if not AS.acwsv.showPacksOfOtherAccountsChars then
            return
        end
    end
    local svTable, charId, characterName = getSVTableForPacksOfCharname(charName, characterId)
    if svTable ~= nil and charId ~= nil and characterName ~= nil then
        if NonContiguousCount(svTable) == 1 then return end --only _charName entry is in there!
        --Hide the dropdown
        ClearCustomScrollableMenu()
        AS.comboBox:HideDropdown()
        --Show security dialog
        ShowConfirmationDialog("DeleteCharacterPacksDialog",
                    deleteWholeCharacterPacksTitleStr .. "\n[" .. characterName .. "]",
                    deleteWholeCharacterPacksQuestionStr,
                    function() OnClick_DeleteWholeCharacterDo(characterName, charId) end,
                    function() end,
                    nil,
                    nil,
                    true
            )
    end
end

-- When delete is clicked, remove the selected addon pack
local function OnClick_Delete(itemData, buttonWasPressed)
    buttonWasPressed = buttonWasPressed or false
    --d("[AddonSelector]OnClick_Delete - itemData: " .. tos(itemData))
    --todo: If itemData was passed in this was called from "Selecting an item in the dropdown -> e.g. submenu -> delete pack".
    --Selecting this menu entry will select the packName to delete to the dropdown's ItemSelectedText!
    --We need to overwrite this one with the before selected packname again (if any was selected!) so that aborting or deleting the
    --pack will not show the currently deleted packName at the dropdown
    local itemDataWasProvided = itemData ~= nil
    local currentlySelectedPackData
    if itemDataWasProvided == true then
        currentlySelectedPackData = AS.currentlySelectedPackData
    end

    itemData = itemData or AS.comboBox:GetSelectedItemData()
    if not itemData then return end
    --Debuggin
--AddonSelector._SelectedItemDataOnDelete = itemData

    --If the character name (could be _G for global packs too!) is missing at the pack (old saved packs e.g.): Add it here
    if itemData.charName == nil then
        itemData.charName                           = itemData.addonTable ~= nil and itemData.addonTable._charName
        itemData.charNameWasAddedByContextMenuClick = true --identifier to show the charname was added during click on "Delete pack"
    end

    --Deleting a pack could be done for all kinds of packs, so we always need to check for the selected charName of the item!
    --local saveGroupedByChar = AddonSelector.acwsv.saveGroupedByCharacterName
    local charId, charName, svTable
    charName = itemData.charName
    if charName == nil then return end
    --What if the charName on 2 accounts is the same? Not handlebar, as packs are saved below the name -> Deleting the one found then!
    if charName == currentCharName or charName == GLOBAL_PACK_NAME then
        svTable = getSVTableForPacks()
        charId = (charName ~= GLOBAL_PACK_NAME and currentCharId) or nil
    else
        svTable, charId = getSVTableForPacksOfCharname(charName, nil)
    end
    if not svTable then return end

--d(">charName: " ..tos(charName) .. ", charId: " ..tos(charId))

    local packCharName
    if charName ~= GLOBAL_PACK_NAME then packCharName = charName end
    local selectedPackName = itemData.name
    --ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
    local addonPackName = "\'" .. selectedPackName .. "\'"
    local deletePackQuestion = strfor(AddonSelector_GetLocalizedText("deletePackBody"), tos(addonPackName))
    ShowConfirmationDialog("DeleteAddonPackDialog",
            (deletePackTitleStr) .. "\n[" .. (packCharName and strfor(charNamePackColorTemplate, packCharName) or packNameGlobal) .. "]\n" .. selectedPackName,
            deletePackQuestion,
            function() OnClick_DeleteDo(itemData, charId, currentlySelectedPackData, buttonWasPressed) end,
            function() OnAbort_Do(false, true, itemData, charId, currentlySelectedPackData) end,
            nil,
            nil,
            true
    )
end

--[[
local function customAddonPackSortFunc(entryA, entryB)
    if entryA.isCharacterPackHeader == true and entryB.isCharacterPackHeader == true then
        return entryA.name < entryB.name
    elseif entryA.isCharacterPackHeader == true and not entryB.isCharacterPackHeader then
        return true
    elseif not entryA.isCharacterPackHeader and entryB.isCharacterPackHeader == true then
        return false
    end
    return entryA.name < entryB.name
end
]]

-- Create ItemEntry table for the ddl (dropdown box, ZO_ComboBox entries)
function AS.CreateItemEntry(packName, label, addonTable, isCharacterPack, charName, tooltip, entriesSubmenu, isSubmenuMainEntry, isHeader, iconData, contextMenuCallbackFunc)
    local isSubmenu = (entriesSubmenu ~= nil and true) or false
    local isCharacterPackHeader = (isCharacterPack and isSubmenuMainEntry and true) or false
    local settings = AS.acwsv

    local entry = {
        name = packName,
        label = label, --optional, might be nil. If nil name will be used instead
        addonTable = addonTable,
        tooltip = function()
            if tooltip == nil or not settings.addPackTooltip then return end
            return tooltip
        end,


        --Is character saved pack?
        isCharacterPackHeader=isCharacterPackHeader,
        charName=charName,

        --Submenu?
        isSubmenuMainEntry = isSubmenuMainEntry,
        isSubmenu=isSubmenu,
        entries=entriesSubmenu,

        --Header (non-clickable. Only headerline)
        isHeader = isHeader,

        --Icon
        icon = iconData,

        --ContextMenu
        contextMenuCallback = contextMenuCallbackFunc,
    }

    if not isSubmenu and not isHeader then
        entry.callback = OnClickDDL
    end
    --Enable the main entry, which got a submenu, to be clickable too (add a callback to it)
    -->But do not allow to click a "Character saved packs" line!
    if isSubmenuMainEntry == true and not isCharacterPack then
        entry.callback = function(comboBox, ...)
            OnClickDDL(comboBox, packName, entry, nil, nil)
        end
    end

    return entry
end
local createItemEntry = AS.CreateItemEntry

local submenuPacksSaveButtons = {}
local function updatePackSubmenuSaveButtonEnabledState(p_comboBox, newEnabledState)
    --d("[AS]updatePackSubmenuSaveButtonEnabledState - p_comboBox: " ..tos(p_comboBox) .. ", newEnabledState: " ..tos(newEnabledState))
    if p_comboBox == nil then return end
    --local dropdownBaseObject = p_comboBox.openingControl and p_comboBox.openingControl or p_comboBox --> that#s the parent submenu!
    local dropdownBaseObject = p_comboBox --that's the current nested submenu of the parent submenu (Addon list, of addons which are in the pack)

    --The save buttons
    if ZO_IsTableEmpty(submenuPacksSaveButtons[p_comboBox]) then return end
    for _, submenuPacksSaveButtonData in pairs(submenuPacksSaveButtons[p_comboBox]) do
        submenuPacksSaveButtonData.enabled = newEnabledState

        dropdownBaseObject.m_dropdownObject:Refresh(submenuPacksSaveButtonData)
    end
end

    --Get the save button
local function getPackSubmenuSaveButtons(p_comboBox, p_item, entriesFound)
    --d("[AS]getPackSubmenuSaveButton->RunCustomScrollableMenuItemsCallback: WAS EXECUTED!")
    submenuPacksSaveButtons[p_comboBox] = {}
    --Loop the normal entries and get the save buttons
--AddonSelector._entriesFound = entriesFound
    for k, v in ipairs(entriesFound) do
        local name = v.label or v.name
    --d(">name of entry: " .. tostring(name).. ", isSaveButton: " .. tostring(v.isSaveButton))
        if v.isSaveButton then
            submenuPacksSaveButtons[p_comboBox][v] = v
        end
    end
    --AddonSelector._submenuPacksSaveButtons = submenuPacksSaveButtons
end

local function onCheckboxInAddonPackListClicked(p_comboBox, rowControl, itemName, checked, packName, charName)
--d("[AS]checkbox ".. tos(itemName) .." clicked, newState: " ..tos(checked))
--AddonSelector._debugRowControl = rowControl
    --LSM 2.21 compatibility
    if p_comboBox == nil then
        p_comboBox = rowControl.m_owner
    end
    updatePackSubmenuSaveButtonEnabledState(p_comboBox, true)
end

local function saveUpdatedAddonPackCallbackFuncSubmenu(p_comboBox, p_item, entriesFound, p_character, p_packName) --... will be filled with customParams
    --local selectedContextMenuItemData = (GetCustomScrollableMenuRowData ~= nil and GetCustomScrollableMenuRowData(p_item)) or p_item.m_data.dataSource
    --if selectedContextMenuItemData == nil then return end

--AddonSelector._debugEntriesFoundSaveUpdatedAddonPack = ZO_ShallowTableCopy(entriesFound)

--d("[AS]saveUpdatedAddonPackCallbackFuncSubmenu->RunCustomScrollableMenuItemsCallback: WAS EXECUTED! packNameGlobal: " ..tos(packNameGlobal) .. ", packName: " ..tos(packName))

    --The currently saved pack from SavedVariables - For comparison
    local currentSvPackDataTable = getSVTableForPackBySavedType(p_character)
    if currentSvPackDataTable == nil then return end
--d(">sv table found")
    local currentSvPackData = currentSvPackDataTable[p_packName]
    if currentSvPackData == nil then return end

    local fileNameLookup = AS.FileNameLookup

--AddonSelector._debugCurrentSvPackData = currentSvPackData
--d(">current addons in pack found")
    --Loop the checkboxes and get their current state
    local addonsChanged = 0
    for _, v in ipairs(entriesFound) do
        local name = v.name
        local isCheckedNow = v.checked

        local addOnFileName = fileNameLookup[name]
--d(">name of entry: " .. tostring(name).. ", addOnFileName: " .. tos(addOnFileName) ..", checked: " .. tostring(isCheckedNow))
        if addOnFileName ~= nil then
            if currentSvPackData[addOnFileName] ~= nil then
                if not isCheckedNow then
                    currentSvPackData[addOnFileName] = nil
--d(">>removed addon from pack!")
                    addonsChanged = addonsChanged + 1
                end
            end
        else
--d(">>addon is missing in AddOns list!")
            if not isCheckedNow then
                --find the addon's filename in the SV via the name
                local addOnFileNameOfNotInstalledAddon
                for key, value in pairs(currentSvPackData) do
                    if value == name then
                        addOnFileNameOfNotInstalledAddon = key
                        break
                    end
                end
                if addOnFileNameOfNotInstalledAddon ~= nil then
                    currentSvPackData[addOnFileNameOfNotInstalledAddon] = nil
--d(">>2removed addon from pack!")
                    addonsChanged = addonsChanged + 1
                end
            end
        end
    end
    d(string.format(addonNamePrefix .. changedAddonPackStr, tos(p_packName), tos((p_character == GLOBAL_PACK_NAME) and packNameGlobal or (packCharNameStr .. ": " .. p_character)), tos(addonsChanged)))
    if addonsChanged > 0 then
        updateDDL()
        --Disable the saved button's enabled state
        ChangeSaveButtonEnabledState(false)
        --Disable the "delete pack" button
        ChangeDeleteButtonEnabledState(nil, false)
    end
end


local function isAddonPackEnabledForAutoLoadOnLogout(packName, characterOrGlobalPackName)
    local loadAddonPackOnLogout = AS.acwsvChar.loadAddonPackOnLogout
    if ZO_IsTableEmpty(loadAddonPackOnLogout) then return false end
    if loadAddonPackOnLogout.packName == packName and loadAddonPackOnLogout.charName == characterOrGlobalPackName then return true end
    return false
end


-- Called on load or when a new addon pack is saved & added to the comboBox
-- Clear & re-add all items + submenus, including new ones. Easier/quicker than
-- trying to see if an item already exists & editing it. Just adding
-- a new item would result in duplicates when editing a pack.
-->Uses LibScrollableMenu now as LibCustomMenu uses ZO_Menu and since API101040 ZO_ComboBox is a multiselect scrollable comboxbox NOT using ZO_Menu anymore!!!
function AS.UpdateDDL(wasDeleted)
    wasDeleted = wasDeleted or false
    local megaServer = GetWorldName()
    --local addonPacks = AddonSelector.acwsv.addonPacks
    local packTable = {} -- table with the pack entries and the submenus (if enabled)
    local settings = AS.acwsv
    local autoReloadUI = settings.autoReloadUI

    local wasItemAdded = false
    local saveGroupedByCharacterName = settings.saveGroupedByCharacterName
    local showGroupedByCharacterName = settings.showGroupedByCharacterName
    local showGlobalPacks = settings.showGlobalPacks
    local showSubMenuAtGlobalPacks = settings.showSubMenuAtGlobalPacks
    local addPackTooltip = settings.addPackTooltip
    local showPacksAddonList = settings.showPacksAddonList
    local showPacksOfOtherAccountsChars = settings.showPacksOfOtherAccountsChars
--d("[LSM]UpdateDDL-showPacksAddonList: " ..tos(showPacksAddonList))
    --local addonPacksComboBox = AddonSelector.comboBox


    --Auto reload theUI if a pack is changed? Show that directly at the pack's entry text
    local autoReloadUISuffix = ""
    local autoReloadUISuffixSubmenu = ""
    if autoReloadUI == true then
        autoReloadUISuffix = reloadUITextureStr
        autoReloadUISuffixSubmenu = " & " .. reloadUIStr
    end

    --Character IDs and names at the @account
    charactersOfAccount = charactersOfAccount or getCharactersOfAccount(false)
    characterIdsOfAccount = characterIdsOfAccount or getCharactersOfAccount(true)
    --local characterCount = NonContiguousCount(AddonSelector.charactersOfAccount)

    --Build the lookup tables for libraries
    BuildAddOnReverseLookUpTable()
    local librariesLookup = AS.Libraries
    local addonsLookup    = AS.NameLookup

------------------------------------------------------------------------------------------------------------------------
    --!LibScrollableMenu - Create the dropdown menu entries now - CharacterName entries!
    --Show the addon packs saved per character?
------------------------------------------------------------------------------------------------------------------------
    if showGroupedByCharacterName == true or saveGroupedByCharacterName == true then
------------------------------------------------------------------------------------------------------------------------
        local subMenuEntriesChar = {}
        local addedSubMenuEntry  = false

        --Create a header "Character packs"
        local itemDataCharacterPackHeader = createItemEntry(packNameCharacter, nil, nil, false, nil, "[" .. tostring(megaServer) .. "]" .. characterWidesStr,
                nil, false, true)
        tins(packTable, itemDataCharacterPackHeader)


        --Sort the character addon packs by their pack name
        local addonPacksOfChar = settings.addonPacksOfChar
        local addonPacksOfAllCharsSortedLookup = sortNonNumberKeyTableAndBuildSortedLookup(addonPacksOfChar)

        for _, charId in ipairs(addonPacksOfAllCharsSortedLookup) do
            local isCharOfCurrentAcc = charactersOfAccount[charId] or false

            --Only show the saved packs of the logged in account's characters
            if showPacksOfOtherAccountsChars or (not showPacksOfOtherAccountsChars and isCharOfCurrentAcc) then

                local addonPacks = addonPacksOfChar[charId]

                subMenuEntriesChar = nil

                local charName = addonPacks._charName
                local numAddonsInSubmenuPack
                local numAddonsInPack = NonContiguousCount(addonPacks)
                if charName ~= nil and numAddonsInPack > 1 then --count 1 will be the _charName entry!
                    if showGroupedByCharacterName == true then
                        subMenuEntriesChar = {}

                        local addonPacksOfCharSortedLookup = sortNonNumberKeyTableAndBuildSortedLookup(addonPacks)

                        --The entry in the DDL is the characterName -> We need to add the submenu entries for each packName
                        for _, packNameOfChar in pairs(addonPacksOfCharSortedLookup) do
                            if packNameOfChar ~= CHARACTER_PACK_CHARNAME_IDENTIFIER then --not the "_charName" entry
                                local iconData

                                local nestedSubmenuEntriesOfCharPack = {}
                                local addonsInCharPack = addonPacks[packNameOfChar]

                                numAddonsInSubmenuPack = NonContiguousCount(addonsInCharPack)
                                local subSubMenuEntriesForCharPack

                                ------------------------------------------------------------------------------------------------------------------------
                                ---Show the addons of the pack as submenu
                                subSubMenuEntriesForCharPack = {}

                                local addonTableOfCharSorted = {}
                                for addonFileName, addonNameOfCharPack in pairs(addonsInCharPack) do
                                    addonTableOfCharSorted[#addonTableOfCharSorted + 1] = { addonFileName = addonFileName, addonNameStripped = addonNameOfCharPack }
                                end
                                table.sort(addonTableOfCharSorted, function(a, b) return a.addonNameStripped < b.addonNameStripped end)
                                numAddonsInSubmenuPack = #addonTableOfCharSorted

                                --Show the addon list submenu sorted by addons first, then libarries (With a headline each)
                                --First currently enabled ones, then the disabled and then missing (not installed) ones
                                local addonTableSortedAddons = {}
                                local addonTableSortedLibraries = {}
                                local addonTableSortedAddonsNotEnabled = {}
                                local addonTableSortedLibrariesNotEnabled = {}
                                local addonTableSortedAddonsMissing = {}
                                local addonTableSortedLibrariesMissing = {}

                                for _, addonDataOfCharPackSorted in ipairs(addonTableOfCharSorted) do
                                    local wasAddonAdded                   = false
                                    local addonNameOfCharPackSorted     = addonDataOfCharPackSorted.addonNameStripped
                                    local addonFileNameOfCharPackSorted = addonDataOfCharPackSorted.addonFileName
                                    if addonsLookup ~= nil or librariesLookup ~= nil then
                                        --if string.find(addonNameOfCharPackSorted, "LibChar", 1, true) == 1 then
                                        --d(">addoName: " ..tos(addonNameOfCharPackSorted) .. "; fileName: " ..tos(addonFileNameOfCharPackSorted) .."; isLibrary: " ..tos(librariesLookup[addonFileNameOfCharPackSorted] or librariesLookup[addonNameOfCharPackSorted]) or nil)
                                        --end
                                        if addonsLookup then
                                            local addonsData = addonsLookup[addonFileNameOfCharPackSorted] or addonsLookup[addonNameOfCharPackSorted]
                                            if addonsData ~= nil then
                                                local enabled = addonsData.addOnEnabled or false
                                                if not enabled then
                                                    addonTableSortedAddonsNotEnabled[#addonTableSortedAddonsNotEnabled + 1] = addonNameOfCharPackSorted
                                                else
                                                    addonTableSortedAddons[#addonTableSortedAddons + 1] = addonNameOfCharPackSorted
                                                end
                                                wasAddonAdded = true
                                            end
                                        end
                                        if librariesLookup then
                                            local libraryData = librariesLookup[addonFileNameOfCharPackSorted] or librariesLookup[addonNameOfCharPackSorted]
                                            if libraryData ~= nil then
                                                local enabled = libraryData.addOnEnabled or false
                                                if not enabled then
                                                    addonTableSortedLibrariesNotEnabled[#addonTableSortedLibrariesNotEnabled + 1] = addonNameOfCharPackSorted
                                                else
                                                    addonTableSortedLibraries[#addonTableSortedLibraries + 1] = addonNameOfCharPackSorted
                                                end
                                                wasAddonAdded = true
                                            end
                                        end

                                        if not wasAddonAdded then
                                            --d(">not lib nor addon - addoName: " ..tos(addonNameOfCharPackSorted) .. "; fileName: " ..tos(addonFileNameOfCharPackSorted))
                                            --Addon in pack is not installed anymore? Or at least teh saved fileName and strippedAddonName do not match anymore
                                            --Check if it begins with Lib and assume it's a library then
                                            if string.find(string.lower(addonNameOfCharPackSorted), "lib", 1, true) ~= nil then
                                                addonTableSortedLibrariesMissing[#addonTableSortedLibrariesMissing + 1] = addonNameOfCharPackSorted
                                                wasAddonAdded = true
                                            else
                                                addonTableSortedAddonsMissing[#addonTableSortedAddonsMissing + 1] = addonNameOfCharPackSorted
                                                wasAddonAdded = true
                                            end
                                        end
                                    end
                                    if not wasAddonAdded then
                                        --Could happen as dropdown get's initialized on first run -> Just all all entries as normal addons for then
                                        addonTableSortedAddons[#addonTableSortedAddons + 1] = addonNameOfCharPackSorted
                                    end

                                end --for ... do
                                table.sort(addonTableSortedAddons)
                                table.sort(addonTableSortedLibraries)
                                table.sort(addonTableSortedAddonsNotEnabled)
                                table.sort(addonTableSortedLibrariesNotEnabled)
                                table.sort(addonTableSortedAddonsMissing)
                                table.sort(addonTableSortedLibrariesMissing)

                                local numOnlyAddOnsInSubmenuPack = #addonTableSortedAddons
                                local numLibrariesInSubmenuPack = #addonTableSortedLibraries
                                local numDisabledAddonsInSubmenuPack = #addonTableSortedAddonsNotEnabled
                                local numDisabledLibrariesInSubmenuPack = #addonTableSortedLibrariesNotEnabled
                                local numMissingAddonsInSubmenuPack = #addonTableSortedAddonsMissing
                                local numMissingLibrariesInSubmenuPack = #addonTableSortedLibrariesMissing

                                if showPacksAddonList == true then

                                    if numAddonsInPack > 0 then
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                            name    = saveChangesNowStr,
                                            callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                                --d("[AS]Save changes to charName: " .. tos(packNameGlobal) .. ", packName: " ..tos(packName))
                                                --As the clicked nested submenu entry will select this entry -> Clear the selection now
                                                --unselectAnyPack()

                                                --Save the changes to the pack now, using API function
                                                --AddonSelector._debugRowPackData = packData
                                                local currentComboBox = packData.m_owner --added with LSM 2.3 !
                                                --Use LSM API func to get the current control's list and m_sorted items properly so addons do not have to take care of that again and again on their own
                                                RunCustomScrollableMenuItemsCallback(currentComboBox, packData, saveUpdatedAddonPackCallbackFuncSubmenu, { LSM_ENTRY_TYPE_CHECKBOX }, false, charName, packNameOfChar)
                                            end,
                                            enabled = false,--will get enabled by ther checkbox's callback
                                            isSaveButton = true,
                                            entryType = LSM_ENTRY_TYPE_BUTTON,
                                            buttonTemplate = 'ZO_DefaultButton',
                                            doNotFilter = true,
                                        }
                                    end

                                    if numOnlyAddOnsInSubmenuPack > 0 then
                                        local addonsInPackText = string.format(addonsInPackStr .. " - #" .. numAddonsColorTemplate.."/%s", packNameOfChar, tos(numOnlyAddOnsInSubmenuPack), tos(numAddonsInSubmenuPack)) .. " [" .. singleCharNameColoredStr .. ": " .. charName .. "]"
                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                            name    = addonsInPackText, --Colored white/light grey
                                            --[[
                                            --No callback function -> Just a non clickable scrollable list of entries
                                            callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                                --Do nothing, just show info
                                                return true
                                            end,
                                            ]]
                                            enabled = false, -- non clickable
                                            isHeader = true,
                                        }

                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        -->Normal addons first
                                        for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedAddons) do
                                            subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                                label   = "|cF0F0F0" .. addonNameOfGlobalPackSorted .. "|r", --Colored white/light grey
                                                name    = addonNameOfGlobalPackSorted,
                                                callback = function(comboBox, itemName, rowControl, checked)
                                                    RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                                    onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, charName, packNameOfChar)
                                                end,
                                                entryType = LSM_ENTRY_TYPE_CHECKBOX,
                                                enabled = true,
                                                checked = true,
                                            }
                                        end
                                    end

                                    if numDisabledAddonsInSubmenuPack > 0 then
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                            name    = '-',
                                            enabled = false,
                                            isDivider = true,
                                        }
                                        local addonsInPackTextNotEnabled = string.format("["..disabledStr.."]" .. addonsInPackStr .. " - #" .. numAddonsColorTemplate .. "/%s", packNameOfChar, tos(numDisabledAddonsInSubmenuPack), tos(numAddonsInSubmenuPack))
                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1]  = {
                                            name    = addonsInPackTextNotEnabled, --Colored white/light grey
                                            --[[
                                            --No callback function -> Just a non clickable scrollable list of entries
                                            callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                                --Do nothing, just show info
                                                return true
                                            end,
                                            ]]
                                            enabled = false, -- non clickable
                                            isHeader = true,
                                        }

                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        -->Normal addons first
                                        for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedAddonsNotEnabled) do
                                            subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                                label    = addonNameOfGlobalPackSorted .. " (" .. disabledStr .. ")",
                                                name    = addonNameOfGlobalPackSorted,
                                                callback = function(comboBox, itemName, rowControl, checked)
                                                    RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                                    onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, charName, packNameOfChar)
                                                end,
                                                entryType = LSM_ENTRY_TYPE_CHECKBOX,
                                                enabled = true,
                                                checked = true,
                                            }
                                        end
                                    end

                                    if numMissingAddonsInSubmenuPack > 0 then
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                            name    = '-',
                                            enabled = false,
                                            isDivider = true,
                                        }
                                        local addonsInPackTextMissing = string.format("["..missingStr.."]"..addonsInPackStr .. " - #" .. numAddonsColorTemplate .. "/%s", packNameOfChar, tos(numMissingAddonsInSubmenuPack), tos(numAddonsInSubmenuPack))
                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1]  = {
                                            name    = addonsInPackTextMissing, --Colored white/light grey
                                            --[[
                                            --No callback function -> Just a non clickable scrollable list of entries
                                            callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                                --Do nothing, just show info
                                                return true
                                            end,
                                            ]]
                                            enabled = false, -- non clickable
                                            isHeader = true,
                                        }

                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        -->Normal addons first
                                        for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedAddonsMissing) do
                                            subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                                label   = "|cFF0000" .. addonNameOfGlobalPackSorted .. "|r",
                                                name    = addonNameOfGlobalPackSorted,
                                                callback = function(comboBox, itemName, rowControl, checked)
                                                    RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                                    onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, charName, packNameOfChar)
                                                end,
                                                entryType = LSM_ENTRY_TYPE_CHECKBOX,
                                                enabled = true,
                                                checked = true,
                                            }
                                        end
                                    end

                                    if numLibrariesInSubmenuPack > 0 then
                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        -->Libraries then
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                            name    = '-',
                                            enabled = false,
                                            isDivider = true,
                                        }
                                        local librariesInPackText = string.format(librariesInPackStr .. " - #" .. numLibrariesColorTemplate .. "/%s", packNameOfChar, tos(numLibrariesInSubmenuPack), tos(numAddonsInSubmenuPack))
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                            name    = librariesInPackText, --Colored white/light grey
                                            --[[
                                            --No callback function -> Just a non clickable scrollable list of entries
                                            callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                                --Do nothing, just show info
                                                return true
                                            end,
                                            ]]
                                            enabled = false, -- non clickable
                                            isHeader = true,
                                        }
                                        for _, libraryNameOfGlobalPackSorted in ipairs(addonTableSortedLibraries) do
                                            subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                                label   = "|cF0F0F0" .. libraryNameOfGlobalPackSorted .. "|r", --Colored white/light grey
                                                name    = libraryNameOfGlobalPackSorted,
                                                callback = function(comboBox, itemName, rowControl, checked)
                                                    RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                                    onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, charName, packNameOfChar)
                                                end,
                                                entryType = LSM_ENTRY_TYPE_CHECKBOX,
                                                enabled = true,
                                                checked = true,
                                            }
                                        end
                                    end

                                    if numDisabledLibrariesInSubmenuPack > 0 then
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                            name    = '-',
                                            enabled = false,
                                            isDivider = true,
                                        }
                                        local librariesInPackTextNotEnabled = string.format("["..disabledStr.."]" .. librariesInPackStr .. " - #" .. numLibrariesColorTemplate .. "/%s", packNameOfChar, tos(numDisabledLibrariesInSubmenuPack), tos(numAddonsInSubmenuPack))
                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1]  = {
                                            name    = librariesInPackTextNotEnabled, --Colored white/light grey
                                            --[[
                                            --No callback function -> Just a non clickable scrollable list of entries
                                            callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                                --Do nothing, just show info
                                                return true
                                            end,
                                            ]]
                                            enabled = false, -- non clickable
                                            isHeader = true,
                                        }

                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        -->Normal addons first
                                        for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedLibrariesNotEnabled) do
                                            subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                                label   = addonNameOfGlobalPackSorted .. " (" .. disabledStr .. ")",
                                                name    = addonNameOfGlobalPackSorted,
                                                callback = function(comboBox, itemName, rowControl, checked)
                                                    RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                                    onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, charName, packNameOfChar)
                                                end,
                                                entryType = LSM_ENTRY_TYPE_CHECKBOX,
                                                enabled = true,
                                                checked = true,
                                            }
                                        end
                                    end

                                    if numMissingLibrariesInSubmenuPack > 0 then
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1]  = {
                                            name    = "-",
                                            enabled = false, -- non clickable
                                            isDivider = true,
                                        }
                                        local librariesInPackTextMissing = string.format("["..missingStr.."]" .. librariesInPackStr .. " - #" .. numLibrariesColorTemplate.."/%s", packNameOfChar, tos(numMissingLibrariesInSubmenuPack), tos(numAddonsInSubmenuPack))
                                        subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1]  = {
                                            name    = librariesInPackTextMissing, --Colored white/light grey
                                            --[[
                                            --No callback function -> Just a non clickable scrollable list of entries
                                            callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                                --Do nothing, just show info
                                                return true
                                            end,
                                            ]]
                                            enabled = false, -- non clickable
                                            isHeader = true,
                                        }

                                        --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                                        -->Normal addons first
                                        for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedLibrariesMissing) do
                                            subSubMenuEntriesForCharPack[#subSubMenuEntriesForCharPack + 1] = {
                                                label   = "|cFF0000" .. addonNameOfGlobalPackSorted .. "|r",
                                                name    = addonNameOfGlobalPackSorted,
                                                callback = function(comboBox, itemName, rowControl, checked)
                                                    RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                                    onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, charName, packNameOfChar)
                                                end,
                                                entryType = LSM_ENTRY_TYPE_CHECKBOX,
                                                enabled = true,
                                                checked = true,
                                            }
                                        end
                                    end
                                end
                                ------------------------------------------------------------------------------------------------------------------------

                                local tooltipCharPack = (addPackTooltip == true and numAddonsInSubmenuPack ~= nil
                                        and (enabledAddonsInPackStr .. "\n'" ..
                                        packNameOfChar .. "': " ..tos(numAddonsInSubmenuPack) .. "\n" ..
                                        addonsStr .. ": " .. tos(numOnlyAddOnsInSubmenuPack) ..
                                        ((numDisabledAddonsInSubmenuPack > 0 and "\n" .. disabledStr.. "': " ..tos(numDisabledAddonsInSubmenuPack)) or "") ..
                                        ((numMissingAddonsInSubmenuPack > 0 and "\n" .. missingStr .. "': " ..tos(numMissingAddonsInSubmenuPack)) or "")
                                )
                                ) or nil
                                if numLibrariesInSubmenuPack > 0 and tooltipCharPack ~= nil then
                                    tooltipCharPack = tooltipCharPack ..
                                            "\n" .. librariesStr .. ": " .. tos(numLibrariesInSubmenuPack) ..
                                            ((numDisabledLibrariesInSubmenuPack > 0 and "\n" .. disabledStr.. "': " ..tos(numDisabledLibrariesInSubmenuPack)) or "") ..
                                            ((numMissingLibrariesInSubmenuPack > 0 and "\n" .. missingStr .. "': " ..tos(numMissingLibrariesInSubmenuPack)) or "")
                                end

                                tins(nestedSubmenuEntriesOfCharPack, {
                                    name = packNameOfChar,
                                    label = selectPackStr .. autoReloadUISuffixSubmenu .. ": " .. packNameOfChar,
                                    charName = charName,
                                    callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                        OnClickDDL(comboBox, packNameOfChar, packData, selectionChanged, oldItem)
                                        if settings.autoReloadUI == true then ReloadUI("ingame") end
                                    end,
                                    isCharacterPackHeader = false,
                                    isCharacterPack = true,
                                    isGlobalPackHeader = false,
                                    isGlobalPack = false,
                                    addonTable = addonsInCharPack,
                                    tooltip = tooltipCharPack,
                                    entries = ( showPacksAddonList == true and subSubMenuEntriesForCharPack) or nil,
                                })

                                if not autoReloadUI then
                                    nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] =
                                    {
                                        name    = "-",
                                        isDivider = true,
                                        callback = function() end,
                                        disabled = true,
                                    }
                                    nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] =
                                    {
                                        name    = packNameOfChar,
                                        label   = selectPackStr .. " & " .. reloadUIStr .. ": " .. packNameOfChar,
                                        callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                            OnClickDDL(comboBox, packNameOfChar, packData, selectionChanged, oldItem)
                                            ReloadUI("ingame")
                                        end,
                                        charName = charName,
                                        isCharacterPackHeader = false,
                                        isCharacterPack = true,
                                        isGlobalPackHeader = false,
                                        isGlobalPack = false,
                                        addonTable = addonsInCharPack,
                                    }
                                end

                                nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] =
                                {
                                    name    = "-",
                                    isDivider = true,
                                    callback = function() end,
                                    disabled = true,
                                }
                                nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] = {
                                    name = packNameOfChar,
                                    label = deletePackTitleStr .. " " .. packNameOfChar,
                                    charName = charName,
                                    callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                        OnClick_Delete(packData, false)
                                    end,
                                    isCharacterPackHeader = false,
                                    isCharacterPack = true,
                                    isGlobalPackHeader = false,
                                    isGlobalPack = false,
                                    addonTable = addonsInCharPack,
                                }

                                nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] = {
                                    name    = "-",
                                    isDivider = true,
                                    callback = function() end,
                                    disabled = true,
                                }
                                local packNameOfCharCopy = packNameOfChar
                                local charNameCopy = charName
                                nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] = {
                                    name    =  packNameOfChar,
                                    label    = string.format(overwriteSavePackStr, packNameOfChar),
                                    callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                        OnClick_Save(packNameOfCharCopy, packData, charNameCopy)
                                    end,
                                    charName = charName,
                                    addonTable = addonsInCharPack,
                                }
                                nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] = {
                                    name    = "-",
                                    isDivider = true,
                                    callback = function() end,
                                    disabled = true,
                                }
                                local keybindingEntries, keybindIconData = getKeybindingLSMEntriesForPacks(packNameOfCharCopy, charNameCopy)
                                nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] =  {
                                    name    =  GetString(SI_GAME_MENU_KEYBINDINGS),
                                    callback = nil,
                                    entries = keybindingEntries,
                                    charName = charName,
                                }

                                nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] =  {
                                    name    = "-",
                                    isDivider = true,
                                    callback = function() end,
                                    disabled = true,
                                }
                                nestedSubmenuEntriesOfCharPack[#nestedSubmenuEntriesOfCharPack+1] =  {
                                    name    = loadOnLogoutOrQuitStr,
                                    isCheckbox = true,
                                    callback = function(comboBox, itemName, rowControl, checked)
                                        AS.acwsvChar.loadAddonPackOnLogout = nil
                                        AS.acwsvChar.skipLoadAddonPackOnLogout = false
                                        if checked == true then
                                            AS.acwsvChar.loadAddonPackOnLogout = { packName = packNameOfCharCopy, charName = charNameCopy }
                                        end
                                        clearAndUpdateDDL()
                                    end,
                                    entryType = LSM_ENTRY_TYPE_CHECKBOX,
                                    checked = function()
                                        return isAddonPackEnabledForAutoLoadOnLogout(packNameOfCharCopy, charNameCopy)
                                    end,
                                }

                                --Add the characterPack as entry, with the nested submenu entries to select, select & reloadUI, and delete it
                                local labelCharacterPack = packNameOfChar
                                local autoLoadThisPackOnLogout = isAddonPackEnabledForAutoLoadOnLogout(packNameOfChar, charName)
                                --if autoLoadThisPackOnLogout == true then
                                --labelCharacterPack = labelCharacterPack .. autoLoadOnLogoutTextureStr
                                --end
                                if autoLoadThisPackOnLogout == true then
                                    iconData = iconData or {}
                                    local skipAutoLoadPackAtLogout = AS.acwsvChar.skipLoadAddonPackOnLogout
                                    tins(iconData, { iconTexture=autoLoadOnLogoutTexture, iconTint=not skipAutoLoadPackAtLogout and "00FF22" or "FF0000", tooltip=loadOnLogoutOrQuitStr })
                                end
                                if not ZO_IsTableEmpty(keybindIconData) then
                                    iconData = iconData or {}
                                    for _, v in ipairs(keybindIconData) do
                                        --tins(iconData, v)
                                        labelCharacterPack = labelCharacterPack .. v.iconTexture
                                    end
                                end

                                subMenuEntriesChar[#subMenuEntriesChar + 1] = {
                                    name = packNameOfChar,
                                    label = labelCharacterPack,
                                    charName = charName,
                                    callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                    OnClickDDL(comboBox, packNameOfChar, packData, selectionChanged, oldItem)
                                    if settings.autoReloadUI == true then ReloadUI("ingame") end
                                    end,
                                    isCharacterPackHeader = false,
                                    isCharacterPack = true,
                                    isGlobalPackHeader = false,
                                    isGlobalPack = false,
                                    addonTable = addonsInCharPack,
                                    entries = nestedSubmenuEntriesOfCharPack,
                                    tooltip = tooltipCharPack,
                                    icon = iconData,
                                }

                                addedSubMenuEntry = true
                            end --if packNameOfChar ~= CHARACTER_PACK_CHARNAME_IDENTIFIER then
                        end --for ... do
                        if not addedSubMenuEntry then subMenuEntriesChar = nil end
                    end ---if showGroupedByCharacterName

                    --CreateItemEntry(packName, addonTable, isCharacterPack, charName, tooltip, entriesSubmenu, isSubmenuMainEntry, isHeader)
                    --"[" .. charName .. "]"
                    local label
                    local charContextMenuCallbackFunc
                    if not ZO_IsTableEmpty(subMenuEntriesChar) then
                        charContextMenuCallbackFunc = function()
                            ClearCustomScrollableMenu()
                            AddCustomScrollableMenuEntry(deleteWholeCharacterPacksTitleStr, function() OnClick_DeleteWholeCharacter(charId) end, LSM_ENTRY_TYPE_NORMAL)
                            ShowCustomScrollableMenu(nil, LSM_defaultContextMenuOptions)
                        end
                    end

                    --packName, label, addonTable, isCharacterPack, charName, tooltip, entriesSubmenu, isSubmenuMainEntry, isHeader, iconData, contextMenuCallbackFunc
                    local itemCharData = createItemEntry(charName .. ((not isCharOfCurrentAcc and " " .. otherAccStr) or ""), label, addonPacks, true,
                            charName, "[" .. tostring(megaServer) .. "]"..characterWideStr..": \'" ..tostring(charName) .. "\' (ID: " .. tostring(charId)..")",
                            subMenuEntriesChar, subMenuEntriesChar ~= nil, false, nil, charContextMenuCallbackFunc)
                    tins(packTable, itemCharData)
                    wasItemAdded = true
                end
            end --if characterIdsOfAccount[charId] then
        end
------------------------------------------------------------------------------------------------------------------------
    end --Show grouped by character
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
    --!LibScrollableMenu - Create the dropdown menu entries now - Global entries!
    --Show the addon packs saved without character? -> Global, server wide
------------------------------------------------------------------------------------------------------------------------
    if showGlobalPacks == true then
------------------------------------------------------------------------------------------------------------------------
        local subMenuEntriesGlobal
        local addedSubMenuEntryGlobal

        --Create a header "Global packs"
        local itemDataGlobalPackHeader = createItemEntry(packNameGlobal, nil, nil, false, nil, "[" .. tostring(megaServer) .. "]" .. accountWidesStr,
                nil, false, true)
        tins(packTable, itemDataGlobalPackHeader)

        --Sort the global addon packs by their pack name
        local addonPacks = settings.addonPacks
        local addonPacksSortedLookup = sortNonNumberKeyTableAndBuildSortedLookup(addonPacks)
        for _, packName in ipairs(addonPacksSortedLookup) do
            local addonTable = addonPacks[packName]

            subMenuEntriesGlobal = nil
            local numAddonsInGlobalPack
            --if showSubMenuAtGlobalPacks == true then
            local subSubMenuEntriesGlobal
            local tooltipStr

            local addonTableSorted = {}
            for addonFileName, addonNameOfGlobalPack in pairs(addonTable) do
                addonTableSorted[#addonTableSorted + 1] = { addonFileName = addonFileName, addonNameStripped = addonNameOfGlobalPack }
            end
            numAddonsInGlobalPack = #addonTableSorted

            ------------------------------------------------------------------------------------------------------------------------
            subSubMenuEntriesGlobal = {}

            table.sort(addonTableSorted, function(a, b) return a.addonNameStripped < b.addonNameStripped end)

            --Show the addon list submenu sorted by addons first, then libarries (With a headline each)
            --First currently enabled ones, then the disabled and then missing (not installed) ones
            local addonTableSortedAddons = {}
            local addonTableSortedLibraries = {}
            local addonTableSortedAddonsNotEnabled = {}
            local addonTableSortedLibrariesNotEnabled = {}
            local addonTableSortedAddonsMissing = {}
            local addonTableSortedLibrariesMissing = {}

            for _, addonDataOfGlobalPackSorted in ipairs(addonTableSorted) do
                local wasAddonAdded = false
                local addonNameOfGlobalPackSorted = addonDataOfGlobalPackSorted.addonNameStripped
                local addonFileNameOfGlobalPackSorted = addonDataOfGlobalPackSorted.addonFileName
                if addonsLookup ~= nil or librariesLookup ~= nil then
                    --if string.find(addonNameOfGlobalPackSorted, "LibAddonMenu", 1, true) == 1 then
                    --    d(">addoName: " ..tos(addonNameOfGlobalPackSorted) .. "; fileName: " ..tos(addonFileNameOfGlobalPackSorted) .."; isLibrary: " ..tos(libraries[addonFileNameOfGlobalPackSorted]) or nil)
                    --end
                    if addonsLookup then
                        local addonsData = addonsLookup[addonFileNameOfGlobalPackSorted] or addonsLookup[addonNameOfGlobalPackSorted]
                        if addonsData ~= nil then
                            local enabled = addonsData.addOnEnabled or false
                            if not enabled then
                                addonTableSortedAddonsNotEnabled[#addonTableSortedAddonsNotEnabled + 1] = addonNameOfGlobalPackSorted
                            else
                                addonTableSortedAddons[#addonTableSortedAddons + 1] = addonNameOfGlobalPackSorted
                            end
                            wasAddonAdded = true
                        end
                    end
                    if librariesLookup then
                        local libraryData = librariesLookup[addonFileNameOfGlobalPackSorted] or librariesLookup[addonNameOfGlobalPackSorted]
                        if libraryData ~= nil then
                            local enabled = libraryData.addOnEnabled or false
                            if not enabled then
                                addonTableSortedLibrariesNotEnabled[#addonTableSortedLibrariesNotEnabled + 1] = addonNameOfGlobalPackSorted
                            else
                                addonTableSortedLibraries[#addonTableSortedLibraries + 1] = addonNameOfGlobalPackSorted
                            end
                            wasAddonAdded = true
                        end
                    end

                    if not wasAddonAdded then
                        --d(">not lib nor addon - addoName: " ..tos(addonNameOfGlobalPackSorted) .. "; fileName: " ..tos(addonFileNameOfGlobalPackSorted))
                        --Addon in pack is not installed anymore? Or at least teh saved fileName and strippedAddonName do not match anymore
                        --Check if it begins with Lib and assume it's a library then
                        if string.find(string.lower(addonNameOfGlobalPackSorted), "lib", 1, true) ~= nil then
                            addonTableSortedLibrariesMissing[#addonTableSortedLibrariesMissing + 1] = addonNameOfGlobalPackSorted
                            wasAddonAdded = true
                        else
                            addonTableSortedAddonsMissing[#addonTableSortedAddonsMissing + 1] = addonNameOfGlobalPackSorted
                            wasAddonAdded = true
                        end
                    end
                end
                if not wasAddonAdded then
                    --Could happen as dropdown get's initialized on first run -> Just all all entries as normal addons for then
                    addonTableSortedAddons[#addonTableSortedAddons + 1] = addonNameOfGlobalPackSorted
                end

            end --for ... do
            table.sort(addonTableSortedAddons)
            table.sort(addonTableSortedLibraries)
            table.sort(addonTableSortedAddonsNotEnabled)
            table.sort(addonTableSortedLibrariesNotEnabled)
            table.sort(addonTableSortedAddonsMissing)
            table.sort(addonTableSortedLibrariesMissing)

            local numOnlyAddOnsInGlobalPack      = #addonTableSortedAddons
            local numLibrariesInGlobalPack          = #addonTableSortedLibraries
            local numDisabledAddonsInGlobalPack    = #addonTableSortedAddonsNotEnabled
            local numDisabledLibrariesInGlobalPack = #addonTableSortedLibrariesNotEnabled
            local numMissingAddonsInGlobalPack    = #addonTableSortedAddonsMissing
            local numMissingLibrariesInGlobalPack = #addonTableSortedLibrariesMissing

            --Show list of addons in the saved pack as extra submenu
            if showPacksAddonList == true then
                if numAddonsInGlobalPack > 0 then
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = saveChangesNowStr,
                        callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                            --d("[AS]Save changes to charName: " .. tos(packNameGlobal) .. ", packName: " ..tos(packName))
                            --As the clicked nested submenu entry will select this entry -> Clear the selection now
                            --unselectAnyPack()

                            --Save the changes to the pack now, using API function
--AddonSelector._debugRowPackData = packData
                            local currentComboBox = packData.m_owner --added with LSM 2.3 !
                            --Use LSM API func to get the current control's list and m_sorted items properly so addons do not have to take care of that again and again on their own
                            RunCustomScrollableMenuItemsCallback(currentComboBox, packData, saveUpdatedAddonPackCallbackFuncSubmenu, { LSM_ENTRY_TYPE_CHECKBOX }, false, GLOBAL_PACK_NAME, packName)
                        end,
                        enabled = false,--will get enabled by ther checkbox's callback
                        isSaveButton = true,
                        entryType = LSM_ENTRY_TYPE_BUTTON,
                        buttonTemplate = 'ZO_DefaultButton',
                        doNotFilter = true,
                    }
                end

                if numOnlyAddOnsInGlobalPack > 0 then
                    local addonsInPackText = string.format(addonsInPackStr .. " - #" .. numAddonsColorTemplate.."/%s", packName, tos(#addonTableSortedAddons), tos(numAddonsInGlobalPack)) .. " [" .. packNameGlobal .. "]"
                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = addonsInPackText, --Colored white/light grey
                        --[[
                        --No callback function -> Just a non clickable scrollable list of entries
                        callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                            --Do nothing, just show info
                            return true
                        end,
                        ]]
                        enabled = false, -- non clickable
                        isHeader = true,
                    }

                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    -->Normal addons first
                    for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedAddons) do
                        subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                            label = "|cF0F0F0" .. addonNameOfGlobalPackSorted .. "|r", --Colored white/light grey
                            name    = addonNameOfGlobalPackSorted,
                            callback = function(comboBox, itemName, rowControl, checked)
                                RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, packNameGlobal, packName)
                            end,
                            entryType = LSM_ENTRY_TYPE_CHECKBOX,
                            checked = true,
                            enabled = true,
                        }
                    end
                end

                if numDisabledAddonsInGlobalPack > 0 then
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = '-',
                        enabled = false,
                        isDivider = true,
                    }
                    local addonsInPackTextNotEnabled = string.format("["..disabledStr.."]" .. addonsInPackStr .. " - #" .. numAddonsColorTemplate .. "/%s", packName, tos(numDisabledAddonsInGlobalPack), tos(numAddonsInGlobalPack))
                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = addonsInPackTextNotEnabled, --Colored white/light grey
                        --[[
                        --No callback function -> Just a non clickable scrollable list of entries
                        callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                            --Do nothing, just show info
                            return true
                        end,
                        ]]
                        enabled = false, -- non clickable
                        isHeader = true,
                    }

                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    -->Normal addons first
                    for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedAddonsNotEnabled) do
                        subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                            label    = addonNameOfGlobalPackSorted .. " (" .. disabledStr .. ")",
                            name    = addonNameOfGlobalPackSorted,
                            callback = function(comboBox, itemName, rowControl, checked)
                                RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, packNameGlobal, packName)
                            end,
                            entryType = LSM_ENTRY_TYPE_CHECKBOX,
                            checked = true,
                            enabled = true,
                        }
                    end
                end

                if numMissingAddonsInGlobalPack > 0 then
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = '-',
                        enabled = false,
                        isDivider = true,
                    }
                    local addonsInPackTextMissing = string.format("["..missingStr.."]"..addonsInPackStr .. " - #" .. numAddonsColorTemplate .. "/%s", packName, tos(numMissingAddonsInGlobalPack), tos(numAddonsInGlobalPack))
                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = addonsInPackTextMissing, --Colored white/light grey
                        --[[
                        --No callback function -> Just a non clickable scrollable list of entries
                        callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                            --Do nothing, just show info
                            return true
                        end,
                        ]]
                        enabled = false, -- non clickable
                        isHeader = true,
                    }

                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    -->Normal addons first
                    for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedAddonsMissing) do
                        subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                            label    = "|cFF0000" .. addonNameOfGlobalPackSorted .. "|r",
                            name    = addonNameOfGlobalPackSorted,
                            callback = function(comboBox, itemName, rowControl, checked)
                                RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, packNameGlobal, packName)
                            end,
                            entryType = LSM_ENTRY_TYPE_CHECKBOX,
                            checked = true,
                            enabled = true,
                        }
                    end
                end

                if numLibrariesInGlobalPack > 0 then
                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    -->Libraries then
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = '-',
                        enabled = false,
                        isDivider = true,
                    }
                    local librariesInPackText = string.format(librariesInPackStr .. " - #" .. numLibrariesColorTemplate .. "/%s", packName, tos(#addonTableSortedLibraries), tos(numAddonsInGlobalPack))
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = librariesInPackText, --Colored white/light grey
                        --[[
                        --No callback function -> Just a non clickable scrollable list of entries
                        callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                            --Do nothing, just show info
                            return true
                        end,
                        ]]
                        enabled = false, -- non clickable
                        isHeader = true,
                    }

                    for _, libraryNameOfGlobalPackSorted in ipairs(addonTableSortedLibraries) do
                        subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                            label    = "|cF0F0F0" .. libraryNameOfGlobalPackSorted .. "|r", --Colored white/light grey
                            name    = libraryNameOfGlobalPackSorted,
                            callback = function(comboBox, itemName, rowControl, checked)
                                RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, packNameGlobal, packName)
                            end,
                            entryType = LSM_ENTRY_TYPE_CHECKBOX,
                            checked = true,
                            enabled = true,
                        }
                    end
                end

                if numDisabledLibrariesInGlobalPack > 0 then
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = '-',
                        enabled = false,
                        isDivider = true,
                    }
                    local librariesInPackTextNotEnabled = string.format("["..disabledStr.."]" .. librariesInPackStr .. " - #" .. numLibrariesColorTemplate .. "/%s", packName, tos(numDisabledLibrariesInGlobalPack), tos(numAddonsInGlobalPack))
                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = librariesInPackTextNotEnabled, --Colored white/light grey
                        --[[
                        --No callback function -> Just a non clickable scrollable list of entries
                        callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                            --Do nothing, just show info
                            return true
                        end,
                        ]]
                        enabled = false, -- non clickable
                        isHeader = true,
                    }

                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    -->Normal addons first
                    for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedLibrariesNotEnabled) do
                        subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                            label   = addonNameOfGlobalPackSorted .. " (" .. disabledStr .. ")",
                            name    = addonNameOfGlobalPackSorted,
                            callback = function(comboBox, itemName, rowControl, checked)
                                RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, packNameGlobal, packName)
                            end,
                            entryType = LSM_ENTRY_TYPE_CHECKBOX,
                            checked = true,
                            enabled = true,
                        }
                    end
                end

                if numMissingLibrariesInGlobalPack > 0 then
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = "-",
                        enabled = false, -- non clickable
                        isDivider = true,
                    }
                    local librariesInPackTextMissing = string.format("["..missingStr.."]" .. librariesInPackStr .. " - #" .. numLibrariesColorTemplate.."/%s", packName, tos(numMissingLibrariesInGlobalPack), tos(numAddonsInGlobalPack))
                    subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                        name    = librariesInPackTextMissing, --Colored white/light grey
                        --[[
                        --No callback function -> Just a non clickable scrollable list of entries
                        callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                            --Do nothing, just show info
                            return true
                        end,
                        ]]
                        enabled = false, -- non clickable
                        isHeader = true,
                    }

                    --Build nested submenuData for the submenu below, so one can see each single addon saved to the pack in the nested submenu
                    -->Normal addons first
                    for _, addonNameOfGlobalPackSorted in ipairs(addonTableSortedLibrariesMissing) do
                        subSubMenuEntriesGlobal[#subSubMenuEntriesGlobal + 1] = {
                            label    = "|cFF0000" .. addonNameOfGlobalPackSorted .. "|r",
                            name    = addonNameOfGlobalPackSorted,
                            callback = function(comboBox, itemName, rowControl, checked)
                                RunCustomScrollableMenuItemsCallback(comboBox, rowControl, getPackSubmenuSaveButtons, { LSM_ENTRY_TYPE_BUTTON }, false)
                                onCheckboxInAddonPackListClicked(comboBox, rowControl, itemName, checked, packNameGlobal, packName)
                            end,
                            entryType = LSM_ENTRY_TYPE_CHECKBOX,
                            checked = true,
                            enabled = true,
                        }
                    end
                end


            end --if showPacksAddonList == true then
            ------------------------------------------------------------------------------------------------------------------------

            if addPackTooltip == true and numAddonsInGlobalPack ~= nil then
                tooltipStr = (numAddonsInGlobalPack ~= nil
                    and (enabledAddonsInPackStr .. "\n'" ..
                        packName .. "': " ..tos(numAddonsInGlobalPack) .. "\n" ..
                        addonsStr .. ": " .. tos(numOnlyAddOnsInGlobalPack) ..
                        ((numDisabledAddonsInGlobalPack > 0 and "\n" .. disabledStr.. "': " ..tos(numDisabledAddonsInGlobalPack)) or "") ..
                        ((numMissingAddonsInGlobalPack > 0 and "\n" .. missingStr .. "': " ..tos(numMissingAddonsInGlobalPack)) or "")
                    )
                ) or nil
                if numLibrariesInGlobalPack > 0 and tooltipStr ~= nil then
                    tooltipStr = tooltipStr ..
                    "\n" .. librariesStr .. ": " .. tos(numLibrariesInGlobalPack) ..
                    ((numDisabledLibrariesInGlobalPack > 0 and "\n" .. disabledStr.. "': " ..tos(numDisabledLibrariesInGlobalPack)) or "") ..
                    ((numMissingLibrariesInGlobalPack > 0 and "\n" .. missingStr .. "': " ..tos(numMissingLibrariesInGlobalPack)) or "")
                end


            end

            subMenuEntriesGlobal = {
                {
                    name    = packName,
                    label   = selectPackStr .. autoReloadUISuffixSubmenu .. ": " .. packName,
                    callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
    --d(">submenuEntry callback of " .. tos(packName) .. ", packNameWithSelectPackStr: " ..tos(packNameWithSelectPackStr))
                        --OnClickDDL(comboBox, packName, packData, selectionChanged, oldItem)
                        --Pass in the addonTable of the pack, else it won't load properly!
                        OnClickDDL(comboBox, packName, packData, selectionChanged, oldItem)
                    end,
                    charName = GLOBAL_PACK_NAME,
                    addonTable = addonTable,
                    tooltip = tooltipStr or nil,
                    --Nested submenu showing all the addons in the pack
                    entries = (showPacksAddonList == true and subSubMenuEntriesGlobal) or nil,
                },
            }

            if not autoReloadUI then
                subMenuEntriesGlobal[#subMenuEntriesGlobal +1] =
                {
                    name    = "-",
                    isDivider = true,
                    callback = function() end,
                    disabled = true,
                }
                subMenuEntriesGlobal[#subMenuEntriesGlobal +1] =
                {
                    name    = packName,
                    label   = selectPackStr .. " & " .. reloadUIStr.. ": " .. packName,
                    callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                        OnClickDDL(comboBox, packName, packData, selectionChanged, oldItem)
                        ReloadUI("ingame")
                    end,
                    charName = GLOBAL_PACK_NAME,
                    addonTable = addonTable,
                }
            end

            subMenuEntriesGlobal[#subMenuEntriesGlobal +1] =
            {
                name    = "-",
                isDivider = true,
                callback = function() end,
                disabled = true,
            }
            subMenuEntriesGlobal[#subMenuEntriesGlobal +1] =
            {
                name    =  packName,
                label    = deletePackTitleStr .. " " .. packName,
                callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                    OnClick_Delete(packData, false)
                end,
                charName = GLOBAL_PACK_NAME,
                addonTable = addonTable,
            }

            subMenuEntriesGlobal[#subMenuEntriesGlobal +1] =
            {
                name    = "-",
                isDivider = true,
                callback = function() end,
                disabled = true,
            }

            local packNameCopy = packName
            subMenuEntriesGlobal[#subMenuEntriesGlobal +1] =
            {
                name    =  packName,
                label    = string.format(overwriteSavePackStr, packName),
                callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                    OnClick_Save(packNameCopy, packData, GLOBAL_PACK_NAME)
                end,
                charName = GLOBAL_PACK_NAME,
                addonTable = addonTable,
            }

            subMenuEntriesGlobal[#subMenuEntriesGlobal +1] = {
                name    = "-",
                isDivider = true,
                callback = function() end,
                disabled = true,
            }
            local keybindingEntries, keybindIconData = getKeybindingLSMEntriesForPacks(packName, GLOBAL_PACK_NAME)
            local keybindingEntriesCopy = ZO_ShallowNumericallyIndexedTableCopy(keybindingEntries)
            subMenuEntriesGlobal[#subMenuEntriesGlobal +1] = {
                name    =  GetString(SI_GAME_MENU_KEYBINDINGS),
                callback = nil,
                entries = keybindingEntriesCopy,
                charName = GLOBAL_PACK_NAME,
            }

            subMenuEntriesGlobal[#subMenuEntriesGlobal +1] = {
                name    = "-",
                isDivider = true,
                callback = function() end,
                disabled = true,
            }
            subMenuEntriesGlobal[#subMenuEntriesGlobal +1] = {
                name    = loadOnLogoutOrQuitStr,
                isCheckbox = true,
                callback = function(comboBox, itemName, rowControl, checked)
                    AS.acwsvChar.loadAddonPackOnLogout = nil
                    AS.acwsvChar.skipLoadAddonPackOnLogout = false
                    if checked == true then
                        AS.acwsvChar.loadAddonPackOnLogout = { packName = packNameCopy, charName = GLOBAL_PACK_NAME }
                    end
                    clearAndUpdateDDL()
                end,
                entryType = LSM_ENTRY_TYPE_CHECKBOX,
                checked = function()
                    return isAddonPackEnabledForAutoLoadOnLogout(packNameCopy, GLOBAL_PACK_NAME)
                end,
            }

            addedSubMenuEntryGlobal = true

            --end --if showSubMenuAtGlobalPacks == true then

            local label = packName

            local iconData = (autoReloadUI == true and { iconTexture=reloadUITexture, iconTint="FF0000", tooltip=reloadUIStrWithoutIcon }) or nil
            if not ZO_IsTableEmpty(keybindIconData) then
                iconData = iconData or {}
                for _, v in ipairs(keybindIconData) do
                    --tins(iconData, v)
                    label = label .. v.iconTexture
                end
            end

            local enabledAddonsInPackStrAddition = (addPackTooltip == true and numAddonsInGlobalPack ~= nil and ("\n" .. enabledAddonsInPackStr .. ": " ..tos(numAddonsInGlobalPack))) or ""

            ------------------------------------------------------------------------------------------------------------------------
            ---Context menu (right click) at the addon pack name
            local globalPackContextMenuCallbackFunc
            if addedSubMenuEntryGlobal then
                local subMenuEntriesCopy    = ZO_ShallowNumericallyIndexedTableCopy(subMenuEntriesGlobal)
                local subSubMenuEntriesCopy = (showPacksAddonList == true and ZO_ShallowNumericallyIndexedTableCopy(subSubMenuEntriesGlobal)) or nil
                globalPackContextMenuCallbackFunc = function()
                    ClearCustomScrollableMenu()
                    if not ZO_IsTableEmpty(subMenuEntriesCopy) then
                        for idx, submenuEntryData in ipairs(subMenuEntriesCopy) do
                            local entryType = submenuEntryData.entryType
                                    or (
                                        ((submenuEntryData.isDivider or submenuEntryData.name == "-") and LSM_ENTRY_TYPE_DIVIDER)
                                        or ((submenuEntryData.isHeader) and LSM_ENTRY_TYPE_HEADER)
                                        or ((submenuEntryData.isCheckbox) and LSM_ENTRY_TYPE_CHECKBOX)
                                        or ((submenuEntryData.isRadiobutton) and LSM_ENTRY_TYPE_RADIOBUTTON)
                                        or ((submenuEntryData.isButton) and LSM_ENTRY_TYPE_BUTTON)
                                    ) or LSM_ENTRY_TYPE_NORMAL
                            local callbackFunc = submenuEntryData.callback ~= nil and function(...) return submenuEntryData.callback(...) end or ((entryType == LSM_ENTRY_TYPE_HEADER and nil) or defaultCallbackFunc)
                            AddCustomScrollableMenuEntry(nil,
                                    callbackFunc,
                                    entryType,
                                    ((idx == 1 and subSubMenuEntriesCopy) or submenuEntryData.entries) or nil,    --entries
                                    {                                               --additionalData
                                        label = submenuEntryData.label,
                                        name = submenuEntryData.name,
                                        enabled = (submenuEntryData.disabled ~= nil and not submenuEntryData.disabled) or nil,
                                        checked = submenuEntryData.checked,
                                        buttonGroup = submenuEntryData.buttonGroup,
                                        buttonGroupOnSelectionChangedCallback = submenuEntryData.buttonGroupOnSelectionChangedCallback,

                                        --AddonSelector data
                                        charName = submenuEntryData.charName,
                                        addonTable = submenuEntryData.addonTable,
                                    }
                            )
                        end
                        ShowCustomScrollableMenu(nil, LSM_defaultContextMenuOptions)
                    end
                end
            end

            --Do not show submenus at the global packs?
            if not showSubMenuAtGlobalPacks then
                --Clear the submenu entries again now (will only be used for the contextMenu then)
                subMenuEntriesGlobal = nil
            end
            ------------------------------------------------------------------------------------------------------------------------

            local autoLoadThisPackOnLogout = isAddonPackEnabledForAutoLoadOnLogout(packName, GLOBAL_PACK_NAME)
            --if autoLoadThisPackOnLogout == true then
            --    label = label .. autoLoadOnLogoutTextureStr
            --end
            if autoLoadThisPackOnLogout == true then
                iconData = iconData or {}
                local skipAutoLoadPackAtLogout = AS.acwsvChar.skipLoadAddonPackOnLogout
                tins(iconData, { iconTexture=autoLoadOnLogoutTexture, iconTint=not skipAutoLoadPackAtLogout and "00FF22" or "FF0000", tooltip=loadOnLogoutOrQuitStr })
            end

            --CreateItemEntry(packName, addonTable, isCharacterPack, charName, tooltip, entriesSubmenu, isSubmenuMainEntry, isHeader)
            local itemGlobalData = createItemEntry(packName, label, addonTable, false, GLOBAL_PACK_NAME, "[" .. tostring(megaServer) .. "]"..accountWideStr.." \'" ..packName.."\'" .. enabledAddonsInPackStrAddition,
                    subMenuEntriesGlobal, subMenuEntriesGlobal ~= nil, false, iconData, globalPackContextMenuCallbackFunc)
            tins(packTable, itemGlobalData)
            wasItemAdded = true
        end --for _, packName in ipairs(addonPacksSortedLookup) do
------------------------------------------------------------------------------------------------------------------------
    end --showGlobalPacks
------------------------------------------------------------------------------------------------------------------------

    AS.comboBox:SetSortsItems(false)
--d("AddonSelector.comboBox:ClearItems()")
    AS.comboBox:ClearItems()

    if wasItemAdded == true then
        --tsor(packTable, customAddonPackSortFunc) --Disabled as the sorting would move the headers to wrong places. Sorting is done for character and global packs before adding to the table packTable now
        AS.comboBox:AddItems(packTable)
    end

    --Update the currently selected packName label
    UpdateCurrentlySelectedPackName(wasDeleted, nil, nil)
end

--OnMouseUp event function for the XML control editbox
function AddonSelector_OnMouseUp(editControl, mouseButton, upInside, ctrlKey, altKey, shiftKey, ...)
--d("[AddonSelector]EditBox OnMouseUp- mouseButton: " ..tos(mouseButton) ..", upInside: " ..tos(upInside))
    if mouseButton == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        local newText = editControl:GetText()
        if newText and newText == "" then
            --Get the current character name and format it
            if currentCharName and currentCharName ~= "" then
                editControl:SetText(currentCharName .. "_")
                editControl:SetMouseEnabled(true)
                editControl:TakeFocus()
            end
        end
    end
    return false
end

-- On text changed, when user types in the editBox
-- Clear the comboBox, check to make sure the text is not empty
-- I don't want it clearing the ddl when I manually call editBox:Clear()
function AddonSelector_TextChanged(editControl)
	local newText = editControl:GetText()
    local newEnabledState = false
    if newText ~= nil and newText ~= "" then
        newEnabledState = true
        --Deactivate the delete button as the combobox was emptied (non selected entry)
        ChangeDeleteButtonEnabledState(nil, false)
    else
        if AS.comboBox.m_selectedItemData ~= nil then
            newEnabledState = true
        end
    end
    --Enable/Disable the save pack button
    ChangeSaveButtonEnabledState(newEnabledState)
end

local function updateSaveModeTexure(doShow)
    AS.saveModeTexture:SetHidden(not doShow)
    ADDON_MANAGER_OBJECT:RefreshVisible()
end

local function updateAutoReloadUITexture(doShow)
    AS.autoReloadUITexture:SetHidden(not doShow)
    ADDON_MANAGER_OBJECT:RefreshVisible()
end


local function checkIfGlobalPacksShouldBeShown()
    local settings = AS.acwsv
    if not settings then return end
    local showGlobalPacks = settings.showGlobalPacks
    local savePerCharacter = settings.saveGroupedByCharacterName
    --Show the global pack entries if neither global packs nor character packs were selected to save/show!
    if showGlobalPacks == false and savePerCharacter == false then
        AS.acwsv.showGlobalPacks = true
    end
    updateSaveModeTexure(savePerCharacter)
end


-- called from clicking the "Auto reload" label
local function OnClick_CheckBoxLabel(selfVar, currentStateVar)
--d("OnClick_CheckBoxLabel-currentStateVar: " ..tos(currentStateVar))
    if AS.acwsv[currentStateVar] == nil then return end
    local currentState        = AS.acwsv[currentStateVar]
--d(">currentState of \'".. currentStateVar .."\': " ..tos(currentState))
    local newState = not currentState
    AS.acwsv[currentStateVar] = newState
    --Clear the selected addon pack
    if newState == true then
        deselectComboBoxEntry()
    end
    --Reenable/Disable delete button?
    ChangeDeleteButtonEnabledState(newState, nil)

    --Any setting was changed that needs to update the comboox's dropdown entries?
    if settingNeedsToUpdateDDL[currentStateVar] then
        --Rebuild the dropdown entries
        updateDDL()
        if currentStateVar == "autoReloadUI" then
            updateAutoReloadUITexture(newState)
        end
    end
end

-- called from clicking the button
--[[
local function OnClick_AutoReload(self, button, upInside, ctrl, alt, shift, command)
	if not upInside then return end
	if not button == MOUSE_BUTTON_INDEX_LEFT then return end
	local checkedState = self:GetState()
    AddonSelector.acwsv.autoReloadUI = checkedState
    --Clear the selected addon pack
    if checkedState == true then
        deselectComboBoxEntry()
    end
    --Reenable/Disable delete button?
    ChangeDeleteButtonEnabledState(checkedState)
end
]]

local function OnClick_SaveDo(wasPackNameProvided, packName, characterName)
    wasPackNameProvided = wasPackNameProvided or false
    if wasPackNameProvided == false then
        packName = AS.editBox:GetText()
    end

    if not packName or packName == "" then
        if wasPackNameProvided == true then return end

        local itemData = AS.comboBox:GetSelectedItemData()
        if not itemData then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, AddonSelector_GetLocalizedText("ERRORpackMissing"))
            return
        end
        packName = itemData.name
    end

    --Overwrite an existing pack without selecting it (chose "Overwrite" from submenu)
    if wasPackNameProvided == true then
        --Get SavedVariables table for the existing pack and update the pack there
        saveAddonsAsPackToSV(packName, false, characterName, wasPackNameProvided)

        clearAndUpdateDDL()
    else
        --Get SavedVariables table for the pack and update the pack there
        local svForPack = saveAddonsAsPackToSV(packName, false, nil, false)
        -- Create a temporary copy of the itemEntry data so we can select it
        -- after the ddl is updated
        local savePackPerCharacter = AS.acwsv.saveGroupedByCharacterName
        --CreateItemEntry(packName, addonTable, isCharacterPack, charName, tooltip, entriesSubmenu, isSubmenuMainEntry, isHeader)
        local itemData = createItemEntry(packName, nil, svForPack, false, (savePackPerCharacter and currentCharName) or GLOBAL_PACK_NAME, nil, nil, nil, true)

        clearAndUpdateDDL()
        --Prevent reloadui for a currently new saved addon pack!
        doNotReloadUI = true
        AS.comboBox:SelectItem(itemData)
        doNotReloadUI = false

        --Disable the "save pack" button
        ChangeSaveButtonEnabledState(true)
    end
end

local function isPackKeybindUsed(keybindNr, packName, charName)
    if keybindNr == nil or keybindNr < 1 or keybindNr > MAX_ADDON_LOAD_PACK_KEYBINDS then return false end
    if packName == nil or packName == "" or charName == nil or charName == "" then return false end

    local packKeybinds = AS.acwsv.packKeybinds
    local packDataToLoad = packKeybinds[keybindNr]
    if packDataToLoad ~= nil and packDataToLoad.packName ~= nil then
        if packName == nil or (packName ~= nil and packName == packDataToLoad.packName) then
            if charName == nil or (charName ~= nil and charName == packDataToLoad.charName) then
                return true
            else
                return false
            end
        else
            return false
        end
        return true
    end
    return false
end
local function removePackFromKeybind(keybindNr, packName, charName)
    if keybindNr == nil or keybindNr < 1 or keybindNr > MAX_ADDON_LOAD_PACK_KEYBINDS then return false end
    if packName == nil or packName == "" or charName == nil or charName == "" then return false end

    local packKeybinds = AS.acwsv.packKeybinds
    local packDataToLoad = packKeybinds[keybindNr]
    if packDataToLoad ~= nil and packDataToLoad.packName ~= nil then
        AS.acwsv.packKeybinds[keybindNr] = {}
        return true
    end
    return false
end

local function savePackToKeybind(keybindNr, packName, charName)
    if keybindNr == nil or keybindNr < 1 or keybindNr > MAX_ADDON_LOAD_PACK_KEYBINDS then return false end
    if packName == nil or packName == "" or charName == nil or charName == "" then return false end

    local packKeybinds = AS.acwsv.packKeybinds
    packKeybinds[keybindNr] = packKeybinds[keybindNr] or {}
    local packDataToLoad = packKeybinds[keybindNr]
    --if packDataToLoad.packName ~= nil then
    --todo: Ask before overwrite the keybind?
    --end
    packDataToLoad.packName = packName
    packDataToLoad.charName = charName
    return true
end

function getKeybindingLSMEntriesForPacks(packName, charName)
    local keybindEntries = {}
    local keybindIconData = {}
    for keybindNr = 1, MAX_ADDON_LOAD_PACK_KEYBINDS, 1 do
        local isPackAlreadySavedAsKeybind = isPackKeybindUsed(keybindNr, packName, charName)
        if isPackAlreadySavedAsKeybind == false then
            keybindEntries[#keybindEntries + 1] = {
                name = strfor(addPackToKeybindStr, tos(keybindNr)),
                callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                    savePackToKeybind(keybindNr, packName, charName)
                    clearAndUpdateDDL()
                end,
                entryType = LSM_ENTRY_TYPE_NORMAL,
            }
        else
            keybindEntries[#keybindEntries + 1] = {
                name = strfor(removePackFromKeybindStr, tos(keybindNr)),
                callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                    removePackFromKeybind(keybindNr, packName, charName)
                    clearAndUpdateDDL()
                end,
                entryType = LSM_ENTRY_TYPE_NORMAL,
            }

            keybindIconData[#keybindIconData +1] = {
                iconTexture=keybindTexturesLoadPack[keybindNr], iconTint="FFFFFF", tooltip=AddonSelector_GetLocalizedText("LoadPackByKeybind" .. tos(keybindNr))
            }
        end
    end
    return keybindEntries, keybindIconData
end

-- When the save button is clicked, creates a table containing all
-- enabled addons:  { [AddOnFileName] = AddonStrippedName, ...}
function OnClick_Save(packName, packData, characterName)
    local newPackName
    local wasPackNameProvided = (packName ~= nil and packData ~= nil and characterName ~= nil and true) or false
--d("[AddonSelector]OnClick_Save - packName: " ..tos(packName) .. ", characterName: " ..tos(characterName))

    if packName ~= nil then
        if packData == nil or characterName == nil then return end
        newPackName = packName
    else
        newPackName = AS.editBox:GetText()
        if not newPackName or newPackName == "" then
            local itemData = AS.comboBox.m_selectedItemData
            if itemData then
                newPackName = itemData.name
            end
        end
    end

    if not newPackName or newPackName == "" then
        return
    end

    local doesPackAlreadyExist = false
    local saveGroupedByChar = false
    local svTable


    local savePerCharacter = AS.acwsv.saveGroupedByCharacterName
    if savePerCharacter == false and wasPackNameProvided == true and (characterName ~= nil and characterName ~= GLOBAL_PACK_NAME) then
        savePerCharacter = true
    end

    local packCharacter = packNameGlobal
    --Save grouped by charactername
--d(">savePerChar: " ..tos(savePerCharacter) .. ", newPackName: " ..tos(newPackName))
    if savePerCharacter == true then
        local svTableOfCurrentChar, charName
        if wasPackNameProvided == true then
--d(">charname was provided")
            svTableOfCurrentChar, charName = getSVTableForPacks(characterName)
        else
            svTableOfCurrentChar, charName = getSVTableForPacks()
        end
--d(">>charName: " ..tos(charName))
        if svTableOfCurrentChar ~= nil and charName ~= nil then
--d(">>>svTableOfCurrentChar ~= nil and charName ~= nil -> simulate saveGroupedByChar = true")
            saveGroupedByChar = true
            svTable = svTableOfCurrentChar
            packCharacter = charName
        end
    end
    if not saveGroupedByChar then
        svTable = AS.acwsv.addonPacks
    end

--AS._debugSvTable = svTable

    --Does the pack name already exist?
    doesPackAlreadyExist = (svTable[newPackName] ~= nil and true) or false
    if doesPackAlreadyExist == true then
        local addonPackName = "\'" .. newPackName .. "\'"
        local savePackQuestion = strfor(AddonSelector_GetLocalizedText("savePackBody"), tos(addonPackName))
        ShowConfirmationDialog("SaveAddonPackDialog",
                (AddonSelector_GetLocalizedText("savePackTitle")) .. "\n" ..
                        "[".. (saveGroupedByChar and strfor(charNamePackColorTemplate, packCharacter) or packCharacter) .. "]\n" .. newPackName,
                savePackQuestion,
                function() OnClick_SaveDo(wasPackNameProvided, packName, characterName) end,
                function() OnAbort_Do(true, false, nil, nil, nil) end,
                nil,
                nil,
                true
        )
    else
        --Pack does not exist but we passed in packName, packData and characterName -> Error
        if wasPackNameProvided == true then return end

        OnClick_SaveDo()
    end
end

--OnMouseUp event for the selected pack name label
local function OnClick_SelectedPackNameLabel(selfVar, button, upInside, ctrl, alt, shift, command)
--d("[AddonSelector]OnClick_SelectedPackNameLabel")
    if not upInside or button ~= MOUSE_BUTTON_INDEX_LEFT or not AS.editBox then return end
    --Set the "name edit" to the currently selected addon pack entry so you just need to hit the save button afterwards
    local currentlySelectedPacknamesForChars = AS.acwsv.selectedPackNameForCharacters
    if not currentlySelectedPacknamesForChars then return end
    local currentCharactersSelectedPackNameData = currentlySelectedPacknamesForChars[currentCharId] --currentCharIdNum changed to String at 15.07.2022, 00:30am
    if currentCharactersSelectedPackNameData and currentCharactersSelectedPackNameData.packName ~= "" then
        AS.editBox:Clear()
        AS.editBox:SetText(currentCharactersSelectedPackNameData.packName)
    end
end

local function setMenuItemCheckboxState(checkboxIndex, newState)
    newState = newState or false
    if newState == true then
        ZO_CheckButton_SetChecked(ZO_Menu.items[checkboxIndex].checkbox)
    else
        ZO_CheckButton_SetUnchecked(ZO_Menu.items[checkboxIndex].checkbox)
    end
end

--Show the settings context menu at the dropdown button
function AddonSelector_ShowSettingsDropdown(buttonCtrl)
    local areAllAddonsCurrentlyEnabled = areAddonsCurrentlyEnabled()
    local disabledColor = ( not areAllAddonsCurrentlyEnabled and myDisabledColor) or nil

    ClearMenu()

    --Add the currently logged in character name as header
    AddCustomMenuItem(currentCharName, function() end, MENU_ADD_OPTION_HEADER)

    --Last changed addons backup/restore
    if AS.acwsv.lastMassMarkingSavedProfile ~= nil then
        local lastSavedPreMassMarkingTime = ""
        local countAddonsInBackup = NonContiguousCount(AS.acwsv.lastMassMarkingSavedProfile)
        if AS.acwsv.lastMassMarkingSavedProfileTime ~= nil then
            lastSavedPreMassMarkingTime = os.date("%c", AS.acwsv.lastMassMarkingSavedProfileTime)
        end
        if countAddonsInBackup ~= nil and countAddonsInBackup > 0 then
            --AddCustomMenuItem(mytext, myfunction, itemType, myFont, normalColor, highlightColor, itemYPad, horizontalAlignment, isHighlighted, onEnter, onExit, enabled)
            AddCustomMenuItem(AddonSelector_GetLocalizedText("UndoLastMassMarking") .. " #" .. tos(countAddonsInBackup) .." (" .. tos(lastSavedPreMassMarkingTime) .. ")", function() AddonSelector_UndoLastMassMarking(false) end, MENU_ADD_OPTION_LABEL, nil, disabledColor, nil, nil, nil, nil, nil, nil, areAllAddonsCurrentlyEnabled)
        end
        AddCustomMenuItem(AddonSelector_GetLocalizedText("ClearLastMassMarking"),function() AddonSelector_UndoLastMassMarking(true) end, MENU_ADD_OPTION_LABEL, nil, disabledColor, nil, nil, nil, nil, nil, nil, areAllAddonsCurrentlyEnabled)
        AddCustomMenuItem("-", function() end, MENU_ADD_OPTION_LABEL)
    end

    --Deselect/Select all
    AddCustomMenuItem(AddonSelector_GetLocalizedText("DeselectAllAddons"),      function() AddonSelector_SelectAddons(false, nil, nil) end, MENU_ADD_OPTION_LABEL, nil, disabledColor, nil, nil, nil, nil, nil, nil, areAllAddonsCurrentlyEnabled)
    local currentAddonSelectorSelectAllButtonText = addonSelectorSelectAddonsButtonNameLabel:GetText()
    if currentAddonSelectorSelectAllButtonText ~= selectAllText then
        AddCustomMenuItem(currentAddonSelectorSelectAllButtonText,              function() AddonSelector_SelectAddons(true, nil, nil) end, MENU_ADD_OPTION_LABEL, nil, disabledColor, nil, nil, nil, nil, nil, nil, areAllAddonsCurrentlyEnabled)
    end
    AddCustomMenuItem(selectAllText,                                            function() AddonSelector_SelectAddons(true, true, nil) end, MENU_ADD_OPTION_LABEL, nil, disabledColor, nil, nil, nil, nil, nil, nil, areAllAddonsCurrentlyEnabled)
    AddCustomMenuItem(AddonSelector_GetLocalizedText("DeselectAllLibraries"),   function() AddonSelector_SelectAddons(false, true, true) end, MENU_ADD_OPTION_LABEL, nil, disabledColor, nil, nil, nil, nil, nil, nil, areAllAddonsCurrentlyEnabled)
    AddCustomMenuItem(AddonSelector_GetLocalizedText("SelectAllLibraries"),     function() AddonSelector_SelectAddons(true, true, true) end, MENU_ADD_OPTION_LABEL, nil, disabledColor, nil, nil, nil, nil, nil, nil, areAllAddonsCurrentlyEnabled)
    AddCustomMenuItem("-", function()end, MENU_ADD_OPTION_LABEL)

    --Scroll to addons/libraries
    AddCustomMenuItem(AddonSelector_GetLocalizedText("ScrollToAddons"),         function() AddonSelector_ScrollTo(true)  end, MENU_ADD_OPTION_LABEL)
    AddCustomMenuItem(AddonSelector_GetLocalizedText("ScrollToLibraries"),      function() AddonSelector_ScrollTo(false) end, MENU_ADD_OPTION_LABEL)
    AddCustomMenuItem("-", function() end, MENU_ADD_OPTION_LABEL)

    --Add the global pack options
    checkIfGlobalPacksShouldBeShown()
    local globalPackSubmenu = {
        {
            label    = AddonSelector_GetLocalizedText("ShowGlobalPacks"),
            callback = function(state)
                AS.acwsv.showGlobalPacks = state
                checkIfGlobalPacksShouldBeShown()
                clearAndUpdateDDL()
            end,
            checked  = function() return AS.acwsv.showGlobalPacks end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
        {
            label    = AddonSelector_GetLocalizedText("ShowSubMenuAtGlobalPacks"),
            callback = function(state)
                AS.acwsv.showSubMenuAtGlobalPacks = state
                clearAndUpdateDDL()
            end,
            checked  = function() return AS.acwsv.showSubMenuAtGlobalPacks end,
            disabled = function() return not AS.acwsv.showGlobalPacks end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
    }
    AddCustomSubMenuItem(AddonSelector_GetLocalizedText("GlobalPackSettings"), globalPackSubmenu)

    --Add the character pack options
    local characterNameSubmenu = {
        {
            label    = savedGroupedByCharNameStr,
            callback = function(state)
                AS.acwsv.saveGroupedByCharacterName = state
                checkIfGlobalPacksShouldBeShown()
                if state == true then
                    AS.acwsv.showGroupedByCharacterName = true
                end
                clearAndUpdateDDL()
            end,
            checked  = function() return AS.acwsv.saveGroupedByCharacterName end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
        {
            label    = AddonSelector_GetLocalizedText("ShowGroupedByCharacterName"),
            callback = function(state)
                AS.acwsv.showGroupedByCharacterName = state
                checkIfGlobalPacksShouldBeShown()
                clearAndUpdateDDL()
            end,
            checked  = function() return AS.acwsv.showGroupedByCharacterName end,
            disabled = function(rootMenu, childControl) return AS.acwsv.saveGroupedByCharacterName end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
        {
            label    = AddonSelector_GetLocalizedText("ShowPacksOfOtherAccountsChars"),
            callback = function(state)
                AS.acwsv.showPacksOfOtherAccountsChars = state
                clearAndUpdateDDL()
            end,
            checked  = function() return AS.acwsv.showPacksOfOtherAccountsChars end,
            disabled = function(rootMenu, childControl) return not AS.acwsv.saveGroupedByCharacterName and not AS.acwsv.showGroupedByCharacterName end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
    }
    AddCustomSubMenuItem(AddonSelector_GetLocalizedText("CharacterNameSettings"), characterNameSubmenu)


    --Add the search options
    local searchOptionsSubmenu = {
        {
            label    = AddonSelector_GetLocalizedText("searchExcludeFilename"),
            callback = function(state)
                AS.acwsv.searchExcludeFilename = state
            end,
            checked  = function() return AS.acwsv.searchExcludeFilename end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
        {
            label    = AddonSelector_GetLocalizedText("searchSaveHistory"),
            callback = function(state)
                AS.acwsv.searchSaveHistory = state
            end,
            checked  = function() return AS.acwsv.searchSaveHistory end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        }
    }
    AddCustomSubMenuItem(searchMenuStr, searchOptionsSubmenu)

    --Add the auto reload pack after selection checkbox
    local cbAutoReloadUIindex = AddCustomMenuItem(reloadUITextureStr .. autoReloadUIStr,
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "autoReloadUI")
            end,
            MENU_ADD_OPTION_CHECKBOX)
    setMenuItemCheckboxState(cbAutoReloadUIindex, AS.acwsv.autoReloadUI)

    --Add the pack tooltip after autoRealoadUI checkbox
    local cbAddPackTooltipIndex = AddCustomMenuItem(addPackTooltipStr,
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "addPackTooltip")
            end,
            MENU_ADD_OPTION_CHECKBOX)
    setMenuItemCheckboxState(cbAddPackTooltipIndex, AS.acwsv.addPackTooltip)

    --Add the pack's addon list submenu after pack tooltip checkbox
    local cbShowPacksAddonListIndex = AddCustomMenuItem(showPacksAddonListStr,
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "showPacksAddonList")
            end,
            MENU_ADD_OPTION_CHECKBOX)
    setMenuItemCheckboxState(cbShowPacksAddonListIndex, AS.acwsv.showPacksAddonList)

    --Show search header at the addon packs dropdown
    local cbShowSearchFilterAtPacksListIndex = AddCustomMenuItem(showSearchFilterAtPacksListStr,
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "showSearchFilterAtPacksList")
            end,
            MENU_ADD_OPTION_CHECKBOX)
    setMenuItemCheckboxState(cbShowSearchFilterAtPacksListIndex, AS.acwsv.showSearchFilterAtPacksList)


    --Last pack loaded info
    local lastLoadedPackData = AS.acwsv.lastLoadedPackNameForCharacters and AS.acwsv.lastLoadedPackNameForCharacters[currentCharId]
    if lastLoadedPackData ~= nil then
        local lastLoadedPackCharName = lastLoadedPackData.charName
        local lastLoadedPackCharNameReal = lastLoadedPackData.charName
        if lastLoadedPackCharName == GLOBAL_PACK_NAME then
           lastLoadedPackCharName = packNameGlobal
        end
        local lastLoadedPackName = lastLoadedPackData.packName
        local packStillExistsAndIsSelectable = true
        --Check if that pack still exists or not
        local outputColorCharStart = ""
        local outputColorCharEnd = ""
        local outputColorStart = ""
        local outputColorEnd = ""
        local addonPacksOfCharOrGlobal, _ = getSVTableForPackBySavedType(lastLoadedPackCharNameReal)
        if addonPacksOfCharOrGlobal == nil then
            --Pack does not exist anymore - Change the output color to red
            if lastLoadedPackCharName == GLOBAL_PACK_NAME then
                outputColorStart =  "|cFF0000"
                outputColorEnd =    "|r"
                packStillExistsAndIsSelectable = false
            else
                outputColorCharStart =  "|cFF0000"
                outputColorCharEnd =    "|r"
                packStillExistsAndIsSelectable = false
            end
        else
            if lastLoadedPackName == nil or addonPacksOfCharOrGlobal[lastLoadedPackName] == nil then
                outputColorStart =  "|cFF0000"
                outputColorEnd =    "|r"
                packStillExistsAndIsSelectable = false
            end
        end

        local lastLoadedPackTime = ""
        lastLoadedPackTime = os.date("%c", lastLoadedPackData.timestamp)
        if lastLoadedPackCharName ~= "" and lastLoadedPackName ~= "" and lastLoadedPackTime ~= "" then
            --AddCustomMenuItem(mytext, myfunction, itemType, myFont, normalColor, highlightColor, itemYPad, horizontalAlignment)
            AddCustomMenuItem(AddonSelector_GetLocalizedText("LastPackLoaded"), function() end, MENU_ADD_OPTION_HEADER, nil, nil, nil, 6)
            AddCustomMenuItem("[" .. outputColorCharStart .. tos(lastLoadedPackCharName) .. outputColorCharEnd .."]" .. outputColorStart .. tos(lastLoadedPackName) .. outputColorEnd ..  " (" .. tos(lastLoadedPackTime) ..")",
                function()
                    --TODO Set the pack to the dropddown box again
                    if packStillExistsAndIsSelectable == true then
                        doNotReloadUI = true
                        --todo Select the entry in the pack dropdown box now and activate the addons of the pack that way
                        --But do not reloadUI automatically!
                        local function evalFunc(entry)
                            if entry.isCharacterPackHeader == false then
                                if entry.name == lastLoadedPackName and entry.charName == lastLoadedPackCharNameReal then
                                    return true
                                end
                            end
                            return false
                        end
                        AS.ddl.m_comboBox:SetSelectedItemByEval(evalFunc, false) --do not ignore the callback -> run it!
                        doNotReloadUI = false
                    end
                end, MENU_ADD_OPTION_LABEL, nil, disabledColor, nil, nil, nil, nil, nil, nil, areAllAddonsCurrentlyEnabled)
        end
    end

    ShowMenu(buttonCtrl)
end


-- Used to change the layout of the Addon scrollList to
-- make room for the AddonSelector control
function AS.ChangeLayout()
	--local template = ZO_AddOns
	--local divider = ZO_AddOnsDivider
	local list = ZOAddOnsList
	--local bg = ZO_AddonsBGLeft
	list:ClearAnchors()
	list:SetAnchor(TOPLEFT, AS.addonSelectorControl, BOTTOMLEFT, 0, 10)
	-- This does not work ?? Items get cut off.
	--list:SetAnchor(BOTTOMRIGHT, bg, BOTTOMRIGHT, -20, -100)
	--list:SetDimensions(885, 560)
	ZO_ScrollList_SetHeight(list, 600)
	ZO_ScrollList_Commit(list)
end

local function onMouseEnterTooltip(ctrl)
    ZO_Tooltips_ShowTextTooltip(ctrl, TOP, ctrl.tooltipText)
end
local function onMouseExitTooltip()
    ZO_Tooltips_HideTextTooltip()
end


-- Create the AddonSelector control, set references to controls
-- and click handlers for the save/delete buttons
function AS.CreateControlReferences()
    local settings                         = AS.acwsv
    -- Create Controls:
    local addonSelector                    = CreateControlFromVirtual("AddonSelector", ZOAddOns, "AddonSelectorVirtualTemplate", nil)

    -- Assign references:
    AS.addonSelectorControl                = addonSelector
    addonSelector._AddonSelectorObject = AS

    AS.ddl                                 = addonSelector:GetNamedChild("ddl") --<Control name="$(parent)ddl" inherits="ZO_ComboBox" mouseEnabled="true" >
    --LibScrollableMenu - Add scrollable menu + submenu possibility at the dropdown list (ZO_ComboBox)
    -->No more need to overwrite AddonSelector.ddl.m_comboBox:AddMenuItems below in this addon's code!
    -->Just use AddonSelector.ddl.m_comboBox:AddItems(tableWithMenuAndSubmenuEntries) instead, or in this addon use AddonSelector.UpdateDDL as it already exists to do the AddItems() call
    --AddonSelector.ddl = CreateControlFromVirtual  ZO_ComboBox
    --		table	narrate:optional				Table or function returning a table with key = narration event and value = function called for that narration event.
    --												The functions signature/parameters always is scrollHelperObject, control, data:nilable, isSubmenu:nilable
    --												-> The function either builds your narrateString and narrates it in your addon.
    --												   Or you must return a string as 1st return param (and optionally a boolean "stopCurrentNarration" as 2nd return param. If this is nil it will be set to false!)
    --												    and let the library here narrate it for you via the UI narration
    --												Optional narration events can be:
    --												"OnComboBoxMouseEnter" 	function(scrollhelperObject, dropdownControl)  Build your narrateString and narrate it now, or return a string and let the library narrate it for you end
    --												"OnComboBoxMouseExit"	function(scrollhelperObject, dropdownControl) end
    --												"OnMenuShow"			function(scrollhelperObject, dropdownControl) end
    --												"OnMenuHide"			function(scrollhelperObject, dropdownControl) end
    --												"OnSubMenuShow"			function(scrollhelperObject, parentControl) end
    --												"OnSubMenuHide"			function(scrollhelperObject, parentControl) end
    --												"OnEntryMouseEnter"		function(scrollhelperObject, entryControl, data, isSubmenu) end
    --												"OnEntryMouseExit"		function(scrollhelperObject, entryControl, data, isSubmenu) end
    --												"OnEntrySelected"		function(scrollhelperObject, entryControl, data, isSubmenu) end
    --												"OnCheckboxUpdated"		function(scrollhelperObject, checkboxControl, data) end
    --			Example:	narrate = { ["OnDropdownMouseEnter"] = myAddonsNarrateDropdownOnMouseEnter, ... }
    AS.ddl.scrollHelper                    = AddCustomScrollableComboBoxDropdownMenu(addonSelector, AS.ddl, LSM_defaultAddonPackMenuOptions) --Entries will be added at AddonSelector.UpdateDDL(wasDeleted)

    AS.comboBox                            = AS.ddl.m_comboBox
    local savedPacksComboBox               = AS.comboBox

    AS.editBox                             = addonSelector:GetNamedChild("EditBox")

    AS.saveBtn                             = addonSelector:GetNamedChild("Save")
    AS.deleteBtn                           = addonSelector:GetNamedChild("Delete")
    --AddonSelector.autoReloadBtn = addonSelector:GetNamedChild("AutoReloadUI")
    --AddonSelector.autoReloadLabel = AddonSelector.autoReloadBtn:GetNamedChild("Label")
    AS.settingsOpenDropdown                = addonSelector:GetNamedChild("SettingsOpenDropdown")
    AS.settingsOpenDropdown.onClickHandler = AS.settingsOpenDropdown:GetHandler("OnClicked")
    --PerfectPixel: Reposition of the settings "gear" icon -> move up to other icons (like Votans Addon List)
    AS.settingsOpenDropdown:ClearAnchors()
    --<Anchor point="TOPLEFT" relativeTo="ZO_AddOns" relativePoint="TOP" offsetX="100" offsetY="65"/>
    local offsetX = (PP ~= nil and 40) or 100
    local offsetY = (PP ~= nil and -7) or 65
    AS.settingsOpenDropdown:SetAnchor(TOPLEFT, ZOAddOns, TOP, offsetX, offsetY)

    AS.searchBox = addonSelector:GetNamedChild("SearchBox")
    AS.searchBox:SetHandler("OnMouseUp", function(selfCtrl, mouseButton, isUpInside)
        if isUpInside and mouseButton == MOUSE_BUTTON_INDEX_RIGHT then
            local doShowMenu = false
            local searchHistoryWasAdded = false
            if settings.searchSaveHistory then
                local searchHistory = settings.searchHistory
                local searchType = SEARCH_TYPE_NAME
                local searchHistoryOfSearchMode = searchHistory[searchType]
                if searchHistoryOfSearchMode ~= nil and #searchHistoryOfSearchMode > 0 then
                    ClearMenu()
                    for _, searchTerm in ipairs(searchHistoryOfSearchMode) do
                        AddCustomMenuItem(searchTerm, function()
                            openGameMenuAndAddOnsAndThenSearch(searchTerm, true, false)
                            ClearMenu()
                        end)
                    end
                    AddCustomMenuItem("-", function() end)
                    AddCustomMenuItem(clearSearchHistoryStr, function()
                        clearSearchHistory(searchType)
                        ClearMenu()
                    end)
                    doShowMenu = true
                    searchHistoryWasAdded = true
                end
            end
            --AddonCategory support
            if isAddonCategoryEnabled == true then
                addonCategoryCategories, addonCategoryIndices = getAddonCategoryCategories()
                if addonCategoryCategories ~= nil and #addonCategoryCategories > 0 then
                    if not searchHistoryWasAdded then
                        ClearMenu()
                    else
                        AddCustomMenuItem(addonCategoriesStr, function() end, MENU_ADD_OPTION_HEADER)
                    end
                    for _, searchTerm in ipairs(addonCategoryCategories) do
                        AddCustomMenuItem(searchTerm, function()
                            openGameMenuAndAddOnsAndThenSearch(searchTerm, true, true)
                            ClearMenu()
                        end)
                    end
                    doShowMenu = true
                end
            end
            --Show the context menu now?
            if doShowMenu == true then
                ShowMenu(selfCtrl)
            end
        elseif isUpInside and mouseButton == MOUSE_BUTTON_INDEX_LEFT then
            local currentText = selfCtrl:GetText()
            if currentText ~= nil then
                local narrateText = searchMenuStr
                if currentText == "" then
                    narrateText = searchInstructions
                else
                    narrateText = "["..narrateText .. "]  " .. currentText
                end
                OnUpdateDoNarrate("OnAddonSearchLeftClicked", 0, function() AddNewChatNarrationText(narrateText, true)  end)
            end
        end
    end)
    AS.searchLabel = addonSelector:GetNamedChild("SearchBoxLabel")
    AS.searchLabel:SetText(AddonSelector_GetLocalizedText("AddonSearch"))
    AS.selectedPackNameLabel = addonSelector:GetNamedChild("SelectedPackNameLabel")

    AS.saveModeTexture       = addonSelector:GetNamedChild("SaveModeTexture")
    AS.saveModeTexture:SetTexture("/esoui/art/characterselect/gamepad/gp_characterselect_characterslots.dds")
    AS.saveModeTexture:SetColor(charNamePackColorDef:UnpackRGBA())
    AS.saveModeTexture:SetMouseEnabled(true)
    AS.saveModeTexture.tooltipText = savedGroupedByCharNameStr
    AS.saveModeTexture:SetHandler("OnMouseEnter", onMouseEnterTooltip)
    AS.saveModeTexture:SetHandler("OnMouseExit", onMouseExitTooltip)

    AS.autoReloadUITexture = addonSelector:GetNamedChild("AutoReloadUITexture")
    AS.autoReloadUITexture:SetTexture(reloadUITexture)
    AS.autoReloadUITexture:SetColor(1, 0, 0, 0.6)
    AS.autoReloadUITexture:SetMouseEnabled(true)
    AS.autoReloadUITexture.tooltipText = autoReloadUIStr
    AS.autoReloadUITexture:SetHandler("OnMouseEnter", onMouseEnterTooltip)
    AS.autoReloadUITexture:SetHandler("OnMouseExit", onMouseExitTooltip)

    -- Set Saved Btn State for checkbox "Auto reloadui after pack selection"
    local checkedState = settings.autoReloadUI
    updateAutoReloadUITexture(checkedState)
    --AddonSelector.autoReloadBtn:SetState(checkedState)
    --Disable the "save pack" button
    ChangeSaveButtonEnabledState(false)
    --Disable the "delete pack" button
    ChangeDeleteButtonEnabledState(checkedState)
    --Show the currently selected pack name for the logged in character
    UpdateCurrentlySelectedPackName(nil, nil, nil)

    -- Add Tooltips for AutoReloadUI
    --[[
    local function OnMouseEnter()
        local toolTipText = AddonSelector_GetLocalizedText("autoReloadUIHintTooltip")
        InitializeTooltip(InformationTooltip, AddonSelector.autoReloadLabel, LEFT, 26, 0, RIGHT)
        InformationTooltip:AddLine(toolTipText)
    end
    local function OnMouseExit()
        ClearTooltip(InformationTooltip)
    end
    ]]



    local function OnMouseEnter(ctrl)
        local toolTipText = AddonSelector_GetLocalizedText("ShowSettings")
        if not toolTipText then return end
        ZO_Tooltips_ShowTextTooltip(ctrl, TOP, toolTipText)
    end
    local function OnMouseExit()
        ZO_Tooltips_HideTextTooltip()
    end
    --[[
    local function OnMouseUp_SettingsLabel(settingsLabel, mouseButton, upInside)
        ZO_Tooltips_HideTextTooltip()
        if not upInside or not mouseButton == MOUSE_BUTTON_INDEX_LEFT then return end
        AddonSelector_ShowSettingsDropdown(AddonSelector.settingsOpenDropdown)
    end
    ]]

    -- SetHandlers:
    AS.saveBtn:SetHandler("OnMouseUp", function(ctrl) OnClick_Save() end)
    AS.deleteBtn:SetHandler("OnMouseUp", function() OnClick_Delete(nil, true) end)
    --AddonSelector.autoReloadBtn:SetHandler("OnMouseUp", OnClick_AutoReload)
    --AddonSelector.autoReloadBtn:SetHandler("OnMouseEnter", OnMouseEnter)
    --AddonSelector.autoReloadBtn:SetHandler("OnMouseExit", OnMouseExit)
    --AddonSelector.autoReloadLabel:SetHandler("OnMouseUp", OnClick_AutoReloadLabel)
    --AddonSelector.autoReloadLabel:SetHandler("OnMouseEnter", OnMouseEnter)
    --AddonSelector.autoReloadLabel:SetHandler("OnMouseExit", OnMouseExit)
    AS.settingsOpenDropdown:SetHandler("OnMouseEnter", OnMouseEnter)
    AS.settingsOpenDropdown:SetHandler("OnMouseExit", OnMouseExit)
    AS.selectedPackNameLabel:SetHandler("OnMouseUp", OnClick_SelectedPackNameLabel)


    SecurePostHook(savedPacksComboBox, "ShowDropdownInternal", function(comboBoxCtrl)
        local currentSelectedEntryText = savedPacksComboBox.currentSelectedItemText
        OnUpdateDoNarrate("OnSavedPackDropdown", 50, function() AddNewChatNarrationText("["..openedStr.."]   -   " .. currentSelectedEntryText, true)  end)
    end)
    --[[
    SecurePostHook(savedPacksComboBox, "HideDropdownInternal", function(comboBoxCtrl)
        local currentSelectedEntryText = savedPacksComboBox.currentSelectedItemText
        OnUpdateDoNarrate("OnSavedPackDropdown", 100, function() AddNewChatNarrationText("["..closedStr.."]   -   " .. currentSelectedEntryText, false)  end)
    end)
    ]]
end


local OrigAddonGetRowSetupFunc = ZO_AddOnManager.GetRowSetupFunction
function ZO_AddOnManager:GetRowSetupFunction()
--d("Manual PreHook ZO_AddOnManager:GetRowSetupFunction")
	local func = OrigAddonGetRowSetupFunc(self)

    return function(control, data)
        control:SetMouseEnabled(areAllAddonsEnabled(true))
        control:SetHandler("OnMouseUp", function(ctrl) Addon_Toggle_Enabled(ctrl, nil) end)

        --Accessibility
        if control:GetHandler("OnMouseEnter") ~= nil then
            ZO_PostHookHandler(control, "OnMouseEnter", function(ctrl) OnAddonRowMouseEnterStartNarrate(ctrl) end)
        else
            control:SetHandler("OnMouseEnter", function(ctrl) OnAddonRowMouseEnterStartNarrate(ctrl) end,   "AddonSelectorAddonRowOnMouseEnter")
        end
        --[[
                if control:GetHandler("OnMouseExit") ~= nil then
                    ZO_PostHookHandler(control, "OnMouseExit", function(ctrl) OnAddonRowMouseExitStopNarrate(ctrl) end)
                else
                    control:SetHandler("OnMouseExit", function(ctrl) OnAddonRowMouseExitStopNarrate(ctrl) end,      "AddonSelectorAddonRowOnMouseExit")
                end
        ]]

        local retVar
        local expandButton = control:GetNamedChild("ExpandButton")
        if expandButton == nil then
            local addonName, _ = getAddonNameAndData(control)
            d(string.format("[AddonSelector]ExpandButton missing: addon: %q, row: %s", tos(addonName), tos(control:GetName())))

            --Do not call the original setupFunction now as expandButton is missing and would lead to a nil error!
            -->zo_addonmanager.lua, row 174: expandButton:SetHidden(not data.expandable)
            --e.g. after selection of an addon, then ALT+TAB to desktop and see another monitor, then switch back to the addon manager of ESO
            --and move the mouse above an addon > Error message (maybe only if VotansAddonList is enabled too!).
        elseif data == nil then
            local addonName, _ = getAddonNameAndData(control)
            d(string.format("[AddonSelector]Data missing: addon: %q, row: %s", tos(addonName), tos(control:GetName())))
        else
            --Call original setupFunction: ZO_AddOnManager.GetRowSetupFunction
            retVar = func(control, data)
        end
        AddonSelector_HookSingleControlForMultiSelectByShiftKey(control)

        return retVar
    end
end

--Start an addon search: Set mouse cursor to search box so you can start to type directly
local onMouseUpHandlerOfSearchBox
function AddonSelector_StartAddonSearch()
    AS.selectedAddonSearchResult = nil
    if AS.searchBox == nil then return end
    local searchBox = AS.searchBox
    searchBox:Clear()
    onMouseUpHandlerOfSearchBox = onMouseUpHandlerOfSearchBox or searchBox:GetHandler("OnMouseUp")
    if onMouseUpHandlerOfSearchBox == nil then return end
    onMouseUpHandlerOfSearchBox(searchBox, MOUSE_BUTTON_INDEX_LEFT, true)
    searchBox:TakeFocus()
end



--Toggle the addon state of the currently searched, and thus selected, addon, or if no addonw as searched: The addon row
--below the mouse cursor
function AddonSelector_ToggleCurrentAddonState()
    if not areAllAddonsEnabled(true) then return end

    local rowCtrl = WINDOW_MANAGER:GetMouseOverControl()

    --Is an addon search active and was a result found
    if AS.selectedAddonSearchResult ~= nil then
        local searchBox = AS.searchBox
        if searchBox ~= nil and searchBox:GetText() ~= "" then
            --1 addon row was selected with the surrounding [>  <] tags. Toggle this addon's state!
            rowCtrl = AS.selectedAddonSearchResult.control
            if rowCtrl == nil or AS.selectedAddonSearchResult.sortIndex == nil then
                AS.selectedAddonSearchResult = nil
                return
            end
        else
            AS.selectedAddonSearchResult = nil
            wasSearchNextDoneByReturnKey = false
        end
    end

    zo_callLater(function()
--d("[AddonSelector_ToggleCurrentAddonState]")
--d("rowCtrl: " .. tos(rowCtrl:GetName()))
        if rowCtrl ~= nil and rowCtrl:IsMouseEnabled() then
            --Check if rowControl is an addon row and get it's data,
            --as getting it later would result in wrong data because of the scroll list's re-used row control pool!
            local isAddonRowControl, addonData = isAddonRow(rowCtrl)
            if not isAddonRowControl or addonData == nil then
                return
            else
                if AS.selectedAddonSearchResult ~= nil then
                    --Did the rows scroll and the sortIndex at the pool's rowControl changed
                    local sortIndexSearchSaved = AS.selectedAddonSearchResult.sortIndex
                    if sortIndexSearchSaved ~= addonData.sortIndex then
--d(">sortIndex changed, expected:  " ..tos(sortIndexSearchSaved) .. "/ got: " ..tos(addonData.sortIndex))
                        local rowControlOfSortIndex = (ZOAddOnsList.data[sortIndexSearchSaved] ~= nil and ZOAddOnsList.data[sortIndexSearchSaved].control) or nil
                        if rowControlOfSortIndex ~= nil then
--d(">>found new rowControl: " .. tos(rowControlOfSortIndex:GetName()))
                            AS.selectedAddonSearchResult.control = rowControlOfSortIndex
                            rowCtrl                              = rowControlOfSortIndex

                            isAddonRowControl, addonData = isAddonRow(rowCtrl)
                            if not isAddonRowControl or addonData == nil then
                                return
                            end
                        else
                            AS.selectedAddonSearchResult = nil
                            return
                        end
                    end
                end
            end

            local enabledBtn = rowCtrl:GetNamedChild("Enabled")
            if enabledBtn == nil then
                rowCtrl = rowCtrl:GetParent()
                enabledBtn = rowCtrl:GetNamedChild("Enabled")
                if enabledBtn == nil then return end
            end
            Addon_Toggle_Enabled(rowCtrl, addonData)
        end
    end, 0) --call 1 frame later to assure moc() got the correct ctrl of the scrollable, resused list row pool!
end

--[[
local function PackScrollableComboBox_Entry_OnMouseEnter(entry, entry2)
d("[ADDON SELECTOR] Entry of scrollable combobox OnMouseEnter")
AddonSelector._ddl = ddl
AddonSelector._OnMouseEnter_entry = entry
AddonSelector._OnMouseEnter_entry2 = entry2
    if entry.m_owner ~= ddl then return end
end
]]

--====================================--
--====  SavedVariables ====--
--====================================--
function AS.LoadSaveVariables()
    local svName            = "AddonSelectorSavedVars"
    local SAVED_VAR_VERSION = 1
    local defaultSavedVars  = {
        svMigrationToServerDone = false,
        -----------------------------------------------------
        addonPacks = {},
        addonPacksOfChar = {},
        autoReloadUI = false,
        selectAllSave = {},
        selectedPackNameForCharacters = {},
        showGlobalPacks = true,
        showSubMenuAtGlobalPacks = true,
        saveGroupedByCharacterName = false,
        showGroupedByCharacterName = false,
        searchExcludeFilename = false,
        searchSaveHistory = false,
        searchHistory = {},
        searchHistoryMaxEntries = 10,
        lastMassMarkingSavedProfile = nil,      --backup pack of enabled addons before mass-marking
        lastMassMarkingSavedProfileTime = nil,  --timeStamp of last saved backup before mass-marking
        lastLoadedPackNameForCharacters = {}, --charName, packName, and timestamp as the pack was loaded with a ReloadUI
        packChangedBeforeReloadUI = false,
        addPackTooltip = false,
        showPacksAddonList = false,
        showSearchFilterAtPacksList = true,
        showPacksOfOtherAccountsChars = true,
        packKeybinds = {
            [1] = {},
            [2] = {},
            [3] = {},
            [4] = {},
            [5] = {},
        },
    }
    local defaultSavedVarsChar = {
        loadAddonPackOnLogout = nil, --table with packName and charName
        skipLoadAddonPackOnLogout = false,
    }

    local worldName = GetWorldName()
    --Get the saved addon packages without a server reference
    local oldSVWithoutServer = ZO_SavedVars:NewAccountWide(svName, SAVED_VAR_VERSION, nil, defaultSavedVars)

    --Show packs of all accounts at the same time
    --ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
    AS.acwsv                = ZO_SavedVars:NewAccountWide(svName, SAVED_VAR_VERSION, nil, defaultSavedVars, worldName, "AllAccounts")
    AS.acwsvChar            = ZO_SavedVars:NewCharacterIdSettings(svName, SAVED_VAR_VERSION, nil, defaultSavedVarsChar, worldName, nil)

    --Reset "Skip load addon pack on logout"
    AS.acwsvChar.skipLoadAddonPackOnLogout = false


    --Old non-server dependent SV exist and new SV too and were not migrated yet
    if oldSVWithoutServer ~= nil and not AS.acwsv.svMigrationToServerDone then
        --Copy all addon packages from the old SV to the new server dependent ones, but do not overwrite any existing ones
        local addonPacksOfNonServerDependentSV = oldSVWithoutServer.addonPacks
        for packName, addonTable in pairs(addonPacksOfNonServerDependentSV) do
            if AS.acwsv.addonPacks and not AS.acwsv.addonPacks[packName] then
                AS.acwsv.addonPacks[packName] = addonTable
            end
        end
        --Copy all select all save infos
        local selectAllSavedOfNonServerDependentSV = oldSVWithoutServer.selectAllSave
        for idx, data in pairs(selectAllSavedOfNonServerDependentSV) do
            if AS.acwsv.selectAllSave and not AS.acwsv.selectAllSave[idx] then
                AS.acwsv.selectAllSave[idx] = data
            end
        end
        --Copy all selected packnames of the characters
        local selectedPackNameForCharactersOfNonServerDependentSV = oldSVWithoutServer.selectedPackNameForCharacters
        for idx, data in pairs(selectedPackNameForCharactersOfNonServerDependentSV) do
            if AS.acwsv.selectedPackNameForCharacters and not AS.acwsv.selectedPackNameForCharacters[idx] then
                AS.acwsv.selectedPackNameForCharacters[idx] = data
            end
        end
        --Copy the other settings
        AS.acwsv.autoReloadUI            = oldSVWithoutServer.autoReloadUI

        --SV copy old non-server to server dependent finished for this server. Set the flag to true
        AS.acwsv.svMigrationToServerDone = true
    end

    if AS.acwsv.autoReloadUI == BSTATE_PRESSED then
        AS.acwsv.autoReloadUI = true
    elseif AS.acwsv.autoReloadUI == BSTATE_NORMAL then
        AS.acwsv.autoReloadUI = false
    end

    --Packname saved was an old value without charName info? Migrate it
    for charId, packNameDataOfCharId in pairs(AS.acwsv.selectedPackNameForCharacters) do
        if type(packNameDataOfCharId) ~= "table" then
            local oldData                                  = packNameDataOfCharId
            --Create the table, overwriting it with the old data's packname and the charName = "global" constant
            AS.acwsv.selectedPackNameForCharacters[charId] = {
                packName = oldData,
                charName = GLOBAL_PACK_NAME,
            }
        end
    end
end


--====================================--
--====  Logout / Quit ====--
--====================================--
local function myLogoutCallback()
    local charSettings = AS.acwsvChar
    if charSettings == nil then return end
    local addonPackToLoad = charSettings.loadAddonPackOnLogout
    if addonPackToLoad == nil then return end
    --Skip tthe current logout/quit addon pack loading?
    if charSettings.skipLoadAddonPackOnLogout == true then return end

    loadAddonPackNow(addonPackToLoad.packName, addonPackToLoad.charName, true, true)

    --return true --todo: Comment again after debugging! For debugging abort logout and quit!
end

--====================================--
--====  Keybindings ====--
--====================================--
function AS.LoadKeybinds()
    --AddonSelector UI Keybinds
    ZO_CreateStringId("SI_KEYBINDINGS_CATEGORY_ADDON_SELECTOR", ADDON_NAME)
    ZO_CreateStringId("SI_BINDING_NAME_ADDONS_RELOADUI",        reloadUIStr)
    ZO_CreateStringId("SI_BINDING_NAME_SHOWACTIVEPACK",         AddonSelector_GetLocalizedText("ShowActivePack"))

    --Pack load keybinds
    if AS.acwsv == nil or AS.acwsv.packKeybinds == nil then return end
    local packKeybinds = AS.acwsv.packKeybinds
    local numKeybinds = #packKeybinds
    if numKeybinds <= 0 then return end

    for i=1, MAX_ADDON_LOAD_PACK_KEYBINDS, 1 do
        ZO_CreateStringId("SI_BINDING_NAME_ADDONS_LOAD_PACK" .. tos(i), AddonSelector_GetLocalizedText("LoadPackByKeybind" .. tos(i)))
    end
end

--Update the keybind descriptor for the 2nd keybind ("Clear unused") to use the 4th keybind instead, as AddonSelector also uses 2nd (and recently also 3rd -> Enable/Disable addon below mouse cursor)
--keybinds since years!
local function moveAddonManager2ndKeybindDescriptorTo4th()
    --[[
    local secondaryKeybindDescriptor =
    {
        keybind = "ADDONS_PANEL_SECONDARY",
        name =  GetString(SI_CLEAR_UNUSED_KEYBINDS_KEYBIND),
        callback = function()
            ZO_Dialogs_ShowDialog("CONFIRM_CLEAR_UNUSED_KEYBINDS")
        end,
    }
    ]]
    ADDON_MANAGER_OBJECT = ADDON_MANAGER_OBJECT or ADD_ON_MANAGER
    if ADDON_MANAGER_OBJECT.secondaryKeybindDescriptor ~= nil then
        ADDON_MANAGER_OBJECT.secondaryKeybindDescriptor = {
            keybind = "ADDONS_PANEL_QUATERNARY",
            name =  GetString(SI_CLEAR_UNUSED_KEYBINDS_KEYBIND),
            callback = function()
                ZO_Dialogs_ShowDialog("CONFIRM_CLEAR_UNUSED_KEYBINDS")
            end,
        }
        ADDON_MANAGER_OBJECT:RefreshKeybinds()
    end
end

--====================================--
--====  Initialize ====--
--====================================--
local wasLogoutPrehooked = false
function AS.Initialize()
    --Libraries
    AS.LDIALOG = LibDialog
    AS.LCM     = LibCustomMenu
    AS.LSM     = LibScrollableMenu

    --Load the SavedVariables and do "after SV loaded checks"
    AS.LoadSaveVariables()

    AS.LoadKeybinds()

    --Create the controls, and update them
    AS.CreateControlReferences()
    updateDDL() --Add the entries to the packs dropdown list / combobox -> Uses LibScrollableMenu now
    AS.ChangeLayout() --Change the layout of the Addon's list and controls so that AddonSelector got space to be inserted

    --Get the addon manager and object
    ADDON_MANAGER           = ADDON_MANAGER or GetAddOnManager()
    ADDON_MANAGER_OBJECT    = ADDON_MANAGER_OBJECT or ADD_ON_MANAGER
    AS.ADDON_MANAGER_OBJECT = ADDON_MANAGER_OBJECT

    -- Very hacky, but easiest method: Wipe out the game's TYPE_ID = 1 dataType and recreate it using my own template.
    -- Done to make the row controls mouseEnabled
    --[[ Disabled on advice by Votan, 31.08.2018, Exchanged with code lines below
    ADDON_MANAGER_OBJECT.list.dataTypes = {}
    ZO_ScrollList_AddDataType(ADDON_MANAGER_OBJECT.list, 1, "ZO_AddOnRow", 30, ADDON_MANAGER_OBJECT:GetRowSetupFunction())
    ]]
    if ADDON_MANAGER_OBJECT.list.dataTypes[1] then
        ADDON_MANAGER_OBJECT.list.dataTypes[1].setupCallback = ADDON_MANAGER_OBJECT:GetRowSetupFunction()
    else
        ZO_ScrollList_AddDataType(ADDON_MANAGER_OBJECT.list, 1, "ZO_AddOnRow", 30, ADDON_MANAGER_OBJECT:GetRowSetupFunction())
    end

    --Change the description texts now
    AddonSelectorNameLabel:SetText(packNameStr)
    AddonSelectorSave:SetText(AddonSelector_GetLocalizedText("saveButton"))
    AddonSelectorSelectLabel:SetText((selectPackStr) .. ":")
    AddonSelectorDelete:SetText(AddonSelector_GetLocalizedText("deleteButton"))

    --PreHook the ChangeEnabledState function for the addon entries, in order to update the enabled addons number
    ZO_PreHook(ADDON_MANAGER_OBJECT, "ChangeEnabledState", function(ctrl, index, checkState)
        if not AS.noAddonNumUpdate then
            AddonSelectorUpdateCount(50)
        end
    end)
    if ADDON_MANAGER ~= nil then
        --PreHook the SetAddOnEnabled function for the addon entries, in order to update the enabled addons number
        ZO_PreHook(ADDON_MANAGER, "SetAddOnEnabled", function(ctrl)
            --d("[AddonSelector]PreHook SetAddOnEnabled")
            if not AS.noAddonNumUpdate then
                updateAddonsEnabledCountThrottled(50)
                --AddonSelectorUpdateCount(50)
                --Rebuild the Dropdown's entry data so the enabled addon state is reflected correctly
                -->After loading a pack this will lead to deselected packname from dropdoen box! So we need to skip this here if a pack was "loaded"
                if not skipUpdateDDL then
                    updateDDLThrottled(250)
                end
            end
            --if AddonSelector.noAddonCheckBoxUpdate then return true end
        end)
        --EM:RegisterForEvent("AddonSelectorMultiselectHookOnShow", EVENT_ACTION_LAYER_PUSHED, function(...) AddonSelector_HookForMultiSelectByShiftKey(...) end)

        --Make the AddOns list movable
        if ZOAddOns ~= nil then
            ZOAddOns:SetMouseEnabled(true)
            ZOAddOns:SetMovable(true)
        end
    end

    local function AddonSelectorOnShow_HideStuff()
        local addonManagerControl = ADDON_MANAGER_OBJECT.control

        --ZOs addon manager controls
        local primaryButton = addonManagerControl:GetNamedChild("PrimaryButton") --Reload UI
        local secondaryButton = addonManagerControl:GetNamedChild("SecondaryButton") --Clear unused
        local currentBindingsSaved = addonManagerControl:GetNamedChild("CurrentBindingsSaved") --Currently saved 83/100
        local advancedUIErrors = addonManagerControl:GetNamedChild("AdvancedUIErrors")
        local advancedUIErrorsLabel = advancedUIErrors.label

        --AddonSelector custom added controls
        local selectAllButton = AddonSelectorSelectAddonsButton --Select all --AddonSelectorSelectAddonsButton
        local deSelectAllButton = AddonSelectorDeselectAddonsButton --Select all --AddonSelectorDeselectAddonsButton
        local startAddonSearchButton = AddonSelectorStartAddonSearchButton --Start search --AddonSelectorStartAddonSearchButton
        local toggleStateButton = AddonSelectorToggleAddonStateButton --Toggle state --AddonSelectorToggleAddonStateButton


        --Move the AddonSelector keybind buttons to the left below each other to show the vanilla UI keybindings
        --properly
        selectAllButton:ClearAnchors()
        selectAllButton:SetAnchor(TOPLEFT, deSelectAllButton, BOTTOMLEFT, 0, 0)
        --Toggle Addon On/Off button
        toggleStateButton:ClearAnchors()
        toggleStateButton:SetAnchor(TOPLEFT, deSelectAllButton, TOPRIGHT, 5, 0)

        --Start addon search button
        startAddonSearchButton:SetText(searchMenuStr)
        startAddonSearchButton:ClearAnchors()
        startAddonSearchButton:SetAnchor(TOPLEFT, selectAllButton, TOPRIGHT, 5, 0)

        --Reanchor the custom bindings text (below "deselect all" button)
        currentBindingsSaved:ClearAnchors()
        currentBindingsSaved:SetAnchor(TOPLEFT, selectAllButton, BOTTOMLEFT, 0, 5)

        --Reanchor the "Clear unused" button (right of "custom bindings text")
        secondaryButton:ClearAnchors()
        secondaryButton:SetAnchor(LEFT, currentBindingsSaved, RIGHT, 10, 0)

        --With API101038 - "Advanced error messages" checkbox - reanchor 1 frame later, or it won't move properly
        zo_callLater(function()
            advancedUIErrors:ClearAnchors()
            advancedUIErrors:SetAnchor(TOPLEFT, secondaryButton, TOPRIGHT, 10, 10)
        end, 0)

        if not advancedUIErrors.wasHookedByAddonSelector then
            advancedUIErrors.wasHookedByAddonSelector = true

            onMouseEnterDoNarrate(advancedUIErrorsLabel)
            onMouseEnterDoNarrate(advancedUIErrors)
            ZO_PostHookHandler(advancedUIErrors, "OnMouseUp", function(ctrl, button, upInside)
                if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
                    OnControlClickedNarrate(ctrl, true)
                end
            end)
            ZO_PostHookHandler(advancedUIErrorsLabel, "OnMouseUp", function(ctrl, button, upInside)
                if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
                    OnControlClickedNarrate(ctrl, true)
                end
            end)
        end
    end
    AS.OnShow_HideStuff = AddonSelectorOnShow_HideStuff

    --PreHook the Addonmanagers OnShow function
    ZO_PreHook(ADDON_MANAGER_OBJECT, "OnShow", function(ctrl)
        --d("ADD_ON_MANAGER:OnShow")
        --Hide other controls/keybinds
        AddonSelectorOnShow_HideStuff()

        --Update the count/total number at the addon manager titel
        if not AS.noAddonNumUpdate then
            AddonSelectorUpdateCount(250, true)
        end
        --Clear the search text editbox
        AS.searchBox:SetText("")
        --Reset the searched table completely
        AS.alreadyFound = {}
        --Clear the previously searched data and unregister the events
        unregisterOldEventUpdater()

        zo_callLater(function()
            --Reset variables
            AS.firstControl     = nil
            AS.firstControlData = nil
            --Build the lookup table for the sortIndex to row index of addon rows
            BuildAddOnReverseLookUpTable()
            --Hook the visible addon rows (controls) to set a hanlder for OnMouseDown
            --AddonSelector_HookForMultiSelectByShiftKey()

            --Refresh the dropdown contents once so the libraries and addons are split up into proper tables
            updateDDL()

            --PostHook the new Enable All addons checkbox function so that the controls of Circonians Addon Selector get disabled/enabled
            updateEnableAllAddonsCtrls()
            if not enableAllAddonsCheckboxHooked and enableAllAddonsCheckboxCtrl ~= nil then
                ZO_PostHookHandler(enableAllAddonsCheckboxCtrl, "OnMouseUp", function(checkboxCtrl, mouseButton, isUpInside)
                    if not isUpInside or mouseButton ~= MOUSE_BUTTON_INDEX_LEFT then return end
                    areAllAddonsEnabled(false)
                end)
                local disableAllAddonsToggleFunc = enableAllAddonsCheckboxCtrl.toggleFunction
                enableAllAddonTextCtrl:SetMouseEnabled(true)
                enableAllAddonTextCtrl:SetHandler("OnMouseUp", function(textCtrl, mouseButton, isUpInside)
                    if not isUpInside or mouseButton ~= MOUSE_BUTTON_INDEX_LEFT then return end
                    local currentState = enableAllAddonsCheckboxCtrl:GetState()
                    local isBoxChecked = true
                    if currentState == BSTATE_PRESSED then
                        isBoxChecked = false
                    end
                    disableAllAddonsToggleFunc(enableAllAddonsCheckboxCtrl, isBoxChecked)
                end)

                enableAllAddonsCheckboxHooked = true
            end

            --Add narration to all controls
            enableZO_AddOnsUI_controlNarration()

        end, 500) -- Attention: Delay needs to be 500 as AddonSelector_HookForMultiSelectByShiftKey was enabled!!!
    end)

    --PreHook the Addonmanagers OnEffectivelyHidden function
    if ADDON_MANAGER_OBJECT.control:GetHandler("OnHide") == nil then
        ADDON_MANAGER_OBJECT.control:SetHandler("OnHide", function(ctrl)
            AddNewChatNarrationText("[" ..GetString(SI_WINDOW_TITLE_ADDON_MANAGER) .. "] " .. closedStr, true)
        end)
    else
        ZO_PostHookHandler(ADDON_MANAGER_OBJECT.control, "OnHide", function(ctrl)
            AddNewChatNarrationText("[" ..GetString(SI_WINDOW_TITLE_ADDON_MANAGER) .. "] " .. closedStr, true)
        end)
    end

    --[[
    ZO_PreHook("ZO_ScrollList_ScrollRelative", function(self, delta, onScrollCompleteCallback, animateInstantly)
        if self == ZOAddOnsList then
            AddonSelector_HookForMultiSelectByShiftKey()
        end
    end)
    ZO_PreHook("ZO_ScrollList_MoveWindow", function(self, value)
        if self == ZOAddOnsList then
            AddonSelector_HookForMultiSelectByShiftKey()
        end
    end)
    ZO_PreHook("ZO_ScrollList_ScrollAbsolute", function(self, value)
        d("ZO_ScrollList_ScrollAbsolute")
        if self == ZOAddOnsList then
            --AddonSelector_HookForMultiSelectByShiftKey()
        end
    end)
    ]]
    moveAddonManager2ndKeybindDescriptorTo4th()

    --Get the currently loaded packname of the char, if it was changed before reloadUI
    if AS.acwsv.packChangedBeforeReloadUI == true then
        local currentPackOfchar = GetCurrentCharacterSelectedPackname()
        if currentPackOfchar ~= nil then
            --Set the last loaded pack data
            AS.acwsv.lastLoadedPackNameForCharacters[currentCharId] = currentPackOfchar
        end
    end
    AS.acwsv.packChangedBeforeReloadUI = false


    --Prehook the logout and quit functions to check if any addon pack should be loaded now
    if not wasLogoutPrehooked then
        ZO_PreHook("Logout", myLogoutCallback)
        ZO_PreHook("Quit", myLogoutCallback)
        wasLogoutPrehooked = true
    end
end

--Reload the user interface
function AddonSelector_ReloadTheUI()
    ReloadUI("ingame")
end


local function searchAddOnSlashCommandHandlder(args)
    if not args or args == "" then
        showAddOnsList()
    else
        --Parse the arguments string
        local options = {}
        --local searchResult = {} --old: searchResult = { string.match(args, "^(%S*)%s*(.-)$") }
        for param in strgma(args, "([^%s]+)%s*") do
            if (param ~= nil and param ~= "") then
                options[#options+1] = strlow(param)
            end
        end
        if options and options[1] then
            openGameMenuAndAddOnsAndThenSearch(tos(options[1]))
        end
    end
    addonListWasOpenedByAddonSelector = false
end

local function loadAddOnPackSlashCommandHandler(args, noReloadUI)
    openGameMenuAndAddOnsAndThenLoadPack(args, nil, noReloadUI, nil)
end

local function skipLoadAddonPackOnLogoutToggle(args)
    if args == nil or args == "" then
        AS.acwsvChar.skipLoadAddonPackOnLogout = not AS.acwsvChar.skipLoadAddonPackOnLogout
        updateDDL()
    else
        if args == "0" or args == "false" or args == "off" then
            AS.acwsvChar.skipLoadAddonPackOnLogout = false
            updateDDL()
        elseif args == "1" or args == "true" or args == "on" then
            AS.acwsvChar.skipLoadAddonPackOnLogout = true
            updateDDL()
        end
    end
    local currentValue = AS.acwsvChar.skipLoadAddonPackOnLogout
    d(strfor(addonNamePrefix .. skipLoadAddonPackStr, tos(booleanToOnOff[currentValue])))
end

local function ShowLAMAddonSettings()
    LibAddonMenu2:OpenToPanel(nil)
end

-------------------------------------------------------------------
--  Global functions  --
-------------------------------------------------------------------
function AddonSelector_LoadPackByKeybind(keybindNr)
    if keybindNr == nil or keybindNr < 1 or keybindNr > MAX_ADDON_LOAD_PACK_KEYBINDS then return end
    local packKeybinds = AS.acwsv.packKeybinds
    local packDataToLoad = packKeybinds[keybindNr]
    if packDataToLoad == nil then return end
    loadAddonPackNow(packDataToLoad.packName, packDataToLoad.charName, nil, nil)
end

--Show the current user's active pack in the chat
function AddonSelector_ShowActivePackInChat()
    local currentCharacterId, currentlySelectedPackNameData = getCurrentCharsPackNameData()
--d(">currentCharacterId: " ..tos(currentCharacterId) .. ", currentlySelectedPackNameData.packName: " ..tos(currentlySelectedPackNameData.packName))
    if not currentCharacterId or not currentlySelectedPackNameData then return end
    local currentlySelectedPackName = currentlySelectedPackNameData.packName
    local charNameOfSelectedPack = currentlySelectedPackNameData.charName
--d(">charNameOfSelectedPack: " ..tos(charNameOfSelectedPack))
    if not currentlySelectedPackName or currentlySelectedPackName == "" then return end
    local currentPackInfoText = (packNameStr) .. " " ..tos(currentlySelectedPackName)
    if charNameOfSelectedPack == nil or charNameOfSelectedPack == "" or charNameOfSelectedPack == GLOBAL_PACK_NAME then
        charNameOfSelectedPack = ", " .. packNameGlobal
    else
        charNameOfSelectedPack = ", " .. packCharNameStr .. ": " ..tos(charNameOfSelectedPack)
    end
    d(addonNamePrefix .. currentPackInfoText .. charNameOfSelectedPack)
end

-------------------------------------------------------------------
--  OnAddOnLoaded  --
-------------------------------------------------------------------
local function OnAddOnLoaded(event, addonName)
    if addonName ~= ADDON_NAME then return end
    ADDON_MANAGER = ADDON_MANAGER or GetAddOnManager()
    ADDON_MANAGER_OBJECT     = ADDON_MANAGER_OBJECT or ADD_ON_MANAGER
    AS.ADDON_MANAGER_OBJECT  = ADDON_MANAGER_OBJECT

    --Save the currently logged in @account's characterId = characterName table
    AS.charactersOfAccount   = getCharactersOfAccount(false)
    charactersOfAccount      = AS.charactersOfAccount
    AS.characterIdsOfAccount = getCharactersOfAccount(true)
    characterIdsOfAccount    = AS.characterIdsOfAccount


    --AddonCategory is enabled?
    isAddonCategoryEnabled = (AddonCategory ~= nil and AddonCategory.getIndexOfCategory ~= nil and true) or false
    if isAddonCategoryEnabled == true then
        addonCategoryCategories, addonCategoryIndices = getAddonCategoryCategories()
    end

---------------------------------------------------------------------
    --Load SavedVariables, create and update controls etc.
    AS.Initialize()
---------------------------------------------------------------------

    addonSelectorSelectAddonsButtonNameLabel = AddonSelectorSelectAddonsButton.nameLabel --GetControl(AddonSelectorSelectAddonsButton, "NameLabel")

    --Slash commands
    SLASH_COMMANDS["/rl"]               = AddonSelector_ReloadTheUI
    SLASH_COMMANDS["/rlui"]             = AddonSelector_ReloadTheUI
    SLASH_COMMANDS["/reload"]           = AddonSelector_ReloadTheUI
    if SLASH_COMMANDS["/addons"] == nil then
        SLASH_COMMANDS["/addons"]       = searchAddOnSlashCommandHandlder
    end
    if SLASH_COMMANDS["/as"] == nil then
        SLASH_COMMANDS["/as"]           = searchAddOnSlashCommandHandlder
    end
    SLASH_COMMANDS["/addonsearch"]      = searchAddOnSlashCommandHandlder
    SLASH_COMMANDS["/addonselector"]    = searchAddOnSlashCommandHandlder
    if SLASH_COMMANDS["/asl"] == nil then
        SLASH_COMMANDS["/asl"]          = function(args) loadAddOnPackSlashCommandHandler(args, true) end
    end
    SLASH_COMMANDS["/addonload"]        = function(args) loadAddOnPackSlashCommandHandler(args, true) end
    SLASH_COMMANDS["/loadpack"]         = function(args) loadAddOnPackSlashCommandHandler(args, true) end
    if SLASH_COMMANDS["/aslrl"] == nil then
        SLASH_COMMANDS["/aslrl"]          = function(args) loadAddOnPackSlashCommandHandler(args, false) end
    end
    SLASH_COMMANDS["/addonloadrl"]        = function(args) loadAddOnPackSlashCommandHandler(args, false) end
    SLASH_COMMANDS["/loadpackrl"]         = function(args) loadAddOnPackSlashCommandHandler(args, false) end
    if SLASH_COMMANDS["/aslskip"] == nil then
        SLASH_COMMANDS["/aslskip"]      = skipLoadAddonPackOnLogoutToggle
    end
    if SLASH_COMMANDS["/asls"] == nil then
        SLASH_COMMANDS["/asls"]         = skipLoadAddonPackOnLogoutToggle
    end
    SLASH_COMMANDS["/loadpackskip"]     = skipLoadAddonPackOnLogoutToggle


    SLASH_COMMANDS["/asap"]             = AddonSelector_ShowActivePackInChat
    if LibAddonMenu2 ~= nil then
        SLASH_COMMANDS["/addonsettings"] =  ShowLAMAddonSettings
        SLASH_COMMANDS["/lam"] =            ShowLAMAddonSettings
    end

    --Hook the scrollable combobox OnMouseEnter function to show the menu entry to select/delete the pack of the row
    --SecurePostHook("ZO_ScrollableComboBox_Entry_OnMouseEnter", PackScrollableComboBox_Entry_OnMouseEnter)
    AS.LCM = AS.LCM or LibCustomMenu
    AS.LSM = AS.LSM or LibScrollableMenu
    checkIfGlobalPacksShouldBeShown()

    --Narrate ZO_Menu.items + submenus of LibCustomMenu
    --Trying via LibCustomMenu.submenu:SetSelectedIndex(control.index) hook as this will be called OnMouseEnter
    local function getNarratableZO_MenuItemText(itemCtrl, isSubMenuEntry)
        isSubMenuEntry = isSubMenuEntry or false
        local textToNarrate
        local isCheckbox = false
        local isSubmenu = false

        local prefixStr = getOwnerPrefixStr(GetMenuOwner())

        --d("[AddonSelector]ZO_Menu_EnterItem - itemCtrl: " .. tos(itemCtrl))
        local currentMenuItemText = (isSubMenuEntry == false and ZO_Menu_GetSelectedText()) or (itemCtrl.nameLabel ~= nil and itemCtrl.nameLabel:GetText())
        if currentMenuItemText ~= nil then
            --Find out if a submenu exists or if the entry in the ZO_Menu is a checkbox or normal text
            --It got a submenu? Check that first as the .checkbox will be "reused" for a submenu! But the control name won't be "Arror" at the suffix then
            if GetControl(itemCtrl, "Arrow") ~= nil then
                textToNarrate = "[" .. submenuStr .. "]   " .. strfor(prefixStr, currentMenuItemText)
                isSubmenu = true
                --Checkbox?
            else
                --Checkbox is not a control of the item at the CustomMenu (only at submenus...)
                --How to determine the checkbox? Via the name of the label: " |u16:0::|uTooltip zu Pack in Auswahlbox hinzufügen"
                if (itemCtrl.checkbox ~= nil and itemCtrl.checkbox.GetState ~= nil and itemCtrl.checkbox:IsHidden() == false) or zo_plainstrfind(currentMenuItemText, "|u") == true then
                    isCheckbox = true
                else
                    --Normal
                    textToNarrate = strfor(prefixStr, currentMenuItemText)
                end
            end
            if isCheckbox == true and isSubmenu == false then
                --Get the checkbox via .checkBox or via the anchorTo
                local checkBoxCtrl, currentCbState
                if itemCtrl.checkbox ~= nil then
                    checkBoxCtrl = itemCtrl.checkbox
                else
                    checkBoxCtrl = select(3, itemCtrl:GetAnchor()) --Get the relativeTo anchor control
                end
                if checkBoxCtrl ~= nil and checkBoxCtrl.GetState ~= nil then
                    currentCbState = ZO_CheckButton_IsChecked(checkBoxCtrl)
                end
                textToNarrate = "[" .. checkboxStr .."]   " .. strfor(prefixStr, currentMenuItemText .. " ["..currentlyStr.."]: " ..tos(booleanToOnOff[currentCbState]))
            end
        end
        return textToNarrate, isCheckbox, isSubmenu
    end


    --Normal entries -> Settings menu
    SecurePostHook("ZO_Menu_EnterItem", function(itemCtrl)
        if checkIfMenuOwnerIsZOAddOns() == false or IsAccessibilityUIReaderEnabled() == false then return end
        --d("[AddonSelector]ZO_Menu_EnterItem")
        local textToNarrate = getNarratableZO_MenuItemText(itemCtrl, false)
        OnUpdateDoNarrate("OnAddonSelectorSettingsZOMenuItemEnter", 25, function() AddNewChatNarrationText(textToNarrate, true)  end)
    end)
    --Submenu entries -> Settings menu
    SecurePostHook(AS.LCM.submenu, "SetSelectedIndex", function(submenuTab, index)
        if submenuTab == nil or index == nil or checkIfMenuOwnerIsZOAddOns() == false or IsAccessibilityUIReaderEnabled() == false then return end
        --d("[AddonSelector]LCM.submenu.SetSelectedIndex - index: " .. tos(index))
        local textToNarrate = getNarratableZO_MenuItemText(submenuTab.items[index], true)
        OnUpdateDoNarrate("OnAddonSelectorSettingsZOMenuItemEnter", 25, function() AddNewChatNarrationText(textToNarrate, true)  end)
    end)
    --Narrate a checkbox againa fter it was clicked
    SecurePostHook("ZO_Menu_ClickItem", function(itemCtrl, button)
        if checkIfMenuOwnerIsZOAddOns() == false or IsAccessibilityUIReaderEnabled() == false then return end
        --d("[AddonSelector]ZO_Menu_ClickItem")
        if button ~= MOUSE_BUTTON_INDEX_LEFT then return end
        local textToNarrate, isCheckbox = getNarratableZO_MenuItemText(itemCtrl, false)
        if textToNarrate ~= nil and isCheckbox == true then
            OnUpdateDoNarrate("OnAddonSelectorSettingsZOMenuItemEnter", 25, function() AddNewChatNarrationText(textToNarrate, true)  end)
        end
    end)


    --[[
    --For debugging to see if fragment remove and add to SCENE_MANAGER will call this
    ADDONS_FRAGMENT:RegisterCallback("StateChange",   function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
--d("[AddonSelector]Addons Fragment - Showing")
            --PushActionLayerByName("Addons")
        elseif newState == SCENE_FRAGMENT_HIDING then
--d("[AddonSelector]Addons Fragment - Hiding")
            --RemoveActionLayerByName("Addons")
        end
    end)
    ]]

--[[
    ZO_PreHook(AddonSelector.comboBox, "ItemSelectedClickHelper", function()
d("[AS]comboBox:ItemSelectedClickHelper")
    end)
    function ZO_ComboBoxDropdown_Keyboard:Refresh(item)
d("[AS]ZO_ComboBoxDropdown_Keyboard:Refresh - item: " ..tos(item))
    local entryData = nil
    if item then
--AddonSelector._debugItems = AddonSelector._debugItems or {}
        local timeStamp = GetGameTimeMilliseconds()
--AddonSelector._debugItems[timeStamp] = item
--AddonSelector._debugDataSource = {}
        local dataList = ZO_ScrollList_GetDataList(self.scrollControl)
--AddonSelector._scrollDataList = ZO_ShallowTableCopy(dataList)
        for i, data in ipairs(dataList) do
--AddonSelector._debugDataSource[i] = data:GetDataSource()
            if data:GetDataSource() == item then
                entryData = data
d(">["..tos(timeStamp).."]item was found - index: " ..tos(i))
                break
            end
        end
    end

AddonSelector._debugScrollControl = self.scrollControl
    ZO_ScrollList_RefreshVisible(self.scrollControl, entryData)
end
]]

	EM:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
end

---------------------------------------------------------------------
--  Register Events --
---------------------------------------------------------------------
EM:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

