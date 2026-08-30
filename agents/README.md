# Ecosystem test agents

Role prompts used to have autonomous agents live on the Agent Knowledge Commons
demo and critique it. Each agent is given **only the base URL** — it must
discover the entire site from `/llms.txt`, which tests whether the site is
truly self-describing to a machine.

| Role | Goal | What it stresses |
|---|---|---|
| `reader` | Acquire knowledge on a budget | discovery, pricing, resolutions, 402 |
| `contributor` | Publish knowledge and earn | write-back, staking, provenance rules |
| `verifier` | Police quality for bounties | verification, self-verify guard, slashing |
| `adversary` | Extract value / publish slop cheaply | economic soundness, abuse resistance |

Findings are aggregated in [`../reports/ECOSYSTEM-REPORT.md`](../reports/ECOSYSTEM-REPORT.md).
