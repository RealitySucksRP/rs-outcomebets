-- rs-outcomebets audio.lua
-- Added by RS OutcomeBets Audio Director.
-- Client-only NUI OGG voice layer. No cash/gameplay logic changed.

local lastVoiceAt = 0

local function voiceConfig()
    return Config and Config.VoiceAudio or {}
end

local function asList(value)
    if type(value) == 'string' then return { value } end
    if type(value) == 'table' then return value end
    return nil
end

local function pickFrom(files)
    if not files or #files == 0 then return nil end
    return files[math.random(1, #files)]
end

local function pickFile(bucket)
    local cfg = voiceConfig()
    if cfg.enabled == false then return end
    local files = cfg.files and cfg.files[bucket] or nil
    return pickFrom(files)
end

local function canHearGame(gameId)
    local cfg = voiceConfig()
    local radius = tonumber(cfg.audibleRadius or 0) or 0
    if radius <= 0 or not gameId then return true end
    if not RSOBClient or not RSOBClient.games then return true end
    local game = RSOBClient.games[gameId]
    if not game or not game.coords then return true end

    local ped = PlayerPedId()
    if not ped or ped == 0 then return true end

    local p = GetEntityCoords(ped)
    local g = vector3(game.coords.x, game.coords.y, game.coords.z)
    return #(p - g) <= radius
end

local function sendVoice(file, volume, delayMs)
    if not file or file == '' then return end
    delayMs = tonumber(delayMs or 0) or 0
    if delayMs > 0 then
        SetTimeout(delayMs, function()
            sendVoice(file, volume, 0)
        end)
        return
    end

    SendNUIMessage({
        action = 'playVoice',
        file = file,
        volume = tonumber(volume or voiceConfig().volume or 0.70) or 0.70
    })
end

function RSOB_PlayVoiceFile(file, opts)
    local cfg = voiceConfig()
    if cfg.enabled == false then return end
    opts = opts or {}
    if opts.gameId and not canHearGame(opts.gameId) then return end
    sendVoice(file, opts.volume or cfg.volume, opts.delayMs or 0)
end

function RSOB_PlayVoiceFromList(files, opts)
    local file = pickFrom(asList(files))
    if not file then return end
    RSOB_PlayVoiceFile(file, opts)
end

function RSOB_PlayVoiceBucket(bucket, gameId)
    local cfg = voiceConfig()
    if cfg.enabled == false then return end
    if gameId and not canHearGame(gameId) then return end

    local cooldown = tonumber(cfg.cooldownMs or 2500) or 2500
    local now = GetGameTimer()
    if now - lastVoiceAt < cooldown then return end

    local file = pickFile(bucket)
    if not file or file == '' then return end

    lastVoiceAt = now
    sendVoice(file, cfg.volume, 0)
end

local function textHasAny(text, words)
    for _, word in ipairs(words or {}) do
        if text:find(word, 1, true) then return true end
    end
    return false
end

local function inferVoiceType(outcome, reaction)
    if reaction and reaction.voiceType then return reaction.voiceType end
    if outcome and outcome.voiceType then return outcome.voiceType end

    local text = string.lower(((outcome and outcome.id) or '') .. ' ' .. ((outcome and outcome.label) or ''))
    if textHasAny(text, { 'slap', 'punch', 'hook', 'kick', 'shot', 'fight', 'combat', 'knock', 'runover', 'attack' }) then
        return 'hit'
    end
    if textHasAny(text, { 'bird', 'finger', 'taunt', 'argue', 'facepalm', 'thumb', 'peace', 'roast', 'soft', 'pose' }) then
        return 'humiliation'
    end
    if textHasAny(text, { 'dance', 'guitar', 'jazz', 'bow', 'salute', 'flex', 'shag', 'pole', 'club' }) then
        return 'showboat'
    end
    if textHasAny(text, { 'alien', 'mind', 'fall', 'stumble', 'crawl', 'pass', 'sleep', 'chaos', 'carjack', 'horde', 'explosion', 'panic', 'flip' }) then
        return 'chaos'
    end
    return 'generic'
end

local function pool(kind, voiceType)
    local cfg = voiceConfig()
    local pools = cfg.pools and cfg.pools[kind] or nil
    if not pools then return nil end
    return pools[voiceType] or pools.generic
end

function RSOB_PlayOutcomeVoices(gameId, outcome, reaction)
    local cfg = voiceConfig()
    if cfg.enabled == false then return end

    local action = cfg.action or {}
    if action.enabled == false then return end
    if not canHearGame(gameId) then return end

    local voiceType = inferVoiceType(outcome, reaction)
    local performerFiles = asList(outcome and outcome.performerSounds) or pool('performer', voiceType)
    local reactorFiles = asList((reaction and reaction.sounds) or (outcome and outcome.reactorSounds)) or pool('reactor', voiceType)
    local crowdFiles = asList(outcome and outcome.crowdSounds) or pool('crowd', voiceType)

    RSOB_PlayVoiceFromList(performerFiles, {
        gameId = gameId,
        volume = action.performerVolume or action.volume or cfg.volume,
        delayMs = action.performerDelayMs or 100
    })

    RSOB_PlayVoiceFromList(reactorFiles, {
        gameId = gameId,
        volume = action.reactorVolume or action.volume or cfg.volume,
        delayMs = action.reactorDelayMs or 850
    })

    if crowdFiles and math.random(1, 100) <= (tonumber(action.crowdChance) or 35) then
        RSOB_PlayVoiceFromList(crowdFiles, {
            gameId = gameId,
            volume = action.crowdVolume or action.volume or cfg.volume,
            delayMs = action.crowdDelayMs or 1500
        })
    end
end

RegisterNetEvent('rs-outcomebets:client:hype', function(gameId, bucket, text)
    RSOB_PlayVoiceBucket(bucket, gameId)
end)

RegisterNetEvent('rs-outcomebets:client:warn', function(gameId, secondsLeft)
    RSOB_PlayVoiceBucket('warning', gameId)
end)

RegisterNetEvent('rs-outcomebets:client:payoutResult', function(gameId, winningOutcome, paid)
    RSOB_PlayVoiceBucket('payout', gameId)
end)
