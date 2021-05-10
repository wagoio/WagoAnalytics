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
local WagoAnalytics = LibStub:NewLibrary("WagoAnalytics", 1)
if not WagoAnalytics then return end -- Version is already loaded

local type = type
local playerClass, playerRegion, playerSpecs, playerMinLevel, playerMaxLevel, playerRace, playerFaction, playerAddons, playerLocale
local registeredAddons = {}

do
	local tostring, ipairs, debugstack, debuglocals, date, tIndexOf, tinsert, tremove, match =
		tostring, ipairs, debugstack, debuglocals, date, tIndexOf, table.insert, table.remove, string.match
	local GetLocale, UnitAffectingCombat, InCombatLockdown, GetNumAddOns, GetAddOnInfo, GetAddOnMetadata, CreateFrame, IsLoggedIn, UnitClass, UnitLevel, UnitRace, GetPlayerFactionGroup, GetCurrentRegionName, GetSpecialization, GetSpecializationInfo =
		GetLocale, UnitAffectingCombat, InCombatLockdown, GetNumAddOns, GetAddOnInfo, GetAddOnMetadata, CreateFrame, IsLoggedIn, UnitClass, UnitLevel, UnitRace, GetPlayerFactionGroup, GetCurrentRegionName, GetSpecialization, GetSpecializationInfo

	local function handleError(errorMessage, isSimple)
		errorMessage = tostring(errorMessage)
		local wagoID = GetAddOnMetadata(match(errorMessage, "AddOns\\([^\\]+)\\") or "Unknown", "X-Wago-ID")
		if not wagoID or not registeredAddons[wagoID] then
			return
		end
		local addon = registeredAddons[wagoID]
		for _, err in ipairs(addon.errors) do
			if err.message and err.message == errorMessage then
				return
			end
		end
		if isSimple then
			addon:Error({
				message = errorMessage
			})
		else
			addon:Error({
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
			_, playerClass = UnitClass("player")
			local currentSpec = GetSpecialization()
			if currentSpec then
				local _, playerSpec = GetSpecializationInfo(currentSpec)
				playerSpecs = {}
				tinsert(playerSpecs, playerSpec)
			end
			_, playerRace = UnitRace("player")
			playerMinLevel = UnitLevel("player")
			playerMaxLevel = playerMinLevel
			playerLocale = GetLocale()
			playerAddons = {}
			for i = 1, GetNumAddOns() do
				local name, _, _, enabled = GetAddOnInfo(i)
				if enabled then
					playerAddons[name] = GetAddOnMetadata(i, "Version")
				end
			end
		elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
			local currentSpec = GetSpecialization()
			if currentSpec then
				local _, playerSpec = GetSpecializationInfo(currentSpec)
				if not tIndexOf(playerSpecs, playerSpec) then
					tinsert(playerSpecs, playerSpec)
				end
			end
		elseif event == "PLAYER_LEVEL_UP" then
			playerMaxLevel = arg1
		elseif event == "ADDON_LOADED" then
			playerAddons[arg1] = GetAddOnMetadata(arg1, "Version")
		elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
			handleError(("[%s] AddOn '%s' tried to call the protected function '%s'."):format(event, arg1 or "<name>", arg2 or "<func>"))
		elseif event == "LUA_WARNING" then
			handleError(arg2, true)
		end
	end)
end

local TableHas
do
	local pairs = pairs

	function TableHas(table, number)
		local count = 0
		for _, _ in pairs(table) do
			count = count + 1
			if count >= number then
				return true
			end
		end
		return count >= number
	end
end

local wagoPrototype = {}

function wagoPrototype:Counter(name, increment)
	if type(name) ~= "string" then
		return false
	end
	if TableHas(self.counters, 512) then
		return false
	end
	if #name > 128 then
		name = name:sub(0, 128)
	end
	self.counters[name] = (self.counters[name] or 0) + (increment or 1)
	self:Save()
end

function wagoPrototype:Gauge(name)
	if type(name) ~= "string" then
		return false
	end
	if TableHas(self.gauges, 512) then
		return false
	end
	if #name > 128 then
		name = name:sub(0, 128)
	end
	self.gauges[name] = true
	self:Save()
end

do
	local tinsert = table.insert

	function wagoPrototype:Error(error)
		if type(error) ~= "string" then
			return false
		end
		if #error > 1024 then
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
		if type(data) ~= "string" then
			return false
		end
		if #data > 255 then
			data = data:sub(0, 252) .. "..."
		end
		tinsert(self.breadcrumbs, data)
	end
end

do
	local gsub, format, random, time, pairs = string.gsub, string.format, math.random, time, pairs
	local SV

	function wagoPrototype:Save()
		if not SV then
			local uuid = gsub("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "x", function()
				return format("%x", random(0, 0xf))
			end)
			WagoAnalyticsSV[uuid] = {
				time = time(),
				addons = playerAddons,
				playerData = {
					locale = playerLocale,
					class = playerClass,
					region = playerRegion,
					specs = playerSpecs,
					levelMin = playerMinLevel,
					levelMax = playerMaxLevel,
					race = playerRace,
					faction = playerFaction
				}
			}
			local count, lastK, lastTime = 0, nil, math.maxinteger
			for k, v in pairs(WagoAnalyticsSV) do
				count = count + 1
				if count > 256 then
					WagoAnalyticsSV[lastK] = nil
					break
				end
				if v.time < lastTime then
					lastK = k
					lastTime = v.time
				end
			end
			SV = WagoAnalyticsSV[uuid]
		end
		local dat = {}
		if TableHas(self.counters, 1) then
			dat.counters = self.counters
		end
		if TableHas(self.gauges, 1) then
			dat.gauges = self.gauges
		end
		if #self.errors > 0 then
			dat.errors = self.errors
		end
		SV[self.addon] = dat
	end
end

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
		registeredAddons[addon] = obj
		return obj
	end
end