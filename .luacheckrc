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
	"WOW_PROJECT_MISTS_CLASSIC",
	"WOW_PROJECT_CATACLYSM_CLASSIC",
	"WOW_PROJECT_ID",

	-- WoW API
	"C_AddOns.GetAddOnInfo",
	"C_AddOns.GetAddOnMetadata",
	"C_AddOns.GetNumAddOns",
	"C_SpecializationInfo.GetSpecialization", -- MoP only
	"C_SpecializationInfo.GetSpecializationInfo", -- MoP only
	"CreateCircularBuffer",
	"CreateFrame",
	"GetAddOnInfo",
	"GetAddOnMetadata",
	"GetCurrentRegion",
	"GetLocale",
	"GetNumAddOns",
	"GetPrimaryTalentTree", -- Cata only
	"GetRealmName",
	"GetSpecialization", -- Retail only
	"GetSpecializationInfo", -- Retail only
	"GetTalentTabInfo", -- Cata only
	"InCombatLockdown",
	"UnitAffectingCombat",
	"UnitClass",
	"UnitFactionGroup",
	"UnitLevel",
	"UnitName",
	"UnitRace",
}
