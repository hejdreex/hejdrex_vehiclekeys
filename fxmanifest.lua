fx_version 'cerulean'
game 'gta5'

author 'Hejdrex'
description 'Vehicle lock system with ox_target and ox_inventory item'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/*.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
}