-- FIVEGUARD WEAPON SECURITY MODULE
-- Gelişmiş silah güvenlik sistemi ve aimbot tespiti (Icarus'tan esinlenilmiş)

FiveguardServer.WeaponSecurity = {}

-- =============================================
-- WEAPON SECURITY DEĞİŞKENLERİ
-- =============================================

local weaponData = {
    isActive = false,
    playerWeapons = {},
    weaponModifiers = {},
    aimbotDetections = {},
    tazerUsage = {},
    suspiciousShots = {},
    config = {
        enableAimbotDetection = true,
        enableWeaponModifierDetection = true,
        enableTazerProtection = true,
        enableWeaponBlacklist = true,
        enableDamageValidation = true,
        aimbotOffsetDistance = 7.0, -- Icarus'tan alınan değer
        maxDamageModifier = 1.0,
        dynamicModifier = false,
        tazerMaxDistance = 12.0, -- Icarus'tan alınan değer
        tazerCooldown = 12000, -- 12 saniye
        autoActionEnabled = true
    },
    stats = {
        totalWeaponChecks = 0,
        aimbotDetections = 0,
        weaponModifierViolations = 0,
        tazerViolations = 0,
        blacklistedWeapons = 0,
        damageViolations = 0,
        lastDetection = 0
    }
}

-- Weapon Blacklist (Icarus'tan alınan)
local weaponBlacklist = {
    "WEAPON_MG",
    "WEAPON_RPG",
    "WEAPON_BZGAS",
    "WEAPON_RAILGUN",
    "WEAPON_MINIGUN",
    "WEAPON_GRENADE",
    "WEAPON_MOLOTOV",
    "WEAPON_MINISMG",
    "WEAPON_SMG_MK2",
    "WEAPON_PIPEBOMB",
    "WEAPON_PROXMINE",
    "WEAPON_MICROSMG",
    "WEAPON_FIREWORK",
    "WEAPON_HAZARDCAN",
    "WEAPON_RAYPISTOL",
    "WEAPON_RAILGUNXM3",
    "WEAPON_GARBAGEBAG",
    "WEAPON_RAYMINIGUN",
    "WEAPON_STICKYBOMB",
    "WEAPON_RAYCARBINE",
    "WEAPON_AUTOSHOTGUN",
    "WEAPON_EMPLAUNCHER",
    "WEAPON_COMBATMG_MK2",
    "WEAPON_MACHINEPISTOL",
    "WEAPON_HOMINGLAUNCHER",
    "WEAPON_MARKSMANPISTOL",
    "WEAPON_ASSAULTSHOTGUN",
    "WEAPON_GRENADELAUNCHER",
    "WEAPON_COMPACTLAUNCHER",
    "WEAPON_GRENADELAUNCHER_SMOKE"
}

-- Weapon Damage Values (Normal damage değerleri)
local weaponDamageValues = {
    ["WEAPON_PISTOL"] = 26,
    ["WEAPON_COMBATPISTOL"] = 27,
    ["WEAPON_APPISTOL"] = 22,
    ["WEAPON_PISTOL50"] = 51,
    ["WEAPON_SNSPISTOL"] = 22,
    ["WEAPON_HEAVYPISTOL"] = 35,
    ["WEAPON_VINTAGEPISTOL"] = 26,
    ["WEAPON_FLAREGUN"] = 20,
    ["WEAPON_MARKSMANPISTOL"] = 65,
    ["WEAPON_REVOLVER"] = 126,
    ["WEAPON_MICROSMG"] = 21,
    ["WEAPON_SMG"] = 23,
    ["WEAPON_ASSAULTSMG"] = 23,
    ["WEAPON_COMBATPDW"] = 21,
    ["WEAPON_MACHINEPISTOL"] = 21,
    ["WEAPON_MINISMG"] = 21,
    ["WEAPON_ASSAULTRIFLE"] = 30,
    ["WEAPON_CARBINERIFLE"] = 32,
    ["WEAPON_ADVANCEDRIFLE"] = 31,
    ["WEAPON_SPECIALCARBINE"] = 32,
    ["WEAPON_BULLPUPRIFLE"] = 32,
    ["WEAPON_COMPACTRIFLE"] = 30,
    ["WEAPON_MG"] = 45,
    ["WEAPON_COMBATMG"] = 45,
    ["WEAPON_GUSENBERG"] = 30,
    ["WEAPON_SNIPERRIFLE"] = 101,
    ["WEAPON_HEAVYSNIPER"] = 216,
    ["WEAPON_MARKSMANRIFLE"] = 65,
    ["WEAPON_PUMPSHOTGUN"] = 26,
    ["WEAPON_SAWNOFFSHOTGUN"] = 40,
    ["WEAPON_ASSAULTSHOTGUN"] = 28,
    ["WEAPON_BULLPUPSHOTGUN"] = 26,
    ["WEAPON_MUSKET"] = 95,
    ["WEAPON_HEAVYSHOTGUN"] = 45,
    ["WEAPON_DBSHOTGUN"] = 175,
    ["WEAPON_AUTOSHOTGUN"] = 17
}

-- Aimbot Detection Patterns
local aimbotPatterns = {
    -- Rapid target switching
    {
        name = 'rapid_target_switch',
        threshold = 5, -- 5 farklı target 1 saniyede
        timeWindow = 1000
    },
    -- Perfect accuracy
    {
        name = 'perfect_accuracy',
        threshold = 0.95, -- %95+ accuracy
        minShots = 10
    },
    -- Impossible angles
    {
        name = 'impossible_angle',
        maxAngleChange = 180, -- 180 derece ani değişim
        timeWindow = 100 -- 100ms içinde
    },
    -- Headshot ratio
    {
        name = 'high_headshot_ratio',
        threshold = 0.8, -- %80+ headshot
        minShots = 20
    }
}

-- =============================================
-- WEAPON SECURITY BAŞLATMA
-- =============================================

function FiveguardServer.WeaponSecurity.Initialize()
    print('^2[FIVEGUARD WEAPON SECURITY]^7 Weapon Security Module başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardServer.WeaponSecurity.LoadConfig()
    
    -- Event'leri kaydet
    FiveguardServer.WeaponSecurity.RegisterEvents()
    
    -- Weapon monitoring'i başlat
    FiveguardServer.WeaponSecurity.StartWeaponMonitoring()
    
    -- Aimbot detection'ı başlat
    FiveguardServer.WeaponSecurity.StartAimbotDetection()
    
    -- Cleanup thread'ini başlat
    FiveguardServer.WeaponSecurity.StartCleanup()
    
    weaponData.isActive = true
    print('^2[FIVEGUARD WEAPON SECURITY]^7 Weapon Security Module hazır')
end

-- Konfigürasyonu yükle
function FiveguardServer.WeaponSecurity.LoadConfig()
    local config = FiveguardServer.Config.Modules.WeaponSecurity or {}
    
    -- Ana ayarları yükle
    weaponData.config.enabled = config.enabled ~= nil and config.enabled or weaponData.config.enabled
    
    -- Protection types'ları yükle
    if config.protectionTypes then
        for key, value in pairs(config.protectionTypes) do
            if weaponData.config[key] ~= nil then
                weaponData.config[key] = value
            end
        end
    end
    
    -- Aimbot ayarlarını yükle
    if config.aimbot then
        weaponData.config.aimbotOffsetDistance = config.aimbot.aimbotOffsetDistance or weaponData.config.aimbotOffsetDistance
        weaponData.config.maxAccuracy = config.aimbot.maxAccuracy or weaponData.config.maxAccuracy
        weaponData.config.minShotsForCheck = config.aimbot.minShotsForCheck or weaponData.config.minShotsForCheck
        weaponData.config.checkInterval = config.aimbot.checkInterval or weaponData.config.checkInterval
    end
    
    -- Weapon modifier ayarlarını yükle
    if config.weaponModifier then
        weaponData.config.maxDamageModifier = config.weaponModifier.maxDamageModifier or weaponData.config.maxDamageModifier
        weaponData.config.dynamicModifier = config.weaponModifier.dynamicModifier ~= nil and config.weaponModifier.dynamicModifier or weaponData.config.dynamicModifier
        weaponData.config.tolerancePercentage = config.weaponModifier.tolerancePercentage or weaponData.config.tolerancePercentage
    end
    
    -- Tazer ayarlarını yükle
    if config.tazer then
        weaponData.config.tazerMaxDistance = config.tazer.tazerMaxDistance or weaponData.config.tazerMaxDistance
        weaponData.config.tazerCooldown = config.tazer.tazerCooldown or weaponData.config.tazerCooldown
        weaponData.config.enableDistanceCheck = config.tazer.enableDistanceCheck ~= nil and config.tazer.enableDistanceCheck or weaponData.config.enableDistanceCheck
    end
    
    -- Auto actions ayarlarını yükle
    if config.autoActions then
        weaponData.config.autoActionEnabled = config.autoActions.autoActionEnabled ~= nil and config.autoActions.autoActionEnabled or weaponData.config.autoActionEnabled
        weaponData.config.banDuration = config.autoActions.banDuration or weaponData.config.banDuration
    end
    
    -- Config'den weapon blacklist'i yükle
    if FiveguardServer.Config.Lists and FiveguardServer.Config.Lists.WeaponBlacklist then
        weaponData.weaponBlacklist = FiveguardServer.Config.Lists.WeaponBlacklist
    end
    
    print('^2[FIVEGUARD WEAPON SECURITY]^7 Config yüklendi - Enabled: ' .. tostring(weaponData.config.enabled))
end

-- Event'leri kaydet
function FiveguardServer.WeaponSecurity.RegisterEvents()
    -- Weapon damage event
    RegisterNetEvent('gameEventTriggered')
    AddEventHandler('gameEventTriggered', function(name, args)
        if name == 'CEventNetworkEntityDamage' then
            local victim = args[1]
            local attacker = args[2]
            local damage = args[4]
            local weaponHash = args[5]
            
            if attacker and GetPlayerPed(attacker) then
                FiveguardServer.WeaponSecurity.HandleWeaponDamage(attacker, victim, damage, weaponHash)
            end
        end
    end)
    
    -- Weapon give/remove events
    AddEventHandler('weaponDamageEvent', function(sender, data)
        FiveguardServer.WeaponSecurity.HandleWeaponEvent(sender, data)
    end)
    
    -- Player connecting event
    AddEventHandler('playerConnecting', function()
        local playerId = source
        FiveguardServer.WeaponSecurity.InitializePlayer(playerId)
    end)
    
    -- Player dropped event
    AddEventHandler('playerDropped', function()
        local playerId = source
        FiveguardServer.WeaponSecurity.CleanupPlayer(playerId)
    end)
    
    -- Tazer usage event
    RegisterNetEvent('fiveguard:weapon:tazerUsed')
    AddEventHandler('fiveguard:weapon:tazerUsed', function(targetId, distance)
        local playerId = source
        FiveguardServer.WeaponSecurity.HandleTazerUsage(playerId, targetId, distance)
    end)
    
    -- Aimbot detection event
    RegisterNetEvent('fiveguard:weapon:suspiciousAim')
    AddEventHandler('fiveguard:weapon:suspiciousAim', function(aimData)
        local playerId = source
        FiveguardServer.WeaponSecurity.HandleSuspiciousAim(playerId, aimData)
    end)
end

-- =============================================
-- PLAYER INITIALIZATION
-- =============================================

-- Player'ı initialize et
function FiveguardServer.WeaponSecurity.InitializePlayer(playerId)
    weaponData.playerWeapons[playerId] = {
        weapons = {},
        lastWeaponCheck = 0,
        shotsFired = 0,
        shotsHit = 0,
        headshotCount = 0,
        lastShotTime = 0,
        aimHistory = {},
        damageDealt = {}
    }
    
    weaponData.weaponModifiers[playerId] = {
        modifiers = {},
        violations = 0,
        lastCheck = 0
    }
    
    weaponData.tazerUsage[playerId] = {
        lastUsage = 0,
        usageCount = 0,
        violations = 0
    }
end

-- Player'ı temizle
function FiveguardServer.WeaponSecurity.CleanupPlayer(playerId)
    weaponData.playerWeapons[playerId] = nil
    weaponData.weaponModifiers[playerId] = nil
    weaponData.aimbotDetections[playerId] = nil
    weaponData.tazerUsage[playerId] = nil
    weaponData.suspiciousShots[playerId] = nil
end

-- =============================================
-- WEAPON MONITORING
-- =============================================

-- Weapon monitoring'i başlat
function FiveguardServer.WeaponSecurity.StartWeaponMonitoring()
    CreateThread(function()
        while weaponData.isActive do
            Wait(5000) -- 5 saniye bekle
            
            -- Tüm oyuncuları kontrol et
            for playerId, player in pairs(FiveguardServer.Players or {}) do
                FiveguardServer.WeaponSecurity.CheckPlayerWeapons(playerId)
            end
        end
    end)
end

-- Player'ın silahlarını kontrol et
function FiveguardServer.WeaponSecurity.CheckPlayerWeapons(playerId)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    weaponData.stats.totalWeaponChecks = weaponData.stats.totalWeaponChecks + 1
    
    -- Client'tan silah listesini iste
    TriggerClientEvent('fiveguard:weapon:requestWeaponList', playerId)
end

-- Weapon listesini işle
RegisterNetEvent('fiveguard:weapon:weaponListResponse')
AddEventHandler('fiveguard:weapon:weaponListResponse', function(weapons)
    local playerId = source
    FiveguardServer.WeaponSecurity.ProcessWeaponList(playerId, weapons)
end)

-- Weapon listesini işle
function FiveguardServer.WeaponSecurity.ProcessWeaponList(playerId, weapons)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    if not weaponData.playerWeapons[playerId] then
        FiveguardServer.WeaponSecurity.InitializePlayer(playerId)
    end
    
    -- Blacklisted weapon kontrolü
    if weaponData.config.enableWeaponBlacklist then
        for _, weapon in ipairs(weapons) do
            if FiveguardServer.WeaponSecurity.IsWeaponBlacklisted(weapon.hash) then
                FiveguardServer.WeaponSecurity.HandleBlacklistedWeapon(playerId, weapon)
            end
        end
    end
    
    -- Weapon modifier kontrolü
    if weaponData.config.enableWeaponModifierDetection then
        for _, weapon in ipairs(weapons) do
            FiveguardServer.WeaponSecurity.CheckWeaponModifier(playerId, weapon)
        end
    end
    
    -- Weapon listesini güncelle
    weaponData.playerWeapons[playerId].weapons = weapons
    weaponData.playerWeapons[playerId].lastWeaponCheck = os.time()
end

-- =============================================
-- WEAPON BLACKLIST
-- =============================================

-- Weapon blacklist kontrolü
function FiveguardServer.WeaponSecurity.IsWeaponBlacklisted(weaponHash)
    local weaponName = GetWeapontypeModel(weaponHash) or 'unknown'
    
    for _, blacklistedWeapon in ipairs(weaponBlacklist) do
        if string.upper(weaponName) == string.upper(blacklistedWeapon) then
            return true
        end
    end
    
    return false
end

-- Blacklisted weapon'ı işle
function FiveguardServer.WeaponSecurity.HandleBlacklistedWeapon(playerId, weapon)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'blacklisted_weapon',
        weaponHash = weapon.hash,
        weaponName = GetWeapontypeModel(weapon.hash) or 'unknown',
        ammo = weapon.ammo or 0,
        timestamp = os.time(),
        severity = 'critical'
    }
    
    -- İstatistikleri güncelle
    weaponData.stats.blacklistedWeapons = weaponData.stats.blacklistedWeapons + 1
    weaponData.stats.lastDetection = os.time()
    
    -- Silahı kaldır
    TriggerClientEvent('fiveguard:weapon:removeWeapon', playerId, weapon.hash)
    
    -- Detection'ı işle
    FiveguardServer.WeaponSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD WEAPON SECURITY]^7 Blacklisted weapon: ' .. player.name .. 
          ' (' .. detection.weaponName .. ')')
end

-- =============================================
-- WEAPON MODIFIER DETECTION
-- =============================================

-- Weapon modifier kontrolü
function FiveguardServer.WeaponSecurity.CheckWeaponModifier(playerId, weapon)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local weaponName = GetWeapontypeModel(weapon.hash) or 'unknown'
    local normalDamage = weaponDamageValues[weaponName]
    
    if not normalDamage then return end -- Bilinmeyen silah
    
    local currentDamage = weapon.damage or normalDamage
    local damageModifier = currentDamage / normalDamage
    
    -- Dynamic modifier hesaplama
    local maxModifier = weaponData.config.maxDamageModifier
    if weaponData.config.dynamicModifier then
        maxModifier = FiveguardServer.WeaponSecurity.CalculateDynamicModifier(playerId)
    end
    
    if damageModifier > maxModifier then
        FiveguardServer.WeaponSecurity.HandleWeaponModifier(playerId, weapon, damageModifier, maxModifier)
    end
end

-- Dynamic modifier hesapla
function FiveguardServer.WeaponSecurity.CalculateDynamicModifier(playerId)
    -- Tüm oyuncuların ortalama modifier'ını hesapla
    local totalModifier = 0
    local playerCount = 0
    
    for pId, playerWeapons in pairs(weaponData.playerWeapons) do
        if pId ~= playerId and playerWeapons.weapons then
            for _, weapon in ipairs(playerWeapons.weapons) do
                local weaponName = GetWeapontypeModel(weapon.hash) or 'unknown'
                local normalDamage = weaponDamageValues[weaponName]
                
                if normalDamage and weapon.damage then
                    local modifier = weapon.damage / normalDamage
                    totalModifier = totalModifier + modifier
                    playerCount = playerCount + 1
                end
            end
        end
    end
    
    if playerCount > 0 then
        local averageModifier = totalModifier / playerCount
        return math.max(averageModifier * 1.2, weaponData.config.maxDamageModifier) -- %20 tolerance
    end
    
    return weaponData.config.maxDamageModifier
end

-- Weapon modifier violation'ı işle
function FiveguardServer.WeaponSecurity.HandleWeaponModifier(playerId, weapon, currentModifier, maxModifier)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'weapon_modifier',
        weaponHash = weapon.hash,
        weaponName = GetWeapontypeModel(weapon.hash) or 'unknown',
        currentModifier = currentModifier,
        maxModifier = maxModifier,
        timestamp = os.time(),
        severity = 'high'
    }
    
    -- İstatistikleri güncelle
    weaponData.stats.weaponModifierViolations = weaponData.stats.weaponModifierViolations + 1
    weaponData.stats.lastDetection = os.time()
    
    -- Modifier'ı kaydet
    if not weaponData.weaponModifiers[playerId] then
        weaponData.weaponModifiers[playerId] = {modifiers = {}, violations = 0}
    end
    
    weaponData.weaponModifiers[playerId].violations = weaponData.weaponModifiers[playerId].violations + 1
    
    -- Detection'ı işle
    FiveguardServer.WeaponSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD WEAPON SECURITY]^7 Weapon modifier: ' .. player.name .. 
          ' (' .. detection.weaponName .. ' - ' .. string.format('%.2f', currentModifier) .. ')')
end

-- =============================================
-- AIMBOT DETECTION
-- =============================================

-- Aimbot detection'ı başlat
function FiveguardServer.WeaponSecurity.StartAimbotDetection()
    if not weaponData.config.enableAimbotDetection then
        return
    end
    
    CreateThread(function()
        while weaponData.isActive do
            Wait(1000) -- 1 saniye bekle
            
            -- Aimbot pattern analizi
            for playerId, player in pairs(FiveguardServer.Players or {}) do
                FiveguardServer.WeaponSecurity.AnalyzeAimbotPatterns(playerId)
            end
        end
    end)
end

-- Suspicious aim'i işle
function FiveguardServer.WeaponSecurity.HandleSuspiciousAim(playerId, aimData)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    if not weaponData.playerWeapons[playerId] then
        FiveguardServer.WeaponSecurity.InitializePlayer(playerId)
    end
    
    -- Aim history'ye ekle
    table.insert(weaponData.playerWeapons[playerId].aimHistory, {
        targetCoords = aimData.targetCoords,
        playerCoords = aimData.playerCoords,
        aimAngle = aimData.aimAngle,
        distance = aimData.distance,
        timestamp = GetGameTimer()
    })
    
    -- Offset distance kontrolü
    if aimData.distance and aimData.distance > weaponData.config.aimbotOffsetDistance then
        FiveguardServer.WeaponSecurity.HandleAimbotDetection(playerId, 'offset_distance', aimData)
    end
end

-- Aimbot pattern'lerini analiz et
function FiveguardServer.WeaponSecurity.AnalyzeAimbotPatterns(playerId)
    local playerWeapons = weaponData.playerWeapons[playerId]
    if not playerWeapons or not playerWeapons.aimHistory then return end
    
    local currentTime = GetGameTimer()
    local recentAims = {}
    
    -- Son 10 saniyedeki aim'leri al
    for _, aim in ipairs(playerWeapons.aimHistory) do
        if (currentTime - aim.timestamp) <= 10000 then
            table.insert(recentAims, aim)
        end
    end
    
    if #recentAims < 5 then return end -- Yeterli veri yok
    
    -- Rapid target switching kontrolü
    FiveguardServer.WeaponSecurity.CheckRapidTargetSwitching(playerId, recentAims)
    
    -- Impossible angle kontrolü
    FiveguardServer.WeaponSecurity.CheckImpossibleAngles(playerId, recentAims)
    
    -- Perfect accuracy kontrolü
    FiveguardServer.WeaponSecurity.CheckPerfectAccuracy(playerId)
end

-- Rapid target switching kontrolü
function FiveguardServer.WeaponSecurity.CheckRapidTargetSwitching(playerId, aimHistory)
    local pattern = aimbotPatterns[1] -- rapid_target_switch
    local currentTime = GetGameTimer()
    
    local recentTargets = {}
    for _, aim in ipairs(aimHistory) do
        if (currentTime - aim.timestamp) <= pattern.timeWindow then
            local targetKey = string.format('%.1f_%.1f_%.1f', aim.targetCoords.x, aim.targetCoords.y, aim.targetCoords.z)
            recentTargets[targetKey] = true
        end
    end
    
    local uniqueTargets = 0
    for _ in pairs(recentTargets) do
        uniqueTargets = uniqueTargets + 1
    end
    
    if uniqueTargets >= pattern.threshold then
        FiveguardServer.WeaponSecurity.HandleAimbotDetection(playerId, 'rapid_target_switch', {
            uniqueTargets = uniqueTargets,
            threshold = pattern.threshold
        })
    end
end

-- Impossible angle kontrolü
function FiveguardServer.WeaponSecurity.CheckImpossibleAngles(playerId, aimHistory)
    local pattern = aimbotPatterns[3] -- impossible_angle
    
    for i = 2, #aimHistory do
        local prevAim = aimHistory[i-1]
        local currentAim = aimHistory[i]
        
        local timeDiff = currentAim.timestamp - prevAim.timestamp
        if timeDiff <= pattern.timeWindow then
            local angleDiff = math.abs(currentAim.aimAngle - prevAim.aimAngle)
            
            if angleDiff > pattern.maxAngleChange then
                FiveguardServer.WeaponSecurity.HandleAimbotDetection(playerId, 'impossible_angle', {
                    angleDiff = angleDiff,
                    timeDiff = timeDiff,
                    maxAngle = pattern.maxAngleChange
                })
                break
            end
        end
    end
end

-- Perfect accuracy kontrolü
function FiveguardServer.WeaponSecurity.CheckPerfectAccuracy(playerId)
    local playerWeapons = weaponData.playerWeapons[playerId]
    if not playerWeapons then return end
    
    local pattern = aimbotPatterns[2] -- perfect_accuracy
    
    if playerWeapons.shotsFired >= pattern.minShots then
        local accuracy = playerWeapons.shotsHit / playerWeapons.shotsFired
        
        if accuracy >= pattern.threshold then
            FiveguardServer.WeaponSecurity.HandleAimbotDetection(playerId, 'perfect_accuracy', {
                accuracy = accuracy,
                shotsFired = playerWeapons.shotsFired,
                shotsHit = playerWeapons.shotsHit
            })
        end
    end
    
    -- Headshot ratio kontrolü
    local headshotPattern = aimbotPatterns[4] -- high_headshot_ratio
    if playerWeapons.shotsFired >= headshotPattern.minShots then
        local headshotRatio = playerWeapons.headshotCount / playerWeapons.shotsFired
        
        if headshotRatio >= headshotPattern.threshold then
            FiveguardServer.WeaponSecurity.HandleAimbotDetection(playerId, 'high_headshot_ratio', {
                headshotRatio = headshotRatio,
                headshotCount = playerWeapons.headshotCount,
                shotsFired = playerWeapons.shotsFired
            })
        end
    end
end

-- Aimbot detection'ı işle
function FiveguardServer.WeaponSecurity.HandleAimbotDetection(playerId, detectionType, details)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'aimbot_' .. detectionType,
        details = details,
        timestamp = os.time(),
        severity = 'critical'
    }
    
    -- İstatistikleri güncelle
    weaponData.stats.aimbotDetections = weaponData.stats.aimbotDetections + 1
    weaponData.stats.lastDetection = os.time()
    
    -- Aimbot detection'ları kaydet
    if not weaponData.aimbotDetections[playerId] then
        weaponData.aimbotDetections[playerId] = {}
    end
    
    table.insert(weaponData.aimbotDetections[playerId], detection)
    
    -- Detection'ı işle
    FiveguardServer.WeaponSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD WEAPON SECURITY]^7 Aimbot detection: ' .. player.name .. 
          ' (' .. detectionType .. ')')
end

-- =============================================
-- TAZER PROTECTION
-- =============================================

-- Tazer usage'ı işle
function FiveguardServer.WeaponSecurity.HandleTazerUsage(playerId, targetId, distance)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    if not weaponData.config.enableTazerProtection then
        return
    end
    
    if not weaponData.tazerUsage[playerId] then
        FiveguardServer.WeaponSecurity.InitializePlayer(playerId)
    end
    
    local currentTime = GetGameTimer()
    local tazerData = weaponData.tazerUsage[playerId]
    
    -- Distance kontrolü
    if distance > weaponData.config.tazerMaxDistance then
        FiveguardServer.WeaponSecurity.HandleTazerViolation(playerId, 'max_distance', {
            distance = distance,
            maxDistance = weaponData.config.tazerMaxDistance,
            targetId = targetId
        })
        return
    end
    
    -- Cooldown kontrolü
    if (currentTime - tazerData.lastUsage) < weaponData.config.tazerCooldown then
        FiveguardServer.WeaponSecurity.HandleTazerViolation(playerId, 'cooldown', {
            timeSinceLastUse = currentTime - tazerData.lastUsage,
            cooldown = weaponData.config.tazerCooldown,
            targetId = targetId
        })
        return
    end
    
    -- Usage'ı kaydet
    tazerData.lastUsage = currentTime
    tazerData.usageCount = tazerData.usageCount + 1
end

-- Tazer violation'ı işle
function FiveguardServer.WeaponSecurity.HandleTazerViolation(playerId, violationType, details)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'tazer_' .. violationType,
        details = details,
        timestamp = os.time(),
        severity = 'high'
    }
    
    -- İstatistikleri güncelle
    weaponData.stats.tazerViolations = weaponData.stats.tazerViolations + 1
    weaponData.stats.lastDetection = os.time()
    
    -- Violation'ı kaydet
    weaponData.tazerUsage[playerId].violations = weaponData.tazerUsage[playerId].violations + 1
    
    -- Detection'ı işle
    FiveguardServer.WeaponSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD WEAPON SECURITY]^7 Tazer violation: ' .. player.name .. 
          ' (' .. violationType .. ')')
end

-- =============================================
-- WEAPON DAMAGE HANDLING
-- =============================================

-- Weapon damage'ı işle
function FiveguardServer.WeaponSecurity.HandleWeaponDamage(attackerId, victimId, damage, weaponHash)
    local attacker = FiveguardServer.Players[attackerId]
    if not attacker then return end
    
    if not weaponData.config.enableDamageValidation then
        return
    end
    
    if not weaponData.playerWeapons[attackerId] then
        FiveguardServer.WeaponSecurity.InitializePlayer(attackerId)
    end
    
    local playerWeapons = weaponData.playerWeapons[attackerId]
    
    -- Shot istatistiklerini güncelle
    playerWeapons.shotsFired = playerWeapons.shotsFired + 1
    playerWeapons.lastShotTime = GetGameTimer()
    
    -- Damage hit kontrolü
    if damage > 0 then
        playerWeapons.shotsHit = playerWeapons.shotsHit + 1
        
        -- Headshot kontrolü (damage > normal damage * 2 ise headshot kabul et)
        local weaponName = GetWeapontypeModel(weaponHash) or 'unknown'
        local normalDamage = weaponDamageValues[weaponName]
        
        if normalDamage and damage > (normalDamage * 1.5) then
            playerWeapons.headshotCount = playerWeapons.headshotCount + 1
        end
    end
    
    -- Damage validation
    FiveguardServer.WeaponSecurity.ValidateWeaponDamage(attackerId, damage, weaponHash)
end

-- Weapon damage validation
function FiveguardServer.WeaponSecurity.ValidateWeaponDamage(playerId, damage, weaponHash)
    local weaponName = GetWeapontypeModel(weaponHash) or 'unknown'
    local normalDamage = weaponDamageValues[weaponName]
    
    if not normalDamage then return end -- Bilinmeyen silah
    
    -- Damage çok yüksek mi?
    local maxAllowedDamage = normalDamage * (weaponData.config.maxDamageModifier + 0.5) -- %50 tolerance
    
    if damage > maxAllowedDamage then
        FiveguardServer.WeaponSecurity.HandleDamageViolation(playerId, weaponHash, damage, maxAllowedDamage)
    end
end

-- Damage violation'ı işle
function FiveguardServer.WeaponSecurity.HandleDamageViolation(playerId, weaponHash, damage, maxAllowed)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'damage_violation',
        weaponHash = weaponHash,
        weaponName = GetWeapontypeModel(weaponHash) or 'unknown',
        damage = damage,
        maxAllowed = maxAllowed,
        timestamp = os.time(),
        severity = 'high'
    }
    
    -- İstatistikleri güncelle
    weaponData.stats.damageViolations = weaponData.stats.damageViolations + 1
    weaponData.stats.lastDetection = os.time()
    
    -- Detection'ı işle
    FiveguardServer.WeaponSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD WEAPON SECURITY]^7 Damage violation: ' .. player.name .. 
          ' (' .. detection.weaponName .. ' - ' .. damage .. ' damage)')
end

-- Weapon event'ini işle
function FiveguardServer.WeaponSecurity.HandleWeaponEvent(playerId, data)
    -- Bu fonksiyon weapon give/remove event'leri için kullanılabilir
    -- Şu an için boş bırakıyoruz
end

-- =============================================
-- DETECTION PROCESSING
-- =============================================

-- Detection'ı işle
function FiveguardServer.WeaponSecurity.ProcessDetection(detection)
    -- Severity'ye göre işlem yap
    FiveguardServer.WeaponSecurity.HandleDetectionSeverity(detection)
    
    -- Veritabanına kaydet
    FiveguardServer.WeaponSecurity.SaveDetectionToDatabase(detection)
    
    -- Webhook gönder
    FiveguardServer.WeaponSecurity.SendDetectionWebhook(detection)
    
    -- Protection Manager'a bildir
    if FiveguardServer.ProtectionManager then
        FiveguardServer.ProtectionManager.RecordDetection('weapon_security', {
            type = detection.type,
            severity = detection.severity,
            playerId = detection.playerId,
            timestamp = detection.timestamp
        })
    end
end

-- Detection severity'sini işle
function FiveguardServer.WeaponSecurity.HandleDetectionSeverity(detection)
    if not weaponData.config.autoActionEnabled then
        return
    end
    
    local playerId = detection.playerId
    
    if detection.severity == 'critical' then
        -- Kritik seviye - Ban
        FiveguardServer.WeaponSecurity.BanPlayer(playerId, 'Weapon security violation: ' .. detection.type)
        
    elseif detection.severity == 'high' then
        -- Yüksek seviye - Kick
        FiveguardServer.WeaponSecurity.KickPlayer(playerId, 'Weapon violation detected')
        
    elseif detection.severity == 'medium' then
        -- Orta seviye - Uyarı
        FiveguardServer.WeaponSecurity.WarnPlayer(playerId, 'Weapon security warning')
    end
end

-- Oyuncuyu banla
function FiveguardServer.WeaponSecurity.BanPlayer(playerId, reason)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Ban kaydı
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_bans (player_id, player_name, reason, ban_type, timestamp, expires_at, active) VALUES (?, ?, ?, ?, ?, ?, 1)', {
        playerId,
        player.name,
        reason,
        'weapon_security',
        os.time(),
        os.time() + (14 * 24 * 3600) -- 14 gün
    })
    
    -- Oyuncuyu at
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
    
    print('^1[FIVEGUARD WEAPON SECURITY]^7 Oyuncu banlandı: ' .. player.name .. ' (Sebep: ' .. reason .. ')')
end

-- Oyuncuyu uyar
function FiveguardServer.WeaponSecurity.WarnPlayer(playerId, reason)
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {255, 165, 0},
        multiline = true,
        args = {'FIVEGUARD UYARI', reason}
    })
end

-- Oyuncuyu at
function FiveguardServer.WeaponSecurity.KickPlayer(playerId, reason)
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
end

-- =============================================
-- CLEANUP
-- =============================================

-- Cleanup thread'ini başlat
function FiveguardServer.WeaponSecurity.StartCleanup()
    CreateThread(function()
        while weaponData.isActive do
            Wait(300000) -- 5 dakika bekle
            
            -- Eski aim history'leri temizle
            FiveguardServer.WeaponSecurity.CleanupAimHistory()
            
            -- Eski detection'ları temizle
            FiveguardServer.WeaponSecurity.CleanupDetections()
        end
    end)
end

-- Eski aim history'leri temizle
function FiveguardServer.WeaponSecurity.CleanupAimHistory()
    local currentTime = GetGameTimer()
    local cleanupThreshold = 60000 -- 1 dakika önce
    
    for playerId, playerWeapons in pairs(weaponData.playerWeapons) do
        if playerWeapons.aimHistory then
            local filteredHistory = {}
            for _, aim in ipairs(playerWeapons.aimHistory) do
                if (currentTime - aim.timestamp) <= cleanupThreshold then
                    table.insert(filteredHistory, aim)
                end
            end
            playerWeapons.aimHistory = filteredHistory
        end
    end
end

-- Eski detection'ları temizle
function FiveguardServer.WeaponSecurity.CleanupDetections()
    local currentTime = os.time()
    local cleanupThreshold = currentTime - 3600 -- 1 saat önce
    
    for playerId, detections in pairs(weaponData.aimbotDetections) do
        local filteredDetections = {}
        for _, detection in ipairs(detections) do
            if detection.timestamp > cleanupThreshold then
                table.insert(filteredDetections, detection)
            end
        end
        weaponData.aimbotDetections[playerId] = filteredDetections
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Detection'ı veritabanına kaydet
function FiveguardServer.WeaponSecurity.SaveDetectionToDatabase(detection)
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_weapon_detections (player_id, player_name, detection_type, detection_data, severity, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
        detection.playerId,
        detection.playerName,
        detection.type,
        json.encode(detection),
        detection.severity,
        detection.timestamp
    })
end

-- Detection webhook'u gönder
function FiveguardServer.WeaponSecurity.SendDetectionWebhook(detection)
    local color = 16711680 -- Kırmızı
    if detection.severity == 'high' then
        color = 16776960 -- Sarı
    elseif detection.severity == 'medium' then
        color = 16753920 -- Turuncu
    end
    
    local webhookData = {
        username = 'Fiveguard Weapon Security',
        avatar_url = 'https://i.imgur.com/fiveguard-logo.png',
        embeds = {{
            title = '🔫 Weapon Security Tespit Edildi!',
            color = color,
            fields = {
                {name = 'Oyuncu', value = detection.playerName, inline = true},
                {name = 'Tespit Türü', value = detection.type, inline = true},
                {name = 'Severity', value = detection.severity, inline = true},
                {name = 'Detaylar', value = FiveguardServer.WeaponSecurity.FormatDetectionDetails(detection), inline = false},
                {name = 'Zaman', value = os.date('%Y-%m-%d %H:%M:%S', detection.timestamp), inline = true}
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', detection.timestamp)
        }}
    }
    
    FiveguardServer.Webhook.Send('weapon_security', webhookData)
end

-- Detection detaylarını formatla
function FiveguardServer.WeaponSecurity.FormatDetectionDetails(detection)
    if detection.type == 'blacklisted_weapon' then
        return 'Weapon: ' .. detection.weaponName .. ' (Hash: ' .. detection.weaponHash .. ')'
    elseif detection.type == 'weapon_modifier' then
        return 'Weapon: ' .. detection.weaponName .. ' (Modifier: ' .. string.format('%.2f', detection.currentModifier) .. ')'
    elseif detection.type == 'damage_violation' then
        return 'Weapon: ' .. detection.weaponName .. ' (Damage: ' .. detection.damage .. '/' .. detection.maxAllowed .. ')'
    elseif string.find(detection.type, 'aimbot_') then
        local aimbotType = string.gsub(detection.type, 'aimbot_', '')
        return 'Aimbot Type: ' .. aimbotType .. ' (' .. FiveguardServer.WeaponSecurity.FormatAimbotDetails(detection.details) .. ')'
    elseif string.find(detection.type, 'tazer_') then
        local tazerType = string.gsub(detection.type, 'tazer_', '')
        return 'Tazer Violation: ' .. tazerType .. ' (' .. FiveguardServer.WeaponSecurity.FormatTazerDetails(detection.details) .. ')'
    else
        return 'Weapon security violation'
    end
end

-- Aimbot detaylarını formatla
function FiveguardServer.WeaponSecurity.FormatAimbotDetails(details)
    if details.accuracy then
        return 'Accuracy: ' .. string.format('%.2f%%', details.accuracy * 100)
    elseif details.uniqueTargets then
        return 'Targets: ' .. details.uniqueTargets .. '/' .. details.threshold
    elseif details.angleDiff then
        return 'Angle: ' .. string.format('%.1f°', details.angleDiff) .. ' in ' .. details.timeDiff .. 'ms'
    elseif details.headshotRatio then
        return 'Headshot: ' .. string.format('%.2f%%', details.headshotRatio * 100)
    else
        return 'Suspicious aim pattern'
    end
end

-- Tazer detaylarını formatla
function FiveguardServer.WeaponSecurity.FormatTazerDetails(details)
    if details.distance then
        return 'Distance: ' .. string.format('%.1f', details.distance) .. 'm (Max: ' .. details.maxDistance .. 'm)'
    elseif details.timeSinceLastUse then
        return 'Cooldown: ' .. details.timeSinceLastUse .. 'ms (Required: ' .. details.cooldown .. 'ms)'
    else
        return 'Tazer violation'
    end
end

-- İstatistikleri getir
function FiveguardServer.WeaponSecurity.GetStats()
    return {
        totalWeaponChecks = weaponData.stats.totalWeaponChecks,
        aimbotDetections = weaponData.stats.aimbotDetections,
        weaponModifierViolations = weaponData.stats.weaponModifierViolations,
        tazerViolations = weaponData.stats.tazerViolations,
        blacklistedWeapons = weaponData.stats.blacklistedWeapons,
        damageViolations = weaponData.stats.damageViolations,
        lastDetection = weaponData.stats.lastDetection,
        isActive = weaponData.isActive,
        activePlayers = FiveguardServer.WeaponSecurity.GetActivePlayerCount(),
        totalDetections = FiveguardServer.WeaponSecurity.GetTotalDetectionCount()
    }
end

-- Aktif player sayısını getir
function FiveguardServer.WeaponSecurity.GetActivePlayerCount()
    local count = 0
    for _ in pairs(weaponData.playerWeapons) do
        count = count + 1
    end
    return count
end

-- Toplam detection sayısını getir
function FiveguardServer.WeaponSecurity.GetTotalDetectionCount()
    local count = 0
    for _, detections in pairs(weaponData.aimbotDetections) do
        count = count + #detections
    end
    return count
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Weapon security istatistiklerini getir
function GetWeaponSecurityStats()
    return FiveguardServer.WeaponSecurity.GetStats()
end

-- Weapon security durumunu kontrol et
function IsWeaponSecurityActive()
    return weaponData.isActive
end

-- Player weapon bilgilerini getir
function GetPlayerWeaponInfo(playerId)
    return weaponData.playerWeapons[playerId]
end

-- Player aimbot detection'larını getir
function GetPlayerAimbotDetections(playerId)
    return weaponData.aimbotDetections[playerId] or {}
end

-- Manuel weapon validation
function ValidatePlayerWeapons(playerId)
    FiveguardServer.WeaponSecurity.CheckPlayerWeapons(playerId)
    return true
end

-- Weapon blacklist'e ekle
function AddWeaponToBlacklist(weaponName)
    table.insert(weaponBlacklist, string.upper(weaponName))
    return true
end

-- Weapon blacklist'ten çıkar
function RemoveWeaponFromBlacklist(weaponName)
    for i, blacklistedWeapon in ipairs(weaponBlacklist) do
        if string.upper(blacklistedWeapon) == string.upper(weaponName) then
            table.remove(weaponBlacklist, i)
            return true
        end
    end
    return false
end

print('^2[FIVEGUARD WEAPON SECURITY]^7 Weapon Security Module modülü yüklendi')
