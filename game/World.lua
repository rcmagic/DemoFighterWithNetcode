-- The world stores manages state that effect all in game objects.
World = 
{
    stop = false,  -- Pauses the entire world when true
}

-- Used in the rollback system to make a copy of the world state
function World:CopyState()
    local state = {}
    state.stop = World.stop
    return state
end

-- Used in the rollback system to restore the old state of the world
function World:SetState(state)
    World.stop = state.stop
end