local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonSelectorStrPrefix = AS.constants.addonSelectorStrPrefix


--The strings
local langArray = { -- by Kwisatz
    ["packName"]            = "Nombre del conjunto:",
    ["selectPack"]          = "Selecciona",
    ["ERRORpackMissing"]    = "ADDON SELECTOR: Falta nombre de conjunto",
    ["autoReloadUIHint"]    = "Recargar interfaz al seleccionar un conjunto.",
    ["autoReloadUIHintTooltip"] = "Recarga automática: Si está seleccionado, impide editar o suprimir conjuntos. Tiene que estar deseleccionado si quieres editar o suprimir conjuntos",
    ["saveButton"]          = "Guardar",
    ["savePackTitle"]        = "¿Sobreescribir conjunto?",
    ["savePackBody"]        = "Sobreescribir conjunto existente %s?",
    ["deleteButton"]        = "Suprimir",
    ["deletePackTitle"]     = "Suprimir: ",
    ["deletePackAlert"]     = "ADDON SELECTOR: Tienes que seleccionar un conjunto a suprimir.",
    ["deletePackError"]     = "ADDON SELECTOR: Error de supresión del conjunto\n%s.",
    ["deletePackBody"]      = "¿Quieres realmente suprimir el conjunto?\n%s",
    ["DeselectAllAddons"]   = "Deseleccionar todo",
    ["SelectAllAddons"]     = "Seleccionar todo",
    ["SelectAllAddonsSaved"] = "Seleccionar lo guardado",
    ["AddonSearch"]          = "Buscar:",
    ["selectedPackName"]     = "Seleccionado (%s): ",
    ["LibDialogMissing"]     = "¡Falta la librería \'LibDialog\'! ¡El complemento no puede funcionar sin ella!",
    ["ReloadUI"]            = GetString(SI_ADDON_MANAGER_RELOAD) or "Recargar interfaz",
    ["ShowActivePack"]      = "Mostrar conjunto activo",
    ["ShowSubMenuAtGlobalPacks"] = "Mostrar submenus en los conjuntos globales",
    ["ShowSettings"]        = "Mostrar ajustes de \'"..ADDON_NAME.."\' ",
    ["ShowGlobalPacks"]     = "Mostrar conjuntos globales guardados",
    ["GlobalPackSettings"] = "Ajustes de conjunto global",
    ["CharacterNameSettings"] = "Ajustes del nombre de personaje",
    ["SaveGroupedByCharacterName"] = "Guardar conjuntos por nombre de personaje",
    ["ShowGroupedByCharacterName"] = "Mostrar conjuntos por nombre de personaje",
    ["packCharName"]        = "Personaje del conjunto",
    ["packGlobal"]          = "Global",
    ["searchExcludeFilename"] = "Excluir nombre de archivo",
    ["searchSaveHistory"] = "Guardar historial de búsqueda",
    ["searchClearHistory"] = "Borrar historial",
    ["LastPackLoaded"] = "Último cargado:",
    ["singleCharName"]       = GetString(SI_CURRENCYLOCATION0),
}

for key, strValue in pairs(langArray) do
    local stringId = addonSelectorStrPrefix .. key
    SafeAddString(_G[stringId], strValue, 2)
end