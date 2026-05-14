# ShieldFi capstone checklist

| Requirement | File | Proof |
| --- | --- | --- |
| ERC20 governance token with votes and permit | `contracts/token/ShieldGovToken.sol` | Inherits `ERC20Votes` and `ERC20Permit`; minting restricted to timelock minter. |
| ERC4626 underwriting vault | `contracts/vault/InsuranceVault.sol` | Inherits `ERC4626Upgradeable`; deposits, mints, withdrawals, and redeems are paused and non-reentrant. |
| Policy purchase lifecycle | `contracts/policy/PolicyManager.sol` | Computes premiums, routes treasury fees, records coverage, expiration, and trigger parameters. |
| Chainlink oracle claims | `contracts/claims/ClaimProcessor.sol` | Reads `AggregatorV3Interface`, rejects bad, incomplete, stale, and future-dated oracle rounds. |
| Double-claim prevention | `contracts/policy/PolicyManager.sol` | `consumeClaim` marks claimed and inactive before vault payout. |
| Timelock-owned treasury | `contracts/treasury/ProtocolTreasury.sol` | ERC20/native withdrawals require `msg.sender == timelock`; deployment sets timelock address. |
| DAO governance | `contracts/governance/ShieldProtocolGovernor.sol` | Governor uses votes, quorum fraction, proposal threshold, and `GovernorTimelockControl`. |
| UUPS upgradeability | `InsuranceVault.sol`, `PolicyManager.sol`, `ClaimProcessor.sol` | `_authorizeUpgrade` is role-gated and rejects zero implementation addresses. |
| Upgrade demonstration | `contracts/vault/InsuranceVaultV2.sol`, `test/SuiteA.t.sol` | V2 appends `protocolFeeBps`; test upgrades proxy and uses new setter. |
| CREATE and CREATE2 | `contracts/factory/PoolFactory.sol` | Factory deploys policy pools with both normal and deterministic deployment. |
| Vulnerable and fixed lessons | `contracts/lessons/*`, `test/Lessons.t.sol` | Reentrancy and mint-access examples are isolated from production gate. |
| Fuzz and invariant coverage | `test/FuzzSuite.t.sol`, `test/invariant/VaultInvariant.t.sol` | Fuzzes deposits, policies, oracle windows; invariants cover vault solvency and share accounting. |
| Arbitrum Sepolia readiness | `script/DeployShieldFi.s.sol`, `test/ForkArbSepolia.t.sol` | Deployment script reads Arbitrum env vars; fork test validates chain id 421614. |
| Frontend integration | `apps/web/src` | Wagmi/RainbowKit configured for Arbitrum Sepolia with guarded contract writes and readable errors. |
| Subgraph indexing | `subgraph/schema.graphql`, `subgraph/src/mapping.ts` | Indexes vault deposits/withdrawals, policy purchases, claims, and treasury withdrawals. |
| Security reporting | `audits/SECURITY_AUDIT_REPORT.md`, `slither.config.json` | Production Slither gate excludes mocks, tests, scripts, dependencies, and vulnerable lessons. |

## Presentation risks

| Risk | Mitigation |
| --- | --- |
| Foundry unavailable on grader machine | Install Foundry with `foundryup`, then run `forge build`, `forge test`, and `forge coverage --report summary`. |
| Subgraph placeholder addresses | Replace zero addresses in `subgraph/subgraph.yaml` after deployment and use deployment block numbers. |
| WalletConnect demo project id | Use a real `VITE_WALLETCONNECT_PROJECT_ID` for live frontend presentation. |
| Empty vault ERC4626 donation optics | Seed vault liquidity before policy sales and explain OZ virtual-offset mitigation. |
| Oracle feed selection | Use an Arbitrum Sepolia Chainlink-compatible feed with documented heartbeat. |

## Likely professor questions

| Question | Answer anchor |
| --- | --- |
| Why split policy and claim logic? | `ClaimProcessor` isolates oracle and payout orchestration while `PolicyManager` owns policy state transitions. |
| How are treasury funds protected? | `ProtocolTreasury` only allows the timelock to withdraw; governor proposals queue through `TimelockController`. |
| What prevents double claims? | `consumeClaim` checks active/unclaimed, then marks claimed and inactive before payout. |
| What happens if Chainlink is stale? | `ClaimProcessor._readOracle` reverts with `StaleOracle`. |
| How do you demonstrate upgrades? | `SuiteA.t.sol::test_upgradeVaultToV2` upgrades the vault proxy to `InsuranceVaultV2`. |
