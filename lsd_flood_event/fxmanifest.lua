fx_version 'cerulean'
game 'gta5'

author 'lsd_flood_event'
description 'Rupture du barrage de Land Act - inondation progressive de Los Santos avec sirenes, montee d eau synchronisee et survie'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'shared/config.lua'
}

server_scripts {
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

lua54 'yes'
