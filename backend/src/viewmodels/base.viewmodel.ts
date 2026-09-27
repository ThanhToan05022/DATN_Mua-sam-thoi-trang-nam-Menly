import { z } from 'zod';
import { Cursor, AppError } from '../models/types.js';

const cursorSchema = z.object({
  v: z.union([z.number().int(), z.string().datetime({ offset: true })]),
  id: z.string().uuid(),
});

export const encodeCursor = (c: Cursor): string =>
  Buffer.from(JSON.stringify(c)).toString('base64url');

export function decodeCursor(raw: string): Cursor {
  try {
    const parsed = JSON.parse(Buffer.from(raw, 'base64url').toString('utf8'));
    return cursorSchema.parse(parsed);
  } catch {
    throw new AppError('INVALID_CURSOR', 400, 'Cursor không hợp lệ');
  }
}

export const normalizeSearch = (s: string): string =>
  s
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/gi, 'd')
    .toLowerCase()
    .trim();
