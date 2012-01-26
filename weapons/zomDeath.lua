-- Misc - Deaths

-- Death Base Class
local zomDeathClass = Weapon:New{
  craterMult         = 0,
  explosionSpeed     = 30,
  damage = {
    default            = 33,
  },
}

-- Death Base Class
local zomDeath = zomDeathClass:New{
  craterMult         = 0,
  explosionSpeed     = 30,
  areaOfEffect       = 64,
  impulseFactor      = 0,
  customparams = {
    damagetype         = [[explosive]],
  },
  damage = {
    default            = 1,
  },
}


local zomDeathSmoke = zomDeathClass:New{
  craterMult         = 0,
  explosionSpeed     = 30,
  areaOfEffect       = 64,
  impulseFactor      = 0,
  customparams = {
	smokeradius        = 160,
	smokeduration      = 5,
	smokeceg           = [[SMOKESHELL_Small]],
  },
  damage = {
    default            = 1,
  },
}
-- Implementations

return lowerkeys({
  zomDeath = zomDeath,
  zomDeathSmoke = zomDeathSmoke,
})
