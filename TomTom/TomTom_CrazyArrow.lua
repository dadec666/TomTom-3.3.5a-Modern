--[[--------------------------------------------------------------------------
--  TomTom - A navigational assistant for World of Warcraft
--  Optimized CrazyArrow Module for Lua 5.1 / WotLK 3.3.5a
----------------------------------------------------------------------------]]

local Astrolabe = DongleStub("Astrolabe-0.4")
local sformat = string.format
local mfloor = math.floor
local mabs = math.abs
local pi = math.pi
local twopi = pi * 2
local GetPlayerFacing = GetPlayerFacing
local IsInInstance = IsInInstance

local L = TomTomLocals
local ldb = LibStub("LibDataBroker-1.1")

-- Предварительный кэш строк дистанции (0 - 1000 ярдов) для полного устранения GC
local dist_cache = {}
for i = 0, 1000 do
	dist_cache[i] = sformat(L["%d yards"], i)
end

local function GetFormattedDist(dist)
	local d = mfloor(dist + 0.5)
	if d <= 1000 then
		return dist_cache[d] or sformat(L["%d yards"], d)
	end
	return sformat(L["%d yards"], d)
end

-- Предвычисленный плоский кэш UV-координат спрайта (12 строк по 9 столбцов = 108 кадров)
local texcoords_precomputed = {}
for cell = 0, 107 do
	local column = cell % 9
	local row = mfloor(cell / 9)
	local xstart = (column * 56) / 512
	local ystart = (row * 42) / 512
	local xend = ((column + 1) * 56) / 512
	local yend = ((row + 1) * 42) / 512
	texcoords_precomputed[cell] = {xstart, xend, ystart, yend}
end

-- Кэшированные цвета стрелки для избежания unpack() в OnUpdate
local goodR, goodG, goodB = 0, 1, 0
local midR, midG, midB = 1, 1, 0
local badR, badG, badB = 1, 0, 0

local function UpdateCachedColors()
	if TomTom and TomTom.db and TomTom.db.profile and TomTom.db.profile.arrow then
		local p = TomTom.db.profile.arrow
		goodR, goodG, goodB = p.goodcolor[1], p.goodcolor[2], p.goodcolor[3]
		midR, midG, midB = p.middlecolor[1], p.middlecolor[2], p.middlecolor[3]
		badR, badG, badB = p.badcolor[1], p.badcolor[2], p.badcolor[3]
	end
end

local function FastColorGradient(perc)
	if perc >= 1 then
		return goodR, goodG, goodB
	elseif perc <= 0 then
		return badR, badG, badB
	end

	if perc < 0.5 then
		local relperc = perc * 2
		return badR + (midR - badR) * relperc,
		       badG + (midG - badG) * relperc,
		       badB + (midB - badB) * relperc
	else
		local relperc = (perc - 0.5) * 2
		return midR + (goodR - midR) * relperc,
		       midG + (goodG - midG) * relperc,
		       midB + (goodB - midB) * relperc
	end
end

local wayframe = CreateFrame("Button", "TomTomCrazyArrow", UIParent)
wayframe:SetHeight(42)
wayframe:SetWidth(56)
wayframe:SetPoint("CENTER", 0, 0)
wayframe:EnableMouse(true)
wayframe:SetMovable(true)
wayframe:Hide()

local titleframe = CreateFrame("Frame", nil, wayframe)
wayframe.title = titleframe:CreateFontString("OVERLAY", nil, "GameFontHighlightSmall")
wayframe.status = titleframe:CreateFontString("OVERLAY", nil, "GameFontNormalSmall")
wayframe.tta = titleframe:CreateFontString("OVERLAY", nil, "GameFontNormalSmall")
wayframe.title:SetPoint("TOP", wayframe, "BOTTOM", 0, 0)
wayframe.status:SetPoint("TOP", wayframe.title, "BOTTOM", 0, 0)
wayframe.tta:SetPoint("TOP", wayframe.status, "BOTTOM", 0, 0)

local function OnDragStart(self, button)
	if not TomTom.db.profile.arrow.lock then
		self:StartMoving()
	end
end

local function OnDragStop(self, button)
	self:StopMovingOrSizing()
end

wayframe:SetScript("OnDragStart", OnDragStart)
wayframe:SetScript("OnDragStop", OnDragStop)
wayframe:RegisterForDrag("LeftButton")
wayframe:RegisterEvent("ZONE_CHANGED_NEW_AREA")
wayframe:RegisterEvent("PLAYER_STARTED_MOVING")

wayframe.arrow = wayframe:CreateTexture(nil, "OVERLAY")
wayframe.arrow:SetTexture("Interface\\Addons\\TomTom\\Images\\Arrow")
wayframe.arrow:SetAllPoints()

local active_point, arrive_distance, showDownArrow, point_title

function TomTom:SetCrazyArrow(uid, dist, title)
	active_point = uid
	arrive_distance = dist
	point_title = title 

	if self.profile.arrow.enable then
		wayframe.title:SetText(title or "Unknown waypoint")
		wayframe:Show()
	end
end

local status = wayframe.status
local tta = wayframe.tta
local arrow = wayframe.arrow
local count = 0
local last_distance = 0
local tta_throttle = 0
local speed = 0
local speed_count = 0
local update_timer = 0
local STEP_THROTTLE = 0.06 -- ~16.6 FPS: идеально плавно для стрелки, не грузит Lua GC

local function OnEvent(self, event, ...)
	if event == "ZONE_CHANGED_NEW_AREA" and TomTom.profile.arrow.enable then
		self:Show()
	elseif event == "PLAYER_STARTED_MOVING" then
		update_timer = STEP_THROTTLE -- Мгновенно пробуждает стрелку без фриза при старте бега
	end
end
wayframe:SetScript("OnEvent", OnEvent)

-- Добавляем в настройки дефолтные значения (если не заданы)
local function GetProfileThrottle()
	if TomTom and TomTom.db and TomTom.db.profile and TomTom.db.profile.arrow then
		return TomTom.db.profile.arrow.dist_throttle or 0.08
	end
	return 0.08
end

local dist_timer = 0
local tta_timer = 0
local cached_dist = 0
local cached_arrive = false

local function OnUpdate(self, elapsed)
	if not active_point then
		self:Hide()
		return
	end

	-- 1. Блок угла и поворота стрелки (КАЖДЫЙ КАДР - 60/144+ FPS)
	-- Выполняется мгновенно без создания таблиц и строк (0 GC)
	local angle = TomTom:GetDirectionToWaypoint(active_point)
	local player = GetPlayerFacing() or 0

	if not angle then
		self:Hide()
		return
	end

	angle = angle - player
	local cell = mfloor(angle / twopi * 108 + 0.5) % 108
	local coords = texcoords_precomputed[cell]

	if not cached_arrive then
		arrow:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
		local perc = mabs((pi - mabs(angle)) / pi)
		local r, g, b = FastColorGradient(perc)
		arrow:SetVertexColor(r, g, b)
	end

	-- 2. Блок дистанции (Троттлинг по настраиваемому таймеру)
	dist_timer = dist_timer + elapsed
	local throttle = GetProfileThrottle()

	if dist_timer >= throttle then
		dist_timer = 0
		local dist, x, y = TomTom:GetDistanceToWaypoint(active_point)

		if not dist or IsInInstance() then
			if not TomTom:IsValidWaypoint(active_point) then
				active_point = nil
				if TomTom.profile.arrow.setclosest then
					TomTom:SetClosestWaypoint()
					return
				end
			end
			self:Hide()
			return
		end

		cached_dist = dist
		status:SetText(GetFormattedDist(dist))

		-- Проверка зоны прибытия
		if dist <= arrive_distance then
			if not showDownArrow then
				arrow:SetHeight(70)
				arrow:SetWidth(53)
				arrow:SetTexture("Interface\\AddOns\\TomTom\\Images\\Arrow-UP")
				arrow:SetVertexColor(goodR, goodG, goodB)
				showDownArrow = true
				cached_arrive = true
			end

			count = count + 1
			if count >= 55 then count = 0 end

			local column = count % 9
			local row = mfloor(count / 9)
			local xstart = (column * 53) / 512
			local ystart = (row * 70) / 512
			arrow:SetTexCoord(xstart, xstart + (53/512), ystart, ystart + (70/512))
		else
			if showDownArrow then
				arrow:SetHeight(56)
				arrow:SetWidth(42)
				arrow:SetTexture("Interface\\AddOns\\TomTom\\Images\\Arrow")
				showDownArrow = false
				cached_arrive = false
			end
		end
	end

	-- 3. Расчёт времени прибытия (TTA) раз в секунду
	tta_timer = tta_timer + elapsed
	if tta_timer >= 1.0 then
		local current_speed = (last_distance - cached_dist) / tta_timer
		if last_distance == 0 then current_speed = 0 end

		if speed_count < 2 then
			speed = (speed + current_speed) / 2
			speed_count = speed_count + 1
		else
			speed_count = 0
			speed = current_speed
		end

		if speed > 0 then
			local eta = mabs(cached_dist / speed)
			tta:SetFormattedText("%01d:%02d", eta / 60, eta % 60)
		else
			tta:SetText("***")
		end

		last_distance = cached_dist
		tta_timer = 0
	end
end

wayframe:SetScript("OnUpdate", OnUpdate)

function TomTom:ShowHideCrazyArrow()
	UpdateCachedColors()
	if self.profile.arrow.enable then
		wayframe:Show()

		if self.profile.arrow.noclick then
			wayframe:EnableMouse(false)
		else
			wayframe:EnableMouse(true)
		end

		wayframe:SetScale(TomTom.db.profile.arrow.scale)
		wayframe:SetAlpha(TomTom.db.profile.arrow.alpha)
		local width = TomTom.db.profile.arrow.title_width
		local height = TomTom.db.profile.arrow.title_height
		local scale = TomTom.db.profile.arrow.title_scale

		wayframe.title:SetWidth(width)
		wayframe.title:SetHeight(height)
		titleframe:SetScale(scale)
		titleframe:SetAlpha(TomTom.db.profile.arrow.title_alpha)

		if self.profile.arrow.showtta then
			tta:Show()
		else
			tta:Hide()
		end
	else
		wayframe:Hide()
	end
end

wayframe:SetScript("OnUpdate", OnUpdate)

--[[-------------------------------------------------------------------------
--  Dropdown
-------------------------------------------------------------------------]]--

local dropdown_info = {
	[1] = {
		{
			text = L["TomTom Waypoint Arrow"],
			isTitle = 1,
		},
		{
			text = L["Clear waypoint from crazy arrow"],
			func = function()
				local prior = active_point
				active_point = nil
				if TomTom.profile.arrow.setclosest then
					local uid = TomTom:GetClosestWaypoint()
					if uid and uid ~= prior then
						TomTom:SetClosestWaypoint()
						return
					end
				end
			end,
		},
		{
			text = L["Remove waypoint"],
			func = function()
				local uid = active_point
				TomTom:RemoveWaypoint(uid)
			end,
		},
		{
			text = L["Remove all waypoints from this zone"],
			func = function()
				local uid = active_point
				local waypoints = TomTom.waypoints
				local data = waypoints[uid]
				if data and waypoints[data.zone] then
					for zone_uid in pairs(waypoints[data.zone]) do
						TomTom:RemoveWaypoint(zone_uid)
					end
				end
			end,
		},
		{
			text = L["Remove all waypoints"],
			func = function()
				if TomTom.db.profile.general.confirmremoveall then
					StaticPopup_Show("TOMTOM_REMOVE_ALL_CONFIRM")
				else
					StaticPopupDialogs["TOMTOM_REMOVE_ALL_CONFIRM"].OnAccept()
					return
				end
			end,
		},
	}
}

local function init_dropdown(self, level)
	level = level or 1
	local info = dropdown_info[level]

	if level > 1 and UIDROPDOWNMENU_MENU_VALUE then
		if info[UIDROPDOWNMENU_MENU_VALUE] then
			info = info[UIDROPDOWNMENU_MENU_VALUE]
		end
	end

	for idx, entry in ipairs(info) do
		if type(entry.checked) == "function" then
			local new = {}
			for k, v in pairs(entry) do new[k] = v end
			new.checked = new.checked()
			entry = new
		end
		UIDropDownMenu_AddButton(entry, level)
	end
end

local function WayFrame_OnClick(self, button)
	if active_point then
		if TomTom.db.profile.arrow.menu then
			UIDropDownMenu_Initialize(TomTom.dropdown, init_dropdown)
			ToggleDropDownMenu(1, nil, TomTom.dropdown, "cursor", 0, 0)
		end
	end
end

wayframe:RegisterForClicks("RightButtonUp")
wayframe:SetScript("OnClick", WayFrame_OnClick)

local function wayframe_OnEvent_LDB(self, event, arg1, ...)
	if arg1 == "TomTom" then
		if TomTom.db.profile.feeds.arrow then
			local feed_crazy = ldb:NewDataObject("TomTom_CrazyArrow", {
				type = "data source",
				icon = "Interface\\Addons\\TomTom\\Images\\Arrow",
				text = "Crazy",
				iconR = 1,
				iconG = 1,
				iconB = 1,
				iconCoords = {0, 1, 0, 1},
				OnTooltipShow = function(tooltip)
					local dist = TomTom:GetDistanceToWaypoint(active_point)
					if dist then
						tooltip:AddLine(point_title or L["Unknown waypoint"])
						tooltip:AddLine(GetFormattedDist(dist), 1, 1, 1)
					end
				end,
				OnClick = WayFrame_OnClick,
			})

			local crazyFeedFrame = CreateFrame("Frame")
			local throttle = TomTom.db.profile.feeds.arrow_throttle
			local counter = 0

			function TomTom:UpdateArrowFeedThrottle()
				throttle = TomTom.db.profile.feeds.arrow_throttle
			end

			crazyFeedFrame:SetScript("OnUpdate", function(self, elapsed)
				counter = counter + elapsed
				if counter < throttle then return end
				counter = 0

				local angle = TomTom:GetDirectionToWaypoint(active_point)
				local player = GetPlayerFacing()
				if not angle or not player then
					feed_crazy.iconCoords = texcoords_precomputed[0]
					feed_crazy.iconR = 0.2
					feed_crazy.iconG = 1.0
					feed_crazy.iconB = 0.2
					feed_crazy.text = "No waypoint"
					return
				end

				angle = angle - player
				local perc = mabs((pi - mabs(angle)) / pi)
				local r, g, b = FastColorGradient(perc)
				feed_crazy.iconR = r
				feed_crazy.iconG = g
				feed_crazy.iconB = b

				local cell = mfloor(angle / twopi * 108 + 0.5) % 108
				feed_crazy.iconCoords = texcoords_precomputed[cell]
				feed_crazy.text = point_title or "Unknown waypoint"
			end)
		end
	end
end

local ldbInitFrame = CreateFrame("Frame")
ldbInitFrame:RegisterEvent("ADDON_LOADED")
ldbInitFrame:SetScript("OnEvent", wayframe_OnEvent_LDB)

-- Public API
function TomTom:SetCrazyArrowDirection(angle)
	local cell = mfloor(angle / twopi * 108 + 0.5) % 108
	local coords = texcoords_precomputed[cell]
	arrow:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
end

function TomTom:SetCrazyArrowColor(r, g, b, a)
	arrow:SetVertexColor(r, g, b, a)
end

function TomTom:SetCrazyArrowTitle(title, status_text, tta_text)
	wayframe.title:SetText(title)
	wayframe.status:SetText(status_text)
	wayframe.tta:SetText(tta_text)
end

function TomTom:HijackCrazyArrow(onupdate)
	wayframe:SetScript("OnUpdate", onupdate)
	wayframe.hijacked = true
	wayframe:Show()
end

function TomTom:ReleaseCrazyArrow()
	wayframe:SetScript("OnUpdate", OnUpdate)
	wayframe.hijacked = false
end

function TomTom:CrazyArrowIsHijacked()
	return wayframe.hijacked
end