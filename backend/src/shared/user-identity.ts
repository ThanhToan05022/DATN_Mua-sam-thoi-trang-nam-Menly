/**
 * Ánh xạ user id -> uuid thật trong bảng auth.users / public.profiles.
 *
 * Ở môi trường dev ứng dụng mobile đôi khi gửi user id giả lập hoặc email của
 * tài khoản mẫu. Các bảng nghiệp vụ (user_addresses, orders...) đều khai báo
 * khoá ngoại uuid nên cần chuẩn hoá id trước khi truy vấn.
 */

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const DEMO_USER_IDS: Record<string, string> = {
  // Admin
  '00000000-0000-0000-0000-000000000001': '0f444d92-322c-4956-b452-0c5c10950508',
  'usr-admin-001': '0f444d92-322c-4956-b452-0c5c10950508',
  // Staff
  '00000000-0000-0000-0000-000000000004': 'd604e122-aa50-47e0-ac44-10a2473af6ce',
  'usr-staff-001': 'd604e122-aa50-47e0-ac44-10a2473af6ce',
  // Khách hàng mẫu
  '00000000-0000-0000-0000-000000000002': '7fb74d58-4155-4ab5-8124-cb0b5bb6651d',
};

/**
 * Ánh xạ email tài khoản mẫu -> uuid trong bảng auth.users / public.profiles.
 *
 * Giá trị BẮT BUỘC là uuid vì kết quả được dùng trực tiếp làm `user_id`
 * cho các bảng có khoá ngoại (user_addresses, orders...).
 */
const DEMO_USER_EMAILS: Record<string, string> = {
  'admin@gmail.com': '0f444d92-322c-4956-b452-0c5c10950508',
  'admin@menshop.vn': '0f444d92-322c-4956-b452-0c5c10950508',
  'staff@gmail.com': 'd604e122-aa50-47e0-ac44-10a2473af6ce',
  'staff@menshop.vn': 'd604e122-aa50-47e0-ac44-10a2473af6ce',
  'user@menshop.vn': '7fb74d58-4155-4ab5-8124-cb0b5bb6651d',
  'user@gmail.com': '7fb74d58-4155-4ab5-8124-cb0b5bb6651d',
};

/** Khách hàng dùng chung khi không xác định được user cụ thể */
export const FALLBACK_CUSTOMER_ID = '7fb74d58-4155-4ab5-8124-cb0b5bb6651d';

export const isUuid = (value: unknown): value is string =>
  typeof value === 'string' && UUID_PATTERN.test(value);

/**
 * Chuẩn hoá định danh người dùng về uuid hợp lệ.
 * Trả về `null` nếu không xác định được (id rỗng hoặc không phải uuid).
 */
export const resolveUserUuid = (
  userId?: string | null,
  userEmail?: string | null
): string | null => {
  const byId = userId?.trim();
  if (byId) {
    if (DEMO_USER_IDS[byId]) return DEMO_USER_IDS[byId];
    if (isUuid(byId)) return byId;
  }

  const byEmail = userEmail?.trim().toLowerCase();
  if (byEmail) {
    const mapped = DEMO_USER_EMAILS[byEmail];
    if (mapped) return mapped;
  }

  return null;
};

/**
 * Chuẩn hoá định danh người dùng, luôn trả về một uuid.
 * Dùng cho các bảng bắt buộc có khoá ngoại (orders, user_addresses...).
 */
export const resolveUserUuidOrDefault = (
  userId?: string | null,
  userEmail?: string | null
): string => resolveUserUuid(userId, userEmail) ?? FALLBACK_CUSTOMER_ID;

/** Chuẩn hoá email: cắt khoảng trắng + chuyển chữ thường. */
export const normalizeEmail = (email?: string | null): string =>
  (email ?? '').trim().toLowerCase();
