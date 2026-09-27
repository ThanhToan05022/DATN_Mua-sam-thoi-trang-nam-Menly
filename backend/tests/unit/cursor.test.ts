import { describe, it, expect } from 'vitest';
import { encodeCursor, decodeCursor } from '../../src/application/cursor.js';
import { AppError } from '../../src/domain/errors.js';

describe('Cursor Codec', () => {
  it('should encode and decode integer cursor', () => {
    const original = { v: 350000, id: '11111111-1111-1111-1111-111111111111' };
    const encoded = encodeCursor(original);
    expect(typeof encoded).toBe('string');

    const decoded = decodeCursor(encoded);
    expect(decoded).toEqual(original);
  });

  it('should encode and decode ISO date cursor', () => {
    const original = {
      v: '2026-09-20T10:00:00.000Z',
      id: '22222222-2222-2222-2222-222222222222',
    };
    const encoded = encodeCursor(original);
    const decoded = decodeCursor(encoded);
    expect(decoded).toEqual(original);
  });

  it('should throw AppError on invalid base64 or schema', () => {
    expect(() => decodeCursor('invalid-cursor-string')).toThrow(AppError);
  });
});
