import { Router, RequestHandler } from 'express';
import { PaymentViewModel } from '../../viewmodels/payment.viewmodel.js';
import { createPaymentSchema } from '../../presentation/http/schemas/payment.schema.js';
import { clientIp } from '../../infrastructure/vnpay/vnpay.sign.js';

export const paymentRoutes = (
  requireAuth: RequestHandler,
  vm: PaymentViewModel
): Router => {
  const router = Router();

  router.post('/vnpay/create', requireAuth, async (req, res, next) => {
    try {
      const body = createPaymentSchema.parse(req.body);
      const ip = clientIp(req.ip);
      const result = await vm.createPaymentUrl({
        orderId: body.orderId,
        userId: req.user!.id,
        clientIp: ip,
      });
      res.json(result);
    } catch (err) {
      next(err);
    }
  });

  router.get('/vnpay/ipn', async (req, res, next) => {
    try {
      const query = req.query as Record<string, string>;
      const result = await vm.handleIpn(query);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  });

  router.get('/vnpay/return', (req, res) => {
    const isSuccess = req.query.vnp_ResponseCode === '00';
    const txnRef = req.query.vnp_TxnRef || '';
    const amount = Number(req.query.vnp_Amount || 0) / 100;

    res.send(`
      <!DOCTYPE html>
      <html lang="vi">
      <head>
        <meta charset="UTF-8">
        <title>Kết quả thanh toán MenShop</title>
        <style>
          body { font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f8fafc; }
          .card { background: white; padding: 32px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); text-align: center; max-width: 400px; }
          .status { font-size: 24px; font-weight: bold; color: ${isSuccess ? '#16a34a' : '#dc2626'}; margin-bottom: 12px; }
          .info { color: #475569; margin: 8px 0; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="status">${isSuccess ? 'Thanh toán thành công' : 'Thanh toán thất bại'}</div>
          <p class="info">Mã giao dịch: <strong>${txnRef}</strong></p>
          <p class="info">Số tiền: <strong>${amount.toLocaleString('vi-VN')} VND</strong></p>
          <p class="info">Bạn có thể quay lại ứng dụng để xem trạng thái đơn hàng.</p>
        </div>
      </body>
      </html>
    `);
  });

  return router;
};
