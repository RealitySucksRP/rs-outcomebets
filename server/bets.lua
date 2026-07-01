RSOB = RSOB or {}

local function recompute(g)
    g.pool = g.pool or {}
    g.npcPool = {}
    for _, o in ipairs(g.outcomes or {}) do g.pool[o.id] = 0 end
    for _, b in pairs(g.bets or {}) do
        g.pool[b.outcome] = (g.pool[b.outcome] or 0) + b.amount
    end
    for outcomeId, amount in pairs(g.npcBets or {}) do
        amount = math.floor(tonumber(amount) or 0)
        if amount > 0 then
            g.pool[outcomeId] = (g.pool[outcomeId] or 0) + amount
            g.npcPool[outcomeId] = (g.npcPool[outcomeId] or 0) + amount
        end
    end
end

local function realBetStats(g)
    local totals, picked = {}, {}
    local total, count = 0, 0
    for _, b in pairs(g.bets or {}) do
        local amount = math.floor(tonumber(b.amount) or 0)
        if amount > 0 and b.outcome then
            count = count + 1
            total = total + amount
            totals[b.outcome] = (totals[b.outcome] or 0) + amount
            picked[b.outcome] = true
        end
    end
    return totals, picked, total, count
end

local function clearNpcOpponent(g)
    g.npcBets = {}
    g.npcPool = {}
    g.npcOpponentSeededRound = nil
end

local function buildNpcOpponentBets(g)
    local cfg = Config.NpcOpponent or {}
    if cfg.enabled == false then return {} end

    local _, picked, realTotal, realCount = realBetStats(g)
    if realTotal <= 0 or realCount <= 0 then return {} end

    local autoDisableAt = tonumber(cfg.activeWhenRealBettorsBelow or 0) or 0
    if autoDisableAt > 0 and realCount >= autoDisableAt then return {} end

    local eligible = {}
    for _, outcome in ipairs(g.outcomes or {}) do
        if outcome.id and not picked[outcome.id] then
            eligible[#eligible+1] = outcome.id
        end
    end
    if #eligible == 0 then return {} end

    local multiplier = tonumber(cfg.stakeMultiplier or 1.0) or 1.0
    local npcTotal = math.floor(realTotal * multiplier)
    local minStake = math.floor(tonumber(cfg.minStake or 0) or 0)
    if minStake > 0 then npcTotal = math.max(npcTotal, minStake) end

    local maxTotal = math.floor(tonumber(cfg.maxTotalStake or 0) or 0)
    if maxTotal > 0 then npcTotal = math.min(npcTotal, maxTotal) end
    if npcTotal <= 0 then return {} end

    local maxPerOutcome = math.floor(tonumber(cfg.maxPerOutcome or 0) or 0)
    local base = math.floor(npcTotal / #eligible)
    local remainder = npcTotal - (base * #eligible)
    local out = {}

    for i, outcomeId in ipairs(eligible) do
        local amount = base
        if i <= remainder then amount = amount + 1 end
        if maxPerOutcome > 0 then amount = math.min(amount, maxPerOutcome) end
        if amount > 0 then out[outcomeId] = amount end
    end

    return out
end

function RSOB.RefreshNpcOpponent(g)
    if not g then return end
    g.npcBets = buildNpcOpponentBets(g)
    recompute(g)
end

function RSOB.ClearNpcOpponent(g)
    if not g then return end
    clearNpcOpponent(g)
end

local function moneyAccount()
    if Config.Betting and Config.Betting.account and Config.Betting.account ~= '' then
        return Config.Betting.account
    end
    return Config.Currency or 'cash'
end

local function betLabel(outcomes, outcomeId)
    for _, o in ipairs(outcomes or {}) do
        if o.id == outcomeId then return o.label or o.id end
    end
    return tostring(outcomeId)
end

function RSOB.PlaceBet(src, gameId, outcomeId, amount)
    local g = RSOB.Games[tonumber(gameId)]
    if not g then RSBridge.Notify(src, 'No active betting show.', 'error'); return false end
    if g.state ~= 'ROUND_BETTING' then RSBridge.Notify(src, 'Bets are not open.', 'error'); return false end
    if g.host and g.host ~= 0 and g.host == src and not (Config.Betting and Config.Betting.hostCanBet) then
        RSBridge.Notify(src, 'Hosts cannot bet in their own show. Set Config.Betting.hostCanBet = true to test as owner.', 'error'); return false
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount < Config.MinBet or amount > Config.MaxBet then
        RSBridge.Notify(src, ('Bet must be between $%s and $%s.'):format(Config.MinBet, Config.MaxBet), 'error')
        return false
    end
    if (not Config.Betting or Config.Betting.oneBetPerRound ~= false) and g.bets[src] and g.bets[src].round == g.round then
        RSBridge.Notify(src, 'You already bet this round.', 'error'); return false
    end
    local valid = false
    for _, o in ipairs(g.outcomes or {}) do
        if o.id == outcomeId then valid = true break end
    end
    if not valid then RSBridge.Notify(src, 'Invalid outcome.', 'error'); return false end
    if not RSBridge.RemoveMoney(src, moneyAccount(), amount, 'rs-outcomebets-cash-stake') then
        RSBridge.Notify(src, 'Not enough cash.', 'error'); return false
    end
    g.bets[src] = {
        amount=amount, outcome=outcomeId, name=RSBridge.GetName(src), round=g.round,
        armedLeave=Config.AntiLeave.armOnFirstBet
    }
    RSOB.RefreshNpcOpponent(g)
    RSBridge.Notify(src, ('Cash bet placed: $%s on %s.'):format(amount, betLabel(g.outcomes, outcomeId)), 'success')
    if Config.NpcOpponent and Config.NpcOpponent.enabled and Config.NpcOpponent.notifyOnSeed ~= false and g.npcPool and next(g.npcPool) then
        RSBridge.Notify(src, ('%s is covering the other side this round.'):format(Config.NpcOpponent.label or 'NPC House'), 'primary')
    end
    if Config.VIP and Config.VIP.enabled and Config.VIP.hypeHighRollers and amount >= (Config.VIP.highRollerAmount or 10000) then
        RSOB.Hype(g, 'highroller', ('High roller bet: $%s on %s.'):format(amount, betLabel(g.outcomes, outcomeId)))
    end
    RSOB.Sync(g)
    return true
end

function RSOB.RefundRound(g, reason)
    for src, b in pairs(g.bets or {}) do
        RSBridge.AddMoney(src, moneyAccount(), b.amount, 'rs-outcomebets-cash-refund')
        RSBridge.Notify(src, ('Refunded $%s (%s).'):format(b.amount, reason or 'cancelled'), 'primary')
    end
    g.bets = {}
    clearNpcOpponent(g)
    recompute(g)
end

function RSOB.ForfeitBet(src, gameId)
    local g = RSOB.Games[tonumber(gameId)]
    if not g or not g.bets[src] then return end
    if g.bets[src].round ~= g.round then return end
    local lost = g.bets[src].amount
    g.bets[src] = nil
    RSOB.RefreshNpcOpponent(g)
    RSBridge.Notify(src, Config.Text.leaveForfeit or ('Forfeited $'..lost), 'error')
    RSOB.Sync(g)
end

function RSOB.PayoutRound(g, winningOutcome)
    if g._paidRound == g.round then return end
    g._paidRound = g.round
    g.state = 'ROUND_PAYOUT'
    local payoutSeconds = math.max(1, tonumber(Config.Show.paidOutDelay) or 6)
    g.payoutEndsAt = os.time() + payoutSeconds
    RSOB.RefreshNpcOpponent(g)
    RSOB.Sync(g)
    RSOB.Hype(g, 'payout')

    local winnerTotal = g.pool[winningOutcome] or 0
    local totalPool = 0
    for _, amt in pairs(g.pool or {}) do totalPool = totalPool + amt end
    local loserPool = totalPool - winnerTotal
    local paid = {}

    for src, b in pairs(g.bets or {}) do
        if b.outcome == winningOutcome then
            local profit = 0
            if winnerTotal > 0 then profit = math.floor((b.amount / winnerTotal) * loserPool) end
            local payout = b.amount + profit
            RSBridge.AddMoney(src, moneyAccount(), payout, 'rs-outcomebets-cash-win')
            RSBridge.Notify(src, ('WINNER: cash paid $%s.'):format(payout), 'success')
            paid[#paid+1] = { src=src, amount=payout, result='win' }
        else
            RSBridge.Notify(src, ('Lost cash bet: $%s. Winner: %s.'):format(b.amount, betLabel(g.outcomes, winningOutcome)), 'error')
            paid[#paid+1] = { src=src, amount=b.amount, result='lose' }
        end
    end
    TriggerClientEvent('rs-outcomebets:client:payoutResult', -1, g.id, winningOutcome, paid)
    g.bets = {}
    clearNpcOpponent(g)
    recompute(g)

    SetTimeout(payoutSeconds * 1000, function()
        local live = RSOB.Games[g.id]
        if not live then return end
        local nextRound = live.round + 1
        -- only require nextRound to be within roundsPerShow; GetRoundCfg cycles
        -- through configured rounds so we do not need an explicit Config.Rounds[N]
        if nextRound <= Config.Show.roundsPerShow and RSOB.GetRoundCfg(nextRound) then
            RSOB.InterRound(live, nextRound)
        else
            RSOB.EndShow(live)
        end
    end)
end
