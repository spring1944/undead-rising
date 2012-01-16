--TODO:
function gadget:GetInfo()
    return {
        name      = "Civilian behavior",
        desc      = "Handles civilian behavior for Zombie apocolypse mode",
        author    = "B. Tyler (Nemo)",
        date      = "December 2009",
        license   = "LGPL v2.1 or later",
        layer     = 0,
        enabled   = true --  loaded by default?
    }
end

local zombieTeam
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
local BASE_RADIUS			= 	800


local function InRadius(x1, z1, x2, z2, radius)
	return (math.abs(x1-x2) < radius or math.abs(z1-z1) < radius)
end

local function Flee(scaryX, scaryZ, unitID, attackerTeam) --RUN AWWAAAAAY!
	Spring.SetUnitAlwaysVisible(unitID, true)
	--Spring.Echo("Fleeee", unitID, "fleee!")
	scaredUnits[unitID] = fearDuration
	scaryTeams[attackerTeam] = scaryTeamDuration
	local civX,_,civZ = GetUnitPosition(unitID)
	--Spring.Echo("civX:", civX,"civZ:", civZ)
	local nearbyUnits = GetUnitsInCylinder(civX, civZ, civilianAwareRadius)
	--Spring.Echo("and all of your little friends, all", #nearbyUnits, "of them!")
	if nearbyUnits ~= nil then
		for _,unit in ipairs(nearbyUnits) do
			if (unit ~= unitID) and (scaredUnits[unit] == 0) then
				Flee(scaryX, scaryZ, unit, attackerTeam)
			end
		end
	end
	local xDest
	local zDest	
	local x1
	local x2
	local z1
	local z2
	if (civX > scaryX) and (civZ > scaryZ) then 
		local xMax = civX + scaryX
		local zMax = civZ + scaryZ
		x1 = math.min(xMax, civX)
		x2 = math.max(xMax, civX)
		z1 = math.min(zMax, civZ)
		z2 = math.max(zMax, civZ)
		--Spring.Echo("outcome #1, xMax:", xMax, "zMax", zMax)
	end
	if (civX < scaryX) and (civZ < scaryZ) then 
		local xMin = scaryX - civX
		local zMin = scaryZ - civZ
		x1 = math.min(xMin, civX)
		x2 = math.max(xMin, civX)
		z1 = math.min(zMin, civZ)
		z2 = math.max(zMin, civZ)
		--Spring.Echo("outcome #2, xMin:", xMin, "zMin", zMin)
	end
	if (civX > scaryX) and (civZ < scaryZ) then 
		local xMax = civX + scaryX
		local zMin = scaryZ - civZ
		x1 = math.min(xMax, civX)
		x2 = math.max(xMax, civX)
		z1 = math.min(zMin, civZ)
		z2 = math.max(zMin, civZ)
		--Spring.Echo("outcome #3, xMax:", xMax, "zMin", zMin)
	end
	if (civX < scaryX) and (civZ > scaryZ) then 
		local xMin = scaryX - civX
		local zMax = civZ + scaryZ
		x1 = math.min(xMin, civX)
		x2 = math.max(xMin, civX)
		z1 = math.min(zMax, civZ)
		z2 = math.max(zMax, civZ)
		--Spring.Echo("outcome #4, xMin:", xMin, "zMax", zMax)
	end
	--Spring.Echo("x1: ",x1," x2: ",x2," z1: ",z1," z2: ",z2)
	if (x1 and x2 and z1 and z2) then
	xDest = math.random(x1, x2)
	zDest = math.random(z1, z2)
	else
	xDest = 1
	zDest = 1
	end
	local y = Spring.GetGroundHeight(xDest, zDest)
	--Spring.Echo("run off to", xDest, zDest, "little civilian")
	GiveOrderToUnit(unitID, CMD_MOVE, {xDest, y, zDest}, {})
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, _, _, _, attackerID, _, attackerTeam)
	if (scaredUnits[unitID] ~= nil) then
		--Spring.Echo("I've been hit, run my friends!")
		if attackerID ~= nil then
		local scaryX, _, scaryZ = GetUnitPosition(attackerID)
		Flee(scaryX, scaryZ, unitID, attackerTeam)	
		end
	end
end

function gadget:UnitDestroyed(unitID)
	scaredUnits[unitID] = nil
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local ud = UnitDefs[unitDefID]
	if (ud.customParams.civilian) then
		Spring.SetUnitAlwaysVisible(unitID, true)
		scaredUnits[unitID] = 0
	end
end

function gadget:Initialize()
	for _, teamID in ipairs(Spring.GetTeamList()) do
		scaryTeams[teamID] = 0
	end
end

function gadget:GameFrame(n)
	if n == 15 then
		Spring.SetGameRulesParam('zombieteam', GG.zombieTeam[0])
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
							GiveOrderToUnit(unitID, CMD_GUARD, {nearestEnemy}, {})
							local px, py, pz = GetTeamStartPosition(guardTeam)
							if scaredUnits[unitID] == 0 or InRadius(px, pz, civX, civZ, BASE_RADIUS) then
								GiveOrderToUnit(unitID, CMD_MOVE, {px, py, pz + 200}, {})
								Spring.SetUnitAlwaysVisible(unitID, false)
								AddTeamResource(guardTeam, "m", modOptions.civilian_income or 1)
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
local sendCommands			=	Spring.SendCommands
local LocalTeamID			=	Spring.GetLocalTeamID()
local GAIA_TEAM_ID			=	Spring.GetGaiaTeamID()
local GetTeamInfo			=	Spring.GetTeamInfo


local function allytogaia()
	local zombieTeam = Spring.GetGameRulesParam('zombieteam')
	local _, _, _, _, _, GAIA_ALLY_ID = GetTeamInfo(GAIA_TEAM_ID)
	local _, _, _, _, _, zombie_ally_ID	= GetTeamInfo(zombieTeam)
	if LocalTeamID == zombieTeam then
		sendCommands({'ally '.. zombie_ally_ID ..' 0'})
	else
		sendCommands({'ally '.. GAIA_ALLY_ID ..' 1'})
	end
end


function gadget:Initialize()
	gadgetHandler:AddSyncAction("allytogaia", allytogaia)
end

end
