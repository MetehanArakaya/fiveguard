-- FIVEGUARD LOGGER MODULE
-- Log sistemi ve kayıt yönetimi

Fiveguard.Logger = {}

-- =============================================
-- LOG SEVİYELERİ VE RENKLER
-- =============================================

local LogColors = {
    [Shared.LogLevels.DEBUG] = '^5',    -- Mor
    [Shared.LogLevels.INFO] = '^2',     -- Yeşil
    [Shared.LogLevels.WARNING] = '^3',  -- Sarı
    [Shared.LogLevels.ERROR] = '^1',    -- Kırmızı
    [Shared.LogLevels.CRITICAL] = '^9'  -- Kırmızı + Bold
}

-- =============================================
-- LOGGER BAŞLATMA
-- =============================================

function Fiveguard.Logger.Initialize()
    print('^2[FIVEGUARD]^7 Logger sistemi başlatılıyor...')
    
    -- Log dizinini oluştur
    if Config.Logging.Types.File then
        Fiveguard.Logger.CreateLogDirectory()
    end
    
    -- Otomatik temizlik başlat
    if Config.Logging.AutoCleanup.Enabled then
        Fiveguard.Logger.StartAutoCleanup()
    end
    
    print('^2[FIVEGUARD]^7 Logger sistemi hazır')
end

-- Log dizinini oluştur
function Fiveguard.Logger.CreateLogDirectory()
    -- FiveM'de dosya sistemi işlemleri sınırlı olduğu için
    -- Bu fonksiyon gerçek uygulamada external script ile yapılabilir
    print('^2[FIVEGUARD]^7 Log dizini kontrol ediliyor: ' .. Config.Logging.File.Path)
end

-- =============================================
-- ANA LOG FONKSİYONLARI
-- =============================================

-- Genel log fonksiyonu
function Fiveguard.Logger.Log(level, message, context, category)
    -- Seviye kontrolü
    if not Fiveguard.Logger.ShouldLog(level) then
        return
    end
    
    context = context or {}
    category = category or 'general'
    
    -- Timestamp ekle
    local timestamp = os.date(Config.Logging.File.DateFormat)
    
    -- Log mesajını formatla
    local formattedMessage = string.format('[%s] [%s] [%s] %s', 
        timestamp, 
        string.upper(level), 
        string.upper(category), 
        message
    )
    
    -- Konsola yazdır
    if Config.Logging.Types.Console then
        local color = LogColors[level] or '^7'
        print(color .. '[FIVEGUARD] ' .. formattedMessage .. '^7')
    end
    
    -- Dosyaya kaydet
    if Config.Logging.Types.File then
        Fiveguard.Logger.WriteToFile(level, formattedMessage, context)
    end
    
    -- Veritabanına kaydet
    if Config.Logging.Types.Database then
        Fiveguard.Database.LogSystem(level, category, message, context)
    end
    
    -- Webhook'a gönder
    if Config.Logging.Types.Webhook and Fiveguard.Logger.ShouldSendWebhook(level) then
        Fiveguard.Logger.SendToWebhook(level, message, context, category)
    end
end

-- Debug log
function Fiveguard.Logger.Debug(message, context, category)
    Fiveguard.Logger.Log(Shared.LogLevels.DEBUG, message, context, category or 'debug')
end

-- Info log
function Fiveguard.Logger.Info(message, context, category)
    Fiveguard.Logger.Log(Shared.LogLevels.INFO, message, context, category or 'info')
end

-- Warning log
function Fiveguard.Logger.Warning(message, context, category)
    Fiveguard.Logger.Log(Shared.LogLevels.WARNING, message, context, category or 'warning')
end

-- Error log
function Fiveguard.Logger.Error(message, context, category)
    Fiveguard.Logger.Log(Shared.LogLevels.ERROR, message, context, category or 'error')
end

-- Critical log
function Fiveguard.Logger.Critical(message, context, category)
    Fiveguard.Logger.Log(Shared.LogLevels.CRITICAL, message, context, category or 'critical')
end

-- =============================================
-- ÖZELLEŞTİRİLMİŞ LOG FONKSİYONLARI
-- =============================================

-- Anti-cheat tespiti logu
function Fiveguard.Logger.Detection(playerName, detectionType, confidence, evidence)
    local message = string.format('TESPIT: %s - %s (Güven: %.1f%%)', 
        playerName, detectionType, confidence)
    
    local context = {
        player = playerName,
        detection_type = detectionType,
        confidence = confidence,
        evidence = evidence
    }
    
    Fiveguard.Logger.Warning(message, context, 'anticheat')
end

-- Oyuncu bağlantı logu
function Fiveguard.Logger.PlayerConnection(playerName, playerId, action, details)
    local message = string.format('OYUNCU %s: %s (%s)', 
        string.upper(action), playerName, playerId)
    
    local context = {
        player = playerName,
        player_id = playerId,
        action = action,
        details = details or {}
    }
    
    Fiveguard.Logger.Info(message, context, 'player')
end

-- Admin eylem logu
function Fiveguard.Logger.AdminAction(adminName, action, target, reason)
    local message = string.format('ADMIN EYLEM: %s - %s -> %s (Sebep: %s)', 
        adminName, action, target or 'N/A', reason or 'Belirtilmemiş')
    
    local context = {
        admin = adminName,
        action = action,
        target = target,
        reason = reason
    }
    
    Fiveguard.Logger.Warning(message, context, 'admin')
end

-- Sistem hatası logu
function Fiveguard.Logger.SystemError(errorMessage, stackTrace, module)
    local message = string.format('SİSTEM HATASI [%s]: %s', 
        module or 'UNKNOWN', errorMessage)
    
    local context = {
        error = errorMessage,
        stack_trace = stackTrace,
        module = module,
        timestamp = os.time()
    }
    
    Fiveguard.Logger.Error(message, context, 'system')
end

-- Performans logu
function Fiveguard.Logger.Performance(operation, duration, details)
    local message = string.format('PERFORMANS: %s - %.2fms', operation, duration)
    
    local context = {
        operation = operation,
        duration = duration,
        details = details or {}
    }
    
    -- Yavaş işlemler için warning
    local level = duration > 1000 and Shared.LogLevels.WARNING or Shared.LogLevels.DEBUG
    Fiveguard.Logger.Log(level, message, context, 'performance')
end

-- =============================================
-- DOSYA İŞLEMLERİ
-- =============================================

-- Dosyaya yaz
function Fiveguard.Logger.WriteToFile(level, message, context)
    -- FiveM'de dosya yazma işlemleri sınırlı
    -- Gerçek uygulamada external script veya resource kullanılabilir
    
    local filename = string.format('%s/fiveguard_%s.log', 
        Config.Logging.File.Path, 
        os.date('%Y-%m-%d'))
    
    -- Bu kısım gerçek uygulamada file I/O ile yapılacak
    if Config.Debug then
        print(string.format('^6[FIVEGUARD LOG]^7 %s -> %s', filename, message))
    end
end

-- Log dosyası rotasyonu
function Fiveguard.Logger.RotateLogFiles()
    -- Dosya boyutu kontrolü ve rotasyon
    -- Gerçek uygulamada implement edilecek
    print('^3[FIVEGUARD]^7 Log dosyası rotasyonu (placeholder)')
end

-- =============================================
-- WEBHOOK İŞLEMLERİ
-- =============================================

-- Webhook'a gönder
function Fiveguard.Logger.SendToWebhook(level, message, context, category)
    if not Config.Webhooks.Discord.Enabled then return end
    
    -- Sadece önemli logları webhook'a gönder
    if level == Shared.LogLevels.DEBUG then return end
    
    local color = Fiveguard.Logger.GetWebhookColor(level)
    local title = string.format('Fiveguard Log - %s', string.upper(level))
    
    local embed = {
        title = title,
        description = message,
        color = color,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        fields = {
            {name = 'Kategori', value = category, inline = true},
            {name = 'Seviye', value = string.upper(level), inline = true}
        }
    }
    
    -- Context bilgilerini ekle
    if context and next(context) then
        local contextStr = ''
        for key, value in pairs(context) do
            if type(value) == 'table' then
                value = json.encode(value)
            end
            contextStr = contextStr .. string.format('**%s:** %s\n', key, tostring(value))
        end
        
        if #contextStr > 0 then
            table.insert(embed.fields, {
                name = 'Detaylar',
                value = contextStr:sub(1, 1024), -- Discord limit
                inline = false
            })
        end
    end
    
    -- Webhook'a gönder
    if Fiveguard.Webhook then
        Fiveguard.Webhook.SendDiscord('log', embed)
    end
end

-- Webhook renk kodu
function Fiveguard.Logger.GetWebhookColor(level)
    local colors = {
        [Shared.LogLevels.DEBUG] = 9936031,    -- Açık gri
        [Shared.LogLevels.INFO] = 3447003,     -- Mavi
        [Shared.LogLevels.WARNING] = 16776960, -- Sarı
        [Shared.LogLevels.ERROR] = 15158332,   -- Kırmızı
        [Shared.LogLevels.CRITICAL] = 10038562 -- Koyu kırmızı
    }
    
    return colors[level] or 9936031
end

-- =============================================
-- FİLTRELEME VE KONTROL
-- =============================================

-- Log seviyesi kontrolü
function Fiveguard.Logger.ShouldLog(level)
    if not Config.Logging.Enabled then return false end
    
    local levels = {
        [Shared.LogLevels.DEBUG] = 1,
        [Shared.LogLevels.INFO] = 2,
        [Shared.LogLevels.WARNING] = 3,
        [Shared.LogLevels.ERROR] = 4,
        [Shared.LogLevels.CRITICAL] = 5
    }
    
    local currentLevel = levels[Config.Logging.Level] or 2
    local messageLevel = levels[level] or 1
    
    return messageLevel >= currentLevel
end

-- Webhook gönderimi kontrolü
function Fiveguard.Logger.ShouldSendWebhook(level)
    -- Sadece warning ve üzeri seviyeleri webhook'a gönder
    local webhookLevels = {
        [Shared.LogLevels.WARNING] = true,
        [Shared.LogLevels.ERROR] = true,
        [Shared.LogLevels.CRITICAL] = true
    }
    
    return webhookLevels[level] or false
end

-- =============================================
-- TEMİZLİK VE BAKIM
-- =============================================

-- Otomatik temizlik başlat
function Fiveguard.Logger.StartAutoCleanup()
    CreateThread(function()
        while true do
            Wait(Config.Logging.AutoCleanup.CheckInterval)
            Fiveguard.Logger.CleanupOldLogs()
        end
    end)
end

-- Eski logları temizle
function Fiveguard.Logger.CleanupOldLogs()
    local cutoffTime = os.time() - (Config.Logging.AutoCleanup.Days * 24 * 3600)
    
    -- Veritabanından eski logları sil
    if Config.Logging.Types.Database then
        MySQL.execute('DELETE FROM system_logs WHERE created_at < FROM_UNIXTIME(?)', {cutoffTime})
    end
    
    -- Dosya temizliği (placeholder)
    if Config.Logging.Types.File then
        -- Gerçek uygulamada eski log dosyalarını sil
        print('^3[FIVEGUARD]^7 Eski log dosyaları temizlendi (placeholder)')
    end
    
    if Config.Debug then
        print('^2[FIVEGUARD]^7 Log temizlik işlemi tamamlandı')
    end
end

-- =============================================
-- İSTATİSTİKLER VE RAPORLAMA
-- =============================================

-- Log istatistikleri
function Fiveguard.Logger.GetStats(callback)
    if not Config.Logging.Types.Database then
        callback({error = 'Veritabanı logları devre dışı'})
        return
    end
    
    local stats = {}
    
    -- Bugünkü log sayısı
    MySQL.scalar('SELECT COUNT(*) FROM system_logs WHERE DATE(created_at) = CURDATE()', {}, function(count)
        stats.todayLogs = count or 0
        
        -- Seviye bazında dağılım
        MySQL.query('SELECT log_level, COUNT(*) as count FROM system_logs WHERE DATE(created_at) = CURDATE() GROUP BY log_level', {}, function(results)
            stats.levelDistribution = {}
            for _, row in ipairs(results) do
                stats.levelDistribution[row.log_level] = row.count
            end
            
            -- Kategori bazında dağılım
            MySQL.query('SELECT category, COUNT(*) as count FROM system_logs WHERE DATE(created_at) = CURDATE() GROUP BY category ORDER BY count DESC LIMIT 10', {}, function(results)
                stats.categoryDistribution = results
                
                callback(stats)
            end)
        end)
    end)
end

-- Log raporu oluştur
function Fiveguard.Logger.GenerateReport(days, callback)
    days = days or 7
    
    MySQL.query('SELECT DATE(created_at) as date, log_level, COUNT(*) as count FROM system_logs WHERE created_at >= DATE_SUB(NOW(), INTERVAL ? DAY) GROUP BY DATE(created_at), log_level ORDER BY date DESC', {
        days
    }, function(results)
        local report = {
            period = days .. ' gün',
            generated_at = os.date('%Y-%m-%d %H:%M:%S'),
            data = results
        }
        
        callback(report)
    end)
end

-- =============================================
-- HATA YÖNETİMİ
-- =============================================

-- Güvenli log fonksiyonu (hata durumunda sistem çökmez)
function Fiveguard.Logger.SafeLog(level, message, context, category)
    local success, error = pcall(function()
        Fiveguard.Logger.Log(level, message, context, category)
    end)
    
    if not success then
        -- Fallback: En azından konsola yazdır
        print('^1[FIVEGUARD LOG ERROR]^7 ' .. tostring(error))
        print('^3[FIVEGUARD LOG FALLBACK]^7 ' .. tostring(message))
    end
end

-- Log sistemi sağlık kontrolü
function Fiveguard.Logger.HealthCheck()
    local health = {
        console = Config.Logging.Types.Console,
        file = Config.Logging.Types.File,
        database = Config.Logging.Types.Database and Fiveguard.Database.TestConnection(),
        webhook = Config.Logging.Types.Webhook and Config.Webhooks.Discord.Enabled
    }
    
    local healthyCount = 0
    local totalCount = 0
    
    for _, isHealthy in pairs(health) do
        totalCount = totalCount + 1
        if isHealthy then
            healthyCount = healthyCount + 1
        end
    end
    
    local healthPercentage = (healthyCount / totalCount) * 100
    
    Fiveguard.Logger.Info(string.format('Log sistemi sağlık durumu: %.1f%% (%d/%d)', 
        healthPercentage, healthyCount, totalCount), health, 'system')
    
    return health
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Mesajı formatla
function Fiveguard.Logger.FormatMessage(template, ...)
    local args = {...}
    return string.format(template, table.unpack(args))
end

-- Context'i temizle (hassas bilgileri kaldır)
function Fiveguard.Logger.SanitizeContext(context)
    if not context or type(context) ~= 'table' then
        return context
    end
    
    local sanitized = {}
    local sensitiveKeys = {'password', 'token', 'key', 'secret', 'auth'}
    
    for key, value in pairs(context) do
        local keyLower = string.lower(tostring(key))
        local isSensitive = false
        
        for _, sensitiveKey in ipairs(sensitiveKeys) do
            if string.find(keyLower, sensitiveKey) then
                isSensitive = true
                break
            end
        end
        
        if isSensitive then
            sanitized[key] = '[REDACTED]'
        else
            sanitized[key] = value
        end
    end
    
    return sanitized
end

print('^2[FIVEGUARD]^7 Logger modülü yüklendi')
