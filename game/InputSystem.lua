-- The input system is an abstraction layer between system input and commands used to control player objects.
InputSystem = 
{
	MAX_INPUT_FRAMES = 60,			-- The maximum number of input commands stored in the player controller ring buff.

	localPlayerIndex 	= 1,		-- The player index for the player on the local client.
	remotePlayerIndex 	= 2,		-- The player index for the player on the remote client.

	keyboardState = {}, 			-- System keyboard state. This is updated in love callbacks love.keypressed and love.keyreleased.

	remotePlayerState = {},			-- Store the input state for the remote player.

	playerCommandBuffer = {{}, {}},	-- A ring buffer. Stores the on/off state for each basic input command.
	inputBufferIndex = 0,			-- The current index used to update and read player input commands. Starting at 0

	inputDelay = 0,					-- Specify how many frames the player's inputs will be delayed by. Used in networking. Increase this value to test delay!

	joysticks = {},					-- Available joysticks 
}

-- Get the entire input state for the current from a player's input command buffer.
function InputSystem:GetInputState(bufferIndex)
	return self.playerCommandBuffer[bufferIndex][self.inputBufferIndex]
end

-- Initialize the player input command ring buffer.
function InputSystem:InitializeBuffer(bufferIndex)
	for i=1,InputSystem.MAX_INPUT_FRAMES do
		self.playerCommandBuffer[bufferIndex][i] = { up = false, down = false, left = false, right = false, attack = false}
	end
end

-- Record inputs the player pressed this frame.
function InputSystem:UpdateInputChanges()
	local previousIndex = self.inputBufferIndex - 1
	if previousIndex < 1 then
		previousIndex = InputSystem.MAX_INPUT_FRAMES
	end

	for i=1,2 do
		local state = self.playerCommandBuffer[i][self.inputBufferIndex]
		local previousState = self.playerCommandBuffer[i][previousIndex]

		state.up_pressed = state.up and not previousState.up
		state.down_pressed = state.down and not previousState.down
		state.left_pressed = state.left and not previousState.left
		state.right_pressed = state.right and not previousState.right
		state.attack_pressed = state.attack and not previousState.attack
	end
end

-- The update method syncs the keyboard and joystick input with the internal player input state. It also handles syncing the remote player's inputs.
function InputSystem:Update()

	-- Update the input ring buffer index.
	self.inputBufferIndex = self.inputBufferIndex + 1
	if self.inputBufferIndex > InputSystem.MAX_INPUT_FRAMES then
		self.inputBufferIndex = 1 
	end

	-- Setup the index used to handle input delay
	local delayedIndex = self.inputBufferIndex + self.inputDelay
	-- Wrap around the index to the front of the buffer.
	if delayedIndex > InputSystem.MAX_INPUT_FRAMES then
		delayedIndex = delayedIndex - InputSystem.MAX_INPUT_FRAMES + 1
	end

	-- Update the local player's command buffer for the current frame.
	self.playerCommandBuffer[self.localPlayerIndex][delayedIndex] = table.copy(self.keyboardState)

	-- Update the remote player's command buffer.
	self.playerCommandBuffer[self.remotePlayerIndex][delayedIndex] = table.copy(self.remotePlayerState)

	-- Get buttons from first joysticks
	for index, joystick in pairs(self.joysticks) do
		if self.joysticks[1] then



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
		paused = not paused
	elseif key == 'f2' then
		frameStep = true
	elseif key == 'f1' then
		SHOW_DEBUG_INFO = not SHOW_DEBUG_INFO

	-- Test controls for storing/restoring state.
	elseif key == 'f7' then
		Game:StoreState()
	elseif key == 'f8' then
		Game:RestoreState()
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