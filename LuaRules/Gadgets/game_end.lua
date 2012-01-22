function gadget:GetInfo()
	return {
		name = "Game OVER!",
		desc = "Ends the game under appropriate conditions",
		author = "Nemo (shares a name but no code with the version in S44Main.sdd)",
		date = "22 January 2012",
		license = "GNU GPL v2",
		layer = 1,
		enabled = true
	}
end

-- synced only
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

--synced ctrl
local KillTeam			=	Spring.KillTeam
local GameOver			=	Spring.GameOver
--synced read
local GetGameFrame		=	Spring.GetGameFrame
local GetTeamUnits		=	Spring.GetTeamUnits
local GetTeamList		=	Spring.GetTeamList
local GetTeamInfo		=	Spring.GetTeamInfo
local GetGameRulesParam	=	Spring.GetGameRulesParam

local SendMessage		=	Spring.SendMessage

--constants
local params 					= VFS.Include("LuaRules/header/sharedParams.lua")
local OBJECTIVE_PHASE_LENGTH	= params.OBJECTIVE_PHASE_LENGTH
local REINFORCEMENT_DELAY		= params.REINFORCEMENT_DELAY

local GAIA_TEAM_ID				= Spring.GetGaiaTeamID()

local retreatColor		= "\255\001\050\255"	--blue ish --
local humanDeathColor	= "\255\255\125\001"	--YELLOW-orange --
local zombieDeathColor	= "\255\051\001\102"	--purple 

local retreatedTeams = {}
local zombieKilledTeams = {}

local teamUnitCounts = {}
local aliveTeams = {}

local retreatMessages = {
	[1] = "%s retreated from the battlefield!",
	[2] = "The last of %s's forces have withdrawn.",
	[3] = "%s strategically repositioned.",
}

local humanDeathMessages = {
	[1] = "%s was obliterated.",
	[2] = "%s has been neutralized.",
	[3] = "%s poses no further threat to mission objectives.",
}

local zombieDeathMessages = {
	[1] = "%s let the brainjuice spill out the headhole!",
	[2] = "%s, it's what's for dinner!",
	[3] = "OM NOM NOM %s",
	[4] = "%s says: 'braaaaains!'",
}

function gadget:TeamDied(deadTeamID)
	--Spring.Echo("team died!", deadTeamID)
	if deadTeamID ~= GAIA_TEAM_ID then
		local playerName = GG.teamIDToPlayerName[deadTeamID]
		local playerData = GG.activeAccounts[playerName]
		playerData.teamID = "inactive"	
		aliveTeams[deadTeamID] = nil
		--need to adapt this to handle team games in the future
		local aliveCount = 0
		for teamID, isAlive in pairs(aliveTeams) do
			aliveCount = aliveCount + 1	
		end
		--Spring.Echo("alive teams: ", aliveCount)
		--Spring.Echo("number of surviving teams minus gaia!", #livingTeams-1)
		if aliveCount-1 == 1 then
			local winningTeamID = 0
			for teamID, isAlive in pairs(aliveTeams) do
				if teamID ~= GAIA_TEAM_ID then
					winningTeamID = teamID
				end
			end
			local gameFrame = GetGameFrame()
			local objWinTeamID = GetGameRulesParam("obj_win_team")
			--Spring.Echo("WINNING TEAM!", winningTeamID, GG.teamIDToPlayerName[winningTeamID])
			--Spring.Echo("objective winning team!", objWinTeamID, GG.teamIDToPlayerName[objWinTeamID])
			--re-enable the player's teamID so that moneyHandler can properly record their prize
			local winningName = GG.teamIDToPlayerName[winningTeamID]
			if winningTeamID == objWinTeamID then
				SendMessage("\255\255\001\001 "..winningName.."achieved their objective and secured the area!")
				GG.Reward(winningTeamID, "wongame")
			end
			
			if gameFrame < OBJECTIVE_PHASE_LENGTH and winningTeamID == GG.zombieTeamID then
				SendMessage("\255\255\001\001"..winningName.." drove away the humans!")
				GG.Reward(winningTeamID, "humansgone")
			end
			
			if winningTeamID ~= objWinTeamID and gameFrame > OBJECTIVE_PHASE_LENGTH then
				SendMessage("\255\255\001\001EPIC WIN FOR "..winningName.."!")
				GG.Reward(winningTeamID, "epicwin")
			end
			
			if gameFrame < OBJECTIVE_PHASE_LENGTH and winningTeamID ~= GG.zombieTeamID then
				Spring.Echo("ERROR! Humans can't win before objective round is over!")
			end
			
			--teamID, leader, isDead, isAiTeam, side, allyTeam
			local _, _, _, _, _, winningAllyTeam = GetTeamInfo(winningTeamID)
			GG.Delay.DelayCall(GameOver, {{winningAllyTeam}}, 120)
			--gadgetHandler:RemoveGadget()
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID, attackerDefID, attackerTeamID)
	teamUnitCounts[teamID] = teamUnitCounts[teamID] - 1
	--Spring.Echo("team", teamID, "has", teamUnitCounts[teamID], "units!")
	if teamID ~= GAIA_TEAM_ID then
		--Spring.Echo("unit died, team units remaining:", #teamUnits-1)
		if teamUnitCounts[teamID] <= 0 then 
			local removeTeam = true
			local gameFrame = GetGameFrame()
			local playerName = GG.teamIDToPlayerName[teamID]
			local pd = GG.activeAccounts[playerName] --player data
			local OPL = OBJECTIVE_PHASE_LENGTH
			local OPLRD = OBJECTIVE_PHASE_LENGTH + REINFORCEMENT_DELAY
			if (teamID == GG.zombieTeamID and gameFrame < OPL) or (pd.objVictor and gameFrame < OPLRD + 5) then
				removeTeam = false
			end
			if removeTeam == true then

				local messageNum = 1
				
				if attackerID == nil then --retreated
					messageNum = math.random(1, #retreatMessages)
					SendMessage("\n\n"..retreatColor.." "..string.format(retreatMessages[messageNum], playerName))		
				elseif attackerTeamID == GG.zombieTeamID then --eaten by zombies!
					messageNum = math.random(1, #zombieDeathMessages)
					SendMessage("\n\n"..zombieDeathColor.." "..string.format(zombieDeathMessages[messageNum], playerName))
				else -- killed by a human player
					messageNum = math.random(1, #humanDeathMessages)
					SendMessage("\n\n"..humanDeathColor.." "..string.format(humanDeathMessages[messageNum], playerName))
				end
				KillTeam(teamID)
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	teamUnitCounts[teamID] = teamUnitCounts[teamID] + 1
	--Spring.Echo("unit created! team", teamID, "has", teamUnitCounts[teamID], "units!")
end

function gadget:Initialize()
	local teams = GetTeamList()
	for i=1, #teams do
		local teamID = teams[i]
		teamUnitCounts[teamID] = 0
		aliveTeams[teamID] = true
	end
end