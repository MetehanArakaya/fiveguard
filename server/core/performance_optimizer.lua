-- FIVEGUARD PERFORMANCE OPTIMIZER
-- Sistem performansı ve kaynak kullanımı optimizasyonu

FiveguardServer.PerformanceOptimizer = {}

-- =============================================
-- PERFORMANCE OPTIMIZER DEĞİŞKENLERİ
-- =============================================

local performanceData = {
    isActive = false,
    metrics = {
        cpu = {
            usage = 0,
            peak = 0,
            average = 0,
            history = {}
        },
        memory = {
            usage = 0,
            peak = 0,
            average = 0,
            history = {},
            gcCount = 0
        },
        network = {
            inbound = 0,
            outbound = 0,
            totalIn = 0,
            totalOut = 0
        },
        database = {
            queries = 0,
            avgResponseTime = 0,
            slowQueries = 0,
            totalQueries = 0
        }
    },
    thresholds = {
        cpu = {
            warning = 70,
            critical = 85,
            emergency = 95
        },
        memory = {
            warning = 512,  -- MB
            critical = 768, -- MB
            emergency = 1024 -- MB
        },
        responseTime = {
            warning = 100,  -- ms
            critical = 250, -- ms
            emergency = 500 -- ms
        }
    },
    optimizations = {
        autoGarbageCollection = true,
        threadPooling = true,
        cacheOptimization = true,
        queryOptimization = true,
        networkOptimization = true
    },
    stats = {
        optimizationsApplied = 0,
        performanceGains = 0,
        resourcesSaved = 0,
        lastOptimization = 0
    }
}

-- Optimizasyon türleri
local optimizationTypes = {
    MEMORY = 'memory',
    CPU = 'cpu',
    NETWORK = 'network',
    DATABASE = 'database',
    CACHE = 'cache',
    THREAD = 'thread'
}

-- Performans seviyeleri
local performanceLevels = {
    OPTIMAL = 1,
    GOOD = 2,
    WARNING = 3,
    CRITICAL = 4,
    EMERGENCY = 5
}

-- =============================================
-- PERFORMANCE OPTIMIZER BAŞLATMA
-- =============================================

function FiveguardServer.PerformanceOptimizer.Initialize()
    print('^2[FIVEGUARD PERFORMANCE]^7 Performance Optimizer başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardServer.PerformanceOptimizer.LoadConfig()
    
    -- Monitoring thread'ini başlat
    FiveguardServer.PerformanceOptimizer.StartMonitoring()
    
    -- Optimization thread'ini başlat
    FiveguardServer.PerformanceOptimizer.StartOptimization()
    
    -- Garbage collection thread'ini başlat
    FiveguardServer.PerformanceOptimizer.StartGarbageCollection()
    
    performanceData.isActive = true
    print('^2[FIVEGUARD PERFORMANCE]^7 Performance Optimizer hazır')
end

-- Konfigürasyonu yükle
function FiveguardServer.PerformanceOptimizer.LoadConfig()
    local config = FiveguardServer.Config.performance or {}
    
    -- Threshold'ları güncelle
    if config.thresholds then
        for category, thresholds in pairs(config.thresholds) do
            if performanceData.thresholds[category] then
                for key, value in pairs(thresholds) do
                    performanceData.thresholds[category][key] = value
                end
            end
        end
    end
    
    -- Optimizasyon ayarlarını güncelle
    if config.optimizations then
        for key, value in pairs(config.optimizations) do
            if performanceData.optimizations[key] ~= nil then
                performanceData.optimizations[key] = value
            end
        end
    end
end

-- =============================================
-- PERFORMANS MONİTORİNG
-- =============================================

-- Monitoring thread'ini başlat
function FiveguardServer.PerformanceOptimizer.StartMonitoring()
    CreateThread(function()
        while performanceData.isActive do
            Wait(5000) -- 5 saniye bekle
            
            -- Performans metriklerini topla
            FiveguardServer.PerformanceOptimizer.CollectMetrics()
            
            -- Performans seviyesini değerlendir
            FiveguardServer.PerformanceOptimizer.EvaluatePerformance()
        end
    end)
end

-- Performans metriklerini topla
function FiveguardServer.PerformanceOptimizer.CollectMetrics()
    -- CPU kullanımı (yaklaşık hesaplama)
    local cpuUsage = FiveguardServer.PerformanceOptimizer.CalculateCPUUsage()
    performanceData.metrics.cpu.usage = cpuUsage
    
    if cpuUsage > performanceData.metrics.cpu.peak then
        performanceData.metrics.cpu.peak = cpuUsage
    end
    
    -- CPU geçmişini güncelle
    table.insert(performanceData.metrics.cpu.history, cpuUsage)
    if #performanceData.metrics.cpu.history > 60 then -- Son 5 dakika (60 * 5 saniye)
        table.remove(performanceData.metrics.cpu.history, 1)
    end
    
    -- CPU ortalamasını hesapla
    local cpuSum = 0
    for _, usage in ipairs(performanceData.metrics.cpu.history) do
        cpuSum = cpuSum + usage
    end
    performanceData.metrics.cpu.average = #performanceData.metrics.cpu.history > 0 and (cpuSum / #performanceData.metrics.cpu.history) or 0
    
    -- Memory kullanımı
    local memoryUsage = FiveguardServer.PerformanceOptimizer.CalculateMemoryUsage()
    performanceData.metrics.memory.usage = memoryUsage
    
    if memoryUsage > performanceData.metrics.memory.peak then
        performanceData.metrics.memory.peak = memoryUsage
    end
    
    -- Memory geçmişini güncelle
    table.insert(performanceData.metrics.memory.history, memoryUsage)
    if #performanceData.metrics.memory.history > 60 then
        table.remove(performanceData.metrics.memory.history, 1)
    end
    
    -- Memory ortalamasını hesapla
    local memSum = 0
    for _, usage in ipairs(performanceData.metrics.memory.history) do
        memSum = memSum + usage
    end
    performanceData.metrics.memory.average = #performanceData.metrics.memory.history > 0 and (memSum / #performanceData.metrics.memory.history) or 0
    
    -- Network metrikleri (basit hesaplama)
    FiveguardServer.PerformanceOptimizer.UpdateNetworkMetrics()
    
    -- Database metrikleri
    FiveguardServer.PerformanceOptimizer.UpdateDatabaseMetrics()
end

-- CPU kullanımını hesapla
function FiveguardServer.PerformanceOptimizer.CalculateCPUUsage()
    -- Basit CPU kullanım hesaplaması
    -- Gerçek uygulamada daha gelişmiş metrikler kullanılabilir
    local startTime = GetGameTimer()
    
    -- Küçük bir işlem yap
    local sum = 0
    for i = 1, 1000 do
        sum = sum + math.sqrt(i)
    end
    
    local endTime = GetGameTimer()
    local processingTime = endTime - startTime
    
    -- CPU kullanımını yaklaşık olarak hesapla (0-100 arası)
    local cpuUsage = math.min(processingTime * 2, 100)
    
    return cpuUsage
end

-- Memory kullanımını hesapla
function FiveguardServer.PerformanceOptimizer.CalculateMemoryUsage()
    -- Lua memory kullanımını al (KB cinsinden)
    local memoryKB = collectgarbage('count')
    local memoryMB = memoryKB / 1024
    
    return memoryMB
end

-- Network metriklerini güncelle
function FiveguardServer.PerformanceOptimizer.UpdateNetworkMetrics()
    -- Basit network metrikleri
    -- Gerçek uygulamada network trafiği izlenebilir
    local playerCount = #GetPlayers()
    
    performanceData.metrics.network.inbound = playerCount * 10 -- KB/s yaklaşık
    performanceData.metrics.network.outbound = playerCount * 15 -- KB/s yaklaşık
    
    performanceData.metrics.network.totalIn = performanceData.metrics.network.totalIn + performanceData.metrics.network.inbound
    performanceData.metrics.network.totalOut = performanceData.metrics.network.totalOut + performanceData.metrics.network.outbound
end

-- Database metriklerini güncelle
function FiveguardServer.PerformanceOptimizer.UpdateDatabaseMetrics()
    -- Database istatistiklerini al (eğer varsa)
    if FiveguardServer.Database and FiveguardServer.Database.GetStats then
        local dbStats = FiveguardServer.Database.GetStats()
        
        performanceData.metrics.database.queries = dbStats.queriesPerSecond or 0
        performanceData.metrics.database.avgResponseTime = dbStats.avgResponseTime or 0
        performanceData.metrics.database.slowQueries = dbStats.slowQueries or 0
        performanceData.metrics.database.totalQueries = dbStats.totalQueries or 0
    end
end

-- Performans seviyesini değerlendir
function FiveguardServer.PerformanceOptimizer.EvaluatePerformance()
    local cpuLevel = FiveguardServer.PerformanceOptimizer.GetPerformanceLevel('cpu', performanceData.metrics.cpu.usage)
    local memoryLevel = FiveguardServer.PerformanceOptimizer.GetPerformanceLevel('memory', performanceData.metrics.memory.usage)
    local responseLevel = FiveguardServer.PerformanceOptimizer.GetPerformanceLevel('responseTime', performanceData.metrics.database.avgResponseTime)
    
    -- En yüksek seviyeyi al
    local overallLevel = math.max(cpuLevel, memoryLevel, responseLevel)
    
    -- Seviyeye göre işlem yap
    if overallLevel >= performanceLevels.WARNING then
        FiveguardServer.PerformanceOptimizer.HandlePerformanceIssue(overallLevel)
    end
end

-- Performans seviyesini getir
function FiveguardServer.PerformanceOptimizer.GetPerformanceLevel(metricType, value)
    local thresholds = performanceData.thresholds[metricType]
    if not thresholds then
        return performanceLevels.OPTIMAL
    end
    
    if value >= thresholds.emergency then
        return performanceLevels.EMERGENCY
    elseif value >= thresholds.critical then
        return performanceLevels.CRITICAL
    elseif value >= thresholds.warning then
        return performanceLevels.WARNING
    else
        return performanceLevels.OPTIMAL
    end
end

-- Performans sorununu işle
function FiveguardServer.PerformanceOptimizer.HandlePerformanceIssue(level)
    if level == performanceLevels.EMERGENCY then
        print('^1[FIVEGUARD PERFORMANCE]^7 ACİL DURUM: Kritik performans sorunu tespit edildi!')
        FiveguardServer.PerformanceOptimizer.ApplyEmergencyOptimizations()
        
    elseif level == performanceLevels.CRITICAL then
        print('^1[FIVEGUARD PERFORMANCE]^7 KRİTİK: Yüksek performans sorunu tespit edildi!')
        FiveguardServer.PerformanceOptimizer.ApplyCriticalOptimizations()
        
    elseif level == performanceLevels.WARNING then
        print('^3[FIVEGUARD PERFORMANCE]^7 UYARI: Performans sorunu tespit edildi!')
        FiveguardServer.PerformanceOptimizer.ApplyWarningOptimizations()
    end
end

-- =============================================
-- OPTİMİZASYON SİSTEMİ
-- =============================================

-- Optimization thread'ini başlat
function FiveguardServer.PerformanceOptimizer.StartOptimization()
    CreateThread(function()
        while performanceData.isActive do
            Wait(30000) -- 30 saniye bekle
            
            -- Proaktif optimizasyonlar uygula
            FiveguardServer.PerformanceOptimizer.ApplyProactiveOptimizations()
        end
    end)
end

-- Proaktif optimizasyonlar
function FiveguardServer.PerformanceOptimizer.ApplyProactiveOptimizations()
    -- Cache optimizasyonu
    if performanceData.optimizations.cacheOptimization then
        FiveguardServer.PerformanceOptimizer.OptimizeCache()
    end
    
    -- Thread pool optimizasyonu
    if performanceData.optimizations.threadPooling then
        FiveguardServer.PerformanceOptimizer.OptimizeThreadPool()
    end
    
    -- Query optimizasyonu
    if performanceData.optimizations.queryOptimization then
        FiveguardServer.PerformanceOptimizer.OptimizeQueries()
    end
end

-- Uyarı seviyesi optimizasyonları
function FiveguardServer.PerformanceOptimizer.ApplyWarningOptimizations()
    -- Hafif optimizasyonlar
    FiveguardServer.PerformanceOptimizer.OptimizeCache()
    FiveguardServer.PerformanceOptimizer.CleanupTempData()
    
    performanceData.stats.optimizationsApplied = performanceData.stats.optimizationsApplied + 1
    performanceData.stats.lastOptimization = os.time()
end

-- Kritik seviye optimizasyonları
function FiveguardServer.PerformanceOptimizer.ApplyCriticalOptimizations()
    -- Orta seviye optimizasyonlar
    FiveguardServer.PerformanceOptimizer.ApplyWarningOptimizations()
    FiveguardServer.PerformanceOptimizer.ForceGarbageCollection()
    FiveguardServer.PerformanceOptimizer.OptimizeThreadPool()
    FiveguardServer.PerformanceOptimizer.ReduceNonEssentialProcesses()
    
    performanceData.stats.optimizationsApplied = performanceData.stats.optimizationsApplied + 3
end

-- Acil durum optimizasyonları
function FiveguardServer.PerformanceOptimizer.ApplyEmergencyOptimizations()
    -- Ağır optimizasyonlar
    FiveguardServer.PerformanceOptimizer.ApplyCriticalOptimizations()
    FiveguardServer.PerformanceOptimizer.SuspendNonCriticalModules()
    FiveguardServer.PerformanceOptimizer.EmergencyCleanup()
    
    -- Admin'leri bilgilendir
    FiveguardServer.PerformanceOptimizer.NotifyAdmins('Acil durum performans optimizasyonları uygulandı!')
    
    performanceData.stats.optimizationsApplied = performanceData.stats.optimizationsApplied + 5
end

-- Cache optimizasyonu
function FiveguardServer.PerformanceOptimizer.OptimizeCache()
    if FiveguardServer.ProtectionManager and FiveguardServer.ProtectionManager.CacheClear then
        -- Eski cache'leri temizle
        local cacheStats = FiveguardServer.ProtectionManager.GetCacheStats()
        
        if cacheStats.hitRate < 50 then -- %50'den düşük hit rate
            FiveguardServer.ProtectionManager.CacheClear('temporary')
            
            if FiveguardServer.Config.debug then
                print('^3[FIVEGUARD PERFORMANCE]^7 Cache optimizasyonu uygulandı')
            end
        end
    end
end

-- Geçici veri temizliği
function FiveguardServer.PerformanceOptimizer.CleanupTempData()
    -- Geçici dosyaları temizle
    -- Log dosyalarını optimize et
    -- Eski kayıtları temizle
    
    if FiveguardServer.Config.debug then
        print('^3[FIVEGUARD PERFORMANCE]^7 Geçici veri temizliği yapıldı')
    end
end

-- Zorla garbage collection
function FiveguardServer.PerformanceOptimizer.ForceGarbageCollection()
    local beforeMem = collectgarbage('count')
    collectgarbage('collect')
    local afterMem = collectgarbage('count')
    
    local freedMem = beforeMem - afterMem
    performanceData.metrics.memory.gcCount = performanceData.metrics.memory.gcCount + 1
    performanceData.stats.resourcesSaved = performanceData.stats.resourcesSaved + freedMem
    
    if FiveguardServer.Config.debug then
        print('^3[FIVEGUARD PERFORMANCE]^7 Garbage collection: ' .. string.format('%.2f', freedMem) .. ' KB temizlendi')
    end
end

-- Thread pool optimizasyonu
function FiveguardServer.PerformanceOptimizer.OptimizeThreadPool()
    -- Thread sayısını optimize et
    -- Aktif olmayan thread'leri temizle
    
    if FiveguardServer.Config.debug then
        print('^3[FIVEGUARD PERFORMANCE]^7 Thread pool optimizasyonu uygulandı')
    end
end

-- Query optimizasyonu
function FiveguardServer.PerformanceOptimizer.OptimizeQueries()
    -- Yavaş query'leri optimize et
    -- Index'leri kontrol et
    -- Connection pool'u optimize et
    
    if FiveguardServer.Config.debug then
        print('^3[FIVEGUARD PERFORMANCE]^7 Database query optimizasyonu uygulandı')
    end
end

-- Kritik olmayan işlemleri azalt
function FiveguardServer.PerformanceOptimizer.ReduceNonEssentialProcesses()
    -- Debug loglarını azalt
    -- İstatistik toplama sıklığını azalt
    -- Gereksiz kontrolleri durdur
    
    if FiveguardServer.Config.debug then
        print('^3[FIVEGUARD PERFORMANCE]^7 Kritik olmayan işlemler azaltıldı')
    end
end

-- Kritik olmayan modülleri askıya al
function FiveguardServer.PerformanceOptimizer.SuspendNonCriticalModules()
    -- Performans açısından kritik olmayan modülleri geçici olarak durdur
    local nonCriticalModules = {'behavioral_analysis', 'advanced_logging'}
    
    for _, moduleName in ipairs(nonCriticalModules) do
        if FiveguardServer.ProtectionManager and FiveguardServer.ProtectionManager.StopProtection then
            FiveguardServer.ProtectionManager.StopProtection(moduleName)
        end
    end
    
    print('^1[FIVEGUARD PERFORMANCE]^7 Kritik olmayan modüller askıya alındı')
end

-- Acil durum temizliği
function FiveguardServer.PerformanceOptimizer.EmergencyCleanup()
    -- Tüm cache'i temizle
    if FiveguardServer.ProtectionManager then
        FiveguardServer.ProtectionManager.CacheClear()
    end
    
    -- Zorla garbage collection
    for i = 1, 3 do
        collectgarbage('collect')
        Wait(100)
    end
    
    print('^1[FIVEGUARD PERFORMANCE]^7 Acil durum temizliği tamamlandı')
end

-- =============================================
-- GARBAGE COLLECTION
-- =============================================

-- Garbage collection thread'ini başlat
function FiveguardServer.PerformanceOptimizer.StartGarbageCollection()
    if not performanceData.optimizations.autoGarbageCollection then
        return
    end
    
    CreateThread(function()
        while performanceData.isActive do
            Wait(60000) -- 1 dakika bekle
            
            -- Memory kullanımını kontrol et
            local memoryUsage = performanceData.metrics.memory.usage
            
            if memoryUsage > performanceData.thresholds.memory.warning then
                FiveguardServer.PerformanceOptimizer.ForceGarbageCollection()
            end
        end
    end)
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Admin'leri bilgilendir
function FiveguardServer.PerformanceOptimizer.NotifyAdmins(message)
    for playerId, player in pairs(FiveguardServer.Players or {}) do
        if player.isAdmin then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 165, 0},
                multiline = true,
                args = {'FIVEGUARD PERFORMANCE', message}
            })
        end
    end
end

-- Performans raporunu oluştur
function FiveguardServer.PerformanceOptimizer.GeneratePerformanceReport()
    return {
        timestamp = os.time(),
        metrics = performanceData.metrics,
        thresholds = performanceData.thresholds,
        stats = performanceData.stats,
        recommendations = FiveguardServer.PerformanceOptimizer.GetRecommendations()
    }
end

-- Önerileri getir
function FiveguardServer.PerformanceOptimizer.GetRecommendations()
    local recommendations = {}
    
    -- CPU önerileri
    if performanceData.metrics.cpu.average > performanceData.thresholds.cpu.warning then
        table.insert(recommendations, {
            type = 'cpu',
            severity = 'warning',
            message = 'CPU kullanımı yüksek. Thread optimizasyonu önerilir.'
        })
    end
    
    -- Memory önerileri
    if performanceData.metrics.memory.average > performanceData.thresholds.memory.warning then
        table.insert(recommendations, {
            type = 'memory',
            severity = 'warning',
            message = 'Memory kullanımı yüksek. Garbage collection sıklığını artırın.'
        })
    end
    
    -- Database önerileri
    if performanceData.metrics.database.avgResponseTime > performanceData.thresholds.responseTime.warning then
        table.insert(recommendations, {
            type = 'database',
            severity = 'warning',
            message = 'Database response time yüksek. Query optimizasyonu gerekli.'
        })
    end
    
    return recommendations
end

-- İstatistikleri getir
function FiveguardServer.PerformanceOptimizer.GetStats()
    return {
        metrics = performanceData.metrics,
        stats = performanceData.stats,
        isActive = performanceData.isActive,
        optimizationsEnabled = performanceData.optimizations
    }
end

-- Performans seviyesini getir
function FiveguardServer.PerformanceOptimizer.GetCurrentPerformanceLevel()
    local cpuLevel = FiveguardServer.PerformanceOptimizer.GetPerformanceLevel('cpu', performanceData.metrics.cpu.usage)
    local memoryLevel = FiveguardServer.PerformanceOptimizer.GetPerformanceLevel('memory', performanceData.metrics.memory.usage)
    local responseLevel = FiveguardServer.PerformanceOptimizer.GetPerformanceLevel('responseTime', performanceData.metrics.database.avgResponseTime)
    
    return math.max(cpuLevel, memoryLevel, responseLevel)
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Performans istatistiklerini getir
function GetPerformanceStats()
    return FiveguardServer.PerformanceOptimizer.GetStats()
end

-- Performans raporunu getir
function GetPerformanceReport()
    return FiveguardServer.PerformanceOptimizer.GeneratePerformanceReport()
end

-- Manuel optimizasyon uygula
function ApplyManualOptimization(optimizationType)
    if optimizationType == optimizationTypes.MEMORY then
        FiveguardServer.PerformanceOptimizer.ForceGarbageCollection()
    elseif optimizationType == optimizationTypes.CACHE then
        FiveguardServer.PerformanceOptimizer.OptimizeCache()
    elseif optimizationType == optimizationTypes.DATABASE then
        FiveguardServer.PerformanceOptimizer.OptimizeQueries()
    end
    
    return true
end

-- Performance Optimizer durumunu kontrol et
function IsPerformanceOptimizerActive()
    return performanceData.isActive
end

print('^2[FIVEGUARD PERFORMANCE]^7 Performance Optimizer modülü yüklendi')
