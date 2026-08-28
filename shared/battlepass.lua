BattlepassConfig = {}

BattlepassConfig.Command = 'battlepass'
BattlepassConfig.AdminAddXPCommand = 'AddXP'
BattlepassConfig.AdminPremiumCommand = 'AddBattlepass'
BattlepassConfig.AdminLogLimit = 25

BattlepassConfig.AdminAce = 'bcc.rewards.admin'
BattlepassConfig.AdminGroups = {
    admin = true,
    superadmin = true,
    god = true
}

BattlepassConfig.Season = {
    key = 'season_1',
    label = 'Frontier Season',
    maxLevel = 30,
    autoMonthlyReset = true,
    monthlyKeyPrefix = 'season',
    monthlyLabelFormat = 'Frontier Season %Y-%m'
}

BattlepassConfig.PremiumSettings = {
    enabled = true,
    premiumWithTokens = 80,
    premiumCanClaimNormal = true
}

BattlepassConfig.PostMaxLevelReward = {
    enabled = true,
    everyXP = 1500,
    reward = { type = 'item', name = 'gold_nugget', amount = 2, label = 'Pepita de aur x2' }
}

BattlepassConfig.OnlineXPPerHour = 100
BattlepassConfig.OnlineXPIntervalMinutes = 60
BattlepassConfig.IdleJobs = {
    unemployed = true,
    none = true
}

BattlepassConfig.Webhook = {
    enabled = false,
    url = '',
    name = 'Battlepass Logs',
    color = 15844367
}

BattlepassConfig.Text = {
    title = 'Battlepass',
    openHint = 'Open Battlepass',
    xpAdded = 'Battlepass XP added.',
    premiumGranted = 'Premium battlepass granted.',
    premiumBought = 'Premium battlepass purchased.',
    noPermission = 'You do not have permission.',
    invalidPlayer = 'Player not found.',
    invalidAmount = 'Invalid amount.',
    notEnoughTokens = 'You do not have enough tokens.',
    alreadyPremium = 'You already have premium.',
    rewardClaimed = 'Reward claimed.',
    rewardAlreadyClaimed = 'Reward already claimed.',
    rewardLocked = 'You have not reached this level.',
    premiumRequired = 'Premium battlepass required.',
    invalidReward = 'Invalid reward.',
    postMaxRewardClaimed = 'Battlepass bonus reward claimed.'
}

BattlepassConfig.Objectives = {
    enabled = true,
    progressEvent = 'bcc-rewards:server:addObjectiveProgress',
    list = {
        {
            id = 'chop_logs',
            labelKey = 'objectiveChopLogs',
            descriptionKey = 'objectiveChopLogsDesc',
            required = 75,
            xp = 200,
            repeatable = true,
            period = 'season',
            limit = 40
        },
        {
            id = 'mine_ore',
            labelKey = 'objectiveMineOre',
            descriptionKey = 'objectiveMineOreDesc',
            required = 75,
            xp = 250,
            repeatable = true,
            period = 'season',
            limit = 40
        },
        {
            id = 'fish_caught',
            labelKey = 'objectiveCatchFish',
            descriptionKey = 'objectiveCatchFishDesc',
            required = 5,
            xp = 200,
            repeatable = true,
            period = 'season',
            limit = 20
        },
        {
            id = 'hunt_animals',
            labelKey = 'objectiveHuntAnimals',
            descriptionKey = 'objectiveHuntAnimalsDesc',
            required = 12,
            xp = 250,
            repeatable = true,
            period = 'season',
            limit = 24
        },
        {
            id = 'deliver_goods',
            labelKey = 'objectiveDeliverGoods',
            descriptionKey = 'objectiveDeliverGoodsDesc',
            required = 1,
            xp = 750,
            repeatable = true,
            period = 'season',
            limit = 12
        },
        {
            id = 'collect_honey',
            labelKey = 'objectiveCollectHoney',
            descriptionKey = 'objectiveCollectHoneyDesc',
            required = 50,
            xp = 200,
            repeatable = true,
            period = 'season',
            limit = 20
        },
        {
            id = 'nazar_treasures',
            labelKey = 'objectiveNazarTreasures',
            descriptionKey = 'objectiveNazarTreasuresDesc',
            required = 1,
            xp = 750,
            repeatable = true,
            period = 'season',
            limit = 8
        },
        {
            id = 'loot_npcs',
            labelKey = 'objectiveLootNpcs',
            descriptionKey = 'objectiveLootNpcsDesc',
            required = 20,
            xp = 250,
            repeatable = true,
            period = 'season',
            limit = 20
        },
        {
            id = 'gold_panning',
            labelKey = 'objectiveGoldPanning',
            descriptionKey = 'objectiveGoldPanningDesc',
            required = 15,
            xp = 300,
            repeatable = true,
            period = 'season',
            limit = 20
        },
        {
            id = 'store_robberies',
            labelKey = 'objectiveStoreRobberies',
            descriptionKey = 'objectiveStoreRobberiesDesc',
            required = 1,
            xp = 1000,
            repeatable = true,
            period = 'season',
            limit = 8
        },
        {
            id = 'craft_items',
            labelKey = 'objectiveCraftItems',
            descriptionKey = 'objectiveCraftItemsDesc',
            required = 10,
            xp = 300,
            repeatable = true,
            period = 'season',
            limit = 20
        }
    }
}

BattlepassConfig.LevelXP = {}
for level = 1, BattlepassConfig.Season.maxLevel do
    BattlepassConfig.LevelXP[level] = (level - 1) * 1500
end

BattlepassConfig.Rewards = {
    normal = {},
    premium = {}
}

local function rewardItem(name, amount, label)
    return { type = 'item', name = name, amount = amount, label = label }
end

local normalRewards = {
    rewardItem('flamed_horseshoe', 2, 'Potcoave in flacari x2'),
    rewardItem('ironhammer', 10, 'Ciocane de fier x10'),
    rewardItem('ironbar', 20, 'Lingou de fier x20'),
    rewardItem('copperbar', 20, 'Lingou de cupru x20'),
    rewardItem('goldbar', 20, 'Lingou de aur x20'),
    rewardItem('lockpick', 10, 'Lockpick x10'),
    rewardItem('ammorifleexpress', 10, 'Munitie Rifle Express x10'),
    rewardItem('mortarpestle', 10, 'Mojar x10'),
    rewardItem('silverbar', 12, 'Lingou de argint x12'),
    rewardItem('barmould', 2, 'Matrite lingou x2'),
    rewardItem('powdergun', 20, 'Praf de pusca x20'),
    rewardItem('bulletscase', 40, 'Tuburi gloante x40'),
    rewardItem('ammorepeaterexpress', 12, 'Munitie Repeater Express x12'),
    rewardItem('gold_nugget', 25, 'Pepita de aur x25'),
    rewardItem('p_ambpack01x', 1, 'Ranita'),
    rewardItem('ammopistolexpress', 12, 'Munitie Pistol Express x12'),
    rewardItem('coal', 80, 'Carbuni x80'),
    rewardItem('lockpickmold', 1, 'Matrita Lockpick'),
    rewardItem('glassbottle', 15, 'Sticle goale x15'),
    rewardItem('jar', 10, 'Borcane x10'),
    rewardItem('ammoshotgunslug', 12, 'Munitie Shotgun Express x12'),
    rewardItem('moonshineapple', 8, 'Tuica de mere x8'),
    rewardItem('moonshinepeach', 8, 'Tuica de piersica x8'),
    rewardItem('moonshineplum', 8, 'Tuica de pruna x8'),
    rewardItem('screwdriver', 1, 'Surubelnita'),
    rewardItem('tequila', 8, 'Tequila x8'),
    rewardItem('vodka', 8, 'Vodka x8'),
    rewardItem('bulletsmould', 1, 'Matrita gloante'),
    rewardItem('pliers', 1, 'Cleste'),
    rewardItem('goldbar', 10, 'Lingou de aur x10')
}

local premiumRewards = {
    rewardItem('flamed_horseshoe', 4, 'Potcoave in flacari x4'),
    rewardItem('ironhammer', 15, 'Ciocane de fier x15'),
    rewardItem('ironbar', 35, 'Lingou de fier x35'),
    rewardItem('copperbar', 35, 'Lingou de cupru x35'),
    rewardItem('goldbar', 30, 'Lingou de aur x30'),
    rewardItem('lockpick', 20, 'Lockpick x20'),
    rewardItem('ammorifleexpress', 25, 'Munitie Rifle Express x25'),
    rewardItem('mortarpestle', 15, 'Mojar x15'),
    rewardItem('silverbar', 20, 'Lingou de argint x20'),
    rewardItem('barmould', 4, 'Matrite lingou x4'),
    rewardItem('powdergun', 40, 'Praf de pusca x40'),
    rewardItem('bulletscase', 80, 'Tuburi gloante x80'),
    rewardItem('ammorepeaterexpress', 25, 'Munitie Repeater Express x25'),
    rewardItem('gold_nugget', 50, 'Pepita de aur x50'),
    rewardItem('p_ambpack01x', 1, 'Ranita'),
    rewardItem('ammopistolexpress', 25, 'Munitie Pistol Express x25'),
    rewardItem('coal', 150, 'Carbuni x150'),
    rewardItem('lockpickmold', 2, 'Matrite Lockpick x2'),
    rewardItem('glassbottle', 30, 'Sticle goale x30'),
    rewardItem('jar', 20, 'Borcane x20'),
    rewardItem('ammoshotgunslug', 25, 'Munitie Shotgun Express x25'),
    rewardItem('moonshineapple', 15, 'Tuica de mere x15'),
    rewardItem('moonshinepeach', 15, 'Tuica de piersica x15'),
    rewardItem('moonshineplum', 15, 'Tuica de pruna x15'),
    rewardItem('screwdriver', 2, 'Surubelnite x2'),
    rewardItem('tequila', 15, 'Tequila x15'),
    rewardItem('vodka', 15, 'Vodka x15'),
    rewardItem('bulletsmould', 2, 'Matrite gloante x2'),
    rewardItem('pliers', 2, 'Clesti x2'),
    rewardItem('flamed_horseshoe', 6, 'Potcoave in flacari x6')
}

for level = 1, BattlepassConfig.Season.maxLevel do
    BattlepassConfig.Rewards.normal[level] = normalRewards[level]
    BattlepassConfig.Rewards.premium[level] = premiumRewards[level]
end
