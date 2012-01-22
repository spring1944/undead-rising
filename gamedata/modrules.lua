local modRules = {
	flankingBonus = {
		defaultMode					=	0,
	},
	experience = {
		powerScale					=	1.5,
		healthScale					=	1.5,
		reloadScale					=	1.5,
		experienceMult			=	0.75,
	},
	sensors = {
		los = {
			losMipLevel				=	3,
			airMipLevel				=	5,
		},
	},
	movement = {
		allowCrushingAlliedUnits = false,
		allowUnitCollisionDamage = true,
	},
	nanospray = {
		allow_team_colours	=	false,
	},
}

return modRules