--TODO:
function gadget:GetInfo()
    return {
        name      = "Zombie behavior",
        desc      = "Handles zombie behavior for Zombie apocolypse mode",
        author    = "B. Tyler (Nemo)",
        date      = "December 2009",
        license   = "LGPL v2.1 or later",
        layer     = 0,
        enabled   = false --  loaded by default?
    }
end

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end


local CMD_FIRESTATE		=	CMD.FIRE_STATE
local CMD_MOVESTATE		=	CMD.MOVE_STATE
local CMD_GUARD			=	CMD.GUARD
local CMD_MOVE			=	CMD.MOVE
local CMD_STOP			=	CMD.STOP

local GetTeamStartPosition	=	Spring.GetTeamStartPosition
local GetUnitTransporter	=	Spring.GetUnitTransporter
local GetGameFrame			=	Spring.GetGameFrame
local GetGameSeconds		=	Spring.GetGameSeconds
local GetUnitNearestEnemy	=	Spring.GetUnitNearestEnemy
local GetUnitSeparation		=	Spring.GetUnitSeparation
local GetUnitsInCylinder	=	Spring.GetUnitsInCylinder
local GetUnitPosition		=	Spring.GetUnitPosition
local GetUnitTeam			=	Spring.GetUnitTeam
local GetUnitAllyTeam		=	Spring.GetUnitAllyTeam
local GetGaiaTeamID			=	Spring.GetGaiaTeamID
local GetTeamInfo			=	Spring.GetTeamInfo
local GetUnitDefID			=	Spring.GetUnitDefID

local AddTeamResource		=	Spring.AddTeamResource
local GiveOrderToUnit		=	Spring.GiveOrderToUnit

local civilianAwareRadius	=	450 --how far around them civilians are aware of things happening (like civilians dying, zombies approaching, etc).
local scaredUnits			=	{}
local scaryTeams			=	{}
local scaryTeamDuration		=	15
local fearDuration			=	15
local stationaryScaredTime	=	5

function gadget:UnitDestroyed(unitID)
	zombies[unitID] = nil
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if (ud.customParams.undead == "1") then
		zombies[unitID] = true
		GG.zombieTeam = teamID
		GiveOrderToUnit(unitID, CMD_MOVESTATE, { 2 }, 0)
	end
end

function gadget:GameFrame(n)
	if n == 5 then
		SendToUnsynced('allytogaia')
	end
	
	if(n % 30 < 1) then
		for teamID, someThing in pairs(scaryTeams) do
			--Spring.Echo("scary teamID:",teamID, "fear factor:", scaryTeams[teamID])
			if scaryTeams[teamID] > 0 then
				scaryTeams[teamID] = scaryTeams[teamID] - 1
			else
				scaryTeams[teamID] = 0
			end
		end
		
		for unitID, someThing in pairs(scaredUnits) do
			if scaredUnits[unitID] > 0 then
				scaredUnits[unitID] = scaredUnits[unitID] - 1
			else
				scaredUnits[unitID] = 0
			end
			local nearestEnemy = GetUnitNearestEnemy(unitID, civilianAwareRadius, 0)
			if nearestEnemy ~= nil then
				local unitDefID = GetUnitDefID(nearestEnemy)
				local ud = UnitDefs[unitDefID]
				local zombie = ud.customParams.undead
				local civX, _, civZ = GetUnitPosition(unitID)
				if (zombie == "1") then
					local zomX, _, zomZ = GetUnitPosition(nearestEnemy)
					local zombieTeam = GetUnitTeam(nearestEnemy)
					--Spring.Echo("aiee a zombie!")
					Flee(zomX, zomZ, unitID, zombieTeam)
				else
					local guardTeam = GetUnitTeam(nearestEnemy)
					if (scaryTeams[guardTeam]) then
						if (scaryTeams[guardTeam] > 0 and scaredUnits[unitID] > stationaryScaredTime) then
							local enemyX,_,enemyZ = GetUnitPosition(nearestEnemy)
							--Spring.Echo("they're the ones who shot at us!")
							Flee(enemyX, enemyZ, unitID, guardTeam)
						else
							local unitDefID = Spring.GetUnitDefID(nearestEnemy)
							local ud = UnitDefs[unitDefID]
							local armedGuard = ud.weapons[1]
							if ud.canMove and armedGuard then
								GiveOrderToUnit(unitID, CMD_GUARD, {nearestEnemy}, {})
								if scaredUnits[unitID] == 0 then
									AddTeamResource(guardTeam, "m", modOptions.civilian_income or 1)
								end
							end
						end
					end
				end
			end
		end
    end
end

-----------------------
else --Unsynced
----------------------

end
