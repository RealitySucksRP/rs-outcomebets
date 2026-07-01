RSOBClient = RSOBClient or {}

local function openMenuFor(gameId)
    local g = RSOBClient.games and RSOBClient.games[gameId]
    if not g then return end
    SendNUIMessage({ action='show', data=g })
    SetNuiFocus(true, true)
end

function RSOBClient.SetupCashierTarget(gameId, ped)
    if not ped or not DoesEntityExist(ped) then return end
    if GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddTargetEntity(ped, {
            options = {{
                icon = Config.Cashier.target.icon,
                label = Config.Cashier.target.label,
                action = function() openMenuFor(gameId) end
            }},
            distance = Config.Cashier.target.distance or 2.5
        })
    end
end

function RSOBClient.RemoveCashierTarget(ped)
    if not ped then return end
    if GetResourceState('qb-target') == 'started' then
        pcall(function() exports['qb-target']:RemoveTargetEntity(ped, Config.Cashier.target.label) end)
    end
end

-- E-key fallback when qb-target is not present, or for raw interaction
CreateThread(function()
    while true do
        local wait = 750
        local ped = PlayerPedId()
        local pc = GetEntityCoords(ped)
        if RSOBClient.entities then
            for gameId, b in pairs(RSOBClient.entities) do
                if b.cashier and DoesEntityExist(b.cashier) then
                    local ec = GetEntityCoords(b.cashier)
                    local d = #(pc - ec)
                    if d < 2.0 then
                        wait = 0
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to place a bet')
                        EndTextCommandDisplayHelp(0, false, false, -1)
                        if IsControlJustPressed(0, 38) then openMenuFor(gameId) end
                    end
                end
            end
        end
        Wait(wait)
    end
end)
