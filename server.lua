local weblit = require('weblit')
local static = require('weblit-static')
local pathJoin = require('luvi').path.join
local json = require('json')
local fs = require('fs')

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
	print("Https redirect\t\tEnabled")
else
	print("Https redirect\t\tDisabled")
end

	-- This cache does not work for dynamic sites..... for get it exists
	--.use(require('fazeit-web-cache'))
	-- We're missing Last-Modified here so might need to reimplement static page loading

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

	-- For debugging purposes, use fallback static page parser
	.use(static(pathJoin(module.dir, "static")))

	-- Start the server
	.start()