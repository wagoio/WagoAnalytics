local MAJOR, MINOR = "WagoLib", 0
local WagoLib = LibStub:NewLibrary(MAJOR, MINOR)

function WagoLib:Register()
	return setmetatable({}, {
		__index = {
			Counter = function() end,
			Gauge = function() end,
			Error = function() end,
			Breadcrumb = function() end
		}
	})
end