--TODO:
function gadget:GetInfo()
    return {
        name      = "Surrender",
        desc      = "Allows units to 'surrender' rather than just die.",
        author    = "Ben Tyler (Nemo)",
        date      = "July 9th, 2009",
        license   = "LGPL v2.1 or later",
        layer     = 0,
        enabled   = false  --  loaded by default?
    }
end

if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()

if (tonumber(modOptions.prisoner_income)) then
if (tonumber(modOptions.prisoner_income) > 0) then
if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
--  SYNCED
--------------------------------------------------------------------------------
local CMD_FIRESTATE		=	CMD.FIRE_STATE
local CMD_MOVESTATE		=	CMD.MOVE_STATE
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
local TransferUnit			= 	Spring.TransferUnit
local GiveOrderToUnit		=	Spring.GiveOrderToUnit

local surrenderedUnits		= 	{}
local escapeRadius 			=	400 --how far away enemy 'guards' can go before the escape countdown timer begins. Also used for checking nearby units when a unit is scared and considering surrender.
local enemyMult				=	2 --the 'advantage' given to enemies in counting friendlies and enemies to determine surrendering - 2 means that if there are half the # of enemies as there are allies, and the unit is scared enough, they'll surrender
local surrenderDestDistance	=	700 --the distance that the 4 "holding spots" for prisoners will be from that team's starting pos.
local prisonFudge 			=	150
--[[
esTime is given by the call to GG.surrender,
and sets how long the unit can be guard-free
in their escapeRadius before they go back to
their old team.
]]--


--escapeTime is seconds until unit escapes if unattended. 0 is unlimited
function GG.surrender(unitID, esTime)
	local GAIA_TEAM_ID = GetGaiaTeamID()
	local currentTeam = GetUnitTeam(unitID)
	if currentTeam ~= GAIA_TEAM_ID then
		local allyTeam	= GetUnitAllyTeam(unitID)
		--local nearbyUnits	= {}
		local x, _, z = GetUnitPosition(unitID)
		--Spring.Echo(x, z, escapeRadius)
		local enemyTotal = 0
		local allyTotal = 0
		--counts nearby enemies and friendlies
		local nearbyUnits = GetUnitsInCylinder(x, z, escapeRadius)

		if nearbyUnits ~= nil then
			 for i = 1, #nearbyUnits do
				local nearbyUnit = nearbyUnits[i]
				local unitAllyTeam = GetUnitAllyTeam(nearbyUnit)
				local nearbyUnitTeam = GetUnitTeam(nearbyUnit)
				if nearbyUnitTeam ~= GAIA_TEAM_ID then
					if allyTeam == unitAllyTeam then
						allyTotal = allyTotal + 1
					else
						enemyTotal = enemyTotal + 1
					end
				end
			end
		end
		--Spring.Echo("allies: ", allyTotal, "enemies: ", enemyTotal)
		--if he's scared enough and there are too many bad guys around - surrender!
		if ((enemyMult*enemyTotal) > allyTotal) then
			local currentTime = GetGameSeconds()
			local nearestGuard = GetUnitNearestEnemy(unitID, escapeRadius, 0)
			if nearestGuard ~= nil then -- shouldn't ever be nil, really; the count just happened!
				local guardTeam = GetUnitTeam(nearestGuard)
				if (currentTeam ~= GAIA_TEAM_ID) and (surrenderedUnits[unitID] == nil) then
					local px, py, pz = GetTeamStartPosition(guardTeam)
					local pickDest = math.random(1,4)
					if pickDest == 1 then
					px = (px - surrenderDestDistance)
					pz = (pz - surrenderDestDistance)
					end
					if pickDest == 2 then
					px = (px + surrenderDestDistance)
					pz = (pz + surrenderDestDistance)
					end
					if pickDest == 3 then
					px = (px + surrenderDestDistance)
					pz = (pz - surrenderDestDistance)
					end
					if pickDest == 4 then
					px = (px - surrenderDestDistance)
					pz = (pz + surrenderDestDistance)
					end
					surrenderedUnits[unitID] = {
						originalTeam = currentTeam,
						surrenderTime = currentTime,
						escapeTime = esTime,
						capturingTeam = guardTeam,
						prisonX = px,
						prisonZ = pz,
					}
					TransferUnit(unitID, GAIA_TEAM_ID, false)
					GiveOrderToUnit(unitID, CMD_FIRESTATE, { 0 }, 0)
					GiveOrderToUnit(unitID, CMD_MOVESTATE, { 0 }, 0)
					GiveOrderToUnit(unitID, CMD_STOP, {}, 0)

				end
			end
		end
		nearbyUnits[unitID] = nil
	end
end

function gadget:UnitDestroyed(unitID)
	surrenderedUnits[unitID] = nil
end


function gadget:GameFrame(n)
	if n == 5 then
		SendToUnsynced('allytogaia')
	end
	if n % (1*30) < 0.5 then
		for unitID, someThing in pairs(surrenderedUnits) do
			px, py, pz = GetUnitPosition(unitID)
			if surrenderedUnits[unitID].prisonX - px > prisonFudge or surrenderedUnits[unitID].prisonX - px < ((0-1) * prisonFudge) then 
				GiveOrderToUnit(unitID, CMD_MOVE, {surrenderedUnits[unitID].prisonX, py, surrenderedUnits[unitID].prisonZ}, {})
			else
				GiveOrderToUnit(unitID, CMD_FIRESTATE, { 0 }, 0)
				GiveOrderToUnit(unitID, CMD_MOVESTATE, { 0 }, 0)
				GiveOrderToUnit(unitID, CMD_STOP, {}, 0)
			end
			local nearestGuard = GetUnitNearestEnemy(unitID, escapeRadius, 0)
			local inTransport = GetUnitTransporter(unitID)
			local currentTime = GetGameSeconds()
			local captureTime = surrenderedUnits[unitID].surrenderTime
			local escapeTime = surrenderedUnits[unitID].escapeTime
			local oldTeam = surrenderedUnits[unitID].originalTeam
			local captureTeam = surrenderedUnits[unitID].capturingTeam
			if nearestGuard ~= nil then
				local unitDefID = GetUnitDefID(nearestGuard)
				local ud = UnitDefs[unitDefID]
				local armedGuard = ud.weapons[1]
				if armedGuard == nil then
					nearestGuard = nil
				end
			end
			if nearestGuard ~= nil then
				local guardTeam = GetUnitTeam(nearestGuard)
				if guardTeam == oldTeam and ((currentTime - captureTime) > (escapeTime/2)) and (inTransport == nil) and GG.fear[unitID] < 20 then --nearby friendlies let the prisoner escape in half the time; its all a mental prison, really.
					TransferUnit(unitID, oldTeam)
					surrenderedUnits[unitID] = nil
					return
				end
				if guardTeam == captureTeam then
					if (tonumber(modOptions.prisoner_income) > 0) then
							AddTeamResource(guardTeam, "m", modOptions.prisoner_income or 1)
					end
					surrenderedUnits[unitID].surrenderTime = n / 30
				end
			else
				if inTransport == nil then
					if ((currentTime - captureTime) > escapeTime) and GG.fear[unitID] == 0 then
						TransferUnit(unitID, oldTeam)
						surrenderedUnits[unitID] = nil
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
local _, _, _, _, _, GAIA_ALLY_ID = GetTeamInfo(GAIA_TEAM_ID)
local function allytogaia()
	sendCommands({'ally '.. GAIA_ALLY_ID ..' 1'})
	Spring.Echo(LocalTeamID, "Allied!")
end

function gadget:Initialize()
	gadgetHandler:AddSyncAction("allytogaia", allytogaia)
end
end
end
end
end
