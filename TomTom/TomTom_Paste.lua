--[[--------------------------------------------------------------------------
--  TomTom_Paste.lua
--  Автономный модуль пакетного импорта координат (/ttpaste /paste)
----------------------------------------------------------------------------]]

local PasteFrame = CreateFrame("Frame", "TomTomPasteFrame", UIParent)
PasteFrame:SetSize(400, 300)
PasteFrame:SetPoint("CENTER")
PasteFrame:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
PasteFrame:EnableMouse(true)
PasteFrame:SetMovable(true)
PasteFrame:RegisterForDrag("LeftButton")
PasteFrame:SetScript("OnDragStart", PasteFrame.StartMoving)
PasteFrame:SetScript("OnDragStop", PasteFrame.StopMovingOrSizing)
PasteFrame:Hide()

local title = PasteFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", 0, -14)
title:SetText("TomTom Batch Import (/ttpaste)")

local scroll = CreateFrame("ScrollFrame", "TomTomPasteScroll", PasteFrame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 16, -40)
scroll:SetPoint("BOTTOMRIGHT", -36, 45)

local editBox = CreateFrame("EditBox", nil, scroll)
editBox:SetMultiLine(true)
editBox:SetMaxLetters(99999)
editBox:EnableMouse(true)
editBox:SetAutoFocus(false)
editBox:SetFontObject(ChatFontNormal)
editBox:SetWidth(340)
editBox:SetScript("OnEscapePressed", function() PasteFrame:Hide() end)
scroll:SetScrollChild(editBox)

local btnImport = CreateFrame("Button", nil, PasteFrame, "UIPanelButtonTemplate")
btnImport:SetSize(100, 24)
btnImport:SetPoint("BOTTOMLEFT", 16, 12)
btnImport:SetText("Импорт")

local btnClose = CreateFrame("Button", nil, PasteFrame, "UIPanelButtonTemplate")
btnClose:SetSize(100, 24)
btnClose:SetPoint("BOTTOMRIGHT", -16, 12)
btnClose:SetText("Закрыть")
btnClose:SetScript("OnClick", function() PasteFrame:Hide() end)

btnImport:SetScript("OnClick", function()
	local text = editBox:GetText()
	if not text or text == "" then return end

	local count = 0
	for line in text:gmatch("[^\r\n]+") do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		-- Распознаем строки вида /way, /tway или чистые координаты
		if line:find("^/way") or line:find("^/tway") then
			local msg = line:gsub("^/%a+%s+", "")
			SlashCmdList["TOMTOM_WAY"](msg)
			count = count + 1
		elseif line:match("^(%d+%.?%d*)%s+(%d+%.?%d*)") then
			SlashCmdList["TOMTOM_WAY"](line)
			count = count + 1
		end
	end

	editBox:SetText("")
	PasteFrame:Hide()
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffffff78TomTom:|r Импортировано точек: %d", count))
end)

SLASH_TOMTOM_PASTE1 = "/ttpaste"
SLASH_TOMTOM_PASTE2 = "/waypaste"
SlashCmdList["TOMTOM_PASTE"] = function()
	if PasteFrame:IsShown() then
		PasteFrame:Hide()
	else
		PasteFrame:Show()
		editBox:SetFocus()
	end
end