std = "lua51"
max_line_length = false
exclude_files = {
	".luacheckrc"
}
ignore = {
	"212/self", -- Unused argument "self" (WagoAnalytics:Register)
}
globals = {
	-- Global variable
	"WagoAnalyticsSV",
	"WagoAnalytics",

	-- Lua
	"debuglocals",
	"debugstack",
	"time",
	"tIndexOf",

	-- WoW Constants
	"WOW_PROJECT_MAINLINE",
	"WOW_PROJECT_ID",

	-- WoW API
	"CreateCircularBuffer",
	"CreateFrame",
	"GetAddOnInfo",
	"GetAddOnMetadata",
	"GetCurrentRegion",
	"GetLocale",
	"GetNumAddOns",
	"GetRealmName",
	"GetSpecialization",
	"GetSpecializationInfo",
	"InCombatLockdown",
	"UnitAffectingCombat",
	"UnitClass",
	"UnitFactionGroup",
	"UnitLevel",
	"UnitName",
	"UnitRace",
}