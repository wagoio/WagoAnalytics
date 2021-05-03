--[[
Include the Shim.lua inside of your AddOn for when users decide to opt-out of contributing analytics data.
Simply drop the file inside of your AddOn, and include it in your TOC file

Example Usage:

Options = {
	breadcrumbCount = 10, -- Default: 20. Number of breadcrumbs to push with an error
	reportErrors = true, -- Default: true. Should we report errors?
}

local WagoAnalytics = LibStub("WagoAnalytics"):Register("<Your Wago addon ID>") -- 2nd argument is an optional list of options

-- Add breadcrumb data with arg1 table of information
WagoAnalytics:Breadcrumb({
	someData = "Hello",
	otherData = "World"
})

-- Increments the counter arg1 by arg2 amount
WagoAnalytics:Counter("SomeCounter", 50)

-- Set a boolean arg1 value to true
WagoAnalytics:Gauge("SomeGauge")

-- Throw a custom error message arg1. This includes the previous breadcrumbs automatically.
WagoAnalytics:Error("Variable was expected to be defined, but wasn't")
--]]

local MAJOR, MINOR = "WagoAnalytics", 1

local WagoAnalytics = LibStub:NewLibrary(MAJOR, MINOR)
if not WagoAnalytics then return end -- Version is already loaded

local SV = {}

do
	local tostring, ipairs, debugstack, debuglocals, date, gsub, format, random, tIndexOf, tinsert, tremove =
		tostring, ipairs, debugstack, debuglocals, date, string.gsub, string.format, math.random, tIndexOf, table.insert, table.remove
	local UnitAffectingCombat, InCombatLockdown, GetNumAddOns, GetAddOnInfo, GetAddOnMetadata, CreateFrame, IsLoggedIn, UnitClass, UnitLevel, UnitRace, GetPlayerFactionGroup, GetCurrentRegionName, GetSpecialization, GetSpecializationInfo =
		UnitAffectingCombat, InCombatLockdown, GetNumAddOns, GetAddOnInfo, GetAddOnMetadata, CreateFrame, IsLoggedIn, UnitClass, UnitLevel, UnitRace, GetPlayerFactionGroup, GetCurrentRegionName, GetSpecialization, GetSpecializationInfo

	local function handleError(errorMessage, isSimple)
		errorMessage = tostring(errorMessage)
		for _, err in ipairs(SV.errors) do
			if err.message == errorMessage then
				return
			end
		end
		if isSimple then
			tinsert(SV.errors, {
				addon = string.match(errorMessage, "AddOns\\([^\\]+)\\") or "Unknown",
				message = errorMessage
			})
		else
			tinsert(SV.errors, {
				addon = string.match(errorMessage, "AddOns\\([^\\]+)\\") or "Unknown",
				message = errorMessage,
				stack = debugstack(3),
				locals = (InCombatLockdown() or UnitAffectingCombat("player")) and "InCombatSkipped" or debuglocals(3)
			})
		end
	end
	_G.seterrorhandler(handleError)

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	frame:RegisterEvent("PLAYER_LEVEL_UP")
	frame:RegisterEvent("ADDON_LOADED")
	frame:RegisterEvent("ADDON_ACTION_BLOCKED")
	frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
	frame:RegisterEvent("LUA_WARNING")
	frame:SetScript("OnEvent", function(self, event, arg1, arg2)
		if event == "PLAYER_LOGIN" then
			if not IsLoggedIn() then
				return
			end
			if not WagoAnalyticsSV then
				WagoAnalyticsSV = {}
			end
			local uuid = gsub("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "x", function()
				return format("%x", random(0, 0xf))
			end)
			local _, playerClass = UnitClass("player")
			local currentSpecName, currentSpec = "Unknown", GetSpecialization()
			if currentSpec then
				_, currentSpecName = GetSpecializationInfo(currentSpec)
			end
			local _, playerRace = UnitRace("player")
			local addons = {}
			for i = 1, GetNumAddOns() do
				local name, _, _, enabled = GetAddOnInfo(i)
				if enabled then
					addons[name] = GetAddOnMetadata(i, "Version")
				end
			end
			WagoAnalyticsSV[uuid] = {
				addons = {},
				errors = {},
				playerData = {
					class = playerClass,
					region = GetCurrentRegionName(),
					specs = {currentSpecName},
					levelMin = UnitLevel("player"),
					race = playerRace,
					faction = GetPlayerFactionGroup("player")
				}
			}
			SV = WagoAnalyticsSV[uuid]
		elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
			local currentSpecName, currentSpec = "Unknown", GetSpecialization()
			if currentSpec then
				_, currentSpecName = GetSpecializationInfo(currentSpec)
			end
			if not tIndexOf(SV.playerData.specs, currentSpecName) then
				tinsert(SV.playerData.specs, currentSpecName)
			end
		elseif event == "PLAYER_LEVEL_UP" then
			SV.playerData.levelMax = arg1
		elseif event == "ADDON_LOADED" then
			SV.addons[arg1] = GetAddOnMetadata(arg1, "Version")
		elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
			handleError(("[%s] AddOn '%s' tried to call the protected function '%s'."):format(event, arg1 or "<name>", arg2 or "<func>"))
		elseif event == "LUA_WARNING" then
			handleError(arg2, true)
		end
	end)
end

local wagoPrototype = {}

function wagoPrototype:Counter(name, increment)
	self.counters[name] = (self.counters[name] or 0) + (increment or 1)
	self:Save()
end

function wagoPrototype:Gauge(name)
	self.gauges[name] = true
	self:Save()
end

do
	local tinsert, type = table.insert, type

	function wagoPrototype:Error(error)
		if type(error) == "string" and #error > 1024 then
			error = error:sub(0, 1021) .. "..."
		end
		tinsert(self.errors, {
			error = error,
			breadcrumb = self.breadcrumbs
		})
		self:Save()
	end
end

do
	local tremove, tinsert, type = table.remove, table.insert, type

	function wagoPrototype:Breadcrumb(data)
		if #self.breadcrumbs > self.options.breadcrumbCount then
			tremove(self.breadcrumbs, 1)
		end
		if type(data) == "string" and #data > 255 then
			data = data:sub(0, 252) .. "..."
		end
		tinsert(self.breadcrumbs, data)
		self:Save()
	end
end

function wagoPrototype:Save()
	if not SV[self.addon] then
		SV[self.addon] = {}
	end
	SV[self.addon] = {
		counters = self.counters,
		gauges = self.gauges,
		errors = self.errors
	}
end

local addons = {}

do
	local mmin, setmetatable = math.min, setmetatable

	function WagoAnalytics:Register(addon, options)
		if not options then
			options = {}
		end
		options.breadcrumbCount = mmin(options.breadcrumbCount or 20, 50)
		if options.reportErrors == nil then
			options.reportErrors = true
		end
		local obj = setmetatable({
			addon = addon,
			options = options,
			counters = {},
			gauges = {},
			errors = {},
			breadcrumbs = {}
		}, {
			__index = wagoPrototype
		})
		addons[addon] = obj
		return obj
	end
end