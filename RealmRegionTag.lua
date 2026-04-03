local addonName = ...

local addon = CreateFrame("Frame")
local DEFAULT_US_MODE = "split"
local CURRENT_VERSION = GetAddOnMetadata(addonName, "Version") or "0.0.0"
local LOCALE = GetLocale()
local IS_CHINESE_LOCALE = LOCALE == "zhCN" or LOCALE == "zhTW"
local VERSION_MESSAGES = {
    ["1.0.8"] = {
        zh = "1.0.8 新功能: 使用 \"/rrt us\" 可切换美服标签为统一 US 或分开显示 USE/USC/USM/USP。",
        en = "New in 1.0.8: use \"/rrt us\" to toggle US realm tags between US and USE/USC/USM/USP.",
    },
}

local REGION_COLORS = {
    US = "4DA3FF",
    USE = "5AA9FF",
    USC = "46C3FF",
    USM = "7A8CFF",
    USP = "8E7CFF",
    OC = "36D06F",
    BR = "FF9B42",
    LA = "FF6FAE",
}

local REGION_LABELS = {
    US = "US",
    USE = "USE",
    USC = "USC",
    USM = "USM",
    USP = "USP",
    OC = "OC",
    BR = "BR",
    LA = "LA",
}

local REALM_TO_REGION = {}

local FIXED_REGION_REALMS = {
    -- Oceanic
    amanthul = "OC",
    barthilas = "OC",
    caelestrasz = "OC",
    dathremar = "OC",
    dreadmaul = "OC",
    frostmourne = "OC",
    gundrak = "OC",
    jubeithos = "OC",
    khazgoroth = "OC",
    nagrand = "OC",
    saurfang = "OC",
    thaurissan = "OC",

    -- Brazil
    azralon = "BR",
    gallywix = "BR",
    goldrinn = "BR",
    nemesis = "BR",
    tolbarad = "BR",

    -- Latin America
    drakkari = "LA",
    quelthalas = "LA",
    ragnaros = "LA",
}

local US_REALMS_BY_TIMEZONE = {
    USE = "altarofstorms,alteracmountains,anetheron,area52,argentdawn,arthas,arygos,balnazzar,blackdragonflight,bleedinghollow,bloodfurnace,bloodhoof,burningblade,dalaran,draktharon,durotan,duskwood,earthenring,eldrethalas,elune,eonar,exodar,firetree,garrosh,gilneas,gorgonnash,grizzlyhills,guldan,kargath,korialstrasz,lightningsblade,llane,lothar,magtheridon,malfurion,malorne,mannoroth,medivh,nazjatar,norgannon,onyxia,rivendare,skullcrusher,spirestone,stormrage,stormscale,theforgottencoast,thescryers,thrall,trollbane,turalyon,velen,warsong,ysera,ysondre,zuljin",
    USC = "aegwynn,agamaggan,aggramar,alexstrasza,alleria,anubarak,anvilmar,archimonde,auchindoun,azgalor,azshara,azuremyst,blackhand,blackwinglair,bladefist,bladesedge,bonechewer,burninglegion,chogall,chromaggus,crushridge,daggerspine,dawnbringer,dentarg,destromath,dethecus,detheroc,eitrigg,emeralddream,eredar,fizzcrank,frostmane,galakrond,garithos,garona,ghostlands,gorefiend,greymane,gurubashi,hakkar,haomarush,hellscream,icecrown,illidan,jaedenar,kaelthas,khadgar,kirintor,korgath,kultiras,laughingskull,lethon,lightninghoof,madoran,maelstrom,malganis,malygos,misha,moonguard,muradin,nathrezim,nazgrel,nerzhul,nesingwary,nordrassil,queldorei,ravencrest,ravenholdt,rexxar,runetotem,sargeras,senjin,sentinels,shadowmoon,shuhalo,smolderthorn,spinebreaker,staghelm,steamwheedlecartel,stormreaver,tanaris,terokkar,theunderbog,theventureco,thunderhorn,thunderlord,tortheldrin,twistingnether,uldaman,undermine,uther,veknilash,whisperwind,wildhammer,zangarmarsh",
    USM = "azjolnerub,blackwaterraiders,bloodscalp,boulderfist,cairne,darkspear,dunemaul,hydraxis,kelthuzad,khazmodan,maiev,perenolde,shadowcouncil,stonemaul,terenas",
    USP = "aeriepeak,akama,andorhal,antonidas,arathor,baelgun,blackrock,boreantundra,bronzebeard,cenarioncircle,cenarius,coilfang,dalvengyr,darkiron,darrowmere,deathwing,demonsoul,doomhammer,draenor,dragonblight,dragonmaw,draka,drakthul,drenden,echoisles,executus,farstriders,feathermoon,fenris,frostwolf,gnomeregan,hyjal,kalecgos,kiljaeden,kilrogg,lightbringer,moknathal,moonrunner,mugthol,proudmoore,scarletcrusade,scilla,shadowsong,shandris,shatteredhalls,shatteredhand,silverhand,silvermoon,sistersofelune,skywall,suramar,thoriumbrotherhood,tichondrius,uldum,ursin,vashj,windrunner,winterhoof,wyrmrestaccord,zuluhed",
}

local function InitializeRealmMappings()
    for realmName, region in pairs(FIXED_REGION_REALMS) do
        REALM_TO_REGION[realmName] = region
    end

    for region, realmList in pairs(US_REALMS_BY_TIMEZONE) do
        for realmName in realmList:gmatch("[^,]+") do
            REALM_TO_REGION[realmName] = region
        end
    end
end

local function NormalizeRealmName(realmName)
    if type(realmName) ~= "string" or realmName == "" then
        return nil
    end

    return realmName:lower():gsub("[%s%-'%’]", "")
end

local function ExtractRealmFromLeaderName(leaderName)
    if type(leaderName) ~= "string" then
        return nil
    end

    local realmName = leaderName:match("^[^-]+%-(.+)$")
    if not realmName or realmName == "" then
        return nil
    end

    return realmName
end

local function GetRegionForRealm(realmName)
    local normalizedRealm = NormalizeRealmName(realmName)
    return normalizedRealm and REALM_TO_REGION[normalizedRealm] or "US"
end

local function IsSplitUSRegion(region)
    return region == "USE" or region == "USC" or region == "USM" or region == "USP"
end

local function GetUSDisplayMode()
    local db = _G.RealmRegionTagDB
    local mode = db and db.usMode
    if mode == "unified" then
        return "unified"
    end
    return DEFAULT_US_MODE
end

local function ParseVersion(version)
    local major, minor, patch = tostring(version or ""):match("^(%d+)%.(%d+)%.(%d+)$")
    return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
end

local function IsVersionNewer(newVersion, oldVersion)
    local newMajor, newMinor, newPatch = ParseVersion(newVersion)
    local oldMajor, oldMinor, oldPatch = ParseVersion(oldVersion)

    if newMajor ~= oldMajor then
        return newMajor > oldMajor
    end

    if newMinor ~= oldMinor then
        return newMinor > oldMinor
    end

    return newPatch > oldPatch
end

local function GetDisplayRegion(region)
    if GetUSDisplayMode() == "unified" and IsSplitUSRegion(region) then
        return "US"
    end

    return region
end

local function GetEntryInfo(resultID)
    if not resultID then
        return nil
    end

    local resultInfo = C_LFGList.GetSearchResultInfo(resultID)
    if not resultInfo or not resultInfo.leaderName then
        return nil
    end

    local realmName = ExtractRealmFromLeaderName(resultInfo.leaderName)
    if not realmName or realmName == "" then
        realmName = GetRealmName()
    end

    local region = GetRegionForRealm(realmName)

    return {
        leaderName = resultInfo.leaderName,
        realmName = realmName,
        region = region,
    }
end

local function BuildColoredTag(region)
    local color = REGION_COLORS[region] or "FFFFFF"
    local label = REGION_LABELS[region] or region
    return string.format("|cff%s[%s]|r", color, label)
end

local function StripExistingTag(text)
    if type(text) ~= "string" then
        return text
    end

    text = text:gsub("^|cff%x%x%x%x%x%x%[[A-Z][A-Z][A-Z]?%]|r%s*", "")
    text = text:gsub("^%[[A-Z][A-Z][A-Z]?%]%s*", "")
    return text
end

local function UpdateEntry(entry)
    if not entry or not entry.resultID or not entry.Name then
        return
    end

    local nameText = entry.Name.GetText and entry.Name:GetText()
    if not nameText or nameText == "" or not entry.Name.SetText then
        return
    end

    local info = GetEntryInfo(entry.resultID)
    if not info or not info.region then
        return
    end

    entry.Name:SetText(BuildColoredTag(GetDisplayRegion(info.region)) .. " " .. StripExistingTag(nameText))
end

local function HookSearchEntryUpdate()
    if type(LFGListSearchEntry_Update) ~= "function" then
        return false
    end

    if not addon.isHooked then
        hooksecurefunc("LFGListSearchEntry_Update", UpdateEntry)
        addon.isHooked = true
    end

    return true
end

local function RefreshSearchResults()
    if type(LFGListSearchPanel_UpdateResults) == "function" and LFGListFrame and LFGListFrame.SearchPanel then
        LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel)
    end
end

local function PrintUsage()
    print("|cff4DA3FFRealmRegionTag|r 用法: \"/rrt us\"")
end

local function PrintUSDisplayMode()
    local mode = GetUSDisplayMode()
    local label = mode == "unified" and "统一 US" or "分开 USE/USC/USM/USP"
    print(string.format("|cff4DA3FFRealmRegionTag|r 当前美服显示模式: %s", label))
end

local function SetUSDisplayMode(mode)
    RealmRegionTagDB = RealmRegionTagDB or {}
    RealmRegionTagDB.usMode = mode

    PrintUSDisplayMode()
    RefreshSearchResults()
end

local function ToggleUSDisplayMode()
    if GetUSDisplayMode() == "unified" then
        SetUSDisplayMode("split")
    else
        SetUSDisplayMode("unified")
    end
end

local function HandleSlashCommand(message)
    local command, option = strsplit(" ", strtrim(message or ""), 2)
    command = command and command:lower() or ""
    option = option and option:lower() or ""

    if command == "" then
        PrintUSDisplayMode()
        PrintUsage()
        return
    end

    if command == "us" and option == "" then
        ToggleUSDisplayMode()
        return
    end

    PrintUsage()
end

local function InitializeSavedVariables()
    RealmRegionTagDB = RealmRegionTagDB or {}
    if RealmRegionTagDB.usMode ~= "unified" and RealmRegionTagDB.usMode ~= "split" then
        RealmRegionTagDB.usMode = DEFAULT_US_MODE
    end
end

local function RegisterSlashCommands()
    SLASH_REALMREGIONTAG1 = "/realmregiontag"
    SLASH_REALMREGIONTAG2 = "/rrt"
    SlashCmdList.REALMREGIONTAG = HandleSlashCommand
end

local function ShowVersionUpdateMessage()
    RealmRegionTagDB = RealmRegionTagDB or {}

    local lastSeenVersion = RealmRegionTagDB.lastSeenVersion
    if not lastSeenVersion then
        RealmRegionTagDB.lastSeenVersion = CURRENT_VERSION
        return
    end

    if IsVersionNewer(CURRENT_VERSION, lastSeenVersion) then
        local versionMessage = VERSION_MESSAGES[CURRENT_VERSION]
        local message
        if type(versionMessage) == "table" then
            message = IS_CHINESE_LOCALE and versionMessage.zh or versionMessage.en
        else
            message = versionMessage
        end
        if message then
            print("|cff4DA3FFRealmRegionTag|r " .. message)
        end
    end

    RealmRegionTagDB.lastSeenVersion = CURRENT_VERSION
end

addon:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "PLAYER_LOGIN" then
        InitializeSavedVariables()
        RegisterSlashCommands()
        ShowVersionUpdateMessage()

        if HookSearchEntryUpdate() then
            return
        end

        addon:RegisterEvent("ADDON_LOADED")
    elseif event == "ADDON_LOADED" and loadedAddon == "Blizzard_GroupFinder" then
        HookSearchEntryUpdate()
    end
end)

addon:RegisterEvent("PLAYER_LOGIN")

InitializeRealmMappings()
