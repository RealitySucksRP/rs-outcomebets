# 🎭 RS-OUTCOMES — NPC Prediction Arena

![RS-Outcomes NPC Prediction Arena](tebex_assets/rs-outcomes-tebex-banner-safe.png)

Turn your city into a live underground street spectacle.

CHECK OUT MY TEBEX STORE: https://reality-sucks-rp-webstore.tebex.io/

RS-Outcomes is an NPC-driven FiveM RP event resource where players gather around a cage arena, predict chaotic NPC outcomes, watch the show unfold live, and react to dynamic performer, reactor, and crowd moments.

Built for immersive city events, nightlife districts, gang territory RP, streamer events, community nights, and public social hubs.

> ⚠️ **RP ENTERTAINMENT ONLY**
>
> This resource must not be connected to real money, cryptocurrency, paid currency, or anything with real-world value.

☕ Like the resource? Support Reality Sucks RP on Ko-fi: [ko-fi.com/realitysucksrp](https://ko-fi.com/realitysucksrp)

## 🌱 Open Source & Community Friendly

RS-Outcomes / RS-OutcomeBets is released as an open-source community resource.

You are encouraged to:

🔧 add more outcomes  
🎭 create new NPC reactions  
🔊 add custom voice lines  
🏟 build new arena locations  
🖥 improve the UI  
🧩 add framework support  
📦 fork it for your own RP events  
🚀 share improvements with the community

Please keep credit to the original creator:

**Original Creator:** Reality Sucks RP / William Brito  
**Original Resource:** RS-Outcomes / RS-OutcomeBets

Do not claim the original work as your own, and do not use the Reality Sucks RP / William Brito name to imply endorsement of modified versions unless permission is given.

Licensed under the [BSD 3-Clause License](LICENSE).

## 🧩 Framework Support

✅ QBCore  
✅ Qbox  
✅ Standalone  
✅ ESX support through RS-Bridge if installed separately

## 🔥 Features

### 🎬 Live NPC Prediction Shows

Players gather around a cage arena and predict what the performer NPC will do next.

Outcome types include:

🥊 fight moments  
😤 taunts  
🕺 dance-offs  
😈 intimidation  
😂 comedy reactions  
💥 chaos moments  
🎭 rare cinematic outcomes  
🌃 street-action scenes  
👽 strange wildcard moments

Every round is designed to feel different.

### 🧠 Smart Outcome Director

The director system helps reduce repetitive shows by tracking recent outcomes and rotating different action styles.

Helps prevent:

🔁 repeated outcomes  
🧊 stale pacing  
📋 duplicate-feeling rounds  
👀 predictable shows

The show can rotate between combat, taunt, showboat, chaos, street-action, humiliation, weird chaos, and finale branches.

### 🎭 Dynamic NPC Reactions

The reactor NPC is not just standing there.

Depending on the outcome, they can:

😱 panic  
😂 laugh  
🥴 stumble  
😤 taunt back  
🤕 oversell hits  
🙌 fake surrender  
💀 collapse dramatically  
🔄 recover differently after the round

This creates a more natural live-event feel for the crowd.

### 🔊 Voice Reaction System

Includes OGG voice callouts for performer, reactor, and crowd moments.

Includes:

🎙 performer hype lines  
🗣 reactor trash-talk  
💢 pain reactions  
😨 panic reactions  
📣 crowd callouts

Server owners can replace or expand the included OGG files.

### 🏟 Underground Cage Atmosphere

Includes:

✅ chain-link cage arena  
✅ red event lighting  
✅ performer NPC  
✅ reactor NPC  
✅ event host NPC  
✅ outside crowd NPCs  
✅ performer marker system  
✅ fight-club style UI  
✅ local atmosphere effects

Built to feel like a live GTA-style street event.

### 🎟 Configurable RP Participation System

Server owners can configure how players participate in each round.

Includes:

⚙️ configurable entry settings  
⚙️ server-side validation  
⚙️ round handling  
⚙️ duplicate result protection  
⚙️ one-entry-per-round option  
⚙️ anti-leave behavior  
⚙️ optional NPC assist pool for low-pop servers

Use only for in-city RP entertainment. Do not use real money, crypto, paid coins, or anything with real-world value.

### 🤖 Optional NPC Assist Pool

For smaller or newer servers, an optional NPC assist system can support low-pop events so solo players still have a reason to participate.

Can be disabled in config:

```lua
Config.NpcOpponent.enabled = false
```

## ⚡ Customization

Server owners can configure:

🎬 rounds  
🎲 outcome branches  
🧍 NPC models  
🎭 animations  
🔁 reaction pools  
🔊 voice lines  
⏱ event timing  
📍 arena location  
🏟 cage size  
👥 crowd size  
🚨 lighting  
🖥 UI behavior  
🧊 cooldowns  
🔁 anti-repeat settings  
🤖 NPC assist settings

## 🧩 Perfect For

🌃 city events  
🎭 underground RP  
🏴 gang territories  
🎶 nightlife districts  
📺 streamer events  
👥 public social hubs  
🏆 server tournaments  
💥 chaotic street entertainment  
🎉 community event nights

## ✅ Included

✅ QBCore support  
✅ Qbox support  
✅ Standalone support  
✅ RS-Bridge compatibility  
✅ Full source code  
✅ Config system  
✅ Multi-round event logic  
✅ Outcome director system  
✅ Dynamic NPC reaction system  
✅ Fight-club UI  
✅ Crowd atmosphere system  
✅ OGG voice reaction system  
✅ NPC assist option  
✅ Changelog

## 🛠 Install

1. Drop `rs-outcomebets` into your resources folder.
2. Add this to `server.cfg`:

```cfg
ensure rs-outcomebets
```

3. Configure your framework and arena settings in `shared/config.lua`.
4. If using fixed arenas, set `Config.Arenas` before running `/betstart fixed`.
5. Restart the resource and test on a dev server before running live.

## 🎮 Commands

```txt
/betstart              Start a popup arena at your current location
/betstart fixed        Start the default fixed arena
/betstart fixed id     Start a specific configured fixed arena
/betmenu               Open the UI if you are near/inside a show
/betforce [round] [outcomeId]  Dev test a round/outcome
/betend                End hosted show and refund active entries
/betcancel             Cancel hosted show and refund active entries
```

## 🧪 Testing

Useful forced outcome tests:

```txt
/betforce 1 shadow_boxing
/betforce 1 vehicle_kickout
/betforce 3 driveby_fakeout
/betforce 4 air_shag_taunt
/betforce 6 alien_teleport_fake
/betforce 9 arena_flip
/betforce 10 fake_final_shot
```

## ⚠️ Important Notice

This resource is designed for FiveM roleplay entertainment only.

Do not use this resource with:

❌ real money  
❌ cryptocurrency  
❌ paid currency  
❌ anything with real-world value  
❌ real gambling systems

Server owners are responsible for configuring this resource in a way that follows their platform rules, local laws, Tebex policies, and Cfx.re/FiveM policies.

## 🎬 Summary

RS-Outcomes turns a simple NPC event into a full live crowd experience.

Players gather, predict, react, laugh, and watch the cage show unfold round by round.

🎭 **Watch the show. Predict the outcome. Create the RP moment.**

## Version

Current package version: `2.4.1`

See [CHANGELOG.md](CHANGELOG.md) for release history.
