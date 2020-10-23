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
	res.headers["Connection"] = "close"
	print("--- RESPONSE BEGIN --- ")
	print((req.path or req.params.path) .. " - " .. req.method)
	go()
end)

app.use(require 'fazeit-web-cookies')


local auth = require 'webauthn'

app.route({
	method = "GET",
	path = "/authentication/creationOptions"
},function(req, res, go)
	res.code = 200
	res.headers["Content-Type"] = "text/json"
	-- generate public key credentialoptions
	res.body = json.stringify( auth.generatePublicKeyCredentialRequestOptions() )
	return
end)

app.route({
	method = "GET",
	path = "/authentication/requestOptions"
},function(req, res, go)
	res.code = 200
	res.headers["Content-Type"] = "text/json"
	-- generate public key credential requestoptions
	res.body = json.stringify({ hello = "sailor" })
	return
end)


app.route({
	method = "POST",
	path = "/authentication/register"
}, function(req, res, go)

	local reg = auth.registerKey(json.parse(req.body,1,nil).pkc, req.cookies.userId)
	res.code = reg.status
	res.body = reg.text

	return
end)




-- Custom static file provider
if config.staticFiles then
	app.use(a("static", config.enableXHTML or false))
end


if config.staticFiles then
	-- For debugging purposes, use fallback static page parser
	--app.use(static(pathJoin(module.dir, config.staticRoot or "static")))
	print("Serve static files\t\27[32mEnabled\27[0m")
else
	print("Serve static files\t\27[31mDisabled\27[0m")
end




-- Start the server
app.start()