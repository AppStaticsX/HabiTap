import 'package:habitap/models/habit.dart';

bool isHabitCompletedToday(Habit habit) {
  final today = DateTime.now();

  if (habit.completedDays == null) {
    return false;
  }

  return habit.completedDays!.any(
        (completedDay) =>
    completedDay.date.year == today.year &&
        completedDay.date.month == today.month &&
        completedDay.date.day == today.day,
  );
}

Map<DateTime, int> prepMapDataset(List<Habit> habits) {
  Map<DateTime, int> dataset = {};

  for (var habit in habits) {
    if (habit.completedDays == null) continue;

    for (var completedDay in habit.completedDays!) {
      final date = completedDay.date;
      final normalizedDate = DateTime(date.year, date.month, date.day);

      if (dataset.containsKey(normalizedDate)) {
        dataset[normalizedDate] = dataset[normalizedDate]! + 1;
      } else {
        dataset[normalizedDate] = 1;
      }
    }
  }

  return dataset;
}