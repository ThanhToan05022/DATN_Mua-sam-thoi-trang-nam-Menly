import { Request, Response, NextFunction } from 'express';

// Color definitions for ANSI terminal (matching Next.js dev server aesthetic)
const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[90m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m',
};

function getMethodColor(method: string): string {
  switch (method.toUpperCase()) {
    case 'GET':
      return colors.green;
    case 'POST':
      return colors.blue;
    case 'PUT':
      return colors.yellow;
    case 'PATCH':
      return colors.magenta;
    case 'DELETE':
      return colors.red;
    default:
      return colors.reset;
  }
}

function getStatusColor(status: number): string {
  if (status >= 500) return colors.red;
  if (status >= 400) return colors.yellow;
  if (status >= 300) return colors.cyan;
  if (status >= 200) return colors.green;
  return colors.reset;
}

declare global {
  namespace Express {
    interface Request {
      log?: {
        info: (...args: any[]) => void;
        warn: (...args: any[]) => void;
        error: (...args: any[]) => void;
      };
    }
  }
}

/**
 * Next.js-style clean HTTP request logger middleware.
 * Outputs concise API logs without messy header dumps.
 * Example:
 *   GET    /api/v1/orders?limit=50 200 in 1ms
 *   GET    /api/v1/wishlist 200 in 306ms
 */
export function apiLogger(req: Request, res: Response, next: NextFunction): void {
  // Completely silent during automated tests
  if (process.env.NODE_ENV === 'test') {
    req.log = {
      info: () => {},
      warn: () => {},
      error: () => {},
    };
    return next();
  }

  // Lightweight logging interface attached to req
  req.log = {
    info: (...args: any[]) => console.log(`${colors.dim}[API]${colors.reset}`, ...args),
    warn: (...args: any[]) => console.warn(`${colors.yellow}[API WARN]${colors.reset}`, ...args),
    error: (...args: any[]) => console.error(`${colors.red}[API ERROR]${colors.reset}`, ...args),
  };

  const start = process.hrtime.bigint();
  const method = req.method;
  const url = req.originalUrl || req.url;

  res.on('finish', () => {
    const end = process.hrtime.bigint();
    const durationMs = Number(end - start) / 1_000_000;
    const timeFormatted = durationMs < 1 ? '<1ms' : `${Math.round(durationMs)}ms`;

    const status = res.statusCode;
    const methodColored = `${getMethodColor(method)}${method.padEnd(6)}${colors.reset}`;
    const statusColored = `${getStatusColor(status)}${status}${colors.reset}`;
    const timeColored = `${colors.dim}in ${timeFormatted}${colors.reset}`;

    // Format clean Next.js style log
    console.log(`  ${methodColored} ${url} ${statusColored} ${timeColored}`);
  });

  next();
}
