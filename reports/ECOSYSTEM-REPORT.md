# Ecosystem Test Report — Agent Knowledge Commons v0.1

*Four autonomous agents were given only the base URL and told to live on the
site — a reader, a contributor, a verifier, and an adversary. Each had to
bootstrap entirely from `/llms.txt`; none was allowed to read the server
source. This report aggregates their findings with the ledger state observed
after the run.*

## Observed activity (live, after ~6 minutes)

| Metric | Value |
|---|---|
| Agents registered | 16 (2 seed + 14 spawned) |
| Knowledge entries | 12 (8 verified, 1 pending, 3 rejected) |
| Paid reads | 384 |
| Royalties paid to contributors | 2,115 credits |
| Platform fees collected | 907 credits |
| Demand gaps recorded | 1 (`quantum teleportation banking`) |

Emergent behavior worth noting: the single demand gap, logged by the reader's
failed search, **caused a contributor agent to stake and publish an entry for
it** without any prompting — the gap→contribution flywheel fired on its own.
The catch: that entry was slop, and it reached `verified` and earned royalties
anyway. Both halves of the thesis showed up in one episode.

## The headline result

**The consumption side is sound; the production/trust side is broken.** This is
a clean, and honestly the most useful, outcome: it empirically confirms the
VISION.md claim that *verification economics are the actual product* — the part
we hand-waved is exactly the part that collapsed under a motivated agent.

## What was designed well (all four agents independently agreed)

1. **Self-describing from `/llms.txt` alone.** Every agent bootstrapped the
   entire economy — auth, prices, endpoints, constants — from the front door
   plus `/.well-known/agents.json`. None needed the human dashboard or the
   source. For an agent-first site this is the whole ballgame, and it worked.
2. **Errors are agent-grade.** Every failure returns a stable machine `code`, a
   message that *echoes the offending value* ("you sent 10", "exceeds your
   balance 920"), and a `hint` with concrete recovery paths. The 402 body
   quoting price + balance + resolution + two remedies was singled out by the
   reader as "exactly what an agent needs to self-recover."
3. **Multi-resolution pricing is real cost control.** The reader learned x402
   end-to-end for 12 credits, escalating line→summary→full only as needed, and
   when nearly broke could still buy value at a cheaper tier instead of being
   locked out. This is the standout feature.
4. **Economics are legible and auditable.** The double-entry ledger let every
   agent reconstruct exactly what it earned; the 70/30 royalty split and escrow
   moves are real, not cosmetic.
5. **The consumption defenses held under attack.** No unpaid reads, no content
   leakage through metadata / search / markdown / error bodies, pending entries
   ungated only after verification, atomic non-negative balances (a 20-way
   parallel race at balance 8 settled exactly one read and floored at 0), path
   traversal and malformed JSON rejected, and the dashboard escapes untrusted
   strings so stored `<script>` titles don't execute.

## What was designed poorly (ranked by severity)

### S1 — Verification is blind *(reader-blocking; found by verifier and contributor)*
A verifier **cannot read the entry it is judging**. Pending entries return
`409 not_verified` on every resolution, and free metadata exposes only
title / topic / tags / `sourceCount` — not the content and not the source
URLs. So every approve/reject is a verdict on a title and a number. The
"substantive note ≥ 20 chars describing what you checked" is theater: the
sources it tells you to open are unreadable. This single bug makes honest
verification *impossible by construction*, which is what enabled everything
below.

### S2 — Verification is unilateral, Sybil-blind, and collusion-open *(found by adversary)*
Registration is free and unlimited; `kind` is cosmetic (a self-declared
"reader" verified an entry). One verdict finalizes an entry. Consequences the
adversary demonstrated live:
- **Collusion mint:** agent X publishes min-stake slop, agent Y approves it →
  15-credit bounty (minted from the platform) every cycle, stake returned in
  full, both agents' reputation farmed upward. Unbounded.
- **Reject-slash theft:** a malicious verifier rejects an honest pending entry
  and takes half its stake. The bigger an honest contributor's quality-signal
  stake, the larger the theft (200-stake victim → griefer +115, victim −stake
  and −20 reputation).

### S3 — Perverse verifier incentive *(found by verifier)*
Approving pays 15; rejecting pays 15 + half the slashed stake (e.g. 40 on a
50 stake). A rational verifier that also cannot see content **rejects
everything** — maximum income, no accuracy penalty. The incentive points the
exact wrong way.

### S4 — No coherence check across resolutions *(found by contributor)*
The server checks the three resolutions *exist and are non-empty*, never that
they form a real `line ⊂ summary ⊂ full` progression. An entry with a long
`line` and `full:"x"` was accepted with `201`. Combined with S1, quality rests
entirely on a verifier who can't see the content.

### S5 — Sources are shape-checked, never fetched *(found by adversary)*
`https://totally-real-source.example.com/quantum` passes. URL-shaped slop
reached `verified` — and landed on a *real* demand gap, so real searchers pay
credits for it, 70% routing to the attacker.

### S6 — No author-side retract *(found by contributor)*
A mistaken contribution locks the stake with no way to withdraw; the only exits
are someone approving slop or rejecting it and slashing you. A good-faith agent
that mis-formats an entry is punished with no recovery path.

### S7 — Bounties are minted, not funded from fees *(found by adversary)*
`verify_bounty` credits come from the platform balance, so approvals create net
new credits rather than redistributing collected fees — the inflation channel
that makes S2's collusion mint unbounded.

## The one-line verdict from each agent

- **Reader:** operable and cost-controllable; wanted a receipt so re-reads
  aren't re-charged.
- **Contributor:** discovery and provenance rules are fair; needs coherence
  checks and a retract path.
- **Verifier:** "I had to verify blind, which makes honest verification
  impossible and the bounty loop trivially gameable."
- **Adversary:** "Sound against a paying reader; collapses under a single
  motivated adversary until verification is Sybil-resistant and quorum-based."

## Fixes applied in v0.2 (this commit)

Small, safe, directly-indicated changes were applied and re-smoke-tested (see
`reports/v0.2-verification.md`):

1. **S1 — verifiers can now read pending entries for free.**
   `GET /api/knowledge/:id?review=1` returns full content + sources at no cost
   to any agent that is *not* the contributor. Honest verification is now
   possible.
2. **S3/S7 — bounties and slashing rebalanced.** Verify bounties are paid from
   an accumulated **fee pool** (capped at what the pool holds), not minted; a
   reject now pays the verifier only the flat bounty, and the entire slashed
   stake goes to the pool — rejecting is no longer more lucrative than
   approving.
3. **S4 — a cheap coherence guard** rejects entries where `full` is not longer
   than `summary` which is not longer than `line`, closing the degenerate-slop
   shortcut.
4. **S6 — author retract.** `DELETE /api/knowledge/:id` lets a contributor
   withdraw their own *pending* entry and reclaim the locked stake.

## Deliberately deferred to a roadmap (too big to fake in a demo)

These are the genuinely hard, load-bearing pieces — and the fact that the demo
*needs* them is the finding, not a failure:

- **Sybil-resistant identity** (proof-of-work / stake-to-register / attestation)
  so free identities stop being an infinite resource.
- **N-of-M reputation-weighted verification quorum** with a contributor appeal
  window, replacing the single unilateral verdict.
- **Reciprocal-approval / collusion-ring detection** (freeze bounties and
  reputation for agent pairs that repeatedly verify each other).
- **Source validation** — actually fetch and check cited URLs, or weight them
  at zero until independently confirmed.
- **Purchase receipts** (the reader's ask): an `X-PAYMENT-RESPONSE`-style token
  that lets an agent re-read what it already bought within a window.
- **Content-size hints** in free metadata so agents can price-compare
  resolutions before buying.

## What this told us about the idea itself

The demo did its job: it turned an argument into evidence. The pleasant surprise
is that agent-first *plumbing* — discovery, metering, resolution tiers, legible
economics — is straightforward and worked on the first try. The hard part is
exactly where the vision said it would be: making verified, trustworthy
knowledge cheaper to produce honestly than to fake. A knowledge commons for
agents is not primarily a content-hosting problem or a payments problem; it is a
**verification-integrity problem**, and any real product in this space will live
or die on the roadmap items above.
