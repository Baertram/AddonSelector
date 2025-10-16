local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonNamePrefix = AS.addonNamePrefix

local constants = AS.constants
local utility = AS.utility
local asControls = AS.controls


local ZOsControls = constants.ZOsControls

local GLOBAL_PACK_NAME = constants.GLOBAL_PACK_NAME
local GLOBAL_PACK_BACKUP_BEFORE_MASSMARK_NAME = constants.GLOBAL_PACK_BACKUP_BEFORE_MASSMARK_NAME

local currentCharId = constants.currentCharId
local addonsWhichShouldNotBeDisabled = constants.addonsWhichShouldNotBeDisabled
local addonSelectorSelectAddonsButtonNameLabel = asControls.addonSelectorSelectAddonsButtonNameLabel

local onAddonPackSelected = AS.onAddonPackSelected

local areAllAddonsEnabled = utility.areAllAddonsEnabled

local ADDON_MANAGER = utility.GetAddonManager()
local ADDON_MANAGER_OBJECT = utility.GetAddonManagerObject()

local AddonSelector_GetLocalizedText = AddonSelector_GetLocalizedText


--ZOs reference variables
local tos = tostring
local strsub = string.sub
local strlow = string.lower
local strfor = string.format
local tsor = table.sort

local SM = SCENE_MANAGER


--======================================================================================================================
-- Addon packs
--======================================================================================================================

local function unselectAnyPack(selectedPackLabelToo)
--d("[AS]unselectAnyPack - selectedPackLabelToo: " .. tos(selectedPackLabelToo))
    local AddonSelectorDDL = AS.comboBox
    if AddonSelectorDDL == nil then return end
    AddonSelectorDDL:ClearAllSelections()
    AddonSelectorDDL:SetSelectedItemText("")

    if AS.controls.editBox then
        AS.controls.editBox:Clear()
    end

    if not selectedPackLabelToo then return end
    local selectedPackLabel = AS.controls.selectedPackNameLabel
    if selectedPackLabel ~= nil then
        selectedPackLabel:SetText("")
    end
end
utility.unselectAnyPack = unselectAnyPack

--Get the currently selected pack name and the character owning the pack for the currently logged in character
--as the user interfaces reloaded and the pack was loaded
local function GetCurrentCharacterSelectedPackname()
--d("GetCurrentCharacterSelectedPackname-currentCharId: " .. tos(currentCharId))
    --Get the current character's uniqueId
    if not currentCharId then return end
    --Set the currently selected packname to the SavedVariables
    return AS.acwsv.selectedPackNameForCharacters[currentCharId]
end
AS.GetCurrentCharacterSelectedPackname = GetCurrentCharacterSelectedPackname

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
AS.SetCurrentCharacterSelectedPackname = SetCurrentCharacterSelectedPackname


------------------------------------------------------------------------------------------------------------------------
-- Automatic dependency enabling upon pack load (if enabled in settings)
------------------------------------------------------------------------------------------------------------------------
--Enable any dependency which is currently not enabled, but would be needed for that addonIndex
local function enableDisabledAddonDependencies(addOnIndex, doDebug, packData, isCharacterPack)
    doDebug = doDebug or false

    local autoAddMissingDependencyAtPackLoad = AS.acwsv.autoAddMissingDependencyAtPackLoad  --#16

    --Build the ReverseLookup table for the ZO_AddOnsList scrollList indices to addon indices
    if AS.ReverseLookup == nil then
        utility.BuildAddOnReverseLookUpTable()
    end
    local nameLookup = AS.NameLookup
    local librariesLookup = AS.Libraries
    local filenameLookup = AS.FileNameLookup
    local anyAddonAddedToPack = false

    for dependencyIndex = 1, ADDON_MANAGER:GetAddOnNumDependencies(addOnIndex) do
        local dependencyName, dependencyExists, dependencyActive, dependencyMinVersion, dependencyVersion = ADDON_MANAGER:GetAddOnDependencyInfo(addOnIndex, dependencyIndex)
        if doDebug then --and not dependencyActive then
            d(">>dependencyName: " ..tos(dependencyName) .. ", dependencyExists: " ..tos(dependencyExists) .. ", dependencyActive: " .. tos(dependencyActive) .. ", dependencyMinVersion: " .. tos(dependencyMinVersion) .. ", dependencyVersion: " .. tos(dependencyVersion))
        end
        if dependencyExists and dependencyVersion >= dependencyMinVersion then --and not dependencyActive then
            local isLibrary = (librariesLookup[dependencyName] ~= nil and true) or false
            local dependencyAddOnIndex = (isLibrary and librariesLookup[dependencyName].index) or (nameLookup[dependencyName] ~= nil and nameLookup[dependencyName].index) or nil
            if doDebug then
                d(">>>enabling dependency now, index: " .. tos(dependencyAddOnIndex))
            end
            if dependencyAddOnIndex ~= nil then
                ADDON_MANAGER:SetAddOnEnabled(dependencyAddOnIndex, true)
                --#16 Add the missing dependency to the AddonPack
                if autoAddMissingDependencyAtPackLoad == true then
                    --Add missing to the pack, automatically upon pack load #16
                    if packData ~= nil then
                        local addonTable = packData.addonTable or packData
                        local strippedAddOnName = (isLibrary and librariesLookup[dependencyName].strippedAddOnName) or nameLookup[dependencyName].strippedAddOnName
                        if strippedAddOnName == nil then strippedAddOnName = dependencyName end
                        local dependencyFileName = filenameLookup[strippedAddOnName] or filenameLookup[dependencyName]
                        if addonTable[dependencyFileName] == nil then
                            d(addonNamePrefix .. strfor(AddonSelector_GetLocalizedText("autoAddedMissingDependencyToPack"), dependencyFileName, tos(packData.name)))
                            addonTable[dependencyFileName] = strippedAddOnName
                            anyAddonAddedToPack = true
                        end
                    end
                end
            end
        end
    end

    if anyAddonAddedToPack == true then
        --Update the DDL now - Throttled, so next call to enableDisabledAddonDependencies won't update it again and again ...
        utility.updateDDLThrottled(500)
    end
end

local function updateAddonsEnabledStateByPackData(packData, noUIShown, isCharacterPack, packLoading)
    local doDebug = false -- todo: 20251010 Disable after testing

    if not packData then return false end
    noUIShown = noUIShown or false
    isCharacterPack = isCharacterPack or false
    packLoading = packLoading or false
    local addonTable = packData.addonTable or packData
    if not addonTable or NonContiguousCount(addonTable) == 0 then return false end

    local notEnabledAddOnsOfLoadedPack = {} --#16
    local notEnabledAddOnNamesOfLoadedPack = {} --#16
    local scrollListData

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

            --Check all addons and libs at the current AddOns scrolllist, compare them to the addon pack (by filename)
            --and if their enabled state differs from "On", enable them.
            --> Also check for dependencies if enabling did not work! And automatically add the dependency to the pack
            scrollListData = ZO_ScrollList_GetDataList(ZOsControls.ZOAddOnsList)
            local counter = 0
            for k = 1, #scrollListData do
                local addonData = scrollListData[k]
                local addondataData = addonData and addonData.data or nil
                if addondataData then
                    local fileName = addondataData and addondataData.addOnFileName or nil
                    local addonIndex = addondataData and addondataData.index or nil
                    if addonIndex and fileName then
                        local addonShouldBeEnabled = addonTable[fileName] ~= nil

                        --Attention: addondataData.addOnEnabled does not relialby tell us if the addon is currently enabled!
                        --It could be that it is true but the addondataData.addOnState says "Dependency error"! (addondataData.hasDependencyError is true then)
                        -->The addon actually is not enabled then!
                        local changeAddonState = addonShouldBeEnabled ~= addondataData.addOnEnabled
                        if addondataData.addOnEnabled == true then
                            if addondataData.hasDependencyError == true or addondataData.addOnState == ADDON_STATE_DEPENDENCIES_DISABLED then
                                --[[
                                    ADDON_STATE_NO_STATE = 0
                                    ADDON_STATE_TOC_LOADED = 1
                                    ADDON_STATE_ENABLED = 2
                                    ADDON_STATE_DISABLED = 3
                                    ADDON_STATE_VERSION_MISMATCH = 4
                                    ADDON_STATE_DEPENDENCIES_DISABLED = 5
                                    ADDON_STATE_ERROR_STATE_UNABLE_TO_LOAD = 6
                                ]]
                                changeAddonState = false
                                if packLoading == true then
                                    --#16 Addon was not enabled? Maybe missing new dependency
                                    --if doDebug then d("<was not enabled due to dependencies!") end
                                    if not notEnabledAddOnNamesOfLoadedPack[fileName] then
                                        notEnabledAddOnNamesOfLoadedPack[fileName] = true
                                        notEnabledAddOnsOfLoadedPack[#notEnabledAddOnsOfLoadedPack + 1] = { scrollListIndex = k, addonIndex = addonIndex, fileName = fileName }
                                    end
                                end
                            end
                        end

                        --Addon is in the saved pack?
                        if doDebug and addonShouldBeEnabled == true then
                            counter = counter + 1
                            d("[" .. tos(counter).."]Idx " ..tos(addonIndex) ..": " ..tos(fileName) .. " / Change: " .. tos(changeAddonState))
                        end

                        if changeAddonState == true then
                            if doDebug and not addonShouldBeEnabled then
                                d("<<DISABLED non-pack addon: " ..tos(fileName))
                            end
                            somethingDone = true
                            ADDON_MANAGER:SetAddOnEnabled(addonIndex, addonShouldBeEnabled)
                            local enabled = select(5, ADDON_MANAGER:GetAddOnInfo(addonIndex))
                            addonData.data.addOnEnabled = enabled
                            if enabled then changed = true
                            end
                        end
                    end
                end
            end
        end
    end

    --#16 Any non enabled addon?
    if scrollListData ~= nil and #notEnabledAddOnsOfLoadedPack > 0 then
        ---Sort the not enabled so the libraries are the first (enabling them first should make life easier)
        table.sort(notEnabledAddOnsOfLoadedPack, function(a, b)
            local nameALow = strlow(a.fileName)
            local isALibrary = strsub(nameALow, 1, 3) == "lib"
            local nameBLow = strlow(b.fileName)
            local isBLibrary = strsub(nameBLow, 1, 3) == "lib"
            if isALibrary and not isBLibrary then return true end
            return nameALow < nameBLow
        end)

        --Loop the not enabled addons now, enable the dependencies and add them to the currently loaded pack
        for _, addonData in ipairs(notEnabledAddOnsOfLoadedPack) do
            if doDebug then
                local addonFileName = addonData.fileName
                local addonIndex = addonData.addonIndex
                d(">not enabled due to dependency errors - IDX ".. tos(addonIndex) .. ": " ..tos(addonFileName))
            end
            local addonRowDataOfNotEnabledAddon = scrollListData[addonData.scrollListIndex] ~= nil and scrollListData[addonData.scrollListIndex].data or nil
            if addonRowDataOfNotEnabledAddon ~= nil then
                if doDebug then
                    d(">checking: " ..tos(addonRowDataOfNotEnabledAddon.addOnFileName))
                end
                --checkDependsOn(addonRowDataOfNotEnabledAddon)
                enableDisabledAddonDependencies(addonRowDataOfNotEnabledAddon.index, doDebug, packData, isCharacterPack)
            end
        end

    end
    return somethingDone
end


------------------------------------------------------------------------------------------------------------------------
-- Save Pack
------------------------------------------------------------------------------------------------------------------------
local function saveAddonsAsPackToSV(packName, isPackBeforeMassMark, characterName, wasPackNameProvided)
    isPackBeforeMassMark = isPackBeforeMassMark or false
    local l_svForPack = (not isPackBeforeMassMark and AS.createSVTableForPack(packName, characterName, wasPackNameProvided)) or (isPackBeforeMassMark == true and {})

--d("[AS]saveAddonsAsPackToSV-packName: " ..tos(packName) .. "; isPackBeforeMassMark: " .. tos(isPackBeforeMassMark) .. "; characterName: " ..tos(characterName) .. "; wasPackNameProvided: " ..tos(wasPackNameProvided))
    if l_svForPack == nil then return end
    --#15 If any main-addon was disabled by clicking that addon line, and sub-addons that depend on the main addon were automatically
    --disabled too, the SavedVariables pack here must take the sub-addons into account too: They need to be removed from the pack
    --automatically! Checking only the enabled state will add those to the pack allthough they got dependency errors

    -- Add all of the enabled addOn to the pack table
    local aad = ZO_ScrollList_GetDataList(ZOsControls.ZOAddOnsList)
    for _, addonData in pairs(aad) do
        local data = addonData.data
        local isEnabled = data.addOnEnabled
        local hasDependencyError = data.hasDependencyError --#15

        if isEnabled and not hasDependencyError then
            local fileName = data.addOnFileName
            local addonName = data.strippedAddOnName
            --Add the addon to the pack into the SavedVariables
            l_svForPack[fileName] = addonName
        end
    end
--AddonSelector._debugSVForPack = l_svForPack
    --Try to save the addon packs to your SV "NOW" without reloadui
    --Will only work once every 15mins, and only if your SV file is < 50kb and will not happen instantly, but maybe soon within 3 mins (w/o a ReloadUI)
    ADDON_MANAGER:RequestAddOnSavedVariablesPrioritySave(ADDON_NAME)

    return l_svForPack
end
AS.saveAddonsAsPackToSV = saveAddonsAsPackToSV

local function saveAddonsAsPackBeforeMassMarking()
    AS.acwsv.lastMassMarkingSavedProfile     = nil
    AS.acwsv.lastMassMarkingSavedProfile     = saveAddonsAsPackToSV("LastAddonsBeforeMassMarking", true)
    AS.acwsv.lastMassMarkingSavedProfileTime = GetTimeStamp()
end
AS.saveAddonsAsPackBeforeMassMarking = saveAddonsAsPackBeforeMassMarking


------------------------------------------------------------------------------------------------------------------------
-- Load pack
------------------------------------------------------------------------------------------------------------------------
local function loadAddonPackNow(packName, charName, doNotShowAddonsList, noReloadUI, comingFromLogout)
    if packName == nil or packName == "" or charName == nil or charName == "" then return end
    AS.OpenGameMenuAndAddOnsAndThenLoadPack(packName, doNotShowAddonsList, noReloadUI, charName, comingFromLogout)
end
AS.loadAddonPackNow = loadAddonPackNow

local function loadAddonPack(packName, packData, forAllCharsTheSame, noUIShown, isCharacterPack)
--d("[AS]loadAddonPack")
    forAllCharsTheSame = forAllCharsTheSame or false
    -- Clear the edit box:
    AS.controls.editBox:Clear()

    --Prevent that hook to ADDON_MANAGER:SetAddOnEnabled will call updateDDL() and unselect the current selected pack
    AS.flags.skipUpdateDDL = true
    local somethingDone = updateAddonsEnabledStateByPackData(packData, noUIShown, isCharacterPack, true)
    AS.flags.skipUpdateDDL = false
--d(">somethingDone: " ..tos(somethingDone))

    if not AS.flags.doNotReloadUI and AS.acwsv.autoReloadUI == true then -- and somethingDone == true then
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
        onAddonPackSelected(packName, packData, AS.flags.skipOnAddonPackSelected, isCharacterPack)
    end
end
AS.loadAddonPack = loadAddonPack


------------------------------------------------------------------------------------------------------------------------
-- Undo
------------------------------------------------------------------------------------------------------------------------
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


------------------------------------------------------------------------------------------------------------------------
-- AddOns of a pack: Select/Deselect at addon list
------------------------------------------------------------------------------------------------------------------------
local addonIndicesOfAddonsWhichShouldNotBeDisabled = {}
local thisAddonIndex

--Select/Deselect all addon checkboxes
function AddonSelector_SelectAddons(selectAll, enableAll, onlyLibraries)
    enableAll = enableAll or false
    onlyLibraries = onlyLibraries or false
--d("[AddonSelector]AddonSelector_SelectAddons - selectAll: " ..tos(selectAll) .. ", enableAll: " ..tos(enableAll).. ", onlyLibraries: " ..tos(onlyLibraries))
    if not areAllAddonsEnabled(false) then return end
    if not ZOsControls.ZOAddOnsList or not ZOsControls.ZOAddOnsList.data then return end

    local selectAllSave = AS.acwsv.selectAllSave

    local selectAddOnsButton = AddonSelectorSelectAddonsButton

    --Save the currently enabled addons as a special "backup pack" so we can restore it later
    saveAddonsAsPackBeforeMassMarking()

    --Copy the AddOns list
    local addonsListCopy = ZO_ShallowTableCopy(ZOsControls.ZOAddOnsList.data)
    --TODO: For debugging
    --AddonSelector._addonsListCopy = addonsListCopy
    --local addonsList = ZOsControls.ZOAddOnsList.data

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
        selectAddOnsButton:SetText(AddonSelector_GetLocalizedText("SelectAllAddonsSaved"))
    else
        selectAddOnsButton:SetText(AddonSelector_GetLocalizedText("SelectAllAddons"))
    end
    addonSelectorSelectAddonsButtonNameLabel = addonSelectorSelectAddonsButtonNameLabel or asControls.addonSelectorSelectAddonsButtonNameLabel
    local isSelectAddonsButtonTextEqualSelectedSaved = (not enableAll and selectAll == true and addonSelectorSelectAddonsButtonNameLabel:GetText() == AddonSelector_GetLocalizedText("SelectAllAddonsSaved") and true) or false

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
        selectAddOnsButton:SetText(AddonSelector_GetLocalizedText("SelectAllAddons"))
    end

    --Update the flag for the filters and resort of the addon list
    ZO_AddOnManager.isDirty = true
    --Remove the addons fragment from the scene (to refresh it properly)
    SM:RemoveFragment(ADDONS_FRAGMENT)
    --Re-Add the addons fragment to the scene (to refresh it properly)
    SM:AddFragment(ADDONS_FRAGMENT)

--Attempt to fix ESC and RETURN key and other global keybinds not woring aftr you have used an AddonManager keybind
    -->Maybe because of the remove and add fragment?
    ADDON_MANAGER_OBJECT:RefreshKeybinds()
end