--  Custom Options Definition Table format

--  NOTES:
--  - using an enumerated table lets you specify the options order

--
--  These keywords must be lowercase for LuaParser to read them.
--
--  key:      the string used in the script.txt
--  name:     the displayed name
--  desc:     the description (could be used as a tooltip)
--  type:     the option type
--  def:      the default value;
--  min:      minimum value for number options
--  max:      maximum value for number options
--  step:     quantization step, aligned to the def value
--  maxlen:   the maximum string length for string options
--  items:    array of item strings for list options
--  scope:    "all", "player", "team", "allyteam"      <<< not supported yet >>>


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local options = {
  {
	key    = '3resources',
	name   = 'Resource Settings',
	desc   = 'Sets various options related to the in-game resources, Command and Logistics',
	type   = 'section',
  },

    {
    key    = "logistics_period",
    name   = "Logistics Resupply Frequency",
    desc   = "Sets the gap between Logistics Resupply (key = 'logistics_period')",
    type   = "list",
	section= '3resources',
    def    = "450",
    items  =
    {
      {
        key  = "675",
        name = "Low - 11.25 minute gap",
        desc = "Limited logistics supply. Conservative play - storage buildings and well supplied infantry are the order of the day.",
      },
      {
        key  = "450",
        name = "Normal - 7.5 minute gap",
        desc = "Normal logistics supply. Supplies come on a frequent enough basis to keep the warmachine rumbling, but beware of large artillery batteries or armored thrusts.",
      },
      {
        key  = "225",
        name = "High - 3.75 minute gap",
        desc = "Abundant logistics supply. Supply deliveries arrive early and often, allowing for much more aggressive play.",
      },
	 },
    },
  

   {
    key    = "command_storage",
    name   = "Fixed Command Storage",
    desc   = "Fixes the command storage of all players. (key = 'command_storage')",
    type   = "number",
    def    = 10000,
    min    = 1000,
    max    = 50000,
	section= '3resources',
    step   = 1000,
  },
  
  {
	key    = '1balance',
	name   = 'Balance Settings. REMOVE BEFORE RELEASE',
	desc   = "Sets experimental balance options.",
	type   = 'section',
  },
  
  	{
		key = "civilian_income",
		name = "Command Income per tick per civilian protected",
		desc = "Changes the amount you recieve for protecting civilians (key = 'civilian_income')",
	    type   = "number",
		def    = 3,
		min    = 0,
		max    = 5,
		section= '1balance',
		step   = 0.25,
	},
	
	
	{
		key = "zombie_count",
		name = "how many zombies spawn in at once?",
		desc = "how many zombies spawn in at once?? (key = 'zombie_count')",
	    type   = "number",
		def    = 5,
		min    = 0,
		max    = 64,
		section= '1balance',
		step   = 1,
	},
	
	{
		key = "civilian_count",
		name = "how many civs spawn in at once?",
		desc = "how many civs spawn in at once? (key = 'civilian_count')",
	    type   = "number",
		def    = 15,
		min    = 0,
		max    = 64,
		section= '1balance',
		step   = 1,
	},
	
	{
		key = "respawn_period",
		name = "How often do things spawn in?",
		desc = "How often do things spawn in (in minutes)? (key = 'respawn_period')",
	    type   = "number",
		def    = 1,
		min    = 1,
		max    = 5,
		section= '1balance',
		step   = 1,
	},

	{
	key    = '4other',
	name   = 'Other Settings',
	desc   = 'Various other settings',
	type   = 'section',
  },
	
	{
		key = "gm_team_enable",
		name = "Enable Sandbox/GM tools faction",
		desc = "Allows the sandbox/game master tools faction to spawn, rather than changing to a random team (key = 'gm_team_enable')",
		type = "bool",
		section = '4other',
		def = false,
	},

	{
    key    = "weapon_range_mult",
    name   = "Range multiplier",
    desc   = 'Multiplies the range of all weapons, adjusting accuracy and weapon velocity as well. 1 is default, 8 is "realistic".',
    type   = "number",
    def    = 1.0,
    min	   = 0.1,
    max    = 8.0,
	section = '4other',
    step   = 0.1,
	},

	{
    key    = "weapon_bulletdamage_mult",
    name   = "Bullet Damage Multiplier",
    desc   = 'Multiplies the damage of smallarms (high smallarms damage best used with high range multipliers)',
    type   = "number",
    def    = 1.0,
    min	   = 0.1,
    max    = 10.0,
	section = '4other',
    step   = 0.1,
	},
	
	 {
    key    = "unit_los_mult",
    name   = "Unit sight (los/airLoS) multiplier",
    desc   = "Applies a multiplier to all the LoS ranges ingame",
    type   = "number",
    def    = 1.0,
    min	   = 0.1,
    max    = 10,
	section = '4other',
    step   = 0.1,
  },
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  C.R.A.I.G. specific option(s)
--
  {
	key    = '5ai',
	name   = 'A.I. Settings',
	desc   = "Sets C.R.A.I.G's options",
	type   = 'section',
  },
	{
		key    = "craig_difficulty",
		name   = "C.R.A.I.G. difficulty level",
		desc   = "Sets the difficulty level of the C.R.A.I.G. bot. (key = 'craig_difficulty')",
		type   = "list",
		section = "5ai",
		def    = "2",
		items = {
			{
				key = "1",
				name = "Easy",
				desc = "No resource cheating."
			},
			{
				key = "2",
				name = "Medium",
				desc = "Little bit of resource cheating."
			},
			{
				key = "3",
				name = "Hard",
				desc = "Infinite resources."
			},
		}
	},
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
}
return options
