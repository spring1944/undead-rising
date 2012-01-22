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
	key    = '2gamemode',
	name   = 'Game Mode Settings',
	desc   = 'Game pacing and duration',
	type   = 'section',
  },
	
  {
      key="starttime",
      name="Start Time",
      desc="When the capturing of points can begin in Victory Point mode. (key = 'starttime')",
      type="list",
	  section	= '2gamemode',
      def="2",
      items = {
         { key = "0", name = "0", desc = "0 minutes", },
         { key = "2", name = "2", desc = "2 minutes", },
         { key = "3", name = "3", desc = "3 minutes", },
         { key = "5", name = "5", desc = "5 minutes", },
         { key = "10", name = "10", desc = "10 minutes", },
      },
   },
   {
      key="limitscore",
      name="Score Limit",
      desc="The Winning Amount for Victory Point Mode",
      type="list",
	  section	= '2gamemode',
      def="500",
      items = {
         { key = "200", name = "200", desc = "Very Short", },
         { key = "500", name = "500", desc = "Short", },
         { key = "1000", name = "1000", desc = "Average", },
         { key = "2000", name = "2000", desc = "Long", },
         { key = "3000", name = "3000", desc = "Insane!", },
      },
   },
   
	{
	key    = '4other',
	name   = 'Other Settings',
	desc   = 'Various other settings',
	type   = 'section',
    },
	
	{
		key = "initial_cash",
		name = "Start of round cash",
		desc = "Determines how much Command players receive at the start of a game period (key = 'initial_cash')",
		type   = "number",
		def    = 50000,
		min    = 5000,
		max    = 100000,
		section= '4other',
		step   = 5000,
	},
	{
		key = "objective_phase_length",
		name = "Objective Phase Length",
		desc = "Length of the objective phase of the game in minutes (key = 'objective_phase_length')",
		type   = "number",
		def    = 10,
		min    = 2,
		max    = 20,
		section= '4other',
		step   = 1,
	},
	{
		key = "logistics_reserve",
		name = "Logistics reserve",
		desc = "Determines how much Logistics players have to work with in each game (key = 'logistics_reserve')",
		type   = "number",
		def    = 5000,
		min    = 1000,
		max    = 20000,
		section= '4other',
		step   = 500,
	},
	
	{
		key = "shop_mode",
		name = "Enable unit purchasing mode",
		desc = "Disables normal gameplay and allows players to spend money to add to their army (key = 'shop_mode')",
		type = "bool",
		section = '4other',
		def = false,
	},
	{
		key = "civilian_goal",
		name = "Civilian Rescue Goal",
		desc = "Determines how much Logistics players have to work with in each game (key = 'civilian_goal')",
		type   = "number",
		def    = 50,
		min    = 15,
		max    = 100,
		section= '4other',
		step   = 5,
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
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
}
return options
