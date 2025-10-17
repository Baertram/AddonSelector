local AS = AddonSelectorGlobal
local constants = AS.constants

--local ADDON_NAME = AS.name
local addonNamePrefix = AS.addonNamePrefix

local utility = AS.utility
local utilityOtherAddons = utility.otherAddOns
local otherAddonData = AS.otherAddonsData
local keybinds = constants.keybinds
local ZOsControls = constants.ZOsControls
local narration = AS.narration
--local stringConstants = constants.strings
--local flags = AS.flags

local currentCharName = constants.currentCharName

local GLOBAL_PACK_NAME = constants.GLOBAL_PACK_NAME
local SEARCH_TYPE_NAME = constants.SEARCH_TYPE_NAME
local MAX_ADDON_LOAD_PACK_KEYBINDS = keybinds.MAX_ADDON_LOAD_PACK_KEYBINDS

local scrollAddonsScrollBarToIndex = utility.scrollAddonsScrollBarToIndex
local isAddonRow = utility.isAddonRow
local areAllAddonsEnabled = utility.areAllAddonsEnabled

local ADDON_MANAGER_OBJECT = utility.GetAddonManagerObject()

local AddonSelector_GetLocalizedText = AddonSelector_GetLocalizedText
local packNameGlobal = AddonSelector_GetLocalizedText("packGlobal")

local tos = tostring
local tins = table.insert
local strlow = string.lower
local zopsf = zo_plainstrfind


--======================================================================================================================
-- Global API functions
--======================================================================================================================

------------------------------------------------------------------------------------------------------------------------
-- UI functions
------------------------------------------------------------------------------------------------------------------------
--Reload the user interface
function AddonSelector_ReloadTheUI()
    ReloadUI("ingame")
end


------------------------------------------------------------------------------------------------------------------------
-- AddOn List functions
------------------------------------------------------------------------------------------------------------------------
--Scroll to AddOns or libraries section
function AddonSelector_ScrollTo(toAddOns)
    if toAddOns == nil then end
    utility.GetAddonManagerObject()
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

--Search for addons by e.g. name and scroll the list to the found addon, or filter (hide) all non matching addons
function AddonSelector_SearchAddon(searchType, searchValue, doHideNonFound, isAddonCategorySearched)
    searchType = searchType or SEARCH_TYPE_NAME
    doHideNonFound = doHideNonFound or false
    isAddonCategorySearched = isAddonCategorySearched or false
--d("[AddonSelector]SearchAddon, searchType: " .. tos(searchType) .. ", searchValue: " .. tos(searchValue) .. ", hideNonFound: " ..tos(doHideNonFound).. ", isAddonCategorySearched: " ..tos(isAddonCategorySearched))

    local wasAnythingFound = false
    AS.lastData.selectedAddonSearchResult = nil
    AS.flags.AddedAddonsFragment = false
--d("[AddonSelector]search done FALSE 1: " ..tos(AS.flags.AddedAddonsFragment))

    if isAddonCategorySearched == true then
        --searchValue is the category name of the addon AddonCategory. The index to scroll to is defined via table
        --AddonCategory.indexCategories[categoryName] = addonsIndexInAddonsList
        --Cached data will be stored in local table addonCategoryIndices[categoryName] where categoryName is searchValue!
        -->Get the index tos croll to now
        utilityOtherAddons.getAddonCategoryCategories()
        local addonCategoryIndices = otherAddonData.addonCategoryIndices
        if addonCategoryIndices == nil then return end
        local indexToScrollTo = addonCategoryIndices[searchValue]
--d(">addoncategory index: " ..tos(indexToScrollTo))
        if indexToScrollTo == nil then return end
        if indexToScrollTo ~= -1 then
            -->Scroll to the searchValue's index now
            AS.flags.AddedAddonsFragment = true
--d("[AddonSelector]search done 2: " ..tos(AS.flags.AddedAddonsFragment))
            scrollAddonsScrollBarToIndex(indexToScrollTo)
            AS.flags.AddedAddonsFragment = true
--d("[AddonSelector]search done 3: " ..tos(AS.flags.AddedAddonsFragment))

            narration.AddNewChatNarrationText("[Scrolled to] Category: " ..tos(searchValue), true)
        else
            --Scroll to the top -> Unassigned addons (no category)
            AS.flags.AddedAddonsFragment = true
--d("[AddonSelector]search done 4: " ..tos(AS.flags.AddedAddonsFragment))
            AddonSelector_ScrollTo(true)
            AS.flags.AddedAddonsFragment = true
--d("[AddonSelector]search done 5: " ..tos(AS.flags.AddedAddonsFragment))

            narration.AddNewChatNarrationText("[Scrolled to] AddOns", true)
        end
        AS.flags.AddedAddonsFragment = false
        return
    end

    local addonList = ZOsControls.ZOAddOnsList.data
    if addonList == nil then return end
    local isEmptySearch = searchValue == ""
    local toSearch = (not isEmptySearch and strlow(searchValue)) or searchValue
    local settings = AS.acwsv
    local searchExcludeFilename = settings.searchExcludeFilename
    local searchSaveHistory = settings.searchSaveHistory
    if searchSaveHistory == true and not isEmptySearch then
        utility.updateSearchHistoryDelayed(searchType, searchValue)
    end

    local addonsFound = {}
    local alreadyFound = AS.searchAndFoundData.alreadyFound
    --No search term given
    if isEmptySearch then
        --Refresh the visible controls so their names get resetted to standard
        ADDON_MANAGER_OBJECT:RefreshVisible()
        --Reset the searched table completely
        AS.searchAndFoundData.alreadyFound = {}
        --Unregister all update events
        utility.unregisterOldEventUpdater()
        AS.flags.AddedAddonsFragment = false
--d("[AddonSelector]search done FALSE 2: " ..tos(AS.flags.AddedAddonsFragment))

        narration.AddNewChatNarrationText(AddonSelector_GetLocalizedText("searchMenuStr") .. " " .. GetString(SI_QUICKSLOTS_EMPTY), true)
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
                        AS.searchAndFoundData.alreadyFound[toSearch] = AS.searchAndFoundData.alreadyFound[toSearch] or {}
                        tins(AS.searchAndFoundData.alreadyFound[toSearch], { [sortIndex] = false})

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
                    AS.flags.AddedAddonsFragment = true
--d("[AddonSelector]search done 6: " ..tos(AS.flags.AddedAddonsFragment))
                    scrollAddonsScrollBarToIndex(scrollToIndex)

                    AS.lastData.selectedAddonSearchResult                    = {
                        sortIndex   =   scrollToIndex,
                        control     =   ZOsControls.ZOAddOnsList.data[scrollToIndex], --Will be re-set at function eventUpdateFunc as the [>  <] surrounding tags will be placed!
                    }

                    AS.flags.AddedAddonsFragment = true
--d("[AddonSelector]search done 7: " ..tos(AS.flags.AddedAddonsFragment))
                    --Set this entry to true so we know a scroll-to has taken place already to this sortIndex
                    AS.searchAndFoundData.alreadyFound[toSearch][index][scrollToIndex] = true
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
                        AS.searchAndFoundData.alreadyFound[toSearch] = nil
                        resetWasDone              = true
--d(">all entries found and scrolled to!")
                    end
                    --Change the shown row name and put [ ] around the addon name so one sees the currently selected row
                    --[[
                    local scrollbar = ZOsControls.ZOAddOnsList.scrollbar
                    local delay = 100
                    if scrollbar ~= nil then
                        local currentScrollBarPosition = scrollbar:GetValue()
                        local approximatelyCurrentAddonSortIndex = currentScrollBarPosition / ZOsControls.ZOAddOnsList.uniformControlHeight
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
                    if AS.flags.addonListWasOpenedByAddonSelector == true then
                        zo_callLater(function()
                            narration.narrateCurrentlyScrolledToAddonName(scrollToIndex, resetWasDone, searchValue)
                        end, 3500)
                    else
                        narration.narrateCurrentlyScrolledToAddonName(scrollToIndex, resetWasDone, searchValue)
                    end

                    utility.changeAddonControlName(scrollToIndex, true)

                    --Abort now as scroll-to was done
                    return
                end
            end
        end
    end

    if not wasAnythingFound then
        AS.flags.AddedAddonsFragment = false
        narration.AddNewChatNarrationText(GetString(SI_TRADINGHOUSESEARCHOUTCOME1), true)
    end
end

--Toggle the addon state of the currently searched, and thus selected, addon, or if no addon as searched: The addon row
--below the mouse cursor
function AddonSelector_ToggleCurrentAddonState()
    if not areAllAddonsEnabled(true) then return end

    local rowCtrl = WINDOW_MANAGER:GetMouseOverControl()

    --Is an addon search active and was a result found
    if AS.lastData.selectedAddonSearchResult ~= nil then
        local searchBox = AS.controls.searchBox
        if searchBox ~= nil and searchBox:GetText() ~= "" then
            --1 addon row was selected with the surrounding [>  <] tags. Toggle this addon's state!
            rowCtrl = AS.lastData.selectedAddonSearchResult.control
            if rowCtrl == nil or AS.lastData.selectedAddonSearchResult.sortIndex == nil then
                AS.lastData.selectedAddonSearchResult = nil
                return
            end
        else
            AS.lastData.selectedAddonSearchResult = nil
            AS.flags.AddedAddonsFragment = false
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
                if AS.lastData.selectedAddonSearchResult ~= nil then
                    --Did the rows scroll and the sortIndex at the pool's rowControl changed
                    local sortIndexSearchSaved = AS.lastData.selectedAddonSearchResult.sortIndex
                    if sortIndexSearchSaved ~= addonData.sortIndex then
--d(">sortIndex changed, expected:  " ..tos(sortIndexSearchSaved) .. "/ got: " ..tos(addonData.sortIndex))
                        local rowControlOfSortIndex = (ZOsControls.ZOAddOnsList.data[sortIndexSearchSaved] ~= nil and ZOsControls.ZOAddOnsList.data[sortIndexSearchSaved].control) or nil
                        if rowControlOfSortIndex ~= nil then
--d(">>found new rowControl: " .. tos(rowControlOfSortIndex:GetName()))
                            AS.lastData.selectedAddonSearchResult.control = rowControlOfSortIndex
                            rowCtrl = rowControlOfSortIndex

                            isAddonRowControl, addonData = isAddonRow(rowCtrl)
                            if not isAddonRowControl or addonData == nil then
                                return
                            end
                        else
                            AS.lastData.selectedAddonSearchResult = nil
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
            AS.Addon_Toggle_Enabled(rowCtrl, addonData)
        end
    end, 0) --call 1 frame later to assure moc() got the correct ctrl of the scrollable, resused list row pool!
end

--Start an addon search: Set mouse cursor to search box so you can start to type directly
local onMouseUpHandlerOfSearchBox
function AddonSelector_StartAddonSearch()
    AS.lastData.selectedAddonSearchResult = nil
    if AS.controls.searchBox == nil then return end
    local searchBox = AS.controls.searchBox
    searchBox:Clear()
    onMouseUpHandlerOfSearchBox = onMouseUpHandlerOfSearchBox or searchBox:GetHandler("OnMouseUp")
    if onMouseUpHandlerOfSearchBox == nil then return end
    onMouseUpHandlerOfSearchBox(searchBox, MOUSE_BUTTON_INDEX_LEFT, true)
    searchBox:TakeFocus()
end


------------------------------------------------------------------------------------------------------------------------
-- Pack functions
------------------------------------------------------------------------------------------------------------------------
--Load a saved pack via a keybind
function AddonSelector_LoadPackByKeybind(keybindNr)
    if keybindNr == nil or keybindNr < 1 or keybindNr > MAX_ADDON_LOAD_PACK_KEYBINDS then return end
    if AS.acwsv == nil then return end
    local packKeybinds = AS.acwsv.packKeybinds
    local packDataToLoad = packKeybinds[keybindNr]
    if packDataToLoad == nil then return end
    AS.loadAddonPackNow(packDataToLoad.packName, packDataToLoad.charName, nil, nil)
end

--Show the current user's active pack in the chat
function AddonSelector_ShowActivePackInChat()
    local currentCharacterId, currentlySelectedPackNameData = utility.getCurrentCharsPackNameData()
--d(">currentCharacterId: " ..tos(currentCharacterId) .. ", currentlySelectedPackNameData.packName: " ..tos(currentlySelectedPackNameData.packName))
    if not currentCharacterId or not currentlySelectedPackNameData then return end
    local currentlySelectedPackName = currentlySelectedPackNameData.packName
    local charNameOfSelectedPack = currentlySelectedPackNameData.charName
--d(">charNameOfSelectedPack: " ..tos(charNameOfSelectedPack))
    if not currentlySelectedPackName or currentlySelectedPackName == "" then return end
    local currentPackInfoText = (AddonSelector_GetLocalizedText("packName")) .. " " ..tos(currentlySelectedPackName)
    if charNameOfSelectedPack == nil or charNameOfSelectedPack == "" or charNameOfSelectedPack == GLOBAL_PACK_NAME then
        charNameOfSelectedPack = ", " .. packNameGlobal
    else
        charNameOfSelectedPack = ", " .. AddonSelector_GetLocalizedText("packCharName") .. ": " ..tos(charNameOfSelectedPack)
    end
    d(addonNamePrefix .. currentPackInfoText .. charNameOfSelectedPack)
end



------------------------------------------------------------------------------------------------------------------------
-- XML global functions
------------------------------------------------------------------------------------------------------------------------
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
        utility.ChangeDeleteButtonEnabledState(nil, false)
    else
        if AS.comboBox.m_selectedItemData ~= nil then
            newEnabledState = true
        end
    end
    --Enable/Disable the save pack button
    utility.ChangeSaveButtonEnabledState(newEnabledState)
end
