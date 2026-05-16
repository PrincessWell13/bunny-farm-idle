# 🐇 GAME DESIGN DOCUMENT — Bunny Farm Idle
## Phiên bản 2.0 — Bản nâng cấp hoàn chỉnh

---

## 1. TỔNG QUAN

| Trường | Nội dung |
|---|---|
| **Tên game** | Bunny Farm Idle *(working title)* |
| **Thể loại** | Idle · Simulation · Breeding · Light Strategy |
| **Phong cách** | Pixel 2D — top-down + side-view hybrid |
| **Nền tảng** | Android / iOS (ưu tiên) · PC (port sau) |
| **Đối tượng** | Casual player 13–35 tuổi |
| **Thời gian chơi mục tiêu** | 5–20 phút/ngày (casual) · 1–2 giờ (hardcore) |
| **USP** | Hệ thống di truyền có chiều sâu thực sự — mỗi quyết định lai giống tạo ra kết quả khác nhau và không thể đoán trước 100% |

### Core Fantasy
> *"Bạn là nhà khoa học-nông dân. Trang trại của bạn không chỉ là nơi nuôi thỏ — đó là phòng thí nghiệm gene sống động. Mỗi con thỏ huyền thoại bạn tạo ra là một tuyệt phẩm duy nhất trên thế giới."*

---

## 2. GAMEPLAY LOOPS

### 2.1 Core Loop (3–10 phút/vòng)
```
Nhận thỏ → Chăm sóc → Trưởng thành → Lai giống → Thu hoạch → Tái đầu tư
```

- **Nhận thỏ**: Mua tại Shop, nhận từ Event, tìm thấy khi Expedition, trade với player khác
- **Chăm sóc**: Cho ăn, dọn chuồng, chơi với thỏ, chữa bệnh
- **Trưởng thành**: Thanh Growth đầy → thỏ có thể sinh sản và bán được
- **Lai giống**: Chọn bố + mẹ → xem kết quả gene → con ra đời
- **Thu hoạch**: Bán thỏ thường, giữ thỏ tốt gene, gửi thỏ đi expedition

### 2.2 Meta Loop (ngày/tuần)
- Hoàn thiện Bộ sưu tập (Pokedex thỏ)
- Tối ưu chuỗi gene (build "dòng giống thuần chủng")
- Leo rank Hội thỏ
- Chuẩn bị cho World Event theo mùa

### 2.3 Endgame Loop
- Prestige → reset với bonus → chơi nhanh hơn
- Hunt Legendary rabbit (siêu hiếm, xác suất cố định)
- Tham gia Guild Raid boss rabbit
- Đóng góp vào Bunny World Economy

---

## 3. HỆ THỐNG CỐT LÕI

### 3.1 Hệ thống thỏ (Rabbit System)

#### Thuộc tính hiển thị

| Stat | Phạm vi | Giảm khi | Hệ quả nếu về 0 |
|---|---|---|---|
| Hunger | 0–100 | Theo thời gian thực | Health giảm 1/phút |
| Happiness | 0–100 | Không được chơi, chuồng bẩn | Fertility −30%, Growth −15% |
| Health | 0–100 | Đói lâu, bệnh | Thỏ chết nếu = 0 |
| Cleanliness | 0–100 | Theo thời gian | Happiness −, Disease chance + |

#### Thuộc tính ẩn
- **Growth Rate** — thỏ lớn nhanh hay chậm
- **Fertility** — khả năng sinh sản
- **Mutation Chance** — xác suất đột biến gene
- **Lifespan** — thỏ già sẽ nghỉ hưu (không chết, vào Sanctuary)
- **Aura** — thỏ đặc biệt tỏa aura buff cho thỏ xung quanh

#### Vòng đời thỏ
```
Baby → Juvenile → Adult → Elder → Sanctuary
```
- Baby: không thể sinh sản, cần chăm sóc nhiều nhất
- Juvenile: bắt đầu phát triển trait
- Adult: có thể lai giống, bán, expedition
- Elder: Fertility giảm 50%, Aura effect tăng 2x
- Sanctuary: passive buff toàn trang trại

---

### 3.2 Hệ thống di truyền (Genetics System) — Core Differentiator

#### Bộ gene (Genome)
Mỗi thỏ có **6 gene slot**, mỗi slot có 2 allele:
```
[Màu A / Màu B] [Kích thước A / B] [Tai A / B] [Trait1 A / B] [Trait2 A / B] [Đặc biệt A / B]
```

#### Bảng màu lông và độ hiếm

| Màu | Xác suất tự nhiên | Cần lai để ra |
|---|---|---|
| Trắng, Nâu, Xám | 60% | Không |
| Đốm, Vằn, Tam thể | 25% | Có thể random |
| Vàng (Gold), Bạc (Silver) | 10% | Cần 2 thỏ có allele Gold/Silver |
| Thiên hà (Galaxy) | 3% | Cần mutation đặc biệt |
| Cầu vồng (Rainbow) | 1% | Cần 3 thế hệ lai |
| Huyền thoại (Legendary) | 0.1% | Cần điều kiện đặc biệt + item |

#### Trait System — 24 trait chia 3 tier

**Tier 1 — Phổ thông**
- Fast Eater, Efficient Eater, Active, Calm, Sturdy, Curious

**Tier 2 — Nâng cao**
- Speed Grower (+25%), High Fertility (+20%), Lucky (+10% drop rate), Charming (+15% bán)

**Tier 3 — Huyền thoại**
- Gene Beacon, Immortal Gene, Mutation Master (+5%), Golden Touch (+25% coin), Legendary Blood (+0.5%)

#### Cơ chế lai giống
```
Con nhận 1 allele ngẫu nhiên từ mỗi slot của bố và mẹ
+ Mutation roll (base 5%, tăng theo item và trait)
+ Environment bonus (chuồng đặc biệt tăng mutation)
```

**Gene Preview**: Trước khi lai, người chơi thấy xác suất các kết quả (Pie chart) — tạo cảm giác chiến lược và hồi hộp.

#### Trait Stacking
- Cộng hưởng: Fast Grower + Efficient Eater = "Optimized" bonus x1.3
- Triệt tiêu: Calm + Active = chỉ giữ trait mạnh hơn
- Hidden combo: 3 trait đặc biệt → Ultra Trait (discovery system)

---

### 3.3 Hệ thống thức ăn (Food & Nutrition)

| Thức ăn | Tác dụng | Nguồn | Chi phí |
|---|---|---|---|
| Cỏ thường | Hunger +30 | Shop, tự trồng | Rẻ nhất |
| Cà rốt | Hunger +40, Growth +10 | Shop, vườn | Trung bình |
| Cà rốt ngôi sao | Growth +25, Happy +10 | Expedition, event | Cao |
| Vitamin C | Fertility +15, Health +10 | Craft | Trung bình |
| Thức ăn năng lượng | Growth Rate +50% trong 1 giờ | Gem shop | Premium |
| Nấm huyền bí | Mutation Chance +10% trong 30 phút | Rare drop | Rất hiếm |
| Trà thảo mộc | Lifespan +20%, Elder buff +50% | Craft | Cao |
| Táo vàng | Gold coat chance +5% lứa tiếp theo | Legendary drop | Cực hiếm |

**Farm Plot**: Người chơi trồng rau tự cung tự cấp. Thỏ Elder có thể làm "Gardener".

---

### 3.4 Hệ thống chuồng (Habitat System)

| Cấp | Capacity | Bonus | Mở khóa |
|---|---|---|---|
| 1 — Chuồng gỗ | 4 thỏ | — | Mặc định |
| 2 — Chuồng gạch | 8 thỏ | Growth +5% | 500 coin |
| 3 — Chuồng thủy tinh | 12 thỏ | Happiness auto-regen | 2,000 coin |
| 4 — Chuồng sinh thái | 16 thỏ | Disease immune, Fertility +10% | 10,000 coin + blueprint |
| 5 — Chuồng vũ trụ | 24 thỏ | Mutation +5%, Legendary +0.1% | Prestige unlock |

**Chuồng chuyên dụng**:
- Chuồng thiền — Happiness 100%, Growth −20%
- Lab Chuồng — Mutation +15%, tốn 10 Gem/ngày
- Sanctuary — Aura buff toàn trang trại
- Vườn ươm — Baby lớn nhanh hơn 50%

---

### 3.5 Hệ thống Thời tiết & Mùa vụ

4 mùa (7 ngày in-game/mùa):

| Mùa | Hiệu ứng | Thỏ đặc biệt |
|---|---|---|
| Xuân | Fertility +30% | Spring Bunny (xanh lá) |
| Hạ | Growth Rate +20% | Summer Bunny (cam) |
| Thu | Harvest bonus +50% | Harvest Bunny (vàng đỏ) |
| Đông | Offline production +30% | Snow Bunny (trắng tuyết) |

---

### 3.6 Hệ thống Expedition

| Khu vực | Thời gian | Loot | Yêu cầu |
|---|---|---|---|
| Rừng Gần | 30 phút | Cỏ ngôi sao, Herb | 1 thỏ Adult |
| Đồng Cỏ Phía Đông | 2 giờ | Cà rốt đặc biệt, Coin x3 | 2 thỏ Adult |
| Núi Tuyết | 8 giờ | Nấm huyền bí, Blueprint | 3 thỏ có Sturdy |
| Vùng Đất Cổ | 24 giờ | Táo vàng, Legendary shard | 5 thỏ + item |
| Vũ trụ Thỏ (Prestige) | 48 giờ | Cosmic gene, Ultra shard | Sau Prestige 1 |

---

### 3.7 Hệ thống Gene Puzzle

**Breeding Challenge** (ví dụ):
- "Tạo thỏ có 3 trait Tier 2 trở lên" → thưởng Blueprint
- "Lai ra thỏ Galaxy trong 10 thế hệ" → thưởng Legendary shard

**Gene Journal**: Cây phả hệ của từng thỏ, chia sẻ được với bạn bè/Guild.

---

### 3.8 Hệ thống Kinh tế

#### Đơn vị tiền tệ

| Currency | Nguồn | Dùng để |
|---|---|---|
| 🥕 Carrot Coin (CC) | Bán thỏ, Quest, Idle | Mua thức ăn, nâng chuồng |
| ✨ Star Dust | Expedition, Event | Rare item, craft |
| 💎 Crystal Gem | IAP, rare achievement | Skin, speed-up, premium |
| 🔬 Gene Fragment | Dismantle thỏ | Craft Gene item |

#### Giá thỏ
- Thỏ thường: 10–200 CC
- Thỏ Rare: 500–5,000 CC
- Thỏ Legendary: 10,000–50,000 CC + Star Dust

#### Thương lái ngẫu nhiên (mỗi 4–8 giờ)
- "3 thỏ màu Đốm trong 2 giờ" → thưởng x3
- "Thỏ có Fast Grower trả gấp đôi hôm nay"
- "Thỏ Elder Sanctuary để nghiên cứu" → đổi Star Dust

---

### 3.9 Guild System

- Tối đa 20 thành viên
- Guild Farm: đóng góp điểm chung
- Guild Boss Raid: xuất hiện mỗi tuần → Boss Fragment → craft thỏ mạnh
- Thị trường Guild: trade nội bộ
- Guild Leaderboard: xếp hạng theo gene score

---

### 3.10 Event System

#### Thường xuyên
| Event | Tần suất | Nội dung |
|---|---|---|
| Carrot Festival | Mỗi tháng | Thức ăn −50%, Fertility x2 |
| Bunny Olympics | Mỗi tháng | Thi đua tốc độ, sức mạnh |
| Moonlight Breeding | Mỗi tuần (đêm) | Mutation +10% trong 3 giờ |
| Merchant Caravan | 2 ngày/lần | Item hiếm |

#### World Event (1 lần/tháng)
- "Legendary Bunny Appears": guild tích điểm nhiều nhất sở hữu thỏ
- "Gene Plague": craft vaccine cộng đồng → thưởng chung

---

### 3.11 Mini-games

| Mini-game | Cơ chế | Thưởng |
|---|---|---|
| Carrot Dash | Endless runner | Food, Coin |
| Bunny Match | Match-3 | Star Dust |
| Gene Tetris | Xếp gene block | Gene Fragment |
| Farm Defense | Tower defense | Coin, Blueprint |
| Speed Feed | Click nhanh 30 giây | Food bonus |

---

### 3.12 Idle & Offline

| Trạng thái | Tốc độ sản xuất |
|---|---|
| Online | 100% |
| Background | 75% |
| Offline <4 giờ | 60% |
| Offline 4–12 giờ | 50% |
| Offline >12 giờ | 40% (hard cap) |

**Offline items**: Alarm Bunny (+70%), Auto-Feeder, Security Dog

---

## 4. PROGRESSION

### Early Game (giờ 1–10)
- 1–2 chuồng, 4–6 thỏ cơ bản
- Học: cho ăn, chăm sóc, bán thỏ
- Mục tiêu: tích đủ coin mua chuồng cấp 2

### Mid Game (ngày 2–14)
- Unlock Breeding → điểm ngoặt cảm xúc
- Khám phá Trait system, mở Expedition đầu tiên
- Mục tiêu: tạo ra con thỏ Rare đầu tiên

### Late Game (tuần 3–8)
- Hunting Legendary rabbit
- Optimize Gene chain (3–4 thế hệ)
- Guild Boss Raid

### Endgame
- Prestige và bắt đầu lại mạnh hơn
- World Event participation
- Achievement hunting

---

## 5. PRESTIGE SYSTEM

**Điều kiện**: ≥1 thỏ Legendary + 80% Bộ sưu tập.

**Reset**: Coin, thỏ thường, chuồng cơ bản
**Giữ lại**: Thỏ Legendary, Guild rank, Blueprint, item đặc biệt

| Lần Prestige | Bonus vĩnh viễn |
|---|---|
| 1 | Growth Rate +15% |
| 2 | Mutation Chance +8% |
| 3 | Offline production +15% |
| 4 | +1 slot Expedition |
| 5 | Unlock Chuồng Vũ Trụ |
| 10 | Legendary chance +0.5% |
| 20 | Unlock Cosmic Rabbit |

**Prestige Title**: Tân binh → Nông dân → Nhà khoa học → Huyền thoại → Thần Thỏ

---

## 6. BALANCE

### Thời gian mục tiêu
- Baby → Adult: 4 giờ (base), 2 giờ (max upgrade)
- Thỏ thường → 100 CC: 1–2 giờ idle
- Thỏ Rare → 1,000 CC: 1–2 ngày active
- Thỏ Legendary → 10,000+ CC: 1–2 tuần optimize

### Nguyên tắc
- Không pay-to-win: Gem chỉ speed-up và cosmetic
- Player-driven economy: giá thỏ do cộng đồng quyết định
- Soft cap Idle: tránh offline farm quá mạnh

---

## 7. UI/UX

### Main Screen Layout
```
[Header: Tên + Coin + Gem + Notification]
[Bản đồ trang trại có thể scroll — thỏ chạy nhảy]
[Bottom bar: Trang trại | Breeding | Guild | Shop | Quest]
```

### UX Principles
- Không quá 2 tap để thực hiện hành động thường xuyên
- Notification thông minh: chỉ báo khi thỏ đói
- One-hand friendly: dùng được bằng ngón cái
- Dark mode / Light mode tự động

### Accessibility
- Text size tùy chỉnh
- Colorblind mode
- Simplified mode cho người mới

---

## 8. ART DIRECTION

- **Style**: Pixel 16-bit, warm pastel palette
- **Sprite thỏ**: 32×32px, animated 4–8 frames
- **Background**: Parallax scrolling 3 lớp

### Palette chính
- Nền: Xanh mềm (#B8E4B8), Be ấm (#F5E6D3)
- UI: Trắng kem (#FAFAF5), Nâu gỗ (#8B6B4A)
- Accent: Cam cà rốt (#FF8C42), Tím huyền bí (#9B72CF)

### Animation thỏ
- Idle: Thở, nháy mắt, ngọ ngoạy tai
- Ăn: Gật đầu nhịp nhàng
- Vui: Nhảy lên, quay vòng
- Buồn: Cúi đầu, tai xụ
- Legendary reveal: Dramatic flash + particle explosion

---

## 9. MONETIZATION

### Triết lý
> *"Người chơi trả tiền vì yêu game, không vì bị ép."*

### Ads (opt-in)
- x2 offline reward (1 lần/4 giờ)
- Roll gene thêm 1 lần
- KHÔNG forced ads, KHÔNG interstitial

### IAP
| Gói | Giá | Nội dung |
|---|---|---|
| Starter Pack | $0.99 | Gem x100 + Skin |
| Monthly Pass | $4.99/tháng | Gem x30/ngày + Offline +10% |
| Bunny Lab | $9.99 | Lab Chuồng vĩnh viễn |
| Cosmetic Bundle | $2.99 | 3 Skin set |

**KHÔNG bán**: Legendary rabbit, stat boost pay-to-win

---

## 10. MVP SCOPE (v1.0)

- [ ] 5 loại thỏ cơ bản (3 màu, 2 trait)
- [ ] Core breeding (4 gene slot)
- [ ] 3 loại thức ăn
- [ ] 2 loại chuồng
- [ ] Hệ thống coin + shop
- [ ] Idle production offline
- [ ] 3 Quest ngày
- [ ] UI cơ bản đầy đủ

---

## 11. TECH STACK

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Backend**: Firebase (Realtime DB + Auth + Cloud Functions)
- **Animation**: Aseprite → Godot AnimationPlayer

---

## 12. KPI THÀNH CÔNG

- D1 Retention: ≥ 40%
- D7 Retention: ≥ 20%
- D30 Retention: ≥ 8%
- Session length: 8–15 phút trung bình
- Conversion free → paid: ≥ 3%
