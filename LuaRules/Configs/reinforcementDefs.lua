local reinforcementDefs = {
    ["ger"] = {
        wave = {
            [1] = {
                ["gertrucksupplies"] = 3,
                ["gerflak38_stationary"] = 4,
                ["ger_platoon_rifle"] = 4,
                ["gerjagdpanzeriv"] = 3,
            },
            [2] = {
                ["ger_platoon_rifle"] = 7,
                ["ger_platoon_assault"] = 4,
                ["gertiger"] = 5,
                ["gertigerii"] = 2,
                ["gerpanzeriv"] = 10,
                ["gerpanther"] = 8,
                ["gersdkfz251"] = 10,
                ["gersdkfz250"] = 6,
                ["gerstugiii"] = 6,
                ["gerpuma"] = 12,
            },
        },
    },
    ["rus"] = {
        wave = {
            [1] = {
                ["rus61k_stationary"] = 4,
                ["rustrucksupplies"] = 3,
                ["rus_platoon_rifle"] = 3,
                ["russu85"] = 4,
            },
            [2] = {
                ["rus_platoon_rifle"] = 7,
                ["rus_platoon_assault"] = 4,
                ["rust60"] = 10,
                ["rusm5halftrack"] = 5,
                ["rust3476"] = 8,
                ["rust3485"] = 6,
                ["rusis2"] = 2,
                ["rusisu152"] = 4,
                ["russu100"] = 2,
                ["rusbm13n"] = 2,
                ["rusba64"] = 10,
            },
        },
    },
    ["us"] = {
        wave = {
            [1] = {
                ["usm1bofors_stationary"] = 4,
                ["ustrucksupplies"] = 3,
                ["us_platoon_rifle"] = 3,
                ["usm10wolverine"] = 6,
            },
            [2] = {
                ["us_platoon_rifle"] = 7,
                ["us_platoon_assault"] = 4,
                ["us_platoon_flamethrower"] = 5,
                ["usm5stuart"] = 15,
                ["usm3halftrack"] = 10,
                ["usm8greyhound"] = 8,
                ["usm4a4sherman"] = 14,
                ["usm4a376sherman"] = 8,
                ["usm4a3105sherman"] = 4,
                ["usm4jumbo"] = 4,
            }
        },
    },
    ["gbr"] = {
        wave = {
            [1] = {
                ["gbrbofors_stationary"] = 4,
                ["gbrtrucksupplies"] = 3,
                ["gbr_platoon_rifle"] = 3,
                ["gbrm10achilles"] = 3,
            },
            [2] = {
                ["gbr_platoon_hq"] = 15,
                ["gbr_platoon_rifle"] = 1,
                ["gbr_platoon_assault"] = 5,
                ["gbrwasp"] = 20,
                ["gbrdaimler"] = 10,
                ["gbrm5halftrack"] = 10,
                ["gbrcromwell"] = 8,
                ["gbraecmkii"] = 6,
                ["gbrshermanfirefly"] = 6,
                ["gbrcromwellmkvi"] = 4,
                ["gbrchurchillmkvii"] = 4,
            }
        },
    },
    ["ita"] = {
        wave = {
            [1] = {
                ["itabreda20_stationary"] = 4,
                ["itatrucksupplies"] = 3,
                ["ita_platoon_rifle"] = 3,
                ["itaautocannone90"] = 3,
            },
            [2] = {
                ["ita_platoon_rifle"] = 2,
                ["ita_platoon_bersaglieri"] = 6,
                ["ita_platoon_alpini"] = 4,
                ["ital6_40lf"] = 8,
                ["itaab41"] = 12,
                ["itaas37"] = 10,
                ["itap40"] = 5,
                ["itasemovente90"] = 8,
                ["itasemovente75"] = 10,
                ["itasemovente105"] = 4,
            }
        },
    },
    ["jpn"] = {
        wave = {
            [1] = {
                ["jpntype98_20mm_stationary"] = 4,
                ["jpntrucksupplies"] = 3,
                ["jpn_platoon_rifle"] = 3,
                ["jpnhoniiii"] = 6,
            },
            [2] = {
                ["jpn_platoon_rifle"] = 7,
                ["jpn_platoon_assault"] = 4,
                ["jpn_tankette_platoon_teke"] = 8,
                ["jpnhoha"] = 4,
                ["jpnchihe"] = 12,
                ["jpnhoni"] = 8,
                ["jpnchiha120mm"] = 4,
                ["jpnshinhotochiha"] = 8,
                ["jpnchiha"] = 6,
                ["jpnhoro"] = 6,
                ["jpnhoniii"] = 3,
            }
        },
    },

    ["zom"] = {
        wave = {
            [1] = {
                ["zomsprinter"] = 70,
            },
            [2] = {
                ["zomsprinter"] = 200,
            }
        },
    }
}
return reinforcementDefs
