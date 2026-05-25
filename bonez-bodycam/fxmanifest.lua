fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'bonez-bodycam'
description 'Bodycam overlay — Axon, Motorola, Generic styles. ERS + Night Shifts MDT integration.'
author      'Bonez Workshop'
version     '3.0.0'

ui_page 'html/index.html'

dependency          'RageUI'
optional_dependency 'night_shifts_mdt'
optional_dependency 'night_ers'

files {
    'html/index.html',
    'html/css/style.css',
    'html/fonts/KlartextMonoBold.ttf',
    'html/img/logo.png',
    'html/sound/beep.wav',
    'html/sound/axon_rec_on.wav',
    'html/sound/axon_rec_off.wav',
    'html/sound/motorola_rec_on.wav',
    'html/sound/motorola_rec_off.wav',
    'html/sound/generic_rec_on.wav',
    'html/sound/generic_rec_off.wav',
}

shared_scripts {
    'config.lua',
    'shared/util.lua',
}

client_scripts {
    '@RageUI/imports/client.lua',
    'client/settings.lua',
    'client/ers.lua',
    'client/menu.lua',
    'client/main.lua',
}

server_scripts {
    'server/server.lua',
}
