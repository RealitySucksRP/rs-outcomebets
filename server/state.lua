RSOB = RSOB or {}
RSOB.Games = RSOB.Games or {}
RSOB.PlayerGame = RSOB.PlayerGame or {}
RSOB.NextGameId = RSOB.NextGameId or 1

local function now() return os.time() end
local function dbg(msg) if Config.Debug then print('[rs-outcomebets:state] '..msg) end end

local function getCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    return { x=c.x, y=c.y, z=c.z, w=h }
end

local function findArena(id)
    for _, a in ipairs(Config.Arenas or {}) do if a.id == id then return a end end
    return (Config.Arenas or {})[1]
end

-- sorted list of configured round keys (cached on first use)
local _configuredKeysCache = nil
local function configuredKeys()
    if _configuredKeysCache then return _configuredKeysCache end
    local keys = {}
    for k, _ in pairs(Config.Rounds or {}) do
        if type(k) == 'number' then keys[#keys+1] = k end
    end
    table.sort(keys)
    _configuredKeysCache = keys
    return keys
end

local function shallowCopy(t)
    local out = {}
    for k, v in pairs(t or {}) do out[k] = v end
    return out
end

local function contains(list, value)
    for _, v in ipairs(list or {}) do if v == value then return true end end
    return false
end

local function pushRecent(list, value, maxLen)
    if not value then return end
    list = list or {}
    list[#list+1] = value
    maxLen = tonumber(maxLen) or 4
    while #list > maxLen do table.remove(list, 1) end
    return list
end

local function getBranchCandidates(branchId)
    local b = Config.OutcomeBranches and Config.OutcomeBranches[branchId]
    if not b then return {} end
    return b.outcomes or {}
end

local function addReactionPool(out, poolId)
    local pool = Config.ReactionPools and Config.ReactionPools[poolId] or nil
    if not pool then return end
    for _, reaction in ipairs(pool) do
        out[#out+1] = shallowCopy(reaction)
    end
end

local function getOutcomeReactions(outcome)
    local out = {}
    local pools = outcome and outcome.reactionPool or nil

    if type(pools) == 'table' then
        for _, poolId in ipairs(pools) do addReactionPool(out, poolId) end
    elseif type(pools) == 'string' then
        addReactionPool(out, pools)
    end

    for _, reaction in ipairs((outcome and outcome.reactions) or {}) do
        out[#out+1] = shallowCopy(reaction)
    end

    return out
end

local function makeRoundFromBranch(g, cfg)
    local randomizer = Config.Randomizer or {}
    local pickCount = tonumber(cfg.pickCount or randomizer.pickCount or 4) or 4
    local noRepeatWindow = tonumber(randomizer.noRepeatWindow or 4) or 4
    local candidates = {}

    -- Pull from one or more branches. This lets each round be a branch like
    -- 'combat', 'showboat', or a mixed table { 'combat', 'taunt' }.
    if cfg.branch then
        if type(cfg.branch) == 'table' then
            for _, branchId in ipairs(cfg.branch) do
                for _, o in ipairs(getBranchCandidates(branchId)) do candidates[#candidates+1] = o end
            end
        else
            for _, o in ipairs(getBranchCandidates(cfg.branch)) do candidates[#candidates+1] = o end
        end
    end
    for _, o in ipairs(cfg.outcomes or {}) do candidates[#candidates+1] = o end

    if #candidates == 0 then return {} end

    local picked, used = {}, {}
    local recent = g.recentOfferedOutcomeIds or {}

    -- Pass 1: try to avoid anything shown in the last few rounds.
    while #picked < pickCount do
        local pool = {}
        for _, o in ipairs(candidates) do
            if o.id and not used[o.id] and not contains(recent, o.id) then pool[#pool+1] = o end
        end
        if #pool == 0 then break end
        local pick = RSOB.RollWeighted(pool)
        if not pick then break end
        picked[#picked+1] = shallowCopy(pick)
        used[pick.id] = true
    end

    -- Pass 2: fill remaining slots even if recent avoidance exhausted the branch.
    while #picked < pickCount do
        local pool = {}
        for _, o in ipairs(candidates) do
            if o.id and not used[o.id] then pool[#pool+1] = o end
        end
        if #pool == 0 then break end
        local pick = RSOB.RollWeighted(pool)
        if not pick then break end
        picked[#picked+1] = shallowCopy(pick)
        used[pick.id] = true
    end

    -- Remember what was offered so the next rounds feel fresh.
    for _, o in ipairs(picked) do
        g.recentOfferedOutcomeIds = pushRecent(g.recentOfferedOutcomeIds, o.id, noRepeatWindow)
    end

    return picked
end

-- Returns the round config to use for a given round number.
-- - If the round is explicitly configured, returns that.
-- - Otherwise honors Config.Show.fillMissingRounds: 'cycle' wraps through configured
--   rounds, 'random' picks a random configured round, 'end' returns nil.
function RSOB.GetRoundCfg(roundId)
    local cfg = Config.Rounds and Config.Rounds[roundId] or nil
    if cfg then return cfg end
    local mode = (Config.Show and Config.Show.fillMissingRounds) or 'cycle'
    if mode == 'end' then return nil end
    local keys = configuredKeys()
    if #keys == 0 then return nil end
    if mode == 'random' then
        return Config.Rounds[keys[math.random(1, #keys)]]
    end
    local idx = ((roundId - 1) % #keys) + 1
    return Config.Rounds[keys[idx]]
end

function RSOB.GetRoundOutcomes(g, cfg)
    if not cfg then return {} end
    if cfg.branch then return makeRoundFromBranch(g, cfg) end
    local out = {}
    for _, o in ipairs(cfg.outcomes or {}) do out[#out+1] = shallowCopy(o) end
    return out
end

local function applyWinnerAntiRepeat(g, outcomes)
    local randomizer = Config.Randomizer or {}
    local recent = g.recentWinningOutcomeIds or {}
    local penalty = tonumber(randomizer.repeatWeightPenalty or 0.15) or 0.15
    local adjusted = {}
    for _, o in ipairs(outcomes or {}) do
        local c = shallowCopy(o)
        if contains(recent, c.id) then
            c.weight = math.max(1, math.floor((tonumber(c.weight) or 1) * penalty))
        end
        adjusted[#adjusted+1] = c
    end
    return adjusted
end

local function publicGame(g)
    local bets = {}
    for src, bet in pairs(g.bets or {}) do
        bets[tostring(src)] = { amount=bet.amount, outcome=bet.outcome, name=bet.name, round=bet.round }
    end
    local timeLeft = nil
    if g.state == 'COUNTDOWN' and g.countdownEndsAt then
        timeLeft = math.max(0, g.countdownEndsAt - now())
    elseif g.state == 'ROUND_BETTING' and g.bettingEndsAt then
        timeLeft = math.max(0, g.bettingEndsAt - now())
    elseif g.state == 'INTER_ROUND' and g.interRoundEndsAt then
        timeLeft = math.max(0, g.interRoundEndsAt - now())
    elseif g.state == 'ROUND_PAYOUT' and g.payoutEndsAt then
        timeLeft = math.max(0, g.payoutEndsAt - now())
    end
    local publicOutcomes = {}
    local totalPool = 0
    for _, amt in pairs(g.pool or {}) do totalPool = totalPool + (tonumber(amt) or 0) end
    for _, o in ipairs(g.outcomes or {}) do
        local pool = (g.pool and g.pool[o.id]) or 0
        local npcPool = (g.npcPool and g.npcPool[o.id]) or 0
        local c = shallowCopy(o)
        c.pool = pool
        c.npcPool = (Config.NpcOpponent and Config.NpcOpponent.showInUi == false) and 0 or npcPool
        if Config.DynamicOdds and Config.DynamicOdds.enabled and pool > 0 then
            c.poolShare = math.floor((pool / math.max(totalPool, 1)) * 100)
            -- Potential payout estimate for a default bet if it joined the current pool.
            local stake = tonumber(Config.DefaultBet or Config.MinBet or 100) or 100
            local winnerTotal = pool + stake
            local loserPool = math.max(0, totalPool - pool)
            c.potential = stake + math.floor((stake / math.max(winnerTotal, 1)) * loserPool)
        else
            c.poolShare = 0
            c.potential = 0
        end
        publicOutcomes[#publicOutcomes+1] = c
    end

    return {
        id=g.id, host=g.host, state=g.state, arena=g.arena, coords=g.coords, shape=g.shape,
        radius=g.radius, size=g.size, wallHeight=g.wallHeight, round=g.round,
        roundsPerShow=g.roundsPerShow, timeLeft=timeLeft, prompt=g.prompt, outcomes=publicOutcomes,
        bets=bets, pool=g.pool or {}, winner=g.winner, resolvedLabel=g.resolvedLabel,
        npcPool=g.npcPool or {}, npcOpponentActive=(g.npcPool and next(g.npcPool) ~= nil) or false,
        isAutoLoop=g.isAutoLoop or false
    }
end
RSOB.PublicGame = publicGame

function RSOB.Broadcast(g, event, ...)
    TriggerClientEvent(event, -1, g.id, ...)
end

function RSOB.Sync(g)
    RSOB.Broadcast(g, 'rs-outcomebets:client:sync', publicGame(g))
end

function RSOB.Hype(g, bucket, fallback)
    if not Config.Hype or not Config.Hype.enabled then return end
    local lines = Config.Hype.lines and Config.Hype.lines[bucket] or nil
    local text = fallback or ''
    if lines and #lines > 0 then text = lines[math.random(1, #lines)] end
    RSOB.Broadcast(g, 'rs-outcomebets:client:hype', bucket, text)
end

function RSOB.MakeGame(src, mode, arenaId)
    if src ~= 0 and RSOB.PlayerGame[src] then
        RSBridge.Notify(src, 'You already have an active betting show.', 'error'); return nil
    end
    local arena, coords, shape, radius, size, wallHeight
    if mode == 'fixed' or mode == 'autoloop' then
        arena = findArena(arenaId)
        if not arena then
            if src ~= 0 then RSBridge.Notify(src, 'No arena configured.', 'error') end
            return nil
        end
        coords = { x=arena.coords.x, y=arena.coords.y, z=arena.coords.z, w=arena.coords.w }
        shape, radius, size, wallHeight = arena.shape, arena.radius, arena.size, arena.wallHeight
    else
        if not Config.Hostable.enabled then
            RSBridge.Notify(src, 'Hostable popup arenas are disabled.', 'error'); return nil
        end
        coords = getCoords(src)
        if not coords then return nil end
        shape, radius, size, wallHeight = Config.Hostable.shape, Config.Hostable.radius, Config.Hostable.size, Config.Hostable.wallHeight
    end
    local g = {
        id=RSOB.NextGameId, host=src, state='SETUP', mode=mode,
        arena=arena and arena.id or 'popup', coords=coords,
        shape=shape or 'circle', radius=radius or 8.0, size=size or 16.0,
        wallHeight=wallHeight or 'low', round=0,
        roundsPerShow=Config.Show.roundsPerShow, bets={}, pool={},
        createdAt=now(), isAutoLoop=(mode == 'autoloop')
    }
    RSOB.NextGameId = RSOB.NextGameId + 1
    RSOB.Games[g.id] = g
    if src ~= 0 then RSOB.PlayerGame[src] = g.id end
    RSOB.Sync(g)
    RSOB.Hype(g, 'setup')
    return g
end

function RSOB.Destroy(id, reason, refund)
    local g = RSOB.Games[id]
    if not g then return end
    if refund and RSOB.RefundRound then RSOB.RefundRound(g, reason or 'cancelled') end
    RSOB.Broadcast(g, 'rs-outcomebets:client:cleanup', reason or 'ended')
    if g.host and g.host ~= 0 then RSOB.PlayerGame[g.host] = nil end
    RSOB.Games[id] = nil
end

function RSOB.GetHostGame(src)
    if src ~= 0 then
        local id = RSOB.PlayerGame[src]
        if id then return RSOB.Games[id] end
    end
    for _, g in pairs(RSOB.Games) do if g.host == src then return g end end
    return nil
end

function RSOB.RollWeighted(list)
    local total = 0
    for _, item in ipairs(list or {}) do total = total + (tonumber(item.weight) or 0) end
    if total <= 0 then return list and list[1] end
    local r, acc = math.random(total), 0
    for _, item in ipairs(list) do
        acc = acc + (tonumber(item.weight) or 0)
        if r <= acc then return item end
    end
    return list[#list]
end

function RSOB.BuildRound(g, roundId)
    local cfg = RSOB.GetRoundCfg(roundId)
    if not cfg then return false end
    g.round = roundId
    local tmpl = (Config.Show and Config.Show.promptTemplate) or 'Round %d / %d -- pick the outcome'
    g.prompt = string.format(tmpl, roundId, g.roundsPerShow or (Config.Show.roundsPerShow or 10))
    g.roundCfg = cfg
    g.roundOutcomesFull = RSOB.GetRoundOutcomes(g, cfg)
    g.outcomes = {}
    g.pool = {}
    g.bets = {}
    g.npcBets = {}
    g.npcPool = {}
    for _, o in ipairs(g.roundOutcomesFull or {}) do
        g.outcomes[#g.outcomes+1] = { id=o.id, label=o.label, weight=o.weight, branch=o.branchLabel or cfg.label, pool=0, potential=0 }
        g.pool[o.id] = 0
    end
    return #g.outcomes > 0
end

function RSOB.BeginCountdown(g, onComplete)
    local secs = math.max(1, tonumber(Config.Show.countdownSeconds) or 8)
    g.state = 'COUNTDOWN'
    g.countdownEndsAt = now() + secs
    RSOB.Sync(g)
    SetTimeout(secs * 1000, function()
        local live = RSOB.Games[g.id]
        if not live then return end
        if onComplete then onComplete(live) else RSOB.StartRound(live, 1) end
    end)
end

function RSOB.StartRound(g, roundId)
    if not RSOB.BuildRound(g, roundId) then RSOB.EndShow(g); return end
    g.state = 'ROUND_BETTING'
    local seconds = math.max(5, tonumber(Config.Show.bettingSeconds) or 30)
    g.bettingEndsAt = now() + seconds
    g.winner = nil; g.resolvedLabel = nil
    RSOB.Sync(g)
    RSOB.Hype(g, 'open')
    for _, secLeft in ipairs(Config.Show.warnAt or {}) do
        local fireIn = (seconds - tonumber(secLeft)) * 1000
        if fireIn > 0 then
            SetTimeout(fireIn, function()
                local live = RSOB.Games[g.id]
                if live and live.state == 'ROUND_BETTING' and live.round == roundId then
                    RSOB.Broadcast(live, 'rs-outcomebets:client:warn', tonumber(secLeft))
                    RSOB.Hype(live, 'warning')
                end
            end)
        end
    end
    SetTimeout(seconds * 1000, function()
        local live = RSOB.Games[g.id]
        if live and live.state == 'ROUND_BETTING' and live.round == roundId then RSOB.LockRound(live) end
    end)
end

function RSOB.LockRound(g)
    g.state = 'ROUND_LOCKED'
    RSOB.Sync(g)
    RSOB.Hype(g, 'locked')
    SetTimeout(1000, function()
        local live = RSOB.Games[g.id]
        if live and live.state == 'ROUND_LOCKED' then RSOB.ExecuteRound(live) end
    end)
end

function RSOB.ExecuteRound(g, forcedOutcomeId)
    local roundCfg = g.roundCfg or RSOB.GetRoundCfg(g.round)
    if not roundCfg then return RSOB.EndShow(g) end
    local available = g.roundOutcomesFull or RSOB.GetRoundOutcomes(g, roundCfg)
    if #available == 0 then return RSOB.EndShow(g) end

    local outcome
    if forcedOutcomeId then
        for _, o in ipairs(available or {}) do
            if o.id == forcedOutcomeId then outcome = o break end
        end
        -- Dev/test helper: allow /betforce to pull any outcome from any branch,
        -- even if it was not one of this round's four betting-card picks.
        if not outcome and Config.OutcomeBranches then
            for _, branch in pairs(Config.OutcomeBranches) do
                for _, o in ipairs(branch.outcomes or {}) do
                    if o.id == forcedOutcomeId then outcome = o break end
                end
                if outcome then break end
            end
        end
    end
    outcome = outcome or RSOB.RollWeighted(applyWinnerAntiRepeat(g, available))
    if not outcome then return RSOB.EndShow(g) end

    local reaction = RSOB.RollWeighted(getOutcomeReactions(outcome)) or {}
    g.state = 'ROUND_EXECUTE'
    g.winner = outcome.id
    g.resolvedLabel = outcome.label or outcome.id
    if Config.RareMoments and Config.RareMoments.enabled and math.random(1, 100) <= (Config.RareMoments.chance or 0) then
        local lines = Config.RareMoments.lines or {}
        RSOB.Hype(g, 'rare', lines[math.random(1, math.max(#lines, 1))] or 'Rare moment!')
    end
    local randomizer = Config.Randomizer or {}
    g.recentWinningOutcomeIds = pushRecent(g.recentWinningOutcomeIds, outcome.id, tonumber(randomizer.noRepeatWinners or 3) or 3)
    RSOB.Sync(g)
    RSOB.Broadcast(g, 'rs-outcomebets:client:playOutcome', outcome, reaction)
    local animCfg = Config.Animation or {}
    local duration = math.max(tonumber(outcome.duration) or 2500, tonumber(reaction.duration) or 1000, tonumber(animCfg.minOutcomeDuration) or 2500, tonumber(animCfg.minReactionDuration) or 1000)
    local hold = tonumber(animCfg.postOutcomeHoldMs) or 0
    SetTimeout(duration + hold + 900, function()
        local live = RSOB.Games[g.id]
        if live and live.state == 'ROUND_EXECUTE' then RSOB.PayoutRound(live, outcome.id) end
    end)
end

function RSOB.InterRound(g, nextRound)
    local secs = math.max(0, tonumber(Config.Show.interRoundDelay) or 0)
    if secs <= 0 then RSOB.StartRound(g, nextRound); return end
    g.state = 'INTER_ROUND'
    g.interRoundEndsAt = now() + secs
    RSOB.Sync(g)
    SetTimeout(secs * 1000, function()
        local live = RSOB.Games[g.id]
        if live then RSOB.StartRound(live, nextRound) end
    end)
end

function RSOB.EndShow(g)
    g.state = 'COOLDOWN'
    RSOB.Sync(g)
    RSOB.Hype(g, 'endshow')
    local wasAutoLoop = g.isAutoLoop
    SetTimeout(3000, function()
        RSOB.Destroy(g.id, 'ended', false)
        if wasAutoLoop and Config.Lifecycle.autoLoop.enabled then
            local cooldown = math.max(5, tonumber(Config.Lifecycle.autoLoop.cooldownBetweenShows) or 300)
            print(('[rs-outcomebets] autoloop: next show in %ds'):format(cooldown))
            SetTimeout(cooldown * 1000, function() RSOB.StartAutoLoop() end)
        end
    end)
end

function RSOB.StartAutoLoop()
    if not Config.Lifecycle or not Config.Lifecycle.autoLoop or not Config.Lifecycle.autoLoop.enabled then return end
    if next(RSOB.Games) then
        SetTimeout(10000, function() RSOB.StartAutoLoop() end)
        return
    end
    local g = RSOB.MakeGame(0, 'autoloop', Config.Lifecycle.autoLoop.arenaId)
    if not g then
        print('[rs-outcomebets] autoloop failed to create game (no arena configured)')
        return
    end
    SetTimeout(1500, function()
        local live = RSOB.Games[g.id]
        if live then RSOB.BeginCountdown(live) end
    end)
end
