local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonSelectorStrPrefix = AS.constants.addonSelectorStrPrefix


--The strings
local langArray =  { --by Kwisatz
    ["packName"]            = "Nom du profil :",
    ["selectPack"]          = "Sélectionner",
    ["ERRORpackMissing"]    = "ADDON SELECTOR : Pas de nom de profil",
    ["autoReloadUIHint"]    = "Recharger l'interface après sélection d'un profil.",
    ["autoReloadUIHintTooltip"] = "Recharge automatique : Sélectionné, interdit l'édition ou la suppression des profils. Doit être déselectionné pour éditer ou supprimer un profil",
    ["saveButton"]          = "Enregistrer",
    ["savePackTitle"]        = "¿Remplacer le profil?",
    ["savePackBody"]        = "Remplacer le profil existant %s?",
    ["deleteButton"]        = "Supprimer",
    ["deletePackTitle"]     = "Supprimer: ",
    ["deletePackAlert"]     = "ADDON SELECTOR: Vous devez sélectionner un profil à supprimer.",
    ["deletePackError"]     = "ADDON SELECTOR: Erreur de suppression du profil\n%s.",
    ["deletePackBody"]      = "Vous souhaitez vraiment supprimer ce profil?\n%s",
    ["DeselectAllAddons"]   = "Tout desélectionner",
    ["SelectAllAddons"]     = "Tout sélectionner",
    ["SelectAllAddonsSaved"] = "Sélectionner enregistrée",
    ["AddonSearch"]          = "Rechercher:",
    ["selectedPackName"]     = "Sélectionné (%s): ",
    ["LibDialogMissing"]     = "Librairie \'LibDialog\' manquante! L'addon ne peut pas fonctionner sans elle!",
    ["ReloadUI"]            = GetString(SI_ADDON_MANAGER_RELOAD) or "Recharger l'interface",
    ["ShowActivePack"]      = "Montrer le  profil actif",
    ["ShowSubMenuAtGlobalPacks"] = "Montrer les sous-menus des groupes de profils",
    ["ShowSettings"]        = "Montrer configuration de \'"..ADDON_NAME.."\' ",
    ["ShowGlobalPacks"]     = "Montrer les groupes de profils enregistrés",
    ["GlobalPackSettings"] = "Configuration de groupe de profil",
    ["CharacterNameSettings"] = "Configuration du nom du personnage",
    ["SaveGroupedByCharacterName"] = "Enregistrer les groupes par nom de personnage",
    ["ShowGroupedByCharacterName"] = "Montrer les groupes par nom de personnage",
    ["packCharName"]        = "Profil de personnage",
    ["packGlobal"]          = "Profil global",
    ["searchExcludeFilename"] = "Exclure nom de fichier",
    ["searchSaveHistory"] = "Enregistrer historique des recherches",
    ["searchClearHistory"] = "Effacer l'historique",
    ["LastPackLoaded"] = "Dernier chargé:",
    ["singleCharName"]       = GetString(SI_CURRENCYLOCATION0),
}


for key, strValue in pairs(langArray) do
    local stringId = addonSelectorStrPrefix .. key
    SafeAddString(_G[stringId], strValue, 2)
end