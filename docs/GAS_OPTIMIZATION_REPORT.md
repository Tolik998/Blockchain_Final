# ShieldFi gas optimization report

## Methodology

Gas measurements use Foundry `gasleft()` deltas in `test/SuiteA.t.sol` and `forge test --gas-report` for deeper runs. Results vary with optimizer settings (`foundry.toml` uses `optimizer_runs = 200`).

## Optimizations shipped

1. **Custom Yul mulDiv for premium intermediates** — `GasOptimizedMath.premiumMulDivYul` avoids `Math.mulDiv` overhead for the constrained premium formula used in fuzz equivalence tests. The production premium path remains in Solidity inside `PolicyManager` for readability and auditability.
2. **UUPS proxies** — core protocol modules share implementation bytecode on-chain.
3. **Packed counters** — `totalPayouts` uses `uint128` where possible to leave headroom within the same slot as future packed fields.
4. **Minimal external calls in hot paths** — `ClaimProcessor` reads oracle once per `processClaim` and batches state updates in `PolicyManager.consumeClaim`.

## Benchmark snapshot (local)

| Function pair | Notes |
| --- | --- |
| `premiumMulDivSolidity` vs `premiumMulDivYul` | Compared in `test/SuiteA.t.sol::test_gas_mulDivBenchmarkRecordsUsage`; Yul path trades bytecode complexity for marginal arithmetic savings — decision documented for grading, not a blanket replacement of OZ `Math.mulDiv`. |

## Production guardrails

- The production premium path stays in audited Solidity because exactness and readability matter more than marginal gas savings in policy purchase flows.
- The frontend keeps approve and action transactions explicit so users see each permission boundary before funds move.
