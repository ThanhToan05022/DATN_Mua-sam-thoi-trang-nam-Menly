import { describe, it, expect } from 'vitest';
import {
  buildSignData,
  sign,
  verify,
} from '../../src/infrastructure/vnpay/vnpay.sign.js';

describe('VNPay Sign and Verify', () => {
  const secret = 'TEST_SECRET_KEY';

  it('should sort keys and format url query properly', () => {
    const params = {
      vnp_Amount: 100000,
      vnp_Command: 'pay',
      vnp_OrderInfo: 'Don hang test',
    };
    const query = buildSignData(params);
    expect(query).toBe('vnp_Amount=100000&vnp_Command=pay&vnp_OrderInfo=Don+hang+test');
  });

  it('should verify signature correctly', () => {
    const params = {
      vnp_Amount: '100000',
      vnp_Command: 'pay',
      vnp_TxnRef: 'ORDER_123',
    };
    const data = buildSignData(params);
    const hash = sign(data, secret);

    const queryWithHash = {
      ...params,
      vnp_SecureHash: hash,
    };

    expect(verify(queryWithHash, secret)).toBe(true);
    expect(verify({ ...queryWithHash, vnp_Amount: '200000' }, secret)).toBe(false);
  });
});
