-- FIVEGUARD SERVER MAIN
-- AI Destekli FiveM Anti-Cheat Sistemi - Ana Sunucu Dosyası

-- Global değişkenler
Fiveguard = {}
Fiveguard.Players = {}
Fiveguard.Detections = {}
Fiveguard.Bans = {}
Fiveguard.Config = Config
Fiveguard.Version = '1.0.0'

-- Başlangıç mesajı
print('^2[FIVEGUARD]^7 AI Destekli Anti-Cheat Sistemi başlatılıyor...')
print('^2[FIVEGUARD]^7 Versiyon: ' .. Fiveguard.Version)

-- =============================================
-- BAŞLATMA FONKSİYONLARI
-- =============================================

-- Ana başlatma fonksiyonu
function Fiveguard.Initialize()
    print('^2[FIVEGUARD]^7 Sistem başlatılıyor...')
    
    -- Lisans kontrolü
    if not Fiveguard.License.Verify() then
        print('^1[FIVEGUARD]^7 HATA: Geçersiz lisans! Sistem durduruluyor.')
        return false
    end
    
    -- Veritabanı bağlantısı
    if not Fiveguard.Database.Initialize() then
        print('^1[FIVEGUARD]^7 HATA: Veritabanı bağlantısı kurulamadı!')
        return false
    end
    
    -- Modülleri başlat
    Fiveguard.StartModules()
    
    -- Event'leri kaydet
    Fiveguard.RegisterEvents()
    
    -- Komutları kaydet
    Fiveguard.RegisterCommands()
    
    -- Heartbeat başlat
    Fiveguard.StartHeartbeat()
    
    print('^2[FIVEGUARD]^7 Sistem başarıyla başlatıldı!')
    return true
end

-- Modülleri başlat
function Fiveguard.StartModules()
    print('^2[FIVEGUARD]^7 Modüller başlatılıyor...')
    
    -- Anti-cheat modülleri
    if Config.GodMode.Enabled then
        Fiveguard.GodMode.Initialize()
        print('^2[FIVEGUARD]^7 GodMode koruması aktif')
    end
    
    if Config.SpeedHack.Enabled then
        Fiveguard.SpeedHack.Initialize()
        print('^2[FIVEGUARD]^7 SpeedHack koruması aktif')
    end
    
    if Config.Teleport.Enabled then
        Fiveguard.Teleport.Initialize()
        print('^2[FIVEGUARD]^7 Teleport koruması aktif')
    end
    
    if Config.Weapon.Enabled then
        Fiveguard.Weapon.Initialize()
        print('^2[FIVEGUARD]^7 Silah koruması aktif')
    end
    
    if Config.Money.Enabled then
        Fiveguard.Money.Initialize()
        print('^2[FIVEGUARD]^7 Para koruması aktif')
    end
    
    if Config.Chat.Enabled then
        Fiveguard.Chat.Initialize()
        print('^2[FIVEGUARD]^7 Sohbet koruması aktif')
    end
    
    -- AI modülleri
    if Config.AI.Enabled then
        Fiveguard.AI.Initialize()
        print('^2[FIVEGUARD]^7 AI modülleri aktif')
    end
    
    print('^2[FIVEGUARD]^7 Tüm modüller başlatıldı')
end

-- Event'leri kaydet
function Fiveguard.RegisterEvents()
    print('^2[FIVEGUARD]^7 Event'ler kaydediliyor...')
    
    -- Oyuncu bağlantı event'leri
    AddEventHandler('playerConnecting', Fiveguard.OnPlayerConnecting)
    AddEventHandler('playerJoining', Fiveguard.OnPlayerJoining)
    AddEventHandler('playerDropped', Fiveguard.OnPlayerDropped)
    
    -- Framework event'leri
    if Config.Framework.Type == 'esx' or Config.Framework.Type == 'auto' then
        AddEventHandler(Config.Framework.ESX.PlayerLoaded, Fiveguard.OnPlayerLoaded)
        AddEventHandler(Config.Framework.ESX.PlayerDropped, Fiveguard.OnPlayerUnloaded)
    end
    
    if Config.Framework.Type == 'qbcore' or Config.Framework.Type == 'auto' then
        AddEventHandler(Config.Framework.QBCore.PlayerLoaded, Fiveguard.OnPlayerLoaded)
        AddEventHandler(Config.Framework.QBCore.PlayerDropped, Fiveguard.OnPlayerUnloaded)
    end
    
    -- İstemci event'leri
    RegisterNetEvent(Shared.Events.Client.DETECTION_TRIGGERED)
    AddEventHandler(Shared.Events.Client.DETECTION_TRIGGERED, Fiveguard.OnDetectionTriggered)
    
    RegisterNetEvent(Shared.Events.Client.SCREENSHOT_TAKEN)
    AddEventHandler(Shared.Events.Client.SCREENSHOT_TAKEN, Fiveguard.OnScreenshotTaken)
    
    RegisterNetEvent(Shared.Events.Client.BEHAVIOR_DATA)
    AddEventHandler(Shared.Events.Client.BEHAVIOR_DATA, Fiveguard.OnBehaviorData)
    
    RegisterNetEvent(Shared.Events.Client.HEARTBEAT)
    AddEventHandler(Shared.Events.Client.HEARTBEAT, Fiveguard.OnClientHeartbeat)
    
    print('^2[FIVEGUARD]^7 Event'ler kaydedildi')
end

-- Komutları kaydet
function Fiveguard.RegisterCommands()
    print('^2[FIVEGUARD]^7 Komutlar kaydediliyor...')
    
    -- Admin komutları
    RegisterCommand(Config.Admin.Commands.Ban, function(source, args, rawCommand)
        Fiveguard.Admin.BanCommand(source, args)
    end, true)
    
    RegisterCommand(Config.Admin.Commands.Unban, function(source, args, rawCommand)
        Fiveguard.Admin.UnbanCommand(source, args)
    end, true)
    
    RegisterCommand(Config.Admin.Commands.Check, function(source, args, rawCommand)
        Fiveguard.Admin.CheckCommand(source, args)
    end, true)
    
    RegisterCommand(Config.Admin.Commands.Stats, function(source, args, rawCommand)
        Fiveguard.Admin.StatsCommand(source, args)
    end, true)
    
    RegisterCommand(Config.Admin.Commands.Whitelist, function(source, args, rawCommand)
        Fiveguard.Admin.WhitelistCommand(source, args)
    end, true)
    
    print('^2[FIVEGUARD]^7 Komutlar kaydedildi')
end

-- Heartbeat başlat
function Fiveguard.StartHeartbeat()
    CreateThread(function()
        while true do
            Wait(60000) -- 1 dakika
            
            -- Lisans heartbeat
            Fiveguard.License.SendHeartbeat()
            
            -- Performans metrikleri
            Fiveguard.CollectMetrics()
            
            -- Temizlik işlemleri
            Fiveguard.Cleanup()
        end
    end)
end

-- =============================================
-- OYUNCU EVENT FONKSİYONLARI
-- =============================================

-- Oyuncu bağlanırken
function Fiveguard.OnPlayerConnecting(name, setKickReason, deferrals)
    local source = source
    local identifiers = GetPlayerIdentifiers(source)
    local ip = GetPlayerEndpoint(source)
    
    deferrals.defer()
    
    Wait(0)
    deferrals.update('Fiveguard güvenlik kontrolü yapılıyor...')
    
    -- Ban kontrolü
    local banInfo = Fiveguard.CheckPlayerBan(identifiers)
    if banInfo then
        deferrals.done('Sunucudan yasaklandınız!\nSebep: ' .. banInfo.reason .. '\nSüre: ' .. (banInfo.expires_at and Shared.FormatTime(banInfo.expires_at) or 'Kalıcı'))
        return
    end
    
    -- Whitelist kontrolü (eğer aktifse)
    if Config.AntiCheat.WhitelistBypass then
        local isWhitelisted = Fiveguard.CheckWhitelist(identifiers)
        if not isWhitelisted then
            deferrals.done('Bu sunucuya girmek için whitelist'te olmanız gerekiyor!')
            return
        end
    end
    
    -- VPN/Proxy kontrolü (eğer aktifse)
    if Config.AI.Enabled then
        local vpnCheck = Fiveguard.AI.CheckVPN(ip)
        if vpnCheck.isVPN then
            deferrals.done('VPN/Proxy kullanımı yasaktır!')
            return
        end
    end
    
    deferrals.done()
    
    -- Log kaydet
    Fiveguard.Logger.Info('Oyuncu bağlanıyor: ' .. name .. ' (' .. source .. ')', {
        identifiers = identifiers,
        ip = ip
    })
end

-- Oyuncu sunucuya girdiğinde
function Fiveguard.OnPlayerJoining(source)
    local identifiers = GetPlayerIdentifiers(source)
    local name = GetPlayerName(source)
    
    -- Oyuncu verisini oluştur
    Fiveguard.Players[source] = {
        source = source,
        name = name,
        identifiers = identifiers,
        joinTime = os.time(),
        trustScore = Config.AntiCheat.TrustScore.DefaultScore,
        violations = {},
        warnings = 0,
        lastPosition = vector3(0, 0, 0),
        lastVelocity = vector3(0, 0, 0),
        behaviorData = {},
        isWhitelisted = false,
        isBypassed = false
    }
    
    -- Veritabanına kaydet
    Fiveguard.Database.CreateOrUpdatePlayer(source, identifiers, name)
    
    -- Whitelist kontrolü
    Fiveguard.Players[source].isWhitelisted = Fiveguard.CheckWhitelist(identifiers)
    
    -- Bypass kontrolü
    Fiveguard.Players[source].isBypassed = IsPlayerAceAllowed(source, Config.Admin.BypassAce)
    
    -- İstemciye konfigürasyon gönder
    TriggerClientEvent(Shared.Events.Server.UPDATE_CONFIG, source, {
        debug = Config.Debug,
        ai = Config.AI,
        screenshot = Config.AI.Screenshot
    })
    
    -- Discord webhook
    if Config.Webhooks.Discord.Enabled then
        Fiveguard.Webhook.SendDiscord('player_join', {
            title = 'Oyuncu Sunucuya Girdi',
            description = name .. ' sunucuya katıldı',
            color = Config.Webhooks.Discord.Colors.info,
            fields = {
                {name = 'Oyuncu', value = name, inline = true},
                {name = 'ID', value = source, inline = true},
                {name = 'Güven Skoru', value = Fiveguard.Players[source].trustScore, inline = true}
            }
        })
    end
    
    print('^2[FIVEGUARD]^7 Oyuncu katıldı: ' .. name .. ' (' .. source .. ')')
end

-- Oyuncu sunucudan ayrıldığında
function Fiveguard.OnPlayerDropped(reason)
    local source = source
    local playerData = Fiveguard.Players[source]
    
    if playerData then
        -- Oyun süresini hesapla
        local playtime = os.time() - playerData.joinTime
        
        -- Veritabanını güncelle
        Fiveguard.Database.UpdatePlayerStats(source, playtime)
        
        -- Discord webhook
        if Config.Webhooks.Discord.Enabled then
            Fiveguard.Webhook.SendDiscord('player_leave', {
                title = 'Oyuncu Sunucudan Ayrıldı',
                description = playerData.name .. ' sunucudan ayrıldı',
                color = Config.Webhooks.Discord.Colors.warning,
                fields = {
                    {name = 'Oyuncu', value = playerData.name, inline = true},
                    {name = 'Sebep', value = reason, inline = true},
                    {name = 'Oyun Süresi', value = Shared.FormatDuration(playtime), inline = true}
                }
            })
        end
        
        print('^3[FIVEGUARD]^7 Oyuncu ayrıldı: ' .. playerData.name .. ' (' .. source .. ') - Sebep: ' .. reason)
        
        -- Oyuncu verisini temizle
        Fiveguard.Players[source] = nil
    end
end

-- Framework oyuncu yüklendiğinde
function Fiveguard.OnPlayerLoaded(source, xPlayer)
    if Fiveguard.Players[source] then
        Fiveguard.Players[source].frameworkLoaded = true
        Fiveguard.Players[source].xPlayer = xPlayer
        
        print('^2[FIVEGUARD]^7 Framework oyuncu verisi yüklendi: ' .. source)
    end
end

-- Framework oyuncu kaldırıldığında
function Fiveguard.OnPlayerUnloaded(source)
    if Fiveguard.Players[source] then
        Fiveguard.Players[source].frameworkLoaded = false
        Fiveguard.Players[source].xPlayer = nil
        
        print('^3[FIVEGUARD]^7 Framework oyuncu verisi kaldırıldı: ' .. source)
    end
end

-- =============================================
-- DETECTION EVENT FONKSİYONLARI
-- =============================================

-- İstemciden tespit geldiğinde
function Fiveguard.OnDetectionTriggered(detectionData)
    local source = source
    local playerData = Fiveguard.Players[source]
    
    if not playerData then return end
    
    -- Bypass kontrolü
    if playerData.isBypassed then
        if Config.Debug then
            print('^3[FIVEGUARD]^7 Tespit bypass edildi (Admin): ' .. playerData.name)
        end
        return
    end
    
    -- Whitelist bypass kontrolü
    if Config.AntiCheat.WhitelistBypass and playerData.isWhitelisted then
        if Config.Debug then
            print('^3[FIVEGUARD]^7 Tespit bypass edildi (Whitelist): ' .. playerData.name)
        end
        return
    end
    
    -- Tespit işle
    Fiveguard.ProcessDetection(source, detectionData)
end

-- Screenshot alındığında
function Fiveguard.OnScreenshotTaken(screenshotData)
    local source = source
    local playerData = Fiveguard.Players[source]
    
    if not playerData then return end
    
    -- AI analizi için gönder
    if Config.AI.Enabled then
        Fiveguard.AI.AnalyzeScreenshot(source, screenshotData)
    end
end

-- Davranış verisi geldiğinde
function Fiveguard.OnBehaviorData(behaviorData)
    local source = source
    local playerData = Fiveguard.Players[source]
    
    if not playerData then return end
    
    -- Davranış verisini kaydet
    playerData.behaviorData = behaviorData
    
    -- AI analizi için gönder
    if Config.AI.Enabled then
        Fiveguard.AI.AnalyzeBehavior(source, behaviorData)
    end
end

-- İstemci heartbeat
function Fiveguard.OnClientHeartbeat(data)
    local source = source
    local playerData = Fiveguard.Players[source]
    
    if not playerData then return end
    
    -- Son heartbeat zamanını güncelle
    playerData.lastHeartbeat = os.time()
    
    -- Pozisyon ve hız verilerini güncelle
    if data.position then
        playerData.lastPosition = data.position
    end
    
    if data.velocity then
        playerData.lastVelocity = data.velocity
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Oyuncu ban kontrolü
function Fiveguard.CheckPlayerBan(identifiers)
    return Fiveguard.Database.GetActiveBan(identifiers)
end

-- Whitelist kontrolü
function Fiveguard.CheckWhitelist(identifiers)
    return Fiveguard.Database.IsWhitelisted(identifiers)
end

-- Tespit işleme
function Fiveguard.ProcessDetection(source, detectionData)
    local playerData = Fiveguard.Players[source]
    if not playerData then return end
    
    -- Tespit verisini doğrula
    if not detectionData.type or not detectionData.confidence then
        return
    end
    
    -- Güven skoru kontrolü
    if detectionData.confidence < Config.AntiCheat.ConfidenceThresholds.Low then
        return -- Çok düşük güven skoru, görmezden gel
    end
    
    -- Önem seviyesini belirle
    local severity = Shared.GetDetectionSeverity(detectionData.type)
    local action = Shared.GetDefaultAction(severity)
    
    -- Güven skoruna göre eylemi ayarla
    if detectionData.confidence >= Config.AntiCheat.ConfidenceThresholds.Critical then
        action = Shared.ActionTypes.TEMP_BAN
    elseif detectionData.confidence >= Config.AntiCheat.ConfidenceThresholds.High then
        action = Shared.ActionTypes.KICK
    end
    
    -- Tespit kaydını oluştur
    local detection = {
        playerId = source,
        type = detectionData.type,
        severity = severity,
        confidence = detectionData.confidence,
        description = detectionData.description or '',
        evidence = detectionData.evidence or {},
        timestamp = os.time(),
        action = action
    }
    
    -- Veritabanına kaydet
    Fiveguard.Database.LogDetection(detection)
    
    -- Güven skorunu güncelle
    Fiveguard.UpdateTrustScore(source, detectionData.type, detectionData.confidence)
    
    -- Eylemi uygula
    Fiveguard.ApplyAction(source, action, detection)
    
    -- Log kaydet
    Fiveguard.Logger.Warning('Tespit: ' .. detectionData.type .. ' - ' .. playerData.name, detection)
    
    -- Discord webhook
    if Config.Webhooks.Discord.Enabled then
        Fiveguard.Webhook.SendDiscord('detection', {
            title = 'Anti-Cheat Tespiti',
            description = 'Oyuncu: ' .. playerData.name .. '\nTespit: ' .. detectionData.type,
            color = Shared.GetDiscordColor(severity),
            fields = {
                {name = 'Oyuncu', value = playerData.name, inline = true},
                {name = 'Tespit Türü', value = detectionData.type, inline = true},
                {name = 'Güven Skoru', value = Shared.FormatConfidence(detectionData.confidence), inline = true},
                {name = 'Önem', value = severity, inline = true},
                {name = 'Eylem', value = action, inline = true}
            }
        })
    end
end

-- Güven skorunu güncelle
function Fiveguard.UpdateTrustScore(source, detectionType, confidence)
    local playerData = Fiveguard.Players[source]
    if not playerData then return end
    
    -- Güven skoru azaltma miktarını hesapla
    local reduction = (confidence / 100) * 2 -- Maksimum 2 puan azaltma
    
    -- Tespit türüne göre çarpan uygula
    local multiplier = 1
    if detectionType == Shared.DetectionTypes.LUA_EXECUTOR or 
       detectionType == Shared.DetectionTypes.RESOURCE_INJECTION then
        multiplier = 2 -- Kritik tespitler için daha fazla azaltma
    end
    
    reduction = reduction * multiplier
    
    -- Güven skorunu güncelle
    playerData.trustScore = math.max(0, playerData.trustScore - reduction)
    
    -- Veritabanını güncelle
    Fiveguard.Database.UpdateTrustScore(source, playerData.trustScore)
    
    -- Kritik seviyeye düştüyse otomatik ban
    if playerData.trustScore <= Config.AntiCheat.TrustScore.CriticalThreshold then
        Fiveguard.BanPlayer(source, 'Düşük güven skoru (AI)', 86400) -- 24 saat
    end
end

-- Eylem uygula
function Fiveguard.ApplyAction(source, action, detection)
    local playerData = Fiveguard.Players[source]
    if not playerData then return end
    
    if action == Shared.ActionTypes.WARN then
        playerData.warnings = playerData.warnings + 1
        TriggerClientEvent(Shared.Events.Server.PLAYER_WARNED, source, detection)
        
        -- Maksimum uyarı sayısına ulaştıysa kick
        if playerData.warnings >= Config.AntiCheat.MaxWarnings then
            Fiveguard.KickPlayer(source, 'Çok fazla uyarı aldınız')
        end
        
    elseif action == Shared.ActionTypes.KICK then
        Fiveguard.KickPlayer(source, 'Anti-cheat tespiti: ' .. detection.type)
        
    elseif action == Shared.ActionTypes.TEMP_BAN then
        Fiveguard.BanPlayer(source, 'Anti-cheat tespiti: ' .. detection.type, Config.AntiCheat.BanDuration)
        
    elseif action == Shared.ActionTypes.PERMANENT_BAN then
        Fiveguard.BanPlayer(source, 'Kalıcı anti-cheat tespiti: ' .. detection.type, nil)
    end
end

-- Oyuncu kick
function Fiveguard.KickPlayer(source, reason)
    local playerData = Fiveguard.Players[source]
    if not playerData then return end
    
    DropPlayer(source, 'Fiveguard: ' .. reason)
    
    Fiveguard.Logger.Info('Oyuncu kick edildi: ' .. playerData.name .. ' - Sebep: ' .. reason)
end

-- Oyuncu ban
function Fiveguard.BanPlayer(source, reason, duration)
    local playerData = Fiveguard.Players[source]
    if not playerData then return end
    
    -- Ban kaydını oluştur
    local banData = {
        identifiers = playerData.identifiers,
        reason = reason,
        duration = duration,
        adminId = nil -- Sistem ban'ı
    }
    
    -- Veritabanına kaydet
    Fiveguard.Database.CreateBan(banData)
    
    -- Oyuncuyu at
    DropPlayer(source, 'Fiveguard: Sunucudan yasaklandınız!\nSebep: ' .. reason)
    
    Fiveguard.Logger.Warning('Oyuncu ban edildi: ' .. playerData.name .. ' - Sebep: ' .. reason)
end

-- Performans metrikleri topla
function Fiveguard.CollectMetrics()
    local playerCount = GetNumPlayerIndices()
    local detectionCount = #Fiveguard.Detections
    
    -- Veritabanına kaydet
    Fiveguard.Database.SaveMetrics({
        playerCount = playerCount,
        detectionCount = detectionCount,
        timestamp = os.time()
    })
end

-- Temizlik işlemleri
function Fiveguard.Cleanup()
    -- Eski tespitleri temizle
    local cutoffTime = os.time() - 3600 -- 1 saat öncesi
    for i = #Fiveguard.Detections, 1, -1 do
        if Fiveguard.Detections[i].timestamp < cutoffTime then
            table.remove(Fiveguard.Detections, i)
        end
    end
    
    -- Garbage collection
    if Config.Performance.MemoryOptimization.Enabled then
        collectgarbage('collect')
    end
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Oyuncu güven skorunu döndür
function GetPlayerTrustScore(source)
    local playerData = Fiveguard.Players[source]
    return playerData and playerData.trustScore or 0
end

-- Oyuncu ban durumunu kontrol et
function IsPlayerBanned(identifiers)
    return Fiveguard.Database.GetActiveBan(identifiers) ~= nil
end

-- Tespit kaydet
function LogDetection(source, detectionType, confidence, evidence)
    local detectionData = {
        type = detectionType,
        confidence = confidence,
        evidence = evidence or {}
    }
    
    Fiveguard.ProcessDetection(source, detectionData)
end

-- Oyuncu istatistiklerini döndür
function GetPlayerStats(source)
    local playerData = Fiveguard.Players[source]
    if not playerData then return nil end
    
    return {
        name = playerData.name,
        trustScore = playerData.trustScore,
        warnings = playerData.warnings,
        joinTime = playerData.joinTime,
        violations = playerData.violations
    }
end

-- Whitelist'e ekle
function AddToWhitelist(identifier, reason)
    return Fiveguard.Database.AddToWhitelist(identifier, reason)
end

-- Whitelist'ten çıkar
function RemoveFromWhitelist(identifier)
    return Fiveguard.Database.RemoveFromWhitelist(identifier)
end

-- =============================================
-- SİSTEM BAŞLATMA
-- =============================================

-- Sistem başlat
CreateThread(function()
    Wait(1000) -- Diğer resourceların yüklenmesini bekle
    
    if Fiveguard.Initialize() then
        print('^2[FIVEGUARD]^7 Sistem hazır!')
    else
        print('^1[FIVEGUARD]^7 Sistem başlatılamadı!')
    end
end)
