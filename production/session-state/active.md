# Session State — Bunny Farm Idle

**Ngày bắt đầu**: 2026-05-16
**Giai đoạn hiện tại**: Pre-production → Architecture

## Tiến độ hiện tại

- [x] Project khởi tạo từ CCGS template
- [x] Engine cấu hình: Godot 4.6 / GDScript
- [x] GDD lưu tại: `design/gdd/bunny-farm-idle-master.md`
- [x] Technical preferences cấu hình
- [ ] Architecture document (`docs/architecture/master-architecture.md`)
- [ ] ADRs cho các quyết định kỹ thuật quan trọng
- [ ] Epics tạo từ GDD
- [ ] Stories tạo từ Epics
- [ ] Implementation bắt đầu

## Quyết định đã đưa ra

1. **Engine**: Godot 4.6 (GDScript) — vì nhẹ, free, export Android/iOS tốt
2. **Scope**: Full game (không chỉ MVP)
3. **Workflow**: CCGS framework đầy đủ
4. **Platform**: Android/iOS primary, PC sau

## Files đang làm việc

- `design/gdd/bunny-farm-idle-master.md` — GDD chính (DONE)
- `docs/architecture/master-architecture.md` — TIẾP THEO
- `.claude/docs/technical-preferences.md` — DONE

## Bước tiếp theo

Tạo Architecture document — chạy `/create-architecture` trong project directory.

## Câu hỏi chờ trả lời

- Backend: Firebase hay PlayFab? (cần quyết định trước khi build social features)
- Multiplayer real-time hay async? (ảnh hưởng architecture)
