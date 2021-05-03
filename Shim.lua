local WagoAnalytics = LibStub:NewLibrary("WagoAnalytics", 0)

function WagoAnalytics:Register()
	return setmetatable({}, {
		__index = {
			Counter = function() end,
			Gauge = function() end,
			Error = function() end,
			Breadcrumb = function() end
		}
	})
end