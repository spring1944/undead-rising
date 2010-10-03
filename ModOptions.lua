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
	--[[{
		key = "simple_tanks",
		name = "Simplified Tank Buildtree",
		desc = "Different german tank buildtree",
		type = "bool",
		def = true,
	},]]--
	--[[{
		key = "always_visible_flags",
		name = "Always Visible Flags",
		desc = "Flags and their capping status can be seen without LOS",
		type = "bool",
		def = true,
	},]]--
	--[[{
    key    = "maxammo_mult",
    name   = "Vehicle maxammmo multiplier",
    desc   = "Applies a multiplier to all the vehicle maxammo values",
    type   = "number",
    def    = 1.0,
    min	   = 0.1,
    max    = 10,
    step   = 0.1,
  },]]--
 

   
  {
	key    = '3resources',
	name   = 'Resource Settings',
	desc   = 'Sets various options related to the in-game resources, Command and Logistics',
	type   = 'section',
  },
  {
    key    = "command_mult",
    name   = "Command Point Income/Battle Significance",
    desc   = "Sets level of Command Point income - use to adjust maps that provide too much or too little command points (key = 'command_mult')",
    type   = "list",
	section= '3resources',
    def    = "2",
    items  =
    {
	  {
        key  = "0",
        name = "Very Low",
        desc = "Very limited resources. Nothing but a minor skirmish, you must make the most of what resources you have.",
      },
      {
        key  = "1",
        name = "Low",
        desc = "Limited Command Points. This battle is insignificant, and you will be struggling to maintain infantry battalions",
      },
      {
        key  = "2",
        name = "Normal",
        desc = "Standard Command Points. The supreme commanders are keeping an eye on the outcome of this engagement. Expect medium numbers of infantry with considerable vehicle support, with armor and gun batteries appearing later.",
      },
      {
        key  = "3",
        name = "High",
        desc = "Abundant Command Points. The command has deemed this battle vital. You must win at all costs, and your available resources reflect that urgency.",
      },
	  {
        key  = "4",
        name = "Very High",
        desc = "Excessive Command Points. High command has an emotional attachment to your skirmish, and they want it won.",
      },
    },
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
    max    = 1944000,
	section= '3resources',
    step   = 1000,
  },
  
  {
    key    = "map_command_per_player",
    name   = "Map Command Per Player",
    desc   = "Sets the total command on the map to some number per player (negative to disable). (key = 'map_command_per_player')",
    type   = "number",
    def    = -10,
    min    = -10,
    max    = 1000,
	section= '3resources',
    step   = 10,
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
		def    = 1,
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
		def    = 5,
		min    = 1,
		max    = 10,
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


  --[[ 

  {
    key    = "weapon_reload_mult",
    name   = "Weapon reload multiplier",
    desc   = "Applies a multiplier to all the weapon reloadtimes ingame",
    type   = "number",
    def    = 1.0,
    min	   = 0.1,
    max    = 10,
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
    step   = 0.1,
  },
  {
    key    = "unit_speed_mult",
    name   = "Unit speed multiplier",
    desc   = "Applies a multiplier to all the unit speeds and acceleration values ingame",
    type   = "number",
    def    = 1.0,
    min	   = 0.1,
    max    = 10,
    step   = 0.1,
  },
    {
    key    = "weapon_aoe_mult",
    name   = "AoE multiplier",
    desc   = "Applies a multiplier to all the weapon AoE values",
    type   = "number",
    def    = 1.0,
    min	   = 0.1,
    max    = 10,
    step   = 0.05,
  },

   {
    key    = "weapon_hedamage_mult",
    name   = "HE damage multiplier",
    desc   = "Applies a multiplier to all the HE damage values",
    type   = "number",
    def    = 1.0,
    min	   = 0.1,
    max    = 10,
    step   = 0.05,
  },
  {
    key    = "weapon_edgeeffectiveness_mult",
    name   = "Weapon edgeeffectiveness multiplier",
    desc   = "Applies a multiplier to all the weapon edgeeffectiveness ingame",
    type   = "number",
    def    = 1.0,
    min	   = 0.01,
    max    = 10,
    step   = 0.1,
  }
  {
    key    = "unit_hq_platoon",
    name   = "HQ-centric infantry game",
    desc   = "Removes rifle/assault squads from barracks, puts them in HQ",
    type   = "number",
    def    = 0,
    min	   = 0,
    max    = 1,
    step   = 1,
  }]]--

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
