-- FIVEGUARD ENTITY VALIDATION SYSTEM
-- Kapsamlı entity kontrolü ve validation sistemi (Valkyrie'den esinlenilmiş)

FiveguardServer.EntityValidation = {}

-- =============================================
-- ENTITY VALIDATION DEĞİŞKENLERİ
-- =============================================

local entityData = {
    isActive = false,
    validatedEntities = {},
    suspiciousEntities = {},
    entityCreations = {},
    config = {
        enableVehicleValidation = true,
        enablePedValidation = true,
        enableObjectValidation = true,
        enableWeaponValidation = true,
        maxEntitiesPerPlayer = 50,
        entityCreationCooldown = 1000, -- 1 saniye
        autoDeleteIllegal = true,
        autoActionEnabled = true,
        whitelistMode = true -- true = sadece whitelist'teki entity'ler, false = blacklist kontrolü
    },
    stats = {
        totalValidations = 0,
        illegalVehicles = 0,
        illegalPeds = 0,
        illegalObjects = 0,
        illegalWeapons = 0,
        entitiesDeleted = 0,
        lastDetection = 0
    }
}

-- Vehicle Whitelist (Valkyrie'den alınan kapsamlı liste)
local vehicleWhitelist = {
    -- Compacts
    "adder", "rs62", "asbo", "blista", "brioso", "club", "dilettante", "dilettante2",
    "issi2", "issi3", "issi4", "issi5", "issi6", "kanjo", "panto", "prairie", "rhapsody",
    
    -- Sedans
    "asea", "asea2", "asterope", "cog55", "cog552", "cognoscenti", "cognoscenti2",
    "emperor", "emperor2", "emperor3", "fugitive", "glendale", "glendale2", "ingot",
    "intruder", "limo2", "premier", "primo", "primo2", "regina", "romero", "schafter2",
    "schafter5", "schafter6", "stafford", "stanier", "stratum", "stretch", "superd",
    "surge", "tailgater", "warrener", "washington",
    
    -- SUVs
    "baller", "baller2", "baller3", "baller4", "baller5", "baller6", "bjxl",
    "cavalcade", "cavalcade2", "contender", "dubsta", "dubsta2", "fq2", "granger",
    "gresley", "habanero", "huntley", "landstalker", "landstalker2", "mesa", "mesa2",
    "novak", "patriot", "patriot2", "radi", "rebla", "rocoto", "seminole", "seminole2",
    "serrano", "toros", "xls", "xls2",
    
    -- Coupes
    "cogcabrio", "exemplar", "f620", "felon", "felon2", "jackal", "oracle", "oracle2",
    "sentinel", "sentinel2", "windsor", "windsor2", "zion", "zion2",
    
    -- Muscle
    "blade", "buccaneer", "buccaneer2", "chino", "chino2", "clique", "coquette3",
    "deviant", "dominator", "dominator2", "dominator3", "dominator4", "dominator5",
    "dominator6", "dukes", "dukes2", "dukes3", "ellie", "faction", "faction2",
    "faction3", "gauntlet", "gauntlet2", "gauntlet3", "gauntlet4", "gauntlet5",
    "hermes", "hotknife", "hustler", "impaler", "impaler2", "impaler3", "impaler4",
    "lurcher", "manana2", "moonbeam", "moonbeam2", "nightshade", "peyote2", "phoenix",
    "picador", "ratloader", "ratloader2", "ruiner", "sabregt", "sabregt2", "slamvan",
    "slamvan2", "slamvan3", "stalion", "stalion2", "tampa", "tulip", "vamos", "vigero",
    "virgo", "virgo2", "virgo3", "voodoo", "voodoo2", "yosemite", "yosemite2",
    
    -- Sports Classics
    "ardent", "btype", "btype2", "btype3", "casco", "cheburek", "cheetah2", "coquette2",
    "deluxo", "dynasty", "fagaloa", "feltzer3", "gt500", "infernus2", "jb700", "jb7002",
    "jester3", "mamba", "manana", "michelli", "monroe", "nebula", "peyote", "peyote3",
    "pigalle", "rapidgt3", "retinue", "retinue2", "savestra", "stinger", "stingergt",
    "stromberg", "swinger", "torero", "tornado", "tornado2", "tornado3", "tornado4",
    "tornado5", "tornado6", "turismo2", "viseris", "z190", "zion3", "ztype",
    
    -- Sports
    "alpha", "banshee", "bestiagts", "blista2", "blista3", "buffalo", "buffalo2",
    "buffalo3", "carbonizzare", "comet2", "comet3", "comet4", "comet5", "coquette",
    "coquette4", "drafter", "elegy", "elegy2", "feltzer2", "flashgt", "furoregt",
    "fusilade", "futo", "gb200", "hotring", "imorgon", "issi7", "italigto", "jester",
    "jester2", "jugular", "khamelion", "komoda", "kuruma", "kuruma2", "locust", "lynx",
    "massacro", "massacro2", "neo", "neon", "ninef", "ninef2", "omnis", "paragon",
    "paragon2", "pariah", "penumbra", "penumbra2", "raiden", "rapidgt", "rapidgt2",
    "revolter", "ruston", "schafter3", "schafter4", "schlagen", "schwarzer", "sentinel3",
    "seven70", "specter", "specter2", "sugoi", "sultan", "sultan2", "surano", "tampa2",
    "tropos", "verlierer2", "vstr", "zr380", "zr3802", "zr3803",
    
    -- Super
    "autarch", "banshee2", "bullet", "cheetah", "cyclone", "deveste", "emerus",
    "entityxf", "entity2", "fmj", "furia", "gp1", "infernus", "italigtb", "italigtb2",
    "krieger", "le7b", "nero", "nero2", "osiris", "penetrator", "pfister811",
    "prototipo", "reaper", "s80", "sc1", "scramjet", "sheava", "sultanrs", "t20",
    "taipan", "tempesta", "tezeract", "thrax", "tigon", "turismor", "tyrant", "tyrus",
    "vacca", "vagner", "vigilante", "visione", "voltic", "voltic2", "xa21", "zentorno",
    "zorrusso",
    
    -- Motorcycles
    "akuma", "avarus", "bagger", "bati", "bati2", "bf400", "carbonrs", "chimera",
    "cliffhanger", "daemon", "daemon2", "defiler", "diablous", "diablous2", "double",
    "enduro", "esskey", "faggio", "faggio2", "faggio3", "fcr", "fcr2", "gargoyle",
    "hakuchou", "hakuchou2", "hexer", "innovation", "lectro", "manchez", "nemesis",
    "nightblade", "oppressor", "oppressor2", "pcj", "ratbike", "rrocket", "ruffian",
    "sanchez", "sanchez2", "sanctus", "shotaro", "sovereign", "stryder", "thrust",
    "vader", "vindicator", "vortex", "wolfsbane", "zombiea", "zombieb",
    
    -- Off-Road
    "bfinjection", "bifta", "blazer", "blazer2", "blazer3", "blazer4", "blazer5",
    "bodhi2", "brawler", "caracara", "caracara2", "dloader", "dubsta3", "dune",
    "dune4", "everon", "freecrawler", "hellion", "insurgent", "insurgent2", "insurgent3",
    "kalahari", "kamacho", "marshall", "menacer", "mesa3", "monster", "monster2",
    "monster3", "nightshark", "outlaw", "rancherxl", "rancherxl2", "rcbandito",
    "rebel", "rebel2", "riata", "sandking", "sandking2", "technical", "technical2",
    "technical3", "trophytruck", "trophytruck2", "vargant", "yosemite3", "zhaba",
    
    -- Industrial
    "bulldozer", "cutter", "dump", "flatbed", "guardian", "handler", "mixer", "mixer2",
    "rubble", "tiptruck", "tiptruck2",
    
    -- Utility
    "airtug", "caddy", "caddy2", "caddy3", "docktug", "forklift", "tractor2", "tractor3",
    "mower", "ripley", "sadler", "sadler2", "scrap", "towtruck", "towtruck2", "tractor",
    "utillitruck", "utillitruck2", "utillitruck3",
    
    -- Vans
    "bison", "bison2", "bison3", "bobcatxl", "boxville", "boxville2", "boxville3",
    "boxville4", "burrito", "burrito2", "burrito3", "burrito4", "burrito5", "camper",
    "gburrito", "gburrito2", "journey", "minivan", "minivan2", "paradise", "pony",
    "pony2", "rumpo", "rumpo2", "rumpo3", "speedo", "speedo2", "speedo4", "surfer",
    "surfer2", "taco", "youga", "youga2", "youga3",
    
    -- Cycles
    "bmx", "cruiser", "fixter", "scorcher", "tribike", "tribike2", "tribike3",
    
    -- Boats
    "dinghy", "dinghy2", "dinghy3", "dinghy4", "jetmax", "marquis", "predator",
    "seashark", "seashark2", "seashark3", "speeder", "speeder2", "squalo",
    "submersible", "submersible2", "suntrap", "toro", "toro2", "tropic", "tropic2", "tug",
    
    -- Helicopters
    "akula", "annihilator", "buzzard", "buzzard2", "cargobob", "cargobob2", "cargobob3",
    "cargobob4", "frogger", "frogger2", "havok", "hunter", "maverick", "polmav",
    "savage", "seasparrow", "skylift", "supervolito", "supervolito2", "swift", "swift2",
    "valkyrie", "valkyrie2", "volatus",
    
    -- Planes
    "alphaz1", "avenger", "avenger2", "besra", "blimp", "blimp2", "blimp3", "bombushka",
    "cargoplane", "cuban800", "dodo", "duster", "howard", "hydra", "jet", "lazer",
    "luxor", "luxor2", "mammatus", "microlight", "miljet", "mogul", "molotok", "nimbus",
    "nokota", "pyro", "rogue", "seabreeze", "shamal", "starling", "strikeforce", "stunt",
    "titan", "tula", "velum", "velum2", "vestra", "volatol",
    
    -- Service
    "airbus", "brickade", "bus", "coach", "pbus2", "rallytruck", "rentalbus", "taxi",
    "tourbus", "trash", "trash2", "wastelander",
    
    -- Emergency
    "ambulance", "fbi", "fbi2", "firetruk", "lguard", "pbus", "police", "police2",
    "police3", "police4", "policeb", "policeold1", "policeold2", "policet", "pranger",
    "riot", "riot2", "sheriff", "sheriff2",
    
    -- Commercial
    "benson", "biff", "hauler", "hauler2", "mule", "mule2", "mule3", "mule4", "packer",
    "phantom", "phantom2", "phantom3", "pounder", "pounder2", "stockade", "stockade3",
    
    -- Trains
    "cablecar", "freight", "freightcar", "freightcont1", "freightcont2", "freightgrain",
    "metrotrain", "tankercar",
    
    -- Open Wheel
    "formula", "formula2", "openwheel1", "openwheel2"
}

-- Ped Whitelist (Valkyrie'den alınan kapsamlı liste)
local pedWhitelist = {
    -- Player models
    "player_one", "player_two", "player_zero", "mp_f_freemode_01", "mp_m_freemode_01",
    
    -- Animals
    "a_c_boar", "a_c_cat_01", "a_c_chickenhawk", "a_c_chimp", "a_c_cormorant", "a_c_cow",
    "a_c_coyote", "a_c_crow", "a_c_deer", "a_c_dolphin", "a_c_fish", "a_c_hen",
    "a_c_humpback", "a_c_husky", "a_c_killerwhale", "a_c_mtlion", "a_c_pig", "a_c_pigeon",
    "a_c_poodle", "a_c_pug", "a_c_rabbit_01", "a_c_rat", "a_c_retriever", "a_c_rhesus",
    "a_c_rottweiler", "a_c_seagull", "a_c_sharkhammer", "a_c_sharktiger", "a_c_shepherd",
    "a_c_westy",
    
    -- Male Adults
    "a_m_m_acult_01", "a_m_m_afriamer_01", "a_m_m_beach_01", "a_m_m_beach_02",
    "a_m_m_bevhills_01", "a_m_m_bevhills_02", "a_m_m_business_01", "a_m_m_eastsa_01",
    "a_m_m_eastsa_02", "a_m_m_farmer_01", "a_m_m_fatlatin_01", "a_m_m_genfat_01",
    "a_m_m_genfat_02", "a_m_m_golfer_01", "a_m_m_hasjew_01", "a_m_m_hillbilly_01",
    "a_m_m_hillbilly_02", "a_m_m_indian_01", "a_m_m_ktown_01", "a_m_m_malibu_01",
    "a_m_m_mexcntry_01", "a_m_m_mexlabor_01", "a_m_m_og_boss_01", "a_m_m_paparazzi_01",
    "a_m_m_polynesian_01", "a_m_m_prolhost_01", "a_m_m_rurmeth_01", "a_m_m_salton_01",
    "a_m_m_salton_02", "a_m_m_salton_03", "a_m_m_salton_04", "a_m_m_skater_01",
    "a_m_m_skidrow_01", "a_m_m_socenlat_01", "a_m_m_soucent_01", "a_m_m_soucent_02",
    "a_m_m_soucent_03", "a_m_m_soucent_04", "a_m_m_stlat_02", "a_m_m_tennis_01",
    "a_m_m_tourist_01", "a_m_m_trampbeac_01", "a_m_m_tramp_01", "a_m_m_tranvest_01",
    "a_m_m_tranvest_02",
    
    -- Male Old
    "a_m_o_acult_02", "a_m_o_beach_01", "a_m_o_genstreet_01", "a_m_o_ktown_01",
    "a_m_o_salton_01", "a_m_o_soucent_01", "a_m_o_soucent_02", "a_m_o_soucent_03",
    "a_m_o_tramp_01",
    
    -- Male Young
    "a_m_y_acult_01", "a_m_y_acult_02", "a_m_y_beachvesp_01", "a_m_y_beachvesp_02",
    "a_m_y_beach_01", "a_m_y_beach_02", "a_m_y_beach_03", "a_m_y_bevhills_01",
    "a_m_y_bevhills_02", "a_m_y_breakdance_01", "a_m_y_busicas_01", "a_m_y_business_01",
    "a_m_y_business_02", "a_m_y_business_03", "a_m_y_cyclist_01", "a_m_y_dhill_01",
    "a_m_y_downtown_01", "a_m_y_eastsa_01", "a_m_y_eastsa_02", "a_m_y_epsilon_01",
    "a_m_y_epsilon_02", "a_m_y_gay_01", "a_m_y_gay_02", "a_m_y_genstreet_01",
    "a_m_y_genstreet_02", "a_m_y_golfer_01", "a_m_y_hasjew_01", "a_m_y_hiker_01",
    "a_m_y_hippy_01", "a_m_y_hipster_01", "a_m_y_hipster_02", "a_m_y_hipster_03",
    "a_m_y_indian_01", "a_m_y_jetski_01", "a_m_y_juggalo_01", "a_m_y_ktown_01",
    "a_m_y_ktown_02", "a_m_y_latino_01", "a_m_y_methhead_01", "a_m_y_mexthug_01",
    "a_m_y_motox_01", "a_m_y_motox_02", "a_m_y_musclbeac_01", "a_m_y_musclbeac_02",
    "a_m_y_polynesian_01", "a_m_y_roadcyc_01", "a_m_y_runner_01", "a_m_y_runner_02",
    "a_m_y_salton_01", "a_m_y_skater_01", "a_m_y_skater_02", "a_m_y_soucent_01",
    "a_m_y_soucent_02", "a_m_y_soucent_03", "a_m_y_soucent_04", "a_m_y_stbla_01",
    "a_m_y_stbla_02", "a_m_y_stlat_01", "a_m_y_stwhi_01", "a_m_y_stwhi_02",
    "a_m_y_sunbathe_01", "a_m_y_surfer_01", "a_m_y_vindouche_01", "a_m_y_vinewood_01",
    "a_m_y_vinewood_02", "a_m_y_vinewood_03", "a_m_y_vinewood_04", "a_m_y_yoga_01",
    
    -- Female Adults
    "a_f_m_beach_01", "a_f_m_bevhills_01", "a_f_m_bevhills_02", "a_f_m_bodybuild_01",
    "a_f_m_business_02", "a_f_m_downtown_01", "a_f_m_eastsa_01", "a_f_m_eastsa_02",
    "a_f_m_fatbla_01", "a_f_m_fatcult_01", "a_f_m_fatwhite_01", "a_f_m_ktown_01",
    "a_f_m_ktown_02", "a_f_m_prolhost_01", "a_f_m_salton_01", "a_f_m_skidrow_01",
    "a_f_m_soucentmc_01", "a_f_m_soucent_01", "a_f_m_soucent_02", "a_f_m_tourist_01",
    "a_f_m_trampbeac_01", "a_f_m_tramp_01",
    
    -- Female Old
    "a_f_o_genstreet_01", "a_f_o_indian_01", "a_f_o_ktown_01", "a_f_o_salton_01",
    "a_f_o_soucent_01", "a_f_o_soucent_02",
    
    -- Female Young
    "a_f_y_beach_01", "a_f_y_bevhills_01", "a_f_y_bevhills_02", "a_f_y_bevhills_03",
    "a_f_y_bevhills_04", "a_f_y_business_01", "a_f_y_business_02", "a_f_y_business_03",
    "a_f_y_business_04", "a_f_y_eastsa_01", "a_f_y_eastsa_02", "a_f_y_eastsa_03",
    "a_f_y_epsilon_01", "a_f_y_fitness_01", "a_f_y_fitness_02", "a_f_y_genhot_01",
    "a_f_y_golfer_01", "a_f_y_hiker_01", "a_f_y_hippie_01", "a_f_y_hipster_01",
    "a_f_y_hipster_02", "a_f_y_hipster_03", "a_f_y_hipster_04", "a_f_y_indian_01",
    "a_f_y_juggalo_01", "a_f_y_runner_01", "a_f_y_rurmeth_01", "a_f_y_scdressy_01",
    "a_f_y_skater_01", "a_f_y_soucent_01", "a_f_y_soucent_02", "a_f_y_soucent_03",
    "a_f_y_tennis_01", "a_f_y_topless_01", "a_f_y_tourist_01", "a_f_y_tourist_02",
    "a_f_y_vinewood_01", "a_f_y_vinewood_02", "a_f_y_vinewood_03", "a_f_y_vinewood_04",
    "a_f_y_yoga_01"
}

-- Object Blacklist (Tehlikeli objeler)
local objectBlacklist = {
    -- Explosion objects
    "prop_bomb_01", "prop_bomb_02", "prop_bomb_03", "prop_explosive_01", "prop_explosive_02",
    "prop_gas_tank_01", "prop_gas_tank_02", "prop_propane_tank_01", "prop_propane_tank_02",
    
    -- Weapon objects
    "prop_gun_case_01", "prop_gun_case_02", "prop_minigun_01", "prop_rpg_01",
    "prop_launcher_01", "prop_grenade_01", "prop_molotov_01",
    
    -- Large/Problematic objects
    "prop_container_01a", "prop_container_01b", "prop_container_01c", "prop_container_01d",
    "prop_container_01e", "prop_container_01f", "prop_container_01g", "prop_container_01h",
    "prop_building_01", "prop_building_02", "prop_building_03", "prop_skyscraper_01",
    
    -- Invisible/Collision objects
    "prop_invis_base_01", "prop_collision_01", "prop_collision_02", "prop_barrier_work_01",
    "prop_barrier_work_02", "prop_barrier_work_03", "prop_barrier_work_04", "prop_barrier_work_05",
    
    -- Money/Cash objects
    "prop_cash_pile_01", "prop_cash_pile_02", "prop_money_bag_01", "prop_money_bag_02",
    "prop_gold_bar_01", "prop_gold_cont_01", "prop_diamond_01",
    
    -- Admin/Debug objects
    "prop_debug_01", "prop_debug_02", "prop_admin_01", "prop_test_01", "prop_test_02"
}

-- Weapon Blacklist (Yasak silahlar)
local weaponBlacklist = {
    -- Heavy Weapons
    "WEAPON_RPG", "WEAPON_GRENADELAUNCHER", "WEAPON_GRENADELAUNCHER_SMOKE",
    "WEAPON_MINIGUN", "WEAPON_FIREWORK", "WEAPON_RAILGUN", "WEAPON_HOMINGLAUNCHER",
    "WEAPON_COMPACTLAUNCHER", "WEAPON_RAYMINIGUN", "WEAPON_EMPLAUNCHER",
    
    -- Explosives
    "WEAPON_GRENADE", "WEAPON_BZGAS", "WEAPON_MOLOTOV", "WEAPON_STICKYBOMB",
    "WEAPON_PROXMINE", "WEAPON_SNOWBALL", "WEAPON_PIPEBOMB", "WEAPON_BALL",
    "WEAPON_SMOKEGRENADE", "WEAPON_FLARE",
    
    -- Special/Modded Weapons
    "WEAPON_RAYPISTOL", "WEAPON_RAYCARBINE", "WEAPON_RAYGUN", "WEAPON_DIGISCANNER",
    "WEAPON_GARBAGEBAG", "WEAPON_HAZARDCAN", "WEAPON_FERTILIZERCAN", "WEAPON_FIREEXTINGUISHER",
    
    -- Admin/Debug Weapons
    "WEAPON_ADMINGUN", "WEAPON_DEBUGGUN", "WEAPON_TESTGUN", "WEAPON_MODGUN"
}

-- =============================================
-- ENTITY VALIDATION BAŞLATMA
-- =============================================

function FiveguardServer.EntityValidation.Initialize()
    print('^2[FIVEGUARD ENTITY VALIDATION]^7 Entity Validation System başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardServer.EntityValidation.LoadConfig()
    
    -- Event'leri kaydet
    FiveguardServer.EntityValidation.RegisterEvents()
    
    -- Entity monitoring'i başlat
    FiveguardServer.EntityValidation.StartEntityMonitoring()
    
    -- Cleanup thread'ini başlat
    FiveguardServer.EntityValidation.StartCleanup()
    
    entityData.isActive = true
    print('^2[FIVEGUARD ENTITY VALIDATION]^7 Entity Validation System hazır')
end

-- Konfigürasyonu yükle
function FiveguardServer.EntityValidation.LoadConfig()
    local config = FiveguardServer.Config.Modules.EntityValidation or {}
    
    -- Ana ayarları yükle
    entityData.config.enabled = config.enabled ~= nil and config.enabled or entityData.config.enabled
    
    -- Validation types'ları yükle
    if config.validationTypes then
        for key, value in pairs(config.validationTypes) do
            if entityData.config[key] ~= nil then
                entityData.config[key] = value
            end
        end
    end
    
    -- Limits'leri yükle
    if config.limits then
        entityData.config.maxEntitiesPerPlayer = config.limits.maxEntitiesPerPlayer or entityData.config.maxEntitiesPerPlayer
        entityData.config.entityCreationCooldown = config.limits.entityCreationCooldown or entityData.config.entityCreationCooldown
        entityData.config.maxVehiclesPerPlayer = config.limits.maxVehiclesPerPlayer or entityData.config.maxVehiclesPerPlayer
        entityData.config.maxPedsPerPlayer = config.limits.maxPedsPerPlayer or entityData.config.maxPedsPerPlayer
        entityData.config.maxObjectsPerPlayer = config.limits.maxObjectsPerPlayer or entityData.config.maxObjectsPerPlayer
    end
    
    -- Validation mode'u yükle
    if config.validationMode then
        entityData.config.whitelistMode = config.validationMode.whitelistMode ~= nil and config.validationMode.whitelistMode or entityData.config.whitelistMode
        entityData.config.autoDeleteIllegal = config.validationMode.autoDeleteIllegal ~= nil and config.validationMode.autoDeleteIllegal or entityData.config.autoDeleteIllegal
    end
    
    -- Auto actions'ları yükle
    if config.autoActions then
        entityData.config.autoActionEnabled = config.autoActions.autoActionEnabled ~= nil and config.autoActions.autoActionEnabled or entityData.config.autoActionEnabled
        entityData.config.banDuration = config.autoActions.banDuration or entityData.config.banDuration
    end
    
    -- Config'den whitelist/blacklist'leri yükle
    if FiveguardServer.Config.Lists then
        if FiveguardServer.Config.Lists.VehicleWhitelist then
            entityData.vehicleWhitelist = FiveguardServer.Config.Lists.VehicleWhitelist
        end
        if FiveguardServer.Config.Lists.PedWhitelist then
            entityData.pedWhitelist = FiveguardServer.Config.Lists.PedWhitelist
        end
        if FiveguardServer.Config.Lists.ObjectBlacklist then
            entityData.objectBlacklist = FiveguardServer.Config.Lists.ObjectBlacklist
        end
    end
    
    print('^2[FIVEGUARD ENTITY VALIDATION]^7 Config yüklendi - Enabled: ' .. tostring(entityData.config.enabled))
end

-- Event'leri kaydet
function FiveguardServer.EntityValidation.RegisterEvents()
    -- Entity creation events
    AddEventHandler('entityCreating', function(entity)
        local playerId = NetworkGetEntityOwner(entity)
        if not FiveguardServer.EntityValidation.ValidateEntityCreation(entity, playerId) then
            CancelEvent()
        end
    end)
    
    -- Entity created event
    AddEventHandler('entityCreated', function(entity)
        local playerId = NetworkGetEntityOwner(entity)
        FiveguardServer.EntityValidation.RegisterEntityCreation(entity, playerId)
    end)
    
    -- Entity removing event
    AddEventHandler('entityRemoved', function(entity)
        FiveguardServer.EntityValidation.UnregisterEntity(entity)
    end)
    
    -- Player dropped event
    AddEventHandler('playerDropped', function(reason)
        local playerId = source
        FiveguardServer.EntityValidation.CleanupPlayerEntities(playerId)
    end)
end

-- =============================================
-- ENTITY CREATION VALIDATION
-- =============================================

-- Entity creation'ı validate et
function FiveguardServer.EntityValidation.ValidateEntityCreation(entity, playerId)
    local player = FiveguardServer.Players[playerId]
    if not player then return false end
    
    local entityType = GetEntityType(entity)
    local entityModel = GetEntityModel(entity)
    local modelName = GetEntityArchetypeName(entity) or 'unknown'
    
    -- Entity creation cooldown kontrolü
    if not FiveguardServer.EntityValidation.CheckCreationCooldown(playerId) then
        FiveguardServer.EntityValidation.HandleViolation(playerId, 'creation_cooldown', {
            entityType = entityType,
            modelName = modelName
        })
        return false
    end
    
    -- Entity limit kontrolü
    if not FiveguardServer.EntityValidation.CheckEntityLimit(playerId) then
        FiveguardServer.EntityValidation.HandleViolation(playerId, 'entity_limit', {
            entityType = entityType,
            modelName = modelName
        })
        return false
    end
    
    -- Entity type'a göre validation
    if entityType == 1 then -- Ped
        return FiveguardServer.EntityValidation.ValidatePed(modelName, playerId)
    elseif entityType == 2 then -- Vehicle
        return FiveguardServer.EntityValidation.ValidateVehicle(modelName, playerId)
    elseif entityType == 3 then -- Object
        return FiveguardServer.EntityValidation.ValidateObject(modelName, playerId)
    end
    
    return true
end

-- Creation cooldown kontrolü
function FiveguardServer.EntityValidation.CheckCreationCooldown(playerId)
    local currentTime = GetGameTimer()
    
    if not entityData.entityCreations[playerId] then
        entityData.entityCreations[playerId] = {}
    end
    
    local lastCreation = entityData.entityCreations[playerId].lastCreation or 0
    
    if (currentTime - lastCreation) < entityData.config.entityCreationCooldown then
        return false
    end
    
    entityData.entityCreations[playerId].lastCreation = currentTime
    return true
end

-- Entity limit kontrolü
function FiveguardServer.EntityValidation.CheckEntityLimit(playerId)
    if not entityData.entityCreations[playerId] then
        entityData.entityCreations[playerId] = {count = 0}
    end
    
    return entityData.entityCreations[playerId].count < entityData.config.maxEntitiesPerPlayer
end

-- =============================================
-- ENTITY TYPE VALIDATION
-- =============================================

-- Vehicle validation
function FiveguardServer.EntityValidation.ValidateVehicle(modelName, playerId)
    if not entityData.config.enableVehicleValidation then
        return true
    end
    
    entityData.stats.totalValidations = entityData.stats.totalValidations + 1
    
    if entityData.config.whitelistMode then
        -- Whitelist mode - sadece listedeki araçlar
        local isWhitelisted = false
        for _, whitelistedModel in ipairs(vehicleWhitelist) do
            if string.lower(modelName) == string.lower(whitelistedModel) then
                isWhitelisted = true
                break
            end
        end
        
        if not isWhitelisted then
            FiveguardServer.EntityValidation.HandleViolation(playerId, 'illegal_vehicle', {
                modelName = modelName,
                reason = 'not_whitelisted'
            })
            entityData.stats.illegalVehicles = entityData.stats.illegalVehicles + 1
            return false
        end
    end
    
    return true
end

-- Ped validation
function FiveguardServer.EntityValidation.ValidatePed(modelName, playerId)
    if not entityData.config.enablePedValidation then
        return true
    end
    
    entityData.stats.totalValidations = entityData.stats.totalValidations + 1
    
    if entityData.config.whitelistMode then
        -- Whitelist mode - sadece listedeki ped'ler
        local isWhitelisted = false
        for _, whitelistedModel in ipairs(pedWhitelist) do
            if string.lower(modelName) == string.lower(whitelistedModel) then
                isWhitelisted = true
                break
            end
        end
        
        if not isWhitelisted then
            FiveguardServer.EntityValidation.HandleViolation(playerId, 'illegal_ped', {
                modelName = modelName,
                reason = 'not_whitelisted'
            })
            entityData.stats.illegalPeds = entityData.stats.illegalPeds + 1
            return false
        end
    end
    
    return true
end

-- Object validation
function FiveguardServer.EntityValidation.ValidateObject(modelName, playerId)
    if not entityData.config.enableObjectValidation then
        return true
    end
    
    entityData.stats.totalValidations = entityData.stats.totalValidations + 1
    
    -- Blacklist kontrolü (objeler için blacklist kullanıyoruz)
    for _, blacklistedModel in ipairs(objectBlacklist) do
        if string.lower(modelName) == string.lower(blacklistedModel) then
            FiveguardServer.EntityValidation.HandleViolation(playerId, 'illegal_object', {
                modelName = modelName,
                reason = 'blacklisted'
            })
            entityData.stats.illegalObjects = entityData.stats.illegalObjects + 1
            return false
        end
    end
    
    return true
end

-- Weapon validation
function FiveguardServer.EntityValidation.ValidateWeapon(weaponHash, playerId)
    if not entityData.config.enableWeaponValidation then
        return true
    end
    
    entityData.stats.totalValidations = entityData.stats.totalValidations + 1
    
    -- Weapon hash'i string'e çevir
    local weaponName = GetWeapontypeModel(weaponHash) or 'unknown'
    
    -- Blacklist kontrolü
    for _, blacklistedWeapon in ipairs(weaponBlacklist) do
        if string.upper(weaponName) == string.upper(blacklistedWeapon) then
            FiveguardServer.EntityValidation.HandleViolation(playerId, 'illegal_weapon', {
                weaponName = weaponName,
                weaponHash = weaponHash,
                reason = 'blacklisted'
            })
            entityData.stats.illegalWeapons = entityData.stats.illegalWeapons + 1
            return false
        end
    end
    
    return true
end

-- =============================================
-- ENTITY REGISTRATION
-- =============================================

-- Entity creation'ı kaydet
function FiveguardServer.EntityValidation.RegisterEntityCreation(entity, playerId)
    if not entityData.entityCreations[playerId] then
        entityData.entityCreations[playerId] = {count = 0, entities = {}}
    end
    
    entityData.entityCreations[playerId].count = entityData.entityCreations[playerId].count + 1
    entityData.entityCreations[playerId].entities[entity] = {
        entityType = GetEntityType(entity),
        modelName = GetEntityArchetypeName(entity) or 'unknown',
        createdAt = os.time()
    }
    
    entityData.validatedEntities[entity] = {
        playerId = playerId,
        entityType = GetEntityType(entity),
        modelName = GetEntityArchetypeName(entity) or 'unknown',
        createdAt = os.time()
    }
end

-- Entity'yi kayıttan çıkar
function FiveguardServer.EntityValidation.UnregisterEntity(entity)
    if entityData.validatedEntities[entity] then
        local playerId = entityData.validatedEntities[entity].playerId
        
        if entityData.entityCreations[playerId] and entityData.entityCreations[playerId].entities[entity] then
            entityData.entityCreations[playerId].count = entityData.entityCreations[playerId].count - 1
            entityData.entityCreations[playerId].entities[entity] = nil
        end
        
        entityData.validatedEntities[entity] = nil
    end
end

-- Player entity'lerini temizle
function FiveguardServer.EntityValidation.CleanupPlayerEntities(playerId)
    if entityData.entityCreations[playerId] then
        -- Player'ın tüm entity'lerini sil
        for entity, _ in pairs(entityData.entityCreations[playerId].entities) do
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
                entityData.stats.entitiesDeleted = entityData.stats.entitiesDeleted + 1
            end
            entityData.validatedEntities[entity] = nil
        end
        
        entityData.entityCreations[playerId] = nil
    end
end

-- =============================================
-- ENTITY MONITORING
-- =============================================

-- Entity monitoring'i başlat
function FiveguardServer.EntityValidation.StartEntityMonitoring()
    CreateThread(function()
        while entityData.isActive do
            Wait(30000) -- 30 saniye bekle
            
            -- Tüm entity'leri kontrol et
            FiveguardServer.EntityValidation.MonitorEntities()
        end
    end)
end

-- Entity'leri monitör et
function FiveguardServer.EntityValidation.MonitorEntities()
    -- Registered entity'leri kontrol et
    for entity, entityInfo in pairs(entityData.validatedEntities) do
        if not DoesEntityExist(entity) then
            -- Entity artık yok, kayıttan çıkar
            FiveguardServer.EntityValidation.UnregisterEntity(entity)
        else
            -- Entity hala var, suspicious activity kontrolü
            if FiveguardServer.EntityValidation.IsSuspiciousEntity(entity, entityInfo) then
                FiveguardServer.EntityValidation.HandleSuspiciousEntity(entity, entityInfo)
            end
        end
    end
end

-- Suspicious entity kontrolü
function FiveguardServer.EntityValidation.IsSuspiciousEntity(entity, entityInfo)
    -- Entity çok uzun süredir var mı?
    local currentTime = os.time()
    local entityAge = currentTime - entityInfo.createdAt
    
    if entityAge > 3600 then -- 1 saat
        return true
    end
    
    -- Entity owner hala online mı?
    local playerId = entityInfo.playerId
    if not GetPlayerName(playerId) then
        return true -- Player offline
    end
    
    return false
end

-- Suspicious entity'yi işle
function FiveguardServer.EntityValidation.HandleSuspiciousEntity(entity, entityInfo)
    -- Suspicious entity'lere ekle
    if not entityData.suspiciousEntities[entityInfo.playerId] then
        entityData.suspiciousEntities[entityInfo.playerId] = {}
    end
    
    table.insert(entityData.suspiciousEntities[entityInfo.playerId], {
        entity = entity,
        entityInfo = entityInfo,
        detectedAt = os.time()
    })
    
    -- Auto delete aktifse entity'yi sil
    if entityData.config.autoDeleteIllegal then
        DeleteEntity(entity)
        entityData.stats.entitiesDeleted = entityData.stats.entitiesDeleted + 1
        FiveguardServer.EntityValidation.UnregisterEntity(entity)
        
        print('^3[FIVEGUARD ENTITY VALIDATION]^7 Suspicious entity silindi: ' .. entityInfo.modelName)
    end
end

-- =============================================
-- VIOLATION HANDLING
-- =============================================

-- Violation'ı işle
function FiveguardServer.EntityValidation.HandleViolation(playerId, violationType, details)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = violationType,
        details = details,
        timestamp = os.time(),
        severity = FiveguardServer.EntityValidation.GetViolationSeverity(violationType)
    }
    
    -- İstatistikleri güncelle
    entityData.stats.lastDetection = os.time()
    
    -- Detection'ı işle
    FiveguardServer.EntityValidation.ProcessDetection(detection)
    
    print('^1[FIVEGUARD ENTITY VALIDATION]^7 Entity violation: ' .. player.name .. 
          ' (' .. violationType .. ' - ' .. (details.modelName or 'unknown') .. ')')
end

-- Violation severity'sini getir
function FiveguardServer.EntityValidation.GetViolationSeverity(violationType)
    local severityMap = {
        creation_cooldown = 'medium',
        entity_limit = 'high',
        illegal_vehicle = 'high',
        illegal_ped = 'medium',
        illegal_object = 'high',
        illegal_weapon = 'critical'
    }
    
    return severityMap[violationType] or 'medium'
end

-- Detection'ı işle
function FiveguardServer.EntityValidation.ProcessDetection(detection)
    -- Severity'ye göre işlem yap
    FiveguardServer.EntityValidation.HandleDetectionSeverity(detection)
    
    -- Veritabanına kaydet
    FiveguardServer.EntityValidation.SaveDetectionToDatabase(detection)
    
    -- Webhook gönder
    FiveguardServer.EntityValidation.SendDetectionWebhook(detection)
    
    -- Protection Manager'a bildir
    if FiveguardServer.ProtectionManager then
        FiveguardServer.ProtectionManager.RecordDetection('entity_validation', {
            type = detection.type,
            severity = detection.severity,
            playerId = detection.playerId,
            timestamp = detection.timestamp
        })
    end
end

-- Detection severity'sini işle
function FiveguardServer.EntityValidation.HandleDetectionSeverity(detection)
    if not entityData.config.autoActionEnabled then
        return
    end
    
    local playerId = detection.playerId
    
    if detection.severity == 'critical' then
        -- Kritik seviye - Ban
        FiveguardServer.EntityValidation.BanPlayer(playerId, 'Entity validation violation: ' .. detection.type)
        
    elseif detection.severity == 'high' then
        -- Yüksek seviye - Kick
        FiveguardServer.EntityValidation.KickPlayer(playerId, 'Illegal entity detected')
        
    elseif detection.severity == 'medium' then
        -- Orta seviye - Uyarı
        FiveguardServer.EntityValidation.WarnPlayer(playerId, 'Entity validation warning')
    end
end

-- Oyuncuyu banla
function FiveguardServer.EntityValidation.BanPlayer(playerId, reason)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Ban kaydı
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_bans (player_id, player_name, reason, ban_type, timestamp, expires_at, active) VALUES (?, ?, ?, ?, ?, ?, 1)', {
        playerId,
        player.name,
        reason,
        'entity_validation',
        os.time(),
        os.time() + (7 * 24 * 3600) -- 7 gün
    })
    
    -- Player entity'lerini temizle
    FiveguardServer.EntityValidation.CleanupPlayerEntities(playerId)
    
    -- Oyuncuyu at
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
    
    print('^1[FIVEGUARD ENTITY VALIDATION]^7 Oyuncu banlandı: ' .. player.name .. ' (Sebep: ' .. reason .. ')')
end

-- Oyuncuyu uyar
function FiveguardServer.EntityValidation.WarnPlayer(playerId, reason)
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {255, 165, 0},
        multiline = true,
        args = {'FIVEGUARD UYARI', reason}
    })
end

-- Oyuncuyu at
function FiveguardServer.EntityValidation.KickPlayer(playerId, reason)
    -- Player entity'lerini temizle
    FiveguardServer.EntityValidation.CleanupPlayerEntities(playerId)
    
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
end

-- =============================================
-- CLEANUP
-- =============================================

-- Cleanup thread'ini başlat
function FiveguardServer.EntityValidation.StartCleanup()
    CreateThread(function()
        while entityData.isActive do
            Wait(300000) -- 5 dakika bekle
            
            -- Eski suspicious entity'leri temizle
            FiveguardServer.EntityValidation.CleanupSuspiciousEntities()
            
            -- Orphaned entity'leri temizle
            FiveguardServer.EntityValidation.CleanupOrphanedEntities()
        end
    end)
end

-- Eski suspicious entity'leri temizle
function FiveguardServer.EntityValidation.CleanupSuspiciousEntities()
    local currentTime = os.time()
    local cleanupThreshold = currentTime - 1800 -- 30 dakika önce
    
    for playerId, suspiciousEntities in pairs(entityData.suspiciousEntities) do
        local filteredEntities = {}
        for _, suspiciousEntity in ipairs(suspiciousEntities) do
            if suspiciousEntity.detectedAt > cleanupThreshold then
                table.insert(filteredEntities, suspiciousEntity)
            end
        end
        entityData.suspiciousEntities[playerId] = filteredEntities
    end
end

-- Orphaned entity'leri temizle
function FiveguardServer.EntityValidation.CleanupOrphanedEntities()
    for entity, entityInfo in pairs(entityData.validatedEntities) do
        local playerId = entityInfo.playerId
        
        -- Player offline mı?
        if not GetPlayerName(playerId) then
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
                entityData.stats.entitiesDeleted = entityData.stats.entitiesDeleted + 1
            end
            FiveguardServer.EntityValidation.UnregisterEntity(entity)
        end
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Detection'ı veritabanına kaydet
function FiveguardServer.EntityValidation.SaveDetectionToDatabase(detection)
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_entity_detections (player_id, player_name, detection_type, detection_data, severity, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
        detection.playerId,
        detection.playerName,
        detection.type,
        json.encode(detection),
        detection.severity,
        detection.timestamp
    })
end

-- Detection webhook'u gönder
function FiveguardServer.EntityValidation.SendDetectionWebhook(detection)
    local color = 16711680 -- Kırmızı
    if detection.severity == 'high' then
        color = 16776960 -- Sarı
    elseif detection.severity == 'medium' then
        color = 16753920 -- Turuncu
    end
    
    local webhookData = {
        username = 'Fiveguard Entity Validation',
        avatar_url = 'https://i.imgur.com/fiveguard-logo.png',
        embeds = {{
            title = '🚗 Entity Validation Tespit Edildi!',
            color = color,
            fields = {
                {name = 'Oyuncu', value = detection.playerName, inline = true},
                {name = 'Violation Türü', value = detection.type, inline = true},
                {name = 'Severity', value = detection.severity, inline = true},
                {name = 'Detaylar', value = FiveguardServer.EntityValidation.FormatDetectionDetails(detection), inline = false},
                {name = 'Zaman', value = os.date('%Y-%m-%d %H:%M:%S', detection.timestamp), inline = true}
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', detection.timestamp)
        }}
    }
    
    FiveguardServer.Webhook.Send('entity_validation', webhookData)
end

-- Detection detaylarını formatla
function FiveguardServer.EntityValidation.FormatDetectionDetails(detection)
    local details = detection.details or {}
    
    if detection.type == 'illegal_vehicle' then
        return 'Vehicle: ' .. (details.modelName or 'unknown') .. ' (Reason: ' .. (details.reason or 'unknown') .. ')'
    elseif detection.type == 'illegal_ped' then
        return 'Ped: ' .. (details.modelName or 'unknown') .. ' (Reason: ' .. (details.reason or 'unknown') .. ')'
    elseif detection.type == 'illegal_object' then
        return 'Object: ' .. (details.modelName or 'unknown') .. ' (Reason: ' .. (details.reason or 'unknown') .. ')'
    elseif detection.type == 'illegal_weapon' then
        return 'Weapon: ' .. (details.weaponName or 'unknown') .. ' (Hash: ' .. (details.weaponHash or 'unknown') .. ')'
    elseif detection.type == 'entity_limit' then
        return 'Entity limit exceeded for: ' .. (details.modelName or 'unknown')
    elseif detection.type == 'creation_cooldown' then
        return 'Creation cooldown violation for: ' .. (details.modelName or 'unknown')
    else
        return 'Entity validation violation'
    end
end

-- İstatistikleri getir
function FiveguardServer.EntityValidation.GetStats()
    return {
        totalValidations = entityData.stats.totalValidations,
        illegalVehicles = entityData.stats.illegalVehicles,
        illegalPeds = entityData.stats.illegalPeds,
        illegalObjects = entityData.stats.illegalObjects,
        illegalWeapons = entityData.stats.illegalWeapons,
        entitiesDeleted = entityData.stats.entitiesDeleted,
        lastDetection = entityData.stats.lastDetection,
        isActive = entityData.isActive,
        totalEntities = FiveguardServer.EntityValidation.GetTotalEntityCount(),
        suspiciousEntities = FiveguardServer.EntityValidation.GetSuspiciousEntityCount()
    }
end

-- Toplam entity sayısını getir
function FiveguardServer.EntityValidation.GetTotalEntityCount()
    local count = 0
    for _ in pairs(entityData.validatedEntities) do
        count = count + 1
    end
    return count
end

-- Suspicious entity sayısını getir
function FiveguardServer.EntityValidation.GetSuspiciousEntityCount()
    local count = 0
    for _, suspiciousEntities in pairs(entityData.suspiciousEntities) do
        count = count + #suspiciousEntities
    end
    return count
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Entity validation istatistiklerini getir
function GetEntityValidationStats()
    return FiveguardServer.EntityValidation.GetStats()
end

-- Entity validation durumunu kontrol et
function IsEntityValidationActive()
    return entityData.isActive
end

-- Manuel entity validation
function ValidateEntityManual(entity)
    local playerId = NetworkGetEntityOwner(entity)
    return FiveguardServer.EntityValidation.ValidateEntityCreation(entity, playerId)
end

-- Player entity'lerini getir
function GetPlayerEntities(playerId)
    if entityData.entityCreations[playerId] then
        return entityData.entityCreations[playerId].entities
    end
    return {}
end

-- Entity'yi force delete et
function ForceDeleteEntity(entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        FiveguardServer.EntityValidation.UnregisterEntity(entity)
        entityData.stats.entitiesDeleted = entityData.stats.entitiesDeleted + 1
        return true
    end
    return false
end

-- Weapon validation (export)
function ValidatePlayerWeapon(playerId, weaponHash)
    return FiveguardServer.EntityValidation.ValidateWeapon(weaponHash, playerId)
end

print('^2[FIVEGUARD ENTITY VALIDATION]^7 Entity Validation System modülü yüklendi')
