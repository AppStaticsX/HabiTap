import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class AnalyticsHeatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final DateTime startDate;
  final int totalHabits; // Added total number of habits

  const AnalyticsHeatmap({
    super.key,
    required this.datasets,
    required this.startDate,
    required this.totalHabits, // Required parameter for total habits
  });

  // Generate dynamic colorsets based on the total number of habits
  Map<int, Color> _generateDynamicColorsets(Map<DateTime, int> datasets) {
    Map<int, Color> colorsets = {};

    // Find the maximum completed habits in a day
    int maxValue = datasets.values.isEmpty ? totalHabits : datasets.values.reduce((max, value) => max > value ? max : value);
    maxValue = maxValue > 0 ? maxValue : totalHabits;

    // Create color gradient based on the number of habits
    for (int i = 1; i <= totalHabits; i++) {
      // Calculate opacity percentage based on completed habits ratio
      double opacityPercentage = i / totalHabits;

      // Create a color with varying intensity based on completion ratio
      // Using shade variants for better visibility
      if (opacityPercentage == 1) {
        colorsets[i] = Colors.green.shade600;
      }
    }

    return colorsets;
  }

  @override
  Widget build(BuildContext context) {
    // Get current date
    final DateTime now = DateTime.now();

    // Calculate first day of current month
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, now.day);

    // Calculate last day of current month
    final DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HeatMapCalendar(
              initDate: firstDayOfMonth,  // Start from first day of current month
              datasets: datasets,
              colorMode: ColorMode.color,
              defaultColor: Theme.of(context).colorScheme.secondary,
              textColor: Theme.of(context).colorScheme.inverseSurface,
              showColorTip: false,
              size: 34,
              colorsets: _generateDynamicColorsets(datasets),
            ),
          ],
        ),
      ),
    );
  }
}