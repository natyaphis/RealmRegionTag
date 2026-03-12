local addonName = ...

local addon = CreateFrame("Frame")

local REGION_COLORS = {
    US = "4DA3FF",
    OC = "36D06F",
    BR = "FF9B42",
    LA = "FF6FAE",
}

local REALM_TO_REGION = {
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

local function BuildColoredTag(region)
    local color = REGION_COLORS[region] or "FFFFFF"
    return string.format("|cff%s[%s]|r", color, region)
end

local function StripExistingTag(text)
    if type(text) ~= "string" then
        return text
    end

    text = text:gsub("^|cff%x%x%x%x%x%x%[[A-Z][A-Z]?%]|r%s*", "")
    text = text:gsub("^%[[A-Z][A-Z]?%]%s*", "")
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

addon:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "PLAYER_LOGIN" then
        if HookSearchEntryUpdate() then
            return
        end

        addon:RegisterEvent("ADDON_LOADED")
    elseif event == "ADDON_LOADED" and loadedAddon == "Blizzard_GroupFinder" then
        HookSearchEntryUpdate()
    end
end)

addon:RegisterEvent("PLAYER_LOGIN")
