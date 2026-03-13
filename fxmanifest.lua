fx_version 'cerulean'
game 'gta5'

author 'Fiveguard Team'
description 'AI Destekli FiveM Anti-Cheat Sistemi'
version '1.0.0'

-- Lua 5.4 desteği
lua54 'yes'

-- Sunucu tarafı scriptleri
server_scripts {
    '@mysql-async/lib/MySQL.lua', -- MySQL bağlantısı için
    'config/config.lua',
    'server/core/database.lua',
    'server/core/logger.lua',
    'server/core/webhook.lua',
    'server/core/license.lua',
    'server/modules/anticheat.lua',
    'server/modules/godmode.lua',
    'server/modules/speedhack.lua',
    'server/modules/teleport.lua',
    'server/modules/weapon.lua',
    'server/modules/money.lua',
    'server/modules/chat.lua',
    'server/modules/events.lua',
    'server/modules/ai_integration.lua',
    'server/admin/commands.lua',
    'server/admin/menu.lua',
    'server/main.lua'
}

-- İstemci tarafı scriptleri
client_scripts {
    'config/config.lua',
    'client/core/utils.lua',
    'client/modules/anticheat.lua',
    'client/modules/godmode.lua',
    'client/modules/speedhack.lua',
    'client/modules/noclip.lua',
    'client/modules/aimbot.lua',
    'client/modules/esp.lua',
    'client/modules/freecam.lua',
    'client/modules/lua_executor.lua',
    'client/modules/screenshot.lua',
    'client/admin/menu.lua',
    'client/main.lua'
}

-- Paylaşılan scriptler
shared_scripts {
    'config/shared.lua'
}

-- UI dosyaları
ui_page 'client/html/index.html'

files {
    'client/html/index.html',
    'client/html/css/style.css',
    'client/html/js/script.js',
    'client/html/assets/**/*'
}

-- Bağımlılıklar
dependencies {
    'mysql-async'
}

-- Sunucu exportları
server_exports {
    'GetPlayerTrustScore',
    'BanPlayer',
    'UnbanPlayer',
    'IsPlayerBanned',
    'LogDetection',
    'GetPlayerStats',
    'AddToWhitelist',
    'RemoveFromWhitelist'
}

-- İstemci exportları
client_exports {
    'TakeScreenshot',
    'GetPlayerBehaviorData',
    'IsMenuOpen'
}

-- Provide direktifleri (diğer resourcelar için)
provide 'fiveguard-core'
provide 'anticheat'
