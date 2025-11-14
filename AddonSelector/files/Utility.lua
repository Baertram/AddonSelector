local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name

local constants = AS.constants
local utility = AS.utility

--local SEARCH_TYPE_NAME = constants.SEARCH_TYPE_NAME
local stringConstants = constants.strings
--local prefixStrings = stringConstants.prefixStrings
local ZOsControls = constants.ZOsControls
local LSMconstants = constants.LSM
--local LSM_defaultAddonPackMenuOptions = LSMconstants.defaultAddonPackMenuOptions
local narration = AS.narration
local colors = constants.colors

--local currentCharIdNum = constants.currentCharIdNum
local currentCharId = constants.currentCharId
--local currentCharName = constants.currentCharName
local isExcludedFromChangeEnabledState = constants.isExcludedFromChangeEnabledState

--Other Addons
local otherAddonsData = AS.otherAddonsData

local ASYesNoDialogName = constants.ASYesNoDialogName --"ADDON_SELECTOR_YESNO_DIALOG"


local updaterNames = constants.updaterNames
local ASUpdateDDLThrottleName = updaterNames.ASUpdateDDLThrottleName
local ASUpdateAddonCountThrottleName = updaterNames.ASUpdateAddonCountThrottleName
local searchHistoryEventUpdaterName = updaterNames.searchHistoryEventUpdaterName


local AddonSelector_GetLocalizedText = AddonSelector_GetLocalizedText

local simplyRedColorPattern = colors.simplyRed
local noCategoryStr = AddonSelector_GetLocalizedText("noCategory")


--ZOs reference variables
local tos = tostring
local tins = table.insert
local tsor = table.sort
local strlow = string.lower
local strfor = string.format

local EM = EVENT_MANAGER


--======================================================================================================================
-- Utility/helper functions
--======================================================================================================================
local ADDON_MANAGER, ADDON_MANAGER_OBJECT
local updateDDL, addonSelectorUpdateCount

--The drop down list for the packs -> ZO_ScrollableComboBox
local isAreAddonsEnabledFuncGiven = nil


------------------------------------------------------------------------------------------------------------------------
-- ADD_ON_MANAGER helper functions
------------------------------------------------------------------------------------------------------------------------
function utility.GetAddonManager()
    ADDON_MANAGER = ADDON_MANAGER or GetAddOnManager()
    AS.ADDON_MANAGER = ADDON_MANAGER
    return ADDON_MANAGER
end
local getAddOnManager = utility.GetAddonManager

function utility.GetAddonManagerObject()
    ADDON_MANAGER_OBJECT = ADDON_MANAGER_OBJECT or ADD_ON_MANAGER
    AS.ADDON_MANAGER_OBJECT = ADDON_MANAGER_OBJECT
    return ADDON_MANAGER_OBJECT
end
local getAddOnManagerObject = utility.GetAddonManagerObject


------------------------------------------------------------------------------------------------------------------------
-- Throttled calls (to prevent the same function calls too often, overwrite the last with the current)
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
utility.throttledCall = throttledCall

local function updateDDLThrottled(delay)
    updateDDL = updateDDL or utility.updateDDL
    delay = delay or 250
    throttledCall(updateDDL, delay, ASUpdateDDLThrottleName)
end
utility.updateDDLThrottled = updateDDLThrottled

local function updateAddonsEnabledCountThrottled(delay)
    delay = delay or 50
    throttledCall(addonSelectorUpdateCount, delay, ASUpdateAddonCountThrottleName)
end
utility.updateAddonsEnabledCountThrottled = updateAddonsEnabledCountThrottled


------------------------------------------------------------------------------------------------------------------------
-- Event updater
------------------------------------------------------------------------------------------------------------------------
local eventUpdaterNameTemplate = "AddonSelector_ChangeZO_AddOnsList_Row_Index_%s_%s"
local function unregisterOldEventUpdater(p_sortIndexOfControl, p_addSelection)
    --Disable the check for the control for the last index so it will not be skipped and thus active for ever!
    local activeUpdateControlEvents = AS.controls.controlData.activeUpdateControlEvents
    if activeUpdateControlEvents ~= nil then
        for index, eventData in ipairs(activeUpdateControlEvents) do
            local lastEventUpdateName
            if p_sortIndexOfControl == nil and p_addSelection == nil then
                lastEventUpdateName = strfor(eventUpdaterNameTemplate, tos(eventData.sortIndex), tos(eventData.addSelection))
            else
                if eventData.sortIndex == p_sortIndexOfControl and eventData.addSelection == p_addSelection then
                    lastEventUpdateName = strfor(eventUpdaterNameTemplate, tos(eventData.sortIndex), tos(eventData.addSelection))
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
utility.unregisterOldEventUpdater = unregisterOldEventUpdater

local function eventUpdateFunc(p_sortIndexOfControl, p_addSelection, p_eventUpdateName)
    if p_eventUpdateName == nil then return end
    if p_sortIndexOfControl == nil then return end
    p_addSelection = p_addSelection or false
    --Change the shown row name and put [ ] around the addon name so one sees the currently selected row
    local addonList = ZOsControls.ZOAddOnsList.data
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
                newAddonText = strfor(simplyRedColorPattern, "[>") .. currentAddonText .. strfor(simplyRedColorPattern, "<]")
            else
                local selectedAddonData = addonList[p_sortIndexOfControl].data
                newAddonText = selectedAddonData.addOnName
            end

            if AS.lastData.selectedAddonSearchResult ~= nil then
                AS.lastData.selectedAddonSearchResult.control = nil
                if p_addSelection == true and AS.lastData.selectedAddonSearchResult.sortIndex ~= nil and AS.lastData.selectedAddonSearchResult.sortIndex == p_sortIndexOfControl then
                    AS.lastData.selectedAddonSearchResult.control = selectedAddonControl
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
utility.eventUpdateFunc = eventUpdateFunc


------------------------------------------------------------------------------------------------------------------------
-- ZO_Menu functions
------------------------------------------------------------------------------------------------------------------------
local function checkIfMenuOwnerIsZOAddOns()
    local menuOwner = GetMenuOwner()
    if menuOwner ~= nil and menuOwner.GetOwningWindow ~= nil and menuOwner:GetOwningWindow() == ZOsControls.ZOAddOns then return true end
    return false
end
utility.checkIfMenuOwnerIsZOAddOns = checkIfMenuOwnerIsZOAddOns


------------------------------------------------------------------------------------------------------------------------
-- Table functions
------------------------------------------------------------------------------------------------------------------------
local function sortNonNumberKeyTableAndBuildSortedLookup(tab)
    local addonPackToIndex = {}
    for k, _ in pairs(tab) do
        tins(addonPackToIndex, k)
    end
    tsor(addonPackToIndex)
    return addonPackToIndex
end
utility.sortNonNumberKeyTableAndBuildSortedLookup = sortNonNumberKeyTableAndBuildSortedLookup


------------------------------------------------------------------------------------------------------------------------
-- String functions
------------------------------------------------------------------------------------------------------------------------
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
utility.splitStringAndRespectQuotes = splitStringAndRespectQuotes


------------------------------------------------------------------------------------------------------------------------
-- Character (pack) functions
------------------------------------------------------------------------------------------------------------------------
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
utility.getCharactersOfAccount = getCharactersOfAccount


--Fill the tables
AS.charactersOfAccount, AS.charactersOfAccountLower     = getCharactersOfAccount(false)
AS.characterIdsOfAccount, AS.characterIdsOfAccountLower = getCharactersOfAccount(true)
local characterIdsOfAccount = AS.characterIdsOfAccount
local characterIdsOfAccountLowerCase = AS.characterIdsOfAccountLower

local function getCharacterIdByName(characterName)
    local characterIdOfCharacterName = characterIdsOfAccount[characterName]
    if characterIdOfCharacterName == nil then
        characterIdOfCharacterName = characterIdsOfAccountLowerCase[strlow(characterName)]
    end
    return characterIdOfCharacterName
end
utility.getCharacterIdByName = getCharacterIdByName

local function getCurrentCharsPackNameData()
    --Get the currently selected packname from the SavedVariables
    local packNamesForCharacters = AS.acwsv.selectedPackNameForCharacters
    if not packNamesForCharacters then return nil, nil end
    local currentlySelectedPackData = packNamesForCharacters[currentCharId]
    return currentCharId, currentlySelectedPackData
end
utility.getCurrentCharsPackNameData = getCurrentCharsPackNameData



------------------------------------------------------------------------------------------------------------------------
-- Global Pack functions
------------------------------------------------------------------------------------------------------------------------
local function checkIfGlobalPacksShouldBeShown(comboBox, mocCtrl, item)
    local settings = AS.acwsv
    if not settings then return end
    local showGlobalPacks = settings.showGlobalPacks
    local savePerCharacter = settings.saveGroupedByCharacterName
    --Show the global pack entries if neither global packs nor character packs were selected to save/show!
    if showGlobalPacks == false and savePerCharacter == false then
        AS.acwsv.showGlobalPacks = true
    end
    utility.updateSaveModeTexure(savePerCharacter)
end
utility.checkIfGlobalPacksShouldBeShown = checkIfGlobalPacksShouldBeShown

local function selectPreviouslySelectedPack(beforeSelectedPackData)
    beforeSelectedPackData = beforeSelectedPackData or AS.currentlySelectedPackData
    AS.comboBox:SelectItem(beforeSelectedPackData, true) --ignore the callback for entry selected!
end
utility.selectPreviouslySelectedPack = selectPreviouslySelectedPack


------------------------------------------------------------------------------------------------------------------------
-- Search
------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------
-- Search history
------------------------------------------------------------------------------------------------------------------------
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
utility.updateSearchHistory = updateSearchHistory


local function updateSearchHistoryDelayed(searchType, searchValue)
    EM:UnregisterForUpdate(searchHistoryEventUpdaterName)
    EM:RegisterForUpdate(searchHistoryEventUpdaterName, 1500, function()
        EM:UnregisterForUpdate(searchHistoryEventUpdaterName)
        updateSearchHistory(searchType, searchValue)
    end)
end
utility.updateSearchHistoryDelayed = updateSearchHistoryDelayed

local function clearSearchHistory(searchType)
    local settings = AS.acwsv
    local searchHistory = settings.searchHistory
    if not searchHistory[searchType] then return end
    settings.searchHistory[searchType] = nil
end
utility.clearSearchHistory = clearSearchHistory


------------------------------------------------------------------------------------------------------------------------
-- AddOn (list) helper functions
------------------------------------------------------------------------------------------------------------------------
local function sortAndGroupAddons(addonsTab)
    local librariesLookup = AS.Libraries
    local addons = {}
    local libraries = {}
    for addonFileName, addOnName in pairs(addonsTab) do
        local isLibrary = (librariesLookup[addonFileName] ~= nil and true) or false
        if isLibrary == true then
            tins(libraries, addOnName)
        else
            tins(addons, addOnName)
        end
    end
    tsor(addons)
    tsor(libraries)
    return addons, libraries
end
utility.sortAndGroupAddons = sortAndGroupAddons


local function isAddonPackDropdownOpen()
    return AS.controls.ddl.m_comboBox:IsDropdownVisible()
end
utility.isAddonPackDropdownOpen = isAddonPackDropdownOpen

local function getAddonNameFromData(addonData)
    if addonData == nil then return end
    local addonName = addonData.strippedAddOnName
    addonName = addonName or addonData.addOnName
    return addonName
end
utility.getAddonNameFromData = getAddonNameFromData

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
utility.getAddonNameAndData = getAddonNameAndData

local function isAddonRow(rowControl)
    if rowControl == nil then return false, nil end
    if rowControl:GetOwningWindow() ~= ZOsControls.ZOAddOns then
--d("<isAddonRow: no ZO_AddOns owner!")
        return false, nil
    end

    local addonName, addonData = getAddonNameAndData(rowControl)
    if addonName ~= nil and addonData ~= nil and addonData.addOnName ~= nil then return true, addonData end
    return false, nil
end
utility.isAddonRow = isAddonRow

--Enable/Disable all the controls of this addon "AddonSelector" depending on the enabled checkbox for all addons
local function setThisAddonsControlsEnabledState(enabledState)
    local controls = AS.controls
    local addonSelectorTLC = controls.addonSelectorControl
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
    if enabledState == false then
        controls.editBox:Clear()
    end
    --AddonSelectorddlOpenDropdown:SetMouseEnabled(enabledState)
    controls.ddl.m_comboBox.m_openDropdown:SetMouseEnabled(enabledState)
end
utility.setThisAddonsControlsEnabledState = setThisAddonsControlsEnabledState

local function areAddonsCurrentlyEnabled()
    local addOnManagerObject = getAddOnManagerObject()
    --Function to detect the enabled state exists?
    if (addOnManagerObject ~= nil and addOnManagerObject.AreAddOnsEnabled) then
        return addOnManagerObject:AreAddOnsEnabled()
    end
    --No, check the checkbox state of ZO_AddOnsList2Row1Checkbox
    local enableAllAddonsCheckboxCtrl = ZOsControls.enableAllAddonsCheckboxCtrl
    if enableAllAddonsCheckboxCtrl ~= nil then
--d("[AS]1areAddonsCurrentlyEnabled: " .. tos(ZO_CheckButton_IsChecked(enableAllAddonsCheckboxCtrl)))
        return ZO_CheckButton_IsChecked(enableAllAddonsCheckboxCtrl)
    end
--d("[AS]1areAddonsCurrentlyEnabled - true")
    return true --simulate all are enabled as we cannot detect it properly...
end
utility.areAddonsCurrentlyEnabled = areAddonsCurrentlyEnabled


--Check if the checkbox to disable all addons is enabled or not
local function areAllAddonsEnabled(noControlUpdate)
    noControlUpdate = noControlUpdate or false
    local areAllAddonsCurrentlyEnabled = areAddonsCurrentlyEnabled()
    if not noControlUpdate then
        setThisAddonsControlsEnabledState(areAllAddonsCurrentlyEnabled)
    end
    --d("[CAS]areAllAddonsEnabled: " ..tos(areAllAddonsCurrentlyEnabled) .. ", noControlUpdate: " ..tos(noControlUpdate))
    return areAllAddonsCurrentlyEnabled
end
utility.areAllAddonsEnabled = areAllAddonsEnabled

--Function to build the reverse lookup table for sortIndex to addonIndex
local function BuildAddOnReverseLookUpTable()
    if ZOsControls.ZOAddOnsList ~= nil and ZOsControls.ZOAddOnsList.data ~= nil then
        --Build the lookup table for the sortIndex to nrow index of addon rows
        if ZO_IsTableEmpty(ZOsControls.ZOAddOnsList.data) then return end
    --d(">>>[AS]BuildAddOnReverseLookUpTable - Running")

        AS.ReverseLookup     = {}
        AS.NameLookup        = {}
        AS.FileNameLookup    = {}
        AS.Libraries         = {}
        local reverseLookup  = AS.ReverseLookup
        local nameLookup     = AS.NameLookup
        local fileNameLookup = AS.FileNameLookup
        local libraries      = AS.Libraries

        for _,v in ipairs(ZOsControls.ZOAddOnsList.data) do
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
utility.BuildAddOnReverseLookUpTable = BuildAddOnReverseLookUpTable


--Add the active addon count to the header text
function addonSelectorUpdateCount(delay, doNarrate)
--d("[AddonSelector]AddonSelectorUpdateCount, AS.flags.noAddonNumUpdate: " .. tos(AddonSelector.AS.flags.noAddonNumUpdate))
    if AS.flags.noAddonNumUpdate then return false end
    delay = delay or 100
    doNarrate = doNarrate or false
    zo_callLater(function()
        if not ZOsControls.ZOAddOnsList or not ZOsControls.ZOAddOnsList.data then return false end
        local addonRows = ZOsControls.ZOAddOnsList.data
        if addonRows == nil then return false end
        local countFound = 0
        local countActive = 0
        AS.numbers.numAddonsEnabled     = 0
        AS.numbers.numAddonsTotal       = 0

        getAddOnManager()
        getAddOnManagerObject()
        if ADDON_MANAGER == nil then return false end

        countFound = ADDON_MANAGER:GetNumAddOns()
        for _, addonRow in ipairs(addonRows) do
            local data = addonRow.data
            if data and not data.hasDependencyError and data.addOnEnabled == true then
                countActive = countActive + 1
            end
        end

        AS.numbers.numAddonsEnabled = countActive
        AS.numbers.numAddonsTotal   = countFound
        if doNarrate == true then
            narration.narrateAddonsEnabledTotal()
        end

        --Update the addon manager title with the number of active/total addons
        --d("[AddonSelector] active/found: " .. tos(countActive) .. "/" .. tos(countFound))
        local zoAddOnsTitle = ZOsControls.ZOAddOnsTitle
        zoAddOnsTitle:SetText(GetString(SI_WINDOW_TITLE_ADDON_MANAGER) .. " (" .. tos(countActive) .. "/" .. tos(countFound) .. ")")
        zoAddOnsTitle:SetMouseEnabled(true)
    end, delay)
end
utility.AddonSelectorUpdateCount = addonSelectorUpdateCount

--Scroll the scrollbar to an index
local function scrollAddonsScrollBarToIndex(index, animateInstantly)
    if ADDON_MANAGER_OBJECT ~= nil and ADDON_MANAGER_OBJECT.list ~= nil and ADDON_MANAGER_OBJECT.list.scrollbar ~= nil then
        --ADDON_MANAGER_OBJECT.list.scrollbar:SetValue((ADDON_MANAGER_OBJECT.list.uniformControlHeight-0.9)*index)
        --ZO_Scroll_ScrollAbsolute(self, value)
        local onScrollCompleteCallback = function() end
        animateInstantly = animateInstantly or false
        ZO_ScrollList_ScrollDataIntoView(ADDON_MANAGER_OBJECT.list, index, onScrollCompleteCallback, animateInstantly)
    end
end
utility.scrollAddonsScrollBarToIndex = scrollAddonsScrollBarToIndex



------------------------------------------------------------------------------------------------------------------------
-- Logout
------------------------------------------------------------------------------------------------------------------------
local function isAddonPackEnabledForAutoLoadOnLogout(packName, characterOrGlobalPackName)
    local loadAddonPackOnLogout = AS.acwsvChar.loadAddonPackOnLogout
    if ZO_IsTableEmpty(loadAddonPackOnLogout) then return false end
    if loadAddonPackOnLogout.packName == packName and loadAddonPackOnLogout.charName == characterOrGlobalPackName then return true end
    return false
end
utility.isAddonPackEnabledForAutoLoadOnLogout = isAddonPackEnabledForAutoLoadOnLogout


------------------------------------------------------------------------------------------------------------------------
-- LibScrollableMenu
------------------------------------------------------------------------------------------------------------------------
--> See API function RefreshCustomScrollableMenu


------------------------------------------------------------------------------------------------------------------------
-- Dialogs
------------------------------------------------------------------------------------------------------------------------
local function GetAddonSelectorYesNoDialog()
    if(not ESO_Dialogs[ASYesNoDialogName]) then
        ESO_Dialogs[ASYesNoDialogName] = {
            canQueue = true,
            title = {
                text = "",
            },
            mainText = {
                text = "",
            },
            buttons = {
                [1] = {
                    text = SI_DIALOG_YES,
                    callback = function()  end,
                },
                [2] = {
                    text = SI_DIALOG_NO,
                    callback = function()  end,
                }
            },
            noChoiceCallback = function()  end,
        }
    end
    return ESO_Dialogs[ASYesNoDialogName]
end

local function updateDialogTextsAndCallbacks(dialog, title, body, callbackYes, callbackNo)
    if dialog == nil or title == nil or body == nil or type(callbackYes) ~= "function" then return end

    dialog.title.text = title
    dialog.mainText.text = body

    local buttons = dialog.buttons
    buttons[1].callback = callbackYes
    if callbackNo ~= nil then buttons[2].callback = callbackNo else buttons[2].callback = function() end end
    return true
end

--Function to show a confirmation dialog
local function ShowConfirmationDialog(title, body, callbackYes, callbackNo, data)
    --Initialize the dialogs
    local yesNoDialog = GetAddonSelectorYesNoDialog()
    if yesNoDialog == nil then return end

    if updateDialogTextsAndCallbacks(yesNoDialog, title, body, callbackYes, callbackNo) == true then
        --Show the dialog now
        ZO_Dialogs_ShowPlatformDialog(ASYesNoDialogName, data)
        narration.AddDialogTitleBodyKeybindNarration(title, body, nil)
    end
end
utility.ShowConfirmationDialog = ShowConfirmationDialog



--======================================================================================================================
--======================================================================================================================
--======================================================================================================================

-------------------------------------------------------------------
-- -v- Other addons -v-
-------------------------------------------------------------------

--[AddonCategory]
local isAddonCategoryAddOnEnabled
local function isAddonCategoryEnabled()
    if isAddonCategoryAddOnEnabled == nil then
        isAddonCategoryAddOnEnabled = (AddonCategory ~= nil and AddonCategory.getIndexOfCategory ~= nil and true) or false
    end
    return isAddonCategoryAddOnEnabled
end
utility.otherAddOns.isAddonCategoryAddOnEnabled = isAddonCategoryEnabled


local function getAddonCategoryCategories()
    otherAddonsData.addonCategories = {}
    otherAddonsData.addonCategoriesIndices = {}

    if not isAddonCategoryEnabled() then return nil, nil end
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
    otherAddonsData.addonCategories = addonCategories
    otherAddonsData.addonCategoriesIndices = addonCategoriesIndices

    return addonCategories, addonCategoriesIndices
end
utility.otherAddOns.getAddonCategoryCategories = getAddonCategoryCategories
-------------------------------------------------------------------
--  -^- Other addons -^-
-------------------------------------------------------------------
