-- FIVEGUARD DATABASE MODULE
-- Veritabanı işlemleri ve bağlantı yönetimi

Fiveguard.Database = {}

-- =============================================
-- VERİTABANI BAĞLANTISI
-- =============================================

-- Veritabanı başlatma
function Fiveguard.Database.Initialize()
    print('^2[FIVEGUARD]^7 Veritabanı bağlantısı kuruluyor...')
    
    -- MySQL bağlantısını test et
    local success = false
    local attempts = 0
    local maxAttempts = 5
    
    while not success and attempts < maxAttempts do
        attempts = attempts + 1
        
        MySQL.ready(function()
            success = true
            print('^2[FIVEGUARD]^7 Veritabanı bağlantısı başarılı!')
        end)
        
        if not success then
            print('^3[FIVEGUARD]^7 Veritabanı bağlantısı deneme ' .. attempts .. '/' .. maxAttempts)
            Wait(2000) -- 2 saniye bekle
        end
    end
    
    if not success then
        print('^1[FIVEGUARD]^7 Veritabanı bağlantısı kurulamadı!')
        return false
    end
    
    -- Tabloları kontrol et ve oluştur
    Fiveguard.Database.CheckTables()
    
    return true
end

-- Tabloları kontrol et
function Fiveguard.Database.CheckTables()
    print('^2[FIVEGUARD]^7 Veritabanı tabloları kontrol ediliyor...')
    
    -- Temel tabloların varlığını kontrol et
    local tables = {
        'licenses', 'admin_users', 'players', 'detections', 
        'bans', 'system_logs', 'server_configs', 'access_lists'
    }
    
    for _, tableName in ipairs(tables) do
        MySQL.scalar('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ? AND table_name = ?', {
            Config.Database.Database, tableName
        }, function(count)
            if count == 0 then
                print('^1[FIVEGUARD]^7 UYARI: ' .. tableName .. ' tablosu bulunamadı!')
            end
        end)
    end
end

-- =============================================
-- OYUNCU İŞLEMLERİ
-- =============================================

-- Oyuncu oluştur veya güncelle
function Fiveguard.Database.CreateOrUpdatePlayer(source, identifiers, name)
    local licenseId = 1 -- Şimdilik sabit, gerçek uygulamada dinamik olacak
    local primaryIdentifier = identifiers[1] -- İlk identifier'ı kullan
    local ip = GetPlayerEndpoint(source)
    
    -- Oyuncu var mı kontrol et
    MySQL.scalar('SELECT id FROM players WHERE license_id = ? AND identifier = ?', {
        licenseId, primaryIdentifier
    }, function(playerId)
        if playerId then
            -- Oyuncu mevcut, güncelle
            MySQL.execute('UPDATE players SET name = ?, ip_address = ?, last_seen = NOW(), total_connections = total_connections + 1 WHERE id = ?', {
                name, ip, playerId
            })
        else
            -- Yeni oyuncu oluştur
            MySQL.execute('INSERT INTO players (license_id, identifier, name, ip_address, first_join, last_seen) VALUES (?, ?, ?, ?, NOW(), NOW())', {
                licenseId, primaryIdentifier, name, ip
            })
        end
    end)
end

-- Oyuncu istatistiklerini güncelle
function Fiveguard.Database.UpdatePlayerStats(source, playtime)
    local playerData = Fiveguard.Players[source]
    if not playerData then return end
    
    local primaryIdentifier = playerData.identifiers[1]
    
    MySQL.execute('UPDATE players SET playtime = playtime + ?, last_seen = NOW() WHERE identifier = ?', {
        math.floor(playtime / 60), -- Dakikaya çevir
        primaryIdentifier
    })
end

-- Güven skorunu güncelle
function Fiveguard.Database.UpdateTrustScore(source, trustScore)
    local playerData = Fiveguard.Players[source]
    if not playerData then return end
    
    local primaryIdentifier = playerData.identifiers[1]
    
    MySQL.execute('UPDATE players SET trust_score = ? WHERE identifier = ?', {
        trustScore, primaryIdentifier
    })
end

-- Oyuncu bilgilerini getir
function Fiveguard.Database.GetPlayer(identifier, callback)
    MySQL.single('SELECT * FROM players WHERE identifier = ?', {identifier}, callback)
end

-- Oyuncu ID'sini getir
function Fiveguard.Database.GetPlayerId(identifier, callback)
    MySQL.scalar('SELECT id FROM players WHERE identifier = ?', {identifier}, callback)
end

-- =============================================
-- BAN İŞLEMLERİ
-- =============================================

-- Aktif ban kontrolü
function Fiveguard.Database.GetActiveBan(identifiers)
    for _, identifier in ipairs(identifiers) do
        local result = MySQL.scalar.await('SELECT COUNT(*) FROM bans b JOIN players p ON b.player_id = p.id WHERE p.identifier = ? AND b.is_active = 1 AND (b.expires_at IS NULL OR b.expires_at > NOW())', {
            identifier
        })
        
        if result and result > 0 then
            local banInfo = MySQL.single.await('SELECT b.*, p.name FROM bans b JOIN players p ON b.player_id = p.id WHERE p.identifier = ? AND b.is_active = 1 AND (b.expires_at IS NULL OR b.expires_at > NOW()) ORDER BY b.banned_at DESC LIMIT 1', {
                identifier
            })
            return banInfo
        end
    end
    
    return nil
end

-- Ban oluştur
function Fiveguard.Database.CreateBan(banData)
    local primaryIdentifier = banData.identifiers[1]
    
    -- Oyuncu ID'sini al
    Fiveguard.Database.GetPlayerId(primaryIdentifier, function(playerId)
        if not playerId then return end
        
        local expiresAt = nil
        if banData.duration then
            expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + banData.duration)
        end
        
        MySQL.execute('INSERT INTO bans (license_id, player_id, admin_id, ban_type, reason, evidence, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            1, -- Şimdilik sabit lisans ID
            playerId,
            banData.adminId,
            banData.duration and 'temporary' or 'permanent',
            banData.reason,
            json.encode(banData.evidence or {}),
            expiresAt
        })
    end)
end

-- Ban kaldır
function Fiveguard.Database.RemoveBan(identifier, adminId, reason)
    Fiveguard.Database.GetPlayerId(identifier, function(playerId)
        if not playerId then return end
        
        MySQL.execute('UPDATE bans SET is_active = 0, unbanned_by = ?, unbanned_at = NOW(), unban_reason = ? WHERE player_id = ? AND is_active = 1', {
            adminId, reason, playerId
        })
    end)
end

-- =============================================
-- DETECTION İŞLEMLERİ
-- =============================================

-- Tespit kaydet
function Fiveguard.Database.LogDetection(detection)
    local playerData = Fiveguard.Players[detection.playerId]
    if not playerData then return end
    
    local primaryIdentifier = playerData.identifiers[1]
    
    Fiveguard.Database.GetPlayerId(primaryIdentifier, function(playerId)
        if not playerId then return end
        
        MySQL.execute('INSERT INTO detections (license_id, player_id, detection_type, severity, confidence_score, description, evidence, action_taken) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            1, -- Şimdilik sabit lisans ID
            playerId,
            detection.type,
            detection.severity,
            detection.confidence,
            detection.description,
            json.encode(detection.evidence),
            detection.action
        })
    end)
end

-- Son tespitleri getir
function Fiveguard.Database.GetRecentDetections(limit, callback)
    limit = limit or 50
    
    MySQL.query('SELECT d.*, p.name, p.identifier FROM detections d JOIN players p ON d.player_id = p.id ORDER BY d.detected_at DESC LIMIT ?', {
        limit
    }, callback)
end

-- Oyuncu tespitlerini getir
function Fiveguard.Database.GetPlayerDetections(identifier, callback)
    MySQL.query('SELECT d.* FROM detections d JOIN players p ON d.player_id = p.id WHERE p.identifier = ? ORDER BY d.detected_at DESC', {
        identifier
    }, callback)
end

-- =============================================
-- WHİTELİST İŞLEMLERİ
-- =============================================

-- Whitelist kontrolü
function Fiveguard.Database.IsWhitelisted(identifiers)
    for _, identifier in ipairs(identifiers) do
        local result = MySQL.scalar.await('SELECT COUNT(*) FROM access_lists WHERE list_type = "whitelist" AND entry_value = ? AND is_active = 1 AND (expires_at IS NULL OR expires_at > NOW())', {
            identifier
        })
        
        if result and result > 0 then
            return true
        end
    end
    
    return false
end

-- Whitelist'e ekle
function Fiveguard.Database.AddToWhitelist(identifier, reason, adminId)
    MySQL.execute('INSERT INTO access_lists (license_id, list_type, entry_type, entry_value, reason, added_by) VALUES (?, ?, ?, ?, ?, ?)', {
        1, -- Şimdilik sabit lisans ID
        'whitelist',
        'identifier',
        identifier,
        reason,
        adminId
    })
    
    return true
end

-- Whitelist'ten çıkar
function Fiveguard.Database.RemoveFromWhitelist(identifier)
    MySQL.execute('UPDATE access_lists SET is_active = 0 WHERE list_type = "whitelist" AND entry_value = ?', {
        identifier
    })
    
    return true
end

-- =============================================
-- LOG İŞLEMLERİ
-- =============================================

-- Sistem logu kaydet
function Fiveguard.Database.LogSystem(level, category, message, context, userId)
    context = context or {}
    
    MySQL.execute('INSERT INTO system_logs (license_id, log_level, category, message, context, user_id, ip_address) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        1, -- Şimdilik sabit lisans ID
        level,
        category,
        message,
        json.encode(context),
        userId,
        context.ip or nil
    })
end

-- Son logları getir
function Fiveguard.Database.GetRecentLogs(level, category, limit, callback)
    limit = limit or 100
    local whereClause = ''
    local params = {1} -- Lisans ID
    
    if level then
        whereClause = whereClause .. ' AND log_level = ?'
        table.insert(params, level)
    end
    
    if category then
        whereClause = whereClause .. ' AND category = ?'
        table.insert(params, category)
    end
    
    table.insert(params, limit)
    
    MySQL.query('SELECT * FROM system_logs WHERE license_id = ?' .. whereClause .. ' ORDER BY created_at DESC LIMIT ?', params, callback)
end

-- =============================================
-- KONFİGÜRASYON İŞLEMLERİ
-- =============================================

-- Konfigürasyon kaydet
function Fiveguard.Database.SaveConfig(key, value, type, userId)
    MySQL.execute('INSERT INTO server_configs (license_id, config_key, config_value, config_type, updated_by) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE config_value = ?, updated_by = ?, updated_at = NOW()', {
        1, -- Şimdilik sabit lisans ID
        key,
        json.encode(value),
        type,
        userId,
        json.encode(value),
        userId
    })
end

-- Konfigürasyon getir
function Fiveguard.Database.GetConfig(key, callback)
    MySQL.single('SELECT config_value FROM server_configs WHERE license_id = ? AND config_key = ?', {
        1, key
    }, function(result)
        if result then
            local success, value = pcall(json.decode, result.config_value)
            callback(success and value or nil)
        else
            callback(nil)
        end
    end)
end

-- Tüm konfigürasyonları getir
function Fiveguard.Database.GetAllConfigs(callback)
    MySQL.query('SELECT config_key, config_value, config_type FROM server_configs WHERE license_id = ?', {
        1
    }, function(results)
        local configs = {}
        
        for _, row in ipairs(results) do
            local success, value = pcall(json.decode, row.config_value)
            if success then
                configs[row.config_key] = {
                    value = value,
                    type = row.config_type
                }
            end
        end
        
        callback(configs)
    end)
end

-- =============================================
-- PERFORMANS METRİKLERİ
-- =============================================

-- Metrikleri kaydet
function Fiveguard.Database.SaveMetrics(metrics)
    MySQL.execute('INSERT INTO server_metrics (license_id, cpu_usage, memory_usage, player_count, detection_count_hourly) VALUES (?, ?, ?, ?, ?)', {
        1, -- Şimdilik sabit lisans ID
        metrics.cpuUsage or 0,
        metrics.memoryUsage or 0,
        metrics.playerCount or 0,
        metrics.detectionCount or 0
    })
end

-- Son metrikleri getir
function Fiveguard.Database.GetRecentMetrics(hours, callback)
    hours = hours or 24
    
    MySQL.query('SELECT * FROM server_metrics WHERE license_id = ? AND recorded_at >= DATE_SUB(NOW(), INTERVAL ? HOUR) ORDER BY recorded_at DESC', {
        1, hours
    }, callback)
end

-- =============================================
-- İSTATİSTİKLER
-- =============================================

-- Genel istatistikleri getir
function Fiveguard.Database.GetStats(callback)
    local stats = {}
    
    -- Toplam oyuncu sayısı
    MySQL.scalar('SELECT COUNT(*) FROM players WHERE license_id = ?', {1}, function(count)
        stats.totalPlayers = count or 0
        
        -- Aktif ban sayısı
        MySQL.scalar('SELECT COUNT(*) FROM bans WHERE license_id = ? AND is_active = 1', {1}, function(count)
            stats.activeBans = count or 0
            
            -- Bugünkü tespit sayısı
            MySQL.scalar('SELECT COUNT(*) FROM detections WHERE license_id = ? AND DATE(detected_at) = CURDATE()', {1}, function(count)
                stats.todayDetections = count or 0
                
                -- Bu ayki tespit sayısı
                MySQL.scalar('SELECT COUNT(*) FROM detections WHERE license_id = ? AND MONTH(detected_at) = MONTH(NOW()) AND YEAR(detected_at) = YEAR(NOW())', {1}, function(count)
                    stats.monthlyDetections = count or 0
                    
                    callback(stats)
                end)
            end)
        end)
    end)
end

-- Tespit türü istatistikleri
function Fiveguard.Database.GetDetectionStats(days, callback)
    days = days or 7
    
    MySQL.query('SELECT detection_type, COUNT(*) as count FROM detections WHERE license_id = ? AND detected_at >= DATE_SUB(NOW(), INTERVAL ? DAY) GROUP BY detection_type ORDER BY count DESC', {
        1, days
    }, callback)
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Veritabanı bağlantısını test et
function Fiveguard.Database.TestConnection()
    MySQL.scalar('SELECT 1', {}, function(result)
        if result then
            print('^2[FIVEGUARD]^7 Veritabanı bağlantısı aktif')
            return true
        else
            print('^1[FIVEGUARD]^7 Veritabanı bağlantısı sorunu!')
            return false
        end
    end)
end

-- Veritabanını temizle (eski kayıtları sil)
function Fiveguard.Database.Cleanup()
    local cleanupDays = 30 -- 30 gün öncesini temizle
    
    -- Eski logları sil
    MySQL.execute('DELETE FROM system_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL ? DAY)', {cleanupDays})
    
    -- Eski metrikleri sil
    MySQL.execute('DELETE FROM server_metrics WHERE recorded_at < DATE_SUB(NOW(), INTERVAL ? DAY)', {cleanupDays})
    
    -- Süresi dolmuş ban'ları pasif yap
    MySQL.execute('UPDATE bans SET is_active = 0 WHERE expires_at IS NOT NULL AND expires_at < NOW() AND is_active = 1')
    
    print('^2[FIVEGUARD]^7 Veritabanı temizlik işlemi tamamlandı')
end

-- Veritabanı yedekle (basit)
function Fiveguard.Database.Backup()
    -- Bu fonksiyon gerçek bir uygulamada mysqldump kullanabilir
    print('^3[FIVEGUARD]^7 Veritabanı yedekleme özelliği henüz implementasyonda değil')
end

print('^2[FIVEGUARD]^7 Database modülü yüklendi')
