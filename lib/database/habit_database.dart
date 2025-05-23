import 'package:flutter/foundation.dart';
import 'package:habitap/models/app_settings.dart';
import 'package:habitap/models/habit.dart';
import 'package:habitap/util/habit_export_util.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HabitDatabase extends ChangeNotifier {
  static late Box<Habit> _habitsBox;
  static late Box<AppSettings> _settingsBox;

  // Map to track opened completedDays boxes
  final Map<int, Box<CompletedDay>> _completedDaysBoxes = {};

  // Habit Lists
  final List<Habit> currentHabits = [];

  // Initialize - Database
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(CompletedDayAdapter());
    Hive.registerAdapter(AppSettingsAdapter());

    // Open boxes
    _habitsBox = await Hive.openBox<Habit>('habits');
    _settingsBox = await Hive.openBox<AppSettings>('appSettings');
  }

  // Open CompletedDays box for a specific habit
  Future<Box<CompletedDay>> _openCompletedDaysBox(int habitId) async {
    if (_completedDaysBoxes.containsKey(habitId)) {
      return _completedDaysBoxes[habitId]!;
    }

    final boxName = 'completedDays_$habitId';
    final box = await Hive.openBox<CompletedDay>(boxName);
    _completedDaysBoxes[habitId] = box;
    return box;
  }

  // Save First Date Of App Startup (For HeatMap)
  Future<void> saveFirstLaunchDate() async {
    if (_settingsBox.isEmpty) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await _settingsBox.add(settings);
    }
  }

  // Get First Date of App Startup (For HeatMap)
  Future<DateTime?> getFirstLaunchDate() async {
    if (_settingsBox.isNotEmpty) {
      return _settingsBox.getAt(0)?.firstLaunchDate;
    }
    return null;
  }

  // Create Or Add New Habit
  Future<void> addHabit(String habitName) async {
    final habit = Habit()..name = habitName;

    await _habitsBox.add(habit);
    final completedDaysBox = await _openCompletedDaysBox(habit.id);

    habit.completedDays = HiveList(completedDaysBox);
    await habit.save();

    await readHabits();
  }

  // Read Habits From Database
  Future<void> readHabits() async {
    try {
      currentHabits.clear();

      if (_habitsBox.isOpen && _habitsBox.isNotEmpty) {
        List<Habit> habits = _habitsBox.values.toList();

        for (var habit in habits) {
          final completedDaysBox = await _openCompletedDaysBox(habit.id);

          if (habit.completedDays == null) {
            habit.completedDays = HiveList(completedDaysBox);
            await habit.save();
          } else if (habit.completedDays!.box == null) {
            habit.completedDays = HiveList(completedDaysBox, objects: habit.completedDays!.toList());
            await habit.save();
          }
        }

        currentHabits.addAll(habits);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error reading habits: $e');
    }
  }

  // Update Habits
  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    final habitIndex = _findHabitIndexById(id);

    if (habitIndex != -1) {
      final habit = _habitsBox.getAt(habitIndex);

      if (habit != null) {
        final completedDaysBox = await _openCompletedDaysBox(habit.id);

        if (habit.completedDays == null) {
          habit.completedDays = HiveList(completedDaysBox);
        } else if (habit.completedDays!.box == null) {
          habit.completedDays = HiveList(completedDaysBox, objects: habit.completedDays!.toList());
        }

        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

        if (isCompleted) {
          bool alreadyCompleted = habit.completedDays!.any((day) =>
          day.date.year == today.year &&
              day.date.month == today.month &&
              day.date.day == today.day);

          if (!alreadyCompleted) {
            final completedDay = CompletedDay(date: today);
            await completedDaysBox.add(completedDay);
            habit.completedDays!.add(completedDay);
          }
        } else {
          final toRemove = habit.completedDays!.where((day) =>
          day.date.year == today.year &&
              day.date.month == today.month &&
              day.date.day == today.day).toList();

          for (var day in toRemove) {
            habit.completedDays!.remove(day);
            await day.delete();
          }
        }

        await habit.save();
      }
    }

    await readHabits();
  }

  // Update Habit Name
  Future<void> updateHabitName(int id, String newName) async {
    final habitIndex = _findHabitIndexById(id);

    if (habitIndex != -1) {
      final habit = _habitsBox.getAt(habitIndex);

      if (habit != null) {
        habit.name = newName;
        await habit.save();
      }
    }

    await readHabits();
  }

  // Delete Habits
  Future<void> deleteHabit(int id) async {
    final habitIndex = _findHabitIndexById(id);

    if (habitIndex != -1) {
      final habit = _habitsBox.getAt(habitIndex);

      if (habit != null) {
        final boxName = 'completedDays_${habit.id}';
        Box<CompletedDay>? completedDaysBox = _completedDaysBoxes[habit.id];

        if (completedDaysBox == null) {
          try {
            completedDaysBox = await Hive.openBox<CompletedDay>(boxName);
            _completedDaysBoxes[habit.id] = completedDaysBox;
          } catch (e) {
            debugPrint('Error opening completedDays box: $e');
          }
        }

        if (habit.completedDays != null && habit.completedDays!.isNotEmpty) {
          for (var day in habit.completedDays!) {
            await day.delete();
          }
        }

        if (completedDaysBox != null) {
          await completedDaysBox.close();
          _completedDaysBoxes.remove(habit.id);
        }

        await Hive.deleteBoxFromDisk(boxName);
        await _habitsBox.deleteAt(habitIndex);
      }
    }

    await readHabits();
  }

  // Helper method to find habit index by id
  int _findHabitIndexById(int id) {
    for (int i = 0; i < _habitsBox.length; i++) {
      final habit = _habitsBox.getAt(i);
      if (habit != null && habit.id == id) {
        return i;
      }
    }
    return -1;
  }

  // Export habits to CSV and share
  Future<void> exportHabitsAsCSV() async {
    try {
      await HabitExportUtil.exportAndShareHabits(currentHabits);
    } catch (e) {
      debugPrint('Error exporting habits: $e');
      rethrow;
    }
  }

  // Export habits to CSV and return file path (default location)
  Future<String> exportHabitsToFile() async {
    try {
      return await HabitExportUtil.exportHabitsToFile(currentHabits);
    } catch (e) {
      debugPrint('Error exporting habits to file: $e');
      rethrow;
    }
  }

  // Export habits to custom directory
  Future<String> exportHabitsToCustomDirectory() async {
    try {
      return await HabitExportUtil.exportHabitsToCustomDirectory(currentHabits);
    } catch (e) {
      debugPrint('Error exporting habits to custom directory: $e');
      rethrow;
    }
  }

  // Import habits from CSV file
  Future<void> importHabitsFromCSV(String filePath) async {
    try {
      List<Map<String, dynamic>> importedHabits = await HabitExportUtil.importHabitsFromCSV(filePath);

      for (var habitData in importedHabits) {
        final habit = Habit()
          ..name = habitData['name']
          ..id = habitData['id'];

        await _habitsBox.add(habit);
        final completedDaysBox = await _openCompletedDaysBox(habit.id);

        habit.completedDays = HiveList(completedDaysBox);
        await habit.save();

        // Add completed days
        List<DateTime> completedDays = habitData['completedDays'];
        for (var date in completedDays) {
          final completedDay = CompletedDay(date: date);
          await completedDaysBox.add(completedDay);
          habit.completedDays!.add(completedDay);
        }

        await habit.save();
      }

      await readHabits();
    } catch (e) {
      debugPrint('Error importing habits: $e');
      rethrow;
    }
  }
}