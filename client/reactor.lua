RSOBClient = RSOBClient or {}

-- public idle entry: snap reactor to anchor and resume wait behavior.
-- This is called both at spawn and at the end of every reaction. The settle
-- waits give the engine a couple frames to clear ragdoll/death physics state
-- before we move the ped, which is what caused floating in v2.2.
function RSOBClient.ReactorIdle(gameId)
    local b = RSOBClient.entities and RSOBClient.entities[gameId]
    if not b or not b.reactor or not DoesEntityExist(b.reactor) then return end
    local ped = b.reactor
    -- ensure alive + clean before we move them
    if IsPedDeadOrDying(ped, true) then
        ResurrectPed(ped)
        ClearPedBloodDamage(ped)
        SetEntityHealth(ped, 200)
    end
    ClearPedTasks(ped)
    SetEntityInvincible(ped, true)
    Wait(80)  -- let ragdoll/death physics state release before movement
    if RSOBClient.WalkBackToAnchor then
        RSOBClient.WalkBackToAnchor(ped, b.reactorAnchor)
    elseif RSOBClient.SnapBack then
        RSOBClient.SnapBack(ped, b.reactorAnchor)
    end
    Wait((Config.ReturnToAnchor and Config.ReturnToAnchor.settleBeforeIdleMs) or 200)
    if RSOBClient.StartWait then RSOBClient.StartWait(ped, Config.Reactor) end
end

function RSOBClient.PlayReaction(gameId, reaction)
    local b = RSOBClient.entities and RSOBClient.entities[gameId]
    if not b or not b.reactor or not DoesEntityExist(b.reactor) then return end
    local ped = b.reactor
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
    local effect = reaction and reaction.effect or 'none'

    if effect == 'ragdoll' then
        SetEntityInvincible(ped, false)
        SetPedToRagdoll(ped, reaction.ragdollMs or 1500, reaction.ragdollMs or 1500, 0, false, false, false)
    elseif effect == 'kill_temp' then
        SetEntityInvincible(ped, false)
        SetEntityHealth(ped, 0)
        SetTimeout(reaction.resetMs or 3500, function()
            if DoesEntityExist(ped) then
                ResurrectPed(ped)
                ClearPedBloodDamage(ped)
                SetEntityHealth(ped, 200)
                SetEntityInvincible(ped, true)
            end
        end)
    end

    local animCfg = Config.Animation or {}
    local duration = math.max(tonumber(reaction and reaction.duration) or 2500, tonumber(animCfg.minReactionDuration) or 2500)
    if effect == 'none' and reaction and reaction.dict and reaction.dict ~= '' then
        if RSOBClient.PlayTimedAnim then
            if not RSOBClient.PlayTimedAnim(ped, reaction.dict, reaction.anim, duration, reaction.flag or 1) then
                TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_SMOKING', 0, true)
            end
        elseif RSOBClient.LoadAnim and RSOBClient.LoadAnim(reaction.dict) then
            TaskPlayAnim(ped, reaction.dict, reaction.anim, 4.0, -4.0, duration, 1, 0.0, false, false, false)
        end
    end

    SetTimeout(duration + (tonumber(animCfg.postOutcomeHoldMs) or 0) + 350, function()
        if not DoesEntityExist(ped) then return end
        RSOBClient.ReactorIdle(gameId)
    end)
end
