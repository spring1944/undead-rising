function gadget:GetInfo()
	return {
		name      = "Corpse buster!",
		desc      = "Causes the undead to spring from the corpses of the fallen.",
		author    = "Gnome, tweaked by Nemo",
		date      = "December 2009",
		license   = "CC by-nc, version 3.0",
		layer     = 0,
		enabled   = true
	}
end

if (gadgetHandler:IsSyncedCode()) then
--[[zombie types, numbered 1-to max.
BRAINSBRAINSBRAINSBRAINSBRAINS
1 - shambler. slow, fairly durable. no ranged attack
2 - sprinter. FAST ANGRY ZOMBIE. not as durable
3 - something else?


]]--
if (Spring.GetModOptions) then
  modOptions = Spring.GetModOptions()
end

local GetGaiaTeamID			=	Spring.GetGaiaTeamID

local zombificationRadius	=	100

function gadget:GameFrame(n)

	if(n % 30 < 3) then
		local features = Spring.GetAllFeatures()
		for _,fid in ipairs(features) do
			local fdid = Spring.GetFeatureDefID(fid)
			local fname = FeatureDefs[fdid].name
			if fname and (string.find(fname, "soldier") or string.find(fname, "civilian")) ~= nil then
				local x, y, z = Spring.GetFeaturePosition(fid)
				local nearbyUnits = Spring.GetUnitsInCylinder(x, z, zombificationRadius)
				if nearbyUnits ~= nil then
					for _,unit in ipairs(nearbyUnits) do
						local unitDefID = Spring.GetUnitDefID(unit)
						--Spring.Echo("UnitID!!!",unit)
						local ud = UnitDefs[unitDefID]
						--Spring.Echo("UD!!!",ud)
						if ud ~= nil then
							if (ud.customParams.undead == "1") then
								local pickZombie = math.random(1,1)
								local zombieName
								if pickZombie == 1 then
									zombieName = "zomsprinter"
								end
								local teams = Spring.GetTeamList()
								local zombieTeam = tonumber(modOptions.zombie_team) or 1
								if (teams[zombieTeam] ~= nil) then
									Spring.CreateUnit(zombieName, x, y, z, 0, zombieTeam)
									Spring.DestroyFeature(fid)
									break
								end
							end
						end
					end
				end
			end
		end
	end
end

end
