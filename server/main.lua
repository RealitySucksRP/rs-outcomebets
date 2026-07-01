math.randomseed(os.time() + GetGameTimer())
RSOB = RSOB or {}

local function canHost(src)
    if src == 0 then return true end
    if not Config.AdminOnlyHost then return true end
    return IsPlayerAceAllowed(src, Config.AdminAce)
end

local function isAdmin(src)
    if src == 0 then return true end
    return IsPlayerAceAllowed(src, Config.AdminAce)
end

RegisterCommand(Config.Commands.hostStart, function(src, args)
    if src == 0 then print('Use in-game so location can be captured.'); return end
    if not canHost(src) then RSBridge.Notify(src, 'No permission.', 'error'); return end
    local mode = args[1] == 'fixed' and 'fixed' or 'popup'
    local arenaId = args[2]
    local g = RSOB.MakeGame(src, mode, arenaId)
    if not g then return end
    SetTimeout(1500, function()
        local live = RSOB.Games[g.id]
        if live then RSOB.BeginCountdown(live) end
    end)
end, false)

RegisterCommand(Config.Commands.forceEnd, function(src)
    local g = RSOB.GetHostGame(src)
    if not g then RSBridge.Notify(src, 'No hosted show.', 'error'); return end
    RSOB.Destroy(g.id, 'ended', true)
end, false)

RegisterCommand(Config.Commands.cancel, function(src)
    local g = RSOB.GetHostGame(src)
    if not g then RSBridge.Notify(src, 'No hosted show.', 'error'); return end
    RSOB.Destroy(g.id, 'cancelled', true)
end, false)

-- /betforce is admin-only no matter what AdminOnlyHost is set to,
-- and refunds any active-round bets before switching round id.
RegisterCommand(Config.Commands.force, function(src, args)
    if not isAdmin(src) then
        RSBridge.Notify(src, 'Admin only command.', 'error')
        return
    end
    local g = RSOB.GetHostGame(src)
    if not g then RSBridge.Notify(src, 'No hosted show.', 'error'); return end
    local roundId = tonumber(args[1]) or g.round
    local outcomeId = args[2]
    if not outcomeId then
        RSBridge.Notify(src, 'Usage: /'..Config.Commands.force..' <round> <outcomeId>', 'error')
        return
    end
    if roundId ~= g.round then
        if next(g.bets or {}) then RSOB.RefundRound(g, 'forced-round-skip') end
        if not RSOB.BuildRound(g, roundId) then
            RSBridge.Notify(src, 'No such round configured.', 'error'); return
        end
    end
    RSOB.ExecuteRound(g, outcomeId)
end, false)

RegisterNetEvent('rs-outcomebets:server:placeBet', function(gameId, outcomeId, amount)
    RSOB.PlaceBet(source, gameId, outcomeId, amount)
end)

RegisterNetEvent('rs-outcomebets:server:requestSync', function()
    local src = source
    for _, g in pairs(RSOB.Games) do
        if RSOB.PublicGame then
            TriggerClientEvent('rs-outcomebets:client:sync', src, g.id, RSOB.PublicGame(g))
        else
            TriggerClientEvent('rs-outcomebets:client:sync', src, g.id, {
                id=g.id, host=g.host, state=g.state, arena=g.arena, coords=g.coords,
                shape=g.shape, radius=g.radius, size=g.size, wallHeight=g.wallHeight,
                round=g.round, roundsPerShow=g.roundsPerShow,
                timeLeft=(function()
                    if g.state == 'COUNTDOWN' and g.countdownEndsAt then return math.max(0, g.countdownEndsAt - os.time()) end
                    if g.state == 'ROUND_BETTING' and g.bettingEndsAt then return math.max(0, g.bettingEndsAt - os.time()) end
                    if g.state == 'INTER_ROUND' and g.interRoundEndsAt then return math.max(0, g.interRoundEndsAt - os.time()) end
                    if g.state == 'ROUND_PAYOUT' and g.payoutEndsAt then return math.max(0, g.payoutEndsAt - os.time()) end
                    return nil
                end)(),
                prompt=g.prompt, outcomes=g.outcomes,
                bets=(function()
                    local out = {}
                    for s, bet in pairs(g.bets or {}) do
                        out[tostring(s)] = { amount=bet.amount, outcome=bet.outcome, name=bet.name, round=bet.round }
                    end
                    return out
                end)(),
                pool=g.pool or {}, winner=g.winner, resolvedLabel=g.resolvedLabel,
                isAutoLoop=g.isAutoLoop or false
            })
        end
    end
end)

RegisterNetEvent('rs-outcomebets:server:forfeitLeave', function(gameId)
    RSOB.ForfeitBet(source, gameId)
end)

-- player disconnect / walk-away safety:
-- If the host leaves, hosted popup shows refund and end.
-- If any bettor disconnects mid-round, their current cash stake is forfeited (no ghost payouts to offline sources).
AddEventHandler('playerDropped', function()
    local src = source
    for id, g in pairs(RSOB.Games) do
        if g.host == src and not g.isAutoLoop then
            RSOB.Destroy(id, 'host_disconnected', true)
        elseif Config.Betting and Config.Betting.disconnectForfeitsRoundBet and g.bets and g.bets[src] then
            g.bets[src] = nil
            if RSOB.RefreshNpcOpponent then RSOB.RefreshNpcOpponent(g) end
            if RSOB.Sync then RSOB.Sync(g) end
        end
    end
end)

-- autoloop boot
CreateThread(function()
    Wait(3500)
    if Config.Lifecycle and Config.Lifecycle.autoLoop and Config.Lifecycle.autoLoop.enabled
       and Config.Lifecycle.autoLoop.runOnResourceStart then
        print('[rs-outcomebets] autoloop boot scheduled')
        RSOB.StartAutoLoop()
    end
end)
