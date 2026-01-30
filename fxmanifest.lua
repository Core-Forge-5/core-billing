fx_version 'cerulean'
game 'gta5'
author 'Dice'
name 'Core-Billing'
discription 'Core Forge Billing System'

client_scripts {
    'client/cl_billing.lua'
}
server_scripts  {
    'server/sv_billing.lua'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/playerdata.lua',
    'config.lua'
}