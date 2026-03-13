-- FIVEGUARD WEBHOOK MODULE
-- Discord ve diğer webhook entegrasyonları

Fiveguard.Webhook = {}

-- =============================================
-- WEBHOOK BAŞLATMA
-- =============================================

function Fiveguard.Webhook.Initialize()
    print('^2[FIVEGUARD]^7 Webhook sistemi başlatılıyor...')
    
    -- Webhook URL'lerini kontrol et
    if Config.Webhooks.Discord.Enabled then
        if not Config.Webhooks.Discord.Url or Config.Webhooks.Discord.Url == '' then
            print('^3[FIVEGUARD]^7 UYARI: Discord webhook URL'si boş!')
            Config.Webhooks.Discord.Enabled = false
        else
            print('^2[FIVEGUARD]^7 Discord webhook aktif')
        end
    end
    
    -- Test mesajı gönder
    if Config.Webhooks.Discord.Enabled and Config.Debug then
        Fiveguard.Webhook.SendDiscord('startup', {
            title = 'Fiveguard Başlatıldı',
            description = 'AI Destekli Anti-Cheat Sistemi başarıyla başlatıldı',
            color = Config.Webhooks.Discord.Colors.success,
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        })
    end
    
    print('^2[FIVEGUARD]^7 Webhook sistemi hazır')
end

-- =============================================
-- DISCORD WEBHOOK FONKSİYONLARI
-- =============================================

-- Discord'a mesaj gönder
function Fiveguard.Webhook.SendDiscord(eventType, data)
    if not Config.Webhooks.Discord.Enabled then return end
    
    -- Event kontrolü
    if not Fiveguard.Webhook.ShouldSendEvent(eventType) then return end
    
    -- Embed oluştur
    local embed = Fiveguard.Webhook.CreateEmbed(data)
    
    -- Webhook payload'ı hazırla
    local payload = {
        username = Config.Webhooks.Discord.Username,
        avatar_url = Config.Webhooks.Discord.Avatar,
        embeds = {embed}
    }
    
    -- Rate limiting kontrolü
    if not Fiveguard.Webhook.CheckRateLimit() then
        if Config.Debug then
            print('^3[FIVEGUARD]^7 Webhook rate limit aşıldı, mesaj atlandı')
        end
        return
    end
    
    -- HTTP isteği gönder
    PerformHttpRequest(Config.Webhooks.Discord.Url, function(errorCode, resultData, resultHeaders)
        if errorCode == 200 or errorCode == 204 then
            if Config.Debug then
                print('^2[FIVEGUARD]^7 Discord webhook başarıyla gönderildi')
            end
        else
            print('^1[FIVEGUARD]^7 Discord webhook hatası: ' .. tostring(errorCode))
            if Config.Debug and resultData then
                print('^1[FIVEGUARD]^7 Hata detayı: ' .. tostring(resultData))
            end
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

-- Embed oluştur
function Fiveguard.Webhook.CreateEmbed(data)
    local embed = {
        title = data.title or 'Fiveguard Bildirimi',
        description = data.description or '',
        color = data.color or Config.Webhooks.Discord.Colors.info,
        timestamp = data.timestamp or os.date('!%Y-%m-%dT%H:%M:%SZ'),
        footer = {
            text = 'Fiveguard Anti-Cheat v' .. Fiveguard.Version,
            icon_url = Config.Webhooks.Discord.Avatar
        }
    }
    
    -- Alanları ekle
    if data.fields and type(data.fields) == 'table' then
        embed.fields = {}
        for _, field in ipairs(data.fields) do
            if field.name and field.value then
                table.insert(embed.fields, {
                    name = tostring(field.name),
                    value = tostring(field.value),
                    inline = field.inline or false
                })
            end
        end
    end
    
    -- Thumbnail ekle
    if data.thumbnail then
        embed.thumbnail = {url = data.thumbnail}
    end
    
    -- Image ekle
    if data.image then
        embed.image = {url = data.image}
    end
    
    -- Author ekle
    if data.author then
        embed.author = {
            name = data.author.name or 'Fiveguard',
            icon_url = data.author.icon or Config.Webhooks.Discord.Avatar,
            url = data.author.url
        }
    end
    
    return embed
end

-- =============================================
-- ÖZELLEŞTİRİLMİŞ WEBHOOK FONKSİYONLARI
-- =============================================

-- Tespit bildirimi
function Fiveguard.Webhook.SendDetection(playerName, detectionType, confidence, evidence, action)
    local severity = Shared.GetDetectionSeverity(detectionType)
    local color = Shared.GetDiscordColor(severity)
    
    local embed = {
        title = '🚨 Anti-Cheat Tespiti',
        description = string.format('**%s** adlı oyuncuda **%s** tespiti yapıldı', playerName, detectionType),
        color = color,
        fields = {
            {name = '👤 Oyuncu', value = playerName, inline = true},
            {name = '🎯 Tespit Türü', value = detectionType, inline = true},
            {name = '📊 Güven Skoru', value = Shared.FormatConfidence(confidence), inline = true},
            {name = '⚠️ Önem Seviyesi', value = string.upper(severity), inline = true},
            {name = '⚡ Alınan Eylem', value = string.upper(action), inline = true},
            {name = '🕐 Zaman', value = os.date('%H:%M:%S'), inline = true}
        }
    }
    
    -- Kanıt bilgilerini ekle
    if evidence and next(evidence) then
        local evidenceStr = ''
        for key, value in pairs(evidence) do
            evidenceStr = evidenceStr .. string.format('**%s:** %s\n', key, tostring(value))
        end
        
        if #evidenceStr > 0 then
            table.insert(embed.fields, {
                name = '🔍 Kanıtlar',
                value = evidenceStr:sub(1, 1024), -- Discord limit
                inline = false
            })
        end
    end
    
    Fiveguard.Webhook.SendDiscord('detection', embed)
end

-- Ban bildirimi
function Fiveguard.Webhook.SendBan(playerName, reason, duration, adminName)
    local embed = {
        title = '🔨 Oyuncu Yasaklandı',
        description = string.format('**%s** adlı oyuncu sunucudan yasaklandı', playerName),
        color = Config.Webhooks.Discord.Colors.error,
        fields = {
            {name = '👤 Oyuncu', value = playerName, inline = true},
            {name = '📝 Sebep', value = reason, inline = true},
            {name = '⏰ Süre', value = duration and Shared.FormatDuration(duration) or 'Kalıcı', inline = true}
        }
    }
    
    if adminName then
        table.insert(embed.fields, {name = '👮 Admin', value = adminName, inline = true})
    end
    
    Fiveguard.Webhook.SendDiscord('ban', embed)
end

-- Unban bildirimi
function Fiveguard.Webhook.SendUnban(playerName, reason, adminName)
    local embed = {
        title = '✅ Oyuncu Yasağı Kaldırıldı',
        description = string.format('**%s** adlı oyuncunun yasağı kaldırıldı', playerName),
        color = Config.Webhooks.Discord.Colors.success,
        fields = {
            {name = '👤 Oyuncu', value = playerName, inline = true},
            {name = '📝 Sebep', value = reason, inline = true},
            {name = '👮 Admin', value = adminName or 'Sistem', inline = true}
        }
    }
    
    Fiveguard.Webhook.SendDiscord('unban', embed)
end

-- Oyuncu bağlantı bildirimi
function Fiveguard.Webhook.SendPlayerConnection(playerName, playerId, action, details)
    local isJoin = action == 'join'
    local embed = {
        title = isJoin and '📥 Oyuncu Katıldı' or '📤 Oyuncu Ayrıldı',
        description = string.format('**%s** sunucuya %s', playerName, isJoin and 'katıldı' or 'ayrıldı'),
        color = isJoin and Config.Webhooks.Discord.Colors.success or Config.Webhooks.Discord.Colors.warning,
        fields = {
            {name = '👤 Oyuncu', value = playerName, inline = true},
            {name = '🆔 ID', value = tostring(playerId), inline = true},
            {name = '🕐 Zaman', value = os.date('%H:%M:%S'), inline = true}
        }
    }
    
    -- Ek detayları ekle
    if details and next(details) then
        for key, value in pairs(details) do
            table.insert(embed.fields, {
                name = tostring(key),
                value = tostring(value),
                inline = true
            })
        end
    end
    
    Fiveguard.Webhook.SendDiscord(isJoin and 'player_join' or 'player_leave', embed)
end

-- Admin eylem bildirimi
function Fiveguard.Webhook.SendAdminAction(adminName, action, target, reason, details)
    local embed = {
        title = '👮 Admin Eylemi',
        description = string.format('**%s** tarafından **%s** eylemi gerçekleştirildi', adminName, action),
        color = Config.Webhooks.Discord.Colors.warning,
        fields = {
            {name = '👮 Admin', value = adminName, inline = true},
            {name = '⚡ Eylem', value = action, inline = true},
            {name = '🎯 Hedef', value = target or 'N/A', inline = true}
        }
    }
    
    if reason then
        table.insert(embed.fields, {name = '📝 Sebep', value = reason, inline = false})
    end
    
    -- Ek detayları ekle
    if details and next(details) then
        local detailsStr = ''
        for key, value in pairs(details) do
            detailsStr = detailsStr .. string.format('**%s:** %s\n', key, tostring(value))
        end
        
        if #detailsStr > 0 then
            table.insert(embed.fields, {
                name = '📋 Detaylar',
                value = detailsStr:sub(1, 1024),
                inline = false
            })
        end
    end
    
    Fiveguard.Webhook.SendDiscord('admin_action', embed)
end

-- Sistem hatası bildirimi
function Fiveguard.Webhook.SendSystemError(errorMessage, module, stackTrace)
    local embed = {
        title = '💥 Sistem Hatası',
        description = string.format('**%s** modülünde hata oluştu', module or 'UNKNOWN'),
        color = Config.Webhooks.Discord.Colors.error,
        fields = {
            {name = '📦 Modül', value = module or 'UNKNOWN', inline = true},
            {name = '🕐 Zaman', value = os.date('%H:%M:%S'), inline = true},
            {name = '❌ Hata', value = errorMessage:sub(1, 1024), inline = false}
        }
    }
    
    if stackTrace then
        table.insert(embed.fields, {
            name = '📋 Stack Trace',
            value = '```\n' .. stackTrace:sub(1, 1000) .. '\n```',
            inline = false
        })
    end
    
    Fiveguard.Webhook.SendDiscord('system_error', embed)
end

-- Performans uyarısı
function Fiveguard.Webhook.SendPerformanceAlert(metric, value, threshold, details)
    local embed = {
        title = '⚠️ Performans Uyarısı',
        description = string.format('**%s** metriği eşik değeri aştı', metric),
        color = Config.Webhooks.Discord.Colors.warning,
        fields = {
            {name = '📊 Metrik', value = metric, inline = true},
            {name = '📈 Değer', value = tostring(value), inline = true},
            {name = '🎯 Eşik', value = tostring(threshold), inline = true}
        }
    }
    
    if details then
        table.insert(embed.fields, {
            name = '📋 Detaylar',
            value = tostring(details),
            inline = false
        })
    end
    
    Fiveguard.Webhook.SendDiscord('performance_alert', embed)
end

-- =============================================
-- RATE LİMİTİNG VE KONTROL
-- =============================================

-- Rate limiting değişkenleri
local webhookQueue = {}
local lastWebhookTime = 0
local webhookCount = 0
local rateLimitWindow = 60000 -- 1 dakika
local maxWebhooksPerWindow = 30 -- Dakikada maksimum 30 webhook

-- Rate limit kontrolü
function Fiveguard.Webhook.CheckRateLimit()
    local currentTime = GetGameTimer()
    
    -- Zaman penceresi sıfırlandı mı?
    if currentTime - lastWebhookTime > rateLimitWindow then
        webhookCount = 0
        lastWebhookTime = currentTime
    end
    
    -- Limit aşıldı mı?
    if webhookCount >= maxWebhooksPerWindow then
        return false
    end
    
    webhookCount = webhookCount + 1
    return true
end

-- Event gönderim kontrolü
function Fiveguard.Webhook.ShouldSendEvent(eventType)
    if not Config.Webhooks.Discord.Events then return true end
    
    -- Event listesi boşsa hepsini gönder
    if #Config.Webhooks.Discord.Events == 0 then return true end
    
    -- Event listesinde var mı kontrol et
    for _, allowedEvent in ipairs(Config.Webhooks.Discord.Events) do
        if allowedEvent == eventType then
            return true
        end
    end
    
    return false
end

-- =============================================
-- WEBHOOK QUEUE SİSTEMİ
-- =============================================

-- Webhook'u kuyruğa ekle
function Fiveguard.Webhook.QueueWebhook(eventType, data, priority)
    priority = priority or 1 -- 1 = düşük, 2 = orta, 3 = yüksek
    
    table.insert(webhookQueue, {
        eventType = eventType,
        data = data,
        priority = priority,
        timestamp = GetGameTimer()
    })
    
    -- Kuyruğu önceliğe göre sırala
    table.sort(webhookQueue, function(a, b)
        if a.priority == b.priority then
            return a.timestamp < b.timestamp
        end
        return a.priority > b.priority
    end)
    
    -- Kuyruk çok uzunsa eski öğeleri sil
    if #webhookQueue > 100 then
        for i = 101, #webhookQueue do
            webhookQueue[i] = nil
        end
    end
end

-- Kuyruktaki webhook'ları işle
function Fiveguard.Webhook.ProcessQueue()
    if #webhookQueue == 0 then return end
    
    local webhook = table.remove(webhookQueue, 1)
    if webhook then
        Fiveguard.Webhook.SendDiscord(webhook.eventType, webhook.data)
    end
end

-- Kuyruk işleyicisini başlat
function Fiveguard.Webhook.StartQueueProcessor()
    CreateThread(function()
        while true do
            Wait(5000) -- 5 saniyede bir kontrol et
            Fiveguard.Webhook.ProcessQueue()
        end
    end)
end

-- =============================================
-- WEBHOOK TEST FONKSİYONLARI
-- =============================================

-- Webhook bağlantısını test et
function Fiveguard.Webhook.TestConnection(callback)
    if not Config.Webhooks.Discord.Enabled then
        callback(false, 'Discord webhook devre dışı')
        return
    end
    
    local testPayload = {
        username = Config.Webhooks.Discord.Username,
        content = 'Fiveguard webhook bağlantı testi - ' .. os.date('%H:%M:%S')
    }
    
    PerformHttpRequest(Config.Webhooks.Discord.Url, function(errorCode, resultData, resultHeaders)
        local success = errorCode == 200 or errorCode == 204
        local message = success and 'Bağlantı başarılı' or ('Hata kodu: ' .. tostring(errorCode))
        
        callback(success, message)
    end, 'POST', json.encode(testPayload), {
        ['Content-Type'] = 'application/json'
    })
end

-- Test mesajı gönder
function Fiveguard.Webhook.SendTestMessage()
    local embed = {
        title = '🧪 Test Mesajı',
        description = 'Bu bir Fiveguard webhook test mesajıdır',
        color = Config.Webhooks.Discord.Colors.info,
        fields = {
            {name = '🕐 Zaman', value = os.date('%Y-%m-%d %H:%M:%S'), inline = true},
            {name = '🔧 Versiyon', value = Fiveguard.Version, inline = true},
            {name = '📊 Durum', value = 'Aktif', inline = true}
        }
    }
    
    Fiveguard.Webhook.SendDiscord('test', embed)
end

-- =============================================
-- WEBHOOK İSTATİSTİKLERİ
-- =============================================

-- Webhook istatistikleri
local webhookStats = {
    sent = 0,
    failed = 0,
    queued = 0,
    lastSent = 0
}

-- İstatistikleri güncelle
function Fiveguard.Webhook.UpdateStats(success)
    if success then
        webhookStats.sent = webhookStats.sent + 1
        webhookStats.lastSent = GetGameTimer()
    else
        webhookStats.failed = webhookStats.failed + 1
    end
end

-- İstatistikleri getir
function Fiveguard.Webhook.GetStats()
    webhookStats.queued = #webhookQueue
    return webhookStats
end

-- İstatistikleri sıfırla
function Fiveguard.Webhook.ResetStats()
    webhookStats = {
        sent = 0,
        failed = 0,
        queued = #webhookQueue,
        lastSent = 0
    }
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Mesajı temizle (Discord formatına uygun hale getir)
function Fiveguard.Webhook.SanitizeMessage(message)
    if not message then return '' end
    
    -- Discord'da sorun çıkarabilecek karakterleri temizle
    message = string.gsub(message, '@everyone', '@\u200beveryone')
    message = string.gsub(message, '@here', '@\u200bhere')
    
    -- Uzun mesajları kısalt
    if #message > 2000 then
        message = message:sub(1, 1997) .. '...'
    end
    
    return message
end

-- Embed alanlarını doğrula
function Fiveguard.Webhook.ValidateEmbed(embed)
    if not embed then return false end
    
    -- Başlık kontrolü
    if embed.title and #embed.title > 256 then
        embed.title = embed.title:sub(1, 253) .. '...'
    end
    
    -- Açıklama kontrolü
    if embed.description and #embed.description > 4096 then
        embed.description = embed.description:sub(1, 4093) .. '...'
    end
    
    -- Alan kontrolü
    if embed.fields then
        for i, field in ipairs(embed.fields) do
            if i > 25 then -- Discord maksimum 25 alan
                embed.fields[i] = nil
            else
                if field.name and #field.name > 256 then
                    field.name = field.name:sub(1, 253) .. '...'
                end
                if field.value and #field.value > 1024 then
                    field.value = field.value:sub(1, 1021) .. '...'
                end
            end
        end
    end
    
    return true
end

-- Webhook URL'sini doğrula
function Fiveguard.Webhook.ValidateWebhookUrl(url)
    if not url or url == '' then return false end
    
    -- Discord webhook URL formatını kontrol et
    local pattern = 'https://discord%.com/api/webhooks/%d+/[%w%-_]+'
    return string.match(url, pattern) ~= nil
end

print('^2[FIVEGUARD]^7 Webhook modülü yüklendi')
