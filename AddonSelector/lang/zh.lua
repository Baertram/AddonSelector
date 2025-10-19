local AS = AddonSelectorGlobal
local ADDON_NAME = AS.name
local addonSelectorStrPrefix = AS.constants.addonSelectorStrPrefix

local constants = AS.constants
local textures = constants.textures

--The strings
local langArray = { -- by Lykeion 20221206
    ["packName"] = "插件包名称:",
    ["selectPack"] = "选择插件包",
    ["ERRORpackMissing"] = ADDON_NAME..": 未找到插件包名称",
    ["autoReloadUIHint"] = "选择插件包时自动重新加载UI.",
    ["autoReloadUIHintTooltip"] = "启用该选项时你对插件包的编辑和删除将被重载中断. 如果你想编辑插件包请先关闭本功能!",
    ["saveButton"] = "保存",
    ["savePackTitle"] = "覆盖插件包?",
    ["savePackBody"] = "覆盖已存在的插件包 %s?",
    ["deleteButton"] = "删除",
    ["deletePackTitle"] = "删除: ",
    ["deletePackAlert"] = ADDON_NAME..": 你必须选中一个插件包以删除.",
    ["deletePackError"] = ADDON_NAME..": 插件包删除发生错误\n%s.",
    ["deletePackBody"] = "真的要删除吗?\n%s",
    ["DeselectAllAddons"] = "取消选择所有",
    ["SelectAllAddons"] = "选择所有",
    ["DeselectAllLibraries"]= "取消选择所有Lib",
    ["SelectAllLibraries"] = "选择所有Lib",
    ["ScrollToAddons"] = "↑向上滚动至插件↑",
    ["ScrollToLibraries"] = "↓向下滚动至运行库↓",
    ["SelectAllAddonsSaved"] = "选择已保存的",
    ["AddonSearch"] = "搜索:",
    ["selectedPackName"] = "已选择 (%s): ",
    ["ReloadUI"] = GetString(SI_ADDON_MANAGER_RELOAD) or "重新加载UI",
    ["ShowActivePack"] = "显示启用的插件包",
    ["ShowSubMenuAtGlobalPacks"] = "在账户插件包包中展示子菜单",
    ["ShowSettings"] = "显示 \'"..ADDON_NAME.."\' 设置",
    ["ShowGlobalPacks"] = "显示账户保存的插件包",
    ["GlobalPackSettings"] = "账户插件包设置",
    ["CharacterNameSettings"] = "角色名设置",
    ["SaveGroupedByCharacterName"] = "按角色名保存插件包",
    ["ShowGroupedByCharacterName"] = "展示以角色命名的插件包",
    ["packCharName"] = "角色插件包",
    ["packGlobal"] = "账户插件包",
    ["searchExcludeFilename"] = "不包含文件名",
    ["searchSaveHistory"] = "保存搜索关键词历史",
    ["searchClearHistory"] = "清除历史",
    ["UndoLastMassMarking"] = "< 重做上次的标记",
    ["ClearLastMassMarking"] = "清除标记备份文件",
    ["LastPackLoaded"] = "上次加载:",
    ["singleCharName"]       = GetString(SI_CURRENCYLOCATION0),
}


for key, strValue in pairs(langArray) do
    local stringId = addonSelectorStrPrefix .. key
    SafeAddString(_G[stringId], strValue, 2)
end