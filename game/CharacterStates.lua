require("PlayerState")

-- Default gravity acceleration
local GRAVITY = -2

-- Default table of states
CharacterStates = {}

CharacterStates.Standing = PlayerState:New()

function CharacterStates.Standing:Begin(player)
    player:PlayTimeline("stand")
end

function CharacterStates.Standing:Update(player)

    if player:GetInputState().attack_pressed then
        return CharacterStates.Attack
    elseif player:GetInputState().up then
        return CharacterStates.Jump
    elseif player:GetInputState().right then 
        player.physics.xVel = 3
    elseif player:GetInputState().left then
        player.physics.xVel = -3
    else
        player.physics.xVel = 0
    end
end

function CharacterStates.Standing:End(player)
end

CharacterStates.Walk = PlayerState:New()

CharacterStates.Backup = PlayerState:New()

-- Neutral Jump
CharacterStates.Jump = PlayerState:New()

function CharacterStates.Jump:Begin(player)
    player:PlayTimeline("stand")

    -- Returing to this state while in the air doesn't not add any vertical velocity.
    if player.physics.y <= 0 then
        player.physics.yVel = 30;
    end

    player.physics.yAcc = GRAVITY
end

function CharacterStates.Jump:Update(player)
    if player.events.GroundCollision then
        player.physics.yVel = 0
        player.physics.yAcc = 0
        return CharacterStates.Standing
    elseif player:GetInputState().attack then
        return CharacterStates.Attack
    end
end

function CharacterStates.Jump:End(player)
end



CharacterStates.JumpBack = PlayerState:New()

CharacterStates.JumpForward = PlayerState:New()


-- Ground damage reaction
CharacterStates.GroundDamage = PlayerState:New()
function CharacterStates.GroundDamage:Update(player)

    -- When hitstun is over the player can return to controlling the character.
    if player.hitstunTimer < 0 then
        return CharacterStates.Standing
    end
end



CharacterStates.Attack = PlayerState:New()
CharacterStates.Attack.attack = true        -- Indicates this state is an attack


function CharacterStates.Attack:Begin(player)
    player:PlayTimeline("attack")
end

function CharacterStates.Attack:Update(player)
    if player.currentFrame == 8 then
        player.attackCanHit = true
    else
        player.attackCanHit = false
    end

    if player.events.AnimEnd then
        return CharacterStates.Standing 
    end
end

CharacterStates.JumpAttack = PlayerState:New()

function CharacterStates.JumpAttack:Begin(player)
    player:PlayTimeline("attack")
end

function CharacterStates.JumpAttack:Update(player)
    if player.events.AnimEnd then
        if player.physics.y > 0 then
            return CharacterStates.Jump
        else
            return CharacterStates.Standing
        end
    end
end