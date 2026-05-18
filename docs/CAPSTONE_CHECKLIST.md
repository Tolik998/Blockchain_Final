# ShieldFi capstone checklist

## Requirements matrix

| Requirement | File | Test proof |
|-------------|------|-----------|
| ERC20 governance token with votes and permit | `contracts/token/ShieldGovToken.sol` | `MiscB.t.sol::test_govTokenName/Symbol`, `GovTokenBranchTest::test_govTokenMintNotMinterReverts`, `GovernanceFlow.t.sol::test_proposalLifecycleMintsThroughTimelock` |
| ERC4626 underwriting vault | `contracts/vault/InsuranceVault.sol` | `ProtocolCore::test_aliceDepositMintsShares`, `FuzzSuite::testFuzz_depositWithdrawRoundTrip`, `VaultInvariant::invariant_vaultSolvent` |
| Policy purchase lifecycle | `contracts/policy/PolicyManager.sol` | `ProtocolCore::test_purchasePolicyRoutesFees`, `SuiteA::test_policyAnnualBps`, `FuzzSuite::testFuzz_policyIdIncrements` |
| Chainlink oracle claims | `contracts/claims/ClaimProcessor.sol` | `ProtocolCore::test_staleOracleReverts`, `SuiteA::test_badOracleAnswerReverts`, `CoverageBoost::test_claimIncompleteRound` |
| Double-claim prevention | `contracts/policy/PolicyManager.sol` | `ProtocolCore::test_doubleClaimReverts` |
| Timelock-owned treasury | `contracts/treasury/ProtocolTreasury.sol` | `TreasuryCoverageTest::test_treasuryWithdrawERC20HappyPath`, `test_treasuryWithdrawERC20RevertsNonTimelock` |
| DAO governance | `contracts/governance/ShieldProtocolGovernor.sol` | `GovernanceFlow::test_proposalLifecycleMintsThroughTimelock`, `test_cannotProposeWithoutVotes` |
| UUPS upgradeability | `InsuranceVault.sol`, `PolicyManager.sol`, `ClaimProcessor.sol` | `SuiteA::test_upgradeVaultToV2`, `EdgeCaseCoverageTest::test_vaultV2VersionReturns2` |
| Upgrade demonstration V1→V2 | `contracts/vault/InsuranceVaultV2.sol` | `SuiteA::test_upgradeVaultToV2`, `EdgeCaseCoverageTest::test_vaultV2SetFeeBpsStores` |
| CREATE and CREATE2 factory | `contracts/factory/PoolFactory.sol` | `ProtocolCore::test_poolFactoryCreate`, `test_poolFactoryCreate2Predict` |
| Vulnerable + fixed lesson contracts | `contracts/lessons/*` | `Lessons.t.sol` — 6 tests covering reentrancy drain and mint-access bypass |
| Fuzz tests | `test/FuzzSuite.t.sol`, `test/SuiteA.t.sol` | 14 `testFuzz_*` functions |
| Invariant tests | `test/invariant/VaultInvariant.t.sol` | 5 invariants × 256 runs × 128k calls each |
| Arbitrum Sepolia readiness | `script/DeployShieldFi.s.sol`, `test/ForkArbSepolia.t.sol` | Fork tests validate chain id 421614, block advancement, ERC20 deployment |
| Frontend integration | `apps/web/src/` | Wagmi + RainbowKit, guarded writes, typed contracts; Analytics page queries subgraph live |
| Subgraph indexing | `subgraph/schema.graphql`, `subgraph/src/mapping.ts` | 5 entity types: VaultDeposit, VaultWithdraw, PolicyPurchase, ClaimProcessed, TreasuryWithdraw |
| Security reporting | `audits/SECURITY_AUDIT_REPORT.md`, `slither.config.json` | 4 findings (all Low/Informational), Slither gate on CI |
| Gas optimization analysis | `contracts/math/GasOptimizedMath.sol`, `docs/GAS_OPTIMIZATION_REPORT.md` | `SuiteA::test_gas_mulDivBenchmarkRecordsUsage`, fuzz equivalence |
| CI pipeline | `.github/workflows/shieldfi-ci.yml` | forge build + test + coverage + solhint + Slither (High/Medium gate) + web build |

---

## Coverage targets

| Contract | Target | Notes |
|----------|--------|-------|
| `InsuranceVault.sol` | ≥ 90% | Boosted by `VaultBranchCoverageTest` |
| `PolicyManager.sol` | ≥ 90% | Boosted by `PolicyManagerBranchTest` |
| `ClaimProcessor.sol` | ≥ 90% | Boosted by `ClaimProcessorBranchTest` |
| `ProtocolTreasury.sol` | ≥ 90% | Boosted by `TreasuryCoverageTest` |
| `ShieldGovToken.sol` | ≥ 90% | Boosted by `GovTokenBranchTest` |
| `InsuranceVaultV2.sol` | 100% | Covered in `EdgeCaseCoverageTest` |
| `PoolFactory.sol` | 100% | `ProtocolCore` tests |
| Total | **≥ 90%** | |

---

## Presentation risks and mitigations

| Risk | Mitigation |
|------|-----------|
| Foundry unavailable on grader machine | `foundryup` takes 30s; instructions in README |
| Subgraph placeholder addresses | Replace `0x000...` in `subgraph/subgraph.yaml` after deployment and set `startBlock` |
| WalletConnect demo project id | Use a real `VITE_WALLETCONNECT_PROJECT_ID` for live UI demo |
| Empty vault at demo time | Run vault seed before demo: `cast send $VAULT ...` |
| Oracle heartbeat mismatch | Verify deployed Chainlink feed heartbeat matches `ORACLE_HEARTBEAT_SECONDS` |
| slither.config.json encoding | Save as UTF-8 **without BOM** — Windows editors add BOM which breaks Slither |

---

## Likely professor questions

| Question | Answer anchor |
|----------|--------------|
| Why split PolicyManager and ClaimProcessor? | Separates oracle-parsing risk surface from policy state transitions; `ClaimProcessor` can be upgraded without touching policy accounting |
| How are treasury funds protected? | `ProtocolTreasury` only accepts `msg.sender == timelock`; any withdrawal must pass through a Governor proposal queued via `TimelockController` |
| What prevents double claims? | `consumeClaim` checks `active && !claimed`, marks `claimed=true; active=false` **before** calling `vault.payout` (strict CEI) |
| What happens if Chainlink is stale? | `_readOracle` reverts `StaleOracle` if `block.timestamp - updatedAt > heartbeatSeconds` or if `updatedAt > block.timestamp` |
| How do you demonstrate UUPS upgrades? | `test_upgradeVaultToV2` upgrades the proxy to V2, calls `setProtocolFeeBps`, verifies storage layout is preserved |
| What is the ERC4626 inflation attack risk? | OZ virtual-offset mitigates it by default; README documents seed deposit best practice |
| Why use block-based Governor timing on Arbitrum? | ERC20Votes default clock is block-number; deployment script encodes Arbitrum-approximate block windows (2s/block) |
| What does the Yul benchmark prove? | Documents the gas trade-off between overflow-safe Solidity `Math.mulDiv` and a hand-written assembly path for bounded inputs; production still uses the safe path |

---

## File change log (fixes applied in this version)

| File | Change | Reason |
|------|--------|--------|
| `contracts/vault/InsuranceVault.sol` | `_authorizeUpgrade` → `internal view override` | Remove Solidity compiler warning 2018 |
| `contracts/policy/PolicyManager.sol` | Same | Same |
| `contracts/claims/ClaimProcessor.sol` | Same | Same |
| `slither.config.json` | Remove UTF-16 BOM | Slither `filter_paths` was interpreted as a list instead of a string, causing crash |
| `apps/web/vite.config.ts` | Add `manualChunks` + `chunkSizeWarningLimit` | Remove build warnings about large chunks |
| `.github/workflows/shieldfi-ci.yml` | Add TypeScript check + coverage gate + cache key fix | Enforce type safety and coverage regression in CI |
| `test/CoverageBoost.t.sol` | **New file — 88 tests** | Raise total line coverage from 74% to ≥90% |
