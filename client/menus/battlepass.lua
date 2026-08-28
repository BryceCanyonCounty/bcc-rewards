local Core = exports.vorp_core:GetCore()
local FeatherMenu = exports['feather-menu'].initiate()

local activeMenu = nil

local colors = {
    gold = '#d4b06a',
    text = '#E0E0E0',
    muted = '#b8aa8c',
    green = '#82b366',
    red = '#d86b5f'
}

local function notify(message, kind)
    if not message or message == '' then
        return
    end

    Core.NotifyRightTip(message, 4000)
end

local function isDbTrue(value)
    return value == true or value == 1 or value == '1' or tonumber(value or 0) == 1
end

local function rewardName(reward)
    if not reward then
        return _U('noReward')
    end

    return reward.label or reward.name or reward.type or 'Reward'
end

local function rewardMeta(reward)
    if not reward then
        return ''
    end

    if reward.type == 'money' then
        return _U('cashReward')
    elseif reward.type == 'gold' then
        return _U('goldReward')
    elseif reward.type == 'rol' then
        return _U('rolReward')
    elseif reward.type == 'weapon' then
        return _U('weaponReward')
    elseif reward.type == 'command' then
        return _U('specialReward')
    end

    return ('%s x%s'):format(_U('itemReward'), reward.amount or 1)
end

local function objectiveText(objective, keyName, fallbackName)
    local key = objective and objective[keyName]
    if key and key ~= '' then
        return _U(key)
    end

    return objective and objective[fallbackName] or ''
end

local function objectivePeriodLabel(period)
    period = tostring(period or 'season'):lower()

    if period == 'daily' then
        return _U('objectivePeriodDaily')
    elseif period == 'weekly' then
        return _U('objectivePeriodWeekly')
    end

    return _U('objectivePeriodSeason')
end

local function objectiveProgressText(objective)
    local progress = tonumber(objective.progress or 0) or 0
    local required = tonumber(objective.required or 1) or 1
    local completions = tonumber(objective.completions or 0) or 0
    local limit = tonumber(objective.limit or 0) or 0

    if limit > 0 then
        return _U('objectiveProgressWithLimit', progress, required, completions, limit)
    end

    return _U('objectiveProgressNoLimit', progress, required, completions)
end

local function statusFor(payload, levelData, track)
    local claimed = track == 'normal' and levelData.normalClaimed or levelData.premiumClaimed

    if claimed then
        return _U('claimed'), colors.red, false
    end

    if payload.progress.level < levelData.level then
        return _U('locked'), colors.red, false
    end

    if track == 'premium' and not payload.progress.premium then
        return _U('premiumRequired'), colors.red, false
    end

    if track == 'normal' and payload.progress.premium and not payload.premium.premiumCanClaimNormal then
        return _U('normalOnly'), colors.red, false
    end

    return _U('ready'), colors.gold, true
end

local function addHeader(page, title, subtitle)
    page:RegisterElement('header', {
        value = title,
        slot = 'header',
        style = {
            ['color'] = colors.gold
        }
    })

    if subtitle then
        page:RegisterElement('subheader', {
            value = subtitle,
            slot = 'header',
            style = {
                ['color'] = colors.text
            }
        })
    end

    page:RegisterElement('line', {
        slot = 'header',
        style = {}
    })
end

local function addFooterBack(page, targetPage)
    page:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    page:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
        style = {
            ['color'] = colors.text
        }
    }, function()
        targetPage:RouteTo()
    end)
end

local function addEmptyLogText(page)
    page:RegisterElement('textdisplay', {
        value = _U('battlepassNoLogs'),
        slot = 'content',
        style = {
            ['color'] = colors.muted,
            ['font-size'] = '0.78vw'
        }
    })
end

local function addLogLine(page, value)
    page:RegisterElement('textdisplay', {
        value = value,
        slot = 'content',
        style = {
            ['color'] = colors.text,
            ['font-size'] = '0.68vw'
        }
    })

    page:RegisterElement('line', {
        slot = 'content',
        style = {}
    })
end

local function openBattlepassMenu(payload)
    if activeMenu then
        activeMenu:Close()
        activeMenu = nil
    end

    local menuId = ('hoinarii:battlepass:%s'):format(GetGameTimer())
    local menu = FeatherMenu:RegisterMenu(menuId, BccRewards.MenuOptions())

    activeMenu = menu

    local mainPage = menu:RegisterPage('hoinarii:battlepass:main')
    local levelsPage = menu:RegisterPage('hoinarii:battlepass:levels')
    local objectivesPage = menu:RegisterPage('hoinarii:battlepass:objectives')
    local adminPage = menu:RegisterPage('hoinarii:battlepass:admin')
    local adminPlayersPage = menu:RegisterPage('hoinarii:battlepass:admin:players')
    local adminObjectivesPage = menu:RegisterPage('hoinarii:battlepass:admin:objectives')
    local adminClaimsPage = menu:RegisterPage('hoinarii:battlepass:admin:claims')
    local adminPurchasesPage = menu:RegisterPage('hoinarii:battlepass:admin:purchases')

    addHeader(mainPage, BattlepassConfig.Text.title, payload.season.label or payload.season.key)

    mainPage:RegisterElement('textdisplay', {
        value = _U('battlepassLevelStatus', payload.progress.level, payload.progress.maxLevel),
        slot = 'content',
        style = {
            ['color'] = colors.gold,
            ['font-size'] = '0.88vw'
        }
    })

    local xpStatus = _U('battlepassXpStatus', payload.progress.xp, payload.progress.nextLevelXP)
    if payload.progress.isMaxLevel and payload.progress.postRewardEnabled then
        xpStatus = _U('battlepassBonusXpStatus', payload.progress.xp, payload.progress.nextPostRewardXP, payload.progress.postRewards or 0)
    elseif payload.progress.isMaxLevel then
        xpStatus = _U('battlepassMaxLevelStatus', payload.progress.xp)
    end

    mainPage:RegisterElement('textdisplay', {
        value = xpStatus,
        slot = 'content',
        style = {
            ['color'] = colors.text,
            ['font-size'] = '0.78vw'
        }
    })

    mainPage:RegisterElement('textdisplay', {
        value = payload.progress.premium and _U('battlepassPremiumActive') or _U('battlepassPremiumInactive'),
        slot = 'content',
        style = {
            ['color'] = payload.progress.premium and colors.green or colors.muted,
            ['font-size'] = '0.78vw'
        }
    })

    mainPage:RegisterElement('line', {
        slot = 'content',
        style = {}
    })

    if payload.premium.enabled and not payload.progress.premium then
        mainPage:RegisterElement('button', {
            label = _U('buyPremiumTokens', payload.premium.price),
            slot = 'content',
            style = {
                ['color'] = colors.gold
            }
        }, function()
            TriggerServerEvent('bcc-rewards:server:buyPremium')
        end)
    end

    mainPage:RegisterElement('button', {
        label = _U('viewObjectives'),
        slot = 'content',
        style = {
            ['color'] = colors.text
        }
    }, function()
        objectivesPage:RouteTo()
    end)

    mainPage:RegisterElement('button', {
        label = _U('viewRewards'),
        slot = 'content',
        style = {
            ['color'] = colors.text
        }
    }, function()
        levelsPage:RouteTo()
    end)

    if payload.isAdmin then
        mainPage:RegisterElement('button', {
            label = _U('battlepassAdminLogs'),
            slot = 'content',
            style = {
                ['color'] = colors.text
            }
        }, function()
            adminPage:RouteTo()
        end)
    end

    mainPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    mainPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
        style = {
            ['color'] = colors.text
        }
    }, function()
        menu:Close()
        activeMenu = nil

        if OpenRewardsHub then
            OpenRewardsHub()
        end
    end)

    mainPage:RegisterElement('button', {
        label = _U('close'),
        slot = 'footer',
        style = {
            ['color'] = colors.text
        }
    }, function()
        menu:Close()
        activeMenu = nil
    end)

    addHeader(levelsPage, _U('battlepassRewards'), _U('normalPremiumTracks'))

    addHeader(objectivesPage, _U('battlepassObjectives'), payload.season.label or payload.season.key)

    addHeader(adminPage, _U('battlepassAdminLogs'), payload.season.label or payload.season.key)
    addHeader(adminPlayersPage, _U('battlepassPlayersLog'), payload.season.label or payload.season.key)
    addHeader(adminObjectivesPage, _U('battlepassObjectivesLog'), payload.season.label or payload.season.key)
    addHeader(adminClaimsPage, _U('battlepassClaimsLog'), payload.season.label or payload.season.key)
    addHeader(adminPurchasesPage, _U('battlepassPurchasesLog'), payload.season.label or payload.season.key)

    local logs = payload.adminLogs or {}
    local playerLogs = logs.players or {}
    local objectiveLogs = logs.objectives or {}
    local claimLogs = logs.claims or {}
    local purchaseLogs = logs.purchases or {}

    adminPage:RegisterElement('button', {
        label = ('%s (%s)'):format(_U('battlepassPlayersLog'), #playerLogs),
        slot = 'content',
        style = {
            ['color'] = colors.text
        }
    }, function()
        adminPlayersPage:RouteTo()
    end)

    adminPage:RegisterElement('button', {
        label = ('%s (%s)'):format(_U('battlepassObjectivesLog'), #objectiveLogs),
        slot = 'content',
        style = {
            ['color'] = colors.text
        }
    }, function()
        adminObjectivesPage:RouteTo()
    end)

    adminPage:RegisterElement('button', {
        label = ('%s (%s)'):format(_U('battlepassClaimsLog'), #claimLogs),
        slot = 'content',
        style = {
            ['color'] = colors.text
        }
    }, function()
        adminClaimsPage:RouteTo()
    end)

    adminPage:RegisterElement('button', {
        label = ('%s (%s)'):format(_U('battlepassPurchasesLog'), #purchaseLogs),
        slot = 'content',
        style = {
            ['color'] = colors.text
        }
    }, function()
        adminPurchasesPage:RouteTo()
    end)

    if #playerLogs == 0 then
        addEmptyLogText(adminPlayersPage)
    else
        for _, row in ipairs(playerLogs) do
            addLogLine(adminPlayersPage, ('%s | Char %s | %s XP | %s | %s'):format(
                row.identifier or '-',
                row.charid or '-',
                row.xp or 0,
                isDbTrue(row.premium) and _U('battlepassPremiumActive') or _U('battlepassPremiumInactive'),
                row.updated_at or '-'
            ))
        end
    end

    if #objectiveLogs == 0 then
        addEmptyLogText(adminObjectivesPage)
    else
        for _, row in ipairs(objectiveLogs) do
            addLogLine(adminObjectivesPage, ('%s | Char %s | %s | %s/%s | %s'):format(
                row.identifier or '-',
                row.charid or '-',
                row.objective or '-',
                row.progress or 0,
                row.completions or 0,
                row.updated_at or '-'
            ))
        end
    end

    if #claimLogs == 0 then
        addEmptyLogText(adminClaimsPage)
    else
        for _, row in ipairs(claimLogs) do
            addLogLine(adminClaimsPage, ('%s | Char %s | Level %s | %s | %s'):format(
                row.identifier or '-',
                row.charid or '-',
                row.level or '-',
                row.claim_type or '-',
                row.claimed_at or '-'
            ))
        end
    end

    if #purchaseLogs == 0 then
        addEmptyLogText(adminPurchasesPage)
    else
        for _, row in ipairs(purchaseLogs) do
            addLogLine(adminPurchasesPage, ('%s | %s | Char %s | %s Tokens | %s -> %s | %s'):format(
                row.player_name or '-',
                row.character_name or row.identifier or '-',
                row.charid or '-',
                row.price or 0,
                row.balance_before or 0,
                row.balance_after or 0,
                row.purchased_at or '-'
            ))
        end
    end

    addFooterBack(adminPlayersPage, adminPage)
    addFooterBack(adminObjectivesPage, adminPage)
    addFooterBack(adminClaimsPage, adminPage)
    addFooterBack(adminPurchasesPage, adminPage)
    addFooterBack(adminPage, mainPage)

    for _, objective in ipairs(payload.objectives or {}) do
        local title = objectiveText(objective, 'labelKey', 'label')
        local description = objectiveText(objective, 'descriptionKey', 'description')
        local color = objective.limitReached and colors.green or colors.gold

        objectivesPage:RegisterElement('textdisplay', {
            value = title,
            slot = 'content',
            style = {
                ['color'] = color,
                ['font-size'] = '0.82vw'
            }
        })

        objectivesPage:RegisterElement('progressbar', {
            progress = objective.percent or 0,
            text = objectiveProgressText(objective),
            rightText = _U('objectiveRewardXp', objective.xp or 0),
            color = color,
            slot = 'content'
        })

        objectivesPage:RegisterElement('textdisplay', {
            value = ('%s | %s'):format(objectivePeriodLabel(objective.period), objective.limitReached and _U('objectiveLimitReached') or description),
            slot = 'content',
            style = {
                ['color'] = objective.limitReached and colors.green or colors.muted,
                ['font-size'] = '0.70vw'
            }
        })

        objectivesPage:RegisterElement('line', {
            slot = 'content',
            style = {}
        })
    end

    addFooterBack(objectivesPage, mainPage)

    for _, levelData in ipairs(payload.levels or {}) do
        local detailPage = menu:RegisterPage(('hoinarii:battlepass:level:%s'):format(levelData.level))
        local normalStatus = statusFor(payload, levelData, 'normal')
        local premiumStatus = statusFor(payload, levelData, 'premium')
        local levelButtonColor = levelData.level <= payload.progress.level and colors.text or colors.muted

        if levelData.normalClaimed or levelData.premiumClaimed then
            levelButtonColor = colors.red
        end

        levelsPage:RegisterElement('button', {
            label = _U('battlepassLevelButton', levelData.level, normalStatus, premiumStatus),
            slot = 'content',
            style = {
                ['color'] = levelButtonColor,
                ['font-size'] = '0.76vw'
            }
        }, function()
            detailPage:RouteTo()
        end)

        addHeader(detailPage, _U('battlepassLevelTitle', levelData.level), _U('battlepassRequiresXp', levelData.xpRequired))

        local tracks = {
            { key = 'normal', label = _U('normalTrail'), reward = levelData.normal },
            { key = 'premium', label = _U('premiumTrail'), reward = levelData.premium }
        }

        for _, track in ipairs(tracks) do
            local status, color, canClaim = statusFor(payload, levelData, track.key)

            detailPage:RegisterElement('textdisplay', {
                value = track.label,
                slot = 'content',
                style = {
                    ['color'] = track.key == 'premium' and colors.gold or colors.text,
                    ['font-size'] = '0.84vw'
                }
            })

            detailPage:RegisterElement('textdisplay', {
                value = rewardName(track.reward),
                slot = 'content',
                style = {
                    ['color'] = colors.text,
                    ['font-size'] = '0.78vw'
                }
            })

            detailPage:RegisterElement('textdisplay', {
                value = ('%s | %s'):format(rewardMeta(track.reward), status),
                slot = 'content',
                style = {
                    ['color'] = color,
                    ['font-size'] = '0.74vw'
                }
            })

            if canClaim then
                detailPage:RegisterElement('button', {
                    label = ('%s %s'):format(_U('claim'), track.label),
                    slot = 'content',
                    style = {
                        ['color'] = colors.gold
                    }
                }, function()
                    TriggerServerEvent('bcc-rewards:server:claim', levelData.level, track.key)
                end)
            end

            detailPage:RegisterElement('line', {
                slot = 'content',
                style = {}
            })
        end

        addFooterBack(detailPage, levelsPage)
    end

    addFooterBack(levelsPage, mainPage)

    menu:Open({
        startupPage = mainPage
    })
end

RegisterNetEvent('bcc-rewards:client:open', function(payload)
    openBattlepassMenu(payload)
end)

RegisterNetEvent('bcc-rewards:client:update', function(payload)
    if activeMenu then
        openBattlepassMenu(payload)
    end
end)

RegisterNetEvent('bcc-rewards:client:notify', function(message, kind)
    notify(message, kind)
end)

RegisterNetEvent('FeatherMenu2:closed', function()
    activeMenu = nil
end)
