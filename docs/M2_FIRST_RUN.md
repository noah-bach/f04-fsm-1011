# F04 — lần chạy mô phỏng chức năng đầu tiên

Đây là bản khởi đầu để học bằng thao tác. AI đã soạn RTL, testbench và script.
Sinh viên cần chạy, đọc, giải thích và tự sửa chúng. Chưa coi M1/M2 được nghiệm
thu chỉ vì đã tải các file. Chưa có synthesis, PPA hoặc layout của lần chạy này.

## Các file có vai trò gì?

| File | Vai trò |
|---|---|
| rtl/f04_mealy.sv | Lõi Mealy, 4 trạng thái S0–S3 |
| rtl/f04_moore.sv | Lõi Moore, 5 trạng thái S0–S4 |
| rtl/tt_um_f04_fsm_1011.sv | Top module: nối hai lõi và ánh xạ đúng chân F04 |
| tb/tb_f04.sv | Testbench: đưa dữ liệu vào và tự so sánh đúng/sai |
| scripts/run_sim.sh | Biên dịch, mô phỏng, lưu phiên bản/lệnh/log gốc |
| scripts/view_wave.sh | Mở dạng sóng của lần chạy thành công gần nhất |

RTL (Register Transfer Level — mô tả phần cứng ở mức thanh ghi) là cách viết
bộ nhớ trạng thái và logic của mạch. Testbench (bộ kiểm thử mô phỏng) tạo clock,
reset và luồng bit để kiểm tra RTL; nó không phải khối đem đi chế tạo.
Reference model (mô hình tham chiếu) ở đây giữ bốn bit đã nhận gần nhất, không
chép bảng case của FSM. Waveform (dạng sóng) cho thấy tín hiệu theo thời gian.

## Đặc tả dùng cho bản khởi đầu

Các lựa chọn clock/reset/enable dưới đây là giả định thiết kế được ghi rõ vì
charter chưa chốt chúng; cần đối chiếu lại nếu giảng viên bổ sung yêu cầu.

| Cổng | Chiều/độ rộng | Cách dùng |
|---|---|---|
| clk | Input, 1 bit | Nhận dữ liệu ở cạnh lên, 0 sang 1 |
| rst_n | Input, 1 bit | Reset đồng bộ mức 0 tích cực, ưu tiên hơn ena |
| ena | Input, 1 bit | 1: nhận bit; 0: giữ trạng thái, bỏ qua bit |
| ui_in | Input, 8 bit | Không dùng |
| uio_in | Input, 8 bit | [0] là bit dữ liệu; [7:1] không dùng |
| uo_out | Output, 8 bit | [0] Mealy; [1] Moore; [5:2] trạng thái Moore |
| uio_out | Output, 8 bit | Buộc về 0 |
| uio_oe | Output, 8 bit | Buộc về 0: các chân uio là đầu vào |

uo_out[7:6] bằng 0. Mã trạng thái Moore là S0=0, S1=1, S2=2, S3=3, S4=4;
xuất thành bốn bit có bit cao bằng 0. Bốn chân debug không đồng nghĩa bốn
flip-flop sau synthesis. Flip-flop (phần tử nhớ một bit) tạo bộ nhớ trạng thái;
số thực tế phải đọc từ report tổng hợp, có thể bị ảnh hưởng bởi việc đổi mã FSM.

Khi rst_n=0 tại cạnh lên, cả hai lõi về S0 kể cả khi ena=0. Khi reset không tích
cực và ena=0, hai lõi giữ trạng thái. Top che cả hai đầu ra phát hiện về 0 khi
rst_n=0 hoặc ena=0. Đầu ra của lõi Moore phụ thuộc trạng thái; đầu ra ngoài top
còn phụ thuộc hai tín hiệu điều khiển này. Debug không bị che: nó giữ giá trị
khi tạm dừng, và chỉ về 0 ở cạnh lên reset. Testbench thay đổi cả các bit input
không dùng để kiểm tra chúng không làm sai chức năng.

## Đọc ba đoạn code quan trọng

- `always @(posedge clk)`: cập nhật bộ nhớ tại rising edge (cạnh lên).
- `state <= ...`: nonblocking assignment (phép gán không chặn), dùng cho bộ
  nhớ tuần tự; testbench đợi sau cạnh để quan sát trạng thái đã cập nhật.
- `always @*` và `case (state)`: logic tổ hợp tính trạng thái kế tiếp; có thể
  tính ngay khi input đổi, nhưng chưa ghi vào bộ nhớ trước cạnh clock.
- Mealy: `detect = (state == S3) && bit_in`.
- Moore: `detect = (state == S4)`.

Điều cần tự giải thích: sau S3 nhận 1, Mealy giữ phần cuối 1 nên về S1;
Moore vào S4 để biểu thị vừa nhận đủ mẫu. Sau S4 nhận 0, giữ phần cuối 10 nên
về S2. Đây là lý do vẫn nhận được mẫu chồng lấn.

## Thời điểm đưa bit và kiểm tra

Clock trong testbench đổi mức mỗi 5 ns, nên một chu kỳ là 10 ns. ns là nano
giây, 1 ns = 10^-9 giây. Đây là lựa chọn minh họa mô phỏng, không phải số liệu
Fmax hoặc khả năng vận hành thật.

Testbench thay input/reset/enable ở falling edge (cạnh xuống, 1 sang 0). Nó
đọc Mealy 1 ns trước cạnh lên nhận bit, rồi đọc Moore 1 ns sau cùng cạnh đó.
Nó cũng kiểm tra cả hai tín hiệu ở cả hai thời điểm với đúng kỳ vọng tương ứng.
Việc thay input cách cạnh lấy mẫu tránh race condition (tranh chấp thứ tự
thực thi trong mô phỏng).

Đầu ra tổ hợp Mealy có thể đổi sau khi trạng thái đổi dù bit input còn được
giữ. Ví dụ sau khi đã nhận 101, trạng thái là S3, input còn 1 có thể làm Mealy
cao. Nếu bit kế tiếp được đổi thành 0 trước cạnh nhận tiếp theo, vẫn chưa có
mẫu 1011 được nhận. Vì vậy chỉ đếm quan sát Mealy trước cạnh nhận bit; không
đếm mọi mức 1 xuất hiện trong dạng sóng thành một mẫu hợp lệ.

Mẫu hoàn tất ở một cạnh: Mealy được kiểm tra trước cạnh đó, Moore sau chính
cạnh đó. Nếu một flip-flop tầng sau lấy mẫu tại cạnh lên, nó đọc trạng thái
Moore cũ. Không kết luận chung rằng hai mức đầu ra luôn lệch nguyên một chu kỳ
khi chưa nêu thời điểm quan sát và cách tầng sau lấy mẫu.

## Các ca kiểm tra và lỗi bắt được

- Bắt buộc: 1011; 10111011; chuỗi không có mẫu; quan sát thời điểm đầu ra.
- 10111011 có mẫu ở 1–4 và 5–8: liền nhau, không dùng chung bit.
- Bổ sung 1011011: mẫu ở 1–4 và 4–7, chồng lấn tại bit 4; bắt lỗi quên hậu tố.
- Ba mẫu liền nhau: bắt đầu ra bị giữ mãi hoặc mất lần phát hiện kế tiếp.
- Chuỗi gần đúng và thiếu bit cuối: bắt phát hiện nhầm tại cạnh nhận bit.
- Reset giữa chuỗi: bắt việc giữ lịch sử cũ qua reset và ưu tiên reset sai.
- Enable tạm dừng: bắt việc vẫn nhận bit khi dừng, mất lịch sử hoặc che output sai.
- 1024 bit giả ngẫu nhiên và 256 chu kỳ có reset/enable giả ngẫu nhiên.

Seed (giá trị khởi đầu của bộ sinh dữ liệu) cố định giúp tái tạo luồng thử:
data=F0410111, unused_pin_noise=13579BDF, thuật toán xorshift32.
Assertion (kiểm tra điều kiện tự động) báo lỗi bằng `$fatal` khi expected (kỳ
vọng) khác actual (thực tế). Phép `!==` còn bắt giá trị X/Z chưa xác định.
Invariant (điều kiện luôn phải đúng) gồm chân không dùng bằng 0 và mã trạng
thái đúng. Transition coverage (bao phủ chuyển trạng thái) ở đây đếm các tổ
hợp trạng thái/input hợp lệ: phải thăm 8 tổ hợp Mealy và 10 tổ hợp Moore.
Bao phủ hữu hạn này chưa phải formal proof (chứng minh hình thức mọi hành vi).

## Chạy lại và giữ bằng chứng

Tại ~/projects/f04-fsm-1011:

```bash
bash scripts/run_sim.sh
```

Biên dịch (compile) bằng iverilog chuẩn bị file sim.vvp; mô phỏng (simulation)
bằng vvp thực thi file đó. Chỉ khi lần chạy thật tới dòng PASS F04, không có
FAIL/fatal, mới ghi nhận lần kiểm tra này thành công.

Mỗi lần có một thư mục riêng build/sim_runs/<UTC_timestamp>_<process_id>/:
manifest.txt, compile.log, sim.log, trace.csv, wave.vcd, sim.vvp. Manifest ghi
ngày UTC, commit hiện tại, trạng thái Git, phiên bản công cụ, hash mã nguồn,
seed, lệnh và thư mục chạy. Các file mới có thể chưa được commit; phải dùng
cả hash mã nguồn và trạng thái Git, không coi HEAD tự động đại diện mã mới.
Đây là mô phỏng RTL; không dùng PDK và không có số liệu PPA.

build/LAST_SIM_RUN.txt chỉ tới lần chạy đã hoàn tất gần nhất. Mở dạng sóng:

```bash
bash scripts/view_wave.sh
```

Trong GTKWave chọn tb_f04 ở cây hierarchy (cấu trúc các module). Chọn và đưa
clk, rst_n, ena, bit_in, detect_mealy, detect_moore, state_moore vào cửa sổ sóng.
Bắt đầu ở khoảng thời gian có case required_1011 trong trace.csv. Các cột
mealy_before và moore_after là hai quan sát dùng để đếm mẫu được nhận.

## Ghi AI và giới hạn

AI soạn bản khởi đầu; sinh viên chưa được đánh giá việc tự giải thích toàn bộ
mạch. Sau khi chạy, ghi mình đã kiểm tra gì/sửa gì trong docs/AI_USAGE_LOG.md.
Không ghi PASS chỉ vì trong hướng dẫn có mẫu dòng PASS. Chưa có synthesis,
STA, power, CTS, DRC/LVS hoặc layout; không suy ra các kết quả đó từ mô phỏng.

Nguồn chính thức của lệnh Icarus:
https://steveicarus.github.io/iverilog/usage/getting_started.html
