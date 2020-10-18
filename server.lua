local weblit = require('weblit')
local static = require('weblit-static')
local pathJoin = require('luvi').path.join
local json = require('json')
local fs = require('fs')
local log = require('pretty-print')

local a = require("fazeit-web-static")

log.loadColors(16)
--[[
	ANSI color escape codes

	31 - red
	32 - green
	94 - bright blue
	30 - black
	93 - yellow
	97 - white
	
]]

local file = fs.readFileSync("config.json")
local config = json.parse(file, 1, nil)


local app = weblit.app
	-- Bind http port
	.bind({
		host = "127.0.0.1", 
		port = 80
	})
	
if config.tls ~= nil then
	require("fazeit-web-https")(app, config)
end

app.use(function(req, res, go)
	print("--- RESPONSE BEGIN --- ")
	print((req.path or req.params.path) .. " - " .. req.method)
	go()
end)


-- Custom static file provider
if config.staticFiles then
	app.use(a("static"))
end


if config.staticFiles then
	-- For debugging purposes, use fallback static page parser
	app.use(static(pathJoin(module.dir, config.staticRoot or "static")))
	print("Serve static files\t\27[32mEnabled\27[0m")
else
	print("Serve static files\t\27[31mDisabled\27[0m")
end


-- Start the server
app.start()