local function slice(buffer, starti, endi)
	local slice = {}
	local slicei = 1
	endi = math.min(endi, #buffer)
	for i = starti, endi, 1 do
		slice[slicei] = buffer[i]
		slicei = slicei + 1
	end
	return slice
end
return {
	slice = slice
}