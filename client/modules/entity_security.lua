-- FIVEGUARD ENTITY SECURITY MODULE
-- State bag overflow ve entity güvenlik koruması

FiveguardClient.EntitySecurity = {}

-- =============================================
-- ENTITY SECURITY DEĞİŞKENLERİ
-- =============================================

local entityData = {
    isActive = false,
    trackedEntities = {},
    playerEntities = {
        vehicles = {},
        peds = {},
        objects = {},
        total = 0
    },
    stateBagMonitor = {
        lastCheck = 0,
        violations = {},
        overflowDetected = false
    },
    stats = {
        totalEntitiesCreated = 0,
        totalEntitiesDeleted = 0,
        violationsDetected = 0,
        stateBagOverflows = 0,
        lastViolation = 0
    }
}

-- Entity limitleri
local entityLimits = {
    vehicles = 10,          -- Maksimum araç sayısı
    peds = 12,             -- Maksimum ped sayısı
    objects = 20,          -- Maksimum obje sayısı
    totalEntities = 40,    -- Toplam entity limiti
    stateBagSize = 1024,   -- State bag boyut limiti (KB)
    creationRate = 5,      -- Saniyede maksimum entity oluşturma
    networkRange = 500.0   -- Network range limiti
}

-- Blacklisted entity'ler
local blacklistedEntities = {
    vehicles = {
        'rhino',           -- Tank
        'lazer',           -- Savaş uçağı
        'hydra',           -- Hydra
        'savage',          -- Savage helikopter
        'buzzard',         -- Buzzard
        'oppressor',       -- Oppressor
        'oppressor2',      -- Oppressor MK2
        'khanjali',        -- Khanjali tank
        'akula',           -- Akula
        'hunter',          -- Hunter
        'annihilator2'     -- Annihilator Stealth
    },
    peds = {
        's_m_y_swat_01',      -- SWAT
        's_m_y_cop_01',       -- Polis
        's_m_m_movalien_01',  -- Alien
        'u_m_y_zombie_01',    -- Zombie
        's_m_y_blackops_01'   -- BlackOps
    },
    objects = {
        'prop_logpile_07b',           -- Log pile
        'hei_prop_carrier_radar_1',   -- Radar
        'prop_rock_1_a',              -- Büyük kaya
        'prop_test_boulder_01',       -- Test boulder
        'apa_mp_apa_crashed_usaf_01a' -- Crashed plane
    }
}

-- Entity oluşturma oranı takibi
local creationRateTracker = {
    timestamps = {},
    maxEntries = 10
}

-- =============================================
-- ENTITY SECURITY BAŞLATMA
-- =============================================

function FiveguardClient.EntitySecurity.Initialize()
    print('^2[FIVEGUARD ENTITY]^7 Entity Security başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardClient.EntitySecurity.LoadConfig()
    
    -- Event'leri kaydet
    FiveguardClient.EntitySecurity.RegisterEvents()
    
    -- Entity monitoring başlat
    FiveguardClient.EntitySecurity.StartEntityMonitoring()
    
    -- State bag monitoring başlat
    FiveguardClient.EntitySecurity.StartStateBagMonitoring()
    
    -- Network entity monitoring başlat
    FiveguardClient.EntitySecurity.StartNetworkMonitoring()
    
    entityData.isActive = true
    print('^2[FIVEGUARD ENTITY]^7 Entity Security hazır')
end

-- Konfigürasyonu yükle
function FiveguardClient.EntitySecurity.LoadConfig()
    -- Sunucudan konfigürasyon al
    TriggerServerEvent('fiveguard:entity:getConfig')
end

-- Event'leri kaydet
function FiveguardClient.EntitySecurity.RegisterEvents()
    -- Konfigürasyon güncellemesi
    RegisterNetEvent('fiveguard:entity:updateConfig')
    AddEventHandler('fiveguard:entity:updateConfig', function(config)
        FiveguardClient.EntitySecurity.UpdateConfig(config)
    end)
    
    -- Entity whitelist güncellemesi
    RegisterNetEvent('fiveguard:entity:updateWhitelist')
    AddEventHandler('fiveguard:entity:updateWhitelist', function(whitelist)
        FiveguardClient.EntitySecurity.UpdateWhitelist(whitelist)
    end)
    
    -- Manual entity check
    RegisterNetEvent('fiveguard:entity:manualCheck')
    AddEventHandler('fiveguard:entity:manualCheck', function()
        FiveguardClient.EntitySecurity.PerformManualCheck()
    end)
end

-- =============================================
-- ENTITY MONİTORİNG
-- =============================================

-- Entity monitoring başlat
function FiveguardClient.EntitySecurity.StartEntityMonitoring()
    CreateThread(function()
        while entityData.isActive do
            Wait(5000) -- 5 saniye bekle
            
            -- Entity sayılarını kontrol et
            FiveguardClient.EntitySecurity.CheckEntityCounts()
            
            -- Blacklisted entity'leri kontrol et
            FiveguardClient.EntitySecurity.CheckBlacklistedEntities()
            
            -- Entity oluşturma oranını kontrol et
            FiveguardClient.EntitySecurity.CheckCreationRate()
            
            -- Orphaned entity'leri temizle
            FiveguardClient.EntitySecurity.CleanupOrphanedEntities()
        end
    end)
end

-- Entity sayılarını kontrol et
function FiveguardClient.EntitySecurity.CheckEntityCounts()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    
    -- Mevcut entity sayılarını say
    local counts = {
        vehicles = 0,
        peds = 0,
        objects = 0,
        total = 0
    }
    
    -- Araçları say
    for vehicle in EnumerateVehicles() do
        if NetworkGetEntityOwner(vehicle) == PlayerId() then
            counts.vehicles = counts.vehicles + 1
            counts.total = counts.total + 1
            
            -- Tracked entities'e ekle
            if not entityData.trackedEntities[vehicle] then
                entityData.trackedEntities[vehicle] = {
                    type = 'vehicle',
                    model = GetEntityModel(vehicle),
                    created = GetGameTimer(),
                    networkId = NetworkGetNetworkIdFromEntity(vehicle)
                }
            end
        end
    end
    
    -- Ped'leri say
    for ped in EnumeratePeds() do
        if ped ~= playerPed and NetworkGetEntityOwner(ped) == PlayerId() then
            counts.peds = counts.peds + 1
            counts.total = counts.total + 1
            
            -- Tracked entities'e ekle
            if not entityData.trackedEntities[ped] then
                entityData.trackedEntities[ped] = {
                    type = 'ped',
                    model = GetEntityModel(ped),
                    created = GetGameTimer(),
                    networkId = NetworkGetNetworkIdFromEntity(ped)
                }
            end
        end
    end
    
    -- Objeleri say
    for object in EnumerateObjects() do
        if NetworkGetEntityOwner(object) == PlayerId() then
            counts.objects = counts.objects + 1
            counts.total = counts.total + 1
            
            -- Tracked entities'e ekle
            if not entityData.trackedEntities[object] then
                entityData.trackedEntities[object] = {
                    type = 'object',
                    model = GetEntityModel(object),
                    created = GetGameTimer(),
                    networkId = NetworkGetNetworkIdFromEntity(object)
                }
            end
        end
    end
    
    -- Limitleri kontrol et
    local violations = {}
    
    if counts.vehicles > entityLimits.vehicles then
        table.insert(violations, {
            type = 'vehicle_limit',
            current = counts.vehicles,
            limit = entityLimits.vehicles,
            severity = 'high'
        })
    end
    
    if counts.peds > entityLimits.peds then
        table.insert(violations, {
            type = 'ped_limit',
            current = counts.peds,
            limit = entityLimits.peds,
            severity = 'high'
        })
    end
    
    if counts.objects > entityLimits.objects then
        table.insert(violations, {
            type = 'object_limit',
            current = counts.objects,
            limit = entityLimits.objects,
            severity = 'medium'
        })
    end
    
    if counts.total > entityLimits.totalEntities then
        table.insert(violations, {
            type = 'total_entity_limit',
            current = counts.total,
            limit = entityLimits.totalEntities,
            severity = 'critical'
        })
    end
    
    -- Violation'ları işle
    if #violations > 0 then
        FiveguardClient.EntitySecurity.HandleViolations(violations, counts)
    end
    
    -- Entity sayılarını güncelle
    entityData.playerEntities = counts
    
    if FiveguardClient.Config.debug then
        print('^3[FIVEGUARD ENTITY]^7 Entity sayıları - Araç: ' .. counts.vehicles .. 
              ', Ped: ' .. counts.peds .. ', Obje: ' .. counts.objects .. ', Toplam: ' .. counts.total)
    end
end

-- Blacklisted entity'leri kontrol et
function FiveguardClient.EntitySecurity.CheckBlacklistedEntities()
    local violations = {}
    
    -- Araçları kontrol et
    for vehicle in EnumerateVehicles() do
        if NetworkGetEntityOwner(vehicle) == PlayerId() then
            local model = GetEntityModel(vehicle)
            local modelName = string.lower(GetDisplayNameFromVehicleModel(model))
            
            for _, blacklisted in ipairs(blacklistedEntities.vehicles) do
                if modelName == blacklisted then
                    table.insert(violations, {
                        type = 'blacklisted_vehicle',
                        entity = vehicle,
                        model = modelName,
                        severity = 'critical'
                    })
                    break
                end
            end
        end
    end
    
    -- Ped'leri kontrol et
    for ped in EnumeratePeds() do
        if ped ~= PlayerPedId() and NetworkGetEntityOwner(ped) == PlayerId() then
            local model = GetEntityModel(ped)
            local modelHash = tostring(model)
            
            for _, blacklisted in ipairs(blacklistedEntities.peds) do
                if modelHash == tostring(GetHashKey(blacklisted)) then
                    table.insert(violations, {
                        type = 'blacklisted_ped',
                        entity = ped,
                        model = blacklisted,
                        severity = 'high'
                    })
                    break
                end
            end
        end
    end
    
    -- Objeleri kontrol et
    for object in EnumerateObjects() do
        if NetworkGetEntityOwner(object) == PlayerId() then
            local model = GetEntityModel(object)
            local modelHash = tostring(model)
            
            for _, blacklisted in ipairs(blacklistedEntities.objects) do
                if modelHash == tostring(GetHashKey(blacklisted)) then
                    table.insert(violations, {
                        type = 'blacklisted_object',
                        entity = object,
                        model = blacklisted,
                        severity = 'high'
                    })
                    break
                end
            end
        end
    end
    
    -- Blacklisted entity violation'larını işle
    if #violations > 0 then
        FiveguardClient.EntitySecurity.HandleBlacklistedEntities(violations)
    end
end

-- Entity oluşturma oranını kontrol et
function FiveguardClient.EntitySecurity.CheckCreationRate()
    local currentTime = GetGameTimer()
    local recentCreations = 0
    
    -- Son 1 saniyedeki oluşturmaları say
    for i = #creationRateTracker.timestamps, 1, -1 do
        local timestamp = creationRateTracker.timestamps[i]
        if currentTime - timestamp <= 1000 then -- 1 saniye
            recentCreations = recentCreations + 1
        else
            break
        end
    end
    
    -- Rate limit kontrolü
    if recentCreations > entityLimits.creationRate then
        local violation = {
            type = 'creation_rate_limit',
            current = recentCreations,
            limit = entityLimits.creationRate,
            severity = 'high',
            timeWindow = 1000
        }
        
        FiveguardClient.EntitySecurity.HandleViolations({violation}, entityData.playerEntities)
    end
end

-- Orphaned entity'leri temizle
function FiveguardClient.EntitySecurity.CleanupOrphanedEntities()
    local cleanedCount = 0
    
    for entity, data in pairs(entityData.trackedEntities) do
        if not DoesEntityExist(entity) then
            -- Entity artık mevcut değil, tracking'den kaldır
            entityData.trackedEntities[entity] = nil
            cleanedCount = cleanedCount + 1
        elseif NetworkGetEntityOwner(entity) ~= PlayerId() then
            -- Entity artık bu oyuncuya ait değil
            entityData.trackedEntities[entity] = nil
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 and FiveguardClient.Config.debug then
        print('^3[FIVEGUARD ENTITY]^7 Orphaned entity temizlendi: ' .. cleanedCount)
    end
end

-- =============================================
-- STATE BAG MONİTORİNG
-- =============================================

-- State bag monitoring başlat
function FiveguardClient.EntitySecurity.StartStateBagMonitoring()
    CreateThread(function()
        while entityData.isActive do
            Wait(10000) -- 10 saniye bekle
            
            -- State bag boyutlarını kontrol et
            FiveguardClient.EntitySecurity.CheckStateBagSizes()
            
            -- State bag overflow tespiti
            FiveguardClient.EntitySecurity.DetectStateBagOverflow()
        end
    end)
end

-- State bag boyutlarını kontrol et
function FiveguardClient.EntitySecurity.CheckStateBagSizes()
    local playerPed = PlayerPedId()
    local violations = {}
    
    -- Player state bag kontrolü
    local playerStateBag = Player(GetPlayerServerId(PlayerId())).state
    if playerStateBag then
        local stateBagSize = FiveguardClient.EntitySecurity.CalculateStateBagSize(playerStateBag)
        
        if stateBagSize > entityLimits.stateBagSize then
            table.insert(violations, {
                type = 'state_bag_overflow',
                target = 'player',
                size = stateBagSize,
                limit = entityLimits.stateBagSize,
                severity = 'critical'
            })
        end
    end
    
    -- Entity state bag'lerini kontrol et
    for entity, data in pairs(entityData.trackedEntities) do
        if DoesEntityExist(entity) then
            local entityStateBag = Entity(entity).state
            if entityStateBag then
                local stateBagSize = FiveguardClient.EntitySecurity.CalculateStateBagSize(entityStateBag)
                
                if stateBagSize > entityLimits.stateBagSize then
                    table.insert(violations, {
                        type = 'entity_state_bag_overflow',
                        target = 'entity',
                        entity = entity,
                        entityType = data.type,
                        size = stateBagSize,
                        limit = entityLimits.stateBagSize,
                        severity = 'high'
                    })
                end
            end
        end
    end
    
    -- State bag violation'larını işle
    if #violations > 0 then
        FiveguardClient.EntitySecurity.HandleStateBagViolations(violations)
    end
end

-- State bag overflow tespiti
function FiveguardClient.EntitySecurity.DetectStateBagOverflow()
    local currentTime = GetGameTimer()
    
    -- Son state bag değişikliklerini kontrol et
    if entityData.stateBagMonitor.lastCheck > 0 then
        local timeDiff = currentTime - entityData.stateBagMonitor.lastCheck
        
        -- Çok hızlı state bag değişiklikleri tespit et
        if timeDiff < 100 then -- 100ms'den hızlı
            entityData.stateBagMonitor.violations[currentTime] = {
                type = 'rapid_state_bag_changes',
                timeDiff = timeDiff,
                severity = 'medium'
            }
            
            -- Eski violation'ları temizle
            for timestamp, _ in pairs(entityData.stateBagMonitor.violations) do
                if currentTime - timestamp > 5000 then -- 5 saniye eski
                    entityData.stateBagMonitor.violations[timestamp] = nil
                end
            end
            
            -- Çok fazla violation varsa overflow tespit et
            local violationCount = 0
            for _ in pairs(entityData.stateBagMonitor.violations) do
                violationCount = violationCount + 1
            end
            
            if violationCount > 10 then
                entityData.stateBagMonitor.overflowDetected = true
                
                local violation = {
                    type = 'state_bag_overflow_attack',
                    violationCount = violationCount,
                    severity = 'critical'
                }
                
                FiveguardClient.EntitySecurity.HandleStateBagViolations({violation})
            end
        end
    end
    
    entityData.stateBagMonitor.lastCheck = currentTime
end

-- State bag boyutunu hesapla
function FiveguardClient.EntitySecurity.CalculateStateBagSize(stateBag)
    local size = 0
    
    -- State bag içeriğini JSON'a çevir ve boyutunu hesapla
    local success, jsonStr = pcall(json.encode, stateBag)
    if success and jsonStr then
        size = #jsonStr
    end
    
    return size
end

-- =============================================
-- NETWORK MONİTORİNG
-- =============================================

-- Network entity monitoring başlat
function FiveguardClient.EntitySecurity.StartNetworkMonitoring()
    CreateThread(function()
        while entityData.isActive do
            Wait(15000) -- 15 saniye bekle
            
            -- Network range kontrolü
            FiveguardClient.EntitySecurity.CheckNetworkRange()
            
            -- Network entity ownership kontrolü
            FiveguardClient.EntitySecurity.CheckEntityOwnership()
        end
    end)
end

-- Network range kontrolü
function FiveguardClient.EntitySecurity.CheckNetworkRange()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local violations = {}
    
    for entity, data in pairs(entityData.trackedEntities) do
        if DoesEntityExist(entity) then
            local entityPos = GetEntityCoords(entity)
            local distance = #(playerPos - entityPos)
            
            if distance > entityLimits.networkRange then
                table.insert(violations, {
                    type = 'network_range_violation',
                    entity = entity,
                    entityType = data.type,
                    distance = distance,
                    limit = entityLimits.networkRange,
                    severity = 'medium'
                })
            end
        end
    end
    
    if #violations > 0 then
        FiveguardClient.EntitySecurity.HandleNetworkViolations(violations)
    end
end

-- Entity ownership kontrolü
function FiveguardClient.EntitySecurity.CheckEntityOwnership()
    local violations = {}
    
    for entity, data in pairs(entityData.trackedEntities) do
        if DoesEntityExist(entity) then
            local owner = NetworkGetEntityOwner(entity)
            
            if owner ~= PlayerId() then
                table.insert(violations, {
                    type = 'entity_ownership_mismatch',
                    entity = entity,
                    entityType = data.type,
                    expectedOwner = PlayerId(),
                    actualOwner = owner,
                    severity = 'low'
                })
            end
        end
    end
    
    if #violations > 0 then
        FiveguardClient.EntitySecurity.HandleOwnershipViolations(violations)
    end
end

-- =============================================
-- VİOLATİON HANDLING
-- =============================================

-- Violation'ları işle
function FiveguardClient.EntitySecurity.HandleViolations(violations, entityCounts)
    for _, violation in ipairs(violations) do
        entityData.stats.violationsDetected = entityData.stats.violationsDetected + 1
        entityData.stats.lastViolation = GetGameTimer()
        
        -- Sunucuya bildir
        TriggerServerEvent('fiveguard:entity:violation', {
            type = violation.type,
            severity = violation.severity,
            current = violation.current,
            limit = violation.limit,
            entityCounts = entityCounts,
            timestamp = GetGameTimer(),
            playerPosition = GetEntityCoords(PlayerPedId())
        })
        
        if FiveguardClient.Config.debug then
            print('^1[FIVEGUARD ENTITY]^7 Entity violation: ' .. violation.type .. 
                  ' (Mevcut: ' .. (violation.current or 'N/A') .. 
                  ', Limit: ' .. (violation.limit or 'N/A') .. ')')
        end
    end
end

-- Blacklisted entity violation'larını işle
function FiveguardClient.EntitySecurity.HandleBlacklistedEntities(violations)
    for _, violation in ipairs(violations) do
        entityData.stats.violationsDetected = entityData.stats.violationsDetected + 1
        
        -- Entity'yi sil
        if DoesEntityExist(violation.entity) then
            DeleteEntity(violation.entity)
            
            if FiveguardClient.Config.debug then
                print('^1[FIVEGUARD ENTITY]^7 Blacklisted entity silindi: ' .. violation.model)
            end
        end
        
        -- Sunucuya bildir
        TriggerServerEvent('fiveguard:entity:blacklisted', {
            type = violation.type,
            model = violation.model,
            severity = violation.severity,
            timestamp = GetGameTimer(),
            playerPosition = GetEntityCoords(PlayerPedId())
        })
    end
end

-- State bag violation'larını işle
function FiveguardClient.EntitySecurity.HandleStateBagViolations(violations)
    for _, violation in ipairs(violations) do
        entityData.stats.stateBagOverflows = entityData.stats.stateBagOverflows + 1
        
        -- Sunucuya bildir
        TriggerServerEvent('fiveguard:entity:stateBagViolation', {
            type = violation.type,
            target = violation.target,
            size = violation.size,
            limit = violation.limit,
            severity = violation.severity,
            timestamp = GetGameTimer()
        })
        
        if FiveguardClient.Config.debug then
            print('^1[FIVEGUARD ENTITY]^7 State bag violation: ' .. violation.type .. 
                  ' (Boyut: ' .. (violation.size or 'N/A') .. ' bytes)')
        end
    end
end

-- Network violation'larını işle
function FiveguardClient.EntitySecurity.HandleNetworkViolations(violations)
    for _, violation in ipairs(violations) do
        -- Uzak entity'leri sil
        if DoesEntityExist(violation.entity) then
            DeleteEntity(violation.entity)
            entityData.trackedEntities[violation.entity] = nil
        end
        
        -- Sunucuya bildir
        TriggerServerEvent('fiveguard:entity:networkViolation', {
            type = violation.type,
            entityType = violation.entityType,
            distance = violation.distance,
            limit = violation.limit,
            severity = violation.severity,
            timestamp = GetGameTimer()
        })
        
        if FiveguardClient.Config.debug then
            print('^3[FIVEGUARD ENTITY]^7 Network violation: ' .. violation.type .. 
                  ' (Mesafe: ' .. string.format('%.2f', violation.distance) .. 'm)')
        end
    end
end

-- Ownership violation'larını işle
function FiveguardClient.EntitySecurity.HandleOwnershipViolations(violations)
    for _, violation in ipairs(violations) do
        -- Tracking'den kaldır
        entityData.trackedEntities[violation.entity] = nil
        
        if FiveguardClient.Config.debug then
            print('^3[FIVEGUARD ENTITY]^7 Ownership mismatch: ' .. violation.entityType .. 
                  ' (Beklenen: ' .. violation.expectedOwner .. ', Gerçek: ' .. violation.actualOwner .. ')')
        end
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Entity oluşturma kaydı
function FiveguardClient.EntitySecurity.RecordEntityCreation()
    local currentTime = GetGameTimer()
    
    -- Timestamp'i ekle
    table.insert(creationRateTracker.timestamps, currentTime)
    
    -- Eski timestamp'leri temizle
    if #creationRateTracker.timestamps > creationRateTracker.maxEntries then
        table.remove(creationRateTracker.timestamps, 1)
    end
    
    entityData.stats.totalEntitiesCreated = entityData.stats.totalEntitiesCreated + 1
end

-- Manuel kontrol gerçekleştir
function FiveguardClient.EntitySecurity.PerformManualCheck()
    print('^2[FIVEGUARD ENTITY]^7 Manuel entity kontrolü başlatılıyor...')
    
    -- Tüm kontrolleri hemen çalıştır
    FiveguardClient.EntitySecurity.CheckEntityCounts()
    FiveguardClient.EntitySecurity.CheckBlacklistedEntities()
    FiveguardClient.EntitySecurity.CheckCreationRate()
    FiveguardClient.EntitySecurity.CheckStateBagSizes()
    FiveguardClient.EntitySecurity.CheckNetworkRange()
    
    print('^2[FIVEGUARD ENTITY]^7 Manuel kontrol tamamlandı')
end

-- Konfigürasyonu güncelle
function FiveguardClient.EntitySecurity.UpdateConfig(newConfig)
    for key, value in pairs(newConfig.limits or {}) do
        if entityLimits[key] ~= nil then
            entityLimits[key] = value
        end
    end
    
    for category, entities in pairs(newConfig.blacklisted or {}) do
        if blacklistedEntities[category] then
            blacklistedEntities[category] = entities
        end
    end
    
    if FiveguardClient.Config.debug then
        print('^2[FIVEGUARD ENTITY]^7 Entity konfigürasyonu güncellendi')
    end
end

-- Whitelist güncelle
function FiveguardClient.EntitySecurity.UpdateWhitelist(whitelist)
    -- Whitelist implementasyonu
    if FiveguardClient.Config.debug then
        print('^2[FIVEGUARD ENTITY]^7 Entity whitelist güncellendi')
    end
end

-- İstatistikleri getir
function FiveguardClient.EntitySecurity.GetStats()
    return {
        totalEntitiesCreated = entityData.stats.totalEntitiesCreated,
        totalEntitiesDeleted = entityData.stats.totalEntitiesDeleted,
        violationsDetected = entityData.stats.violationsDetected,
        stateBagOverflows = entityData.stats.stateBagOverflows,
        lastViolation = entityData.stats.lastViolation,
        currentEntities = entityData.playerEntities,
        trackedEntitiesCount = FiveguardClient.EntitySecurity.GetTrackedEntityCount(),
        isActive = entityData.isActive
    }
end

-- Tracked entity sayısını getir
function FiveguardClient.EntitySecurity.GetTrackedEntityCount()
    local count = 0
    for _ in pairs(entityData.trackedEntities) do
        count = count + 1
    end
    return count
end

-- =============================================
-- ENUMERATOR FONKSİYONLARI
-- =============================================

-- Vehicle enumerator
function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        if not handle or handle == -1 then return end
        
        local success
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success
        
        EndFindVehicle(handle)
    end)
end

-- Ped enumerator
function EnumeratePeds()
    return coroutine.wrap(function()
        local handle, ped = FindFirstPed()
        if not handle or handle == -1 then return end
        
        local success
        repeat
            coroutine.yield(ped)
            success, ped = FindNextPed(handle)
        until not success
        
        EndFindPed(handle)
    end)
end

-- Object enumerator
function EnumerateObjects()
    return coroutine.wrap(function()
        local handle, object = FindFirstObject()
        if not handle or handle == -1 then return end
        
        local success
        repeat
            coroutine.yield(object)
            success, object = FindNextObject(handle)
        until not success
        
        EndFindObject(handle)
    end)
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Entity oluşturma kaydı (diğer resource'lar için)
function RecordEntityCreation()
    FiveguardClient.EntitySecurity.RecordEntityCreation()
end

-- Entity security durumunu kontrol et
function IsEntitySecurityActive()
    return entityData.isActive
end

-- Entity istatistiklerini getir
function GetEntitySecurityStats()
    return FiveguardClient.EntitySecurity
