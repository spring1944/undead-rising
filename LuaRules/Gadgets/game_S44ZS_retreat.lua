function gadget:GetInfo()
	return {
		name      = "Retreat from map",
		desc      = "Allows players to retreat units off-map. Also handles 'rescuing' civilians",
		author    = "Nemo",
		date      = "Jan 2012",
		license   = "GPL v2",
		layer     = 2,
		enabled   = true
	}
end

--TODO
--assign each allyteam two map edges for retreating
--use those map edges as retreat zones instead of team start positions
--draw something on those areas to indicate that units can retreat from there
local GetTeamStartPosition	=	Spring.GetTeamStartPosition
local RETREAT_ZONE_RADIUS		= 400

if gadgetHandler:IsSyncedCode() then
--	SYNCED
local GetTeamList			=	Spring.GetTeamList
local GetUnitIsTransporting	=	Spring.GetUnitIsTransporting
local GetUnitsInCylinder	=	Spring.GetUnitsInCylinder
local GetUnitTeam			=	Spring.GetUnitTeam
local GetGameRulesParam		=	Spring.GetGameRulesParam
local GetGameFrame			=	Spring.GetGameFrame

local SetGameRulesParam		=	Spring.SetGameRulesParam

local FindUnitCmdDesc		=	Spring.FindUnitCmdDesc

local GiveOrderToUnit		=	Spring.GiveOrderToUnit
local DestroyUnit			=	Spring.DestroyUnit

local InsertUnitCmdDesc		=	Spring.InsertUnitCmdDesc
local RemoveUnitCmdDesc		=	Spring.RemoveUnitCmdDesc

local params = VFS.Include("LuaRules/header/sharedParams.lua")

--variables
local unitsWhichCanRetreat = {}
--constants
local OBJECTIVE_PHASE_LENGTH	= params.OBJECTIVE_PHASE_LENGTH
local REINFORCEMENT_DELAY		= params.REINFORCEMENT_DELAY
local NO_RETREAT_PERIOD			= params.NO_RETREAT_PERIOD

local NO_RETREAT_PERIOD_START 	= OBJECTIVE_PHASE_LENGTH + REINFORCEMENT_DELAY
local NO_RETREAT_PERIOD_END		= NO_RETREAT_PERIOD_START + NO_RETREAT_PERIOD

local RETREAT_CHECK_INTERVAL	= 2 --seconds

--assign a CMDID to the retreat command
local CMD_RETREAT				= GG.CustomCommands.GetCmdID("CMD_RETREAT")

local retreatDesc = {
	name	= "Retreat",
	action	= "retreat",
	id		= CMD_RETREAT,
	type	= CMDTYPE.ICON,
	tooltip	= "Retreat this unit from the field of battle.",
}

function GG.Retreat(unitID, ignoreUnitPosition)
	local unitTeam = GetUnitTeam(unitID)
	if ignoreUnitPosition == true then
		unitsWhichCanRetreat[unitTeam][unitID] = true
	end		
	GiveOrderToUnit(unitID, CMD_RETREAT, {}, {})
end

function gadget:Initialize()
	local teams = GetTeamList()
	for i=1, #teams do
		local teamID = teams[i]
		if teamID ~= GAIA_TEAM_ID then
			unitsWhichCanRetreat[teamID] = {}
		end
	end
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_RETREAT then
		local gameFrame = GetGameFrame()
		if not unitsWhichCanRetreat[teamID][unitID] then
			return false
		end
		GG.LeaveBattlefield({[1] = unitID}, teamID)
		return true
	end
	return true
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID, attackerID)
	if unitsWhichCanRetreat[teamID] then
		if attackerID == nil then --retreated
			--process all of the units the unit was transporting and retreat them too.
			local transportedUnits = GetUnitIsTransporting(unitID)
			if transportedUnits ~= nil then
				for i=1, #transportedUnits do
					local transportedUnit = transportedUnits[i]
					local tudid = GetUnitDefID(transportedUnit)
					local tud = UnitDefs[tudid]
					if tud.name == "civilian" then
						Spring.Echo("retreated a transport with a civ in it, killing civ!")
						GG.Reward(unitTeam, "civiliansave")
						--don't need to 'retreat' them because they don't need to be recorded.
						-- their death won't trigger this code because GAIA doesn't have an index in unitsWhichCanRetreat.
						DestroyUnit(transportedUnit, false, true)
					else
						Spring.Echo("retreated a transport with non-civ units in it. retreating them in 1 second")
						--delay their retreat call so that they're free of the transport paralysis first
						GG.Delay.DelayCall(GG.Retreat, {transportedUnit, true}, 30)
					end
				end
			end
		end
		unitsWhichCanRetreat[teamID][unitID] = nil
	end
end

function gadget:GameFrame(n)
	if n % (30*RETREAT_CHECK_INTERVAL) < 0.1 then
		local teams = GetTeamList()
		for i=1,#teams do
			local teamID = teams[i]
			if teamID ~= GG.zombieTeamID and teamID ~= GetGameRulesParam("obj_win_team") then
				for unitID, canRetreat in pairs(unitsWhichCanRetreat[teamID]) do
					RemoveUnitCmdDesc(unitID, retreatDesc)
					--remove this unit from the list of units which can retreat.
					unitsWhichCanRetreat[teamID][unitID] = nil
				end
				--TODO make this apparent to the player
				if (n < NO_RETREAT_PERIOD_START or n > NO_RETREAT_PERIOD_END) then
					local x, _, z = GetTeamStartPosition(teamID)
					local unitsInRetreatZone = GetUnitsInCylinder(x, z, RETREAT_ZONE_RADIUS)
					for k=1,#unitsInRetreatZone do
						local unitID = unitsInRetreatZone[k]
						local unitTeam = GetUnitTeam(unitID)
						if unitTeam == teamID then
							unitsWhichCanRetreat[teamID][unitID] = true
							InsertUnitCmdDesc(unitID, retreatDesc)
						end
					end
				end
			end
		end
	
	end
end

else --UNSYNCED

end
