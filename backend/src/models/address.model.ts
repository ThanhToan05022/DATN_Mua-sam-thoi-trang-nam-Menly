import { SupabaseClient } from '@supabase/supabase-js';
import {
  UserAddress,
  CreateAddressInput,
  UpdateAddressInput,
  AppError,
} from './types.js';
import { resolveUserUuid, isUuid } from '../shared/user-identity.js';

export interface IAddressModel {
  listByUser(userId: string, userEmail?: string): Promise<UserAddress[]>;
  findById(userId: string, addressId: string, userEmail?: string): Promise<UserAddress | null>;
  create(userId: string, input: CreateAddressInput, userEmail?: string): Promise<UserAddress>;
  update(
    userId: string,
    addressId: string,
    input: UpdateAddressInput,
    userEmail?: string
  ): Promise<UserAddress>;
  remove(userId: string, addressId: string, userEmail?: string): Promise<void>;
  setDefault(userId: string, addressId: string, userEmail?: string): Promise<UserAddress>;
}

const COLUMNS =
  'id, user_id, recipient_name, phone, province, district, ward, detail_address, is_default, created_at';

const mapRow = (row: any): UserAddress => ({
  id: row.id,
  userId: row.user_id,
  recipientName: row.recipient_name || '',
  phone: row.phone || '',
  province: row.province || '',
  district: row.district || '',
  ward: row.ward || '',
  detailAddress: row.detail_address || '',
  isDefault: Boolean(row.is_default),
  createdAt: row.created_at || new Date().toISOString(),
});

export class AddressModel implements IAddressModel {
  /** Fallback khi không có Supabase: key = userId, value = danh sách địa chỉ */
  private inMemory = new Map<string, UserAddress[]>();

  constructor(private readonly supabase?: SupabaseClient) {}

  /** Bỏ toàn bộ trường địa chỉ rỗng để ghi vào DB (cột đều NOT NULL) */
  private static clean(value: string | undefined, fallback = ''): string {
    const trimmed = (value ?? '').trim();
    return trimmed.length > 0 ? trimmed : fallback;
  }

  /**
 * Xác định chủ sở hữu địa chỉ.
 *
 * KHÔNG dùng `resolveUserUuidOrDefault` cho các đường đọc/ghi vì hàm đó rơi về
 * uuid khách hàng mẫu dùng chung: nếu không xác định được user thực thì người
 * gọi sẽ đọc/sửa được địa chỉ của tài khoản khác.
 */
private static ownerId(userId: string, userEmail?: string): string {
  const ownerId = resolveUserUuid(userId, userEmail);
  if (!ownerId) {
    throw new AppError(
      'UNAUTHORIZED',
      401,
      'Không xác định được tài khoản người dùng. Vui lòng đăng nhập lại.'
    );
  }
  return ownerId;
}

async listByUser(userId: string, userEmail?: string): Promise<UserAddress[]> {
    if (this.supabase) {
      const ownerId = AddressModel.ownerId(userId, userEmail);

      const { data, error } = await this.supabase
        .from('user_addresses')
        .select(COLUMNS)
        .eq('user_id', ownerId)
        .order('is_default', { ascending: false })
        .order('created_at', { ascending: false });

      if (error) {
        throw new AppError('DB_QUERY_FAILED', 400, error.message);
      }
      return (data || []).map(mapRow);
    }

    const key = AddressModel.ownerId(userId, userEmail);
    return [...(this.inMemory.get(key) ?? [])].sort(
      (a, b) =>
        Number(b.isDefault) - Number(a.isDefault) ||
        b.createdAt.localeCompare(a.createdAt)
    );
  }

  async findById(
    userId: string,
    addressId: string,
    userEmail?: string
  ): Promise<UserAddress | null> {
    if (!addressId) return null;

    if (this.supabase) {
      const ownerId = AddressModel.ownerId(userId, userEmail);
      if (!isUuid(addressId)) return null;

      const { data, error } = await this.supabase
        .from('user_addresses')
        .select(COLUMNS)
        .eq('id', addressId)
        .eq('user_id', ownerId)
        .maybeSingle();

      if (error) return null;
      return data ? mapRow(data) : null;
    }

    const key = AddressModel.ownerId(userId, userEmail);
    return this.inMemory.get(key)?.find((a) => a.id === addressId) ?? null;
  }

  async create(
    userId: string,
    input: CreateAddressInput,
    userEmail?: string
  ): Promise<UserAddress> {
    const ownerId = AddressModel.ownerId(userId, userEmail);

    const payload = {
      user_id: ownerId,
      recipient_name: AddressModel.clean(input.recipientName),
      phone: AddressModel.clean(input.phone),
      province: AddressModel.clean(input.province, 'Hà Nội'),
      district: AddressModel.clean(input.district, 'Hà Nội'),
      ward: AddressModel.clean(input.ward, 'Hà Nội'),
      detail_address: AddressModel.clean(input.detailAddress, 'Chưa cập nhật'),
      is_default: Boolean(input.isDefault),
    };

    if (this.supabase) {
      const existing = await this.listByUser(userId, userEmail);

      // Địa chỉ đầu tiên luôn là mặc định
      const shouldBeDefault = payload.is_default || existing.length === 0;

      if (shouldBeDefault) {
        await this.supabase
          .from('user_addresses')
          .update({ is_default: false })
          .eq('user_id', ownerId);
      }

      const { data, error } = await this.supabase
        .from('user_addresses')
        .insert({ ...payload, is_default: shouldBeDefault })
        .select(COLUMNS)
        .single();

      if (error) {
        throw new AppError('DB_INSERT_FAILED', 400, error.message);
      }
      return mapRow(data);
    }

    const key = AddressModel.ownerId(userId, userEmail);
    const list = this.inMemory.get(key) ?? [];
    const shouldBeDefault = payload.is_default || list.length === 0;

    const address: UserAddress = {
      id: isUuid(ownerId)
        ? crypto.randomUUID()
        : `addr-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      userId: key,
      recipientName: payload.recipient_name,
      phone: payload.phone,
      province: payload.province,
      district: payload.district,
      ward: payload.ward,
      detailAddress: payload.detail_address,
      isDefault: shouldBeDefault,
      createdAt: new Date().toISOString(),
    };

    if (shouldBeDefault) {
      list.forEach((a) => {
        a.isDefault = false;
      });
    }
    list.push(address);
    this.inMemory.set(key, list);

    return address;
  }

  async update(
    userId: string,
    addressId: string,
    input: UpdateAddressInput,
    userEmail?: string
  ): Promise<UserAddress> {
    const existing = await this.findById(userId, addressId, userEmail);
    if (!existing) {
      throw new AppError('ADDRESS_NOT_FOUND', 404, 'Không tìm thấy địa chỉ cần cập nhật');
    }

    const patch: Record<string, unknown> = {};
    if (input.recipientName !== undefined) {
      patch.recipient_name = AddressModel.clean(input.recipientName, existing.recipientName);
    }
    if (input.phone !== undefined) {
      patch.phone = AddressModel.clean(input.phone, existing.phone);
    }
    if (input.province !== undefined) {
      patch.province = AddressModel.clean(input.province, existing.province);
    }
    if (input.district !== undefined) {
      patch.district = AddressModel.clean(input.district, existing.district);
    }
    if (input.ward !== undefined) {
      patch.ward = AddressModel.clean(input.ward, existing.ward);
    }
    if (input.detailAddress !== undefined) {
      patch.detail_address = AddressModel.clean(input.detailAddress, existing.detailAddress);
    }

    if (input.isDefault === true) {
      return this.setDefault(userId, addressId, userEmail);
    }

    if (Object.keys(patch).length === 0) return existing;

    if (this.supabase) {
      const { data, error } = await this.supabase
        .from('user_addresses')
        .update(patch)
        .eq('id', existing.id)
        .eq('user_id', existing.userId)
        .select(COLUMNS)
        .single();

      if (error) {
        throw new AppError('DB_UPDATE_FAILED', 400, error.message);
      }
      return mapRow(data);
    }

    const key = existing.userId;
    const list = this.inMemory.get(key) ?? [];
    const idx = list.findIndex((a) => a.id === existing.id);
    if (idx === -1) return existing;

    // patch dùng khoá snake_case cho Postgres, nên phải ánh xạ lại
    // sang tên field camelCase của UserAddress trước khi ghi vào bộ nhớ.
    list[idx] = {
      ...list[idx],
      ...(patch.recipient_name !== undefined
        ? { recipientName: String(patch.recipient_name) }
        : {}),
      ...(patch.phone !== undefined ? { phone: String(patch.phone) } : {}),
      ...(patch.province !== undefined ? { province: String(patch.province) } : {}),
      ...(patch.district !== undefined ? { district: String(patch.district) } : {}),
      ...(patch.ward !== undefined ? { ward: String(patch.ward) } : {}),
      ...(patch.detail_address !== undefined
        ? { detailAddress: String(patch.detail_address) }
        : {}),
    };
    this.inMemory.set(key, list);
    return list[idx];
  }

  async remove(userId: string, addressId: string, userEmail?: string): Promise<void> {
    const existing = await this.findById(userId, addressId, userEmail);
    if (!existing) {
      throw new AppError('ADDRESS_NOT_FOUND', 404, 'Không tìm thấy địa chỉ cần xoá');
    }

    if (this.supabase) {
      const { error } = await this.supabase
        .from('user_addresses')
        .delete()
        .eq('id', existing.id)
        .eq('user_id', existing.userId);

      if (error) {
        throw new AppError('DB_DELETE_FAILED', 400, error.message);
      }
    } else {
      const list = this.inMemory.get(existing.userId) ?? [];
      this.inMemory.set(
        existing.userId,
        list.filter((a) => a.id !== existing.id)
      );
    }

    // Xoá địa chỉ mặc định thì tự động đẩy địa chỉ còn lại lên mặc định
    if (existing.isDefault) {
      const remaining = await this.listByUser(userId, userEmail);
      if (remaining.length > 0) {
        await this.setDefault(userId, remaining[0].id, userEmail);
      }
    }
  }

  async setDefault(
    userId: string,
    addressId: string,
    userEmail?: string
  ): Promise<UserAddress> {
    const existing = await this.findById(userId, addressId, userEmail);
    if (!existing) {
      throw new AppError('ADDRESS_NOT_FOUND', 404, 'Không tìm thấy địa chỉ cần đặt mặc định');
    }

    if (this.supabase) {
      const { error: clearError } = await this.supabase
        .from('user_addresses')
        .update({ is_default: false })
        .eq('user_id', existing.userId);
      if (clearError) {
        throw new AppError('DB_UPDATE_FAILED', 400, clearError.message);
      }

      const { data, error } = await this.supabase
        .from('user_addresses')
        .update({ is_default: true })
        .eq('id', existing.id)
        .eq('user_id', existing.userId)
        .select(COLUMNS)
        .single();

      if (error) {
        throw new AppError('DB_UPDATE_FAILED', 400, error.message);
      }
      return mapRow(data);
    }

    const list = this.inMemory.get(existing.userId) ?? [];
    const target = list.find((a) => a.id === existing.id);
    if (!target) return existing;

    list.forEach((a) => {
      a.isDefault = a.id === existing.id;
    });
    this.inMemory.set(existing.userId, list);
    return target;
  }

  /**
   * Chuẩn hoá địa chỉ đã lưu thành khối thông tin giao hàng dùng cho đơn hàng.
   * Trả về `null` nếu địa chỉ không tồn tại hoặc không thuộc về người dùng.
   */
  async toShippingInfo(
    userId: string,
    addressId: string,
    userEmail?: string
  ): Promise<{ name: string; phone: string; address: string } | null> {
    const uuid = resolveUserUuid(userId, userEmail);
    if (!uuid || !isUuid(addressId)) return null;

    const address = await this.findById(userId, addressId, userEmail);
    if (!address) return null;

    return {
      name: address.recipientName,
      phone: address.phone,
      address: [address.detailAddress, address.ward, address.district, address.province]
        .filter((part) => part && part.trim().length > 0)
        .join(', '),
    };
  }
}
