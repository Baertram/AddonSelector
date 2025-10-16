local AS = AddonSelectorGlobal
local constants = AS.constants
local utility = AS.utility

local ADDON_NAME = AS.name

local MAX_ADDON_LOAD_PACK_KEYBINDS = constants.keybinds.MAX_ADDON_LOAD_PACK_KEYBINDS

local keybindTexturesLoadPack = {}

--ZOs reference variables
local tos = tostring
local strfor = string.format

local ADDON_MANAGER_OBJECT = utility.GetAddonManagerObject()

local AddonSelector_GetLocalizedText = AddonSelector_GetLocalizedText


--======================================================================================================================
-- Keybindings
--======================================================================================================================

--Create the keybinding textures/Strings
local keybindStr = AddonSelector_GetLocalizedText("keybind")
for keybindNr  = 1, MAX_ADDON_LOAD_PACK_KEYBINDS, 1 do
    keybindTexturesLoadPack[keybindNr] = "  " .. keybindStr .. " " .. keybindNr  --does not work: ZO_Keybindings_GenerateIconKeyMarkup(22 + keybindNr, 100, false)
end
constants.keybinds.keybindTexturesLoadPack = keybindTexturesLoadPack

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
    ADDON_MANAGER_OBJECT = ADDON_MANAGER_OBJECT or utility.GetAddonManagerObject()
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

--Pack keybinds load/save/List
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

local function getKeybindingLSMEntriesForPacks(packName, charName)
    local keybindEntries = {}
    local keybindIconData = {}
    for keybindNr = 1, MAX_ADDON_LOAD_PACK_KEYBINDS, 1 do
        local isPackAlreadySavedAsKeybind = isPackKeybindUsed(keybindNr, packName, charName)
        if isPackAlreadySavedAsKeybind == false then
            keybindEntries[#keybindEntries + 1] = {
                name = strfor(AddonSelector_GetLocalizedText("addPackToKeybind"), tos(keybindNr)),
                callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                    savePackToKeybind(keybindNr, packName, charName)
                    utility.clearAndUpdateDDL()
                end,
                entryType = LSM_ENTRY_TYPE_NORMAL,
            }
        else
            keybindEntries[#keybindEntries + 1] = {
                name = strfor(AddonSelector_GetLocalizedText("removePackFromKeybind"), tos(keybindNr)),
                callback = function(comboBox, packNameWithSelectPackStr, packData, selectionChanged, oldItem)
                    removePackFromKeybind(keybindNr, packName, charName)
                    utility.clearAndUpdateDDL()
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
utility.getKeybindingLSMEntriesForPacks = getKeybindingLSMEntriesForPacks



--Load the keybindings
function AS.LoadKeybinds()
    --AddonSelector UI Keybinds
    ZO_CreateStringId("SI_KEYBINDINGS_CATEGORY_ADDON_SELECTOR", ADDON_NAME)
    ZO_CreateStringId("SI_BINDING_NAME_ADDONS_RELOADUI",        AddonSelector_GetLocalizedText("reloadUI"))
    ZO_CreateStringId("SI_BINDING_NAME_SHOWACTIVEPACK",         AddonSelector_GetLocalizedText("ShowActivePack"))

    --Pack load keybinds
    if AS.acwsv ~= nil and AS.acwsv.packKeybinds ~= nil then
        local packKeybinds = AS.acwsv.packKeybinds
        local numKeybinds = #packKeybinds
        if numKeybinds <= 0 then return end

        for i=1, MAX_ADDON_LOAD_PACK_KEYBINDS, 1 do
            ZO_CreateStringId("SI_BINDING_NAME_ADDONS_LOAD_PACK" .. tos(i), AddonSelector_GetLocalizedText("LoadPackByKeybind" .. tos(i)))
        end
    end

    --Move the keybinds strip at the Addon Manager list
    moveAddonManager2ndKeybindDescriptorTo4th()
end
