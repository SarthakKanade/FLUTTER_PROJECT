import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fitness_providers.dart';

/// Modal dialog for modifying daily calorie target and user weight.
/// Meets F9: Editable daily target & body weight for MET calculations.
class TargetDialog extends ConsumerStatefulWidget {
  const TargetDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const TargetDialog(),
    );
  }

  @override
  ConsumerState<TargetDialog> createState() => _TargetDialogState();
}

enum FitnessGoal {
  fatLoss('Fat Loss', '🥗', -500, 'Deficit for steady fat loss (~0.5 kg/week)', 350),
  maintain('Maintain', '⚖️', 0, 'Balanced daily energy balance', 250),
  muscleGain('Muscle Gain', '💪', 300, 'Lean surplus for muscle hypertrophy', 200);

  final String label;
  final String icon;
  final int offset;
  final String description;
  final int targetBurn;
  const FitnessGoal(this.label, this.icon, this.offset, this.description, this.targetBurn);
}

class _TargetDialogState extends ConsumerState<TargetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _targetController;
  late TextEditingController _weightController;
  FitnessGoal _selectedGoal = FitnessGoal.fatLoss;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentTarget = ref.read(targetProvider).value ?? 2000;
    final currentWeight = ref.read(weightProvider).value ?? 70.0;

    _targetController = TextEditingController(text: currentTarget.toString());
    _weightController = TextEditingController(text: currentWeight.toStringAsFixed(1));
    _weightController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _targetController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double get _currentWeight {
    final parsed = double.tryParse(_weightController.text.trim());
    return (parsed != null && parsed >= 20 && parsed <= 300) ? parsed : 70.0;
  }

  int get _recommendedIntake {
    final maintenance = (_currentWeight * 30.0).round();
    final recommended = maintenance + _selectedGoal.offset;
    return recommended.clamp(1200, 5000);
  }

  int get _recommendedBurn => _selectedGoal.targetBurn;

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final targetVal = int.parse(_targetController.text.trim());
    final weightVal = double.parse(_weightController.text.trim());

    await ref.read(targetProvider.notifier).setTarget(targetVal);
    await ref.read(weightProvider.notifier).setWeight(weightVal);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target & profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.tune_rounded, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Daily Goal & Profile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set your weight and preferred goal to get a personalized calorie intake and workout burn recommendation.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              // 1. Body Weight in kg
              Text(
                'Your Body Weight (kg)',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'e.g. 70.0',
                  prefixIcon: Icon(Icons.monitor_weight_rounded, size: 20),
                  suffixText: 'kg',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Weight cannot be empty';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed < 20 || parsed > 300) {
                    return 'Enter a valid weight (20 - 300 kg)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Preferred Plan / Goal
              Text(
                'Preferred Goal Plan',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FitnessGoal.values.map((goal) {
                  final isSelected = _selectedGoal == goal;
                  return ChoiceChip(
                    avatar: Text(goal.icon, style: const TextStyle(fontSize: 14)),
                    label: Text(goal.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedGoal = goal);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Recommended Plan Card (Minimal & Clear)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Recommended for ${_selectedGoal.label}:',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _targetController.text = _recommendedIntake.toString();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              'Apply',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Target Intake: $_recommendedIntake kcal/day\n• Target Burn: ~$_recommendedBurn kcal/day via exercise',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Daily Calorie Target Input
              Text(
                'Daily Calorie Target (kcal)',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 2000',
                  prefixIcon: Icon(Icons.flag_rounded, size: 20),
                  suffixText: 'kcal',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Target cannot be empty';
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null || parsed < 500 || parsed > 10000) {
                    return 'Enter a valid target (500 - 10,000)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
