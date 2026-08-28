local Core = exports.vorp_core:GetCore()
local FeatherMenu = exports['feather-menu'].initiate()

local function notifyRightTip(message, kind)
    if not message or message == '' then
        return
    end

    local duration = VipConfig.Notifications.info
    if kind == 'success' then
        duration = VipConfig.Notifications.success
    elseif kind == 'error' then
        duration = VipConfig.Notifications.error
    end

    Core.NotifyRightTip(message, duration)
end

local function buildRewardLines(pkg)
    local rewards = {}
    local rewardData = pkg.rewards or {}

    if tonumber(rewardData.tokens or 0) > 0 then
        rewards[#rewards + 1] = ('%s: %s'):format(VipConfig.TokenLabel, rewardData.tokens)
    end

    if #(rewardData.commands or {}) > 0 then
        rewards[#rewards + 1] = _U('specialReward')
    end

    if #rewards == 0 then
        rewards[#rewards + 1] = _U('noReward')
    end

    return rewards
end

local function openVipMenu(payload)
    local menuId = ('bcc:vip:menu:%s'):format(GetGameTimer())
    local menu = FeatherMenu:RegisterMenu(menuId, BccRewards.MenuOptions())

    local mainPage = menu:RegisterPage('bcc:vip:main')
    local packagesPage = menu:RegisterPage('bcc:vip:packages')
    local buyPage = menu:RegisterPage('bcc:vip:buy')
    local pendingPage = menu:RegisterPage('bcc:vip:pending')
    local adminPage = menu:RegisterPage('bcc:vip:admin')

    mainPage:RegisterElement('header', {
        value = VipConfig.MenuTitle,
        slot = 'header',
        style = {
            ['color'] = '#d4b06a'
        }
    })

    mainPage:RegisterElement('subheader', {
        value = VipConfig.StoreName,
        slot = 'header',
        style = {
            ['color'] = '#E0E0E0'
        }
    })

    mainPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    mainPage:RegisterElement('textdisplay', {
        value = VipConfig.Messages.menu_store,
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0',
            ['font-size'] = '0.80vw'
        }
    })

    mainPage:RegisterElement('textdisplay', {
        value = VipConfig.StoreUrl,
        slot = 'content',
        style = {
            ['color'] = '#CC9900',
            ['font-size'] = '0.80vw'
        }
    })

    mainPage:RegisterElement('line', {
        slot = 'content',
        style = {}
    })

    mainPage:RegisterElement('textdisplay', {
        value = VipConfig.Messages.menu_identity,
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0',
            ['font-size'] = '0.80vw'
        }
    })

    mainPage:RegisterElement('textdisplay', {
        value = ('Server ID: %s | Character ID: %s'):format(payload.serverId, payload.charId),
        slot = 'content',
        style = {
            ['color'] = '#CC9900',
            ['font-size'] = '0.80vw'
        }
    })

    mainPage:RegisterElement('textdisplay', {
        value = ('%s %s %s'):format(VipConfig.Messages.menu_balance, tostring(payload.tokenBalance or 0), VipConfig.TokenShortLabel),
        slot = 'content',
        style = {
            ['color'] = '#CC9900',
            ['font-size'] = '0.80vw'
        }
    })

    mainPage:RegisterElement('button', {
        label = _U('buyVip'),
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        buyPage:RouteTo()
    end)

    mainPage:RegisterElement('button', {
        label = ('Pending VIP (%s)'):format(#payload.pending),
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        pendingPage:RouteTo()
    end)

    mainPage:RegisterElement('button', {
        label = ('Packages (%s)'):format(#payload.packages),
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        packagesPage:RouteTo()
    end)

    if payload.isAdmin then
        mainPage:RegisterElement('button', {
            label = ('VIP Admin Log (%s)'):format(#(payload.adminPurchases or {})),
            slot = 'content',
            style = {
                ['color'] = '#E0E0E0'
            }
        }, function()
            adminPage:RouteTo()
        end)
    end

    buyPage:RegisterElement('header', {
        value = _U('buyVip'),
        slot = 'header',
        style = {
            ['color'] = '#d4b06a'
        }
    })

    buyPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    buyPage:RegisterElement('textdisplay', {
        value = VipConfig.Messages.menu_store,
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0',
            ['font-size'] = '0.80vw'
        }
    })

    buyPage:RegisterElement('textdisplay', {
        value = VipConfig.StoreUrl,
        slot = 'content',
        style = {
            ['color'] = '#CC9900',
            ['font-size'] = '0.80vw'
        }
    })

    buyPage:RegisterElement('line', {
        slot = 'content',
        style = {}
    })

    buyPage:RegisterElement('textdisplay', {
        value = ('Your Server ID: %s'):format(payload.serverId),
        slot = 'content',
        style = {
            ['color'] = '#CC9900',
            ['font-size'] = '0.80vw'
        }
    })

    buyPage:RegisterElement('textdisplay', {
        value = VipConfig.Messages.menu_identifier,
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0',
            ['font-size'] = '0.80vw'
        }
    })

    buyPage:RegisterElement('textdisplay', {
        value = tostring(payload.identifier or 'unknown'),
        slot = 'content',
        style = {
            ['color'] = '#CC9900',
            ['font-size'] = '0.76vw'
        }
    })

    buyPage:RegisterElement('textdisplay', {
        value = _U('vipDeliveryNotice'),
        slot = 'content',
        style = {
            ['color'] = '#E0E0E0',
            ['font-size'] = '0.80vw'
        }
    })

    buyPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    buyPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        mainPage:RouteTo()
    end)

    mainPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    mainPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        menu:Close()

        if OpenRewardsHub then
            OpenRewardsHub()
        end
    end)

    mainPage:RegisterElement('button', {
        label = _U('close'),
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        menu:Close()
    end)

    packagesPage:RegisterElement('header', {
        value = _U('storePackages'),
        slot = 'header',
        style = {
            ['color'] = '#d4b06a'
        }
    })

    packagesPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    for _, pkg in ipairs(payload.packages) do
        local detailPage = menu:RegisterPage(('bcc:vip:package:%s'):format(pkg.id))

        packagesPage:RegisterElement('button', {
            label = ('%s [%s]'):format(pkg.label, pkg.price or 'N/A'),
            slot = 'content',
            style = {
                ['color'] = '#E0E0E0'
            }
        }, function()
            detailPage:RouteTo()
        end)

        detailPage:RegisterElement('header', {
            value = pkg.label,
            slot = 'header',
            style = {
                ['color'] = '#d4b06a'
            }
        })

        detailPage:RegisterElement('subheader', {
            value = pkg.price or 'Price not set',
            slot = 'header',
            style = {
                ['color'] = '#E0E0E0'
            }
        })

        detailPage:RegisterElement('line', {
            slot = 'header',
            style = {}
        })

        detailPage:RegisterElement('textdisplay', {
            value = pkg.description or 'No description set.',
            slot = 'content',
            style = {
                ['color'] = '#E0E0E0',
                ['font-size'] = '0.80vw'
            }
        })

        for _, rewardLine in ipairs(buildRewardLines(pkg)) do
            detailPage:RegisterElement('textdisplay', {
                value = rewardLine,
                slot = 'content',
                style = {
                    ['color'] = '#CC9900',
                    ['font-size'] = '0.78vw'
                }
            })
        end

        detailPage:RegisterElement('line', {
            slot = 'footer',
            style = {}
        })

        detailPage:RegisterElement('button', {
            label = _U('back'),
            slot = 'footer',
            style = {
                ['color'] = '#E0E0E0'
            }
        }, function()
            packagesPage:RouteTo()
        end)
    end

    packagesPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    packagesPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        mainPage:RouteTo()
    end)

    adminPage:RegisterElement('header', {
        value = _U('vipAdminLog'),
        slot = 'header',
        style = {
            ['color'] = '#d4b06a'
        }
    })

    adminPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    if not payload.isAdmin or #(payload.adminPurchases or {}) == 0 then
        adminPage:RegisterElement('textdisplay', {
            value = VipConfig.Messages.admin_empty,
            slot = 'content',
            style = {
                ['color'] = '#E0E0E0',
                ['font-size'] = '0.80vw'
            }
        })
    else
        for _, row in ipairs(payload.adminPurchases) do
            local detailPage = menu:RegisterPage(('bcc:vip:admin:%s'):format(row.id))

            adminPage:RegisterElement('button', {
                label = ('#%s %s [%s]'):format(row.id, row.package_label, row.status),
                slot = 'content',
                style = {
                    ['color'] = '#E0E0E0'
                }
            }, function()
                detailPage:RouteTo()
            end)

            detailPage:RegisterElement('header', {
                value = ('VIP #%s'):format(row.id),
                slot = 'header',
                style = {
                    ['color'] = '#d4b06a'
                }
            })

            detailPage:RegisterElement('subheader', {
                value = ('%s [%s]'):format(row.package_label or row.package_id, row.status or 'unknown'),
                slot = 'header',
                style = {
                    ['color'] = '#E0E0E0'
                }
            })

            detailPage:RegisterElement('line', {
                slot = 'header',
                style = {}
            })

            local detailLines = {
                ('Transaction: %s'):format(row.transaction_id or '-'),
                ('Target Identifier: %s'):format(row.target_identifier or '-'),
                ('Character ID: %s'):format(row.target_charid or '-'),
                ('Tebex Target: %s'):format(row.tebex_target or '-'),
                ('Username: %s'):format(row.tebex_username or '-'),
                ('Server: %s'):format(row.tebex_server or '-'),
                ('Payment: %s %s'):format(row.payment_price or '-', row.payment_currency or '-'),
                ('Payment Time: %s %s'):format(row.payment_date or '-', row.payment_time or '-'),
                ('Email: %s'):format(row.customer_email or '-'),
                ('IP: %s'):format(row.customer_ip or '-'),
                ('Package Price: %s'):format(row.package_price or '-'),
                ('Package Expiry: %s'):format(row.package_expiry or '-'),
                ('Package Name: %s'):format(row.package_name or '-'),
                ('Created: %s'):format(row.created_at or '-'),
                ('Claimed: %s'):format(row.claimed_at or '-'),
                ('Rewards: %s'):format(row.reward_summary or '-'),
                ('Failure: %s'):format(row.failure_reason or '-')
            }

            for _, line in ipairs(detailLines) do
                detailPage:RegisterElement('textdisplay', {
                    value = line,
                    slot = 'content',
                    style = {
                        ['color'] = '#E0E0E0',
                        ['font-size'] = '0.76vw'
                    }
                })
            end

            detailPage:RegisterElement('line', {
                slot = 'footer',
                style = {}
            })

            detailPage:RegisterElement('button', {
                label = _U('back'),
                slot = 'footer',
                style = {
                    ['color'] = '#E0E0E0'
                }
            }, function()
                adminPage:RouteTo()
            end)
        end
    end

    adminPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    adminPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        mainPage:RouteTo()
    end)

    pendingPage:RegisterElement('header', {
        value = _U('pendingVip'),
        slot = 'header',
        style = {
            ['color'] = '#d4b06a'
        }
    })

    pendingPage:RegisterElement('line', {
        slot = 'header',
        style = {}
    })

    if #payload.pending == 0 then
        pendingPage:RegisterElement('textdisplay', {
            value = VipConfig.Messages.menu_empty,
            slot = 'content',
            style = {
                ['color'] = '#E0E0E0',
                ['font-size'] = '0.80vw'
            }
        })
    else
        for _, entry in ipairs(payload.pending) do
            pendingPage:RegisterElement('button', {
                label = ('Claim: %s'):format(entry.package_label),
                slot = 'content',
                style = {
                    ['color'] = '#E0E0E0'
                }
            }, function()
                TriggerServerEvent('bcc-rewards:vip:server:claimPurchase', entry.id)
                menu:Close()
            end)
        end
    end

    pendingPage:RegisterElement('line', {
        slot = 'footer',
        style = {}
    })

    pendingPage:RegisterElement('button', {
        label = _U('back'),
        slot = 'footer',
        style = {
            ['color'] = '#E0E0E0'
        }
    }, function()
        mainPage:RouteTo()
    end)

    menu:Open({
        startupPage = mainPage
    })
end

RegisterNetEvent('bcc-rewards:vip:client:openMenu', function(payload)
    openVipMenu(payload)
end)

RegisterNetEvent('bcc-rewards:vip:client:notify', function(message, kind)
    notifyRightTip(message, kind)
end)
