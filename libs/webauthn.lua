
local json = require 'json'
local sha = require 'sha2'

local function generateChallenge()
	local chars = "1234567890qwertzuiopasdfghjklyxcvbnm"
	local output = ""
	for i=1, 32, 1 do
		local charnum = math.random(string.len(chars))
		output = output .. string.sub(chars, charnum, charnum+1)
	end
	return output
end

local function generateKeyOptions()

	return {
		challenge = generateChallenge(),
		rp = {
			name = "myservice", -- probably should add field to config
			id = "faze.dev" -- same with this value
		},
		user = {
			id = "",
			name = "",
			displayName = ""
		},
		pubKeyCredParams = {
			[1] = { type = "public-key", alg = -7 },
			[2] = { type = "public-key", alg = -35 },
			[3] = { type = "public-key", alg = -36 },
			[4] = { type = "public-key", alg = -257 },
			[5] = { type = "public-key", alg = -258 },
			[6] = { type = "public-key", alg = -259 },
			[7] = { type = "public-key", alg = -37 },
			[8] = { type = "public-key", alg = -38 },
			[9] = { type = "public-key", alg = -39 },
			[10] = { type = "public-key", alg = -8 },
		},
		authenticatorSelection = {
			--Select authenticators that support username-less flows
            requireResidentKey = false,
            --This attribute decides if the client asks the user again if he really wants to sign up.
            userVerification = "discouraged"
		},
		timeout = 60000,
		--Specifies if the relying party (e.g. our server) wishes to know which Authenticator performed the authentication of the user. You can find all details here: https://w3c.github.io/webauthn/#attestation-conveyance
        attestation = "indirect"
	}
end

cache = {}

local function registerKey(keycred, userId)

	local clientData = json.parse(keycred.clientDataJSON)

	if clientData.type ~= "webauthn.create" then
		return { status = 403, text = "Invalid operation specified" }
	end

	if cache[clientData.challenge] == true then
		return { status = 403, text = "The challenge of this request has been used" }
	end

	if cache[clientData.challenge] == nil then
		return { status = 403, text = "This challenge has not been issued" }
	end

	cache[clientData.challenge] = true

	-- Check origin, this needs to be dynamic
	if clientData.origin ~= "faze.dev" then
		return { status = 403, text = "Invalid origin" }
	end

	if clientData.tokenBinding then
		-- TLS check
	end

	local clientDataHash = sha.sha256(keycred.clientDataJSON)
	

	return {
		status = 403,
		text = "hehe"
	}
end

return {
	generatePublicKeyCredentialRequestOptions = generateKeyOptions,
	registerKey = registerKey
}