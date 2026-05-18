import { useAccount } from 'wagmi';
import { CONTRACTS } from '../config/contracts';

function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="glass p-6">
      <h2 className="text-lg font-semibold mb-3 text-slate-100">{title}</h2>
      <div className="text-sm text-slate-300 leading-relaxed">{children}</div>
    </section>
  );
}

export function Dashboard() {
  const { address, isConnected } = useAccount();
  const configured =
    CONTRACTS.vault !== '0x0000000000000000000000000000000000000000' &&
    CONTRACTS.collateral !== '0x0000000000000000000000000000000000000000';

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">ShieldFi Control Center</h1>
        <p className="text-slate-400 mt-2 max-w-2xl">
          Underwriters supply ERC20 collateral into an ERC4626 vault, buyers pay premiums for parametric policies, and
          Chainlink-backed claim checks route payouts through a timelocked governance perimeter.
        </p>
      </div>
      {!configured ? (
        <div className="rounded-xl border border-amber-500/40 bg-amber-500/10 px-4 py-3 text-amber-100 text-sm">
          Set <code className="text-amber-50">VITE_*</code> addresses in <code className="text-amber-50">apps/web/.env</code>{' '}
          after deployment so the UI can submit transactions to your deployed contracts.
        </div>
      ) : null}
      <div className="grid md:grid-cols-2 gap-4">
        <Card title="Wallet">
          {isConnected ? (
            <p>
              Connected as <span className="text-accent font-mono text-xs break-all">{address}</span>
            </p>
          ) : (
            <p>Connect a wallet with MetaMask or WalletConnect to begin.</p>
          )}
        </Card>
        <Card title="Protocol posture">
          <ul className="list-disc pl-5 space-y-1">
            <li>OpenZeppelin UUPS core contracts with pausable entrypoints</li>
            <li>Timelock-only treasury movements for fee segregation</li>
            <li>Governor + ERC20Votes for parameter and upgrade control</li>
          </ul>
        </Card>
      </div>
    </div>
  );
}
