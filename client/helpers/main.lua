BccRewards = BccRewards or {}

VORPCore = VORPCore or exports.vorp_core:GetCore()
FeatherMenu = FeatherMenu or exports['feather-menu'].initiate()
BccUtils = BccUtils or exports['bcc-utils'].initiate()

BccRewards.MenuWidth = '560px'

function BccRewards.MenuOptions()
    return {
        top = '3%',
        left = '3%',
        ['720width'] = '430px',
        ['1080width'] = BccRewards.MenuWidth,
        ['2kwidth'] = '680px',
        ['4kwidth'] = '860px',
        style = {
            ['width'] = BccRewards.MenuWidth,
            ['min-width'] = BccRewards.MenuWidth,
            ['max-width'] = BccRewards.MenuWidth,
            ['box-sizing'] = 'border-box'
        },
        contentslot = {
            style = {
                ['height'] = '520px',
                ['min-height'] = '380px',
                ['width'] = '100%',
                ['box-sizing'] = 'border-box'
            }
        },
        draggable = true,
        canclose = true
    }
end

if Config.debug then
    function devPrint(message)
        print("^1[DEV MODE]^3 " .. tostring(message) .. "^0")
    end
else
    function devPrint(_) end
end
