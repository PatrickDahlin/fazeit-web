local fs = require("coro-fs")
local fs2 = require("fs")
local sha1 = require("sha1")
local mime = require("mime")
local pprint = require("pretty-print").prettyPrint



return function (hostPath)
	
	local folder = fs2.stat(hostPath)
	assert(folder ~= nil)
	
	return function(req, res, go)

		local path = req.path or req.params.path
		-- Check for leading slash
		if path:byte(1) == tostring("/"):byte(1) then
			path = path:sub(2)
		end

		if path == "" then 
			path = "index.html"
		end

		local status = fs.stat(hostPath.."/"..path)
		if status ~= nil then
			-- return file contents
			local lastm_time = status.mtime -- seconds since 1 Jan 1970 UTC
			local len = status.st_size
			-- Last-Modified: <day-name>, <day> <month> <year> <hour>:<minute>:<second> GMT
			local m_time = os.date("!%a, %d %m %Y %H:%M:%S GMT",lastm_time.sec)
			local req_last_mod = req.headers["If-Modified-Since"]
			
			res.headers["Content-Type"] = mime.getType(path)
			res.headers["Content-Length"] = len
			res.headers["Cache-Control"] = "must-revalidate"--"no-cache, max-age=0"
			res.headers["Last-Modified"] = m_time

			if m_time == req_last_mod and (req.method == "HEAD" or req.method == "GET") then
				print("File hasn't been changed -> 304 no body")
				res.code = 304 -- Not Modified
				res.body = nil
				return
			end

			local data = fs.readFile(hostPath.."/"..path)
			--pprint(m_time)
			res.code = 200
			res.body = data
			res.headers["ETag"] = sha1(data)
			print("200 -> file body")
			return
			--print("File size: "..(status.size or "n/a"))
		else
			print("File not found! "..path)
		end
		go()
	end
end