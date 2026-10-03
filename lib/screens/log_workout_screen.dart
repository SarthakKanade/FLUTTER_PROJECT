import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../logic/met_table.dart';
import '../models/entry.dart';
import '../providers/fitness_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_card.dart';

/// Screen and modal for logging or editing workouts.
/// Meets R1 (Form, ListView, Card), R6 (type, duration, burned kcal),
/// F1 (Log Workout form with live estimate), F15 (Flow progress cue).
class LogWorkoutScreen extends ConsumerStatefulWidget {
  final Entry? initialEntry;
  final VoidCallback? onSaved;

  const LogWorkoutScreen({
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
        child: LogWorkoutScreen(
          initialEntry: entry,
          onSaved: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late ExerciseType _selectedExerciseType;
  int _durationMin = 30;
  bool _isSaving = false;

  bool get isEditMode => widget.initialEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _selectedExerciseType = entry?.exerciseType ?? ExerciseType.running;
    _durationMin = entry?.durationMin ?? 30;

    _titleController = TextEditingController(
      text: entry?.title ?? _selectedExerciseType.label,
    );
    _durationController = TextEditingController(
      text: _durationMin.toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  int _calculateBurn(double weightKg) {
    return MetCalculator.estimateBurn(
      exerciseType: _selectedExerciseType,
      durationMin: _durationMin,
      weightKg: weightKg,
    );
  }

  Future<void> _handleSave(double weightKg) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final burnedKcal = _calculateBurn(weightKg);

    if (isEditMode) {
      final updated = widget.initialEntry!.copyWith(
        title: title,
        kcal: burnedKcal,
        exerciseType: _selectedExerciseType,
        durationMin: _durationMin,
      );
      await ref.read(dayLogProvider.notifier).updateEntry(updated);
    } else {
      final newEntry = Entry(
        id: const Uuid().v4(),
        type: EntryType.workout,
        title: title,
        kcal: burnedKcal,
        createdAt: DateTime.now(),
        exerciseType: _selectedExerciseType,
        durationMin: _durationMin,
      );
      await ref.read(dayLogProvider.notifier).addEntry(newEntry);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? 'Workout updated' : 'Workout logged successfully!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        // Reset form if standalone screen
        setState(() {
          _selectedExerciseType = ExerciseType.running;
          _durationMin = 30;
          _titleController.text = _selectedExerciseType.label;
          _durationController.text = '30';
        });
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userWeight = ref.watch(weightProvider).value ?? 70.0;
    final dayLogAsync = ref.watch(dayLogProvider);
    final balanceAsync = ref.watch(balanceProvider);
    final workouts = (dayLogAsync.value ?? []).where((e) => e.isWorkout).toList();

    final estimatedBurn = _calculateBurn(userWeight);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Workout' : 'Log Workout'),
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
                color: AppTheme.burnedOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_run_rounded,
                    size: 18,
                    color: AppTheme.burnedOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEditMode
                          ? 'Modify workout details and save'
                          : 'Step 1 of 2: Select exercise & duration → Confirm burn estimate',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.burnedOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live MET Calorie Estimate Card (R6, Sec 6.2)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.burnedOrange.withValues(alpha: 0.12),
                    AppTheme.burnedOrange.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.burnedOrange.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.burnedOrange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: AppTheme.burnedOrange,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Burn',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$estimatedBurn',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.burnedOrange,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'kcal',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.burnedOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MET: ${_selectedExerciseType.met} • Weight: ${userWeight.toStringAsFixed(1)} kg',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Workout Form Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Exercise Type Selector Dropdown
                      Text(
                        'Exercise Type',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ExerciseType>(
                        initialValue: _selectedExerciseType,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.fitness_center_rounded, size: 20),
                        ),
                        items: ExerciseType.values.map((type) {
                          return DropdownMenuItem<ExerciseType>(
                            value: type,
                            child: Row(
                              children: [
                                Text(type.icon, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Text('${type.label} (${type.met} MET)'),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newType) {
                          if (newType != null) {
                            setState(() {
                              _selectedExerciseType = newType;
                              if (!isEditMode) {
                                _titleController.text = newType.label;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Workout Title
                      Text(
                        'Activity Name',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Evening Jog, Chest Day, etc.',
                          prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter an activity name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Duration Field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duration (Minutes)',
                            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '$_durationMin min',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 30',
                          prefixIcon: Icon(Icons.timer_rounded, size: 20),
                          suffixText: 'minutes',
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val.trim());
                          if (parsed != null && parsed >= 1 && parsed <= 600) {
                            setState(() => _durationMin = parsed);
                          }
                        },
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter duration';
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null || parsed < 1 || parsed > 600) {
                            return 'Enter duration between 1 and 600 minutes';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Quick Duration Presets Slider
                      Slider(
                        value: _durationMin.clamp(5, 120).toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '$_durationMin min',
                        onChanged: (val) {
                          setState(() {
                            _durationMin = val.toInt();
                            _durationController.text = _durationMin.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      // Quick Duration Chips
                      Wrap(
                        spacing: 8,
                        children: [15, 30, 45, 60, 90].map((mins) {
                          final isSelected = _durationMin == mins;
                          return ChoiceChip(
                            label: Text('$mins min'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _durationMin = mins;
                                  _durationController.text = mins.toString();
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Live projected balance banner (R3, R4, R7)
                      balanceAsync.when(
                        data: (balance) {
                          final currentDeficit = balance.remaining;
                          final projectedDeficit = currentDeficit + estimatedBurn;
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
                                    'Current deficit: $currentDeficit kcal • Workout adds +$estimatedBurn kcal burn (Projected deficit: $projectedDeficit kcal)',
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.burnedOrange,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isSaving ? null : () => _handleSave(userWeight),
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
                                    Text(isEditMode ? 'Update Workout' : 'Log Workout'),
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

            // Today's Workouts Section Below Form (Sec 6.2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Workouts",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${workouts.length} completed',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (workouts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('🏃', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          'No workouts logged yet today',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fill out the form above to record your exercise',
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
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return EntryCard(
                    entry: workout,
                    onTap: () => LogWorkoutScreen.showAsSheet(context, entry: workout),
                    onDelete: () async {
                      await ref.read(dayLogProvider.notifier).deleteEntry(workout.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deleted "${workout.title}"'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () => ref.read(dayLogProvider.notifier).restoreEntry(workout),
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
