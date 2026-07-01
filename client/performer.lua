RSOBClient = RSOBClient or {}

local function loadAnim(dict)
    if not dict or dict == '' then return false end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(10) end
    return HasAnimDictLoaded(dict)
end
RSOBClient.LoadAnim = loadAnim

local function playTimedAnim(ped, dict, anim, totalMs, flags)
    if not ped or not DoesEntityExist(ped) then return false end
    if not loadAnim(dict) then return false end
    totalMs = math.max(tonumber(totalMs) or 2500, 1000)
    flags = flags or 1
    TaskPlayAnim(ped, dict, anim, 4.0, -4.0, totalMs, flags, 0.0, false, false, false)
    if Config.Animation and Config.Animation.replayOneShots then
        local started = GetGameTimer()
        CreateThread(function()
            while DoesEntityExist(ped) and (GetGameTimer() - started) < (totalMs - 1200) do
                Wait(2400)
                if DoesEntityExist(ped) and not IsEntityPlayingAnim(ped, dict, anim, 3) then
                    TaskPlayAnim(ped, dict, anim, 4.0, -4.0, math.max(1200, totalMs - (GetGameTimer() - started)), flags, 0.0, false, false, false)
                end
            end
        end)
    end
    return true
end
RSOBClient.PlayTimedAnim = playTimedAnim

local function drawText3D(x, y, z, text, scale, font, r, g, b, a)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextFont(font or 4)
    SetTextProportional(1)
    SetTextColour(r or 255, g or 255, b or 255, a or 255)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- performer marker render thread
CreateThread(function()
    while true do
        local wait = 750
        if Config.PerformerMarker.enabled and RSOBClient.entities then
            for gameId, b in pairs(RSOBClient.entities) do
                local ped = b.performer
                if ped and DoesEntityExist(ped) then
                    wait = 0
                    local c = GetEntityCoords(ped)
                    local bob = 0.0
                    if Config.PerformerMarker.bob and Config.PerformerMarker.bob.enabled then
                        bob = math.sin(GetGameTimer() / 1000.0 * (Config.PerformerMarker.bob.speed or 1.5))
                              * (Config.PerformerMarker.bob.amplitude or 0.1)
                    end
                    local rgba = Config.PerformerMarker.rgba
                    local size = Config.PerformerMarker.size
                    DrawMarker(Config.PerformerMarker.markerType,
                        c.x, c.y, c.z + Config.PerformerMarker.heightOffset + bob,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        size[1], size[2], size[3],
                        rgba[1], rgba[2], rgba[3], rgba[4],
                        false, true, 2, false, nil, nil, false)
                    if Config.PerformerMarker.text and Config.PerformerMarker.text.enabled then
                        local t = Config.PerformerMarker.text
                        drawText3D(c.x, c.y, c.z + t.heightOffset + bob, t.content,
                            t.scale, t.font, t.rgba[1], t.rgba[2], t.rgba[3], t.rgba[4])
                    end
                end
            end
        end
        Wait(wait)
    end
end)

local function getGroundedAnchor(anchor)
    if not anchor then return nil end
    local ok, gz = GetGroundZFor_3dCoord(anchor.x, anchor.y, anchor.z + 5.0, false)
    local z = (ok and gz ~= 0.0) and gz or anchor.z
    return { x = anchor.x, y = anchor.y, z = z, w = anchor.w or 0.0 }
end
RSOBClient.GetGroundedAnchor = getGroundedAnchor

-- emergency snap only. Normal round cleanup should use WalkBackToAnchor first.
local function snapBack(ped, anchor)
    if not anchor or not DoesEntityExist(ped) then return end
    local a = getGroundedAnchor(anchor)
    SetEntityCoords(ped, a.x, a.y, a.z, false, false, false, true)
    SetEntityHeading(ped, a.w or 0.0)
end
RSOBClient.SnapBack = snapBack

-- Smooth return-to-anchor. This prevents the ugly pop-back after outcomes like
-- stumble, ragdoll, or dodge push the NPC away from the center. If the ped is
-- extremely far away or stuck, it falls back to snapBack so the show cannot break.
local function walkBackToAnchor(ped, anchor, opts)
    if not anchor or not DoesEntityExist(ped) then return false end
    local cfg = Config.ReturnToAnchor or {}
    if not cfg.enabled then
        snapBack(ped, anchor)
        return false
    end

    local a = getGroundedAnchor(anchor)
    local c = GetEntityCoords(ped)
    local dist = #(vector3(c.x, c.y, c.z) - vector3(a.x, a.y, a.z))
    if dist <= (cfg.stopDistance or 0.55) then
        SetEntityHeading(ped, a.w or 0.0)
        return true
    end
    if dist >= (cfg.snapIfFartherThan or 8.0) then
        snapBack(ped, anchor)
        return false
    end

    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    TaskGoStraightToCoord(ped, a.x, a.y, a.z, cfg.speed or 1.15, -1, a.w or 0.0, cfg.stopDistance or 0.55)

    local timeout = GetGameTimer() + (cfg.timeoutMs or 6500)
    local lastDist = dist
    local stuckTicks = 0
    while DoesEntityExist(ped) and GetGameTimer() < timeout do
        Wait(150)
        c = GetEntityCoords(ped)
        dist = #(vector3(c.x, c.y, c.z) - vector3(a.x, a.y, a.z))
        if dist <= (cfg.stopDistance or 0.55) then
            ClearPedTasks(ped)
            SetEntityHeading(ped, a.w or 0.0)
            return true
        end
        if math.abs(dist - lastDist) < 0.03 then
            stuckTicks = stuckTicks + 1
        else
            stuckTicks = 0
        end
        lastDist = dist
        if stuckTicks >= 14 then break end
    end

    if DoesEntityExist(ped) and cfg.snapOnTimeout then
        snapBack(ped, anchor)
    end
    return false
end
RSOBClient.WalkBackToAnchor = walkBackToAnchor

-- start the configured wait behavior on a ped (anim or scenario)
local function startWait(ped, cfg)
    if not ped or not DoesEntityExist(ped) or not cfg then return end
    if cfg.waitAnim and cfg.waitAnim.dict and cfg.waitAnim.dict ~= '' then
        if loadAnim(cfg.waitAnim.dict) then
            FreezeEntityPosition(ped, false)
            TaskPlayAnim(ped, cfg.waitAnim.dict, cfg.waitAnim.anim, 4.0, 4.0, -1, 1, 0.0, false, false, false)
            return
        end
    end
    if cfg.waitScenario and cfg.waitScenario ~= '' then
        FreezeEntityPosition(ped, false)
        TaskStartScenarioInPlace(ped, cfg.waitScenario, 0, true)
        return
    end
    FreezeEntityPosition(ped, true)
end
RSOBClient.StartWait = startWait

-- public idle entry: snap performer to anchor and resume wait behavior
function RSOBClient.PerformerIdle(gameId)
    local b = RSOBClient.entities and RSOBClient.entities[gameId]
    if not b or not b.performer or not DoesEntityExist(b.performer) then return end
    local ped = b.performer
    ClearPedTasks(ped)
    walkBackToAnchor(ped, b.performerAnchor)
    Wait((Config.ReturnToAnchor and Config.ReturnToAnchor.settleBeforeIdleMs) or 200)
    startWait(ped, Config.Performer)
end

function RSOBClient.PlayPerformerOutcome(gameId, outcome)
    local b = RSOBClient.entities and RSOBClient.entities[gameId]
    if not b or not b.performer or not DoesEntityExist(b.performer) then return end
    local ped = b.performer
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
    if outcome.giveWeapon then
        GiveWeaponToPed(ped, joaat(outcome.giveWeapon), 1, false, true)
    end
    local animCfg = Config.Animation or {}
    local duration = math.max(tonumber(outcome.duration) or 2500, tonumber(animCfg.minOutcomeDuration) or 2500)
    if not playTimedAnim(ped, outcome.dict, outcome.anim, duration, outcome.flag or 1) then
        -- fallback so the round never looks like nothing happened
        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_MUSCLE_FLEX', 0, true)
    end
    SetTimeout(duration + (tonumber(animCfg.postOutcomeHoldMs) or 0) + 250, function()
        if not DoesEntityExist(ped) then return end
        if outcome.giveWeapon then RemoveAllPedWeapons(ped, true) end
        RSOBClient.PerformerIdle(gameId)
    end)
end
