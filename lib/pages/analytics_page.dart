import 'package:flutter/material.dart';
import 'package:habitap/components/analytics_heatmap.dart';
import 'package:habitap/database/habit_database.dart';
import 'package:habitap/models/habit.dart';
import 'package:habitap/util/habit_util.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('ANALYTICS',
          style: const TextStyle(fontWeight: FontWeight.bold,
              letterSpacing: 2),),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),

      body: FutureBuilder(
          future: context.watch<HabitDatabase>().getFirstLaunchDate(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final startDate = snapshot.data!;
            return _buildHabitsList(startDate);
          }
      ),
    );
  }

  Widget _buildHabitsList(DateTime startDate) {
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;

    if (currentHabits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'No habits to analyze yet',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add habits to see analytics',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: currentHabits.length,
      itemBuilder: (context, index) {
        final habit = currentHabits[index];
        return _buildHabitHeatmapCard(habit, startDate);
      },
    );
  }

  Widget _buildHabitHeatmapCard(Habit habit, DateTime startDate) {
    // Get completion data for just this specific habit
    Map<DateTime, int> habitData = {};

    if (habit.completedDays != null) {
      for (var day in habit.completedDays!) {
        DateTime dateKey = DateTime(day.date.year, day.date.month, day.date.day);
        // For individual habit tracking, we use 1 as the value since it's completed
        habitData[dateKey] = 1;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Lottie.asset(
                  'assets/lottie/streaks-anim.json', // Update with your actual path
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  repeat: true, // Set to true for continuous animation
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Completed ${habit.completedDays?.length ?? 0} times',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AnalyticsHeatmap(
              datasets: habitData,
              startDate: startDate,
              totalHabits: 1, // Since we're displaying individual habits, totalHabits is 1
            ),
            const SizedBox(height: 8),
            _buildStreakInfo(habit),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakInfo(Habit habit) {
    int currentStreak = _calculateCurrentStreak(habit);
    int longestStreak = _calculateLongestStreak(habit);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStreakCard(
          'Current',
          '$currentStreak days',
          Icons.local_fire_department,
          Colors.orange,
        ),
        _buildStreakCard(
          'Longest',
          '$longestStreak days',
          Icons.emoji_events,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStreakCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCurrentStreak(Habit habit) {
    if (habit.completedDays == null || habit.completedDays!.isEmpty) {
      return 0;
    }

    // Sort completedDays by date (newest first)
    final completedDays = habit.completedDays!.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if habit was completed today or yesterday
    bool hasToday = completedDays.any((day) =>
    day.date.year == today.year &&
        day.date.month == today.month &&
        day.date.day == today.day);

    bool hasYesterday = completedDays.any((day) =>
    day.date.year == yesterday.year &&
        day.date.month == yesterday.month &&
        day.date.day == yesterday.day);

    // If neither today nor yesterday was completed, streak is 0
    if (!hasToday && !hasYesterday) {
      return 0;
    }

    // Calculate streak
    int streak = hasToday ? 1 : 0;
    DateTime currentDate = hasToday ? yesterday : today.subtract(const Duration(days: 2));

    while (true) {
      bool hasDate = completedDays.any((day) =>
      day.date.year == currentDate.year &&
          day.date.month == currentDate.month &&
          day.date.day == currentDate.day);

      if (!hasDate) break;

      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int _calculateLongestStreak(Habit habit) {
    if (habit.completedDays == null || habit.completedDays!.isEmpty) {
      return 0;
    }

    // Sort completedDays by date
    final completedDays = habit.completedDays!.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < completedDays.length; i++) {
      final difference = completedDays[i].date.difference(completedDays[i-1].date).inDays;

      if (difference == 1) {
        // Consecutive days
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else if (difference > 1) {
        // Streak broken
        currentStreak = 1;
      }
    }

    return longestStreak;
  }
}