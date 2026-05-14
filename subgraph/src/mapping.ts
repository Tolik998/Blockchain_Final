import { Deposit as DepositEvent, Withdraw as WithdrawEvent } from '../generated/InsuranceVault/VaultAbi';
import { PolicyPurchased as PolicyPurchasedEvent } from '../generated/PolicyManager/PolicyAbi';
import { ClaimProcessed as ClaimProcessedEvent } from '../generated/ClaimProcessor/ClaimAbi';
import { Withdrawn as WithdrawnEvent } from '../generated/ProtocolTreasury/TreasuryAbi';
import { VaultDeposit, VaultWithdraw, PolicyPurchase, ClaimProcessed, TreasuryWithdraw } from '../generated/schema';

export function handleVaultDeposit(event: DepositEvent): void {
  let id = event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString();
  let e = new VaultDeposit(id);
  e.vault = event.address;
  e.sender = event.params.sender;
  e.owner = event.params.owner;
  e.assets = event.params.assets;
  e.shares = event.params.shares;
  e.blockNumber = event.block.number;
  e.timestamp = event.block.timestamp;
  e.txHash = event.transaction.hash;
  e.save();
}

export function handleVaultWithdraw(event: WithdrawEvent): void {
  let id = event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString();
  let e = new VaultWithdraw(id);
  e.vault = event.address;
  e.sender = event.params.sender;
  e.receiver = event.params.receiver;
  e.owner = event.params.owner;
  e.assets = event.params.assets;
  e.shares = event.params.shares;
  e.blockNumber = event.block.number;
  e.timestamp = event.block.timestamp;
  e.txHash = event.transaction.hash;
  e.save();
}

export function handlePolicyPurchased(event: PolicyPurchasedEvent): void {
  let id = event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString();
  let e = new PolicyPurchase(id);
  e.policyId = event.params.policyId;
  e.buyer = event.params.buyer;
  e.coverage = event.params.coverage;
  e.premium = event.params.premium;
  e.expiration = event.params.expiration;
  e.blockNumber = event.block.number;
  e.timestamp = event.block.timestamp;
  e.txHash = event.transaction.hash;
  e.save();
}

export function handleClaimProcessed(event: ClaimProcessedEvent): void {
  let id = event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString();
  let e = new ClaimProcessed(id);
  e.policyId = event.params.policyId;
  e.beneficiary = event.params.beneficiary;
  e.payout = event.params.payout;
  e.oraclePrice = event.params.oraclePrice;
  e.blockNumber = event.block.number;
  e.timestamp = event.block.timestamp;
  e.txHash = event.transaction.hash;
  e.save();
}

export function handleTreasuryWithdraw(event: WithdrawnEvent): void {
  let id = event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString();
  let e = new TreasuryWithdraw(id);
  e.treasury = event.address;
  e.token = event.params.token;
  e.to = event.params.to;
  e.amount = event.params.amount;
  e.blockNumber = event.block.number;
  e.timestamp = event.block.timestamp;
  e.txHash = event.transaction.hash;
  e.save();
}
