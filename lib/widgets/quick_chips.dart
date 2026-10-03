import 'package:flutter/material.dart';
import '../models/entry.dart';

/// Preset item for quick meal logging.
class QuickMealItem {
  final String name;
  final int calories;
  final MealType mealType;
  final String icon;

  const QuickMealItem({
    required this.name,
    required this.calories,
    required this.mealType,
    required this.icon,
  });
}

/// Horizontal scrollable list of quick-add meal chips.
/// Meets F10: Quick-add meal chips for fast prefill.
class QuickMealChips extends StatelessWidget {
  final ValueChanged<QuickMealItem> onSelect;

  const QuickMealChips({
    super.key,
    required this.onSelect,
  });

  static const List<QuickMealItem> quickMeals = [
    QuickMealItem(name: 'Poha', calories: 350, mealType: MealType.breakfast, icon: '🥣'),
    QuickMealItem(name: 'Roti & Dal', calories: 420, mealType: MealType.lunch, icon: '🫓'),
    QuickMealItem(name: 'Idli & Sambar', calories: 300, mealType: MealType.breakfast, icon: '🥘'),
    QuickMealItem(name: 'Paneer Bhurji', calories: 380, mealType: MealType.dinner, icon: '🧀'),
    QuickMealItem(name: 'Banana', calories: 105, mealType: MealType.snack, icon: '🍌'),
    QuickMealItem(name: 'Greek Yogurt', calories: 150, mealType: MealType.snack, icon: '🥛'),
    QuickMealItem(name: 'Oats Bowl', calories: 280, mealType: MealType.breakfast, icon: '🌾'),
    QuickMealItem(name: 'Grilled Chicken', calories: 320, mealType: MealType.lunch, icon: '🍗'),
    QuickMealItem(name: 'Veg Khichdi', calories: 340, mealType: MealType.dinner, icon: '🍲'),
    QuickMealItem(name: 'Boiled Eggs (2)', calories: 156, mealType: MealType.breakfast, icon: '🥚'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Quick-add popular foods',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quickMeals.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = quickMeals[index];
              return ActionChip(
                avatar: Text(item.icon, style: const TextStyle(fontSize: 14)),
                label: Text('${item.name} (${item.calories} kcal)'),
                labelStyle: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: theme.cardTheme.color,
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => onSelect(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
