import { parseAbi } from 'viem';

const zero = '0x0000000000000000000000000000000000000000' as const;
export const ZERO_ADDRESS = zero;

function addr(key: string): `0x${string}` {
  const v = (import.meta.env as Record<string, string | undefined>)[key];
  if (v && v.startsWith('0x') && v.length === 42) return v as `0x${string}`;
  return zero;
}

export const CONTRACTS = {
  collateral: addr('VITE_COLLATERAL_ADDRESS'),
  vault: addr('VITE_VAULT_ADDRESS'),
  policy: addr('VITE_POLICY_MANAGER_ADDRESS'),
  claim: addr('VITE_CLAIM_PROCESSOR_ADDRESS'),
  governor: addr('VITE_GOVERNOR_ADDRESS'),
  govToken: addr('VITE_GOV_TOKEN_ADDRESS'),
} as const;

export function isConfigured(address: `0x${string}`): boolean {
  return address !== ZERO_ADDRESS;
}

export const vaultAbi = parseAbi([
  'function asset() view returns (address)',
  'function deposit(uint256 assets, address receiver) returns (uint256 shares)',
  'function redeem(uint256 shares, address receiver, address owner) returns (uint256 assets)',
  'function balanceOf(address account) view returns (uint256)',
  'function previewDeposit(uint256 assets) view returns (uint256)',
  'function totalAssets() view returns (uint256)',
]);

export const erc20Abi = parseAbi([
  'function approve(address spender, uint256 amount) returns (bool)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'function balanceOf(address account) view returns (uint256)',
  'function decimals() view returns (uint8)',
]);

export const policyAbi = parseAbi([
  'function purchasePolicy(uint256 coverageAmount, uint48 durationSeconds, int256 triggerPrice1e8, bool triggerAbove) returns (uint256 policyId)',
  'function computePremium(uint256 coverageAmount, uint48 durationSeconds) view returns (uint256 premium)',
]);

export const claimAbi = parseAbi(['function processClaim(uint256 policyId)']);

export const votesAbi = parseAbi([
  'function delegate(address delegatee)',
  'function getVotes(address account) view returns (uint256)',
  'function balanceOf(address account) view returns (uint256)',
]);

export const governorAbi = parseAbi([
  'function state(uint256 proposalId) view returns (uint8)',
  'function proposalSnapshot(uint256 proposalId) view returns (uint256)',
  'function proposalDeadline(uint256 proposalId) view returns (uint256)',
  'function castVote(uint256 proposalId, uint8 support)',
]);
