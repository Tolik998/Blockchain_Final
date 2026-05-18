import { useState } from 'react';
import { useWriteContract, useAccount } from 'wagmi';

import { CONTRACTS, claimAbi, isConfigured } from '../config/contracts';
import { formatTxError } from '../lib/errors';

export function ClaimsPage() {
  const { address } = useAccount();
  const [policyId, setPolicyId] = useState('1');
  const [err, setErr] = useState<string | null>(null);
  const { writeContractAsync, isPending } = useWriteContract();

  async function submit() {
    setErr(null);
    try {
      if (!address) throw new Error('Connect wallet');
      if (!isConfigured(CONTRACTS.claim)) throw new Error('Configure claim processor address first');
      await writeContractAsync({
        address: CONTRACTS.claim,
        abi: claimAbi,
        functionName: 'processClaim',
        args: [BigInt(policyId || '0')],
      });
    } catch (e) {
      setErr(formatTxError(e));
    }
  }

  return (
    <div className="space-y-6 max-w-xl">
      <h1 className="text-2xl font-bold">Claims</h1>
      <p className="text-slate-400 text-sm">
        Anyone can call <code className="text-accent">processClaim</code> when the Chainlink feed satisfies the policy
        trigger and the vault is solvent. The processor enforces staleness checks and double-claim prevention.
      </p>
      <div className="glass p-6 space-y-4">
        <div>
          <label className="text-xs text-slate-400">Policy id</label>
          <input className="w-full mt-1 bg-night-800 border border-night-700 rounded-lg px-3 py-2" value={policyId} onChange={(e) => setPolicyId(e.target.value)} />
        </div>
        <button
          type="button"
          disabled={isPending || !policyId || policyId === '0'}
          onClick={() => void submit()}
          className="w-full py-2 rounded-lg bg-accent text-night-950 font-semibold disabled:opacity-40"
        >
          {isPending ? 'Submitting…' : 'Process claim'}
        </button>
        {err ? <p className="text-red-400 text-sm">{err}</p> : null}
      </div>
    </div>
  );
}
