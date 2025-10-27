# API Services Documentation

## 📋 Overview

Services này sử dụng **Dio** để gọi API từ domain: `https://fandom-gg.onrender.com/`

Tính năng chính:
- ✅ Automatic CURL logging với format đẹp
- ✅ Request/Response interceptors
- ✅ Error handling
- ✅ Type-safe models

## 🚀 Sử dụng

### 1. Khởi tạo API Client

```dart
import 'package:fanfiction/services/api_client.dart';

// Initialize API client (chỉ cần gọi 1 lần trong app)
ApiClient().init();
```

### 2. Category Service

```dart
import 'package:fanfiction/services/category_service.dart';

final categoryService = CategoryService();

// Get all categories
final categories = await categoryService.getAllCategories();

// Search categories
final results = await categoryService.searchCategories('anime');

// Get category by ID
final category = await categoryService.getCategoryById('cat_xxx');
```

### 3. Fandom Service

```dart
import 'package:fanfiction/services/fandom_service.dart';

final fandomService = FandomService();

// Get all fandoms
final fandoms = await fandomService.getAllFandoms();

// Get fandoms by category
final fandoms = await fandomService.getFandomsByCategory('cat_xxx');

// Search fandoms
final results = await fandomService.searchFandoms('harry potter');
```

### 4. Work Service

```dart
import 'package:fanfiction/services/work_service.dart';

final workService = WorkService();

// Get all works with pagination
final works = await workService.getAllWorks(page: 1, limit: 20);

// Get work by ID
final work = await workService.getWorkById('work_xxx');

// Get works by fandom
final works = await workService.getWorksByFandom('fandom_xxx');

// Get work content
final content = await workService.getWorkContent('work_xxx');
```

## 📊 CURL Logging

Mỗi request sẽ được log với format đẹp:

```
============================================================
🌐 CURL REQUEST
============================================================

🔹 Method: GET
🔹 URL: https://fandom-gg.onrender.com/categories

📋 Headers:
   Content-Type: application/json
   accept: application/json

💻 CURL Command:
curl -X GET \
  -H 'Content-Type: application/json' \
  -H 'accept: application/json' \
  'https://fandom-gg.onrender.com/categories'

============================================================
```

Response sẽ được log tương tự:

```
============================================================
✅ CURL RESPONSE
============================================================

🔹 Status Code: 200
🔹 URL: https://fandom-gg.onrender.com/categories

📦 Response Data:
   [{id: cat_xxx, name: Anime & Manga, ...}]

============================================================
```

## 🎨 Models

### CategoryModel
```dart
class CategoryModel {
  final String id;
  final String name;
  final String encodedName;
}
```

### FandomModel
```dart
class FandomModel {
  final String id;
  final String name;
  final String encodedName;
  final String? categoryId;
}
```

### WorkModel
```dart
class WorkModel {
  final String id;
  final String title;
  final String? summary;
  final String? author;
  final String? fandom;
  final List<String>? tags;
  final int? words;
  final int? chapters;
  final String? rating;
  final String? status;
}
```

## ⚠️ Error Handling

Tất cả services đều có error handling:

```dart
try {
  final categories = await categoryService.getAllCategories();
  // Use categories...
} catch (e) {
  // Error is already logged by interceptor
  // You can show error message to user
  print('Error: $e');
}
```

## 🔧 Configuration

### Thay đổi base URL

Chỉnh sửa trong `lib/services/api_client.dart`:

```dart
static const String baseUrl = 'https://fandom-gg.onrender.com';
```

### Thay đổi timeout

```dart
BaseOptions(
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
)
```

## 📝 Example trong Screen

```dart
import 'package:fanfiction/services/category_service.dart';
import 'package:fanfiction/models/category_model.dart';

class CategoryScreen extends StatefulWidget {
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<CategoryModel> categories = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final categoryService = CategoryService();
      final result = await categoryService.getAllCategories();

      setState(() {
        categories = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return CircularProgressIndicator();
    if (error != null) return Text('Error: $error');
    
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          title: Text(category.name),
          subtitle: Text(category.id),
        );
      },
    );
  }
}
```

## 🎯 Best Practices

1. **Single Instance**: Chỉ khởi tạo ApiClient() một lần trong app
2. **Use try-catch**: Luôn wrap API calls trong try-catch
3. **Loading States**: Hiển thị loading state khi đang fetch data
4. **Error Messages**: Hiển thị error message user-friendly cho người dùng

