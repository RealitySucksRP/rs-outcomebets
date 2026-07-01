RSOBClient = RSOBClient or {}
local outsideSince = {}

local function dist2d(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function hasActiveBet(g)
    if not g or not g.bets then return false end
    local mySrc = tostring(GetPlayerServerId(PlayerId()))
    local b = g.bets[mySrc]
    if not b then return false end
    -- only the current round counts; after PayoutRound bets are cleared anyway
    if b.round and g.round and b.round ~= g.round then return false end
    return true
end

CreateThread(function()
    while true do
        Wait(1000)
        if Config.AntiLeave.enabled and RSOBClient.games then
            local pc = GetEntityCoords(PlayerPedId())
            for gameId, g in pairs(RSOBClient.games) do
                local watchable = (g.state == 'ROUND_BETTING' or g.state == 'ROUND_LOCKED' or g.state == 'ROUND_EXECUTE')
                if watchable and hasActiveBet(g) then
                    local radius = (g.radius or 8.0) + 2.0
                    local d = dist2d(pc.x, pc.y, g.coords.x, g.coords.y)
                    if d > radius then
                        outsideSince[gameId] = outsideSince[gameId] or GetGameTimer()
                        local elapsed = math.floor((GetGameTimer() - outsideSince[gameId]) / 1000)
                        local left = (Config.AntiLeave.graceSeconds or 12) - elapsed
                        if left > 0 then
                            SendNUIMessage({ action='leaveWarning', data={ seconds=left } })
                        else
                            TriggerServerEvent('rs-outcomebets:server:forfeitLeave', gameId)
                            outsideSince[gameId] = GetGameTimer() + 999999
                            SendNUIMessage({ action='leaveReturn', data={} })
                        end
                    else
                        if outsideSince[gameId] then
                            SendNUIMessage({ action='leaveReturn', data={} })
                        end
                        outsideSince[gameId] = nil
                    end
                else
                    if outsideSince[gameId] then
                        SendNUIMessage({ action='leaveReturn', data={} })
                    end
                    outsideSince[gameId] = nil
                end
            end
        end
    end
end)
