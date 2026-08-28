BccRewards = BccRewards or {}

VORPCore = VORPCore or exports.vorp_core:GetCore()
BccUtils = BccUtils or exports['bcc-utils'].initiate()

if Config.debug then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. tostring(message))
    end
else
    function devPrint(_) end
end
