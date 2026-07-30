fx_version 'cerulean'
game 'gta5'

author 'lsd_flood_event'
description 'Tsunami sur Los Santos - inondation progressive avec sirenes, montee d eau synchronisee et survie'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/vehicles.lua',
    'shared/weapons.lua'
}

server_scripts {
    'server/main.lua',
    'server/nui.lua',
    'server/contextmenu.lua'
}

client_scripts {
    'client/main.lua',
    'client/water.lua',
    'client/tsunami.lua',
    'client/spectacle.lua',
    'client/nui.lua',
    'client/combatstance.lua',
    'client/contextmenu.lua'
}

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/sounds/tsunami_siren.mp3'
}

-- Les water_lvl_XX.xml sont générés par tools/generate_water_levels.py.
-- Ils doivent être déclarés ici pour que LoadWaterFromPath puisse les lire.
files {
    'stream/water_lvl_*.xml'
}

lua54 'yes'
