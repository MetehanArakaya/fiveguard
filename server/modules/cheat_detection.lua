-- FIVEGUARD CHEAT DETECTION ENGINE
-- Gelişmiş cheat tespit algoritmaları ve DUI texture analizi

FiveguardServer.CheatDetection = {}

-- =============================================
-- CHEAT DETECTION DEĞİŞKENLERİ
-- =============================================

local cheatData = {
    isActive = false,
    detections = {},
    suspiciousActivities = {},
    duiTextures = {},
    cheatSignatures = {},
    bypassAttempts = {},
    config = {
        enableDuiDetection = true,
        enableSignatureDetection = true,
        enableBypassDetection = true,
        enableRuntimeAnalysis = true,
        detectionThreshold = 3,
        suspicionTimeout = 300000, -- 5 dakika
        autoActionEnabled = true
    },
    stats = {
        totalDetections = 0,
        duiDetections = 0,
        signatureDetections = 0,
        bypassDetections = 0,
        falsePositives = 0,
        lastDetection = 0
    }
}

-- DUI Texture Blacklist (Cheat menülerinde kullanılan texture'lar)
local duiBlacklist = {
    -- AntiCheese'den alınan DUI blacklist
    'nui://absolute-menu/',
    'nui://brutan-menu/',
    'nui://lynx-menu/',
    'nui://d0pamine/',
    'nui://roc-menu/',
    'nui://blood-x/',
    'nui://nertigel/',
    'nui://kolorek/',
    'nui://melon-menu/',
    'nui://desudo/',
    'nui://falcon-menu/',
    'nui://shadow-menu/',
    'nui://alien-menu/',
    'nui://cat-flacko/',
    'nui://ham-mafia/',
    'nui://skrobek/',
    'nui://theulan/',
    'nui://brutan-premium/',
    'nui://lynx-revolution/',
    'nui://malossi-hosting/',
    'nui://darkside-gang/',
    'nui://sugar-mafia/',
    'nui://xaries/',
    'nui://darmowe-cheaty/',
    'nui://shadow-menu/',
    
    -- Ek cheat menü texture'ları
    'nui://cheat-menu/',
    'nui://mod-menu/',
    'nui://trainer/',
    'nui://injector/',
    'nui://executor/',
    'nui://exploit/',
    'nui://hack-menu/',
    'nui://admin-menu/',
    'nui://god-menu/',
    'nui://super-menu/',
    'nui://ultimate-menu/',
    'nui://premium-menu/',
    'nui://vip-menu/',
    'nui://pro-menu/',
    'nui://advanced-menu/',
    'nui://elite-menu/',
    'nui://master-menu/',
    'nui://king-menu/',
    'nui://legend-menu/',
    'nui://omega-menu/',
    'nui://alpha-menu/',
    'nui://beta-menu/',
    'nui://gamma-menu/',
    'nui://delta-menu/',
    'nui://sigma-menu/',
    'nui://phantom-menu/',
    'nui://ghost-menu/',
    'nui://stealth-menu/',
    'nui://invisible-menu/',
    'nui://hidden-menu/'
}

-- Cheat Signature Patterns
local cheatSignatures = {
    -- Memory patterns
    {
        name = 'cheat_engine_pattern',
        pattern = 'CheatEngine',
        type = 'memory',
        severity = 'critical'
    },
    {
        name = 'mod_menu_pattern',
        pattern = 'ModMenu',
        type = 'memory',
        severity = 'high'
    },
    {
        name = 'trainer_pattern',
        pattern = 'Trainer',
        type = 'memory',
        severity = 'high'
    },
    
    -- Network patterns
    {
        name = 'injection_pattern',
        pattern = 'inject',
        type = 'network',
        severity = 'critical'
    },
    {
        name = 'bypass_pattern',
        pattern = 'bypass',
        type = 'network',
        severity = 'high'
    },
    
    -- File patterns
    {
        name = 'dll_injection',
        pattern = '.dll',
        type = 'file',
        severity = 'medium'
    },
    {
        name = 'exe_injection',
        pattern = '.exe',
        type = 'file',
        severity = 'medium'
    }
}

-- Bypass Detection Patterns
local bypassPatterns = {
    -- Anti-cheat bypass attempts
    'anticheese_bypass',
    'fireac_bypass',
    'ruxoac_bypass',
    'secureserve_bypass',
    'valkyrie_bypass',
    'icarus_bypass',
    'fiveguard_bypass',
    
    -- Generic bypass patterns
    'anticheat_disable',
    'protection_disable',
    'security_bypass',
    'detection_bypass',
    'hook_bypass',
    'memory_bypass',
    'process_bypass',
    'thread_bypass'
}

-- Runtime Analysis Patterns
local runtimePatterns = {
    -- Suspicious function calls
    'SetEntityInvincible',
    'SetPlayerInvincible',
    'SetEntityHealth',
    'SetPedHealth',
    'GiveWeaponToPed',
    'RemoveWeaponFromPed',
    'SetEntityCoords',
    'SetEntityVelocity',
    'NetworkExplodeVehicle',
    'AddExplosion',
    'CreateVehicle',
    'CreatePed',
    'CreateObject',
    'DeleteEntity',
    'DeleteVehicle',
    'DeletePed',
    'DeleteObject'
}

-- =============================================
-- CHEAT DETECTION BAŞLATMA
-- =============================================

function FiveguardServer.CheatDetection.Initialize()
    print('^2[FIVEGUARD CHEAT DETECTION]^7 Cheat Detection Engine başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardServer.CheatDetection.LoadConfig()
    
    -- Event'leri kaydet
    FiveguardServer.CheatDetection.RegisterEvents()
    
    -- Monitoring thread'ini başlat
    FiveguardServer.CheatDetection.StartMonitoring()
    
    -- DUI detection thread'ini başlat
    FiveguardServer.CheatDetection.StartDuiDetection()
    
    -- Runtime analysis thread'ini başlat
    FiveguardServer.CheatDetection.StartRuntimeAnalysis()
    
    cheatData.isActive = true
    print('^2[FIVEGUARD CHEAT DETECTION]^7 Cheat Detection Engine hazır')
end

-- Konfigürasyonu yükle
function FiveguardServer.CheatDetection.LoadConfig()
    local config = FiveguardServer.Config.Modules.CheatDetection or {}
    
    -- Ana ayarları yükle
    cheatData.config.enabled = config.enabled ~= nil and config.enabled or cheatData.config.enabled
    
    -- Detection types'ları yükle
    if config.detectionTypes then
        for key, value in pairs(config.detectionTypes) do
            if cheatData.config[key] ~= nil then
                cheatData.config[key] = value
            end
        end
    end
    
    -- Check intervals'ları yükle
    if config.checkIntervals then
        for key, value in pairs(config.checkIntervals) do
            local configKey = key:gsub('Check', 'CheckInterval')
            if cheatData.config[configKey] then
                cheatData.config[configKey] = value
            end
        end
    end
    
    -- Violations ayarlarını yükle
    if config.violations then
        cheatData.config.maxViolations = config.violations.maxViolations or cheatData.config.maxViolations
        cheatData.config.violationResetTime = config.violations.violationResetTime or cheatData.config.violationResetTime
        cheatData.config.autoActionEnabled = config.violations.autoActionEnabled ~= nil and config.violations.autoActionEnabled or cheatData.config.autoActionEnabled
    end
    
    -- Thresholds'ları yükle
    if config.thresholds then
        for key, value in pairs(config.thresholds) do
            if cheatData.config[key] then
                cheatData.config[key] = value
            end
        end
    end
    
    print('^2[FIVEGUARD CHEAT DETECTION]^7 Config yüklendi - Enabled: ' .. tostring(cheatData.config.enabled))
end

-- Event'leri kaydet
function FiveguardServer.CheatDetection.RegisterEvents()
    -- DUI texture detection
    RegisterNetEvent('fiveguard:cheat:duiDetected')
    AddEventHandler('fiveguard:cheat:duiDetected', function(textureUrl)
        local playerId = source
        FiveguardServer.CheatDetection.HandleDuiDetection(playerId, textureUrl)
    end)
    
    -- Signature detection
    RegisterNetEvent('fiveguard:cheat:signatureDetected')
    AddEventHandler('fiveguard:cheat:signatureDetected', function(signature)
        local playerId = source
        FiveguardServer.CheatDetection.HandleSignatureDetection(playerId, signature)
    end)
    
    -- Bypass attempt detection
    RegisterNetEvent('fiveguard:cheat:bypassAttempt')
    AddEventHandler('fiveguard:cheat:bypassAttempt', function(bypassType)
        local playerId = source
        FiveguardServer.CheatDetection.HandleBypassAttempt(playerId, bypassType)
    end)
    
    -- Runtime analysis
    RegisterNetEvent('fiveguard:cheat:runtimeSuspicious')
    AddEventHandler('fiveguard:cheat:runtimeSuspicious', function(functionCall, parameters)
        local playerId = source
        FiveguardServer.CheatDetection.HandleRuntimeSuspicious(playerId, functionCall, parameters)
    end)
end

-- =============================================
-- DUI TEXTURE DETECTION
-- =============================================

-- DUI detection thread'ini başlat
function FiveguardServer.CheatDetection.StartDuiDetection()
    if not cheatData.config.enableDuiDetection then
        return
    end
    
    CreateThread(function()
        while cheatData.isActive do
            Wait(10000) -- 10 saniye bekle
            
            -- Tüm oyuncuları kontrol et
            for playerId, player in pairs(FiveguardServer.Players or {}) do
                FiveguardServer.CheatDetection.CheckPlayerDui(playerId)
            end
        end
    end)
end

-- Oyuncunun DUI texture'larını kontrol et
function FiveguardServer.CheatDetection.CheckPlayerDui(playerId)
    -- Client'tan DUI texture listesini iste
    TriggerClientEvent('fiveguard:cheat:requestDuiList', playerId)
end

-- DUI detection'ı işle
function FiveguardServer.CheatDetection.HandleDuiDetection(playerId, textureUrl)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Blacklist kontrolü
    for _, blacklistedUrl in ipairs(duiBlacklist) do
        if string.find(string.lower(textureUrl), string.lower(blacklistedUrl)) then
            -- Cheat menü texture'ı tespit edildi
            local detection = {
                playerId = playerId,
                playerName = player.name,
                type = 'dui_texture',
                textureUrl = textureUrl,
                blacklistedPattern = blacklistedUrl,
                timestamp = os.time(),
                severity = 'critical'
            }
            
            FiveguardServer.CheatDetection.ProcessDetection(detection)
            return
        end
    end
    
    -- Şüpheli pattern kontrolü
    local suspiciousPatterns = {'menu', 'cheat', 'hack', 'mod', 'trainer', 'inject'}
    for _, pattern in ipairs(suspiciousPatterns) do
        if string.find(string.lower(textureUrl), pattern) then
            local detection = {
                playerId = playerId,
                playerName = player.name,
                type = 'suspicious_dui',
                textureUrl = textureUrl,
                suspiciousPattern = pattern,
                timestamp = os.time(),
                severity = 'medium'
            }
            
            FiveguardServer.CheatDetection.ProcessDetection(detection)
            return
        end
    end
end

-- =============================================
-- SIGNATURE DETECTION
-- =============================================

-- Signature detection'ı işle
function FiveguardServer.CheatDetection.HandleSignatureDetection(playerId, signature)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Signature pattern kontrolü
    for _, cheatSig in ipairs(cheatSignatures) do
        if string.find(string.lower(signature), string.lower(cheatSig.pattern)) then
            local detection = {
                playerId = playerId,
                playerName = player.name,
                type = 'cheat_signature',
                signature = signature,
                matchedPattern = cheatSig,
                timestamp = os.time(),
                severity = cheatSig.severity
            }
            
            FiveguardServer.CheatDetection.ProcessDetection(detection)
            return
        end
    end
end

-- =============================================
-- BYPASS DETECTION
-- =============================================

-- Bypass attempt'i işle
function FiveguardServer.CheatDetection.HandleBypassAttempt(playerId, bypassType)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Bypass pattern kontrolü
    for _, pattern in ipairs(bypassPatterns) do
        if string.find(string.lower(bypassType), pattern) then
            local detection = {
                playerId = playerId,
                playerName = player.name,
                type = 'bypass_attempt',
                bypassType = bypassType,
                matchedPattern = pattern,
                timestamp = os.time(),
                severity = 'critical'
            }
            
            FiveguardServer.CheatDetection.ProcessDetection(detection)
            
            -- Bypass attempt'leri kaydet
            if not cheatData.bypassAttempts[playerId] then
                cheatData.bypassAttempts[playerId] = {}
            end
            
            table.insert(cheatData.bypassAttempts[playerId], {
                type = bypassType,
                timestamp = os.time()
            })
            
            return
        end
    end
end

-- =============================================
-- RUNTIME ANALYSIS
-- =============================================

-- Runtime analysis thread'ini başlat
function FiveguardServer.CheatDetection.StartRuntimeAnalysis()
    if not cheatData.config.enableRuntimeAnalysis then
        return
    end
    
    CreateThread(function()
        while cheatData.isActive do
            Wait(5000) -- 5 saniye bekle
            
            -- Runtime pattern analizi
            FiveguardServer.CheatDetection.AnalyzeRuntimePatterns()
        end
    end)
end

-- Runtime pattern'leri analiz et
function FiveguardServer.CheatDetection.AnalyzeRuntimePatterns()
    -- Bu fonksiyon client-side hook'lar ile birlikte çalışır
    -- Client'tan gelen şüpheli function call'ları analiz eder
end

-- Runtime suspicious activity'yi işle
function FiveguardServer.CheatDetection.HandleRuntimeSuspicious(playerId, functionCall, parameters)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Runtime pattern kontrolü
    for _, pattern in ipairs(runtimePatterns) do
        if string.find(functionCall, pattern) then
            local detection = {
                playerId = playerId,
                playerName = player.name,
                type = 'runtime_suspicious',
                functionCall = functionCall,
                parameters = parameters,
                matchedPattern = pattern,
                timestamp = os.time(),
                severity = 'high'
            }
            
            FiveguardServer.CheatDetection.ProcessDetection(detection)
            return
        end
    end
end

-- =============================================
-- DETECTION PROCESSING
-- =============================================

-- Detection'ı işle
function FiveguardServer.CheatDetection.ProcessDetection(detection)
    -- Detection'ı kaydet
    if not cheatData.detections[detection.playerId] then
        cheatData.detections[detection.playerId] = {}
    end
    
    table.insert(cheatData.detections[detection.playerId], detection)
    
    -- İstatistikleri güncelle
    cheatData.stats.totalDetections = cheatData.stats.totalDetections + 1
    cheatData.stats.lastDetection = os.time()
    
    if detection.type == 'dui_texture' or detection.type == 'suspicious_dui' then
        cheatData.stats.duiDetections = cheatData.stats.duiDetections + 1
    elseif detection.type == 'cheat_signature' then
        cheatData.stats.signatureDetections = cheatData.stats.signatureDetections + 1
    elseif detection.type == 'bypass_attempt' then
        cheatData.stats.bypassDetections = cheatData.stats.bypassDetections + 1
    end
    
    -- Severity'ye göre işlem yap
    FiveguardServer.CheatDetection.HandleDetectionSeverity(detection)
    
    -- Veritabanına kaydet
    FiveguardServer.CheatDetection.SaveDetectionToDatabase(detection)
    
    -- Webhook gönder
    FiveguardServer.CheatDetection.SendDetectionWebhook(detection)
    
    -- Protection Manager'a bildir
    if FiveguardServer.ProtectionManager then
        FiveguardServer.ProtectionManager.RecordDetection('cheat_detection', {
            type = detection.type,
            severity = detection.severity,
            playerId = detection.playerId,
            timestamp = detection.timestamp
        })
    end
    
    print('^1[FIVEGUARD CHEAT DETECTION]^7 Cheat tespit edildi: ' .. detection.playerName .. 
          ' (' .. detection.type .. ' - ' .. detection.severity .. ')')
end

-- Detection severity'sini işle
function FiveguardServer.CheatDetection.HandleDetectionSeverity(detection)
    if not cheatData.config.autoActionEnabled then
        return
    end
    
    local playerId = detection.playerId
    local playerDetections = cheatData.detections[playerId] or {}
    
    if detection.severity == 'critical' then
        -- Kritik seviye - Anında ban
        FiveguardServer.CheatDetection.BanPlayer(playerId, 'Cheat tespit edildi: ' .. detection.type)
        
    elseif detection.severity == 'high' then
        -- Yüksek seviye - 3 detection'da ban
        local highSeverityCount = 0
        for _, det in ipairs(playerDetections) do
            if det.severity == 'high' or det.severity == 'critical' then
                highSeverityCount = highSeverityCount + 1
            end
        end
        
        if highSeverityCount >= 3 then
            FiveguardServer.CheatDetection.BanPlayer(playerId, 'Çoklu cheat tespiti')
        else
            FiveguardServer.CheatDetection.WarnPlayer(playerId, 'Şüpheli aktivite tespit edildi')
        end
        
    elseif detection.severity == 'medium' then
        -- Orta seviye - 5 detection'da kick
        local mediumSeverityCount = 0
        for _, det in ipairs(playerDetections) do
            if det.severity == 'medium' then
                mediumSeverityCount = mediumSeverityCount + 1
            end
        end
        
        if mediumSeverityCount >= 5 then
            FiveguardServer.CheatDetection.KickPlayer(playerId, 'Şüpheli aktivite')
        end
    end
end

-- Oyuncuyu banla
function FiveguardServer.CheatDetection.BanPlayer(playerId, reason)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Ban kaydı
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_bans (player_id, player_name, reason, ban_type, timestamp, expires_at, active) VALUES (?, ?, ?, ?, ?, ?, 1)', {
        playerId,
        player.name,
        reason,
        'cheat_detection',
        os.time(),
        os.time() + (365 * 24 * 3600) -- 1 yıl
    })
    
    -- Oyuncuyu at
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
    
    print('^1[FIVEGUARD CHEAT DETECTION]^7 Oyuncu banlandı: ' .. player.name .. ' (Sebep: ' .. reason .. ')')
end

-- Oyuncuyu uyar
function FiveguardServer.CheatDetection.WarnPlayer(playerId, reason)
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {255, 165, 0},
        multiline = true,
        args = {'FIVEGUARD UYARI', reason}
    })
end

-- Oyuncuyu at
function FiveguardServer.CheatDetection.KickPlayer(playerId, reason)
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
end

-- =============================================
-- MONİTORİNG
-- =============================================

-- Monitoring thread'ini başlat
function FiveguardServer.CheatDetection.StartMonitoring()
    CreateThread(function()
        while cheatData.isActive do
            Wait(60000) -- 1 dakika bekle
            
            -- Eski detection'ları temizle
            FiveguardServer.CheatDetection.CleanupOldDetections()
            
            -- Suspicious activity analizi
            FiveguardServer.CheatDetection.AnalyzeSuspiciousActivities()
        end
    end)
end

-- Eski detection'ları temizle
function FiveguardServer.CheatDetection.CleanupOldDetections()
    local currentTime = os.time()
    local cleanupThreshold = currentTime - cheatData.config.suspicionTimeout / 1000
    
    for playerId, detections in pairs(cheatData.detections) do
        local filteredDetections = {}
        for _, detection in ipairs(detections) do
            if detection.timestamp > cleanupThreshold then
                table.insert(filteredDetections, detection)
            end
        end
        cheatData.detections[playerId] = filteredDetections
    end
end

-- Suspicious activity'leri analiz et
function FiveguardServer.CheatDetection.AnalyzeSuspiciousActivities()
    -- Pattern analizi ve trend tespiti
    for playerId, detections in pairs(cheatData.detections) do
        if #detections >= cheatData.config.detectionThreshold then
            -- Şüpheli aktivite pattern'i tespit edildi
            FiveguardServer.CheatDetection.HandleSuspiciousPattern(playerId, detections)
        end
    end
end

-- Suspicious pattern'i işle
function FiveguardServer.CheatDetection.HandleSuspiciousPattern(playerId, detections)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Pattern analizi
    local patternTypes = {}
    for _, detection in ipairs(detections) do
        patternTypes[detection.type] = (patternTypes[detection.type] or 0) + 1
    end
    
    -- En yaygın pattern'i bul
    local mostCommonPattern = nil
    local maxCount = 0
    for pattern, count in pairs(patternTypes) do
        if count > maxCount then
            maxCount = count
            mostCommonPattern = pattern
        end
    end
    
    if mostCommonPattern and maxCount >= cheatData.config.detectionThreshold then
        -- Suspicious activity kaydı
        local suspiciousActivity = {
            playerId = playerId,
            playerName = player.name,
            pattern = mostCommonPattern,
            count = maxCount,
            detections = detections,
            timestamp = os.time()
        }
        
        cheatData.suspiciousActivities[playerId] = suspiciousActivity
        
        -- Admin'leri bilgilendir
        FiveguardServer.CheatDetection.NotifyAdmins('Şüpheli cheat pattern tespit edildi: ' .. player.name .. ' (' .. mostCommonPattern .. ')')
    end
end

-- Admin'leri bilgilendir
function FiveguardServer.CheatDetection.NotifyAdmins(message)
    for playerId, player in pairs(FiveguardServer.Players or {}) do
        if player.isAdmin then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 0, 0},
                multiline = true,
                args = {'FIVEGUARD CHEAT DETECTION', message}
            })
        end
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Detection'ı veritabanına kaydet
function FiveguardServer.CheatDetection.SaveDetectionToDatabase(detection)
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_cheat_detections (player_id, player_name, detection_type, detection_data, severity, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
        detection.playerId,
        detection.playerName,
        detection.type,
        json.encode(detection),
        detection.severity,
        detection.timestamp
    })
end

-- Detection webhook'u gönder
function FiveguardServer.CheatDetection.SendDetectionWebhook(detection)
    local color = 16711680 -- Kırmızı
    if detection.severity == 'high' then
        color = 16776960 -- Sarı
    elseif detection.severity == 'medium' then
        color = 16753920 -- Turuncu
    end
    
    local webhookData = {
        username = 'Fiveguard Cheat Detection',
        avatar_url = 'https://i.imgur.com/fiveguard-logo.png',
        embeds = {{
            title = '🚨 Cheat Tespit Edildi!',
            color = color,
            fields = {
                {name = 'Oyuncu', value = detection.playerName, inline = true},
                {name = 'Tespit Türü', value = detection.type, inline = true},
                {name = 'Severity', value = detection.severity, inline = true},
                {name = 'Detaylar', value = FiveguardServer.CheatDetection.FormatDetectionDetails(detection), inline = false},
                {name = 'Zaman', value = os.date('%Y-%m-%d %H:%M:%S', detection.timestamp), inline = true}
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', detection.timestamp)
        }}
    }
    
    FiveguardServer.Webhook.Send('cheat_detection', webhookData)
end

-- Detection detaylarını formatla
function FiveguardServer.CheatDetection.FormatDetectionDetails(detection)
    if detection.type == 'dui_texture' then
        return 'Texture URL: ' .. detection.textureUrl
    elseif detection.type == 'cheat_signature' then
        return 'Signature: ' .. detection.signature
    elseif detection.type == 'bypass_attempt' then
        return 'Bypass Type: ' .. detection.bypassType
    elseif detection.type == 'runtime_suspicious' then
        return 'Function: ' .. detection.functionCall
    else
        return 'Bilinmeyen tespit türü'
    end
end

-- İstatistikleri getir
function FiveguardServer.CheatDetection.GetStats()
    return {
        totalDetections = cheatData.stats.totalDetections,
        duiDetections = cheatData.stats.duiDetections,
        signatureDetections = cheatData.stats.signatureDetections,
        bypassDetections = cheatData.stats.bypassDetections,
        falsePositives = cheatData.stats.falsePositives,
        lastDetection = cheatData.stats.lastDetection,
        isActive = cheatData.isActive,
        activeDetections = FiveguardServer.CheatDetection.GetActiveDetectionCount(),
        suspiciousActivities = FiveguardServer.CheatDetection.GetSuspiciousActivityCount()
    }
end

-- Aktif detection sayısını getir
function FiveguardServer.CheatDetection.GetActiveDetectionCount()
    local count = 0
    for _, detections in pairs(cheatData.detections) do
        count = count + #detections
    end
    return count
end

-- Suspicious activity sayısını getir
function FiveguardServer.CheatDetection.GetSuspiciousActivityCount()
    local count = 0
    for _ in pairs(cheatData.suspiciousActivities) do
        count = count + 1
    end
    return count
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Cheat detection istatistiklerini getir
function GetCheatDetectionStats()
    return FiveguardServer.CheatDetection.GetStats()
end

-- Cheat detection durumunu kontrol et
function IsCheatDetectionActive()
    return cheatData.isActive
end

-- Manuel detection ekle
function AddManualDetection(playerId, detectionType, details)
    local detection = {
        playerId = playerId,
        playerName = GetPlayerName(playerId) or 'Bilinmeyen',
        type = detectionType,
        details = details,
        timestamp = os.time(),
        severity = 'manual'
    }
    
    FiveguardServer.CheatDetection.ProcessDetection(detection)
    return true
end

print('^2[FIVEGUARD CHEAT DETECTION]^7 Cheat Detection Engine modülü yüklendi')
