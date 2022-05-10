--[[
Known bugs:
]]
local ADDON_NAME	= "AddonSelector"
local ADDON_MANAGER
local AddonSelector = {}
AddonSelector.name = ADDON_NAME
AddonSelector.firstControl     = nil
AddonSelector.firstControlData = nil
AddonSelector.noAddonNumUpdate = false
AddonSelector.noAddonCheckBoxUpdate = false
AddonSelector.lastChangedAddOnVars = {}
AddonSelector.alreadyFound = {}
AddonSelector.activeUpdateControlEvents = {}
AddonSelector.version = "2.13"

AddonSelectorGlobal = AddonSelector
--TODO:Remove comment for quicker debugging
--ASG = AddonSelectorGlobal

local EM = EVENT_MANAGER
local SM = SCENE_MANAGER

local strfor = string.format
local strlow = string.lower
local strgma = string.gmatch
local zopsf = zo_plainstrfind
local gTab = table
local tins = gTab.insert
--local trem = gTab.remove
local tsor = gTab.sort

--Constant for the global pack name
local GLOBAL_PACK_NAME = "$G"
local SEARCH_TYPE_NAME = "name"

--Other Addons/Libraries which should not be disabled if you use the "disable all" keybind
--> see function AddonSelector_SelectAddons(false)
local addonsWhichShouldNotBeDisabled = {
    ["LibDialog"] =     true,
    ["LibCustomMenu"] = true,
}
local addonsWhichShouldNotBeDisabledCount = 2 --entries in addonsWhichShouldNotBeDisabled
--Get the current addonIndex of the "AddonSelector" addon
local thisAddonIndex = 0
--Needed dependencies index
local addonIndicesOfAddonsWhichShouldNotBeDisabled = {}


local AddOnManager = GetAddOnManager()
AddonSelector.AddOnManager = AddOnManager
--The drop down list for the packs -> ZO_ScrollableComboBox
local isAreAddonsEnabledFuncGiven = (AddOnManager.AreAddOnsEnabled ~= nil) or false

--The "Enable all addons" checkbox introduced with API101031
local ZOAddOnsList                  = ZO_AddOnsList
local enableAllAddonsCheckboxHooked = false
local enableAllAddonsCheckboxCtrl   = ZO_AddOnsList2Row1Checkbox

local currentCharIdNum = GetCurrentCharacterId()
local currentCharId = tostring(currentCharIdNum)
local currentCharName = ZO_CachedStrFormat(SI_UNIT_NAME, GetUnitName("player"))

local doNotReloadUI = false
local lang = GetCVar("language.2")
local fallbackLang = "en"
local langArray = {
	["en"] = { -- by Baertram
		["packName"]			= "Pack name:",
		["selectPack"]			= "Select pack",
    	["ERRORpackMissing"] 	= "ADDON SELECTOR: Pack name missing.",
        ["autoReloadUIHint"]	= "Auto-Reload UI on pack selection.",
        ["autoReloadUIHintTooltip"] = "Auto-Reload UI: When ON this will prevent editing and deleting addon packs. You will need to turn it off to edit or delete packs!",
        ["saveButton"]			= "Save",
        ["savePackTitle"]        = "Overwrite pack?",
        ["savePackBody"]        = "Overwrite existing pack %s?",
        ["deleteButton"]		= "Delete",
        ["deletePackTitle"]     = "Delete: ",
        ["deletePackAlert"]     = "ADDON SELECTOR: You must select a pack to delete.",
        ["deletePackError"]     = "ADDON SELECTOR: Pack delete error\n%s.",
        ["deletePackBody"]      = "Really delete?\n%s",
        ["DeselectAllAddons"]   = "Deselect all",
        ["SelectAllAddons"]     = "Select all",
        ["SelectAllAddonsSaved"] = "Re-select saved",
        ["AddonSearch"]          = "Search:",
        ["selectedPackName"]     = "Selected (%s): ",
        ["LibDialogMissing"]     = "Library \'LibDialog\' is missing! This addon will not work without it!",
        ["ReloadUI"]            = GetString(SI_ADDON_MANAGER_RELOAD) or "Reload UI",
        ["ShowActivePack"]      = "Show active pack",
        ["ShowSubMenuAtGlobalPacks"] = "Show submenu at global packs",
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
    },
    ["es"] = { -- by Kwisatz
        ["packName"]            = "Nombre del conjunto:",
        ["selectPack"]          = "Selecciona conjunto",
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
        ["SelectAllAddonsSaved"] = "Volver a seleccionar lo guardado",
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
    },
    ["fr"] = { --by Kwisatz
        ["packName"]            = "Nom du profil :",
        ["selectPack"]          = "Sélectionner profil",
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
        ["SelectAllAddonsSaved"] = "Reprendre la sélection enregistrée",
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
    },
	["de"] = { -- by Baertram
		["packName"]			= "Pack Name:",
		["selectPack"]			= "Pack wählen",
    	["ERRORpackMissing"] 	= "ADDON SELECTOR: Pack Name fehlt.",
        ["autoReloadUIHint"]	= "Autom. Reload UI nach Pack Auswahl!",
        ["autoReloadUIHintTooltip"] = "Auto-Reload UI: Wenn diese Option aktiviert wurde können keine AddOn Packs geändert oder gelöscht werden. Sie müssen diese Option deaktivieren, um AddOn Packs ändern oder löschen zu können.",
        ["saveButton"]			= "Sichern",
        ["savePackTitle"]        = "Pack überschreiben?",
        ["savePackBody"]        = "Überschreibe Pack %s?",
        ["deleteButton"]		= "Löschen",
        ["deletePackAlert"]     = "ADDON SELECTOR: Du musst einen Pack zum Löschen auswählen.",
        ["deletePackError"]     = "ADDON SELECTOR: Pack Löschen Fehler\n%s.",
        ["deletePackTitle"]     = "Löschen: ",
        ["deletePackBody"]      = "Pack löschen?\n%s",
        ["DeselectAllAddons"]   = "Alle demarkieren",
        ["SelectAllAddons"]     = "Alle markieren",
        ["SelectAllAddonsSaved"] = "Gesicherte re-markieren",
        ["AddonSearch"]          = "Suche:",
        ["selectedPackName"]     = "Gewählt (%s): ",
        ["LibDialogMissing"]     = "Bibliothek \'LibDialog \' fehlt! Dieses Addon wird ohne diese nicht funktionieren!",
        ["ReloadUI"]        = GetString(SI_ADDON_MANAGER_RELOAD) or "UI neu laden",
        ["ShowActivePack"]      = "Aktiven Pack zeigen",
        ["ShowSubMenuAtGlobalPacks"]            = "Zeige Untermenü am globalen Pack",
        ["ShowSettings"]        = "\'"..ADDON_NAME.."\' Einstellungen anzeigen",
        ["ShowGlobalPacks"]     = "Zeige global gespeicherte Packs",
        ["GlobalPackSettings"] = "Globale Pack Einstellungen",
        ["CharacterNameSettings"] = "Charaktername Einstellungen",
        ["SaveGroupedByCharacterName"] = "Speichere Packs je Charaktername",
        ["ShowGroupedByCharacterName"] = "Zeige Packs der Charakternamen",
        ["packCharName"]        = "Charakter des Packs",
        ["packGlobal"]          = "Global",
        ["searchExcludeFilename"] = "Dateiname nicht durchsuchen",
        ["searchSaveHistory"] = "Historie der Suchbegriffe speichern",
        ["searchClearHistory"] = "Historie leeren",
    },
    ["ru"] = { --by Friday_The13_rus
        ["packName"]            = "Имя сборки:",
        ["selectPack"]          = "Выбрать",
        ["ERRORpackMissing"]    = "ADDON SELECTOR: Имя сборки не найдено.",
        ["autoReloadUIHint"]    = "Автоматически перезагружать интерфейс.",
        ["autoReloadUIHintTooltip"] = "Автоматически перезагружать интерфейс: Когда включено, делает невозможным редактирование и удаление сборок. Выключите опцию, чтобы редактировать или удалять сборки!",
        ["saveButton"]          = "Сохранить",
        ["savePackTitle"]        = "Перезаписать сборку?",
        ["savePackBody"]        = "Перезаписать существующую сборку %s?",
        ["deleteButton"]        = "Удалить",
        ["deletePackTitle"]     = "Удалить: ",
        ["deletePackAlert"]     = "ADDON SELECTOR: Вы должны выбрать сборку для удаления.",
        ["deletePackError"]     = "ADDON SELECTOR: Ошибка при удалении сборки\n%s.",
        ["deletePackBody"]      = "Действительно удалить сборку?\n%s",
        ["DeselectAllAddons"]   = "Отключить всё",
        ["SelectAllAddons"]     = "Включить всё",
        ["SelectAllAddonsSaved"] = "Включить сохранённые",
        ["AddonSearch"]          = "Поиск:",
        ["selectedPackName"]     = "Выбрано (%s): ",
        ["LibDialogMissing"]     = "Библиотека \'LibDialog\' отсутствует! Этот аддон не будет работать без него!",
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
    },
    ["br"] = { -- by Anntauri
        ["packName"]            = "Nome do pacote:",
        ["selectPack"]          = "Selecionar pacote",
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
    },
    ["pt"] = {
        ["packName"] = "Nome do Pacote:",
        ["selectPack"] = "Escolha pacote",
        ["ERRORpackMissing"] = "ADDON SELECTOR: Faltando Nome do Pacote.",
        ["autoReloadUIHint"]	= "Auto-Relê UI na seleção do pacote.",
        ["autoReloadUIHintTooltip"] = "Auto-Relê UI: Quando ativada, você também pode evitar a edição ou exclusão de pacotes complementares.",
        ["saveButton"] = "Salva",
        ["savePackTitle"]        = "Substituir pacote?",
        ["savePackBody"]        = "Substituir pacote existente %s?",
        ["deleteButton"] = "Apaga",
        ["deletePackAlert"]     = "ADDON SELECTOR: Você deve selecionar um pacote para deletar.",
        ["deletePackError"]     = "ADDON SELECTOR: Pack delete error\n%s.",
        ["deletePackTitle"] = "Apaga: ",
        ["deletePackBody"] = "Apaga de Verdade?\n%s",
        ["DeselectAllAddons"] = "Desmarca tudo",
        ["SelectAllAddons"] = "Marca tudo",
        ["SelectAllAddonsSaved"] = "Re-escolhe salvo",
        ["AddonSearch"] = "Procura:",
        ["selectedPackName"]     = "Selecionada (%s):",
        ["LibDialogMissing"]     = "Biblioteca \'LibDialog \' está faltando! Este addon não funcionará sem ele!",
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
    },
    ["jp"] = { -- by Calamath
        ["packName"] = "パック名:",
        ["selectPack"] = "パック選択",
        ["ERRORpackMissing"] = "ADDON SELECTOR: パック名が見つかりません",
        ["autoReloadUIHint"] = "自動UIリロード",
        ["autoReloadUIHintTooltip"] = "自動UIリロード: ONにした場合、編集や削除ができなくなります。 編集や削除をする場合はOFFにして下さい。",
        ["saveButton"] = "保存",
        ["savePackTitle"] = "上書き保存しますか？",
        ["savePackBody"] = " %s に上書き保存しますか？",
        ["deleteButton"] = "削除",
        ["deletePackAlert"]     = "ADDON SELECTOR: 削除するパックを選択する必要があります。",
        ["deletePackError"]     = "ADDON SELECTOR: パック削除エラー\n%s.",
        ["deletePackTitle"] = "削除: ",
        ["deletePackBody"] = "本当に削除しますか？\n%s",
        ["DeselectAllAddons"] = "全解除",
        ["SelectAllAddons"] = "全選択",
        ["SelectAllAddonsSaved"] = "保存したものを再選択",
        ["AddonSearch"] = "検索:",
        ["selectedPackName"] = "選択中 (%s):",
        ["LibDialogMissing"] = "ライブラリ \'LibDialog\' が見つかりません！ このアドオンはこれがないと動きません。",
        ["ReloadUI"]        = GetString(SI_ADDON_MANAGER_RELOAD) or "UIをリロード",
        ["ShowActivePack"]      = "アクティブパックを表示",
        ["ShowSubMenuAtGlobalPacks"]            = "グローバルパックでサブメニューを表示",
        ["ShowSettings"]        = "\'"..ADDON_NAME.."\' の設定を表示",
        ["ShowGlobalPacks"]     = "グローバルに保存されたパックを表示",
        ["GlobalPackSettings"] = "グローバルパックの設定",
        ["CharacterNameSettings"] = "キャラクタ名パックの設定",
        ["SaveGroupedByCharacterName"] = "キャラクタ名でパックを保存",
        ["ShowGroupedByCharacterName"] = "キャラクタ名パックを表示",
        ["packCharName"]        = "パックのキャラクタ",
        ["packGlobal"]          = "グローバル",
        ["searchExcludeFilename"] = "ファイル名を除外",
        ["searchSaveHistory"] = "検索語の履歴を保存",
        ["searchClearHistory"] = "履歴を消去する",
    },
    ["pl"] = { --by generaluploads
		["packName"]			= "Nazwa paczki:",
		["selectPack"]			= "Wybierz",
    	["ERRORpackMissing"] 	= "ADDON SELECTOR: Brak nazwy paczki",
        ["autoReloadUIHint"]	= "Automatycznie przeładuj interfejs przy wyborze paczki.",
        ["autoReloadUIHintTooltip"] = "Automatycznie przeładuj interfejs: Kiedy jest WłĄCZONA, uniemożliwi to edycję i usuwanie pakietów addonów. Będziesz musiał/a to wyłączyć, aby edytować lub usuwać paczki addonów!",
        ["saveButton"]			= "Zapisz",
        ["savePackTitle"]        = "Nadpisać paczkę?",
        ["savePackBody"]        = "Nadpisać istniejącą paczkę %s?",
        ["deleteButton"]		= "Usuń",
        ["deletePackTitle"]     = "Usuń: ",
        ["deletePackAlert"]     = "ADDON SELECTOR: Musisz wybrać paczkę, którą chcesz usunąć.",
        ["deletePackError"]     = "ADDON SELECTOR: Błąd usuwania paczki\n%s.",
        ["deletePackBody"]      = "Naprawdę usunąć?\n%s",
        ["DeselectAllAddons"]   = "Odznacz wszystkie",
        ["SelectAllAddons"]     = "Zaznacz wszystkie",
        ["SelectAllAddonsSaved"] = "Zapisano ponowny wybór",
        ["AddonSearch"]          = "Szukaj:",
        ["selectedPackName"]     = "Wybrano (%s): ",
        ["LibDialogMissing"]     = "Brakuje biblioteki \'LibDialog\'! Ten addon nie będzie działał bez niego!",
        ["ReloadUI"]            = GetString(SI_ADDON_MANAGER_RELOAD) or "Przeładuj interfejs",
        ["ShowActivePack"]      = "Pokaż aktywną paczkę",
        ["ShowSubMenuAtGlobalPacks"] = "Pokaż podmenu przy paczkach ogólnych",
        ["ShowSettings"]        = "Pokaż ustawienia \'"..ADDON_NAME.."\'",
        ["ShowGlobalPacks"]     = "Pokaż ogólne zapisane paczki",
        ["GlobalPackSettings"] = "Ogólne ustawienia paczek",
        ["CharacterNameSettings"] = "Ustawienia nazw postaci",
        ["SaveGroupedByCharacterName"] = "Zapisz paczki addonów według nazwy postaci",
        ["ShowGroupedByCharacterName"] = "Pokaż paczki addonów według nazw postaci",
        ["packCharName"]        = "Paczka postaci",
        ["packGlobal"]          = "Ogólny",
        ["searchExcludeFilename"] = "Wyklucz nazwę pliku",
        ["searchSaveHistory"] = "Zapisz historię wyszukiwanych haseł",
        ["searchClearHistory"] = "Wyczyść historię",
    },
}
langArray["fx"] = langArray["pl"] --inofficial pl "debug language" -> by generaluploads

local langArrayInClientLang = langArray[lang]
local langArrayInFallbackLang = langArray[fallbackLang]
local charNamePackColorTemplate = "|cc9b636%s|r"
local charNamePackColorDef = ZO_ColorDef:New("C9B636")
local globalPackColorTemplate = "|c7EC8E3%s|r"
local packNameGlobal = strfor(globalPackColorTemplate, langArrayInClientLang["packGlobal"] or langArrayInFallbackLang["packGlobal"])
local selectedPackNameStr = langArrayInClientLang["selectedPackName"] or langArrayInFallbackLang["selectedPackName"]
local deletePackAlertStr = langArrayInClientLang["deletePackAlert"] or langArrayInFallbackLang["deletePackAlert"]
local deletePackErrorStr = langArrayInClientLang["deletePackError"] or langArrayInFallbackLang["deletePackError"]
local savedGroupedByCharNameStr = langArrayInClientLang["SaveGroupedByCharacterName"] or langArrayInFallbackLang["SaveGroupedByCharacterName"]
local autoReloadUIStr = langArrayInClientLang["autoReloadUIHint"] or langArrayInFallbackLang["autoReloadUIHint"]
local searchMenuStr = langArrayInClientLang["AddonSearch"] or langArrayInFallbackLang["AddonSearch"]
searchMenuStr = string.sub(searchMenuStr, 1, -2) --remove last char
local clearSearchHistoryStr = langArrayInClientLang["searchClearHistory"] or langArrayInFallbackLang["searchClearHistory"]

--Clean the color codes from the addon name
--[[
local function stripText(text)
    return text:gsub("|c%x%x%x%x%x%x", "")
end
]]

--Get localized texts
function AddonSelector_GetLocalizedText(textToFind)
    return langArrayInClientLang[textToFind] or langArrayInFallbackLang[textToFind] or "N/A"
end

-- Create the pack table or nil it out if it exists.
-- Distinguish between packs grouped for charactes or general packs
local function createSVTableForPack(packName)
    if AddonSelector.acwsv.saveGroupedByCharacterName then
        AddonSelector.acwsv.addonPacksOfChar[currentCharId] = AddonSelector.acwsv.addonPacksOfChar[currentCharId] or {}
        AddonSelector.acwsv.addonPacksOfChar[currentCharId]._charName = currentCharName
        AddonSelector.acwsv.addonPacksOfChar[currentCharId][packName] = {}
        return AddonSelector.acwsv.addonPacksOfChar[currentCharId][packName]
    else
        AddonSelector.acwsv.addonPacks[packName] = {}
        return AddonSelector.acwsv.addonPacks[packName]
    end
    return
end

local function getSVTableForPacks()
    if AddonSelector.acwsv.saveGroupedByCharacterName then
        --Table for current char does not exist yt, so create it. Else a new saved pack will be compared to the global
        --packs and if the name matches it will be saved as global!
        AddonSelector.acwsv.addonPacksOfChar = AddonSelector.acwsv.addonPacksOfChar or {}
        AddonSelector.acwsv.addonPacksOfChar[currentCharId] = AddonSelector.acwsv.addonPacksOfChar[currentCharId] or {}
        AddonSelector.acwsv.addonPacksOfChar[currentCharId]._charName = currentCharName
        return AddonSelector.acwsv.addonPacksOfChar[currentCharId], currentCharName
    end
    return AddonSelector.acwsv.addonPacks, nil
end

--[[
local function getSVTableForPacksOfChar(charId)
    if AddonSelector.acwsv.saveGroupedByCharacterName then
        if AddonSelector.acwsv.addonPacksOfChar and AddonSelector.acwsv.addonPacksOfChar[charId] then
            return AddonSelector.acwsv.addonPacksOfChar[charId], AddonSelector.acwsv.addonPacksOfChar[charId]._charName
        end
    end
    return AddonSelector.acwsv.addonPacks, nil
end
]]

local function getSVTableForPacksOfCharname(charName)
    local addonPacksOfChar = AddonSelector.acwsv.addonPacksOfChar
    if addonPacksOfChar then
        for charId, packsData in pairs(addonPacksOfChar) do
            local addonPacksCharName = packsData["_charName"]
            if addonPacksCharName ~= GLOBAL_PACK_NAME and addonPacksCharName == charName then
                return addonPacksOfChar[charId], charId
            end
        end
    end
    return nil, nil
end

--[[
local function getSVTableForPackOfChar(packName, charId)
    if AddonSelector.acwsv.saveGroupedByCharacterName then
        if AddonSelector.acwsv.addonPacksOfChar and AddonSelector.acwsv.addonPacksOfChar[charId] and AddonSelector.acwsv.addonPacksOfChar[charId][packName] then
            return AddonSelector.acwsv.addonPacksOfChar[charId][packName], AddonSelector.acwsv.addonPacksOfChar[charId]._charName
        end
    end
    return AddonSelector.acwsv.addonPacks, nil
end

local function getCharNameOfPack(charId)
    if AddonSelector.acwsv.saveGroupedByCharacterName then
        if AddonSelector.acwsv.addonPacksOfChar and AddonSelector.acwsv.addonPacksOfChar[charId] then
            return AddonSelector.acwsv.addonPacksOfChar[charId]._charName
        end
    end
    return
end
]]

--Deselect the combobox entry
local function deselectComboBoxEntry()
    local comboBox = AddonSelector.comboBox
    if comboBox then
        comboBox:SetSelectedItem("")
        comboBox.m_selectedItemData = nil
    end
end

--Check if dependencies of an addon are given and enable them, if not already enabled
--> This function was taken from addon "Votans Addon List". All credits go to Votan!
local dependencyLevel = 0
local function checkDependsOn(data)
--d(">checkDependsOn")
    if not data or (data and not data.dependsOn) then return end
    -- assume success to break recursion
    data.addOnEnabled, data.addOnState = true, ADDON_STATE_ENABLED

    dependencyLevel = dependencyLevel + 1

    local other
    for i = 1, #data.dependsOn do
        other = data.dependsOn[i]
--d(">dependency (level "..tostring(dependencyLevel).."): " ..tostring(other.strippedAddOnName))
        if other.addOnState ~= ADDON_STATE_ENABLED and not other.missing then
            checkDependsOn(other)
        end
    end
    AddOnManager:SetAddOnEnabled(data.index, true)
    -- Verify success
    --data.addOnEnabled, data.addOnState = select(5, AddOnManager:GetAddOnInfo(data.index))
    --return data.addOnState == ADDON_STATE_ENABLED
    dependencyLevel = dependencyLevel - 1
end

--Enable/Disable all the controls of this addon depending on the enabled checkbox for all addons
local function setThisAddonsControlsEnabledState(enabledState)
    local addonSelectorTLC = AddonSelector.addonSelectorControl
    local numChildControls = addonSelectorTLC:GetNumChildren()
    if numChildControls <= 0 then return end
    for childindex=1, numChildControls, 1 do
        local childControl = addonSelectorTLC:GetChild(childindex)
        if childControl ~= nil and childControl.SetMouseEnabled and childControl.IsHidden then
            childControl:SetMouseEnabled(enabledState)
        end
    end
end

--Check if the checkbox to disable all addons is enabled or not
local function areAllAddonsEnabled(noControlUpdate)
    noControlUpdate = noControlUpdate or false
    if not isAreAddonsEnabledFuncGiven then
        --[[
        if not noControlUpdate then
            setThisAddonsControlsEnabledState(true)
        end
        ]]
        return true
    end

    local areAllAddonsCurrentlyEnabled = AddOnManager:AreAddOnsEnabled()
    if not noControlUpdate then
        setThisAddonsControlsEnabledState(areAllAddonsCurrentlyEnabled)
    end
    --d("[CAS]areAllAddonsEnabled: " ..tostring(areAllAddonsCurrentlyEnabled) .. ", noControlUpdate: " ..tostring(noControlUpdate))
    return areAllAddonsCurrentlyEnabled
end

-- Toggles Enabled state when a row is clicked
-->Using  Votans Addon List function ADD_ON_MANAGER:OnEnabledButtonClicked so that dependencies are enabled too
local function Addon_Toggle_Enabled(rowControl)
    --d("Addon_Toggle_Enabled")
    if not areAllAddonsEnabled(true) then return end

    --local addonIndex 	= rowControl.data.index
    local enabledBtn 	= rowControl:GetNamedChild("Enabled")
    local state 		= ZO_TriStateCheckButton_GetState(enabledBtn)

    if state == TRISTATE_CHECK_BUTTON_CHECKED then
        -- changed so it automatically refreshes the multiButton (reload UI)
        --ADD_ON_MANAGER:ChangeEnabledState(addonIndex, TRISTATE_CHECK_BUTTON_UNCHECKED)
        ADD_ON_MANAGER:OnEnabledButtonClicked(enabledBtn, TRISTATE_CHECK_BUTTON_UNCHECKED)
        return
    end
    --ADD_ON_MANAGER:ChangeEnabledState(addonIndex, TRISTATE_CHECK_BUTTON_CHECKED)
    ADD_ON_MANAGER:OnEnabledButtonClicked(enabledBtn, TRISTATE_CHECK_BUTTON_CHECKED)
end

local function getCurrentCharsPackNameData()
    --Get the currently selected packname from the SavedVariables
    local packNamesForCharacters = AddonSelector.acwsv.selectedPackNameForCharacters
    if not packNamesForCharacters then return nil, nil end
    local currentlySelectedPackData = packNamesForCharacters[currentCharId]
    return currentCharId, currentlySelectedPackData
end

--Update the currently selected packName label
local function UpdateCurrentlySelectedPackName(wasDeleted, packName, packData)
--d(">1")
    wasDeleted = wasDeleted or false
    local packNameLabel = AddonSelector.selectedPackNameLabel
    if not packNameLabel then return end
    local savePackPerCharacter = AddonSelector.acwsv.saveGroupedByCharacterName

    local currentlySelectedPackName
    local currentlySelectedPackCharName
    local currentCharacterId = currentCharId
    if packName == nil or packName == "" or packData == nil then
--d(">2")
        local currentlySelectedPackNameData
        currentCharacterId, currentlySelectedPackNameData = getCurrentCharsPackNameData()
        if not currentCharacterId or not currentlySelectedPackNameData then return end
        currentlySelectedPackName = currentlySelectedPackNameData.packName
        if wasDeleted then
--d(">3")
            --If pack was deleted:
            --Reset the pack character to the currently logged in charname if settings to save per character are enabled.
            --Else reset to "Global" name
            currentlySelectedPackCharName = (savePackPerCharacter and currentCharName) or packNameGlobal
        else
--d(">4")
            currentlySelectedPackCharName = (currentlySelectedPackNameData.charName and ((currentlySelectedPackNameData.charName == GLOBAL_PACK_NAME and packNameGlobal) or currentlySelectedPackNameData.charName))
        end
    else
--d(">5")
        currentlySelectedPackName = packName
        currentlySelectedPackCharName = (packData.charName and ((packData.charName == GLOBAL_PACK_NAME and packNameGlobal) or packData.charName)) or "n/a"
    end
--d("[AddonSelector]currentlySelectedPackName: " ..tostring(currentlySelectedPackName) ..", currentlySelectedPackCharName: " ..tostring(currentlySelectedPackCharName))

    --Pack wurde nicht gelöscht, sondern soll normal updaten?
    if not wasDeleted then
        if not currentlySelectedPackName then return end
    else
        --Pack wurde gelöscht. Entfernen und label leeren
        currentlySelectedPackName = ""
        AddonSelector.acwsv.selectedPackNameForCharacters[currentCharacterId] = nil
    end
    if currentlySelectedPackName then
--d(">6")
        --Packs are saved per character? Show the character that belongs to teh currently selected pack
        local packNameText
        local settings = AddonSelector.acwsv
        --[[
        if settings.saveGroupedByCharacterName == true then
            packNameText = strfor(selectedPackNameStr, strfor(charNamePackColorTemplate, currentlySelectedPackCharName))
        else
            --Show the "global pack" info
            packNameText = strfor(selectedPackNameStr, packNameGlobal)
        end
        ]]
        packNameText = strfor(selectedPackNameStr, strfor(charNamePackColorTemplate, currentlySelectedPackCharName))
        packNameText = packNameText .. currentlySelectedPackName
        packNameLabel:SetText(packNameText)
    end
end

--Set the currently selected pack name and the character owning the pack for the currently logged in character
local function SetCurrentCharacterSelectedPackname(currentlySelectedPackName, packData)
--d("SetCurrentCharacterSelectedPackname: " ..tostring(currentlySelectedPackName) .. ", charName: " ..tostring(packData.charName))
    if not currentlySelectedPackName or currentlySelectedPackName == "" or packData == nil then return end
    --Get the current character's uniqueId
    local currentCharacterId = tostring(GetCurrentCharacterId())
    if not currentCharacterId then return end
    --Set the currently selected packname to the SavedVariables
    AddonSelector.acwsv.selectedPackNameForCharacters[currentCharacterId] = {
        packName = currentlySelectedPackName,
        charName = (AddonSelector.acwsv.saveGroupedByCharacterName == true and packData.charName) or GLOBAL_PACK_NAME
    }
end

--Disable/Enable the delete button's enabled state depending on the autoreloadui after pack change checkbox state
local function ChangeDeleteButtonEnabledState(autoreloadUICheckboxState, skipStateCheck)
--d("[AddonSelector]ChangeDeleteButtonEnabledState-autoreloadUICheckboxState: " ..tostring(autoreloadUICheckboxState) .. ", skipStateCheck: " ..tostring(skipStateCheck))
    local deleteBtn = AddonSelector.deleteBtn
    if not deleteBtn then end
    skipStateCheck = skipStateCheck or false
    local checkedBool = false
    local newDeleteButtonEnabledState
    if not skipStateCheck then
        --autoreloadUICheckboxState = autoreloadUICheckboxState or AddonSelector.autoReloadBtn:GetState()
        if autoreloadUICheckboxState == true then checkedBool = true end
    end
    newDeleteButtonEnabledState = not checkedBool
    --New enabled state of delete button would be enabled?
    if newDeleteButtonEnabledState then
        --Check if the user selected any dropdown entry yet. If not, disable the button
        local itemData = AddonSelector.comboBox:GetSelectedItemData()
        if itemData == nil then
            --No entry selected: Disable delete button
            newDeleteButtonEnabledState = false
        end
    end
    deleteBtn:SetMouseEnabled(newDeleteButtonEnabledState)
    deleteBtn:SetKeyboardEnabled(newDeleteButtonEnabledState)
    deleteBtn:SetEnabled(newDeleteButtonEnabledState)
end

--Change the pack save buttons's enabled state
local function ChangeSaveButtonEnabledState(newEnabledState)
    newEnabledState = newEnabledState or false
    --Enable/Disable the "Save" button
    local saveButton = AddonSelector.saveBtn
    if saveButton then
        saveButton:SetEnabled(newEnabledState)
        saveButton:SetMouseEnabled(newEnabledState)
        saveButton:SetKeyboardEnabled(newEnabledState)
    end
end

local function clearAndUpdateDDL(wasDeleted)
--d("[AddonSelector]clearAndUpdateDDL - wasDeleted: " ..tostring(wasDeleted))
    AddonSelector:UpdateDDL(wasDeleted)
    AddonSelector.editBox:Clear()
    --Disable the "delete pack" button
    ChangeDeleteButtonEnabledState(nil, false)
end

--Select/Deselect all addon checkboxes
function AddonSelector_SelectAddons(selectAll)
--d("[AddonSelector]AddonSelector_SelectAddons - selectAll: " ..tostring(selectAll))
    if not areAllAddonsEnabled(false) then return end
    if not ZOAddOnsList or not ZOAddOnsList.data then return end

    local selectAllSave = AddonSelector.acwsv.selectAllSave
    local selectSavedText = AddonSelector_GetLocalizedText("SelectAllAddonsSaved")
    local selectAllText = AddonSelector_GetLocalizedText("SelectAllAddons")

    --Copy the AddOns list
    local addonsListCopy = ZO_ShallowTableCopy(ZOAddOnsList.data)
    --TODO: For debugging
    --AddonSelector._addonsListCopy = addonsListCopy
    --local addonsList = ZOAddOnsList.data

    --Only if not all entries should be selected
    if not selectAll then
        addonIndicesOfAddonsWhichShouldNotBeDisabled = {}

        --d(">Sorting addon table and finding index")
        --Sort the copied addons list by type (headlines etc. to the end, sort by addonFileName or cleanAddonName)
        tsor(addonsListCopy, function(a,b)
            --headlines etc: Move to the end
            if a.typeId == nil or a.typeId ~= 1 then
                --d(">>Comp skipped a: " ..tostring(a.typeId))
                return false
                --AddonFileName (TXT filename) is provided? Sort by that
            elseif a.data.addOnFileName ~= nil then
                local addonFileName = a.data.addOnFileName
                --d(">>Comp file idx " .. tostring(a.data.index) .. " a: " ..tostring(addonFileName) .. ", b: " ..tostring(b.data.addOnFileName))
                --Find AddonSelector and other dependencies indices
                local addonIndex = a.data.index
                if addonIndex ~= nil then
                    if thisAddonIndex == 0 and addonFileName == ADDON_NAME then
                        thisAddonIndex = addonIndex
                        --d(">>>Found AddonSelector at addonIdx: " ..tostring(addonIndex) .. ", addOnFileName: " ..tostring(addonFileName))
                    elseif addonsWhichShouldNotBeDisabled[addonFileName] then
                        addonIndicesOfAddonsWhichShouldNotBeDisabled[addonIndex] = true
                        --d(">>>Found dependency at addonIdx: " ..tostring(addonIndex) .. ", addOnFileName: " ..tostring(addonFileName))
                    end
                end

                if not b.data.addOnFileName then return true end
                return a.data.addOnFileName < b.data.addOnFileName
            elseif a.data.strippedAddOnName ~= nil then
                --d(">>Comp name a: " ..tostring(a.data.strippedAddOnName) .. ", b: " ..tostring(b.data.strippedAddOnName))
                if not b.data.strippedAddOnName then return true end
                --Sort by "clean" (no color coding etc.) addon name
                return a.data.strippedAddOnName < b.data.strippedAddOnName
            else
                --Nothing to compare
                return false
            end
        end)

        --Save the currently enabled addons for a later re-enable
        selectAllSave = {}
        for _,v in ipairs(addonsListCopy) do
            local vData = v.data
            local vDataIndex = vData ~= nil and vData.index
            if vDataIndex ~= nil then
                selectAllSave[vDataIndex] = vData.addOnEnabled
            end
        end

        --Restore from saved addons (after some were disabled already -> re-enable them again) or disable all?
        local fullHouse = true
        local emptyHouse = true
        for i,v in ipairs(selectAllSave) do
            if i ~= thisAddonIndex and not addonIndicesOfAddonsWhichShouldNotBeDisabled[i] then
                if not v then fullHouse = false
                else emptyHouse = false end
            end
        end
        if not fullHouse and not emptyHouse then
            AddonSelectorSelectAddonsButton:SetText(selectSavedText)
        else
            AddonSelectorSelectAddonsButton:SetText(selectAllText)
        end
    end --if not selectAll

    local isSelectAddonsButtonTextEqualSelectedSaved = (selectAll == true and AddonSelectorSelectAddonsButton.nameLabel:GetText() == selectSavedText and true) or false

    local numAddons = AddOnManager:GetNumAddOns()
    for i = 1, numAddons do
        local name = AddOnManager:GetAddOnInfo(i)
--d(">addonIdx: " ..tostring(i) .. ", addOnFileName: " ..tostring(name))
        if selectAll == true or (i ~= thisAddonIndex and not addonIndicesOfAddonsWhichShouldNotBeDisabled[i]) then
            if isSelectAddonsButtonTextEqualSelectedSaved == true then -- Are we restoring from save?
--d(">>restoring previously saved")
                AddOnManager:SetAddOnEnabled(i, selectAllSave[i])
            else -- Otherwise continue as normal: enabled/disable addon via "selectAll" boolean flag
--d(">>selectAll: " ..tostring(selectAll))
                AddOnManager:SetAddOnEnabled(i, selectAll)
            end
        end
    end

    --Update the flag for the filters and resort of the addon list
    ZO_AddOnManager.isDirty = true
    SM:RemoveFragment(ADDONS_FRAGMENT)
    SM:AddFragment(ADDONS_FRAGMENT)
end

--Scroll the scrollbar to an index
local function scrollAddonsScrollBarToIndex(index, animateInstantly)
    if ADD_ON_MANAGER ~= nil and ADD_ON_MANAGER.list ~= nil and ADD_ON_MANAGER.list.scrollbar ~= nil then
        --ADD_ON_MANAGER.list.scrollbar:SetValue((ADD_ON_MANAGER.list.uniformControlHeight-0.9)*index)
        --ZO_Scroll_ScrollAbsolute(self, value)
        local onScrollCompleteCallback = function() end
        animateInstantly = animateInstantly or false
        ZO_ScrollList_ScrollDataIntoView(ADD_ON_MANAGER.list, index, onScrollCompleteCallback, animateInstantly)
    end
end

local function unregisterOldEventUpdater(p_sortIndexOfControl, p_addSelection)
    --Disable the check for the control for the last index so it will not be skipped and thus active for ever!
    local activeUpdateControlEvents = AddonSelector.activeUpdateControlEvents
    if activeUpdateControlEvents ~= nil then
        for index, eventData in ipairs(activeUpdateControlEvents) do
            local lastEventUpdateName
            if p_sortIndexOfControl == nil and p_addSelection == nil then
                lastEventUpdateName = "AddonSelector_ChangeZO_AddOnsList_Row_Index_" ..tostring(eventData.sortIndex) .. "_" .. tostring(eventData.addSelection)
            else
                if eventData.sortIndex == p_sortIndexOfControl and eventData.addSelection == p_addSelection then
                    lastEventUpdateName = "AddonSelector_ChangeZO_AddOnsList_Row_Index_" ..tostring(eventData.sortIndex) .. "_" .. tostring(eventData.addSelection)
                end
            end
            if lastEventUpdateName ~= nil then
                --Unregister the update function again now
                EM:UnregisterForUpdate(lastEventUpdateName)
--d("<<Unregistered old events for: " ..tostring(eventData.sortIndex) .. ", " ..  tostring(eventData.addSelection))
                --Remove the entry from the table again
                activeUpdateControlEvents[index]= nil
            end
        end
    end
end

local function eventUpdateFunc(p_sortIndexOfControl, p_addSelection, p_eventUpdateName)
    if p_eventUpdateName == nil then return end
    if p_sortIndexOfControl == nil then return end
    p_addSelection = p_addSelection or false
    --Change the shown row name and put [ ] around the addon name so one sees the currently selected row
    local addonList = ZOAddOnsList.data
    if addonList == nil then return end
    if addonList[p_sortIndexOfControl] == nil then return false end
    local selectedAddonControl = addonList[p_sortIndexOfControl].control
    if selectedAddonControl ~= nil then
        local selectedAddonControlName = selectedAddonControl:GetNamedChild("Name")
        if selectedAddonControlName.GetText ~= nil and selectedAddonControlName.SetText ~= nil then
            local currentAddonText
            local newAddonText
            if p_addSelection then
                currentAddonText = selectedAddonControlName:GetText()
                newAddonText = "|cFF0000[>|r " .. currentAddonText .. " |cFF0000<]|r"
            else
                local selectedAddonData = addonList[p_sortIndexOfControl].data
                newAddonText = selectedAddonData.addOnName
            end
            selectedAddonControlName:SetText(newAddonText)
            --Unregister the update function again now
            EM:UnregisterForUpdate(p_eventUpdateName)
--d("<<Control was found and changed, unregistering event updater: " ..tostring(p_eventUpdateName))
            --Remove the entry of enabled event updater again
            unregisterOldEventUpdater(p_sortIndexOfControl, p_addSelection)
        end
    else
--d(">>Control not found: " ..tostring(p_sortIndexOfControl))
    end
end

local function changeAddonControlName(sortIndexOfControl, addSelection)
    addSelection = addSelection or false
    if sortIndexOfControl == nil then return false end
    --Disable the update checks for the last control (sortIndices) so it will not be skipped and thus be active for ever!
    unregisterOldEventUpdater()
    --Refresh the visible controls so their names get resetted to standard
    if addSelection then
        ADD_ON_MANAGER:RefreshVisible()
    end
    --Enable the check function which will try to find the addon list row control every 100ms
    local eventUpdateName = "AddonSelector_ChangeZO_AddOnsList_Row_Index_" ..tostring(sortIndexOfControl) .. "_" .. tostring(addSelection)
    EM:UnregisterForUpdate(eventUpdateName)
    local eventWasRegistered = EM:RegisterForUpdate(eventUpdateName, 100, function()
--d(">Calling RegisterForUpdateFunc: " ..tostring(eventUpdateName))
        eventUpdateFunc(sortIndexOfControl, addSelection, eventUpdateName)
    end)
    if eventWasRegistered then
        local activeUpdateControlEvents = AddonSelector.activeUpdateControlEvents
        if activeUpdateControlEvents ~= nil then
            --Add this event to the currently active list
            local eventData = {
                ["sortIndex"]       = sortIndexOfControl,
                ["addSelection"]    = addSelection,
            }
            tins(activeUpdateControlEvents, eventData)
--d(">Event was registeerd: " ..tostring(eventUpdateName))
        end
    end
end

local function updateSearchHistory(searchType, searchValue)
    local settings = AddonSelector.acwsv
    local maxSearchHistoryEntries = settings.searchHistoryMaxEntries
    local searchHistory = settings.searchHistory
    searchHistory[searchType] = searchHistory[searchType] or {}
    local searchHistoryOfSearchType = searchHistory[searchType]
    local toSearch = strlow(searchValue)
    if not ZO_IsElementInNumericallyIndexedTable(searchHistoryOfSearchType, toSearch) then
        --Only keep the last 10 search entries
        tins(searchHistory[searchType], 1, searchValue)
        local countEntries = #searchHistory[searchType]
        if countEntries > maxSearchHistoryEntries then
            for i=maxSearchHistoryEntries+1, countEntries, 1 do
                searchHistory[searchType][i] = nil
            end
        end
    end
end

local searchHistoryEventUpdaterName = "AddonSelector_SearchHistory_Update"
local function updateSearchHistoryDelayed(searchType, searchValue)
    EM:UnregisterForUpdate(searchHistoryEventUpdaterName)
    EM:RegisterForUpdate(searchHistoryEventUpdaterName, 1500, function()
        EM:UnregisterForUpdate(searchHistoryEventUpdaterName)
        updateSearchHistory(searchType, searchValue)
    end)
end

local function clearSearchHistory(searchType)
    local settings = AddonSelector.acwsv
    local searchHistory = settings.searchHistory
    if not searchHistory[searchType] then return end
    settings.searchHistory[searchType] = nil
end

--Search for addons by e.g. name and scroll the list to the found addon, or filter (hide) all non matching addons
function AddonSelector_SearchAddon(searchType, searchValue, doHideNonFound)
    searchType = searchType or SEARCH_TYPE_NAME
    doHideNonFound = doHideNonFound or false
--d("[AddonSelector]SearchAddon, searchType: " .. tostring(searchType) .. ", searchValue: " .. tostring(searchValue) .. ", hideNonFound: " ..tostring(doHideNonFound))
    local addonList = ZOAddOnsList.data
    if addonList == nil then return end
    local isEmptySearch = searchValue == ""
    local toSearch = (not isEmptySearch and strlow(searchValue)) or searchValue
    local settings = AddonSelector.acwsv
    local searchExcludeFilename = settings.searchExcludeFilename
    local searchSaveHistory = settings.searchSaveHistory
    if searchSaveHistory == true and not isEmptySearch then
        updateSearchHistoryDelayed(searchType, searchValue)
    end

    local addonsFound = {}
    local alreadyFound = AddonSelector.alreadyFound
    --No search term given
    if isEmptySearch then
        --Refresh the visible controls so their names get resetted to standard
        ADD_ON_MANAGER:RefreshVisible()
        --Reset the searched table completely
        AddonSelector.alreadyFound = {}
        --Unregister all update events
        unregisterOldEventUpdater()
        return
    end
    for _, addonDataTable in ipairs(addonList) do
        local addonData = addonDataTable.data
        if addonData and addonData.index ~= nil and addonData.sortIndex ~= nil then
            local stringFindResult
            local stringFindCleanResult
            local stringFindResultFile
            if searchType == SEARCH_TYPE_NAME then
                local addonName = strlow(addonData.addOnName)
                local addonCleanName = strlow(addonData.strippedAddOnName )
                local addonFileName = strlow(addonData.addOnFileName)
                --stringFindResult = (string.find(addonFileName, toSearch) or string.find(addonName, toSearch)) or nil
                --stringFindResult = string.find(addonName, toSearch) or nil
                stringFindResult = zopsf(addonName, toSearch) or nil
                stringFindCleanResult = zopsf(addonCleanName, toSearch) or nil
                stringFindResultFile = (not searchExcludeFilename and zopsf(addonFileName, toSearch)) or nil
--d(">addonName: " .. tostring(addonName) .. ", addonFileName: " .. tostring(addonFileName) .. ", search: " .. tostring(toSearch) .. ", found: " .. tostring(stringFindResult))
            end
            --Result of the search
            if stringFindResult ~= nil or stringFindCleanResult ~= nil or stringFindResultFile ~= nil then
                --Hide the non found addons?
                if doHideNonFound then
                    --Add the found addon indices to the "show list"
                    local newEntryIndex = #addonsFound+1
                    addonsFound[newEntryIndex] = {}
                    addonsFound[newEntryIndex] = addonData

                --Scroll to the found addon?
                else
                    local sortIndex = addonData.sortIndex
                    --Check if the addon was found before and scroll to another one then, if there are multiple with the name
                    local wasFoundBefore = false
                    local wasAddedBefore = false
                    if alreadyFound[toSearch] ~= nil then
                        --Check each entry in the list
                        for _, scrolledToData in ipairs(alreadyFound[toSearch]) do
                            if scrolledToData[sortIndex] ~= nil then
                                wasAddedBefore = true
                                if scrolledToData[sortIndex] == true then
                                    wasFoundBefore = true
                                    break -- exit the loop
                                end
                            end
                        end
                    end
                    --Addon was not found before
                    if not wasAddedBefore and not wasFoundBefore then
                        --Add the found addon to the already found, but not scrolled-to list
                        AddonSelector.alreadyFound[toSearch] = AddonSelector.alreadyFound[toSearch] or {}
                        tins(AddonSelector.alreadyFound[toSearch], {[sortIndex] = false})
                    end
                end
            end
        end
    end
    --All sortIndex entries matching the search string were added to teh table alreadyFound[searchTerm] with the value false
    --Check all found sortIndices and use the first one for the next scroll, where the value is false
    if alreadyFound[toSearch] ~= nil then
--d(">found toSearch entries: " ..tostring(#alreadyFound[toSearch]))
        for index, wasScrolledToBeforeData in ipairs(alreadyFound[toSearch]) do
            for scrollToIndex, wasScrolledToBefore in pairs(wasScrolledToBeforeData) do
                if wasScrolledToBefore == false then
--d(">scrolling to index: " ..tostring(scrollToIndex))
                    --Scroll to the found addon now, if it was not found before
                    scrollAddonsScrollBarToIndex(scrollToIndex)
                    --Set this entry to true so we know a scroll-to has taken place already to this sortIndex
                    AddonSelector.alreadyFound[toSearch][index][scrollToIndex] = true
                    --Check if all entries in the list are true now, so we scrolled to all of them already. Clear the list then
                    local trueCounter = 0
                    local entryCounter = 0
                    for _, wasScrolledToBeforeAllTrueData in ipairs(alreadyFound[toSearch]) do
                        for _, wasScrolledToBeforeAllTrue in pairs(wasScrolledToBeforeAllTrueData) do
                            if wasScrolledToBeforeAllTrue == true then trueCounter = trueCounter + 1 end
                            entryCounter = entryCounter + 1
                        end
                    end
                    --Are all entries in this search term table true?
                    local resetWasDone = false
                    if trueCounter~=0 and entryCounter~=0 and trueCounter == entryCounter then
                        --Reset the search term table for a new scroll-to from the beginning
                        AddonSelector.alreadyFound[toSearch] = nil
                        resetWasDone = true
                    end
                    --Change the shown row name and put [ ] around the addon name so one sees the currently selected row
                    --[[
                    local scrollbar = ZOAddOnsList.scrollbar
                    local delay = 100
                    if scrollbar ~= nil then
                        local currentScrollBarPosition = scrollbar:GetValue()
                        local approximatelyCurrentAddonSortIndex = currentScrollBarPosition / ZOAddOnsList.uniformControlHeight
                        if approximatelyCurrentAddonSortIndex < 0 then approximatelyCurrentAddonSortIndex = 0 end
                        --Scroll to index is bigger than then approximately current selected addon's scrollIndex
                        if scrollToIndex > approximatelyCurrentAddonSortIndex then
                            delay = (scrollToIndex - approximatelyCurrentAddonSortIndex) * 4
                        else
                            --Are we near the end of the list and it needs to scroll up again
                            if resetWasDone then
                                delay = 350
                            else
                                delay = (approximatelyCurrentAddonSortIndex - scrollToIndex) * 4
                            end
                        end
d(">scrollToIndex: " ..tostring(scrollToIndex) .. ", approximatelyCurrentAddonSortIndex: " ..tostring(approximatelyCurrentAddonSortIndex) .. ", delay: " ..tostring(delay))
                        if delay < 0 then delay = 100 end
                        if delay > 500 then delay = 500 end
                    end
                    zo_callLater(function()
                        changeAddonControlName(scrollToIndex, true)
                    end, delay)
                    ]]
                    changeAddonControlName(scrollToIndex, true)
                    --Abort now as scroll-to was done
                    return
                end
            end
        end
    end
end

local function showAddOnsList()
    if not SM then return end
    if not ADDONS_FRAGMENT then return end
    if ADDONS_FRAGMENT and ADDONS_FRAGMENT.control and not ADDONS_FRAGMENT.control:IsHidden() then return end
    --Show the game menu (as if you have pressed ESC key)
    ZO_SceneManager_ToggleGameMenuBinding()
    --Show the addons
    SM:AddFragment(ADDONS_FRAGMENT)
    return true
end

local function openGameMenuAndAddOnsAndThenSearch(addonName, doNotShowAddOnsScene)
    if not addonName or addonName == "" then return end
    doNotShowAddOnsScene = doNotShowAddOnsScene or false
    if not doNotShowAddOnsScene then
        --Show the game menu and open the AddOns
        if not showAddOnsList() then return end
    end
    --Set the focus to the addon search box
    local searchBox = AddonSelector.searchBox
    if searchBox then
        searchBox:SetText(addonName)
        searchBox:TakeFocus()
    end
    --Search for the addonName
    AddonSelector_SearchAddon(SEARCH_TYPE_NAME, addonName, false)
end

--Add the active addon count to the header text
local function AddonSelectorUpdateCount(delay)
--d("[AddonSelector]AddonSelectorUpdateCount, noAddonNumUpdate: " .. tostring(AddonSelector.noAddonNumUpdate))
    if AddonSelector.noAddonNumUpdate then return false end
    delay = delay or 100
    zo_callLater(function()
        if not ZOAddOnsList or not ZOAddOnsList.data then return false end
        local addonRows = ZOAddOnsList.data
        if addonRows == nil then return false end
        local countFound = 0
        local countActive = 0
        if ADDON_MANAGER == nil then ADDON_MANAGER = GetAddOnManager() end
        if ADDON_MANAGER == nil then return false end
        countFound = ADDON_MANAGER:GetNumAddOns()
        for _, addonRow in ipairs(addonRows) do
            if addonRow.data then
                --countFound = countFound + 1
                if not addonRow.data.hasDependencyError and addonRow.data.addOnEnabled and addonRow.data.addOnEnabled == true then
                    countActive = countActive + 1
                end
            end
        end
        --Update the addon manager title with the number of active/total addons
        --d("[AddonSelector] active/found: " .. tostring(countActive) .. "/" .. tostring(countFound))
        ZO_AddOnsTitle:SetText(GetString(SI_WINDOW_TITLE_ADDON_MANAGER) .. " (" .. tostring(countActive) .. "/" .. tostring(countFound) .. ")")
    end, delay)
end

--Function to build the reverse lookup table for sortIndex to addonIndex
local function BuildAddOnReverseLookUpTable()
    if ZOAddOnsList ~= nil and ZOAddOnsList.data ~= nil then
        --Build the lookup table for the sortIndex to nrow index of addon rows
        AddonSelector.ReverseLookup = {}
        for i,v in ipairs(ZOAddOnsList.data) do
            if v.data.sortIndex ~= nil and v.data.index ~= nil then
                AddonSelector.ReverseLookup[v.data.sortIndex] = v.data.index
            end
        end
    end
end

local function AddonSelector_MultiSelect(control, addonEnabledCBox, button)
--d("AddonSelector_MultiSelect")
    if button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
    if addonEnabledCBox == nil then return false end
    --Get the current's row data
    --local addonRowControl = addonEnabledCBox:GetParent()
    local addonRowControl = control
    if addonRowControl == nil or addonRowControl.data == nil
            or addonRowControl.data.sortIndex == nil or addonRowControl.data.index == nil then return false end
    --Is the shift key pressed on the keyboard?
    local isShiftDown = IsShiftKeyDown()
    local isAddonEnabled = addonEnabledCBox.checkState
--d("[AddonSelector]AddonSelector_MultiSelect(" .. addonRowControl:GetName() .. ", button: " .. tostring(button) .. "), isShiftDown: " ..tostring(isShiftDown) .. ", enabled: " .. tostring(isAddonEnabled))
    --Shift not pressed: Remember the currently clicked control as first one + remember it's data as table copy so it won't change with the next "scroll" indside the addonlist,
    --as the addon list rows are re-used during scroll (they belong to a control pool)!
    if not isShiftDown then
        AddonSelector.firstControl      = addonRowControl
        local currentAddonRowData       = ZO_ShallowTableCopy(addonRowControl.data)
        AddonSelector.firstControlData  = currentAddonRowData
--d(">no shift key pressed -> First control was set to: " ..tostring(ZOAddOnsList.data[currentAddonRowData.sortIndex].data.strippedAddOnName))
        return false
    end

    local firstClickedControl = AddonSelector.firstControl
    --Not the current row clicked and shift key was pressed: The actually clicked row is the "to" range row
    if isShiftDown and (firstClickedControl and addonRowControl ~= firstClickedControl) then
--d(">Shift key was pressed and addonRow is not the same as the first pressed one")
        local firstRowData = AddonSelector.firstControlData
        if firstRowData == nil or firstRowData.sortIndex == nil then return false end
        local firstControlAddonName     = ZOAddOnsList.data[firstRowData.sortIndex].data.strippedAddOnName
        local currentRowData = addonRowControl.data
        local currentControlAddonName   = ZOAddOnsList.data[currentRowData.sortIndex].data.strippedAddOnName
--d(">Trying to mark from \"" .. tostring(firstControlAddonName) .. "\" to \"" .. tostring(currentControlAddonName).."\"")

        local step = ((firstRowData.sortIndex - currentRowData.sortIndex < 0) and 1) or -1
        --is the reverse addonIndex lookup table empty? Build it.
        if AddonSelector.ReverseLookup == nil then
            BuildAddOnReverseLookUpTable()
        end
        --From the first selected row to the currently selected row with SHIFT key pressed:
        -- loop forwards/backwards and simulate the click on the enable/disable checkbox
        local checkBoxNewState = true
        if firstRowData.addOnEnabled == true then checkBoxNewState = false end
--d(">From sortIndex: " .. tostring(firstRowData.sortIndex) .. " to sortindex: " .. tostring(currentRowData.sortIndex) .. ", step: " .. tostring(step) .. ", enabledNew: " .. tostring(checkBoxNewState))
        --Disable the update of the addon count during the loop, to avoid lags
        AddonSelector.noAddonNumUpdate = true
        --local checkState = (firstRowData.addOnEnabled == true and TRISTATE_CHECK_BUTTON_CHECKED) or TRISTATE_CHECK_BUTTON_UNCHECKED
        AddonSelector.lastChangedAddOnVars = {}
        for addonSortIndex = firstRowData.sortIndex, currentRowData.sortIndex, step do
            local currentAddonListRowData = ZOAddOnsList.data[addonSortIndex].data
            if currentAddonListRowData then
--d(">>currentRowData: " ..tostring(currentAddonListRowData.sortIndex) .. ", name: "..tostring(currentAddonListRowData.strippedAddOnName))
                --Get the addon index
                local addonIndex = AddonSelector.ReverseLookup[addonSortIndex]
                if addonIndex ~= nil and addonIndex >= 0 then
                    --d(">>sortIndex: " .. tostring(addonSortIndex) .. ", addonIndex: " .. tostring(addonIndex))
                    --Check if the addon got dependencies that need to be enabled if the addon will be enabled
                    local changeCheckboxNow = false
                    --Only if not the last clicked entry was met: Will be always checked and updated after the addonManager data was refreshed as the click on the
                    --name / checkbox changes the row already manually
                    if addonSortIndex ~= currentRowData.sortIndex then
                        if checkBoxNewState == true then
                            if currentAddonListRowData.addOnState ~= ADDON_STATE_ENABLED and not currentAddonListRowData.missing then
                                changeCheckboxNow = true
                                checkDependsOn(currentAddonListRowData)
                            end
                        else
                            if currentAddonListRowData.addOnState == ADDON_STATE_ENABLED and not currentAddonListRowData.missing then
                                changeCheckboxNow = true
                            end
                        end
                    else
                        changeCheckboxNow = true
                    end
                    --Set the state off the addon's enable/disable checkbox the same like first row state
                    if changeCheckboxNow == true then
                        AddOnManager:SetAddOnEnabled(addonIndex, checkBoxNewState)
                    end
                    --Variables for the check if the last changed AddOn's state is the same as the wished one. If not: Change it accordingly.
                    if changeCheckboxNow == true and addonSortIndex == currentRowData.sortIndex then
--d(">>>lastChangdAddOnVars: " .. tostring(addonSortIndex) .. ", addonIndex: " .. tostring(addonIndex))
                        AddonSelector.lastChangedAddOnVars.sortIndex        = addonSortIndex
                        AddonSelector.lastChangedAddOnVars.addonIndex       = addonIndex
                        AddonSelector.lastChangedAddOnVars.addonNewState    = checkBoxNewState
                    end
                end
            end
        end
        --Enable the update of the addon count after the loop again
        AddonSelector.noAddonNumUpdate = false
        --Refresh the visible data
        ADD_ON_MANAGER:RefreshData()
        ZO_ScrollList_RefreshVisible(ZOAddOnsList)
        return true
    else
        --Reset the first clicked data if the SHIFT key was pressed
        if isShiftDown then
--d(">Clicked with SHIFT key. Resetting first clicked data")
            AddonSelector.firstControlData = nil
            AddonSelector.firstClickedControl = nil
        end
    end
    return false
end

--Function to check if the last changed AddOn's state is the same as the wished one. If not: Change it accordingly.
local function AddonSelector_CheckLastChangedMultiSelectAddOn(rowControl)
--d("[AddonSelector]AddonSelector_CheckLastChangedMultiSelectAddOn")
    local lastChangedAddOnVars = AddonSelector.lastChangedAddOnVars
    if lastChangedAddOnVars ~= nil and lastChangedAddOnVars.addonIndex ~= nil and lastChangedAddOnVars.addonNewState ~= nil and lastChangedAddOnVars.sortIndex ~= nil then
--d(">addonIndex: " .. tostring(lastChangedAddOnVars.addonIndex) .. ", newState: " .. tostring(lastChangedAddOnVars.addonNewState))
        local preventerVarsWereSet = (AddonSelector.noAddonNumUpdate or AddonSelector.noAddonCheckBoxUpdate) or false
        if not preventerVarsWereSet then
            AddonSelector.noAddonNumUpdate = true
            AddonSelector.noAddonCheckBoxUpdate = true
        end
        local newState = lastChangedAddOnVars.addonNewState
        local currentAddonListRowData = ZOAddOnsList.data[lastChangedAddOnVars.sortIndex].data
        if not currentAddonListRowData then return end
        local changeCheckboxNow = false
        if newState == true then
--d(">newState: true")
            if currentAddonListRowData.addOnState ~= ADDON_STATE_ENABLED and not currentAddonListRowData.missing then
                changeCheckboxNow = true
                checkDependsOn(currentAddonListRowData)
            end
        else
--d(">newState: false")
            if currentAddonListRowData.addOnState == ADDON_STATE_ENABLED and not currentAddonListRowData.missing then
                changeCheckboxNow = true
            end
        end
        if changeCheckboxNow == true then
--d(">Changing last addon now: " ..tostring(currentAddonListRowData.strippedAddOnName))
            AddOnManager:SetAddOnEnabled(lastChangedAddOnVars.addonIndex, newState)
            --Addon_Toggle_Enabled(rowControl)
            if not preventerVarsWereSet then
                AddonSelector.noAddonNumUpdate = false
                AddonSelector.noAddonCheckBoxUpdate = false
            end
        end
        --Refresh the visible data
        ADD_ON_MANAGER:RefreshData()
        ZO_ScrollList_RefreshVisible(ZOAddOnsList)
        --Update the active addons count
        AddonSelectorUpdateCount(50)
    end
end

--[[
--Enable the multiselect of addons via the SHIFT key
--Parameters: _ = eventCode,  a = layerIndex,  b = activeLayerIndex
local function AddonSelector_HookForMultiSelectByShiftKey()--eventCode, layerIndex, activeLayerIndex)
--d("[AddonSelector]AddonSelector_HookForMultiSelectByShiftKey")
    --if not (layerIndex == 17 and activeLayerIndex == 5) then return end
    for i, control in pairs(ZOAddOnsList.activeControls) do
        local name = control:GetNamedChild("Name")
        if name ~= nil then
            local enabled = control:GetNamedChild("Enabled")
            if enabled ~= nil then
                ZO_PreHookHandler(enabled, "OnClicked", function(self, button)
--d("[Enabled checkbox - OnClicked]")
                    --Do not run the same code (AddonSelector_MultiSelect) again if we come from the left mouse click on the name control
                    if AddonSelector.noAddonCheckBoxUpdate or button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
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
                    AddonSelector.noAddonNumUpdate = true
                    AddonSelector.noAddonCheckBoxUpdate = true
                    enabledClick(enabled, button)
                    if retVar == true then
                        zo_callLater(function()
                            AddonSelector_CheckLastChangedMultiSelectAddOn(control)
                        end, 150)
                    end
                    AddonSelector.noAddonCheckBoxUpdate = false
                    AddonSelector.noAddonNumUpdate = false
                end)
            end
        end
    end
end
]]

local alreadyAddedMultiSelectByShiftKeyHandlers = {}
local function AddonSelector_HookSingleControlForMultiSelectByShiftKey(control)--eventCode, layerIndex, activeLayerIndex)
    if not control or not control.GetName then return end
    local controlName = control:GetName()
    if alreadyAddedMultiSelectByShiftKeyHandlers[controlName] then return end
    alreadyAddedMultiSelectByShiftKeyHandlers[controlName] = true

--d("[AddonSelector]AddonSelector_HookSingleControlForMultiSelectByShiftKey: " ..tostring(controlName))
    local name = control:GetNamedChild("Name")
    if name ~= nil then
        local enabled = control:GetNamedChild("Enabled")
        if enabled ~= nil then
            ZO_PreHookHandler(enabled, "OnClicked", function(self, button)
                --d("[Enabled checkbox - OnClicked]")
                --Do not run the same code (AddonSelector_MultiSelect) again if we come from the left mouse click on the name control
                if button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
                if not areAllAddonsEnabled(true) then return end

                --Check shift key, or not. If yes: Mark/unmark all addons from first clicked row to SHIFT + clicked row.
                -- Else save clicked name sortIndex + addonIndex
                --[[
                local retVar = AddonSelector_MultiSelect(control, self, button)
                if retVar == true then
                    zo_callLater(function()
                        AddonSelector_CheckLastChangedMultiSelectAddOn(control)
                    end, 150)
                end
                ]]
                --If the shift key was pressed do not enable the addon's checkbox by the normal function here but via function
                --AddonSelector_MultiSelect())
                return IsShiftKeyDown()
            end)
            local enabledClick = enabled:GetHandler("OnClicked")
            name:SetMouseEnabled(true)
            name:SetHandler("OnMouseDown", nil)
            name:SetHandler("OnMouseDown", function(self, button)
                if button ~= MOUSE_BUTTON_INDEX_LEFT then return false end
                if not areAllAddonsEnabled(true) then return end
                --Check shift key, or not. If yes: Mark/unmark all addons from first clicked row to SHIFT + clicked row.
                -- Else save clicked name sortIndex + addonIndex
                local retVar = AddonSelector_MultiSelect(control, enabled, button)
                --Set preventer variables in order to suppress duplicate code run at the checkbox
                AddonSelector.noAddonNumUpdate = true
                AddonSelector.noAddonCheckBoxUpdate = true
                --Simulate a click on the checkbox left to the addon's name
                enabledClick(enabled, button)
                if retVar == true then
                    zo_callLater(function()
                        AddonSelector_CheckLastChangedMultiSelectAddOn(control)
                    end, 150)
                end
                AddonSelector.noAddonCheckBoxUpdate = false
                AddonSelector.noAddonNumUpdate = false
            end)
        end
    end
end

--Function to show a confirmation dialog
local function ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, callbackSetup, data, forceUpdate)
    --Initialize the library
    if AddonSelector.LDIALOG == nil then
        AddonSelector.LDIALOG = LibDialog
    end
    if not AddonSelector.LDIALOG then
        d("[AddonSelector]"..langArrayInClientLang["LibDialogMissing"] or langArrayInFallbackLang["LibDialogMissing"])
        return
    end
    local libDialog = AddonSelector.LDIALOG
    --Force the dialog to be updated with the title, text, etc.?
    forceUpdate = forceUpdate or false
    --Check if the dialog exists already, and if not register it
    local existingDialogs = libDialog.dialogs
    if forceUpdate or existingDialogs[ADDON_NAME] == nil or existingDialogs[ADDON_NAME][dialogName] == nil then
        libDialog:RegisterDialog(ADDON_NAME, dialogName, title, body, callbackYes, callbackNo, callbackSetup, forceUpdate)
    end
    --Show the dialog now
    libDialog:ShowDialog(ADDON_NAME, dialogName, data)
end

-- When an item is selected in the comboBox go through all available
-- addons & compare them against the selected addon pack.
-- Enable all addons that are in the selected addon pack, disable the rest.
local function OnClickDDL(comboBox, packName, packData, selectionChanged)
	-- Clear the edit box:
	AddonSelector.editBox:Clear()

    --TODO: Remove after debugging
    AddonSelector.SelectedPackData = packData

	local addonTable = packData.addonTable
	local scrollListData = ZO_ScrollList_GetDataList(ZOAddOnsList)

	local changed = true
	local numScrollListData = #scrollListData
	-- loop until all dependencies are solved.
	while changed do
		changed = false
		for k = 1, numScrollListData do
			local addonData = scrollListData[k]
			local addondataData = addonData.data
			local fileName = addondataData.addOnFileName
            local addonIndex = addondataData.index

			local addonShouldBeEnabled = addonTable[fileName] ~= nil
            if addonShouldBeEnabled ~= addondataData.addOnEnabled and addonIndex and fileName then
				AddOnManager:SetAddOnEnabled(addonIndex, addonShouldBeEnabled)
				local enabled = select(5, AddOnManager:GetAddOnInfo(addonIndex))
				addonData.data.addOnEnabled = enabled
				if enabled then changed = true end
			end
		end
	end

    if not doNotReloadUI and AddonSelector.acwsv.autoReloadUI == true then
        --Set the currently selected packname
        SetCurrentCharacterSelectedPackname(packName, packData)
		ReloadUI("ingame")
	else
		ADD_ON_MANAGER:RefreshData()
		ADD_ON_MANAGER.isDirty = true
		ADD_ON_MANAGER:RefreshMultiButton()
        --Enable the delete button
        ChangeDeleteButtonEnabledState(nil, true)
        --Set the currently selected packname
        SetCurrentCharacterSelectedPackname(packName, packData)
        --Update the currently selected packName label
        UpdateCurrentlySelectedPackName(nil, packName, packData)
        --Enable the save pack button
        ChangeSaveButtonEnabledState(true)
	end
end

-- Create ItemEntry table for the ddl
function AddonSelector:CreateItemEntry(packName, addonTable, isCharacterPackHeader, charName)
	return {name = packName, callback = OnClickDDL, addonTable = addonTable, isCharacterPackHeader=isCharacterPackHeader, charName=charName}
end

-- Called on load or when a new addon pack is saved & added to the comboBox
-- Clear & re-add all items, including new ones. Easier/quicker than
-- trying to see if an item already exists & editing it. Just adding
-- a new item would result in duplicates when editing a pack.
function AddonSelector:UpdateDDL(wasDeleted)
    wasDeleted = wasDeleted or false
    --local addonPacks = AddonSelector.acwsv.addonPacks
    local packTable = {}
    local settings = AddonSelector.acwsv
    local wasItemAdded = false

    --Show the addon packs saved per character?
    if settings.showGroupedByCharacterName == true or settings.saveGroupedByCharacterName == true then
        for _, addonPacks in pairs(settings.addonPacksOfChar) do
            local charName = addonPacks._charName
            local itemData = self:CreateItemEntry("[" .. charName .. "]", addonPacks, true, charName)
            tins(packTable, itemData)
            wasItemAdded = true
        end
    end

    --Show the addon packs saved without character?
    if settings.showGlobalPacks == true then
        for packName, addonTable in pairs(settings.addonPacks) do
            local itemData = self:CreateItemEntry(packName, addonTable, false, GLOBAL_PACK_NAME)
            tins(packTable, itemData)
            wasItemAdded = true
        end
    end

    self.comboBox:SetSortsItems(false)
    self.comboBox:ClearItems()

    if wasItemAdded == true then
        tsor(packTable, function(entryA, entryB)
            if entryA.isCharacterPackHeader == true and entryB.isCharacterPackHeader == true then
                return entryA.name < entryB.name
            elseif entryA.isCharacterPackHeader == true and not entryB.isCharacterPackHeader then
                return true
            elseif not entryA.isCharacterPackHeader and entryB.isCharacterPackHeader == true then
                return false
            end
            return entryA.name < entryB.name
        end)
        self.comboBox:AddItems(packTable)
    end
    --Update the currently selected packName label
    UpdateCurrentlySelectedPackName(wasDeleted, nil, nil)
end

--OnMouseUp event function for the XML control editbox
function AddonSelector_OnMouseUp(self, mouseButton, upInside, ctrlKey, altKey, shiftKey, ...)
--d("[AddonSelector]EditBox OnMouseUp- mouseButton: " ..tostring(mouseButton) ..", upInside: " ..tostring(upInside))
    if mouseButton == MOUSE_BUTTON_INDEX_RIGHT and upInside then
        local newText = self:GetText()
        if newText and newText == "" then
            --Get the current character name and format it
            if currentCharName and currentCharName ~= "" then
                self:SetText(currentCharName .. "_")
                self:SetMouseEnabled(true)
                self:SetKeyboardEnabled(true)
                self:TakeFocus()
            end
        end
    end
    return false
end

-- On text changed, when user types in the editBox
-- Clear the comboBox, check to make sure the text is not empty
-- I don't want it clearing the ddl when I manually call editBox:Clear()
function AddonSelector_TextChanged(self)
	local newText = self:GetText()
    local newEnabledState = false
    if newText and newText ~= "" then
        newEnabledState = true
        --Deactivate the delete button as the combobox was emptied (non selected entry)
        ChangeDeleteButtonEnabledState(nil, false)
    else
        if AddonSelector.comboBox.m_selectedItemData ~= nil then
            newEnabledState = true
        end
    end
    --Enable/Disable the save pack button
    ChangeSaveButtonEnabledState(newEnabledState)
end

local function updateSaveModeTexure(doShow)
    AddonSelector.saveModeTexture:SetHidden(not doShow)
    ADD_ON_MANAGER:RefreshVisible()
end

local function updateAutoReloadUITexture(doShow)
    AddonSelector.autoReloadUITexture:SetHidden(not doShow)
    ADD_ON_MANAGER:RefreshVisible()
end

local function checkIfGlobalPacksShouldBeShown()
    local settings = AddonSelector.acwsv
    if not settings then return end
    local showGlobalPacks = settings.showGlobalPacks
    local savePerCharacter = settings.saveGroupedByCharacterName
    --Show the global pack entries if neither global packs nor character packs were selected to save/show!
    if showGlobalPacks == false and savePerCharacter == false then
        AddonSelector.acwsv.showGlobalPacks = true
    end
    updateSaveModeTexure(savePerCharacter)
end

-- called from clicking the "Auto reload" label
local function OnClick_CheckBoxLabel(self, currentStateVar)
--d("OnClick_CheckBoxLabel")
    if AddonSelector.acwsv[currentStateVar] == nil then return end
    local currentState = AddonSelector.acwsv[currentStateVar]
--d(">currentState of \'".. currentStateVar .."\': " ..tostring(currentState))
    local newState = not currentState
    AddonSelector.acwsv[currentStateVar] = newState
    --Clear the selected addon pack
    if newState == true then
        deselectComboBoxEntry()
    end
    --Reenable/Disable delete button?
    ChangeDeleteButtonEnabledState(newState, nil)
    if currentStateVar == "autoReloadUI" then
        updateAutoReloadUITexture(newState)
    end
end

-- called from clicking the button
--[[
local function OnClick_AutoReload(self, button, upInside, ctrl, alt, shift, command)
	if not upInside then return end
	if not button == MOUSE_BUTTON_INDEX_LEFT then return end
	local checkedState = self:GetState()
    AddonSelector.acwsv.autoReloadUI = checkedState
    --Clear the selected addon pack
    if checkedState == true then
        deselectComboBoxEntry()
    end
    --Reenable/Disable delete button?
    ChangeDeleteButtonEnabledState(checkedState)
end
]]

local function OnClick_SaveDo()
    local aad = ZO_ScrollList_GetDataList(ZOAddOnsList)
    local packName = AddonSelector.editBox:GetText()

    if not packName or packName == "" then
        local itemData = AddonSelector.comboBox:GetSelectedItemData()
        if not itemData then
            ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, langArrayInClientLang["ERRORpackMissing"] or langArrayInFallbackLang["ERRORpackMissing"])
            return
        end
        packName = itemData.name
    end

    local svForPack = createSVTableForPack(packName)

    -- Add all of the enabled addOn to the pack table
    for _, addonData in pairs(aad) do
        local data = addonData.data
        local isEnabled = data.addOnEnabled

        if isEnabled then
            local fileName = data.addOnFileName
            local addonName = data.strippedAddOnName
            --Set the addon to the pack into the SavedVariables
            svForPack[fileName] = addonName
        end
    end
    -- Create a temporary copy of the itemEntry data so we can select it
    -- after the ddl is updated
    local savePackPerCharacter = AddonSelector.acwsv.saveGroupedByCharacterName
    local itemData = AddonSelector:CreateItemEntry(packName, svForPack, false, (savePackPerCharacter and currentCharName) or GLOBAL_PACK_NAME)

    clearAndUpdateDDL()
    --Prevent reloadui for a currently new saved addon pack!
    doNotReloadUI = true
    AddonSelector.comboBox:SelectItem(itemData)
    doNotReloadUI = false

    --Disable the "save pack" button
    ChangeSaveButtonEnabledState(true)
end

-- When the save button is clicked, creates a table containing all
-- enabled addons:  { [AddOnFileName] = AddonStrippedName, ...}
local function OnClick_Save()
    local newPackName = AddonSelector.editBox:GetText()
    if not newPackName or newPackName == "" then
        local itemData = AddonSelector.comboBox.m_selectedItemData
        if itemData then
            newPackName = itemData.name
        end
    end
    if not newPackName or newPackName == "" then
        return
    end

    local doesPackAlreadyExist = false
    local saveGroupedByChar = false
    local svTable
    local savePerCharacter = AddonSelector.acwsv.saveGroupedByCharacterName
    local packCharacter = packNameGlobal
    --Save grouped by charactername
--d("[AddonSelector]OnClick_Save - savePerChar: " ..tostring(savePerCharacter) .. ", newPackName: " ..tostring(newPackName))
    if savePerCharacter then
        local svTableOfCurrentChar, charName = getSVTableForPacks()
--d(">charName: " ..tostring(charName))
        if svTableOfCurrentChar ~= nil and charName ~= nil then
            saveGroupedByChar = true
            svTable = svTableOfCurrentChar
            packCharacter = charName
        end
    end
    if not saveGroupedByChar then
        svTable = AddonSelector.acwsv.addonPacks
    end

    --Does the pack name already exist?
    doesPackAlreadyExist = svTable[newPackName] ~= nil or false
    if doesPackAlreadyExist == true then
        local addonPackName = "\'" .. newPackName .. "\'"
        local savePackQuestion = strfor(langArrayInClientLang["savePackBody"] or langArrayInFallbackLang["savePackBody"], tostring(addonPackName))
        ShowConfirmationDialog("SaveAddonPackDialog",
                (langArrayInClientLang["savePackTitle"] or langArrayInFallbackLang["savePackTitle"]) .. "\n" ..
                "[".. (saveGroupedByChar and strfor(charNamePackColorTemplate, packCharacter) or packCharacter) .. "]\n" .. newPackName,
                savePackQuestion,
                function() OnClick_SaveDo() end,
                function() end,
                nil,
                nil,
                true
        )
    else
        OnClick_SaveDo()
    end
end

local function OnClick_DeleteDo(itemData, charId)
    if not itemData then
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, deletePackAlertStr)
        return
    end
    local function deleteError(reason)
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, strfor(deletePackErrorStr, reason))
    end
    if not itemData.name or itemData.name == "" then
        deleteError("Pack name")
        return
    end
    if not itemData.charName or itemData.charName == "" then
        deleteError("Pack charName")
        return
    end

    local wasDeleted = false
    local selectedPackName = itemData.name
    local selectedCharName = itemData.charName
    local isGlobalPack = (selectedCharName == GLOBAL_PACK_NAME) or false

    --Save grouped by charactername
    if isGlobalPack == true then
        AddonSelector.acwsv.addonPacks[selectedPackName] = nil
        wasDeleted = true
    else
        if charId == nil then
            deleteError("CharId nil")
            return
        end
        if AddonSelector.acwsv.addonPacksOfChar[charId] and AddonSelector.acwsv.addonPacksOfChar[charId][selectedPackName] then
            AddonSelector.acwsv.addonPacksOfChar[charId][selectedPackName] = nil
            wasDeleted = true
        end
    end

    if wasDeleted == true then
        clearAndUpdateDDL(true)

        --Disable the "save pack" button
        ChangeSaveButtonEnabledState(false)
        --Disable the "delete pack" button
        ChangeDeleteButtonEnabledState(nil, false)
    end
end

-- When delete is clicked, remove the selected addon pack
local function OnClick_Delete(itemData)
--d("[AddonSelector]OnClick_Delete")
    itemData = itemData or AddonSelector.comboBox:GetSelectedItemData()
    if not itemData then return end
    --Debuggin
    --AddonSelector._SelectedItemDataOnDelete = itemData

    --Deleting a pack could be done for all kinds of packs, so we always need to check for the selected charName of the item!
    --local saveGroupedByChar = AddonSelector.acwsv.saveGroupedByCharacterName
    local charId, charName, svTable
    charName = itemData.charName
    if charName == currentCharName or charName == GLOBAL_PACK_NAME then
        svTable = getSVTableForPacks()
        charId = (charName ~= GLOBAL_PACK_NAME and currentCharId)
    else
        svTable, charId = getSVTableForPacksOfCharname(charName)
    end
    if not svTable then return end

    --d("[AddonSelector]charName: " ..tostring(charName) .. ", charId: " ..tostring(charId))

    local packCharName
    if charName ~= GLOBAL_PACK_NAME then packCharName = charName end
    local selectedPackName = itemData.name
    --ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
    local addonPackName = "\'" .. selectedPackName .. "\'"
    local deletePackQuestion = strfor(langArrayInClientLang["deletePackBody"] or langArrayInFallbackLang["deletePackBody"], tostring(addonPackName))
    ShowConfirmationDialog("DeleteAddonPackDialog",
        (langArrayInClientLang["deletePackTitle"] or langArrayInFallbackLang["deletePackTitle"]) .. "\n[" .. (packCharName and strfor(charNamePackColorTemplate, packCharName) or packNameGlobal) .. "]\n" .. selectedPackName,
        deletePackQuestion,
        function() OnClick_DeleteDo(itemData, charId) end,
        function() end,
        nil,
        nil,
        true
    )
end

--OnMouseUp event for the selected pack name label
local function OnClick_SelectedPackNameLabel(self, button, upInside, ctrl, alt, shift, command)
--d("[AddonSelector]OnClick_SelectedPackNameLabel")
    if not upInside or button ~= MOUSE_BUTTON_INDEX_LEFT or not AddonSelector.editBox then return end
    --Set the "name edit" to the currently selected addon pack entry so you just need to hit the save button afterwards
    local currentlySelectedPacknamesForChars = AddonSelector.acwsv.selectedPackNameForCharacters
    if not currentlySelectedPacknamesForChars then return end
    local currentCharactersSelectedPackNameData = currentlySelectedPacknamesForChars[currentCharIdNum]
    if currentCharactersSelectedPackNameData and currentCharactersSelectedPackNameData.packName ~= "" then
        AddonSelector.editBox:Clear()
        AddonSelector.editBox:SetText(currentCharactersSelectedPackNameData.packName)
    end
end

local function setMenuItemCheckboxState(checkboxIndex, newState, doClearAndUpdateDdl)
    newState = newState or false
    doClearAndUpdateDdl = doClearAndUpdateDdl or false
    if newState == true then
        ZO_CheckButton_SetChecked(ZO_Menu.items[checkboxIndex].checkbox)
    else
        ZO_CheckButton_SetUnchecked(ZO_Menu.items[checkboxIndex].checkbox)
    end
    if doClearAndUpdateDdl == true then
        clearAndUpdateDDL()
    end
end

--Show the settings context menu at the dropdown button
function AddonSelector_ShowSettingsDropdown(buttonCtrl)
    ClearMenu()

    --Add the currently logged in character name as header
    AddCustomMenuItem(currentCharName, function() end, MENU_ADD_OPTION_HEADER)

    --Add the global pack options
    checkIfGlobalPacksShouldBeShown()
    local globalPackSubmenu = {
        {
            label    = langArrayInClientLang["ShowGlobalPacks"] or langArrayInFallbackLang["ShowGlobalPacks"],
            callback = function(state)
                AddonSelector.acwsv.showGlobalPacks = state
                checkIfGlobalPacksShouldBeShown()
                clearAndUpdateDDL()
            end,
            checked  = function() return AddonSelector.acwsv.showGlobalPacks end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
        {
            label    = langArrayInClientLang["ShowSubMenuAtGlobalPacks"] or langArrayInFallbackLang["ShowSubMenuAtGlobalPacks"],
            callback = function(state)
                AddonSelector.acwsv.showSubMenuAtGlobalPacks = state
                clearAndUpdateDDL()
            end,
            checked  = function() return AddonSelector.acwsv.showSubMenuAtGlobalPacks end,
            disabled = function(rootMenu, childControl) return not AddonSelector.acwsv.showGlobalPacks end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
    }
    AddCustomSubMenuItem(langArrayInClientLang["GlobalPackSettings"] or langArrayInFallbackLang["GlobalPackSettings"], globalPackSubmenu)

    --Add the character pack options
    local characterNameSubmenu = {
        {
            label    = savedGroupedByCharNameStr,
            callback = function(state)
                AddonSelector.acwsv.saveGroupedByCharacterName = state
                checkIfGlobalPacksShouldBeShown()
                if state == true then
                    AddonSelector.acwsv.showGroupedByCharacterName = true
                end
                clearAndUpdateDDL()
            end,
            checked  = function() return AddonSelector.acwsv.saveGroupedByCharacterName end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
        {
            label    = langArrayInClientLang["ShowGroupedByCharacterName"] or langArrayInFallbackLang["ShowGroupedByCharacterName"],
            callback = function(state)
                AddonSelector.acwsv.showGroupedByCharacterName = state
                checkIfGlobalPacksShouldBeShown()
                clearAndUpdateDDL()
            end,
            checked  = function() return AddonSelector.acwsv.showGroupedByCharacterName end,
            disabled = function(rootMenu, childControl) return AddonSelector.acwsv.saveGroupedByCharacterName end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
    }
    AddCustomSubMenuItem(langArrayInClientLang["CharacterNameSettings"] or langArrayInFallbackLang["CharacterNameSettings"], characterNameSubmenu)


    --Add the search options
    local searchOptionsSubmenu = {
        {
            label    = langArrayInClientLang["searchExcludeFilename"] or langArrayInFallbackLang["searchExcludeFilename"],
            callback = function(state)
                AddonSelector.acwsv.searchExcludeFilename = state
            end,
            checked  = function() return AddonSelector.acwsv.searchExcludeFilename end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        },
        {
            label    = langArrayInClientLang["searchSaveHistory"] or langArrayInFallbackLang["searchSaveHistory"],
            callback = function(state)
                AddonSelector.acwsv.searchSaveHistory = state
            end,
            checked  = function() return AddonSelector.acwsv.searchSaveHistory end,
            itemType = MENU_ADD_OPTION_CHECKBOX,
        }
    }
    AddCustomSubMenuItem(searchMenuStr, searchOptionsSubmenu)

    --Add the auto reload pack after selection checkbox
    local cbAutoReloadUIindex = AddCustomMenuItem(langArrayInClientLang["autoReloadUIHint"] or langArrayInFallbackLang["autoReloadUIHint"],
            function(cboxCtrl)
                OnClick_CheckBoxLabel(cboxCtrl, "autoReloadUI")
            end,
            MENU_ADD_OPTION_CHECKBOX)
    setMenuItemCheckboxState(cbAutoReloadUIindex, AddonSelector.acwsv.autoReloadUI)

    ShowMenu(buttonCtrl)
end


-- Used to change the layout of the Addon scrollList to
-- make room for the AddonSelector control
function AddonSelector:ChangeLayout()
	--local template = ZO_AddOns
	--local divider = ZO_AddOnsDivider
	local list = ZOAddOnsList
	--local bg = ZO_AddonsBGLeft
	list:ClearAnchors()
	list:SetAnchor(TOPLEFT, self.addonSelectorControl, BOTTOMLEFT, 0, 10)
	-- This does not work ?? Items get cut off.
	--list:SetAnchor(BOTTOMRIGHT, bg, BOTTOMRIGHT, -20, -100)
	--list:SetDimensions(885, 560)
	ZO_ScrollList_SetHeight(list, 600)
	ZO_ScrollList_Commit(list)
end

local function onMouseEnterTooltip(ctrl)
    ZO_Tooltips_ShowTextTooltip(ctrl, TOP, ctrl.tooltipText)
end
local function onMouseExitTooltip()
    ZO_Tooltips_HideTextTooltip()
end

-- Create the AddonSelector control, set references to controls
-- and click handlers for the save/delete buttons
function AddonSelector:CreateControlReferences()
    local settings = AddonSelector.acwsv
    -- Create Controls:
    local addonSelector = CreateControlFromVirtual("AddonSelector", ZO_AddOns, "AddonSelectorVirtualTemplate", nil)

    --[[
    local addonSelector = CreateControlFromVirtual("AddonSelector", GuiRoot, "AddonSelectorTLC")
    addonSelector:SetHidden(true)
    ADDONS_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            addonSelector:SetHidden(false)
        elseif newState == SCENE_FRAGMENT_HIDING then
            addonSelector:SetHidden(true)
        end
    end)
    ]]

    -- Assign references:
    self.addonSelectorControl = addonSelector

    self.editBox 	= addonSelector:GetNamedChild("EditBox")
    self.ddl 		= addonSelector:GetNamedChild("ddl")
    self.comboBox	= self.ddl.m_comboBox
    self.saveBtn 	= addonSelector:GetNamedChild("Save")
    self.deleteBtn 	= addonSelector:GetNamedChild("Delete")
    --self.autoReloadBtn = addonSelector:GetNamedChild("AutoReloadUI")
    --self.autoReloadLabel = self.autoReloadBtn:GetNamedChild("Label")
    self.settingsOpenDropdown = addonSelector:GetNamedChild("SettingsOpenDropdown")
    self.settingsOpenDropdown.onClickHandler = self.settingsOpenDropdown:GetHandler("OnClicked")
    --PerfectPixel: Reposition of the settings "gear" icon -> move up to other icons (like Votans Addon List)
    self.settingsOpenDropdown:ClearAnchors()
    --<Anchor point="TOPLEFT" relativeTo="ZO_AddOns" relativePoint="TOP" offsetX="100" offsetY="65"/>
    local offsetX = (PP ~= nil and 40) or 100
    local offsetY = (PP ~= nil and -7) or 65
    self.settingsOpenDropdown:SetAnchor(TOPLEFT, ZO_AddOns, TOP, offsetX, offsetY)

    self.searchBox 	= addonSelector:GetNamedChild("SearchBox")
    self.searchBox:SetHandler("OnMouseUp", function(selfCtrl, mouseButton, isUpInside)
        if not settings.searchSaveHistory then return end
        if isUpInside and mouseButton == MOUSE_BUTTON_INDEX_RIGHT then
            local searchHistory = settings.searchHistory
            local searchType = SEARCH_TYPE_NAME
            local searchHistoryOfSearchMode = searchHistory[searchType]
            if searchHistoryOfSearchMode ~= nil and #searchHistoryOfSearchMode > 0 then
                ClearMenu()
                for _, searchTerm in ipairs(searchHistoryOfSearchMode) do
                    AddCustomMenuItem(searchTerm, function()
                        openGameMenuAndAddOnsAndThenSearch(searchTerm, true)
                        ClearMenu()
                    end)
                end
                AddCustomMenuItem("-", function() end)
                AddCustomMenuItem(clearSearchHistoryStr, function()
                    clearSearchHistory(searchType)
                    ClearMenu()
                end)
                ShowMenu(selfCtrl)
            end
        end
    end)
    self.searchLabel = addonSelector:GetNamedChild("SearchBoxLabel")
    self.searchLabel:SetText(AddonSelector_GetLocalizedText("AddonSearch"))
    self.selectedPackNameLabel = addonSelector:GetNamedChild("SelectedPackNameLabel")

    self.saveModeTexture = addonSelector:GetNamedChild("SaveModeTexture")
    self.saveModeTexture:SetTexture("/esoui/art/characterselect/gamepad/gp_characterselect_characterslots.dds")
    self.saveModeTexture:SetColor(charNamePackColorDef:UnpackRGBA())
    self.saveModeTexture:SetMouseEnabled(true)
    self.saveModeTexture.tooltipText = savedGroupedByCharNameStr
    self.saveModeTexture:SetHandler("OnMouseEnter", onMouseEnterTooltip)
    self.saveModeTexture:SetHandler("OnMouseExit", onMouseExitTooltip)

    self.autoReloadUITexture = addonSelector:GetNamedChild("AutoReloadUITexture")
    self.autoReloadUITexture:SetTexture("/esoui/art/miscellaneous/eso_icon_warning.dds")
    self.autoReloadUITexture:SetColor(1, 0, 0, 0.6)
    self.autoReloadUITexture:SetMouseEnabled(true)
    self.autoReloadUITexture.tooltipText = autoReloadUIStr
    self.autoReloadUITexture:SetHandler("OnMouseEnter", onMouseEnterTooltip)
    self.autoReloadUITexture:SetHandler("OnMouseExit", onMouseExitTooltip)

    -- Set Saved Btn State for checkbox "Auto reloadui after pack selection"
    local checkedState = settings.autoReloadUI
    updateAutoReloadUITexture(checkedState)
    --self.autoReloadBtn:SetState(checkedState)
    --Disable the "save pack" button
    ChangeSaveButtonEnabledState(false)
    --Disable the "delete pack" button
    ChangeDeleteButtonEnabledState(checkedState)
    --Show the currently selected pack name for the logged in character
    UpdateCurrentlySelectedPackName(nil, nil, nil)

    -- Add Tooltips for AutoReloadUI
    --[[
    local function OnMouseEnter()
        local toolTipText = langArrayInClientLang["autoReloadUIHintTooltip"] or langArrayInFallbackLang["autoReloadUIHintTooltip"]
        InitializeTooltip(InformationTooltip, self.autoReloadLabel, LEFT, 26, 0, RIGHT)
        InformationTooltip:AddLine(toolTipText)
    end
    local function OnMouseExit()
        ClearTooltip(InformationTooltip)
    end
    ]]



    local function OnMouseEnter(ctrl)
        local toolTipText = langArrayInClientLang["ShowSettings"] or langArrayInFallbackLang["ShowSettings"]
        if not toolTipText then return end
        ZO_Tooltips_ShowTextTooltip(ctrl, TOP, toolTipText)
    end
    local function OnMouseExit()
        ZO_Tooltips_HideTextTooltip()
    end
    local function OnMouseUp_SettingsLabel(settingsLabel, mouseButton, upInside)
        ZO_Tooltips_HideTextTooltip()
        if not upInside or not mouseButton == MOUSE_BUTTON_INDEX_LEFT then return end
        AddonSelector_ShowSettingsDropdown(self.settingsOpenDropdown)
    end

    -- SetHandlers:
    self.saveBtn:SetHandler("OnMouseUp", OnClick_Save)
    self.deleteBtn:SetHandler("OnMouseUp", function() OnClick_Delete() end)
    --self.autoReloadBtn:SetHandler("OnMouseUp", OnClick_AutoReload)
    --self.autoReloadBtn:SetHandler("OnMouseEnter", OnMouseEnter)
    --self.autoReloadBtn:SetHandler("OnMouseExit", OnMouseExit)
    --self.autoReloadLabel:SetHandler("OnMouseUp", OnClick_AutoReloadLabel)
    --self.autoReloadLabel:SetHandler("OnMouseEnter", OnMouseEnter)
    --self.autoReloadLabel:SetHandler("OnMouseExit", OnMouseExit)
    self.settingsOpenDropdown:SetHandler("OnMouseEnter", OnMouseEnter)
    self.settingsOpenDropdown:SetHandler("OnMouseExit", OnMouseExit)
    self.selectedPackNameLabel:SetHandler("OnMouseUp", OnClick_SelectedPackNameLabel)
end


local OrigAddonGetRowSetupFunc = ZO_AddOnManager.GetRowSetupFunction
function ZO_AddOnManager:GetRowSetupFunction()
--d("Manual PreHook ZO_AddOnManager:GetRowSetupFunction")
	local func = OrigAddonGetRowSetupFunc(self)

    return function(control, data)
        control:SetMouseEnabled(areAllAddonsEnabled(true))
        control:SetHandler("OnMouseUp", Addon_Toggle_Enabled)
        local retVar = func(control, data)
        AddonSelector_HookSingleControlForMultiSelectByShiftKey(control)
        return retVar
    end
end

--[[
local function PackScrollableComboBox_Entry_OnMouseEnter(entry, entry2)
d("[ADDON SELECTOR] Entry of scrollable combobox OnMouseEnter")
AddonSelector._ddl = ddl
AddonSelector._OnMouseEnter_entry = entry
AddonSelector._OnMouseEnter_entry2 = entry2
    if entry.m_owner ~= ddl then return end
end
]]

--====================================--
--====  Initialize ====--
--====================================--
function AddonSelector:Initialize()
	--Libraries
    AddonSelector.LDIALOG = LibDialog
    AddonSelector.LCM = LibCustomMenu

    local svName = "AddonSelectorSavedVars"
    local SAVED_VAR_VERSION = 1
	local defaultSavedVars = {
		addonPacks = {},
        addonPacksOfChar = {},
		autoReloadUI = false,
        selectAllSave = {},
        selectedPackNameForCharacters = {},
        svMigrationToServerDone = false,
        showGlobalPacks = true,
        showSubMenuAtGlobalPacks = true,
        saveGroupedByCharacterName = false,
        showGroupedByCharacterName = false,
        searchExcludeFilename = false,
        searchSaveHistory = false,
        searchHistory = {},
        searchHistoryMaxEntries = 10,
	}
    local worldName = GetWorldName()
    --Get the saved addon packages without a server reference
	local oldSVWithoutServer = ZO_SavedVars:NewAccountWide(svName, SAVED_VAR_VERSION, nil, defaultSavedVars)

    --ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
	self.acwsv = ZO_SavedVars:NewAccountWide(svName, SAVED_VAR_VERSION, nil, defaultSavedVars, worldName, "AllAccounts")
    --Old non-server dependent SV exist and new SV too and were not migrated yet
    if oldSVWithoutServer ~= nil and not self.acwsv.svMigrationToServerDone then
        --Copy all addon packages from the old SV to the new server dependent ones, but do not overwrite any existing ones
        local addonPacksOfNonServerDependentSV = oldSVWithoutServer.addonPacks
        for packName, addonTable in pairs(addonPacksOfNonServerDependentSV) do
            if self.acwsv.addonPacks and not self.acwsv.addonPacks[packName] then
                self.acwsv.addonPacks[packName] = addonTable
            end
        end
        --Copy all select all save infos
        local selectAllSavedOfNonServerDependentSV = oldSVWithoutServer.selectAllSave
        for idx, data in pairs(selectAllSavedOfNonServerDependentSV) do
            if self.acwsv.selectAllSave and not self.acwsv.selectAllSave[idx] then
                self.acwsv.selectAllSave[idx] = data
            end
        end
        --Copy all selected packnames of the characters
        local selectedPackNameForCharactersOfNonServerDependentSV = oldSVWithoutServer.selectedPackNameForCharacters
        for idx, data in pairs(selectedPackNameForCharactersOfNonServerDependentSV) do
            if self.acwsv.selectedPackNameForCharacters and not self.acwsv.selectedPackNameForCharacters[idx] then
                self.acwsv.selectedPackNameForCharacters[idx] = data
            end
        end
        --Copy the other settings
        self.acwsv.autoReloadUI = oldSVWithoutServer.autoReloadUI

        --SV copy old non-server to server dependent finished for this server. Set the flag to true
        self.acwsv.svMigrationToServerDone = true
    end

    if self.acwsv.autoReloadUI == BSTATE_PRESSED then
        self.acwsv.autoReloadUI = true
    elseif self.acwsv.autoReloadUI == BSTATE_NORMAL then
        self.acwsv.autoReloadUI = false
    end

    --Packname saved was an old value without charName info? Migrate it
    for charId, packNameDataOfCharId in pairs(AddonSelector.acwsv.selectedPackNameForCharacters) do
        if type(packNameDataOfCharId) ~= "table" then
            local oldData = packNameDataOfCharId
            --Create the table, overwriting it with the old data's packname and the charName = "global" constant
            AddonSelector.acwsv.selectedPackNameForCharacters[charId] = {
                packName = oldData,
                charName = GLOBAL_PACK_NAME,
            }
        end
    end

	self:CreateControlReferences()
	self:UpdateDDL()
	self:ChangeLayout()

	-- Very hacky, but easiest method: Wipe out the games
	-- TYPE_ID = 1 dataType and recreate it using my own template.
	-- Done to make the row controls mouseEnabled
	--[[ Disabled on advice by Votan, 31.08.2018, Exchanged with code lines below
    ADD_ON_MANAGER.list.dataTypes = {}
	ZO_ScrollList_AddDataType(ADD_ON_MANAGER.list, 1, "ZO_AddOnRow", 30, ADD_ON_MANAGER:GetRowSetupFunction())
	]]
    if ADD_ON_MANAGER.list.dataTypes[1] then
        ADD_ON_MANAGER.list.dataTypes[1].setupCallback = ADD_ON_MANAGER:GetRowSetupFunction()
    else
        ZO_ScrollList_AddDataType(ADD_ON_MANAGER.list, 1, "ZO_AddOnRow", 30, ADD_ON_MANAGER:GetRowSetupFunction())
    end

    --Change the description texts now
    AddonSelectorNameLabel:SetText(langArrayInClientLang["packName"] or langArrayInFallbackLang["packName"])
    AddonSelectorSave:SetText(langArrayInClientLang["saveButton"] or langArrayInFallbackLang["saveButton"])
    AddonSelectorSelectLabel:SetText((langArrayInClientLang["selectPack"] or langArrayInFallbackLang["selectPack"]) .. ":")
    AddonSelectorDelete:SetText(langArrayInClientLang["deleteButton"] or langArrayInFallbackLang["deleteButton"])
    --AddonSelectorAutoReloadUILabel:SetText(langArrayInClientLang["autoReloadUIHint"] or langArrayInFallbackLang["autoReloadUIHint"])
    --Get the addon manager object
    if ADDON_MANAGER == nil then
        ADDON_MANAGER = GetAddOnManager()
    end
    --PreHook the ChangeEnabledState function for the addon entries, in order to update the enabled addons number
    ZO_PreHook(ADD_ON_MANAGER, "ChangeEnabledState", function(ctrl, index, checkState)
        AddonSelectorUpdateCount(50)
    end)
    if ADDON_MANAGER ~= nil then
        --PreHook the SetAddOnEnabled function for the addon entries, in order to update the enabled addons number
        ZO_PreHook(ADDON_MANAGER, "SetAddOnEnabled", function(ctrl)
            --d("[AddonSelector]PreHook SetAddOnEnabled")
            if not AddonSelector.noAddonNumUpdate then
                AddonSelectorUpdateCount(50)
            end
            --if AddonSelector.noAddonCheckBoxUpdate then return true end
        end)
        --EM:RegisterForEvent("AddonSelectorMultiselectHookOnShow", EVENT_ACTION_LAYER_PUSHED, function(...) AddonSelector_HookForMultiSelectByShiftKey(...) end)

        if ZO_AddOns ~= nil then
            ZO_AddOns:SetMouseEnabled(true)
            ZO_AddOns:SetMovable(true)
        end
    end

    --PreHook the Addonmanagers OnShow function
    ZO_PreHook(ADD_ON_MANAGER, "OnShow", function(ctrl)
        --d("ADD_ON_MANAGER:OnShow")
        --Update the count/total number at the addon manager titel
        AddonSelectorUpdateCount(250)
        --Clear the search table
        AddonSelector.searchBox:SetText("")
        --Reset the searched table completely
        AddonSelector.alreadyFound = {}
        --Clear the previously searched data and unregister the events
        unregisterOldEventUpdater()

        zo_callLater(function()
            --Reset variables
            AddonSelector.firstControl     = nil
            AddonSelector.firstControlData = nil
            --Build the lookup table for the sortIndex to row index of addon rows
            BuildAddOnReverseLookUpTable()
            --Hook the visible addon rows (controls) to set a hanlder for OnMouseDown
            --AddonSelector_HookForMultiSelectByShiftKey()

            --PostHook the new Enable All addons heckbox function so that the controls of Circonians Addon Selector get disabled/enabled
            enableAllAddonsCheckboxCtrl = enableAllAddonsCheckboxCtrl or ZO_AddOnsList2Row1Checkbox
            if not enableAllAddonsCheckboxHooked and enableAllAddonsCheckboxCtrl ~= nil then
                ZO_PostHookHandler(enableAllAddonsCheckboxCtrl, "OnMouseUp", function(checkboxCtrl, mouseButton, isUpInside)
                    if not isUpInside or mouseButton ~= MOUSE_BUTTON_INDEX_LEFT then return end
                    areAllAddonsEnabled(false)
                end)
                enableAllAddonsCheckboxHooked = true
            end
        end, 50) -- Attention: Delay needs to be 500 as AddonSelector_HookForMultiSelectByShiftKey was enabled!!!
    end)
    --[[
    ZO_PreHook("ZO_ScrollList_ScrollRelative", function(self, delta, onScrollCompleteCallback, animateInstantly)
        if self == ZOAddOnsList then
            AddonSelector_HookForMultiSelectByShiftKey()
        end
    end)
    ZO_PreHook("ZO_ScrollList_MoveWindow", function(self, value)
        if self == ZOAddOnsList then
            AddonSelector_HookForMultiSelectByShiftKey()
        end
    end)
    ZO_PreHook("ZO_ScrollList_ScrollAbsolute", function(self, value)
        d("ZO_ScrollList_ScrollAbsolute")
        if self == ZOAddOnsList then
            --AddonSelector_HookForMultiSelectByShiftKey()
        end
    end)
    ]]
end

--Reload the user interface
function AddonSelector_ReloadTheUI()
    ReloadUI("ingame")
end

--Show the current user's active pack in the chat
function AddonSelector_ShowActivePackInChat()
    local currentCharacterId, currentlySelectedPackNameData = getCurrentCharsPackNameData()
    if not currentCharacterId or not currentlySelectedPackNameData then return end
    local currentlySelectedPackName = currentlySelectedPackNameData.packName
    local charIdOfSelectedPack = currentlySelectedPackNameData.charId
    local charNameOfSelectedPack = tostring(charIdOfSelectedPack)

    d("[ADDON SELECTOR]" .. (langArrayInClientLang["packName"] or langArrayInFallbackLang["packName"]) .. ": " ..tostring(currentlySelectedPackName) .. ", " .. (langArrayInClientLang["packCharName"] or langArrayInFallbackLang["packCharName"]) .. ": " ..tostring(charNameOfSelectedPack))
end

local function searchAddOnSlashCommandHandlder(args)
    if not args or args == "" then
        showAddOnsList()
    else
        --Parse the arguments string
        local options = {}
        --local searchResult = {} --old: searchResult = { string.match(args, "^(%S*)%s*(.-)$") }
        for param in strgma(args, "([^%s]+)%s*") do
            if (param ~= nil and param ~= "") then
                options[#options+1] = strlow(param)
            end
        end
        if options and options[1] then
            openGameMenuAndAddOnsAndThenSearch(tostring(options[1]))
        end
    end
end


-------------------------------------------------------------------
--  OnAddOnLoaded  --
-------------------------------------------------------------------
local function OnAddOnLoaded(event, addonName)
	if addonName ~= ADDON_NAME then return end
	AddonSelector:Initialize()


    --Slash commands
    SLASH_COMMANDS["/rl"]               = AddonSelector_ReloadTheUI
    SLASH_COMMANDS["/rlui"]             = AddonSelector_ReloadTheUI
    SLASH_COMMANDS["/reload"]           = AddonSelector_ReloadTheUI
    if SLASH_COMMANDS["/addons"] == nil then
        SLASH_COMMANDS["/addons"]       = searchAddOnSlashCommandHandlder
    end
    if SLASH_COMMANDS["/as"] == nil then
        SLASH_COMMANDS["/as"]           = searchAddOnSlashCommandHandlder
    end
    SLASH_COMMANDS["/addonsearch"]      = searchAddOnSlashCommandHandlder
    SLASH_COMMANDS["/addonselector"]    = searchAddOnSlashCommandHandlder
    SLASH_COMMANDS["/asap"]             = AddonSelector_ShowActivePackInChat
    --Keybinding
    ZO_CreateStringId("SI_KEYBINDINGS_CATEGORY_ADDON_SELECTOR", ADDON_NAME)
    ZO_CreateStringId("SI_BINDING_NAME_ADDONS_RELOADUI",        langArrayInClientLang["ReloadUI"] or langArrayInFallbackLang["ReloadUI"])
    ZO_CreateStringId("SI_BINDING_NAME_SHOWACTIVEPACK",         langArrayInClientLang["ShowActivePack"] or langArrayInFallbackLang["ShowActivePack"])

    --Hook the scrollable combobox OnMouseEnter function to show the menu entry to delete the pack of the row
    --SecurePostHook("ZO_ScrollableComboBox_Entry_OnMouseEnter", PackScrollableComboBox_Entry_OnMouseEnter)
    AddonSelector.LCM = AddonSelector.LCM or LibCustomMenu
    checkIfGlobalPacksShouldBeShown()

    ZO_PreHook(ZO_ComboBox, "AddMenuItems", function(selfVar)
        if not AddonSelector or not AddonSelector.comboBox or selfVar ~= AddonSelector.comboBox then return end
        local settings = AddonSelector.acwsv
        local saveGroupedByCharacterName = settings.saveGroupedByCharacterName
        local showGroupedByCharacterName = settings.showGroupedByCharacterName
        local showGlobalPacks = settings.showGlobalPacks
        local showSubMenuAtGlobalPacks = settings.showSubMenuAtGlobalPacks
        if showSubMenuAtGlobalPacks == false and (saveGroupedByCharacterName == false and showGroupedByCharacterName == false) then return false end

        for i = 1, #selfVar.m_sortedItems do
            local subMenuEntries = {}
            local addedSubMenuEntry = false
            local itemName
            -- The variable item must be defined locally here, otherwise it won't work as an upvalue to the selection helper
            local item = selfVar.m_sortedItems[i]

            local function mainEntryOnClickCallback(control)
                if item.isCharacterPackHeader == true then return end
                selfVar:ItemSelectedClickHelper(item) --will call "OnClickDDL", defined in "AddonSelector:CreateItemEntry" as callback of the entry
            end


            --Packs are saved grouped below character names
            if (saveGroupedByCharacterName == true or showGroupedByCharacterName == true) and item.isCharacterPackHeader == true then
                local packDataOfChar = item.addonTable
                local charName = packDataOfChar._charName
                --The entry in the DDL is the characterName -> We need to add the submenu entries for each packName
                if charName ~= nil and packDataOfChar ~= nil then
                    itemName = item.name
                    for packNameOfChar, addonsOfPack in pairs(packDataOfChar) do
                        if packNameOfChar ~= "_charName" then
                            tins(subMenuEntries, {
                                label = (langArrayInClientLang["selectPack"] or langArrayInFallbackLang["selectPack"]) .. ": " .. packNameOfChar,
                                callback = function()
                                    local packItem = AddonSelector:CreateItemEntry(packNameOfChar, addonsOfPack, false, charName)
                                    selfVar:ItemSelectedClickHelper(packItem) --will call "OnClickDDL", defined in "AddonSelector:CreateItemEntry" as callback of the entry
                                end,
                            })
                            addedSubMenuEntry = true
                        end
                    end
                end
            end

            if showGlobalPacks == true and not item.isCharacterPackHeader then
                --Packs are saved without character name grouping
                --The entry in the DDL is the packname
                itemName = item.name
                if showSubMenuAtGlobalPacks == true then
                    subMenuEntries = {
                        {
                            label = (langArrayInClientLang["selectPack"] or langArrayInFallbackLang["selectPack"]) .. ": " .. itemName,
                            callback = function()
                                selfVar:ItemSelectedClickHelper(item) --will call "OnClickDDL", defined in "AddonSelector:CreateItemEntry" as callback of the entry
                            end,
                        },
                        {
                            label = "-",
                            callback = function() end,
                            disabled = true,
                        },
                        {
                            label = (langArrayInClientLang["selectPack"] or langArrayInFallbackLang["selectPack"]) .. " & " .. (langArrayInClientLang["ReloadUI"] or langArrayInFallbackLang["ReloadUI"]) .. ": " .. itemName,
                            callback = function()
                                selfVar:ItemSelectedClickHelper(item) --will call "OnClickDDL", defined in "AddonSelector:CreateItemEntry" as callback of the entry
                                ReloadUI("ingame")
                            end,
                        },
                        {
                            label = "-",
                            callback = function() end,
                            disabled = true,
                        },
                        {
                            label =  (langArrayInClientLang["deletePackTitle"] or langArrayInFallbackLang["deletePackTitle"]) .. " " .. itemName,
                            callback = function()
                                if item.charName == nil then
                                    local packDataOfChar = item.addonTable
                                    local charName = packDataOfChar._charName
                                    item.charName = charName
                                    item.charNameWasAddedByContextMenuClick = true
                                end
                                OnClick_Delete(item)
                            end,
                        }
                    }
                    addedSubMenuEntry = true
                else
                    AddCustomMenuItem(itemName, mainEntryOnClickCallback, nil, nil, nil, nil, nil)
                end
            end

            if addedSubMenuEntry == true then
                AddCustomSubMenuItem(itemName, subMenuEntries, nil, nil, nil, nil, mainEntryOnClickCallback)
            end
        end
        return true
    end)

	EM:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
end

---------------------------------------------------------------------
--  Register Events --
---------------------------------------------------------------------
EM:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
