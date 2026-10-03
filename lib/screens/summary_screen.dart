import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entry.dart';
import '../providers/fitness_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/calorie_ring.dart';
import '../widgets/date_header.dart';
import '../widgets/entry_card.dart';
import '../widgets/stat_tile.dart';
import '../widgets/target_dialog.dart';
import 'log_meal_screen.dart';
import 'log_workout_screen.dart';

/// Main Daily Summary dashboard screen.
/// Meets R1 (Summary screen), R2 (M3 theme & progress ring),
/// R4 (Riverpod balance), R8 (Progress ring consumed vs target),
/// R9 (Edit/delete with immediate balance update),
/// R11 (Responsive phone/tablet layout).
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  void _showAddChoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like to log?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.consumedBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🥗', style: TextStyle(fontSize: 22)),
                  ),
                  title: const Text('Log a Meal', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Breakfast, Lunch, Dinner, or Snacks'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(context).pop();
                    LogMealScreen.showAsSheet(context);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.burnedOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🏃', style: TextStyle(fontSize: 22)),
                  ),
                  title: const Text('Log a Workout', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Running, Walking, Gym, Yoga, etc.'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    Navigator.of(context).pop();
                    LogWorkoutScreen.showAsSheet(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final balanceAsync = ref.watch(balanceProvider);
    final dayLogAsync = ref.watch(dayLogProvider);

    final entries = dayLogAsync.value ?? [];
    final meals = entries.where((e) => e.isMeal).toList();
    final workouts = entries.where((e) => e.isWorkout).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.directions_run_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text('FitTrail'),
          ],
        ),
        actions: [
          // Theme Mode Toggle
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          // Target & Weight Profile Setting Dialog (F9)
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Calorie Target & Profile',
            onPressed: () => TargetDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChoiceSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Entry'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          // Responsive Two-Column layout for Tablet / Desktop (R11)
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Date + Ring + Stats + Banner
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const DateHeader(),
                        const SizedBox(height: 20),
                        _buildHeroRingSection(context, balanceAsync),
                        const SizedBox(height: 20),
                        _buildStatTilesSection(balanceAsync),
                        const SizedBox(height: 16),
                        _buildStatusBanner(context, balanceAsync),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                // Right Column: Entries List (Meals & Workouts)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildEntriesSection(context, ref, meals, workouts),
                  ),
                ),
              ],
            );
          }

          // Single Column layout for Phones
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DateHeader(),
                const SizedBox(height: 16),
                _buildHeroRingSection(context, balanceAsync),
                const SizedBox(height: 16),
                _buildStatTilesSection(balanceAsync),
                const SizedBox(height: 14),
                _buildStatusBanner(context, balanceAsync),
                const SizedBox(height: 20),
                _buildEntriesSection(context, ref, meals, workouts),
                const SizedBox(height: 80), // Padding for FAB
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroRingSection(BuildContext context, AsyncValue balanceAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: balanceAsync.when(
          data: (balance) => CalorieRing(balance: balance),
          loading: () => const Center(
            child: SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (err, _) => Center(
            child: Text(
              'Error calculating balance',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatTilesSection(AsyncValue balanceAsync) {
    return balanceAsync.when(
      data: (balance) {
        return Row(
          children: [
            StatTile(
              label: 'Consumed',
              value: balance.consumed,
              icon: Icons.restaurant_rounded,
              accentColor: AppTheme.consumedBlue,
            ),
            const SizedBox(width: 10),
            StatTile(
              label: 'Burned',
              value: balance.burned,
              icon: Icons.local_fire_department_rounded,
              accentColor: AppTheme.burnedOrange,
            ),
            const SizedBox(width: 10),
            StatTile(
              label: 'Target',
              value: balance.target,
              icon: Icons.flag_rounded,
              accentColor: AppTheme.primarySeed,
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 90),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusBanner(BuildContext context, AsyncValue balanceAsync) {
    final theme = Theme.of(context);

    return balanceAsync.when(
      data: (balance) {
        final isOver = balance.isOver;
        final bannerColor = isOver ? theme.colorScheme.error : theme.colorScheme.primary;

        final title = isOver ? 'Calorie Target Exceeded' : 'On Track';
        final message = isOver
            ? 'You are ${balance.overAmount} kcal over your daily target.'
            : 'You have ${balance.remaining} kcal remaining to reach your goal.';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bannerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: bannerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOver ? Icons.warning_rounded : Icons.check_circle_rounded,
                color: bannerColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: bannerColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildEntriesSection(
    BuildContext context,
    WidgetRef ref,
    List<Entry> meals,
    List<Entry> workouts,
  ) {
    final theme = Theme.of(context);
    final hasNoEntries = meals.isEmpty && workouts.isEmpty;

    if (hasNoEntries) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.event_note_rounded,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing logged yet today',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap "Log Entry" below to record your meals and workouts.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: () => _showAddChoiceSheet(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add First Entry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meals Section Header
        if (meals.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meals',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${meals.fold(0, (sum, m) => sum + m.kcal)} kcal total',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.consumedBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 18),
        ],

        // Workouts Section Header
        if (workouts.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workouts',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${workouts.fold(0, (sum, w) => sum + w.kcal)} kcal burned',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.burnedOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
        ],
      ],
    );
  }
}
