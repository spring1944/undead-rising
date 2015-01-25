local reinforcementDefs = {
    ["ger"] = {
        wave = {
            [1] = {
                ["gertrucksupplies"] = 3,
                ["gerflak38_stationary"] = 4,
                ["gerrifle"] = 20,
                ["gerjagdpanzeriv"] = 3,
            },
            [2] = {
                ["gerrifle"] = 50,
                ["gertiger"] = 5,
                ["gertigerii"] = 2,
                ["gerpanther"] = 6,
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
                ["rusrifle"] = 30,
                ["russu85"] = 4,
            },
            [2] = {
                ["rusrifle"] = 100,
                ["rusppsh"] = 50,
                ["rust60"] = 15,
                ["rusm5halftrack"] = 5,
                ["rust3485"] = 6,
                ["rusis2"] = 2,
                ["rusisu152"] = 4,
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
                ["usgirifle"] = 20,
                ["usm10wolverine"] = 4,
            },
            [2] = {
                ["usgirifle"] = 60,
                ["usgibar"] = 30,
                ["usgithompson"] = 30,
                ["usgiflamethrower"] = 15,
                ["usm5stuart"] = 20,
                ["usm3halftrack"] = 10,
                ["usm8greyhound"] = 8,
                ["usm4a4sherman"] = 12,
                ["usm4a3105sherman"] = 4,
            }
        },
    },
    ["gbr"] = {
        wave = {
            [1] = {
                ["gbrbofors_stationary"] = 4,
                ["gbrtrucksupplies"] = 3,
                ["gbrrifle"] = 20,
                ["gbrachilles"] = 3,
            },
            [2] = {
                ["gbrrifle"] = 50,
                ["gbrsten"] = 30,
                ["gbrbren"] = 15,
                ["gbrcommando"] = 20,
                ["gbrwasp"] = 20,
                ["gbrm5halftrack"] = 10,
                ["gbrcromwell"] = 8,
                ["gbraecmkii"] = 10,
                ["gbrcromwellmkvi"] = 4,
                ["gbrchurchillmkvii"] = 4,
            }
        },
    },
    ["zom"] = {
        wave = {
            [1] = {
                ["zomsprinter"] = 50,
            },
            [2] = {
                ["zomsprinter"] = 250,
            }
        },
    }
}
return reinforcementDefs
