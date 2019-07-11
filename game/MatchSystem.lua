MatchSystem = 
{
    currentState = {},          -- Current match state.
    timer = 0,                  -- Total time the current state has been running (in frames)
    players = {},               -- player list
}

function MatchSystem:Begin()
    self.currentState = Match.Start:New()
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


-- Base table for match states.
MatchState = {}


-- Boiler plate for making inheritance and instancing possible
function MatchState:New(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end


-- Called when transitioning into this state.
function MatchState:Begin(match)
end

-- Called every frame.
function MatchState:Update(match)
end

-- Called when transitioning out of this state.
function MatchState:End(match)
end

-- Handles drawing for the state
function MatchState:Draw(match)
end

Match = {}

-- Initial state for the match
Match.Start = MatchState:New()

function Match.Start:Update(match)
    if match.timer > 60 * 3 then
        return Match.Go
    end
end

function Match.Start:Draw(match)
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Match Start", 10, 80, 0, 4, 4, -85, -50)
    love.graphics.pop()
end

-- Handles the Go! Message at that appears before the match begins.
Match.Go = MatchState:New()

function Match.Go:Update(match)
    if match.timer > 60 * 1 then
        return Match.Run
    end
end

function Match.Go:Draw(match)
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Go!", 10, 80, 0, 4, 4, -110, -50)
    love.graphics.pop()
end

-- Running state for the match
Match.Run = MatchState:New()

function Match.Run:Begin(match)
    match.players[1].inputEnabled = true
    match.players[2].inputEnabled = true
end
function Match.Run:Update(match)
    match.players[1].inputEnabled = true
    -- Check match end condition
    if match.players[1].hp <= 0 or match.players[2].hp <= 0 then
        return Match.End
    end
end


-- Runs when atleast one player runs out of HP
Match.End = MatchState:New()

function Match.End:Begin(match)
    -- Disable world updates
    match.world.stop = true
    
    -- Disable player input at the end of a match
    match.players[1].inputEnabled = false
    match.players[2].inputEnabled = false
end

function Match.End:Update(match)
    if match.timer > 60 * 2 then
        return Match.EndWait
    end
end

function Match.End:End(match)
    -- Enable world updates
    match.world.stop = false
end

function Match.End:Draw(match)
    love.graphics.push()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("KO!", 10, 80, 0, 4, 4, -110, -50)
    love.graphics.pop()
end

-- Final state for the match
Match.EndWait = MatchState:New()





