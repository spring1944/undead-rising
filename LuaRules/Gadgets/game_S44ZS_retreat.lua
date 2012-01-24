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

local FindUnitCmdDesc		=	Spring.FindUnitCmdDesc

local GiveOrderToUnit		=	Spring.GiveOrderToUnit
local DestroyUnit			=	Spring.DestroyUnit

local InsertUnitCmdDesc		=	Spring.InsertUnitCmdDesc
local RemoveUnitCmdDesc		=	Spring.RemoveUnitCmdDesc

VFS.Include("LuaRules/header/S44_commandIDs.lua")

--variables
local unitsWhichCanRetreat = {}
--constants
local RETREAT_CHECK_INTERVAL	= 2 --seconds


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
		unitsWhichCanRetreat[teamID][unitID] = true
	end
		
	GiveOrderToUnit(unitID, CMD_RETREAT, {}, {})
	local transportedUnits = GetUnitIsTransporting(unitID)

	if transportedUnits ~= nil then
		for i=1, #transportedUnits do
			local transportedUnit = transportedUnits[i]
			local tudid = GetUnitDefID(transportedUnit)
			local tud = UnitDefs[tudid]
			if tud.name == "civilian" then
				GG.activeAcounts.rescuedCivilians = GG.activeAcounts.rescuedCivilians + 1
				GG.Reward(unitTeam, "civiliansave")
			end
			--GiveOrderToUnit(transportedUnit, CMD_RETREAT, {}, {})
		end
	end
end

function gadget:Initialize()
	local teams = GetTeamList()
	for i=1, #teams do
		local teamID = teams[i]
		if teamID ~= GAIA_TEAM_ID then
			unitsWhichCanRetreat[teamID] = {}
		end
	end
	gadgetHandler:RegisterCMDID(CMD_RETREAT)
end

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_RETREAT then
		if not unitsWhichCanRetreat[teamID][unitID] then
			return false
		end
		DestroyUnit(unitID, false, true) --unitID, self-d, reclaimed (ie silent)
		return true
	end
	return true
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitsWhichCanRetreat[teamID] then
		unitsWhichCanRetreat[teamID][unitID] = nil
	end
end

function gadget:GameFrame(n)
	if Spring.GetGameRulesParam("shopmode") == 1  then
		gadgetHandler:RemoveGadget()
		return
	end
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

else --UNSYNCED

end