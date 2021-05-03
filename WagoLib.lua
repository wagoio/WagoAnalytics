--[[
Example Usage:

Options = {
	breadcrumbCount = 10, -- Default: 20. Number of breadcrumbs to push with an error
	reportErrors = true, -- Default: true. Should we report errors?
}

local WagoLib = LibStub("WagoLib"):Register("<Your Wago addon ID>") -- 2nd argument is an optional list of options

-- Add breadcrumb data with arg1 table of information
WagoLib:Breadcrumb({
	someData = "Hello",
	otherData = "World"
})

-- Increments the counter arg1 by arg2 amount
WagoLib:Counter("SomeCounter", 50)

-- Set a boolean arg1 value to true
WagoLib:Gauge("SomeGauge")

-- Throw a custom error message arg1. This includes the previous breadcrumbs automatically.
WagoLib:Error("Variable was expected to be defined, but wasn't")
--]]

local MAJOR, MINOR = "LibWago", 1

local WagoLib
if WagoLib then
	WagoLib = LibStub:NewLibrary(MAJOR, MINOR)
	if not WagoLib then return end -- Version is already loaded
else
	WagoLib = {}
end

local SV = {}

do
	local gsub, format, random, tIndexOf, tinsert = string.gsub, string.format, math.random, tIndexOf, table.insert
	local CreateFrame, IsLoggedIn, UnitClass, UnitLevel, GetCurrentRegionName, GetSpecialization, GetSpecializationInfo = CreateFrame, IsLoggedIn, UnitClass, UnitLevel, GetCurrentRegionName, GetSpecialization, GetSpecializationInfo

	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	frame:RegisterEvent("PLAYER_LEVEL_UIP")
	function frame:OnEvent(_, event, arg1)
		if event == "PLAYER_LOGIN" then
			if not IsLoggedIn() then
				return
			end
			if not WagoLibSV then
				WagoLibSV = {}
			end
			local uuid = gsub("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", "x", function()
				return format('%x', random(0, 0xf))
			end)
			local _, playerClass = UnitClass("player")
			local currentSpec = GetSpecialization()
			local _, currentSpecName = currentSpec and GetSpecializationInfo(currentSpec) or nil, "Unknown"
			WagoLibSV[uuid] = {
				playerData = {
					class = playerClass,
					region = GetCurrentRegionName(),
					specs = {currentSpecName},
					levelMin = UnitLevel("player")
				}
			}
			SV = WagoLibSV[uuid]
		elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
			local currentSpec = GetSpecialization()
			local _, currentSpecName = currentSpec and GetSpecializationInfo(currentSpec) or nil, "Unknown"
			if not tIndexOf(SV.playerData.specs, currentSpecName) then
				tinsert(SV.playerData.specs, currentSpecName)
			end
		elseif event == "PLAYER_LEVEL_UP" then
			SV.playerData.levelMax = arg1
		end
	end
end

local wagoPrototype = {}

function wagoPrototype:Counter(name, increment)
	self.counters[name] = (self.counters[name] or 0) + increment
	self:Save()
end

function wagoPrototype:Gauge(name)
	self.gauges[name] = true
	self:Save()
end

do
	local tinsert = table.insert

	function wagoPrototype:Error(error)
		tinsert(self.errors, {
			error: error,
			breadcrumb: self.breadcrumbs
		})
		self:Save()
	end
end

do
	local tremove, tinsert = table.remove, table.insert

	function wagoPrototype:Breadcrumb(data)
		if #self.breadcrumbs > self.options.breadcrumbCount then
			tremove(self.breadcrumbs, 1)
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
		guages = self.guages,
		errors = self.errors
	}
end

local addons = {}

do
	local mmin, setmetatable = math.min, setmetatable

	function WagoLib:Register(addon, options)
		if not options then
			options = {
				breadcrumbCount = 20,
				reportErrors = true
			}
		end
		options.breadcrumbCount = mmin(options.breadcrumbCount, 50)
		local obj = setmetatable({
			addon: addon,
			options: options,
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