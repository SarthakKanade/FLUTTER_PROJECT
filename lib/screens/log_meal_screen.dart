import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/entry.dart';
import '../providers/fitness_providers.dart';
import '../widgets/entry_card.dart';
import '../widgets/quick_chips.dart';

/// Screen and modal for logging or editing meals.
/// Meets R1 (Form, ListView, Card), R4 (shared Riverpod),
/// F2 (Log Meal form), F10 (Quick-add chips), F15 (Flow progress cue).
class LogMealScreen extends ConsumerStatefulWidget {
  final Entry? initialEntry;
  final VoidCallback? onSaved;

  const LogMealScreen({
    super.key,
    this.initialEntry,
    this.onSaved,
  });

  static Future<void> showAsSheet(BuildContext context, {Entry? entry}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: LogMealScreen(
          initialEntry: entry,
          onSaved: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _caloriesController;
  late MealType _selectedMealType;
  bool _isSaving = false;

  bool get isEditMode => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _caloriesController = TextEditingController(
      text: entry != null ? entry.kcal.toString() : '',
    );
    _selectedMealType = entry?.mealType ?? MealType.breakfast;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _handleQuickMealSelect(QuickMealItem item) {
    setState(() {
      _titleController.text = item.name;
      _caloriesController.text = item.calories.toString();
      _selectedMealType = item.mealType;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final calories = int.parse(_caloriesController.text.trim());

    if (isEditMode) {
      final updated = widget.initialEntry!.copyWith(
        title: title,
        kcal: calories,
        mealType: _selectedMealType,
      );
      await ref.read(dayLogProvider.notifier).updateEntry(updated);
    } else {
      final newEntry = Entry(
        id: const Uuid().v4(),
        type: EntryType.meal,
        title: title,
        kcal: calories,
        createdAt: DateTime.now(),
        mealType: _selectedMealType,
      );
      await ref.read(dayLogProvider.notifier).addEntry(newEntry);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Meal updated' : 'Meal added successfully!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        // Clear form if standalone screen
        _titleController.clear();
        _caloriesController.clear();
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayLogAsync = ref.watch(dayLogProvider);
    final balanceAsync = ref.watch(balanceProvider);

    final meals = (dayLogAsync.value ?? []).where((e) => e.isMeal).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Meal' : 'Log Meal'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Flow Progress Cue (F15)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditMode
                          ? 'Modify details and confirm update'
                          : 'Step 1 of 2: Enter meal details → Confirm to recalculate',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Add Chips (F10)
            if (!isEditMode) ...[
              QuickMealChips(onSelect: _handleQuickMealSelect),
              const SizedBox(height: 16),
            ],

            // Meal Form Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food Name Field
                      Text(
                        'Food Name',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Oatmeal & Blueberries, Poha, etc.',
                          prefixIcon: Icon(Icons.restaurant_rounded, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a food name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Calories Field
                      Text(
                        'Calories (kcal)',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 350',
                          prefixIcon: Icon(Icons.local_fire_department_rounded, size: 20),
                          suffixText: 'kcal',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter calories';
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null || parsed < 1 || parsed > 5000) {
                            return 'Enter calories between 1 and 5,000';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Meal Type Selector with responsive chips
                      Text(
                        'Meal Category',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: MealType.values.map((type) {
                          final isSelected = _selectedMealType == type;
                          return ChoiceChip(
                            avatar: Text(type.icon, style: const TextStyle(fontSize: 14)),
                            label: Text(type.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedMealType = type);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Live projected balance banner (R3, R7)
                      balanceAsync.when(
                        data: (balance) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Current balance: ${balance.remaining} kcal remaining (Target: ${balance.target} kcal)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 20),

                      // Save Button with loading state
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isEditMode ? Icons.check_rounded : Icons.save_rounded),
                                    const SizedBox(width: 8),
                                    Text(isEditMode ? 'Update Meal' : 'Save Meal'),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's Meals Section Below Form (Sec 6.1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Meals",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${meals.length} logged',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (meals.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('🥗', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          'No meals logged yet today',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fill out the form above to add your first meal',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  return EntryCard(
                    entry: meal,
                    onTap: () => LogMealScreen.showAsSheet(context, entry: meal),
                    onDelete: () async {
                      await ref.read(dayLogProvider.notifier).deleteEntry(meal.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deleted "${meal.title}"'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () => ref.read(dayLogProvider.notifier).restoreEntry(meal),
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
