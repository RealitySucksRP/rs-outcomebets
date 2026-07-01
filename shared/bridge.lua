RSBridge = RSBridge or {}
RSBridge.framework = 'standalone'

local function resStarted(name)
    return GetResourceState(name) == 'started'
end

CreateThread(function()
    if Config.Framework == 'qbcore' or (Config.Framework == 'auto' and resStarted('qb-core')) then
        RSBridge.framework = 'qbcore'
        RSBridge.QBCore = exports['qb-core']:GetCoreObject()
    elseif Config.Framework == 'qbox' or (Config.Framework == 'auto' and resStarted('qbx_core')) then
        RSBridge.framework = 'qbox'
    else
        RSBridge.framework = 'standalone'
    end
    print(('[rs-outcomebets] bridge=%s'):format(RSBridge.framework))
end)

function RSBridge.Notify(src, msg, typ)
    if IsDuplicityVersion() then
        TriggerClientEvent('rs-outcomebets:client:notify', src, msg, typ or 'primary')
    else
        if RSBridge.framework == 'qbcore' and RSBridge.QBCore then RSBridge.QBCore.Functions.Notify(msg, typ or 'primary') return end
        if lib and lib.notify then lib.notify({ description = msg, type = typ or 'inform' }) return end
        BeginTextCommandThefeedPost('STRING'); AddTextComponentSubstringPlayerName(msg); EndTextCommandThefeedPostTicker(false, false)
    end
end

function RSBridge.GetPlayer(src)
    if RSBridge.framework == 'qbcore' and RSBridge.QBCore then return RSBridge.QBCore.Functions.GetPlayer(src) end
    if RSBridge.framework == 'qbox' and exports.qbx_core then return exports.qbx_core:GetPlayer(src) end
    return nil
end

function RSBridge.GetName(src)
    local p = RSBridge.GetPlayer(src)
    if p then
        if p.PlayerData and p.PlayerData.charinfo then
            local c = p.PlayerData.charinfo
            return ((c.firstname or 'Player') .. ' ' .. (c.lastname or tostring(src)))
        end
        if p.name then return p.name end
    end
    return GetPlayerName(src) or ('Player '..src)
end

function RSBridge.RemoveMoney(src, account, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    local p = RSBridge.GetPlayer(src)
    if RSBridge.framework == 'qbcore' and p then
        local bal = p.PlayerData.money and p.PlayerData.money[account] or 0
        if bal < amount then return false end
        return p.Functions.RemoveMoney(account, amount, reason or 'rs-outcomebets')
    elseif RSBridge.framework == 'qbox' and p and exports.qbx_core then
        return exports.qbx_core:RemoveMoney(src, account, amount, reason or 'rs-outcomebets')
    end
    return true -- standalone test mode
end

function RSBridge.AddMoney(src, account, amount, reason)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    local p = RSBridge.GetPlayer(src)
    if RSBridge.framework == 'qbcore' and p then
        return p.Functions.AddMoney(account, amount, reason or 'rs-outcomebets')
    elseif RSBridge.framework == 'qbox' and p and exports.qbx_core then
        return exports.qbx_core:AddMoney(src, account, amount, reason or 'rs-outcomebets')
    end
    return true
end
