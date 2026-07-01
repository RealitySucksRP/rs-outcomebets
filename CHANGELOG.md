# rs-outcomebets Safe Baseline

## Sweet Spot Baseline

- This package is based on the uploaded working version William confirmed felt stable.
- Later broken/buggy patches are not included.
- Old separate UPGRADE_NOTES files were removed.
- Future changes should build from this baseline only.
- Code logic was not changed in this cleanup package.

---

# v2.4.1 - Configurable NPC Opponent Betting

- Added `Config.NpcOpponent` for low-pop servers.
- NPC/house money can now seed outcomes real players did not pick, allowing solo or low-pop players to win more than their own stake back.
- Added automatic disable threshold with `activeWhenRealBettorsBelow`.
- Added caps for NPC total stake and per-outcome stake to control economy risk.
- Added `NPC BANK` display in the betting UI when a pool contains virtual NPC money.
- NPC opponent stakes are virtual only: they are not refunded, not paid out, and are cleared after each round.

# v2.4.0 - Action Outcomes + Reactor Voice Pack

- Added reusable `Config.ReactionPools` so outcomes can pull punch, humiliation, intimidated, generic, and chaos reactions.
- Added more reactor animation dictionaries for embarrassment, intimidation, punch reactions, explosion-style reactions, cowering, golf-style bad reactions, and ragdoll sells.
- Added new `street_action`, `humiliation`, and `weird_chaos` outcome branches.
- Added new outcomes inspired by carjacks, run-over sells, drive-by fakeouts, horde callouts, danger sprints, vehicle kicks, club/showboat moments, arena flips, and alien chaos.
- Increased normal round cards from 4 to 5 and expanded anti-repeat windows so shows feel less repetitive.
- Added outcome/reaction-specific voice playback with performer, reactor, and optional crowd callout pools.
- Added distance-gated voice playback so local voice lines play around the cage instead of globally.
- Added overlapping NUI OGG playback so both NPCs can talk during the same outcome.
- Added a starter OGG voice pack with trash-talk, pain, panic, performer callouts, and crowd reactions.

# v2.3.1 - Bigger Outside Cage Crowd

- Increased the default outside-cage atmosphere crowd from 10 NPCs to 22 NPCs.
- Added front and back crowd rings so the arena feels fuller without putting peds inside the cage.
- Added more varied street, nightlife, gang, beach, skater, tourist, and dealer-style NPC models.
- Added more ambient crowd scenarios including cheering, filming, smoking, drinking, mobile, and guard behavior.
- Added configurable crowd jitter, heading variation, and outside-buffer controls in `Config.Atmosphere.crowd`.
- Crowd peds remain client-only atmosphere and do not touch betting, payouts, or server cash flow.

# v2.3.0 - Cash Flow + Full Atmosphere Upgrade

- Host/server owner can now place cash bets while hosting (`Config.Betting.hostCanBet = true`).
- Betting account is explicitly cash via `Config.Betting.account = 'cash'`.
- Added payout guard so a round cannot pay twice.
- Disconnecting/walking away forfeits only the active round stake.
- Added high roller hype, dynamic pool-share/potential payout display, crowd peds, red cage lighting, frontend hype sounds, and rare moment hype.
- Added `client/atmosphere.lua` as visual-only polish so the existing betting/outcome brain stays intact.

# Changelog

## v2.2.1 - Smooth Walk-Back Polish
- Added `Config.ReturnToAnchor` so performer/reactor walk back to their positions after outcomes instead of popping back.
- Kept hard snap as a failsafe only for stuck, dead, too-far, or timeout cases.
- Reactor cleanup now clears ragdoll/death physics, walks home, then resumes idle scenario.
- Performer cleanup now walks home after moving/stumble-style outcomes, then resumes idle scenario.
- This specifically improves big movement outcomes like stumble where the NPC ends far away from the center.


## v2.2.0

- Added branch-based outcome randomizer.
- Added `Config.OutcomeBranches` for bigger animation pools.
- Added `Config.Randomizer` to reduce repeated outcomes/winners.
- Reworked rounds so each round can draw from combat, taunt, showboat, chaos, and finale branches.
- Increased default animation timing so outcomes stay visible longer.
- `/betforce` can now test branch outcomes by id.

# Changelog

## v2.0.0

### Added
- I actually just rebuilt this resource from dice/craps into underground outcome betting.
- Added fixed arena and hostable popup arena modes.
- Added chain-link cage prop spawning with low/mid/tall height presets.
- Added performer NPC, reactor NPC, and cashier/bank NPC.
- Added performer-only overhead marker and `BET ON ME` text tag.
- Added weighted outcome config schema.
- Added weighted reaction system with `none`, `ragdoll`, and `kill_temp` effects.
- Added multi-round server state machine.
- Added server-authoritative bet placement and pool payout logic.
- Added current-round anti-leave forfeiture watcher.
- Added fight-club poster NUI.
- Added qb-target support and E-key fallback for cashier interaction.


### Notes
- This is a rebuild-level update. Test on a dev server before selling or running live.

## v2.1.2 - Animation cleanup and timing polish
- Removed duplicate-feeling DISCO / DANCE TAUNT setup.
- Replaced Round 6 phone-looking Freeze Out with stronger intimidation outcomes.
- Replaced unreliable Haymaker with more reliable punch/fight animations.
- Replaced Curtain Call clap-only finale with stronger final round outcomes.
- Added 10 fully-defined rounds instead of cycling two rounds.
- Added Config.Animation timing controls.
- Outcome/reaction animations now hold through the post-round beat before payout.
- Round prompt text now follows the live round count.
