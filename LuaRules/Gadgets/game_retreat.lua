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
local FindUnitCmdDesc		=	Spring.FindUnitCmdDesc

local DestroyUnit			=	Spring.DestroyUnit

local InsertUnitCmdDesc		=	Spring.InsertUnitCmdDesc
local RemoveUnitCmdDesc		=	Spring.RemoveUnitCmdDesc

VFS.Include("LuaRules/header/S44_commandIDs.lua")

--variables
local unitsWhichCanRetreat = {}
--constants
local RETREAT_CHECK_INTERVAL	= 5 --seconds


local retreatDesc = {
	name	= "Retreat",
	action	= "retreat",
	id		= CMD_RETREAT,
	type	= CMDTYPE.ICON,
	tooltip	= "Retreat this unit from the field of battle.",
}

function GG.Retreat(unitID, teamID)
	DestroyUnit(unitID, false, true) --unitID, self-d, reclaimed (ie silent)
end

function gadget:Initialize()
	local teams = GetTeamList()
	for i=1, #teams do
		teamID = teams[i]
		if teamID ~= GAIA_TEAM_ID and teamID ~= GG.zombieTeamID then
			unitsWhichCanRetreat[teamID] = {}
		end
	end
	gadgetHandler:RegisterCMDID(CMD_RETREAT)
end

function gadget:CommandFallback(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID == CMD_RETREAT then
		Spring.Echo("GOT A RETREAT COMMAND!")
		GG.Retreat(unitID, teamID)
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if unitsWhichCanRetreat[teamID] then
		unitsWhichCanRetreat[teamID][unitID] = nil
	end
end

function gadget:GameFrame(n)
	if n % RETREAT_CHECK_INTERVAL < 0.1 then
		local teams = GetTeamList()
		for i=1,#teams do
			local teamID = teams[i]
			
			for unitID, canRetreat in pairs(unitsWhichCanRetreat[teamID]) do
				RemoveUnitCmdDesc(unitID, retreatDesc)
				--remove this unit from the list of units which can retreat.
				unitsWhichCanRetreat[teamID][unitID] = nil
			end
			
			local x, _, z = GetTeamStartPosition(teamID)
			local unitsInRetreatZone = GetUnitsInCylinder(x, z, RETREAT_ZONE_RADIUS)
			for k=1,#unitsInRetreatZone do
				local unitID = unitsInRetreatZone[k]
				unitsWhichCanRetreat[teamID][unitID] = true
				InsertUnitCmdDesc(unitID, retreatDesc)
			end
		end
	
	end
end

else --UNSYNCED

end