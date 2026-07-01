RSOBClient = RSOBClient or {}

local function loadModel(model)
    if RSOBClient.LoadModel then return RSOBClient.LoadModel(model) end
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    return hash, HasModelLoaded(hash)
end

local function pick(list, fallback)
    if not list or #list == 0 then return fallback end
    return list[math.random(1, #list)]
end

local function randomFloat(min, max)
    return min + ((max - min) * math.random())
end

local function spawnCrowdRing(game, bucket, crowd, ring, ringIndex)
    local count = tonumber(ring.count or crowd.count) or 0
    if count <= 0 then return end

    local arenaRadius = tonumber(game.radius) or 8.0
    local radiusExtra = tonumber(ring.radiusExtra or crowd.radiusExtra) or 2.4
    local positionJitter = tonumber(ring.positionJitter or crowd.positionJitter) or 0.35
    local angleJitter = tonumber(ring.angleJitter or crowd.angleJitter) or 0.08
    local headingJitter = tonumber(ring.headingJitter or crowd.headingJitter) or 10.0
    local minOutsideBuffer = tonumber(crowd.minOutsideBuffer) or 1.0
    local angleOffset = tonumber(ring.angleOffset)

    if not angleOffset then
        angleOffset = (ringIndex - 1) * (math.pi / math.max(count, 1))
    end

    for i = 1, count do
        local ang = (((i - 1) / math.max(count, 1)) * math.pi * 2.0) + angleOffset + randomFloat(-angleJitter, angleJitter)
        local radius = math.max(arenaRadius + minOutsideBuffer, arenaRadius + radiusExtra + randomFloat(-positionJitter, positionJitter))
        local x = game.coords.x + math.cos(ang) * radius
        local y = game.coords.y + math.sin(ang) * radius
        local ok, z = GetGroundZFor_3dCoord(x, y, (game.coords.z or 30.0) + 10.0, false)
        z = ok and z or game.coords.z
        local heading = (math.deg(ang) + 180.0 + randomFloat(-headingJitter, headingJitter)) % 360.0
        local model = pick(ring.models or crowd.models, 'a_m_y_stwhi_01')
        local hash, loaded = loadModel(model)
        if loaded then
            local ped = CreatePed(4, hash, x, y, z, heading, false, false)
            SetEntityAsMissionEntity(ped, true, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityInvincible(ped, true)
            SetPedCanRagdoll(ped, false)
            FreezeEntityPosition(ped, true)
            local scenario = pick(ring.scenarios or crowd.scenarios, 'WORLD_HUMAN_CHEERING')
            if scenario and scenario ~= '' then TaskStartScenarioInPlace(ped, scenario, 0, true) end
            bucket.crowd[#bucket.crowd+1] = ped
            SetModelAsNoLongerNeeded(hash)
        end
    end
end

local function spawnCrowdForGame(gameId, game, bucket)
    if not Config.Atmosphere or not Config.Atmosphere.enabled then return end
    local crowd = Config.Atmosphere.crowd or {}
    if not crowd.enabled then return end

    bucket.crowd = bucket.crowd or {}

    if crowd.rings and #crowd.rings > 0 then
        for ringIndex, ring in ipairs(crowd.rings) do
            spawnCrowdRing(game, bucket, crowd, ring, ringIndex)
        end
    else
        spawnCrowdRing(game, bucket, crowd, crowd, 1)
    end
end

-- Hook into arena spawning without touching arena.lua logic.
CreateThread(function()
    while not RSOBClient.EnsureArena do Wait(100) end
    local originalEnsure = RSOBClient.EnsureArena
    RSOBClient.EnsureArena = function(gameId, game)
        originalEnsure(gameId, game)
        local bucket = RSOBClient.entities and RSOBClient.entities[gameId]
        if bucket and not bucket._atmosphereReady then
            bucket._atmosphereReady = true
            spawnCrowdForGame(gameId, game, bucket)
        end
    end

    while not RSOBClient.CleanupArena do Wait(100) end
    local originalCleanup = RSOBClient.CleanupArena
    RSOBClient.CleanupArena = function(gameId)
        local bucket = RSOBClient.entities and RSOBClient.entities[gameId]
        if bucket and bucket.crowd then
            for _, ped in ipairs(bucket.crowd) do
                if ped and DoesEntityExist(ped) then DeleteEntity(ped) end
            end
            bucket.crowd = nil
        end
        originalCleanup(gameId)
    end
end)

function RSOBClient.AtmosphereHype(gameId, bucketName)
    if not Config.Atmosphere or not Config.Atmosphere.enabled then return end
    local fs = Config.Atmosphere.frontendSounds or {}
    if fs.enabled then
        local sound = nil
        if bucketName == 'open' then sound = fs.onOpen end
        if bucketName == 'locked' or bucketName == 'execute' then sound = fs.onLocked end
        if bucketName == 'payout' or bucketName == 'rare' then sound = fs.onPayout end
        if sound then PlaySoundFrontend(-1, sound, 'HUD_MINI_GAME_SOUNDSET', true) end
    end
    local b = RSOBClient.entities and RSOBClient.entities[gameId]
    if b and b.crowd then
        for _, ped in ipairs(b.crowd) do
            if ped and DoesEntityExist(ped) and math.random(1, 100) <= 45 then
                ClearPedTasks(ped)
                TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CHEERING', 0, true)
            end
        end
    end
end

-- Local red arena light pulse. This is visual-only and safe if disabled.
CreateThread(function()
    while true do
        local wait = 750
        if Config.Atmosphere and Config.Atmosphere.enabled and Config.Atmosphere.lights and Config.Atmosphere.lights.enabled and RSOBClient.games then
            for gameId, g in pairs(RSOBClient.games) do
                if RSOBClient.entities and RSOBClient.entities[gameId] then
                    wait = 0
                    local l = Config.Atmosphere.lights
                    local color = l.color or {180,20,20}
                    DrawLightWithRange(g.coords.x, g.coords.y, g.coords.z + (l.height or 5.0), color[1], color[2], color[3], l.range or 13.0, l.intensity or 2.0)
                end
            end
        end
        Wait(wait)
    end
end)
