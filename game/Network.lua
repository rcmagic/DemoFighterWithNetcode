require("Constants")
require("Util")
local socket = require("socket")

-- Network code indicating the type of message.
local MsgCode =
{
	Handshake = 1,		-- Used when sending the hand shake.
	PlayerInput = 2,	-- Sends part of the player's input buffer.
}

-- Bit flags used to convert input state to a form suitable for network transmission. 
local InputCode =
{
	Up 		= bit.lshift(1, 0),
	Down 	= bit.lshift(1, 1),
	Left 	= bit.lshift(1, 2),
	Right 	= bit.lshift(1, 3),
	Attack 	= bit.lshift(1, 4),
}

-- This object will handle all network related functionality 
Network = 
{ 
	enabled = false,				-- Set to true when the network is running.
	connectedToClient = false,		-- Indicates whether or not the game is connected to another client
	isServer = false,				-- Indicates whether or not this game is the server.

	clientIP = "",					-- Detected network address for the non-server client
	clientPort = -1,				-- Detected port for the non-server client

	confirmedTick = -1,				-- The confirmed tick indicates up to what game frame we have the inputs for.
	inputState = nil,				-- Current input state sent over the network
	inputDelay = NET_INPUT_DELAY,	-- This must be set to a value of 1 more higher.

	inputHistory = {},				-- The input history for the local player. Stored as bit flag encoded input states.	
	remoteInputHistory = {},		-- The input history for the local player. Stored as bit flag encoded input states.

	inputHistoryIndex = 0,			-- Current index in history buffer.
}

-- Initialize History Buffer
function Network:InitializeInputHistoryBuffer()
	for i=1,NET_INPUT_HISTORY_SIZE do
		self.inputHistory[i] = 0
		self.remoteInputHistory[i] = 0
	end
end

-- Probably will move this call to some initialization function.
Network:InitializeInputHistoryBuffer()

-- Setup a network connection at connect to the server.
function Network:StartConnection()
	print("Starting Network")

	-- the address and port of the server
	local address, port = SERVER_IP, SERVER_PORT	
	self.clientIP = address
	self.clientPort = port
	
	self.enabled = true
	self.isServer = false

	self.udp = socket.udp()

	-- Since there isn't a seperate network thread we need non-blocking sockets.
	self.udp:settimeout(0)

	-- The client can bind to any port since the server will wait on a handshake message and record it later.
	self.udp:setsockname('*', 0)

	-- Start the connection with the server
	self:ConnectToServer()
end

-- Setup a network connection as the server then wait for a client to connect.
function Network:StartServer()

	print("Starting Server")

	self.enabled = true
	self.isServer = true

	self.udp = socket.udp()

	-- Since there isn't a seperate network thread we need non-blocking sockets.
	self.udp:settimeout(0)

	-- Bind to a specific port since the client needs to know where to send its handshake message.
	self.udp:setsockname('*', SERVER_PORT)
 
end

-- Get input from the remote player for the passed in game tick.
function Network:GetRemoteInputState(tick)
	return self:DecodeInput(self.remoteInputHistory[1+(tick % NET_INPUT_HISTORY_SIZE)]) -- First index is 1 not 0.
end

-- Connects to the other player who is hosting as the server.d
function Network:ConnectToServer()
	-- This most be called to connect with the server.
	self:SendPacket(self:MakeHandshakePacket(), 5)
end

-- Send the inputState for the local player to the remote later for the passed in game tick.
function Network:SendInputData(inputState, tick)

	-- Don't send input data when not connect to another player's game client.
	if not (self.enabled and self.connectedToClient) then
		return
	end

	local encodedInput = self:EncodeInput(inputState)

	-- TODO: Set the input history somewhere else so it only occurs once for each game tick.
	self.inputHistory[1+(tick % NET_INPUT_HISTORY_SIZE)] = encodedInput -- 1 base indexing.

	self:SendPacket(self:MakeInputPacket(tick), 5)
end

-- Handles sending packets to the other client. Set duplicates to something > 0 to send more than once.
function Network:SendPacket(packet, duplicates)
	if not duplicates then
		duplicates = 1
	end

	for i=1,duplicates do
		self.udp:sendto(packet, self.clientIP, self.clientPort)
	end
end

-- Handles receiving packets from the other client.
function Network:ReceivePacket(packet)
	local data = nil
	local msg = nil
	local ip_or_msg = nil 
	local port = nil

	data, ip_or_msg, port = self.udp:receivefrom()

	if not data then
		msg = ip_or_msg
	end

	return data, msg, ip_or_msg, port
end

-- Generates a string which is used to pack/unpack the data in a player input packet.
-- This format string is used by the love.data.pack() and love.data.unpack() functions.
local INPUT_FORMAT_STRING = string.format('Bj%.' .. NET_SEND_HISTORY_SIZE .. 's', 'BBBBBBBBBBBBBBBB')

-- Checks the queue for any incoming packets and process them.
function Network:ReceiveData()
	if not self.enabled then
		return
	end

	-- For now we'll process all packets every frame.
	repeat 
		local data,msg,ip,port = self:ReceivePacket()
		
		if data then
			local code = love.data.unpack("B", data, 1)

			-- Handshake code must be received by both game instances before a match can begin.
			if code == MsgCode.Handshake then
				if not self.connectedToClient then
					self.connectedToClient = true

					-- The server needs to remember the address and port in order to send data to the other cilent.
					if true then
						-- Server needs to the other the client address and ip to know where to send data.
						if self.isServer then
							self.clientIP = ip
							self.clientPort = port
						end
						print("Received Handshake. Address: " .. self.clientIP .. ".   Port: " .. self.clientPort)
						-- Send handshake to client.
						self:SendPacket(self:MakeHandshakePacket(), 5)
					end
				end

			elseif code == MsgCode.PlayerInput then
				-- Break apart the packet into its parts.
				local results = { love.data.unpack(INPUT_FORMAT_STRING, data, 1) } -- Final parameter is the start position
				
				local receivedTick = results[2]
				if receivedTick > self.confirmedTick then
					self.confirmedTick = receivedTick

					for offset=0, NET_SEND_HISTORY_SIZE-1 do 
						-- Save the input history sent in the packet.
						local historyIndex = 1 + ( (NET_INPUT_HISTORY_SIZE+receivedTick-offset) % NET_INPUT_HISTORY_SIZE) -- 1 based indexing again.
						self.remoteInputHistory[historyIndex] = results[2+NET_SEND_HISTORY_SIZE-offset] -- 3 is the index of the first input.
					end
				end

				--print("Received Tick: " .. receivedTick .. ",  Input: " .. self.remoteInputHistory[(self.confirmedTick % NET_INPUT_HISTORY_SIZE)+1])
			end
		elseif msg and msg ~= 'timeout' then 
			error("Network error: "..tostring(msg))
		end
	-- When we no longer have data we're done processing packets for this frame.
	until data == nil
end



-- Generate a packet containing information about player input.
function Network:MakeInputPacket(frame)

	local historyIndexStart = (NET_INPUT_HISTORY_SIZE + (frame - NET_SEND_HISTORY_SIZE)) % NET_INPUT_HISTORY_SIZE

	local history = {}
	for i=0, NET_SEND_HISTORY_SIZE-1 do
		history[i+1] = self.inputHistory[(historyIndexStart + i) % NET_INPUT_HISTORY_SIZE + 1] -- +1 here because lua indices start at 1 and not 0.
	end

	local data = love.data.pack("string", INPUT_FORMAT_STRING, MsgCode.PlayerInput, frame, unpack(history))
	return data
end

-- Generate handshake packet for connecting with another client.
function Network:MakeHandshakePacket()
	return love.data.pack("string", "B", MsgCode.Handshake)
end

-- Encodes the player input state into a compact form for network transmission. 
function Network:EncodeInput(state)
	local data = 0

	if state.up then
		data = bit.bor( data, InputCode.Up)
	end

	if state.down then
		data = bit.bor( data, InputCode.Down)
	end

	if state.left then
		data = bit.bor( data, InputCode.Left)
	end

	if state.right then
		data = bit.bor( data, InputCode.Right)
	end

	if state.attack then
		data = bit.bor( data, InputCode.Attack)
	end

	return data
end


-- Decodes the input from a packet generated by EncodeInput().
function Network:DecodeInput(data)
	local state = {}

	state.up 		= bit.band( data, InputCode.Up) > 0
	state.down 		= bit.band( data, InputCode.Down) > 0
	state.left 		= bit.band( data, InputCode.Left) > 0
	state.right 	= bit.band( data, InputCode.Right) > 0
	state.attack 	= bit.band( data, InputCode.Attack) > 0

	return state
end