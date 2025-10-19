local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonSelectorStrPrefix = AS.constants.addonSelectorStrPrefix

local constants = AS.constants
local textures = constants.textures

--The strings
local langArray = { -- by Calamath
    ["packName"] = "パック名:",
    ["selectPack"] = "パック選択",
    ["ERRORpackMissing"] = ADDON_NAME .. ": パック名が見つかりません",
    ["autoReloadUIHint"] = "自動UIリロード",
    ["autoReloadUIHintTooltip"] = "自動UIリロード: ONにした場合、編集や削除ができなくなります。 編集や削除をする場合はOFFにして下さい。",
    ["saveButton"] = "保存",
    ["savePackTitle"] = "上書き保存しますか？",
    ["savePackBody"] = " %s に上書き保存しますか？",
    ["deleteButton"] = "削除",
    ["deletePackAlert"]     = ADDON_NAME .. ": 削除するパックを選択する必要があります。",
    ["deletePackError"]     = ADDON_NAME .. ": パック削除エラー\n%s.",
    ["deletePackTitle"] = "削除: ",
    ["deletePackBody"] = "本当に削除しますか？\n%s",
    ["DeselectAllAddons"] = "全解除",
    ["SelectAllAddons"] = "全選択",
    ["SelectAllAddonsSaved"] = "保存したものを再選択",
    ["AddonSearch"] = "検索:",
    ["selectedPackName"] = "選択中 (%s):",
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
    ["LastPackLoaded"] = "最終ロード:",
    ["singleCharName"]       = GetString(SI_CURRENCYLOCATION0),
}

for key, strValue in pairs(langArray) do
    local stringId = addonSelectorStrPrefix .. key
    SafeAddString(_G[stringId], strValue, 2)
end