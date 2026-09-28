# ĐỒ ÁN: APP BÁN HÀNG (KIỂU SHOPEE)
### Bản mô tả dễ hiểu — ai làm được gì trong app

> Công nghệ: Flutter (app điện thoại) · Node.js (máy chủ) · PostgreSQL (cơ sở dữ liệu) · VNPay (thanh toán thử)

---

## App này là gì?

Đây là một **cái chợ online** giống Shopee: rất nhiều shop cùng bán hàng trên một app.
Người dùng mở app lên, tìm đồ, bỏ vào giỏ, trả tiền, rồi chờ shop giao. Sau khi nhận hàng thì đánh giá sao.

Trong app có **4 kiểu người dùng** và **1 hệ thống bên ngoài** (VNPay lo phần tiền).

---

## Những ai tham gia vào app?

| Ai | Là người như thế nào |
|----|----------------------|
| **Khách vãng lai** | Người mới vào app, **chưa đăng nhập**. Chỉ được xem hàng, muốn mua thì phải đăng ký. |
| **Người mua** | Khách hàng đã có tài khoản. Đây là người dùng chính. |
| **Người bán** | Chủ shop. Đăng hàng lên bán và xử lý đơn của khách. |
| **Admin** | Người quản lý cả cái chợ. Kiểm soát mọi thứ cho công bằng, an toàn. |
| **VNPay** | Không phải người — là dịch vụ ngân hàng lo việc trừ tiền, hoàn tiền. |

> Lưu ý: một người vừa có thể **đi mua** vừa **mở shop bán** (giống Shopee thật).

---

## 1. KHÁCH VÃNG LAI làm được gì?

Người chưa đăng nhập, chỉ được "ngó" thôi:

- Xem danh sách hàng và bấm vào xem chi tiết từng món
- Tìm kiếm và lọc hàng (theo giá, loại hàng, số sao)
- Xem trang của một shop
- **Muốn mua thì phải đăng ký / đăng nhập**

## 2. NGƯỜI MUA làm được gì?

Đây là phần quan trọng nhất, làm chắc phần này điểm sẽ cao.

**Về tài khoản:**
- Đăng ký, đăng nhập, quên mật khẩu thì lấy lại được
- Sửa thông tin cá nhân, đổi mật khẩu
- Lưu nhiều địa chỉ nhận hàng (nhà, công ty...)
- Đăng ký mở shop nếu muốn bán hàng

**Về mua sắm:**
- Tìm, lọc, xem chi tiết hàng; chọn loại (size, màu)
- Bỏ hàng vào giỏ, sửa số lượng, xóa bớt
- Giỏ hàng gộp được nhiều shop cùng lúc
- Đặt hàng, chọn địa chỉ giao
- Trả tiền qua **VNPay** hoặc **trả khi nhận hàng (COD)**
- Áp mã giảm giá khi thanh toán

**Sau khi mua:**
- Xem lại các đơn đã đặt và trạng thái (đang gói, đang giao, xong...)
- Hủy đơn nếu shop chưa xác nhận
- Đánh giá sao + viết nhận xét cho món hàng
- Nhắn tin trực tiếp với shop để hỏi
- Yêu cầu **trả hàng / hoàn tiền** nếu hàng lỗi

**Tiện ích thêm:**
- Bấm tim lưu hàng yêu thích để xem sau
- Theo dõi shop mình thích
- Đánh giá shop
- Xem gợi ý "hàng liên quan" và lịch sử đã xem
- Nhận thông báo khi đơn cập nhật hoặc có khuyến mãi

## 3. NGƯỜI BÁN (chủ shop) làm được gì?

**Về hàng hóa:**
- Đăng hàng mới, sửa, xóa hoặc tạm ẩn
- Upload ảnh sản phẩm
- Quản lý phân loại và số lượng tồn kho

**Về đơn hàng:**
- Xem các đơn khách đặt ở shop mình
- Xác nhận hoặc từ chối đơn
- Cập nhật trạng thái: đã gói xong → đang giao...
- Duyệt hoặc từ chối yêu cầu trả hàng

**Về khách:**
- Trả lời tin nhắn của khách
- Trả lời các đánh giá

**Về khuyến mãi & báo cáo:**
- Tạo mã giảm giá riêng cho shop
- Tạo chương trình flash sale (giảm giá theo giờ)
- Xem bảng doanh thu, hàng nào bán chạy, biểu đồ theo thời gian

## 4. ADMIN (người quản lý chợ) làm được gì?

- Quản lý người dùng: khóa tài khoản xấu, mở lại khi cần
- Duyệt shop mới đăng ký (cho phép bán hay không)
- Duyệt sản phẩm mới trước khi lên sàn
- Quản lý danh mục (điện thoại, quần áo, đồ ăn...)
- Xử lý báo cáo vi phạm và khiếu nại trả hàng
- Tạo mã giảm giá áp cho **cả sàn**
- Đăng banner quảng cáo ở trang chủ
- Gửi thông báo chung cho mọi người
- Xem thống kê tổng: tổng tiền, tổng đơn, tổng người dùng
- Xem nhật ký hoạt động (ai làm gì, lúc nào)

## 5. VNPAY (dịch vụ thanh toán) làm gì?

- Nhận lệnh thanh toán khi khách bấm trả tiền
- Báo kết quả về app (thành công / thất bại)
- Hoàn tiền lại cho khách khi được duyệt trả hàng

---

## Nên làm cái nào trước? (rất quan trọng cho nhóm 5 người)

Đừng làm hết một lúc. Làm theo 3 bước:

**Bước 1 — Bắt buộc phải xong (đây là phần chấm điểm chính):**
Đăng ký/đăng nhập → tìm hàng → bỏ giỏ → đặt hàng → thanh toán → shop xử lý đơn → khách nhận và đánh giá. Làm cho **chạy mượt, không lỗi**.

**Bước 2 — Nên có (làm thêm để đẹp điểm):**
Yêu thích, theo dõi shop, thông báo, mã giảm giá.

**Bước 3 — Nâng cao (làm được thì thầy cô rất thích):**
Trả hàng/hoàn tiền, duyệt sản phẩm, banner, nhật ký hoạt động.

**Chưa cần làm — chỉ ghi vào phần "hướng phát triển" trong báo cáo:**
Ví điện tử, theo dõi giao hàng bằng bản đồ GPS, gợi ý hàng bằng AI, đăng nhập bằng Google/Facebook.

---

## PHÍA BACKEND (máy chủ) làm gì?

Nếu app trên điện thoại là "bộ mặt" khách nhìn thấy, thì **backend là cái bếp phía sau** — chạy ngầm, xử lý mọi thứ nặng nhọc rồi trả kết quả về cho app. Khách không nhìn thấy nhưng thiếu nó thì app không chạy được.

**1. Nhận và trả dữ liệu cho app (API)**
Mỗi khi app cần gì (danh sách hàng, chi tiết đơn...), nó "hỏi" backend, backend lấy từ cơ sở dữ liệu rồi gửi về. Mỗi chức năng ở trên đều có một hoặc vài API tương ứng.

**2. Kiểm tra đăng nhập & phân quyền**
- Mã hóa mật khẩu trước khi lưu (không lưu mật khẩu thô)
- Cấp "vé" đăng nhập (JWT) cho mỗi lần đăng nhập
- Kiểm tra: người này là khách, shop hay admin? Có được phép làm việc này không? (VD: khách không được vào trang admin)

**3. Lưu trữ dữ liệu (Database)**
Lưu toàn bộ: tài khoản, sản phẩm, đơn hàng, đánh giá, tin nhắn... trong PostgreSQL, và thiết kế các bảng liên kết với nhau cho đúng.

**4. Xử lý ảnh**
Nhận ảnh sản phẩm shop upload lên, lưu lên dịch vụ ảnh (Cloudinary) và trả về đường link.

**5. Xử lý thanh toán VNPay**
- Tạo lệnh thanh toán, chuyển khách sang trang VNPay
- Khi VNPay báo về, **kiểm tra chữ ký** xem có phải thật không (chống gian lận), rồi cập nhật đơn thành "đã thanh toán"

**6. Chat real-time**
Chạy máy chủ Socket.io để tin nhắn giữa khách và shop hiện ra ngay lập tức, không cần tải lại.

**7. Gửi thông báo đẩy**
Khi đơn đổi trạng thái hoặc có khuyến mãi, backend tự đẩy thông báo về điện thoại người dùng.

**8. Xử lý nghiệp vụ ngầm (phần quan trọng, hay bị quên)**
- Tính tổng tiền đơn, cộng phí, trừ tiền giảm giá của voucher
- **Trừ số lượng tồn kho** khi có người mua
- Kiểm tra voucher còn hạn / còn lượt không
- Tự động **hủy đơn** nếu quá lâu không thanh toán
- Tự bật/tắt flash sale đúng giờ

**9. Bảo mật & kiểm tra dữ liệu**
Kiểm tra dữ liệu app gửi lên có hợp lệ không (VD: giá không được âm), chặn spam, chống truy cập trái phép.

**10. Tổng hợp thống kê**
Tính doanh thu, số đơn, hàng bán chạy... để trả về cho dashboard của shop và admin.

> **Gợi ý chia việc backend cho nhóm:**
> - Bạn 1: Tài khoản + phân quyền + Sản phẩm/Danh mục (mục 1, 2, 3, 4)
> - Bạn 2: Giỏ hàng + Đơn hàng + Thanh toán VNPay + Nghiệp vụ ngầm (mục 5, 8)
> - Chat real-time + Thông báo (mục 6, 7) chia cho người rảnh hơn.

---

*Tài liệu đồ án tốt nghiệp — nhóm 5 thành viên. Bản đầy đủ theo mã UC01–UC74 để trong file kỹ thuật.*
