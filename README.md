# ShieldFi

Decentralized insurance protocol for a university capstone: ERC4626 underwriting vault, policy lifecycle, Chainlink-triggered claims, DAO governance, factory deployment patterns, and UUPS upgrades.

## Repository layout

- `contracts/` — Solidity protocol, mocks, vulnerable vs fixed teaching contracts
- `script/` — Foundry deployment and verification helpers
- `test/` — Foundry unit, fuzz, invariant, and fork tests
- `apps/web/` — React + TypeScript + Wagmi + RainbowKit frontend
- `subgraph/` — The Graph indexing layer
- `docs/` — architecture, gas, and operational documentation
- `audits/` — student security audit report template and Slither appendix
- `diagrams/` — C4 + sequence diagrams (Mermaid)

## Prerequisites

- Node.js 20+ (repo tested with Node 22)
- Foundry (`foundryup`) for `forge`, `cast`, `anvil`

## Install

```bash
npm install
```

OpenZeppelin + Chainlink are resolved from `node_modules` via `remappings.txt`.

## Build & test

```bash
forge build
forge test
forge coverage --report lcov
```

The Foundry suite currently registers **90+** unit/fuzz tests, **5** invariant tests, and **4** Arbitrum Sepolia fork tests across `test/` (coverage depends on local `forge` toolchain).

## Lint

```bash
npm run lint:sol
npm run format
```

## Slither

Slither is configured to focus on production contracts and exclude teaching/mocks from the main gate (see `slither.config.json` and `audits/SECURITY_AUDIT_REPORT.md`).

```bash
slither . --config-file slither.config.json
```

## Frontend

```bash
npm run frontend:dev
```

Copy `apps/web/.env.example` to `apps/web/.env` and set contract addresses after deployment.

## Subgraph

See `subgraph/README.md`.

## Deployment (Arbitrum Sepolia)

Set env vars from `.env.example`, then follow `docs/DEPLOYMENT.md`. The broadcast command is:

```bash
forge script script/DeployShieldFi.s.sol:DeployShieldFi --rpc-url $ARB_SEPOLIA_RPC_URL --broadcast --verify
```

## Capstone proof

`docs/CAPSTONE_CHECKLIST.md` maps each mandatory requirement to source files and verification evidence.

## License

MIT
