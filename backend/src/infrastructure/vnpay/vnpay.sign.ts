import { createHmac, timingSafeEqual } from 'node:crypto';

const enc = (v: string): string => encodeURIComponent(v).replace(/%20/g, '+');

export function buildSignData(params: Record<string, string | number>): string {
  return Object.keys(params)
    .sort()
    .map((k) => `${enc(k)}=${enc(String(params[k]))}`)
    .join('&');
}

export const sign = (data: string, secret: string): string =>
  createHmac('sha512', secret).update(data, 'utf8').digest('hex');

export function verify(query: Record<string, string>, secret: string): boolean {
  const { vnp_SecureHash, vnp_SecureHashType, ...rest } = query;
  if (!vnp_SecureHash) return false;
  try {
    const a = Buffer.from(sign(buildSignData(rest), secret), 'hex');
    const b = Buffer.from(vnp_SecureHash.toLowerCase(), 'hex');
    return a.length === b.length && timingSafeEqual(a, b);
  } catch {
    return false;
  }
}

export const fmtVn = (d: Date): string =>
  new Date(d.getTime() + 7 * 3600_000)
    .toISOString()
    .replace(/\D/g, '')
    .slice(0, 14);

export const clientIp = (raw?: string): string =>
  (raw ?? '127.0.0.1').replace(/^::ffff:/, '').replace(/^::1$/, '127.0.0.1');
