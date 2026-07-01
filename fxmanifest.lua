fx_version 'cerulean'
game 'gta5'

name 'rs-outcomebets'
author 'Reality Sucks RP / William Brito'
description 'NPC-driven underground cage outcome betting show with cashier cash payouts, configurable NPC opponent pools, action outcomes, reaction voice lines, and QBCore/Qbox/standalone support.'
version '2.4.1'
lua54 'yes'

ui_page 'html/index.html'

shared_scripts {
    'shared/config.lua',
    'shared/bridge.lua'
}

server_scripts {
    'server/state.lua',
    'server/bets.lua',
    'server/main.lua'
}

client_scripts {
    'client/audio.lua',
    'client/main.lua',
    'client/arena.lua',
    'client/performer.lua',
    'client/reactor.lua',
    'client/cashier.lua',
    'client/zone.lua',
    'client/atmosphere.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

provide 'rs-outcomebets'

files {
    'sounds/*.ogg'
}
