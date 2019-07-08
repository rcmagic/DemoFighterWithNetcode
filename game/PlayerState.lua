
function table.copy(t)
	if t == nil then return nil end	
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

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

Object = {}
-- Boiler late for making it object inheritance and instancing possible
function Object:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

PlayerState = {}


PlayerState = Object:New()

-- Called when the transitioning into this state.
function PlayerState:Begin(player)
end

-- Called every frame.
function PlayerState:Update(player)
end

-- Called when the transitioning out of this state.
function PlayerState:End(player)
end

