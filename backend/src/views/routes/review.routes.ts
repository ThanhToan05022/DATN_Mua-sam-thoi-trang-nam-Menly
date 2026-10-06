import { Router } from 'express';
import { ReviewViewModel } from '../../viewmodels/review.viewmodel.js';

export function reviewRoutes(
  requireAuth: any,
  viewModel: ReviewViewModel
): Router {
  const router = Router();

  // Create a review
  router.post('/:productId', requireAuth, async (req, res, next) => {
    try {
      const review = await viewModel.createReview(req.user!.id, req.params.productId, req.body);
      res.status(201).json({ data: review });
    } catch (error) {
      next(error);
    }
  });

  // Get reviews for a product
  router.get('/product/:productId', async (req, res, next) => {
    try {
      const limit = parseInt(req.query.limit as string) || 10;
      const page = parseInt(req.query.page as string) || 1;
      const result = await viewModel.getProductReviews(req.params.productId, limit, page);
      res.json({ data: result });
    } catch (error) {
      next(error);
    }
  });

  // Delete own review
  router.delete('/:reviewId', requireAuth, async (req, res, next) => {
    try {
      await viewModel.deleteReview(req.params.reviewId, req.user!.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  });

  return router;
}
