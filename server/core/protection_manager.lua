-- FIVEGUARD PROTECTION MANAGER
-- Modüler koruma sistemi ve cache yöneticisi

FiveguardServer.ProtectionManager = {}

-- =============================================
-- PROTECTION MANAGER DEĞİŞKENLERİ
-- =============================================

local protectionData = {
    isActive = false,
    loadedProtections = {},
    protectionStates = {},
    cache = {
        data = {},
        expiry = {},
        stats = {
            hits = 0,
            misses = 0,
            evictions = 0
        }
    },
    config = {
        maxCacheSize = 1000,
        defaultCacheExpiry = 300000, -- 5 dakika
        cleanupInterval = 60000,     -- 1 dakika
        enableAutoReload = true,
        enableHotSwap = true,
        enableProfiling = false
    },
    stats = {
        totalProtections = 0,
        activeProtections = 0,
        totalDetections = 0,
        avgResponseTime = 0,
        lastUpdate = 0
    }
}

-- Koruma türleri
local protectionTypes = {
    CLIENT_SIDE = 'client',
    SERVER_SIDE = 'server',
    HYBRID = 'hybrid',
    AI_POWERED = 'ai',
    BEHAVIORAL = 'behavioral'
}

-- Koruma durumları
local protectionStates = {
    INACTIVE = 0,
    ACTIVE = 1,
    SUSPENDED = 2,
    ERROR = 3,
    UPDATING = 4
}

-- Cache türleri
local cacheTypes = {
    PLAYER_DATA = 'player_data',
    DETECTION_RESULTS = 'detection_results',
    CONFIGURATION = 'configuration',
    STATISTICS = 'statistics',
    TEMPORARY = 'temporary'
}

-- =============================================
-- PROTECTION MANAGER BAŞLATMA
-- =============================================

function FiveguardServer.ProtectionManager.Initialize()
    print('^2[FIVEGUARD PROTECTION MANAGER]^7 Protection Manager başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardServer.ProtectionManager.LoadConfig()
    
    -- Cache sistemini başlat
    FiveguardServer.ProtectionManager.InitializeCache()
    
    -- Koruma modüllerini yükle
    FiveguardServer.ProtectionManager.LoadProtectionModules()
    
    -- Monitoring thread'ini başlat
    FiveguardServer.ProtectionManager.StartMonitoring()
    
    -- Cache cleanup thread'ini başlat
    FiveguardServer.ProtectionManager.StartCacheCleanup()
    
    protectionData.isActive = true
    print('^2[FIVEGUARD PROTECTION MANAGER]^7 Protection Manager hazır')
end

-- Konfigürasyonu yükle
function FiveguardServer.ProtectionManager.LoadConfig()
    local config = FiveguardServer.Config.protectionManager or {}
    
    for key, value in pairs(config) do
        if protectionData.config[key] ~= nil then
            protectionData.config[key] = value
        end
    end
end

-- Cache sistemini başlat
function FiveguardServer.ProtectionManager.InitializeCache()
    protectionData.cache = {
        data = {},
        expiry = {},
        stats = {
            hits = 0,
            misses = 0,
            evictions = 0,
            totalSize = 0
        }
    }
    
    print('^2[FIVEGUARD PROTECTION MANAGER]^7 Cache sistemi başlatıldı')
end

-- =============================================
-- KORUMA MODÜLÜ YÖNETİMİ
-- =============================================

-- Koruma modüllerini yükle
function FiveguardServer.ProtectionManager.LoadProtectionModules()
    local protectionModules = {
        -- Temel korumalar
        {
            name = 'godmode',
            type = protectionTypes.CLIENT_SIDE,
            priority = 1,
            enabled = true,
            module = FiveguardClient.GodMode
        },
        {
            name = 'speedhack',
            type = protectionTypes.CLIENT_SIDE,
            priority = 1,
            enabled = true,
            module = FiveguardClient.SpeedHack
        },
        {
            name = 'teleport',
            type = protectionTypes.CLIENT_SIDE,
            priority = 1,
            enabled = true,
            module = FiveguardClient.Teleport
        },
        
        -- Gelişmiş korumalar
        {
            name = 'ocr_detection',
            type = protectionTypes.AI_POWERED,
            priority = 2,
            enabled = true,
            module = FiveguardServer.OCR
        },
        {
            name = 'entity_security',
            type = protectionTypes.HYBRID,
            priority = 2,
            enabled = true,
            module = FiveguardClient.EntitySecurity
        },
        {
            name = 'admin_abuse',
            type = protectionTypes.SERVER_SIDE,
            priority = 3,
            enabled = true,
            module = FiveguardServer.AdminAbuse
        },
        
        -- AI destekli korumalar
        {
            name = 'behavioral_analysis',
            type = protectionTypes.BEHAVIORAL,
            priority = 3,
            enabled = true,
            module = FiveguardServer.BehavioralAnalysis
        }
    }
    
    -- Modülleri yükle
    for _, protection in ipairs(protectionModules) do
        FiveguardServer.ProtectionManager.RegisterProtection(protection)
    end
    
    print('^2[FIVEGUARD PROTECTION MANAGER]^7 ' .. #protectionModules .. ' koruma modülü yüklendi')
end

-- Koruma modülünü kaydet
function FiveguardServer.ProtectionManager.RegisterProtection(protection)
    if not protection.name or not protection.module then
        print('^1[FIVEGUARD PROTECTION MANAGER]^7 Geçersiz koruma modülü')
        return false
    end
    
    -- Koruma verilerini hazırla
    local protectionInfo = {
        name = protection.name,
        type = protection.type or protectionTypes.SERVER_SIDE,
        priority = protection.priority or 5,
        enabled = protection.enabled ~= false,
        module = protection.module,
        state = protectionStates.INACTIVE,
        stats = {
            detections = 0,
            falsePositives = 0,
            avgResponseTime = 0,
            lastDetection = 0,
            uptime = 0,
            startTime = 0
        },
        config = protection.config or {},
        dependencies = protection.dependencies or {},
        version = protection.version or '1.0.0'
    }
    
    -- Kaydet
    protectionData.loadedProtections[protection.name] = protectionInfo
    protectionData.stats.totalProtections = protectionData.stats.totalProtections + 1
    
    -- Etkinse başlat
    if protectionInfo.enabled then
        FiveguardServer.ProtectionManager.StartProtection(protection.name)
    end
    
    return true
end

-- Koruma modülünü başlat
function FiveguardServer.ProtectionManager.StartProtection(protectionName)
    local protection = protectionData.loadedProtections[protectionName]
    if not protection then
        print('^1[FIVEGUARD PROTECTION MANAGER]^7 Koruma modülü bulunamadı: ' .. protectionName)
        return false
    end
    
    if protection.state == protectionStates.ACTIVE then
        return true -- Zaten aktif
    end
    
    -- Bağımlılıkları kontrol et
    if not FiveguardServer.ProtectionManager.CheckDependencies(protection) then
        print('^1[FIVEGUARD PROTECTION MANAGER]^7 Bağımlılık hatası: ' .. protectionName)
        return false
    end
    
    -- Modülü başlat
    protection.state = protectionStates.UPDATING
    
    local success, error = pcall(function()
        if protection.module and protection.module.Initialize then
            protection.module.Initialize()
        end
    end)
    
    if success then
        protection.state = protectionStates.ACTIVE
        protection.stats.startTime = os.time()
        protectionData.stats.activeProtections = protectionData.stats.activeProtections + 1
        
        print('^2[FIVEGUARD PROTECTION MANAGER]^7 Koruma başlatıldı: ' .. protectionName)
        return true
    else
        protection.state = protectionStates.ERROR
        print('^1[FIVEGUARD PROTECTION MANAGER]^7 Koruma başlatma hatası: ' .. protectionName .. ' - ' .. (error or 'Bilinmeyen hata'))
        return false
    end
end

-- Koruma modülünü durdur
function FiveguardServer.ProtectionManager.StopProtection(protectionName)
    local protection = protectionData.loadedProtections[protectionName]
    if not protection then
        return false
    end
    
    if protection.state ~= protectionStates.ACTIVE then
        return true -- Zaten aktif değil
    end
    
    -- Modülü durdur
    protection.state = protectionStates.UPDATING
    
    local success, error = pcall(function()
        if protection.module and protection.module.Stop then
            protection.module.Stop()
        end
    end)
    
    if success then
        protection.state = protectionStates.INACTIVE
        protection.stats.uptime = protection.stats.uptime + (os.time() - protection.stats.startTime)
        protectionData.stats.activeProtections = protectionData.stats.activeProtections - 1
        
        print('^3[FIVEGUARD PROTECTION MANAGER]^7 Koruma durduruldu: ' .. protectionName)
        return true
    else
        protection.state = protectionStates.ERROR
        print('^1[FIVEGUARD PROTECTION MANAGER]^7 Koruma durdurma hatası: ' .. protectionName .. ' - ' .. (error or 'Bilinmeyen hata'))
        return false
    end
end

-- Koruma modülünü yeniden başlat
function FiveguardServer.ProtectionManager.RestartProtection(protectionName)
    FiveguardServer.ProtectionManager.StopProtection(protectionName)
    Wait(1000) -- 1 saniye bekle
    return FiveguardServer.ProtectionManager.StartProtection(protectionName)
end

-- Bağımlılıkları kontrol et
function FiveguardServer.ProtectionManager.CheckDependencies(protection)
    if not protection.dependencies or #protection.dependencies == 0 then
        return true
    end
    
    for _, dependency in ipairs(protection.dependencies) do
        local depProtection = protectionData.loadedProtections[dependency]
        if not depProtection or depProtection.state ~= protectionStates.ACTIVE then
            return false
        end
    end
    
    return true
end

-- =============================================
-- CACHE SİSTEMİ
-- =============================================

-- Cache'e veri ekle
function FiveguardServer.ProtectionManager.CacheSet(key, value, expiry, cacheType)
    if not key or value == nil then
        return false
    end
    
    -- Cache boyutu kontrolü
    if FiveguardServer.ProtectionManager.GetCacheSize() >= protectionData.config.maxCacheSize then
        FiveguardServer.ProtectionManager.EvictOldestCache()
    end
    
    -- Expiry hesapla
    local expiryTime = os.time() + (expiry or protectionData.config.defaultCacheExpiry) / 1000
    
    -- Cache'e ekle
    protectionData.cache.data[key] = {
        value = value,
        type = cacheType or cacheTypes.TEMPORARY,
        timestamp = os.time(),
        accessCount = 0,
        lastAccess = os.time()
    }
    
    protectionData.cache.expiry[key] = expiryTime
    
    return true
end

-- Cache'den veri al
function FiveguardServer.ProtectionManager.CacheGet(key)
    local cached = protectionData.cache.data[key]
    local expiry = protectionData.cache.expiry[key]
    
    if not cached or not expiry then
        protectionData.cache.stats.misses = protectionData.cache.stats.misses + 1
        return nil
    end
    
    -- Expiry kontrolü
    if os.time() > expiry then
        FiveguardServer.ProtectionManager.CacheDelete(key)
        protectionData.cache.stats.misses = protectionData.cache.stats.misses + 1
        return nil
    end
    
    -- Access bilgilerini güncelle
    cached.accessCount = cached.accessCount + 1
    cached.lastAccess = os.time()
    
    protectionData.cache.stats.hits = protectionData.cache.stats.hits + 1
    return cached.value
end

-- Cache'den veri sil
function FiveguardServer.ProtectionManager.CacheDelete(key)
    protectionData.cache.data[key] = nil
    protectionData.cache.expiry[key] = nil
    return true
end

-- Cache'i temizle
function FiveguardServer.ProtectionManager.CacheClear(cacheType)
    if cacheType then
        -- Belirli türdeki cache'leri temizle
        for key, cached in pairs(protectionData.cache.data) do
            if cached.type == cacheType then
                FiveguardServer.ProtectionManager.CacheDelete(key)
            end
        end
    else
        -- Tüm cache'i temizle
        protectionData.cache.data = {}
        protectionData.cache.expiry = {}
    end
    
    return true
end

-- En eski cache'i çıkar
function FiveguardServer.ProtectionManager.EvictOldestCache()
    local oldestKey = nil
    local oldestTime = os.time()
    
    for key, cached in pairs(protectionData.cache.data) do
        if cached.lastAccess < oldestTime then
            oldestTime = cached.lastAccess
            oldestKey = key
        end
    end
    
    if oldestKey then
        FiveguardServer.ProtectionManager.CacheDelete(oldestKey)
        protectionData.cache.stats.evictions = protectionData.cache.stats.evictions + 1
    end
end

-- Cache boyutunu getir
function FiveguardServer.ProtectionManager.GetCacheSize()
    local count = 0
    for _ in pairs(protectionData.cache.data) do
        count = count + 1
    end
    return count
end

-- Cache istatistiklerini getir
function FiveguardServer.ProtectionManager.GetCacheStats()
    local hitRate = 0
    local totalRequests = protectionData.cache.stats.hits + protectionData.cache.stats.misses
    
    if totalRequests > 0 then
        hitRate = (protectionData.cache.stats.hits / totalRequests) * 100
    end
    
    return {
        hits = protectionData.cache.stats.hits,
        misses = protectionData.cache.stats.misses,
        evictions = protectionData.cache.stats.evictions,
        hitRate = hitRate,
        totalSize = FiveguardServer.ProtectionManager.GetCacheSize(),
        maxSize = protectionData.config.maxCacheSize
    }
end

-- =============================================
-- MONİTORİNG VE CLEANUP
-- =============================================

-- Monitoring thread'ini başlat
function FiveguardServer.ProtectionManager.StartMonitoring()
    CreateThread(function()
        while protectionData.isActive do
            Wait(30000) -- 30 saniye bekle
            
            -- Koruma modüllerini kontrol et
            FiveguardServer.ProtectionManager.MonitorProtections()
            
            -- Performans istatistiklerini güncelle
            FiveguardServer.ProtectionManager.UpdateStats()
        end
    end)
end

-- Koruma modüllerini monitör et
function FiveguardServer.ProtectionManager.MonitorProtections()
    for name, protection in pairs(protectionData.loadedProtections) do
        if protection.state == protectionStates.ACTIVE then
            -- Health check
            local isHealthy = FiveguardServer.ProtectionManager.HealthCheck(protection)
            
            if not isHealthy then
                print('^3[FIVEGUARD PROTECTION MANAGER]^7 Koruma sağlıksız, yeniden başlatılıyor: ' .. name)
                FiveguardServer.ProtectionManager.RestartProtection(name)
            end
            
            -- Uptime güncelle
            protection.stats.uptime = protection.stats.uptime + 30 -- 30 saniye
        end
    end
end

-- Health check
function FiveguardServer.ProtectionManager.HealthCheck(protection)
    if not protection.module then
        return false
    end
    
    -- Modülün health_check fonksiyonu varsa çağır
    if protection.module.HealthCheck then
        local success, result = pcall(protection.module.HealthCheck)
        return success and result
    end
    
    return true -- Default olarak sağlıklı kabul et
end

-- İstatistikleri güncelle
function FiveguardServer.ProtectionManager.UpdateStats()
    local totalDetections = 0
    local totalResponseTime = 0
    local activeCount = 0
    
    for _, protection in pairs(protectionData.loadedProtections) do
        if protection.state == protectionStates.ACTIVE then
            activeCount = activeCount + 1
            totalDetections = totalDetections + protection.stats.detections
            totalResponseTime = totalResponseTime + protection.stats.avgResponseTime
        end
    end
    
    protectionData.stats.activeProtections = activeCount
    protectionData.stats.totalDetections = totalDetections
    protectionData.stats.avgResponseTime = activeCount > 0 and (totalResponseTime / activeCount) or 0
    protectionData.stats.lastUpdate = os.time()
end

-- Cache cleanup thread'ini başlat
function FiveguardServer.ProtectionManager.StartCacheCleanup()
    CreateThread(function()
        while protectionData.isActive do
            Wait(protectionData.config.cleanupInterval)
            
            -- Expired cache'leri temizle
            FiveguardServer.ProtectionManager.CleanupExpiredCache()
        end
    end)
end

-- Expired cache'leri temizle
function FiveguardServer.ProtectionManager.CleanupExpiredCache()
    local currentTime = os.time()
    local cleanedCount = 0
    
    for key, expiryTime in pairs(protectionData.cache.expiry) do
        if currentTime > expiryTime then
            FiveguardServer.ProtectionManager.CacheDelete(key)
            cleanedCount = cleanedCount + 1
        end
    end
    
    if cleanedCount > 0 and FiveguardServer.Config.debug then
        print('^3[FIVEGUARD PROTECTION MANAGER]^7 Expired cache temizlendi: ' .. cleanedCount)
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Koruma durumunu getir
function FiveguardServer.ProtectionManager.GetProtectionStatus(protectionName)
    local protection = protectionData.loadedProtections[protectionName]
    if not protection then
        return nil
    end
    
    return {
        name = protection.name,
        type = protection.type,
        state = protection.state,
        enabled = protection.enabled,
        stats = protection.stats,
        uptime = protection.stats.uptime + (protection.state == protectionStates.ACTIVE and (os.time() - protection.stats.startTime) or 0)
    }
end

-- Tüm koruma durumlarını getir
function FiveguardServer.ProtectionManager.GetAllProtectionStatus()
    local statuses = {}
    
    for name, _ in pairs(protectionData.loadedProtections) do
        statuses[name] = FiveguardServer.ProtectionManager.GetProtectionStatus(name)
    end
    
    return statuses
end

-- Koruma istatistiklerini getir
function FiveguardServer.ProtectionManager.GetStats()
    return {
        totalProtections = protectionData.stats.totalProtections,
        activeProtections = protectionData.stats.activeProtections,
        totalDetections = protectionData.stats.totalDetections,
        avgResponseTime = protectionData.stats.avgResponseTime,
        lastUpdate = protectionData.stats.lastUpdate,
        cacheStats = FiveguardServer.ProtectionManager.GetCacheStats(),
        isActive = protectionData.isActive
    }
end

-- Koruma konfigürasyonunu güncelle
function FiveguardServer.ProtectionManager.UpdateProtectionConfig(protectionName, newConfig)
    local protection = protectionData.loadedProtections[protectionName]
    if not protection then
        return false
    end
    
    -- Konfigürasyonu güncelle
    for key, value in pairs(newConfig) do
        protection.config[key] = value
    end
    
    -- Hot reload destekleniyorsa modülü güncelle
    if protectionData.config.enableHotSwap and protection.module and protection.module.UpdateConfig then
        local success, error = pcall(protection.module.UpdateConfig, protection.config)
        if not success then
            print('^1[FIVEGUARD PROTECTION MANAGER]^7 Konfigürasyon güncelleme hatası: ' .. protectionName .. ' - ' .. (error or 'Bilinmeyen hata'))
            return false
        end
    end
    
    return true
end

-- Tespit kaydı
function FiveguardServer.ProtectionManager.RecordDetection(protectionName, detectionData)
    local protection = protectionData.loadedProtections[protectionName]
    if not protection then
        return
    end
    
    -- İstatistikleri güncelle
    protection.stats.detections = protection.stats.detections + 1
    protection.stats.lastDetection = os.time()
    
    -- Response time güncelle
    if detectionData.responseTime then
        if protection.stats.avgResponseTime == 0 then
            protection.stats.avgResponseTime = detectionData.responseTime
        else
            protection.stats.avgResponseTime = (protection.stats.avgResponseTime + detectionData.responseTime) / 2
        end
    end
    
    -- Cache'e kaydet
    local cacheKey = 'detection_' .. protectionName .. '_' .. os.time()
    FiveguardServer.ProtectionManager.CacheSet(cacheKey, detectionData, 3600000, cacheTypes.DETECTION_RESULTS) -- 1 saat
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Koruma durumunu kontrol et
function IsProtectionActive(protectionName)
    local protection = protectionData.loadedProtections[protectionName]
    return protection and protection.state == protectionStates.ACTIVE
end

-- Cache'e veri ekle (diğer modüller için)
function SetCache(key, value, expiry, cacheType)
    return FiveguardServer.ProtectionManager.CacheSet(key, value, expiry, cacheType)
end

-- Cache'den veri al (diğer modüller için)
function GetCache(key)
    return FiveguardServer.ProtectionManager.CacheGet(key)
end

-- Protection Manager istatistiklerini getir
function GetProtectionManagerStats()
    return FiveguardServer.ProtectionManager.GetStats()
end

-- Koruma modülünü yeniden başlat
function RestartProtection(protectionName)
    return FiveguardServer.ProtectionManager.RestartProtection(protectionName)
end

-- Tespit kaydet (diğer modüller için)
function RecordDetection(protectionName, detectionData)
    FiveguardServer.ProtectionManager.RecordDetection(protectionName, detectionData)
end

print('^2[FIVEGUARD PROTECTION MANAGER]^7 Protection Manager modülü yüklendi')
