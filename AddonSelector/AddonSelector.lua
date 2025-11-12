--[[
------------------------------------------------------------------------------------------------------------------------
 Changelog
------------------------------------------------------------------------------------------------------------------------
2025-11-12
AddonSelector v3.00


------------------------------------------------------------------------------------------------------------------------
 Known bugs - Max: 19
------------------------------------------------------------------------------------------------------------------------
20251104 - #17 Selecting a keybind at the submenu of a saved pack write the text "Keybind ...." into the DDL instead of not selecting it to the DDL, and there is no keybind icon at the DDL entry
20251104 - #18 Selecting a keybind at the context menu of a saved pack (as submenus at the pack are disabled in the settings) won't update the next open of the context menu so the keybind can be removed again, and there is no keybind icon at the DDL entry



Feature requests:
20251010 - #16 Add missing dependencies (e.g. new added to addons) automatically to loaded packs (maybe show a popup informing the user about it)
20251010 - Show missing (non installed) dependencies, of all addons, at a collapsible UI at the addon manager
20251112 - Add slash command /asnone to disable all addons and reload the UI

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
]]

local AS = AddonSelectorGlobal

--Addon internal variables
local ADDON_NAME = AS.name

local utility = AS.utility

--Object variables
local ADDON_MANAGER
local ADDON_MANAGER_OBJECT


--ZOs reference variables
local EM = EVENT_MANAGER

--local tos = tostring

--local AddonSelector_GetLocalizedText = AddonSelector_GetLocalizedText

------------------------------------------------------------------------------------------------------------------------
-- Addon Selector
---------------------------------------------------------------------------------------------------------------------------
ADDON_MANAGER        = utility.GetAddonManager()
ADDON_MANAGER_OBJECT = utility.GetAddonManagerObject() --maybe nil here, updated later at EVENT_ADD_ON_LOADED again

---------------------------------------------------------------------
--  Register Events --
---------------------------------------------------------------------
EM:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, AS.OnAddOnLoaded)