require("Constants")
require("CharacterStates")
require("StateTimelines")


-- System for managing the physics of a player.

-- Boiler late for making it object inheritance possible
local PhysicsSystem = Object:New()

-- Once a frame update of the physics system for the player.
function PhysicsSystem:Update(player)
	-- For this example project we are using a fixed frame step update, so simple integration will work just fine.
	self.x = self.x + self.xVel
	self.y = self.y + self.yVel
    self.xVel = self.xVel + self.xAcc

    -- Apply friction on the ground
    if self.y <= 0 then
        self.xVel = self.xVel * 0.8
    end

	self.yVel = self.yVel + self.yAcc

	----------------
	-- Contraints --
	----------------

	-- Never allow the horizontal position of the player to move beyond the stage walls.
	if self.x < -STAGE_RADIUS then
		self.x = -STAGE_RADIUS
	elseif self.x > STAGE_RADIUS then
		self.x = STAGE_RADIUS
	end

	-- Never allow the vertical position of the player fall below the ground.
	if self.yVel < 0 and self.y <= 0 then 
        self.y = 0
        player.events.GroundCollision = true
	end
end

-- Physics system factor
function MakePhysicsSystem()
    -- Have to create a unique table or it will copy the base one.
    return PhysicsSystem:New({
        x = 0,			-- world x coordinate of the player.
        y = 0,			-- world y coordinate of the player.
        xVel = 0,		-- Absolute x velocity of the player.
        yVel = 0,		-- Absolute y velocity of the player.
    
        xAcc = 0,		-- Absolute x acceleration of the player.
        yAcc = 0,		-- Absolute y acceleration of the player.

        facing = false  -- Whether or not the facing direction is flipped.
    })
end

-- Define the player object we'll use to manage the player characters in this game.
PlayerObject = Object:New()



local PlayerColors =
{
	{213 / 255, 94 / 255,  0},
	{86 / 255, 	180 / 255, 233 / 255}
}
-- Draw the player object
function PlayerObject:Draw()
	love.graphics.push()

	love.graphics.translate(self.physics.x, -self.physics.y)
    love.graphics.setColor(1,1,1)

    local xOff = -25
    local yOff = -152
    local xScale = 1

    if self.facing then
        xScale = -1
    end

    love.graphics.scale(xScale, 1)

    -- Draw the image referenced in the current timeline
    if self.currentTimeline then
        local currentImage = self:GetImageFromTimeline(self.currentTimeline, self.currentFrame)
        love.graphics.draw(currentImage.image, currentImage.x, currentImage.y)
    end

    love.graphics.pop()
    
    if SHOW_HITBOXES then
        local damageBoxList = self:GetDamageBoxFromTimeline(self.currentTimeline, self.currentFrame)

        -- Draw damage collision boxes
        for index, box in pairs(damageBoxList) do
            box = TranslateBox(box, self.physics.x, self.physics.y, self.facing)
            love.graphics.setColor(0,0,1, 0.5)
            love.graphics.rectangle('fill', box.x, -box.y, box.r - box.x, box.y - box.b)
        end

        local attackBoxList = self:GetAttackBoxFromTimeline(self.currentTimeline, self.currentFrame)

        -- Draw attack collision boxes
        for index, box in pairs(attackBoxList) do
            box = TranslateBox(box, self.physics.x, self.physics.y, self.facing)
            love.graphics.setColor(1,0,0, 0.5)
            love.graphics.rectangle('fill', box.x, -box.y, box.r - box.x, box.y - box.b)
        end

        love.graphics.setColor(1,1,1)
    end
end


function PlayerObject:Begin()
	self.currentState = CharacterStates.Standing:New()
	self.currentState:Begin(self)
end

-- Handle any changes that must happen before Update() is called.
function PlayerObject:PreUpdate()
        -- Create new event list.
        self.events = {}
end

-- Called once every frame
function PlayerObject:Update()

    -- The player is paused on the frame the their attack collision occurred 
    if self.events.HitEnemyThisFrame then
        self.hitstopTimer = self.events.hitstop
        return;        
    end

    -- While counting down hitstop, don't update the player's state.
    if self.hitstopTimer > 0 then
        self.hitstopTimer = self.hitstopTimer - 1
        return
    end

	-- Updating the physics first so that the state system can respond to it later.
    self.physics:Update(self)
    
    if self.currentTimeline then
        self:UpdateTimeline()
    end

    -- Transitions into a hit reaction if hit by an attack
    if self.events.AttackedThisFrame then
        self.attackCanHit = false
        self.currentState:End(self)
        self.currentState = CharacterStates.GroundDamage:New()
        self.currentState:Begin(self)
        self.hitstunTimer = self.events.hitstun -- Get hitstun that was passed in during the collision from the opponent's attack
        self.hitstopTimer = self.events.hitstop
    else
        if self.hitstunTimer > 0 then
            self.hitstunTimer = self.hitstunTimer - 1
        end
    end

	-- Update the current state and then execute the relevant callbacks when transition occurs. 
	local nextState = self.currentState:Update(self)
    if nextState then
        self.attackHit = false
        self.attackCanHit = false
        self.currentState:End(self)
        self.currentState = nextState:New()
        self.currentState:Begin(self)

	end
end

function PlayerObject:UpdateTimeline()
    -- Update frame count
    if self.currentFrame + 1 >= self.currentTimeline.duration then
        -- Indicate the animation has ended for other systems to use.
        self.events.AnimEnd = true

        -- Loop if this is a looping move.
        if self.currentTimeline.looping then
            self.currentFrame = 0
        end
    else        
        self.currentFrame = self.currentFrame + 1
    end
end

function PlayerObject:PlayTimeline(timeline)
    self.currentTimeline = self.timelines[timeline]
    self.currentFrame = 0
    self.events.AnimEnd = false
end

-- Search for the currently displayed image in a timeline.
function PlayerObject:GetImageFromTimeline(timeline, frame)
    local offset = 0
    local lastImage = nil
    for index, imageDescription in pairs(timeline.images) do
        lastImage = self.imageSequences[imageDescription.sequence][imageDescription.index] 

        if (imageDescription.duration + offset) > frame then
            return lastImage
        end
        offset = offset + imageDescription.duration
    end
    return lastImage
end

function PlayerObject:GetAttackBoxFromTimeline(timeline, frame)
    local boxList = {}
    for index, box in pairs(timeline.attackBoxes) do
        if frame >= box.start and frame < box.last then
            table.insert(boxList, box)
        end
    end
    return boxList
end

function PlayerObject:GetDamageBoxFromTimeline(timeline, frame)
    local boxList = {}
    for index, box in pairs(timeline.damageBoxes) do
        if frame >= box.start and frame < box.last then
            table.insert(boxList, box)
        end
    end
    return boxList
end


-- Check to see if 2 boxes are colliding
function CheckIfBoxesCollide(box1, box2)
    return not (box1.x > box2.r or box2.x > box1.r or box1.y < box2.b or box2.y < box1.b)
end

function TranslateBox(box, x, y, flipped) 
    if flipped then
        return { x = x - box.r, y = box.y + y, r = x - box.x, b = box.b + y}
    end

    return { x = box.x + x, y = box.y + y, r = box.r + x, b = box.b + y}
end
function PlayerObject:IsAttacking()
    if self.currentState and self.currentState.attack and self.attackCanHit then
        return true
    end
end

-- Check if colliding with one of the enemy's attack boxes.
function PlayerObject:CheckIfHit(enemy)
    local attackBoxList = self:GetAttackBoxFromTimeline(enemy.currentTimeline, enemy.currentFrame)
    local damageBoxList = self:GetDamageBoxFromTimeline(self.currentTimeline, self.currentFrame)



    for index, box1 in pairs(attackBoxList) do
        -- Check against all damage boxes
        for index2, box2 in pairs(damageBoxList) do
            if CheckIfBoxesCollide(TranslateBox(box1, enemy.physics.x, enemy.physics.y, enemy.facing), TranslateBox(box2, self.physics.x, self.physics.y, self.facing)) then
                return true
            end
        end
    end
    return false
end

-- Get the current attack properties if they exist.
function PlayerObject:GetAttackProperties()
    if self.currentTimeline then
        return self.currentTimeline.attackProperties
    end
end

-- Apply all the hit properties to the defending player
function PlayerObject:ApplyHitProperties(attackProperties)
    self.events.hitstop = attackProperties.hitStop
    self.events.hitstun = attackProperties.hitStun
    self.hp = self.hp - attackProperties.damage
    if self.hp < 0 then
        self.hp = 0
    end
end

-- Get State State
function PlayerObject:GetInputState()
    return self.input:GetInputState(self.playerIndex)
end


-- Player Object Factory
function MakePlayerObject()
    return PlayerObject:New(
        {
            playerIndex = 1,                                    -- Index that references the player.
            states = CharacterStates,                           -- List of all the player character states
            currentState = CharacterStates.Standing:New(),      -- Current executing state
            physics = MakePhysicsSystem(),                      -- Physics system for the player character
            timelines = Timelines,                              -- List of timelines used by this player character
            currentTimeline = nil,                              -- Currently playing timeline
            currentFrame = 0,                                   -- Current frame in the timeline.

            hitstunTimer = 0,                                   -- Timer used to down down the frames until a damage reaction is over.
            hitstopTimer = 0,                                   -- Timer used while in hitstop 
            
            attackCanHit = false,                               -- Whether or not the attack is currently able to hit
            attackHit = false,                                  -- Whether or not the current attack already hit.

            hpMax = DEFAULT_HP,                                 -- Maximum amount of life the player can have
            hp = DEFAULT_HP,                                    -- Current amount of life the player has.

            events = {},                                        -- Events that get cleared at the start of every frame.
        }  
    )
end

-- Loads images reference in ImageSequences
function LoadPlayerImageSequences(playerIndex)

    local imageSequences = table.deep_copy(ImageSequences)

    -- Load images
    for sequenceName,sequence in pairs(imageSequences) do
        for index, imageDescription in pairs(sequence) do
            imageDescription.image = love.graphics.newImage('assets/player' .. playerIndex .. "/" .. imageDescription.source .. '.png')
        end
    end

    return imageSequences
end


