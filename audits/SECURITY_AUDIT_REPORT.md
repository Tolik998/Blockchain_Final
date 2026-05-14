# ShieldFi student security audit

**Scope:** Solidity contracts under `contracts/` excluding intentionally vulnerable lesson contracts (`contracts/lessons/vulnerable`) and mocks for automated gate purposes.  
**Tooling:** Slither (`slither.config.json` filters), Foundry tests (unit, fuzz, invariant, fork).  
**Disclaimer:** This is a capstone audit, not a substitute for professional third-party review.

## Executive summary

ShieldFi separates underwriting (ERC4626), policy accounting, and oracle-driven settlement. Critical safety controls include OpenZeppelin `AccessControl`, `Pausable`, `ReentrancyGuard`, `SafeERC20`, CEI in payout paths, timelock-only treasury withdrawals, and UUPS upgrade authorization restricted to administrators ultimately intended to be the timelock.

## Findings table

| ID | Title | Severity | Status |
| --- | --- | --- | --- |
| F-01 | Governance parameter mismatch risk if token clock changes | Low | Documented / monitor |
| F-02 | ERC4626 donation / inflation risk on empty vault | Low | Mitigated via OZ defaults + seeding guidance |
| F-03 | Intentional lesson contracts | Informational | Isolated + excluded from Slither gate |
| F-04 | Chainlink feed assumptions (heartbeat, feed selection) | Low | Mitigated by stale, future timestamp, bad answer, and incomplete round checks |

## Attack analysis — reentrancy

Production vault payouts use `nonReentrant`, update counters before `safeTransfer`, and avoid `transfer`/`send`. Lesson contracts deliberately violate CEI to demonstrate draining ETH; fixed versions add `ReentrancyGuard` and reorder effects.

## Attack analysis — access control

`ProtocolTreasury` withdrawals require `msg.sender == timelock`. Lesson `VulnerableMintAccessLesson` demonstrates missing mint gates; `FixedMintAccessLesson` restores `MINTER_ROLE`.

## Governance attack notes

- **Vote buying / flash governance:** mitigated by ERC20Votes checkpoints + timelock delay; still requires monitoring large delegated bundles.
- **Proposal spam:** `proposalThreshold` enforces minimum voting weight.
- **Timelock executor openness:** deployment uses OZ convention `EXECUTOR_ROLE` granted to `address(0)` for permissionless execution of queued operations—standard but should be documented for operators.

## Oracle attack notes

- **Stale prices:** rejected via `heartbeatSeconds`.
- **Bad / incomplete rounds:** rejected via `answer <= 0` and `answeredInRound` checks.
- **Liquidity griefing:** `ClaimProcessor` checks vault balance before consuming the claim, avoiding stuck “claimed but unpaid” states.

## Slither appendix

CI runs `crytic/slither-action` with `fail-on: high` and `filter_paths` excluding mocks, lessons, tests, scripts, and dependencies. For strict “0 Medium” production reporting, maintain a triage document mapping any informational/medium findings to accepted risks or follow-up issues.

## Pedagogical vulnerabilities

See `contracts/lessons/vulnerable` and corresponding fixes under `contracts/lessons/fixed` with tests in `test/Lessons.t.sol`.
