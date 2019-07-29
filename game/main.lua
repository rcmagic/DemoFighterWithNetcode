require("InputSystem")		-- Manages player inputs.
require("World")			-- World object
require("PlayerObject")		-- Player object handling.
require("RunOverride")		-- Includes an overrided love.run function for handling fixed time step.
require("MatchSystem")		-- Manages match state
require("Network")			-- Handles networking
	


-- Manages the game state
local Game = 
{
	-- Enabled when the game is paused
	paused = false,

	-- Enabled when game needs to update for a single frame.
	frameStep = false,

	-- Number of ticks since the start of the game.
	tick = 0

	
}

-- Resets the game.
function Game:Reset()
	Game.tick = 0
	MatchSystem:Reset()
end

-- Stores the state of all rollbackable objects and systems in the game.
function Game:StoreState()
	self.storedState = {}

	-- All rollbackable objects and systems will have a CopyState() method.
	self.storedState.world = World:CopyState()
	self.storedState.inputSystem = InputSystem:CopyState()
	self.storedState.matchSystem = MatchSystem:CopyState()
	self.storedState.players = {self.players[1]:CopyState(), self.players[2]:CopyState()}

	self.storedState.tick  = self.tick
end

-- Restores the state of all rollbackable objects and systems in the game.
function Game:RestoreState()
	-- Can't restore the state if has not been saved yet.
	if not self.storedState then 
		return
	end

	-- All rollbackable objects and systems will have a SetState() method.
	World:SetState(self.storedState.world)
	InputSystem:SetState(self.storedState.inputSystem)
	MatchSystem:SetState(self.storedState.matchSystem)
	self.players[1]:SetState(self.storedState.players[1])
	self.players[2]:SetState(self.storedState.players[2])

	self.tick = self.storedState.tick
end


-- Top level update for the game state.
function Game:Update()

	-- Pause and frame step control
	if Game.paused then
		if Game.frameStep then
			Game.frameStep = false
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

		-- Transition to hit reaction and handle other damaged state.
		Game.players[1]:HandleHitReaction()
		Game.players[2]:HandleHitReaction()

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


	if SHOW_DEBUG_INFO then
		--- Draw debug information ontop of everything else.
		love.graphics.setColor(1,1,1)
		love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)

		love.graphics.print("Hitstun: (".. Game.players[1].hitstunTimer .. ", " .. Game.players[2].hitstunTimer .. ")", 10, 20)
		love.graphics.print("Hitstop: (".. Game.players[1].hitstopTimer .. ", " .. Game.players[2].hitstopTimer .. ")", 10, 30)
		love.graphics.print("P1.x: ".. Game.players[1].physics.x .. ", P2.x" .. Game.players[2].physics.x, 10, 40)
		if World.stop == true then
			love.graphics.print("World Stop", 10, 40)
		end

		love.graphics.print("Tick: " .. Game.tick, 10, 50)

	end

	-- Shown while the server is running but not connected to a client.
	if Network.isServer and not Network.connectedToClient then
		love.graphics.setColor(1,0,0)
		love.graphics.print("Network: Waiting on client to connect", 10, 40)
	end
	
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

	-- Load sounds
	for index, player in pairs(Game.players) do
		player.jumpSound = love.audio.newSource("assets/sounds/jump.wav", "static")
		player.hitSound = love.audio.newSource("assets/sounds/hit.wav", "static")
		player.whiffSound = love.audio.newSource("assets/sounds/whiff.wav", "static")
	end

	love.keyboard.setKeyRepeat(false)

	InputSystem.game = Game
	
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

	Game.network = Network

	Game:Reset()

	-- Store game state before the first update
	Game:StoreState()
end	

-- Gets the sync data to confirm the client game states are in sync
function Game:GetSyncData()
	-- For now we will just compare the x coordinates of the both players
	return love.data.pack("string", "nn", self.players[1].physics.x, self.players[2].physics.x)
end

-- Checks whether or not a game state desync has occurred between the local and remote clients.
function Game:SyncCheck()

	if not NET_DETECT_DESYNCS then 
		return
	end

	if Network.lastSyncedTick < 0 then
		return
	end

	-- Check desyncs at a fixed rate.
	if (Network.lastSyncedTick % Network.desyncCheckRate) ~= 0 then
		return
	end

	-- Generate the data we'll send to the other player for testing that their game state is in sync.
	Network:SetLocalSyncData(Network.lastSyncedTick, Game:GetSyncData())
			
	-- Send sync data everytime we've applied from the remote player to a game frame.
	Network:SendSyncData()
	

	local desynced, desyncFrame = Network:DesyncCheck()
	if not desynced then
		return 
	end


	-- Detect when the sync data doesn't match then halt the game
	NetLog("Desync detected at tick: " .. desyncFrame)

	love.window.showMessageBox( "Alert", "Desync detected", "info", true )
	-- the log afterward is pretty useless so exiting here. It also helps to know when a desync occurred. 
	love.event.quit(0)
end

-- Rollback if needed.
function HandleRollbacks()
	local lastGameTick = Game.tick - 1
	-- The input needed to resync state is available so rollback.
	-- Network.lastSyncedTick keeps track of the lastest synced game tick.
	-- When the tick count for the inputs we have is more than the number of synced ticks it's possible to rerun those game updates
	-- with a rollback.
	if lastGameTick >= 0 and lastGameTick > (Network.lastSyncedTick + 1) and Network.confirmedTick > Network.lastSyncedTick then
	
		-- Must revert back to the last known synced game frame.
		Game:RestoreState()

		-- The number of frames that's elasped since the game has been out of sync.
		-- Rerun rollbackFrames number of updates. 
		local rollbackFrames = lastGameTick - Network.lastSyncedTick
		
		for i=1,rollbackFrames do
			-- Get input from the input history buffer. The network system will predict input after the last confirmed tick (for the remote player).
			InputSystem:SetInputState(InputSystem.localPlayerIndex, Network:GetLocalInputState(Game.tick)) -- Offset of 1 ensure it's used for the next game update.
			InputSystem:SetInputState(InputSystem.remotePlayerIndex, Network:GetRemoteInputState(Game.tick)) 

			local lastRolledBackGameTick = Game.tick
			Game:Update()
			Game.tick = Game.tick + 1

			-- Confirm that we are indeed still synced
			if lastRolledBackGameTick <= Network.confirmedTick then
				-- Store the state since we know it's synced. We really only need to call this on the last synced frame. 
				-- Leaving in for demonstration purposes.
				Game:StoreState()
				Network.lastSyncedTick = lastRolledBackGameTick
				
				-- Confirm the game clients are in sync
				Game:SyncCheck()
			end
		end			
	end
			
end

-- Handles testing rollbacks offline.
function TestRollbacks()
	if ROLLBACK_TEST_ENABLED then
		if Game.tick >= ROLLBACK_TEST_FRAMES then

			-- Get sync data that we'll test after the rollback 
			local syncData = love.data.pack("string", "nn", Game.players[1].physics.y, Game.players[2].physics.y)

			Game:RestoreState()
			
			-- Prevent polling for input since we set it directly from the input history.
			for i=1,ROLLBACK_TEST_FRAMES do
				-- Get input from a input history buffer that we update below
				InputSystem:SetInputState(InputSystem.localPlayerIndex, Network:GetLocalInputState(Game.tick))
				InputSystem:SetInputState(InputSystem.remotePlayerIndex, Network:GetRemoteInputState(Game.tick))
				

				Game.tick = Game.tick + 1
				Game:Update()

				-- Store only the first updated state
				if i == 1 then
					Game:StoreState()
				end
			end

			-- Get the sync data after a rollback and check to see if it matches the data before the rollback.
			local postSyncData = love.data.pack("string", "nn", Game.players[1].physics.y, Game.players[2].physics.y)

			if syncData ~= postSyncData then
				love.window.showMessageBox( "Alert", "Rollback Desync Detected", "info", true )
				love.event.quit(0)
			end
		end
	end
end
-- Used for testing performance. 
local lastTime = love.timer.getTime()
function love.update(dt) 

	local lastGameTick = Game.tick

	local updateGame = false

	if ROLLBACK_TEST_ENABLED then
		updateGame = true
	end

	-- The network is update first
	if Network.enabled then
		local x = love.timer.getTime()

		-- Setup the local input delay to match the network input delay. 
		-- If this isn't done, the two game clients will be out of sync with each other as the local player's input will be applied on the current frame,
		-- while the opponent's will be applied to a frame inputDelay frames in the input buffer.
		InputSystem.inputDelay = Network.inputDelay
		
		-- First get any data that has been sent from the other client
		Network:ReceiveData()

		-- Send any packets that have been queued
		Network:ProcessDelayedPackets()

		if Network.connectedToClient then

			-- Run any rollbacks that can be processed before the next game update
			HandleRollbacks()
			
			-- Calculate the difference between remote game tick and the local. This will be used for syncing.
			-- We don't use the latest local tick, but the tick for the latest input sent to the remote client.
			Network.localTickDelta = (lastGameTick+Network.inputDelay) - Network.confirmedTick


			-- Prevent updating the game when the tick difference is greater on this end.
			-- This allows the game deltas to be off by atleast on frame. Our timing is only accurate to one frame so any slight increase in network latency
			-- would cause the game to constantly hold. You could increase this tolerance, but this would increase the advantage for one player over the other.
			local hold = (Network.localTickDelta - Network.remoteTickDelta) > 1 
			
			-- Hold until the tick deltas match.
			if hold then
				-- print("Hold. Tick Delta = [ Local: " .. Network.localTickDelta .. ", Remote: " .. Network.remoteTickDelta .. "]")
				updateGame = false
			else
				-- We allow the game to run for NET_ROLLBACK_MAX_FRAMES updates without having input for the current frame.
				-- Once the game can no longer update, it will wait until the other player's client can catch up.
				if (Network.confirmedTick + NET_ROLLBACK_MAX_FRAMES) >= lastGameTick then
					updateGame = true
				else
					updateGame = false
				end
			end
		end

	end

	if updateGame then	
		-- Test rollbacks
		TestRollbacks()

		-- Poll inputs for this frame. In network mode the network manager will handle updating player command buffers.
		local updateCommandBuffers = not Network.enabled
		InputSystem:PollInputs(updateCommandBuffers)

		-- Network manager will handle updating inputs.
		if Network.enabled then
			-- Update local input history
			local sendInput = InputSystem:GetLatestInput(InputSystem.localPlayerIndex)
			Network:SetLocalInput(sendInput, lastGameTick+Network.inputDelay)

			-- Set the input state fo[r the current tick for the remote player's character.
			InputSystem:SetInputState(InputSystem.localPlayerIndex, Network:GetLocalInputState(lastGameTick))
			InputSystem:SetInputState(InputSystem.remotePlayerIndex, Network:GetRemoteInputState(lastGameTick))

		end

		-- Increment the tick count only when the game actually updates.
		Game:Update()
		
		Game.tick = Game.tick + 1

		-- Save stage after an update if testing rollbacks
		if ROLLBACK_TEST_ENABLED then
			-- Save local input history for this game tick
			Network:SetLocalInput(InputSystem:GetLatestInput(InputSystem.localPlayerIndex), lastGameTick)
		end
	

		if Network.enabled then
			-- Check whether or not the game state is confirmed to be in sync.
			-- Since we previously rolled back, it's safe to set the lastSyncedTick here since we know any previous frames will be synced.
			if  (Network.lastSyncedTick + 1) == lastGameTick and lastGameTick <= Network.confirmedTick then

				-- Increment the synced tick number if we have inputs
				Network.lastSyncedTick = lastGameTick	
				
				-- Applied the remote player's input, so this game frame should synced.
				Game:StoreState()

				-- Confirm the game clients are in sync
				Game:SyncCheck()
 
			end
							
		end
	end


	-- Since our input is update in Game:Update() we want to send the input as soon as possible. 
	-- Previously this as happening before the Game:Update() and adding uneeded latency.  
	if Network.enabled and Network.connectedToClient  then

		-- if updateGame then
		-- 	PacketLog("Sending Input: " .. Network:GetLocalInputEncoded(lastGameTick + Network.inputDelay) .. ' @ ' .. lastGameTick + Network.inputDelay  )
		-- end

		-- Send this player's input state. We when Network.inputDelay frames ahead.
		-- Note: This input comes from the last game update, so we subtract 1 to set the correct tick.
		Network:SendInputData(Game.tick - 1 + Network.inputDelay)


		-- Send ping so we can test network latency.
		Network:SendPingMessage()
		
	end
end

function love.draw()
	Game:Draw()
end
