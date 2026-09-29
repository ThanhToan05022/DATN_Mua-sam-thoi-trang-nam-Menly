import { Router, RequestHandler } from 'express';
import { WishlistViewModel } from '../../viewmodels/wishlist.viewmodel.js';

export const wishlistRoutes = (
  requireAuth: RequestHandler,
  wishlistVm: WishlistViewModel
): Router => {
  const router = Router();
  router.use(requireAuth);

  // 1. Lấy danh sách sản phẩm yêu thích của người dùng
  router.get('/', async (req, res, next) => {
    try {
      const userId = req.user!.id;
      const items = await wishlistVm.getWishlist(userId);
      res.json(items);
    } catch (err) {
      next(err);
    }
  });

  // 2. Thêm sản phẩm vào danh sách yêu thích
  router.post('/:productId', async (req, res, next) => {
    try {
      const userId = req.user!.id;
      const productId = req.params.productId;
      await wishlistVm.add(userId, productId);
      res.status(201).json({
        message: 'Đã thêm sản phẩm vào danh sách yêu thích',
        productId,
        isFavorite: true,
      });
    } catch (err) {
      next(err);
    }
  });

  // Hỗ trợ thêm qua POST body { productId }
  router.post('/', async (req, res, next) => {
    try {
      const userId = req.user!.id;
      const productId = req.body.productId;
      await wishlistVm.add(userId, productId);
      res.status(201).json({
        message: 'Đã thêm sản phẩm vào danh sách yêu thích',
        productId,
        isFavorite: true,
      });
    } catch (err) {
      next(err);
    }
  });

  // 3. Xóa sản phẩm khỏi danh sách yêu thích
  router.delete('/:productId', async (req, res, next) => {
    try {
      const userId = req.user!.id;
      const productId = req.params.productId;
      await wishlistVm.remove(userId, productId);
      res.json({
        message: 'Đã xóa sản phẩm khỏi danh sách yêu thích',
        productId,
        isFavorite: false,
      });
    } catch (err) {
      next(err);
    }
  });

  // 4. Kiểm tra xem một sản phẩm đã có trong wishlist chưa
  router.get('/check/:productId', async (req, res, next) => {
    try {
      const userId = req.user!.id;
      const productId = req.params.productId;
      const isFav = await wishlistVm.isFavorite(userId, productId);
      res.json({ productId, isFavorite: isFav });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
