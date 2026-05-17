# ShieldFi

> Decentralized parametric insurance protocol — university capstone project.

Underwriters deposit ERC20 collateral into an ERC4626 vault, buyers pay premiums for parametric policies, and Chainlink-triggered claims settle payouts through a timelocked DAO governance system.

---

## Architecture overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         ShieldFi Protocol                       │
│                                                                 │
│  Underwriter ──deposit──► InsuranceVault (ERC4626 UUPS)         │
│                                │ premium yield                  │
│  Policyholder ─purchase──► PolicyManager (UUPS)                 │
│                                │ fee split                      │
│                    ┌───────────┴───────────┐                    │
│                    │                       │                    │
│             ProtocolTreasury         InsuranceVault             │
│             (timelock-only)          (net premium)             │
│                                                                 │
│  Keeper ──processClaim──► ClaimProcessor (UUPS)                 │
│                                │                               │
│                         Chainlink Feed                          │
│                         PolicyManager.consumeClaim              │
│                         InsuranceVault.payout                   │
│                                                                 │
│  Token holders ──vote──► ShieldProtocolGovernor                 │
│                          │                                      │
│                     TimelockController                          │
│                          │                                      │
│              ┌───────────┼────────────────┐                     │
│          upgrade     mint/burn       treasury.withdraw          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Repository layout

```
├── contracts/
│   ├── claims/        ClaimProcessor.sol           — UUPS, Chainlink oracle + CEI settlement
│   ├── factory/       PoolFactory.sol, PolicyPool  — CREATE / CREATE2 demo
│   ├── governance/    ShieldProtocolGovernor.sol   — OZ Governor + timelock
│   ├── interfaces/    AggregatorV3Interface, IPolicyManager, IClaimProcessor
│   ├── lessons/
│   │   ├── vulnerable/  VulnerableEthReentrancyLesson, VulnerableMintAccessLesson
│   │   └── fixed/       FixedEthReentrancyLesson, FixedMintAccessLesson
│   ├── math/          GasOptimizedMath.sol         — mulDiv Solidity vs Yul benchmark
│   ├── mocks/         MockAggregatorV3, MockERC20  — test helpers
│   ├── policy/        PolicyManager.sol            — UUPS, premium routing, policy lifecycle
│   ├── token/         ShieldGovToken.sol           — ERC20Votes + ERC20Permit
│   ├── treasury/      ProtocolTreasury.sol         — timelock-only withdrawals
│   └── vault/         InsuranceVault.sol (V1), InsuranceVaultV2.sol — ERC4626 UUPS
├── script/
│   ├── DeployShieldFi.s.sol   — full broadcast deployment script
│   └── VerifyShieldFi.s.sol   — post-deploy verification helper
├── test/
│   ├── base/          ShieldFiBase.sol             — shared deployment fixture
│   ├── helpers/       ReentrancyAttacker, FixedReentrancyAttacker
│   ├── invariant/     VaultInvariant.t.sol         — 5 invariants, 256 runs x 128k calls
│   ├── CoverageBoost.t.sol    — 88 edge-case & branch tests
│   ├── ForkArbSepolia.t.sol   — fork tests for Arbitrum Sepolia
│   ├── FuzzSuite.t.sol        — 11 property-based fuzz tests
│   ├── GovernanceFlow.t.sol   — full proposal lifecycle test
│   ├── Lessons.t.sol          — reentrancy and access-control lesson tests
│   ├── MiscB.t.sol            — 30 configuration sanity checks
│   ├── ProtocolCore.t.sol     — 18 end-to-end integration tests
│   └── SuiteA.t.sol           — 26 math, upgrade, and oracle tests
├── apps/web/                  — React + TypeScript + Wagmi + RainbowKit frontend
├── subgraph/                  — The Graph indexing (schema, mappings, subgraph.yaml)
├── docs/                      — Architecture, deployment, gas, capstone checklist
├── audits/                    — Security audit report + Slither appendix
├── diagrams/                  — C4 context diagram (Mermaid)
├── foundry.toml
├── remappings.txt
└── slither.config.json
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | 20+ | npm deps, frontend build |
| Foundry | latest | forge build / test / coverage |
| Python 3 + pip | any | Slither static analysis (optional) |

Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

---

## Quick start

```bash
# 1. Clone
git clone https://github.com/<your-org>/shieldfi.git
cd shieldfi

# 2. Install JS dependencies (OpenZeppelin, dev tooling)
npm install

# 3. Build Solidity
forge build

# 4. Run all tests
forge test -v

# 5. Coverage report
forge coverage --report summary
```

Expected output: **190+ tests pass, 0 fail**.
Expected coverage: **>=90% lines** across production contracts.

---

## Detailed test commands

```bash
# Run specific suite
forge test --match-contract ProtocolCoreTest -v

# Run fuzz tests with more runs
forge test --match-contract FuzzSuiteTest --fuzz-runs 1000

# Run invariant tests
forge test --match-contract VaultInvariantTest -v

# Coverage with LCOV (for HTML report)
forge coverage --report lcov
genhtml lcov.info --output-directory coverage-html
open coverage-html/index.html

# Arbitrum Sepolia fork tests (requires RPC URL)
forge test --match-contract ForkArbSepoliaTest \
  --fork-url https://sepolia-rollup.arbitrum.io/rpc -v
```

---

## Lint & format

```bash
npm run lint:sol     # Solhint
forge fmt --check    # CI format check
forge fmt            # Auto-format
```

---

## Slither static analysis

```bash
pip install slither-analyzer --break-system-packages
slither . --config-file slither.config.json
```

The `slither.config.json` excludes intentionally vulnerable lesson contracts, mocks, tests, scripts, and dependencies. Production gate targets **0 High, 0 Medium** findings.

---

## Frontend

```bash
cd apps/web
cp .env.example .env          # fill VITE_* addresses after deployment
npm install
npm run dev                   # dev server -> http://localhost:5173
npm run build                 # production build (TypeScript checked)
```

The frontend connects to Arbitrum Sepolia via Wagmi + RainbowKit. If VITE_* contract addresses are not set it shows a setup banner — intentional.

---

## Deployment (Arbitrum Sepolia)

### 1. Prepare environment

```bash
cp .env.example .env
# Edit .env — required fields:
#   PRIVATE_KEY=0x...
#   COLLATERAL_ASSET=0x...     (ERC20 collateral token address)
#   CHAINLINK_AGGREGATOR=0x... (AggregatorV3-compatible feed)
#   ARB_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
#   ETHERSCAN_API_KEY=...
```

### 2. Deploy

```bash
source .env
forge script script/DeployShieldFi.s.sol:DeployShieldFi \
  --rpc-url $ARB_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

Copy printed addresses to `apps/web/.env` as `VITE_*` variables.

### 3. Seed the vault before selling policies

```bash
cast send $VAULT_ADDRESS \
  "deposit(uint256,address)" \
  1000000000000 $DEPLOYER_ADDRESS \
  --rpc-url $ARB_SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### 4. Verify deployment

```bash
forge script script/VerifyShieldFi.s.sol:VerifyShieldFi \
  --rpc-url $ARB_SEPOLIA_RPC_URL
```

---

## Subgraph

See [`subgraph/README.md`](subgraph/README.md) for full instructions.

```bash
cd subgraph
# Replace placeholder 0x000... addresses in subgraph.yaml with deployed addresses
npm install
npm run codegen
npm run build
graph deploy --studio shieldfi
```

---

## Security model

| Vector | Protection |
|--------|-----------|
| Reentrancy | `nonReentrant` on all state-changing calls + CEI ordering |
| Flash governance | ERC20Votes checkpoints + TimelockController min delay |
| Oracle manipulation | Staleness, positive-answer, incomplete-round checks |
| Double claim | `consumeClaim` marks claimed=true + active=false before payout |
| Unauthorized upgrades | `_authorizeUpgrade` is `onlyRole(UPGRADER_ROLE)` |
| Treasury drain | withdrawERC20/Native require `msg.sender == timelock` |
| ERC4626 inflation | OZ virtual share offsets; seed deposit recommended |

See [`audits/SECURITY_AUDIT_REPORT.md`](audits/SECURITY_AUDIT_REPORT.md) for the full student audit.

---

## Capstone checklist

See [`docs/CAPSTONE_CHECKLIST.md`](docs/CAPSTONE_CHECKLIST.md) for the complete mapping:
**Requirement → File → Test proof**

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `forge: command not found` | Run `foundryup` and restart terminal |
| `cannot find module '@openzeppelin'` | Run `npm install` in repo root |
| `forge coverage` — stack too deep | Use `forge coverage --ir-minimum` |
| Frontend shows "Configure addresses" | Set `VITE_*` in `apps/web/.env` after deployment |
| Slither crashes with `AttributeError: 'list'` | Ensure `slither.config.json` is saved as UTF-8 without BOM |
| Fork tests skip oracle | Set `CHAINLINK_AGGREGATOR` env var or test auto-skips cleanly |

---

## License

MIT
