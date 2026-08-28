Config = {
    defaultlang = 'en_lang',
    allowedGroups = {
        'admin',
        'superadmin',
    },
    debug = false,
}

Config.Guild_ID = 'YOUR_GUILD_ID'
Config.Bot_Token = 'CHANGE_ME'

Config.DiscordRoleReward = {
    enabled = false,
    roleID = 'ROLE_ID',
    interval = 60,

    rewards = {
        money = 100,
        gold = 0.30
    },

    notify = {
        dict = 'inventory_items',
        icon = 'money_moneystack',
        color = 'COLOR_GREEN',
        duration = 4000
    }
}
