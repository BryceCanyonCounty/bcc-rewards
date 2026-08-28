VipConfig = {}

VipConfig.Command = 'vip'
VipConfig.MenuTitle = 'VIP Center'
VipConfig.StoreName = 'Your VIP Store'
VipConfig.StoreUrl = 'https://your-store.tebex.io'
VipConfig.AutoClaimWhenQueued = true
VipConfig.AdminCommand = 'vipadmin'
VipConfig.AdminAddTokensCommand = 'addviptokens'
VipConfig.AdminAce = 'bcc.rewards.vip.admin'
VipConfig.AdminGroups = {
    admin = true,
    superadmin = true
}
VipConfig.AdminLogLimit = 50
VipConfig.TokenLabel = 'VIP Tokens'
VipConfig.TokenShortLabel = 'Tokens'

VipConfig.Webhook = {
    enabled = false,
    url = '',
    name = 'VIP Logs',
    color = 15844367
}

VipConfig.Notifications = {
    success = 4000,
    error = 5000,
    info = 5000
}

VipConfig.Packages = {

    tokens_80 = {
        label = '80x VIP Tokens',
        price = 'EUR 5.99',
        description = 'Adds 80 VIP tokens to your premium balance.',
        tebex_url = 'https://your-store.tebex.io/package/80-tokens',
        rewards = {
            tokens = 80
        }
    },

    tokens_150 = {
        label = '150x VIP Tokens',
        price = 'EUR 9.99',
        description = 'Adds 150 VIP tokens to your premium balance.',
        tebex_url = 'https://your-store.tebex.io/package/150-tokens',
        rewards = {
            tokens = 150
        }
    },

    tokens_250 = {
        label = '250x VIP Tokens',
        price = 'EUR 14.99',
        description = 'Adds 250 VIP tokens to your premium balance.',
        tebex_url = 'https://your-store.tebex.io/package/250-tokens',
        rewards = {
            tokens = 250
        }
    },

    tokens_400 = {
        label = '400x VIP Tokens',
        price = 'EUR 19.99',
        description = 'Adds 400 VIP tokens to your premium balance.',
        tebex_url = 'https://your-store.tebex.io/package/400-tokens',
        rewards = {
            tokens = 400
        }
    },

    tokens_650 = {
        label = '650x VIP Tokens',
        price = 'EUR 29.99',
        description = 'Adds 650 VIP tokens to your premium balance.',
        tebex_url = 'https://your-store.tebex.io/package/650-tokens',
        rewards = {
            tokens = 650
        }
    },

    tokens_1000 = {
        label = '1000x VIP Tokens',
        price = 'EUR 39.99',
        description = 'Adds 1000 VIP tokens to your premium balance.',
        tebex_url = 'https://your-store.tebex.io/package/1000-tokens',
        rewards = {
            tokens = 1000
        }
    }
}

VipConfig.Messages = {
    queued = 'Your purchase has been saved. Open /reward to claim it.',
    queued_auto = 'Your VIP purchase was delivered automatically.',
    queued_duplicate = 'This transaction is already queued.',
    invalid_package = 'Invalid Tebex package id.',
    invalid_player = 'The target player is not online.',
    invalid_identifier = 'Invalid Tebex target identifier.',
    no_character = 'Character data is not ready yet.',
    no_pending = 'No pending VIP purchases were found.',
    claimed = 'VIP purchase claimed successfully.',
    claim_failed = 'Unable to claim this VIP purchase right now.',
    menu_loading = 'Loading your VIP data...',
    menu_store = 'Buy from the Tebex website using the link below:',
    menu_identity = 'Stay online and use this server ID when required by Tebex.',
    menu_identifier = 'Preferred Tebex identifier:',
    menu_balance = 'Current token balance:',
    menu_empty = 'No pending VIP purchases.',
    copied = 'Use the Tebex link shown in the menu.',
    auto_claim_failed_queued = 'Your VIP purchase was saved because it could not be delivered instantly. Open /reward to claim it later.',
    admin_denied = 'You do not have permission to access VIP admin.',
    admin_empty = 'No VIP purchase logs found.',
    admin_loading = 'Loading VIP admin log...',
    pending_delivery_notice = 'This purchase is saved for your account and can be claimed from any of your characters unless you lock it to a character manually.',
    tokens_added = 'Tokens added to your account.',
    no_token_account = 'Could not load your token balance.'
}
