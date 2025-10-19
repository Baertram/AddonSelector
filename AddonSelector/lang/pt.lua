local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonSelectorStrPrefix = AS.constants.addonSelectorStrPrefix

local constants = AS.constants
local textures = constants.textures

--The strings
local langArray = {
    ["packName"] = "Nome do Pacote:",
    ["selectPack"] = "Escolha",
    ["ERRORpackMissing"] = ADDON_NAME .. ": Faltando Nome do Pacote.",
    ["autoReloadUIHint"]	= "Auto-Relê UI na seleção do pacote.",
    ["autoReloadUIHintTooltip"] = "Auto-Relê UI: Quando ativada, você também pode evitar a edição ou exclusão de pacotes complementares.",
    ["saveButton"] = "Salva",
    ["savePackTitle"]        = "Substituir pacote?",
    ["savePackBody"]        = "Substituir pacote existente %s?",
    ["deleteButton"] = "Apaga",
    ["deletePackAlert"]     = ADDON_NAME .. ": Você deve selecionar um pacote para deletar.",
    ["deletePackError"]     = ADDON_NAME .. ": Pack delete error\n%s.",
    ["deletePackTitle"] = "Apaga: ",
    ["deletePackBody"] = "Apaga de Verdade?\n%s",
    ["DeselectAllAddons"] = "Desmarca tudo",
    ["SelectAllAddons"] = "Marca tudo",
    ["SelectAllAddonsSaved"] = "Re-escolhe salvo",
    ["AddonSearch"] = "Procura:",
    ["selectedPackName"]     = "Selecionada (%s):",
    ["ReloadUI"]        = GetString(SI_ADDON_MANAGER_RELOAD) or "Recarregar IU",
    ["ShowActivePack"]      = "Mostrar pacote ativo",
    ["ShowSubMenuAtGlobalPacks"]            = "Show submenu at global packs",
    ["ShowSettings"]        = "Show \'"..ADDON_NAME.."\' settings",
    ["ShowGlobalPacks"]     = "Show global saved packs",
    ["GlobalPackSettings"] = "Global pack settings",
    ["CharacterNameSettings"] = "Character name settings",
    ["SaveGroupedByCharacterName"] = "Save packs by character name",
    ["ShowGroupedByCharacterName"] = "Show packs of character names",
    ["packCharName"]        = "Character of pack",
    ["packGlobal"]          = "Global",
    ["searchExcludeFilename"] = "Exclude filename",
    ["searchSaveHistory"] = "Save history of search terms",
    ["searchClearHistory"] = "Clear history",
    ["LastPackLoaded"] = "Último carregamento:",
}

for key, strValue in pairs(langArray) do
    local stringId = addonSelectorStrPrefix .. key
    SafeAddString(_G[stringId], strValue, 2)
end