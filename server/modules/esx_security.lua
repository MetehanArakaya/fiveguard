-- FIVEGUARD ESX SECURITY MODULE
-- ESX-specific exploit koruması ve güvenlik sistemi

FiveguardServer.ESXSecurity = {}

-- =============================================
-- ESX SECURITY DEĞİŞKENLERİ
-- =============================================

local esxData = {
    isActive = false,
    eventSpam = {},
    billingExploits = {},
    sqlInjections = {},
    negativePayEvents = {},
    suspiciousActivities = {},
    config = {
        enableEventSpamProtection = true,
        enableBillingProtection = true,
        enableSqlInjectionProtection = true,
        enableNegativePayProtection = true,
        eventSpamThreshold = 10,
        eventSpamTimeWindow = 5000, -- 5 saniye
        billingAmountLimit = 1000000, -- 1M limit
        autoActionEnabled = true,
        whitelistedEvents = {}
    },
    stats = {
        totalBlocked = 0,
        eventSpamBlocked = 0,
        billingExploitsBlocked = 0,
        sqlInjectionsBlocked = 0,
        negativePayBlocked = 0,
        lastDetection = 0
    }
}

-- ESX Event Spam Blacklist (AntiCheese'den alınan)
local spammedEvents = {
    "esx_pilot:success",
    "esx_taxijob:success",
    "esx_mugging:giveMoney",
    "paycheck:salary",
    "esx_godirtyjob:pay",
    "esx_pizza:pay",
    "esx_slotmachine:sv:2",
    "esx_banksecurity:pay",
    "esx_gopostaljob:pay",
    "esx_truckerjob:pay",
    "esx_carthief:pay",
    "esx_garbagejob:pay",
    "esx_ranger:pay",
    "esx_truckersjob:payy",
    "PayForRepairNow",
    "reanimar:pagamento",
    "salario:pagamento",
    "offred:salar",
    "gcPhone:sendMessage",
    "esx_jailer:sendToJail",
    "esx_jailler:sendToJail",
    "esx-qalle-jail:jailPlayer",
    "esx-qalle-jail:jailPlayerNew",
    "esx_jail:sendToJail",
    "8321hiue89js",
    "esx_jailer:sendToJailCatfrajerze",
    "js:jailuser",
    "wyspa_jail:jailPlayer",
    "wyspa_jail:jail",
    "esx_policejob:billPlayer",
    "esx-qalle-jail:updateJailTime",
    "esx-qalle-jail:updateJailTime_n96nDDU@X?@zpf8",
    "::{korioz#0110}::jobs_civil:pay",
    "esx_drugs:startHarvestOpium",
    "esx_drugs:startTransformOpium",
    "esx_drugs:startSellOpium",
    "esx_drugs:startHarvestWeed",
    "esx_drugs:startTransformWeed",
    "esx_drugs:startSellWeed",
    "::{korioz#0110}::esx_billing:sendBill",
    "esx_billing:sendBill",
    "esx_mechanicjob:startHarvest",
    "esx_mechanicjob:startHarvest2",
    "esx_mechanicjob:startHarvest3",
    "esx_mechanicjob:startHarvest4",
    "esx_mechanicjob:startCraft",
    "esx_mechanicjob:startCraft2",
    "esx_mechanicjob:startCraft3",
    "esx_bitcoin:startHarvestKoda",
    "esx_bitcoin:startSellKoda",
    "esx_blanchisseur:startWhitening",
    "trip_adminmenu:addMoney",
    "esx_reprogjob:onNPCJobMissionCompleted",
    "esx_ambulancejob:revive",
    "Impulsionjobs_civil:pay",
    "SEM_InteractionMenu:CuffNear",
    "esx_fueldelivery:pay",
    "AdminMenu:giveBank",
    "AdminMenu:giveCash",
    "esx-qalle-hunting:reward",
    "esx-qalle-hunting:sell",
    "esx_vangelico_robbery:gioielli1",
    "lester:vendita",
    "houseRobberies:giveMoney",
    "lh-bankrobbery:server:recieveItem",
    "esx_uber:pay",
    "99kr-burglary:Add",
    "99kr-shops:Cashier",
    "esx-ecobottles:retrieveBottle",
    "loffe_carthief:questFinished",
    "loffe_fishing:caught",
    "esx_loffe_fangelse:Pay",
    "loffe_robbery:pickUp",
    "hospital:client:Revive",
    "cylex:startSellSarap",
    "cylex:startTransformSarap",
    "cylex:startHarvestSarap",
    "cylex:startSellMelon",
    "cylex:startTransformMelon",
    "cylex:startHarvestMelon",
    "sp_admin:menuv",
    "sp_admin:giveCash",
    "sp_admin:giveDirtyMoney",
    "sp_admin:giveCash"
}

-- Jailer Events (AntiCheese'den alınan)
local jailerEvents = {
    "esx_jailer:sendToJail",
    "esx_jailler:sendToJail",
    "esx-qalle-jail:jailPlayer",
    "esx-qalle-jail:jailPlayerNew",
    "esx_jail:sendToJail",
    "esx_jailer:sendToJailCatfrajerze",
    "js:jailuser",
    "wyspa_jail:jailPlayer",
    "wyspa_jail:jail",
    "esx-qalle-jail:updateJailTime",
    "esx-qalle-jail:updateJailTime_n96nDDU@X?@zpf8"
}

-- Negative Pay Events (AntiCheese'den alınan)
local negativePayEvents = {
    "neweden_garage:pay",
    "projektsantos:mandathajs",
    "esx_dmvschool:pay"
}

-- Malicious Billing Text (AntiCheese'den alınan)
local maliciousBillings = {
    "Absolute Menu",
    "d0pamine.xyz",
    "d0pamine_xyz",
    "discord.gg/fjBp55t",
    "RocMenu",
    "Blood-X Menu",
    "Brutan#7799",
    "BRUTAN menu",
    "Lynx10",
    "lynxmenu",
    "Nertigel#5391",
    "Kolorek#1396",
    "https://discord.gg/rMFtEFK",
    "https://discord.gg/kgUtDrC",
    "You've been sent to jail by Cat and Flacko",
    "https://discord.gg/DAhzN6q",
    "Melon#1379",
    "Desudo Executor",
    "ahezu#6666",
    "HamMafia on YOUTUBE",
    "Skrobek on YOUTUBE",
    "https://discord.gg/yJb3qKG",
    "ZAPRASZAM NA KANAŁ THEULAN",
    "https://discord.gg/BEcQrjC"
}

-- SQL Injection Patterns
local sqlInjectionPatterns = {
    "' OR '1'='1",
    "' OR 1=1--",
    "' UNION SELECT",
    "'; DROP TABLE",
    "'; DELETE FROM",
    "'; INSERT INTO",
    "'; UPDATE SET",
    "' AND 1=1--",
    "' AND '1'='1",
    "%27 OR %271%27=%271",
    "admin'--",
    "admin' #",
    "admin'/*",
    "' or 1=1#",
    "' or 1=1--",
    "') or '1'='1--",
    "') or ('1'='1--",
    "1' or '1'='1",
    "1' or '1'='1'--",
    "1' or '1'='1'#",
    "1' or '1'='1'/*",
    "1) or (1=1",
    "1) or (1=1)--",
    "1) or (1=1)#",
    "1) or (1=1)/*",
    "1 or 1=1",
    "1 or 1=1--",
    "1 or 1=1#",
    "1 or 1=1/*",
    "') or 1=1 or ('1'='1",
    "') or 1=1 or ('1'='1'--",
    "') or 1=1 or ('1'='1'#",
    "') or 1=1 or ('1'='1'/*"
}

-- =============================================
-- ESX SECURITY BAŞLATMA
-- =============================================

function FiveguardServer.ESXSecurity.Initialize()
    print('^2[FIVEGUARD ESX SECURITY]^7 ESX Security Module başlatılıyor...')
    
    -- Konfigürasyonu yükle
    FiveguardServer.ESXSecurity.LoadConfig()
    
    -- Event'leri kaydet
    FiveguardServer.ESXSecurity.RegisterEvents()
    
    -- Event spam protection'ı başlat
    FiveguardServer.ESXSecurity.StartEventSpamProtection()
    
    -- Monitoring thread'ini başlat
    FiveguardServer.ESXSecurity.StartMonitoring()
    
    esxData.isActive = true
    print('^2[FIVEGUARD ESX SECURITY]^7 ESX Security Module hazır')
end

-- Konfigürasyonu yükle
function FiveguardServer.ESXSecurity.LoadConfig()
    local config = FiveguardServer.Config.Modules.ESXSecurity or {}
    
    -- Ana ayarları yükle
    esxData.config.enabled = config.enabled ~= nil and config.enabled or esxData.config.enabled
    
    -- Protection types'ları yükle
    if config.protectionTypes then
        for key, value in pairs(config.protectionTypes) do
            if esxData.config[key] ~= nil then
                esxData.config[key] = value
            end
        end
    end
    
    -- Event spam ayarlarını yükle
    if config.eventSpam then
        esxData.config.eventSpamThreshold = config.eventSpam.eventSpamThreshold or esxData.config.eventSpamThreshold
        esxData.config.eventSpamTimeWindow = config.eventSpam.eventSpamTimeWindow or esxData.config.eventSpamTimeWindow
        if config.eventSpam.whitelistedEvents then
            esxData.config.whitelistedEvents = config.eventSpam.whitelistedEvents
        end
    end
    
    -- Billing ayarlarını yükle
    if config.billing then
        esxData.config.billingAmountLimit = config.billing.billingAmountLimit or esxData.config.billingAmountLimit
        esxData.config.enableMaliciousTextDetection = config.billing.enableMaliciousTextDetection ~= nil and config.billing.enableMaliciousTextDetection or esxData.config.enableMaliciousTextDetection
    end
    
    -- SQL injection ayarlarını yükle
    if config.sqlInjection then
        esxData.config.enablePatternDetection = config.sqlInjection.enablePatternDetection ~= nil and config.sqlInjection.enablePatternDetection or esxData.config.enablePatternDetection
        esxData.config.logAllAttempts = config.sqlInjection.logAllAttempts ~= nil and config.sqlInjection.logAllAttempts or esxData.config.logAllAttempts
    end
    
    -- Auto actions ayarlarını yükle
    if config.autoActions then
        esxData.config.autoActionEnabled = config.autoActions.autoActionEnabled ~= nil and config.autoActions.autoActionEnabled or esxData.config.autoActionEnabled
        esxData.config.banDuration = config.autoActions.banDuration or esxData.config.banDuration
    end
    
    print('^2[FIVEGUARD ESX SECURITY]^7 Config yüklendi - Enabled: ' .. tostring(esxData.config.enabled))
end

-- Event'leri kaydet
function FiveguardServer.ESXSecurity.RegisterEvents()
    -- ESX billing protection
    RegisterNetEvent('esx_billing:sendBill')
    AddEventHandler('esx_billing:sendBill', function(targetId, sharedAccountName, label, amount)
        local playerId = source
        if not FiveguardServer.ESXSecurity.ValidateBilling(playerId, targetId, label, amount) then
            CancelEvent()
        end
    end)
    
    -- ESX callback protection
    RegisterNetEvent('esx:triggerServerCallback')
    AddEventHandler('esx:triggerServerCallback', function(name, requestId, ...)
        local playerId = source
        if not FiveguardServer.ESXSecurity.ValidateCallback(playerId, name, {...}) then
            CancelEvent()
        end
    end)
    
    -- Generic ESX event protection
    for _, eventName in ipairs(spammedEvents) do
        RegisterNetEvent(eventName)
        AddEventHandler(eventName, function(...)
            local playerId = source
            if not FiveguardServer.ESXSecurity.ValidateEvent(playerId, eventName, {...}) then
                CancelEvent()
            end
        end)
    end
    
    -- Jailer event protection
    for _, eventName in ipairs(jailerEvents) do
        RegisterNetEvent(eventName)
        AddEventHandler(eventName, function(...)
            local playerId = source
            if not FiveguardServer.ESXSecurity.ValidateJailerEvent(playerId, eventName, {...}) then
                CancelEvent()
            end
        end)
    end
end

-- =============================================
-- EVENT SPAM PROTECTION
-- =============================================

-- Event spam protection'ı başlat
function FiveguardServer.ESXSecurity.StartEventSpamProtection()
    if not esxData.config.enableEventSpamProtection then
        return
    end
    
    CreateThread(function()
        while esxData.isActive do
            Wait(esxData.config.eventSpamTimeWindow)
            
            -- Event spam verilerini temizle
            FiveguardServer.ESXSecurity.CleanupEventSpamData()
        end
    end)
end

-- Event'i validate et
function FiveguardServer.ESXSecurity.ValidateEvent(playerId, eventName, parameters)
    local player = FiveguardServer.Players[playerId]
    if not player then return false end
    
    -- Whitelist kontrolü
    if esxData.config.whitelistedEvents[eventName] then
        return true
    end
    
    -- Event spam kontrolü
    if not FiveguardServer.ESXSecurity.CheckEventSpam(playerId, eventName) then
        return false
    end
    
    -- Negative pay kontrolü
    if FiveguardServer.ESXSecurity.IsNegativePayEvent(eventName, parameters) then
        return false
    end
    
    -- SQL injection kontrolü
    if FiveguardServer.ESXSecurity.CheckSqlInjection(parameters) then
        return false
    end
    
    return true
end

-- Event spam kontrolü
function FiveguardServer.ESXSecurity.CheckEventSpam(playerId, eventName)
    local currentTime = GetGameTimer()
    
    -- Player'ın event geçmişini al
    if not esxData.eventSpam[playerId] then
        esxData.eventSpam[playerId] = {}
    end
    
    if not esxData.eventSpam[playerId][eventName] then
        esxData.eventSpam[playerId][eventName] = {}
    end
    
    local eventHistory = esxData.eventSpam[playerId][eventName]
    
    -- Son event'leri say
    local recentEvents = 0
    for _, timestamp in ipairs(eventHistory) do
        if (currentTime - timestamp) <= esxData.config.eventSpamTimeWindow then
            recentEvents = recentEvents + 1
        end
    end
    
    -- Threshold kontrolü
    if recentEvents >= esxData.config.eventSpamThreshold then
        -- Event spam tespit edildi
        FiveguardServer.ESXSecurity.HandleEventSpam(playerId, eventName, recentEvents)
        return false
    end
    
    -- Event'i kaydet
    table.insert(eventHistory, currentTime)
    
    return true
end

-- Event spam'i işle
function FiveguardServer.ESXSecurity.HandleEventSpam(playerId, eventName, eventCount)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'event_spam',
        eventName = eventName,
        eventCount = eventCount,
        threshold = esxData.config.eventSpamThreshold,
        timestamp = os.time(),
        severity = 'high'
    }
    
    -- İstatistikleri güncelle
    esxData.stats.totalBlocked = esxData.stats.totalBlocked + 1
    esxData.stats.eventSpamBlocked = esxData.stats.eventSpamBlocked + 1
    esxData.stats.lastDetection = os.time()
    
    -- Detection'ı işle
    FiveguardServer.ESXSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD ESX SECURITY]^7 Event spam tespit edildi: ' .. player.name .. 
          ' (' .. eventName .. ' - ' .. eventCount .. ' kez)')
end

-- Event spam verilerini temizle
function FiveguardServer.ESXSecurity.CleanupEventSpamData()
    local currentTime = GetGameTimer()
    local cleanupThreshold = esxData.config.eventSpamTimeWindow * 2
    
    for playerId, playerEvents in pairs(esxData.eventSpam) do
        for eventName, eventHistory in pairs(playerEvents) do
            local filteredHistory = {}
            for _, timestamp in ipairs(eventHistory) do
                if (currentTime - timestamp) <= cleanupThreshold then
                    table.insert(filteredHistory, timestamp)
                end
            end
            esxData.eventSpam[playerId][eventName] = filteredHistory
        end
    end
end

-- =============================================
-- BILLING PROTECTION
-- =============================================

-- Billing'i validate et
function FiveguardServer.ESXSecurity.ValidateBilling(playerId, targetId, label, amount)
    local player = FiveguardServer.Players[playerId]
    if not player then return false end
    
    -- Amount kontrolü
    if amount and (amount > esxData.config.billingAmountLimit or amount < 0) then
        FiveguardServer.ESXSecurity.HandleBillingExploit(playerId, 'invalid_amount', {
            amount = amount,
            limit = esxData.config.billingAmountLimit
        })
        return false
    end
    
    -- Malicious text kontrolü
    if label and FiveguardServer.ESXSecurity.CheckMaliciousBilling(label) then
        FiveguardServer.ESXSecurity.HandleBillingExploit(playerId, 'malicious_text', {
            label = label
        })
        return false
    end
    
    return true
end

-- Malicious billing kontrolü
function FiveguardServer.ESXSecurity.CheckMaliciousBilling(text)
    local lowerText = string.lower(text)
    
    for _, maliciousText in ipairs(maliciousBillings) do
        if string.find(lowerText, string.lower(maliciousText)) then
            return true
        end
    end
    
    return false
end

-- Billing exploit'ini işle
function FiveguardServer.ESXSecurity.HandleBillingExploit(playerId, exploitType, details)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'billing_exploit',
        exploitType = exploitType,
        details = details,
        timestamp = os.time(),
        severity = 'high'
    }
    
    -- İstatistikleri güncelle
    esxData.stats.totalBlocked = esxData.stats.totalBlocked + 1
    esxData.stats.billingExploitsBlocked = esxData.stats.billingExploitsBlocked + 1
    esxData.stats.lastDetection = os.time()
    
    -- Detection'ı işle
    FiveguardServer.ESXSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD ESX SECURITY]^7 Billing exploit tespit edildi: ' .. player.name .. 
          ' (' .. exploitType .. ')')
end

-- =============================================
-- SQL INJECTION PROTECTION
-- =============================================

-- SQL injection kontrolü
function FiveguardServer.ESXSecurity.CheckSqlInjection(parameters)
    if not esxData.config.enableSqlInjectionProtection then
        return false
    end
    
    for _, param in ipairs(parameters) do
        if type(param) == 'string' then
            local lowerParam = string.lower(param)
            
            for _, pattern in ipairs(sqlInjectionPatterns) do
                if string.find(lowerParam, string.lower(pattern)) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- SQL injection'ı işle
function FiveguardServer.ESXSecurity.HandleSqlInjection(playerId, injectionPattern, parameters)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'sql_injection',
        pattern = injectionPattern,
        parameters = parameters,
        timestamp = os.time(),
        severity = 'critical'
    }
    
    -- İstatistikleri güncelle
    esxData.stats.totalBlocked = esxData.stats.totalBlocked + 1
    esxData.stats.sqlInjectionsBlocked = esxData.stats.sqlInjectionsBlocked + 1
    esxData.stats.lastDetection = os.time()
    
    -- Detection'ı işle
    FiveguardServer.ESXSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD ESX SECURITY]^7 SQL injection tespit edildi: ' .. player.name .. 
          ' (' .. injectionPattern .. ')')
end

-- =============================================
-- NEGATIVE PAY PROTECTION
-- =============================================

-- Negative pay event kontrolü
function FiveguardServer.ESXSecurity.IsNegativePayEvent(eventName, parameters)
    if not esxData.config.enableNegativePayProtection then
        return false
    end
    
    -- Event negative pay listesinde mi?
    for _, negativeEvent in ipairs(negativePayEvents) do
        if eventName == negativeEvent then
            -- Amount parametresini bul
            for _, param in ipairs(parameters) do
                if type(param) == 'number' and param < 0 then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Negative pay'i işle
function FiveguardServer.ESXSecurity.HandleNegativePay(playerId, eventName, amount)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'negative_pay',
        eventName = eventName,
        amount = amount,
        timestamp = os.time(),
        severity = 'high'
    }
    
    -- İstatistikleri güncelle
    esxData.stats.totalBlocked = esxData.stats.totalBlocked + 1
    esxData.stats.negativePayBlocked = esxData.stats.negativePayBlocked + 1
    esxData.stats.lastDetection = os.time()
    
    -- Detection'ı işle
    FiveguardServer.ESXSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD ESX SECURITY]^7 Negative pay tespit edildi: ' .. player.name .. 
          ' (' .. eventName .. ' - ' .. amount .. ')')
end

-- =============================================
-- CALLBACK PROTECTION
-- =============================================

-- Callback'i validate et
function FiveguardServer.ESXSecurity.ValidateCallback(playerId, callbackName, parameters)
    local player = FiveguardServer.Players[playerId]
    if not player then return false end
    
    -- SQL injection kontrolü
    if FiveguardServer.ESXSecurity.CheckSqlInjection(parameters) then
        FiveguardServer.ESXSecurity.HandleSqlInjection(playerId, 'callback_injection', parameters)
        return false
    end
    
    -- Malicious callback kontrolü
    if FiveguardServer.ESXSecurity.CheckMaliciousCallback(callbackName) then
        FiveguardServer.ESXSecurity.HandleMaliciousCallback(playerId, callbackName)
        return false
    end
    
    return true
end

-- Malicious callback kontrolü
function FiveguardServer.ESXSecurity.CheckMaliciousCallback(callbackName)
    local maliciousCallbacks = {
        'esx:getSharedObject',
        'esx:triggerServerCallback',
        'esx_license:getLicenses',
        'esx_kashacter:getCharacters'
    }
    
    for _, maliciousCallback in ipairs(maliciousCallbacks) do
        if callbackName == maliciousCallback then
            return true
        end
    end
    
    return false
end

-- Malicious callback'i işle
function FiveguardServer.ESXSecurity.HandleMaliciousCallback(playerId, callbackName)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'malicious_callback',
        callbackName = callbackName,
        timestamp = os.time(),
        severity = 'high'
    }
    
    -- Detection'ı işle
    FiveguardServer.ESXSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD ESX SECURITY]^7 Malicious callback tespit edildi: ' .. player.name .. 
          ' (' .. callbackName .. ')')
end

-- =============================================
-- JAILER EVENT PROTECTION
-- =============================================

-- Jailer event'ini validate et
function FiveguardServer.ESXSecurity.ValidateJailerEvent(playerId, eventName, parameters)
    local player = FiveguardServer.Players[playerId]
    if not player then return false end
    
    -- Admin kontrolü
    if not player.isAdmin then
        FiveguardServer.ESXSecurity.HandleJailerExploit(playerId, eventName, 'unauthorized_access')
        return false
    end
    
    -- Mass jail kontrolü
    if FiveguardServer.ESXSecurity.CheckMassJail(playerId, eventName) then
        FiveguardServer.ESXSecurity.HandleJailerExploit(playerId, eventName, 'mass_jail')
        return false
    end
    
    return true
end

-- Mass jail kontrolü
function FiveguardServer.ESXSecurity.CheckMassJail(playerId, eventName)
    local currentTime = GetGameTimer()
    local timeWindow = 10000 -- 10 saniye
    local maxJails = 3 -- 10 saniyede max 3 jail
    
    if not esxData.eventSpam[playerId] then
        esxData.eventSpam[playerId] = {}
    end
    
    if not esxData.eventSpam[playerId][eventName] then
        esxData.eventSpam[playerId][eventName] = {}
    end
    
    local jailHistory = esxData.eventSpam[playerId][eventName]
    
    -- Son jail'leri say
    local recentJails = 0
    for _, timestamp in ipairs(jailHistory) do
        if (currentTime - timestamp) <= timeWindow then
            recentJails = recentJails + 1
        end
    end
    
    if recentJails >= maxJails then
        return true
    end
    
    -- Jail'i kaydet
    table.insert(jailHistory, currentTime)
    
    return false
end

-- Jailer exploit'ini işle
function FiveguardServer.ESXSecurity.HandleJailerExploit(playerId, eventName, exploitType)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    local detection = {
        playerId = playerId,
        playerName = player.name,
        type = 'jailer_exploit',
        eventName = eventName,
        exploitType = exploitType,
        timestamp = os.time(),
        severity = 'critical'
    }
    
    -- Detection'ı işle
    FiveguardServer.ESXSecurity.ProcessDetection(detection)
    
    print('^1[FIVEGUARD ESX SECURITY]^7 Jailer exploit tespit edildi: ' .. player.name .. 
          ' (' .. eventName .. ' - ' .. exploitType .. ')')
end

-- =============================================
-- DETECTION PROCESSING
-- =============================================

-- Detection'ı işle
function FiveguardServer.ESXSecurity.ProcessDetection(detection)
    -- Suspicious activity'lere ekle
    if not esxData.suspiciousActivities[detection.playerId] then
        esxData.suspiciousActivities[detection.playerId] = {}
    end
    
    table.insert(esxData.suspiciousActivities[detection.playerId], detection)
    
    -- Severity'ye göre işlem yap
    FiveguardServer.ESXSecurity.HandleDetectionSeverity(detection)
    
    -- Veritabanına kaydet
    FiveguardServer.ESXSecurity.SaveDetectionToDatabase(detection)
    
    -- Webhook gönder
    FiveguardServer.ESXSecurity.SendDetectionWebhook(detection)
    
    -- Protection Manager'a bildir
    if FiveguardServer.ProtectionManager then
        FiveguardServer.ProtectionManager.RecordDetection('esx_security', {
            type = detection.type,
            severity = detection.severity,
            playerId = detection.playerId,
            timestamp = detection.timestamp
        })
    end
end

-- Detection severity'sini işle
function FiveguardServer.ESXSecurity.HandleDetectionSeverity(detection)
    if not esxData.config.autoActionEnabled then
        return
    end
    
    local playerId = detection.playerId
    
    if detection.severity == 'critical' then
        -- Kritik seviye - Anında ban
        FiveguardServer.ESXSecurity.BanPlayer(playerId, 'ESX exploit tespit edildi: ' .. detection.type)
        
    elseif detection.severity == 'high' then
        -- Yüksek seviye - Kick
        FiveguardServer.ESXSecurity.KickPlayer(playerId, 'ESX exploit tespit edildi')
        
    elseif detection.severity == 'medium' then
        -- Orta seviye - Uyarı
        FiveguardServer.ESXSecurity.WarnPlayer(playerId, 'Şüpheli ESX aktivitesi tespit edildi')
    end
end

-- Oyuncuyu banla
function FiveguardServer.ESXSecurity.BanPlayer(playerId, reason)
    local player = FiveguardServer.Players[playerId]
    if not player then return end
    
    -- Ban kaydı
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_bans (player_id, player_name, reason, ban_type, timestamp, expires_at, active) VALUES (?, ?, ?, ?, ?, ?, 1)', {
        playerId,
        player.name,
        reason,
        'esx_security',
        os.time(),
        os.time() + (30 * 24 * 3600) -- 30 gün
    })
    
    -- Oyuncuyu at
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
    
    print('^1[FIVEGUARD ESX SECURITY]^7 Oyuncu banlandı: ' .. player.name .. ' (Sebep: ' .. reason .. ')')
end

-- Oyuncuyu uyar
function FiveguardServer.ESXSecurity.WarnPlayer(playerId, reason)
    TriggerClientEvent('chat:addMessage', playerId, {
        color = {255, 165, 0},
        multiline = true,
        args = {'FIVEGUARD UYARI', reason}
    })
end

-- Oyuncuyu at
function FiveguardServer.ESXSecurity.KickPlayer(playerId, reason)
    DropPlayer(playerId, 'FIVEGUARD: ' .. reason)
end

-- =============================================
-- MONİTORİNG
-- =============================================

-- Monitoring thread'ini başlat
function FiveguardServer.ESXSecurity.StartMonitoring()
    CreateThread(function()
        while esxData.isActive do
            Wait(60000) -- 1 dakika bekle
            
            -- Eski suspicious activity'leri temizle
            FiveguardServer.ESXSecurity.CleanupSuspiciousActivities()
        end
    end)
end

-- Eski suspicious activity'leri temizle
function FiveguardServer.ESXSecurity.CleanupSuspiciousActivities()
    local currentTime = os.time()
    local cleanupThreshold = currentTime - 3600 -- 1 saat önce
    
    for playerId, activities in pairs(esxData.suspiciousActivities) do
        local filteredActivities = {}
        for _, activity in ipairs(activities) do
            if activity.timestamp > cleanupThreshold then
                table.insert(filteredActivities, activity)
            end
        end
        esxData.suspiciousActivities[playerId] = filteredActivities
    end
end

-- =============================================
-- YARDIMCI FONKSİYONLAR
-- =============================================

-- Detection'ı veritabanına kaydet
function FiveguardServer.ESXSecurity.SaveDetectionToDatabase(detection)
    FiveguardServer.Database.Execute('INSERT INTO fiveguard_esx_detections (player_id, player_name, detection_type, detection_data, severity, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
        detection.playerId,
        detection.playerName,
        detection.type,
        json.encode(detection),
        detection.severity,
        detection.timestamp
    })
end

-- Detection webhook'u gönder
function FiveguardServer.ESXSecurity.SendDetectionWebhook(detection)
    local color = 16711680 -- Kırmızı
    if detection.severity == 'high' then
        color = 16776960 -- Sarı
    elseif detection.severity == 'medium' then
        color = 16753920 -- Turuncu
    end
    
    local webhookData = {
        username = 'Fiveguard ESX Security',
        avatar_url = 'https://i.imgur.com/fiveguard-logo.png',
        embeds = {{
            title = '🛡️ ESX Exploit Tespit Edildi!',
            color = color,
            fields = {
                {name = 'Oyuncu', value = detection.playerName, inline = true},
                {name = 'Exploit Türü', value = detection.type, inline = true},
                {name = 'Severity', value = detection.severity, inline = true},
                {name = 'Detaylar', value = FiveguardServer.ESXSecurity.FormatDetectionDetails(detection), inline = false},
                {name = 'Zaman', value = os.date('%Y-%m-%d %H:%M:%S', detection.timestamp), inline = true}
            },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ', detection.timestamp)
        }}
    }
    
    FiveguardServer.Webhook.Send('esx_security', webhookData)
end

-- Detection detaylarını formatla
function FiveguardServer.ESXSecurity.FormatDetectionDetails(detection)
    if detection.type == 'event_spam' then
        return 'Event: ' .. detection.eventName .. ' (' .. detection.eventCount .. ' kez)'
    elseif detection.type == 'billing_exploit' then
        return 'Exploit Type: ' .. detection.exploitType
    elseif detection.type == 'sql_injection' then
        return 'Pattern: ' .. detection.pattern
    elseif detection.type == 'negative_pay' then
        return 'Event: ' .. detection.eventName .. ' (Amount: ' .. detection.amount .. ')'
    elseif detection.type == 'jailer_exploit' then
        return 'Event: ' .. detection.eventName .. ' (' .. detection.exploitType .. ')'
    else
        return 'Bilinmeyen exploit türü'
    end
end

-- İstatistikleri getir
function FiveguardServer.ESXSecurity.GetStats()
    return {
        totalBlocked = esxData.stats.totalBlocked,
        eventSpamBlocked = esxData.stats.eventSpamBlocked,
        billingExploitsBlocked = esxData.stats.billingExploitsBlocked,
        sqlInjectionsBlocked = esxData.stats.sqlInjectionsBlocked,
        negativePayBlocked = esxData.stats.negativePayBlocked,
        lastDetection = esxData.stats.lastDetection,
        isActive = esxData.isActive,
        activeSuspiciousActivities = FiveguardServer.ESXSecurity.GetActiveSuspiciousActivityCount()
    }
end

-- Aktif suspicious activity sayısını getir
function FiveguardServer.ESXSecurity.GetActiveSuspiciousActivityCount()
    local count = 0
    for _, activities in pairs(esxData.suspiciousActivities) do
        count = count + #activities
    end
    return count
end

-- =============================================
-- EXPORT FONKSİYONLARI
-- =============================================

-- ESX security istatistiklerini getir
function GetESXSecurityStats()
    return FiveguardServer.ESXSecurity.GetStats()
end

-- ESX security durumunu kontrol et
function IsESXSecurityActive()
    return esxData.isActive
end

-- Manuel ESX detection ekle
function AddManualESXDetection(playerId, detectionType, details)
    local detection = {
        playerId = playerId,
        playerName = GetPlayerName(playerId) or 'Bilinmeyen',
        type = detectionType,
        details = details,
        timestamp = os.time(),
        severity = 'manual'
    }
    
    FiveguardServer.ESXSecurity.ProcessDetection(detection)
    return true
end

print('^2[FIVEGUARD ESX SECURITY]^7 ESX Security Module modülü yüklendi')
