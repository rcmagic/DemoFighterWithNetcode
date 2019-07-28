require("Util")

-- The input system is an abstraction layer between system input and commands used to control player objects.
InputSystem = 
{
	MAX_INPUT_FRAMES = 60,			-- The maximum number of input commands stored in the player controller ring buff.

	localPlayerIndex 	= 1,		-- The player index for the player on the local client.
	remotePlayerIndex 	= 2,		-- The player index for the player on the remote client.

	keyboardState = {}, 			-- System keyboard state. This is updated in love callbacks love.keypressed and love.keyreleased.

	remotePlayerState = {},			-- Store the input state for the remote player.

	playerCommandBuffer = {{}, {}},	-- A ring buffer. Stores the on/off state for each basic input command.

	inputDelay = 0,					-- Specify how many frames the player's inputs will be delayed by. Used in networking. Increase this value to test delay!

	joysticks = {},					-- Available joysticks 

	skipPolling = false,			-- Prevents polling for input during an update. Used to test rollbacks.
}

function InputSystem:InputIndex(offset)
	local tick = self.game.tick
	if offset then
		tick = tick + offset
	end

	return 1 + ((InputSystem.MAX_INPUT_FRAMES + tick) % InputSystem.MAX_INPUT_FRAMES)
end


-- Used in the rollback system to make a copy of the input system state
function InputSystem:CopyState()
	local state = {}
	state.playerCommandBuffer = table.deep_copy(self.playerCommandBuffer)
	return state
end

-- Used in the rollback system to restore the old state of the input system
function InputSystem:SetState(state)
	self.playerCommandBuffer = state.playerCommandBuffer
end


-- Get the entire input state for the current from a player's input command buffer.
function InputSystem:GetInputState(bufferIndex, tick)
	-- The 1 appearing here is because lua arrays used 1 based and not 0 based indexes.
	local inputFrame = 1 + ((InputSystem.MAX_INPUT_FRAMES + tick ) % InputSystem.MAX_INPUT_FRAMES)
	
	local state = self.playerCommandBuffer[bufferIndex][inputFrame]
	if not state then
		return {}
	end
	return state
end

-- Get the current input state for a player
function InputSystem:CurrentInputState(bufferIndex)
	return self:GetInputState(bufferIndex, self.game.tick)
end

-- Directly set the input state or the player. This is used for a online match.
function InputSystem:SetInputState(playerIndex, state)
	local stateCopy = table.copy(state)
	self.playerCommandBuffer[playerIndex][self:InputIndex()] = stateCopy
end

-- Initialize the player input command ring buffer.
function InputSystem:InitializeBuffer(bufferIndex)
	for i=1,InputSystem.MAX_INPUT_FRAMES do
		self.playerCommandBuffer[bufferIndex][i] = { up = false, down = false, left = false, right = false, attack = false}
	end
end

-- Record inputs the player pressed this frame.
function InputSystem:UpdateInputChanges()
	local inputIndex = self:InputIndex()
	local previousInputIndex = self:InputIndex(-1)

	for i=1,2 do
		local state = self.playerCommandBuffer[i][inputIndex]
		local previousState = self.playerCommandBuffer[i][previousInputIndex]

		state.up_pressed = state.up and not previousState.up
		state.down_pressed = state.down and not previousState.down
		state.left_pressed = state.left and not previousState.left
		state.right_pressed = state.right and not previousState.right
		state.attack_pressed = state.attack and not previousState.attack
	end
end

-- The update method syncs the keyboard and joystick input with the internal player input state. It also handles syncing the remote player's inputs.
function InputSystem:Update()

	-- Setup the index used to handle input delay
	local delayedIndex = self:InputIndex(self.inputDelay)


	-- Input polling from the system can be disabled for setting inputs from a buffer. Used in testing rollbacks.
	if not self.skipPolling then
		-- Update the local player's command buffer for the current frame.
		self.playerCommandBuffer[self.localPlayerIndex][delayedIndex] = table.copy(self.keyboardState)

		-- Update the remote player's command buffer.
		--self.playerCommandBuffer[self.remotePlayerIndex][delayedIndex] = table.copy(self.remotePlayerState)

		-- Get buttons from first joysticks
		for index, joystick in pairs(self.joysticks) do
			if self.joysticks[1] and (not self.game.network.enabled or (self.localPlayerIndex == index) ) then

				local commandBuffer = self.playerCommandBuffer[index][delayedIndex]
				local axisX = joystick:getAxis(1)
				local axisY = joystick:getAxis(2)
				
				-- Reset the direction state for this frame.
				commandBuffer.left = false
				commandBuffer.right = false
				commandBuffer.up = false
				commandBuffer.down = false
				commandBuffer.attack = false

				-- Indicates the neutral zone of the joystick
				local axisGap = 0.5

				if axisX > axisGap then
					commandBuffer.right = true
				elseif axisX < -axisGap then 
					commandBuffer.left = true
				end

				if axisY > axisGap then
					commandBuffer.down = true
				elseif axisY < -axisGap then 
					commandBuffer.up = true
				end	

				if joystick:isDown(1) then
					commandBuffer.attack = true
				end

			end
		end
	end

	-- Update input changes
	InputSystem:UpdateInputChanges()
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
	
	if key == 'f5' then
		InputSystem.game:Reset()
	elseif key == 'f4' then
		SHOW_HITBOXES = not SHOW_HITBOXES
	elseif key == 'f3' then
		InputSystem.game.paused = not InputSystem.game.paused
	elseif key == 'f2' then
		InputSystem.game.frameStep = true
	elseif key == 'f1' then
		SHOW_DEBUG_INFO = not SHOW_DEBUG_INFO

	-- Test controls for storing/restoring state.
	elseif key == 'f7' then
		InputSystem.game:StoreState()
	elseif key == 'f8' then
		InputSystem.game:RestoreState()
	elseif key == 'f9' then
		InputSystem.game.network:StartConnection()
		InputSystem.localPlayerIndex = 2	-- Right now the client is always player 2.
		InputSystem.remotePlayerIndex = 1 	-- Right now the server is always players 1.
	elseif key == 'f11' then
		InputSystem.game.network:StartServer()
		InputSystem.localPlayerIndex = 1 	-- Right now the server is always players 1.
		InputSystem.remotePlayerIndex = 2	-- Right now the client is always player 2.
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