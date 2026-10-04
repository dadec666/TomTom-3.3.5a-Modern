--[[--------------------------------------------------------------------------
--  TomTom_GUI.lua
--  Современный автономный UI для TomTom 3.3.5a в стиле Modern Retail / Dragonflight
----------------------------------------------------------------------------]]

local L = TomTomLocals
local GUI = CreateFrame("Frame", "TomTomConfigFrame", UIParent)
GUI:SetSize(800, 560)
GUI:SetPoint("CENTER")
GUI:SetFrameStrata("DIALOG")
GUI:EnableMouse(true)
GUI:SetMovable(true)
GUI:RegisterForDrag("LeftButton")
GUI:SetScript("OnDragStart", GUI.StartMoving)
GUI:SetScript("OnDragStop", GUI.StopMovingOrSizing)
GUI:SetClampedToScreen(true)
GUI:Hide()

tinsert(UISpecialFrames, "TomTomConfigFrame") -- Закрытие по клавише Esc

-- Базовый стиль окна (Dark Minimalist Backdrop)
GUI:SetBackdrop({
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
GUI:SetBackdropColor(0.06, 0.06, 0.08, 0.96)
GUI:SetBackdropBorderColor(0.22, 0.22, 0.26, 1)

-- Верхняя панель заголовка
local titleBar = CreateFrame("Frame", nil, GUI)
titleBar:SetPoint("TOPLEFT", 4, -4)
titleBar:SetPoint("TOPRIGHT", -4, -4)
titleBar:SetHeight(28)

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", 10, 0)
titleText:SetText("|cffffff78TomTom|r  |cff555555/|r  |cffffd200" .. L["Options"] .. "|r")

-- Современная минималистичная кнопка закрытия
local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(18, 18)
closeBtn:SetPoint("RIGHT", -6, 0)

-- Чистая текстура крестика без золотых рамок
local closeTex = closeBtn:CreateTexture(nil, "ARTWORK")
closeTex:SetAllPoints()
closeTex:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
closeTex:SetVertexColor(0.7, 0.7, 0.75, 1)

closeBtn:SetScript("OnEnter", function()
	closeTex:SetVertexColor(1, 0.3, 0.3, 1)
end)
closeBtn:SetScript("OnLeave", function()
	closeTex:SetVertexColor(0.7, 0.7, 0.75, 1)
end)
closeBtn:SetScript("OnClick", function() GUI:Hide() end)

-- Тонкий горизонтальный разделитель под шапкой
local hLine = GUI:CreateTexture(nil, "ARTWORK")
hLine:SetPoint("TOPLEFT", 4, -32)
hLine:SetPoint("TOPRIGHT", -4, -32)
hLine:SetHeight(1)
hLine:SetTexture(0.20, 0.20, 0.24, 0.8)

-- Вертикальный разделитель между вкладками и контентом
local vLine = GUI:CreateTexture(nil, "ARTWORK")
vLine:SetPoint("TOPLEFT", 160, -33)
vLine:SetPoint("BOTTOMLEFT", 160, 4)
vLine:SetWidth(1)
vLine:SetTexture(0.20, 0.20, 0.24, 0.8)

-- Область контента со скроллом
local content = CreateFrame("ScrollFrame", "TomTomGUIContentScroll", GUI, "UIPanelScrollFrameTemplate")
content:SetPoint("TOPLEFT", 170, -44)
content:SetPoint("BOTTOMRIGHT", -26, 12)

-- Стилизация стандартного скроллбара под плоский стиль
local scrollBar = _G["TomTomGUIContentScrollScrollBar"]
if scrollBar then
	scrollBar:SetWidth(6)
	-- Скрываем стандартные кнопки со стрелками вверх/вниз
	local upBtn = _G["TomTomGUIContentScrollScrollBarScrollUpButton"]
	local downBtn = _G["TomTomGUIContentScrollScrollBarScrollDownButton"]
	if upBtn then upBtn:Hide() upBtn:SetSize(0.1, 0.1) end
	if downBtn then downBtn:Hide() downBtn:SetSize(0.1, 0.1) end

	-- Плоский бегунок скроллбара
	local thumb = scrollBar:GetThumbTexture()
	if thumb then
		thumb:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
		thumb:SetVertexColor(0.25, 0.25, 0.30, 0.8)
		thumb:SetWidth(6)
	end
end

local contentChild = CreateFrame("Frame", nil, content)
contentChild:SetSize(580, 500)
content:SetScrollChild(contentChild)

-- ============================================================================
-- Система динамического позиционирования и Retail-виджетов
-- ============================================================================
local currentY = -6
local widgetUID = 0

local function ClearContent()
	for _, child in ipairs({contentChild:GetChildren()}) do
		child:Hide()
		child:SetParent(nil)
	end
	for _, region in ipairs({contentChild:GetRegions()}) do
		region:Hide()
		if region:GetObjectType() == "FontString" then
			region:SetText("")
		end
	end
	currentY = -6
end

local function CreateSectionHeader(text)
	currentY = currentY - 8
	local fs = contentChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	fs:SetPoint("TOPLEFT", 10, currentY)
	fs:SetText("|cffffd200" .. tostring(text or "") .. "|r")

	local line = contentChild:CreateTexture(nil, "ARTWORK")
	line:SetPoint("TOPLEFT", 10, currentY - 18)
	line:SetSize(560, 1)
	line:SetTexture(0.22, 0.22, 0.26, 0.8)

	currentY = currentY - 28
end

-- Retail-тумблер (Modern Switch)
local function CreateSwitch(text, desc, profilePath, updateFunc, col)
	widgetUID = widgetUID + 1
	local name = "TomTomSwitch_" .. widgetUID

	local x = 10
	local width = 560
	if col == 1 then
		x = 10
		width = 270
	elseif col == 2 then
		x = 300
		width = 270
	end

	local row = CreateFrame("Button", name, contentChild)
	row:SetSize(width, 24)
	row:SetPoint("TOPLEFT", x, currentY)

	local track = CreateFrame("Frame", nil, row)
	track:SetSize(36, 18)
	track:SetPoint("LEFT", 0, 0)
	track:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})

	local thumb = track:CreateTexture(nil, "OVERLAY")
	thumb:SetSize(14, 14)
	thumb:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")

	local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", track, "RIGHT", 10, 0)
	label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
	label:SetJustifyH("LEFT")
	label:SetText(text or "")

	local val = TomTom.db.profile
	for _, part in ipairs(profilePath) do
		if val then val = val[part] end
	end
	local isChecked = (val and true or false)

	local function UpdateVisual(state)
		thumb:ClearAllPoints()
		if state then
			track:SetBackdropColor(0.12, 0.45, 0.85, 0.95)
			track:SetBackdropBorderColor(0.20, 0.60, 1.0, 1)
			thumb:SetPoint("RIGHT", track, "RIGHT", -2, 0)
			thumb:SetVertexColor(1, 1, 1, 1)
		else
			track:SetBackdropColor(0.15, 0.15, 0.18, 0.95)
			track:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
			thumb:SetPoint("LEFT", track, "LEFT", 2, 0)
			thumb:SetVertexColor(0.5, 0.5, 0.55, 1)
		end
	end
	UpdateVisual(isChecked)

	row:SetScript("OnClick", function()
		isChecked = not isChecked
		UpdateVisual(isChecked)

		local ref = TomTom.db.profile
		for i = 1, #profilePath - 1 do
			ref = ref[profilePath[i]]
		end
		ref[profilePath[#profilePath]] = isChecked
		if updateFunc then updateFunc() end
	end)

	if desc then
		row:SetScript("OnEnter", function(self)
			track:SetBackdropBorderColor(1, 0.82, 0, 1)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(text, 1, 1, 1)
			GameTooltip:AddLine(desc, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function(self)
			UpdateVisual(isChecked)
			GameTooltip:Hide()
		end)
	end

	if col ~= 1 then
		currentY = currentY - 28
	end
	return row
end

-- Retail-слайдер с темным статусбаром
local function CreateRetailSlider(text, desc, profilePath, minVal, maxVal, step, updateFunc, col)
	widgetUID = widgetUID + 1
	local name = "TomTomFlatSlider_" .. widgetUID

	local x = 14
	if col == 2 then
		x = 300
	end

	-- Базовый контейнер виджета
	local slider = CreateFrame("Slider", name, contentChild)
	slider:SetPoint("TOPLEFT", x, currentY - 18)
	slider:SetSize(190, 8)
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValueStep(step)
	slider:SetOrientation("HORIZONTAL")

	slider:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	slider:SetBackdropColor(0.12, 0.12, 0.15, 0.95)
	slider:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)

	-- Заголовок слайдера сверху полосы
	local header = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	header:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 6)
	header:SetPoint("RIGHT", slider, "RIGHT", 40, 0)
	header:SetJustifyH("LEFT")
	header:SetText(text or "")

	-- Заполняемый прогресс-бар
	local fill = slider:CreateTexture(nil, "BORDER")
	fill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	fill:SetVertexColor(0.12, 0.45, 0.85, 0.9)
	fill:SetPoint("TOPLEFT", slider, "TOPLEFT", 1, -1)
	fill:SetPoint("BOTTOMLEFT", slider, "BOTTOMLEFT", 1, 1)

	-- Бегунок слайдера
	local thumb = slider:CreateTexture(nil, "OVERLAY")
	thumb:SetSize(8, 14)
	thumb:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	thumb:SetVertexColor(0.9, 0.9, 0.95, 1)
	slider:SetThumbTexture(thumb)

	-- Современное поле ввода значения справа от слайдера
	local valEdit = CreateFrame("EditBox", name .. "Val", slider)
	valEdit:SetSize(46, 18)
	valEdit:SetPoint("LEFT", slider, "RIGHT", 10, 0)
	valEdit:SetFontObject("GameFontHighlightSmall")
	valEdit:SetJustifyH("CENTER")
	valEdit:SetAutoFocus(false)
	valEdit:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	valEdit:SetBackdropColor(0.10, 0.10, 0.12, 0.95)
	valEdit:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)

	local ref = TomTom.db.profile
	for _, part in ipairs(profilePath) do
		if ref then ref = ref[part] end
	end
	ref = tonumber(ref) or minVal
	slider:SetValue(ref)

	local function FormatVal(val)
		if step >= 1 then
			return string.format("%d", val)
		elseif step >= 0.1 then
			return string.format("%.1f", val)
		else
			return string.format("%.2f", val)
		end
	end

	local function UpdateVisuals(val)
		valEdit:SetText(FormatVal(val))
		valEdit:SetCursorPosition(0)
		local range = maxVal - minVal
		local perc = (range > 0) and ((val - minVal) / range) or 0
		fill:SetWidth(math.max(1, 188 * perc))
	end
	UpdateVisuals(ref)

	-- Реакция на движение ползунка
	slider:SetScript("OnValueChanged", function(self, value)
		local val = math.floor(value / step + 0.5) * step
		UpdateVisuals(val)

		local target = TomTom.db.profile
		for i = 1, #profilePath - 1 do
			target = target[profilePath[i]]
		end
		target[profilePath[#profilePath]] = val
		if updateFunc then updateFunc() end
	end)

	-- Ручной ввод числа с клавиатуры
	valEdit:SetScript("OnEnterPressed", function(self)
		local num = tonumber(self:GetText())
		if num then
			num = math.max(minVal, math.min(maxVal, num))
			slider:SetValue(num)
		else
			self:SetText(FormatVal(slider:GetValue()))
		end
		self:ClearFocus()
	end)
	valEdit:SetScript("OnEscapePressed", function(self)
		self:SetText(FormatVal(slider:GetValue()))
		self:ClearFocus()
	end)
	valEdit:SetScript("OnEditFocusGained", function(self)
		self:SetBackdropBorderColor(0.12, 0.45, 0.85, 1)
		self:HighlightText()
	end)
	valEdit:SetScript("OnEditFocusLost", function(self)
		self:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
		self:HighlightText(0, 0)
	end)

	if desc then
		slider:SetScript("OnEnter", function(self)
			slider:SetBackdropBorderColor(1, 0.82, 0, 1)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(text, 1, 1, 1)
			GameTooltip:AddLine(desc, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		slider:SetScript("OnLeave", function(self)
			slider:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
			GameTooltip:Hide()
		end)
	end

	if col ~= 1 then
		currentY = currentY - 44
	end
	return slider
end

local function CreateColorPickerRow(colors)
	local startX = 14
	local y = currentY - 4

	for idx, item in ipairs(colors) do
		widgetUID = widgetUID + 1
		local btn = CreateFrame("Button", "TomTomUIColor_" .. widgetUID, contentChild)
		btn:SetSize(20, 20)
		btn:SetPoint("TOPLEFT", startX, y)

		local border = btn:CreateTexture(nil, "BACKGROUND")
		border:SetSize(22, 22)
		border:SetPoint("CENTER")
		border:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")

		local swatch = btn:CreateTexture(nil, "ARTWORK")
		swatch:SetSize(16, 16)
		swatch:SetPoint("CENTER")
		swatch:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")

		local label = contentChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		label:SetPoint("LEFT", btn, "RIGHT", 6, 0)
		label:SetText(item.text)

		local ref = TomTom.db.profile
		for _, part in ipairs(item.path) do ref = ref[part] end
		swatch:SetVertexColor(ref[1], ref[2], ref[3])

		btn:SetScript("OnClick", function()
			local function ColorCallback(restore)
				local r, g, b, a
				if restore then
					r, g, b, a = unpack(restore)
				else
					r, g, b = ColorPickerFrame:GetColorRGB()
					a = item.hasAlpha and (1 - OpacitySliderFrame:GetValue()) or 1
				end
				ref[1], ref[2], ref[3] = r, g, b
				if item.hasAlpha then ref[4] = a end
				swatch:SetVertexColor(r, g, b)
				if item.updateFunc then item.updateFunc() end
			end

			ColorPickerFrame.func = ColorCallback
			ColorPickerFrame.hasOpacity = item.hasAlpha
			ColorPickerFrame.opacityFunc = ColorCallback
			ColorPickerFrame.cancelFunc = ColorCallback
			ColorPickerFrame.previousValues = {ref[1], ref[2], ref[3], ref[4] or 1}
			ColorPickerFrame:SetColorRGB(ref[1], ref[2], ref[3])
			if item.hasAlpha then OpacitySliderFrame:SetValue(1 - (ref[4] or 1)) end
			ColorPickerFrame:Hide()
			ColorPickerFrame:Show()
		end)

		startX = startX + 180
	end

	currentY = currentY - 34
end

local function CreateButton(text, width, onClick)
	local btn = CreateFrame("Button", nil, contentChild)
	btn:SetSize(width or 160, 24)
	btn:SetPoint("TOPLEFT", 14, currentY - 6)

	btn:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeSize = 1,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	btn:SetBackdropColor(0.16, 0.16, 0.20, 0.95)
	btn:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)

	btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	btn.text:SetPoint("CENTER", 0, 0)
	btn.text:SetText(text)

	btn:SetScript("OnEnter", function(self)
		self:SetBackdropColor(0.22, 0.22, 0.28, 1)
		self:SetBackdropBorderColor(0.12, 0.45, 0.85, 1)
		self.text:SetTextColor(1, 0.82, 0)
	end)
	btn:SetScript("OnLeave", function(self)
		self:SetBackdropColor(0.16, 0.16, 0.20, 0.95)
		self:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)
		self.text:SetTextColor(0.9, 0.9, 0.9)
	end)
	btn:SetScript("OnClick", onClick)

	currentY = currentY - 36
	return btn
end

-- ============================================================================
-- Вкладки страниц
-- ============================================================================
local tabs = {}
local activeTab = nil

local function ShowCategory(name)
	ClearContent()

if name == "arrow" then
		CreateSectionHeader(L["Waypoint Arrow"])
		CreateSwitch(L["Enable floating waypoint arrow"], nil, {"arrow", "enable"}, function() TomTom:ShowHideCrazyArrow() end, 1)
		CreateSwitch(L["Lock waypoint arrow"], L["Locks the waypoint arrow, so it can't be moved accidentally"], {"arrow", "lock"}, nil, 2)

		CreateSwitch(L["Show estimated time to arrival"], L["Shows an estimate of how long it will take you to reach the waypoint at your current speed"], {"arrow", "showtta"}, function() TomTom:ShowHideCrazyArrow() end, 1)
		CreateSwitch(L["Automatically set to next closest waypoint"], nil, {"arrow", "setclosest"}, nil, 2)

		CreateSwitch(L["Play a sound when arriving at a waypoint"], nil, {"arrow", "enablePing"}, nil, 0)
		CreateSwitch(L["Automatically set waypoint arrow"], L["When a new waypoint is added, TomTom can automatically set the new waypoint as the \"Crazy Arrow\" waypoint."], {"arrow", "autoqueue"}, nil, 0)
		CreateSwitch(L["Enable the right-click contextual menu"], nil, {"arrow", "menu"}, nil, 0)
		CreateSwitch(L["Disable all mouse input"], nil, {"arrow", "noclick"}, function() TomTom:ShowHideCrazyArrow() end, 0)

		CreateSectionHeader(L["Arrow display"])
		CreateRetailSlider(L["Scale"], nil, {"arrow", "scale"}, 0.2, 2.5, 0.05, function() TomTom:ShowHideCrazyArrow() end, 1)
		CreateRetailSlider(L["Alpha"], nil, {"arrow", "alpha"}, 0.1, 1.0, 0.05, function() TomTom:ShowHideCrazyArrow() end, 2)

		CreateRetailSlider(L["Title Scale"], nil, {"arrow", "title_scale"}, 0.2, 2.0, 0.05, function() TomTom:ShowHideCrazyArrow() end, 1)
		CreateRetailSlider(L["\"Arrival Distance\""], L["This setting will control the distance at which the waypoint arrow switches to a downwards arrow, indicating you have arrived at your destination"], {"arrow", "arrival"}, 0, 150, 5, nil, 2)

		CreateRetailSlider(L["Distance update frequency"], L["Controls how frequently the distance to the waypoint is calculated (arrow rotation is always updated every frame)"], {"arrow", "dist_throttle"}, 0.01, 0.3, 0.01, nil, 0)

		CreateSectionHeader(L["Arrow colors"])
		CreateColorPickerRow({
			{ text = L["Good color"], path = {"arrow", "goodcolor"}, hasAlpha = false },
			{ text = L["Middle color"], path = {"arrow", "middlecolor"}, hasAlpha = false },
			{ text = L["Bad color"], path = {"arrow", "badcolor"}, hasAlpha = false },
		})

		CreateButton(L["Reset Position"], 180, function()
			if TomTomCrazyArrow then
				TomTomCrazyArrow:ClearAllPoints()
				TomTomCrazyArrow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			end
		end)

	elseif name == "block" then
		CreateSectionHeader(L["Coordinate Block"])
		CreateSwitch(L["Enable coordinate block"], L["Enables a floating block that displays your current position in the current zone"], {"block", "enable"}, function() TomTom:ShowHideCoordBlock() end, 1)
		CreateSwitch(L["Lock coordinate block"], L["Locks the coordinate block so it can't be accidentally dragged to another location"], {"block", "lock"}, nil, 2)

		CreateSectionHeader(L["Display Settings"])
		CreateRetailSlider(L["Coordinate Accuracy"], nil, {"block", "accuracy"}, 0, 2, 1, nil, 1)
		CreateRetailSlider(L["Font size"], nil, {"block", "fontsize"}, 8, 24, 1, function() TomTom:ShowHideCoordBlock() end, 2)

		CreateRetailSlider(L["Block width"], nil, {"block", "width"}, 50, 250, 5, function() TomTom:ShowHideCoordBlock() end, 1)
		CreateRetailSlider(L["Block height"], nil, {"block", "height"}, 15, 60, 1, function() TomTom:ShowHideCoordBlock() end, 2)

		CreateColorPickerRow({
			{ text = L["Background color"], path = {"block", "bgcolor"}, hasAlpha = true, updateFunc = function() TomTom:ShowHideCoordBlock() end },
			{ text = L["Border color"], path = {"block", "bordercolor"}, hasAlpha = true, updateFunc = function() TomTom:ShowHideCoordBlock() end },
		})

		CreateButton(L["Reset Position"], 180, function()
			if TomTomBlock then
				TomTomBlock:ClearAllPoints()
				TomTomBlock:SetPoint("TOP", Minimap, "BOTTOM", -20, -10)
			end
		end)

	elseif name == "map" then
		CreateSectionHeader(L["World Map"])
		CreateSwitch(L["Enable world map waypoints"], nil, {"worldmap", "enable"}, function() TomTom:ReloadWaypoints() end, 1)
		CreateSwitch(L["Enable mouseover tooltips"], nil, {"worldmap", "tooltip"}, nil, 2)
		CreateSwitch(L["Allow control-right clicking on map to create new waypoint"], nil, {"worldmap", "clickcreate"}, nil, 0)
		CreateSwitch(L["Enable the right-click contextual menu"], nil, {"worldmap", "menu"}, nil, 0)

		CreateSectionHeader(L["Player Coordinates"])
		CreateSwitch(L["Enable showing player coordinates"], nil, {"mapcoords", "playerenable"}, function() TomTom:ShowHideWorldCoords() end, 1)
		CreateRetailSlider(L["Player coordinate accuracy"], nil, {"mapcoords", "playeraccuracy"}, 0, 2, 1, nil, 2)

		CreateSectionHeader(L["Cursor Coordinates"])
		CreateSwitch(L["Enable showing cursor coordinates"], nil, {"mapcoords", "cursorenable"}, function() TomTom:ShowHideWorldCoords() end, 1)
		CreateRetailSlider(L["Cursor coordinate accuracy"], nil, {"mapcoords", "cursoraccuracy"}, 0, 2, 1, nil, 2)

		CreateSectionHeader(L["Minimap"])
		CreateSwitch(L["Enable minimap waypoints"], nil, {"minimap", "enable"}, function() TomTom:ReloadWaypoints() end, 1)
		CreateSwitch(L["Enable mouseover tooltips"], nil, {"minimap", "tooltip"}, nil, 2)
		CreateSwitch(L["Enable the right-click contextual menu"], nil, {"minimap", "menu"}, nil, 0)

	elseif name == "poi" then
		CreateSectionHeader(L["Quest Objectives"])
		CreateSwitch(L["Enable quest objective click integration"], L["Enables the setting of waypoints when modified-clicking on quest objectives"], {"poi", "enable"}, function() TomTom:EnableDisablePOIIntegration() end, 0)
		CreateSwitch(L["Enable automatic quest objective waypoints"], L["Enables the automatic setting of quest objective waypoints based on which objective is closest to your current location.  This setting WILL override the setting of manual waypoints."], {"poi", "setClosest"}, function() TomTom:EnableDisablePOIIntegration() end, 0)

	elseif name == "feeds" then
		CreateSectionHeader(L["Data Feeds"])
		CreateSwitch(L["Provide a LDB data source for coordinates"], nil, {"feeds", "coords"}, nil, 0)
		CreateRetailSlider(L["Coordinate feed throttle"], nil, {"feeds", "coords_throttle"}, 0, 2.0, 0.05, function()
			if TomTom.UpdateCoordFeedThrottle then
				TomTom:UpdateCoordFeedThrottle()
			end
		end, 1)
		CreateRetailSlider(L["Coordinate feed accuracy"], nil, {"feeds", "coords_accuracy"}, 0, 2, 1, nil, 2)

		CreateSwitch(L["Provide a LDB data source for the crazy-arrow"], nil, {"feeds", "arrow"}, nil, 0)
		CreateRetailSlider(L["Crazy Arrow feed throttle"], nil, {"feeds", "arrow_throttle"}, 0, 2.0, 0.05, function()
			if TomTom.UpdateArrowFeedThrottle then
				TomTom:UpdateArrowFeedThrottle()
			end
		end, 0)

	elseif name == "general" then
		CreateSectionHeader(L["General Options"])
		CreateSwitch(L["Announce new waypoints when they are added"], nil, {"general", "announce"}, nil, 0)
		CreateSwitch(L["Ask for confirmation on \"Remove All\""], nil, {"general", "confirmremoveall"}, nil, 0)
		CreateSwitch(L["Save new waypoints until I remove them"], nil, {"general", "savewaypoints"}, nil, 0)
		CreateSwitch(L["Automatically set a waypoint when I die"], nil, {"general", "corpse_arrow"}, nil, 0)

		CreateRetailSlider(L["Clear waypoint distance"], L["Waypoints can be automatically cleared when you reach them.  This slider allows you to customize the distance in yards that signals your \"arrival\" at the waypoint.  A setting of 0 turns off the auto-clearing feature\n\nChanging this setting only takes effect after reloading your interface."], {"persistence", "cleardistance"}, 0, 150, 1, nil, 0)
	end

	local totalHeight = math.abs(currentY) + 10
	local visibleHeight = content:GetHeight() or 500
	contentChild:SetHeight(math.max(visibleHeight, totalHeight))
end

local function CreateTabButton(label, catKey, index)
	local btn = CreateFrame("Button", nil, GUI)
	btn:SetSize(148, 30)
	btn:SetPoint("TOPLEFT", 6, -42 - (index - 1) * 32)

	btn.bg = btn:CreateTexture(nil, "BACKGROUND")
	btn.bg:SetAllPoints()
	btn.bg:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
	btn.bg:SetAlpha(0.15)

	btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	btn.text:SetPoint("LEFT", 12, 0)
	btn.text:SetText(label)

	btn:SetScript("OnClick", function()
		for _, tab in ipairs(tabs) do
			tab.bg:SetAlpha(0.15)
			tab.text:SetTextColor(0.8, 0.8, 0.8)
		end
		btn.bg:SetAlpha(0.7)
		btn.text:SetTextColor(1, 0.82, 0)
		activeTab = btn
		ShowCategory(catKey)
	end)

	btn:SetScript("OnEnter", function(self)
		if activeTab ~= self then self.bg:SetAlpha(0.35) end
	end)
	btn:SetScript("OnLeave", function(self)
		if activeTab ~= self then self.bg:SetAlpha(0.15) end
	end)

	table.insert(tabs, btn)
	return btn
end

CreateTabButton(L["Crazy Arrow"], "arrow", 1)
CreateTabButton(L["Coordinates"], "block", 2)
CreateTabButton(L["World & Minimap"], "map", 3)
CreateTabButton(L["Quests & POI"], "poi", 4)
CreateTabButton(L["Data Feeds"], "feeds", 5)
CreateTabButton(L["General"], "general", 6)

function TomTom:OpenConfig()
	if GUI:IsShown() then
		GUI:Hide()
	else
		GUI:Show()
		tabs[1]:GetScript("OnClick")(tabs[1])
	end
end

SLASH_TOMTOM_CUSTOM1 = "/tomtom"
SlashCmdList["TOMTOM_CUSTOM"] = function()
	TomTom:OpenConfig()
end