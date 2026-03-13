-- FIVEGUARD OCR HANDLER MODULE
-- Sunucu tarafı OCR işleme ve AI entegrasyonu

FiveguardServer.OCR = {}

-- =============================================
-- OCR DEĞİŞKENLERİ
-- =============================================

local ocrData = {
    isActive = false,
    processingQueue = {},
    aiServiceUrl = 'http://localhost:8000',
    stats = {
        totalProcessed = 0,
        totalDetections = 0,
        avgProcessingTime = 0,
        falsePositives = 0,
        lastProcessed = 0
    },
    cache = {},
    config = {
        maxQueueSize = 50,
        processingTimeout = 30000,
        retryCount = 3,
        cacheExpiry = 300000, -- 5 dakika
        batchSize = 5,
        detectionThreshold = 0.7,
        enableCache = true,
        enableBatching = true
    }
}

-- OCR sonuç türleri
local resultTypes = {
    CLEAN = 'clean',
    CHEAT_MENU = 'cheat_menu',
    SUSPICIOUS = 'suspicious',
    ERROR = 'error'
}

-- Tespit seviyeleri
local detectionLevels = {
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
    CRITICAL = 4
}

-- =============================================
-- OCR HANDLER BAŞLATMA
-- =============================================

function FiveguardServer.OCR.Initialize()
    print('^2[FIVEGUARD OCR]^7 OCR Handler başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardServer.OCR.LoadConfig()
    
    -- Event'leri kaydet
    FiveguardServer.OCR.RegisterEvents()
    
    -- AI servisini kontrol et
    FiveguardServer.OCR.CheckAIService()
    
    -- İşleme thread'ini başlat
    FiveguardServer.OCR.StartProcessingThread()
    
    -- Cache temizleme thread'ini başlat
    FiveguardServer.OCR.StartCacheCleanup()
    
    ocrData.isActive = true
    print('^2[FIVEGUARD OCR]^7 OCR Handler hazır')
end

-- Konfigürasyonu yükle
function FiveguardServer.OCR.LoadConfig()
    local config = FiveguardServer.Config.Modules.OCRHandler or {}
    
    -- Processing ayarlarını yükle
    if config.processing then
        ocrData.config.maxQueueSize = config.processing.maxQueueSize or ocrData.config.maxQueueSize
        ocrData.config.processingTimeout = config.processing.processingTimeout or ocrData.config.processingTimeout
        ocrData.config.retryCount = config.processing.retryCount or ocrData.config.retryCount
        ocrData.config.cacheExpiry = config.processing.cacheExpiry or ocrData.config.cacheExpiry
        ocrData.config.batchSize = config.processing.batchSize or ocrData.config.batchSize
        ocrData.config.enableCache = config.processing.enableCache ~= nil and config.processing.enableCache or ocrData.config.enableCache
        ocrData.config.enableBatching = config.processing.enableBatching ~= nil and config.processing.enableBatching or ocrData.config.enableBatching
    end
    
    -- Detection ayarlarını yükle
    if config.detection then
        ocrData.config.detectionThreshold = config.detection.detectionThreshold or ocrData.config.detectionThreshold
    end
    
    -- AI service ayarlarını yükle
    if config.aiService then
        ocrData.aiServiceUrl = config.aiService.aiServiceUrl or ocrData.aiServiceUrl
    end
    
    print('^2[FIVEGUARD OCR]^7 Config yüklendi - AI Service: ' .. ocrData.aiServiceUrl)
end

-- Event'leri kaydet
function FiveguardServer.OCR.RegisterEvents()
    -- Screenshot işleme talebi
    RegisterNetEvent('fiveguard:screenshot:process')
    AddEventHandler('fiveguard:screenshot:process', function(payload)
        local playerId = source
        FiveguardServer.OCR.ProcessScreenshot(playerId, payload)
    end)
    
    -- Screenshot hatası
    RegisterNetEvent('fiveguard:screenshot:error')
    AddEventHandler('fiveguard:screenshot:error', function(errorData)
        local playerId = source
        FiveguardServer.OCR.HandleScreenshotError(playerId, errorData)
    end)
    
    -- Konfigürasyon talebi
    RegisterNetEvent('fiveguard:screenshot:getConfig')
    AddEventHandler('fiveguard:screenshot:getConfig', function()
        local playerId = source
        FiveguardServer.OCR.SendConfigToClient(playerId)
    end)
    
    -- Batch işleme talebi
    RegisterNetEvent('fiveguard:ocr:processBatch')
    AddEventHandler('fiveguard:ocr:processBatch', function(batchData)
        local playerId = source
        FiveguardServer.OCR.ProcessBatch(playerId, batchData)
    end)
end

-- =============================================
-- SCREENSHOT İŞLEME FONKSİYONLARI
-- =============================================

-- Screenshot'ı işle
function FiveguardServer.OCR.ProcessScreenshot(playerId, payload)
    if not ocrData.isActive then
        return
    end
    
    -- Oyuncu kontrolü
    local player = FiveguardServer.Players[playerId]
    if not player then
        print('^1[FIVEGUARD OCR]^7 Geçersiz oyuncu: ' .. playerId)
        return
    end
    
    -- Payload doğrulama
    if not payload or not payload.imageData or not payload.requestId then
        print('^1[FIVEGUARD OCR]^7 Geçersiz payload: ' .. playerId)
        return
    end
    
    -- Cache kontrolü
    if ocrData.config.enableCache then
        local cacheResult = FiveguardServer.OCR.CheckCache(payload.imageData)
        if cacheResult then
            FiveguardServer.OCR.HandleOCRResult(playerId, payload, cacheResult)
            return
        end
    end
    
    -- İşleme kuyruğuna ekle
    local request = {
        id = payload.requestId,
        playerId = playerId,
        playerName = GetPlayerName(playerId),
        playerIdentifiers = FiveguardServer.GetPlayerIdentifiers(playerId),
        imageData = payload.imageData,
        triggerType = payload.triggerType,
        reason = payload.reason,
        metadata = payload.metadata,
        timestamp = os.time(),
        retryCount = 0,
        priority = FiveguardServer.OCR.CalculatePriority(payload.triggerType)
    }
    
    FiveguardServer.OCR.AddToQueue(request)
    
    if FiveguardServer.Config.debug then
        print('^2[FIVEGUARD OCR]^7 Screenshot kuyruğa eklendi: ' .. request.id .. ' (Oyuncu: ' .. request.playerName .. ')')
    end
end

-- Kuyruğa ekle
function FiveguardServer.OCR.AddToQueue(request)
    -- Kuyruk boyutu kontrolü
    if #ocrData.processingQueue >= ocrData.config.maxQueueSize then
        -- En düşük öncelikli talebi kaldır
        table.sort(ocrData.processingQueue, function(a, b) return a.priority > b.priority end)
        table.remove(ocrData.processingQueue)
        
        print('^3[FIVEGUARD OCR]^7 Kuyruk dolu, düşük öncelikli talep kaldırıldı')
    end
    
    -- Kuyruğa ekle
    table.insert(ocrData.processingQueue, request)
    
    -- Önceliğe göre sırala
    table.sort(ocrData.processingQueue, function(a, b)
        return a.priority > b.priority
    end)
end

-- Öncelik hesapla
function FiveguardServer.OCR.CalculatePriority(triggerType)
    local priorities = {
        detection = 5,      -- En yüksek öncelik
        suspicious = 4,
        behavioral = 3,
        manual = 2,
        periodic = 1,
        random = 1
    }
    
    return priorities[triggerType] or 1
end

-- =============================================
-- İŞLEME THREAD'İ
-- =============================================

-- İşleme thread'ini başlat
function FiveguardServer.OCR.StartProcessingThread()
    CreateThread(function()
        while ocrData.isActive do
            Wait(1000) -- 1 saniye bekle
            
            if #ocrData.processingQueue > 0 then
                if ocrData.config.enableBatching and #ocrData.processingQueue >= ocrData.config.batchSize then
                    -- Batch işleme
                    FiveguardServer.OCR.ProcessBatchRequests()
                else
                    -- Tekli işleme
                    FiveguardServer.OCR.ProcessSingleRequest()
                end
            end
        end
    end)
end

-- Tekli istek işle
function FiveguardServer.OCR.ProcessSingleRequest()
    local request = table.remove(ocrData.processingQueue, 1)
    if not request then return end
    
    CreateThread(function()
        FiveguardServer.OCR.SendToAIService(request)
    end)
end

-- Batch istekleri işle
function FiveguardServer.OCR.ProcessBatchRequests()
    local batch = {}
    local batchSize = math.min(ocrData.config.batchSize, #ocrData.processingQueue)
    
    for i = 1, batchSize do
        table.insert(batch, table.remove(ocrData.processingQueue, 1))
    end
    
    if #batch > 0 then
        CreateThread(function()
            FiveguardServer.OCR.SendBatchToAIService(batch)
        end)
    end
end

-- =============================================
-- AI SERVİS ENTEGRASYONU
-- =============================================

-- AI servisine gönder
function FiveguardServer.OCR.SendToAIService(request)
    local startTime = os.time()
    
    -- AI servis payload'ı hazırla
    local aiPayload = {
        request_id = request.id,
        player_id = request.playerId,
        image_data = request.imageData,
        metadata = {
            trigger_type = request.triggerType,
            reason = request.reason,
            timestamp = request.timestamp,
            player_name = request.playerName,
            player_identifiers = request.playerIdentifiers,
            additional = request.metadata
        },
        config = {
            detection_threshold = ocrData.config.detectionThreshold,
            enable_ocr = true,
            enable_ai_analysis = true,
            enable_signature_detection = true
        }
    }
    
    -- HTTP isteği gönder
    PerformHttpRequest(ocrData.aiServiceUrl .. '/analyze_screenshot', function(statusCode, response, headers)
        local processingTime = os.time() - startTime
        
        if statusCode == 200 then
            -- Başarılı yanıt
            local success, result = pcall(json.decode, response)
            
            if success and result then
                -- Sonucu işle
                FiveguardServer.OCR.HandleAIResponse(request, result, processingTime)
            else
                -- JSON parse hatası
                FiveguardServer.OCR.HandleAIError(request, 'JSON parse hatası: ' .. (response or 'Boş yanıt'))
            end
        else
            -- HTTP hatası
            FiveguardServer.OCR.HandleAIError(request, 'HTTP hatası: ' .. statusCode .. ' - ' .. (response or 'Bilinmeyen hata'))
        end
    end, 'POST', json.encode(aiPayload), {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bearer ' .. (FiveguardServer.Config.aiApiKey or ''),
        ['User-Agent'] = 'Fiveguard-AntiCheat/1.0'
    })
end

-- Batch'i AI servisine gönder
function FiveguardServer.OCR.SendBatchToAIService(batch)
    local startTime = os.time()
    
    -- Batch payload hazırla
    local batchPayload = {
        batch_id = FiveguardServer.OCR.GenerateBatchId(),
        requests = {}
    }
    
    for _, request in ipairs(batch) do
        table.insert(batchPayload.requests, {
            request_id = request.id,
            player_id = request.playerId,
            image_data = request.imageData,
            metadata = {
                trigger_type = request.triggerType,
                reason = request.reason,
                timestamp = request.timestamp,
                player_name = request.playerName,
                additional = request.metadata
            }
        })
    end
    
    -- HTTP isteği gönder
    PerformHttpRequest(ocrData.aiServiceUrl .. '/analyze_batch', function(statusCode, response, headers)
        local processingTime = os.time() - startTime
        
        if statusCode == 200 then
            local success, results = pcall(json.decode, response)
            
            if success and results and results.results then
                -- Batch sonuçlarını işle
                for _, result in ipairs(results.results) do
                    local request = FiveguardServer.OCR.FindRequestById(batch, result.request_id)
                    if request then
                        FiveguardServer.OCR.HandleAIResponse(request, result, processingTime / #batch)
                    end
                end
            else
                -- Batch hatası - tüm istekleri tekrar kuyruğa ekle
                for _, request in ipairs(batch) do
                    FiveguardServer.OCR.HandleAIError(request, 'Batch işleme hatası')
                end
            end
        else
            -- HTTP hatası - tüm istekleri tekrar kuyruğa ekle
            for _, request in ipairs(batch) do
                FiveguardServer.OCR.HandleAIError(request, 'Batch HTTP hatası: ' .. statusCode)
            end
        end
    end, 'POST', json.encode(batchPayload), {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bearer ' .. (FiveguardServer.Config.aiApiKey or ''),
        ['User-Agent'] = 'Fiveguard-AntiCheat/1.0'
    })
end

-- AI yanıtını işle
function FiveguardServer.OCR.HandleAIResponse(request, result, processingTime)
    -- İstatistikleri güncelle
    ocrData.stats.totalProcessed = ocrData.stats.totalProcessed + 1
    ocrData.stats.lastProcessed = os.time()
    
    -- Ortalama işleme süresini güncelle
    if ocrData.stats.avgProcessingTime == 0 then
        ocrData.stats.avgProcessingTime = processingTime
    else
        ocrData.stats.avgProcessingTime = (ocrData.stats.avgProcessingTime + processingTime) / 2
    end
    
    -- Cache'e ekle
    if ocrData.config.enableCache and result.detected ~= nil then
        FiveguardServer.OCR.AddToCache(request.imageData, result)
    end
    
    -- Sonucu işle
    FiveguardServer.OCR.HandleOCRResult(request.playerId, request, result)
    
    if FiveguardServer.Config.debug then
        print('^2[FIVEGUARD OCR]^7 AI analizi tamamlandı: ' .. request.id .. 
              ' (Tespit: ' .. tostring(result.detected) .. 
              ', Güven: ' .. string.format('%.2f', result.confidence or 0) .. ')')
    end
end

-- AI hatasını işle
function FiveguardServer.OCR.HandleAIError(request, error)
    print('^1[FIVEGUARD OCR]^7 AI servis hatası: ' .. error .. ' (İstek: ' .. request.id .. ')')
    
    -- Yeniden dene
    if request.retryCount < ocrData.config.retryCount then
        request.retryCount = request.retryCount + 1
        FiveguardServer.OCR.AddToQueue(request)
        
        if FiveguardServer.Config.debug then
            print('^3[FIVEGUARD OCR]^7 İstek yeniden denenecek: ' .. request.id .. ' (Deneme: ' .. request.retryCount .. ')')
        end
    else
        -- Hata sonucu oluştur
        local errorResult = {
            detected = false,
            confidence = 0,
            detection_type = resultTypes.ERROR,
            error = error,
            timestamp = os.time()
        }
        
        FiveguardServer.OCR.HandleOCRResult(request.playerId, request, errorResult)
    end
end

-- =============================================
-- SONUÇ İŞLEME
-- =============================================

-- OCR sonucunu işle
function FiveguardServer.OCR.HandleOCRResult(playerId, request, result)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Sonuç verilerini hazırla
    local detectionData = {
        requestId = request.id,
        playerId = playerId,
        playerName = request.playerName,
        playerIdentifiers = request.playerIdentifiers,
        detected = result.detected or false,
        confidence = result.confidence or 0,
        detectionType = result.detection_type or resultTypes.CLEAN,
        triggerType = request.triggerType,
        reason = request.reason,
        timestamp = request.timestamp,
        processingTime = result.processing_time or 0,
        ocrResults = result.ocr_results,
        aiResults = result.ai_results,
        analysisDetails = result.analysis_details,
        metadata = request.metadata
    }
    
    -- Tespit durumuna göre işlem yap
    if result.detected then
        FiveguardServer.OCR.HandleDetection(detectionData)
    else
        FiveguardServer.OCR.HandleCleanResult(detectionData)
    end
    
    -- Sonucu kaydet
    FiveguardServer.OCR.SaveResult(detectionData)
    
    -- Webhook gönder
    FiveguardServer.OCR.SendWebhook(detectionData)
end

-- Tespit durumunu işle
function FiveguardServer.OCR.HandleDetection(data)
    ocrData.stats.totalDetections = ocrData.stats.totalDetections + 1
    
    -- Tespit seviyesini belirle
    local level = FiveguardServer.OCR.CalculateDetectionLevel(data.confidence, data.detectionType)
    
    -- Ceza uygula
    local punishment = FiveguardServer.OCR.DeterminePunishment(level, data.detectionType)
    
    if punishment then
        FiveguardServer.OCR.ApplyPunishment(data.playerId, punishment, data)
    end
    
    -- Admin'leri bilgilendir
    FiveguardServer.OCR.NotifyAdmins(data, level)
    
    print('^1[FIVEGUARD OCR]^7 CHEAT MENÜ TESPİT EDİLDİ! Oyuncu: ' .. data.playerName .. 
          ' (Güven: ' .. string.format('%.2f', data.confidence) .. 
          ', Tür: ' .. data.detectionType .. ')')
end

-- Temiz sonucu işle
function FiveguardServer.OCR.HandleCleanResult(data)
    if FiveguardServer.Config.debug then
        print('^2[FIVEGUARD OCR]^7 Temiz screenshot: ' .. data.playerName .. 
              ' (Güven: ' .. string.format('%.2f', data.confidence) .. ')')
    end
end

-- Tespit seviyesini hesapla
function FiveguardServer.OCR.CalculateDetectionLevel(confidence, detectionType)
    if confidence >= 0.9 then
        return detectionLevels.CRITICAL
    elseif confidence >= 0.8 then
        return detectionLevels.HIGH
    elseif confidence >= 0.6 then
        return detectionLevels.MEDIUM
    else
        return detectionLevels.LOW
    end
end

-- Cezayı belirle
function FiveguardServer.OCR.DeterminePunishment(level, detectionType)
    local punishments = {
        [detectionLevels.CRITICAL] = 'ban',
        [detectionLevels.HIGH] = 'ban',
        [detectionLevels.MEDIUM] = 'kick',
        [detectionLevels.LOW] = 'warn'
    }
    
    return punishments[level]
end

-- Ceza uygula
function FiveguardServer.OCR.ApplyPunishment(playerId, punishment, data)
    local reason = 'Cheat menü tespiti (OCR/AI) - Güven: ' .. string.format('%.2f', data.confidence)
    
    if punishment == 'ban' then
        FiveguardServer.BanPlayer(playerId, reason, 0, 'FIVEGUARD-OCR')
    elseif punishment == 'kick' then
        FiveguardServer.KickPlayer(playerId, reason)
    elseif punishment == 'warn' then
        FiveguardServer.WarnPlayer(playerId, reason)
    end
end

-- Admin'leri bilgilendir
function FiveguardServer.OCR.NotifyAdmins(data, level)
    local message = string.format(
        '^1[FIVEGUARD OCR]^7 Cheat menü tespit edildi!\n' ..
        'Oyuncu: ^3%s^7\n' ..
        'Güven: ^3%.2f^7\n' ..
        'Tür: ^3%s^7\n' ..
        'Seviye: ^3%d^7',
        data.playerName,
        data.confidence,
        data.detectionType,
        level
    )
    
    -- Online admin'lere bildir
    for playerId, player in pairs(FiveguardServer.Players) do
        if player.isAdmin then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 0, 0},
                multiline = true,
                args = {'FIVEGUARD OCR', message}
            })
        end
    end
end

-- =============================================
-- CACHE SİSTEMİ
-- =============================================

-- Cache kontrolü
function FiveguardServer.OCR.CheckCache(imageData)
    if not ocrData.config.enableCache then
        return nil
    end
    
    local hash = FiveguardServer.OCR.CalculateImageHash(imageData)
    local cached = ocrData.cache[hash]
    
    if cached and (os.time() - cached.timestamp) < ocrData.config.cacheExpiry then
        return cached.result
    end
    
    return nil
end

-- Cache'e ekle
function FiveguardServer.OCR.AddToCache(imageData, result)
    if not ocrData.config.enableCache then
        return
    end
    
    local hash = FiveguardServer.OCR.CalculateImageHash(imageData)
    
    ocrData.cache[hash] = {
        result = result,
        timestamp = os.time()
    }
end

-- Cache temizleme
function FiveguardServer.OCR.StartCacheCleanup()
    CreateThread(function()
        while ocrData.isActive do
            Wait(60000) -- 1 dakika bekle
            
            local currentTime = os.time()
            local cleaned = 0
            
            for hash, cached in pairs(ocrData.cache) do
                if (currentTime - cached.timestamp) >= ocrData.config.cacheExpiry then
                    ocrData.cache[hash] = nil
                    cleaned = cleaned + 1
                end
            end
            
            if cleaned > 0 and FiveguardServer.Config.debug then
                print('^3[FIVEGUARD OCR]^7 Cache temizlendi: ' .. cleaned .. ' kayıt')
            end
        end
    end)
end

-- Görüntü hash'i hesapla
function FiveguardServer.OCR.CalculateImageHash(imageData)
    -- Basit hash hesaplama (gerçek uygulamada daha gelişmiş olmalı)
    local hash = 0
    for i = 1, math.min(#imageData, 1000) do
        hash = hash + string.byte(imageData, i)
    end
    return tostring(hash)
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- AI servisini kontrol et
function FiveguardServer.OCR.CheckAIService()
    PerformHttpRequest(ocrData.aiServiceUrl .. '/health', function(statusCode, response, headers)
        if statusCode == 200 then
            print('^2[FIVEGUARD OCR]^7 AI servisi aktif: ' .. ocrData.aiServiceUrl)
        else
            print('^1[FIVEGUARD OCR]^7 AI servisi erişilemez: ' .. ocrData.aiServiceUrl .. ' (Kod: ' .. statusCode .. ')')
        end
    end, 'GET', '', {})
end

-- Batch ID oluştur
function FiveguardServer.OCR.GenerateBatchId()
    return 'batch_' .. os.time() .. '_' .. math.random(1000, 9999)
end

-- İstek ID'sine göre request bul
function FiveguardServer.OCR.FindRequestById(batch, requestId)
    for _, request in ipairs(batch) do
        if request.id == requestId then
            return request
        end
    end
    return nil
end

-- Screenshot hatasını işle
function FiveguardServer.OCR.HandleScreenshotError(playerId, errorData)
    print('^1[FIVEGUARD OCR]^7 Screenshot hatası - Oyuncu: ' .. GetPlayerName(playerId) .. 
          ', Hata: ' .. (errorData.error or 'Bilinmeyen'))
    
    -- Hata logunu kaydet
    FiveguardServer.Logger.LogError('screenshot_error', {
        playerId = playerId,
        playerName = GetPlayerName(playerId),
        error = errorData.error,
        requestId = errorData.requestId,
        retryCount = errorData.retryCount
    })
end

-- İstemciye konfigürasyon gönder
function FiveguardServer.OCR.SendConfigToClient(playerId)
    local clientConfig = {
        quality = 0.8,
        format = 'jpg',
        interval = 30000,
        periodicEnabled = true,
        periodicInterval = 300000
    }
    
    TriggerClientEvent('fiveguard:screenshot:updateConfig', playerId, clientConfig)
end

-- Sonucu kaydet
function FiveguardServer.OCR.SaveResult(data)
    -- Veritabanına kaydet
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_ocr_results (request_id, player_id, player_name, detected, confidence, detection_type, trigger_type, reason, timestamp, ocr_data, ai_data) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        data.requestId,
        data.playerId,
        data.playerName,
        data.detected and 1 or 0,
        data.confidence,
        data.detectionType,
        data.triggerType,
        data.reason,
        data.timestamp,
        json.encode(data.ocrResults or {}),
        json.encode(data.aiResults or {})
    })
end

-- Webhook gönder
function FiveguardServer.OCR.SendWebhook(data)
    if not data.detected then return end
    
    local webhookData = {
        username = 'Fiveguard OCR',
        avatar_url = 'https://i.imgur.com/fiveguard-logo.png',
        embeds = {{
            title = '🔍 Cheat Menü Tespit Edildi!',
            color = 16711680, -- Kırmızı
            fields = {
                {name = 'Oyuncu', value = data.playerName, inline = true},
                {name = 'Güven Skoru', value = string.format('%.2f%%', data.confidence * 100), inline = true},
                {name = 'Tespit Türü', value = data.detectionType, inline = true},
                {name = 'Tetikleyici', value = data.triggerType, inline = true},
                {name = 'Sebep', value = data.reason, inline = false},
                {name = 'Zaman', value = os.date('%Y-%m-%d %H:%M:%S', data.timestamp), inline = true}
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', data.timestamp)
        }}
    }
    
    FiveguardServer.Webhook.Send('ocr_detection', webhookData)
end

-- İstatistikleri getir
function FiveguardServer.OCR.GetStats()
    return {
        totalProcessed = ocrData.stats.totalProcessed,
        totalDetections = ocrData.stats.totalDetections,
        detectionRate = ocrData.stats.totalProcessed > 0 and (ocrData.stats.totalDetections / ocrData.stats.totalProcessed) or 0,
        avgProcessingTime = ocrData.stats.avgProcessingTime,
        queueSize = #ocrData.processingQueue,
        cacheSize = FiveguardServer.OCR.GetCacheSize(),
        isActive = ocrData.isActive,
        lastProcessed = ocrData.stats.lastProcessed
    }
end

-- Cache boyutunu getir
function FiveguardServer.OCR.GetCacheSize()
    local count = 0
    for _ in pairs(ocrData.cache) do
        count = count + 1
    end
    return count
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Manuel screenshot talebi (admin komutu için)
function RequestPlayerScreenshot(playerId, reason, triggerType)
    if not DoesPlayerExist(playerId) then
        return false
    end
    
    TriggerClientEvent('fiveguard:screenshot:take', playerId, {
        triggerType = triggerType or 'manual',
        reason = reason or 'Admin talebi',
        priority = 4
    })
    
    return true
end

-- OCR istatistiklerini getir
function GetOCRStats()
    return FiveguardServer.OCR.GetStats()
end

-- OCR durumunu kontrol et
function IsOCRActive()
    return ocrData.isActive
end

print('^2[FIVEGUARD OCR]^7 OCR Handler modülü yüklendi')
