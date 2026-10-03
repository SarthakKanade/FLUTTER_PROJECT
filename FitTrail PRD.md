# FitTrail — Product Requirements Document

**Project:** Personal Workout & Diet Tracker (Flutter) · **Type:** College project examination · **Platform:** Android/iOS + responsive (phone/tablet/web)

---

## 1. Overview

FitTrail lets a user log daily workouts and meals, then **asynchronously** recomputes the day's calorie balance so they always know whether they are within their target. Everything is stored on-device and works offline.

**One-line pitch:** *Log it, see it, stay on target.*

## 2. Goals and non-goals

**Goals**

1. Logging a meal or workout instantly (async) recalculates the daily calorie balance.
2. One shared Riverpod state powers Log Meal, Log Workout and Daily Summary.
3. Edit/delete an entry and the balance updates immediately.
4. Works fully offline (local storage).
5. Clean Material 3 UI with progress cues, designed in Figma first.

**Non-goals (put on "future scope" slide)** Login/accounts, cloud sync, social features, food database/barcode scan, wearable integration, push notifications, weekly/monthly analytics charts.

## 3. Users and scenarios

**Primary user:** a student/young adult who wants a quick daily calorie check, no accounts, no setup friction.

| Scenario | Flow |
| --- | --- |
| Morning meal | Open app → Log Meal → enter "Poha, 350 kcal, Breakfast" → Save → ring updates |
| After gym | Log Workout → Running, 30 min → app shows estimated \~kcal → Save → remaining kcal goes up |
| Mistake | Summary → swipe entry to delete / tap to edit → balance updates instantly |
| Check status | Summary shows ring + "420 kcal remaining" or "130 kcal over" |

## 4. Scope — requirements from the problem statement

| # | Requirement from brief | Where it is met |
| --- | --- | --- |
| R1 | Log Workout, Log Meal, Daily Summary screens using Form, ListView, Card | Sec 6 |
| R2 | Material 3 theme, progress rings, clear calorie typography | Sec 7 |
| R3 | async/await calorie-balance calculation | Sec 8.3 |
| R4 | Riverpod exposes result to Summary (and both Log screens) | Sec 8.2 |
| R5 | Figma flow with progress cues for every screen | Sec 9 |
| R6 | Show exercise type, duration, estimated calories burned per workout entry | Sec 6.2 |
| R7 | Logging triggers async recalculation | Sec 8.3 |
| R8 | Summary progress ring: consumed vs target | Sec 6.3 |
| R9 | Edit or delete entry, balance updates immediately | Sec 6.4 |
| R10 | Local storage for offline access | Sec 8.4 |
| R11 | Responsive working prototype, log-to-summary journey | Sec 10 |
| R12 | Proper justification | Sec 11 |

## 5. Features

**Must have (the brief)**

- F1 Log Workout form (type, duration, auto estimated kcal)
- F2 Log Meal form (name, calories, meal type)
- F3 Daily Summary (progress ring, consumed / burned / remaining)
- F4 Entry list per day with Cards (workouts + meals)
- F5 Edit and delete entries
- F6 Async recalculation via Riverpod
- F7 Offline local storage
- F8 Material 3 theme

**Should have (small, cheap, high impression)**

- F9 **Editable daily target** (dialog from Summary, default 2000 kcal)
- F10 **Quick-add meal chips** (hard-coded 8–10 common Indian foods, e.g. Roti, Dal, Poha, Banana) that prefill the form
- F11 **Date selector** (previous/next day arrows) so past days can be viewed
- F12 **Over-target state**: ring and text turn error colour, message "130 kcal over"
- F13 **Undo snackbar** after delete
- F14 **Empty states** ("Nothing logged yet — add your first meal")
- F15 **Flow progress cue**: a stepper/chip on the form header ("Step 1 of 2: Details → Confirm"), plus the ring as the daily progress cue

**Won't do:** everything in the non-goals list.

## 6. Screens and behaviour

### 6.0 Navigation

Bottom `NavigationBar` with 3 destinations: **Summary** (home), **Meal**, **Workout**. On width ≥ 600 dp it becomes a `NavigationRail`. A floating "+" on Summary opens a bottom sheet with "Log Meal / Log Workout".

### 6.1 Log Meal

- **Fields:** Food name (text, required), Calories (number, required, 1–5000), Meal type (segmented: Breakfast / Lunch / Dinner / Snack).
- **Quick-add chips** above the form fill name + kcal.
- **Validation:** inline errors via `Form` + `TextFormField` validators.
- **Save:** button shows a short loading state while the async write completes, then returns to Summary with a snackbar "Meal added".
- Below the form: today's meals as `Card`s in a `ListView`.

### 6.2 Log Workout

- **Fields:** Exercise type (dropdown: Walking, Running, Cycling, Gym/Weights, Yoga, Swimming, Other), Duration in minutes (required, 1–600).
- **Live estimate:** as type/duration change, a Card shows "Estimated burn: 245 kcal".
- **Every workout entry shows:** exercise type, duration, estimated calories burned (R6), in list Cards.
- **Formula:** `kcal = MET × weight(kg) × duration(h)`. MET table: Walking 3.5, Running 9.8, Cycling 7.5, Gym 5.0, Yoga 3.0, Swimming 6.0, Other 4.0. Default weight 70 kg, editable in the target dialog (F9).

### 6.3 Daily Summary

- Date header with prev/next arrows.
- **Hero progress ring:** consumed ÷ target. Big number in the centre (remaining kcal), small label "kcal left".
- **Three stat tiles:** Consumed, Burned, Target.
- **Balance text:** `Remaining = Target − Consumed + Burned`. Within target → primary colour; over → error colour.
- **Entry list:** two sections (Meals, Workouts), each entry a Card with title, subtitle, kcal.
- Empty state if nothing logged.

### 6.4 Edit / delete

- Swipe left (`Dismissible`) deletes with undo snackbar; tap a Card opens the same form pre-filled in "Edit" mode.
- After save/delete, the ring and numbers update without a manual refresh (shared provider).

## 7. UI and visual design

- **Material 3**, `useMaterial3: true`, `ColorScheme.fromSeed` with a fresh green/teal seed (#16A37F). Light theme first; dark theme if time permits.
- **Colour roles:** primary = within target, tertiary/orange = burned, error = over target.
- **Typography:** `displayMedium` for ring centre number, `titleLarge` for section headers, `labelLarge` for chips/buttons. Calories always shown with the "kcal" unit in smaller text.
- **Shapes:** rounded Cards (16 dp), pill buttons, 8 dp spacing grid.
- **Progress cues:** ring on Summary, step chip on forms, linear bar in each meal-type section is *not* needed.
- **Responsive:** single column on phones; on tablets/web, Summary becomes two columns (ring + stats left, list right).
- **Accessibility:** min tap target 48 dp, contrast-safe colours, semantic label on the ring ("1,580 of 2,000 calories consumed").

## 8. Technical design

### 8.1 Architecture

`UI (screens/widgets) → Riverpod providers → Repository → Local storage`

```
lib/
  main.dart
  models/        entry.dart (Meal/Workout), balance.dart
  data/          log_repository.dart
  logic/         calorie_calculator.dart, met_table.dart
  providers/     day_log_provider.dart, balance_provider.dart, target_provider.dart, selected_date_provider.dart
  screens/       summary_screen.dart, log_meal_screen.dart, log_workout_screen.dart
  widgets/       calorie_ring.dart, entry_card.dart, stat_tile.dart
  theme/         app_theme.dart
```

### 8.2 State (Riverpod 3.x)

- `selectedDateProvider` — `Notifier<DateTime>`.
- `targetProvider` — `Notifier<int>` (persisted).
- `dayLogProvider` — `AsyncNotifier<List<Entry>>`: loads entries for the selected date; has `add`, `update`, `remove`.
- `balanceProvider` — `FutureProvider<Balance>`: watches `dayLogProvider.future` and `targetProvider`, computes balance.
- Log Meal, Log Workout and Summary all `ref.watch(balanceProvider)` so they always agree (R4).
- Note: in Riverpod 3 use `Notifier`/`AsyncNotifier`, not the legacy `StateNotifier`.

### 8.3 Async calorie-balance flow (R3, R7)

1. User taps Save → `dayLogProvider.notifier.add(entry)`.
2. Notifier `await`s the repository write to local storage.
3. State is updated with the new list → `balanceProvider` is invalidated.
4. `balanceProvider` awaits the list, runs `calculateBalance(entries, target)`, returns `Balance(consumed, burned, target, remaining, isOver)`.
5. UI shows `AsyncValue` states: loading (subtle shimmer/indicator), data (ring), error (retry message).

The async is real because it sits on the storage read/write pipeline, not a fake delay.

### 8.4 Local storage (R10)

- `shared_preferences`, one JSON string per date key (`log_2026-10-02`), plus keys for target and weight.
- `Entry.toJson/fromJson` with a `type` field (meal/workout).
- On app start, today's log is loaded asynchronously, so it works offline with no network code.

### 8.5 Data models

```
Entry { id, type(meal|workout), title, kcal, createdAt,
        // meal: mealType
        // workout: exerciseType, durationMin }
Balance { consumed, burned, target, remaining, isOver, progress }
```

`progress = clamp(consumed / target, 0, 1)` (ring); `remaining = target − consumed + burned`.

### 8.6 Edge cases

- Target = 0 or empty → block with validation.
- Consumed > target → ring full, error colour, "X kcal over".
- Burn larger than consumed → remaining can exceed target; ring stays at ≥0.
- Deleting the last entry → empty state.
- Date with no data → empty list, ring at 0.

## 9. Figma deliverable

Frames (390 × 844 mobile, plus one tablet frame):

1. **Daily Summary** — default with data
2. **Daily Summary — over target** state
3. **Log Meal** (with chips and list)
4. **Log Workout** (with live estimate)
5. **Edit entry** (pre-filled form)
6. **Delete + undo** state
7. **Empty state**
8. **Tablet Summary** (two columns)

Plus a style sheet (colours, type, components) and prototype arrows: Summary → Log Meal → Save → Summary; Summary → Log Workout → Save → Summary; Summary → tap entry → Edit → Save.

## 10. Prototype definition of done

- Add meal → ring changes with no restart.
- Add workout → burned and remaining update, estimate matches formula.
- Edit and delete update balance immediately.
- Close and reopen the app → data still there, in airplane mode.
- Resize window/rotate → layout adapts (rail on wide screens).
- One unit test for `calculateBalance` passes.

## 11. Justifications (for viva)

- **Riverpod:** shared state across three screens without passing callbacks, built-in `AsyncValue` handling for loading/error, easy to test.
- **AsyncNotifier + FutureProvider:** the data is loaded and saved asynchronously, so calculation naturally follows an awaited result.
- **No backend:** brief asks for offline use; a server adds failure points with no benefit.
- **shared_preferences:** data per day is tiny; a SQL database would be overkill.
- **MET formula:** a standard, explainable way to estimate burn instead of a typed-in guess.
- **Ring = consumed ÷ target:** matches the brief's wording; the remaining text includes burned calories, so the balance is still net.
- **M3 theming from a seed:** consistent colours and accessible contrast with little custom work.

## 12. Suggested build order

1. Models + `calculateBalance` + unit test
2. Repository + local storage
3. Providers
4. Summary screen with ring
5. Log Meal, then Log Workout
6. Edit/delete + undo
7. Theme polish + responsive layout
8. Figma frames kept in sync, then demo rehearsal

## 13. Risks

| Risk | Mitigation |
| --- | --- |
| Scope creep | Features in "should have" only if must-haves work |
| State bugs between screens | Only two shared providers, no local copies of data |
| Fake-looking async | Tie to storage pipeline, explain in viva |
| Package version changes | Check pub.dev for current `flutter_riverpod` / `shared_preferences` versions before starting |