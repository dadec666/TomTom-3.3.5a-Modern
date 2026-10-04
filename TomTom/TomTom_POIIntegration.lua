local hookEnabled = true;
local modifier;
local watchframeHookEnabled = false;

local function POIAnchorToCoord(poiframe)
    if not poiframe then return nil, nil end
    local point, relto, relpoint, x, y = poiframe:GetPoint()
    local frame = WorldMapDetailFrame
    if not frame then return nil, nil end

    local width = frame:GetWidth()
    local height = frame:GetHeight()
    local frameScale = frame:GetScale()
    local poiScale = poiframe:GetScale()

    if not frameScale or not poiScale or poiScale == 0 or width == 0 or height == 0 then
        return nil, nil
    end

    local scale = frameScale / poiScale
    local cx = (x / scale) / width
    local cy = (-y / scale) / height

    if cx < 0 or cx > 1 or cy < 0 or cy > 1 then
        return nil, nil
    end

    return cx * 100, cy * 100
end

local modTbl = {
    C = IsControlKeyDown,
    A = IsAltKeyDown,
    S = IsShiftKeyDown,
}

local function findQuestFrameFromQuestIndex(questId)
    for i = 1, MAX_NUM_QUESTS do
        local questFrame = _G["WorldMapQuestFrame"..i];
        if not questFrame then
            break
        elseif questFrame.questId == questId then
            return questFrame
        end
    end
end

local function setQuestWaypoint(self)
    if not self then return end
    local c, z = GetCurrentMapContinent(), GetCurrentMapZone();
    local x, y = POIAnchorToCoord(self)

    if not x or not y then return end

    local qid = self.questId

    local title;
    if self.quest and self.quest.questLogIndex then
        title = GetQuestLogTitle(self.quest.questLogIndex)
    elseif self.questLogIndex then
        title = GetQuestLogTitle(self.questLogIndex)
    else
        title = "Quest #" .. (qid or "???") .. " POI"
    end

    local uid = TomTom:AddZWaypoint(c, z, x, y, title)
    return uid
end

local function poi_OnClick(self, button)
    if not hookEnabled or not modifier then
        return
    end

    if button == "RightButton" then
        for i = 1, #modifier do
            local mod = modifier:sub(i, i)
            local func = modTbl[mod]
            if not func or not func() then
                return
            end
        end
    else
        return
    end

    if self.parentName == "WatchFrameLines" or self.parentName == "QuestObjectiveTrackerContentsFrame" then
        local questFrame = findQuestFrameFromQuestIndex(self.questId)
        if not questFrame then
            return
        else
            self = questFrame.poiIcon
        end
    end

    return setQuestWaypoint(self)
end

local hooked = {}
hooksecurefunc("QuestPOI_DisplayButton", function(parentName, buttonType, buttonIndex, questId)
    local buttonName = "poi"..tostring(parentName)..tostring(buttonType).."_"..tostring(buttonIndex);
    local poiButton = _G[buttonName];

    if poiButton and not hooked[buttonName] then
        poiButton:RegisterForClicks("AnyUp")
        hooked[buttonName] = true
    end
end)

-- Безопасный хук для кастомных трекеров (Sirus), не ломающий чистый 3.3.5
if type(rawget(_G, "QuestObjectiveTrackerPOI_OnClick")) == "function" then
    hooksecurefunc("QuestObjectiveTrackerPOI_OnClick", function(self, button)
        poi_OnClick(self, button)
    end)
end

local setPoints = {}

local function updateClosestPOI()
    if not VISIBLE_WATCHES then return end
    local questIndex = VISIBLE_WATCHES[1]
    if questIndex then
        local title, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex);
        local questFrame = findQuestFrameFromQuestIndex(questID)
        if questFrame and questFrame.poiIcon then
            for idx, uid in ipairs(setPoints) do
                TomTom:RemoveWaypoint(uid)
            end
            wipe(setPoints)
            local uid = setQuestWaypoint(questFrame.poiIcon)
            if uid then
                table.insert(setPoints, uid)
            end
        end
    end
end

if rawget(_G, "QuestObjectiveTracker") and type(QuestObjectiveTracker.BuildQuestWatchInfos) == "function" then
    hooksecurefunc(QuestObjectiveTracker, "BuildQuestWatchInfos", function()
        if watchframeHookEnabled then
            updateClosestPOI()
        end
    end)
elseif type(rawget(_G, "WatchFrame_Update")) == "function" then
    hooksecurefunc("WatchFrame_Update", function()
        if watchframeHookEnabled then
            updateClosestPOI()
        end
    end)
end

function TomTom:EnableDisablePOIIntegration()
    hookEnabled = TomTom.profile.poi.enable
    modifier = TomTom.profile.poi.modifier
    watchframeHookEnabled = TomTom.profile.poi.setClosest
end