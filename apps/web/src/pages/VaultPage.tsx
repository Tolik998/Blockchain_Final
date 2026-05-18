import { useEffect, useState } from 'react';
import { parseUnits } from 'viem';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';

import { CONTRACTS, erc20Abi, isConfigured, vaultAbi } from '../config/contracts';
import { formatTxError } from '../lib/errors';

export function VaultPage() {
  const { address } = useAccount();
  const [assets, setAssets] = useState('1000');
  const [err, setErr] = useState<string | null>(null);

  const { data: decimals } = useReadContract({
    address: CONTRACTS.collateral,
    abi: erc20Abi,
    functionName: 'decimals',
    query: { enabled: isConfigured(CONTRACTS.collateral) },
  });

  const { data: bal } = useReadContract({
    address: CONTRACTS.collateral,
    abi: erc20Abi,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: { enabled: !!address && isConfigured(CONTRACTS.collateral) },
  });

  const { data: shareBal } = useReadContract({
    address: CONTRACTS.vault,
    abi: vaultAbi,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
    query: { enabled: !!address && isConfigured(CONTRACTS.vault) },
  });

  const { writeContractAsync, data: hash, isPending, reset } = useWriteContract();
  const { isLoading: confirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  useEffect(() => {
    if (isSuccess) reset();
  }, [isSuccess, reset]);

  async function approveAndDeposit() {
    setErr(null);
    try {
      if (!address) throw new Error('Connect wallet');
      if (!isConfigured(CONTRACTS.collateral) || !isConfigured(CONTRACTS.vault)) {
        throw new Error('Configure collateral and vault addresses first');
      }
      const d = Number(decimals ?? 6);
      const amount = parseUnits(assets, d);
      await writeContractAsync({
        address: CONTRACTS.collateral,
        abi: erc20Abi,
        functionName: 'approve',
        args: [CONTRACTS.vault, amount],
      });
      await writeContractAsync({
        address: CONTRACTS.vault,
        abi: vaultAbi,
        functionName: 'deposit',
        args: [amount, address],
      });
    } catch (e) {
      setErr(formatTxError(e));
    }
  }

  async function withdrawAll() {
    setErr(null);
    try {
      if (!address || !shareBal) throw new Error('Nothing to withdraw');
      if (!isConfigured(CONTRACTS.vault)) throw new Error('Configure vault address first');
      await writeContractAsync({
        address: CONTRACTS.vault,
        abi: vaultAbi,
        functionName: 'redeem',
        args: [shareBal, address, address],
      });
    } catch (e) {
      setErr(formatTxError(e));
    }
  }

  const d = Number(decimals ?? 6);
  const fmtBal = bal !== undefined ? (Number(bal) / 10 ** d).toFixed(2) : '—';
  const fmtShares = shareBal !== undefined ? (Number(shareBal) / 10 ** d).toFixed(6) : '—';

  return (
    <div className="space-y-6 max-w-xl">
      <h1 className="text-2xl font-bold">Vault</h1>
      <p className="text-slate-400 text-sm">
        Deposit collateral to mint ERC4626 shares. Premiums routed into the vault appreciate share price for
        underwriters.
      </p>
      <div className="glass p-6 space-y-4">
        <div>
          <label className="block text-xs uppercase tracking-wide text-slate-400 mb-1">Collateral balance</label>
          <p className="font-mono text-sm">{fmtBal}</p>
        </div>
        <div>
          <label className="block text-xs uppercase tracking-wide text-slate-400 mb-1">Vault shares</label>
          <p className="font-mono text-sm">{fmtShares}</p>
        </div>
        <div>
          <label className="block text-xs uppercase tracking-wide text-slate-400 mb-1">Deposit amount</label>
          <input
            className="w-full bg-night-800 border border-night-700 rounded-lg px-3 py-2 text-sm"
            value={assets}
            onChange={(e) => setAssets(e.target.value)}
          />
        </div>
        <button
          type="button"
          disabled={isPending || confirming}
          onClick={() => void approveAndDeposit()}
          className="w-full py-2 rounded-lg bg-accent text-night-950 font-semibold disabled:opacity-40"
        >
          {isPending || confirming ? 'Submitting…' : 'Approve + deposit'}
        </button>
        <button
          type="button"
          disabled={isPending || confirming || !shareBal}
          onClick={() => void withdrawAll()}
          className="w-full py-2 rounded-lg border border-night-600 text-sm"
        >
          Redeem all shares
        </button>
        {err ? <p className="text-red-400 text-sm">{err}</p> : null}
      </div>
    </div>
  );
}
