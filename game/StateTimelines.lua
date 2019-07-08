-- Image sequence description. 
-- source:  Image name without the extension. 
-- x:       X coordinate alignment offset.
-- y:       Y coordinate alignment offset.
ImageSequences =
{
    stand = {{source = "idle_00", x = -32, y = -152}},
    attack = 
    {
        {source = "attack_00", x = -108, y = -131},
        {source = "attack_01", x = -103, y = -146},
        {source = "attack_02", x = -32, y = -63},
    }
}

-- Stores timing associated data used in player states. Animation and collision boxes are described here.
Timelines =
{
    stand = 
    {
        duration = 5,

        images = 
        {
            { sequence = "stand", index = 1, duration = 5 }
        },

        damageBoxes = 
        {
            {start = 0, last = 5, x = -40, y = 80, r = 40, b = 0}
        },
        attackBoxes = {}
    
    },

    attack = 
    {
        duration = 26,

        images = 
        {
            { sequence = "attack", index = 1, duration = 8 },
            { sequence = "attack", index = 2, duration = 3 },
            { sequence = "attack", index = 3, duration = 15 },
        },

        damageBoxes = 
        {
            {start = 0, last = 26, x = -40, y = 80, r = 40, b = 0}
        },

        attackBoxes = 
        {
            {start = 8, last = 11, x = 32, y = 80, r = 120, b = -20}
        },
    
    }
}
