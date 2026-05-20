import { useState } from 'react';
import { useAccount, useReadContract, useWriteContract } from 'wagmi';
import { sepolia } from 'wagmi/chains';

import { CONTRACTS, governorAbi, isConfigured, votesAbi } from '../config/contracts';
import { formatTxError } from '../lib/errors';

function tryParseBigInt(value: string): bigint | undefined {
  try {
    if (!value) return undefined;
    return BigInt(value);
  } catch {
    return undefined;
  }
}

export function GovernancePage() {
  const { address } = useAccount();
  const [proposalId, setProposalId] = useState('1');
  const [err, setErr] = useState<string | null>(null);

  const pid = tryParseBigInt(proposalId);

  const { data: state } = useReadContract({
    address: CONTRACTS.governor,
    abi: governorAbi,
    functionName: 'state',
    args: pid !== undefined ? [pid] : undefined,
    query: { enabled: isConfigured(CONTRACTS.governor) && pid !== undefined },
  });

  const { data: votes } = useReadContract({
    address: CONTRACTS.govToken,
    abi: votesAbi,
    functionName: 'getVotes',
    args: address ? [address] : undefined,
    query: { enabled: !!address && isConfigured(CONTRACTS.govToken) },
  });

  const { writeContractAsync, isPending } = useWriteContract();

  async function delegateSelf() {
    setErr(null);

    try {
      if (!address) throw new Error('Connect wallet');
      if (!isConfigured(CONTRACTS.govToken)) {
        throw new Error('Configure governance token address first');
      }

      await writeContractAsync({
        chain: sepolia,
        account: address,
        address: CONTRACTS.govToken,
        abi: votesAbi,
        functionName: 'delegate',
        args: [address],
      });
    } catch (e) {
      setErr(formatTxError(e));
    }
  }

  async function castYes() {
    setErr(null);

    try {
      if (!address) throw new Error('Connect wallet');
      if (!isConfigured(CONTRACTS.governor)) {
        throw new Error('Configure governor address first');
      }
      if (pid === undefined) throw new Error('Enter a valid proposal id');

      await writeContractAsync({
        chain: sepolia,
        account: address,
        address: CONTRACTS.governor,
        abi: governorAbi,
        functionName: 'castVote',
        args: [pid, 1],
      });
    } catch (e) {
      setErr(formatTxError(e));
    }
  }

  const labels = ['Pending', 'Active', 'Canceled', 'Defeated', 'Succeeded', 'Queued', 'Expired', 'Executed'];

  return (
    <div className="space-y-6 max-w-xl">
      <h1 className="text-2xl font-bold">Governance</h1>

      <div className="glass p-6 space-y-4 text-sm">
        <p className="text-slate-400">
          Voting power: <span className="text-accent font-mono">{votes?.toString() ?? '—'}</span>
        </p>

        <button
          type="button"
          disabled={isPending || !address}
          className="w-full py-2 rounded-lg border border-night-600 disabled:opacity-40"
          onClick={() => void delegateSelf()}
        >
          {isPending ? 'Submitting…' : 'Delegate to self'}
        </button>

        <div>
          <label className="text-xs text-slate-400">Proposal id</label>
          <input
            className="w-full mt-1 bg-night-800 border border-night-700 rounded-lg px-3 py-2"
            value={proposalId}
            onChange={(e) => setProposalId(e.target.value)}
          />
        </div>

        <p>
          State:{' '}
          <span className="font-mono text-accent">
            {state !== undefined ? `${state} (${labels[Number(state)] ?? 'unknown'})` : '—'}
          </span>
        </p>

        <button
          type="button"
          disabled={isPending || pid === undefined || !address}
          onClick={() => void castYes()}
          className="w-full py-2 rounded-lg bg-accent text-night-950 font-semibold disabled:opacity-40"
        >
          {isPending ? 'Submitting…' : 'Cast vote (yes)'}
        </button>

        {err ? <p className="text-red-400">{err}</p> : null}
      </div>
    </div>
  );
}