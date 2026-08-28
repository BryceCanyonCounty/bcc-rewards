local VORPcore = exports.vorp_core:GetCore()

local function normalizeJobList()
    local jobs = {}

    for key, value in pairs(BattlepassConfig.IdleJobs or {}) do
        if type(key) == 'number' then
            jobs[tostring(value):lower()] = true
        elseif value == true then
            jobs[tostring(key):lower()] = true
        end
    end

    return jobs
end

local idleJobs = normalizeJobList()

local function buildObjectiveMap()
    local objectives = {}

    for _, objective in ipairs((BattlepassConfig.Objectives and BattlepassConfig.Objectives.list) or {}) do
        if objective.id then
            objectives[tostring(objective.id)] = objective
        end
    end

    return objectives
end

local objectiveMap = buildObjectiveMap()

local function notify(src, message, kind)
    if src and src > 0 then
        TriggerClientEvent('bcc-rewards:client:notify', src, message, kind or 'info')
    else
        print(('[bcc-rewards] %s'):format(message))
    end
end

local function getCharacter(src)
    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        return nil
    end

    local character = user.getUsedCharacter
    if not character or not character.identifier or not character.charIdentifier then
        return nil
    end

    return character, user
end

local function isAdmin(src)
    if src == 0 then
        return true
    end

    if BattlepassConfig.AdminAce and BattlepassConfig.AdminAce ~= '' and IsPlayerAceAllowed(src, BattlepassConfig.AdminAce) then
        return true
    end

    local character = getCharacter(src)
    if not character then
        return false
    end

    return BattlepassConfig.AdminGroups[tostring(character.group or ''):lower()] == true
end

local function sendWebhook(title, description)
    if not BattlepassConfig.Webhook.enabled or BattlepassConfig.Webhook.url == '' then
        return
    end

    local payload = {
        username = BattlepassConfig.Webhook.name,
        embeds = {
            {
                title = title,
                description = description,
                color = BattlepassConfig.Webhook.color,
                footer = { text = os.date('%Y-%m-%d %H:%M:%S') }
            }
        }
    }

    PerformHttpRequest(BattlepassConfig.Webhook.url, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

local function getSeasonKey()
    if BattlepassConfig.Season.autoMonthlyReset then
        return ('%s_%s'):format(BattlepassConfig.Season.monthlyKeyPrefix or 'season', os.date('%Y_%m'))
    end

    return BattlepassConfig.Season.key
end

local function getSeasonPayload()
    local season = {}

    for key, value in pairs(BattlepassConfig.Season or {}) do
        season[key] = value
    end

    season.key = getSeasonKey()

    if BattlepassConfig.Season.autoMonthlyReset and BattlepassConfig.Season.monthlyLabelFormat then
        season.label = os.date(BattlepassConfig.Season.monthlyLabelFormat)
    end

    return season
end

local function ensurePlayer(identifier, charid)
    MySQL.insert.await([[
        INSERT INTO bcc_rewards_battlepass_players (identifier, charid, season, xp, premium)
        VALUES (?, ?, ?, 0, 0)
        ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP
    ]], { identifier, charid, getSeasonKey() })
end

local function isDbTrue(value)
    return value == true or value == 1 or value == '1' or tonumber(value or 0) == 1
end

local function getProgress(identifier, charid)
    ensurePlayer(identifier, charid)

    local row = MySQL.single.await([[
        SELECT xp, premium, post_rewards
        FROM bcc_rewards_battlepass_players
        WHERE identifier = ? AND charid = ? AND season = ?
        LIMIT 1
    ]], { identifier, charid, getSeasonKey() })

    return {
        xp = tonumber(row and row.xp or 0) or 0,
        premium = isDbTrue(row and row.premium),
        postRewards = tonumber(row and row.post_rewards or 0) or 0
    }
end

local function getLevelForXP(xp)
    local maxLevel = BattlepassConfig.Season.maxLevel
    local level = 1

    for i = 1, maxLevel do
        if xp >= tonumber(BattlepassConfig.LevelXP[i] or 0) then
            level = i
        else
            break
        end
    end

    return level
end

local function getClaimMap(identifier, charid)
    local rows = MySQL.query.await([[
        SELECT level, claim_type
        FROM bcc_rewards_battlepass_claims
        WHERE identifier = ? AND charid = ? AND season = ?
    ]], { identifier, charid, getSeasonKey() }) or {}

    local claims = {}
    for _, row in ipairs(rows) do
        local level = tonumber(row.level)
        if level then
            claims[level] = claims[level] or {}
            claims[level][row.claim_type] = true
        end
    end

    return claims
end

local function getTokenBalance(identifier, charid)
    local row = MySQL.single.await([[
        SELECT id, balance
        FROM bcc_vip_tokens
        WHERE identifier = ? AND (charid = ? OR charid IS NULL)
        ORDER BY charid DESC
        LIMIT 1
    ]], { identifier, charid })

    return row and tonumber(row.balance or 0) or 0, row and row.id or nil
end

local function getCharacterRolBalance(character)
    local balance = tonumber(character.rol)

    if not balance and type(character.Rol) == 'function' then
        balance = tonumber(character.Rol())
    end

    return balance or 0
end

local function syncTokenBalanceToRol(identifier, charid, character)
    local savedBalance, tokenRowId = getTokenBalance(identifier, charid)
    local rolBalance = getCharacterRolBalance(character)

    if tokenRowId and savedBalance > rolBalance then
        MySQL.update.await([[
            UPDATE bcc_vip_tokens
            SET balance = ?,
                charid = COALESCE(charid, ?),
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ]], {
            rolBalance,
            charid,
            tokenRowId
        })

        return rolBalance, tokenRowId
    end

    return savedBalance, tokenRowId
end

local function removeTokenBalance(identifier, charid, amount)
    amount = math.floor(tonumber(amount or 0) or 0)
    if amount <= 0 then
        return true
    end

    local _, tokenRowId = getTokenBalance(identifier, charid)
    if not tokenRowId then
        return true
    end

    local affectedRows = MySQL.update.await([[
        UPDATE bcc_vip_tokens
        SET balance = GREATEST(balance - ?, 0),
            charid = COALESCE(charid, ?),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
    ]], {
        amount,
        charid,
        tokenRowId
    })

    return tonumber(affectedRows or 0) > 0
end

local function getObjectivePeriodKey(objective)
    local period = tostring(objective.period or 'season'):lower()

    if period == 'daily' then
        return os.date('%Y-%m-%d')
    end

    if period == 'weekly' then
        return os.date('%Y-W%W')
    end

    return getSeasonKey()
end

local function mergeObjectiveRowsToPeriod(identifier, charid, objectiveId, periodKey)
    local legacyRows = MySQL.query.await([[
        SELECT progress, completions
        FROM bcc_rewards_battlepass_objectives
        WHERE identifier = ? AND charid = ? AND season = ? AND objective = ? AND period_key <> ?
    ]], { identifier, charid, getSeasonKey(), objectiveId, periodKey }) or {}

    if #legacyRows == 0 then
        return
    end

    local progress = 0
    local completions = 0
    for _, row in ipairs(legacyRows) do
        progress = progress + (tonumber(row.progress or 0) or 0)
        completions = completions + (tonumber(row.completions or 0) or 0)
    end

    MySQL.insert.await([[
        INSERT INTO bcc_rewards_battlepass_objectives (identifier, charid, season, objective, period_key, progress, completions)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            progress = progress + VALUES(progress),
            completions = completions + VALUES(completions),
            updated_at = CURRENT_TIMESTAMP
    ]], { identifier, charid, getSeasonKey(), objectiveId, periodKey, progress, completions })

    MySQL.update.await([[
        DELETE FROM bcc_rewards_battlepass_objectives
        WHERE identifier = ? AND charid = ? AND season = ? AND objective = ? AND period_key <> ?
    ]], { identifier, charid, getSeasonKey(), objectiveId, periodKey })
end

local function getObjectiveRows(identifier, charid)
    local rows = {}

    for _, objective in ipairs((BattlepassConfig.Objectives and BattlepassConfig.Objectives.list) or {}) do
        if objective.id then
            local periodKey = getObjectivePeriodKey(objective)
            mergeObjectiveRowsToPeriod(identifier, charid, objective.id, periodKey)
            local row = MySQL.single.await([[
                SELECT progress, completions
                FROM bcc_rewards_battlepass_objectives
                WHERE identifier = ? AND charid = ? AND season = ? AND objective = ? AND period_key = ?
                LIMIT 1
            ]], { identifier, charid, getSeasonKey(), objective.id, periodKey })

            rows[tostring(objective.id)] = {
                progress = tonumber(row and row.progress or 0) or 0,
                completions = tonumber(row and row.completions or 0) or 0,
                periodKey = periodKey
            }
        end
    end

    return rows
end

local function buildObjectivePayload(identifier, charid)
    if not BattlepassConfig.Objectives or BattlepassConfig.Objectives.enabled == false then
        return {}
    end

    local rows = getObjectiveRows(identifier, charid)
    local objectives = {}

    for _, objective in ipairs(BattlepassConfig.Objectives.list or {}) do
        if objective.id then
            local required = math.max(1, tonumber(objective.required or 1) or 1)
            local row = rows[tostring(objective.id)] or { progress = 0, completions = 0, periodKey = getObjectivePeriodKey(objective) }
            local limit = tonumber(objective.limit or 0) or 0
            local progress = math.min(required, tonumber(row.progress or 0) or 0)
            local completions = tonumber(row.completions or 0) or 0

            objectives[#objectives + 1] = {
                id = objective.id,
                label = objective.label,
                labelKey = objective.labelKey,
                description = objective.description,
                descriptionKey = objective.descriptionKey,
                required = required,
                progress = progress,
                percent = math.floor((progress / required) * 100),
                xp = tonumber(objective.xp or 0) or 0,
                period = objective.period or 'season',
                repeatable = objective.repeatable == true,
                limit = limit,
                completions = completions,
                limitReached = limit > 0 and completions >= limit,
                periodKey = row.periodKey
            }
        end
    end

    return objectives
end

local function rewardFor(track, level)
    if track ~= 'normal' and track ~= 'premium' then
        return nil
    end

    return BattlepassConfig.Rewards[track] and BattlepassConfig.Rewards[track][level] or nil
end

local function publicReward(reward)
    if not reward then
        return nil
    end

    return {
        type = reward.type,
        name = reward.name,
        amount = reward.amount,
        label = reward.label or reward.name or reward.type
    }
end

local function getBattlepassAdminLogs()
    local limit = tonumber(BattlepassConfig.AdminLogLimit or 25) or 25

    return {
        players = MySQL.query.await(([[
            SELECT identifier, charid, season, xp, premium, updated_at
            FROM bcc_rewards_battlepass_players
            ORDER BY updated_at DESC
            LIMIT %d
        ]]):format(limit)) or {},
        objectives = MySQL.query.await(([[
            SELECT identifier, charid, season, objective, period_key, progress, completions, updated_at
            FROM bcc_rewards_battlepass_objectives
            ORDER BY updated_at DESC
            LIMIT %d
        ]]):format(limit)) or {},
        claims = MySQL.query.await(([[
            SELECT identifier, charid, season, level, claim_type, claimed_at
            FROM bcc_rewards_battlepass_claims
            ORDER BY claimed_at DESC
            LIMIT %d
        ]]):format(limit)) or {},
        purchases = MySQL.query.await(([[
            SELECT identifier, charid, season, player_name, character_name, price, balance_before, balance_after, purchase_type, purchased_at
            FROM bcc_rewards_battlepass_purchases
            ORDER BY purchased_at DESC
            LIMIT %d
        ]]):format(limit)) or {}
    }
end

local function buildPayload(src)
    local character = getCharacter(src)
    if not character then
        return nil
    end

    local progress = getProgress(character.identifier, character.charIdentifier)
    local claims = getClaimMap(character.identifier, character.charIdentifier)
    local level = getLevelForXP(progress.xp)
    local levels = {}

    for i = 1, BattlepassConfig.Season.maxLevel do
        levels[#levels + 1] = {
            level = i,
            xpRequired = BattlepassConfig.LevelXP[i] or 0,
            normal = publicReward(rewardFor('normal', i)),
            premium = publicReward(rewardFor('premium', i)),
            normalClaimed = claims[i] and claims[i].normal == true or false,
            premiumClaimed = claims[i] and claims[i].premium == true or false
        }
    end

    local maxLevelXP = BattlepassConfig.LevelXP[BattlepassConfig.Season.maxLevel] or 0
    local nextLevelXP = BattlepassConfig.LevelXP[math.min(level + 1, BattlepassConfig.Season.maxLevel)] or maxLevelXP
    local postRewardSettings = BattlepassConfig.PostMaxLevelReward or {}
    local postRewardEnabled = postRewardSettings.enabled ~= false and postRewardSettings.reward ~= nil
    local postRewardEveryXP = math.max(1, tonumber(postRewardSettings.everyXP or 1500) or 1500)
    local postRewardsEarned = math.floor(math.max(0, progress.xp - maxLevelXP) / postRewardEveryXP)
    local nextPostRewardXP = maxLevelXP + ((postRewardsEarned + 1) * postRewardEveryXP)

    return {
        season = getSeasonPayload(),
        text = BattlepassConfig.Text,
        progress = {
            xp = progress.xp,
            level = level,
            premium = progress.premium,
            postRewards = progress.postRewards,
            nextLevelXP = nextLevelXP,
            maxLevelXP = maxLevelXP,
            isMaxLevel = level >= BattlepassConfig.Season.maxLevel,
            postRewardEnabled = postRewardEnabled,
            nextPostRewardXP = nextPostRewardXP,
            maxLevel = BattlepassConfig.Season.maxLevel
        },
        premium = {
            enabled = BattlepassConfig.PremiumSettings.enabled,
            price = BattlepassConfig.PremiumSettings.premiumWithTokens,
            premiumCanClaimNormal = BattlepassConfig.PremiumSettings.premiumCanClaimNormal
        },
        levels = levels,
        objectives = buildObjectivePayload(character.identifier, character.charIdentifier),
        isAdmin = isAdmin(src),
        adminLogs = isAdmin(src) and getBattlepassAdminLogs() or nil
    }
end

local function refresh(src)
    local payload = buildPayload(src)
    if payload then
        TriggerClientEvent('bcc-rewards:client:update', src, payload)
    end
end

local giveReward

local function processPostMaxLevelRewards(src, character)
    local settings = BattlepassConfig.PostMaxLevelReward or {}
    if settings.enabled == false or not settings.reward then
        return
    end

    local everyXP = math.max(1, tonumber(settings.everyXP or 1500) or 1500)
    local maxLevelXP = tonumber(BattlepassConfig.LevelXP[BattlepassConfig.Season.maxLevel] or 0) or 0
    local row = MySQL.single.await([[
        SELECT xp, post_rewards
        FROM bcc_rewards_battlepass_players
        WHERE identifier = ? AND charid = ? AND season = ?
        LIMIT 1
    ]], { character.identifier, character.charIdentifier, getSeasonKey() })

    local xp = tonumber(row and row.xp or 0) or 0
    local paidRewards = tonumber(row and row.post_rewards or 0) or 0
    local rewardCount = math.floor(math.max(0, xp - maxLevelXP) / everyXP)
    local dueRewards = rewardCount - paidRewards
    if dueRewards <= 0 then
        return
    end

    local granted = 0
    for _ = 1, dueRewards do
        local ok = giveReward(src, character, settings.reward)
        if not ok then
            break
        end
        granted = granted + 1
    end

    if granted <= 0 then
        return
    end

    MySQL.update.await([[
        UPDATE bcc_rewards_battlepass_players
        SET post_rewards = post_rewards + ?
        WHERE identifier = ? AND charid = ? AND season = ?
    ]], { granted, character.identifier, character.charIdentifier, getSeasonKey() })

    notify(src, BattlepassConfig.Text.postMaxRewardClaimed, 'success')
end

local function addXPToSource(src, amount, reason)
    amount = math.floor(tonumber(amount or 0) or 0)
    if amount <= 0 then
        return false
    end

    local character = getCharacter(src)
    if not character then
        return false
    end

    ensurePlayer(character.identifier, character.charIdentifier)
    MySQL.update.await([[
        UPDATE bcc_rewards_battlepass_players
        SET xp = xp + ?
        WHERE identifier = ? AND charid = ? AND season = ?
    ]], { amount, character.identifier, character.charIdentifier, getSeasonKey() })

    processPostMaxLevelRewards(src, character)

    sendWebhook('Battlepass XP Added', ('Target: %s\nAmount: %s\nReason: %s'):format(GetPlayerName(src) or src, amount, reason or 'unspecified'))
    return true
end

local function grantPremiumToSource(src, reason)
    local character = getCharacter(src)
    if not character then
        print(('[bcc-rewards] Battlepass premium grant failed: no character for source %s'):format(tostring(src)))
        return false
    end

    local currentProgress = getProgress(character.identifier, character.charIdentifier)
    if currentProgress.premium then
        print(('[bcc-rewards] Battlepass premium grant skipped: already active source=%s identifier=%s charid=%s season=%s reason=%s'):format(
            tostring(src),
            tostring(character.identifier),
            tostring(character.charIdentifier),
            tostring(getSeasonKey()),
            tostring(reason or 'unspecified')
        ))
        return true
    end

    ensurePlayer(character.identifier, character.charIdentifier)
    local affectedRows = MySQL.update.await([[
        UPDATE bcc_rewards_battlepass_players
        SET premium = 1
        WHERE identifier = ? AND charid = ? AND season = ?
    ]], { character.identifier, character.charIdentifier, getSeasonKey() })

    print(('[bcc-rewards] Battlepass premium grant source=%s identifier=%s charid=%s season=%s affected=%s reason=%s'):format(
        tostring(src),
        tostring(character.identifier),
        tostring(character.charIdentifier),
        tostring(getSeasonKey()),
        tostring(affectedRows),
        tostring(reason or 'unspecified')
    ))

    local verifiedPremium = getProgress(character.identifier, character.charIdentifier).premium
    if not verifiedPremium then
        print(('[bcc-rewards] Battlepass premium grant verification failed source=%s identifier=%s charid=%s season=%s'):format(
            tostring(src),
            tostring(character.identifier),
            tostring(character.charIdentifier),
            tostring(getSeasonKey())
        ))
        return false
    end

    sendWebhook('Battlepass Premium Granted', ('Target: %s\nReason: %s'):format(GetPlayerName(src) or src, reason or 'unspecified'))
    return true
end

local function getCharacterName(character)
    return ('%s %s'):format(character.firstname or '', character.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function insertPremiumPurchaseLog(src, character, price, balanceBefore, balanceAfter)
    local characterName = getCharacterName(character)

    local ok, err = pcall(function()
        MySQL.insert.await([[
            INSERT INTO bcc_rewards_battlepass_purchases (
                identifier,
                charid,
                season,
                player_name,
                character_name,
                price,
                balance_before,
                balance_after,
                purchase_type
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'tokens')
        ]], {
            character.identifier,
            character.charIdentifier,
            getSeasonKey(),
            GetPlayerName(src),
            characterName,
            price,
            balanceBefore,
            balanceAfter
        })
    end)

    if not ok then
        print(('[bcc-rewards] Battlepass premium purchase log failed: %s'):format(tostring(err)))
    end

    print(('[bcc-rewards] Battlepass premium purchase player=%s character=%s charid=%s identifier=%s season=%s price=%s balance_before=%s balance_after=%s'):format(
        tostring(GetPlayerName(src) or src),
        tostring(characterName),
        tostring(character.charIdentifier),
        tostring(character.identifier),
        tostring(getSeasonKey()),
        tostring(price),
        tostring(balanceBefore),
        tostring(balanceAfter)
    ))
end

local function addObjectiveProgressToSource(src, objectiveId, amount, reason)
    if not BattlepassConfig.Objectives or BattlepassConfig.Objectives.enabled == false then
        return false, 'objectives_disabled'
    end

    src = tonumber(src)
    amount = math.floor(tonumber(amount or 1) or 1)
    objectiveId = tostring(objectiveId or '')

    if not src or src <= 0 or amount <= 0 or objectiveId == '' then
        return false, 'invalid_objective_progress'
    end

    local objective = objectiveMap[objectiveId]
    if not objective then
        return false, 'invalid_objective'
    end

    local character = getCharacter(src)
    if not character then
        return false, 'invalid_character'
    end

    ensurePlayer(character.identifier, character.charIdentifier)

    local periodKey = getObjectivePeriodKey(objective)
    mergeObjectiveRowsToPeriod(character.identifier, character.charIdentifier, objectiveId, periodKey)
    MySQL.insert.await([[
        INSERT INTO bcc_rewards_battlepass_objectives (identifier, charid, season, objective, period_key, progress, completions)
        VALUES (?, ?, ?, ?, ?, 0, 0)
        ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP
    ]], { character.identifier, character.charIdentifier, getSeasonKey(), objectiveId, periodKey })

    local row = MySQL.single.await([[
        SELECT progress, completions
        FROM bcc_rewards_battlepass_objectives
        WHERE identifier = ? AND charid = ? AND season = ? AND objective = ? AND period_key = ?
        LIMIT 1
    ]], { character.identifier, character.charIdentifier, getSeasonKey(), objectiveId, periodKey })

    local progress = tonumber(row and row.progress or 0) or 0
    local completions = tonumber(row and row.completions or 0) or 0
    local required = math.max(1, tonumber(objective.required or 1) or 1)
    local limit = tonumber(objective.limit or 0) or 0

    if limit > 0 and completions >= limit then
        return false, 'objective_limit_reached'
    end

    if objective.repeatable ~= true and completions > 0 then
        return false, 'objective_already_completed'
    end

    progress = progress + amount

    local completedNow = 0
    while progress >= required do
        if limit > 0 and completions >= limit then
            progress = required
            break
        end

        if objective.repeatable ~= true and completions > 0 then
            progress = required
            break
        end

        completedNow = completedNow + 1
        completions = completions + 1

        if objective.repeatable == true then
            progress = progress - required
        else
            progress = required
            break
        end
    end

    if limit > 0 and completions >= limit then
        progress = math.min(progress, required)
    end

    MySQL.update.await([[
        UPDATE bcc_rewards_battlepass_objectives
        SET progress = ?, completions = ?
        WHERE identifier = ? AND charid = ? AND season = ? AND objective = ? AND period_key = ?
    ]], { progress, completions, character.identifier, character.charIdentifier, getSeasonKey(), objectiveId, periodKey })

    local xp = math.floor((tonumber(objective.xp or 0) or 0) * completedNow)
    if xp > 0 then
        addXPToSource(src, xp, ('objective:%s:%s'):format(objectiveId, reason or 'progress'))
        notify(src, (BattlepassConfig.Text.xpAdded or 'Battlepass XP added.'), 'success')
    end

    refresh(src)
    return true, completedNow, xp
end

giveReward = function(src, character, reward)
    local rewardType = tostring(reward.type or ''):lower()
    local amount = tonumber(reward.amount or 1) or 1

    if rewardType == 'money' then
        character.addCurrency(0, amount)
        return true
    end

    if rewardType == 'gold' then
        character.addCurrency(1, amount)
        return true
    end

    if rewardType == 'rol' then
        character.addCurrency(2, amount)
        return true
    end

    if rewardType == 'item' and reward.name then
        local canCarry = exports.vorp_inventory:canCarryItem(src, reward.name, amount)
        if not canCarry then
            return false, 'Cannot carry this item.'
        end

        exports.vorp_inventory:addItem(src, reward.name, amount)
        return true
    end

    if rewardType == 'weapon' and reward.name then
        local canCarry = exports.vorp_inventory:canCarryWeapons(src, 1, nil, reward.name)
        if not canCarry then
            return false, 'Cannot carry this weapon.'
        end

        exports.vorp_inventory:createWeapon(src, reward.name, reward.ammo or {}, reward.components or {})
        return true
    end

    if rewardType == 'command' and reward.command then
        local command = reward.command
            :gsub('{source}', tostring(src))
            :gsub('{identifier}', tostring(character.identifier))
            :gsub('{charid}', tostring(character.charIdentifier))
        ExecuteCommand(command)
        return true
    end

    return false, BattlepassConfig.Text.invalidReward
end

RegisterNetEvent('bcc-rewards:server:open', function()
    local src = source
    local character = getCharacter(src)
    if character then
        processPostMaxLevelRewards(src, character)
    end

    local payload = buildPayload(src)
    if payload then
        TriggerClientEvent('bcc-rewards:client:open', src, payload)
    end
end)

RegisterNetEvent('bcc-rewards:server:buyPremium', function()
    local src = source
    local character = getCharacter(src)
    if not character or not BattlepassConfig.PremiumSettings.enabled then
        return
    end

    local progress = getProgress(character.identifier, character.charIdentifier)
    if progress.premium then
        refresh(src)
        return notify(src, BattlepassConfig.Text.alreadyPremium, 'warning')
    end

    local identifier = character.identifier
    local charid = character.charIdentifier
    local price = tonumber(BattlepassConfig.PremiumSettings.premiumWithTokens or 0) or 0
    local balanceBefore = getCharacterRolBalance(character)
    if price > 0 then
        print(('[bcc-rewards] Battlepass premium buy source=%s identifier=%s charid=%s season=%s rol=%s price=%s'):format(
            tostring(src),
            tostring(identifier),
            tostring(charid),
            tostring(getSeasonKey()),
            tostring(balanceBefore),
            tostring(price)
        ))

        if balanceBefore < price then
            return notify(src, _U('notEnoughTokens'), 'error')
        end
    end

    if price > 0 then
        if not removeTokenBalance(identifier, charid, price) then
            return notify(src, _U('notEnoughTokens'), 'error')
        end

        character.removeCurrency(2, price)
    end

    if not grantPremiumToSource(src, 'token_purchase') then
        return notify(src, BattlepassConfig.Text.claim_failed or 'Unable to activate premium.', 'error')
    end

    refresh(src)
    insertPremiumPurchaseLog(src, character, price, balanceBefore, math.max(0, balanceBefore - price))
    notify(src, BattlepassConfig.Text.premiumBought, 'success')
end)

RegisterNetEvent('bcc-rewards:server:claim', function(level, track)
    local src = source
    level = tonumber(level)
    track = tostring(track or ''):lower()

    if track ~= 'normal' and track ~= 'premium' then
        return notify(src, BattlepassConfig.Text.invalidReward, 'error')
    end

    if not level or level < 1 or level > BattlepassConfig.Season.maxLevel then
        return notify(src, BattlepassConfig.Text.invalidReward, 'error')
    end

    local character = getCharacter(src)
    if not character then
        return
    end

    local reward = rewardFor(track, level)
    if not reward then
        return notify(src, BattlepassConfig.Text.invalidReward, 'error')
    end

    local progress = getProgress(character.identifier, character.charIdentifier)
    if getLevelForXP(progress.xp) < level then
        return notify(src, BattlepassConfig.Text.rewardLocked, 'warning')
    end

    if track == 'premium' and not progress.premium then
        return notify(src, BattlepassConfig.Text.premiumRequired, 'warning')
    end

    if track == 'normal' and not BattlepassConfig.PremiumSettings.premiumCanClaimNormal and progress.premium then
        return notify(src, BattlepassConfig.Text.invalidReward, 'error')
    end

    local inserted = MySQL.insert.await([[
        INSERT IGNORE INTO bcc_rewards_battlepass_claims (identifier, charid, season, level, claim_type)
        VALUES (?, ?, ?, ?, ?)
    ]], { character.identifier, character.charIdentifier, getSeasonKey(), level, track })

    if not inserted or inserted == 0 then
        return notify(src, BattlepassConfig.Text.rewardAlreadyClaimed, 'warning')
    end

    local ok, errorMessage = giveReward(src, character, reward)
    if not ok then
        MySQL.update.await([[
            DELETE FROM bcc_rewards_battlepass_claims
            WHERE identifier = ? AND charid = ? AND season = ? AND level = ? AND claim_type = ?
        ]], { character.identifier, character.charIdentifier, getSeasonKey(), level, track })
        return notify(src, errorMessage or BattlepassConfig.Text.invalidReward, 'error')
    end

    notify(src, BattlepassConfig.Text.rewardClaimed, 'success')
    refresh(src)
end)

RegisterCommand(BattlepassConfig.AdminAddXPCommand, function(src, args)
    if not isAdmin(src) then
        return notify(src, BattlepassConfig.Text.noPermission, 'error')
    end

    local target = tonumber(args[1])
    local amount = tonumber(args[2])
    if not target or not GetPlayerName(target) then
        return notify(src, BattlepassConfig.Text.invalidPlayer, 'error')
    end

    if not amount or amount <= 0 then
        return notify(src, BattlepassConfig.Text.invalidAmount, 'error')
    end

    if addXPToSource(target, amount, ('admin:%s'):format(src)) then
        notify(target, BattlepassConfig.Text.xpAdded, 'success')
        notify(src, BattlepassConfig.Text.xpAdded, 'success')
    end
end, false)

RegisterCommand(BattlepassConfig.AdminPremiumCommand, function(src, args)
    if not isAdmin(src) then
        return notify(src, BattlepassConfig.Text.noPermission, 'error')
    end

    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        return notify(src, BattlepassConfig.Text.invalidPlayer, 'error')
    end

    if grantPremiumToSource(target, ('admin:%s'):format(src)) then
        notify(target, BattlepassConfig.Text.premiumGranted, 'success')
        notify(src, BattlepassConfig.Text.premiumGranted, 'success')
        refresh(target)
    end
end, false)

function AddBattlepassXP(src, amount, reason)
    return addXPToSource(tonumber(src), amount, reason or 'export')
end

function GetBattlepassXP(src)
    local character = getCharacter(tonumber(src))
    if not character then
        return 0
    end

    return getProgress(character.identifier, character.charIdentifier).xp
end

function HasBattlepassPremium(src)
    local character = getCharacter(tonumber(src))
    if not character then
        return false
    end

    return getProgress(character.identifier, character.charIdentifier).premium
end

function GrantBattlepassPremium(src, reason)
    return grantPremiumToSource(tonumber(src), reason or 'export')
end

function AddBattlepassObjective(src, objectiveId, amount, reason)
    return addObjectiveProgressToSource(src, objectiveId, amount or 1, reason or 'export')
end

function GetBattlepassObjectives(src)
    local character = getCharacter(tonumber(src))
    if not character then
        return {}
    end

    return buildObjectivePayload(character.identifier, character.charIdentifier)
end

AddEventHandler(BattlepassConfig.Objectives.progressEvent, function(target, objectiveId, amount, reason)
    addObjectiveProgressToSource(target, objectiveId, amount or 1, reason or 'event')
end)

CreateThread(function()
    local interval = math.max(1, tonumber(BattlepassConfig.OnlineXPIntervalMinutes or 60) or 60) * 60000
    local xpPerInterval = math.floor((tonumber(BattlepassConfig.OnlineXPPerHour or 0) or 0) * ((interval / 60000) / 60))

    if xpPerInterval <= 0 then
        return
    end

    while true do
        Wait(interval)

        for _, playerId in ipairs(GetPlayers()) do
            local src = tonumber(playerId)
            local character = getCharacter(src)
            if character then
                local job = tostring(character.job or ''):lower()
                if idleJobs[job] then
                    addXPToSource(src, xpPerInterval, 'online_idle')
                end
            end
        end
    end
end)
