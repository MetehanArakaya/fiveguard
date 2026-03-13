-- FIVEGUARD NETWORK SECURITY LAYER
-- Bağlantı güvenliği, VPN tespiti ve network koruması

FiveguardServer.NetworkSecurity = {}

-- =============================================
-- NETWORK SECURITY DEĞİŞKENLERİ
-- =============================================

local networkData = {
    isActive = false,
    connections = {},
    vpnDetections = {},
    rateLimits = {},
    suspiciousConnections = {},
    bannedIPs = {},
    config = {
        enableVpnDetection = true,
        enableRateLimiting = true,
        enableUsernameValidation = true,
        enableVacBanCheck = false, -- Steam Web API key gerekli
        maxConnectionsPerIP = 3,
        rateLimitWindow = 60000, -- 1 dakika
        rateLimitThreshold = 100, -- 100 request/dakika
        connectionTimeout = 30000, -- 30 saniye
        autoActionEnabled = true,
        whitelistedIPs = {},
        steamWebApiKey = '' -- Steam Web API key
    },
    stats = {
        totalConnections = 0,
        vpnBlocked = 0,
        rateLimitBlocked = 0,
        usernameBlocked = 0,
        vacBanBlocked = 0,
        suspiciousBlocked = 0,
        lastDetection = 0
    }
}

-- VPN/Proxy Detection API'leri
local vpnApis = {
    {
        name = 'ip-api',
        url = 'http://ip-api.com/json/%s?fields=proxy',
        parseResponse = function(response)
            local data = json.decode(response)
            return data and data.proxy == true
        end
    },
    {
        name = 'ipinfo',
        url = 'https://ipinfo.io/%s/json',
        parseResponse = function(response)
            local data = json.decode(response)
            return data and (data.org and (
                string.find(string.lower(data.org), 'vpn') or
                string.find(string.lower(data.org), 'proxy') or
                string.find(string.lower(data.org), 'hosting')
            ))
        end
    }
}

-- Geçersiz username karakterleri (Icarus'tan alınan)
local invalidUsernameChars = {
    '<', '>', '&', '"', "'", '/', '\\', '|', '?', '*', ':', ';',
    '[', ']', '{', '}', '(', ')', '!', '@', '#', '$', '%', '^',
    '`', '~', '+', '=', '\n', '\r', '\t'
}

-- Şüpheli username pattern'leri
local suspiciousUsernamePatterns = {
    'admin', 'moderator', 'owner', 'developer', 'staff',
    'cheat', 'hack', 'mod', 'trainer', 'inject',
    'bypass', 'exploit', 'crash', 'ddos', 'spam',
    'bot', 'script', 'auto', 'macro', 'aimbot'
}

-- Rate limit kategorileri
local rateLimitCategories = {
    CONNECTION = 'connection',
    EVENT = 'event',
    CHAT = 'chat',
    COMMAND = 'command'
}

-- =============================================
-- NETWORK SECURITY BAŞLATMA
-- =============================================

function FiveguardServer.NetworkSecurity.Initialize()
    print('^2[FIVEGUARD NETWORK SECURITY]^7 Network Security Layer başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardServer.NetworkSecurity.LoadConfig()
    
    -- Event'leri kaydet
    FiveguardServer.NetworkSecurity.RegisterEvents()
    
    -- Connection monitoring'i başlat
    FiveguardServer.NetworkSecurity.StartConnectionMonitoring()
    
    -- Rate limiting'i başlat
    FiveguardServer.NetworkSecurity.StartRateLimiting()
    
    -- Cleanup thread'ini başlat
    FiveguardServer.NetworkSecurity.StartCleanup()
    
    -- Banned IP'leri yükle
    FiveguardServer.NetworkSecurity.LoadBannedIPs()
    
    networkData.isActive = true
    print('^2[FIVEGUARD NETWORK SECURITY]^7 Network Security Layer hazır')
end

-- Konfigürasyonu yükle
function FiveguardServer.NetworkSecurity.LoadConfig()
    local config = FiveguardServer.Config.Modules.NetworkSecurity or {}
    
    -- Ana ayarları yükle
    networkData.config.enabled = config.enabled ~= nil and config.enabled or networkData.config.enabled
    
    -- Connection ayarlarını yükle
    if config.connection then
        networkData.config.enableVpnDetection = config.connection.enableVpnDetection ~= nil and config.connection.enableVpnDetection or networkData.config.enableVpnDetection
        networkData.config.enableRateLimiting = config.connection.enableRateLimiting ~= nil and config.connection.enableRateLimiting or networkData.config.enableRateLimiting
        networkData.config.enableUsernameValidation = config.connection.enableUsernameValidation ~= nil and config.connection.enableUsernameValidation or networkData.config.enableUsernameValidation
        networkData.config.enableVacBanCheck = config.connection.enableVacBanCheck ~= nil and config.connection.enableVacBanCheck or networkData.config.enableVacBanCheck
        networkData.config.maxConnectionsPerIP = config.connection.maxConnectionsPerIP or networkData.config.maxConnectionsPerIP
        networkData.config.connectionTimeout = config.connection.connectionTimeout or networkData.config.connectionTimeout
        if config.connection.whitelistedIPs then
            networkData.config.whitelistedIPs = config.connection.whitelistedIPs
        end
    end
    
    -- Rate limit ayarlarını yükle
    if config.rateLimit then
        networkData.config.rateLimitWindow = config.rateLimit.rateLimitWindow or networkData.config.rateLimitWindow
        networkData.config.rateLimitThreshold = config.rateLimit.rateLimitThreshold or networkData.config.rateLimitThreshold
    end
    
    -- Steam ayarlarını yükle
    if config.steam then
        networkData.config.steamWebApiKey = config.steam.steamWebApiKey or networkData.config.steamWebApiKey
        networkData.config.enableVacBanCheck = config.steam.enableVacBanCheck ~= nil and config.steam.enableVacBanCheck or networkData.config.enableVacBanCheck
    end
    
    -- Auto actions ayarlarını yükle
    if config.autoActions then
        networkData.config.autoActionEnabled = config.autoActions.autoActionEnabled ~= nil and config.autoActions.autoActionEnabled or networkData.config.autoActionEnabled
        networkData.config.banDuration = config.autoActions.banDuration or networkData.config.banDuration
    end
    
    print('^2[FIVEGUARD NETWORK SECURITY]^7 Config yüklendi - Enabled: ' .. tostring(networkData.config.enabled))
end

-- Event'leri kaydet
function FiveguardServer.NetworkSecurity.RegisterEvents()
    -- Player connecting event
    AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
        local playerId = source
        local playerIP = GetPlayerEndpoint(playerId)
        local identifiers = GetPlayerIdentifiers(playerId)
        
        deferrals.defer()
        
        -- Connection validation
        FiveguardServer.NetworkSecurity.ValidateConnection(playerId, playerIP, name, identifiers, deferrals)
    end)
    
    -- Chat message rate limiting
    RegisterNetEvent('chatMessage')
    AddEventHandler('chatMessage', function(author, color, message)
        local playerId = source
        if not FiveguardServer.NetworkSecurity.CheckRateLimit(playerId, rateLimitCategories.CHAT) then
            CancelEvent()
        end
    end)
    
    -- Generic event rate limiting
    AddEventHandler('__cfx_internal:commandFallback', function(command)
        local playerId = source
        if not FiveguardServer.NetworkSecurity.CheckRateLimit(playerId, rateLimitCategories.COMMAND) then
            CancelEvent()
        end
    end)
end

-- =============================================
-- CONNECTION VALIDATION
-- =============================================

-- Connection'ı validate et
function FiveguardServer.NetworkSecurity.ValidateConnection(playerId, playerIP, playerName, identifiers, deferrals)
    deferrals.update('FIVEGUARD: Bağlantı kontrol ediliyor...')
    
    -- IP extraction
    local ip = FiveguardServer.NetworkSecurity.ExtractIP(playerIP)
    if not ip then
        deferrals.done('FIVEGUARD: Geçersiz IP adresi')
        return
    end
    
    -- Banned IP kontrolü
    if FiveguardServer.NetworkSecurity.IsIPBanned(ip) then
        deferrals.done('FIVEGUARD: IP adresi banlanmış')
        FiveguardServer.NetworkSecurity.LogSecurityEvent(playerId, 'banned_ip', {ip = ip})
        return
    end
    
    -- Whitelist kontrolü
    if networkData.config.whitelistedIPs[ip] then
        deferrals.done() -- Whitelist'te ise geç
        return
    end
    
    -- Connection limit kontrolü
    if not FiveguardServer.NetworkSecurity.CheckConnectionLimit(ip) then
        deferrals.done('FIVEGUARD: Bu IP adresinden çok fazla bağlantı')
        FiveguardServer.NetworkSecurity.LogSecurityEvent(playerId, 'connection_limit', {ip = ip})
        return
    end
    
    -- Username validation
    if networkData.config.enableUsernameValidation then
        if not FiveguardServer.NetworkSecurity.ValidateUsername(playerName) then
            deferrals.done('FIVEGUARD: Geçersiz kullanıcı adı')
            FiveguardServer.NetworkSecurity.LogSecurityEvent(playerId, 'invalid_username', {name = playerName})
            return
        end
    end
    
    -- VPN detection (async)
    if networkData.config.enableVpnDetection then
        FiveguardServer.NetworkSecurity.CheckVPN(ip, function(isVpn)
            if isVpn then
                deferrals.done('FIVEGUARD: VPN/Proxy kullanımı tespit edildi')
                FiveguardServer.NetworkSecurity.LogSecurityEvent(playerId, 'vpn_detected', {ip = ip})
                return
            end
            
            -- VAC ban check (eğer Steam Web API key varsa)
            if networkData.config.enableVacBanCheck and networkData.config.steamWebApiKey ~= '' then
                FiveguardServer.NetworkSecurity.CheckVACBan(identifiers, function(isBanned)
                    if isBanned then
                        deferrals.done('FIVEGUARD: Steam VAC ban tespit edildi')
                        FiveguardServer.NetworkSecurity.LogSecurityEvent(playerId, 'vac_ban', {identifiers = identifiers})
                        return
                    end
                    
                    -- Tüm kontroller geçildi
                    FiveguardServer.NetworkSecurity.RegisterConnection(playerId, ip, playerName, identifiers)
                    deferrals.done()
                end)
            else
                -- VAC check yok, direkt geç
                FiveguardServer.NetworkSecurity.RegisterConnection(playerId, ip, playerName, identifiers)
                deferrals.done()
            end
        end)
    else
        -- VPN check yok, VAC check'e geç veya direkt geç
        if networkData.config.enableVacBanCheck and networkData.config.steamWebApiKey ~= '' then
            FiveguardServer.NetworkSecurity.CheckVACBan(identifiers, function(isBanned)
                if isBanned then
                    deferrals.done('FIVEGUARD: Steam VAC ban tespit edildi')
                    FiveguardServer.NetworkSecurity.LogSecurityEvent(playerId, 'vac_ban', {identifiers = identifiers})
                    return
                end
                
                FiveguardServer.NetworkSecurity.RegisterConnection(playerId, ip, playerName, identifiers)
                deferrals.done()
            end)
        else
            FiveguardServer.NetworkSecurity.RegisterConnection(playerId, ip, playerName, identifiers)
            deferrals.done()
        end
    end
end

-- IP'yi extract et
function FiveguardServer.NetworkSecurity.ExtractIP(endpoint)
    if not endpoint then return nil end
    
    -- Format: "ip:port" veya "[ipv6]:port"
    local ip = string.match(endpoint, '^([^:]+)')
    if not ip then
        ip = string.match(endpoint, '^%[([^%]]+)%]')
    end
    
    return ip
end

-- Connection limit kontrolü
function FiveguardServer.NetworkSecurity.CheckConnectionLimit(ip)
    local currentConnections = 0
    
    for playerId, connection in pairs(networkData.connections) do
        if connection.ip == ip then
            currentConnections = currentConnections + 1
        end
    end
    
    return currentConnections < networkData.config.maxConnectionsPerIP
end

-- Username validation
function FiveguardServer.NetworkSecurity.ValidateUsername(username)
    if not username or username == '' then
        return false
    end
    
    -- Geçersiz karakter kontrolü
    for _, char in ipairs(invalidUsernameChars) do
        if string.find(username, char, 1, true) then
            return false
        end
    end
    
    -- Şüpheli pattern kontrolü
    local lowerUsername = string.lower(username)
    for _, pattern in ipairs(suspiciousUsernamePatterns) do
        if string.find(lowerUsername, pattern) then
            return false
        end
    end
    
    -- Uzunluk kontrolü
    if string.len(username) < 3 or string.len(username) > 20 then
        return false
    end
    
    return true
end

-- Connection'ı kaydet
function FiveguardServer.NetworkSecurity.RegisterConnection(playerId, ip, playerName, identifiers)
    networkData.connections[playerId] = {
        ip = ip,
        name = playerName,
        identifiers = identifiers,
        connectTime = os.time(),
        lastActivity = os.time(),
        requestCount = 0
    }
    
    networkData.stats.totalConnections = networkData.stats.totalConnections + 1
    
    print('^2[FIVEGUARD NETWORK SECURITY]^7 Bağlantı kaydedildi: ' .. playerName .. ' (' .. ip .. ')')
end

-- =============================================
-- VPN DETECTION
-- =============================================

-- VPN kontrolü
function FiveguardServer.NetworkSecurity.CheckVPN(ip, callback)
    local checkedApis = 0
    local totalApis = #vpnApis
    local isVpnDetected = false
    
    for _, api in ipairs(vpnApis) do
        local url = string.format(api.url, ip)
        
        PerformHttpRequest(url, function(statusCode, response, headers)
            checkedApis = checkedApis + 1
            
            if statusCode == 200 and response then
                local isVpn = api.parseResponse(response)
                if isVpn then
                    isVpnDetected = true
                end
            end
            
            -- Tüm API'ler kontrol edildi
            if checkedApis >= totalApis then
                if isVpnDetected then
                    networkData.stats.vpnBlocked = networkData.stats.vpnBlocked + 1
                    networkData.stats.lastDetection = os.time()
                end
                callback(isVpnDetected)
            end
        end, 'GET', '', {['User-Agent'] = 'FiveGuard-AntiCheat'})
    end
    
    -- Timeout protection
    SetTimeout(5000, function()
        if checkedApis < totalApis then
            callback(false) -- Timeout durumunda VPN yok kabul et
        end
    end)
end

-- =============================================
-- VAC BAN CHECK
-- =============================================

-- VAC ban kontrolü
function FiveguardServer.NetworkSecurity.CheckVACBan(identifiers, callback)
    if not networkData.config.steamWebApiKey or networkData.config.steamWebApiKey == '' then
        callback(false)
        return
    end
    
    -- Steam identifier'ı bul
    local steamId = nil
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, 'steam:') then
            steamId = string.gsub(identifier, 'steam:', '')
            break
        end
    end
    
    if not steamId then
        callback(false) -- Steam ID yok
        return
    end
    
    -- Steam64 ID'ye çevir
    local steam64 = tonumber(steamId, 16)
    if not steam64 then
        callback(false)
        return
    end
    
    steam64 = steam64 + 76561197960265728
    
    -- Steam Web API'ye istek gönder
    local url = string.format('https://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key=%s&steamids=%s', 
                             networkData.config.steamWebApiKey, steam64)
    
    PerformHttpRequest(url, function(statusCode, response, headers)
        if statusCode == 200 and response then
            local data = json.decode(response)
            if data and data.players and #data.players > 0 then
                local player = data.players[1]
                local isBanned = player.VACBanned or player.NumberOfVACBans > 0
                
                if isBanned then
                    networkData.stats.vacBanBlocked = networkData.stats.vacBanBlocked + 1
                    networkData.stats.lastDetection = os.time()
                end
                
                callback(isBanned)
            else
                callback(false)
            end
        else
            callback(false) -- API hatası durumunda geç
        end
    end, 'GET', '', {['User-Agent'] = 'FiveGuard-AntiCheat'})
    
    -- Timeout protection
    SetTimeout(5000, function()
        callback(false)
    end)
end

-- =============================================
-- RATE LIMITING
-- =============================================

-- Rate limiting'i başlat
function FiveguardServer.NetworkSecurity.StartRateLimiting()
    if not networkData.config.enableRateLimiting then
        return
    end
    
    CreateThread(function()
        while networkData.isActive do
            Wait(networkData.config.rateLimitWindow)
            
            -- Rate limit verilerini temizle
            FiveguardServer.NetworkSecurity.CleanupRateLimits()
        end
    end)
end

-- Rate limit kontrolü
function FiveguardServer.NetworkSecurity.CheckRateLimit(playerId, category)
    if not networkData.config.enableRateLimiting then
        return true
    end
    
    local currentTime = GetGameTimer()
    
    -- Player'ın rate limit verilerini al
    if not networkData.rateLimits[playerId] then
        networkData.rateLimits[playerId] = {}
    end
    
    if not networkData.rateLimits[playerId][category] then
        networkData.rateLimits[playerId][category] = {}
    end
    
    local rateLimitData = networkData.rateLimits[playerId][category]
    
    -- Son istekleri say
    local recentRequests = 0
    for _, timestamp in ipairs(rateLimitData) do
        if (currentTime - timestamp) <= networkData.config.rateLimitWindow then
            recentRequests = recentRequests + 1
        end
    end
    
    -- Threshold kontrolü
    if recentRequests >= networkData.config.rateLimitThreshold then
        -- Rate limit aşıldı
        FiveguardServer.NetworkSecurity.HandleRateLimit(playerId, category, recentRequests)
        return false
    end
    
    -- İsteği kaydet
    table.insert(rateLimitData, currentTime)
    
    -- Connection activity güncelle
    if networkData.connections[playerId] then
        networkData.connections[playerId].lastActivity = os.time()
        networkData.connections[playerId].requestCount = networkData.connections[playerId].requestCount + 1
    end
    
    return true
end

-- Rate limit'i işle
function FiveguardServer.NetworkSecurity.HandleRateLimit(playerId, category, requestCount)
    local connection = networkData.connections[playerId]
    if not connection then return end
    
    local detection = {
        playerId = playerId,
        playerName = connection.name,
        playerIP = connection.ip,
        type = 'rate_limit',
        category = category,
        requestCount = requestCount,
        threshold = networkData.config.rateLimitThreshold,
        timestamp = os.time(),
        severity = 'medium'
    }
    
    -- İstatistikleri güncelle
    networkData.stats.rateLimitBlocked = networkData.stats.rateLimitBlocked + 1
    networkData.stats.lastDetection = os.time()
    
    -- Detection'ı işle
    FiveguardServer.NetworkSecurity.ProcessDetection(detection)
    
    print('^3[FIVEGUARD NETWORK SECURITY]^7 Rate limit aşıldı: ' .. connection.name .. 
          ' (' .. category .. ' - ' .. requestCount .. ' istek)')
end

-- Rate limit verilerini temizle
function FiveguardServer.NetworkSecurity.CleanupRateLimits()
    local currentTime = GetGameTimer()
    local cleanupThreshold = networkData.config.rateLimitWindow * 2
    
    for playerId, playerRateLimits in pairs(networkData.rateLimits) do
        for category, rateLimitData in pairs(playerRateLimits) do
            local filteredData = {}
            for _, timestamp in ipairs(rateLimitData) do
                if (currentTime - timestamp) <= cleanupThreshold then
                    table.insert(filteredData, timestamp)
                end
            end
            networkData.rateLimits[playerId][category] = filteredData
        end
    end
end

-- =============================================
-- CONNECTION MONITORING
-- =============================================

-- Connection monitoring'i başlat
function FiveguardServer.NetworkSecurity.StartConnectionMonitoring()
    CreateThread(function()
        while networkData.isActive do
            Wait(30000) -- 30 saniye bekle
            
            -- Connection'ları monitör et
            FiveguardServer.NetworkSecurity.MonitorConnections()
        end
    end)
end

-- Connection'ları monitör et
function FiveguardServer.NetworkSecurity.MonitorConnections()
    local currentTime = os.time()
    
    for playerId, connection in pairs(networkData.connections) do
        -- Timeout kontrolü
        if (currentTime - connection.lastActivity) > (networkData.config.connectionTimeout / 1000) then
            -- Connection timeout
            FiveguardServer.NetworkSecurity.HandleConnectionTimeout(playerId, connection)
        end
        
        -- Suspicious activity kontrolü
        if FiveguardServer.NetworkSecurity.IsSuspiciousConnection(connection) then
            FiveguardServer.NetworkSecurity.HandleSuspiciousConnection(playerId, connection)
        end
    end
end

-- Connection timeout'ı işle
function FiveguardServer.NetworkSecurity.HandleConnectionTimeout(playerId, connection)
    print('^3[FIVEGUARD NETWORK SECURITY]^7 Connection timeout: ' .. connection.name)
    
    -- Connection'ı kaldır
    networkData.connections[playerId] = nil
end

-- Suspicious connection kontrolü
function FiveguardServer.NetworkSecurity.IsSuspiciousConnection(connection)
    local currentTime = os.time()
    local connectionDuration = currentTime - connection.connectTime
    
    -- Çok fazla istek
    if connectionDuration > 0 then
        local requestRate = connection.requestCount / connectionDuration
        if requestRate > 10 then -- Saniyede 10+ istek
            return true
        end
    end
    
    return false
end

-- Suspicious connection'ı işle
function FiveguardServer.NetworkSecurity.HandleSuspiciousConnection(playerId, connection)
    local detection = {
        playerId = playerId,
        playerName = connection.name,
        playerIP = connection.ip,
        type = 'suspicious_connection',
        requestCount = connection.requestCount,
        connectionDuration = os.time() - connection.connectTime,
        timestamp = os.time(),
        severity = 'high'
    }
    
    -- İstatistikleri güncelle
    networkData.stats.suspiciousBlocked = networkData.stats.suspiciousBlocked + 1
    networkData.stats.lastDetection = os.time()
    
    -- Detection'ı işle
    FiveguardServer.NetworkSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD NETWORK SECURITY]^7 Suspicious connection: ' .. connection.name)
end

-- =============================================
-- DETECTION PROCESSING
-- =============================================

-- Detection'ı işle
function FiveguardServer.NetworkSecurity.ProcessDetection(detection)
    -- Suspicious connection'lara ekle
    if not networkData.suspiciousConnections[detection.playerId] then
        networkData.suspiciousConnections[detection.playerId] = {}
    end
    
    table.insert(networkData.suspiciousConnections[detection.playerId], detection)
    
    -- Severity'ye göre işlem yap
    FiveguardServer.NetworkSecurity.HandleDetectionSeverity(detection)
    
    -- Veritabanına kaydet
    FiveguardServer.NetworkSecurity.SaveDetectionToDatabase(detection)
    
    -- Webhook gönder
    FiveguardServer.NetworkSecurity.SendDetectionWebhook(detection)
    
    -- Protection Manager'a bildir
    if FiveguardServer.ProtectionManager then
        FiveguardServer.ProtectionManager.RecordDetection('network_security', {
            type = detection.type,
            severity = detection.severity,
            playerId = detection.playerId,
            timestamp = detection.timestamp
        })
    end
end

-- Detection severity'sini işle
function FiveguardServer.NetworkSecurity.HandleDetectionSeverity(detection)
    if not networkData.config.autoActionEnabled then
        return
    end
    
    local playerId = detection.playerId
    
    if detection.severity == 'critical' then
        -- Kritik seviye - IP ban
        FiveguardServer.NetworkSecurity.BanIP(detection.playerIP, 'Network security violation: ' .. detection.type)
        FiveguardServer.NetworkSecurity.KickPlayer(playerId, 'Network security violation')
        
    elseif detection.severity == 'high' then
        -- Yüksek seviye - Kick
        FiveguardServer.NetworkSecurity.KickPlayer(playerId, 'Suspicious network activity')
        
    elseif detection.severity == 'medium' then
        -- Orta seviye - Uyarı
        FiveguardServer.NetworkSecurity.WarnPlayer(playerId, 'Network activity warning')
    end
end

-- IP'yi banla
function FiveguardServer.NetworkSecurity.BanIP(ip, reason)
    networkData.bannedIPs[ip] = {
        reason = reason,
        timestamp = os.time(),
        active = true
    }
    
    -- Veritabanına kaydet
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_banned_ips (ip_address, reason, timestamp, active) VALUES (?, ?, ?, 1)', {
        ip,
        reason,
        os.time()
    })
    
    print('^1[FIVEGUARD NETWORK SECURITY]^7 IP banlandı: ' .. ip .. ' (Sebep: ' .. reason .. ')')
end

-- Oyuncuyu uyar
function FiveguardServer.NetworkSecurity.WarnPlayer(playerId, reason)
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {255, 165, 0},
        multiline = true,
        args = {'FIVEGUARD UYARI', reason}
    })
end

-- Oyuncuyu at
function FiveguardServer.NetworkSecurity.KickPlayer(playerId, reason)
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
end

-- =============================================
-- CLEANUP VE MONITORING
-- =============================================

-- Cleanup thread'ini başlat
function FiveguardServer.NetworkSecurity.StartCleanup()
    CreateThread(function()
        while networkData.isActive do
            Wait(300000) -- 5 dakika bekle
            
            -- Eski detection'ları temizle
            FiveguardServer.NetworkSecurity.CleanupDetections()
            
            -- Offline player'ları temizle
            FiveguardServer.NetworkSecurity.CleanupOfflinePlayers()
        end
    end)
end

-- Eski detection'ları temizle
function FiveguardServer.NetworkSecurity.CleanupDetections()
    local currentTime = os.time()
    local cleanupThreshold = currentTime - 3600 -- 1 saat önce
    
    for playerId, detections in pairs(networkData.suspiciousConnections) do
        local filteredDetections = {}
        for _, detection in ipairs(detections) do
            if detection.timestamp > cleanupThreshold then
                table.insert(filteredDetections, detection)
            end
        end
        networkData.suspiciousConnections[playerId] = filteredDetections
    end
end

-- Offline player'ları temizle
function FiveguardServer.NetworkSecurity.CleanupOfflinePlayers()
    for playerId, _ in pairs(networkData.connections) do
        if not GetPlayerName(playerId) then
            -- Player offline
            networkData.connections[playerId] = nil
            networkData.rateLimits[playerId] = nil
            networkData.suspiciousConnections[playerId] = nil
        end
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Banned IP'leri yükle
function FiveguardServer.NetworkSecurity.LoadBannedIPs()
    FiveguardServer.Database.Execute('SELECT * FROM fiveguard_banned_ips WHERE active = 1', {}, function(results)
        if results then
            for _, ban in ipairs(results) do
                networkData.bannedIPs[ban.ip_address] = {
                    reason = ban.reason,
                    timestamp = ban.timestamp,
                    active = true
                }
            end
            
            print('^2[FIVEGUARD NETWORK SECURITY]^7 Banned IP\'ler yüklendi: ' .. #results)
        end
    end)
end

-- IP ban kontrolü
function FiveguardServer.NetworkSecurity.IsIPBanned(ip)
    return networkData.bannedIPs[ip] and networkData.bannedIPs[ip].active
end

-- Security event'ini logla
function FiveguardServer.NetworkSecurity.LogSecurityEvent(playerId, eventType, details)
    local logEntry = {
        playerId = playerId,
        eventType = eventType,
        details = details,
        timestamp = os.time()
    }
    
    -- Veritabanına kaydet
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_network_logs (player_id, event_type, event_data, timestamp) VALUES (?, ?, ?, ?)', {
        playerId,
        eventType,
        json.encode(details),
        os.time()
    })
    
    print('^3[FIVEGUARD NETWORK SECURITY]^7 Security event: ' .. eventType .. ' (Player: ' .. playerId .. ')')
end

-- Detection'ı veritabanına kaydet
function FiveguardServer.NetworkSecurity.SaveDetectionToDatabase(detection)
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_network_detections (player_id, player_name, player_ip, detection_type, detection_data, severity, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        detection.playerId,
        detection.playerName,
        detection.playerIP,
        detection.type,
        json.encode(detection),
        detection.severity,
        detection.timestamp
    })
end

-- Detection webhook'u gönder
function FiveguardServer.NetworkSecurity.SendDetectionWebhook(detection)
    local color = 16711680 -- Kırmızı
    if detection.severity == 'high' then
        color = 16776960 -- Sarı
    elseif detection.severity == 'medium' then
        color = 16753920 -- Turuncu
    end
    
    local webhookData = {
        username = 'Fiveguard Network Security',
        avatar_url = 'https://i.imgur.com/fiveguard-logo.png',
        embeds = {{
            title = '🌐 Network Security Tespit Edildi!',
            color = color,
            fields = {
                {name = 'Oyuncu', value = detection.playerName, inline = true},
                {name = 'IP Adresi', value = detection.playerIP, inline = true},
                {name = 'Tespit Türü', value = detection.type, inline = true},
                {name = 'Severity', value = detection.severity, inline = true},
                {name = 'Detaylar', value = FiveguardServer.NetworkSecurity.FormatDetectionDetails(detection), inline = false},
                {name = 'Zaman', value = os.date('%Y-%m-%d %H:%M:%S', detection.timestamp), inline = true}
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', detection.timestamp)
        }}
    }
    
    FiveguardServer.Webhook.Send('network_security', webhookData)
end

-- Detection detaylarını formatla
function FiveguardServer.NetworkSecurity.FormatDetectionDetails(detection)
    if detection.type == 'rate_limit' then
        return 'Category: ' .. detection.category .. ' (' .. detection.requestCount .. ' requests)'
    elseif detection.type == 'suspicious_connection' then
        return 'Request Count: ' .. detection.requestCount .. ' (Duration: ' .. detection.connectionDuration .. 's)'
    elseif detection.type == 'vpn_detected' then
        return 'VPN/Proxy detected from IP: ' .. detection.playerIP
    elseif detection.type == 'vac_ban' then
        return 'Steam VAC ban detected'
    elseif detection.type == 'invalid_username' then
        return 'Invalid username pattern'
    else
        return 'Network security violation'
    end
end

-- İstatistikleri getir
function FiveguardServer.NetworkSecurity.GetStats()
    return {
        totalConnections = networkData.stats.totalConnections,
        vpnBlocked = networkData.stats.vpnBlocked,
        rateLimitBlocked = networkData.stats.rateLimitBlocked,
        usernameBlocked = networkData.stats.usernameBlocked,
        vacBanBlocked = networkData.stats.vacBanBlocked,
        suspiciousBlocked = networkData.stats.suspiciousBlocked,
        lastDetection = networkData.stats.lastDetection,
        isActive = networkData.isActive,
        activeConnections = FiveguardServer.NetworkSecurity.GetActiveConnectionCount(),
        bannedIPCount = FiveguardServer.NetworkSecurity.GetBannedIPCount()
    }
end

-- Aktif connection sayısını getir
function FiveguardServer.NetworkSecurity.GetActiveConnectionCount()
    local count = 0
    for _ in pairs(networkData.connections) do
        count = count + 1
    end
    return count
end

-- Banned IP sayısını getir
function FiveguardServer.NetworkSecurity.GetBannedIPCount()
    local count = 0
    for _, ban in pairs(networkData.bannedIPs) do
        if ban.active then
            count = count + 1
        end
    end
    return count
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Network security istatistiklerini getir
function GetNetworkSecurityStats()
    return FiveguardServer.NetworkSecurity.GetStats()
end

-- Network security durumunu kontrol et
function IsNetworkSecurityActive()
    return networkData.isActive
end

-- IP ban ekle
function BanIPAddress(ip, reason)
    FiveguardServer.NetworkSecurity.BanIP(ip, reason)
    return true
end

-- IP ban kaldır
function UnbanIPAddress(ip)
    if networkData.bannedIPs[ip] then
        networkData.bannedIPs[ip].active = false
        
        -- Veritabanını güncelle
        FiveguardServer.Database.Execute('UPDATE fiveguard_banned_ips SET active = 0 WHERE ip_address = ?', {ip})
        
        print('^2[FIVEGUARD NETWORK SECURITY]^7 IP ban kaldırıldı: ' .. ip)
        return true
    end
    
    return false
end

-- Connection bilgilerini getir
function GetConnectionInfo(playerId)
    return networkData.connections[playerId]
end

-- Rate limit durumunu kontrol et
function CheckPlayerRateLimit(playerId, category)
    return FiveguardServer.NetworkSecurity.CheckRateLimit(playerId, category)
end

print('^2[FIVEGUARD NETWORK SECURITY]^7 Network Security Layer modülü yüklendi')
