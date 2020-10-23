return function(req, res, go)

	local cookieHeaders = req.headers["Cookie"]
	req.cookies = {}
	if cookieHeaders ~= nil then

		for m in string.gmatch(cookieHeaders, "[^;]+;?") do
			local key, value = string.match(m, "([^=]+)=([^=]+)")
			if key ~= nil and value ~= nil then
				req.cookies[key] = value
			end
		end

	end

	go()
end