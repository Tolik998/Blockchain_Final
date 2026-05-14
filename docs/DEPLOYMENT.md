# ShieldFi deployment guide

## Arbitrum Sepolia

1. Install dependencies:

```bash
npm install
npm install --prefix apps/web
npm install --prefix subgraph
```

2. Configure `.env` from `.env.example`:

```bash
PRIVATE_KEY=0x...
ARB_SEPOLIA_RPC_URL=https://sepolia-rollup.arbitrum.io/rpc
ETHERSCAN_API_KEY=...
COLLATERAL_ASSET=0x...
CHAINLINK_AGGREGATOR=0x...
TIMELOCK_MIN_DELAY_SECONDS=86400
ORACLE_HEARTBEAT_SECONDS=3600
TREASURY_FEE_BPS=500
ANNUAL_PREMIUM_BPS=800
```

3. Build and test before broadcast:

```bash
forge build
forge test
forge coverage --report summary
slither . --config-file slither.config.json
```

4. Deploy:

```bash
forge script script/DeployShieldFi.s.sol:DeployShieldFi \
  --rpc-url $ARB_SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

5. Verify deployment wiring:

```bash
cast call $VAULT "asset()(address)" --rpc-url $ARB_SEPOLIA_RPC_URL
cast call $POLICY_MANAGER "claimProcessor()(address)" --rpc-url $ARB_SEPOLIA_RPC_URL
cast call $TREASURY "timelock()(address)" --rpc-url $ARB_SEPOLIA_RPC_URL
cast call $TIMELOCK "hasRole(bytes32,address)(bool)" \
  $(cast keccak "PROPOSER_ROLE") $GOVERNOR \
  --rpc-url $ARB_SEPOLIA_RPC_URL
```

6. Configure frontend:

```bash
VITE_COLLATERAL_ADDRESS=0x...
VITE_VAULT_ADDRESS=0x...
VITE_POLICY_MANAGER_ADDRESS=0x...
VITE_CLAIM_PROCESSOR_ADDRESS=0x...
VITE_GOVERNOR_ADDRESS=0x...
VITE_GOV_TOKEN_ADDRESS=0x...
npm run frontend:build
```

7. Configure subgraph:

Replace the zero placeholder addresses in `subgraph/subgraph.yaml` with deployed addresses and set each `startBlock` to the deployment block. Then run:

```bash
npm run build --prefix subgraph
npm run deploy --prefix subgraph
```
