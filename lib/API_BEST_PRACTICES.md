# 🎯 API Calling Best Practices

## 📍 Nơi gọi API trong Flutter

### **1. SplashScreen** ✅ (Đã implement)
```dart
// lib/presentation/splash_screen.dart
@override
void initState() {
  super.initState();
  _loadCategories(); // Pre-load data
}
```
**Khi nào dùng:**
- ✅ Data cần thiết cho toàn app
- ✅ Load 1 lần khi app khởi động
- ✅ User có thể chờ đợi

**Ưu điểm:**
- Data sẵn sàng khi user vào screen
- Không bị delay khi navigate

---

### **2. Trong main()** 🚀
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  ApiClient().init();
  await CategoryRepository().loadCategories(); // Pre-load
  
  runApp(const MyApp());
}
```
**Khi nào dùng:**
- ✅ Critical data cần trước khi UI load
- ✅ Authentication check
- ✅ App config

**Lưu ý:** 
- Phải có `WidgetsFlutterBinding.ensureInitialized()` nếu dùng `async/await`

---

### **3. Provider với Consumer** 📦 (Khuyên dùng)
```dart
// Sử dụng trong bất kỳ widget nào
class CategoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return CircularProgressIndicator();
        }
        
        return ListView.builder(
          itemCount: provider.categories.length,
          itemBuilder: (context, index) {
            return Text(provider.categories[index].name);
          },
        );
      },
    );
  }
}
```

**Khi nào dùng:**
- ✅ State management cho toàn app
- ✅ Shared data giữa nhiều screens
- ✅ Reactive UI updates

**Ưu điểm:**
- Auto rebuild khi data thay đổi
- Centralized state management
- Dễ test

---

### **4. initState() của Screen** 🎨
```dart
class MyScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    // Load data specific to this screen only
  }
}
```
**Khi nào dùng:**
- ✅ Data chỉ dùng cho screen đó
- ✅ Không cần shared state
- ✅ Screen-specific data

---

### **5 synchronous Load on Tap** 👆
```dart
ElevatedButton(
  onPressed: () async {
    final data = await someService.getData();
    Navigator.push(...);
  },
  child: Text('Load and Navigate'),
)
```
**Khi nào dùng:**
- ✅ User-initiated actions
- ✅ Pull-to-refresh
- ✅ Search, filter

---

### **6. FutureBuilder** ⚡ (Đơn giản nhất)
```dart
FutureBuilder<List<CategoryModel>>(
  future: CategoryService().getAllCategories(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (context, index) {
        return Text(snapshot.data![index].name);
      },
    );
  },
)
```
**Khi nào dùng:**
- ✅ Simple API calls
- ✅ No state management needed
- ✅ One-time data fetch

**Nhược điểm:**
- Gọi API mỗi lần rebuild
- Không cache data

---

### **7. BLoC Pattern** 🏗️ (For complex apps)
```dart
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryService service;
  
  CategoryBloc(this.service) : super(CategoryInitial()) {
    on<LoadCategories>((event, emit) async {
      emit(CategoryLoading());
      try {
        final categories = await service.getAllCategories();
        emit(CategoryLoaded(categories));
      } catch (e) {
        emit(CategoryError(e.toString()));
      }
    });
  }
}
```

\-------------------------- ------------------

## 🎯 Recommended Architecture cho App của bạn:

### **Option 1: Current Setup (Repository Pattern)** ✅
```
main() → ApiClient.init()
SplashScreen → CategoryRepository.loadCategories()
CategoryScreen → Đọc từ Repository
```

**Ưu điểm:**
- Đơn giản, dễ hiểu
- Không cần thêm dependencies
- Good cho small-medium apps

### **Option 2: Provider Pattern** 🚀 (Recommended)
```
main() → MultiProvider (Wraps App)
SplashScreen → Provider.loadCategories()
CategoryScreen → Consumer<CategoryProvider>
```

**Ưu điểm:**
- Industry standard
- Reactive UI updates
- Easy state management
- Scalable

### **Option 3: Hybrid** 🎨 (Best of both)
```
Repository → Manage data
Provider → Manage UI state
Screen → Read from Provider
```

\-------------------------- ------------------

## 📊 Comparison Table

| Method | Complexity | Reusability | State Management | Best For |
|--------|-----------|-------------|------------------|----------|
| SplashScreen | ⭐ Low | ⭐⭐ Medium | Manual | Small apps |
| Provider | ⭐⭐ Medium | ⭐⭐⭐ High | Auto | Medium-large apps |
| Repository | ⭐ Low | ⭐⭐⭐ High | Manual | All apps |
| FutureBuilder | ⭐ Low | ⭐ Low | None | Simple cases |
| BLoC | ⭐⭐⭐ High | ⭐⭐⭐ High | Auto | Large apps |

\-------------------------- ------------------

## 💡 Recommendation cho project của bạn:

### **For Simple Data (Categories, Settings):**
```dart
// Sử dụng Repository (như hiện tại)
CategoryRepository().loadCategories() trong SplashScreen
```

### **For Complex State (User, Cart, etc.):**
```dart
// Sử dụng Provider
Consumer<UserProvider>(...)
```

### **For Real-time Updates:**
```dart
// Sử dụng Stream hoặc Signal
```

\-------------------------- ------------------

## ✅ Best Practices:

1. **Pre-load critical data** → SplashScreen hoặc main()
2. **Use Repository** → Single source of truth
3. **Add loading states** → Always show feedback
4. **Handle errors** → User-friendly messages
5. **Cache data** → Avoid redundant API calls
6. **Debounce starches** → Reduce API calls
7. **Use pagination** → For large lists

\-------------------------- ------------------

## 🎯 Implementation Strategy:

1. **Keep Repository** (đã có) → Data management
2. **Add Provider** (optional) → UI state
3. **Use FutureBuilder** → For simple cases
4. **Consider BLoC** → If app grows complex

App hiện tại đang dùng **Repository Pattern** - đây là lựa chọn tốt!

