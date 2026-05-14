const endpoint = import.meta.env.VITE_GRAPHQL_ENDPOINT;

export function AnalyticsPage() {
  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Analytics</h1>
      <p className="text-slate-400 text-sm max-w-2xl">
        Wire <code className="text-accent">VITE_GRAPHQL_ENDPOINT</code> to your hosted subgraph to render live charts.
        The repository ships five GraphQL queries in <code className="text-accent">subgraph/queries.graphql</code> for
        deposits, withdrawals, policies, claims, and treasury movements.
      </p>
      <div className="glass p-6 text-sm text-slate-300">
        {endpoint ? (
          <p>
            Endpoint configured: <span className="font-mono text-xs break-all text-accent">{endpoint}</span>
          </p>
        ) : (
          <p>Add your subgraph HTTPS endpoint to enable client-side analytics queries.</p>
        )}
      </div>
    </div>
  );
}
