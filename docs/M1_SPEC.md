# M1 - Đặc tả nháp F04

## 1. Yêu cầu chức năng
Mạch nhận lần lượt các bit 0/1 và phát hiện mẫu cố định 1011.
Hai FSM Mealy và Moore cùng xử lý đầu vào; phải nhận được mẫu chồng lấn.
Bối cảnh: khối dò mẫu trong bộ thu không dây sau khi đã có các bit đồng bộ.
Tầng sau cần tín hiệu đánh dấu mẫu; cách lấy mẫu tín hiệu này còn cần chốt.

## 2. Ánh xạ bắt buộc
| Tín hiệu | Ý nghĩa |
|---|---|
| uio_in[0] | Bit đầu vào |
| uo_out[0] | Phát hiện Mealy |
| uo_out[1] | Phát hiện Moore |
| uo_out[5:2] | Trạng thái Moore |

## 3. Các chuỗi cần kiểm tra
- 1011: mẫu ở bit 1-4.
- 10111011: mẫu ở bit 1-4 và 5-8; hai mẫu liền nhau.
- 1011011: mẫu ở bit 1-4 và 4-7; chồng lấn tại bit 4.
- Chuỗi không có mẫu và reset giữa chuỗi.
Đây là kỳ vọng đặc tả, chưa phải kết quả mô phỏng.

## 4. Những điểm cần chốt trước RTL
- Clock (xung nhịp): cạnh lấy mẫu.
- Reset (đặt lại): mức tích cực, thời điểm có hiệu lực.
- Enable (cho phép hoạt động): hành vi khi tạm dừng.
- Giao diện đầy đủ và chân không dùng.
- Bảng chuyển trạng thái Moore, mã trạng thái quan sát.
- Thời điểm đưa bit và quan sát hai đầu ra.
