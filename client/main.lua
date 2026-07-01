RSOBClient = RSOBClient or { games={}, current=nil, entities={}, lastHype=0 }

local function dbg(msg) if Config.Debug then print('[rs-outcomebets:client] '..msg) end end

RegisterNetEvent('rs-outcomebets:client:notify', function(msg, typ)
    RSBridge.Notify(nil, msg, typ)
end)

local function sendUi(action, data)
    SendNUIMessage({ action=action, data=data or {} })
end
RSOBClient.SendUi = sendUi

RegisterCommand(Config.Commands.open, function()
    if RSOBClient.current and RSOBClient.games[RSOBClient.current] then
        sendUi('show', RSOBClient.games[RSOBClient.current])
        SetNuiFocus(true, true)
    else
        RSBridge.Notify(nil, 'No nearby betting show.', 'error')
    end
end, false)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false); cb({ ok=true })
end)

RegisterNUICallback('placeBet', function(data, cb)
    TriggerServerEvent('rs-outcomebets:server:placeBet', data.gameId, data.outcomeId, data.amount)
    cb({ ok=true })
end)

RegisterNetEvent('rs-outcomebets:client:sync', function(gameId, game)
    RSOBClient.games[gameId] = game
    RSOBClient.current = gameId
    -- only spawn locally if within streaming distance; the streaming thread
    -- (in arena.lua) handles ensure/cleanup as the player moves
    if RSOBClient.UpdateStreaming then RSOBClient.UpdateStreaming(gameId) end
    sendUi('sync', game)
end)

RegisterNetEvent('rs-outcomebets:client:hype', function(gameId, bucket, text)
    if not RSOBClient.games[gameId] then return end
    sendUi('hype', { bucket=bucket, text=text })
    if RSOBClient.AtmosphereHype then RSOBClient.AtmosphereHype(gameId, bucket) end
end)

RegisterNetEvent('rs-outcomebets:client:warn', function(gameId, secondsLeft)
    if not RSOBClient.games[gameId] then return end
    sendUi('warn', { secondsLeft=secondsLeft })
    if RSOBClient.AtmosphereHype then RSOBClient.AtmosphereHype(gameId, 'warning') end
end)

RegisterNetEvent('rs-outcomebets:client:playOutcome', function(gameId, outcome, reaction)
    if not RSOBClient.games[gameId] then return end
    if RSOBClient.PlayPerformerOutcome then RSOBClient.PlayPerformerOutcome(gameId, outcome) end
    if RSOBClient.PlayReaction then RSOBClient.PlayReaction(gameId, reaction) end
    if RSOB_PlayOutcomeVoices then RSOB_PlayOutcomeVoices(gameId, outcome, reaction) end
    sendUi('execute', { outcome=outcome, reaction=reaction })
    if RSOBClient.AtmosphereHype then RSOBClient.AtmosphereHype(gameId, 'execute') end
end)

RegisterNetEvent('rs-outcomebets:client:payoutResult', function(gameId, winningOutcome, paid)
    local label = winningOutcome
    local g = RSOBClient.games and RSOBClient.games[gameId]
    if g and g.outcomes then
        for _, o in ipairs(g.outcomes) do if o.id == winningOutcome then label = o.label or o.id break end end
    end
    sendUi('result', { gameId=gameId, winningOutcome=winningOutcome, label=label, paid=paid })
    if RSOBClient.AtmosphereHype then RSOBClient.AtmosphereHype(gameId, 'payout') end
end)

RegisterNetEvent('rs-outcomebets:client:cleanup', function(gameId, reason)
    if RSOBClient.CleanupArena then RSOBClient.CleanupArena(gameId) end
    RSOBClient.games[gameId] = nil
    if RSOBClient.current == gameId then RSOBClient.current = nil end
    sendUi('hide', { reason=reason })
    SetNuiFocus(false, false)
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('rs-outcomebets:server:requestSync')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
    if RSOBClient.entities then
        for gameId, _ in pairs(RSOBClient.entities) do
            if RSOBClient.CleanupArena then RSOBClient.CleanupArena(gameId) end
        end
    end
end)
