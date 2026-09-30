import { IVoucherModel } from '../models/voucher.model.js';
import { Voucher } from '../models/types.js';

export class VoucherViewModel {
  constructor(private readonly model: IVoucherModel) {}

  async listVouchers(activeOnly = false): Promise<Voucher[]> {
    return this.model.list(activeOnly);
  }

  async getVoucher(code: string): Promise<Voucher | null> {
    return this.model.findByCode(code);
  }

  async applyVoucher(
    code: string,
    subtotal: number
  ): Promise<{ voucher: Voucher; discountAmount: number; finalTotal: number }> {
    return this.model.validateAndCalculate(code, subtotal);
  }

  async createVoucher(data: Omit<Voucher, 'id' | 'usedCount' | 'createdAt'>): Promise<Voucher> {
    return this.model.create(data);
  }

  async updateVoucher(id: string, data: Partial<Voucher>): Promise<Voucher | null> {
    return this.model.update(id, data);
  }

  async deleteVoucher(id: string): Promise<boolean> {
    return this.model.delete(id);
  }
}
