import { Router, Request, RequestHandler } from 'express';
import { AddressViewModel } from '../../viewmodels/address.viewmodel.js';
import {
  createAddressSchema,
  updateAddressSchema,
} from '../../presentation/http/schemas/address.schema.js';
import { requireCustomer } from '../../presentation/http/middlewares/auth.js';

/**
 * Định danh người gọi.
 *
 * Luôn lấy `req.user.id` (đã được xác thực từ token) làm chính. Header
 * `x-user-id` do client tự gửi nên chỉ dùng làm fallback khi không có thông tin
 * trong token — nếu ưu tiên header thì người dùng có thể tự khai id của
 * người khác để đọc/sửa địa chỉ không thuộc về mình.
 */
const callerId = (req: Request): string =>
  req.user?.id || (req.headers['x-user-id'] as string) || '';

const callerEmail = (req: Request): string | undefined =>
  req.user?.email || (req.headers['x-user-email'] as string) || undefined;

export const addressRoutes = (
  requireAuth: RequestHandler,
  vm: AddressViewModel
): Router => {
  const router = Router();
  router.use(requireAuth, requireCustomer);

  // GET /api/v1/addresses — danh sách địa chỉ (mặc định đứng đầu)
  router.get('/', async (req, res, next) => {
    try {
      const addresses = await vm.list(callerId(req), callerEmail(req));
      res.json({ data: addresses, items: addresses, total: addresses.length });
    } catch (err) {
      next(err);
    }
  });

  // GET /api/v1/addresses/default — địa chỉ mặc định
  router.get('/default', async (req, res, next) => {
    try {
      const address = await vm.getDefault(callerId(req), callerEmail(req));
      res.json({ data: address });
    } catch (err) {
      next(err);
    }
  });

  // GET /api/v1/addresses/:id — chi tiết một địa chỉ
  router.get('/:id', async (req, res, next) => {
    try {
      const address = await vm.getOne(
        callerId(req),
        req.params.id,
        callerEmail(req)
      );
      res.json({ data: address });
    } catch (err) {
      next(err);
    }
  });

  // POST /api/v1/addresses — thêm địa chỉ mới
  router.post('/', async (req, res, next) => {
    try {
      const body = createAddressSchema.parse(req.body);
      const address = await vm.create(callerId(req), body, callerEmail(req));
      res.status(201).json({ message: 'Thêm địa chỉ thành công', data: address });
    } catch (err) {
      next(err);
    }
  });

  // PUT /api/v1/addresses/:id — sửa địa chỉ (kèm isDefault để đặt mặc định)
  router.put('/:id', async (req, res, next) => {
    try {
      const body = updateAddressSchema.parse(req.body);
      const address = await vm.update(
        callerId(req),
        req.params.id,
        body,
        callerEmail(req)
      );
      res.json({ message: 'Cập nhật địa chỉ thành công', data: address });
    } catch (err) {
      next(err);
    }
  });

  const setDefaultHandler = async (req: Request, res: any, next: any) => {
    try {
      const address = await vm.setDefault(
        callerId(req),
        req.params.id,
        callerEmail(req)
      );
      res.json({ message: 'Đặt địa chỉ mặc định thành công', data: address });
    } catch (err) {
      next(err);
    }
  };

  router.put('/:id/default', setDefaultHandler);
  router.patch('/:id/default', setDefaultHandler);
  router.post('/:id/default', setDefaultHandler);

  // DELETE /api/v1/addresses/:id — xoá địa chỉ
  router.delete('/:id', async (req, res, next) => {
    try {
      await vm.remove(callerId(req), req.params.id, callerEmail(req));
      res.json({ message: 'Xoá địa chỉ thành công' });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
