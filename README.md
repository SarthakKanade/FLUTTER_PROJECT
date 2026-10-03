# FitTrail — Personal Workout & Diet Tracker

> **One-line pitch:** *Log it, see it, stay on target.*  
> **Platform:** Android, iOS, Web, macOS (Responsive Mobile & Tablet/Desktop)  
> **State Management:** Riverpod 3 (`AsyncNotifier`, `Notifier`, `FutureProvider`)  
> **Design:** Material 3 with Emerald Teal palette (`#16A37F`), Google Fonts (Outfit), and adaptive layouts.

---

## 🌟 Highlights That Make This Project Stand Out

1. **Production-Grade Clean Architecture**: Strict separation of concerns across `models/`, `data/`, `logic/`, `providers/`, `screens/`, `widgets/`, and `theme/`.
2. **True Asynchronous Pipeline (R3, R7)**: Zero fake delays. Real async reads and writes to local disk storage (`shared_preferences`) automatically trigger reactive recalculations via Riverpod's `FutureProvider`.
3. **Medical Standard MET Calorie Estimation (R6, Sec 6.2)**: Uses the Metabolic Equivalent of Task (MET) formula:
   $$\text{kcal} = \text{MET} \times \text{weight (kg)} \times \text{duration (hours)}$$
   Live calculation card updates instantly as the user changes exercise type or duration.
4. **Adaptive Responsive UI (R11)**:
   - **Phones (< 600 dp)**: Single-column layout with Material 3 bottom `NavigationBar` and Floating Action Button.
   - **Tablets/Desktop (≥ 600 dp)**: Two-column dashboard with `NavigationRail` (Left: Hero Ring + Stat Tiles + Status Banner; Right: Meals & Workouts Entry Lists).
5. **Interactive Hero Progress Ring (R2, R8, F12)**:
   - Animated progress sweep showing consumed vs target calories.
   - Dynamic over-target transition: When net calories exceed the budget, the ring, badges, and status banner seamlessly transition into high-contrast warning colors with "X kcal over target".
6. **Student Impression Multipliers**:
   - **Quick-Add Meal Chips (F10)**: 10 pre-configured common foods (Poha, Roti & Dal, Idli Sambar, Paneer Bhurji, Banana, Greek Yogurt, etc.) for 1-tap logging.
   - **Historical Date Navigation (F11)**: Previous/Next day arrows, interactive calendar date picker, and quick-jump "Today" chip.
   - **Customizable Target & Profile (F9)**: Editable daily calorie budget (default 2000 kcal) and body weight (default 70 kg) with real-time validation.
   - **Instant Swipe-To-Delete with Undo SnackBar (F13, R9)**: Dismissible cards with undo capability.
   - **Dark Mode & Light Mode**: Built-in dynamic theme switcher adhering to WCAG contrast standards.

---

## 📐 Architecture & Data Flow

```
UI (Screens / Widgets)
       │
       ▼
Riverpod 3 Providers
  ├── selectedDateProvider   (Notifier<DateTime>)
  ├── targetProvider         (AsyncNotifier<int>)
  ├── weightProvider         (AsyncNotifier<double>)
  ├── dayLogProvider         (AsyncNotifier<List<Entry>>)
  └── balanceProvider        (FutureProvider<Balance>)
       │
       ▼
Logic & Repository Layer
  ├── CalorieCalculator & MetCalculator (Pure Dart Logic)
  └── LogRepository (SharedPreferences Local Storage Pipeline)
```

---

## 📋 Requirements Mapping (College PRD Compliance)

| Requirement | Description | Implementation Details |
|---|---|---|
| **R1** | Log Workout, Log Meal, Summary using Form, ListView, Card | `screens/summary_screen.dart`, `screens/log_meal_screen.dart`, `screens/log_workout_screen.dart` |
| **R2** | Material 3 theme, progress rings, calorie typography | `theme/app_theme.dart` with `#16A37F` seed, `widgets/calorie_ring.dart` |
| **R3** | async/await calorie-balance calculation | `balanceProvider` watching `dayLogProvider.future` and `targetProvider` |
| **R4** | Riverpod exposes result across all screens | Shared providers watched in Summary, Log Meal, and Log Workout |
| **R5** | Progress cues for every screen | Stepper header chips on forms, animated circular ring on Summary |
| **R6** | Exercise type, duration, estimated burn in list | `EntryCard` displaying exercise icon, duration (min), and MET estimated burn |
| **R7** | Logging triggers async recalculation | Storage write triggers state refresh and automatic provider invalidation |
| **R8** | Summary progress ring: consumed vs target | Custom painter progress arc clamped to `[0.0, 1.0]` |
| **R9** | Edit or delete entry, balance updates immediately | `Dismissible` swipe-to-delete with undo + tap card to open prefilled edit modal |
| **R10** | Local storage for offline access | `shared_preferences` with key format `fittrail_log_YYYY-MM-DD` |
| **R11** | Responsive working prototype | Adaptive layout switching between `NavigationBar` and `NavigationRail` at 600 dp |
| **R12** | Examination justification & clean codebase | Documented code, zero linter warnings, unit and widget test suite |

---

## 🧪 Testing & Verification

Run all unit tests and widget tests:

```bash
flutter test
```

Run static analysis (clean score guarantee):

```bash
flutter analyze
```

---

## 🎓 Viva Defense / Examination Guide

1. **Why Riverpod over Provider or setState?**
   - Eliminates callback hell and widget coupling.
   - `AsyncNotifier` and `FutureProvider` handle asynchronous data loading, caching, error states, and invalidation natively without boilerplate.
2. **Why local `SharedPreferences` instead of SQLite or a cloud backend?**
   - The PRD specifies offline, frictionless, zero-login daily tracking. Daily JSON payloads are lightweight (< 5 KB per day), making key-value caching faster and more resilient than spinning up a full SQL engine or relying on internet connections.
3. **How does the MET formula work?**
   - Metabolic Equivalent of Task (MET) standardizes energy expenditure across activities. Multiplying by user weight and duration gives an accurate, physiologically validated estimate without guesswork.
4. **How is the async requirement satisfied?**
   - Writes to local storage are asynchronous (`await prefs.setString(...)`). When completed, the provider state updates, which cascades into an awaited balance recalculation in `balanceProvider`.
