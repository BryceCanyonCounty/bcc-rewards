# bcc-rewards

Unified VORP/RedM reward suite for coupon codes, Discord role rewards, VIP/Tebex delivery, and seasonal Battlepass progression.

Repository: https://github.com/BryceCanyonCounty/bcc-rewards

## Features

- Rewards hub menu for coupons, Battlepass, VIP, and admin tools.
- Coupon reward codes for items, weapons, cash, gold, and rol points.
- Optional Discord role rewards on a configurable interval.
- Monthly seasonal Battlepass with Normal and Premium reward tracks.
- Battlepass objectives for gameplay activity XP.
- VIP/Tebex purchase queue with online auto-claim and pending offline claims.
- VIP token balance synced with VORP `rol` currency.
- Admin logs for Battlepass and VIP activity.
- English and Romanian locales included.

## Requirements

Start these resources before `bcc-rewards`:

```cfg
ensure oxmysql
ensure vorp_core
ensure vorp_inventory
ensure bcc-utils
ensure feather-menu
```

## Installation

1. Download or clone this repository.
2. Place the resource folder at `resources/[BCC]/bcc-rewards`.
3. Add it to `server.cfg` after the requirements:

```cfg
ensure bcc-rewards
```

4. Configure `shared/config.lua`, `shared/battlepass.lua`, and `shared/vip.lua`.
5. Start the server. Database tables are created automatically by `server/dbUpdater.lua`.

## Commands

Player commands:

- `/reward` opens the rewards hub.
- `/tebexid` prints the player's Tebex identifier helper.

Admin commands:

- `/AddXP [id] [amount]` grants Battlepass XP.
- `/AddBattlepass [id]` grants Premium Battlepass.
- `/addviptokens [id] [amount]` grants VIP tokens.
- `/printroles` prints configured Discord guild roles to the server console.

Server console or Tebex command:

```text
bcc_vip_queue <id> <packageId> <transaction> [username] [server] [price] [currency] [time] [date] [email] [ip] [packagePrice] [packageExpiry] [packageName]
```

## Configuration

Main settings live in `shared/config.lua`:

```lua
Config.defaultlang = 'en_lang'
Config.allowedGroups = { 'admin', 'superadmin' }
Config.debug = false
```

Discord role rewards are disabled by default for public releases. Set real values only on your server, never before publishing:

```lua
Config.Guild_ID = 'YOUR_GUILD_ID'
Config.Bot_Token = 'CHANGE_ME'

Config.DiscordRoleReward = {
    enabled = false,
    roleID = 'ROLE_ID',
    interval = 60,
    rewards = {
        money = 100,
        gold = 0.30
    }
}
```

Battlepass settings live in `shared/battlepass.lua`:

```lua
BattlepassConfig.Command = 'battlepass'
BattlepassConfig.AdminAddXPCommand = 'AddXP'
BattlepassConfig.AdminPremiumCommand = 'AddBattlepass'

BattlepassConfig.Season = {
    key = 'season_1',
    label = 'Frontier Season',
    maxLevel = 30,
    autoMonthlyReset = true
}

BattlepassConfig.PremiumSettings = {
    enabled = true,
    premiumWithTokens = 80,
    premiumCanClaimNormal = true
}
```

VIP and Tebex settings live in `shared/vip.lua`:

```lua
VipConfig.StoreName = 'Your VIP Store'
VipConfig.StoreUrl = 'https://your-store.tebex.io'
VipConfig.TokenLabel = 'VIP Tokens'
VipConfig.TokenShortLabel = 'Tokens'
VipConfig.AutoClaimWhenQueued = true
```

Replace the example packages in `VipConfig.Packages` with your own Tebex package IDs, prices, labels, and rewards.

## Permissions

Coupon admin access uses VORP character groups from `Config.allowedGroups`.

Battlepass admin access supports ACE and VORP groups:

```lua
BattlepassConfig.AdminAce = 'bcc.rewards.admin'
BattlepassConfig.AdminGroups = {
    admin = true,
    superadmin = true,
    god = true
}
```

VIP admin access supports ACE and VORP groups:

```lua
VipConfig.AdminAce = 'bcc.rewards.vip.admin'
VipConfig.AdminGroups = {
    admin = true,
    superadmin = true
}
```

Example ACE setup:

```cfg
add_ace group.admin bcc.rewards.admin allow
add_ace group.admin bcc.rewards.vip.admin allow
```

## Database

Coupon tables:

- `bcc_rewardcodes`
- `bcc_rewardcodes_items`
- `bcc_rewardcodes_money`
- `bcc_rewardcodes_users`
- `bcc_rewardcodes_weapons`

Battlepass tables:

- `bcc_rewards_battlepass_players`
- `bcc_rewards_battlepass_claims`
- `bcc_rewards_battlepass_purchases`
- `bcc_rewards_battlepass_objectives`

VIP tables:

- `bcc_vip_purchases`
- `bcc_vip_tokens`
- `bcc_vip_delivery_logs`

Tables are created automatically on resource start by `server/dbUpdater.lua`.

## Battlepass Exports

Use exports from trusted server-side scripts when a real activity happens:

```lua
exports['bcc-rewards']:AddBattlepassXP(source, 50, 'lumberjack')
exports['bcc-rewards']:AddBattlepassObjective(source, 'chop_logs', 1, 'lumberjack')
exports['bcc-rewards']:GetBattlepassObjectives(source)
exports['bcc-rewards']:GetBattlepassXP(source)
exports['bcc-rewards']:HasBattlepassPremium(source)
exports['bcc-rewards']:GrantBattlepassPremium(source, 'admin_reward')
```

You can also use the configured server event:

```lua
TriggerEvent('bcc-rewards:server:addObjectiveProgress', source, 'mine_ore', 1, 'mining')
```

Default objective IDs include:

- `chop_logs`
- `mine_ore`
- `fish_caught`
- `hunt_animals`
- `deliver_goods`
- `collect_honey`
- `nazar_treasures`
- `loot_npcs`
- `gold_panning`
- `store_robberies`
- `craft_items`

## Tebex Setup

Configure Tebex to run this command from the server console:

```text
bcc_vip_queue {id} {packageId} {transaction} "{username}" "{server}" {price} {currency} "{time}" "{date}" "{email}" "{ip}" "{packagePrice}" "{packageExpiry}" "{packageName}"
```

The second argument can be a key from `VipConfig.Packages`, such as `tokens_400`, or a numeric package ID found in a package `tebex_url`.

Supported VIP command placeholders inside package reward commands:

- `{source}`
- `{charid}`
- `{identifier}`
- `{firstname}`
- `{lastname}`
- `{package}`
- `{purchase_id}`
- `{transaction}`
- `{tokens}`

## Security Notes

- Do not publish real Discord bot tokens, webhook URLs, Tebex private data, or server-specific IDs.
- Keep Discord role rewards disabled until `Config.Guild_ID`, `Config.Bot_Token`, and `roleID` are configured on your live server.
- Coupon redemption, Battlepass claiming, Premium checks, and VIP delivery are validated server-side.
- Duplicate Battlepass claims are blocked by database uniqueness.
- Item and weapon reward delivery checks inventory capacity where supported.

## Troubleshooting

- Rewards hub does not open: confirm `feather-menu`, `vorp_core`, and `bcc-utils` are started first.
- Coupon Admin fails: check `Config.allowedGroups`.
- Battlepass admin commands fail: check `BattlepassConfig.AdminAce` or `BattlepassConfig.AdminGroups`.
- Battlepass item rewards fail: confirm the configured item exists in `vorp_inventory`.
- Discord rewards do nothing: confirm Discord rewards are enabled and bot/guild/role settings are valid.
- VIP purchases do not queue: confirm Tebex runs `bcc_vip_queue` from server console and the package key or ID exists.
- VIP purchases queue but do not deliver: check Pending VIP and the `bcc_vip_purchases.failure_reason` column.
- Duplicate commands usually mean another resource is registering the same command names.

## License

This project is licensed under GPL-3.0. See `LICENSE`.
