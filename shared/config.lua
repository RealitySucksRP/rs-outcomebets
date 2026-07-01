Config = {}

Config.Debug = false
Config.Framework = 'qbcore' -- auto, qbcore, qbox, standalone
Config.Currency = 'cash' -- hard-locked default for rs-outcomebets cash flow

Config.Commands = {
    open      = 'betmenu',
    hostStart = 'betstart',
    forceEnd  = 'betend',
    cancel    = 'betcancel',
    force     = 'betforce' -- dev/test: /betforce roundId outcomeId
}

Config.AdminOnlyHost = false
Config.AdminAce = 'rs-outcomebets.host'

Config.MinBet = 100
Config.MaxBet = 50000
Config.DefaultBet = 500

-- BETTING / CASH FLOW
-- HostCanBet lets the server owner/admin who started the show test and play like everyone else.
-- The host is no longer treated as the money house; the NPC/bank cashier is the house.
Config.Betting = {
    hostCanBet = true,
    account = 'cash',              -- keep this cash unless you intentionally want bank betting
    oneBetPerRound = true,
    disconnectForfeitsRoundBet = true,
    strictCashFlow = true,         -- server removes stake first, pays only from locked round results
    highRollerNotifyAt = 10000
}

-- Virtual NPC/house opponent for low-pop servers.
-- This seeds money onto outcomes real players did NOT pick, so a solo player
-- can still win profit instead of only getting their own stake back.
-- Turn this off once the server has enough real bettors.
Config.NpcOpponent = {
    enabled = true,
    label = 'NPC House',
    activeWhenRealBettorsBelow = 3, -- disables automatically at this many real bettors; set high to keep it active longer
    stakeMultiplier = 1.0,          -- NPC total stake = real player pool * multiplier
    minStake = 250,
    maxTotalStake = 15000,
    maxPerOutcome = 5000,
    showInUi = true,
    notifyOnSeed = true
}

Config.VIP = {
    enabled = true,
    highRollerAmount = 10000,
    hypeHighRollers = true
}

Config.DynamicOdds = {
    enabled = true,
    showPoolShare = true,
    showPotentialPayout = true
}


Config.Lifecycle = {
    mode = 'both', -- manual, autoloop, both
    autoLoop = {
        enabled = false,
        arenaId = 'la_underground',
        cooldownBetweenShows = 300,
        runOnResourceStart = false
    }
}

Config.Show = {
    roundsPerShow = 10,
    bettingSeconds = 30,
    warnAt = { 10, 5 },
    countdownSeconds = 8,
    interRoundDelay = 5,
    paidOutDelay = 6,
    cooldownBetweenShows = 300,
    promptTemplate = 'Round %d / %d -- pick the outcome',
    -- when roundsPerShow > number of entries in Config.Rounds:
    --   'cycle'  : round N reuses Config.Rounds[((N-1) % count) + 1] (wrap around)
    --   'random' : round N picks any configured round at random
    --   'end'    : show ends at the last explicitly configured round (old behavior)
    fillMissingRounds = 'end'
}

-- Animation playback tuning. Increase these if outcomes feel too fast.
Config.Animation = {
    minOutcomeDuration = 9000,      -- performer animation will hold/repeat at least this long
    minReactionDuration = 6500,     -- reactor reaction will hold/repeat at least this long
    postOutcomeHoldMs = 5500,       -- keeps scene alive through the payout/cooldown beat
    replayOneShots = true           -- replays short one-shot clips so they do not look like nothing happened
}


-- Branch randomizer. Each round can pull a fresh set of outcomes from a branch.
-- This keeps the 10-round show from feeling like the same 3 choices every time.
Config.Randomizer = {
    enabled = true,
    pickCount = 5,              -- how many outcomes appear in the betting UI each round
    noRepeatWindow = 14,        -- avoid showing the same outcome again for this many offered slots
    noRepeatWinners = 6,        -- heavily reduce the chance the same winner repeats soon
    repeatWeightPenalty = 0.05  -- repeated winners keep 5% of their normal weight
}

Config.Arenas = {
    {
        id = 'la_underground',
        label = 'LA Underground',
        coords = vector4(170.15, -990.21, 30.09, 160.0),
        shape = 'circle',
        radius = 8.0,
        size = 16.0,
        wallHeight = 'mid'
    }
}

Config.Hostable = {
    enabled = true,
    shape = 'circle',
    radius = 7.0,
    size = 14.0,
    wallHeight = 'low',
    autoTeardownOnEnd = true
}

Config.Walls = {
    enabled = true,
    sectionProp = 'prop_fnclink_03a',
    sectionWidth = 4.0,
    sectionHeight = 2.5,
    stacks = { low = 1, mid = 2, tall = 3 },
    invincible = true,
    freeze = true,
    headingOffset = 90.0
}

-- Tighter spacing: performer and reactor 1.7m apart (was 2.8m, 40% closer).
-- Cashier stays at -5.2 so the host bank stays separate from the action.
Config.NpcLayout = {
    performer = vector4(0.0, -0.85, 0.0, 0.0),
    reactor   = vector4(0.0,  0.85, 0.0, 180.0),
    cashier    = vector4(0.0, -5.2,  0.0, 0.0)
}

-- NPC waiting behavior (between rounds and during betting).
-- waitAnim takes priority if both are set. Leave waitAnim = nil to use waitScenario.
-- Empty/nil waitScenario means the ped just freezes (no idle motion).
--
-- Good scenario picks for the fight-club vibe:
--   Performer (cocky fighter): WORLD_HUMAN_MUSCLE_FLEX, WORLD_HUMAN_PUSH_UPS,
--                              WORLD_HUMAN_JOG_STANDING, WORLD_HUMAN_HANG_OUT_STREET
--   Reactor (bystander):       WORLD_HUMAN_SMOKING, WORLD_HUMAN_DRINKING,
--                              WORLD_HUMAN_STAND_MOBILE, WORLD_HUMAN_HANG_OUT_STREET
Config.Performer = {
    model = 'a_m_y_musclbeac_01',
    invincible = true,
    blockEvents = true,
    waitScenario = 'WORLD_HUMAN_MUSCLE_FLEX',
    waitAnim = nil
    -- example custom loop instead of scenario:
    -- waitAnim = { dict = 'rcmnigel1c', anim = 'fight_idle_a' }
}

Config.Reactor = {
    model = 'a_m_y_stwhi_02',
    invincible = false,
    blockEvents = true,
    waitScenario = 'WORLD_HUMAN_SMOKING',
    waitAnim = nil
}

Config.Cashier = {
    model = 's_m_m_highsec_01',
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    invincible = true,
    target = { label = 'Place a Bet', icon = 'fa-solid fa-money-bill', distance = 2.5 }
}


-- Smooth return-to-position after outcomes.
-- Normal cleanup makes NPCs walk back to their anchor instead of popping back.
-- Hard snap is kept only as a safety fallback if they are too far away, stuck, dead,
-- or the walk times out. This keeps big stumble/ragdoll outcomes from looking glitchy.
Config.ReturnToAnchor = {
    enabled = true,
    speed = 1.15,
    stopDistance = 0.55,
    timeoutMs = 6500,
    snapIfFartherThan = 8.0,
    snapOnTimeout = true,
    settleBeforeIdleMs = 200
}

Config.PerformerMarker = {
    enabled = true,
    markerType = 6,
    rgba = { 200, 0, 0, 200 },
    size = { 0.6, 0.6, 0.4 },
    heightOffset = 1.45,
    bob = { enabled = true, amplitude = 0.1, speed = 1.5 },
    text = {
        enabled = true,
        content = 'BET ON ME',
        font = 4,
        scale = 0.45,
        rgba = { 239, 231, 218, 255 },
        heightOffset = 1.08
    }
}

Config.AntiLeave = {
    enabled = true,
    armOnFirstBet = true,
    graceSeconds = 12,
    forfeit = 'current_round', -- current_round or all_show
    countdownNuiOverlay = true,
    notifyOnReturn = true
}

Config.Hype = {
    enabled = true,
    cooldownMs = 1800,
    lines = {
        setup = { 'Bank is walking in. Keep it clean.', 'The cage is live. Cash only.' },
        open = { 'Bets are open. Pick the outcome!', 'Put money down or move back.' },
        warning = { 'Last call. Bets close soon!', 'No crying after the lock!' },
        locked = { 'Bets locked. Eyes on the cage!', 'Too late now. Watch it play out.' },
        payout = { 'Winners step up. Bank is paying.', 'Losers paid for the lesson.' },
        endshow = { 'Show is over. Cage is cold.' }
    }
}

Config.Sounds = {
    enabled = false,
    audibleRadius = 25.0,
    volume = 0.65,
    files = {
        open = {}, warning = {}, locked = {}, payout = {}
    }
}


-- ARENA ATMOSPHERE
-- Uses local client-only peds/lights/frontend sounds so it adds vibe without touching cash logic.
Config.Atmosphere = {
    enabled = true,
    crowd = {
        enabled = true,
        count = 18,                -- fallback count if rings below are removed/empty
        radiusExtra = 2.8,
        minOutsideBuffer = 1.0,    -- keeps atmosphere peds outside the cage radius
        positionJitter = 0.45,
        angleJitter = 0.10,
        headingJitter = 14.0,
        rings = {
            { count = 14, radiusExtra = 2.5 },
            { count = 8,  radiusExtra = 4.4 }
        },
        models = {
            'a_m_y_stwhi_01', 'a_m_y_stwhi_02', 'a_m_y_musclbeac_01', 'a_m_y_musclbeac_02',
            'a_m_m_skater_01', 'a_m_y_skater_01', 'a_m_y_skater_02', 'a_m_y_beach_01',
            'a_m_y_soucent_01', 'a_m_y_soucent_02', 'a_m_m_bevhills_02', 'a_m_m_tramp_01',
            'a_f_y_hipster_01', 'a_f_y_hipster_02', 'a_f_y_tourist_01', 'a_f_y_soucent_01',
            'g_m_y_ballaorig_01', 'g_m_y_famca_01', 'g_m_y_lost_01', 's_m_y_dealer_01'
        },
        scenarios = {
            'WORLD_HUMAN_CHEERING',
            'WORLD_HUMAN_HANG_OUT_STREET',
            'WORLD_HUMAN_SMOKING',
            'WORLD_HUMAN_DRINKING',
            'WORLD_HUMAN_STAND_MOBILE',
            'WORLD_HUMAN_MOBILE_FILM_SHOCKING',
            'WORLD_HUMAN_GUARD_STAND'
        }
    },
    lights = {
        enabled = true,
        range = 13.0,
        intensity = 2.2,
        height = 5.0,
        color = { 180, 20, 20 }
    },
    frontendSounds = {
        enabled = true,
        onOpen = 'CHECKPOINT_NORMAL',
        onLocked = 'CHECKPOINT_MISSED',
        onPayout = 'CHECKPOINT_PERFECT'
    }
}

Config.RareMoments = {
    enabled = true,
    chance = 8, -- percent chance to play extra atmosphere hype on a resolved outcome
    lines = {
        'RARE MOMENT! The cage just turned ugly.',
        'The crowd is losing it!',
        'That one is going in the highlight reel.'
    }
}

-- Reusable reactor reactions. Outcomes can set reactionPool = 'punch' or
-- reactionPool = { 'punch', 'generic' } to keep the cage from repeating.
Config.ReactionPools = {
    humiliation = {
        { weight=30, dict='misscarsteal2car_stolen', anim='chad_car_stolen_reaction', effect='none', duration=7200, voiceType='humiliation',
          sounds={ 'trash_look_this_guy.ogg', 'trash_he_soft.ogg', 'trash_embarrassing.ogg' } },
        { weight=30, dict='reaction@male_stand@big_variations@b', anim='react_big_variations_f', effect='none', duration=7000, voiceType='humiliation',
          sounds={ 'trash_look_this_guy.ogg', 'trash_you_aint_nobody.ogg' } },
        { weight=20, dict='mini@golfreactions@generic@', anim='swing_react_bad_02', effect='none', duration=6800, voiceType='humiliation',
          sounds={ 'trash_he_soft.ogg', 'trash_embarrassing.ogg' } },
        { weight=20, dict='reaction@male_stand@small_variations@idle_c', anim='react_small_variations_l', effect='none', duration=6800, voiceType='humiliation',
          sounds={ 'trash_talk_back.ogg', 'trash_look_this_guy.ogg' } }
    },
    intimidated = {
        { weight=30, dict='amb@code_human_cower@female@react_cowering', anim='base_back_left', effect='none', duration=7600, voiceType='chaos',
          sounds={ 'panic_nope_out.ogg', 'panic_get_me_out.ogg' } },
        { weight=30, dict='reaction@male_stand@big_variations@idle_b', anim='react_big_variations_j', effect='none', duration=7200, voiceType='hit',
          sounds={ 'trash_hit_harder.ogg', 'trash_you_aint_nobody.ogg' } },
        { weight=25, dict='anim@heists@ornate_bank@chat_manager', anim='average_clothes', effect='none', duration=7200, voiceType='humiliation',
          sounds={ 'trash_look_this_guy.ogg', 'trash_he_soft.ogg' } },
        { weight=15, dict='', anim='', effect='ragdoll', ragdollMs=1100, duration=6500, voiceType='chaos',
          sounds={ 'pain_oof_1.ogg', 'panic_nope_out.ogg' } }
    },
    punch = {
        { weight=34, dict='missprologueig_3@react_to_explosion', anim='react_to_explosion_brad', effect='none', duration=7600, voiceType='hit',
          sounds={ 'pain_oof_1.ogg', 'trash_hit_harder.ogg' } },
        { weight=34, dict='combat@combat_reactions_2handed', anim='2handed_react_clean_90', effect='none', duration=7000, voiceType='hit',
          sounds={ 'pain_felt_that.ogg', 'trash_he_soft.ogg' } },
        { weight=20, dict='', anim='', effect='ragdoll', ragdollMs=1700, duration=6800, voiceType='hit',
          sounds={ 'pain_oof_2.ogg', 'trash_hit_harder.ogg' } },
        { weight=12, dict='mini@golfreactions@trevor@putter', anim='react_lose_putter_03_trevor', effect='none', duration=7000, voiceType='humiliation',
          sounds={ 'trash_look_this_guy.ogg', 'trash_embarrassing.ogg' } }
    },
    generic = {
        { weight=25, dict='mini@golfreactions@generic@', anim='swing_react_bad_02', effect='none', duration=6800, voiceType='generic',
          sounds={ 'trash_look_this_guy.ogg', 'react_what_was_that.ogg' } },
        { weight=25, dict='mini@golfreactions@generic@', anim='putt_react_bad_03', effect='none', duration=6800, voiceType='generic',
          sounds={ 'trash_he_soft.ogg', 'react_what_was_that.ogg' } },
        { weight=25, dict='reaction@male_stand@small_variations@idle_c', anim='react_small_variations_l', effect='none', duration=6800, voiceType='generic',
          sounds={ 'trash_talk_back.ogg', 'trash_you_aint_nobody.ogg' } },
        { weight=25, dict='mini@golfreactions@trevor@putter', anim='react_lose_putter_03_trevor', effect='none', duration=7000, voiceType='humiliation',
          sounds={ 'trash_embarrassing.ogg', 'trash_look_this_guy.ogg' } }
    },
    chaos = {
        { weight=30, dict='missprologueig_3@react_to_explosion', anim='react_to_explosion_brad', effect='none', duration=7600, voiceType='chaos',
          sounds={ 'pain_explosion.ogg', 'panic_get_me_out.ogg' } },
        { weight=25, dict='amb@code_human_cower@female@react_cowering', anim='base_back_left', effect='none', duration=7600, voiceType='chaos',
          sounds={ 'panic_nope_out.ogg', 'panic_get_me_out.ogg' } },
        { weight=25, dict='', anim='', effect='ragdoll', ragdollMs=1900, duration=7000, voiceType='chaos',
          sounds={ 'pain_oof_2.ogg', 'pain_explosion.ogg' } },
        { weight=20, dict='reaction@male_stand@big_variations@idle_b', anim='react_big_variations_j', effect='none', duration=7200, voiceType='chaos',
          sounds={ 'panic_nope_out.ogg', 'react_what_was_that.ogg' } }
    }
}

Config.Text = {
    showStarting = 'A betting show is starting. Get to the cage.',
    bettingOpen = 'ROUND %d -- bets open for %ds',
    bettingWarn = '%ds left to bet on Round %d',
    bettingLocked = 'Bets locked. Watch the outcome.',
    roundResolved = 'Round %d -- winner: %s',
    showEnded = 'Show over. Cooldown %ds.',
    leaveWarning = 'You left the cage. %ds to return or your round bet is gone.',
    leaveForfeit = 'You bailed. Round bet forfeited.',
    cancelled = 'Show cancelled. Bets refunded.'
}

Config.OutcomeBranches = {
    combat = {
        label = 'Street Fight',
        outcomes = {
            { id='shadow_boxing', label='SHADOW BOXING', weight=18, dict='anim@mp_player_intcelebrationmale@shadow_boxing', anim='shadow_boxing', duration=10000,
              reactions={
                  { weight=45, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7000 },
                  { weight=35, dict='random@car_thief@agitated@idle_a', anim='agitated_idle_a', effect='none', duration=7000 },
                  { weight=20, dict='', anim='', effect='ragdoll', ragdollMs=1200, duration=6500 }
              }
            },
            { id='karate_chops', label='KARATE CHOPS', weight=15, dict='anim@mp_player_intcelebrationmale@karate_chops', anim='karate_chops', duration=9500,
              reactions={
                  { weight=50, dict='misscommon@response', anim='bring_it_on', effect='none', duration=7000 },
                  { weight=30, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 },
                  { weight=20, dict='', anim='', effect='ragdoll', ragdollMs=1300, duration=6500 }
              }
            },
            { id='knuckle_crunch', label='KNUCKLE CRUNCH', weight=14, dict='anim@mp_player_intcelebrationfemale@knuckle_crunch', anim='knuckle_crunch', duration=9500,
              reactions={
                  { weight=45, dict='random@arrests@busted', anim='idle_a', effect='none', duration=7000 },
                  { weight=35, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 },
                  { weight=20, dict='gestures@m@standing@casual', anim='gesture_damn', effect='none', duration=6500 }
              }
            },
            { id='fight_me_c', label='FIGHT ME', weight=16, dict='anim@deathmatch_intros@unarmed', anim='intro_male_unarmed_c', duration=10000,
              reactions={
                  { weight=45, dict='anim@deathmatch_intros@unarmed', anim='intro_male_unarmed_e', effect='none', duration=7000 },
                  { weight=35, dict='misscommon@response', anim='bring_it_on', effect='none', duration=7000 },
                  { weight=20, dict='', anim='', effect='ragdoll', ragdollMs=1100, duration=6500 }
              }
            },
            { id='fight_me_e', label='FIGHT ME 2', weight=14, dict='anim@deathmatch_intros@unarmed', anim='intro_male_unarmed_e', duration=10000,
              reactions={
                  { weight=50, dict='random@car_thief@agitated@idle_a', anim='agitated_idle_a', effect='none', duration=7000 },
                  { weight=30, dict='anim@mp_player_intuppersalute', anim='idle_a', effect='none', duration=6500 },
                  { weight=20, dict='', anim='', effect='ragdoll', ragdollMs=1250, duration=6500 }
              }
            },
            { id='lefthook', label='LEFT HOOK', weight=13, dict='melee@unarmed@streamed_variations', anim='plyr_takedown_rear_lefthook', duration=9000,
              reactions={
                  { weight=60, dict='melee@unarmed@streamed_variations', anim='victim_takedown_front_cross_r', effect='none', duration=6500 },
                  { weight=40, dict='', anim='', effect='ragdoll', ragdollMs=1800, duration=6500 }
              }
            },
            { id='front_slap', label='FRONT SLAP', weight=13, dict='melee@unarmed@streamed_variations', anim='plyr_takedown_front_slap', duration=9000,
              reactions={
                  { weight=60, dict='melee@unarmed@streamed_variations', anim='victim_takedown_front_slap', effect='none', duration=6500 },
                  { weight=40, dict='', anim='', effect='ragdoll', ragdollMs=1500, duration=6500 }
              }
            },
            { id='back_slap', label='BACKHAND SLAP', weight=12, dict='melee@unarmed@streamed_variations', anim='plyr_takedown_front_backslap', duration=9000,
              reactions={
                  { weight=60, dict='melee@unarmed@streamed_variations', anim='victim_takedown_front_backslap', effect='none', duration=6500 },
                  { weight=40, dict='', anim='', effect='ragdoll', ragdollMs=1600, duration=6500 }
              }
            },
            { id='punch_loop', label='PUNCHING BAG', weight=16, dict='rcmextreme2', anim='loop_punching', duration=10500,
              reactions={
                  { weight=45, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7000 },
                  { weight=35, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 },
                  { weight=20, dict='move_m@drunk@verydrunk', anim='idle', effect='none', duration=7000 }
              }
            },
            { id='golfer_punch', label='GOLFER PUNCH', weight=10, dict='anim@scripted@bty2@ig2_beat_target@male@', anim='standing_punch_v1_golfer', duration=9500,
              reactions={
                  { weight=55, dict='', anim='', effect='ragdoll', ragdollMs=1700, duration=6500 },
                  { weight=45, dict='random@arrests', anim='kneeling_arrest_get_up', effect='none', duration=7000 }
              }
            }
        }
    },

    taunt = {
        label = 'Disrespect',
        outcomes = {
            { id='bring_it_on', label='BRING IT ON', weight=18, dict='misscommon@response', anim='bring_it_on', duration=9500,
              reactions={
                  { weight=40, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 },
                  { weight=35, dict='random@car_thief@agitated@idle_a', anim='agitated_idle_a', effect='none', duration=7000 },
                  { weight=25, dict='', anim='', effect='ragdoll', ragdollMs=1200, duration=6500 }
              }
            },
            { id='middle_finger_selfie', label='BIRD FLIP', weight=16, dict='anim@mp_player_intselfiethe_bird', anim='idle_a', duration=10000,
              reactions={
                  { weight=45, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 },
                  { weight=35, dict='gestures@m@standing@casual', anim='gesture_damn', effect='none', duration=6500 },
                  { weight=20, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 }
              }
            },
            { id='upper_finger', label='UPPER FINGER', weight=14, dict='anim@mp_player_intupperfinger', anim='idle_a_fp', duration=10000,
              reactions={
                  { weight=45, dict='random@car_thief@agitated@idle_a', anim='agitated_idle_a', effect='none', duration=7000 },
                  { weight=35, dict='misscommon@response', anim='bring_it_on', effect='none', duration=7000 },
                  { weight=20, dict='', anim='', effect='ragdoll', ragdollMs=900, duration=6500 }
              }
            },
            { id='angry_argue_1', label='ANGRY ARGUE', weight=18, dict='anim@amb@casino@brawl@fights@argue@', anim='arguement_loop_mp_m_brawler_01', duration=10500,
              reactions={
                  { weight=40, dict='anim@amb@casino@brawl@fights@argue@', anim='arguement_loop_mp_m_brawler_02', effect='none', duration=7500 },
                  { weight=35, dict='random@arrests@busted', anim='idle_a', effect='none', duration=7000 },
                  { weight=25, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 }
              }
            },
            { id='angry_argue_2', label='BRAWL ARGUE', weight=16, dict='anim@amb@casino@brawl@fights@argue@', anim='arguement_loop_mp_m_brawler_02', duration=10500,
              reactions={
                  { weight=45, dict='anim@amb@casino@brawl@fights@argue@', anim='arguement_loop_mp_m_brawler_01', effect='none', duration=7500 },
                  { weight=35, dict='gestures@m@standing@casual', anim='gesture_damn', effect='none', duration=6500 },
                  { weight=20, dict='', anim='', effect='ragdoll', ragdollMs=1000, duration=6500 }
              }
            },
            { id='face_palm_roast', label='FACEPALM ROAST', weight=14, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', duration=9500,
              reactions={
                  { weight=45, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 },
                  { weight=35, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=20, dict='random@arrests@busted', anim='idle_a', effect='none', duration=7000 }
              }
            },
            { id='thumbs_up_troll', label='THUMBS-UP TROLL', weight=12, dict='anim@mp_player_intupperthumbs_up', anim='idle_a', duration=9500,
              reactions={
                  { weight=45, dict='random@car_thief@agitated@idle_a', anim='agitated_idle_a', effect='none', duration=7000 },
                  { weight=35, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 },
                  { weight=20, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7000 }
              }
            },
            { id='peace_sign_troll', label='PEACE SIGN', weight=12, dict='mp_player_int_upperpeace_sign', anim='mp_player_int_peace_sign', duration=9500,
              reactions={
                  { weight=40, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=35, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 },
                  { weight=25, dict='gestures@m@standing@casual', anim='gesture_damn', effect='none', duration=6500 }
              }
            }
        }
    },

    showboat = {
        label = 'Showboat',
        outcomes = {
            { id='dance_high_center_down', label='DANCE LOW', weight=15, dict='anim@amb@nightclub@mini@dance@dance_solo@male@var_b@', anim='high_center_down', duration=11000,
              reactions={
                  { weight=55, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=30, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=15, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 }
              }
            },
            { id='dance_high_center', label='DANCE HIGH', weight=15, dict='anim@amb@nightclub@mini@dance@dance_solo@male@var_a@', anim='high_center', duration=11000,
              reactions={
                  { weight=50, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=30, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=20, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 }
              }
            },
            { id='dance_high_center_up', label='DANCE UP', weight=15, dict='anim@amb@nightclub@mini@dance@dance_solo@male@var_b@', anim='high_center_up', duration=11000,
              reactions={
                  { weight=55, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=30, dict='random@car_thief@agitated@idle_a', anim='agitated_idle_a', effect='none', duration=7000 },
                  { weight=15, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 }
              }
            },
            { id='tao_dance_cs', label='TAO DANCE', weight=14, dict='misschinese2_crystalmazemcs1_cs', anim='dance_loop_tao', duration=11000,
              reactions={
                  { weight=50, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=35, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=15, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 }
              }
            },
            { id='fbi_dance', label='FBI DANCE', weight=13, dict='missfbi3_sniping', anim='dance_m_default', duration=11000,
              reactions={
                  { weight=45, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=35, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 },
                  { weight=20, dict='random@car_thief@agitated@idle_a', anim='agitated_idle_a', effect='none', duration=7000 }
              }
            },
            { id='air_guitar', label='AIR GUITAR', weight=14, dict='anim@mp_player_intcelebrationfemale@air_guitar', anim='air_guitar', duration=10000,
              reactions={
                  { weight=50, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=30, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=20, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 }
              }
            },
            { id='jazz_hands', label='JAZZ HANDS', weight=14, dict='anim@mp_player_intcelebrationfemale@jazz_hands', anim='jazz_hands', duration=10000,
              reactions={
                  { weight=45, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=35, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 },
                  { weight=20, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 }
              }
            },
            { id='bow_regal', label='BOW', weight=13, dict='anim@arena@celeb@podium@no_prop@', anim='regal_c_1st', duration=9500,
              reactions={
                  { weight=55, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=30, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=15, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 }
              }
            },
            { id='salute_upper', label='SALUTE', weight=12, dict='anim@mp_player_intuppersalute', anim='idle_a', duration=9500,
              reactions={
                  { weight=45, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=35, dict='random@arrests@busted', anim='idle_a', effect='none', duration=7000 },
                  { weight=20, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 }
              }
            }
        }
    },

    chaos = {
        label = 'Chaos',
        outcomes = {
            { id='mind_blown', label='MIND BLOWN', weight=14, dict='anim@mp_player_intcelebrationmale@mind_blown', anim='mind_blown', duration=10000,
              reactions={
                  { weight=40, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 },
                  { weight=35, dict='random@arrests@busted', anim='idle_a', effect='none', duration=7000 },
                  { weight=25, dict='', anim='', effect='ragdoll', ragdollMs=1300, duration=6500 }
              }
            },
            { id='mind_control', label='MIND CONTROL', weight=14, dict='rcmbarry', anim='mind_control_b_loop', duration=11000,
              reactions={
                  { weight=40, dict='rcmbarry', anim='bar_1_attack_idle_aln', effect='none', duration=7500 },
                  { weight=35, dict='misscommon@response', anim='bring_it_on', effect='none', duration=7000 },
                  { weight=25, dict='', anim='', effect='ragdoll', ragdollMs=1600, duration=6500 }
              }
            },
            { id='superhero_pose', label='SUPERHERO POSE', weight=14, dict='rcmbarry', anim='base', duration=11000,
              reactions={
                  { weight=45, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=35, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=20, dict='random@arrests@busted', anim='idle_a', effect='none', duration=7000 }
              }
            },
            { id='stumble', label='STUMBLE', weight=15, dict='misscarsteal4@actor', anim='stumble', duration=10000,
              reactions={
                  { weight=45, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 },
                  { weight=35, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=20, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 }
              }
            },
            { id='fall_over', label='FALL OVER', weight=12, dict='random@drunk_driver_1', anim='drunk_fall_over', duration=9500,
              reactions={
                  { weight=45, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=35, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=20, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 }
              }
            },
            { id='crawl', label='CRAWL OUT', weight=11, dict='move_injured_ground', anim='front_loop', duration=10000,
              reactions={
                  { weight=45, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=35, dict='random@arrests', anim='generic_idle', effect='none', duration=7000 },
                  { weight=20, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 }
              }
            },
            { id='passout_loop', label='PASS OUT', weight=10, dict='missarmenian2', anim='drunk_loop', duration=10000,
              reactions={
                  { weight=45, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=35, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 },
                  { weight=20, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 }
              }
            },
            { id='sleep_loop', label='SLEEP DROP', weight=9, dict='mp_sleep', anim='sleep_loop', duration=10000,
              reactions={
                  { weight=50, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 },
                  { weight=30, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=20, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 }
              }
            }
        }
    },

    street_action = {
        label = 'Street Action',
        outcomes = {
            { id='carjack_fumble', label='CARJACK FUMBLE', weight=14, dict='anim@veh@std@barrage@rds@enter_exit', anim='jack_dead_perp', duration=11000,
              voiceType='chaos', reactionPool={ 'chaos', 'generic' },
              performerSounds={ 'performer_hold_my_money.ogg', 'performer_watch_this.ogg' },
              reactorSounds={ 'panic_nope_out.ogg', 'react_what_was_that.ogg' }
            },
            { id='vehicle_kickout', label='VEHICLE KICK', weight=16, dict='melee@knife@streamed_variations', anim='vehicle_kick_var_a', duration=9500,
              voiceType='hit', reactionPool='punch',
              performerSounds={ 'performer_watch_this.ogg', 'performer_aint_ready.ogg' },
              reactorSounds={ 'pain_oof_1.ogg', 'trash_hit_harder.ogg' }
            },
            { id='runover_sell', label='RUN-OVER SELL', weight=13, dict='missprologueig_3@react_to_explosion', anim='react_to_explosion_brad', duration=10500,
              voiceType='chaos', reactionPool={ 'chaos', 'punch' },
              performerSounds={ 'performer_hold_my_money.ogg', 'performer_watch_this.ogg' },
              reactorSounds={ 'pain_explosion.ogg', 'panic_get_me_out.ogg' }
            },
            { id='driveby_fakeout', label='DRIVE-BY FAKEOUT', weight=12, dict='weapons@pistol@', anim='fire_med', duration=9500, giveWeapon='WEAPON_PISTOL',
              voiceType='chaos', reactionPool={ 'intimidated', 'chaos' },
              performerSounds={ 'performer_watch_this.ogg', 'performer_aint_ready.ogg' },
              reactorSounds={ 'panic_nope_out.ogg', 'panic_get_me_out.ogg' }
            },
            { id='horde_callout', label='HORDE CALLOUT', weight=12, dict='rcmbarry', anim='mind_control_b_loop', duration=11000,
              voiceType='chaos', reactionPool='intimidated',
              performerSounds={ 'performer_watch_this.ogg', 'performer_hold_my_money.ogg' },
              reactorSounds={ 'panic_get_me_out.ogg', 'panic_nope_out.ogg' }
            },
            { id='danger_sprint_fake', label='DANGER SPRINT', weight=14, dict='amb@world_human_jog_standing@female@idle_a', anim='idle_a', duration=9500,
              voiceType='chaos', reactionPool={ 'intimidated', 'generic' },
              performerSounds={ 'performer_aint_ready.ogg', 'performer_watch_this.ogg' },
              reactorSounds={ 'panic_nope_out.ogg', 'react_what_was_that.ogg' }
            },
            { id='overhead_attack_sell', label='OVERHEAD ATTACK', weight=13, dict='combat@combat_reactions_2handed', anim='2handed_react_clean_90', duration=9500,
              voiceType='hit', reactionPool='punch',
              performerSounds={ 'performer_soft_check.ogg', 'performer_aint_ready.ogg' },
              reactorSounds={ 'pain_felt_that.ogg', 'trash_hit_harder.ogg' }
            }
        }
    },

    humiliation = {
        label = 'Humiliation',
        outcomes = {
            { id='street_pose_vanilla', label='STREET POSE', weight=15, dict='mini@hookers_spvanilla', anim='idle_a', duration=10000,
              voiceType='humiliation', reactionPool='humiliation',
              performerSounds={ 'performer_soft_check.ogg', 'performer_watch_this.ogg' },
              reactorSounds={ 'trash_look_this_guy.ogg', 'trash_he_soft.ogg' }
            },
            { id='air_shag_taunt', label='AIR SHAG TAUNT', weight=13, dict='anim@mp_player_intcelebrationfemale@air_shagging', anim='air_shagging', duration=10000,
              voiceType='humiliation', reactionPool='humiliation',
              performerSounds={ 'performer_soft_check.ogg', 'performer_hold_my_money.ogg' },
              reactorSounds={ 'trash_look_this_guy.ogg', 'trash_embarrassing.ogg' }
            },
            { id='pole_dance_flex', label='POLE DANCE FLEX', weight=12, dict='mini@strip_club@pole_dance@pole_dance1', anim='pd_dance_01', duration=12000,
              voiceType='showboat', reactionPool={ 'humiliation', 'generic' },
              performerSounds={ 'performer_watch_this.ogg', 'performer_hold_my_money.ogg' },
              reactorSounds={ 'trash_he_soft.ogg', 'trash_look_this_guy.ogg' }
            },
            { id='meditation_disrespect', label='MEDITATION DISRESPECT', weight=13, dict='rcmcollect_paperleadinout@', anim='meditiate_idle', duration=10500,
              voiceType='humiliation', reactionPool='humiliation',
              performerSounds={ 'performer_soft_check.ogg', 'performer_aint_ready.ogg' },
              reactorSounds={ 'trash_talk_back.ogg', 'trash_you_aint_nobody.ogg' }
            },
            { id='strength_average', label='STRENGTH TEST', weight=14, dict='anim_heist@arcade@strength@female@', anim='result_average', duration=10000,
              voiceType='showboat', reactionPool='generic',
              performerSounds={ 'performer_watch_this.ogg', 'performer_hold_my_money.ogg' },
              reactorSounds={ 'trash_hit_harder.ogg', 'trash_he_soft.ogg' }
            },
            { id='black_madonna_dance', label='CLUB CREW DANCE', weight=12, dict='anim@amb@nightclub@dancers@black_madonna_entourage@', anim='li_dance_facedj_11_v1_male^1', duration=12000,
              voiceType='showboat', reactionPool={ 'humiliation', 'generic' },
              performerSounds={ 'performer_watch_this.ogg', 'performer_soft_check.ogg' },
              reactorSounds={ 'trash_look_this_guy.ogg', 'trash_embarrassing.ogg' }
            }
        }
    },

    weird_chaos = {
        label = 'Weird Chaos',
        outcomes = {
            { id='arena_flip', label='ARENA FLIP', weight=13, dict='anim@arena@celeb@flat@solo@no_props@', anim='flip_a_player_a', duration=10500,
              voiceType='chaos', reactionPool={ 'generic', 'chaos' },
              performerSounds={ 'performer_watch_this.ogg', 'performer_hold_my_money.ogg' },
              reactorSounds={ 'react_what_was_that.ogg', 'trash_look_this_guy.ogg' }
            },
            { id='swim_flip_recover', label='FLOP RECOVER', weight=10, dict='swimming@swim', anim='recover_flip_back_to_front', duration=9500,
              voiceType='chaos', reactionPool={ 'humiliation', 'generic' },
              performerSounds={ 'performer_soft_check.ogg', 'performer_watch_this.ogg' },
              reactorSounds={ 'trash_embarrassing.ogg', 'trash_he_soft.ogg' }
            },
            { id='alien_hand_light', label='ALIEN HAND LIGHT', weight=9, dict='fam_5_mcs_6-0', anim='cs_alien_hand_light^1-0', duration=11500,
              voiceType='chaos', reactionPool='intimidated',
              performerSounds={ 'performer_watch_this.ogg', 'performer_hold_my_money.ogg' },
              reactorSounds={ 'panic_get_me_out.ogg', 'panic_nope_out.ogg' }
            },
            { id='movalien_takeover', label='ALIEN TAKEOVER', weight=8, dict='fam_5_mcs_6_p4-0', anim='s_m_m_movalien_01-0', duration=11500,
              voiceType='chaos', reactionPool='chaos',
              performerSounds={ 'performer_watch_this.ogg', 'performer_aint_ready.ogg' },
              reactorSounds={ 'panic_get_me_out.ogg', 'pain_explosion.ogg' }
            },
            { id='alien_teleport_fake', label='TELEPORT FAKE', weight=9, dict='anim_freemode@collect@aliensuit_ext@', anim='bar_1a_teleport_aln', duration=11000,
              voiceType='chaos', reactionPool={ 'intimidated', 'chaos' },
              performerSounds={ 'performer_watch_this.ogg', 'performer_hold_my_money.ogg' },
              reactorSounds={ 'panic_nope_out.ogg', 'react_what_was_that.ogg' }
            },
            { id='alien_landing_intro', label='ALIEN LANDING', weight=8, dict='anim@special_peds@alien_landing', anim='intro_b', duration=12000,
              voiceType='chaos', reactionPool='chaos',
              performerSounds={ 'performer_watch_this.ogg', 'performer_aint_ready.ogg' },
              reactorSounds={ 'panic_get_me_out.ogg', 'panic_nope_out.ogg' }
            }
        }
    },

    finale = {
        label = 'Finale',
        outcomes = {
            { id='fake_final_shot', label='FAKE FINAL SHOT', weight=12, dict='weapons@pistol@', anim='fire_med', duration=9500, giveWeapon='WEAPON_PISTOL',
              reactions={
                  { weight=65, dict='', anim='', effect='kill_temp', resetMs=5000, duration=7000 },
                  { weight=35, dict='move_m@drunk@verydrunk', anim='idle', effect='none', duration=7000 }
              }
            },
            { id='winner_bow', label='WINNER BOW', weight=14, dict='anim@arena@celeb@podium@no_prop@', anim='regal_a_1st', duration=10000,
              reactions={
                  { weight=55, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=30, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=15, dict='misscommon@response', anim='bring_it_on', effect='none', duration=7000 }
              }
            },
            { id='angry_clap', label='ANGRY CLAP', weight=13, dict='anim@arena@celeb@flat@solo@no_props@', anim='angry_clap_a_player_a', duration=10000,
              reactions={
                  { weight=45, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 },
                  { weight=35, dict='random@car_thief@agitated@idle_a', anim='agitated_idle_a', effect='none', duration=7000 },
                  { weight=20, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 }
              }
            },
            { id='cutthroat', label='CUTTHROAT', weight=13, dict='anim@mp_player_intcelebrationmale@cut_throat', anim='cut_throat', duration=10000,
              reactions={
                  { weight=45, dict='random@arrests@busted', anim='idle_a', effect='none', duration=7000 },
                  { weight=35, dict='missminuteman_1ig_2', anim='handsup_base', effect='none', duration=7000 },
                  { weight=20, dict='', anim='', effect='ragdoll', ragdollMs=1300, duration=6500 }
              }
            },
            { id='victory_flex', label='VICTORY FLEX', weight=15, dict='amb@world_human_muscle_flex@arms_at_side@base', anim='base', duration=11000,
              reactions={
                  { weight=50, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=35, dict='anim@mp_player_intcelebrationmale@slow_clap', anim='slow_clap', effect='none', duration=7000 },
                  { weight=15, dict='misscommon@response', anim='screw_you', effect='none', duration=7000 }
              }
            },
            { id='finale_mind_blown', label='FINAL MIND BLOWN', weight=12, dict='anim@mp_player_intcelebrationmale@mind_blown', anim='mind_blown', duration=10000,
              reactions={
                  { weight=45, dict='', anim='', effect='ragdoll', ragdollMs=1800, duration=6500 },
                  { weight=35, dict='amb@world_human_cheering@male_a', anim='base', effect='none', duration=7500 },
                  { weight=20, dict='anim@mp_player_intcelebrationmale@face_palm', anim='face_palm', effect='none', duration=7000 }
              }
            }
        }
    }
}

Config.Rounds = {
    [1]  = { prompt='Round 1 -- opening chaos',       branch={ 'combat', 'taunt', 'street_action' },             pickCount=5 },
    [2]  = { prompt='Round 2 -- disrespect branch',   branch={ 'taunt', 'humiliation' },                         pickCount=5 },
    [3]  = { prompt='Round 3 -- fight branch',        branch={ 'combat', 'street_action' },                      pickCount=5 },
    [4]  = { prompt='Round 4 -- showboat branch',     branch={ 'showboat', 'humiliation' },                      pickCount=5 },
    [5]  = { prompt='Round 5 -- dirty mix branch',    branch={ 'combat', 'chaos', 'street_action' },             pickCount=5 },
    [6]  = { prompt='Round 6 -- cold taunt branch',   branch={ 'taunt', 'chaos', 'weird_chaos' },                pickCount=5 },
    [7]  = { prompt='Round 7 -- crowd pop branch',    branch={ 'showboat', 'taunt', 'humiliation' },             pickCount=5 },
    [8]  = { prompt='Round 8 -- knockout branch',     branch={ 'combat', 'street_action', 'humiliation' },       pickCount=5 },
    [9]  = { prompt='Round 9 -- wild card branch',    branch={ 'chaos', 'weird_chaos', 'street_action' },        pickCount=5 },
    [10] = { prompt='Round 10 -- finale branch',      branch={ 'finale', 'combat', 'showboat', 'weird_chaos' },  pickCount=5 }
}

-- RS Voice Audio Pack
-- Added by RS OutcomeBets Audio Director. Client-only voice hype; no money/gameplay logic changed.
Config.VoiceAudio = {
    enabled = true,
    volume = 0.78,
    audibleRadius = 35.0,
    cooldownMs = 1800,
    action = {
        enabled = true,
        volume = 0.86,
        performerVolume = 0.76,
        reactorVolume = 0.90,
        crowdVolume = 0.72,
        performerDelayMs = 150,
        reactorDelayMs = 850,
        crowdDelayMs = 1550,
        crowdChance = 40
    },
    files = {
        open = {'open_1.ogg', 'open_2.ogg'},
        warning = {'warning_1.ogg', 'warning_2.ogg'},
        locked = {'locked_1.ogg', 'locked_2.ogg'},
        payout = {'payout_1.ogg', 'payout_2.ogg'},
        rare = {'rare_1.ogg', 'rare_2.ogg'},
        highroller = {'highroller_1.ogg'},
        execute = {'execute_1.ogg'}
    },
    pools = {
        performer = {
            hit = { 'performer_watch_this.ogg', 'performer_aint_ready.ogg', 'performer_soft_check.ogg' },
            humiliation = { 'performer_soft_check.ogg', 'performer_hold_my_money.ogg', 'performer_watch_this.ogg' },
            showboat = { 'performer_watch_this.ogg', 'performer_hold_my_money.ogg' },
            chaos = { 'performer_watch_this.ogg', 'performer_aint_ready.ogg', 'performer_hold_my_money.ogg' },
            generic = { 'performer_watch_this.ogg', 'performer_hold_my_money.ogg' }
        },
        reactor = {
            hit = { 'pain_oof_1.ogg', 'pain_oof_2.ogg', 'pain_felt_that.ogg', 'trash_hit_harder.ogg' },
            humiliation = { 'trash_you_aint_nobody.ogg', 'trash_look_this_guy.ogg', 'trash_he_soft.ogg', 'trash_embarrassing.ogg' },
            showboat = { 'trash_look_this_guy.ogg', 'trash_he_soft.ogg', 'trash_embarrassing.ogg' },
            chaos = { 'panic_nope_out.ogg', 'panic_get_me_out.ogg', 'pain_explosion.ogg', 'react_what_was_that.ogg' },
            generic = { 'react_what_was_that.ogg', 'trash_talk_back.ogg', 'trash_you_aint_nobody.ogg' }
        },
        crowd = {
            hit = { 'crowd_ohhh.ogg', 'crowd_get_up.ogg' },
            humiliation = { 'crowd_look_this_guy.ogg', 'crowd_laughing.ogg' },
            showboat = { 'crowd_look_this_guy.ogg', 'crowd_laughing.ogg' },
            chaos = { 'crowd_ohhh.ogg', 'crowd_get_up.ogg' },
            generic = { 'crowd_look_this_guy.ogg', 'crowd_ohhh.ogg' }
        }
    }
}
