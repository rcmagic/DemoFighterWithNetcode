-- Makes a shallow copy of a table. Deep copies of child tables will not be duplicate.
function table.copy(t)
	if t == nil then return nil end	
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

function table.array_copy(t)
	if not t then return nil end
	local t2 = {}
	for i,v in ipairs(t) do
		if type(v) == "table" then
			t2[i] = table.deep_copy(v)
		else
			t2[k] = v
		end
	end
	return t2
end

-- Recursively makes a deep copy of a table. Assumes there are no cycles.
function table.deep_copy(t)
	if not t then return nil end
	local t2 = {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			t2[k] = table.deep_copy(v)
		else
			t2[k] = v
		end
	end
	return t2
end

-- Print the table
function table.print(t)
	if not t then
		print("Table is nil")
		return nil
	end
	for k,v in pairs(t) do
		print(k .. " : ", v)
	end
end
