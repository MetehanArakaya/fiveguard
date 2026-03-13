-- FIVEGUARD SCREENSHOT MODULE
-- AI destekli screenshot alma ve OCR entegrasyonu

FiveguardClient.Screenshot = {}

-- =============================================
-- SCREENSHOT DEĞİŞKENLERİ
-- =============================================

local screenshotData = {
    isActive = false,
    lastScreenshot = 0,
    screenshotQueue = {},
    processingQueue = false,
    stats = {
        totalTaken = 0,
        totalSent = 0,
        totalDetections = 0,
        avgProcessingTime = 0
    }
}

-- Screenshot ayarları
local screenshotConfig = {
    quality = 0.8,          -- Kalite (0.1 - 1.0)
    format = "jpg",         -- Format (jpg, png, webp)
    maxWidth = 1920,        -- Maksimum genişlik
    maxHeight = 1080,       -- Maksimum yükseklik
    compression = 0.7,      -- Sıkıştırma oranı
    interval = 30000,       -- Minimum interval (30 saniye)
    maxQueueSize = 10,      -- Maksimum kuyruk boyutu
    timeout = 15000,        -- Timeout süresi
    retryCount = 3          -- Yeniden deneme sayısı
}

-- Trigger türleri
local triggerTypes = {
    MANUAL = "manual",              -- Admin talebi
    SUSPICIOUS = "suspicious",      -- Şüpheli aktivite
    RANDOM = "random",             -- Rastgele kontrol
    BEHAVIORAL = "behavioral",      -- Davranış analizi
    DETECTION = "detection",        -- Tespit sonrası
    PERIODIC = "periodic"          -- Periyodik kontrol
}

-- =============================================
-- SCREENSHOT BAŞLATMA
-- =============================================

function FiveguardClient.Screenshot.Initialize()
    print('^2[FIVEGUARD SCREENSHOT]^7 Screenshot modülü başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardClient.Screenshot.LoadConfig()
    
    -- Event'leri kaydet
    FiveguardClient.Screenshot.RegisterEvents()
    
    -- Periyodik screenshot başlat
    if screenshotConfig.periodicEnabled then
        FiveguardClient.Screenshot.StartPeriodicScreenshots()
    end
    
    -- Kuyruk işleyicisini başlat
    FiveguardClient.Screenshot.StartQueueProcessor()
    
    screenshotData.isActive = true
    print('^2[FIVEGUARD SCREENSHOT]^7 Screenshot modülü hazır')
end

-- Konfigürasyonu yükle
function FiveguardClient.Screenshot.LoadConfig()
    -- Sunucudan konfigürasyon al
    TriggerServerEvent('fiveguard:screenshot:getConfig')
end

-- Event'leri kaydet
function FiveguardClient.Screenshot.RegisterEvents()
    -- Sunucu screenshot talebi
    RegisterNetEvent('fiveguard:screenshot:take')
    AddEventHandler('fiveguard:screenshot:take', function(data)
        FiveguardClient.Screenshot.TakeScreenshot(data)
    end)
    
    -- Konfigürasyon güncellemesi
    RegisterNetEvent('fiveguard:screenshot:updateConfig')
    AddEventHandler('fiveguard:screenshot:updateConfig', function(config)
        FiveguardClient.Screenshot.UpdateConfig(config)
    end)
    
    -- Batch screenshot talebi
    RegisterNetEvent('fiveguard:screenshot:takeBatch')
    AddEventHandler('fiveguard:screenshot:takeBatch', function(requests)
        FiveguardClient.Screenshot.TakeBatchScreenshots(requests)
    end)
end

-- =============================================
-- SCREENSHOT ALMA FONKSİYONLARI
-- =============================================

-- Ana screenshot alma fonksiyonu
function FiveguardClient.Screenshot.TakeScreenshot(requestData)
    if not screenshotData.isActive then
        return false
    end
    
    -- Rate limiting kontrolü
    local currentTime = GetGameTimer()
    if currentTime - screenshotData.lastScreenshot < screenshotConfig.interval then
        if FiveguardClient.Config.debug then
            print('^3[FIVEGUARD SCREENSHOT]^7 Rate limit, screenshot atlandı')
        end
        return false
    end
    
    -- Request verilerini hazırla
    local request = {
        id = requestData.id or FiveguardClient.Screenshot.GenerateId(),
        playerId = FiveguardClient.PlayerData.serverId,
        triggerType = requestData.triggerType or triggerTypes.MANUAL,
        reason = requestData.reason or 'Admin talebi',
        quality = requestData.quality or screenshotConfig.quality,
        format = requestData.format or screenshotConfig.format,
        timestamp = currentTime,
        metadata = requestData.metadata or {},
        priority = requestData.priority or 1,
        retryCount = 0
    }
    
    -- Kuyruğa ekle
    FiveguardClient.Screenshot.AddToQueue(request)
    
    return true
end

-- Kuyruğa screenshot talebi ekle
function FiveguardClient.Screenshot.AddToQueue(request)
    -- Kuyruk boyutu kontrolü
    if #screenshotData.screenshotQueue >= screenshotConfig.maxQueueSize then
        -- En eski talebi kaldır
        table.remove(screenshotData.screenshotQueue, 1)
        
        if FiveguardClient.Config.debug then
            print('^3[FIVEGUARD SCREENSHOT]^7 Kuyruk dolu, eski talep kaldırıldı')
        end
    end
    
    -- Kuyruğa ekle
    table.insert(screenshotData.screenshotQueue, request)
    
    -- Önceliğe göre sırala
    table.sort(screenshotData.screenshotQueue, function(a, b)
        return a.priority > b.priority
    end)
    
    if FiveguardClient.Config.debug then
        print('^2[FIVEGUARD SCREENSHOT]^7 Screenshot talebi kuyruğa eklendi: ' .. request.id)
    end
end

-- Kuyruk işleyicisini başlat
function FiveguardClient.Screenshot.StartQueueProcessor()
    CreateThread(function()
        while screenshotData.isActive do
            Wait(1000) -- 1 saniye bekle
            
            if not screenshotData.processingQueue and #screenshotData.screenshotQueue > 0 then
                FiveguardClient.Screenshot.ProcessQueue()
            end
        end
    end)
end

-- Kuyruktaki screenshot'ları işle
function FiveguardClient.Screenshot.ProcessQueue()
    if screenshotData.processingQueue or #screenshotData.screenshotQueue == 0 then
        return
    end
    
    screenshotData.processingQueue = true
    
    CreateThread(function()
        while #screenshotData.screenshotQueue > 0 do
            local request = table.remove(screenshotData.screenshotQueue, 1)
            
            if request then
                FiveguardClient.Screenshot.ProcessScreenshotRequest(request)
                Wait(2000) -- İşlemler arası bekleme
            end
        end
        
        screenshotData.processingQueue = false
    end)
end

-- Screenshot talebini işle
function FiveguardClient.Screenshot.ProcessScreenshotRequest(request)
    local startTime = GetGameTimer()
    
    if FiveguardClient.Config.debug then
        print('^2[FIVEGUARD SCREENSHOT]^7 Screenshot işleniyor: ' .. request.id)
    end
    
    -- Screenshot al
    FiveguardClient.Screenshot.CaptureScreen(request, function(success, imageData, error)
        local processingTime = GetGameTimer() - startTime
        
        if success and imageData then
            -- Başarılı screenshot
            screenshotData.stats.totalTaken = screenshotData.stats.totalTaken + 1
            screenshotData.lastScreenshot = GetGameTimer()
            
            -- Sunucuya gönder
            FiveguardClient.Screenshot.SendToServer(request, imageData, processingTime)
            
            if FiveguardClient.Config.debug then
                print('^2[FIVEGUARD SCREENSHOT]^7 Screenshot başarıyla alındı: ' .. request.id)
            end
        else
            -- Hata durumu
            print('^1[FIVEGUARD SCREENSHOT]^7 Screenshot hatası: ' .. (error or 'Bilinmeyen hata'))
            
            -- Yeniden dene
            if request.retryCount < screenshotConfig.retryCount then
                request.retryCount = request.retryCount + 1
                FiveguardClient.Screenshot.AddToQueue(request)
                
                if FiveguardClient.Config.debug then
                    print('^3[FIVEGUARD SCREENSHOT]^7 Screenshot yeniden denenecek: ' .. request.id)
                end
            else
                -- Sunucuya hata bildir
                TriggerServerEvent('fiveguard:screenshot:error', {
                    requestId = request.id,
                    error = error or 'Screenshot alınamadı',
                    retryCount = request.retryCount
                })
            end
        end
    end)
end

-- Ekran görüntüsü yakala
function FiveguardClient.Screenshot.CaptureScreen(request, callback)
    -- Menü kontrolü
    if FiveguardClient.Screenshot.IsMenuOpen() then
        callback(false, nil, 'Menü açık, screenshot alınamadı')
        return
    end
    
    -- Oyun durumu kontrolü
    if not FiveguardClient.Screenshot.IsGameReady() then
        callback(false, nil, 'Oyun hazır değil')
        return
    end
    
    -- Screenshot parametreleri
    local options = {
        quality = request.quality,
        format = request.format,
        encoding = 'base64'
    }
    
    -- Timeout ile screenshot al
    local timeoutTimer = nil
    local completed = false
    
    -- Timeout timer
    timeoutTimer = SetTimeout(screenshotConfig.timeout, function()
        if not completed then
            completed = true
            callback(false, nil, 'Screenshot timeout')
        end
    end)
    
    -- Screenshot al
    exports['screenshot-basic']:requestScreenshotUpload(
        'https://api.fiveguard.com/screenshot/upload', -- Placeholder URL
        'screenshot',
        options,
        function(data)
            if completed then return end
            completed = true
            
            -- Timeout timer'ı iptal et
            if timeoutTimer then
                ClearTimeout(timeoutTimer)
            end
            
            if data and data.url then
                -- Base64 data'yı çıkar
                local imageData = FiveguardClient.Screenshot.ExtractImageData(data)
                callback(true, imageData, nil)
            else
                callback(false, nil, 'Screenshot upload başarısız')
            end
        end
    )
end

-- Görüntü verisini çıkar
function FiveguardClient.Screenshot.ExtractImageData(uploadData)
    -- Bu fonksiyon screenshot-basic export'undan gelen veriyi işler
    -- Gerçek uygulamada base64 veriyi çıkarır
    return uploadData.imageData or uploadData.url
end

-- Sunucuya screenshot gönder
function FiveguardClient.Screenshot.SendToServer(request, imageData, processingTime)
    local payload = {
        requestId = request.id,
        playerId = request.playerId,
        triggerType = request.triggerType,
        reason = request.reason,
        imageData = imageData,
        metadata = {
            timestamp = request.timestamp,
            processingTime = processingTime,
            quality = request.quality,
            format = request.format,
            playerPosition = FiveguardClient.PlayerData.position,
            playerHealth = FiveguardClient.PlayerData.health,
            playerArmor = FiveguardClient.PlayerData.armor,
            playerWeapon = FiveguardClient.PlayerData.currentWeapon,
            playerVehicle = FiveguardClient.PlayerData.vehicle,
            gameTime = GetClockHours() .. ':' .. GetClockMinutes(),
            weather = GetPrevWeatherTypeHashName(),
            additional = request.metadata
        }
    }
    
    -- Sunucuya gönder
    TriggerServerEvent('fiveguard:screenshot:process', payload)
    
    screenshotData.stats.totalSent = screenshotData.stats.totalSent + 1
    
    if FiveguardClient.Config.debug then
        print('^2[FIVEGUARD SCREENSHOT]^7 Screenshot sunucuya gönderildi: ' .. request.id)
    end
end

-- =============================================
-- BATCH SCREENSHOT FONKSİYONLARI
-- =============================================

-- Toplu screenshot al
function FiveguardClient.Screenshot.TakeBatchScreenshots(requests)
    if not requests or #requests == 0 then
        return
    end
    
    for _, requestData in ipairs(requests) do
        FiveguardClient.Screenshot.TakeScreenshot(requestData)
        Wait(1000) -- İstekler arası bekleme
    end
end

-- =============================================
-- PERİYODİK SCREENSHOT
-- =============================================

-- Periyodik screenshot'ları başlat
function FiveguardClient.Screenshot.StartPeriodicScreenshots()
    CreateThread(function()
        while screenshotData.isActive do
            local interval = screenshotConfig.periodicInterval or 300000 -- 5 dakika
            Wait(interval)
            
            -- Rastgele screenshot al
            if math.random() < 0.3 then -- %30 şans
                FiveguardClient.Screenshot.TakeScreenshot({
                    triggerType = triggerTypes.PERIODIC,
                    reason = 'Periyodik kontrol',
                    priority = 1
                })
            end
        end
    end)
end

-- =============================================
-- TETİKLEYİCİ FONKSİYONLARI
-- =============================================

-- Şüpheli aktivite sonrası screenshot
function FiveguardClient.Screenshot.OnSuspiciousActivity(activityType, details)
    FiveguardClient.Screenshot.TakeScreenshot({
        triggerType = triggerTypes.SUSPICIOUS,
        reason = 'Şüpheli aktivite: ' .. activityType,
        priority = 3,
        metadata = {
            activityType = activityType,
            details = details
        }
    })
end

-- Tespit sonrası screenshot
function FiveguardClient.Screenshot.OnDetection(detectionType, confidence)
    FiveguardClient.Screenshot.TakeScreenshot({
        triggerType = triggerTypes.DETECTION,
        reason = 'Tespit sonrası: ' .. detectionType,
        priority = 5,
        metadata = {
            detectionType = detectionType,
            confidence = confidence
        }
    })
end

-- Davranış analizi sonrası screenshot
function FiveguardClient.Screenshot.OnBehavioralTrigger(behaviorType, score)
    FiveguardClient.Screenshot.TakeScreenshot({
        triggerType = triggerTypes.BEHAVIORAL,
        reason = 'Davranış analizi: ' .. behaviorType,
        priority = 2,
        metadata = {
            behaviorType = behaviorType,
            score = score
        }
    })
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Menü açık mı kontrol et
function FiveguardClient.Screenshot.IsMenuOpen()
    -- Çeşitli menü sistemlerini kontrol et
    local menuSystems = {
        'esx_menu_default',
        'esx_menu_dialog',
        'qb-menu',
        'ox_lib',
        'menuv'
    }
    
    for _, menuSystem in ipairs(menuSystems) do
        if GetResourceState(menuSystem) == 'started' then
            -- Menu export'larını kontrol et
            local success, isOpen = pcall(function()
                return exports[menuSystem]:IsMenuOpen()
            end)
            
            if success and isOpen then
                return true
            end
        end
    end
    
    -- NUI focus kontrolü
    if HasNuiFocus() then
        return true
    end
    
    -- Pause menu kontrolü
    if IsPauseMenuActive() then
        return true
    end
    
    return false
end

-- Oyun hazır mı kontrol et
function FiveguardClient.Screenshot.IsGameReady()
    local playerPed = PlayerPedId()
    
    -- Oyuncu spawn olmuş mu
    if not DoesEntityExist(playerPed) then
        return false
    end
    
    -- Loading screen aktif mi
    if GetIsLoadingScreenActive() then
        return false
    end
    
    -- Cutscene aktif mi
    if IsCutsceneActive() then
        return false
    end
    
    -- Network aktif mi
    if not NetworkIsPlayerActive(PlayerId()) then
        return false
    end
    
    return true
end

-- Benzersiz ID oluştur
function FiveguardClient.Screenshot.GenerateId()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    local id = ''
    
    for i = 1, 16 do
        local rand = math.random(#chars)
        id = id .. string.sub(chars, rand, rand)
    end
    
    return id .. '_' .. GetGameTimer()
end

-- Konfigürasyonu güncelle
function FiveguardClient.Screenshot.UpdateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if screenshotConfig[key] ~= nil then
            screenshotConfig[key] = value
        end
    end
    
    if FiveguardClient.Config.debug then
        print('^2[FIVEGUARD SCREENSHOT]^7 Konfigürasyon güncellendi')
    end
end

-- İstatistikleri getir
function FiveguardClient.Screenshot.GetStats()
    return {
        totalTaken = screenshotData.stats.totalTaken,
        totalSent = screenshotData.stats.totalSent,
        totalDetections = screenshotData.stats.totalDetections,
        queueSize = #screenshotData.screenshotQueue,
        isActive = screenshotData.isActive,
        lastScreenshot = screenshotData.lastScreenshot
    }
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Manuel screenshot al (diğer resource'lar için)
function TakeManualScreenshot(reason, metadata)
    return FiveguardClient.Screenshot.TakeScreenshot({
        triggerType = triggerTypes.MANUAL,
        reason = reason or 'Manuel screenshot',
        metadata = metadata or {},
        priority = 4
    })
end

-- Screenshot durumunu kontrol et
function IsScreenshotActive()
    return screenshotData.isActive
end

-- Screenshot istatistiklerini getir
function GetScreenshotStats()
    return FiveguardClient.Screenshot.GetStats()
end

-- =============================================
-- CLEANUP
-- =============================================

-- Modülü durdur
function FiveguardClient.Screenshot.Stop()
    screenshotData.isActive = false
    screenshotData.screenshotQueue = {}
    screenshotData.processingQueue = false
    
    print('^3[FIVEGUARD SCREENSHOT]^7 Screenshot modülü durduruldu')
end

print('^2[FIVEGUARD SCREENSHOT]^7 Screenshot modülü yüklendi')
