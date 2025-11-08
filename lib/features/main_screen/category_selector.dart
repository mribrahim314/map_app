// ============================================================================
// CLEANED BY CLAUDE - Firebase removed, dead code eliminated
// ============================================================================

import 'package:flutter/material.dart';
import 'package:map_app/core/cubit/coordinates_cubit.dart';
import 'package:map_app/core/cubit/polygone_cubit.dart';
import 'package:map_app/core/helpers/data.dart';
import 'package:provider/provider.dart';

class CategorySelector extends StatefulWidget {
  const CategorySelector({super.key});

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  List<String> selectedCategories = [];
  List<String> categoriesWithMyData = List.from(Data.Categories)
    ..insert(0, "My Data");

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Search Bar UI
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedCategories.isEmpty
                        ? "Select category"
                        : selectedCategories.join(", "),
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Category chips list
        SizedBox(
          height: 50,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categoriesWithMyData.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categoriesWithMyData[index];
              final isSelected = selectedCategories.contains(category);

              return ChoiceChip(
                label: Row(
                  children: [const SizedBox(width: 4), Text(category)],
                ),
                selected: isSelected,
                selectedColor: Colors.blue,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
                onSelected: (_) async {
                  _handleCategorySelection(category);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSingleFruitCategory(List<String> categories) {
    return categories.length == 1 && categories.first != "My Data";
  }

  Future<void> _handleCategorySelection(String category) async {
    if (category == "My Data") {
      if (selectedCategories.isEmpty) {
        setState(() {
          selectedCategories = ["My Data"];
        });
      } else if (_isSingleFruitCategory(selectedCategories)) {
        setState(() {
          selectedCategories = [selectedCategories[0], "My Data"];
        });
        await context.read<PolygonCubit>().addMainPolygons(
          selectedCategories[0],
          CurrentUser: true,
        );
      } else {
        setState(() {
          selectedCategories = [];
        });
        context.read<PolygonCubit>().clearAll();
        context.read<CoordinatesCubit>().clear();
      }
    } else {
      if (selectedCategories.contains(category)) {
        setState(() {
          selectedCategories.remove(category);
        });
        context.read<PolygonCubit>().clearAll();
        context.read<CoordinatesCubit>().clear();
      } else if (selectedCategories.isEmpty ||
          _isSingleFruitCategory(selectedCategories)) {
        setState(() {
          selectedCategories = [category];
        });
        context.read<PolygonCubit>().clearAll();
        context.read<CoordinatesCubit>().clear();
        await context.read<PolygonCubit>().addMainPolygons(category);
      } else {
        setState(() {
          selectedCategories = [category, "My Data"];
        });
        context.read<PolygonCubit>().clearAll();
        context.read<CoordinatesCubit>().clear();
        await context.read<PolygonCubit>().addMainPolygons(
          category,
          CurrentUser: true,
        );
      }
    }
  }
}
