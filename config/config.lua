-- FIVEGUARD CONFIGURATION
-- AI Destekli FiveM Anti-Cheat Sistemi

Config = {}

-- =============================================
-- GENEL AYARLAR
-- =============================================

Config.Debug = true -- Debug modunu etkinleştir
Config.Locale = 'tr' -- Dil ayarı (tr, en, de, fr, es, it, ru, ja, ko, ar)
Config.Version = '1.0.0'
Config.ResourceName = 'fiveguard'

-- =============================================
-- LİSANS VE KİMLİK DOĞRULAMA
-- =============================================

Config.License = {
    Key = 'FIVEGUARD-DEMO-LICENSE-KEY-2024', -- Lisans anahtarı
    ServerName = 'Demo Server',
    MaxPlayers = 128,
    CheckInterval = 300000, -- 5 dakika (milisaniye)
    ApiUrl = 'https://api.fiveguard.com/v1/license/verify'
}

-- =============================================
-- VERİTABANI AYARLARI
-- =============================================

Config.Database = {
    Type = 'mysql', -- mysql, sqlite
    Host = 'localhost',
    Port = 3306,
    Database = 'fiveguard_db',
    Username = 'root',
    Password = '',
    Charset = 'utf8mb4',
    ConnectionLimit = 10
}

-- =============================================
-- ANTI-CHEAT GENEL AYARLARI
-- =============================================

Config.AntiCheat = {
    Enabled = true,
    AutoBan = true, -- Otomatik ban sistemi
    MaxWarnings = 3, -- Maksimum uyarı sayısı
    BanDuration = 86400, -- Ban süresi (saniye) - 24 saat
    WhitelistBypass = true, -- Whitelist'teki oyuncular bypass olsun mu?
    
    -- AI Güven Skoru Eşikleri
    TrustScore = {
        MinScore = 0.0,
        MaxScore = 10.0,
        DefaultScore = 5.0,
        CriticalThreshold = 2.0, -- Bu skorun altındakiler otomatik ban
        SuspiciousThreshold = 3.5 -- Bu skorun altındakiler yakın takip
    },
    
    -- Tespit Güven Eşikleri (0-100)
    ConfidenceThresholds = {
        Low = 60.0,
        Medium = 75.0,
        High = 85.0,
        Critical = 95.0
    }
}

-- =============================================
-- GODMODE KORUMA
-- =============================================

Config.GodMode = {
    Enabled = true,
    CheckInterval = 2000, -- 2 saniye
    MaxHealth = 200,
    MaxArmor = 100,
    AllowedDamageReduction = 0.1, -- %10 hasar azaltma toleransı
    InstantBan = false, -- Anında ban mı yoksa uyarı mı?
    LogLevel = 'high'
}

-- =============================================
-- SPEEDHACK KORUMA
-- =============================================

Config.SpeedHack = {
    Enabled = true,
    CheckInterval = 1000, -- 1 saniye
    
    -- Hız limitleri
    Limits = {
        OnFoot = 8.0, -- Yürüme hızı
        Swimming = 3.0, -- Yüzme hızı
        Vehicle = {
            Car = 150.0, -- Araba hızı (mph)
            Bike = 120.0, -- Motosiklet hızı
            Boat = 80.0, -- Tekne hızı
            Plane = 300.0, -- Uçak hızı
            Helicopter = 200.0 -- Helikopter hızı
        }
    },
    
    -- Tolerans ayarları
    Tolerance = 1.2, -- %20 tolerans
    MaxViolations = 5, -- Maksimum ihlal sayısı
    ViolationResetTime = 30000, -- 30 saniye sonra ihlaller sıfırlanır
    InstantBan = false
}

-- =============================================
-- TELEPORT KORUMA
-- =============================================

Config.Teleport = {
    Enabled = true,
    CheckInterval = 500, -- 0.5 saniye
    MaxDistance = 50.0, -- Maksimum anlık hareket mesafesi (metre)
    AllowedTeleports = {
        'hospital', 'garage', 'spawn'
    },
    IgnoreVehicles = true, -- Araç içindeyken kontrol etme
    MaxViolations = 3,
    InstantBan = true -- Teleport için anında ban
}

-- =============================================
-- SİLAH KORUMA
-- =============================================

Config.Weapon = {
    Enabled = true,
    
    -- Yasaklı silahlar
    BlacklistedWeapons = {
        'WEAPON_RAILGUN',
        'WEAPON_MINIGUN',
        'WEAPON_RPG',
        'WEAPON_GRENADELAUNCHER',
        'WEAPON_STINGER'
    },
    
    -- Hasar modifikasyonu kontrolü
    DamageModifier = {
        Enabled = true,
        MaxMultiplier = 1.5, -- Maksimum %50 hasar artışı
        CheckInterval = 1000
    },
    
    -- Aimbot tespiti
    Aimbot = {
        Enabled = true,
        MaxAccuracy = 95.0, -- %95 üzeri isabet oranı şüpheli
        CheckInterval = 5000,
        MinShotsForCheck = 10 -- En az 10 atış sonrası kontrol
    }
}

-- =============================================
-- PARA VE ENVANTER KORUMA
-- =============================================

Config.Money = {
    Enabled = true,
    
    -- ESX Framework ayarları
    ESX = {
        Enabled = true,
        MaxCashIncrease = 10000, -- Tek seferde maksimum para artışı
        MaxBankIncrease = 50000,
        CheckInterval = 2000
    },
    
    -- QBCore Framework ayarları
    QBCore = {
        Enabled = false,
        MaxCashIncrease = 10000,
        MaxBankIncrease = 50000,
        CheckInterval = 2000
    },
    
    -- Şüpheli işlemler
    SuspiciousTransactions = {
        LogAll = true,
        MinAmount = 5000, -- Bu miktarın üzeri loglanır
        MaxPerMinute = 3 -- Dakikada maksimum işlem sayısı
    }
}

-- =============================================
-- SOHBET KORUMA
-- =============================================

Config.Chat = {
    Enabled = true,
    
    -- Spam koruması
    AntiSpam = {
        Enabled = true,
        MaxMessages = 5, -- 10 saniyede maksimum mesaj
        TimeWindow = 10000, -- 10 saniye
        MuteTime = 60000 -- 1 dakika susturma
    },
    
    -- Yasaklı kelimeler
    BadWords = {
        'cheat', 'hack', 'mod menu', 'executor', 'inject'
    },
    
    -- Link koruması
    AntiLink = {
        Enabled = true,
        AllowedDomains = {
            'youtube.com',
            'twitch.tv',
            'discord.gg'
        }
    },
    
    -- XSS koruması
    AntiXSS = {
        Enabled = true,
        BlockedTags = {
            '<script>', '</script>',
            '<iframe>', '</iframe>',
            'javascript:', 'data:'
        }
    }
}

-- =============================================
-- YAPAY ZEKA AYARLARI
-- =============================================

Config.AI = {
    Enabled = true,
    ApiUrl = 'http://localhost:5000/api/ai', -- Python AI modülü URL'si
    ApiKey = 'fiveguard-ai-key-2024',
    
    -- Screenshot analizi
    Screenshot = {
        Enabled = true,
        Interval = 300000, -- 5 dakika
        Quality = 80, -- JPEG kalitesi (1-100)
        MaxSize = 1024, -- Maksimum genişlik (px)
        SavePath = 'screenshots/',
        AutoDelete = true, -- 7 gün sonra otomatik sil
        DeleteAfterDays = 7
    },
    
    -- Davranış analizi
    BehaviorAnalysis = {
        Enabled = true,
        CheckInterval = 10000, -- 10 saniye
        MinDataPoints = 50, -- Minimum veri noktası
        LearningRate = 0.01 -- Öğrenme oranı
    },
    
    -- Sahne analizi
    SceneAnalysis = {
        Enabled = true,
        CheckInterval = 5000, -- 5 saniye
        SuspiciousObjectThreshold = 0.8 -- Şüpheli nesne eşiği
    }
}

-- =============================================
-- WEBHOOK VE BİLDİRİMLER
-- =============================================

Config.Webhooks = {
    Discord = {
        Enabled = true,
        Url = '', -- Discord webhook URL'si
        Username = 'Fiveguard',
        Avatar = 'https://i.imgur.com/fiveguard-logo.png',
        
        -- Hangi eventlerde bildirim gönderilecek
        Events = {
            'detection', 'ban', 'unban', 'warning',
            'player_join', 'player_leave', 'suspicious_activity'
        },
        
        -- Renk kodları
        Colors = {
            info = 3447003, -- Mavi
            warning = 16776960, -- Sarı
            error = 15158332, -- Kırmızı
            success = 3066993 -- Yeşil
        }
    },
    
    -- Email bildirimleri
    Email = {
        Enabled = false,
        SmtpServer = 'smtp.gmail.com',
        SmtpPort = 587,
        Username = '',
        Password = '',
        From = 'noreply@fiveguard.com',
        To = 'admin@yourserver.com'
    }
}

-- =============================================
-- LOG SİSTEMİ
-- =============================================

Config.Logging = {
    Enabled = true,
    Level = 'info', -- debug, info, warning, error, critical
    
    -- Log türleri
    Types = {
        Console = true, -- Konsola yazdır
        File = true, -- Dosyaya kaydet
        Database = true, -- Veritabanına kaydet
        Webhook = true -- Webhook'a gönder
    },
    
    -- Dosya ayarları
    File = {
        Path = 'logs/',
        MaxSize = 10485760, -- 10MB
        MaxFiles = 5, -- Maksimum log dosyası sayısı
        DateFormat = '%Y-%m-%d %H:%M:%S'
    },
    
    -- Otomatik temizlik
    AutoCleanup = {
        Enabled = true,
        Days = 30, -- 30 gün sonra eski logları sil
        CheckInterval = 86400000 -- 24 saatte bir kontrol et
    }
}

-- =============================================
-- PERFORMANS AYARLARI
-- =============================================

Config.Performance = {
    -- Thread optimizasyonu
    ThreadOptimization = true,
    
    -- Maksimum eşzamanlı kontrol sayısı
    MaxConcurrentChecks = 10,
    
    -- Bellek kullanımı
    MemoryOptimization = {
        Enabled = true,
        GarbageCollectionInterval = 300000, -- 5 dakika
        MaxCacheSize = 1000 -- Maksimum cache boyutu
    },
    
    -- CPU kullanımı
    CpuOptimization = {
        Enabled = true,
        MaxCpuUsage = 5.0, -- Maksimum %5 CPU kullanımı
        ThrottleOnHighUsage = true
    }
}

-- =============================================
-- ADMIN AYARLARI
-- =============================================

Config.Admin = {
    -- Admin menü
    Menu = {
        Enabled = true,
        Key = 'F10', -- Admin menü açma tuşu
        RequiredAce = 'fiveguard.admin'
    },
    
    -- Komutlar
    Commands = {
        Ban = 'fgban',
        Unban = 'fgunban',
        Check = 'fgcheck',
        Stats = 'fgstats',
        Whitelist = 'fgwhitelist'
    },
    
    -- Bypass yetkisi
    BypassAce = 'fiveguard.bypass'
}

-- =============================================
-- WEBHOOK AYARLARI
-- =============================================

FiveguardConfig.Webhooks = {
    -- Ana webhook URL'leri
    main = "YOUR_MAIN_WEBHOOK_URL",
    bans = "YOUR_BAN_WEBHOOK_URL",
    kicks = "YOUR_KICK_WEBHOOK_URL",
    warnings = "YOUR_WARNING_WEBHOOK_URL",
    ocr_detection = "YOUR_OCR_DETECTION_WEBHOOK_URL",
    entity_violations = "YOUR_ENTITY_VIOLATION_WEBHOOK_URL",
    
    -- Webhook ayarları
    enabled = true,
    timeout = 5000,
    retryCount = 3,
    
    -- Embed ayarları
    embedColor = 16711680, -- Kırmızı
    thumbnailUrl = "https://i.imgur.com/fiveguard-logo.png",
    footerText = "Fiveguard Anti-Cheat System"
}

-- =============================================
-- OCR VE AI AYARLARI
-- =============================================

FiveguardConfig.OCR = {
    -- OCR sistemi aktif mi
    enabled = true,
    
    -- AI servis ayarları
    aiServiceUrl = "http://localhost:8000",
    aiApiKey = "YOUR_AI_API_KEY",
    
    -- Screenshot ayarları
    screenshot = {
        quality = 0.8,
        format = "jpg",
        interval = 30000,        -- Minimum interval (30 saniye)
        maxQueueSize = 10,       -- Maksimum kuyruk boyutu
        timeout = 15000,         -- Timeout süresi
        retryCount = 3,          -- Yeniden deneme sayısı
        
        -- Periyodik screenshot
        periodicEnabled = true,
        periodicInterval = 300000, -- 5 dakika
        periodicChance = 0.3      -- %30 şans
    },
    
    -- OCR işleme ayarları
    processing = {
        maxQueueSize = 50,
        processingTimeout = 30000,
        retryCount = 3,
        cacheExpiry = 300000,    -- 5 dakika
        batchSize = 5,
        detectionThreshold = 0.7,
        enableCache = true,
        enableBatching = true
    },
    
    -- Tespit ayarları
    detection = {
        -- Ceza seviyeleri
        punishments = {
            critical = "ban",    -- 0.9+ güven
            high = "ban",        -- 0.8+ güven
            medium = "kick",     -- 0.6+ güven
            low = "warn"         -- 0.6- güven
        },
        
        -- Otomatik screenshot tetikleyicileri
        triggers = {
            suspicious = true,    -- Şüpheli aktivite sonrası
            detection = true,     -- Tespit sonrası
            behavioral = true,    -- Davranış analizi sonrası
            periodic = true,      -- Periyodik kontrol
            manual = true         -- Admin talebi
        }
    }
}

-- =============================================
-- ENTITY SECURITY AYARLARI
-- =============================================

FiveguardConfig.EntitySecurity = {
    -- Entity security aktif mi
    enabled = true,
    
    -- Entity limitleri
    limits = {
        vehicles = 10,           -- Maksimum araç sayısı
        peds = 12,              -- Maksimum ped sayısı
        objects = 20,           -- Maksimum obje sayısı
        totalEntities = 40,     -- Toplam entity limiti
        stateBagSize = 1024,    -- State bag boyut limiti (bytes)
        creationRate = 5,       -- Saniyede maksimum entity oluşturma
        networkRange = 500.0    -- Network range limiti
    },
    
    -- Monitoring ayarları
    monitoring = {
        entityCheckInterval = 5000,     -- Entity kontrol aralığı (5 saniye)
        stateBagCheckInterval = 10000,  -- State bag kontrol aralığı (10 saniye)
        networkCheckInterval = 15000,   -- Network kontrol aralığı (15 saniye)
        cleanupInterval = 60000         -- Temizlik aralığı (1 dakika)
    },
    
    -- Blacklisted entity'ler
    blacklisted = {
        vehicles = {
            'rhino', 'lazer', 'hydra', 'savage', 'buzzard',
            'oppressor', 'oppressor2', 'khanjali', 'akula',
            'hunter', 'annihilator2', 'avenger', 'bombushka',
            'cargoplane', 'molotok', 'nokota', 'pyro', 'rogue',
            'starling', 'strikeforce', 'scramjet', 'vigilante'
        },
        peds = {
            's_m_y_swat_01', 's_m_y_cop_01', 's_m_m_movalien_01',
            'u_m_y_zombie_01', 's_m_y_blackops_01', 's_m_y_hwaycop_01',
            's_m_m_paramedic_01', 's_m_y_fireman_01'
        },
        objects = {
            'prop_logpile_07b', 'hei_prop_carrier_radar_1',
            'prop_rock_1_a', 'prop_test_boulder_01',
            'apa_mp_apa_crashed_usaf_01a', 'prop_crashed_heli',
            'prop_shamal_crash', 'xm_prop_x17_shamal_crash'
        }
    },
    
    -- Ceza ayarları
    punishments = {
        vehicle_limit = "kick",
        ped_limit = "kick",
        object_limit = "warn",
        total_entity_limit = "ban",
        blacklisted_vehicle = "ban",
        blacklisted_ped = "ban",
        blacklisted_object = "kick",
        creation_rate_limit = "kick",
        state_bag_overflow = "ban",
        entity_state_bag_overflow = "kick",
        state_bag_overflow_attack = "ban",
        network_range_violation = "warn"
    }
}

-- =============================================
-- MODÜL AYARLARI
-- =============================================

Config.Modules = {
    -- =============================================
    -- ADMIN ABUSE PROTECTION
    -- =============================================
    AdminAbuse = {
        enabled = true,
        logAllActions = true,
        maxActionsPerMinute = 10,
        suspiciousActionThreshold = 5,
        autoActionEnabled = true,
        banDuration = 86400, -- 24 saat
        kickReason = "Şüpheli admin aktivitesi tespit edildi",
        
        -- İzlenen admin aksiyonları
        monitoredActions = {
            'give_money', 'give_item', 'teleport_player', 'kick_player',
            'ban_player', 'unban_player', 'set_job', 'revive_player',
            'heal_player', 'god_mode', 'invisible', 'noclip'
        },
        
        -- Whitelist'teki adminler (bypass)
        whitelistedAdmins = {
            -- 'steam:110000000000000'
        }
    },
    
    -- =============================================
    -- CHEAT DETECTION ENGINE
    -- =============================================
    CheatDetection = {
        enabled = true,
        
        -- Tespit türleri
        detectionTypes = {
            enableDuiDetection = true,
            enableLuaExecutorDetection = true,
            enableResourceInjectionDetection = true,
            enableSpeedHackDetection = true,
            enableTeleportDetection = true,
            enableGodModeDetection = true,
            enableAimbotDetection = true,
            enableESPDetection = true,
            enableMenuDetection = true
        },
        
        -- Kontrol aralıkları (milisaniye)
        checkIntervals = {
            duiCheck = 5000,
            luaExecutorCheck = 3000,
            resourceInjectionCheck = 10000,
            speedHackCheck = 1000,
            teleportCheck = 500,
            godModeCheck = 2000,
            aimbotCheck = 1000,
            espCheck = 5000,
            menuCheck = 2000
        },
        
        -- Violation ayarları
        violations = {
            maxViolations = 5,
            violationResetTime = 300000, -- 5 dakika
            autoActionEnabled = true
        },
        
        -- Threshold değerleri
        thresholds = {
            speedHackThreshold = 50.0,
            teleportThreshold = 100.0,
            godModeThreshold = 0.95,
            aimbotAccuracyThreshold = 0.90,
            suspiciousActivityThreshold = 0.75
        }
    },
    
    -- =============================================
    -- ESX SECURITY MODULE
    -- =============================================
    ESXSecurity = {
        enabled = true,
        
        -- Koruma türleri
        protectionTypes = {
            enableEventSpamProtection = true,
            enableBillingProtection = true,
            enableSqlInjectionProtection = true,
            enableNegativePayProtection = true,
            enableCallbackProtection = true
        },
        
        -- Event spam ayarları
        eventSpam = {
            eventSpamThreshold = 10,
            eventSpamTimeWindow = 5000, -- 5 saniye
            whitelistedEvents = {
                'esx:getSharedObject',
                'esx:playerLoaded'
            }
        },
        
        -- Billing koruması
        billing = {
            billingAmountLimit = 1000000, -- 1M limit
            enableMaliciousTextDetection = true
        },
        
        -- SQL injection koruması
        sqlInjection = {
            enablePatternDetection = true,
            logAllAttempts = true
        },
        
        -- Otomatik işlemler
        autoActions = {
            autoActionEnabled = true,
            banDuration = 604800 -- 7 gün
        }
    },
    
    -- =============================================
    -- NETWORK SECURITY LAYER
    -- =============================================
    NetworkSecurity = {
        enabled = true,
        
        -- Bağlantı koruması
        connection = {
            enableVpnDetection = true,
            enableRateLimiting = true,
            enableUsernameValidation = true,
            enableVacBanCheck = false, -- Steam Web API key gerekli
            maxConnectionsPerIP = 3,
            connectionTimeout = 30000, -- 30 saniye
            whitelistedIPs = {
                -- '127.0.0.1',
                -- '192.168.1.1'
            }
        },
        
        -- Rate limiting
        rateLimit = {
            rateLimitWindow = 60000, -- 1 dakika
            rateLimitThreshold = 100, -- 100 request/dakika
            categories = {
                CONNECTION = 'connection',
                EVENT = 'event',
                CHAT = 'chat',
                COMMAND = 'command'
            }
        },
        
        -- Steam ayarları
        steam = {
            steamWebApiKey = '', -- Steam Web API key
            enableVacBanCheck = false
        },
        
        -- Otomatik işlemler
        autoActions = {
            autoActionEnabled = true,
            banDuration = 2592000 -- 30 gün
        }
    },
    
    -- =============================================
    -- ENTITY VALIDATION SYSTEM
    -- =============================================
    EntityValidation = {
        enabled = true,
        
        -- Validation türleri
        validationTypes = {
            enableVehicleValidation = true,
            enablePedValidation = true,
            enableObjectValidation = true,
            enableWeaponValidation = true
        },
        
        -- Entity limitleri
        limits = {
            maxEntitiesPerPlayer = 50,
            entityCreationCooldown = 1000, -- 1 saniye
            maxVehiclesPerPlayer = 10,
            maxPedsPerPlayer = 5,
            maxObjectsPerPlayer = 20
        },
        
        -- Validation modu
        validationMode = {
            whitelistMode = true, -- true = sadece whitelist, false = blacklist
            autoDeleteIllegal = true
        },
        
        -- Otomatik işlemler
        autoActions = {
            autoActionEnabled = true,
            banDuration = 604800 -- 7 gün
        }
    },
    
    -- =============================================
    -- WEAPON SECURITY MODULE
    -- =============================================
    WeaponSecurity = {
        enabled = true,
        
        -- Koruma türleri
        protectionTypes = {
            enableAimbotDetection = true,
            enableWeaponModifierDetection = true,
            enableTazerProtection = true,
            enableWeaponBlacklist = true,
            enableDamageValidation = true
        },
        
        -- Aimbot tespiti
        aimbot = {
            aimbotOffsetDistance = 7.0, -- Icarus'tan alınan değer
            maxAccuracy = 0.95, -- %95+ accuracy şüpheli
            minShotsForCheck = 10,
            checkInterval = 1000
        },
        
        -- Weapon modifier
        weaponModifier = {
            maxDamageModifier = 1.0,
            dynamicModifier = false,
            tolerancePercentage = 0.2 -- %20 tolerans
        },
        
        -- Tazer koruması
        tazer = {
            tazerMaxDistance = 12.0, -- Icarus'tan alınan değer
            tazerCooldown = 12000, -- 12 saniye
            enableDistanceCheck = true
        },
        
        -- Otomatik işlemler
        autoActions = {
            autoActionEnabled = true,
            banDuration = 1209600 -- 14 gün
        }
    },
    
    -- =============================================
    -- OCR HANDLER MODULE
    -- =============================================
    OCRHandler = {
        enabled = true,
        
        -- İşleme ayarları
        processing = {
            maxQueueSize = 50,
            processingTimeout = 30000,
            retryCount = 3,
            cacheExpiry = 300000, -- 5 dakika
            batchSize = 5,
            enableCache = true,
            enableBatching = true
        },
        
        -- Tespit ayarları
        detection = {
            detectionThreshold = 0.7,
            confidenceThreshold = 0.8,
            enableMenuDetection = true,
            enableTextDetection = true
        },
        
        -- Screenshot ayarları
        screenshot = {
            quality = 0.8,
            format = "jpg",
            interval = 30000, -- 30 saniye minimum
            maxQueueSize = 10,
            timeout = 15000,
            retryCount = 3
        },
        
        -- AI servis ayarları
        aiService = {
            aiServiceUrl = "http://localhost:8000",
            aiApiKey = "YOUR_AI_API_KEY",
            timeout = 10000,
            retryCount = 3
        }
    }
}

-- =============================================
-- WHİTELİST VE BLACKLİST AYARLARI
-- =============================================

Config.Lists = {
    -- =============================================
    -- VEHICLE WHİTELİST
    -- =============================================
    VehicleWhitelist = {
        -- Compacts
        "adder", "asbo", "blista", "brioso", "club", "dilettante", "dilettante2",
        "issi2", "issi3", "issi4", "issi5", "issi6", "kanjo", "panto", "prairie", "rhapsody",
        
        -- Sedans
        "asea", "asea2", "asterope", "cog55", "cog552", "cognoscenti", "cognoscenti2",
        "emperor", "emperor2", "emperor3", "fugitive", "glendale", "glendale2", "ingot",
        "intruder", "limo2", "premier", "primo", "primo2", "regina", "romero", "schafter2",
        
        -- SUVs
        "baller", "baller2", "baller3", "baller4", "baller5", "baller6", "bjxl",
        "cavalcade", "cavalcade2", "contender", "dubsta", "dubsta2", "fq2", "granger",
        
        -- Sports
        "alpha", "banshee", "bestiagts", "blista2", "blista3", "buffalo", "buffalo2",
        "buffalo3", "carbonizzare", "comet2", "comet3", "comet4", "comet5", "coquette",
        
        -- Motorcycles
        "akuma", "avarus", "bagger", "bati", "bati2", "bf400", "carbonrs", "chimera",
        "cliffhanger", "daemon", "daemon2", "defiler", "diablous", "diablous2", "double"
    },
    
    -- =============================================
    -- PED WHİTELİST
    -- =============================================
    PedWhitelist = {
        -- Player models
        "player_one", "player_two", "player_zero", "mp_f_freemode_01", "mp_m_freemode_01",
        
        -- Male Adults
        "a_m_m_acult_01", "a_m_m_afriamer_01", "a_m_m_beach_01", "a_m_m_beach_02",
        "a_m_m_bevhills_01", "a_m_m_bevhills_02", "a_m_m_business_01", "a_m_m_eastsa_01",
        
        -- Female Adults
        "a_f_m_beach_01", "a_f_m_bevhills_01", "a_f_m_bevhills_02", "a_f_m_bodybuild_01",
        "a_f_m_business_02", "a_f_m_downtown_01", "a_f_m_eastsa_01", "a_f_m_eastsa_02"
    },
    
    -- =============================================
    -- OBJECT BLACKLİST
    -- =============================================
    ObjectBlacklist = {
        -- Explosion objects
        "prop_bomb_01", "prop_bomb_02", "prop_bomb_03", "prop_explosive_01", "prop_explosive_02",
        "prop_gas_tank_01", "prop_gas_tank_02", "prop_propane_tank_01", "prop_propane_tank_02",
        
        -- Weapon objects
        "prop_gun_case_01", "prop_gun_case_02", "prop_minigun_01", "prop_rpg_01",
        "prop_launcher_01", "prop_grenade_01", "prop_molotov_01",
        
        -- Large/Problematic objects
        "prop_container_01a", "prop_container_01b", "prop_container_01c", "prop_container_01d",
        "prop_building_01", "prop_building_02", "prop_building_03", "prop_skyscraper_01",
        
        -- Money/Cash objects
        "prop_cash_pile_01", "prop_cash_pile_02", "prop_money_bag_01", "prop_money_bag_02",
        "prop_gold_bar_01", "prop_gold_cont_01", "prop_diamond_01"
    },
    
    -- =============================================
    -- WEAPON BLACKLİST
    -- =============================================
    WeaponBlacklist = {
        -- Heavy Weapons
        "WEAPON_MG", "WEAPON_RPG", "WEAPON_BZGAS", "WEAPON_RAILGUN", "WEAPON_MINIGUN",
        "WEAPON_GRENADE", "WEAPON_MOLOTOV", "WEAPON_MINISMG", "WEAPON_SMG_MK2",
        "WEAPON_PIPEBOMB", "WEAPON_PROXMINE", "WEAPON_MICROSMG", "WEAPON_FIREWORK",
        
        -- Special/Modded Weapons
        "WEAPON_RAYPISTOL", "WEAPON_RAILGUNXM3", "WEAPON_GARBAGEBAG", "WEAPON_RAYMINIGUN",
        "WEAPON_STICKYBOMB", "WEAPON_RAYCARBINE", "WEAPON_AUTOSHOTGUN", "WEAPON_EMPLAUNCHER",
        
        -- Admin/Debug Weapons
        "WEAPON_ADMINGUN", "WEAPON_DEBUGGUN", "WEAPON_TESTGUN", "WEAPON_MODGUN"
    }
}

-- =============================================
-- GELİŞTİRİCİ AYARLARI
-- =============================================

Config.Developer = {
    -- Test modu
    TestMode = false,
    
    -- Mock data kullan
    UseMockData = false,
    
    -- API rate limiting
    RateLimit = {
        Enabled = true,
        RequestsPerMinute = 100,
        BurstLimit = 20
    },
    
    -- Profiling
    Profiling = {
        Enabled = false,
        LogSlowQueries = true,
        SlowQueryThreshold = 1000 -- 1 saniye
    }
}
