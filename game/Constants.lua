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
NET_ROLLBACK_MAX_FRAMES	= 8			-- The maximum number of frames we allow the game run forward without a confirmed frame from the opponent.
NET_DETECT_DESYNCS = true			-- Whether or not desyncs are detected and terminates a network session.

NET_INPUT_HISTORY_SIZE = 60			-- The size of the input history buffer. Must be atleast 1.
NET_SEND_HISTORY_SIZE = 5			-- The number of inputs we send from the input history buffer. Must be atleast 1.
NET_SEND_DELAY_FRAMES = 5			-- Delay sending packets when this value is great than 0. Set on both clients to not have one ended latency.

-- Rollback test settings
ROLLBACK_TEST_ENABLED   = false
ROLLBACK_TEST_FRAMES    = 10		-- Number of frames to rollback for tests.