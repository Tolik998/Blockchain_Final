export function formatTxError(err: unknown): string {
  if (typeof err === 'string') return err;
  if (err && typeof err === 'object') {
    const o = err as { shortMessage?: string; message?: string; details?: string };
    if (o.shortMessage) return o.shortMessage;
    if (o.message) return o.message;
    if (o.details) return o.details;
  }
  return 'Transaction failed';
}
