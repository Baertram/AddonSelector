local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonSelectorStrPrefix = AS.constants.addonSelectorStrPrefix


--The strings
local langArray = { -- by Anntauri
    ["packName"]            = "Nome do pacote:",
    ["selectPack"]          = "Selecionar",
    ["ERRORpackMissing"]    = "ADDON SELECTOR: Nome do pacote não existe.",
    ["autoReloadUIHint"]    = "Atualizar interface na seleção de pacote.",
    ["autoReloadUIHintTooltip"] = "Atualização automática: se estiver ativo, isto irá te impedir de editar e deletar pacotes. Você precisa desativar essa opção para editar e deletar pacotes!",
    ["saveButton"]          = "Salvar",
    ["savePackTitle"]        = "Substituir pacote?",
    ["savePackBody"]        = "Substituir pacote %s?",
    ["deleteButton"]        = "Deletar",
    ["deletePackTitle"]     = "Deletar: ",
    ["deletePackAlert"]     = "ADDON SELECTOR: Você deve selecionar um pacote para deletar.",
    ["deletePackError"]     = "ADDON SELECTOR: Erro ao deletar pacote\n%s.",
    ["deletePackBody"]      = "Quer realmente deletar?\n%s",
    ["DeselectAllAddons"]   = "Desmarcar todos",
    ["SelectAllAddons"]     = "Marcar todos",
    ["SelectAllAddonsSaved"] = "Selecionar addons atuais",
    ["AddonSearch"]          = "Buscar:",
    ["selectedPackName"]     = "Selecionado (%s): ",
    ["LibDialogMissing"]     = "Está faltando \'LibDialog\'! O addon não funciona sem ela!",
    ["ReloadUI"]            = GetString(SI_ADDON_MANAGER_RELOAD) or "Atulizar interface",
    ["ShowActivePack"]      = "Mostrar pacote ativo",
    ["ShowSubMenuAtGlobalPacks"] = "Mostrar submenus nos pacotes globais",
    ["ShowSettings"]        = "Mostrar configurações de \'"..ADDON_NAME.."\' ",
    ["ShowGlobalPacks"]     = "Mostrar pacotes salvos globais",
    ["GlobalPackSettings"] = "Configuração de pacotes globais",
    ["CharacterNameSettings"] = "Configurações do nome de personagem",
    ["SaveGroupedByCharacterName"] = "Salvar pacotes pelo nome de personagem",
    ["ShowGroupedByCharacterName"] = "Mostrar pacotes pelo nome de personagem",
    ["packCharName"]        = "Personagem do pacote",
    ["packGlobal"]          = "Global",
    ["searchExcludeFilename"] = "Ignorar nome de arquivo",
    ["searchSaveHistory"] = "Salvar histórico de busca",
    ["searchClearHistory"] = "Limpar histórico",
    ["LastPackLoaded"] = "Último carregamento:",
}

for key, strValue in pairs(langArray) do
    local stringId = addonSelectorStrPrefix .. key
    SafeAddString(_G[stringId], strValue, 2)
end