local lastRewarded = {}

-- Get Discord ID from identifiers
local function GetPlayerDiscord(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:find("discord:") then
            return id:gsub("discord:", "")
        end
    end
    return nil
end

-- Fetch all roles for a player and return them as a map
local function FetchDiscordRoles(source, cb)
    local discordId = GetPlayerDiscord(source)
    if not discordId then
        devPrint("⚠️ Player has no Discord identifier.")
        return cb(nil)
    end

    PerformHttpRequest("https://discord.com/api/guilds/" .. Config.Guild_ID .. "/members/" .. discordId, function(code, data)
        if code ~= 200 then
            devPrint("❌ Discord API failed: HTTP " .. tostring(code))
            return cb(nil)
        end

        local parsed = json.decode(data)
        if not parsed or not parsed.roles then
            devPrint("❌ Invalid Discord response.")
            return cb(nil)
        end

        local roleMap = {}
        for _, roleId in ipairs(parsed.roles) do
            roleMap[roleId] = true
        end

        cb(roleMap)
    end, "GET", "", {
        ["Authorization"] = "Bot " .. Config.Bot_Token,
        ["Content-Type"] = "application/json"
    })
end

-- Utility: Check if a player has a specific Discord role
function CheckDiscordRole(source, targetRoleId, cb)
    FetchDiscordRoles(source, function(roles)
        if not roles then
            devPrint("⚠️ Cannot check roles, none returned for source " .. source)
            return cb(false)
        end
        cb(roles[targetRoleId] == true)
    end)
end

-- Command: Print all roles from the Discord guild
function PrintAllDiscordRoles()
    devPrint("🔄 Fetching Discord roles from guild " .. Config.Guild_ID .. "...")

    PerformHttpRequest("https://discord.com/api/guilds/" .. Config.Guild_ID .. "/roles", function(code, data)
        if code ~= 200 then
            print("^1[ERROR]^0 Failed to fetch roles: HTTP " .. code)
            return
        end

        local roles = json.decode(data)
        if not roles or type(roles) ~= "table" then
            print("^1[ERROR]^0 Invalid response format.")
            return
        end

        print("^2[DISCORD ROLES]^0 Listing " .. #roles .. " roles from the server:")

        table.sort(roles, function(a, b) return a.position > b.position end)

        for _, role in ipairs(roles) do
            print(string.format("• %s (%s)", role.name, role.id))
        end
    end, "GET", "", {
        ["Authorization"] = "Bot " .. Config.Bot_Token,
        ["Content-Type"] = "application/json"
    })
end

RegisterCommand("printroles", function(source)
    if source > 0 then
        local user = VORPCore.getUser(source)
        if not user or user.getGroup ~= Config.allowedGroup then
            return
        end
    end
    PrintAllDiscordRoles()
end, false)

BccUtils.RPC:Register("bcc-rewardcodes:giveDiscordRoleReward", function(_, cb, source)
    if not Config.DiscordRoleReward.enabled then
        devPrint("ℹ️ Discord role reward is disabled in config.")
        return cb(false)
    end

    local user = VORPCore.getUser(source)
    if not user then
        devPrint("❌ No user for source " .. source)
        return cb(false)
    end

    local character = user.getUsedCharacter
    if not character then
        devPrint("❌ No character for source " .. source)
        return cb(false)
    end

    local identifier = user.getIdentifier()
    local lastTime = lastRewarded[identifier] or 0

    if os.time() - lastTime < Config.DiscordRoleReward.interval then
        devPrint("⏳ Cooldown active for " .. identifier)
        return cb(false)
    end

    CheckDiscordRole(source, Config.DiscordRoleReward.roleID, function(hasRole)
        if not hasRole then
            devPrint("❌ " .. identifier .. " does NOT have the required Discord role.")
            return cb(false)
        end

        local rewards = Config.DiscordRoleReward.rewards

        if rewards.money > 0 then
            character.addCurrency(0, rewards.money)
            VORPCore.NotifyAvanced(
                source,
                "Ai primit $" .. rewards.money,
                Config.DiscordRoleReward.notify.dict,
                Config.DiscordRoleReward.notify.icon,
                Config.DiscordRoleReward.notify.color,
                Config.DiscordRoleReward.notify.duration
            )
        end

        if rewards.gold > 0 then
            character.addCurrency(1, rewards.gold)
            local gold = math.floor(rewards.gold * 100 + 0.5) / 100
            VORPCore.NotifyAvanced(
                source,
                "Ai primit " .. gold .. " gold",
                Config.DiscordRoleReward.notify.dict,
                Config.DiscordRoleReward.notify.icon,
                Config.DiscordRoleReward.notify.color,
                Config.DiscordRoleReward.notify.duration
            )
        end

        lastRewarded[identifier] = os.time()
        devPrint("✅ Gave reward to " .. identifier)
        cb(true)
    end)
end)
