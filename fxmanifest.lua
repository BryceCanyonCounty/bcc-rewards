fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
lua54 'yes'
version '1.0.0'

name 'bcc-rewards'
author 'BCC Scripts'
description 'Combined coupon reward codes, Discord role rewards, VIP Tebex delivery, and seasonal battlepass for VORP.'
repository 'https://github.com/BryceCanyonCounty/bcc-rewards'

shared_scripts {
    'shared/config.lua',
    'shared/battlepass.lua',
    'shared/vip.lua',
    'shared/locale.lua',
    'languages/*.lua'
}

client_scripts {
    'client/helpers/*.lua',
    'client/menus/coupons.lua',
    'client/menus/battlepass.lua',
    'client/menus/vip.lua',
    'client/menus/hub.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/dbUpdater.lua',
    'server/helpers/*.lua',
    'server/controllers/coupons.lua',
    'server/services/discord.lua',
    'server/controllers/battlepass.lua',
    'server/controllers/vip.lua'
}

dependencies {
    'oxmysql',
    'vorp_core',
    'vorp_inventory',
    'bcc-utils',
    'feather-menu'
}

server_exports {
    'AddBattlepassXP',
    'AddBattlepassObjective',
    'GetBattlepassObjectives',
    'GetBattlepassXP',
    'HasBattlepassPremium',
    'GrantBattlepassPremium'
}
