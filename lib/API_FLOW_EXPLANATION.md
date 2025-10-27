# 🔄 Giải thích Flow API từ Request đến UI

## 📊 Flow tổng quan

```
App Khởi động
    ↓
AppInitializer
    ↓
CategoryRepository.loadCategories()
    ↓
CategoryService.getAllCategories()
    ↓
Dio HTTP Request: GET /categories
    ↓
API Server Response: JSON
    ↓
CategoryModel.fromJson() - Parse JSON
    ↓
CategoryRepository.categories (Lưu trong memory)
    ↓
CategoryScreen đọc data
    ↓
UI hiển thị ListView
```

---

## 🔍 Chi tiết từng bước

### **1️⃣ App Khởi động (main.dart)**

```dart
void main() {
  ApiClient().init();  // Khởi tạo Dio client
  
  runApp(const MyApp());
}
```

**Chức năng:**
- Tạo Dio instance với config (baseUrl, timeout, headers)
- Thiết lập CurlInterceptor để log CURL commands

---

### **2️⃣ AppInitializer - Pre-load data**

```dart
// lib/presentation/app_initializer.dart
await _categoryRepository.loadCategories();
```

**Thời điểm:** Ngay khi app khởi động

**Mục đích:** Load categories sẵn trước khi user vào screen

---

### **3️⃣ CategoryRepository - Quản lý data**

```dart
// lib/repositories/category_repository.dart

class CategoryRepository {
  // Singleton pattern - Chỉ 1 instance trong app
  static final CategoryRepository _instance = CategoryRepository._internal();
  factory CategoryRepository() => _instance;
  
  // Data storage
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters để access data
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load data từ API
  Future<void> loadCategories() async {
    if (_isLoading || _isInitialized) return;  // Prevent duplicate calls
    
    _isLoading = true;
    _error = null;
    
    try {
      // 1. Gọi service
      _categories = await _categoryService.getAllCategories();
      
      // 2. Update state
      _isLoading = false;
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isInitialized = true;
    }
  }
}
```

**Chức năng:**
- 🎯 Single source of truth cho categories
- ✅ Cache data trong memory
- ⚠️ Quản lý loading & error states
- 🔄 Prevent duplicate API calls

---

### **4️⃣ CategoryService - Gọi API**

```dart
// lib/services/category_service.dart

class CategoryService {
  final ApiClient _apiClient = ApiClient();  // Dio client
  
  Future<List<CategoryModel>> getAllCategories() async {
    // 1. HTTP GET request
    final response = await _apiClient.dio.get('/categories');
    
    // 2. Check status code
    if (response.statusCode == 200) {
      // 3. Parse JSON response
      final List<dynamic> data = response.data;
      
      // 4. Convert JSON → CategoryModel
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    }
  }
}
```

**API Request:**
```bash
curl -X GET \
  -H 'accept: application/json' \
  'https://fandom-gg.onrender.com/categories'
```

**API Response:**
```json
[
  {
    "id": "cat_cfe6f40a31c6",
    "name": "Anime & Manga",
    "encoded_name": "Anime *a* M自在"
  },
  {
    "id": "cat_abc123",
    "name": "Books & Literature",
    "encoded_name": "Books *a* Literature"
  }
]
```

---

### **5️⃣ CategoryModel - Parse JSON**

```dart
// lib/models/category_model.dart

class CategoryModel {
  final String id;
  final String name;
  final String encodedName;
  
  // Factory constructor để parse JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,              // "cat_cfe6f40a31c6"
      name: json['name'] as String,          // "Anime & Manga"
      encodedName: json['encoded_name'] as String,  // "Anime *a* Manga"
    );
  }
}
```

**Flow:**
```json
{"id": "cat_xxx", "name": "Anime & Manga", "encoded_name": "..."}
    ↓
CategoryModel.fromJson(json)
    ↓
CategoryModel(id: "cat_xxx", name: "Anime & Manga", encodedName: "...")
```

---

### **6️⃣ CategoryScreen - Đọc & hiển thị**

```dart
// lib/presentation/category_screen.dart

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(child: _buildBody()),
      ],
    );
  }
  
  Widget _buildBody() {
    // 1. Check loading state
    if (_categoryRepository.isLoading) {
      return CircularProgressIndicator();
    }
    
    // 2. Check error state
    if (_categoryRepository.error != null) {
      return ErrorWidget();
    }
    
    // 3. Get data từ Repository
    final categories = _categoryRepository.categories;
    
    // 4. Check empty
    if (categories.isEmpty) {
      return EmptyWidget();
    }
    
    // 5. Display list
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];  // CategoryModel &&&&&&&&&&&&&&
        return _buildCategoryCard(category);
      },
    );
  }
  
  Widget _buildCategoryCard(CategoryModel category) {
    return Container(
      child: Column(
        children: [
          // Sử dụng properties của CategoryModel
          Text(category.name),        // "Anime & Manga"
          Text(category.encodedName), // "Anime *a* Manga"
        ],
      ),
    );
  }
}
```

---

## 📝 Diagram Flow

```
┌─────────────────────────────────────────────────────────────┐
│ App Khởi động                                                │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ AppInitializer.initState()                                   │
│   → _categoryRepository.loadCategories()                     │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ CategoryRepository.loadCategories()                          │
│   → _categoryService.getAllCategories()                      │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ CategoryService.getAllCategories()                           │
│   → _apiClient.dio.get('/categories')  [HTTP GET]           │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ CurlInterceptor                                              │
│   → Log CURL command (cho Postman)                          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ API Server: https://fandom-gg.onrender.com                  │
│   → Returns JSON: [{id, name, encoded_name}]               │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ CategoryModel.fromJson(json)                                 │
│   → Parse JSON to CategoryModel objects                      │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ CategoryRepository._categories                               │
│   → [CategoryModel, CategoryModel, ...]                     │
│   → Stored in memory (singleton)                            │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ CategoryScreen                                               │
│   → _categoryRepository.categories                          │
│   → ListView.builder()                                      │
│   → Display categories                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Tại sao sử dụng Repository Pattern?

### **Without Repository** ❌
```dart
// Mỗi screen phải gọi API riêng
class CategoryScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // API call 1
    _loadCategories();
  }
}

class LibraryScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    // API call 2 (duplicate!)
    _loadCategories();
  }
}

// Problems:
// - Duplicate API calls
// - No caching
// - Wasted resources
```

### **With Repository** ✅
```dart
// 1 lần load, nhiều nơi sử dụng
class CategoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = CategoryRepository().categories;  // Read only
  }
}

// Benefits:
// - Single source of truth
// - Cached data
// - Efficient resource usage
```

---

## 💡 Cách sử dụng trong Screen

### **Đọc data:**
```dart
final categories = _categoryRepository.categories;
```

### **Check loading:**
```dart
if (_categoryRepository.isLoading) {
  return CircularProgressIndicator();
}
```

### **Check error:**
```dart
if (_categoryRepository.error != null) {
  return ErrorWidget();
}
```

### **Refresh data:**
```dart
await _categoryRepository.refreshCategories();
setState(() {});
```

### **Search:**
```dart
final results = _categoryRepository.searchCategories("anime");
```

### **Get by ID:**
```dart
final category = _categoryRepository.getCategoryById("cat_xxx");
```

---

## 🔑 Key Points

1. **Repository là Singleton**: Chỉ 1 instance trong app
2. **Data được cache**: Không cần gọi API nhiều lần
3. **Screens chỉ đọc data**: Không cần quản lý API logic
4. **Type-safe models**: CategoryModel.fromJson() đảm bảo type safety
5. **Auto logging**: CURL commands tự động log để copy vào Postman

---

## 📊 Data Flow Summary

| Layer | Responsibility | Example |
|-------|---------------|---------|
| **Model** | Define data structure | CategoryModel |
| **Service** | Call API | CategoryService.getAllCategories() |
| **Repository** | Manage & cache data | CategoryRepository |
| **Screen** | Display data | CategoryScreen |

**Clean Architecture!** 🎉

