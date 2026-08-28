VORPCore = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()

local function IsAllowedToManageCode(source)
    local user = VORPCore.getUser(source)
    if not user then return false end
    local group = user.getGroup

    for _, allowed in pairs(Config.allowedGroups) do
        if group == allowed then
            return true
        end
    end

    return false
end

if Config.debug then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    function devPrint(message) end
end

RegisterNetEvent("bcc-rewards:server:redeemCode", function(code)
    local source = source
    local user = VORPCore.getUser(source)
    if not user then return end

    local character = user.getUsedCharacter
    if not character then return end

    local identifier = user.getIdentifier()
    local id = MySQL.scalar.await('SELECT `identifier` FROM `bcc_rewardcodes_users` WHERE `identifier` = ? LIMIT 1', { identifier })

    if id then
        devPrint(_U("already_redeemed"))
        VORPCore.NotifyObjective(source, _U("already_redeemed"), 4000)
        return
    end

    if not code or code == '' then
        devPrint(_U("provide_code"))
        VORPCore.NotifyObjective(source, _U("provide_code"), 4000)
        return
    end

    local response = MySQL.single.await('SELECT `code`, `maxUse`, `currentUse`, `active` FROM `bcc_rewardcodes` WHERE `code` = ? LIMIT 1', { code })

    if not response then
        devPrint(_U("invalid_code"))
        VORPCore.NotifyObjective(source, _U("invalid_code"), 4000)
        return
    end

    if response.active ~= 1 then
        devPrint(_U("code_inactive"))
        VORPCore.NotifyObjective(source, _U("code_inactive"), 4000)
        return
    end

    if response.maxUse ~= -1 and response.currentUse >= response.maxUse then
        devPrint(_U("code_max_reached"))
        VORPCore.NotifyObjective(source, _U("code_max_reached"), 4000)
        return
    end

    local items = MySQL.query.await('SELECT r.item, i.label as label, r.quantity FROM bcc_rewardcodes_items r JOIN items i ON r.item = i.item WHERE `code` = ?', { code })
    local weapons = MySQL.query.await('SELECT `weapon`, `quantity` FROM `bcc_rewardcodes_weapons` WHERE `code` = ?', { code })
    local money = MySQL.single.await('SELECT `money`, `gold` FROM `bcc_rewardcodes_money` WHERE `code` = ? LIMIT 1', { code })

    BccUtils.RPC:Notify("bcc-rewardcodes:redeemCoupon", {
        code = code,
        items = items or {},
        weapons = weapons or {},
        money = money or {}
    }, source)
end)

BccUtils.RPC:Register("bcc-rewardcodes:RedeemCoupon", function(params, cb, source)
    local code = params.code
    if not code then
        devPrint(_U("invalid_code"))
        return
    end

    local user = VORPCore.getUser(source)
    if not user then return end

    local character = user.getUsedCharacter
    if not character then return end

    local identifier = user.getIdentifier()
    local id = MySQL.scalar.await('SELECT `identifier` FROM `bcc_rewardcodes_users` WHERE `identifier` = ? LIMIT 1', { identifier })

    if id then
        devPrint(_U("already_redeemed"))
        VORPCore.NotifyObjective(source, _U("already_redeemed"), 4000)
        return
    end

    local response = MySQL.single.await('SELECT `code`, `maxUse`, `currentUse`, `active` FROM `bcc_rewardcodes` WHERE `code` = ? LIMIT 1', { code })

    if not response or not response.code then
        devPrint(_U("invalid_code"))
        VORPCore.NotifyObjective(source, _U("invalid_code"), 4000)
        return
    end

    if response.active == 0 then
        devPrint(_U("code_inactive"))
        VORPCore.NotifyObjective(source, _U("code_inactive"), 4000)
        return
    end

    if response.maxUse ~= -1 and response.currentUse >= response.maxUse then
        devPrint(_U("code_max_reached"))
        VORPCore.NotifyObjective(source, _U("code_max_reached"), 4000)
        return
    end

    local items = MySQL.query.await('SELECT `item`, `quantity` FROM `bcc_rewardcodes_items` WHERE `code` = ?', { code })
    local weapons = MySQL.query.await('SELECT `weapon`, `quantity` FROM `bcc_rewardcodes_weapons` WHERE `code` = ?', { code })
    local money = MySQL.single.await('SELECT `money`, `gold` FROM `bcc_rewardcodes_money` WHERE `code` = ? LIMIT 1', { code })

    local message = _U("you_received")

    if items then
        for _, item in ipairs(items) do
            exports.vorp_inventory:addItem(source, item.item, item.quantity)
            message = message .. " " .. item.quantity .. "x " .. item.item .. ","
        end
    end

    if weapons then
        for i = 1, #weapons do
            local weapon = weapons[i]
            local ammo = { ["nothing"] = 0 }
            local components = { ["nothing"] = 0 }
            local serial = "RewardCoupon-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
            local label = "Reward Weapon"

            exports.vorp_inventory:createWeapon(
                source,
                weapon.weapon,
                ammo,
                components,
                {},
                nil,
                label,
                serial
            )

            message = message .. " weapon: " .. weapon.weapon .. " [" .. serial .. "],"
        end
    end

    if money then
        if money.money > 0 then
            character.addCurrency(0, money.money)
            message = message .. " $" .. money.money .. ","
        end
        if money.gold > 0 then
            character.addCurrency(1, money.gold)
            message = message .. " " .. money.gold .. " gold,"
        end
    end

    if message:sub(-1) == "," then
        message = message:sub(1, -2)
    end

    if message ~= _U("you_received") then
        VORPCore.NotifyAvanced(source, message, "scoretimer_textures", "scoretimer_generic_tick", "COLOR_GREEN", 6000)
    end

   MySQL.insert.await('INSERT INTO `bcc_rewardcodes_users` (identifier, code) VALUES (?, ?)', { identifier, code })
    MySQL.update.await('UPDATE bcc_rewardcodes SET currentUse = currentUse + 1 WHERE code = ?', { code })

    cb(true)
end)

BccUtils.RPC:Register("bcc-rewardcodes:validateMenuOpenPermission", function(_, cb, source)
    if IsAllowedToManageCode(source) then
        return cb(true)
    end
    devPrint(_U("missing_permissions"))
    cb(false)
end)

BccUtils.RPC:Register("bcc-rewardcodes:fetchItemData", function(params, cb, source)
    if not IsAllowedToManageCode(source) then
        devPrint(_U("missing_permissions"))
        return cb({})
    end

    local id = params.id
    local response = MySQL.single.await('SELECT `id`, `code`, `item`, `quantity` FROM `bcc_rewardcodes_items` WHERE `id` = ? LIMIT 1', { id })

    if not response then
        devPrint(_U("no_item_data"))
        return cb({})
    end

    devPrint(_U("item_data") .. json.encode(response))
    local cbData = {
        id = response.id,
        code = response.code,
        item = response.item,
        quantity = response.quantity
    }

    cb(cbData)
end)

BccUtils.RPC:Register("bcc-rewardcodes:fetchWeaponData", function(params, cb, source)
    local id = params.id
    if not id then return cb(nil) end
    if not IsAllowedToManageCode(source) then return cb(nil) end

    local response = MySQL.single.await('SELECT `id`, `code`, `weapon`, `quantity` FROM `bcc_rewardcodes_weapons` WHERE `id` = ? LIMIT 1', { id })
    if not response then return cb(nil) end

    cb({
        id = response.id,
        code = response.code,
        weapon = response.weapon,
        quantity = response.quantity
    })
end)

BccUtils.RPC:Register("bcc-rewardcodes:fetchCouponItemsData", function(params, cb, source)
    if not IsAllowedToManageCode(source) then return cb({}) end

    local code = params.code
    local response = MySQL.query.await('SELECT `id`, `item` FROM `bcc_rewardcodes_items` WHERE `code` = ?', { code })
    cb(response or {})
end)

BccUtils.RPC:Register("bcc-rewardcodes:fetchCouponWeaponsData", function(params, cb, source)
    if not IsAllowedToManageCode(source) then return cb({}) end

    local code = params.code
    local response = MySQL.query.await('SELECT `id`, `weapon` FROM `bcc_rewardcodes_weapons` WHERE `code` = ?', { code })
    cb(response or {})
end)

BccUtils.RPC:Register("bcc-rewardcodes:fetchCouponMoneyData", function(params, cb, source)
    if not IsAllowedToManageCode(source) then return cb({}) end

    local code = params.code
    local row = MySQL.single.await('SELECT `money`, `gold` FROM `bcc_rewardcodes_money` WHERE `code` = ? LIMIT 1', { code })
    cb(row or {})
end)

BccUtils.RPC:Register("bcc-rewardcodes:fetchCouponData", function(params, cb, source)
    if not IsAllowedToManageCode(source) then return cb(nil) end

    local code = params.code
    local row = MySQL.single.await('SELECT `code`, `currentUse`, `maxUse`, `active` FROM `bcc_rewardcodes` WHERE `code` = ? LIMIT 1', { code })
    cb(row or nil)
end)

BccUtils.RPC:Register("bcc-rewardcodes:fetchAllCoupons", function(_, cb, source)
    if not IsAllowedToManageCode(source) then
        devPrint(_U("missing_permissions"))
        return cb({})
    end

    local response = MySQL.query.await('SELECT `code` FROM `bcc_rewardcodes`')
    cb(response or {})
end)

BccUtils.RPC:Register("bcc-rewardcodes:createNewCoupon", function(params, cb, source)
    if not IsAllowedToManageCode(source) then return cb(false) end

    local code = params.code
    local maxUsage = params.maxUsage or -1

    if not code or maxUsage == nil then return cb(false) end

    local queries = {
        { query = 'INSERT INTO `bcc_rewardcodes` (code, maxUse) VALUES (?, ?)', values = { code, maxUsage }},
        { query = 'INSERT INTO `bcc_rewardcodes_money` (code, money, gold) VALUES (?, ?, ?)', values = { code, 0, 0 }},
    }

    local success = MySQL.transaction.await(queries)
    cb(success)
end)

BccUtils.RPC:Register("bcc-rewardcodes:updateCouponItem", function(params, cb, source)
    if not IsAllowedToManageCode(source) then return cb(false) end

    local id = params.id
    local quantity = params.quantity

    if not id or not quantity then return cb(false) end

    local affectedRows = MySQL.update.await('UPDATE bcc_rewardcodes_items SET quantity = ? WHERE id = ?', { quantity, id })

    cb(affectedRows > 0)
end)

BccUtils.RPC:Register("bcc-rewardcodes:deleteCouponItem", function(params, cb, source)
    if not IsAllowedToManageCode(source) then return cb(false) end

    local id = params.id
    if not id then return cb(false) end

    local affectedRows = MySQL.update.await('DELETE FROM bcc_rewardcodes_items WHERE id = ?', { id })

    cb(affectedRows > 0)
end)

BccUtils.RPC:Register("bcc-rewardcodes:updateCouponWeapon", function(params, cb, source)
    local id = params.id
    local quantity = params.quantity

    if not id or not quantity then return cb(false) end
    if not IsAllowedToManageCode(source) then return cb(false) end

    local affectedRows = MySQL.update.await('UPDATE bcc_rewardcodes_weapons SET quantity = ? WHERE id = ?', { quantity, id })

    cb(affectedRows > 0)
end)

BccUtils.RPC:Register("bcc-rewardcodes:deleteCouponWeapon", function(params, cb, source)
    local id = params.id

    if not id then return cb(false) end
    if not IsAllowedToManageCode(source) then return cb(false) end

    local affectedRows = MySQL.update.await('DELETE FROM bcc_rewardcodes_weapons WHERE id = ?', { id })

    cb(affectedRows > 0)
end)

BccUtils.RPC:Register("bcc-rewardcodes:updateCouponMoneyData", function(params, cb, source)
    local code = params.code
    local money = params.money
    local gold = params.gold
    if not code or money == nil or gold == nil then
        return cb(false)
    end

    if not IsAllowedToManageCode(source) then
        return cb(false)
    end

    local affectedRows = MySQL.update.await('UPDATE bcc_rewardcodes_money SET `money` = ?, `gold` = ? WHERE `code` = ?', {
        money or 0, gold or 0, code
    })

    cb(affectedRows > 0)
end)

BccUtils.RPC:Register("bcc-rewardcodes:updateCouponData", function(params, cb, source)
    local code = params.code
    local maxUse = params.maxUse
    local active = params.active

    if not code or maxUse == nil or active == nil then
        return cb(false)
    end

    if not IsAllowedToManageCode(source) then
        return cb(false)
    end

    local affectedRows = MySQL.update.await('UPDATE bcc_rewardcodes SET `maxUse` = ?, `active` = ? WHERE code = ?', {
        maxUse, active, code
    })

    cb(affectedRows > 0)
end)

BccUtils.RPC:Register("bcc-rewardcodes:addItemToCoupon", function(params, cb, source)
    local code = params.code
    local item = params.item
    local quantity = params.quantity

    if not code or not item or not quantity or quantity < 1 then return cb(false) end
    if not IsAllowedToManageCode(source) then return cb(false) end

    local id = MySQL.insert.await('INSERT INTO `bcc_rewardcodes_items` (code, item, quantity) VALUES (?, ?, ?)', {
        code, item, quantity
    })

    cb(id ~= nil)
end)

BccUtils.RPC:Register("bcc-rewardcodes:addWeaponToCoupon", function(params, cb, source)
    local code = params.code
    local weapon = params.weapon
    local quantity = params.quantity

    if not code or not weapon or not quantity or quantity < 1 then
        return cb(false)
    end

    if not IsAllowedToManageCode(source) then
        return cb(false)
    end

    local id = MySQL.insert.await('INSERT INTO `bcc_rewardcodes_weapons` (code, weapon, quantity) VALUES (?, ?, ?)', {
        code, weapon, quantity
    })

    cb(id ~= nil)
end)

BccUtils.RPC:Register("bcc-rewardcodes:fetchItems", function(_, cb, source)
    -- Check if the player has permission to manage codes
    if not IsAllowedToManageCode(source) then
        devPrint(_U("missing_permissions"))
        return cb({})
    end

    -- Query the database to fetch the list of items
    local items = MySQL.query.await('SELECT `item`, `label` FROM `items`', {})

    -- Format the items for the dropdown menu
    local formattedItems = {}
    for _, item in ipairs(items) do
        table.insert(formattedItems, {
            text = item.label, -- Display text in the dropdown
            value = item.item  -- Value associated with the selection
        })
    end

    -- Return the formatted items to the client
    cb(formattedItems)
end)
