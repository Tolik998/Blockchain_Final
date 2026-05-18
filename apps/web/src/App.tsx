import type { ReactNode } from 'react';
import { NavLink, Route, Routes } from 'react-router-dom';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useChainId } from 'wagmi';
import { sepolia } from "wagmi/chains";

import { Dashboard } from './pages/Dashboard';
import { VaultPage } from './pages/VaultPage';
import { BuyPage } from './pages/BuyPage';
import { ClaimsPage } from './pages/ClaimsPage';
import { GovernancePage } from './pages/GovernancePage';
import { AnalyticsPage } from './pages/AnalyticsPage';

function Layout({ children }: { children: ReactNode }) {
  const chainId = useChainId();
  const wrong = chainId !== sepolia.id;

  const linkCls = ({ isActive }: { isActive: boolean }) =>
    `px-3 py-2 rounded-lg text-sm font-medium transition ${
      isActive ? 'bg-night-700 text-accent' : 'text-slate-300 hover:text-white'
    }`;

  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-night-800 bg-night-900/80 backdrop-blur sticky top-0 z-20">
        <div className="max-w-6xl mx-auto px-4 py-4 flex flex-wrap items-center gap-4 justify-between">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-accent to-indigo-500 shadow-lg shadow-accent/20" />
            <div>
              <p className="text-lg font-semibold tracking-tight">ShieldFi</p>
              <p className="text-xs text-slate-400">Decentralized underwriting + claims</p>
            </div>
          </div>
          <nav className="flex flex-wrap gap-1">
            <NavLink to="/" className={linkCls} end>
              Dashboard
            </NavLink>
            <NavLink to="/vault" className={linkCls}>
              Vault
            </NavLink>
            <NavLink to="/buy" className={linkCls}>
              Buy
            </NavLink>
            <NavLink to="/claims" className={linkCls}>
              Claims
            </NavLink>
            <NavLink to="/governance" className={linkCls}>
              Governance
            </NavLink>
            <NavLink to="/analytics" className={linkCls}>
              Analytics
            </NavLink>
          </nav>
          <ConnectButton showBalance={{ smallScreen: false, largeScreen: true }} />
        </div>
        {wrong ? (
          <div className="bg-amber-500/10 border-t border-amber-500/30 text-amber-200 text-sm px-4 py-2 text-center">
            Switch your wallet to Sepolia (chain id {sepolia.id}) to interact with ShieldFi
            deployments.
          </div>
        ) : null}
      </header>
      <main className="flex-1 max-w-6xl mx-auto w-full px-4 py-8">{children}</main>
      <footer className="border-t border-night-800 py-6 text-center text-xs text-slate-500">
        Capstone build — contracts, subgraph, and UI are configurable for your deployed addresses.
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/vault" element={<VaultPage />} />
        <Route path="/buy" element={<BuyPage />} />
        <Route path="/claims" element={<ClaimsPage />} />
        <Route path="/governance" element={<GovernancePage />} />
        <Route path="/analytics" element={<AnalyticsPage />} />
      </Routes>
    </Layout>
  );
}
