-- FIVEGUARD ADMIN ABUSE DETECTION MODULE
-- Admin yetkilerinin kötüye kullanımını tespit eden sistem

FiveguardServer.AdminAbuse = {}

-- =============================================
-- ADMIN ABUSE DEĞİŞKENLERİ
-- =============================================

local abuseData = {
    isActive = false,
    adminActions = {},
    suspiciousActivities = {},
    whitelistedAdmins = {},
    stats = {
        totalActionsLogged = 0,
        suspiciousActionsDetected = 0,
        adminsBanned = 0,
        lastDetection = 0
    },
    config = {
        logAllActions = true,
        enableRealTimeMonitoring = true,
        suspiciousActionThreshold = 5,
        timeWindow = 300000, -- 5 dakika
        autoActionEnabled = true,
        notifyOtherAdmins = true
    }
}

-- Admin action türleri
local actionTypes = {
    BAN = 'ban',
    UNBAN = 'unban',
    KICK = 'kick',
    WARN = 'warn',
    TELEPORT = 'teleport',
    GIVE_MONEY = 'give_money',
    GIVE_ITEM = 'give_item',
    GIVE_WEAPON = 'give_weapon',
    SET_JOB = 'set_job',
    REVIVE = 'revive',
    HEAL = 'heal',
    GOD_MODE = 'god_mode',
    INVISIBLE = 'invisible',
    NOCLIP = 'noclip',
    SPAWN_VEHICLE = 'spawn_vehicle',
    DELETE_ENTITY = 'delete_entity',
    FREEZE_PLAYER = 'freeze_player',
    SPECTATE = 'spectate',
    BRING_PLAYER = 'bring_player',
    GOTO_PLAYER = 'goto_player'
}

-- Şüpheli davranış kalıpları
local suspiciousPatterns = {
    -- Çok fazla ban
    EXCESSIVE_BANS = {
        type = 'excessive_bans',
        threshold = 10,
        timeWindow = 3600000, -- 1 saat
        severity = 'high',
        description = 'Çok fazla oyuncu banladı'
    },
    
    -- Kendi kendine avantaj sağlama
    SELF_BENEFIT = {
        type = 'self_benefit',
        actions = {'give_money', 'give_item', 'give_weapon', 'set_job'},
        severity = 'critical',
        description = 'Kendine avantaj sağladı'
    },
    
    -- Gece yarısı aktivitesi
    MIDNIGHT_ACTIVITY = {
        type = 'midnight_activity',
        timeRange = {2, 6}, -- 02:00 - 06:00
        actionThreshold = 5,
        severity = 'medium',
        description = 'Gece yarısı şüpheli aktivite'
    },
    
    -- Hızlı ardışık işlemler
    RAPID_ACTIONS = {
        type = 'rapid_actions',
        threshold = 20,
        timeWindow = 60000, -- 1 dakika
        severity = 'high',
        description = 'Çok hızlı ardışık işlemler'
    },
    
    -- Belirli oyuncuları hedef alma
    TARGETING_SPECIFIC_PLAYERS = {
        type = 'targeting_players',
        threshold = 5, -- Aynı oyuncuya 5+ işlem
        timeWindow = 1800000, -- 30 dakika
        severity = 'medium',
        description = 'Belirli oyuncuları hedef aldı'
    },
    
    -- Anormal teleport kullanımı
    EXCESSIVE_TELEPORTS = {
        type = 'excessive_teleports',
        threshold = 50,
        timeWindow = 3600000, -- 1 saat
        severity = 'low',
        description = 'Aşırı teleport kullanımı'
    }
}

-- Risk seviyeleri
local riskLevels = {
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3,
    CRITICAL = 4
}

-- =============================================
-- ADMIN ABUSE BAŞLATMA
-- =============================================

function FiveguardServer.AdminAbuse.Initialize()
    print('^2[FIVEGUARD ADMIN ABUSE]^7 Admin Abuse Detection başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardServer.AdminAbuse.LoadConfig()
    
    -- Event'leri kaydet
    FiveguardServer.AdminAbuse.RegisterEvents()
    
    -- Monitoring thread'ini başlat
    FiveguardServer.AdminAbuse.StartMonitoring()
    
    -- Cleanup thread'ini başlat
    FiveguardServer.AdminAbuse.StartCleanup()
    
    -- Whitelisted admin'leri yükle
    FiveguardServer.AdminAbuse.LoadWhitelistedAdmins()
    
    abuseData.isActive = true
    print('^2[FIVEGUARD ADMIN ABUSE]^7 Admin Abuse Detection hazır')
end

-- Konfigürasyonu yükle
function FiveguardServer.AdminAbuse.LoadConfig()
    local config = FiveguardServer.Config.Modules.AdminAbuse or {}
    
    -- Ana ayarları yükle
    adminData.config.enabled = config.enabled ~= nil and config.enabled or adminData.config.enabled
    adminData.config.logAllActions = config.logAllActions ~= nil and config.logAllActions or adminData.config.logAllActions
    adminData.config.maxActionsPerMinute = config.maxActionsPerMinute or adminData.config.maxActionsPerMinute
    adminData.config.suspiciousActionThreshold = config.suspiciousActionThreshold or adminData.config.suspiciousActionThreshold
    adminData.config.autoActionEnabled = config.autoActionEnabled ~= nil and config.autoActionEnabled or adminData.config.autoActionEnabled
    adminData.config.banDuration = config.banDuration or adminData.config.banDuration
    adminData.config.kickReason = config.kickReason or adminData.config.kickReason
    
    -- Monitored actions'ları yükle
    if config.monitoredActions then
        adminData.config.monitoredActions = config.monitoredActions
    end
    
    -- Whitelisted admins'i yükle
    if config.whitelistedAdmins then
        adminData.config.whitelistedAdmins = config.whitelistedAdmins
    end
    
    print('^2[FIVEGUARD ADMIN ABUSE]^7 Config yüklendi - Enabled: ' .. tostring(adminData.config.enabled))
end

-- Event'leri kaydet
function FiveguardServer.AdminAbuse.RegisterEvents()
    -- Admin action logging
    RegisterNetEvent('fiveguard:admin:logAction')
    AddEventHandler('fiveguard:admin:logAction', function(actionData)
        local adminId = source
        FiveguardServer.AdminAbuse.LogAdminAction(adminId, actionData)
    end)
    
    -- Manual admin check
    RegisterNetEvent('fiveguard:admin:checkAdmin')
    AddEventHandler('fiveguard:admin:checkAdmin', function(targetAdminId)
        local requesterId = source
        FiveguardServer.AdminAbuse.CheckSpecificAdmin(requesterId, targetAdminId)
    end)
    
    -- Whitelist güncelleme
    RegisterNetEvent('fiveguard:admin:updateWhitelist')
    AddEventHandler('fiveguard:admin:updateWhitelist', function(adminList)
        local requesterId = source
        FiveguardServer.AdminAbuse.UpdateWhitelist(requesterId, adminList)
    end)
end

-- =============================================
-- ADMIN ACTION LOGGING
-- =============================================

-- Admin eylemini logla
function FiveguardServer.AdminAbuse.LogAdminAction(adminId, actionData)
    if not abuseData.isActive then return end
    
    local admin = FiveguardServer.Players[adminId]
    if not admin then return end
    
    -- Action verilerini hazırla
    local action = {
        id = FiveguardServer.AdminAbuse.GenerateActionId(),
        adminId = adminId,
        adminName = GetPlayerName(adminId),
        adminIdentifiers = FiveguardServer.GetPlayerIdentifiers(adminId),
        actionType = actionData.type,
        targetPlayerId = actionData.targetPlayerId,
        targetPlayerName = actionData.targetPlayerName,
        parameters = actionData.parameters or {},
        timestamp = os.time(),
        serverTime = os.date('%Y-%m-%d %H:%M:%S'),
        reason = actionData.reason or 'Sebep belirtilmedi',
        source = actionData.source or 'unknown', -- Hangi resource'tan geldi
        metadata = {
            adminPosition = GetEntityCoords(GetPlayerPed(adminId)),
            targetPosition = actionData.targetPosition,
            serverPopulation = #GetPlayers(),
            additional = actionData.metadata or {}
        }
    }
    
    -- Action'ı kaydet
    if not abuseData.adminActions[adminId] then
        abuseData.adminActions[adminId] = {}
    end
    
    table.insert(abuseData.adminActions[adminId], action)
    
    -- İstatistikleri güncelle
    abuseData.stats.totalActionsLogged = abuseData.stats.totalActionsLogged + 1
    
    -- Şüpheli davranış analizi
    FiveguardServer.AdminAbuse.AnalyzeSuspiciousBehavior(adminId, action)
    
    -- Veritabanına kaydet
    FiveguardServer.AdminAbuse.SaveActionToDatabase(action)
    
    if FiveguardServer.Config.debug then
        print('^3[FIVEGUARD ADMIN ABUSE]^7 Admin action logged: ' .. admin.name .. 
              ' -> ' .. action.actionType .. 
              ' (Target: ' .. (action.targetPlayerName or 'N/A') .. ')')
    end
end

-- Şüpheli davranış analizi
function FiveguardServer.AdminAbuse.AnalyzeSuspiciousBehavior(adminId, action)
    -- Whitelisted admin kontrolü
    if abuseData.whitelistedAdmins[adminId] then
        return
    end
    
    local currentTime = os.time()
    local adminActions = abuseData.adminActions[adminId] or {}
    
    -- Her pattern için kontrol yap
    for patternName, pattern in pairs(suspiciousPatterns) do
        local violation = FiveguardServer.AdminAbuse.CheckPattern(adminId, adminActions, pattern, currentTime)
        
        if violation then
            FiveguardServer.AdminAbuse.HandleSuspiciousActivity(adminId, violation, action)
        end
    end
end

-- Pattern kontrolü
function FiveguardServer.AdminAbuse.CheckPattern(adminId, adminActions, pattern, currentTime)
    if pattern.type == 'excessive_bans' then
        return FiveguardServer.AdminAbuse.CheckExcessiveBans(adminActions, pattern, currentTime)
    elseif pattern.type == 'self_benefit' then
        return FiveguardServer.AdminAbuse.CheckSelfBenefit(adminId, adminActions, pattern)
    elseif pattern.type == 'midnight_activity' then
        return FiveguardServer.AdminAbuse.CheckMidnightActivity(adminActions, pattern, currentTime)
    elseif pattern.type == 'rapid_actions' then
        return FiveguardServer.AdminAbuse.CheckRapidActions(adminActions, pattern, currentTime)
    elseif pattern.type == 'targeting_players' then
        return FiveguardServer.AdminAbuse.CheckTargetingPlayers(adminActions, pattern, currentTime)
    elseif pattern.type == 'excessive_teleports' then
        return FiveguardServer.AdminAbuse.CheckExcessiveTeleports(adminActions, pattern, currentTime)
    end
    
    return nil
end

-- Aşırı ban kontrolü
function FiveguardServer.AdminAbuse.CheckExcessiveBans(adminActions, pattern, currentTime)
    local banCount = 0
    local timeWindow = pattern.timeWindow / 1000 -- saniyeye çevir
    
    for _, action in ipairs(adminActions) do
        if action.actionType == actionTypes.BAN and (currentTime - action.timestamp) <= timeWindow then
            banCount = banCount + 1
        end
    end
    
    if banCount >= pattern.threshold then
        return {
            type = pattern.type,
            severity = pattern.severity,
            description = pattern.description,
            count = banCount,
            threshold = pattern.threshold,
            timeWindow = timeWindow
        }
    end
    
    return nil
end

-- Kendi kendine avantaj kontrolü
function FiveguardServer.AdminAbuse.CheckSelfBenefit(adminId, adminActions, pattern)
    for _, action in ipairs(adminActions) do
        if action.targetPlayerId == adminId then
            for _, suspiciousAction in ipairs(pattern.actions) do
                if action.actionType == suspiciousAction then
                    return {
                        type = pattern.type,
                        severity = pattern.severity,
                        description = pattern.description,
                        action = action.actionType,
                        selfTargeted = true
                    }
                end
            end
        end
    end
    
    return nil
end

-- Gece yarısı aktivite kontrolü
function FiveguardServer.AdminAbuse.CheckMidnightActivity(adminActions, pattern, currentTime)
    local nightActions = 0
    local currentHour = tonumber(os.date('%H', currentTime))
    
    -- Gece saatleri kontrolü
    if currentHour >= pattern.timeRange[1] and currentHour <= pattern.timeRange[2] then
        local timeWindow = 3600 -- 1 saat
        
        for _, action in ipairs(adminActions) do
            local actionHour = tonumber(os.date('%H', action.timestamp))
            if actionHour >= pattern.timeRange[1] and actionHour <= pattern.timeRange[2] and
               (currentTime - action.timestamp) <= timeWindow then
                nightActions = nightActions + 1
            end
        end
        
        if nightActions >= pattern.actionThreshold then
            return {
                type = pattern.type,
                severity = pattern.severity,
                description = pattern.description,
                count = nightActions,
                threshold = pattern.actionThreshold,
                timeRange = pattern.timeRange
            }
        end
    end
    
    return nil
end

-- Hızlı ardışık işlem kontrolü
function FiveguardServer.AdminAbuse.CheckRapidActions(adminActions, pattern, currentTime)
    local recentActions = 0
    local timeWindow = pattern.timeWindow / 1000 -- saniyeye çevir
    
    for _, action in ipairs(adminActions) do
        if (currentTime - action.timestamp) <= timeWindow then
            recentActions = recentActions + 1
        end
    end
    
    if recentActions >= pattern.threshold then
        return {
            type = pattern.type,
            severity = pattern.severity,
            description = pattern.description,
            count = recentActions,
            threshold = pattern.threshold,
            timeWindow = timeWindow
        }
    end
    
    return nil
end

-- Belirli oyuncuları hedef alma kontrolü
function FiveguardServer.AdminAbuse.CheckTargetingPlayers(adminActions, pattern, currentTime)
    local targetCounts = {}
    local timeWindow = pattern.timeWindow / 1000 -- saniyeye çevir
    
    for _, action in ipairs(adminActions) do
        if action.targetPlayerId and (currentTime - action.timestamp) <= timeWindow then
            local targetId = action.targetPlayerId
            targetCounts[targetId] = (targetCounts[targetId] or 0) + 1
            
            if targetCounts[targetId] >= pattern.threshold then
                return {
                    type = pattern.type,
                    severity = pattern.severity,
                    description = pattern.description,
                    targetPlayerId = targetId,
                    targetPlayerName = action.targetPlayerName,
                    count = targetCounts[targetId],
                    threshold = pattern.threshold
                }
            end
        end
    end
    
    return nil
end

-- Aşırı teleport kontrolü
function FiveguardServer.AdminAbuse.CheckExcessiveTeleports(adminActions, pattern, currentTime)
    local teleportCount = 0
    local timeWindow = pattern.timeWindow / 1000 -- saniyeye çevir
    
    for _, action in ipairs(adminActions) do
        if (action.actionType == actionTypes.TELEPORT or 
            action.actionType == actionTypes.BRING_PLAYER or 
            action.actionType == actionTypes.GOTO_PLAYER) and 
           (currentTime - action.timestamp) <= timeWindow then
            teleportCount = teleportCount + 1
        end
    end
    
    if teleportCount >= pattern.threshold then
        return {
            type = pattern.type,
            severity = pattern.severity,
            description = pattern.description,
            count = teleportCount,
            threshold = pattern.threshold,
            timeWindow = timeWindow
        }
    end
    
    return nil
end

-- =============================================
-- ŞÜPHELİ AKTİVİTE İŞLEME
-- =============================================

-- Şüpheli aktiviteyi işle
function FiveguardServer.AdminAbuse.HandleSuspiciousActivity(adminId, violation, triggerAction)
    local admin = FiveguardServer.Players[adminId]
    if not admin then return end
    
    -- Şüpheli aktiviteyi kaydet
    local suspiciousActivity = {
        id = FiveguardServer.AdminAbuse.GenerateSuspiciousId(),
        adminId = adminId,
        adminName = admin.name,
        adminIdentifiers = admin.identifiers,
        violation = violation,
        triggerAction = triggerAction,
        timestamp = os.time(),
        riskLevel = FiveguardServer.AdminAbuse.CalculateRiskLevel(violation.severity),
        handled = false
    }
    
    -- Kaydet
    if not abuseData.suspiciousActivities[adminId] then
        abuseData.suspiciousActivities[adminId] = {}
    end
    
    table.insert(abuseData.suspiciousActivities[adminId], suspiciousActivity)
    
    -- İstatistikleri güncelle
    abuseData.stats.suspiciousActionsDetected = abuseData.stats.suspiciousActionsDetected + 1
    abuseData.stats.lastDetection = os.time()
    
    -- Risk seviyesine göre işlem yap
    FiveguardServer.AdminAbuse.TakeActionBasedOnRisk(suspiciousActivity)
    
    -- Diğer admin'leri bilgilendir
    if abuseData.config.notifyOtherAdmins then
        FiveguardServer.AdminAbuse.NotifyOtherAdmins(suspiciousActivity)
    end
    
    -- Veritabanına kaydet
    FiveguardServer.AdminAbuse.SaveSuspiciousActivityToDatabase(suspiciousActivity)
    
    -- Webhook gönder
    FiveguardServer.AdminAbuse.SendSuspiciousActivityWebhook(suspiciousActivity)
    
    print('^1[FIVEGUARD ADMIN ABUSE]^7 ŞÜPHELİ AKTİVİTE TESPİT EDİLDİ! Admin: ' .. admin.name .. 
          ' (' .. violation.type .. ' - ' .. violation.severity .. ')')
end

-- Risk seviyesini hesapla
function FiveguardServer.AdminAbuse.CalculateRiskLevel(severity)
    local riskMap = {
        low = riskLevels.LOW,
        medium = riskLevels.MEDIUM,
        high = riskLevels.HIGH,
        critical = riskLevels.CRITICAL
    }
    
    return riskMap[severity] or riskLevels.LOW
end

-- Risk seviyesine göre işlem al
function FiveguardServer.AdminAbuse.TakeActionBasedOnRisk(suspiciousActivity)
    if not abuseData.config.autoActionEnabled then return end
    
    local riskLevel = suspiciousActivity.riskLevel
    local adminId = suspiciousActivity.adminId
    
    if riskLevel == riskLevels.CRITICAL then
        -- Kritik seviye - Admin'i geçici olarak yetkisiz bırak
        FiveguardServer.AdminAbuse.SuspendAdmin(adminId, 'Kritik şüpheli aktivite tespit edildi', 3600) -- 1 saat
        
    elseif riskLevel == riskLevels.HIGH then
        -- Yüksek seviye - Admin'i uyar ve yakın takibe al
        FiveguardServer.AdminAbuse.WarnAdmin(adminId, 'Yüksek riskli aktivite tespit edildi')
        FiveguardServer.AdminAbuse.AddToCloseMonitoring(adminId)
        
    elseif riskLevel == riskLevels.MEDIUM then
        -- Orta seviye - Admin'i uyar
        FiveguardServer.AdminAbuse.WarnAdmin(adminId, 'Şüpheli aktivite tespit edildi')
        
    elseif riskLevel == riskLevels.LOW then
        -- Düşük seviye - Sadece logla
        if FiveguardServer.Config.debug then
            print('^3[FIVEGUARD ADMIN ABUSE]^7 Düşük riskli aktivite: ' .. suspiciousActivity.adminName)
        end
    end
    
    suspiciousActivity.handled = true
end

-- Admin'i askıya al
function FiveguardServer.AdminAbuse.SuspendAdmin(adminId, reason, duration)
    local admin = FiveguardServer.Players[adminId]
    if not admin then return end
    
    -- Admin yetkilerini geçici olarak kaldır
    ExecuteCommand('remove_ace identifier.' .. admin.identifiers.license .. ' fiveguard.admin allow')
    
    -- Askıya alma kaydı
    local suspension = {
        adminId = adminId,
        adminName = admin.name,
        reason = reason,
        duration = duration,
        timestamp = os.time(),
        expiresAt = os.time() + duration,
        active = true
    }
    
    -- Veritabanına kaydet
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_admin_suspensions (admin_id, admin_name, reason, duration, timestamp, expires_at) VALUES (?, ?, ?, ?, ?, ?)', {
        adminId,
        admin.name,
        reason,
        duration,
        suspension.timestamp,
        suspension.expiresAt
    })
    
    -- Admin'e bildir
    TriggerClientEvent('chat:addMessage', adminId, {
        color = {255, 0, 0},
        multiline = true,
        args = {'FIVEGUARD', 'Admin yetkiniz geçici olarak askıya alındı. Sebep: ' .. reason}
    })
    
    abuseData.stats.adminsBanned = abuseData.stats.adminsBanned + 1
    
    print('^1[FIVEGUARD ADMIN ABUSE]^7 Admin askıya alındı: ' .. admin.name .. ' (Sebep: ' .. reason .. ')')
end

-- Admin'i uyar
function FiveguardServer.AdminAbuse.WarnAdmin(adminId, reason)
    local admin = FiveguardServer.Players[adminId]
    if not admin then return end
    
    TriggerClientEvent('chat:addMessage', adminId, {
        color = {255, 165, 0},
        multiline = true,
        args = {'FIVEGUARD UYARI', reason .. '. Lütfen admin yetkilerinizi sorumlu bir şekilde kullanın.'}
    })
    
    -- Uyarı kaydı
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_admin_warnings (admin_id, admin_name, reason, timestamp) VALUES (?, ?, ?, ?)', {
        adminId,
        admin.name,
        reason,
        os.time()
    })
end

-- Yakın takibe al
function FiveguardServer.AdminAbuse.AddToCloseMonitoring(adminId)
    -- Yakın takip listesine ekle (daha sık kontrol)
    -- Bu implementasyon monitoring thread'inde kullanılacak
end

-- Diğer admin'leri bilgilendir
function FiveguardServer.AdminAbuse.NotifyOtherAdmins(suspiciousActivity)
    local message = string.format(
        '^1[FIVEGUARD ADMIN ABUSE]^7 Şüpheli admin aktivitesi tespit edildi!\n' ..
        'Admin: ^3%s^7\n' ..
        'Tür: ^3%s^7\n' ..
        'Açıklama: ^3%s^7\n' ..
        'Risk Seviyesi: ^3%s^7',
        suspiciousActivity.adminName,
        suspiciousActivity.violation.type,
        suspiciousActivity.violation.description,
        suspiciousActivity.violation.severity
    )
    
    -- Tüm online admin'lere bildir (kendisi hariç)
    for playerId, player in pairs(FiveguardServer.Players) do
        if player.isAdmin and playerId ~= suspiciousActivity.adminId then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 0, 0},
                multiline = true,
                args = {'FIVEGUARD ADMIN ABUSE', message}
            })
        end
    end
end

-- =============================================
-- MONİTORİNG VE CLEANUP
-- =============================================

-- Monitoring thread'ini başlat
function FiveguardServer.AdminAbuse.StartMonitoring()
    CreateThread(function()
        while abuseData.isActive do
            Wait(60000) -- 1 dakika bekle
            
            -- Aktif admin'leri kontrol et
            FiveguardServer.AdminAbuse.MonitorActiveAdmins()
            
            -- Askıya alınan admin'leri kontrol et
            FiveguardServer.AdminAbuse.CheckSuspendedAdmins()
        end
    end)
end

-- Aktif admin'leri monitör et
function FiveguardServer.AdminAbuse.MonitorActiveAdmins()
    for playerId, player in pairs(FiveguardServer.Players) do
        if player.isAdmin then
            -- Son aktivitelerini kontrol et
            local recentActions = FiveguardServer.AdminAbuse.GetRecentActions(playerId, 300) -- Son 5 dakika
            
            if #recentActions > 0 then
                -- Gerçek zamanlı analiz
                FiveguardServer.AdminAbuse.RealTimeAnalysis(playerId, recentActions)
            end
        end
    end
end

-- Askıya alınan admin'leri kontrol et
function FiveguardServer.AdminAbuse.CheckSuspendedAdmins()
    local currentTime = os.time()
    
    FiveguardServer.Database.Execute('SELECT * FROM fiveguard_admin_suspensions WHERE active = 1 AND expires_at <= ?', {
        currentTime
    }, function(results)
        if results then
            for _, suspension in ipairs(results) do
                -- Askıyı kaldır
                FiveguardServer.AdminAbuse.UnsuspendAdmin(suspension.admin_id, suspension.admin_name)
                
                -- Veritabanını güncelle
                FiveguardServer.Database.Execute('UPDATE fiveguard_admin_suspensions SET active = 0 WHERE id = ?', {
                    suspension.id
                })
            end
        end
    end)
end

-- Admin askısını kaldır
function FiveguardServer.AdminAbuse.UnsuspendAdmin(adminId, adminName)
    -- Admin yetkilerini geri ver
    local player = FiveguardServer.Players[adminId]
    if player then
        ExecuteCommand('add_ace identifier.' .. player.identifiers.license .. ' fiveguard.admin allow')
        
        TriggerClientEvent('chat:addMessage', adminId, {
            color = {0, 255, 0},
            multiline = true,
            args = {'FIVEGUARD', 'Admin yetkiniz geri verildi. Lütfen sorumlu bir şekilde kullanın.'}
        })
    end
    
    print('^2[FIVEGUARD ADMIN ABUSE]^7 Admin askısı kaldırıldı: ' .. adminName)
end

-- Cleanup thread'ini başlat
function FiveguardServer.AdminAbuse.StartCleanup()
    CreateThread(function()
        while abuseData.isActive do
            Wait(3600000) -- 1 saat bekle
            
            -- Eski kayıtları temizle
            FiveguardServer.AdminAbuse.CleanupOldRecords()
        end
    end)
end

-- Eski kayıtları temizle
function FiveguardServer.AdminAbuse.CleanupOldRecords()
    local currentTime = os.time()
    local cleanupThreshold = currentTime - (7 * 24 * 3600) -- 7 gün önce
    local cleanedCount = 0
    
    -- Memory'den eski kayıtları temizle
    for adminId, actions in pairs(abuseData.adminActions) do
        local filteredActions = {}
        for _, action in ipairs(actions) do
            if action.timestamp > cleanupThreshold then
                table.insert(filteredActions, action)
            else
                cleanedCount = cleanedCount + 1
            end
        end
        abuseData.adminActions[adminId] = filteredActions
    end
    
    -- Şüpheli aktiviteleri temizle
    for adminId, activities in pairs(abuseData.suspiciousActivities) do
        local filteredActivities = {}
        for _, activity in ipairs(activities) do
            if activity.timestamp > cleanupThreshold then
                table.insert(filteredActivities, activity)
            end
        end
        abuseData.suspiciousActivities[adminId] = filteredActivities
    end
    
    if cleanedCount > 0 and FiveguardServer.Config.debug then
        print('^3[FIVEGUARD ADMIN ABUSE]^7 Eski kayıtlar temizlendi: ' .. cleanedCount)
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Son eylemleri getir
function FiveguardServer.AdminAbuse.GetRecentActions(adminId, timeWindow)
    local actions = abuseData.adminActions[adminId] or {}
    local recentActions = {}
    local currentTime = os.time()
    
    for _, action in ipairs(actions) do
        if (currentTime - action.timestamp) <= timeWindow then
            table.insert(recentActions, action)
        end
    end
    
    return recentActions
end

-- Gerçek zamanlı analiz
function FiveguardServer.AdminAbuse.RealTimeAnalysis(adminId, recentActions)
    -- Gerçek zamanlı pattern analizi
    -- Bu fonksiyon sürekli çalışan analizler için kullanılır
end

-- Whitelisted admin'leri yükle
function FiveguardServer.AdminAbuse.LoadWhitelistedAdmins()
    FiveguardServer.Database.Execute('SELECT * FROM fiveguard_admin_whitelist WHERE active = 1', {}, function(results)
        if results then
            for _, admin in ipairs(results) do
                abuseData.whitelistedAdmins[admin.admin_id] = {
                    adminName = admin.admin_name,
                    reason = admin.reason,
                    addedBy = admin.added_by,
                    timestamp = admin.timestamp
                }
            end
            
            print('^2[FIVEGUARD ADMIN ABUSE]^7 Whitelisted admin\'ler yüklendi: ' .. #results)
        end
    end)
end

-- Belirli admin'i kontrol et
function FiveguardServer.AdminAbuse.CheckSpecificAdmin(requesterId, targetAdminId)
    local requester = FiveguardServer.Players[requesterId]
    if not requester or not requester.isAdmin then return end
    
    local adminActions = abuseData.adminActions[targetAdminId] or {}
    local suspiciousActivities = abuseData.suspiciousActivities[targetAdminId] or {}
    
    -- Rapor oluştur
    local report = {
        adminId = targetAdminId,
        adminName = GetPlayerName(targetAdminId) or 'Bilinmeyen',
        totalActions = #adminActions,
        suspiciousActivities = #suspiciousActivities,
        recentActions = FiveguardServer.AdminAbuse.GetRecentActions(targetAdminId, 3600), -- Son 1 saat
        riskLevel = FiveguardServer.AdminAbuse.CalculateAdminRiskLevel(targetAdminId)
    }
    
    -- Raporu gönder
    TriggerClientEvent('fiveguard:admin:receiveReport', requesterId, report)
end

-- Admin risk seviyesini hesapla
function FiveguardServer.AdminAbuse.CalculateAdminRiskLevel(adminId)
    local suspiciousActivities = abuseData.suspiciousActivities[adminId] or {}
    local recentActivities = 0
    local currentTime = os.time()
    
    for _, activity in ipairs(suspiciousActivities) do
        if (currentTime - activity.timestamp) <= 86400 then -- Son 24 saat
            recentActivities = recentActivities + 1
        end
    end
    
    if recentActivities >= 5 then
        return 'critical'
    elseif recentActivities >= 3 then
        return 'high'
    elseif recentActivities >= 1 then
        return 'medium'
    else
        return 'low'
    end
end

-- Whitelist güncelle
function FiveguardServer.AdminAbuse.UpdateWhitelist(requesterId, adminList)
    local requester = FiveguardServer.Players[requesterId]
    if not requester or not requester.isSuperAdmin then return end
    
    -- Mevcut whitelist'i temizle
    abuseData.whitelistedAdmins = {}
    
    -- Yeni listeyi ekle
    for _, adminData in ipairs(adminList) do
        abuseData.whitelistedAdmins[adminData.adminId] = adminData
        
        -- Veritabanına kaydet
        FiveguardServer.Database.Execute('INSERT OR REPLACE INTO fiveguard_admin_whitelist (admin_id, admin_name, reason, added_by, timestamp, active) VALUES (?, ?, ?, ?, ?, 1)', {
            adminData.adminId,
            adminData.adminName,
            adminData.reason,
            requester.name,
            os.time()
        })
    end
    
    print('^2[FIVEGUARD ADMIN ABUSE]^7 Admin whitelist güncellendi: ' .. #adminList .. ' admin')
end

-- Action ID oluştur
function FiveguardServer.AdminAbuse.GenerateActionId()
    return 'action_' .. os.time() .. '_' .. math.random(1000, 9999)
end

-- Suspicious ID oluştur
function FiveguardServer.AdminAbuse.GenerateSuspiciousId()
    return 'suspicious_' .. os.time() .. '_' .. math.random(1000, 9999)
end

-- Action'ı veritabanına kaydet
function FiveguardServer.AdminAbuse.SaveActionToDatabase(action)
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_admin_actions (action_id, admin_id, admin_name, action_type, target_player_id, target_player_name, parameters, timestamp, reason, source, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        action.id,
        action.adminId,
        action.adminName,
        action.actionType,
        action.targetPlayerId,
        action.targetPlayerName,
        json.encode(action.parameters),
        action.timestamp,
        action.reason,
        action.source,
        json.encode(action.metadata)
    })
end

-- Şüpheli aktiviteyi veritabanına kaydet
function FiveguardServer.AdminAbuse.SaveSuspiciousActivityToDatabase(activity)
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_admin_suspicious_activities (activity_id, admin_id, admin_name, violation_type, violation_data, trigger_action, timestamp, risk_level, handled) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        activity.id,
        activity.adminId,
        activity.adminName,
        activity.violation.type,
        json.encode(activity.violation),
        json.encode(activity.triggerAction),
        activity.timestamp,
        activity.riskLevel,
        activity.handled and 1 or 0
    })
end

-- Şüpheli aktivite webhook'u gönder
function FiveguardServer.AdminAbuse.SendSuspiciousActivityWebhook(activity)
    local webhookData = {
        username = 'Fiveguard Admin Abuse',
        avatar_url = 'https://i.imgur.com/fiveguard-logo.png',
        embeds = {{
            title = '⚠️ Şüpheli Admin Aktivitesi Tespit Edildi!',
            color = 16776960, -- Sarı
            fields = {
                {name = 'Admin', value = activity.adminName, inline = true},
                {name = 'Violation Türü', value = activity.violation.type, inline = true},
                {name = 'Risk Seviyesi', value = activity.violation.severity, inline = true},
                {name = 'Açıklama', value = activity.violation.description, inline = false},
                {name = 'Tetikleyici Action', value = activity.triggerAction.actionType, inline = true},
                {name = 'Zaman', value = os.date('%Y-%m-%d %H:%M:%S', activity.timestamp), inline = true}
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', activity.timestamp)
        }}
    }
    
    FiveguardServer.Webhook.Send('admin_abuse', webhookData)
end

-- İstatistikleri getir
function FiveguardServer.AdminAbuse.GetStats()
    return {
        totalActionsLogged = abuseData.stats.totalActionsLogged,
        suspiciousActionsDetected = abuseData.stats.suspiciousActionsDetected,
        adminsBanned = abuseData.stats.adminsBanned,
        lastDetection = abuseData.stats.lastDetection,
        whitelistedAdminsCount = FiveguardServer.AdminAbuse.GetWhitelistedAdminCount(),
        activeAdminsCount = FiveguardServer.AdminAbuse.GetActiveAdminCount(),
        isActive = abuseData.isActive
    }
end

-- Whitelisted admin sayısını getir
function FiveguardServer.AdminAbuse.GetWhitelistedAdminCount()
    local count = 0
    for _ in pairs(abuseData.whitelistedAdmins) do
        count = count + 1
    end
    return count
end

-- Aktif admin sayısını getir
function FiveguardServer.AdminAbuse.GetActiveAdminCount()
    local count = 0
    for playerId, player in pairs(FiveguardServer.Players) do
        if player.isAdmin then
            count = count + 1
        end
    end
    return count
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Admin action'ı logla (diğer resource'lar için)
function LogAdminAction(adminId, actionType, targetPlayerId, parameters, reason)
    local actionData = {
        type = actionType,
        targetPlayerId = targetPlayerId,
        targetPlayerName = targetPlayerId and GetPlayerName(targetPlayerId) or nil,
        parameters = parameters or {},
        reason = reason or 'Sebep belirtilmedi',
        source = GetInvokingResource() or 'unknown'
    }
    
    FiveguardServer.AdminAbuse.LogAdminAction(adminId, actionData)
end

-- Admin abuse istatistiklerini getir
function GetAdminAbuseStats()
    return FiveguardServer.AdminAbuse.GetStats()
end

-- Admin abuse durumunu kontrol et
function IsAdminAbuseActive()
    return abuseData.isActive
end

-- Admin'i whitelist'e ekle
function AddAdminToWhitelist(adminId, adminName, reason, addedBy)
    abuseData.whitelistedAdmins[adminId] = {
        adminName = adminName,
        reason = reason,
        addedBy = addedBy,
        timestamp = os.time()
    }
    
    -- Veritabanına kaydet
    FiveguardServer.Database.Execute('INSERT OR REPLACE INTO fiveguard_admin_whitelist (admin_id, admin_name, reason, added_by, timestamp, active) VALUES (?, ?, ?, ?, ?, 1)', {
        adminId,
        adminName,
        reason,
        addedBy,
        os.time()
    })
    
    return true
end

-- Admin'i whitelist'ten kaldır
function RemoveAdminFromWhitelist(adminId)
    abuseData.whitelistedAdmins[adminId] = nil
    
    -- Veritabanından kaldır
    FiveguardServer.Database.Execute('UPDATE fiveguard_admin_whitelist SET active = 0 WHERE admin_id = ?', {
        adminId
    })
    
    return true
end

print('^2[FIVEGUARD ADMIN ABUSE]^7 Admin Abuse Detection modülü yüklendi')
