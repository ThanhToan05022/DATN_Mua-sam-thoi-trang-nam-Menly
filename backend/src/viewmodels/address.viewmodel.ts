import {
  UserAddress,
  CreateAddressInput,
  UpdateAddressInput,
  AppError,
} from '../models/types.js';
import { IAddressModel } from '../models/address.model.js';

const requireUserId = (userId?: string): string => {
  if (!userId || userId.trim().length === 0) {
    throw new AppError('UNAUTHORIZED', 401, 'Yêu cầu đăng nhập để quản lý địa chỉ giao hàng');
  }
  return userId;
};

export class AddressViewModel {
  constructor(private readonly addressModel: IAddressModel) {}

  async list(userId: string, userEmail?: string): Promise<UserAddress[]> {
    return this.addressModel.listByUser(requireUserId(userId), userEmail);
  }

  async getOne(
    userId: string,
    addressId: string,
    userEmail?: string
  ): Promise<UserAddress> {
    const address = await this.addressModel.findById(
      requireUserId(userId),
      addressId,
      userEmail
    );
    if (!address) {
      throw new AppError('ADDRESS_NOT_FOUND', 404, 'Không tìm thấy địa chỉ');
    }
    return address;
  }

  async getDefault(userId: string, userEmail?: string): Promise<UserAddress | null> {
    const list = await this.list(userId, userEmail);
    return list.find((a) => a.isDefault) ?? list[0] ?? null;
  }

  async create(
    userId: string,
    input: CreateAddressInput,
    userEmail?: string
  ): Promise<UserAddress> {
    return this.addressModel.create(requireUserId(userId), input, userEmail);
  }

  async update(
    userId: string,
    addressId: string,
    input: UpdateAddressInput,
    userEmail?: string
  ): Promise<UserAddress> {
    return this.addressModel.update(requireUserId(userId), addressId, input, userEmail);
  }

  async remove(userId: string, addressId: string, userEmail?: string): Promise<void> {
    await this.addressModel.remove(requireUserId(userId), addressId, userEmail);
  }

  async setDefault(
    userId: string,
    addressId: string,
    userEmail?: string
  ): Promise<UserAddress> {
    return this.addressModel.setDefault(requireUserId(userId), addressId, userEmail);
  }

  /** Địa chỉ dùng để giao hàng cho một đơn hàng (từ addressId đã lưu). */
  async resolveShipping(
    userId: string,
    addressId: string,
    userEmail?: string
  ): Promise<{ name: string; phone: string; address: string }> {
    const model = this.addressModel as IAddressModel & {
      toShippingInfo?: (
        userId: string,
        addressId: string,
        userEmail?: string
      ) => Promise<{ name: string; phone: string; address: string } | null>;
    };

    const ship = model.toShippingInfo
      ? await model.toShippingInfo(requireUserId(userId), addressId, userEmail)
      : null;

    if (!ship) {
      throw new AppError(
        'ADDRESS_NOT_FOUND',
        404,
        'Địa chỉ giao hàng không tồn tại hoặc không thuộc tài khoản của bạn'
      );
    }
    return ship;
  }
}
