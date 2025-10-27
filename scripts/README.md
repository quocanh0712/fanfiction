# Figma Export Helper Tools

## 🎯 Vấn đề

Khi export hình ảnh từ Figma Desktop qua MCP, file SVG thường có các vấn đề:
- CSS variables không tương thích với `flutter_svg`
- Thiếu hoặc thừa closing tags
- Style attributes không cần thiết

## 🛠️ Giải pháp

### Cách 1: Sử dụng prompt tự động (Tự động hóa)

Chỉ cần nói với AI:
```
Export hình ảnh từ Figma selection này và lưu vào assets/images/ với tên ic_icon_name
```

AI sẽ tự động:
1. ✅ Lấy URL từ Figma Desktop MCP
2. ✅ Download file
3. ✅ Fix các lỗi SVG (CSS variables, structure, etc.)
4. ✅ Validate file
5. ✅ Thông báo kết quả

### Cách 2: Sử dụng script manual

Nếu cần fix file đã tải về:

```bash
# Fix file SVG
./scripts/fix_svg.sh assets/images/ic_icon_name.svg
```

### Cách 3: Sử dụng Flutter helper (Trong code)

```dart
import 'lib/utils/figma_asset_helper.dart';

// Download và fix asset tự động
final path = await FigmaAssetHelper.downloadAsset(
  url: 'http://localhost:3845/assets/xxx.svg',
  savePath: 'assets/images/ic_icon.svg',
);

// Validate asset
final isValid = await FigmaAssetHelper.validateAsset('assets/images/ic_icon.svg');
```

## 📋 Workflow đề xuất

1. **Mở Figma Desktop** và chọn node cần export
2. **Vào Cursor** và gửi prompt export với tên file
3. **AI tự động** download, fix và validate
4. **Hot reload** app để xem kết quả

## ⚠️ Troubleshooting

### Icon không hiển thị

1. Chạy `flutter clean && flutter pub get`
2. Hot restart app (nhấn `R` trong terminal)
3. Kiểm tra file có đầy đủ closing tag `</svg>`
4. Kiểm tra không có CSS variables trong SVG

### File download bị lỗi

1. Check URL từ localhost:3845 còn hoạt động không
2. Thử export lại từ Figma
3. Check network connection

## 🔍 Validate file thủ công

```bash
# Check SVG structure
head -1 assets/images/icon.svg
tail -1 assets/images/icon.svg

# Should see <svg ...> at start and </svg> at end

# Check for CSS variables
grep "var(--" assets/images/icon.svg
# Should return nothing if file is good
```

