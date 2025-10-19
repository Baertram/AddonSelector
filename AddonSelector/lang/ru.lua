local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonSelectorStrPrefix = AS.constants.addonSelectorStrPrefix

local constants = AS.constants
local textures = constants.textures

--The strings
local langArray =  { --by Friday_The13_rus
    ["packName"]            = "Имя сборки:",
    ["selectPack"]          = "Выбрать",
    ["ERRORpackMissing"]    = ADDON_NAME .. ": Имя сборки не найдено.",
    ["autoReloadUIHint"]    = "Автоматически перезагружать интерфейс.",
    ["autoReloadUIHintTooltip"] = "Автоматически перезагружать интерфейс: Когда включено, делает невозможным редактирование и удаление сборок. Выключите опцию, чтобы редактировать или удалять сборки!",
    ["saveButton"]          = "Сохранить",
    ["savePackTitle"]        = "Перезаписать сборку?",
    ["savePackBody"]        = "Перезаписать существующую сборку %s?",
    ["deleteButton"]        = "Удалить",
    ["deletePackTitle"]     = "Удалить: ",
    ["deletePackAlert"]     = ADDON_NAME .. ": Вы должны выбрать сборку для удаления.",
    ["deletePackError"]     = ADDON_NAME .. ": Ошибка при удалении сборки\n%s.",
    ["deletePackBody"]      = "Действительно удалить сборку?\n%s",
    ["DeselectAllAddons"]   = "Отключить всё",
    ["SelectAllAddons"]     = "Включить всё",
    ["SelectAllAddonsSaved"] = "Включить сохранённые",
    ["AddonSearch"]          = "Поиск:",
    ["selectedPackName"]     = "Выбрано (%s): ",
    ["ReloadUI"]        = GetString(SI_ADDON_MANAGER_RELOAD) or "Перезагрузить интерфейс",
    ["ShowActivePack"]      = "Показать активную сборку",
    ["ShowSubMenuAtGlobalPacks"]            = "Показывать вложенное меню для глобальных сборок",
    ["ShowSettings"]        = "Показать настройки \'"..ADDON_NAME.."\'",
    ["ShowGlobalPacks"]     = "Показать глобально сохраненные сборки",
    ["GlobalPackSettings"] = "Настройки глобальных сборок",
    ["CharacterNameSettings"] = "Настройки сборок для персонажа",
    ["SaveGroupedByCharacterName"] = "Сохранять сборки для персонажа",
    ["ShowGroupedByCharacterName"] = "Показывать сборки для персонажей",
    ["packCharName"]        = "Сборка для персонажа",
    ["packGlobal"]          = "Глобальная",
    ["searchExcludeFilename"] = "Исключить имя файла",
    ["searchSaveHistory"] = "Сохранять историю поиска",
    ["searchClearHistory"] = "Очистить историю",
    ["LastPackLoaded"] = "Последняя загрузка:",
    ["singleCharName"]       = GetString(SI_CURRENCYLOCATION0),
}


for key, strValue in pairs(langArray) do
    local stringId = addonSelectorStrPrefix .. key
    SafeAddString(_G[stringId], strValue, 2)
end