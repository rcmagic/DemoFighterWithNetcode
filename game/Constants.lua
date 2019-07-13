-- Constants
SCREEN_WIDTH = 1024
SCREEN_HEIGHT = 768
STAGE_WIDTH = 1000					-- Stage width in screen coordinates.
STAGE_RADIUS = STAGE_WIDTH / 2		-- Half of the stage width
GROUND_HEIGHT = 200					-- Stage ground height in screen coordinates.
DEFAULT_HP  = 10000					-- Default Max HP of players.      

-- Global Variables
SHOW_HITBOXES  = false				-- Debugg settings for displaying hitboxes
SHOW_DEBUG_INFO = false				-- Prints debug information on screen when enabled.
SKIP_MATCH_INTRO = true				-- Set to skip the match intro. Must be the same value on both clients or a desync will occur.


-- Network Settings
SERVER_IP = "localhost"				-- The network address of the other player to connect to.
SERVER_PORT = 12345					-- The network port the server is running on.
NET_INPUT_DELAY	= 3					-- Amount of input delay to use by default during online matches. Should always be > 0