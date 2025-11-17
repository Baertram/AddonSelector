local AS = AddonSelectorGlobal

local constants = AS.constants
local svConstants = constants.SavedVariables
local colors = constants.colors
local utility = AS.utility
local asControls = AS.controls
local textures = constants.textures

local defaultSettingsContextMenuOptions = constants.LSM.defaultSettingsContextMenuOptions

local GLOBAL_PACK_NAME = constants.GLOBAL_PACK_NAME
local CHARACTER_PACK_CHARNAME_IDENTIFIER = constants.CHARACTER_PACK_CHARNAME_IDENTIFIER

--local currentCharIdNum = constants.currentCharIdNum
local currentCharId = constants.currentCharId
local currentCharName = constants.currentCharName

local addonSelectorSelectAddonsButtonNameLabel = asControls.addonSelectorSelectAddonsButtonNameLabel
local myNormalColor = colors.myNormalColorDef
local myDisabledColor = colors.myDisabledColorDef
local settingNeedsToUpdateDDL = constants.settingNeedsToUpdateDDL

local areAddonsCurrentlyEnabled = utility.areAddonsCurrentlyEnabled
local checkIfGlobalPacksShouldBeShown = utility.checkIfGlobalPacksShouldBeShown
local clearAndUpdateDDL = utility.clearAndUpdateDDL
local getCharacterIdByName = utility.getCharacterIdByName

local AddonSelector_GetLocalizedText = AddonSelector_GetLocalizedText

local packNameGlobal = AddonSelector_GetLocalizedText("packNameGlobal")

--ZOs reference variables
local tos = tostring
local strlow = string.lower
local strfor = string.format
local tins = table.insert

--======================================================================================================================
-- SavedVariables & settings menu (context menu at the "gear" icon)
--======================================================================================================================
--Open the LibAddonMenu2 settings panel (of all addons)
local function ShowLAMAddonSettings()
    if not LibAddonMenu2 then return end
    LibAddonMenu2:OpenToPanel(nil)
end
AS.ShowLAMAddonSettings = ShowLAMAddonSettings


------------------------------------------------------------------------------------------------------------------------
-- SavedVariables
------------------------------------------------------------------------------------------------------------------------

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
AS.getSVTableForPacksOfCharname = getSVTableForPacksOfCharname

local function getSVTableForPackBySavedType(globalOrCharName, characterId)
    if globalOrCharName == GLOBAL_PACK_NAME then
        return AS.acwsv.addonPacks, nil
    else
        return getSVTableForPacksOfCharname(globalOrCharName, characterId)
    end
end
AS.getSVTableForPackBySavedType = getSVTableForPackBySavedType

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
AS.getCharacterIdFromSVTableByCharacterName = getCharacterIdFromSVTableByCharacterName

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
AS.getCharacterIdAndNameForSV = getCharacterIdAndNameForSV


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
AS.getSVTableForPacks = getSVTableForPacks

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
AS.createSVTableForPack = createSVTableForPack


------------------------------------------------------------------------------------------------------------------------
-- Loading ZO SavedVars
------------------------------------------------------------------------------------------------------------------------
function AS.LoadSaveVariables()
    local svName            = svConstants.svTableName
    local SAVED_VAR_VERSION = svConstants.svVersion
    local defaultSavedVars  = svConstants.defaultSavedVars
    local defaultSavedVarsChar = svConstants.defaultSavedVarsChar

    local worldName = GetWorldName()
    --Get the saved addon packages without a server reference
    local oldSVWithoutServer = ZO_SavedVars:NewAccountWide(svName, SAVED_VAR_VERSION, nil, defaultSavedVars)

    --Show packs of all accounts at the same time
    --ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
    AS.acwsv                = ZO_SavedVars:NewAccountWide(svName, SAVED_VAR_VERSION, nil, defaultSavedVars, worldName, "AllAccounts")
    --ZO_SavedVars:NewCharacterIdSettings(savedVariableTable, version, namespace, defaults, profile)
    AS.acwsvChar            = ZO_SavedVars:NewCharacterIdSettings(svName, SAVED_VAR_VERSION, nil, defaultSavedVarsChar, worldName)

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



------------------------------------------------------------------------------------------------------------------------
-- Settings menu (context menu) at the "gear" icon
------------------------------------------------------------------------------------------------------------------------
local function setMenuItemCheckboxState(checkboxIndex, newState)
    newState = newState or false
    if newState == true then
        ZO_CheckButton_SetChecked(ZO_Menu.items[checkboxIndex].checkbox)
    else
        ZO_CheckButton_SetUnchecked(ZO_Menu.items[checkboxIndex].checkbox)
    end
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
    utility.ChangeDeleteButtonEnabledState(newState, nil)

    --Any setting was changed that needs to update the comboox's dropdown entries?
    if settingNeedsToUpdateDDL[currentStateVar] == true then
        --Prepare rebuild of the DDL dropdown entries
        utility.updateDDL()
        if currentStateVar == "autoReloadUI" then
            utility.updateAutoReloadUITexture(newState)
        end
    end
end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Show the settings context menu at the dropdown button
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
function AddonSelector_ShowSettingsDropdown(buttonCtrl)
    ClearCustomScrollableMenu()
    --Hide the DDL dropdown, so that setting changes can properly be effecitve on next open
    AS.controls.ddl.m_comboBox:HideDropdown()

    clearAndUpdateDDL = clearAndUpdateDDL or utility.clearAndUpdateDDL

    local areAllAddonsCurrentlyEnabled = areAddonsCurrentlyEnabled()
    --d(">areAllAddonsCurrentlyEnabled: " ..tos(areAllAddonsCurrentlyEnabled))
    addonSelectorSelectAddonsButtonNameLabel = addonSelectorSelectAddonsButtonNameLabel or asControls.addonSelectorSelectAddonsButtonNameLabel

    local LSMadditionalData = { normalColor = myNormalColor, disabledColor = myDisabledColor, enabled = areAllAddonsCurrentlyEnabled }


    --Add the currently logged in character name as header
    AddCustomScrollableMenuHeader(currentCharName)

    --Addons are all enabled (or disabled)?
    if areAllAddonsCurrentlyEnabled == true then
        --Last saved pack before disable all
        local lastDisableAllProfile = AS.acwsv.lastSavedProfileBeforeDisableAll
        if lastDisableAllProfile ~= nil then
            local lastSavedPreDisableAllTime = ""
            local countAddonsInBackup        = NonContiguousCount(lastDisableAllProfile)
            if AS.acwsv.lastSavedProfileBeforeDisableAllTime ~= nil then
                lastSavedPreDisableAllTime = os.date("%c", AS.acwsv.lastSavedProfileBeforeDisableAllTime)
            end
            if countAddonsInBackup ~= nil and countAddonsInBackup > 0 then
                local addonsUndoTab, librariesUndoTab = utility.sortAndGroupAddons(lastDisableAllProfile)
                if #addonsUndoTab > 1 or #librariesUndoTab > 1 then
                    local submenuItemsUndo = {}
                    local firstSubmenuItem = {
                        label    = AddonSelector_GetLocalizedText("UndoLastBeforeDisableAllMarking"),
                        callback = function()
                            AddonSelector_UndoLastDisableAllMarking(false)
                        end,
                    }
                    tins(submenuItemsUndo, firstSubmenuItem)

                    --AddOns
                    for idx, addonUndoName in ipairs(addonsUndoTab) do
                        if idx == 1 then
                            local addonsInUndoText = strfor(AddonSelector_GetLocalizedText("addons") .. " - #" .. colors.numAddonsColorTemplate.."/%s", tos(#addonsUndoTab), tos(countAddonsInBackup))
                            local submenuItemUndoAddOnsHeader = {
                                label    = addonsInUndoText,
                                callback = function()
                                end,
                                entryType = LSM_ENTRY_TYPE_HEADER,
                            }
                            tins(submenuItemsUndo, submenuItemUndoAddOnsHeader)

                        end
                        local submenuItemUndo = {
                            label    = addonUndoName,
                            callback = function()
                            end,
                            enabled = false,
                        }
                        tins(submenuItemsUndo, submenuItemUndo)
                    end
                    --Libraries
                    for idx, libraryUndoName in ipairs(librariesUndoTab) do
                        if idx == 1 then
                            local librariesInUndoText = strfor(AddonSelector_GetLocalizedText("libraries") .. " - #" .. colors.numLibrariesColorTemplate.."/%s", tos(#librariesUndoTab), tos(countAddonsInBackup))
                            local submenuItemUndoLibrariesHeader = {
                                label    = librariesInUndoText,
                                callback = function()
                                end,
                                entryType = LSM_ENTRY_TYPE_HEADER,
                            }
                            tins(submenuItemsUndo, submenuItemUndoLibrariesHeader)
                        end
                        local submenuItemUndo = {
                            label    = libraryUndoName,
                            callback = function()
                            end,
                            enabled = false,
                        }
                        tins(submenuItemsUndo, submenuItemUndo)
                    end
                    if #submenuItemsUndo > 0 then
                        --AddCustomScrollableSubMenuEntry(text, entries, callbackFunc)
                        AddCustomScrollableSubMenuEntry(AddonSelector_GetLocalizedText("UndoLastBeforeDisableAllMarking") .. " #" .. tos(countAddonsInBackup) .." (" .. tos(lastSavedPreDisableAllTime) .. ")", submenuItemsUndo, function() AddonSelector_UndoLastDisableAllMarking(false) end)
                    end
                end
                --AddCustomScrollableMenuEntry(text, callback, entryType, entries, additionalData)
                AddCustomScrollableMenuEntry(AddonSelector_GetLocalizedText("ClearLastBeforeDisableAllMarking"),function() AddonSelector_UndoLastDisableAllMarking(true) end, LSM_ENTRY_TYPE_NORMAL, nil, LSMadditionalData)
                AddCustomScrollableMenuDivider()
            end
        end


        --Last changed addons backup/restore
        local lastMassMarkingProfile = AS.acwsv.lastMassMarkingSavedProfile
        if lastMassMarkingProfile ~= nil then
            local lastSavedPreMassMarkingTime = ""
            local countAddonsInBackup = NonContiguousCount(lastMassMarkingProfile)
            if AS.acwsv.lastMassMarkingSavedProfileTime ~= nil then
                lastSavedPreMassMarkingTime = os.date("%c", AS.acwsv.lastMassMarkingSavedProfileTime)
            end
            if countAddonsInBackup ~= nil and countAddonsInBackup > 0 then
                local addonsUndoTab, librariesUndoTab = utility.sortAndGroupAddons(lastMassMarkingProfile)
                if #addonsUndoTab > 1 or #librariesUndoTab > 1 then
                    local submenuItemsUndo = {}
                    local firstSubmenuItem = {
                        label    = AddonSelector_GetLocalizedText("UndoLastMassMarking"),
                        callback = function()
                            AddonSelector_UndoLastMassMarking(false)
                        end,
                    }
                    tins(submenuItemsUndo, firstSubmenuItem)

                    --AddOns
                    for idx, addonUndoName in ipairs(addonsUndoTab) do
                        if idx == 1 then
                            local addonsInUndoText = strfor(AddonSelector_GetLocalizedText("addons") .. " - #" .. colors.numAddonsColorTemplate.."/%s", tos(#addonsUndoTab), tos(countAddonsInBackup))
                            local submenuItemUndoAddOnsHeader = {
                                label    = addonsInUndoText,
                                callback = function()
                                end,
                                entryType = LSM_ENTRY_TYPE_HEADER,
                            }
                            tins(submenuItemsUndo, submenuItemUndoAddOnsHeader)

                        end
                        local submenuItemUndo = {
                            label    = addonUndoName,
                            callback = function()
                            end,
                            enabled = false,
                        }
                        tins(submenuItemsUndo, submenuItemUndo)
                    end
                    --Libraries
                    for idx, libraryUndoName in ipairs(librariesUndoTab) do
                        if idx == 1 then
                            local librariesInUndoText = strfor(AddonSelector_GetLocalizedText("libraries") .. " - #" .. colors.numLibrariesColorTemplate.."/%s", tos(#librariesUndoTab), tos(countAddonsInBackup))
                            local submenuItemUndoLibrariesHeader = {
                                label    = librariesInUndoText,
                                callback = function()
                                end,
                                entryType = LSM_ENTRY_TYPE_HEADER,
                            }
                            tins(submenuItemsUndo, submenuItemUndoLibrariesHeader)
                        end
                        local submenuItemUndo = {
                            label    = libraryUndoName,
                            callback = function()
                            end,
                            enabled = false,
                        }
                        tins(submenuItemsUndo, submenuItemUndo)
                    end
                    if #submenuItemsUndo > 0 then
                        --AddCustomScrollableSubMenuEntry(text, entries, callbackFunc)
                        AddCustomScrollableSubMenuEntry(AddonSelector_GetLocalizedText("UndoLastMassMarking") .. " #" .. tos(countAddonsInBackup) .." (" .. tos(lastSavedPreMassMarkingTime) .. ")", submenuItemsUndo, function() AddonSelector_UndoLastMassMarking(false) end)
                    end
                end
                --AddCustomScrollableMenuEntry(text, callback, entryType, entries, additionalData)
                AddCustomScrollableMenuEntry(AddonSelector_GetLocalizedText("ClearLastBeforeDisableAllMarking"),function() AddonSelector_UndoLastMassMarking(true) end, LSM_ENTRY_TYPE_NORMAL, nil, LSMadditionalData)
                AddCustomScrollableMenuDivider()
            end
        end

        --Deselect/Select all
        AddCustomScrollableMenuEntry(AddonSelector_GetLocalizedText("DeselectAllAddons"),      function() AddonSelector_SelectAddons(false, nil, nil) end, LSM_ENTRY_TYPE_NORMAL, nil, LSMadditionalData)
        local currentAddonSelectorSelectAllButtonText = addonSelectorSelectAddonsButtonNameLabel:GetText()
        if currentAddonSelectorSelectAllButtonText ~= AddonSelector_GetLocalizedText("SelectAllAddons") then
            AddCustomScrollableMenuEntry(currentAddonSelectorSelectAllButtonText,              function() AddonSelector_SelectAddons(true, nil, nil) end, LSM_ENTRY_TYPE_NORMAL, nil, LSMadditionalData)
        end
        AddCustomScrollableMenuEntry(AddonSelector_GetLocalizedText("SelectAllAddons"),                                            function() AddonSelector_SelectAddons(true, true, nil) end, LSM_ENTRY_TYPE_NORMAL, nil, LSMadditionalData)
        AddCustomScrollableMenuEntry(AddonSelector_GetLocalizedText("DeselectAllLibraries"),   function() AddonSelector_SelectAddons(false, true, true) end, LSM_ENTRY_TYPE_NORMAL, nil, LSMadditionalData)
        AddCustomScrollableMenuEntry(AddonSelector_GetLocalizedText("SelectAllLibraries"),     function() AddonSelector_SelectAddons(true, true, true) end, LSM_ENTRY_TYPE_NORMAL, nil, LSMadditionalData)
        AddCustomScrollableMenuDivider()
    end

    --Scroll to addons/libraries
    AddCustomScrollableMenuEntry(AddonSelector_GetLocalizedText("ScrollToAddons"),         function() AddonSelector_ScrollTo(true)  end, LSM_ENTRY_TYPE_NORMAL)
    AddCustomScrollableMenuEntry(AddonSelector_GetLocalizedText("ScrollToLibraries"),      function() AddonSelector_ScrollTo(false) end, LSM_ENTRY_TYPE_NORMAL)
    AddCustomScrollableMenuDivider()

    --Add the global pack options
    checkIfGlobalPacksShouldBeShown()
    local globalPackSubmenu = {
        {
            label    = AddonSelector_GetLocalizedText("ShowGlobalPacks"),
            callback = function(comboBox, itemName, item, checked)
                AS.acwsv.showGlobalPacks = checked
                checkIfGlobalPacksShouldBeShown(comboBox, moc(), item) --Should update the enabled state of the next submenu entry in same submenu automatically!
                clearAndUpdateDDL()
            end,
            checked  = function() return AS.acwsv.showGlobalPacks end,
            entryType = LSM_ENTRY_TYPE_CHECKBOX,
        },
        {
            label    = AddonSelector_GetLocalizedText("ShowSubMenuAtGlobalPacks"),
            callback = function(comboBox, itemName, item, checked)
                AS.acwsv.showSubMenuAtGlobalPacks = checked
                clearAndUpdateDDL()
            end,
            checked  = function()
                return AS.acwsv.showSubMenuAtGlobalPacks
            end,
            enabled = function()
                return AS.acwsv.showGlobalPacks
            end,
            entryType = LSM_ENTRY_TYPE_CHECKBOX,
        },
    }
    AddCustomScrollableSubMenuEntry(AddonSelector_GetLocalizedText("GlobalPackSettings"), globalPackSubmenu)

    --Add the character pack options
    local characterNameSubmenu = {
        {
            label    = AddonSelector_GetLocalizedText("SaveGroupedByCharacterName"),
            callback = function(comboBox, itemName, item, checked)
                AS.acwsv.saveGroupedByCharacterName = checked
                checkIfGlobalPacksShouldBeShown(comboBox, moc(), item)
                if checked == true then
                    AS.acwsv.showGroupedByCharacterName = true
                end
                clearAndUpdateDDL()
            end,
            checked  = function() return AS.acwsv.saveGroupedByCharacterName end,
            entryType = LSM_ENTRY_TYPE_CHECKBOX,
        },
        {
            label    = AddonSelector_GetLocalizedText("ShowGroupedByCharacterName"),
            callback = function(comboBox, itemName, item, checked)
                AS.acwsv.showGroupedByCharacterName = checked
                checkIfGlobalPacksShouldBeShown(comboBox, moc(), item)
                clearAndUpdateDDL()
            end,
            checked  = function() return AS.acwsv.showGroupedByCharacterName end,
            enabled = function() return not AS.acwsv.saveGroupedByCharacterName end,
            entryType = LSM_ENTRY_TYPE_CHECKBOX,
        },
        {
            label    = AddonSelector_GetLocalizedText("ShowPacksOfOtherAccountsChars"),
            callback = function(comboBox, itemName, item, checked)
                AS.acwsv.showPacksOfOtherAccountsChars = checked
                clearAndUpdateDDL()
            end,
            checked  = function() return AS.acwsv.showPacksOfOtherAccountsChars end,
            enabled = function() return AS.acwsv.saveGroupedByCharacterName or AS.acwsv.showGroupedByCharacterName end,
            entryType = LSM_ENTRY_TYPE_CHECKBOX,
        },
    }
    AddCustomScrollableSubMenuEntry(AddonSelector_GetLocalizedText("CharacterNameSettings"), characterNameSubmenu)


    --Add the search options
    local searchOptionsSubmenu = {
        {
            label    = AddonSelector_GetLocalizedText("searchExcludeFilename"),
            callback = function(comboBox, itemName, item, checked)
                AS.acwsv.searchExcludeFilename = checked
            end,
            checked  = function() return AS.acwsv.searchExcludeFilename end,
            entryType = LSM_ENTRY_TYPE_CHECKBOX,
        },
        {
            label    = AddonSelector_GetLocalizedText("searchSaveHistory"),
            callback = function(comboBox, itemName, item, checked)
                AS.acwsv.searchSaveHistory = checked
            end,
            checked  = function() return AS.acwsv.searchSaveHistory end,
            entryType = LSM_ENTRY_TYPE_CHECKBOX,
        }
    }
    AddCustomScrollableSubMenuEntry(AddonSelector_GetLocalizedText("searchMenuStr"), searchOptionsSubmenu)

    --Add the auto reload pack after selection checkbox
    local cbAutoReloadUIindex = AddCustomScrollableMenuCheckbox(textures.reloadUITextureStr .. AddonSelector_GetLocalizedText("autoReloadUIHint"),
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "autoReloadUI")
            end,
            AS.acwsv.autoReloadUI)

    --Add the pack tooltip after autoRealoadUI checkbox
    local cbAddPackTooltipIndex = AddCustomScrollableMenuCheckbox(AddonSelector_GetLocalizedText("addPackTooltip"),
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "addPackTooltip")
            end,
            AS.acwsv.addPackTooltip)

    --Add the pack's addon list submenu after pack tooltip checkbox
    local cbShowPacksAddonListIndex = AddCustomScrollableMenuCheckbox(AddonSelector_GetLocalizedText("showPacksAddonList"),
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "showPacksAddonList")
            end,
            AS.acwsv.showPacksAddonList)

    --Show search header at the addon packs dropdown
    local cbShowSearchFilterAtPacksListIndex = AddCustomScrollableMenuCheckbox(AddonSelector_GetLocalizedText("showSearchFilterAtPacksList"),
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "showSearchFilterAtPacksList")
            end,
            AS.acwsv.showSearchFilterAtPacksList)

    --Automatically add missing dependency to the pack, if pack loads
    --AddCustomScrollableMenuCheckbox(text, callback, checked, additionalData)
    local cbAutoAddMissingDependencyAtPackLoad = AddCustomScrollableMenuCheckbox(AddonSelector_GetLocalizedText("autoAddMissingDependencyAtPackLoad"),
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "autoAddMissingDependencyAtPackLoad")
            end,
            AS.acwsv.autoAddMissingDependencyAtPackLoad)

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

        if areAllAddonsCurrentlyEnabled == true then
            local lastLoadedPackTime = ""
            lastLoadedPackTime = os.date("%c", lastLoadedPackData.timestamp)
            if lastLoadedPackCharName ~= "" and lastLoadedPackName ~= "" and lastLoadedPackTime ~= "" then
                --AddCustomScrollableMenuEntry(text, callback, entryType, entries, additionalData)
                AddCustomScrollableMenuHeader(AddonSelector_GetLocalizedText("LastPackLoaded"))
                AddCustomScrollableMenuEntry("[" .. outputColorCharStart .. tos(lastLoadedPackCharName) .. outputColorCharEnd .."]" .. outputColorStart .. tos(lastLoadedPackName) .. outputColorEnd ..  " (" .. tos(lastLoadedPackTime) ..")",
                        function()
                            --Set the pack to the dropddown box again
                            if packStillExistsAndIsSelectable == true then
                                AS.flags.doNotReloadUI = true
                                --Select the entry in the pack dropdown box now and activate the addons of the pack that way
                                --But do not reloadUI automatically!
                                local function evalFunc(entry)
                                    if entry.isCharacterPackHeader == false then
                                        if entry.name == lastLoadedPackName and entry.charName == lastLoadedPackCharNameReal then
                                            return true
                                        end
                                    end
                                    return false
                                end
                                AS.controls.ddl.m_comboBox:SetSelectedItemByEval(evalFunc, false) --do not ignore the callback -> run it!
                                AS.flags.doNotReloadUI = false
                            end
                        end, LSM_ENTRY_TYPE_NORMAL, nil, LSMadditionalData)
            end
        end
    end

    ShowCustomScrollableMenu(buttonCtrl, defaultSettingsContextMenuOptions)
end