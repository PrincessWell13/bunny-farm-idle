# Epic: GuildSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §3.9
> **Architecture Module**: `src/core/guild_system.gd`
> **Status**: Blocked — ADR-0014 (GuildSystem async raid) not yet written
> **Stories**: Not yet created — run `/create-stories guild-system`
> **Control Manifest Version**: 2026-05-18

## Overview

GuildSystem is the only Feature layer system that depends on live Firebase data. It maintains a local cache of the guild roster, contribution totals, boss raid HP, and marketplace listings. All reads/writes go through `FirebaseAdapter`. Guild Boss Raids are a 7-day async contribution window — no real-time multiplayer. The marketplace lets players list rabbits for Gem purchase by guild members. GuildSystem calls `FirebaseAdapter` for all I/O; EconomyManager handles transactions. This is the highest-complexity system in the Feature layer due to Firebase dependency.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Firebase Local-First Save | FirebaseAdapter provides the Auth + Realtime DB surface used by GuildSystem | MEDIUM |
| ~~ADR-0014~~: GuildSystem Async Raid | **MISSING** — raid window model, contribution schema, marketplace listing contract not decided | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-guild-001 | Guild requires multiplayer backend | ADR-0008 ✅ (partial — surface only) |
| TR-guild-002 | Guild Boss Raid 7-day contribution window | ❌ No ADR (ADR-0014 needed) |

## Unresolved Requirement
⚠️ TR-guild-002 (raid logic) has no ADR. Engine Risk HIGH — async guild state on Firebase requires careful conflict resolution and offline resilience design. Do not start implementation without ADR-0014.

## Definition of Done

This epic is complete when:
- Players can join/create a guild via FirebaseAdapter
- Contributions submit and aggregate correctly over the 7-day window
- Boss HP is tracked server-side; local cache refreshes correctly
- Marketplace listing and purchase flow completes via EconomyManager
- All Integration stories have evidence docs in `production/qa/evidence/`

## Next Step

1. Write ADR-0014: `/architecture-decision "GuildSystem async raid and marketplace model"`
2. Then: `/create-stories guild-system`
