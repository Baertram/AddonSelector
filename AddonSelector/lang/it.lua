local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonSelectorStrPrefix = AS.constants.addonSelectorStrPrefix


--The strings
local langArray = { --by horizonxael
    ["packName"] = "Nome del profilo :",
    ["selectPack"] = "Seleziona",
    ["ERRORpackMissing"] = "ADDON SELECTOR : Nessun nome profilo",
    ["autoReloadUIHint"] = "Ricaricare l'interfaccia dopo aver selezionato un profilo.",
    ["autoReloadUIHintTooltip"] = "Ricaricamento automatico: selezionato, vieta la modifica o l'eliminazione dei profili. Deve essere deselezionato per modificare o eliminare un profilo",
    ["saveButton"] = "Registra",
    ["savePackTitle"] = "¿Sostituire il profilo?",
    ["savePackBody"] = "Sostituisci il profilo esistente %s?",
    ["deleteButton"] = "Cancella",
    ["deletePackTitle"] = "Cancellare: ",
    ["deletePackAlert"] = "ADDON SELECTOR: Devi selezionare un profilo da eliminare.",
    ["deletePackError"] = "ADDON SELECTOR: Errore di eliminazione del profilo\n%s.",
    ["deletePackBody"] = "Vuoi davvero eliminare questo profilo?\n%s",
    ["DeselectAllAddons"] = "Deseleziona tutto",
    ["SelectAllAddons"] = "Seleziona tutto",
    ["DeselectAllLibraries"]= "Deseleziona tutte le librerie",
    ["SelectAllLibraries"] = "Seleziona tutte le librerie",
    ["ScrollToAddons"] = "^ Componenti Aggiuntivi ^",
    ["ScrollToLibraries"] = "v Librerie v",
    ["SelectAllAddonsSaved"] = "Seleziona Salvato",
    ["AddonSearch"] = "Ricercare:",
    ["selectedPackName"] = "Selezionato (%s): ",
    ["LibDialogMissing"] = "Libreria \'LibDialog\' mancante! Il componente aggiuntivo non può funzionare senza di essa!",
    ["ReloadUI"] = GetString(SI_ADDON_MANAGER_RELOAD) or "Ricarica interfaccia",
    ["ShowActivePack"] = "Mostra profilo attivo",
    ["ShowSubMenuAtGlobalPacks"] = "Mostra i sottomenu del gruppo di profili",
    ["ShowSettings"] = "Mostra configurazione di \'"..ADDON_NAME.."\' ",
    ["ShowGlobalPacks"] = "Mostra i gruppi di profili salvati",
    ["GlobalPackSettings"] = "Configurazione del gruppo di profili",
    ["CharacterNameSettings"] = "Impostazione del nome del personaggio",
    ["SaveGroupedByCharacterName"] = "Salva i gruppi in base al nome del personaggio",
    ["ShowGroupedByCharacterName"] = "Mostra i gruppi in base al nome del personaggio",
    ["packCharName"] = "Profilo del personaggio",
    ["packGlobal"] = "Profilo globale",
    ["searchExcludeFilename"] = "Escludi nome file",
    ["searchSaveHistory"] = "Salva la cronologia delle ricerche",
    ["searchClearHistory"] = "Cancellare la cronologia",
    ["UndoLastMassMarking"] = "< Annulla le ultime marcature",
    ["ClearLastMassMarking"] = "Cancella il backup della marcatura",
    ["LastPackLoaded"] = "Ultimo caricato:",
}

for key, strValue in pairs(langArray) do
    local stringId = addonSelectorStrPrefix .. key
    SafeAddString(_G[stringId], strValue, 2)
end