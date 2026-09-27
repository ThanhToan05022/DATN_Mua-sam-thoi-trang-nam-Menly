import { ProductDetail } from '../../../domain/entities/product.js';
import { ProductRepository } from '../../../domain/repositories/product.repository.js';
import { AppError } from '../../../domain/errors.js';

export class GetProduct {
  constructor(private readonly repo: ProductRepository) {}

  async execute(id: string): Promise<ProductDetail> {
    const product = await this.repo.findById(id);
    if (!product || !product.isActive) {
      throw new AppError('NOT_FOUND', 404, 'Sản phẩm không tồn tại');
    }
    return product;
  }
}
