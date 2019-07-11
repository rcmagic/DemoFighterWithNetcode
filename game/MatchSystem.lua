require("MatchStates")
MatchSystem = 
{
	currentState = MatchState:New(),	-- Current match state.
	timer = 0,							-- Total time the current state has been running (in frames)
	players = {},						-- player list
}

function MatchSystem:Reset()

	self.players[1]:Reset()
	self.players[2]:Reset()
	
	self.timer = 0
	self:Begin()
end

function MatchSystem:Begin()
	self.currentState = Match.Start:New()
	self.currentState:Begin(self)
end

function MatchSystem:Update()
	-- Update the current state and then execute the relevant callbacks when transition occurs. 
	local nextState = self.currentState:Update(self)
	if nextState then
		self.timer = -1
		self.currentState:End(self)
		self.currentState = nextState:New()
		self.currentState:Begin(self)
	end
	
	self.timer = self.timer + 1
end

function MatchSystem:Draw()
	self.currentState:Draw(self)
end
