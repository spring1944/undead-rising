-- easymetal constants
local EXTRACT_RADIUS = Game.extractorRadius > 125 and Game.extractorRadius or 125
local GRID_SIZE	= 4
local THRESH_FRACTION = 0.4
local MAP_WIDTH = math.floor(Game.mapSizeX / GRID_SIZE)
local MAP_HEIGHT = math.floor(Game.mapSizeZ / GRID_SIZE)

--synced read
local GetGroundHeight			= Spring.GetGroundHeight
local GetGroundInfo				= Spring.GetGroundInfo
--easymetal vars
local metalMap = {}
local maxMetal = 0
local totalMetal = 0
local metalSpots = {}
local metalSpotCount	= 0
local metalData = {}
local metalDataCount = 0

-- easymetal code starts
local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


local function mergeToSpot(spotNum, px, pz, pWeight)
	local sx = metalSpots[spotNum].x
	local sz = metalSpots[spotNum].z
	local sWeight = metalSpots[spotNum].weight
	
	local avgX, avgZ
	
	if sWeight > pWeight then
		local sStrength = round(sWeight / pWeight)
		avgX = (sx*sStrength + px) / (sStrength +1)
		avgZ = (sz*sStrength + pz) / (sStrength +1)
	else
		local pStrength = (pWeight / sWeight)
		avgX = (px*pStrength + sx) / (pStrength +1)
		avgZ = (pz*pStrength + sz) / (pStrength +1)		
	end
	
	metalSpots[spotNum].x = avgX
	metalSpots[spotNum].z = avgZ
	metalSpots[spotNum].weight = sWeight + pWeight
end


local function NearSpot(px, pz, dist)
	for k, spot in pairs(metalSpots) do
		local sx, sz = spot.x, spot.z
		if (px-sx)^2 + (pz-sz)^2 < dist then
			return k
		end
	end
	return false
end


function AnalyzeMetalMap()	
	for mx_i = 1, MAP_WIDTH do
		metalMap[mx_i] = {}
		for mz_i = 1, MAP_HEIGHT do
			local mx = mx_i * GRID_SIZE
			local mz = mz_i * GRID_SIZE
			local _, curMetal = GetGroundInfo(mx, mz)
			if GetGroundHeight(mx, mz) <= 0 then curMetal = 0 end -- ignore water metal
			totalMetal = totalMetal + curMetal
			--curMetal = floor(curMetal * 100)
			metalMap[mx_i][mz_i] = curMetal
			if (curMetal > maxMetal) then
				maxMetal = curMetal
			end	
		end
	end
	
	local lowMetalThresh = math.floor(maxMetal * THRESH_FRACTION)
	
	for mx_i = 1, MAP_WIDTH do
		for mz_i = 1, MAP_HEIGHT do
			local mCur = metalMap[mx_i][mz_i]
			if mCur > lowMetalThresh then
				metalDataCount = metalDataCount +1
				
				metalData[metalDataCount] = {
					x = mx_i * GRID_SIZE,
					z = mz_i * GRID_SIZE,
					metal = mCur
				}
				
			end
		end
	end
	
	table.sort(metalData, function(a,b) return a.metal > b.metal end)
	
	for index = 1, metalDataCount do
		local mx = metalData[index].x
		local mz = metalData[index].z
		local mCur = metalData[index].metal
		
		local nearSpotNum = NearSpot(mx, mz, EXTRACT_RADIUS*EXTRACT_RADIUS)
	
		if nearSpotNum then
			mergeToSpot(nearSpotNum, mx, mz, mCur)
		else
			metalSpotCount = metalSpotCount + 1
			metalSpots[metalSpotCount] = {
				x = mx,
				z = mz,
				weight = mCur
			}
		end
	end
	return metalSpots
end
-- easymetal code ends