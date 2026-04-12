local addonName = ...

local addon = CreateFrame("Frame")

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
local DEFAULT_SETTINGS = {
    mergeUS = false,
}

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

local function IsUSMerged()
    return RealmRegionTagDB and RealmRegionTagDB.mergeUS == true
end

local function InitializeRealmMappings()
    wipe(REALM_TO_REGION)

    for realmName, region in pairs(FIXED_REGION_REALMS) do
        REALM_TO_REGION[realmName] = region
    end

    for region, realmList in pairs(US_REALMS_BY_TIMEZONE) do
        for realmName in realmList:gmatch("[^,]+") do
            REALM_TO_REGION[realmName] = IsUSMerged() and "US" or region
        end
    end
end

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff5AA9FFRealmRegionTag:|r %s", message))
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

local function GetApplicantLeaderInfo(applicantID)
    if not applicantID then
        return nil
    end

    local applicantInfo = C_LFGList.GetApplicantInfo(applicantID)
    if not applicantInfo or not applicantInfo.numMembers or applicantInfo.numMembers < 1 then
        return nil
    end

    local memberName = C_LFGList.GetApplicantMemberInfo(applicantID, 1)
    if type(memberName) ~= "string" or memberName == "" then
        return nil
    end

    local realmName = ExtractRealmFromLeaderName(memberName)
    if not realmName or realmName == "" then
        realmName = GetRealmName()
    end

    return {
        leaderName = memberName,
        realmName = realmName,
        region = GetRegionForRealm(realmName),
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

    entry.Name:SetText(BuildColoredTag(info.region) .. " " .. StripExistingTag(nameText))
end

local function UpdateTextWithRegionTag(fontString, info)
    if not fontString or not fontString.GetText or not fontString.SetText then
        return false
    end

    local nameText = fontString:GetText()
    if not nameText or nameText == "" then
        return false
    end

    fontString:SetText(BuildColoredTag(info.region) .. " " .. StripExistingTag(nameText))
    return true
end

local function ResolveApplicantID(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)

        if type(value) == "number" then
            return value
        end

        if type(value) == "table" then
            if type(value.id) == "number" then
                return value.id
            end

            if type(value.applicantID) == "number" then
                return value.applicantID
            end

            if type(value.ApplicantID) == "number" then
                return value.ApplicantID
            end

            if value.elementData then
                local applicantID = ResolveApplicantID(value.elementData)
                if applicantID then
                    return applicantID
                end
            end

            if value.data then
                local applicantID = ResolveApplicantID(value.data)
                if applicantID then
                    return applicantID
                end
            end
        end
    end
end

local function ResolveApplicantMemberIndex(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)

        if type(value) == "table" then
            if type(value.index) == "number" then
                return value.index
            end

            if type(value.memberIdx) == "number" then
                return value.memberIdx
            end

            if type(value.memberIndex) == "number" then
                return value.memberIndex
            end

            if type(value.MemberIdx) == "number" then
                return value.MemberIdx
            end

            if value.elementData then
                local memberIndex = ResolveApplicantMemberIndex(value.elementData)
                if memberIndex then
                    return memberIndex
                end
            end

            if value.data then
                local memberIndex = ResolveApplicantMemberIndex(value.data)
                if memberIndex then
                    return memberIndex
                end
            end
        end
    end
end

local function GetApplicantIDFromButton(button)
    if not button then
        return nil
    end

    return ResolveApplicantID(button)
end

local function GetApplicantMemberIndexFromButton(button)
    if not button then
        return nil
    end

    return ResolveApplicantMemberIndex(button)
end

local function UpdateApplicantNameWidget(widget, info)
    if not widget then
        return false
    end

    if UpdateTextWithRegionTag(widget.Name, info) then
        return true
    end

    if UpdateTextWithRegionTag(widget.MemberName, info) then
        return true
    end

    if UpdateTextWithRegionTag(widget.NameColumnString, info) then
        return true
    end

    if UpdateTextWithRegionTag(widget.Text, info) then
        return true
    end

    return UpdateTextWithRegionTag(widget, info)
end

local function UpdateApplicantEntry(button, elementData)
    local applicantID = ResolveApplicantID(elementData, button)
    if not button or not applicantID then
        return
    end

    local info = GetApplicantLeaderInfo(applicantID)
    if not info or not info.region then
        return
    end

    UpdateApplicantNameWidget(button, info)
end

local function UpdateApplicantMemberEntry(button, applicantID, memberIndex)
    applicantID = ResolveApplicantID(applicantID, button)
    memberIndex = ResolveApplicantMemberIndex(memberIndex, applicantID, button)
    if not button or not applicantID or memberIndex ~= 1 then
        return
    end

    local info = GetApplicantLeaderInfo(applicantID)
    if not info or not info.region then
        return
    end

    UpdateApplicantNameWidget(button, info)
end

local function RefreshSearchResults()
    if not LFGListFrame or not LFGListFrame.SearchPanel then
        return
    end

    local searchPanel = LFGListFrame.SearchPanel

    if searchPanel.ScrollBox and searchPanel.ScrollBox.ForEachFrame then
        searchPanel.ScrollBox:ForEachFrame(UpdateEntry)
    end

    if searchPanel.results and type(searchPanel.results.Update) == "function" then
        searchPanel.results:Update()
    end
end

local function RefreshApplicantResults()
    if not LFGListFrame or not LFGListFrame.ApplicationViewer then
        return
    end

    local applicationViewer = LFGListFrame.ApplicationViewer

    if applicationViewer.ScrollBox and applicationViewer.ScrollBox.ForEachFrame then
        applicationViewer.ScrollBox:ForEachFrame(UpdateApplicantEntry)
    end
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

local function HookApplicantEntryUpdate()
    if type(LFGListApplicationViewer_UpdateApplicant) ~= "function" then
        return false
    end

    if not addon.isApplicantHooked then
        hooksecurefunc("LFGListApplicationViewer_UpdateApplicant", UpdateApplicantEntry)
        addon.isApplicantHooked = true
    end

    return true
end

local function HookApplicantMemberEntryUpdate()
    if type(LFGListApplicationViewer_UpdateApplicantMember) ~= "function" then
        return false
    end

    if not addon.isApplicantMemberHooked then
        hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", UpdateApplicantMemberEntry)
        addon.isApplicantMemberHooked = true
    end

    return true
end

local function InitializeSettings()
    RealmRegionTagDB = RealmRegionTagDB or {}

    for key, value in pairs(DEFAULT_SETTINGS) do
        if RealmRegionTagDB[key] == nil then
            RealmRegionTagDB[key] = value
        end
    end
end

local function ToggleUSMode()
    RealmRegionTagDB.mergeUS = not RealmRegionTagDB.mergeUS
    InitializeRealmMappings()
    RefreshSearchResults()
    RefreshApplicantResults()

    if RealmRegionTagDB.mergeUS then
        Print("US realms are now merged and shown as US.")
    else
        Print("US realms are now split by timezone as USE, USC, USM, and USP.")
    end
end

local function RegisterSlashCommands()
    SLASH_REALMREGIONTAG1 = "/rrt"
    SlashCmdList.REALMREGIONTAG = function(message)
        local command = type(message) == "string" and message:match("^%s*(.-)%s*$"):lower() or ""

        if command == "us" then
            ToggleUSMode()
            return
        end

        if IsUSMerged() then
            Print("Current US mode: merged. Use /rrt us to switch back to timezone tags.")
        else
            Print("Current US mode: timezone split. Use /rrt us to merge them into US.")
        end
    end
end

addon:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "PLAYER_LOGIN" then
        InitializeSettings()
        InitializeRealmMappings()
        RegisterSlashCommands()

        local hookedSearch = HookSearchEntryUpdate()
        local hookedApplicant = HookApplicantEntryUpdate()
        local hookedApplicantMember = HookApplicantMemberEntryUpdate()

        if hookedSearch and hookedApplicant and hookedApplicantMember then
            return
        end

        addon:RegisterEvent("ADDON_LOADED")
    elseif event == "ADDON_LOADED" and loadedAddon == "Blizzard_GroupFinder" then
        HookSearchEntryUpdate()
        HookApplicantEntryUpdate()
        HookApplicantMemberEntryUpdate()
    end
end)

addon:RegisterEvent("PLAYER_LOGIN")
