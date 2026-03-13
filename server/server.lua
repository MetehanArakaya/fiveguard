-- FIVEGUARD ANTI-CHEAT SYSTEM
-- Ana sunucu dosyası - Tüm modüllerin entegrasyonu

print('^2[FIVEGUARD]^7 Fiveguard Anti-Cheat System başlatılıyor...')

-- =============================================
-- GLOBAL NAMESPACE
-- =============================================

FiveguardServer = {}
FiveguardServer.Players = {}
FiveguardServer.Config = {}

-- =============================================
-- KONFIGÜRASYON YÜKLEME
-- =============================================

-- Config dosyasını yükle
local function LoadConfig()
    local configFile = LoadResourceFile(GetCurrentResourceName(), 'config/config.lua')
    if configFile then
        local configFunc = load(configFile)
        if configFunc then
            configFunc()
            FiveguardServer.Config = Config or {}
            print('^2[FIVEGUARD]^7 Konfigürasyon yüklendi')
        else
            print('^1[FIVEGUARD]^7 Konfigürasyon dosyası yüklenemedi!')
        end
    else
        print('^1[FIVEGUARD]^7 Konfigürasyon dosyası bulunamadı!')
    end
end

-- =============================================
-- CORE MODÜLLER
-- =============================================

-- Database modülünü yükle
local function LoadDatabase()
    local databaseFile = LoadResourceFile(GetCurrentResourceName(), 'server/core/database.lua')
    if databaseFile then
        local databaseFunc = load(databaseFile)
        if databaseFunc then
            databaseFunc()
            print('^2[FIVEGUARD]^7 Database modülü yüklendi')
        end
    end
end

-- Webhook modülünü yükle
local function LoadWebhook()
    local webhookFile = LoadResourceFile(GetCurrentResourceName(), 'server/core/webhook.lua')
    if webhookFile then
        local webhookFunc = load(webhookFile)
        if webhookFunc then
            webhookFunc()
            print('^2[FIVEGUARD]^7 Webhook modülü yüklendi')
        end
    end
end

-- Protection Manager modülünü yükle
local function LoadProtectionManager()
    local protectionFile = LoadResourceFile(GetCurrentResourceName(), 'server/core/protection_manager.lua')
    if protectionFile then
        local protectionFunc = load(protectionFile)
        if protectionFunc then
            protectionFunc()
            print('^2[FIVEGUARD]^7 Protection Manager modülü yüklendi')
        end
    end
end

-- Performance Optimizer modülünü yükle
local function LoadPerformanceOptimizer()
    local performanceFile = LoadResourceFile(GetCurrentResourceName(), 'server/core/performance_optimizer.lua')
    if performanceFile then
        local performanceFunc = load(performanceFile)
        if performanceFunc then
            performanceFunc()
            print('^2[FIVEGUARD]^7 Performance Optimizer modülü yüklendi')
        end
    end
end

-- =============================================
-- PROTECTION MODÜLLER
-- =============================================

-- Admin Abuse modülünü yükle
local function LoadAdminAbuse()
    local adminFile = LoadResourceFile(GetCurrentResourceName(), 'server/modules/admin_abuse.lua')
    if adminFile then
        local adminFunc = load(adminFile)
        if adminFunc then
            adminFunc()
            print('^2[FIVEGUARD]^7 Admin Abuse modülü yüklendi')
        end
    end
end

-- OCR Handler modülünü yükle
local function LoadOCRHandler()
    local ocrFile = LoadResourceFile(GetCurrentResourceName(), 'server/modules/ocr_handler.lua')
    if ocrFile then
        local ocrFunc = load(ocrFile)
        if ocrFunc then
            ocrFunc()
            print('^2[FIVEGUARD]^7 OCR Handler modülü yüklendi')
        end
    end
end

-- Cheat Detection modülünü yükle
local function LoadCheatDetection()
    local cheatFile = LoadResourceFile(GetCurrentResourceName(), 'server/modules/cheat_detection.lua')
    if cheatFile then
        local cheatFunc = load(cheatFile)
        if cheatFunc then
            cheatFunc()
            print('^2[FIVEGUARD]^7 Cheat Detection modülü yüklendi')
        end
    end
end

-- ESX Security modülünü yükle
local function LoadESXSecurity()
    local esxFile = LoadResourceFile(GetCurrentResourceName(), 'server/modules/esx_security.lua')
    if esxFile then
        local esxFunc = load(esxFile)
        if esxFunc then
            esxFunc()
            print('^2[FIVEGUARD]^7 ESX Security modülü yüklendi')
        end
    end
end

-- Network Security modülünü yükle
local function LoadNetworkSecurity()
    local networkFile = LoadResourceFile(GetCurrentResourceName(), 'server/modules/network_security.lua')
    if networkFile then
        local networkFunc = load(networkFile)
        if networkFunc then
            networkFunc()
            print('^2[FIVEGUARD]^7 Network Security modülü yüklendi')
        end
    end
end

-- Entity Validation modülünü yükle
local function LoadEntityValidation()
    local entityFile = LoadResourceFile(GetCurrentResourceName(), 'server/modules/entity_validation.lua')
    if entityFile then
        local entityFunc = load(entityFile)
        if entityFunc then
            entityFunc()
            print('^2[FIVEGUARD]^7 Entity Validation modülü yüklendi')
        end
    end
end

-- Weapon Security modülünü yükle
local function LoadWeaponSecurity()
    local weaponFile = LoadResourceFile(GetCurrentResourceName(), 'server/modules/weapon_security.lua')
    if weaponFile then
        local weaponFunc = load(weaponFile)
        if weaponFunc then
            weaponFunc()
            print('^2[FIVEGUARD]^7 Weapon Security modülü yüklendi')
        end
    end
end

-- =============================================
-- PLAYER MANAGEMENT
-- =============================================

-- Player'ı kaydet
local function RegisterPlayer(playerId)
    local playerName = GetPlayerName(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    local endpoint = GetPlayerEndpoint(playerId)
    
    FiveguardServer.Players[playerId] = {
        id = playerId,
        name = playerName,
        identifiers = identifiers,
        endpoint = endpoint,
        joinTime = os.time(),
        isAdmin = false,
        violations = {},
        lastActivity = os.time()
    }
    
    print('^2[FIVEGUARD]^7 Player kaydedildi: ' .. playerName .. ' (' .. playerId .. ')')
end

-- Player'ı kaldır
local function UnregisterPlayer(playerId)
    if FiveguardServer.Players[playerId] then
        local playerName = FiveguardServer.Players[playerId].name
        FiveguardServer.Players[playerId] = nil
        print('^3[FIVEGUARD]^7 Player kaldırıldı: ' .. playerName .. ' (' .. playerId .. ')')
    end
end

-- =============================================
-- EVENT HANDLERS
-- =============================================

-- Player connecting event
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local playerId = source
    print('^3[FIVEGUARD]^7 Player bağlanıyor: ' .. name .. ' (' .. playerId .. ')')
end)

-- Player joined event
AddEventHandler('playerJoining', function()
    local playerId = source
    RegisterPlayer(playerId)
end)

-- Player dropped event
AddEventHandler('playerDropped', function(reason)
    local playerId = source
    UnregisterPlayer(playerId)
end)

-- Resource start event
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^2[FIVEGUARD]^7 Resource başlatıldı: ' .. resourceName)
    end
end)

-- Resource stop event
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('^3[FIVEGUARD]^7 Resource durduruluyor: ' .. resourceName)
    end
end)

-- =============================================
-- COMMANDS
-- =============================================

-- Fiveguard status komutu
RegisterCommand('fiveguard', function(source, args, rawCommand)
    local playerId = source
    
    if playerId == 0 then -- Console
        print('^2[FIVEGUARD STATUS]^7')
        print('Active Players: ' .. #FiveguardServer.Players)
        
        if FiveguardServer.ProtectionManager then
            local stats = FiveguardServer.ProtectionManager.GetStats()
            print('Total Detections: ' .. stats.totalDetections)
            print('Active Modules: ' .. stats.activeModules)
        end
        
        return
    end
    
    -- Player komutu - Admin kontrolü
    local player = FiveguardServer.Players[playerId]
    if not player or not player.isAdmin then
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {255, 0, 0},
            multiline = true,
            args = {'FIVEGUARD', 'Bu komutu kullanma yetkiniz yok!'}
        })
        return
    end
    
    -- Admin için status bilgisi
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {0, 255, 0},
        multiline = true,
        args = {'FIVEGUARD', 'Fiveguard Anti-Cheat System aktif - Oyuncu sayısı: ' .. #FiveguardServer.Players}
    })
end, false)

-- Ban komutu
RegisterCommand('fgban', function(source, args, rawCommand)
    local playerId = source
    
    if playerId ~= 0 then -- Sadece console
        return
    end
    
    if not args[1] or not args[2] then
        print('Kullanım: fgban <player_id> <reason>')
        return
    end
    
    local targetId = tonumber(args[1])
    local reason = table.concat(args, ' ', 2)
    
    if not targetId or not GetPlayerName(targetId) then
        print('Geçersiz player ID: ' .. args[1])
        return
    end
    
    -- Ban kaydı
    if FiveguardServer.Database then
        FiveguardServer.Database.Execute('INSERT INTO fiveguard_bans (player_id, player_name, reason, ban_type, timestamp, expires_at, active) VALUES (?, ?, ?, ?, ?, ?, 1)', {
            targetId,
            GetPlayerName(targetId),
            reason,
            'manual',
            os.time(),
            os.time() + (30 * 24 * 3600) -- 30 gün
        })
    end
    
    -- Player'ı at
    DropPlayer(targetId, 'FIVEGUARD: ' .. reason)
    
    print('^1[FIVEGUARD]^7 Player banlandı: ' .. GetPlayerName(targetId) .. ' (Sebep: ' .. reason .. ')')
end, true)

-- Unban komutu
RegisterCommand('fgunban', function(source, args, rawCommand)
    local playerId = source
    
    if playerId ~= 0 then -- Sadece console
        return
    end
    
    if not args[1] then
        print('Kullanım: fgunban <player_id>')
        return
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId then
        print('Geçersiz player ID: ' .. args[1])
        return
    end
    
    -- Ban'ı kaldır
    if FiveguardServer.Database then
        FiveguardServer.Database.Execute('UPDATE fiveguard_bans SET active = 0 WHERE player_id = ? AND active = 1', {targetId})
    end
    
    print('^2[FIVEGUARD]^7 Player ban\'ı kaldırıldı: ' .. targetId)
end, true)

-- =============================================
-- INITIALIZATION
-- =============================================

-- Sistem başlatma
local function InitializeFiveguard()
    print('^2[FIVEGUARD]^7 ==========================================')
    print('^2[FIVEGUARD]^7 FIVEGUARD ANTI-CHEAT SYSTEM v2.0')
    print('^2[FIVEGUARD]^7 Gelişmiş FiveM Anti-Cheat Sistemi')
    print('^2[FIVEGUARD]^7 ==========================================')
    
    -- Konfigürasyonu yükle
    LoadConfig()
    
    -- Core modülleri yükle
    LoadDatabase()
    LoadWebhook()
    LoadProtectionManager()
    LoadPerformanceOptimizer()
    
    -- Protection modülleri yükle
    LoadAdminAbuse()
    LoadOCRHandler()
    LoadCheatDetection()
    LoadESXSecurity()
    LoadNetworkSecurity()
    LoadEntityValidation()
    LoadWeaponSecurity()
    
    -- Modülleri başlat
    CreateThread(function()
        Wait(1000) -- 1 saniye bekle
        
        -- Database'i başlat
        if FiveguardServer.Database then
            FiveguardServer.Database.Initialize()
        end
        
        -- Protection Manager'ı başlat
        if FiveguardServer.ProtectionManager then
            FiveguardServer.ProtectionManager.Initialize()
        end
        
        -- Performance Optimizer'ı başlat
        if FiveguardServer.PerformanceOptimizer then
            FiveguardServer.PerformanceOptimizer.Initialize()
        end
        
        -- Admin Abuse'u başlat
        if FiveguardServer.AdminAbuse then
            FiveguardServer.AdminAbuse.Initialize()
        end
        
        -- OCR Handler'ı başlat
        if FiveguardServer.OCRHandler then
            FiveguardServer.OCRHandler.Initialize()
        end
        
        -- Cheat Detection'ı başlat
        if FiveguardServer.CheatDetection then
            FiveguardServer.CheatDetection.Initialize()
        end
        
        -- ESX Security'yi başlat
        if FiveguardServer.ESXSecurity then
            FiveguardServer.ESXSecurity.Initialize()
        end
        
        -- Network Security'yi başlat
        if FiveguardServer.NetworkSecurity then
            FiveguardServer.NetworkSecurity.Initialize()
        end
        
        -- Entity Validation'ı başlat
        if FiveguardServer.EntityValidation then
            FiveguardServer.EntityValidation.Initialize()
        end
        
        -- Weapon Security'yi başlat
        if FiveguardServer.WeaponSecurity then
            FiveguardServer.WeaponSecurity.Initialize()
        end
        
        print('^2[FIVEGUARD]^7 ==========================================')
        print('^2[FIVEGUARD]^7 TÜM MODÜLLER BAŞARIYLA YÜKLENDİ!')
        print('^2[FIVEGUARD]^7 Fiveguard Anti-Cheat System hazır')
        print('^2[FIVEGUARD]^7 ==========================================')
    end)
end

-- =============================================
-- EXPORTS
-- =============================================

-- Fiveguard durumunu getir
exports('GetFiveguardStatus', function()
    return {
        isActive = true,
        playerCount = #FiveguardServer.Players,
        modules = {
            database = FiveguardServer.Database ~= nil,
            protectionManager = FiveguardServer.ProtectionManager ~= nil,
            adminAbuse = FiveguardServer.AdminAbuse ~= nil,
            ocrHandler = FiveguardServer.OCRHandler ~= nil,
            cheatDetection = FiveguardServer.CheatDetection ~= nil,
            esxSecurity = FiveguardServer.ESXSecurity ~= nil,
            networkSecurity = FiveguardServer.NetworkSecurity ~= nil,
            entityValidation = FiveguardServer.EntityValidation ~= nil,
            weaponSecurity = FiveguardServer.WeaponSecurity ~= nil
        }
    }
end)

-- Player bilgilerini getir
exports('GetPlayerInfo', function(playerId)
    return FiveguardServer.Players[playerId]
end)

-- Tüm player'ları getir
exports('GetAllPlayers', function()
    return FiveguardServer.Players
end)

-- Player'ı banla
exports('BanPlayer', function(playerId, reason, duration)
    if not FiveguardServer.Players[playerId] then
        return false
    end
    
    local player = FiveguardServer.Players[playerId]
    duration = duration or (30 * 24 * 3600) -- Default 30 gün
    
    -- Ban kaydı
    if FiveguardServer.Database then
        FiveguardServer.Database.Execute('INSERT INTO fiveguard_bans (player_id, player_name, reason, ban_type, timestamp, expires_at, active) VALUES (?, ?, ?, ?, ?, ?, 1)', {
            playerId,
            player.name,
            reason,
            'export',
            os.time(),
            os.time() + duration
        })
    end
    
    -- Player'ı at
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
    
    return true
end)

-- =============================================
-- BAŞLATMA
-- =============================================

-- Sistem başlat
InitializeFiveguard()

print('^2[FIVEGUARD]^7 Server.lua yüklendi - Sistem başlatılıyor...')
