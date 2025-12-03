import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_header.dart';
import '../repositories/category_repository.dart';
import '../models/category_model.dart';
import '../widgets/loading_indicator.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CategoryRepository _categoryRepository = CategoryRepository();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFF121212),
      child: Column(
        children: [
          AppHeader(
            title: "Categories",
            isHaveIcon: false,
            onLeftIconTap: () {
              context.push('/chatbot-suggestion');
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Future<void> _loadCategories() async {
    await _categoryRepository.refreshCategories();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBody() {
    if (_categoryRepository.isLoading) {
      return const Center(child: LoadingIndicator(color: Color(0xFF7d26cd)));
    }

    // Check error and show chip style if has error and no categories
    final categories = _categoryRepository.categories;
    if (_categoryRepository.error != null && categories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCategories,
        color: const Color(0xFF7d26cd),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Error loading categories',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCategories,
        color: const Color(0xFF7d26cd),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Text(
                'No categories available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: const Color(0xFF7d26cd),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Wrap(
          spacing: 5,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: categories.map((category) {
            return _buildCategoryChip(category);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(CategoryModel category) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/home/category/fandom?categoryId=${category.id}&categoryName=${Uri.encodeComponent(category.name)}',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          category.name,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
