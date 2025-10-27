# 🎨 Figma Export Workflow - Tự động fix lỗi

## ✨ Đã tự động hóa! Chỉ cần gửi prompt:

```
Export hình ảnh từ Figma selection này và lưu vào assets/[folder]/ với tên [filename]
```

## 🤖 AI sẽ tự động làm gì?

### Bước 1: Lấy URL từ Figma
```javascript
// AI sử dụng MCP tool
mcp_Figma_Desktop_get_design_context()
→ Lấy URL: "http://localhost:3845/assets/xxx.svg"
```

### Bước 2: Download file
```bash
curl -o assets/images/ic_icon.svg "http://localhost:3845/assets/xxx.svg"
```

### Bước 3: Tự động fix lỗi
```bash
# AI sẽ chạy các lệnh này tự động:
# 1. Fix CSS variables
sed -i '' 's/fill="var(--fill-0, white)"/fill="white"/g' file.svg

# 2. Fix stroke variables  
sed -i '' 's/stroke="var(--stroke-0, white)"/stroke="white"/g' file.svg

# 3. Remove style attributes
sed -i '' 's/ style="display: block;"//g' file.svg

# 4. Validate closing tag
if ! tail -1 file.svg | grep -q '</svg>'; then
    echo "</svg>" >> file.svg
fi
```

### Bước 4: Validate
```bash
# Check file structure
grep '<svg' file.svg && grep '</svg>' file.svg
```

### Bước 5: Báo cáo kết quả
```
✅ File đã được export: assets/images/ic_icon.svg
✅ File size: 3.6KB
✅ SVG structure: Valid
✅ CSS variables: Fixed
```

## 📝 Ví dụ sử dụng

### Ví dụ 1: Export icon
```
User: "Export icon này và lưu vào assets/images/ với tên ic_home"

AI: 
1. get_design_context() → URL
2. curl download
3. Fix SVG automatically
4. Validate
5. ✅ Done: assets/images/ic_home.svg
```

### Ví dụ 2: Export với đường dẫn khác
```
User: "Export logo và lưu vào assets/logos/ với tên app_logo"

AI: Tương tự workflow
✅ Done: assets/logos/app_logo.svg
```

## 🛠️ Tools đã tạo

1. **scripts/fix_svg.sh** - Script fix SVG thủ công
2. **lib/utils/figma_asset_helper.dart** - Flutter helper class
3. **AI tự động workflow** - Tự động export + fix khi được yêu cầu

## ✅ Checklist cho mỗi lần export

- [x] AI lấy URL từ Figma MCP
- [x] AI download file về đúng path
- [x] AI fix CSS variables (var(--fill-0, white) → white)
- [x] AI fix stroke variables
- [x] AI remove style attributes
- [x] AI validate closing tag
- [x] AI validate file structure
- [x] AI báo cáo kết quả
- [x] AI hướng dẫn cách sử dụng trong code

## 🎯 Kết quả

**Không còn lỗi**: Mỗi lần export từ Figma, file SVG sẽ hoạt động ngay lập tức trong Flutter app!

