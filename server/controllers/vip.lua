local VORPcore = exports.vorp_core:GetCore()

local RESOURCE_NAME = GetCurrentResourceName()

RegisterCommand('tebexid', function(source)

    local identifiers = GetPlayerIdentifiers(source)

    for _, identifier in ipairs(identifiers) do

        if string.find(identifier, 'license:') then

            TriggerClientEvent('chat:addMessage', source, {
                args = {
                    '^2Tebex License:',
                    identifier
                }
            })

            print(identifier)
            break
        end
    end

end)

local function notify(src, message, kind)
    TriggerClientEvent('bcc-rewards:vip:client:notify', src, message, kind or 'info')
end

local function sendVipWebhook(title, description)
    print(('[%s] %s: %s'):format(RESOURCE_NAME, title, description:gsub('\n', ' | ')))

    if not VipConfig.Webhook or not VipConfig.Webhook.enabled or VipConfig.Webhook.url == '' then
        return
    end

    local payload = {
        username = VipConfig.Webhook.name or 'VIP Logs',
        embeds = {
            {
                title = title,
                description = description,
                color = VipConfig.Webhook.color or 15844367,
                footer = { text = os.date('%Y-%m-%d %H:%M:%S') }
            }
        }
    }

    PerformHttpRequest(VipConfig.Webhook.url, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

local function getCharacter(src)
    local user = VORPcore.getUser(src)
    if not user or not user.getUsedCharacter then
        return nil, nil
    end

    local character = user.getUsedCharacter
    if not character or not character.charIdentifier then
        return nil, nil
    end

    return user, character
end

local function isAdmin(src)
    if src == 0 then
        return true
    end

    if VipConfig.AdminAce and VipConfig.AdminAce ~= '' and IsPlayerAceAllowed(src, VipConfig.AdminAce) then
        return true
    end

    local _, character = getCharacter(src)
    if not character then
        return false
    end

    local group = tostring(character.group or ''):lower()
    return VipConfig.AdminGroups[group] == true
end

local function rewardSummary(packageData)
    local parts = {}
    local rewards = packageData and packageData.rewards or {}

    if tonumber(rewards.tokens or 0) > 0 then
        parts[#parts + 1] = ('tokens:%s'):format(rewards.tokens)
    end

    for _, item in ipairs(rewards.items or {}) do
        parts[#parts + 1] = ('item:%sx%s'):format(item.name, tonumber(item.count or 1) or 1)
    end

    for _, command in ipairs(rewards.commands or {}) do
        parts[#parts + 1] = ('cmd:%s'):format(command)
    end

    return table.concat(parts, ' | ')
end

local function normalizeIdentifier(value)
    if value == nil then
        return nil
    end

    local trimmed = tostring(value):gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' then
        return nil
    end

    return trimmed:lower()
end

local function normalizeTebexTarget(value)
    local normalized = normalizeIdentifier(value)
    if not normalized then
        return nil
    end

    if normalized:find(':', 1, true) then
        return normalized
    end

    if normalized:match('^%d+$') then
        return ('fivem:%s'):format(normalized)
    end

    return normalized
end

local function getPlayerIdentifiersNormalized(src, character)
    local identifiers = {}
    local seen = {}

    local function add(value)
        local normalized = normalizeIdentifier(value)
        if normalized and not seen[normalized] then
            identifiers[#identifiers + 1] = normalized
            seen[normalized] = true
        end

        local bareFiveM = normalized and normalized:match('^fivem:(%d+)$')
        if bareFiveM and not seen[bareFiveM] then
            identifiers[#identifiers + 1] = bareFiveM
            seen[bareFiveM] = true
        end
    end

    add(character and character.identifier or nil)

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        add(GetPlayerIdentifier(src, i))
    end

    return identifiers
end

local function getPrimaryIdentifier(src, character)
    return getPlayerIdentifiersNormalized(src, character)[1]
end

local function packageToMenuEntry(packageId, packageData)
    return {
        id = packageId,
        label = packageData.label or packageId,
        price = packageData.price or 'N/A',
        description = packageData.description or '',
        tebex_url = packageData.tebex_url or VipConfig.StoreUrl,
        rewards = packageData.rewards or {}
    }
end

local function resolvePackageId(packageId)
    local normalizedPackageId = normalizeIdentifier(packageId)
    if not normalizedPackageId then
        return nil
    end

    if VipConfig.Packages[normalizedPackageId] then
        return normalizedPackageId
    end

    for configuredPackageId, packageData in pairs(VipConfig.Packages) do
        local tebexUrl = tostring(packageData.tebex_url or ''):lower()
        local tebexPackageId = tebexUrl:match('/package/(%d+)')

        if tebexPackageId and tebexPackageId == normalizedPackageId then
            return configuredPackageId
        end
    end

    return nil
end

local function getTokenBalance(identifier, charId)
    local row = MySQL.single.await([[
        SELECT id, balance
        FROM bcc_vip_tokens
        WHERE identifier = ? AND (charid = ? OR charid IS NULL)
        ORDER BY charid DESC
        LIMIT 1
    ]], { identifier, charId })

    return row and tonumber(row.balance) or 0, row and row.id or nil
end

local function getCharacterRolBalance(character)
    local balance = tonumber(character.rol)

    if not balance and type(character.Rol) == 'function' then
        balance = tonumber(character.Rol())
    end

    return balance or 0
end

local function syncTokenBalanceToRol(identifier, charId, character)
    local savedBalance, tokenRowId = getTokenBalance(identifier, charId)
    local rolBalance = getCharacterRolBalance(character)

    if tokenRowId and savedBalance ~= rolBalance then
        MySQL.update.await([[
            UPDATE bcc_vip_tokens
            SET balance = ?,
                charid = COALESCE(charid, ?),
                updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ]], {
            rolBalance,
            charId,
            tokenRowId
        })

        return rolBalance
    end

    if not tokenRowId then
        MySQL.insert.await([[
            INSERT INTO bcc_vip_tokens (identifier, charid, balance)
            VALUES (?, ?, ?)
        ]], {
            identifier,
            charId,
            rolBalance
        })
    end

    return rolBalance
end

local function addTokenBalance(identifier, charId, amount)
    amount = tonumber(amount or 0) or 0
    if amount <= 0 then
        return true
    end

    local existing = MySQL.single.await([[
        SELECT id, balance
        FROM bcc_vip_tokens
        WHERE identifier = ? AND (charid = ? OR charid IS NULL)
        ORDER BY charid DESC
        LIMIT 1
    ]], { identifier, charId })

    if existing then
        MySQL.update.await('UPDATE bcc_vip_tokens SET balance = balance + ?, charid = COALESCE(charid, ?) WHERE id = ?', {
            amount,
            charId,
            existing.id
        })
    else
        MySQL.insert.await([[
            INSERT INTO bcc_vip_tokens (identifier, charid, balance)
            VALUES (?, ?, ?)
        ]], {
            identifier,
            charId,
            amount
        })
    end

    return true
end

local function getCharacterIdentifierByCharId(charId)
    charId = tonumber(charId)
    if not charId then
        return nil
    end

    local row = MySQL.single.await([[
        SELECT identifier
        FROM characters
        WHERE charidentifier = ?
        LIMIT 1
    ]], { charId })

    return row and normalizeIdentifier(row.identifier) or nil
end

local function buildPackageList()
    local packages = {}

    for packageId, packageData in pairs(VipConfig.Packages) do
        packages[#packages + 1] = packageToMenuEntry(packageId, packageData)
    end

    table.sort(packages, function(a, b)
        return a.label < b.label
    end)

    return packages
end

local function getPendingPurchasesForCharacter(identifiers, charId)
    identifiers = identifiers or {}
    local params = {}
    local placeholders = {}

    for _, identifier in ipairs(identifiers) do
        params[#params + 1] = identifier
        placeholders[#placeholders + 1] = '?'
    end

    if #placeholders == 0 then
        return {}
    end

    params[#params + 1] = charId
    params[#params + 1] = charId
    params[#params + 1] = tostring(charId)

    return MySQL.query.await([[
        SELECT id, transaction_id, package_id, package_label, reward_summary, created_at
        FROM bcc_vip_purchases
        WHERE status = 'pending'
          AND (
            (target_identifier IN (]] .. table.concat(placeholders, ',') .. [[) AND (target_charid IS NULL OR target_charid = ?))
            OR target_charid = ?
            OR target_identifier = ?
          )
        ORDER BY created_at ASC
    ]], params) or {}
end

local function findSourceByIdentifier(targetIdentifier)
    local normalizedTarget = normalizeTebexTarget(targetIdentifier)
    if not normalizedTarget then
        return nil, nil
    end

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        local _, character = getCharacter(src)
        if character then
            for _, identifier in ipairs(getPlayerIdentifiersNormalized(src, character)) do
                if identifier == normalizedTarget then
                    return src, character
                end
            end
        end
    end

    return nil, nil
end

local function formatCommand(template, context)
    return (template:gsub('{(%w+)}', function(key)
        local value = context[key]
        if value == nil then
            return ''
        end

        return tostring(value)
    end))
end

local function updatePurchaseStatus(purchaseId, status, fields)
    local row = MySQL.single.await('SELECT * FROM bcc_vip_purchases WHERE id = ? LIMIT 1', { purchaseId })
    if not row then
        return
    end

    fields = fields or {}
    local targetSource = fields.target_source
    if targetSource == nil then
        targetSource = row.target_source
    end

    local targetCharId = fields.target_charid
    if targetCharId == nil then
        targetCharId = row.target_charid
    end

    local failureReason = fields.failure_reason
    if failureReason == nil then
        failureReason = row.failure_reason
    end

    local claimedAt = fields.claimed_at
    local claimedValue = row.claimed_at
    if claimedAt == false then
        claimedValue = nil
    elseif claimedAt ~= nil then
        claimedValue = claimedAt
    end

    MySQL.update.await([[
        UPDATE bcc_vip_purchases
        SET status = ?, target_source = ?, target_charid = ?, failure_reason = ?, claimed_at = ?
        WHERE id = ?
    ]], {
        status,
        targetSource,
        targetCharId,
        failureReason,
        claimedValue,
        purchaseId
    })
end

local function insertDeliveryLog(src, character, identifier, purchaseRow, tokenAmount, deliveryType)
    MySQL.insert.await([[
        INSERT INTO bcc_vip_delivery_logs (
            purchase_id,
            transaction_id,
            package_id,
            package_label,
            target_identifier,
            target_charid,
            target_source,
            player_name,
            tokens_added,
            rol_added,
            delivery_type
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        purchaseRow.id,
        purchaseRow.transaction_id,
        purchaseRow.package_id,
        purchaseRow.package_label,
        identifier,
        character.charIdentifier,
        src,
        GetPlayerName(src),
        tokenAmount,
        tokenAmount,
        deliveryType or 'claim'
    })
end

local function grantPackage(src, purchaseRow)
    local _, character = getCharacter(src)
    if not character then
        return false, VipConfig.Messages.no_character
    end

    local packageData = VipConfig.Packages[purchaseRow.package_id]
    if not packageData then
        return false, VipConfig.Messages.invalid_package
    end

    local rewards = packageData.rewards or {}
    local identifier = getPrimaryIdentifier(src, character) or character.identifier
    local tokenAmount = tonumber(rewards.tokens or 0) or 0

    if tokenAmount > 0 then
        addTokenBalance(identifier, character.charIdentifier, tokenAmount)
        character.addCurrency(2, tokenAmount)
        insertDeliveryLog(src, character, identifier, purchaseRow, tokenAmount, purchaseRow.delivery_type or 'claim')
        sendVipWebhook('VIP Tokens Delivered', table.concat({
            ('Player: %s %s (%s)'):format(character.firstname or '-', character.lastname or '-', GetPlayerName(src) or src),
            ('Identifier: %s'):format(identifier),
            ('Character ID: %s'):format(character.charIdentifier),
            ('Package: %s'):format(purchaseRow.package_id),
            ('Purchase ID: %s'):format(purchaseRow.id),
            ('Transaction: %s'):format(purchaseRow.transaction_id or '-'),
            ('Tokens/Rol Added: %s'):format(tokenAmount)
        }, '\n'))
    end

    local context = {
        source = src,
        charid = character.charIdentifier,
        identifier = identifier,
        firstname = character.firstname,
        lastname = character.lastname,
        package = purchaseRow.package_id,
        purchase_id = purchaseRow.id,
        transaction = purchaseRow.transaction_id,
        tokens = tokenAmount
    }

    for _, command in ipairs(rewards.commands or {}) do
        local formatted = formatCommand(command, context)
        if formatted ~= '' then
            ExecuteCommand(formatted)
        end
    end

    return true, VipConfig.Messages.claimed
end

local function sanitizeMetadataValue(value)
    if value == nil or value == '' then
        return nil
    end

    return tostring(value)
end

local function insertQueuedPurchase(targetIdentifier, packageId, transactionId, targetSource, targetCharId, tebexTarget, tebexData)
    local packageData = VipConfig.Packages[packageId]
    if not packageData then
        return nil, VipConfig.Messages.invalid_package
    end

    tebexData = tebexData or {}

    local inserted
    local ok, err = pcall(function()
        inserted = MySQL.insert.await([[
            INSERT INTO bcc_vip_purchases (
                transaction_id,
                package_id,
                package_label,
                tebex_target,
                tebex_username,
                tebex_server,
                payment_price,
                payment_currency,
                payment_time,
                payment_date,
                customer_email,
                customer_ip,
                package_price,
                package_expiry,
                package_name,
                target_source,
                target_identifier,
                target_charid,
                status,
                reward_summary,
                raw_variables
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?, ?)
        ]], {
            transactionId and tostring(transactionId) or nil,
            packageId,
            packageData.label or packageId,
            tebexTarget,
            sanitizeMetadataValue(tebexData.username),
            sanitizeMetadataValue(tebexData.server),
            sanitizeMetadataValue(tebexData.price),
            sanitizeMetadataValue(tebexData.currency),
            sanitizeMetadataValue(tebexData.time),
            sanitizeMetadataValue(tebexData.date),
            sanitizeMetadataValue(tebexData.email),
            sanitizeMetadataValue(tebexData.ip),
            sanitizeMetadataValue(tebexData.packagePrice),
            sanitizeMetadataValue(tebexData.packageExpiry),
            sanitizeMetadataValue(tebexData.packageName),
            targetSource,
            targetIdentifier,
            targetCharId,
            rewardSummary(packageData),
            json.encode(tebexData)
        })
    end)

    if not ok then
        local lower = string.lower(tostring(err))
        if lower:find('duplicate', 1, true) then
            return nil, VipConfig.Messages.queued_duplicate
        end

        return nil, tostring(err)
    end

    return inserted, nil
end

local function queuePurchase(targetKey, packageId, transactionId, tebexData)
    local resolvedPackageId = resolvePackageId(packageId)
    local packageData = resolvedPackageId and VipConfig.Packages[resolvedPackageId]
    if not packageData then
        return false, VipConfig.Messages.invalid_package
    end

    local tebexTarget = tostring(targetKey or '')
    local onlineSource, onlineCharacter
    local normalizedIdentifier
    local targetCharId

    local asNumber = tonumber(targetKey)
    if asNumber and GetPlayerName(asNumber) ~= nil then
        local _, character = getCharacter(asNumber)
        if not character then
            return false, VipConfig.Messages.no_character
        end

        onlineSource = asNumber
        onlineCharacter = character
        normalizedIdentifier = getPrimaryIdentifier(asNumber, character)
        targetCharId = character.charIdentifier
    else
        local charIdentifier = getCharacterIdentifierByCharId(asNumber)
        if charIdentifier then
            normalizedIdentifier = charIdentifier
            targetCharId = asNumber
        else
            normalizedIdentifier = normalizeTebexTarget(targetKey)
        end

        onlineSource, onlineCharacter = findSourceByIdentifier(normalizedIdentifier)
    end

    if not normalizedIdentifier then
        return false, VipConfig.Messages.invalid_identifier
    end

    local inserted, err = insertQueuedPurchase(
        normalizedIdentifier,
        resolvedPackageId,
        transactionId,
        onlineSource,
        onlineCharacter and onlineCharacter.charIdentifier or targetCharId,
        tebexTarget,
        tebexData
    )

    if not inserted then
        return false, err
    end

    if VipConfig.AutoClaimWhenQueued and onlineSource and onlineCharacter then
        local purchaseRow = MySQL.single.await('SELECT * FROM bcc_vip_purchases WHERE id = ? LIMIT 1', { inserted })
        purchaseRow.delivery_type = 'auto_queue'
        local success, message = grantPackage(onlineSource, purchaseRow)
        if success then
            updatePurchaseStatus(inserted, 'claimed', {
                target_source = onlineSource,
                target_charid = onlineCharacter.charIdentifier,
                failure_reason = nil,
                claimed_at = os.date('%Y-%m-%d %H:%M:%S')
            })
            return true, VipConfig.Messages.queued_auto, onlineSource
        end

        updatePurchaseStatus(inserted, 'pending', {
            target_source = onlineSource,
            target_charid = onlineCharacter.charIdentifier,
            failure_reason = message
        })
        return true, VipConfig.Messages.auto_claim_failed_queued, onlineSource
    end

    return true, VipConfig.Messages.queued, onlineSource
end

local function addVipTokensToSource(target, amount, adminSource)
    target = tonumber(target)
    amount = math.floor(tonumber(amount or 0) or 0)

    if not target or target <= 0 or not GetPlayerName(target) then
        return false, VipConfig.Messages.invalid_player
    end

    if amount <= 0 then
        return false, 'Invalid token amount.'
    end

    local _, character = getCharacter(target)
    if not character then
        return false, VipConfig.Messages.no_character
    end

    local identifier = getPrimaryIdentifier(target, character) or character.identifier
    local balanceBefore = getCharacterRolBalance(character)

    character.addCurrency(2, amount)
    addTokenBalance(identifier, character.charIdentifier, amount)

    local balanceAfter = balanceBefore + amount
    sendVipWebhook('VIP Tokens Added By Admin', table.concat({
        ('Admin: %s'):format(adminSource == 0 and 'console' or (GetPlayerName(adminSource) or adminSource)),
        ('Player: %s'):format(GetPlayerName(target) or target),
        ('Character: %s %s'):format(character.firstname or '-', character.lastname or '-'),
        ('Identifier: %s'):format(identifier),
        ('Character ID: %s'):format(character.charIdentifier),
        ('Tokens Added: %s'):format(amount),
        ('Balance: %s -> %s'):format(balanceBefore, balanceAfter)
    }, '\n'))

    return true, ('Added %s VIP tokens to %s.'):format(amount, GetPlayerName(target) or target)
end

local function getAdminPurchases()
    return MySQL.query.await(([[
        SELECT id, transaction_id, package_id, package_label, tebex_target, tebex_username, tebex_server,
               payment_price, payment_currency, payment_time, payment_date, customer_email, customer_ip,
               package_price, package_expiry, package_name, target_identifier, target_charid, status,
               reward_summary, failure_reason, raw_variables, created_at, claimed_at
        FROM bcc_vip_purchases
        ORDER BY created_at DESC
        LIMIT %d
    ]]):format(tonumber(VipConfig.AdminLogLimit or 50) or 50)) or {}
end

local function buildMenuPayload(src)
    local _, character = getCharacter(src)
    if not character then
        return nil, VipConfig.Messages.no_character
    end

    local identifier = getPrimaryIdentifier(src, character)
    if not identifier then
        return nil, VipConfig.Messages.invalid_identifier
    end
    local identifiers = getPlayerIdentifiersNormalized(src, character)

    return {
        serverId = src,
        charId = character.charIdentifier,
        identifier = identifier,
        tokenBalance = syncTokenBalanceToRol(identifier, character.charIdentifier, character),
        pending = getPendingPurchasesForCharacter(identifiers, character.charIdentifier),
        packages = buildPackageList(),
        isAdmin = isAdmin(src),
        adminPurchases = {}
    }
end

local function sendAdminMenu(src)
    if not isAdmin(src) then
        notify(src, VipConfig.Messages.admin_denied, 'error')
        return
    end

    local payload, err = buildMenuPayload(src)
    if not payload then
        notify(src, err, 'error')
        return
    end

    payload.isAdmin = true
    payload.adminPurchases = getAdminPurchases()
    TriggerClientEvent('bcc-rewards:vip:client:openMenu', src, payload)
end

local function deliverPendingForSource(src)
    local _, character = getCharacter(src)
    if not character then
        return
    end

    local identifier = getPrimaryIdentifier(src, character)
    if not identifier then
        return
    end

    local pending = getPendingPurchasesForCharacter(getPlayerIdentifiersNormalized(src, character), character.charIdentifier)
    for _, purchase in ipairs(pending) do
        local purchaseRow = MySQL.single.await('SELECT * FROM bcc_vip_purchases WHERE id = ? LIMIT 1', { purchase.id })
        if purchaseRow then
            purchaseRow.delivery_type = 'auto_pending'
            local success, message = grantPackage(src, purchaseRow)
            if success then
                updatePurchaseStatus(purchase.id, 'claimed', {
                    target_source = src,
                    target_charid = character.charIdentifier,
                    failure_reason = nil,
                    claimed_at = os.date('%Y-%m-%d %H:%M:%S')
                })
                notify(src, VipConfig.Messages.queued_auto, 'success')
            else
                updatePurchaseStatus(purchase.id, 'pending', {
                    target_source = src,
                    target_charid = character.charIdentifier,
                    failure_reason = message
                })
            end
        end
    end
end

RegisterNetEvent('bcc-rewards:vip:server:openMenu', function()
    local src = source
    local payload, err = buildMenuPayload(src)
    if not payload then
        notify(src, err, 'error')
        return
    end

    TriggerClientEvent('bcc-rewards:vip:client:openMenu', src, payload)
end)

RegisterNetEvent('bcc-rewards:vip:server:openAdminMenu', function()
    local src = source
    sendAdminMenu(src)
end)

RegisterNetEvent('bcc-rewards:vip:server:claimPurchase', function(purchaseId)
    local src = source
    local _, character = getCharacter(src)
    if not character then
        notify(src, VipConfig.Messages.no_character, 'error')
        return
    end

    local identifiers = getPlayerIdentifiersNormalized(src, character)
    if #identifiers == 0 then
        notify(src, VipConfig.Messages.invalid_identifier, 'error')
        return
    end

    local purchase = MySQL.single.await('SELECT * FROM bcc_vip_purchases WHERE id = ? LIMIT 1', { tonumber(purchaseId) })

    if not purchase or purchase.status ~= 'pending' then
        notify(src, VipConfig.Messages.no_pending, 'error')
        return
    end

    local allowed = tonumber(purchase.target_charid) == tonumber(character.charIdentifier)
        or tostring(purchase.target_identifier) == tostring(character.charIdentifier)

    if not allowed then
        for _, identifier in ipairs(identifiers) do
            if purchase.target_identifier == identifier
                and (purchase.target_charid == nil or tonumber(purchase.target_charid) == tonumber(character.charIdentifier)) then
                allowed = true
                break
            end
        end
    end

    if not allowed then
        notify(src, VipConfig.Messages.no_pending, 'error')
        return
    end

    purchase.delivery_type = 'manual_claim'
    local success, message = grantPackage(src, purchase)
    if not success then
        updatePurchaseStatus(purchase.id, 'pending', {
            target_source = src,
            target_charid = character.charIdentifier,
            failure_reason = message or VipConfig.Messages.claim_failed
        })
        notify(src, message or VipConfig.Messages.claim_failed, 'error')
        return
    end

    updatePurchaseStatus(purchase.id, 'claimed', {
        target_source = src,
        target_charid = character.charIdentifier,
        failure_reason = nil,
        claimed_at = os.date('%Y-%m-%d %H:%M:%S')
    })

    notify(src, message, 'success')
end)

RegisterCommand('bcc_vip_queue', function(commandSource, args)
    if commandSource ~= 0 then
        return
    end

    local targetKey = args[1]
    local packageId = args[2]
    local transactionId = args[3]
    local tebexData = {
        id = args[1],
        packageId = args[2],
        transaction = args[3],
        username = args[4],
        server = args[5],
        price = args[6],
        currency = args[7],
        time = args[8],
        date = args[9],
        email = args[10],
        ip = args[11],
        packagePrice = args[12],
        packageExpiry = args[13],
        packageName = args[14] and table.concat(args, ' ', 14) or nil
    }

    if not targetKey or targetKey == '' then
        print(('[%s] Usage: bcc_vip_queue <id> <packageId> <transaction> [username] [server] [price] [currency] [time] [date] [email] [ip] [packagePrice] [packageExpiry] [packageName]'):format(RESOURCE_NAME))
        return
    end

    if not packageId or packageId == '' then
        print(('[%s] Missing packageId.'):format(RESOURCE_NAME))
        return
    end

    local success, message, notifySource = queuePurchase(targetKey, packageId, transactionId, tebexData)
    print(('[%s] queue result for target %s package %s: %s'):format(
        RESOURCE_NAME,
        tostring(targetKey),
        packageId,
        tostring(message)
    ))

    if notifySource then
        notify(notifySource, message, success and 'success' or 'error')
    end
end, true)

RegisterCommand(VipConfig.AdminAddTokensCommand or 'addviptokens', function(commandSource, args)
    if commandSource ~= 0 and not isAdmin(commandSource) then
        notify(commandSource, VipConfig.Messages.admin_denied, 'error')
        return
    end

    local target = tonumber(args[1])
    local amount = tonumber(args[2])

    if not target or not amount then
        local usage = ('Usage: %s <player_id> <amount>'):format(VipConfig.AdminAddTokensCommand or 'addviptokens')
        if commandSource == 0 then
            print(('[%s] %s'):format(RESOURCE_NAME, usage))
        else
            notify(commandSource, usage, 'error')
        end
        return
    end

    local success, message = addVipTokensToSource(target, amount, commandSource)
    if commandSource == 0 then
        print(('[%s] %s'):format(RESOURCE_NAME, message))
    else
        notify(commandSource, message, success and 'success' or 'error')
    end

    if success then
        notify(target, ('%s %s added to your account.'):format(math.floor(amount), VipConfig.TokenShortLabel or 'Tokens'), 'success')
    end
end, false)

AddEventHandler('vorp:SelectedCharacter', function(src)
    if tonumber(src) then
        Wait(1500)
        deliverPendingForSource(tonumber(src))
    end
end)

AddEventHandler('playerJoining', function(_, _, _)
    local src = source
    CreateThread(function()
        Wait(5000)
        deliverPendingForSource(src)
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= RESOURCE_NAME then
        return
    end

    print(('[%s] VIP Tebex queue ready. Open /reward in game. Tebex command: bcc_vip_queue <id> <packageId> <transaction> [username] [server] [price] [currency] [time] [date] [email] [ip] [packagePrice] [packageExpiry] [packageName]'):format(RESOURCE_NAME))
end)
