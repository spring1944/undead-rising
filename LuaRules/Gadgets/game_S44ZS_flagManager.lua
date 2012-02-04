function gadget:GetInfo()
	return {
		name      = "S44ZS flag manager!",
		desc      = "Populates maps with flags and handles control - for zombies!",
		author    = "FLOZi, AnalyseMetalMap algorithm from easymetal.lua by CarRepairer, hacked with an axe by Nemo for UD",
		date      = "31st July 2008",
		license   = "GNU GPL v2",
		layer     = 2,
		enabled   = true  --  loaded by default?
	}
end

-- function localisations
local floor						= math.floor
-- Synced Read
local AreTeamsAllied			= Spring.AreTeamsAllied
local GetFeatureDefID			= Spring.GetFeatureDefID
local GetFeaturePosition		= Spring.GetFeaturePosition
local GetUnitsInCylinder		= Spring.GetUnitsInCylinder
local GetUnitTeam				= Spring.GetUnitTeam
local GetTeamRulesParam			= Spring.GetTeamRulesParam
local GetTeamUnitDefCount 		= Spring.GetTeamUnitDefCount

-- Synced Ctrl
local CallCOBScript				= Spring.CallCOBScript
local CreateUnit				= Spring.CreateUnit
local DestroyFeature			= Spring.DestroyFeature
local GiveOrderToUnit			= Spring.GiveOrderToUnit
local SetTeamRulesParam			= Spring.SetTeamRulesParam
local SetUnitAlwaysVisible		= Spring.SetUnitAlwaysVisible
local SetUnitBlocking			= Spring.SetUnitBlocking
local SetUnitNeutral			= Spring.SetUnitNeutral
local SetUnitNoSelect			= Spring.SetUnitNoSelect
local SetUnitRulesParam			= Spring.SetUnitRulesParam
local TransferUnit				= Spring.TransferUnit

-- constants
local GAIA_TEAM_ID = Spring.GetGaiaTeamID()
local PROFILE_PATH = "maps/flagConfig/" .. Game.mapName .. "_profile.lua"
local DEBUG	= true -- enable to print out flag locations in profile format

local CAP_MULT = 0.25 --multiplies against the FBI defined CapRate
local DEF_MULT = 0.25 --multiplies against the FBI defined DefRate

local FLAG_RADIUS = 230 -- radius of flag capping area
local CAP_THRESHOLD = 10 -- number of capping points needed for flag to switch teams
local FLAG_REGEN = 1 -- how fast a flag with no defenders or attackers will reduce capping statuses

local params = VFS.Include("LuaRules/header/sharedParams.lua")
local FLAG_CONTROL_REWARD_INTERVAL = params.FLAG_CONTROL_REWARD_INTERVAL	
		
local SIDES	= {gbr = 1, ger = 2, rus = 3, us = 4, [""] = 2}

local flagCappers = {} -- cappers[unitID] = true
local flagDefenders	= {} -- defenders[unitID] = true

local flagCapStatuses = {} -- table of flag's capping statuses
local teams	= Spring.GetTeamList()

local modOptions
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

if (gadgetHandler:IsSyncedCode()) then
-- SYNCED

local DelayCall = GG.Delay.DelayCall

-- this function is used to add any additional flag specific behaviour
function FlagSpecialBehaviour(flagID, flagTeamID, teamID)
	SetUnitRulesParam(flagID, "lifespan", 0)
	if flagTeamID == GAIA_TEAM_ID then
		CallCOBScript(flagID, "ShowFlag", 0, SIDES[GG.teamSide[teamID]] or 0)
	else
		CallCOBScript(flagID, "ShowFlag", 0, 0)
	end
end

function gadget:GameFrame(n)
	-- FLAG CONTROL
	if n == 1 then
		for i=1, #GG.houseSpots do
			if GG.houseSpots[i].hasFlag then
				flagCapStatuses[GG.houseSpots[i].unitID] = {}
			end
		end
	end
	if n % 30 == 5 then -- every second with a 5 frame offset
		for spotNum = 1, #GG.houseSpots do
			if GG.houseSpots[spotNum].hasFlag then
				local fd = GG.houseSpots[spotNum]
				local flagID = fd.unitID
				local flagTeamID = GetUnitTeam(fd.unitID)
				local cappers = flagCappers
				local defenders = flagDefenders
				local defendTotal = 0
				local unitsAtFlag = GetUnitsInCylinder(fd.x, fd.z, FLAG_RADIUS)
				
				--Reward flag owners
				if flagTeamID ~= GAIA_TEAM_ID then
					local ownerName = GG.teamIDToPlayerName[flagTeamID]
					local pd = GG.activeAccounts[ownerName] --playerData
					pd.flagControlTime = pd.flagControlTime + 1
					--Spring.Echo(ownerName.." has "..pd.flagControlTime.." control points!")
					if pd.flagControlTime % FLAG_CONTROL_REWARD_INTERVAL < 1 then
						GG.Reward(flagTeamID, "flagcontrol")
					end
				end
				
				--Handle capturing/defending
				if #unitsAtFlag == 1 then -- Only the flag, no other units
					for teamID = 0, #teams-1 do
						if teamID ~= flagTeamID then
							if (flagCapStatuses[flagID][teamID] or 0) > 0 then
								flagCapStatuses[flagID][teamID] = flagCapStatuses[flagID][teamID] - FLAG_REGEN
								SetUnitRulesParam(flagID, "cap" .. tostring(teamID), flagCapStatuses[flagID][teamID], {public = true})
							end
						end
					end
				else -- Attackers or defenders (or both) present
					for i = 1, #unitsAtFlag do
						local unitID = unitsAtFlag[i]
						local unitTeamID = GetUnitTeam(unitID)
						if defenders[unitID] and (unitTeamID == flagTeamID) then
							--Spring.Echo("Defender at flag " .. flagID .. " Value is: " .. defenders[unitID])
							defendTotal = defendTotal + defenders[unitID]
						end
						if cappers[unitID] and (unitTeamID ~= flagTeamID) then
								--Spring.Echo("Capper at flag " .. flagID .. " Value is: " .. cappers[unitID])
								flagCapStatuses[flagID][unitTeamID] = (flagCapStatuses[flagID][unitTeamID] or 0) + cappers[unitID]
						end
					end
					for j = 1, #teams do
						teamID = teams[j]
						local playerName = GG.teamIDToPlayerName[teamID]
						if teamID ~= flagTeamID then
							if (flagCapStatuses[flagID][teamID] or 0) > 0 then
								--Spring.Echo("Capping: " .. flagCapStatuses[flagID][teamID] .. " Defending: " .. defendTotal)
								flagCapStatuses[flagID][teamID] = flagCapStatuses[flagID][teamID] - defendTotal
								if flagCapStatuses[flagID][teamID] < 0 then
									flagCapStatuses[flagID][teamID] = 0
								end
								SetUnitRulesParam(flagID, "cap" .. tostring(teamID), flagCapStatuses[flagID][teamID], {public = true})
							end
						end
						if (flagCapStatuses[flagID][teamID] or 0) > CAP_THRESHOLD and teamID ~= flagTeamID then
							-- Flag is ready to change team
							if (flagTeamID == GAIA_TEAM_ID) then
								-- Neutral flag being capped
								--Spring.SendMessageToTeam(teamID, flagData.tooltip .. " Captured!")
								TransferUnit(flagID, teamID, false)
								SetTeamRulesParam(teamID, "Flags", (GetTeamRulesParam(teamID, "Flags") or 0) + 1, {public = true})
							else
								-- Team flag being neutralised
								--Spring.SendMessageToTeam(teamID, flagData.tooltip .. " Neutralised!")
								TransferUnit(flagID, GAIA_TEAM_ID, false)
								SetTeamRulesParam(teamID, "Flags", (GetTeamRulesParam(teamID, "Flags") or 0) - 1, {public = true})
							end
							-- Perform any flag specific behaviours
							FlagSpecialBehaviour(flagID, flagTeamID, teamID)
							-- Turn flag back on
							GiveOrderToUnit(flagID, CMD.ONOFF, {1}, {})
							-- Flag has changed team, reset capping statuses
							for cleanTeamID = 0, #teams-1 do
								flagCapStatuses[flagID][cleanTeamID] = 0
								SetUnitRulesParam(flagID, "cap" .. tostring(cleanTeamID), 0, {public = true})
							end
						end
						-- cleanup defenders
						flagCapStatuses[flagID][flagTeamID] = 0
					end
				end
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam, builderID)
	if unitTeam ~= GAIA_TEAM_ID then
		local ud = UnitDefs[unitDefID]
		local cp = ud.customParams

		local flagCapRate = cp.flagcaprate or 1
		local flagDefendRate = cp.flagdefendrate or flagCapRate
		if flagCapRate and not (cp.flag) then
			flagCappers[unitID] = (CAP_MULT * flagCapRate)
			flagDefenders[unitID] = (DEF_MULT * flagCapRate)
		end
	end

end


function gadget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	local ud = UnitDefs[unitDefID]
	local cp = ud.customParams
	local flagCapRate = cp.flagcaprate
	local flagCapType = ud.customParams.flagcaptype or "flag"
	if flagCapRate then
		flagCappers[unitID] = nil
		flagDefenders[unitID] = nil
	end
end

else
-- UNSYNCED
end
