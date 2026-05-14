# ShieldFi subgraph

Indexes underwriting vault flows, policy purchases, claim payouts, and timelock treasury withdrawals on Arbitrum Sepolia.

## Setup

1. Update contract addresses and `startBlock` in `subgraph.yaml`.
2. Install tooling:

```bash
npm install
npm run codegen
npm run build
```

3. Deploy to The Graph Studio / hosted service using your access token.

## Governance proposals

`ShieldProtocolGovernor` emits OpenZeppelin `ProposalCreated` with dynamic array parameters. To index governance in production, add an additional data source with the full governor ABI from `forge build` artifacts and extend `src/mapping.ts`.

## Queries

See `queries.graphql` for five ready-made GraphQL queries used by the analytics page.
