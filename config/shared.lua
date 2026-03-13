-- FIVEGUARD SHARED CONFIGURATION
-- Sunucu ve istemci arasında paylaşılan ayarlar

Shared = {}

-- =============================================
-- DETECTION TYPES (Tespit Türleri)
-- =============================================

Shared.DetectionTypes = {
    GODMODE = 'godmode',
    SPEEDHACK = 'speedhack',
    TELEPORT = 'teleport',
    AIMBOT = 'aimbot',
    ESP = 'esp',
    NOCLIP = 'noclip',
    FREECAM = 'freecam',
    LUA_EXECUTOR = 'lua_executor',
    RESOURCE_INJECTION = 'resource_injection',
    MENU_INJECTION = 'menu_injection',
    DAMAGE_MODIFIER = 'damage_modifier',
    WEAPON_SPAWN = 'weapon_spawn',
    MONEY_EXPLOIT = 'money_exploit',
    ITEM_SPAWN = 'item_spawn',
    VEHICLE_SPAWN = 'vehicle_spawn',
    EXPLOSION_SPAM = 'explosion_spam',
    PARTICLE_SPAM = 'particle_spam',
    CHAT_SPAM = 'chat_spam',
    SQL_INJECTION = 'sql_injection',
    XSS_ATTEMPT = 'xss_attempt',
    SUSPICIOUS_BEHAVIOR = 'suspicious_behavior'
}

-- =============================================
-- SEVERITY LEVELS (Önem Seviyeleri)
-- =============================================

Shared.SeverityLevels = {
    LOW = 'low',
    MEDIUM = 'medium',
    HIGH = 'high',
    CRITICAL = 'critical'
}

-- =============================================
-- ACTION TYPES (Eylem Türleri)
-- =============================================

Shared.ActionTypes = {
    NONE = 'none',
    WARN = 'warn',
    KICK = 'kick',
    TEMP_BAN = 'temp_ban',
    PERMANENT_BAN = 'permanent_ban'
}

-- =============================================
-- BAN TYPES (Ban Türleri)
-- =============================================

Shared.BanTypes = {
    TEMPORARY = 'temporary',
    PERMANENT = 'permanent',
    HARDWARE = 'hardware'
}

-- =============================================
-- LOG LEVELS (Log Seviyeleri)
-- =============================================

Shared.LogLevels = {
    DEBUG = 'debug',
    INFO = 'info',
    WARNING = 'warning',
    ERROR = 'error',
    CRITICAL = 'critical'
}

-- =============================================
-- EVENTS (Olaylar)
-- =============================================

Shared.Events = {
    -- Sunucu -> İstemci
    Server = {
        PLAYER_BANNED = 'fiveguard:playerBanned',
        PLAYER_KICKED = 'fiveguard:playerKicked',
        PLAYER_WARNED = 'fiveguard:playerWarned',
        TAKE_SCREENSHOT = 'fiveguard:takeScreenshot',
        UPDATE_CONFIG = 'fiveguard:updateConfig',
        SHOW_NOTIFICATION = 'fiveguard:showNotification',
        OPEN_ADMIN_MENU = 'fiveguard:openAdminMenu',
        CLOSE_ADMIN_MENU = 'fiveguard:closeAdminMenu'
    },
    
    -- İstemci -> Sunucu
    Client = {
        DETECTION_TRIGGERED = 'fiveguard:detectionTriggered',
        SCREENSHOT_TAKEN = 'fiveguard:screenshotTaken',
        BEHAVIOR_DATA = 'fiveguard:behaviorData',
        ADMIN_ACTION = 'fiveguard:adminAction',
        PLAYER_REPORT = 'fiveguard:playerReport',
        HEARTBEAT = 'fiveguard:heartbeat'
    },
    
    -- Çift yönlü
    Shared = {
        SYNC_DATA = 'fiveguard:syncData',
        REQUEST_DATA = 'fiveguard:requestData',
        RESPONSE_DATA = 'fiveguard:responseData'
    }
}

-- =============================================
-- NOTIFICATION TYPES (Bildirim Türleri)
-- =============================================

Shared.NotificationTypes = {
    INFO = 'info',
    SUCCESS = 'success',
    WARNING = 'warning',
    ERROR = 'error'
}

-- =============================================
-- ADMIN PERMISSIONS (Admin İzinleri)
-- =============================================

Shared.AdminPermissions = {
    VIEW_DASHBOARD = 'fiveguard.view.dashboard',
    VIEW_PLAYERS = 'fiveguard.view.players',
    VIEW_LOGS = 'fiveguard.view.logs',
    VIEW_BANS = 'fiveguard.view.bans',
    MANAGE_PLAYERS = 'fiveguard.manage.players',
    MANAGE_BANS = 'fiveguard.manage.bans',
    MANAGE_CONFIG = 'fiveguard.manage.config',
    MANAGE_WHITELIST = 'fiveguard.manage.whitelist',
    BYPASS_ANTICHEAT = 'fiveguard.bypass',
    SUPER_ADMIN = 'fiveguard.superadmin'
}

-- =============================================
-- FRAMEWORK TYPES (Framework Türleri)
-- =============================================

Shared.FrameworkTypes = {
    ESX = 'esx',
    QBCORE = 'qbcore',
    VRP = 'vrp',
    STANDALONE = 'standalone'
}

-- =============================================
-- WEAPON CATEGORIES (Silah Kategorileri)
-- =============================================

Shared.WeaponCategories = {
    MELEE = 'melee',
    HANDGUN = 'handgun',
    SMG = 'smg',
    SHOTGUN = 'shotgun',
    ASSAULT_RIFLE = 'assault_rifle',
    SNIPER_RIFLE = 'sniper_rifle',
    HEAVY = 'heavy',
    THROWABLE = 'throwable'
}

-- =============================================
-- VEHICLE CLASSES (Araç Sınıfları)
-- =============================================

Shared.VehicleClasses = {
    COMPACTS = 0,
    SEDANS = 1,
    SUVS = 2,
    COUPES = 3,
    MUSCLE = 4,
    SPORTS_CLASSICS = 5,
    SPORTS = 6,
    SUPER = 7,
    MOTORCYCLES = 8,
    OFF_ROAD = 9,
    INDUSTRIAL = 10,
    UTILITY = 11,
    VANS = 12,
    CYCLES = 13,
    BOATS = 14,
    HELICOPTERS = 15,
    PLANES = 16,
    SERVICE = 17,
    EMERGENCY = 18,
    MILITARY = 19,
    COMMERCIAL = 20,
    TRAINS = 21
}

-- =============================================
-- AI ANALYSIS TYPES (AI Analiz Türleri)
-- =============================================

Shared.AIAnalysisTypes = {
    SCREENSHOT = 'screenshot',
    BEHAVIOR = 'behavior',
    SCENE = 'scene',
    PATTERN = 'pattern',
    ANOMALY = 'anomaly'
}

-- =============================================
-- UTILITY FUNCTIONS (Yardımcı Fonksiyonlar)
-- =============================================

-- Tespit türünün önem seviyesini döndürür
function Shared.GetDetectionSeverity(detectionType)
    local severityMap = {
        [Shared.DetectionTypes.GODMODE] = Shared.SeverityLevels.HIGH,
        [Shared.DetectionTypes.SPEEDHACK] = Shared.SeverityLevels.HIGH,
        [Shared.DetectionTypes.TELEPORT] = Shared.SeverityLevels.CRITICAL,
        [Shared.DetectionTypes.AIMBOT] = Shared.SeverityLevels.HIGH,
        [Shared.DetectionTypes.ESP] = Shared.SeverityLevels.MEDIUM,
        [Shared.DetectionTypes.NOCLIP] = Shared.SeverityLevels.HIGH,
        [Shared.DetectionTypes.FREECAM] = Shared.SeverityLevels.MEDIUM,
        [Shared.DetectionTypes.LUA_EXECUTOR] = Shared.SeverityLevels.CRITICAL,
        [Shared.DetectionTypes.RESOURCE_INJECTION] = Shared.SeverityLevels.CRITICAL,
        [Shared.DetectionTypes.MENU_INJECTION] = Shared.SeverityLevels.CRITICAL,
        [Shared.DetectionTypes.DAMAGE_MODIFIER] = Shared.SeverityLevels.HIGH,
        [Shared.DetectionTypes.WEAPON_SPAWN] = Shared.SeverityLevels.HIGH,
        [Shared.DetectionTypes.MONEY_EXPLOIT] = Shared.SeverityLevels.HIGH,
        [Shared.DetectionTypes.ITEM_SPAWN] = Shared.SeverityLevels.MEDIUM,
        [Shared.DetectionTypes.VEHICLE_SPAWN] = Shared.SeverityLevels.MEDIUM,
        [Shared.DetectionTypes.EXPLOSION_SPAM] = Shared.SeverityLevels.HIGH,
        [Shared.DetectionTypes.PARTICLE_SPAM] = Shared.SeverityLevels.MEDIUM,
        [Shared.DetectionTypes.CHAT_SPAM] = Shared.SeverityLevels.LOW,
        [Shared.DetectionTypes.SQL_INJECTION] = Shared.SeverityLevels.CRITICAL,
        [Shared.DetectionTypes.XSS_ATTEMPT] = Shared.SeverityLevels.HIGH,
        [Shared.DetectionTypes.SUSPICIOUS_BEHAVIOR] = Shared.SeverityLevels.MEDIUM
    }
    
    return severityMap[detectionType] or Shared.SeverityLevels.LOW
end

-- Önem seviyesine göre varsayılan eylemi döndürür
function Shared.GetDefaultAction(severity)
    local actionMap = {
        [Shared.SeverityLevels.LOW] = Shared.ActionTypes.WARN,
        [Shared.SeverityLevels.MEDIUM] = Shared.ActionTypes.WARN,
        [Shared.SeverityLevels.HIGH] = Shared.ActionTypes.KICK,
        [Shared.SeverityLevels.CRITICAL] = Shared.ActionTypes.TEMP_BAN
    }
    
    return actionMap[severity] or Shared.ActionTypes.NONE
end

-- Renk kodlarını döndürür (hex formatında)
function Shared.GetSeverityColor(severity)
    local colorMap = {
        [Shared.SeverityLevels.LOW] = '#28a745',      -- Yeşil
        [Shared.SeverityLevels.MEDIUM] = '#ffc107',   -- Sarı
        [Shared.SeverityLevels.HIGH] = '#fd7e14',     -- Turuncu
        [Shared.SeverityLevels.CRITICAL] = '#dc3545' -- Kırmızı
    }
    
    return colorMap[severity] or '#6c757d' -- Gri (varsayılan)
end

-- Discord embed renk kodlarını döndürür (decimal formatında)
function Shared.GetDiscordColor(severity)
    local colorMap = {
        [Shared.SeverityLevels.LOW] = 2664261,      -- Yeşil
        [Shared.SeverityLevels.MEDIUM] = 16776960,  -- Sarı
        [Shared.SeverityLevels.HIGH] = 16612884,    -- Turuncu
        [Shared.SeverityLevels.CRITICAL] = 14431557 -- Kırmızı
    }
    
    return colorMap[severity] or 7506394 -- Gri (varsayılan)
end

-- Zaman formatını döndürür
function Shared.FormatTime(timestamp)
    return os.date('%Y-%m-%d %H:%M:%S', timestamp)
end

-- Süreyi insan okunabilir formata çevirir
function Shared.FormatDuration(seconds)
    if seconds < 60 then
        return seconds .. ' saniye'
    elseif seconds < 3600 then
        return math.floor(seconds / 60) .. ' dakika'
    elseif seconds < 86400 then
        return math.floor(seconds / 3600) .. ' saat'
    else
        return math.floor(seconds / 86400) .. ' gün'
    end
end

-- Güven skorunu yüzde formatına çevirir
function Shared.FormatConfidence(score)
    return string.format('%.1f%%', score)
end

-- Güven skorunu renk koduna çevirir
function Shared.GetConfidenceColor(score)
    if score >= 90 then
        return '#dc3545' -- Kırmızı (yüksek güven)
    elseif score >= 75 then
        return '#fd7e14' -- Turuncu
    elseif score >= 60 then
        return '#ffc107' -- Sarı
    else
        return '#28a745' -- Yeşil (düşük güven)
    end
end

-- String'i temizler (XSS koruması için)
function Shared.SanitizeString(str)
    if not str then return '' end
    
    -- HTML etiketlerini temizle
    str = string.gsub(str, '<[^>]*>', '')
    
    -- JavaScript kodlarını temizle
    str = string.gsub(str, 'javascript:', '')
    str = string.gsub(str, 'data:', '')
    
    -- SQL injection karakterlerini temizle
    str = string.gsub(str, "'", "''")
    str = string.gsub(str, '"', '""')
    
    return str
end

-- Tablo'yu JSON string'e çevirir
function Shared.TableToJson(tbl)
    return json.encode(tbl)
end

-- JSON string'i tablo'ya çevirir
function Shared.JsonToTable(jsonStr)
    local success, result = pcall(json.decode, jsonStr)
    if success then
        return result
    else
        return {}
    end
end

-- Rastgele ID oluşturur
function Shared.GenerateId(length)
    length = length or 16
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    local result = ''
    
    for i = 1, length do
        local rand = math.random(#chars)
        result = result .. string.sub(chars, rand, rand)
    end
    
    return result
end

-- Hash oluşturur (basit)
function Shared.SimpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = hash + string.byte(str, i)
    end
    return hash
end

-- Mesafe hesaplar
function Shared.GetDistance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- 2D mesafe hesaplar
function Shared.GetDistance2D(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx*dx + dy*dy)
end

-- Hızı mph'den km/h'ye çevirir
function Shared.MphToKmh(mph)
    return mph * 1.60934
end

-- Hızı km/h'den mph'ye çevirir
function Shared.KmhToMph(kmh)
    return kmh / 1.60934
end

-- Koordinatları string formatına çevirir
function Shared.CoordsToString(coords)
    return string.format('%.2f, %.2f, %.2f', coords.x, coords.y, coords.z)
end

-- String'i koordinatlara çevirir
function Shared.StringToCoords(str)
    local x, y, z = string.match(str, '([%d%.%-]+),%s*([%d%.%-]+),%s*([%d%.%-]+)')
    if x and y and z then
        return vector3(tonumber(x), tonumber(y), tonumber(z))
    end
    return vector3(0, 0, 0)
end
