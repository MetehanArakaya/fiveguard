-- FIVEGUARD LICENSE MODULE
-- Lisans doğrulama ve yönetim sistemi

Fiveguard.License = {}

-- =============================================
-- LİSANS DEĞİŞKENLERİ
-- =============================================

local licenseData = {
    isValid = false,
    key = nil,
    serverName = nil,
    maxPlayers = 0,
    expiresAt = nil,
    features = {},
    lastCheck = 0,
    checkInterval = 300000, -- 5 dakika
    retryCount = 0,
    maxRetries = 3
}

-- =============================================
-- LİSANS BAŞLATMA
-- =============================================

function Fiveguard.License.Initialize()
    print('^2[FIVEGUARD]^7 Lisans sistemi başlatılıyor...')
    
    -- Konfigürasyondan lisans bilgilerini al
    licenseData.key = Config.License.Key
    licenseData.serverName = Config.License.ServerName
    licenseData.maxPlayers = Config.License.MaxPlayers
    licenseData.checkInterval = Config.License.CheckInterval
    
    -- İlk lisans kontrolü
    local isValid = Fiveguard.License.Verify()
    
    if isValid then
        print('^2[FIVEGUARD]^7 Lisans doğrulandı: ' .. licenseData.serverName)
        
        -- Periyodik kontrol başlat
        Fiveguard.License.StartPeriodicCheck()
        
        -- Heartbeat sistemi başlat
        Fiveguard.License.StartHeartbeat()
    else
        print('^1[FIVEGUARD]^7 Lisans doğrulanamadı!')
    end
    
    return isValid
end

-- =============================================
-- LİSANS DOĞRULAMA
-- =============================================

-- Ana lisans doğrulama fonksiyonu
function Fiveguard.License.Verify()
    if not licenseData.key or licenseData.key == '' then
        print('^1[FIVEGUARD]^7 Lisans anahtarı bulunamadı!')
        return false
    end
    
    -- Demo lisans kontrolü
    if licenseData.key == 'FIVEGUARD-DEMO-LICENSE-KEY-2024' then
        return Fiveguard.License.ValidateDemoLicense()
    end
    
    -- Online lisans doğrulama
    return Fiveguard.License.ValidateOnline()
end

-- Demo lisans doğrulama
function Fiveguard.License.ValidateDemoLicense()
    print('^3[FIVEGUARD]^7 Demo lisans kullanılıyor')
    
    licenseData.isValid = true
    licenseData.serverName = 'Demo Server'
    licenseData.maxPlayers = 32
    licenseData.expiresAt = os.time() + (30 * 24 * 3600) -- 30 gün
    licenseData.features = {
        'basic_anticheat',
        'discord_webhook',
        'web_panel',
        'basic_ai'
    }
    
    -- Demo sınırlamaları
    print('^3[FIVEGUARD]^7 Demo lisans sınırlamaları:')
    print('^3[FIVEGUARD]^7 - Maksimum 32 oyuncu')
    print('^3[FIVEGUARD]^7 - 30 gün süre')
    print('^3[FIVEGUARD]^7 - Temel özellikler')
    
    return true
end

-- Online lisans doğrulama
function Fiveguard.License.ValidateOnline()
    local success = false
    local responseData = nil
    
    -- Sunucu bilgilerini hazırla
    local serverInfo = {
        license_key = licenseData.key,
        server_name = licenseData.serverName,
        server_ip = GetConvar('sv_hostname', 'Unknown'),
        fivem_endpoint = GetConvar('sv_endpoint', 'Unknown'),
        max_players = GetConvarInt('sv_maxclients', 32),
        version = Fiveguard.Version,
        timestamp = os.time()
    }
    
    -- API'ye istek gönder
    PerformHttpRequest(Config.License.ApiUrl, function(errorCode, resultData, resultHeaders)
        if errorCode == 200 then
            local success, data = pcall(json.decode, resultData)
            if success and data then
                responseData = data
                success = Fiveguard.License.ProcessLicenseResponse(data)
            else
                print('^1[FIVEGUARD]^7 Lisans API yanıtı parse edilemedi')
            end
        else
            print('^1[FIVEGUARD]^7 Lisans API hatası: ' .. tostring(errorCode))
            
            -- Offline mod kontrolü
            if Fiveguard.License.CanUseOfflineMode() then
                success = Fiveguard.License.UseOfflineMode()
            end
        end
    end, 'POST', json.encode(serverInfo), {
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = 'Fiveguard/' .. Fiveguard.Version
    })
    
    -- Senkron bekleme (maksimum 10 saniye)
    local timeout = GetGameTimer() + 10000
    while not success and responseData == nil and GetGameTimer() < timeout do
        Wait(100)
    end
    
    return success
end

-- Lisans yanıtını işle
function Fiveguard.License.ProcessLicenseResponse(data)
    if not data.valid then
        print('^1[FIVEGUARD]^7 Geçersiz lisans: ' .. (data.message or 'Bilinmeyen hata'))
        return false
    end
    
    -- Lisans bilgilerini güncelle
    licenseData.isValid = true
    licenseData.serverName = data.server_name or licenseData.serverName
    licenseData.maxPlayers = data.max_players or licenseData.maxPlayers
    licenseData.expiresAt = data.expires_at
    licenseData.features = data.features or {}
    licenseData.lastCheck = os.time()
    
    -- Özellik kontrolü
    Fiveguard.License.ValidateFeatures()
    
    print('^2[FIVEGUARD]^7 Lisans başarıyla doğrulandı')
    print('^2[FIVEGUARD]^7 Sunucu: ' .. licenseData.serverName)
    print('^2[FIVEGUARD]^7 Maksimum oyuncu: ' .. licenseData.maxPlayers)
    
    if licenseData.expiresAt then
        print('^2[FIVEGUARD]^7 Bitiş tarihi: ' .. os.date('%Y-%m-%d %H:%M:%S', licenseData.expiresAt))
    end
    
    return true
end

-- =============================================
-- ÖZELLİK KONTROLÜ
-- =============================================

-- Özellikleri doğrula
function Fiveguard.License.ValidateFeatures()
    print('^2[FIVEGUARD]^7 Aktif özellikler:')
    
    for _, feature in ipairs(licenseData.features) do
        print('^2[FIVEGUARD]^7 - ' .. feature)
    end
    
    -- Özellik bazlı konfigürasyon güncellemeleri
    if not Fiveguard.License.HasFeature('discord_webhook') then
        Config.Webhooks.Discord.Enabled = false
        print('^3[FIVEGUARD]^7 Discord webhook özelliği lisansta yok, devre dışı bırakıldı')
    end
    
    if not Fiveguard.License.HasFeature('advanced_ai') then
        Config.AI.Screenshot.Enabled = false
        Config.AI.BehaviorAnalysis.Enabled = false
        print('^3[FIVEGUARD]^7 Gelişmiş AI özellikleri lisansta yok, devre dışı bırakıldı')
    end
    
    if not Fiveguard.License.HasFeature('web_panel') then
        print('^3[FIVEGUARD]^7 Web panel özelliği lisansta yok')
    end
end

-- Özellik kontrolü
function Fiveguard.License.HasFeature(featureName)
    if not licenseData.isValid then return false end
    
    for _, feature in ipairs(licenseData.features) do
        if feature == featureName then
            return true
        end
    end
    
    return false
end

-- Oyuncu limiti kontrolü
function Fiveguard.License.CheckPlayerLimit()
    local currentPlayers = GetNumPlayerIndices()
    
    if currentPlayers > licenseData.maxPlayers then
        print('^1[FIVEGUARD]^7 UYARI: Oyuncu limiti aşıldı! (' .. currentPlayers .. '/' .. licenseData.maxPlayers .. ')')
        
        -- Webhook bildirimi
        if Config.Webhooks.Discord.Enabled then
            Fiveguard.Webhook.SendDiscord('license_violation', {
                title = '⚠️ Lisans İhlali',
                description = 'Oyuncu limiti aşıldı',
                color = Config.Webhooks.Discord.Colors.error,
                fields = {
                    {name = 'Mevcut Oyuncu', value = tostring(currentPlayers), inline = true},
                    {name = 'Maksimum Limit', value = tostring(licenseData.maxPlayers), inline = true}
                }
            })
        end
        
        return false
    end
    
    return true
end

-- =============================================
-- OFFLINE MOD
-- =============================================

-- Offline mod kullanılabilir mi?
function Fiveguard.License.CanUseOfflineMode()
    -- Son başarılı kontrolden 24 saat geçmemişse offline mod kullanılabilir
    local lastValidCheck = Fiveguard.License.GetLastValidCheck()
    if lastValidCheck and (os.time() - lastValidCheck) < 86400 then
        return true
    end
    
    return false
end

-- Offline mod kullan
function Fiveguard.License.UseOfflineMode()
    print('^3[FIVEGUARD]^7 Offline modda çalışıyor')
    
    -- Cached lisans bilgilerini yükle
    local cachedLicense = Fiveguard.License.LoadCachedLicense()
    if cachedLicense then
        licenseData = cachedLicense
        licenseData.isValid = true
        
        print('^3[FIVEGUARD]^7 Cached lisans bilgileri yüklendi')
        return true
    end
    
    print('^1[FIVEGUARD]^7 Cached lisans bilgileri bulunamadı')
    return false
end

-- Son geçerli kontrolü getir
function Fiveguard.License.GetLastValidCheck()
    -- Veritabanından veya dosyadan son geçerli kontrol zamanını al
    -- Bu implementasyon basitleştirilmiş
    return licenseData.lastCheck
end

-- Lisans bilgilerini cache'le
function Fiveguard.License.CacheLicense()
    if not licenseData.isValid then return end
    
    local cacheData = {
        serverName = licenseData.serverName,
        maxPlayers = licenseData.maxPlayers,
        features = licenseData.features,
        cachedAt = os.time()
    }
    
    -- Veritabanına veya dosyaya kaydet
    -- Bu implementasyon basitleştirilmiş
    if Fiveguard.Database then
        Fiveguard.Database.SaveConfig('license_cache', cacheData, 'license')
    end
end

-- Cached lisans bilgilerini yükle
function Fiveguard.License.LoadCachedLicense()
    -- Veritabanından veya dosyadan cached bilgileri yükle
    -- Bu implementasyon basitleştirilmiş
    if Fiveguard.Database then
        Fiveguard.Database.GetConfig('license_cache', function(data)
            if data and data.cachedAt and (os.time() - data.cachedAt) < 86400 then
                return data
            end
        end)
    end
    
    return nil
end

-- =============================================
-- PERİYODİK KONTROL
-- =============================================

-- Periyodik lisans kontrolü başlat
function Fiveguard.License.StartPeriodicCheck()
    CreateThread(function()
        while true do
            Wait(licenseData.checkInterval)
            
            if licenseData.isValid then
                Fiveguard.License.PeriodicCheck()
            end
        end
    end)
end

-- Periyodik kontrol
function Fiveguard.License.PeriodicCheck()
    if Config.Debug then
        print('^2[FIVEGUARD]^7 Periyodik lisans kontrolü yapılıyor...')
    end
    
    -- Süre kontrolü
    if licenseData.expiresAt and os.time() > licenseData.expiresAt then
        print('^1[FIVEGUARD]^7 Lisans süresi doldu!')
        licenseData.isValid = false
        return
    end
    
    -- Oyuncu limiti kontrolü
    Fiveguard.License.CheckPlayerLimit()
    
    -- Online doğrulama (daha az sıklıkta)
    if (os.time() - licenseData.lastCheck) > 3600 then -- 1 saatte bir
        Fiveguard.License.ValidateOnline()
    end
end

-- =============================================
-- HEARTBEAT SİSTEMİ
-- =============================================

-- Heartbeat sistemi başlat
function Fiveguard.License.StartHeartbeat()
    CreateThread(function()
        while licenseData.isValid do
            Wait(300000) -- 5 dakika
            Fiveguard.License.SendHeartbeat()
        end
    end)
end

-- Heartbeat gönder
function Fiveguard.License.SendHeartbeat()
    if not licenseData.isValid then return end
    
    local heartbeatData = {
        license_key = licenseData.key,
        server_name = licenseData.serverName,
        current_players = GetNumPlayerIndices(),
        uptime = GetGameTimer(),
        version = Fiveguard.Version,
        timestamp = os.time(),
        stats = {
            total_detections = #Fiveguard.Detections or 0,
            active_bans = 0, -- Bu değer veritabanından alınabilir
            system_health = 'good'
        }
    }
    
    -- Heartbeat API'sine gönder
    local heartbeatUrl = string.gsub(Config.License.ApiUrl, '/verify', '/heartbeat')
    
    PerformHttpRequest(heartbeatUrl, function(errorCode, resultData, resultHeaders)
        if errorCode == 200 then
            if Config.Debug then
                print('^2[FIVEGUARD]^7 Heartbeat gönderildi')
            end
            
            -- Yanıtı işle
            local success, data = pcall(json.decode, resultData)
            if success and data then
                Fiveguard.License.ProcessHeartbeatResponse(data)
            end
        else
            if Config.Debug then
                print('^3[FIVEGUARD]^7 Heartbeat hatası: ' .. tostring(errorCode))
            end
        end
    end, 'POST', json.encode(heartbeatData), {
        ['Content-Type'] = 'application/json',
        ['User-Agent'] = 'Fiveguard/' .. Fiveguard.Version
    })
end

-- Heartbeat yanıtını işle
function Fiveguard.License.ProcessHeartbeatResponse(data)
    if data.status == 'ok' then
        licenseData.lastCheck = os.time()
        
        -- Lisans bilgilerini güncelle
        if data.license_info then
            if data.license_info.expires_at then
                licenseData.expiresAt = data.license_info.expires_at
            end
            
            if data.license_info.max_players then
                licenseData.maxPlayers = data.license_info.max_players
            end
            
            if data.license_info.features then
                licenseData.features = data.license_info.features
                Fiveguard.License.ValidateFeatures()
            end
        end
        
        -- Sunucu mesajları
        if data.messages and #data.messages > 0 then
            for _, message in ipairs(data.messages) do
                print('^6[FIVEGUARD MESSAGE]^7 ' .. message)
            end
        end
        
        -- Uzaktan komutlar (güvenlik için sınırlı)
        if data.commands and #data.commands > 0 then
            Fiveguard.License.ProcessRemoteCommands(data.commands)
        end
        
        -- Cache'i güncelle
        Fiveguard.License.CacheLicense()
    else
        print('^1[FIVEGUARD]^7 Heartbeat hatası: ' .. (data.message or 'Bilinmeyen hata'))
    end
end

-- Uzaktan komutları işle
function Fiveguard.License.ProcessRemoteCommands(commands)
    for _, command in ipairs(commands) do
        if command.type == 'update_config' and command.config then
            -- Sadece güvenli konfigürasyon güncellemelerine izin ver
            local allowedConfigs = {'webhook_url', 'log_level', 'detection_thresholds'}
            
            for key, value in pairs(command.config) do
                if table.contains(allowedConfigs, key) then
                    -- Konfigürasyonu güncelle
                    print('^3[FIVEGUARD]^7 Uzaktan konfigürasyon güncellendi: ' .. key)
                end
            end
        elseif command.type == 'broadcast_message' and command.message then
            -- Tüm oyunculara mesaj gönder
            TriggerClientEvent('chat:addMessage', -1, {
                color = {255, 165, 0},
                multiline = true,
                args = {'[Fiveguard]', command.message}
            })
        end
    end
end

-- =============================================
-- LİSANS BİLGİLERİ
-- =============================================

-- Lisans durumunu getir
function Fiveguard.License.GetStatus()
    return {
        isValid = licenseData.isValid,
        key = licenseData.key and (licenseData.key:sub(1, 10) .. '...') or nil,
        serverName = licenseData.serverName,
        maxPlayers = licenseData.maxPlayers,
        currentPlayers = GetNumPlayerIndices(),
        expiresAt = licenseData.expiresAt,
        features = licenseData.features,
        lastCheck = licenseData.lastCheck
    }
end

-- Lisans geçerli mi?
function Fiveguard.License.IsValid()
    return licenseData.isValid
end

-- Lisans süresi doldu mu?
function Fiveguard.License.IsExpired()
    if not licenseData.expiresAt then return false end
    return os.time() > licenseData.expiresAt
end

-- Kalan süre
function Fiveguard.License.GetTimeRemaining()
    if not licenseData.expiresAt then return nil end
    
    local remaining = licenseData.expiresAt - os.time()
    return remaining > 0 and remaining or 0
end

-- =============================================
-- HATA YÖNETİMİ
-- =============================================

-- Lisans hatasını işle
function Fiveguard.License.HandleError(errorType, message)
    print('^1[FIVEGUARD LICENSE ERROR]^7 ' .. errorType .. ': ' .. message)
    
    -- Hata türüne göre eylem al
    if errorType == 'expired' then
        licenseData.isValid = false
        
        -- Webhook bildirimi
        if Config.Webhooks.Discord.Enabled then
            Fiveguard.Webhook.SendDiscord('license_expired', {
                title = '⚠️ Lisans Süresi Doldu',
                description = 'Fiveguard lisansının süresi doldu',
                color = Config.Webhooks.Discord.Colors.error
            })
        end
        
    elseif errorType == 'invalid' then
        licenseData.isValid = false
        
    elseif errorType == 'network' then
        -- Ağ hatası, offline moda geç
        if Fiveguard.License.CanUseOfflineMode() then
            Fiveguard.License.UseOfflineMode()
        end
    end
end

-- Lisans uyarısı gönder
function Fiveguard.License.SendWarning(warningType, details)
    local message = 'Lisans uyarısı: ' .. warningType
    if details then
        message = message .. ' - ' .. details
    end
    
    print('^3[FIVEGUARD WARNING]^7 ' .. message)
    
    -- Log kaydet
    if Fiveguard.Logger then
        Fiveguard.Logger.Warning(message, {type = warningType, details = details}, 'license')
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Tablo içinde değer var mı kontrol et
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Lisans anahtarını maskele
function Fiveguard.License.MaskKey(key)
    if not key or #key < 10 then return 'INVALID' end
    return key:sub(1, 8) .. string.rep('*', #key - 12) .. key:sub(-4)
end

-- Lisans bilgilerini temizle (güvenlik için)
function Fiveguard.License.SanitizeInfo(info)
    local sanitized = {}
    for key, value in pairs(info) do
        if key == 'key' then
            sanitized[key] = Fiveguard.License.MaskKey(value)
        else
            sanitized[key] = value
        end
    end
    return sanitized
end

print('^2[FIVEGUARD]^7 License modülü yüklendi')
