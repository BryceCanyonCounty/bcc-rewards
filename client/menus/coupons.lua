VORPCore = exports.vorp_core:GetCore()
FeatherMenu = exports['feather-menu'].initiate()
BccUtils = exports['bcc-utils'].initiate()
-- Helper function for debugging in DevMode
if Config.debug then
    function devPrint(message)
       print("^1[DEV MODE]^3 " .. message .. "^0")
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

CreateThread(function()
    while true do
        Wait(1800000)


            BccUtils.RPC:Call("bcc-rewardcodes:giveDiscordRoleReward", {}, function(success)
                if success then
                    devPrint("Reward granted for Discord role.")
                else
                    devPrint("Reward not granted. Cooldown or missing role.")
                end
            end)
    end
end)

CouponManageMenu = FeatherMenu:RegisterMenu("bcc-rewardcodes:menu:manageMenu", BccRewards.MenuOptions())

function ManageItem(id)
    local itemData = BccUtils.RPC:CallAsync("bcc-rewardcodes:fetchItemData", { id = id })
    if not itemData then return end

    local couponItemPage = CouponManageMenu:RegisterPage("bcc-rewardcodes:couponItemPage")

    couponItemPage:RegisterElement('header', {
        value = _U("manageItem"),
        slot = "header",
        style = {}
    })

    couponItemPage:RegisterElement('subheader', {
        value = itemData.item,
        slot = 'header'
    })

    couponItemPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    couponItemPage:RegisterElement('slider', {
        label = _U('quantity'),
        start = itemData.quantity or 1,
        slot = "content",
        min = 1,
        max = 100,
        steps = 1,
    }, function(data)
        itemData.quantity = data.value
    end)

    couponItemPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    couponItemPage:RegisterElement('button', {
        label = _U('updateItem'),
        slot = 'footer'
    }, function()
        BccUtils.RPC:Call("bcc-rewardcodes:updateCouponItem", { id = id, quantity = itemData.quantity }, function(success)
            if success then
                VORPCore.NotifyObjective(_U("updatedItemSuccess"), 4000)
                devPrint(_U("updatedItemSuccess"))
            else
                VORPCore.NotifyObjective(_U("updateItemFail"), 4000)
                devPrint(_U("updateItemFail"))
            end
            CouponManageMenu:Close()
        end)
    end)

    couponItemPage:RegisterElement('button', {
        label = _U('deleteItem'),
        slot = 'footer'
    }, function()
        BccUtils.RPC:Call("bcc-rewardcodes:deleteCouponItem", { id = id }, function(success)
            if success then
                VORPCore.NotifyObjective(_U("deletedItemSuccess"), 4000)
                devPrint(_U("deletedItemSuccess"))
            else
                VORPCore.NotifyObjective(_U("deletedItemFail"), 4000)
                devPrint(_U("deletedItemFail"))
            end
            CouponManageMenu:Close()
        end)
    end)

    couponItemPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer'
    }, function()
        OpenManageItems(itemData.code)
    end)

    couponItemPage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = couponItemPage })
end

function ManageWeapon(id)
    local weaponData = BccUtils.RPC:CallAsync("bcc-rewardcodes:fetchWeaponData", { id = id })
    if not weaponData then return end

    local couponWeaponPage = CouponManageMenu:RegisterPage("bcc-rewardcodes:couponWeaponPage")

    couponWeaponPage:RegisterElement('header', {
        value = _U("manageWeapon"),
        slot = "header",
        style = {}
    })

    couponWeaponPage:RegisterElement('subheader', {
        value = weaponData.weapon,
        slot = 'header'
    })

    couponWeaponPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    couponWeaponPage:RegisterElement('slider', {
        label = _U('quantity'),
        start = weaponData.quantity or 1,
        slot = "content",
        min = 1,
        max = 100,
        steps = 1,
    }, function(data)
        weaponData.quantity = data.value
    end)

    couponWeaponPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    couponWeaponPage:RegisterElement('button', {
        label = _U('updateWeapon'),
        slot = 'footer'
    }, function()
        BccUtils.RPC:Call("bcc-rewardcodes:updateCouponWeapon", { id = id, quantity = weaponData.quantity }, function(success)
            if success then
                VORPCore.NotifyObjective(_U("updatedWeaponSuccess"), 4000)
                devPrint(_U("updatedWeaponSuccess"))
            else
                VORPCore.NotifyObjective(_U("updatedWeaponFail"), 4000)
                devPrint(_U("updatedWeaponFail"))
            end
            CouponManageMenu:Close()
        end)
    end)

    couponWeaponPage:RegisterElement('button', {
        label = _U('deleteWeapon'),
        slot = 'footer'
    }, function()
        BccUtils.RPC:Call("bcc-rewardcodes:deleteCouponWeapon", { id = id }, function(success)
            if success then
                VORPCore.NotifyObjective(_U("deletedWeaponSuccess"), 4000)
                devPrint(_U("deletedWeaponSuccess"))
            else
                VORPCore.NotifyObjective(_U("deletedWeaponFail"), 4000)
                devPrint(_U("deletedWeaponFail"))
            end
            CouponManageMenu:Close()
        end)
    end)

    couponWeaponPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer'
    }, function()
        OpenManageWeapons(weaponData.code)
    end)

    couponWeaponPage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = couponWeaponPage })
end

function AddItem(code)
    local couponsItemAddPage = CouponManageMenu:RegisterPage("bcc-rewardcodes:couponsItemAddPage")
    local item, quantity = nil, 0

    couponsItemAddPage:RegisterElement('header', {
        value = _U("addRewardItem"),
        slot = "header",
        style = {}
    })

    couponsItemAddPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    couponsItemAddPage:RegisterElement('input', {
        label = _U('itemName'),
        placeholder = _U('validItem'),
    }, function(data)
        item = data.value
    end)

    couponsItemAddPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    couponsItemAddPage:RegisterElement('slider', {
        slot = "footer",
        label = _U('quantity'),
        start = 1,
        min = 1,
        max = 100,
        steps = 1,
    }, function(data)
        quantity = data.value
    end)

    couponsItemAddPage:RegisterElement('button', {
        label = _U('insertSave'),
        slot = 'footer'
    }, function()
        if not item or quantity < 1 then return end

        local success = BccUtils.RPC:CallAsync("bcc-rewardcodes:addItemToCoupon", {
            code = code,
            item = item,
            quantity = quantity
        })

        if success then
            VORPCore.NotifyObjective(_U("addedItemSuccess"), 4000)
            devPrint(_U("addedItemSuccess"))
        else
            VORPCore.NotifyObjective(_U("addedItemFail"), 4000)
            devPrint(_U("addedItemFail"))
        end

        CouponManageMenu:Close()
    end)

    couponsItemAddPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer'
    }, function()
        OpenManageItems(code)
    end)

    couponsItemAddPage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = couponsItemAddPage })
end

function AddWeapon(code)
    local couponsWeaponAddPage = CouponManageMenu:RegisterPage("bcc-rewardcodes:couponsWeaponAddPage")
    local weapon, quantity = nil, 0

    couponsWeaponAddPage:RegisterElement('header', {
        value = _U('addRewardWeapon'),
        slot = "header",
        style = {}
    })

    couponsWeaponAddPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    couponsWeaponAddPage:RegisterElement('input', {
        label = _U('itemHash'),
        placeholder = _U('validWeapon'),
    }, function(data)
        weapon = data.value
    end)

    couponsWeaponAddPage:RegisterElement('slider', {
        label = _U('quantity'),
        start = 1,
        min = 1,
        max = 100,
        steps = 1,
    }, function(data)
        quantity = data.value
    end)

    couponsWeaponAddPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    couponsWeaponAddPage:RegisterElement('button', {
        label = _U('insertSave'),
        slot = 'footer'
    }, function()
        if not weapon or quantity < 1 then return end

        local success = BccUtils.RPC:CallAsync("bcc-rewardcodes:addWeaponToCoupon", {
            code = code,
            weapon = weapon,
            quantity = quantity
        })

        if success then
            VORPCore.NotifyObjective(_U("addedWeaponSuccess"), 4000)
            devPrint(_U("addedWeaponSuccess"))
        else
            VORPCore.NotifyObjective(_U("addedWeaponFail"), 4000)
            devPrint(_U("addedWeaponFail"))
        end

        CouponManageMenu:Close()
    end)

    couponsWeaponAddPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer'
    }, function()
        OpenManageWeapons(code)
    end)

    couponsWeaponAddPage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = couponsWeaponAddPage })
end

function OpenManageItems(code)
    local itemsData = BccUtils.RPC:CallAsync("bcc-rewardcodes:fetchCouponItemsData", { code = code })
    local couponsItemListPage = CouponManageMenu:RegisterPage("bcc-rewardcodes:couponsItemListPage")

    couponsItemListPage:RegisterElement('header', {
        value = _U("rewardItems"),
        slot = "header",
        style = {}
    })

    couponsItemListPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    for _, itemData in pairs(itemsData) do
        couponsItemListPage:RegisterElement('button', {
            label = itemData.item,
            slot = 'content'
        }, function()
            ManageItem(itemData.id)
        end)
    end

    couponsItemListPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    couponsItemListPage:RegisterElement('button', {
        label = _U("addRewardItem"),
        slot = 'footer'
    }, function()
        AddItem(code)
    end)

    couponsItemListPage:RegisterElement('button', {
        label = _U("back"),
        slot = 'footer'
    }, function()
        OpenCouponMenu(code)
    end)

    couponsItemListPage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = couponsItemListPage })
end

function OpenManageWeapons(code)
    local weaponsData = BccUtils.RPC:CallAsync("bcc-rewardcodes:fetchCouponWeaponsData", { code = code })
    local couponsWeaponListPage = CouponManageMenu:RegisterPage("bcc-rewardcodes:couponsWeaponListPage")

    couponsWeaponListPage:RegisterElement('header', {
        value = _U("rewardWeapons"),
        slot = "header",
        style = {}
    })

    couponsWeaponListPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    for _, weaponData in pairs(weaponsData) do
        couponsWeaponListPage:RegisterElement('button', {
            label = weaponData.weapon,
            slot = 'content'
        }, function()
            ManageWeapon(weaponData.id)
        end)
    end

    couponsWeaponListPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    couponsWeaponListPage:RegisterElement('button', {
        label = _U("addRewardWeapon"),
        slot = 'footer'
    }, function()
        AddWeapon(code)
    end)

    couponsWeaponListPage:RegisterElement('button', {
        label = _U("back"),
        slot = 'footer'
    }, function()
        OpenCouponMenu(code)
    end)

    couponsWeaponListPage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = couponsWeaponListPage })
end

function OpenManageMoney(code)
    local moneyData = BccUtils.RPC:CallAsync("bcc-rewardcodes:fetchCouponMoneyData", { code = code })
    local money, gold = moneyData.money or 0, moneyData.gold or 0

    local couponsMoneyListPage = CouponManageMenu:RegisterPage("bcc-rewardcodes:couponsMoneyListPage")

    couponsMoneyListPage:RegisterElement('header', {
        value = _U("rewardMoney"),
        slot = "header",
        style = {}
    })

    couponsMoneyListPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    couponsMoneyListPage:RegisterElement('input', {
        label = _U('money'),
        placeholder = _U('currentMoney') .. money,
        slot = "content",
    }, function(data)
        money = data.value
    end)

    couponsMoneyListPage:RegisterElement('input', {
        label = _U('Gold'),
        placeholder = _U('currentGold') .. gold,
        slot = "content",
    }, function(data)
        gold = data.value
    end)

    couponsMoneyListPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    couponsMoneyListPage:RegisterElement('button', {
        label = _U("back"),
        slot = 'footer'
    }, function()
        OpenCouponMenu(code)
    end)

    couponsMoneyListPage:RegisterElement('button', {
        label = _U("update"),
        slot = "footer",
    }, function()
        local success = BccUtils.RPC:CallAsync("bcc-rewardcodes:updateCouponMoneyData", {
            code = code,
            money = tonumber(money),
            gold = tonumber(gold)
        })

        if success then
            VORPCore.NotifyObjective(_U("updatedMoneySuccess"), 4000)
            devPrint(_U("updatedMoneySuccess"))
        else
            VORPCore.NotifyObjective(_U("updatedMoneyFail"), 4000)
            devPrint(_U("updatedMoneyFail"))
        end

        CouponManageMenu:Close()
    end)

    couponsMoneyListPage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = couponsMoneyListPage })
end

function OpenCouponMenu(code)
    local couponData = BccUtils.RPC:CallAsync("bcc-rewardcodes:fetchCouponData", { code = code })
    if not couponData then return end

    local couponsManagePage = CouponManageMenu:RegisterPage("bcc-rewardcodes:couponsManagePage")

    couponsManagePage:RegisterElement('header', {
        value = _U("manageCoupon"),
        slot = "header",
        style = {}
    })

    couponsManagePage:RegisterElement('subheader', {
        value = couponData.code,
        slot = "header",
        style = {}
    })

    couponsManagePage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    couponsManagePage:RegisterElement("textdisplay", {
        value = _U('totalUse') .. couponData.currentUse or 0,
        slot = "header",
    })

    couponsManagePage:RegisterElement('slider', {
        label = _U('maxUses'),
        start = couponData.maxUse or -1,
        slot = "content",
        min = -1,
        max = 1000,
        steps = 1,
    }, function(data)
        couponData.maxUse = data.value
    end)

    couponsManagePage:RegisterElement("checkbox", {
        label = _U('activeStatus'),
        slot = "content",
        start = couponData.active == 1 and true or false
    }, function(data)
        couponData.active = data.value == true and 1 or 0
    end)

    couponsManagePage:RegisterElement('button', {
        label = _U('manageItems'),
        slot = 'content'
    }, function()
        OpenManageItems(code)
    end)

    couponsManagePage:RegisterElement('button', {
        label = _U('manageWeapons'),
        slot = 'content'
    }, function()
        OpenManageWeapons(code)
    end)

    couponsManagePage:RegisterElement('button', {
        label = _U('manageMoney'),
        slot = 'content'
    }, function()
        OpenManageMoney(code)
    end)

    couponsManagePage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    couponsManagePage:RegisterElement('button', {
        label = _U('update'),
        slot = 'footer'
    }, function()
        local success = BccUtils.RPC:CallAsync("bcc-rewardcodes:updateCouponData", {
            code = couponData.code,
            maxUse = couponData.maxUse,
            active = couponData.active
        })

        if success then
            VORPCore.NotifyObjective(_U("updatedCouponSuccess"), 4000)
            devPrint(_U("updatedCouponSuccess"))
        else
            VORPCore.NotifyObjective(_U("updatedCouponFail"), 4000)
            devPrint(_U("updatedCouponFail"))
        end

        CouponManageMenu:Close()
    end)

    couponsManagePage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
    }, function()
        OpenAllCouponsPage()
    end)

    couponsManagePage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = couponsManagePage })
end

function OpenAllCouponsPage()
    local availableCoupons = BccUtils.RPC:CallAsync("bcc-rewardcodes:fetchAllCoupons")

    if #availableCoupons < 1 then
        VORPCore.NotifyObjective(_U("noCouponsAvailable"), 4000)
        return
    end

    local couponsListPage = CouponManageMenu:RegisterPage("bcc-rewardcodes::couponsListPage")

    couponsListPage:RegisterElement('header', {
        value = _U('availableCoupons'),
        slot = "header",
        style = {}
    })

    couponsListPage:RegisterElement('subheader', {
        value = _U("selectCouponToManage"),
        slot = "header",
        style = {}
    })

    couponsListPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    for _, code in pairs(availableCoupons) do
        couponsListPage:RegisterElement('button', {
            label = code.code,
            slot = 'content'
        }, function()
            OpenCouponMenu(code.code)
        end)
    end

    couponsListPage:RegisterElement('button', {
        label = _U("back"),
        slot = 'footer'
    }, function()
        OpenCouponAdminMenu()
    end)

    couponsListPage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = couponsListPage })
end

function OpenCreateCouponMenu()
    local newCouponPage = CouponManageMenu:RegisterPage("bcc-rewardcodes::newCouponPage")
    local couponCode, maxUsage = nil, -1

    newCouponPage:RegisterElement('header', {
        value = _U("createCoupon"),
        slot = "header",
        style = {}
    })

    newCouponPage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    newCouponPage:RegisterElement('input', {
        label = _U("couponCode"),
        placeholder = _U("uniqueCouponCode"),
        style = {}
    }, function(data)
        couponCode = data.value
    end)

    newCouponPage:RegisterElement('slider', {
        label = _U("maxUsage"),
        start = -1,
        min = -1,
        max = 1000,
        steps = 1,
    }, function(data)
        maxUsage = data.value
    end)

    newCouponPage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    newCouponPage:RegisterElement('button', {
        label = _U("generateCoupon"),
        slot = 'footer'
    }, function()
        BccUtils.RPC:Call("bcc-rewardcodes:createNewCoupon", { code = couponCode, maxUsage = maxUsage }, function(success)
            if success then
                VORPCore.NotifyObjective(_U("created_coupon") .. couponCode, 4000)
                devPrint(_U("created_coupon"))
            else
                VORPCore.NotifyObjective(_U("failed_create_coupon"), 4000)
                devPrint(_U("failed_create_coupon"))
            end
        end)
        OpenCouponAdminMenu()
    end)

    newCouponPage:RegisterElement('button', {
        label = _U("back"),
        slot = 'footer'
    }, function()
        OpenCouponAdminMenu()
    end)

    newCouponPage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = newCouponPage })
end

function OpenCouponAdminMenu()
    local homePage = CouponManageMenu:RegisterPage("bcc-rewardcodes::mainPage")

    homePage:RegisterElement('header', {
        value = _U("creatorCoupon"),
        slot = "header",
        style = {}
    })

    homePage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    homePage:RegisterElement('button', {
        label = _U("createCoupon"),
    }, function()
        OpenCreateCouponMenu()
    end)

    homePage:RegisterElement('button', {
        label = _U("manageCoupons"),
    }, function()
        OpenAllCouponsPage()
    end)

    homePage:RegisterElement('line', {
        slot = "footer",
        style = {}
    })

    homePage:RegisterElement('button', {
        label = _U('close'),
        slot = 'footer'
    }, function()
        CouponManageMenu:Close()
    end)

    homePage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer'
    }, function()
        CouponManageMenu:Close()

        if OpenRewardsHub then
            OpenRewardsHub()
        end
    end)

    homePage:RegisterElement('bottomline', { slot = "footer" })

    CouponManageMenu:Open({ startupPage = homePage })
end

BccUtils.RPC:Register("bcc-rewardcodes:OpenAdminMenu", function(_, cb, source)
    local allowed = BccUtils.RPC:CallAsync("bcc-rewardcodes:validateMenuOpenPermission")
    if allowed then
        OpenCouponAdminMenu()
        cb(true)
    else
        cb(false)
    end
end)

function OpenRedeemMenu(data)
    local homePage = CouponManageMenu:RegisterPage("bcc-rewardcodes:mainRedeemPage")

    homePage:RegisterElement('header', {
        value = _U("redeemCoupon"),
        slot = "header",
        style = {}
    })

    homePage:RegisterElement('subheader', {
        value = data.code,
        slot = "header",
        style = {}
    })

    homePage:RegisterElement('line', {
        slot = "header",
        style = {}
    })

    local itemsText, weaponsText, moneyText = '', '', ''

    for _, item in ipairs(data.items) do
        itemsText = itemsText .. item.quantity .. 'x : ' .. item.label .. '\n'
    end

    for _, weapon in ipairs(data.weapons) do
        weaponsText = weaponsText .. weapon.quantity .. 'x : ' .. weapon.weapon .. '\n'
    end

    if data.money.money > 0 then
        moneyText = moneyText .. _U("money") .. " : " .. data.money.money .. '\n'
    end
    if data.money.gold > 0 then
        moneyText = moneyText .. _U("Gold") .. " : " .. data.money.gold .. '\n'
    end
    homePage:RegisterElement('subheader', {
        value = _U("rewardItems"),
        slot = "content",
        style = { ['color'] = 'red' }
    })
    homePage:RegisterElement('textdisplay', { value = itemsText, slot = "content" })
    homePage:RegisterElement('line', { slot = "content" })

    homePage:RegisterElement('subheader', {
        value = _U("rewardWeapons"),
        slot = "content",
        style = { ['color'] = 'red' }
    })
    homePage:RegisterElement('textdisplay', { value = weaponsText, slot = "content" })
    homePage:RegisterElement('line', { slot = "content" })

    homePage:RegisterElement('subheader', {
        value = _U("rewardMoney"),
        slot = "content",
        style = { ['color'] = 'red' }
    })
    homePage:RegisterElement('textdisplay', { value = moneyText, slot = "content" })

    homePage:RegisterElement('bottomline', { slot = 'footer' })

    homePage:RegisterElement('button', {
        label = _U("getRewards"),
        slot = 'footer'
    }, function()
        BccUtils.RPC:CallAsync("bcc-rewardcodes:RedeemCoupon", { code = data.code })
        CouponManageMenu:Close()
    end)

    homePage:RegisterElement('button', {
        label = _U("back"),
        slot = 'footer'
    }, function()
        CouponManageMenu:Close()
    end)

    homePage:RegisterElement('textdisplay', {
        value = _U("inventorySpaceWarning"),
        slot = "footer",
        style = {}
    })

    CouponManageMenu:Open({ startupPage = homePage })
end

BccUtils.RPC:Register("bcc-rewardcodes:redeemCoupon", function(data, cb)
    OpenRedeemMenu(data)
    cb(true)
end)
