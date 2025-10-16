--[[
------------------------------------------------------------------------------------------------------------------------
 Changelog
------------------------------------------------------------------------------------------------------------------------
2025-10-15
AddonSelector v3.00


------------------------------------------------------------------------------------------------------------------------
 Known bugs - Max: 16
------------------------------------------------------------------------------------------------------------------------

Feature requests:
20251010 - #16 Add missing dependencies (e.g. new added to addons) automatically to loaded packs (maybe show a popup informing the user about it)
20251010 - Show missing (non installed) dependencies, of all addons, at a collapsible UI at the addon manager

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
]]

local AS = AddonSelectorGlobal

--Addon internal variables
local ADDON_NAME = AS.name
local addonNamePrefix = AS.addonNamePrefix

local constants = AS.constants
local utility = AS.utility
local narration = AS.narration
local stringConstants = constants.strings
local SEARCH_TYPE_NAME = constants.SEARCH_TYPE_NAME

--Flags
local flags = AS.flags


--Object variables
local ADDON_MANAGER
local ADDON_MANAGER_OBJECT
local ZOsControls = constants.ZOsControls

--Keybinds
local keybindTexturesLoadPack = constants.keybinds.keybindTexturesLoadPack

--ZOs reference variables
local EM = EVENT_MANAGER
local SM = SCENE_MANAGER


local tos = tostring
local strfor = string.format
local strlow = string.lower
local strsub = string.sub
local zopsf = zo_plainstrfind
local gTab = table
local tins = gTab.insert
--local trem = gTab.remove
local tsor = gTab.sort



--Local function references
local OnClick_Save, OnClick_DeleteWholeCharacter, AddonSelectorUpdateCount, getKeybindingLSMEntriesForPacks

--Local speed-up reference variables
local enableAllAddonsCheckboxHooked = false



------------------------------------------------------------------------------------------------------------------------
-- Addon Selector
---------------------------------------------------------------------------------------------------------------------------
ADDON_MANAGER        = utility.GetAddOnManager()
ADDON_MANAGER_OBJECT = utility.GetAddonManagerObject() --maybe nil here, updated later at EVENT_ADD_ON_LOADED again




--Clean the color codes from the addon name
--[[
local function stripText(text)
    return text:gsub("|c%x%x%x%x%x%x", "")
end
]]

--Check if dependencies of an addon are given and enable them, if not already enabled
--> This function was taken from addon "Votans Addon List". All credits go to Votan!
--[[
local dependencyLevel = 0
local function checkDependsOn(data)
d("=== CHECK DEPENDS ON ==========================")
    if not data or (data and not data.dependsOn) then return end
    -- assume success to break recursion
    data.addOnEnabled, data.addOnState = true, ADDON_STATE_ENABLED

    dependencyLevel = dependencyLevel + 1
d(">dependencyLevel: " .. tos(dependencyLevel))

    local other
    for i = 1, #data.dependsOn do
        other = data.dependsOn[i]
        if other.addOnState ~= ADDON_STATE_ENABLED and not other.missing then
d(">Dependency: " ..tos(other.strippedAddOnName))
            checkDependsOn(other)
        end
    end
    ADDON_MANAGER:SetAddOnEnabled(data.index, true)
    -- Verify success
    --data.addOnEnabled, data.addOnState = select(5, ADDON_MANAGER:GetAddOnInfo(data.index))
    --return data.addOnState == ADDON_STATE_ENABLED
    dependencyLevel = dependencyLevel - 1
end
]]

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


--[[
--Enable the multiselect of addons via the SHIFT key
--Parameters: _ = eventCode,  a = layerIndex,  b = activeLayerIndex
local function AddonSelector_HookForMultiSelectByShiftKey()--eventCode, layerIndex, activeLayerIndex)
--d("[AddonSelector]AddonSelector_HookForMultiSelectByShiftKey")
    --if not (layerIndex == 17 and activeLayerIndex == 5) then return end
    for i, control in pairs(ZOsControls.ZOAddOnsList.activeControls) do
        local name = control:GetNamedChild("Name")
        if name ~= nil then
            local enabled = control:GetNamedChild("Enabled")
            if enabled ~= nil then
                ZO_PreHookHandler(enabled, "OnClicked", function(self, button)
--d("[Enabled checkbox - OnClicked]")
                    --Do not run the same code (AddonSelector_MultiSelect) again if we come from the left mouse click on the name control
                    if AddonSelector.AS.flags.noAddonCheckBoxUpdate or button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
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
                    AddonSelector.AS.flags.noAddonNumUpdate = true
                    AddonSelector.AS.flags.noAddonCheckBoxUpdate = true
                    enabledClick(enabled, button)
                    if retVar == true then
                        zo_callLater(function()
                            AddonSelector_CheckLastChangedMultiSelectAddOn(control)
                        end, 150)
                    end
                    AddonSelector.AS.flags.noAddonCheckBoxUpdate = false
                    AddonSelector.AS.flags.noAddonNumUpdate = false
                end)
            end
        end
    end
end
]]


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

---------------------------------------------------------------------
--  Register Events --
---------------------------------------------------------------------
EM:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, AS.OnAddOnLoaded)