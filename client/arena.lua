RSOBClient = RSOBClient or {}

-- streaming distances: spawn arena entities only when player is within range
local STREAM_IN  = 200.0
local STREAM_OUT = 250.0  -- hysteresis to avoid flicker

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 6000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    return hash, HasModelLoaded(hash)
end
RSOBClient.LoadModel = loadModel

local function waitForCollision(x, y, z)
    RequestCollisionAtCoord(x, y, z)
    local timeout = GetGameTimer() + 1500
    while GetGameTimer() < timeout do
        local ok = GetGroundZFor_3dCoord(x, y, z + 25.0, false)
        if ok then return true end
        Wait(50)
    end
    return false
end

local function groundZ(x, y, z)
    for _ = 1, 6 do
        local ok, gz = GetGroundZFor_3dCoord(x, y, z + 25.0, false)
        if ok and gz ~= 0.0 then return gz end
        Wait(30)
    end
    return z
end

local function rotateOffset(base, off)
    local h = math.rad(base.w or 0.0)
    local x = off.x * math.cos(h) - off.y * math.sin(h)
    local y = off.x * math.sin(h) + off.y * math.cos(h)
    return vector4(base.x + x, base.y + y, base.z + (off.z or 0.0), (base.w or 0.0) + (off.w or 0.0))
end
RSOBClient.RotateOffset = rotateOffset

local function spawnProp(model, x, y, z, h)
    local hash, ok = loadModel(model)
    if not ok then return nil end
    local obj = CreateObject(hash, x, y, z, false, false, false)
    SetEntityHeading(obj, h or 0.0)
    SetEntityAsMissionEntity(obj, true, true)
    FreezeEntityPosition(obj, Config.Walls.freeze)
    SetEntityInvincible(obj, Config.Walls.invincible)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

local function spawnCircleWalls(game, bucket)
    local stacks = Config.Walls.stacks[game.wallHeight or 'low'] or 1
    local radius = game.radius or 8.0
    local count = math.max(8, math.ceil((2.0 * math.pi * radius) / Config.Walls.sectionWidth))
    for level = 0, stacks - 1 do
        for i = 1, count do
            local ang = ((i - 1) / count) * math.pi * 2.0
            local x = game.coords.x + math.cos(ang) * radius
            local y = game.coords.y + math.sin(ang) * radius
            local z = groundZ(x, y, game.coords.z) + (level * Config.Walls.sectionHeight)
            local h = math.deg(ang) + (Config.Walls.headingOffset or 90.0)
            local obj = spawnProp(Config.Walls.sectionProp, x, y, z, h)
            if obj then bucket.props[#bucket.props + 1] = obj end
        end
    end
end

local function spawnSquareWalls(game, bucket)
    local stacks = Config.Walls.stacks[game.wallHeight or 'low'] or 1
    local half = (game.size or 16.0) / 2.0
    local step = Config.Walls.sectionWidth
    local base = game.coords
    local points = {}
    for x = -half, half, step do
        points[#points + 1] = { x=x, y=-half, h=0 }
        points[#points + 1] = { x=x, y=half,  h=180 }
    end
    for y = -half, half, step do
        points[#points + 1] = { x=-half, y=y, h=90 }
        points[#points + 1] = { x=half,  y=y, h=270 }
    end
    for level = 0, stacks - 1 do
        for _, p in ipairs(points) do
            local c = rotateOffset(base, vector4(p.x, p.y, level * Config.Walls.sectionHeight, p.h))
            local obj = spawnProp(Config.Walls.sectionProp, c.x, c.y, groundZ(c.x, c.y, c.z), c.w)
            if obj then bucket.props[#bucket.props + 1] = obj end
        end
    end
end

local function spawnPed(model, coords, invincible, blockEvents)
    local hash, ok = loadModel(model)
    if not ok then return nil end
    local z = groundZ(coords.x, coords.y, coords.z)
    local ped = CreatePed(4, hash, coords.x, coords.y, z, coords.w or 0.0, false, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, blockEvents ~= false)
    SetEntityInvincible(ped, invincible == true)
    SetPedCanRagdoll(ped, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(hash)
    return ped
end
RSOBClient.SpawnPed = spawnPed

-- capture a ped's settled spawn position to use as the snap-back anchor
local function captureAnchor(ped, fallback)
    if ped and DoesEntityExist(ped) then
        local c = GetEntityCoords(ped)
        return { x = c.x, y = c.y, z = c.z, w = fallback.w }
    end
    return fallback
end

function RSOBClient.EnsureArena(gameId, game)
    RSOBClient.entities = RSOBClient.entities or {}
    if RSOBClient.entities[gameId] then return end
    waitForCollision(game.coords.x, game.coords.y, game.coords.z)
    local bucket = { props = {}, peds = {} }
    RSOBClient.entities[gameId] = bucket
    if Config.Walls.enabled then
        if game.shape == 'square' then spawnSquareWalls(game, bucket) else spawnCircleWalls(game, bucket) end
    end
    local p = rotateOffset(game.coords, Config.NpcLayout.performer)
    local r = rotateOffset(game.coords, Config.NpcLayout.reactor)
    local e = rotateOffset(game.coords, Config.NpcLayout.cashier)
    bucket.performer = spawnPed(Config.Performer.model, p, Config.Performer.invincible, Config.Performer.blockEvents)
    bucket.reactor   = spawnPed(Config.Reactor.model, r, true, Config.Reactor.blockEvents)
    bucket.cashier    = spawnPed(Config.Cashier.model, e, Config.Cashier.invincible, Config.Cashier.blockEvents)
    -- IMPORTANT: capture anchor AFTER spawn so snap-back uses the real ground Z,
    -- not the config Z. This is what was making them float between rounds.
    bucket.performerAnchor = captureAnchor(bucket.performer, p)
    bucket.reactorAnchor   = captureAnchor(bucket.reactor, r)
    if bucket.cashier and Config.Cashier.scenario then
        TaskStartScenarioInPlace(bucket.cashier, Config.Cashier.scenario, 0, true)
    end
    if RSOBClient.SetupCashierTarget then RSOBClient.SetupCashierTarget(gameId, bucket.cashier) end
    -- kick performer and reactor into their idle wait behavior right away
    if RSOBClient.PerformerIdle then RSOBClient.PerformerIdle(gameId) end
    if RSOBClient.ReactorIdle then RSOBClient.ReactorIdle(gameId) end
end

function RSOBClient.CleanupArena(gameId)
    local b = RSOBClient.entities and RSOBClient.entities[gameId]
    if not b then return end
    for _, obj in ipairs(b.props or {}) do
        if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    for _, key in ipairs({ 'performer', 'reactor', 'cashier' }) do
        if b[key] and DoesEntityExist(b[key]) then DeleteEntity(b[key]) end
    end
    if b.cashier and RSOBClient.RemoveCashierTarget then
        RSOBClient.RemoveCashierTarget(b.cashier)
    end
    RSOBClient.entities[gameId] = nil
end

function RSOBClient.UpdateStreaming(gameId)
    local g = RSOBClient.games and RSOBClient.games[gameId]
    if not g then return end
    local pc = GetEntityCoords(PlayerPedId())
    local d  = #(pc - vector3(g.coords.x, g.coords.y, g.coords.z))
    local has = RSOBClient.entities and RSOBClient.entities[gameId] ~= nil
    if d <= STREAM_IN and not has then
        RSOBClient.EnsureArena(gameId, g)
    elseif d > STREAM_OUT and has then
        RSOBClient.CleanupArena(gameId)
    end
end

CreateThread(function()
    while true do
        Wait(2000)
        if RSOBClient.games then
            for gameId, _ in pairs(RSOBClient.games) do
                RSOBClient.UpdateStreaming(gameId)
            end
        end
    end
end)
