local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonNamePrefix = AS.addonNamePrefix

local constants = AS.constants

local SEARCH_TYPE_NAME = constants.SEARCH_TYPE_NAME
local GLOBAL_PACK_NAME = constants.GLOBAL_PACK_NAME
local CHARACTER_PACK_CHARNAME_IDENTIFIER = constants.CHARACTER_PACK_CHARNAME_IDENTIFIER

local ZOsControls = constants.ZOsControls
local utility = AS.utility
local utilityOtherAddOns = utility.otherAddOns
local narration = AS.narration
local LSMconstants = constants.LSM
local colors = constants.colors
local textures = constants.textures
local flags = AS.flags
local otherAddonsFlags = AS.flags.otherAddons
local prefixStrings = constants.strings.prefixStrings
local constFunctions = constants.functions

local LSM_defaultAddonPackMenuOptions = LSMconstants.defaultAddonPackMenuOptions

local isAddonCategoryEnabled = utilityOtherAddOns.isAddonCategoryEnabled
local getAddonCategoryCategories = utilityOtherAddOns.getAddonCategoryCategories
local otherAddonData = AS.otherAddonsData


--local ADDON_MANAGER =         utility.GetAddonManager()
local ADDON_MANAGER_OBJECT =  utility.GetAddonManagerObject()

local AddonSelector_GetLocalizedText = AddonSelector_GetLocalizedText


--local currentCharIdNum = constants.currentCharIdNum
local currentCharId = constants.currentCharId
local currentCharName = constants.currentCharName
--local isExcludedFromChangeEnabledState = constants.isExcludedFromChangeEnabledState
local unregisterOldEventUpdater = utility.unregisterOldEventUpdater
local eventUpdateFunc = utility.eventUpdateFunc
local getKeybindingLSMEntriesForPacks = utility.getKeybindingLSMEntriesForPacks
local selectPreviouslySelectedPack = utility.selectPreviouslySelectedPack
local isAddonPackEnabledForAutoLoadOnLogout = utility.isAddonPackEnabledForAutoLoadOnLogout
local sortNonNumberKeyTableAndBuildSortedLookup = utility.sortNonNumberKeyTableAndBuildSortedLookup

local packNameGlobal = AddonSelector_GetLocalizedText("packGlobal")

--ZOs reference variables
local tos = tostring
local strfor = string.format
local tins = table.insert

local EM = EVENT_MANAGER


local addonCategoryCategories, addonCategoryIndices
--Local function references
local OnClickDDL, OnClick_Save, OnClick_Delete, OnClick_DeleteWholeCharacter


--======================================================================================================================
-- Create/update controls
--======================================================================================================================

------------------------------------------------------------------------------------------------------------------------
-- Control functions
------------------------------------------------------------------------------------------------------------------------
local function getOwnerPrefixStr(ownerCtrl)
    if not ownerCtrl or not ownerCtrl.GetName then return "" end
    return prefixStrings[ownerCtrl:GetName()] or ""
end
utility.getOwnerPrefixStr = getOwnerPrefixStr

local function onMouseEnterTooltip(ctrl)
    ZO_Tooltips_ShowTextTooltip(ctrl, TOP, ctrl.tooltipText)
end
local function onMouseExitTooltip()
    ZO_Tooltips_HideTextTooltip()
end

local function updateDDL(wasDeleted)
--d("[AS]updateDDL")
    AS.UpdateDDL(wasDeleted)
end
utility.updateDDL = updateDDL

local function updateEnableAllAddonsCtrls()
    ZOsControls.enableAllAddonsParent = ZOsControls.enableAllAddonsParent or GetControl("ZO_AddOnsList2Row1")
    if ZOsControls.enableAllAddonsParent == nil then return end
    ZOsControls.enableAllAddonsCheckboxCtrl = ZOsControls.enableAllAddonsCheckboxCtrl or GetControl(ZOsControls.enableAllAddonsParent, "Checkbox")
    ZOsControls.enableAllAddonTextCtrl = ZOsControls.enableAllAddonTextCtrl or GetControl(ZOsControls.enableAllAddonsParent, "Text")
end
AS.utility.updateEnableAllAddonsCtrls = updateEnableAllAddonsCtrls

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
        local activeUpdateControlEvents = AS.controls.controlData.activeUpdateControlEvents
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
utility.changeAddonControlName = changeAddonControlName

--Disable/Enable the delete button's enabled state depending on the autoreloadui after pack change checkbox state
local function ChangeDeleteButtonEnabledState(autoreloadUICheckboxState, skipStateCheck)
--d("[AddonSelector]ChangeDeleteButtonEnabledState-autoreloadUICheckboxState: " ..tos(autoreloadUICheckboxState) .. ", skipStateCheck: " ..tos(skipStateCheck))
    local deleteBtn = AS.controls.deleteBtn
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
utility.ChangeDeleteButtonEnabledState = ChangeDeleteButtonEnabledState

--Change the pack save buttons's enabled state
local function ChangeSaveButtonEnabledState(newEnabledState)
    newEnabledState = newEnabledState or false
    --Enable/Disable the "Save" button
    local saveButton = AS.controls.saveBtn
    if saveButton then
        saveButton:SetEnabled(newEnabledState)
        saveButton:SetMouseEnabled(newEnabledState)
    end
end
utility.ChangeSaveButtonEnabledState = ChangeSaveButtonEnabledState

local function updateSaveModeTexure(doShow)
    AS.controls.saveModeTexture:SetHidden(not doShow)
    ADDON_MANAGER_OBJECT:RefreshVisible()
end
utility.updateSaveModeTexure = updateSaveModeTexure

local function updateAutoReloadUITexture(doShow)
    AS.controls.autoReloadUITexture:SetHidden(not doShow)
    ADDON_MANAGER_OBJECT:RefreshVisible()
end
utility.updateAutoReloadUITexture = updateAutoReloadUITexture

local function clearAndUpdateDDL(wasDeleted)
--d("[AddonSelector]clearAndUpdateDDL - wasDeleted: " ..tos(wasDeleted))
    updateDDL(wasDeleted)
    AS.controls.editBox:Clear()
    --Disable the "delete pack" button
    ChangeDeleteButtonEnabledState(nil, false)
end
utility.clearAndUpdateDDL = clearAndUpdateDDL

--Helper functions
--OnMouseUp event for the selected pack name label
local function OnClick_SelectedPackNameLabel(selfVar, button, upInside, ctrl, alt, shift, command)
--d("[AddonSelector]OnClick_SelectedPackNameLabel")
    if not upInside or button ~= MOUSE_BUTTON_INDEX_LEFT or not AS.controls.editBox then return end
    --Set the "name edit" to the currently selected addon pack entry so you just need to hit the save button afterwards
    local currentlySelectedPacknamesForChars = AS.acwsv.selectedPackNameForCharacters
    if not currentlySelectedPacknamesForChars then return end
    local currentCharactersSelectedPackNameData = currentlySelectedPacknamesForChars[currentCharId] --currentCharIdNum changed to String at 15.07.2022, 00:30am
    if currentCharactersSelectedPackNameData and currentCharactersSelectedPackNameData.packName ~= "" then
        AS.controls.editBox:Clear()
        AS.controls.editBox:SetText(currentCharactersSelectedPackNameData.packName)
    end
end

--Update the currently selected packName label
local function UpdateCurrentlySelectedPackName(wasDeleted, packName, packData, isCharacterPack)
--d("[AS]UpdateCurrentlySelectedPackName-wasDeleted: " ..tos(wasDeleted) .. ", packName: " .. tos(packName) .. ", charName: " .. tos(packData ~= nil and packData.charName) .. ", isCharacterPack: " .. tos(isCharacterPack))
    wasDeleted = wasDeleted or false
    local packNameLabel =AS.controls.selectedPackNameLabel
    if not packNameLabel then return end
    local savePackPerCharacter = AS.acwsv.saveGroupedByCharacterName

    local currentlySelectedPackName
    local currentlySelectedPackCharName
    local currentCharacterId = currentCharId
    if packName == nil or packName == "" or packData == nil then
--d(">2")
        local currentlySelectedPackNameData
        currentCharacterId, currentlySelectedPackNameData = utility.getCurrentCharsPackNameData()
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
        packNameText = strfor(AddonSelector_GetLocalizedText("selectedPackName"), strfor(colors.charNamePackColorTemplate, currentlySelectedPackCharName))
        packNameText = packNameText .. currentlySelectedPackName
        packNameLabel:SetText(packNameText)

        if not wasDeleted then
            AS.currentlySelectedPackData = AS.comboBox:GetSelectedItemData()
        end
    end
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
        AS.SetCurrentCharacterSelectedPackname(addonPackName, addonPackData, isCharacterPack)
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
AS.onAddonPackSelected = onAddonPackSelected

-- When an item is selected in the comboBox go through all available
-- addons & compare them against the selected addon pack.
-- Enable all addons that are in the selected addon pack, disable the rest.
-->Called by ItemSelectedClickHelper of the dropdown box entries/items
function OnClickDDL(comboBox, packName, packData, selectionChanged, oldItem, forAllCharsTheSame) --comboBox, itemName, item, selectionChanged, oldItem
--[[
    AddonSelector._onClickDDlData = {
        comboBox = comboBox,
        packName = packName,
        packData = packData,
        selectionChanged = selectionChanged,
        oldItem = oldItem,
    }
]]
--d("OnClickDDL-packName: " ..tos(packName) .. ", doNotReloadUI: " ..tos(AS.flags.doNotReloadUI) ..", autoReloadUI: " ..tos(AddonSelector.acwsv.autoReloadUI))
    if AS.flags.preventOnClickDDL == true then AS.flags.preventOnClickDDL = false return end
    AS.loadAddonPack(packName, packData, forAllCharsTheSame, false)
end


------------------------------------------------------------------------------------------------------------------------
-- AddonSelector
------------------------------------------------------------------------------------------------------------------------
--Create the AddonSelector control, set references to controls
-- and click handlers for the save/delete buttons
function AS.CreateControlReferences()
    utility.updateEnableAllAddonsCtrls()

    local settings                         = AS.acwsv
    -- Create Controls:
    local addonSelector                    = CreateControlFromVirtual(ADDON_NAME, ZOsControls.ZOAddOns, "AddonSelectorVirtualTemplate", nil)

    -- Assign references:
    AS.controls.addonSelectorControl       = addonSelector
    addonSelector._AddonSelectorObject = AS

    AS.controls.ddl                                 = addonSelector:GetNamedChild("ddl") --<Control name="$(parent)ddl" inherits="ZO_ComboBox" mouseEnabled="true" >
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
    local ASDropdownScrollHelper = AddCustomScrollableComboBoxDropdownMenu(addonSelector, AS.controls.ddl, LSM_defaultAddonPackMenuOptions) --Entries will be added at AddonSelector.UpdateDDL(wasDeleted)
    AS.controls.ddl.scrollHelper           = ASDropdownScrollHelper
    --For debugging
    AS.LSM_scrollHelpers = {
        ddl = ASDropdownScrollHelper
    }

    AS.comboBox                            = AS.controls.ddl.m_comboBox
    local savedPacksComboBox               = AS.comboBox

    AS.controls.editBox                             = addonSelector:GetNamedChild("EditBox")

    AS.controls.saveBtn                             = addonSelector:GetNamedChild("Save")
    AS.controls.deleteBtn                           = addonSelector:GetNamedChild("Delete")
    --AddonSelector.autoReloadBtn = addonSelector:GetNamedChild("AutoReloadUI")
    --AddonSelector.autoReloadLabel = AddonSelector.autoReloadBtn:GetNamedChild("Label")
    AS.controls.settingsOpenDropdown                = addonSelector:GetNamedChild("SettingsOpenDropdown")
    AS.controls.settingsOpenDropdown.onClickHandler = AS.controls.settingsOpenDropdown:GetHandler("OnClicked")
    --PerfectPixel: Reposition of the settings "gear" icon -> move up to other icons (like Votans Addon List)
    AS.controls.settingsOpenDropdown:ClearAnchors()
    --<Anchor point="TOPLEFT" relativeTo="ZO_AddOns" relativePoint="TOP" offsetX="100" offsetY="65"/>
    local offsetX = 100
    local offsetY = 65
    AS.controls.settingsOpenDropdown:SetAnchor(TOPLEFT, ZOsControls.ZOAddOns, TOP, offsetX, offsetY)

    AS.controls.searchBox = addonSelector:GetNamedChild("SearchBox")
    AS.controls.searchBox:SetHandler("OnMouseUp", function(selfCtrl, mouseButton, isUpInside)
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
                            AS.openGameMenuAndAddOnsAndThenSearch(searchTerm, true, false)
                            ClearMenu()
                        end)
                    end
                    AddCustomMenuItem("-", function() end)
                    AddCustomMenuItem(AddonSelector_GetLocalizedText("searchClearHistory"), function()
                        utility.clearSearchHistory(searchType)
                        ClearMenu()
                    end)
                    doShowMenu = true
                    searchHistoryWasAdded = true
                end
            end
            --AddonCategory support
            if isAddonCategoryEnabled() == true then
                getAddonCategoryCategories()
                local addonCategoryCategories = otherAddonData.addonCategoryCategories
                if not ZO_IsTableEmpty(addonCategoryCategories) then
                    if not searchHistoryWasAdded then
                        ClearMenu()
                    else
                        AddCustomMenuItem(AddonSelector_GetLocalizedText("addonCategories"), function() end, MENU_ADD_OPTION_HEADER)
                    end
                    for _, searchTerm in ipairs(addonCategoryCategories) do
                        AddCustomMenuItem(searchTerm, function()
                            AS.OpenGameMenuAndAddOnsAndThenSearch(searchTerm, true, true)
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
                local narrateText = AddonSelector_GetLocalizedText("searchMenuStr")
                if currentText == "" then
                    narrateText = AddonSelector_GetLocalizedText("searchInstructions")
                else
                    narrateText = "["..narrateText .. "]  " .. currentText
                end
                narration.OnUpdateDoNarrate("OnAddonSearchLeftClicked", 0, function() narration.AddNewChatNarrationText(narrateText, true)  end)
            end
        end
    end)
    AS.controls.searchLabel = addonSelector:GetNamedChild("SearchBoxLabel")
    AS.controls.searchLabel:SetText(AddonSelector_GetLocalizedText("AddonSearch"))
    AS.controls.selectedPackNameLabel = addonSelector:GetNamedChild("SelectedPackNameLabel")

    AS.controls.saveModeTexture       = addonSelector:GetNamedChild("SaveModeTexture")
    AS.controls.saveModeTexture:SetTexture("/esoui/art/characterselect/gamepad/gp_characterselect_characterslots.dds")
    AS.controls.saveModeTexture:SetColor(colors.charNamePackColorDef:UnpackRGBA())
    AS.controls.saveModeTexture:SetMouseEnabled(true)
    AS.controls.saveModeTexture.tooltipText = AddonSelector_GetLocalizedText("SaveGroupedByCharacterName")
    AS.controls.saveModeTexture:SetHandler("OnMouseEnter", onMouseEnterTooltip)
    AS.controls.saveModeTexture:SetHandler("OnMouseExit", onMouseExitTooltip)

    AS.controls.autoReloadUITexture = addonSelector:GetNamedChild("AutoReloadUITexture")
    AS.controls.autoReloadUITexture:SetTexture(textures.reloadUITexture)
    AS.controls.autoReloadUITexture:SetColor(1, 0, 0, 0.6)
    AS.controls.autoReloadUITexture:SetMouseEnabled(true)
    AS.controls.autoReloadUITexture.tooltipText = AddonSelector_GetLocalizedText("autoReloadUIHint")
    AS.controls.autoReloadUITexture:SetHandler("OnMouseEnter", onMouseEnterTooltip)
    AS.controls.autoReloadUITexture:SetHandler("OnMouseExit", onMouseExitTooltip)

    -- Set Saved Btn State for checkbox "Auto reloadui after pack selection"
    local checkedState = settings.autoReloadUI
    utility.updateAutoReloadUITexture(checkedState)
    --AddonSelector.autoReloadBtn:SetState(checkedState)
    --Disable the "save pack" button
    utility.ChangeSaveButtonEnabledState(false)
    --Disable the "delete pack" button
    utility.ChangeDeleteButtonEnabledState(checkedState)
    --Show the currently selected pack name for the logged in character
    UpdateCurrentlySelectedPackName(nil, nil, nil)


    --Change the description texts
    AddonSelectorNameLabel:SetText(AddonSelector_GetLocalizedText("packName"))
    AddonSelectorSave:SetText(AddonSelector_GetLocalizedText("saveButton"))
    AddonSelectorSelectLabel:SetText(AddonSelector_GetLocalizedText("selectPack") .. ":")
    AddonSelectorDelete:SetText(AddonSelector_GetLocalizedText("deleteButton"))

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
    AS.controls.saveBtn:SetHandler("OnMouseUp", function(ctrl) OnClick_Save() end)
    AS.controls.deleteBtn:SetHandler("OnMouseUp", function() OnClick_Delete(nil, true) end)
    --AddonSelector.autoReloadBtn:SetHandler("OnMouseUp", OnClick_AutoReload)
    --AddonSelector.autoReloadBtn:SetHandler("OnMouseEnter", OnMouseEnter)
    --AddonSelector.autoReloadBtn:SetHandler("OnMouseExit", OnMouseExit)
    --AddonSelector.autoReloadLabel:SetHandler("OnMouseUp", OnClick_AutoReloadLabel)
    --AddonSelector.autoReloadLabel:SetHandler("OnMouseEnter", OnMouseEnter)
    --AddonSelector.autoReloadLabel:SetHandler("OnMouseExit", OnMouseExit)
    AS.controls.settingsOpenDropdown:SetHandler("OnMouseEnter", OnMouseEnter)
    AS.controls.settingsOpenDropdown:SetHandler("OnMouseExit", OnMouseExit)
    AS.controls.selectedPackNameLabel:SetHandler("OnMouseUp", OnClick_SelectedPackNameLabel)


    SecurePostHook(savedPacksComboBox, "ShowDropdownInternal", function(comboBoxCtrl)
        local currentSelectedEntryText = savedPacksComboBox.currentSelectedItemText
        narration.OnUpdateDoNarrate("OnSavedPackDropdown", 50, function() narration.AddNewChatNarrationText("["..AddonSelector_GetLocalizedText("openedStr").."]   -   " .. currentSelectedEntryText, true)  end)
    end)
    --[[
    SecurePostHook(savedPacksComboBox, "HideDropdownInternal", function(comboBoxCtrl)
        local currentSelectedEntryText = savedPacksComboBox.currentSelectedItemText
        OnUpdateDoNarrate("OnSavedPackDropdown", 100, function() narration.AddNewChatNarrationText("["..AddonSelector_GetLocalizedText("closedStr").."]   -   " .. currentSelectedEntryText, false)  end)
    end)
    ]]

    AS.controls.addonSelectorSelectAddonsButtonNameLabel = AddonSelectorSelectAddonsButton.nameLabel --GetControl(AddonSelectorSelectAddonsButton, "NameLabel")
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
    primaryButton:ClearAnchors()
    primaryButton:SetAnchor(TOPRIGHT, ZOsControls.ZOAddOnsList, BOTTOMRIGHT, 0, 15)

    selectAllButton:ClearAnchors()
    selectAllButton:SetAnchor(TOPLEFT, deSelectAllButton, BOTTOMLEFT, 0, 0)
    --Toggle Addon On/Off button
    toggleStateButton:ClearAnchors()
    toggleStateButton:SetAnchor(TOPLEFT, deSelectAllButton, TOPRIGHT, 5, 0)

    --Start addon search button
    startAddonSearchButton:SetText(AddonSelector_GetLocalizedText("searchMenuStr"))
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

        narration.onMouseEnterDoNarrate(advancedUIErrorsLabel)
        narration.onMouseEnterDoNarrate(advancedUIErrors)
        ZO_PostHookHandler(advancedUIErrors, "OnMouseUp", function(ctrl, button, upInside)
            if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
                narration.OnControlClickedNarrate(ctrl, true)
            end
        end)
        ZO_PostHookHandler(advancedUIErrorsLabel, "OnMouseUp", function(ctrl, button, upInside)
            if upInside and button == MOUSE_BUTTON_INDEX_LEFT then
                narration.OnControlClickedNarrate(ctrl, true)
            end
        end)
    end
end
AS.OnShow_HideStuff = AddonSelectorOnShow_HideStuff


------------------------------------------------------------------------------------------------------------------------
--LSM submenu update addons in pack
------------------------------------------------------------------------------------------------------------------------
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
    local currentSvPackDataTable = AS.getSVTableForPackBySavedType(p_character)
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
    d(string.format(addonNamePrefix .. AddonSelector_GetLocalizedText("changedAddonPack"), tos(p_packName), tos((p_character == GLOBAL_PACK_NAME) and packNameGlobal or (AddonSelector_GetLocalizedText("packCharName") .. ": " .. p_character)), tos(addonsChanged)))
    if addonsChanged > 0 then
        updateDDL()
        --Disable the saved button's enabled state
        ChangeSaveButtonEnabledState(false)
        --Disable the "delete pack" button
        ChangeDeleteButtonEnabledState(nil, false)
    end
end


------------------------------------------------------------------------------------------------------------------------
-- AddonSelector - Layout changes
------------------------------------------------------------------------------------------------------------------------
-- Used to change the layout of the Addon scrollList to
-- make room for the AddonSelector control
function AS.ChangeLayout()
	--Make the addons manager not movable outside of the screen, same for the keybindings etc. below
    local controlsToSetClampedToScreen = ZOsControls.controlsToSetClampedToScreen
    for _, ctrl in ipairs(controlsToSetClampedToScreen) do
        if ctrl then ctrl:SetClampedToScreen(true) end
    end


    --local template = ZO_AddOns
	--local divider = ZO_AddOnsDivider
	local list = ZOsControls.ZOAddOnsList
	--local bg = ZO_AddonsBGLeft
	list:ClearAnchors()
	list:SetAnchor(TOPLEFT, AS.controls.addonSelectorControl, BOTTOMLEFT, 0, 10)
	-- This does not work ?? Items get cut off.
	list:SetAnchor(BOTTOMRIGHT, ZOsControls.ZOAddOns, BOTTOMRIGHT, -20, -50)
	--list:SetDimensions(885, 560)
	--ZO_ScrollList_SetHeight(list, 600)
	ZO_ScrollList_Commit(list)
end


------------------------------------------------------------------------------------------------------------------------
-- AddonSelector - Dropdown List (DDL)
------------------------------------------------------------------------------------------------------------------------
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
        autoReloadUISuffix = textures.reloadUITextureStr
        autoReloadUISuffixSubmenu = " & " .. AddonSelector_GetLocalizedText("reloadUIStr")
    end

    --Character IDs and names at the @account
    --local charactersOfAccount = AS.charactersOfAccount
    --local characterIdsOfAccount = AS.characterIdsOfAccount
    --local characterCount = NonContiguousCount(AddonSelector.charactersOfAccount)

    --Build the lookup tables for libraries
    utility.BuildAddOnReverseLookUpTable()
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
        local itemDataCharacterPackHeader = AS.createItemEntry(AddonSelector_GetLocalizedText("packNameCharacter"), nil, nil, false, nil, "[" .. tostring(megaServer) .. "]" .. AddonSelector_GetLocalizedText("characterWides"),
                nil, false, true)
        tins(packTable, itemDataCharacterPackHeader)


        --Sort the character addon packs by their pack name
        local addonPacksOfChar = settings.addonPacksOfChar
        local addonPacksOfAllCharsSortedLookup = sortNonNumberKeyTableAndBuildSortedLookup(addonPacksOfChar)

        for _, charId in ipairs(addonPacksOfAllCharsSortedLookup) do
            local isCharOfCurrentAcc = AS.charactersOfAccount[charId] or false

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
                                            name    = AddonSelector_GetLocalizedText("saveChangesNow"),
                                            callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                                                --d("[AS]Save changes to charName: " .. tos(packNameGlobal) .. ", packName: " ..tos(packName))
                                                --As the clicked nested submenu entry will select this entry -> Clear the selection now
                                                --utility.unselectAnyPack()

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
                                        local addonsInPackText = string.format(AddonSelector_GetLocalizedText("addonsInPack") .. " - #" .. colors.numAddonsColorTemplate.."/%s", packNameOfChar, tos(numOnlyAddOnsInSubmenuPack), tos(numAddonsInSubmenuPack)) .. " [" .. AddonSelector_GetLocalizedText("singleCharNameColoredStr") .. ": " .. charName .. "]"
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
                                        local addonsInPackTextNotEnabled = string.format("["..AddonSelector_GetLocalizedText("disabledRed").."]" .. AddonSelector_GetLocalizedText("addonsInPack") .. " - #" .. colors.numAddonsColorTemplate .. "/%s", packNameOfChar, tos(numDisabledAddonsInSubmenuPack), tos(numAddonsInSubmenuPack))
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
                                                label    = addonNameOfGlobalPackSorted .. " (" .. AddonSelector_GetLocalizedText("disabledRed") .. ")",
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
                                        local addonsInPackTextMissing = string.format("["..AddonSelector_GetLocalizedText("missing").."]"..AddonSelector_GetLocalizedText("addonsInPack") .. " - #" .. colors.numAddonsColorTemplate .. "/%s", packNameOfChar, tos(numMissingAddonsInSubmenuPack), tos(numAddonsInSubmenuPack))
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
                                        local librariesInPackText = string.format(AddonSelector_GetLocalizedText("librariesInPack") .. " - #" .. colors.numLibrariesColorTemplate .. "/%s", packNameOfChar, tos(numLibrariesInSubmenuPack), tos(numAddonsInSubmenuPack))
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
                                        local librariesInPackTextNotEnabled = string.format("["..AddonSelector_GetLocalizedText("disabledRed").."]" .. AddonSelector_GetLocalizedText("librariesInPack") .. " - #" .. colors.numLibrariesColorTemplate .. "/%s", packNameOfChar, tos(numDisabledLibrariesInSubmenuPack), tos(numAddonsInSubmenuPack))
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
                                                label   = addonNameOfGlobalPackSorted .. " (" .. AddonSelector_GetLocalizedText("disabledRed") .. ")",
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
                                        local librariesInPackTextMissing = string.format("["..AddonSelector_GetLocalizedText("missing").."]" .. AddonSelector_GetLocalizedText("librariesInPack") .. " - #" .. colors.numLibrariesColorTemplate.."/%s", packNameOfChar, tos(numMissingLibrariesInSubmenuPack), tos(numAddonsInSubmenuPack))
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
                                        and (AddonSelector_GetLocalizedText("enabledAddonsInPack") .. "\n'" ..
                                        packNameOfChar .. "': " ..tos(numAddonsInSubmenuPack) .. "\n" ..
                                        AddonSelector_GetLocalizedText("addons") .. ": " .. tos(numOnlyAddOnsInSubmenuPack) ..
                                        ((numDisabledAddonsInSubmenuPack > 0 and "\n" .. AddonSelector_GetLocalizedText("disabledRed").. "': " ..tos(numDisabledAddonsInSubmenuPack)) or "") ..
                                        ((numMissingAddonsInSubmenuPack > 0 and "\n" .. AddonSelector_GetLocalizedText("missing") .. "': " ..tos(numMissingAddonsInSubmenuPack)) or "")
                                )
                                ) or nil
                                if numLibrariesInSubmenuPack > 0 and tooltipCharPack ~= nil then
                                    tooltipCharPack = tooltipCharPack ..
                                            "\n" .. librariesStr .. ": " .. tos(numLibrariesInSubmenuPack) ..
                                            ((numDisabledLibrariesInSubmenuPack > 0 and "\n" .. AddonSelector_GetLocalizedText("disabledRed").. "': " ..tos(numDisabledLibrariesInSubmenuPack)) or "") ..
                                            ((numMissingLibrariesInSubmenuPack > 0 and "\n" .. AddonSelector_GetLocalizedText("missing") .. "': " ..tos(numMissingLibrariesInSubmenuPack)) or "")
                                end

                                tins(nestedSubmenuEntriesOfCharPack, {
                                    name = packNameOfChar,
                                    label = AddonSelector_GetLocalizedText("selectPack") .. autoReloadUISuffixSubmenu .. ": " .. packNameOfChar,
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
                                        label   = AddonSelector_GetLocalizedText("selectPack") .. " & " .. AddonSelector_GetLocalizedText("reloadUIStr") .. ": " .. packNameOfChar,
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
                                    label = AddonSelector_GetLocalizedText("deletePackTitle") .. " " .. packNameOfChar,
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
                                    label    = string.format(AddonSelector_GetLocalizedText("OverwriteSavePack"), packNameOfChar),
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
                                    name    = AddonSelector_GetLocalizedText("loadOnLogoutOrQuit"),
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
                                    tins(iconData, { iconTexture=textures.autoLoadOnLogoutTexture, iconTint=not skipAutoLoadPackAtLogout and "00FF22" or "FF0000", tooltip=AddonSelector_GetLocalizedText("loadOnLogoutOrQuit") })
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
                            AddCustomScrollableMenuEntry(AddonSelector_GetLocalizedText("deleteWholeCharacterPacksTitle"), function() OnClick_DeleteWholeCharacter(charId) end, LSM_ENTRY_TYPE_NORMAL)
                            ShowCustomScrollableMenu(nil, LSMconstants.LSM_defaultContextMenuOptions)
                        end
                    end

                    --packName, label, addonTable, isCharacterPack, charName, tooltip, entriesSubmenu, isSubmenuMainEntry, isHeader, iconData, contextMenuCallbackFunc
                    local itemCharData = AS.createItemEntry(charName .. ((not isCharOfCurrentAcc and " " .. AddonSelector_GetLocalizedText("otherAccount")) or ""), label, addonPacks, true,
                            charName, "[" .. tostring(megaServer) .. "]"..AddonSelector_GetLocalizedText("characterWide")..": \'" ..tostring(charName) .. "\' (ID: " .. tostring(charId)..")",
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
        local itemDataGlobalPackHeader = AS.createItemEntry(packNameGlobal, nil, nil, false, nil, "[" .. tostring(megaServer) .. "]" .. AddonSelector_GetLocalizedText("accountWides"),
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
                        name    = AddonSelector_GetLocalizedText("saveChangesNow"),
                        callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                            --d("[AS]Save changes to charName: " .. tos(packNameGlobal) .. ", packName: " ..tos(packName))
                            --As the clicked nested submenu entry will select this entry -> Clear the selection now
                            --utility.unselectAnyPack()

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
                    local addonsInPackText = string.format(AddonSelector_GetLocalizedText("addonsInPack") .. " - #" .. colors.numAddonsColorTemplate.."/%s", packName, tos(#addonTableSortedAddons), tos(numAddonsInGlobalPack)) .. " [" .. packNameGlobal .. "]"
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
                    local addonsInPackTextNotEnabled = string.format("["..AddonSelector_GetLocalizedText("disabledRed").."]" .. AddonSelector_GetLocalizedText("addonsInPack") .. " - #" .. colors.numAddonsColorTemplate .. "/%s", packName, tos(numDisabledAddonsInGlobalPack), tos(numAddonsInGlobalPack))
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
                            label    = addonNameOfGlobalPackSorted .. " (" .. AddonSelector_GetLocalizedText("disabledRed") .. ")",
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
                    local addonsInPackTextMissing = string.format("["..AddonSelector_GetLocalizedText("missing").."]"..AddonSelector_GetLocalizedText("addonsInPack") .. " - #" .. colors.numAddonsColorTemplate .. "/%s", packName, tos(numMissingAddonsInGlobalPack), tos(numAddonsInGlobalPack))
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
                    local librariesInPackText = string.format(AddonSelector_GetLocalizedText("librariesInPack") .. " - #" .. colors.numLibrariesColorTemplate .. "/%s", packName, tos(#addonTableSortedLibraries), tos(numAddonsInGlobalPack))
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
                    local librariesInPackTextNotEnabled = string.format("["..AddonSelector_GetLocalizedText("disabledRed").."]" .. AddonSelector_GetLocalizedText("librariesInPack") .. " - #" .. colors.numLibrariesColorTemplate .. "/%s", packName, tos(numDisabledLibrariesInGlobalPack), tos(numAddonsInGlobalPack))
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
                            label   = addonNameOfGlobalPackSorted .. " (" .. AddonSelector_GetLocalizedText("disabledRed") .. ")",
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
                    local librariesInPackTextMissing = string.format("["..AddonSelector_GetLocalizedText("missing").."]" .. AddonSelector_GetLocalizedText("librariesInPack") .. " - #" .. colors.numLibrariesColorTemplate.."/%s", packName, tos(numMissingLibrariesInGlobalPack), tos(numAddonsInGlobalPack))
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
                    and (AddonSelector_GetLocalizedText("enabledAddonsInPack") .. "\n'" ..
                        packName .. "': " ..tos(numAddonsInGlobalPack) .. "\n" ..
                        AddonSelector_GetLocalizedText("addons") .. ": " .. tos(numOnlyAddOnsInGlobalPack) ..
                        ((numDisabledAddonsInGlobalPack > 0 and "\n" .. AddonSelector_GetLocalizedText("disabledRed").. "': " ..tos(numDisabledAddonsInGlobalPack)) or "") ..
                        ((numMissingAddonsInGlobalPack > 0 and "\n" .. AddonSelector_GetLocalizedText("missing") .. "': " ..tos(numMissingAddonsInGlobalPack)) or "")
                    )
                ) or nil
                if numLibrariesInGlobalPack > 0 and tooltipStr ~= nil then
                    tooltipStr = tooltipStr ..
                    "\n" .. librariesStr .. ": " .. tos(numLibrariesInGlobalPack) ..
                    ((numDisabledLibrariesInGlobalPack > 0 and "\n" .. AddonSelector_GetLocalizedText("disabledRed").. "': " ..tos(numDisabledLibrariesInGlobalPack)) or "") ..
                    ((numMissingLibrariesInGlobalPack > 0 and "\n" .. AddonSelector_GetLocalizedText("missing") .. "': " ..tos(numMissingLibrariesInGlobalPack)) or "")
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
                    label   = AddonSelector_GetLocalizedText("selectPack") .. " & " .. AddonSelector_GetLocalizedText("reloadUIStr") .. ": " .. packName,
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
                label    = AddonSelector_GetLocalizedText("deletePackTitle") .. " " .. packName,
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
                label    = string.format(AddonSelector_GetLocalizedText("OverwriteSavePack"), packName),
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
                name    = AddonSelector_GetLocalizedText("loadOnLogoutOrQuit"),
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

            local iconData = (autoReloadUI == true and { iconTexture=textures.reloadUITexture, iconTint="FF0000", tooltip=AddonSelector_GetLocalizedText("reloadUIStrWithoutIcon") }) or nil
            if not ZO_IsTableEmpty(keybindIconData) then
                iconData = iconData or {}
                for _, v in ipairs(keybindIconData) do
                    --tins(iconData, v)
                    label = label .. v.iconTexture
                end
            end

            local enabledAddonsInPackStrAddition = (addPackTooltip == true and numAddonsInGlobalPack ~= nil and ("\n" .. AddonSelector_GetLocalizedText("enabledAddonsInPack") .. ": " ..tos(numAddonsInGlobalPack))) or ""

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
                            local callbackFunc = submenuEntryData.callback ~= nil and function(...) return submenuEntryData.callback(...) end or ((entryType == LSM_ENTRY_TYPE_HEADER and nil) or constFunctions.defaultCallbackFunc)
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
                        ShowCustomScrollableMenu(nil, LSMconstants.LSM_defaultContextMenuOptions)
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
                tins(iconData, { iconTexture=textures.autoLoadOnLogoutTexture, iconTint=not skipAutoLoadPackAtLogout and "00FF22" or "FF0000", tooltip=AddonSelector_GetLocalizedText("loadOnLogoutOrQuit") })
            end

            --CreateItemEntry(packName, addonTable, isCharacterPack, charName, tooltip, entriesSubmenu, isSubmenuMainEntry, isHeader)
            local itemGlobalData = AS.createItemEntry(packName, label, addonTable, false, GLOBAL_PACK_NAME, "[" .. tostring(megaServer) .. "]"..AddonSelector_GetLocalizedText("accountWide").." \'" ..packName.."\'" .. enabledAddonsInPackStrAddition,
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

local function OnClick_SaveDo(wasPackNameProvided, packName, characterName)
    wasPackNameProvided = wasPackNameProvided or false
    if wasPackNameProvided == false then
        packName = AS.controls.editBox:GetText()
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
        AS.saveAddonsAsPackToSV(packName, false, characterName, wasPackNameProvided)

        clearAndUpdateDDL()
    else
        --Get SavedVariables table for the pack and update the pack there
        local svForPack = AS.saveAddonsAsPackToSV(packName, false, nil, false)
        -- Create a temporary copy of the itemEntry data so we can select it
        -- after the ddl is updated
        local savePackPerCharacter = AS.acwsv.saveGroupedByCharacterName
        --CreateItemEntry(packName, addonTable, isCharacterPack, charName, tooltip, entriesSubmenu, isSubmenuMainEntry, isHeader)
        local itemData = createItemEntry(packName, nil, svForPack, false, (savePackPerCharacter and currentCharName) or GLOBAL_PACK_NAME, nil, nil, nil, true)

        clearAndUpdateDDL()
        --Prevent reloadui for a currently new saved addon pack!
        AS.flags.doNotReloadUI = true
        AS.comboBox:SelectItem(itemData)
        AS.flags.doNotReloadUI = false

        --Disable the "save pack" button
        ChangeSaveButtonEnabledState(true)
    end
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
        newPackName = AS.controls.editBox:GetText()
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
            svTableOfCurrentChar, charName = AS.getSVTableForPacks(characterName)
        else
            svTableOfCurrentChar, charName = AS.getSVTableForPacks()
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
        utility.ShowConfirmationDialog("SaveAddonPackDialog",
                (AddonSelector_GetLocalizedText("savePackTitle")) .. "\n" ..
                        "[".. (saveGroupedByChar and strfor(colors.charNamePackColorTemplate, packCharacter) or packCharacter) .. "]\n" .. newPackName,
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

local function OnClick_DeleteDo(itemData, charId, beforeSelectedPackData, buttonWasPressed)
    buttonWasPressed = buttonWasPressed or false
    if not itemData then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, AddonSelector_GetLocalizedText("deletePackAlert"))
        return
    end
    local function deleteError(reason)
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, strfor(AddonSelector_GetLocalizedText("deletePackError"), reason))
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
    local charactersOfAccount = AS.charactersOfAccount
    --local characterIdsOfAccount = AS.characterIdsOfAccount
    local charName = charactersOfAccount[characterId]
    if charName == nil then
        --Do not show packs of other accounts -> So the charname must be in current account chars list!
        if not AS.acwsv.showPacksOfOtherAccountsChars then
            return
        end
    end
    local svTable, charId, characterName = AS.getSVTableForPacksOfCharname(charName, characterId)
    if svTable ~= nil and charId ~= nil and characterName ~= nil then
        if NonContiguousCount(svTable) == 1 then return end --only _charName entry is in there!
        --Hide the dropdown
        ClearCustomScrollableMenu()
        AS.comboBox:HideDropdown()
        --Show security dialog
        utility.ShowConfirmationDialog("DeleteCharacterPacksDialog",
                    AddonSelector_GetLocalizedText("deleteWholeCharacterPacksTitle") .. "\n[" .. characterName .. "]",
                    AddonSelector_GetLocalizedText("deleteWholeCharacterPacksQuestion"),
                    function() OnClick_DeleteWholeCharacterDo(characterName, charId) end,
                    function() end,
                    nil,
                    nil,
                    true
            )
    end
end

-- When delete is clicked, remove the selected addon pack
function OnClick_Delete(itemData, buttonWasPressed)
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
        svTable = AS.getSVTableForPacks()
        charId = (charName ~= GLOBAL_PACK_NAME and currentCharId) or nil
    else
        svTable, charId = AS.getSVTableForPacksOfCharname(charName, nil)
    end
    if not svTable then return end

--d(">charName: " ..tos(charName) .. ", charId: " ..tos(charId))

    local packCharName
    if charName ~= GLOBAL_PACK_NAME then packCharName = charName end
    local selectedPackName = itemData.name
    --ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
    local addonPackName = "\'" .. selectedPackName .. "\'"
    local deletePackQuestion = strfor(AddonSelector_GetLocalizedText("deletePackBody"), tos(addonPackName))
    utility.ShowConfirmationDialog("DeleteAddonPackDialog",
            (AddonSelector_GetLocalizedText("deletePackTitle")) .. "\n[" .. (packCharName and strfor(colors.charNamePackColorTemplate, packCharName) or packNameGlobal) .. "]\n" .. selectedPackName,
            deletePackQuestion,
            function() OnClick_DeleteDo(itemData, charId, currentlySelectedPackData, buttonWasPressed) end,
            function() OnAbort_Do(false, true, itemData, charId, currentlySelectedPackData) end,
            nil,
            nil,
            true
    )
end