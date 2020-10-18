local fs = require("fs")
local log = require('pretty-print')
log.loadColors(16)

return function(app, config)
	-- If we're disabled, do nothing
	if config.tls.enabled ~= nil and not config.tls.enabled then
		log.print("TLS\t\t\t\27[31mDisabled\27[0m")
		log.print("Https redirect\t\t\27[31mDisabled\27[0m")
		return
	end
	if config.tls.certificate ~= nil and config.tls.key ~= nil then
		assert(fs.statSync(config.tls.certificate))
		assert(fs.statSync(config.tls.key))
		app.bind({
			host =  "127.0.0.1",
			port =  443,
			tls = {
				cert = module:load("../"..config.tls.certificate),
				key = module:load("../"..config.tls.key)
			}
		})
		log.print("TLS\t\t\t\27[32mEnabled\27[0m")
		if config.tls.httpRedirect then
			app.use(require('weblit-force-https'))
			log.print("Https redirect\t\t\27[32mEnabled\27[0m")
		else
			log.print("Https redirect\t\t\27[31mDisabled\27[0m")
		end
	else
		log.print("Missing TLS certificate and key -> disabling tls")
		log.print("TLS\t\t\t\27[31mDisabled\27[0m")
		config.tls.enabled = false
	end

end