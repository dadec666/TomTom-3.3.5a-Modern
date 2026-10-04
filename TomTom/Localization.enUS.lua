--Localization.enUS.lua

TomTomLocals = {
    ["Distance update frequency"] = "Distance update frequency",
	["Controls how frequently the distance to the waypoint is calculated (arrow rotation is always updated every frame)"] = "Controls how frequently the distance to the waypoint is calculated (arrow rotation is always updated every frame)",
    ["Left-click"] = "Left-click",
	["Right-click"] = "Right-click",
	["Shift + Right-click"] = "Shift + Right-click",
	["Options"] = "Options",
	["Batch import (/ttpaste)"] = "Batch import (/ttpaste)",
    ["TomTom Configuration"] = "TomTom Configuration",
	["Crazy Arrow"] = "Crazy Arrow",
	["Coordinates"] = "Coordinates",
	["World & Minimap"] = "World & Minimap",
	["Quests & POI"] = "Quests & POI",
	["General"] = "General",
	["Close"] = "Close",
}

setmetatable(TomTomLocals, {__index=function(t,k) rawset(t, k, k); return k; end})
