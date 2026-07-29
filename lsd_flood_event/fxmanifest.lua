fx_version 'cerulean'
game 'gta5'

author 'lsd_flood_event'
description 'Rupture du barrage de Land Act - inondation progressive de Los Santos avec sirenes, montee d eau synchronisee et survie'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/vehicles.lua',
    'shared/weapons.lua'
}

server_scripts {
    'server/main.lua',
    'server/nui.lua'
}

client_scripts {
    'client/main.lua',
    'client/water.lua',
    'client/dam.lua',
    'client/spectacle.lua',
    'client/nui.lua'
}

ui_page 'html/ui.html'

files {
    'html/ui.html'
}

-- Les water_lvl_XX.xml sont générés par tools/generate_water_levels.py.
-- Ils doivent être déclarés ici pour que LoadWaterFromPath puisse les lire.
files {
    'stream/water_lvl_*.xml'
}

lua54 'yes'
