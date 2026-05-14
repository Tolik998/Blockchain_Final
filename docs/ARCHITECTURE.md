# ShieldFi architecture

ShieldFi is a modular Arbitrum-oriented insurance stack: an ERC4626 underwriting vault absorbs premium inflows as implicit yield, a policy registry prices parametric coverage, a Chainlink-aware claim processor settles payouts under strict CEI ordering, and a timelocked DAO controls minting, upgrades, and treasury outflows.

## C4 context (Mermaid)

```mermaid
C4Context
title ShieldFi system context
Person(underwriter, "Underwriter", "Supplies ERC20 collateral for vault shares")
Person(policyholder, "Policyholder", "Pays premiums and receives claim payouts")
Person(keeper, "Keeper / anyone", "Triggers claim checks when oracle conditions hold")
System_Boundary(shield, "ShieldFi contracts") {
  System(vault, "InsuranceVault (UUPS)", "ERC4626 + pause + claim payouts")
  System(policy, "PolicyManager (UUPS)", "Premiums, coverage, expirations")
  System(claim, "ClaimProcessor (UUPS)", "Oracle staleness + settlement orchestration")
  System(gov, "Governor + Timelock", "Parameter + upgrade control")
}
System_Ext(chainlink, "Chainlink AggregatorV3", "Reference prices")
System_Ext(collateral, "ERC20 collateral", "USDC-like test asset")
Rel(underwriter, vault, "deposit / redeem")
Rel(policyholder, policy, "purchasePolicy")
Rel(keeper, claim, "processClaim")
Rel(claim, chainlink, "latestRoundData")
Rel(policy, collateral, "transferFrom premium")
Rel(claim, vault, "payout coverage")
Rel(gov, vault, "schedule upgrade / role changes")
```

## Container view

```mermaid
flowchart LR
  subgraph Onchain
    V[InsuranceVault UUPS]
    P[PolicyManager UUPS]
    C[ClaimProcessor UUPS]
    T[ProtocolTreasury]
    G[ShieldGovToken]
    TL[TimelockController]
    GV[ShieldProtocolGovernor]
  end
  U[Users] --> V
  U --> P
  U --> C
  U --> GV
  P -->|premiums fee split| T
  P -->|net premium| V
  C -->|consumeClaim| P
  C -->|payout| V
  GV --> TL
  TL -->|mint| G
  TL -->|withdraw| T
```

## Sequence: claim settlement (happy path)

```mermaid
sequenceDiagram
  participant K as Keeper
  participant CP as ClaimProcessor
  participant O as Chainlink feed
  participant PM as PolicyManager
  participant V as InsuranceVault
  participant ERC as Collateral ERC20
  K->>CP: processClaim(policyId)
  CP->>O: latestRoundData()
  O-->>CP: price, updatedAt
  CP->>CP: staleness + round checks
  CP->>PM: getPolicy + balance checks
  CP->>PM: consumeClaim(policyId, price)
  PM-->>CP: beneficiary, payout
  CP->>V: payout(beneficiary, payout)
  V->>ERC: safeTransfer(beneficiary)
```

## Storage layout (UUPS core)

Upgradeable contracts follow OpenZeppelin namespaced ERC4626 storage plus append-only variables:

- `InsuranceVault`: OZ ERC4626 storage namespace + `totalPayouts` + `uint256[50] __gap`.
- `InsuranceVaultV2`: appends `protocolFeeBps` after parent layout (never reorder inherited slots).

Full storage dumps should be regenerated with `forge inspect <Contract> storageLayout` after each release and archived under `docs/storage-layouts/`.

## Trust assumptions

1. **Timelock + Governor** are the ultimate administrators for upgrades, role grants, and treasury withdrawals.
2. **Chainlink feeds** are correct on average but can be stale or manipulated over short horizons; the processor enforces heartbeat and positive-answer checks, not L2 sequencer uptime (add for production mainnet L2).
3. **Collateral ERC20** is non-rebasing, non-fee-on-transfer; fee-on-transfer assets require a different deposit path.
4. **Underwriters** accept ERC4626 donation/inflation risks mitigated by OZ virtual offsets and seed deposits.

## Architectural decision records (ADR)

| ADR | Decision | Rationale |
| --- | --- | --- |
| ADR-001 | UUPS for vault/policy/claim | Gas-efficient upgrades with strict `onlyRole` authorization on `_authorizeUpgrade`. |
| ADR-002 | External ClaimProcessor | Isolates oracle parsing + reentrancy surface; policy state transitions stay in one module. |
| ADR-003 | Premium split to treasury + vault | Satisfies “treasury only timelock” while letting LPs absorb yield via idle balance growth. |
| ADR-004 | Block-based Governor timing | Matches ERC20Votes default clock; deployment script encodes Arbitrum-approximate block windows. |
| ADR-005 | Intentional vulnerable contracts isolated | Pedagogical reentrancy/access flaws live under `contracts/lessons/vulnerable` and are excluded from the primary Slither gate. |

## Assignment coverage map

| Requirement | Implementation |
| --- | --- |
| ERC20Votes + Permit governance | `ShieldGovToken.sol` |
| ERC4626 vault + pause + payouts | `InsuranceVault.sol` |
| Policy lifecycle + premiums | `PolicyManager.sol` |
| Oracle claims + CEI + ReentrancyGuard | `ClaimProcessor.sol` + `PolicyManager.consumeClaim` |
| Governor + timelock + treasury isolation | `ShieldProtocolGovernor.sol`, `ProtocolTreasury.sol` |
| Chainlink staleness + mock | `ClaimProcessor.sol`, `MockAggregatorV3.sol` |
| CREATE + CREATE2 factory | `PoolFactory.sol` |
| UUPS V1/V2 | `InsuranceVault.sol`, `InsuranceVaultV2.sol` |
| Yul gas benchmark | `GasOptimizedMath.sol` + `SuiteA.t.sol` |
| Vulnerable + fixed + tests | `contracts/lessons/*`, `Lessons.t.sol` |
