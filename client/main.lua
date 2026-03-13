-- FIVEGUARD CLIENT MAIN
-- AI Destekli FiveM Anti-Cheat Sistemi - Ana İstemci Dosyası

-- Global değişkenler
FiveguardClient = {}
FiveguardClient.Config = {}
FiveguardClient.PlayerData = {}
FiveguardClient.Detections = {}
FiveguardClient.IsActive = false
FiveguardClient.LastHeartbeat = 0

-- Başlangıç mesajı
print('^2[FIVEGUARD CLIENT]^7 İstemci tarafı başlatılıyor...')

-- =============================================
-- BAŞLATMA FONKSİYONLARI
-- =============================================

-- Ana başlatma fonksiyonu
function FiveguardClient.Initialize()
    print('^2[FIVEGUARD CLIENT]^7 İstemci modülleri başlatılıyor...')
    
    -- Oyuncu verilerini başlat
    FiveguardClient.InitializePlayerData()
    
    -- Modülleri başlat
    FiveguardClient.StartModules()
    
    -- Event'leri kaydet
    FiveguardClient.RegisterEvents()
    
    -- Heartbeat başlat
    FiveguardClient.StartHeartbeat()
    
    -- Ana döngüyü başlat
    FiveguardClient.StartMainLoop()
    
    FiveguardClient.IsActive = true
    print('^2[FIVEGUARD CLIENT]^7 İstemci hazır!')
end

-- Oyuncu verilerini başlat
function FiveguardClient.InitializePlayerData()
    local playerId = PlayerId()
    local playerPed = PlayerPedId()
    
    FiveguardClient.PlayerData = {
        playerId = playerId,
        playerPed = playerPed,
        serverId = GetPlayerServerId(playerId),
        name = GetPlayerName(playerId),
        
        -- Pozisyon ve hareket
        position = GetEntityCoords(playerPed),
        lastPosition = GetEntityCoords(playerPed),
        velocity = GetEntityVelocity(playerPed),
        lastVelocity = GetEntityVelocity(playerPed),
        
        -- Sağlık ve zırh
        health = GetEntityHealth(playerPed),
        maxHealth = GetEntityMaxHealth(playerPed),
        armor = GetPedArmour(playerPed),
        lastHealth = GetEntityHealth(playerPed),
        lastArmor = GetPedArmour(playerPed),
        
        -- Araç bilgileri
        vehicle = nil,
        lastVehicle = nil,
        isInVehicle = false,
        
        -- Silah bilgileri
        currentWeapon = nil,
        lastWeapon = nil,
        weaponAmmo = 0,
        
        -- Davranış verileri
        behaviorData = {
            shotsFired = 0,
            shotsHit = 0,
            accuracy = 0,
            reactionTimes = {},
            movementPattern = {},
            aimingTime = 0,
            lastAimStart = 0
        },
        
        -- Tespit sayaçları
        violations = {},
        lastScreenshot = 0,
        
        -- Durum bayrakları
        isAiming = false,
        isShooting = false,
        isMoving = false,
        isDead = false,
        
        -- Zaman damgaları
        joinTime = GetGameTimer(),
        lastUpdate = GetGameTimer()
    }
end

-- Modülleri başlat
function FiveguardClient.StartModules()
    print('^2[FIVEGUARD CLIENT]^7 Koruma modülleri başlatılıyor...')
    
    -- Anti-cheat modülleri
    if FiveguardClient.Config.godmode and FiveguardClient.Config.godmode.enabled then
        FiveguardClient.GodMode.Initialize()
        print('^2[FIVEGUARD CLIENT]^7 GodMode koruması aktif')
    end
    
    if FiveguardClient.Config.speedhack and FiveguardClient.Config.speedhack.enabled then
        FiveguardClient.SpeedHack.Initialize()
        print('^2[FIVEGUARD CLIENT]^7 SpeedHack koruması aktif')
    end
    
    if FiveguardClient.Config.noclip and FiveguardClient.Config.noclip.enabled then
        FiveguardClient.NoClip.Initialize()
        print('^2[FIVEGUARD CLIENT]^7 NoClip koruması aktif')
    end
    
    if FiveguardClient.Config.aimbot and FiveguardClient.Config.aimbot.enabled then
        FiveguardClient.Aimbot.Initialize()
        print('^2[FIVEGUARD CLIENT]^7 Aimbot koruması aktif')
    end
    
    if FiveguardClient.Config.esp and FiveguardClient.Config.esp.enabled then
        FiveguardClient.ESP.Initialize()
        print('^2[FIVEGUARD CLIENT]^7 ESP koruması aktif')
    end
    
    if FiveguardClient.Config.freecam and FiveguardClient.Config.freecam.enabled then
        FiveguardClient.Freecam.Initialize()
        print('^2[FIVEGUARD CLIENT]^7 Freecam koruması aktif')
    end
    
    if FiveguardClient.Config.lua_executor and FiveguardClient.Config.lua_executor.enabled then
        FiveguardClient.LuaExecutor.Initialize()
        print('^2[FIVEGUARD CLIENT]^7 Lua Executor koruması aktif')
    end
    
    -- Screenshot modülü
    if FiveguardClient.Config.screenshot and FiveguardClient.Config.screenshot.enabled then
        FiveguardClient.Screenshot.Initialize()
        print('^2[FIVEGUARD CLIENT]^7 Screenshot sistemi aktif')
    end
    
    print('^2[FIVEGUARD CLIENT]^7 Tüm modüller başlatıldı')
end

-- Event'leri kaydet
function FiveguardClient.RegisterEvents()
    print('^2[FIVEGUARD CLIENT]^7 Event'ler kaydediliyor...')
    
    -- Sunucu event'leri
    RegisterNetEvent(Shared.Events.Server.PLAYER_BANNED)
    AddEventHandler(Shared.Events.Server.PLAYER_BANNED, FiveguardClient.OnPlayerBanned)
    
    RegisterNetEvent(Shared.Events.Server.PLAYER_KICKED)
    AddEventHandler(Shared.Events.Server.PLAYER_KICKED, FiveguardClient.OnPlayerKicked)
    
    RegisterNetEvent(Shared.Events.Server.PLAYER_WARNED)
    AddEventHandler(Shared.Events.Server.PLAYER_WARNED, FiveguardClient.OnPlayerWarned)
    
    RegisterNetEvent(Shared.Events.Server.TAKE_SCREENSHOT)
    AddEventHandler(Shared.Events.Server.TAKE_SCREENSHOT, FiveguardClient.OnTakeScreenshot)
    
    RegisterNetEvent(Shared.Events.Server.UPDATE_CONFIG)
    AddEventHandler(Shared.Events.Server.UPDATE_CONFIG, FiveguardClient.OnUpdateConfig)
    
    RegisterNetEvent(Shared.Events.Server.SHOW_NOTIFICATION)
    AddEventHandler(Shared.Events.Server.SHOW_NOTIFICATION, FiveguardClient.OnShowNotification)
    
    print('^2[FIVEGUARD CLIENT]^7 Event'ler kaydedildi')
end

-- =============================================
-- ANA DÖNGÜ VE GÜNCELLEMELER
-- =============================================

-- Ana döngüyü başlat
function FiveguardClient.StartMainLoop()
    CreateThread(function()
        while FiveguardClient.IsActive do
            Wait(100) -- 100ms döngü
            
            -- Oyuncu verilerini güncelle
            FiveguardClient.UpdatePlayerData()
            
            -- Davranış verilerini topla
            FiveguardClient.CollectBehaviorData()
            
            -- Performans optimizasyonu
            if GetGameTimer() % 1000 == 0 then -- Her saniye
                FiveguardClient.PerformanceCheck()
            end
        end
    end)
end

-- Oyuncu verilerini güncelle
function FiveguardClient.UpdatePlayerData()
    local playerPed = PlayerPedId()
    local currentTime = GetGameTimer()
    
    -- Pozisyon güncelle
    FiveguardClient.PlayerData.lastPosition = FiveguardClient.PlayerData.position
    FiveguardClient.PlayerData.position = GetEntityCoords(playerPed)
    
    -- Hız güncelle
    FiveguardClient.PlayerData.lastVelocity = FiveguardClient.PlayerData.velocity
    FiveguardClient.PlayerData.velocity = GetEntityVelocity(playerPed)
    
    -- Sağlık ve zırh güncelle
    FiveguardClient.PlayerData.lastHealth = FiveguardClient.PlayerData.health
    FiveguardClient.PlayerData.lastArmor = FiveguardClient.PlayerData.armor
    FiveguardClient.PlayerData.health = GetEntityHealth(playerPed)
    FiveguardClient.PlayerData.armor = GetPedArmour(playerPed)
    
    -- Araç durumu güncelle
    FiveguardClient.PlayerData.lastVehicle = FiveguardClient.PlayerData.vehicle
    FiveguardClient.PlayerData.isInVehicle = IsPedInAnyVehicle(playerPed, false)
    if FiveguardClient.PlayerData.isInVehicle then
        FiveguardClient.PlayerData.vehicle = GetVehiclePedIsIn(playerPed, false)
    else
        FiveguardClient.PlayerData.vehicle = nil
    end
    
    -- Silah durumu güncelle
    FiveguardClient.PlayerData.lastWeapon = FiveguardClient.PlayerData.currentWeapon
    local hasWeapon, weaponHash = GetCurrentPedWeapon(playerPed, true)
    if hasWeapon then
        FiveguardClient.PlayerData.currentWeapon = weaponHash
        FiveguardClient.PlayerData.weaponAmmo = GetAmmoInPedWeapon(playerPed, weaponHash)
    else
        FiveguardClient.PlayerData.currentWeapon = nil
        FiveguardClient.PlayerData.weaponAmmo = 0
    end
    
    -- Durum bayrakları güncelle
    FiveguardClient.PlayerData.isAiming = IsPlayerFreeAiming(FiveguardClient.PlayerData.playerId)
    FiveguardClient.PlayerData.isShooting = IsPedShooting(playerPed)
    FiveguardClient.PlayerData.isMoving = IsPedWalking(playerPed) or IsPedRunning(playerPed) or IsPedSprinting(playerPed)
    FiveguardClient.PlayerData.isDead = IsEntityDead(playerPed)
    
    -- Nişan alma zamanını takip et
    if FiveguardClient.PlayerData.isAiming and FiveguardClient.PlayerData.lastAimStart == 0 then
        FiveguardClient.PlayerData.lastAimStart = currentTime
    elseif not FiveguardClient.PlayerData.isAiming and FiveguardClient.PlayerData.lastAimStart > 0 then
        local aimDuration = currentTime - FiveguardClient.PlayerData.lastAimStart
        FiveguardClient.PlayerData.behaviorData.aimingTime = FiveguardClient.PlayerData.behaviorData.aimingTime + aimDuration
        FiveguardClient.PlayerData.lastAimStart = 0
    end
    
    FiveguardClient.PlayerData.lastUpdate = currentTime
end

-- Davranış verilerini topla
function FiveguardClient.CollectBehaviorData()
    local currentTime = GetGameTimer()
    
    -- Hareket kalıplarını kaydet
    if FiveguardClient.PlayerData.isMoving then
        local movementData = {
            position = FiveguardClient.PlayerData.position,
            velocity = FiveguardClient.PlayerData.velocity,
            timestamp = currentTime
        }
        
        table.insert(FiveguardClient.PlayerData.behaviorData.movementPattern, movementData)
        
        -- Eski verileri temizle (son 30 saniye)
        local cutoffTime = currentTime - 30000
        for i = #FiveguardClient.PlayerData.behaviorData.movementPattern, 1, -1 do
            if FiveguardClient.PlayerData.behaviorData.movementPattern[i].timestamp < cutoffTime then
                table.remove(FiveguardClient.PlayerData.behaviorData.movementPattern, i)
            end
        end
    end
    
    -- Atış verilerini kaydet
    if FiveguardClient.PlayerData.isShooting then
        FiveguardClient.PlayerData.behaviorData.shotsFired = FiveguardClient.PlayerData.behaviorData.shotsFired + 1
        
        -- Hedef kontrolü (basit)
        local hit = false
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local forwardVector = GetEntityForwardVector(playerPed)
        local endCoords = coords + forwardVector * 100.0
        
        local raycast = StartShapeTestRay(coords.x, coords.y, coords.z, endCoords.x, endCoords.y, endCoords.z, -1, playerPed, 0)
        local _, hit, _, _, entityHit = GetShapeTestResult(raycast)
        
        if hit and entityHit and IsPedAHuman(entityHit) then
            FiveguardClient.PlayerData.behaviorData.shotsHit = FiveguardClient.PlayerData.behaviorData.shotsHit + 1
        end
        
        -- İsabet oranını hesapla
        if FiveguardClient.PlayerData.behaviorData.shotsFired > 0 then
            FiveguardClient.PlayerData.behaviorData.accuracy = 
                (FiveguardClient.PlayerData.behaviorData.shotsHit / FiveguardClient.PlayerData.behaviorData.shotsFired) * 100
        end
    end
end

-- =============================================
-- HEARTBEAT SİSTEMİ
-- =============================================

-- Heartbeat başlat
function FiveguardClient.StartHeartbeat()
    CreateThread(function()
        while FiveguardClient.IsActive do
            Wait(30000) -- 30 saniye
            FiveguardClient.SendHeartbeat()
        end
    end)
end

-- Heartbeat gönder
function FiveguardClient.SendHeartbeat()
    local heartbeatData = {
        position = FiveguardClient.PlayerData.position,
        velocity = FiveguardClient.PlayerData.velocity,
        health = FiveguardClient.PlayerData.health,
        armor = FiveguardClient.PlayerData.armor,
        vehicle = FiveguardClient.PlayerData.vehicle,
        weapon = FiveguardClient.PlayerData.currentWeapon,
        timestamp = GetGameTimer()
    }
    
    TriggerServerEvent(Shared.Events.Client.HEARTBEAT, heartbeatData)
    FiveguardClient.LastHeartbeat = GetGameTimer()
end

-- =============================================
-- EVENT HANDLERs
-- =============================================

-- Oyuncu ban edildiğinde
function FiveguardClient.OnPlayerBanned(banData)
    print('^1[FIVEGUARD CLIENT]^7 Sunucudan yasaklandınız!')
    print('^1[FIVEGUARD CLIENT]^7 Sebep: ' .. (banData.reason or 'Belirtilmemiş'))
    
    -- UI bildirimi göster
    FiveguardClient.ShowNotification('Sunucudan yasaklandınız!\nSebep: ' .. (banData.reason or 'Belirtilmemiş'), 'error')
end

-- Oyuncu kick edildiğinde
function FiveguardClient.OnPlayerKicked(kickData)
    print('^3[FIVEGUARD CLIENT]^7 Sunucudan atıldınız!')
    print('^3[FIVEGUARD CLIENT]^7 Sebep: ' .. (kickData.reason or 'Belirtilmemiş'))
    
    -- UI bildirimi göster
    FiveguardClient.ShowNotification('Sunucudan atıldınız!\nSebep: ' .. (kickData.reason or 'Belirtilmemiş'), 'warning')
end

-- Oyuncu uyarı aldığında
function FiveguardClient.OnPlayerWarned(warningData)
    print('^3[FIVEGUARD CLIENT]^7 Uyarı aldınız!')
    print('^3[FIVEGUARD CLIENT]^7 Sebep: ' .. (warningData.reason or 'Belirtilmemiş'))
    
    -- UI bildirimi göster
    FiveguardClient.ShowNotification('Uyarı!\n' .. (warningData.reason or 'Belirtilmemiş'), 'warning')
end

-- Screenshot talebi geldiğinde
function FiveguardClient.OnTakeScreenshot(data)
    if FiveguardClient.Screenshot then
        FiveguardClient.Screenshot.Take(data)
    end
end

-- Konfigürasyon güncellendiğinde
function FiveguardClient.OnUpdateConfig(newConfig)
    print('^2[FIVEGUARD CLIENT]^7 Konfigürasyon güncellendi')
    
    -- Konfigürasyonu birleştir
    for key, value in pairs(newConfig) do
        FiveguardClient.Config[key] = value
    end
    
    -- Modülleri yeniden başlat (gerekirse)
    if newConfig.restart_modules then
        FiveguardClient.RestartModules()
    end
end

-- Bildirim göster talebi geldiğinde
function FiveguardClient.OnShowNotification(data)
    FiveguardClient.ShowNotification(data.message, data.type or 'info')
end

-- =============================================
-- TESPİT FONKSİYONLARI
-- =============================================

-- Tespit tetikle
function FiveguardClient.TriggerDetection(detectionType, confidence, evidence, description)
    -- Tespit verilerini hazırla
    local detectionData = {
        type = detectionType,
        confidence = confidence or 100,
        evidence = evidence or {},
        description = description or '',
        timestamp = GetGameTimer(),
        playerData = {
            position = FiveguardClient.PlayerData.position,
            velocity = FiveguardClient.PlayerData.velocity,
            health = FiveguardClient.PlayerData.health,
            armor = FiveguardClient.PlayerData.armor,
            vehicle = FiveguardClient.PlayerData.vehicle,
            weapon = FiveguardClient.PlayerData.currentWeapon
        }
    }
    
    -- Sunucuya gönder
    TriggerServerEvent(Shared.Events.Client.DETECTION_TRIGGERED, detectionData)
    
    -- Local kayıt
    table.insert(FiveguardClient.Detections, detectionData)
    
    -- Debug mesajı
    if FiveguardClient.Config.debug then
        print('^3[FIVEGUARD CLIENT]^7 Tespit: ' .. detectionType .. ' (Güven: ' .. confidence .. '%)')
    end
end

-- Davranış verilerini gönder
function FiveguardClient.SendBehaviorData()
    local behaviorData = {
        accuracy = FiveguardClient.PlayerData.behaviorData.accuracy,
        shotsFired = FiveguardClient.PlayerData.behaviorData.shotsFired,
        shotsHit = FiveguardClient.PlayerData.behaviorData.shotsHit,
        aimingTime = FiveguardClient.PlayerData.behaviorData.aimingTime,
        movementPatternCount = #FiveguardClient.PlayerData.behaviorData.movementPattern,
        reactionTimes = FiveguardClient.PlayerData.behaviorData.reactionTimes,
        timestamp = GetGameTimer()
    }
    
    TriggerServerEvent(Shared.Events.Client.BEHAVIOR_DATA, behaviorData)
end

-- =============================================
-- UI VE BİLDİRİMLER
-- =============================================

-- Bildirim göster
function FiveguardClient.ShowNotification(message, type)
    type = type or 'info'
    
    -- FiveM native notification
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
    
    -- Console'a da yazdır
    local color = '^7'
    if type == 'error' then
        color = '^1'
    elseif type == 'warning' then
        color = '^3'
    elseif type == 'success' then
        color = '^2'
    end
    
    print(color .. '[FIVEGUARD]^7 ' .. message)
end

-- =============================================
-- PERFORMANS VE OPTİMİZASYON
-- =============================================

-- Performans kontrolü
function FiveguardClient.PerformanceCheck()
    -- Memory kullanımını kontrol et
    local memoryUsage = collectgarbage('count')
    if memoryUsage > 50000 then -- 50MB üzeri
        collectgarbage('collect')
        
        if FiveguardClient.Config.debug then
            print('^3[FIVEGUARD CLIENT]^7 Garbage collection yapıldı (Memory: ' .. math.floor(memoryUsage) .. 'KB)')
        end
    end
    
    -- Eski tespit verilerini temizle
    local currentTime = GetGameTimer()
    local cutoffTime = currentTime - 300000 -- 5 dakika
    
    for i = #FiveguardClient.Detections, 1, -1 do
        if FiveguardClient.Detections[i].timestamp < cutoffTime then
            table.remove(FiveguardClient.Detections, i)
        end
    end
end

-- Modülleri yeniden başlat
function FiveguardClient.RestartModules()
    print('^3[FIVEGUARD CLIENT]^7 Modüller yeniden başlatılıyor...')
    
    -- Mevcut modülleri durdur
    FiveguardClient.StopModules()
    
    -- Yeniden başlat
    Wait(1000)
    FiveguardClient.StartModules()
    
    print('^2[FIVEGUARD CLIENT]^7 Modüller yeniden başlatıldı')
end

-- Modülleri durdur
function FiveguardClient.StopModules()
    -- Her modülün Stop fonksiyonunu çağır
    if FiveguardClient.GodMode and FiveguardClient.GodMode.Stop then
        FiveguardClient.GodMode.Stop()
    end
    
    if FiveguardClient.SpeedHack and FiveguardClient.SpeedHack.Stop then
        FiveguardClient.SpeedHack.Stop()
    end
    
    -- Diğer modüller için de aynı şekilde...
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- Screenshot al
function TakeScreenshot(quality, callback)
    if FiveguardClient.Screenshot then
        return FiveguardClient.Screenshot.Take({quality = quality}, callback)
    end
    return false
end

-- Davranış verilerini getir
function GetPlayerBehaviorData()
    return FiveguardClient.PlayerData.behaviorData
end

-- Menü açık mı kontrol et
function IsMenuOpen()
    -- Bu fonksiyon çeşitli menü sistemlerini kontrol edebilir
    return false -- Placeholder
end

-- =============================================
-- SİSTEM BAŞLATMA
-- =============================================

-- Oyuncu spawn olduğunda başlat
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end
    
    -- Kısa bir bekleme
    Wait(2000)
    
    -- Sistemi başlat
    FiveguardClient.Initialize()
end)

-- Resource durduğunda temizlik yap
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        FiveguardClient.IsActive = false
        FiveguardClient.StopModules()
        print('^3[FIVEGUARD CLIENT]^7 İstemci durduruldu')
    end
end)

print('^2[FIVEGUARD CLIENT]^7 Ana istemci dosyası yüklendi')
