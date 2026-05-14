import { useState } from 'react';
import { parseUnits } from 'viem';
import { useAccount, useReadContract, useWriteContract } from 'wagmi';
import { arbitrumSepolia } from 'wagmi/chains';

import { CONTRACTS, erc20Abi, isConfigured, policyAbi } from '../config/contracts';
import { formatTxError } from '../lib/errors';

function tryParseUnits(value: string, decimals: number): bigint | undefined {
  try {
    if (!value || Number(value) <= 0) return undefined;
    return parseUnits(value, decimals);
  } catch {
    return undefined;
  }
}

export function BuyPage() {
  const { address } = useAccount();
  const [coverage, setCoverage] = useState('100000');
  const [days, setDays] = useState('30');
  const [trigger, setTrigger] = useState('150000000000');
  const [above, setAbove] = useState(true);
  const [err, setErr] = useState<string | null>(null);

  const { data: decimals } = useReadContract({
    address: CONTRACTS.collateral,
    abi: erc20Abi,
    functionName: 'decimals',
    query: { enabled: isConfigured(CONTRACTS.collateral) },
  });

  const durationSeconds = Number(days) * 86400;
  const cov = tryParseUnits(coverage, Number(decimals ?? 6));
  const validDuration = Number.isInteger(durationSeconds) && durationSeconds >= 3600 && durationSeconds <= 365 * 86400;

  const { data: premium } = useReadContract({
    address: CONTRACTS.policy,
    abi: policyAbi,
    functionName: 'computePremium',
    args: cov && validDuration ? [cov, durationSeconds] : undefined,
    query: {
      enabled: isConfigured(CONTRACTS.policy) && cov !== undefined && validDuration,
    },
  });

  const { writeContractAsync, isPending } = useWriteContract();

  async function buy() {
    setErr(null);
    try {
      if (!address) throw new Error('Connect wallet');
      if (!isConfigured(CONTRACTS.collateral) || !isConfigured(CONTRACTS.policy)) {
        throw new Error('Configure collateral and policy addresses first');
      }
      if (!cov || !validDuration || !premium) throw new Error('Enter a valid coverage and duration');
      const triggerPrice = BigInt(trigger);
      await writeContractAsync({
        chain: arbitrumSepolia,
        account: address,
        address: CONTRACTS.collateral,
        abi: erc20Abi,
        functionName: 'approve',
        args: [CONTRACTS.policy, premium],
      });
      await writeContractAsync({
        chain: arbitrumSepolia,
        account: address,
        address: CONTRACTS.policy,
        abi: policyAbi,
        functionName: 'purchasePolicy',
        args: [cov, durationSeconds, triggerPrice, above],
      });
    } catch (e) {
      setErr(formatTxError(e));
    }
  }

  return (
    <div className="space-y-6 max-w-xl">
      <h1 className="text-2xl font-bold">Buy insurance</h1>
      <div className="glass p-6 space-y-4 text-sm">
        <div>
          <label className="text-xs text-slate-400">Coverage (token units)</label>
          <input className="w-full mt-1 bg-night-800 border border-night-700 rounded-lg px-3 py-2" value={coverage} onChange={(e) => setCoverage(e.target.value)} />
        </div>
        <div>
          <label className="text-xs text-slate-400">Duration (days)</label>
          <input className="w-full mt-1 bg-night-800 border border-night-700 rounded-lg px-3 py-2" value={days} onChange={(e) => setDays(e.target.value)} />
        </div>
        <div>
          <label className="text-xs text-slate-400">Trigger price (1e8)</label>
          <input className="w-full mt-1 bg-night-800 border border-night-700 rounded-lg px-3 py-2" value={trigger} onChange={(e) => setTrigger(e.target.value)} />
        </div>
        <label className="flex items-center gap-2 text-slate-300">
          <input type="checkbox" checked={above} onChange={(e) => setAbove(e.target.checked)} />
          Trigger when oracle is above threshold
        </label>
        <p className="text-slate-400">
          Quoted premium: <span className="text-accent font-mono">{premium?.toString() ?? '—'}</span>
        </p>
        <button
          type="button"
          disabled={isPending || !cov || !validDuration || !premium}
          onClick={() => void buy()}
          className="w-full py-2 rounded-lg bg-accent text-night-950 font-semibold disabled:opacity-40"
        >
          {isPending ? 'Submitting…' : 'Approve + purchase'}
        </button>
        {err ? <p className="text-red-400">{err}</p> : null}
      </div>
    </div>
  );
}
