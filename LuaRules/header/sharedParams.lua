local modOptions = Spring.GetModOptions()
local framesPerSecond = 30
local framesPerMinute = 60*framesPerSecond

--note, any typos in this file will crash pretty much everything.

local params = {	
	--NOTE: all of these times are stored in frames, so for printing stuff out they need to be
	--converted back to seconds/minutes.
	--how long does the objective period (before reinforcement wave) last?
	OBJECTIVE_PHASE_LENGTH		= (tonumber(modOptions.objective_phase_length) or 10)*framesPerMinute,

	--how often do new civilians/zombies spawn in?
	RESPAWN_PERIOD				= (tonumber(modOptions.respawn_period) or 1)*framesPerMinute,
	
	--how much advance warning do players get for civilain spawns?
	CIV_SPAWN_WARNINGTIME		= ((tonumber(modOptions.respawn_period)*60) or 60)*framesPerSecond,
	
	--how many zombies/civilians are spawned each RESPAWN_PERIOD?
	ZOMBIE_COUNT 				= tonumber(modOptions.zombie_count) or 5,
	CIVILIAN_COUNT				= tonumber(modOptions.civilian_count) or 15,
	
	--money settings (shockingly, max_money should be > initial cash, or players will only get max_money)
	INITIAL_CASH				= tonumber(modOptions.initial_cash) or 50000,
	MAX_MONEY					= 100000,
	
	--objective settings
		--# civilians saved
	CIVILIAN_SAVE_GOAL			= tonumber(modOptions.civilian_goal) or 50, 
		--#hot zones destroyed
	HOT_ZONE_GOAL				= tonumber(modOptions.hot_zone_goal) or 8, 
		--#seconds of control
	FLAG_HOLD_GOAL				= tonumber(modOptions.flag_hold_goal) or 480, 	
		--number of flags to control on the map
	FLAG_HOLD_POSITIONS			= tonumber(modOptions.flag_hold_positions) or 3,
	
	--how long does it take the objective winner's reinforcements to arrive?
	REINFORCEMENT_DELAY			= (60)*framesPerSecond, --seconds
	
	--how long does a team that remains on map to contend for epic win have to stay before they're allowed to retreat?
	NO_RETREAT_PERIOD			= (2)*framesPerMinute, --minutes

	--corpse settings 
		--what's the upper limit for infantry corpses spawned from a wrecked veh/tank
		--min possible is 0 atm
	MAX_VEH_CORPSES				= 3, 
		--what's the radius where zombies can raise the dead
	ZOMBIFICATION_RADIUS		= 100,
	
	--prizes! What do players get for accomplishing various tasks
		--lost the objective stage, but defeated the huge wave of reinforcements
	PRIZE_EPIC_WIN				= 30000,
		--won the objective stage and then won the game with the reinforcements
	PRIZE_OBJECTIVE_WIN			= 10000,
		--both human players were killed or retreated before the objective round ended
	PRIZE_HUMANS_GONE			= 3000,
		--for completing various mini-goals (saved civvie, purged a hot zone, killed a zombie)
	PRIZE_CIVILIAN_SAVE			= 200,
	PRIZE_FLAG_CONTROL			= 170,
	PRIZE_HOT_ZONE_PURGE		= 2000,
	PRIZE_ZOMBIE_KILL			= 100,
	
	FLAG_CONTROL_REWARD_INTERVAL = 10, --every X seconds of flag control a team will get the above reward
		--zombie income settings
	PRIZE_HUMAN_KILL			= 0, --zombies get a 'bounty' added to this value for killing human units
	ZOM_BOUNTY_MULT				= 1, --which is unit metal cost * this mult
	
	--initialize values
		--these are the names that are allowed to save/send account info
	TRUSTED_NAMES				= {"[S44]Nemo", "[S44]Autohost", "[RD]Godde"},
		--a player's logistics at the start of a game
	LOGISTICS_RESERVE			= tonumber(modOptions.logistics_reserve) or 5000,
	
	--civilian behavior settings
		--how far around them civilians are aware of things happening 
		--(like civilians dying, zombies approaching, etc).
	CIV_AWARE_RADIUS			= 450,
		--how long civvies run from zombies before reevaluating
	CIV_FEAR_DURATION			= 5,
		--how long civvies run from a team that shot at them
	CIV_TEAM_FEAR_DURATION		= 15,
	
	--for house placer - probably don't need to touch unless something seems borked
	HOUSE_FEATURE_CHECK_RADIUS	= 300,
		--how far away from the center spot coordinates houses can be spawned
	HOUSE_SPOT_RADIUS			= 150,
		--the minimum distance any house cluster will be from a team start point.
	SPAWN_BUFFER				= 800,
	
}

return params
