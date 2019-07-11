-- Makes a shallow copy of a table. Deep copies of child tables will not be duplicate.
function table.copy(t)
	if t == nil then return nil end	
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
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

-- Base table for all tables that are inheritable.
Object = {}

-- Boiler plate for making object inheritance and instancing possible
function Object:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

PlayerState = {}

-- Base table for player states.
PlayerState = Object:New()

-- Called when transitioning into this state.
function PlayerState:Begin(player)
end

-- Called every frame.
function PlayerState:Update(player)
end

-- Called when transitioning out of this state.
function PlayerState:End(player)
end

