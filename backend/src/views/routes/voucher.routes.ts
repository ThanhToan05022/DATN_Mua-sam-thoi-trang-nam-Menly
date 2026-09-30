import { Router, RequestHandler } from 'express';
import { z } from 'zod';
import { VoucherViewModel } from '../../viewmodels/voucher.viewmodel.js';

const applyVoucherSchema = z.object({
  code: z.string().min(1, 'Mã giảm giá không được để trống'),
  subtotal: z.number().int().min(0, 'Tổng tiền không hợp lệ'),
});

const createVoucherSchema = z.object({
  code: z.string().min(2, 'Mã giảm giá tối thiểu 2 ký tự').max(30),
  title: z.string().min(2, 'Tiêu đề tối thiểu 2 ký tự').max(100),
  discountType: z.enum(['percentage', 'fixed_amount']),
  discountValue: z.number().int().positive('Giá trị giảm giá phải lớn hơn 0'),
  minOrderValue: z.number().int().min(0).default(0),
  maxDiscount: z.number().int().positive().nullable().optional(),
  usageLimit: z.number().int().min(1).default(100),
  startDate: z.string().optional(),
  endDate: z.string(),
  isActive: z.boolean().default(true),
});

const updateVoucherSchema = createVoucherSchema.partial();

export const voucherRoutes = (vm: VoucherViewModel): Router => {
  const router = Router();

  // GET /api/v1/vouchers — Khách hàng lấy danh sách voucher khả dụng
  router.get('/', async (_req, res, next) => {
    try {
      const vouchers = await vm.listVouchers(true);
      res.json(vouchers);
    } catch (err) {
      next(err);
    }
  });

  // POST /api/v1/vouchers/apply — Áp dụng và tính toán giảm giá
  router.post('/apply', async (req, res, next) => {
    try {
      const { code, subtotal } = applyVoucherSchema.parse(req.body);
      const result = await vm.applyVoucher(code, subtotal);
      res.json({
        valid: true,
        code: result.voucher.code,
        discountAmount: result.discountAmount,
        finalTotal: result.finalTotal,
        voucher: result.voucher,
      });
    } catch (err) {
      next(err);
    }
  });

  return router;
};

export const adminVoucherRoutes = (
  requireAuth: RequestHandler,
  requireAdmin: RequestHandler,
  vm: VoucherViewModel
): Router => {
  const router = Router();
  router.use(requireAuth);
  router.use(requireAdmin);

  // GET /api/v1/admin/vouchers — Quản trị viên xem tất cả voucher
  router.get('/', async (_req, res, next) => {
    try {
      const vouchers = await vm.listVouchers(false);
      res.json(vouchers);
    } catch (err) {
      next(err);
    }
  });

  // POST /api/v1/admin/vouchers — Tạo voucher mới
  router.post('/', async (req, res, next) => {
    try {
      const body = createVoucherSchema.parse(req.body);
      const voucher = await vm.createVoucher({
        code: body.code,
        title: body.title,
        discountType: body.discountType,
        discountValue: body.discountValue,
        minOrderValue: body.minOrderValue,
        maxDiscount: body.maxDiscount ?? null,
        usageLimit: body.usageLimit,
        startDate: body.startDate || new Date().toISOString(),
        endDate: body.endDate,
        isActive: body.isActive,
      });
      res.status(201).json(voucher);
    } catch (err) {
      next(err);
    }
  });

  // PUT /api/v1/admin/vouchers/:id — Cập nhật voucher
  router.put('/:id', async (req, res, next) => {
    try {
      const body = updateVoucherSchema.parse(req.body);
      const updated = await vm.updateVoucher(req.params.id, body);
      res.json(updated);
    } catch (err) {
      next(err);
    }
  });

  // DELETE /api/v1/admin/vouchers/:id — Xóa voucher
  router.delete('/:id', async (req, res, next) => {
    try {
      await vm.deleteVoucher(req.params.id);
      res.json({ success: true, message: 'Đã xóa mã giảm giá thành công' });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
