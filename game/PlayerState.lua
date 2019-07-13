require("Util")
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

