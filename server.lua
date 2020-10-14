local weblit = require('weblit')
local static = require('weblit-static')
local pathJoin = require('luvi').path.join
local json = require('json')
local fs = require('fs')
local log = require('pretty-print')
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

	-- https
	.bind({
		host = "127.0.0.1",
		port = 443,
		tls = {
			cert = module:load("faze_dev.crt"),
    		key = module:load("faze-key.pem")
		}
	})

	-- Configure weblit server
	.use(weblit.logger)
	.use(weblit.autoHeaders)

if config.redirectHttps then
	app.use(require('weblit-force-https'))
	log.print("Https redirect\t\t\27[32mEnabled\27[0m")
else
	log.print("Https redirect\t\t\27[31mDisabled\27[0m")
end


app.route({
		method = "GET",
		path = "/profile/:username"
	}, function(req, res, go)
		res.code = 200
		res.body = "<h2>Profile for "..req.params.username..".</h2>"
		res.headers["Content-Type"] = "text/html"
	end)

	.route({
		method = "GET",
		path = "/mypath/index"
	}, function(req, res, go)
		res.code = 200
		res.body = "<h1>Hello sailor from route-table!</h1>"
		res.headers["Content-Type"] = "text/html"
	end)

if config.staticFiles then
	-- For debugging purposes, use fallback static page parser
	app.use(static(pathJoin(module.dir, config.staticRoot or "static")))
	print("Serve static files\t\27[32mEnabled\27[0m")
else
	print("Serve static files\t\27[31mDisabled\27[0m")
end

-- Start the server
app.start()