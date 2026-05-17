# ShieldFi gas optimization report

## Methodology

Gas measurements use Foundry `gasleft()` deltas in `test/SuiteA.t.sol` and `forge test --gas-report`
for tabular summaries. Optimizer is enabled (`optimizer_runs = 200`, `via_ir = false`) in
`foundry.toml`. Measurements below were collected on a local EVM (Cancun hardfork).

---

## Optimizations shipped

### 1. Custom Yul `mulDiv` for premium arithmetic

`GasOptimizedMath.premiumMulDivYul` computes `(coverage * rateBps * duration) / (10000 * year)` with
inline assembly `mul` + `div`, avoiding the full overflow-safe path of OZ `Math.mulDiv` for inputs
known to be bounded (test suite enforces this via `vm.assume`).

**Fuzz equivalence gate:** `testFuzz_premiumMathMatches` runs 256 rounds and asserts both paths
return identical results across the bounded input space.

**Trade-off:** The Yul path is more brittle for large inputs. The *production* premium computation
inside `PolicyManager.computePremium` intentionally uses the safe Solidity path for auditability.

### 2. UUPS proxies over Transparent proxies

Each UUPS proxy removes the admin slot and the extra `ifAdmin` branch on every call, saving
~2,100 gas per non-upgrade call compared to OZ `TransparentUpgradeableProxy`.

### 3. Packed storage slots

| Contract | Slot | Contents |
|----------|------|----------|
| `InsuranceVault` | slot N | `uint128 totalPayouts` |
| `InsuranceVaultV2` | slot N | `uint128 protocolFeeBps` + `uint128 __reserved` (same slot) |
| `PolicyManager.Policy` | packed struct | `address buyer`, `uint48 purchasedAt`, `uint48 expiresAt`, `bool × 3` — fits in 2 slots |
| `PolicyManager` | state | `uint256 nextPolicyId`, `uint16 treasuryFeeBps`, `uint16 annualPremiumBps` |

### 4. Minimal external calls in hot paths

`ClaimProcessor.processClaim` reads the oracle once (`latestRoundData`), does a balance check,
then delegates to `PolicyManager.consumeClaim` which performs all state transitions atomically.
No repeated external storage reads.

### 5. Custom errors over `require` strings

All revert paths use custom errors (`revert ZeroAddress()` etc.), saving ~200–500 gas per revert
versus string-encoded `require` by omitting ABI encoding of the revert reason bytes.

### 6. `SafeERC20` over raw `transfer`

`SafeERC20.safeTransfer` is slightly more expensive than a direct `transfer` call but prevents
silent failures on non-standard ERC20 tokens (USDT, etc.). The correctness guarantee outweighs
the ~300 gas overhead per transfer.

---

## Benchmark snapshot (local, optimizer runs = 200)

| Test | Gas used | Notes |
|------|----------|-------|
| `test_gas_mulDivBenchmarkRecordsUsage` | see output | Records both paths with `gasleft()` delta |
| `test_aliceDepositMintsShares` | ~112k | ERC4626 deposit with SafeERC20 |
| `test_claimPaysBuyer` | ~408k | Full claim path: oracle + consumeClaim + payout |
| `test_upgradeVaultToV2` | ~2.2M | UUPS upgrade (proxy storage write) |
| `test_proposalLifecycleMintsThroughTimelock` | ~340k | Full governance round-trip |

Run `forge test --gas-report` locally for a complete function-level table.

---

## Production guardrails

- The premium arithmetic stays in audited Solidity inside `PolicyManager`; the Yul version is a
  teaching benchmark only.
- `via_ir = false` is kept for predictable stack usage and simpler auditing. Coverage mode
  automatically disables optimizer for accurate branch tracking.
- The frontend sends approve and deposit/purchase as separate transactions so users can review
  each permission boundary before funds move.

---

## Recommended future improvements

| Improvement | Estimated saving | Risk |
|-------------|-----------------|------|
| Batch oracle + claim in one call via multicall | ~5k gas/claim | Low |
| Use `uint96` for coverage amounts (fits in struct with other fields) | ~1 slot saved | Low |
| Enable `via_ir = true` with `optimizer_runs = 1000` for mainnet | varies | Review storage layout |
