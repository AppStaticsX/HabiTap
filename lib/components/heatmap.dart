import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class Heatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final DateTime startDate;
  final int totalHabits; // Added total number of habits

  const Heatmap({
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
      if (opacityPercentage < 0.1) {
        colorsets[i] = Colors.green.shade700.withValues(alpha: 0.1);
      } else if (opacityPercentage < 0.2) {
        colorsets[i] = Colors.green.shade700.withValues(alpha: 0.2);
      } else if (opacityPercentage < 0.3) {
        colorsets[i] = Colors.green.shade700.withValues(alpha: 0.3);
      } else if (opacityPercentage < 0.4) {
        colorsets[i] = Colors.green.shade700.withValues(alpha: 0.4);
      } else if (opacityPercentage < 0.5) {
        colorsets[i] = Colors.green.shade700.withValues(alpha: 0.5);
      } else if (opacityPercentage < 0.6) {
        colorsets[i] = Colors.green.shade700.withValues(alpha: 0.6);
      } else if (opacityPercentage < 0.7) {
        colorsets[i] = Colors.green.shade700.withValues(alpha: 0.7);
      } else if (opacityPercentage < 0.8) {
        colorsets[i] = Colors.green.shade700.withValues(alpha: 0.8);
      } else if (opacityPercentage < 0.9) {
        colorsets[i] = Colors.green.shade700.withValues(alpha: 0.9);
      } else {
        colorsets[i] = Colors.green.shade700;
      }
    }

    return colorsets;
  }

  @override
  Widget build(BuildContext context) {
    // Get current date
    final DateTime now = DateTime.now();

    // Calculate first day of current month
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 0);

    // Calculate last day of current month
    final DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/streaks-anim.json', // Update with your actual path
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  repeat: true, // Set to true for continuous animation
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                  child: Text(
                    'Habit Streaks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            HeatMap(
              startDate: firstDayOfMonth,  // Start from first day of current month
              endDate: lastDayOfMonth,     // End at last day of current month
              datasets: datasets,
              colorMode: ColorMode.color,
              defaultColor: Theme.of(context).colorScheme.secondary,
              textColor: Theme.of(context).colorScheme.inverseSurface,
              showText: true,
              scrollable: true,
              showColorTip: false,
              size: 30,
              colorsets: _generateDynamicColorsets(datasets),
            ),
            const SizedBox(height: 8),
            _buildHeatmapLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        const Text('Less'),
        const SizedBox(width: 10),

        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green.shade500,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        const Text('Medium'),
        const SizedBox(width: 10),

        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green.shade900,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        const Text('More'),
      ],
    );
  }

  String _getCurrentDate() {
    // Format date as "dd MMMM yyyy"
    return DateFormat('MMMM').format(DateTime.now());
  }
}