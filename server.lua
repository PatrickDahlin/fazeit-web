local weblit = require('weblit')
local static = require('weblit-static')
local pathJoin = require('luvi').path.join


weblit.app
	-- Bind http port
	.bind({
		host = "127.0.0.1", 
		port = 8080
	})

	-- Configure weblit server
	.use(weblit.logger)
	.use(weblit.autoHeaders)

	.use(require('fazeit-web-cache'))

	.use(static(pathJoin(module.dir, "static")))

	.route("/home", function(req, res, go)
		res.code = 200
		res.body = "<h1>Hello sailor!</h1>"
		res.headers["Content-Type"] = "text/html"
		return
	end)

	-- This is how you can define your own middleware
	--[[
	.use(function (req, res, go)
		-- Log the request table
		p("request", req)
		-- Hand off to the next layer.
		return go()
	end)
	--]]

	-- Start the server
	.start()