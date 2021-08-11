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
	"UnitClassBase",
	"UnitFactionGroup",
	"UnitLevel",
	"UnitName",
	"UnitRace",
}