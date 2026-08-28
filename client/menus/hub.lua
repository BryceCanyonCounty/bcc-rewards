local Core = exports.vorp_core:GetCore()
local FeatherMenu = exports['feather-menu'].initiate()
local BccUtils = exports['bcc-utils'].initiate()

local function notify(message)
    if message and message ~= '' then
        Core.NotifyRightTip(message, 4000)
    end
end

function OpenRewardsHub()
    local menu = FeatherMenu:RegisterMenu(('bcc:rewards:hub:%s'):format(GetGameTimer()), BccRewards.MenuOptions())

    local mainPage = menu:RegisterPage('bcc:rewards:hub:main')
    local redeemPage = menu:RegisterPage('bcc:rewards:hub:redeem')
    local redeemCode = ''

    mainPage:RegisterElement('header', {
        value = _U('rewardsHubTitle'),
        slot = 'header',
        style = {
            ['color'] = '#d4b06a'
        }
    })

    mainPage:RegisterElement('subheader', {
        value = _U('rewardsHubSubtitle'),
        slot = 'header',
        style = {}
    })

    mainPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    mainPage:RegisterElement('button', {
        label = _U('openBattlepass'),
        slot = 'content',
        style = {}
    }, function()
        TriggerServerEvent('bcc-rewards:server:open')
        menu:Close()
    end)

    mainPage:RegisterElement('button', {
        label = _U('vipCenter'),
        slot = 'content',
        style = {}
    }, function()
        TriggerServerEvent('bcc-rewards:vip:server:openMenu')
        menu:Close()
    end)

    mainPage:RegisterElement('button', {
        label = _U('redeemCoupon'),
        slot = 'content',
        style = {}
    }, function()
        redeemPage:RouteTo()
    end)

    mainPage:RegisterElement('button', {
        label = _U('couponAdmin'),
        slot = 'content',
        style = {}
    }, function()
        local allowed = BccUtils.RPC:CallAsync('bcc-rewardcodes:validateMenuOpenPermission')
        if allowed and OpenCouponAdminMenu then
            menu:Close()
            OpenCouponAdminMenu()
        else
            notify(_U and _U('missing_permissions') or 'Missing permissions.')
        end
    end)

    mainPage:RegisterElement('button', {
        label = _U('vipAdmin'),
        slot = 'content',
        style = {}
    }, function()
        TriggerServerEvent('bcc-rewards:vip:server:openAdminMenu')
        menu:Close()
    end)

    mainPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    mainPage:RegisterElement('button', {
        label = _U('close'),
        slot = 'footer',
        style = {}
    }, function()
        menu:Close()
    end)

    redeemPage:RegisterElement('header', {
        value = _U('redeemCoupon'),
        slot = 'header',
        style = {
            ['color'] = '#d4b06a'
        }
    })

    redeemPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    redeemPage:RegisterElement('input', {
        label = _U('couponCodeLabel'),
        placeholder = _U('couponCodePlaceholder'),
        slot = 'content'
    }, function(data)
        redeemCode = data.value or ''
    end)

    redeemPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    redeemPage:RegisterElement('button', {
        label = _U('redeem'),
        slot = 'footer',
        style = {}
    }, function()
        TriggerServerEvent('bcc-rewards:server:redeemCode', redeemCode)
        menu:Close()
    end)

    redeemPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
        style = {}
    }, function()
        mainPage:RouteTo()
    end)

    menu:Open({
        startupPage = mainPage
    })
end

RegisterCommand('reward', function()
    OpenRewardsHub()
end, false)
