
local json = require 'json'
local sha = require 'sha2'
local base64 = require 'base64'
local CBOR = require 'CBOR'
local bit = require 'bit'
local util = require 'fazeit-web-util'
local rshift, lshift, bor, band = bit.rshift, bit.lshift, bit.bor, bit.band

cache = {}
storage = {}

local function generateChallenge()
	local chars = "1234567890qwertzuiopasdfghjklyxcvbnm"
	local output = ""
	for i=1, 32, 1 do
		local charnum = math.random(string.len(chars))
		output = output .. string.sub(chars, charnum, charnum+1)
	end
	cache[output] = false
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

local function parseAuthData(buffer)
	local authData = {}

	-- 0 - 32
	authData.rpIdHash = util.slice(buffer, 1, 33)
	authData.flags = buffer[33]

	--print("Size of buffer: "..#buffer)
	--print(type(buffer))

	--(authData[33] << 24) | (authData[34] << 16) | (authData[35] << 8) | (authData[36]);
	authData.signCount = bor( lshift(buffer[34], 24), bor( lshift(buffer[35], 16), bor( lshift(buffer[36], 8), buffer[37] ) ) )

	-- Check if the client sent attestedCredentialdata, which is necessary for every new public key scheduled. 
	-- This is indicated by the 6th bit of the flag byte being 1 (See specification at function start for reference)
    if band(authData.flags, 64) then
		local attestedCredentialData = {}
		attestedCredentialData.aaguid = util.slice(buffer, 38, 54) -- uuid.parse.toupper ???
		attestedCredentialData.credentialIdLength = bor( lshift(buffer[54], 8), buffer[55] )
		attestedCredentialData.credentialId = util.slice(buffer, 56, 56 + attestedCredentialData.credentialIdLength)

		-- js lib converts this to JWK
		local cose = util.slice(buffer, 56 + attestedCredentialData.credentialIdLength, #buffer)
		local strcose = ""
		for _,v in pairs(cose) do strcose = strcose .. string.char(v) end
		local pkcbor = CBOR.decode(strcose)
		local jwk = {}
		if pkcbor[3] == -7 then -- index 3 but 4 in lua
			jwk = {
				kty = "EC",
				crv = "P-256",
				x = base64.encode(pkcbor[-2]),
				y = base64.encode(pkcbor[-3])
			}
		elseif pkcbor[3] == -257 then
			jwk = {
				kty = "RSA",
				n = base64.encode(pkcbor[-1]),
				e = base64.encode(pkcbor[-2])
			}
		end
		-- end of jwk
		
		attestedCredentialData.credentialPublicKey = jwk 

		authData.attestedCredentialData = attestedCredentialData
	end

	if band(authData.flags, 128) then
		-- todo extensions
	end
	
	return authData
end

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
	if string.find(clientData.origin, "faze.dev") == nil then
		return { status = 403, text = "Invalid origin" }
	end

	if clientData.tokenBinding then
		-- TLS check
	end

	local clientDataHash = sha.sha256(keycred.clientDataJSON)
	local attestationtext = base64.decode(keycred.attestationObject)

	local attestation = CBOR.decode(attestationtext)
	local tmp = {}
	for i=1, #attestation.authData do
		table.insert(tmp, string.byte(string.sub(attestation.authData, i, i)))
	end
	attestation.authData = tmp
	local authenticatorData = parseAuthData(attestation.authData)


	if not band(authenticatorData.flags, 1) then
		return {
			status = 403,
			text = "The request failed the user presence test"
		}
	end
	if not band(authenticatorData.flags, 4) then
		return {
			status = 403,
			text = "The request indicates that the user didn't verify before sending the request"
		}
	end

	if storage[userId] ~= nil then
		return {
			status = 401,
			text = "User with this userId already exists!"
		}
	end

	local user = {
		id = keycred.id,
		credentialPublicKey = authenticatorData.attestedCredentialData.credentialPublicKey,
		signCount = authenticatorData.signCount
	}

	storage[userId] = user

	return {
		status = 200,
		text = "Successfully registered!"
	}
end

return {
	generatePublicKeyCredentialRequestOptions = generateKeyOptions,
	registerKey = registerKey
}