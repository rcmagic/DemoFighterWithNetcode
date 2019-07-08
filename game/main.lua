
require("PlayerObject")		-- Player object handling.
require("RunOverride")		-- Includes an overrided love.run function for handling fixed time step.


	
-- Enabled when the game is paused
local paused = false

-- Enabled when game needs to update for a single frame.
local frameStep = false 


-- The input system is an abstraction layer between system input and commands used to control player objects.
local InputSystem = 
{
	MAX_INPUT_FRAMES = 60,			-- The maximum number of input commands stored in the player controller ring buff.

	localPlayerIndex 	= 1,		-- The player index for the player on the local client.
	remotePlayerIndex 	= 2,		-- The player index for the player on the remote client.

	keyboardState = {}, 			-- System keyboard state. This is updated in love callbacks love.keypressed and love.keyreleased.

	remotePlayerState = {},			-- Store the input state for the remote player.

	playerCommandBuffer = {{}, {}},	-- A ring buffer. Stores the on/off state for each basic input command.
	inputBufferIndex = 1			-- The current index used to update and read player input commands.
}

-- The update method syncs the keyboard and joystick input with the internal player input state. It also handles syncing the remote player's inputs.
function InputSystem:Update()

	-- Update the local player's command buffer for the current frame.
	self.playerCommandBuffer[self.localPlayerIndex][self.inputBufferIndex] = table.copy(self.keyboardState)

	-- Update the remote player's command buffer.
	self.playerCommandBuffer[self.remotePlayerIndex][self.inputBufferIndex] = table.copy(self.remotePlayerState)
end



-- Array of our player objects.
local PlayerObjectList = { MakePlayerObject(), MakePlayerObject() }

local data = {}
function love.load()
    --     -- This is the height and the width of the platform.
	-- platform.width = love.graphics.getWidth()    -- This makes the platform as wide as the whole game window.
	-- platform.height = love.graphics.getHeight()  -- This makes the platform as tall as the whole game window.
 
    --     -- This is the coordinates where the platform will be rendered.
	-- platform.x = 0                               -- This starts drawing the platform at the left edge of the game window.
	-- platform.y = platform.height / 2             -- This starts drawing the platform at the very middle of the game window
	
	-- -- This is the coordinates where the player character will be rendered.
	-- player.x = 1
	-- player.y = 1
 

	-- Load all images needed for the player character animations
	PlayerObjectList[1].imageSequences = LoadPlayerImageSequences(1)
	PlayerObjectList[2].imageSequences = LoadPlayerImageSequences(2)

	love.keyboard.setKeyRepeat( false)

	-- Initialize refence to command buffers for each player
	PlayerObjectList[1].inputCommands = InputSystem.playerCommandBuffer[1]
	PlayerObjectList[1].playerIndex = 1

	PlayerObjectList[2].inputCommands = InputSystem.playerCommandBuffer[2]
	PlayerObjectList[2].playerIndex = 2

	PlayerObjectList[2].facing = true

	-- Initial Player Positions.
	PlayerObjectList[1].physics.x = -200
	PlayerObjectList[1].physics.y = 0

	PlayerObjectList[2].physics.x = 200
	PlayerObjectList[2].physics.y = 0

	-- Entry functions for the players starting a match
	PlayerObjectList[1]:Begin()
	PlayerObjectList[2]:Begin()


end

-- Set the internal keyboard state input to true on pressed.
function love.keypressed(key, scancode, isrepeat)

	if key == 'w'  then
		InputSystem.keyboardState.up = true
	elseif key == 's' then
		InputSystem.keyboardState.down = true
	elseif key == 'a'  then
		InputSystem.keyboardState.left = true
	elseif key == 'd' then
		InputSystem.keyboardState.right = true
	elseif key == 'g' then
		InputSystem.keyboardState.attack = true
	end

	if key == 'f3' then
		paused = not paused
	elseif key == 'f2' then
		frameStep = true
	end
end

-- Set the internal keyboard state input to false on release.
function love.keyreleased(key, scancode, isrepeat)

	if key == 'w'  then
		InputSystem.keyboardState.up = false
	elseif key == 's' then
		InputSystem.keyboardState.down = false
	elseif key == 'a'  then
		InputSystem.keyboardState.left = false
	elseif key == 'd' then
		InputSystem.keyboardState.right = false
	elseif key == 'g' then
		InputSystem.keyboardState.attack = false
	end

end

function love.update(dt)

	if paused then
		if frameStep then
			frameStep = false
		else
			-- Do not update the game when paused.
			return
		end
	end

	-- Update the input system
	InputSystem:Update()

	
	-- Run the preupdate
	PlayerObjectList[1]:PreUpdate()
	PlayerObjectList[2]:PreUpdate()

	-- Handle collisions.
	if not PlayerObjectList[1].attackHit and PlayerObjectList[1]:IsAttacking() then
		local hitstop = 15
		PlayerObjectList[2].events.AttackedThisFrame = true
		PlayerObjectList[2].events.hitstun = 20
		PlayerObjectList[2].events.hitstop = hitstop

		PlayerObjectList[1].events.HitEnemyThisFrame = true
		PlayerObjectList[1].events.hitstop = hitstop
		PlayerObjectList[1].attackHit = true
	end

	-- Update the player objects.
	PlayerObjectList[1]:Update()
	PlayerObjectList[2]:Update()
end


function love.draw()
	love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)

	love.graphics.print("Hitstun: (".. PlayerObjectList[1].hitstunTimer .. ", " .. PlayerObjectList[2].hitstunTimer .. ")", 10, 20)
	love.graphics.print("Hitstop: (".. PlayerObjectList[1].hitstopTimer .. ", " .. PlayerObjectList[2].hitstopTimer .. ")", 10, 30)
	-- Stage ground color
	love.graphics.setColor(1,1,1)

	-- Draw the ground.
	love.graphics.rectangle('fill', 0, 768 - GROUND_HEIGHT, 1024, GROUND_HEIGHT)

	love.graphics.push()
	
	-- Move draw everything in world coordinates
	love.graphics.translate(1024 / 2, 768 - GROUND_HEIGHT)


	PlayerObjectList[1]:Draw()
	PlayerObjectList[2]:Draw()

	love.graphics.pop()

end
