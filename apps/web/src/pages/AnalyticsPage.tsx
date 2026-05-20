import { useEffect, useState } from 'react';

const ENDPOINT = import.meta.env.VITE_GRAPHQL_ENDPOINT as string | undefined;

// ── Types ────────────────────────────────────────────────────────────────────

interface VaultDeposit {
  id: string;
  owner: string;
  assets: string;
  shares: string;
  timestamp: string;
  txHash: string;
}

interface PolicyPurchase {
  id: string;
  policyId: string;
  buyer: string;
  coverage: string;
  premium: string;
  expiration: string;
  timestamp: string;
}

interface ClaimProcessed {
  id: string;
  policyId: string;
  beneficiary: string;
  payout: string;
  oraclePrice: string;
  timestamp: string;
}

// ── Error formatter ──────────────────────────────────────────────────────────

function formatSubgraphError(error: unknown): string {
  const message = error instanceof Error ? error.message : String(error);

  if (message.includes('VITE_GRAPHQL_ENDPOINT')) {
    return 'Subgraph endpoint is not configured. Please set VITE_GRAPHQL_ENDPOINT in apps/web/.env.';
  }

  if (message.includes('Failed to fetch') || message.includes('NetworkError')) {
    return 'Unable to connect to The Graph. Please check your internet connection and subgraph endpoint.';
  }

  if (message.includes('HTTP 404')) {
    return 'Subgraph endpoint was not found. Please check the deployed GraphQL URL.';
  }

  if (message.includes('HTTP 401') || message.includes('HTTP 403')) {
    return 'The Graph endpoint rejected the request. Please check endpoint permissions or deployment status.';
  }

  if (message.includes('HTTP 429')) {
    return 'Too many requests to The Graph. Please wait a moment and try again.';
  }

  if (message.includes('indexing')) {
    return 'The subgraph is still indexing. Please wait until synchronization is complete.';
  }

  return 'Failed to load indexed analytics data from The Graph. Please check the subgraph endpoint and network status.';
}

// ── GraphQL fetcher ──────────────────────────────────────────────────────────

async function gqlFetch<T>(query: string, variables: Record<string, unknown> = {}): Promise<T> {
  if (!ENDPOINT) {
    throw new Error('VITE_GRAPHQL_ENDPOINT not set');
  }

  const res = await fetch(ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, variables }),
  });

  if (!res.ok) {
    throw new Error(`HTTP ${res.status}`);
  }

  const json = (await res.json()) as { data?: T; errors?: { message: string }[] };

  if (json.errors?.length) {
    throw new Error(json.errors[0].message);
  }

  if (!json.data) {
    throw new Error('No data in response');
  }

  return json.data;
}

// ── Queries ──────────────────────────────────────────────────────────────────

const Q_DEPOSITS = `
  query RecentDeposits($first: Int!) {
    vaultDeposits(first: $first, orderBy: timestamp, orderDirection: desc) {
      id
      owner
      assets
      shares
      timestamp
      txHash
    }
  }
`;

const Q_POLICIES = `
  query RecentPolicies($first: Int!) {
    policyPurchases(first: $first, orderBy: timestamp, orderDirection: desc) {
      id
      policyId
      buyer
      coverage
      premium
      expiration
      timestamp
    }
  }
`;

const Q_CLAIMS = `
  query RecentClaims($first: Int!) {
    claimProcesseds(first: $first, orderBy: timestamp, orderDirection: desc) {
      id
      policyId
      beneficiary
      payout
      oraclePrice
      timestamp
    }
  }
`;

// ── Helpers ──────────────────────────────────────────────────────────────────

function fmt(raw: string, decimals = 18): string {
  try {
    const value = Number(raw) / 10 ** decimals;
    return value.toLocaleString(undefined, { maximumFractionDigits: 4 });
  } catch {
    return raw;
  }
}

function shortAddr(addr: string): string {
  return addr.length > 10 ? `${addr.slice(0, 6)}…${addr.slice(-4)}` : addr;
}

function tsToDate(ts: string): string {
  const n = Number(ts);

  if (!Number.isFinite(n) || n <= 0) {
    return 'Unknown';
  }

  return new Date(n * 1000).toLocaleString();
}

// ── Sub-components ───────────────────────────────────────────────────────────

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="glass p-6 space-y-3">
      <h2 className="text-base font-semibold text-slate-100">{title}</h2>
      {children}
    </div>
  );
}

function StatusBadge({ loading, error }: { loading: boolean; error: string | null }) {
  if (loading) {
    return <p className="text-xs text-slate-400 animate-pulse">Loading from subgraph…</p>;
  }

  if (error) {
    return (
      <div className="rounded-lg border border-red-500/30 bg-red-500/10 p-3">
        <p className="text-xs text-red-300">{error}</p>
      </div>
    );
  }

  return null;
}

function EmptyRow() {
  return <p className="text-xs text-slate-500 italic">No records yet.</p>;
}

// ── Hook ─────────────────────────────────────────────────────────────────────

function useSubgraph<T>(query: string, key: string) {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!ENDPOINT) {
      setError('Subgraph endpoint is not configured. Please set VITE_GRAPHQL_ENDPOINT in apps/web/.env.');
      return;
    }

    let cancelled = false;

    setLoading(true);
    setError(null);

    gqlFetch<Record<string, T[]>>(query, { first: 10 })
      .then((d) => {
        if (!cancelled) {
          setData(d[key] ?? []);
        }
      })
      .catch((e) => {
        if (!cancelled) {
          setError(formatSubgraphError(e));
        }
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [query, key]);

  return { data, loading, error };
}

// ── Page ─────────────────────────────────────────────────────────────────────

export function AnalyticsPage() {
  const deposits = useSubgraph<VaultDeposit>(Q_DEPOSITS, 'vaultDeposits');
  const policies = useSubgraph<PolicyPurchase>(Q_POLICIES, 'policyPurchases');
  const claims = useSubgraph<ClaimProcessed>(Q_CLAIMS, 'claimProcesseds');

  if (!ENDPOINT) {
    return (
      <div className="space-y-6 max-w-4xl">
        <h1 className="text-2xl font-bold">Analytics</h1>
        <div className="glass p-6 text-sm text-slate-300 space-y-2">
          <p className="text-amber-300 font-medium">Subgraph endpoint not configured.</p>
          <p className="text-slate-400">
            Set <code className="text-accent">VITE_GRAPHQL_ENDPOINT</code> in{' '}
            <code className="text-accent">apps/web/.env</code> to your deployed subgraph URL, then restart the dev server.
          </p>
          <p className="text-slate-500 text-xs mt-2">
            Example: <code>https://api.studio.thegraph.com/query/&lt;id&gt;/shieldfi/v0.0.1</code>
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-2xl font-bold">Analytics</h1>
        <p className="text-slate-400 text-xs mt-1 break-all">
          Subgraph: <span className="text-accent">{ENDPOINT}</span>
        </p>
      </div>

      <Section title="Recent vault deposits">
        <StatusBadge {...deposits} />
        {!deposits.loading &&
          !deposits.error &&
          (deposits.data.length === 0 ? (
            <EmptyRow />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-xs text-slate-300">
                <thead>
                  <tr className="text-slate-500 border-b border-night-700">
                    <th className="text-left pb-2 pr-4">Time</th>
                    <th className="text-left pb-2 pr-4">Owner</th>
                    <th className="text-right pb-2 pr-4">Assets</th>
                    <th className="text-right pb-2">Shares</th>
                  </tr>
                </thead>
                <tbody>
                  {deposits.data.map((d) => (
                    <tr key={d.id} className="border-b border-night-800/50 hover:bg-night-800/30 transition">
                      <td className="py-1.5 pr-4 text-slate-400">{tsToDate(d.timestamp)}</td>
                      <td className="py-1.5 pr-4 font-mono">{shortAddr(d.owner)}</td>
                      <td className="py-1.5 pr-4 text-right font-mono text-accent">{fmt(d.assets)}</td>
                      <td className="py-1.5 text-right font-mono">{fmt(d.shares)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}
      </Section>

      <Section title="Recent policies purchased">
        <StatusBadge {...policies} />
        {!policies.loading &&
          !policies.error &&
          (policies.data.length === 0 ? (
            <EmptyRow />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-xs text-slate-300">
                <thead>
                  <tr className="text-slate-500 border-b border-night-700">
                    <th className="text-left pb-2 pr-4">ID</th>
                    <th className="text-left pb-2 pr-4">Buyer</th>
                    <th className="text-right pb-2 pr-4">Coverage</th>
                    <th className="text-right pb-2 pr-4">Premium</th>
                    <th className="text-left pb-2">Expires</th>
                  </tr>
                </thead>
                <tbody>
                  {policies.data.map((p) => (
                    <tr key={p.id} className="border-b border-night-800/50 hover:bg-night-800/30 transition">
                      <td className="py-1.5 pr-4 font-mono text-accent">#{p.policyId}</td>
                      <td className="py-1.5 pr-4 font-mono">{shortAddr(p.buyer)}</td>
                      <td className="py-1.5 pr-4 text-right font-mono">{fmt(p.coverage)}</td>
                      <td className="py-1.5 pr-4 text-right font-mono">{fmt(p.premium)}</td>
                      <td className="py-1.5 text-slate-400">{tsToDate(p.expiration)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}
      </Section>

      <Section title="Processed claims">
        <StatusBadge {...claims} />
        {!claims.loading &&
          !claims.error &&
          (claims.data.length === 0 ? (
            <EmptyRow />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-xs text-slate-300">
                <thead>
                  <tr className="text-slate-500 border-b border-night-700">
                    <th className="text-left pb-2 pr-4">Policy</th>
                    <th className="text-left pb-2 pr-4">Beneficiary</th>
                    <th className="text-right pb-2 pr-4">Payout</th>
                    <th className="text-right pb-2 pr-4">Oracle price</th>
                    <th className="text-left pb-2">Time</th>
                  </tr>
                </thead>
                <tbody>
                  {claims.data.map((c) => (
                    <tr key={c.id} className="border-b border-night-800/50 hover:bg-night-800/30 transition">
                      <td className="py-1.5 pr-4 font-mono text-accent">#{c.policyId}</td>
                      <td className="py-1.5 pr-4 font-mono">{shortAddr(c.beneficiary)}</td>
                      <td className="py-1.5 pr-4 text-right font-mono">{fmt(c.payout)}</td>
                      <td className="py-1.5 pr-4 text-right font-mono text-slate-400">
                        {(Number(c.oraclePrice) / 1e8).toFixed(2)}
                      </td>
                      <td className="py-1.5 text-slate-400">{tsToDate(c.timestamp)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}
      </Section>
    </div>
  );
}