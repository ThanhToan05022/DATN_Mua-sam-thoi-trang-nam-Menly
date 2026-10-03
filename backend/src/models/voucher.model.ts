import { SupabaseClient } from '@supabase/supabase-js';
import { Voucher, AppError } from './types.js';

export interface IVoucherModel {
  list(activeOnly?: boolean): Promise<Voucher[]>;
  findByCode(code: string): Promise<Voucher | null>;
  findById(id: string): Promise<Voucher | null>;
  create(data: Omit<Voucher, 'id' | 'usedCount' | 'createdAt'>): Promise<Voucher>;
  update(id: string, data: Partial<Voucher>): Promise<Voucher | null>;
  delete(id: string): Promise<boolean>;
  incrementUsage(code: string): Promise<void>;
  validateAndCalculate(
    code: string,
    subtotal: number
  ): Promise<{ voucher: Voucher; discountAmount: number; finalTotal: number }>;
}

export const INITIAL_MOCK_VOUCHERS: Voucher[] = [
  {
    id: 'vch-001',
    code: 'MENLY10',
    title: 'Giảm 10% tối đa 50K cho đơn từ 200K',
    discountType: 'percentage',
    discountValue: 10,
    minOrderValue: 200000,
    maxDiscount: 50000,
    usageLimit: 200,
    usedCount: 0,
    startDate: new Date(Date.now() - 7 * 86400000).toISOString(),
    endDate: new Date(Date.now() + 60 * 86400000).toISOString(),
    isActive: true,
    createdAt: new Date(Date.now() - 7 * 86400000).toISOString(),
  },
  {
    id: 'vch-002',
    code: 'MENLY50K',
    title: 'Giảm ngay 50.000đ cho đơn từ 300K',
    discountType: 'fixed_amount',
    discountValue: 50000,
    minOrderValue: 300000,
    maxDiscount: null,
    usageLimit: 100,
    usedCount: 0,
    startDate: new Date(Date.now() - 5 * 86400000).toISOString(),
    endDate: new Date(Date.now() + 30 * 86400000).toISOString(),
    isActive: true,
    createdAt: new Date(Date.now() - 5 * 86400000).toISOString(),
  },
  {
    id: 'vch-003',
    code: 'FREESHIP',
    title: 'Hỗ trợ 30.000đ phí vận chuyển',
    discountType: 'fixed_amount',
    discountValue: 30000,
    minOrderValue: 150000,
    maxDiscount: null,
    usageLimit: 500,
    usedCount: 0,
    startDate: new Date(Date.now() - 10 * 86400000).toISOString(),
    endDate: new Date(Date.now() + 90 * 86400000).toISOString(),
    isActive: true,
    createdAt: new Date(Date.now() - 10 * 86400000).toISOString(),
  },
  {
    id: 'vch-004',
    code: 'VIP100K',
    title: 'Ưu đãi VIP giảm 100K cho đơn từ 500K',
    discountType: 'fixed_amount',
    discountValue: 100000,
    minOrderValue: 500000,
    maxDiscount: null,
    usageLimit: 50,
    usedCount: 0,
    startDate: new Date(Date.now() - 2 * 86400000).toISOString(),
    endDate: new Date(Date.now() + 45 * 86400000).toISOString(),
    isActive: true,
    createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
  },
];

export class VoucherModel implements IVoucherModel {
  private vouchers: Voucher[] = [...INITIAL_MOCK_VOUCHERS];

  constructor(private readonly supabase?: SupabaseClient) {}

  async list(activeOnly = false): Promise<Voucher[]> {
    if (this.supabase) {
      try {
        let q = this.supabase
          .from('vouchers')
          .select('*')
          .order('created_at', { ascending: false });

        if (activeOnly) {
          q = q.eq('is_active', true);
        }

        const { data, error } = await q;
        if (!error && data) {
          return data.map((r: any) => ({
            id: r.id,
            code: r.code,
            title: r.title,
            discountType: r.discount_type,
            discountValue: r.discount_value,
            minOrderValue: r.min_order_value || 0,
            maxDiscount: r.max_discount,
            usageLimit: r.usage_limit || 100,
            usedCount: r.used_count || 0,
            startDate: r.start_date,
            endDate: r.end_date,
            isActive: Boolean(r.is_active),
            createdAt: r.created_at,
          }));
        }
      } catch {
        // Fallback to in-memory only on hard connection failure
      }
    }

    if (activeOnly) {
      const now = new Date();
      return this.vouchers.filter((v) => {
        if (!v.isActive) return false;
        if (v.usageLimit > 0 && v.usedCount >= v.usageLimit) return false;
        if (new Date(v.endDate) < now) return false;
        return true;
      });
    }

    return [...this.vouchers];
  }

  async findByCode(code: string): Promise<Voucher | null> {
    const clean = code.trim().toUpperCase();
    if (this.supabase) {
      try {
        const { data, error } = await this.supabase
          .from('vouchers')
          .select('*')
          .eq('code', clean)
          .maybeSingle();

        if (!error && data) {
          return {
            id: data.id,
            code: data.code,
            title: data.title,
            discountType: data.discount_type,
            discountValue: data.discount_value,
            minOrderValue: data.min_order_value || 0,
            maxDiscount: data.max_discount,
            usageLimit: data.usage_limit || 100,
            usedCount: data.used_count || 0,
            startDate: data.start_date,
            endDate: data.end_date,
            isActive: Boolean(data.is_active),
            createdAt: data.created_at,
          };
        }
      } catch {
        // Fallback to in-memory
      }
    }

    const found = this.vouchers.find((v) => v.code.toUpperCase() === clean);
    return found ? { ...found } : null;
  }

  async findById(id: string): Promise<Voucher | null> {
    if (this.supabase) {
      try {
        const { data, error } = await this.supabase
          .from('vouchers')
          .select('*')
          .eq('id', id)
          .maybeSingle();

        if (!error && data) {
          return {
            id: data.id,
            code: data.code,
            title: data.title,
            discountType: data.discount_type,
            discountValue: data.discount_value,
            minOrderValue: data.min_order_value || 0,
            maxDiscount: data.max_discount,
            usageLimit: data.usage_limit || 100,
            usedCount: data.used_count || 0,
            startDate: data.start_date,
            endDate: data.end_date,
            isActive: Boolean(data.is_active),
            createdAt: data.created_at,
          };
        }
      } catch {
        // Fallback
      }
    }

    const found = this.vouchers.find((v) => v.id === id);
    return found ? { ...found } : null;
  }

  async create(data: Omit<Voucher, 'id' | 'usedCount' | 'createdAt'>): Promise<Voucher> {
    const cleanCode = data.code.trim().toUpperCase();
    const existing = await this.findByCode(cleanCode);
    if (existing) {
      throw new AppError('VOUCHER_EXISTS', 400, `Mã giảm giá "${cleanCode}" đã tồn tại`);
    }

    if (this.supabase) {
      const { data: vch, error } = await this.supabase
        .from('vouchers')
        .insert({
          code: cleanCode,
          title: data.title.trim(),
          discount_type: data.discountType,
          discount_value: data.discountValue,
          min_order_value: data.minOrderValue || 0,
          max_discount: data.maxDiscount || null,
          usage_limit: data.usageLimit || 100,
          used_count: 0,
          start_date: data.startDate || new Date().toISOString(),
          end_date: data.endDate,
          is_active: data.isActive ?? true,
        })
        .select()
        .single();

      if (error || !vch) {
        throw new AppError('DB_VOUCHER_CREATE_FAILED', 400, error?.message || 'Không thể tạo mã giảm giá');
      }

      return {
        id: vch.id,
        code: vch.code,
        title: vch.title,
        discountType: vch.discount_type,
        discountValue: vch.discount_value,
        minOrderValue: vch.min_order_value,
        maxDiscount: vch.max_discount,
        usageLimit: vch.usage_limit,
        usedCount: vch.used_count,
        startDate: vch.start_date,
        endDate: vch.end_date,
        isActive: vch.is_active,
        createdAt: vch.created_at,
      };
    }

    const newVoucher: Voucher = {
      id: `vch-${Date.now()}-${Math.random().toString(36).substring(2, 6)}`,
      code: cleanCode,
      title: data.title.trim(),
      discountType: data.discountType,
      discountValue: data.discountValue,
      minOrderValue: data.minOrderValue || 0,
      maxDiscount: data.maxDiscount || null,
      usageLimit: data.usageLimit || 100,
      usedCount: 0,
      startDate: data.startDate || new Date().toISOString(),
      endDate: data.endDate,
      isActive: data.isActive ?? true,
      createdAt: new Date().toISOString(),
    };

    this.vouchers.unshift(newVoucher);
    return newVoucher;
  }

  async update(id: string, data: Partial<Voucher>): Promise<Voucher | null> {
    if (this.supabase) {
      const patch: Record<string, unknown> = {};
      if (data.code) patch.code = data.code.trim().toUpperCase();
      if (data.title !== undefined) patch.title = data.title;
      if (data.discountType !== undefined) patch.discount_type = data.discountType;
      if (data.discountValue !== undefined) patch.discount_value = data.discountValue;
      if (data.minOrderValue !== undefined) patch.min_order_value = data.minOrderValue;
      if (data.maxDiscount !== undefined) patch.max_discount = data.maxDiscount;
      if (data.usageLimit !== undefined) patch.usage_limit = data.usageLimit;
      if (data.startDate !== undefined) patch.start_date = data.startDate;
      if (data.endDate !== undefined) patch.end_date = data.endDate;
      if (data.isActive !== undefined) patch.is_active = data.isActive;

      if (Object.keys(patch).length > 0) {
        const { error } = await this.supabase.from('vouchers').update(patch).eq('id', id);
        if (error) throw new AppError('DB_VOUCHER_UPDATE_FAILED', 400, error.message);
      }
      return this.findById(id);
    }

    const idx = this.vouchers.findIndex((v) => v.id === id);
    if (idx === -1) {
      throw new AppError('VOUCHER_NOT_FOUND', 404, 'Không tìm thấy mã giảm giá');
    }

    const current = this.vouchers[idx];
    const updated: Voucher = {
      ...current,
      ...data,
      code: data.code ? data.code.trim().toUpperCase() : current.code,
    };

    this.vouchers[idx] = updated;
    return updated;
  }

  async delete(id: string): Promise<boolean> {
    if (this.supabase) {
      const { error } = await this.supabase.from('vouchers').delete().eq('id', id);
      if (error) throw new AppError('DB_VOUCHER_DELETE_FAILED', 400, error.message);
      return true;
    }

    const idx = this.vouchers.findIndex((v) => v.id === id);
    if (idx === -1) {
      throw new AppError('VOUCHER_NOT_FOUND', 404, 'Không tìm thấy mã giảm giá');
    }

    this.vouchers.splice(idx, 1);
    return true;
  }

  async incrementUsage(code: string): Promise<void> {
    const clean = code.trim().toUpperCase();
    const v = this.vouchers.find((x) => x.code.toUpperCase() === clean);
    if (v) {
      v.usedCount += 1;
    }

    if (this.supabase) {
      try {
        const { error } = await this.supabase.rpc('increment_voucher_usage', { p_code: clean });
        if (error) {
          // Fallback manual increment
          const { data } = await this.supabase
            .from('vouchers')
            .select('used_count')
            .eq('code', clean)
            .single();
          if (data) {
            await this.supabase
              .from('vouchers')
              .update({ used_count: (data.used_count || 0) + 1 })
              .eq('code', clean);
          }
        }
      } catch {
        // Ignore
      }
    }
  }

  async validateAndCalculate(
    code: string,
    subtotal: number
  ): Promise<{ voucher: Voucher; discountAmount: number; finalTotal: number }> {
    const voucher = await this.findByCode(code);
    if (!voucher) {
      throw new AppError('VOUCHER_NOT_FOUND', 404, `Mã giảm giá "${code}" không tồn tại`);
    }

    if (!voucher.isActive) {
      throw new AppError('VOUCHER_INACTIVE', 400, 'Mã giảm giá này hiện đang tạm khóa');
    }

    const now = new Date();
    if (new Date(voucher.startDate) > now) {
      throw new AppError('VOUCHER_NOT_STARTED', 400, 'Mã giảm giá chưa đến ngày áp dụng');
    }

    if (new Date(voucher.endDate) < now) {
      throw new AppError('VOUCHER_EXPIRED', 400, 'Mã giảm giá đã hết hạn sử dụng');
    }

    if (voucher.usageLimit > 0 && voucher.usedCount >= voucher.usageLimit) {
      throw new AppError('VOUCHER_OUT_OF_STOCK', 400, 'Mã giảm giá đã hết lượt sử dụng');
    }

    if (subtotal < voucher.minOrderValue) {
      const minFmt = voucher.minOrderValue.toLocaleString('vi-VN');
      throw new AppError(
        'VOUCHER_MIN_ORDER',
        400,
        `Mã này chỉ áp dụng cho đơn hàng từ ${minFmt}đ (hiện tại: ${subtotal.toLocaleString('vi-VN')}đ)`
      );
    }

    let discount = 0;
    if (voucher.discountType === 'percentage') {
      discount = Math.round((subtotal * voucher.discountValue) / 100);
      if (voucher.maxDiscount && voucher.maxDiscount > 0 && discount > voucher.maxDiscount) {
        discount = voucher.maxDiscount;
      }
    } else {
      discount = voucher.discountValue;
    }

    // Không được giảm quá tổng tiền hàng
    discount = Math.min(discount, subtotal);
    const finalTotal = Math.max(0, subtotal - discount);

    return {
      voucher,
      discountAmount: discount,
      finalTotal,
    };
  }
}
