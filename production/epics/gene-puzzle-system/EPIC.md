# Epic: GenePuzzleSystem

> **Layer**: Feature
> **GDD**: design/gdd/bunny-farm-idle-master.md §3.11
> **Architecture Module**: `src/core/gene_puzzle_system.gd`
> **Status**: Blocked — ADR-0016 (GenePuzzle sharing) not yet written
> **Stories**: Not yet created — run `/create-stories gene-puzzle-system`
> **Control Manifest Version**: 2026-05-18

## Overview

GenePuzzleSystem is the Gene Journal — the breeding challenge and genealogy tracking layer. It stores active breeding challenges (e.g. "breed a rabbit with these 3 specific traits"), tracks player progress against each challenge, and provides the genealogy tree for any rabbit via `get_genealogy(rabbit_id)`. It listens on EventBus for `rabbit_born` to automatically check challenge progress. The cross-player sharing of Gene Journal entries (TR-puzzle-003) requires a Firebase-backed sharing model that is not yet architecturally defined.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: RabbitData Resource | Parentage fields (`parent_a_id`, `parent_b_id`) enable genealogy tree reconstruction | LOW |
| ADR-0006: Genetics Allele Model | Trait and allele data provide challenge verification inputs | LOW |
| ~~ADR-0016~~: GenePuzzle Sharing | **MISSING** — Firebase sharing model for Gene Journal entries not decided | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-puzzle-003 | Gene Journal cross-player sharing | ❌ No ADR (ADR-0016 needed) |

## Unresolved Requirement
⚠️ Cross-player sharing (TR-puzzle-003) requires Firebase storage design. Engine Risk HIGH. Local-only challenge tracking can be implemented without this ADR; sharing feature requires ADR-0016.

## Definition of Done

This epic is complete when:
- Active challenges are correctly evaluated on `rabbit_born` event
- `get_genealogy()` reconstructs full ancestry chain from `parent_a_id`/`parent_b_id`
- Challenge completion emits `puzzle_completed` signal on EventBus
- (Sharing deferred until ADR-0016 is written)
- All Logic stories have passing tests in `tests/unit/`

## Next Step

1. Write ADR-0016: `/architecture-decision "GenePuzzle Gene Journal sharing via Firebase"`
2. Then: `/create-stories gene-puzzle-system`
