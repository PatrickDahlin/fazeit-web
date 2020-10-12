--[[lit-meta
	name = "PatrickDahlin/fazeit-cache"
	version = "0.0.1"
	description = "WIP"
	tags = {"weblit", "middleware", "cache"}
	dependencies = {
		'creationix/sha1@1.0.3'
  	}
	license = "MIT"
	author = { name = "Patrick Dahlin" }
	homepage = "TBA"
]]

local function clone(headers)
  local c = {}
  for k,v in pairs(headers) do c[k] = v end 
  return setmetatable(c, getmetatable(headers))
end

local shasum = require("sha1")

--
-- 200 (OK) should send the following
--   - ETag
--   - Last-Modified
-- If Last-Modified is sent then cache-validator responses should be available(!)
-- One of these cache-validators is If-Match, this checks for existence of any resource
-- with the matching tag. (or * if check for any resource)
--	In case If-Match fails then no change is made and 412 (Precondition failed) response is sent
-- If-Modified needs a If-Unchanged-Since validator based on GMT timestamps (see {"Date", date("!%a, %d %b %Y %H:%M:%S GMT")} )
-- If-None-Match passes a list of ETags and expects either the resource filtered by those tags or a Not Modified header
-- Expires header may be used for fallback caches
-- 


local cache = {}
return function(req, res, go)
	-- Check if cache contains data for this etag
	local req_etag = req.headers.ETag
	if cache[req_etag] then
		-- TODO Check validator for changes
		res.code = 304 -- Not Modified
		res.headers = clone(cache[req_etag].headers)
		return
	end
	
	-- Run the middleware that generates site
	go()
	-- 200 OK and 204 No Content are cacheable responses
	if res.code ~= 200 and
		res.code ~= 204 then 
		return
	end
	local res_etag = res.headers.ETag
	if not res_etag then
		-- Generate new etag
		res_etag = shasum(res.body)
		res.headers.ETag = res_etag
		p(res_etag)
	else
		p("Request generated an ETag for us")
		p(res_etag)
	end

	cache[res_etag] = {
		headers = clone(res.headers),
		content = res.body
	}
end
