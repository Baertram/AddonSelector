--[[
------------------------------------------------------------------------------------------------------------------------
 Changelog
------------------------------------------------------------------------------------------------------------------------
2025-10-16
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
ADDON_MANAGER        = utility.GetAddOnManager()
ADDON_MANAGER_OBJECT = utility.GetAddonManagerObject() --maybe nil here, updated later at EVENT_ADD_ON_LOADED again

---------------------------------------------------------------------
--  Register Events --
---------------------------------------------------------------------
EM:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, AS.OnAddOnLoaded)