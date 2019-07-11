require("InputSystem")
require("World")
require("PlayerObject")		-- Player object handling.
require("RunOverride")		-- Includes an overrided love.run function for handling fixed time step.
require("MatchSystem")

	
-- Enabled when the game is paused
local paused = false

-- Enabled when game needs to update for a single frame.
local frameStep = false 

-- Manages the game state
local Game = {}

-- Resets the game.
function Game:Reset()
	MatchSystem:Reset()
end


-- Top level update for the game state.
function Game:Update()
	
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

	-- When the world state is paused, don't update any of the players
	if not World.stop then
		-- Run the preupdate
		Game.players[1]:PreUpdate()
		Game.players[2]:PreUpdate()

		for playerIndex1, attacker in pairs(Game.players) do
			-- Handle collisions.
			if not attacker.attackHit and attacker:IsAttacking() then
				for playerIndex2, defender in pairs(Game.players) do
					if playerIndex1 ~= playerIndex2 and defender:CheckIfHit(attacker) then

					
						local attackProperties = attacker:GetAttackProperties()

						-- When there are no attack properties, the collision will be ignored.
						if attackProperties then
								
							-- These events are only valid until the end of the frame.
							defender.events.AttackedThisFrame = true
							attacker.events.HitEnemyThisFrame = true
							attacker.events.hitstop = attackProperties.hitStop
							attacker.attackHit = true

							-- Apply the hit properties. I'll probably make an event and delay until the Update() call later.
							defender:ApplyHitProperties(attackProperties)
						end
					end
				end
			end
		end

		-- Update the player objects.
		Game.players[1]:Update()
		Game.players[2]:Update()
	end

	MatchSystem:Update()
end


local lifeBarXOffset = 56		-- Position from the side of the screen of the life bars.
local lifeBarYOffset = 40		-- Position from the top of the screen of the life bars.

local lifeBarWidth = 386		-- Lifebar width.
local lifeBarHeight = 22		-- Lifebar height.

local lifeBarColor = {0, 193 / 255, 0}		-- Color indicating the current amount of HP.
local lifeBarBGColor = {0.3, 0.3, 0.3}	-- Color behind the lifebar when HP is depleated. 

function DrawLifeBar(hpRate)
	love.graphics.setColor(lifeBarBGColor)
	love.graphics.rectangle('fill', 0, 0, lifeBarWidth, lifeBarHeight)

	love.graphics.setColor(lifeBarColor)
	love.graphics.rectangle('fill', 0, 0, lifeBarWidth*hpRate, lifeBarHeight)
end

-- Draw lifebars and other information that will be displayed to the player.
function DrawHUD()
	
	-- Draw player 1's life bar.
	love.graphics.push()
	love.graphics.translate(lifeBarXOffset, lifeBarYOffset)
	DrawLifeBar(Game.players[1].hp / Game.players[1].hpMax)
	love.graphics.pop()


	-- Draw player 2's life bar.
	love.graphics.push()
	love.graphics.translate(SCREEN_WIDTH-lifeBarXOffset, lifeBarYOffset)
	love.graphics.scale(-1, 1)
	DrawLifeBar(Game.players[2].hp / Game.players[2].hpMax)
	love.graphics.pop()
	
end

-- Top level drawing function
function Game:Draw()
	-- Draw the ground.
	love.graphics.rectangle('fill', 0, 768 - GROUND_HEIGHT, 1024, GROUND_HEIGHT)

	love.graphics.push()
	
	-- Move draw everything in world coordinates
	love.graphics.translate(1024 / 2, 768 - GROUND_HEIGHT)

	-- Create drawing priority list.
	local drawList = {Game.players[1], Game.players[2]}
	
	-- Comparison function
	local comparePlayers = function(a, b)
		if a.currentState.attack then
			return false
		end
		return true
	end

	-- Sort based on priority
	table.sort(drawList, comparePlayers)

	-- Draw players from the sorted list
	for index, player in pairs(drawList) do
		player:Draw()
	end

	love.graphics.pop()

	DrawHUD()

	MatchSystem:Draw()

	-- Draw debug information ontop of everything else.
	-- love.graphics.setColor(1,1,1)
	-- love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)

	-- love.graphics.print("Hitstun: (".. Game.players[1].hitstunTimer .. ", " .. Game.players[2].hitstunTimer .. ")", 10, 20)
	-- love.graphics.print("Hitstop: (".. Game.players[1].hitstopTimer .. ", " .. Game.players[2].hitstopTimer .. ")", 10, 30)

	-- love.graphics.print("Position: (".. Game.players[1].physics.x .. ", " .. Game.players[2].physics.x .. ")", 10, 40)

	
	-- Stage ground color
	love.graphics.setColor(1,1,1)
end

function love.load()

	InputSystem.joysticks = love.joystick.getJoysticks()
	for index, stick in pairs(InputSystem.joysticks) do
		print("Found Gamepad: " .. stick:getName())
	end

	Game.players = { MakePlayerObject(), MakePlayerObject() }
 
	-- Load all images needed for the player character animations
	Game.players[1].imageSequences = LoadPlayerImageSequences(1)
	Game.players[2].imageSequences = LoadPlayerImageSequences(2)

	love.keyboard.setKeyRepeat( false)

	-- Initialize player input command buffers
	InputSystem:InitializeBuffer(1)
	InputSystem:InitializeBuffer(2)

	-- Initialize refence to command buffers for each player
	Game.players[1].input = InputSystem
	Game.players[1].playerIndex = 1

	Game.players[2].input = InputSystem
	Game.players[2].playerIndex = 2


	-- Initialize the match system
	MatchSystem.world = World
	MatchSystem.players = Game.players
	MatchSystem.game = Game

	Game:Reset()
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
	
	if key == 'f4' then
		SHOW_HITBOXES = not SHOW_HITBOXES
	elseif key == 'f3' then
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
	Game:Update()
end

function love.draw()
	Game:Draw()
end
