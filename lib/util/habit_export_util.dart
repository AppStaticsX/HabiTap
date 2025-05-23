import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:habitap/models/habit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';

class HabitExportUtil {
  /// Converts a list of habits into CSV format
  static String habitsToCSV(List<Habit> habits) {
    // Define header row
    List<List<dynamic>> csvData = [
      ['Habit ID', 'Habit Name', 'Completion Date']
    ];

    // Add data rows
    for (var habit in habits) {
      if (habit.completedDays == null || habit.completedDays!.isEmpty) {
        // Add a row for the habit even if it has no completed days
        csvData.add([habit.id, habit.name, '']);
      } else {
        // Add a row for each completed day
        for (var completedDay in habit.completedDays!) {
          String formattedDate = '${completedDay.date.year}-${completedDay.date.month.toString().padLeft(2, '0')}-${completedDay.date.day.toString().padLeft(2, '0')}';
          csvData.add([habit.id, habit.name, formattedDate]);
        }
      }
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(csvData);
    return csv;
  }

  /// Exports habits as CSV file and returns the file path
  static Future<String> exportHabitsToFile(List<Habit> habits) async {
    try {
      // Convert habits to CSV
      String csvData = habitsToCSV(habits);

      // Get directory for storing the file
      final directory = await _getExportDirectory();

      // Create filename with timestamp
      String timestamp = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      String fileName = 'habitap_export_$timestamp.csv';

      // Create and write to file
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      return file.path;
    } catch (e) {
      debugPrint('Error exporting habits: $e');
      rethrow;
    }
  }

  /// Exports habits to custom directory
  static Future<String> exportHabitsToCustomDirectory(List<Habit> habits) async {
    try {
      // Check for storage permission on Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission is required to save backups');
          }
        }
      }

      // Convert habits to CSV
      String csvData = habitsToCSV(habits);

      // Create the custom directory path
      final directory = Directory('/storage/emulated/0/HabiTap/backup/');

      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Create filename with timestamp
      String timestamp = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      String fileName = 'habitap_export_$timestamp.csv';

      // Create and write to file
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);

      return file.path;
    } catch (e) {
      debugPrint('Error exporting habits to custom directory: $e');
      rethrow;
    }
  }

  /// Exports and shares the habits CSV file
  static Future<void> exportAndShareHabits(List<Habit> habits) async {
    try {
      // Convert habits to CSV
      String csvData = habitsToCSV(habits);

      // For sharing, we'll use a temporary file in the cache directory
      // This avoids permission issues as apps have write access to their cache
      final tempDir = await getTemporaryDirectory();
      String timestamp = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      String fileName = 'habitap_export_$timestamp.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(file.path)], text: 'HabitAp Data Export');
    } catch (e) {
      debugPrint('Error sharing habits: $e');
      rethrow;
    }
  }

  /// Gets the appropriate directory based on platform
  static Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      // For Android, we'll use the downloads directory available through path_provider
      // This avoids complex permission issues in newer Android versions
      try {
        // First try to get the downloads directory
        Directory? directory = await getExternalStorageDirectory();

        // If null, fall back to app documents directory
        if (directory == null) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          // If we got external storage directory, try to navigate to Download folder
          // This is a common approach for Android
          String newPath = "";
          List<String> paths = directory.path.split("/");
          for (int x = 1; x < paths.length; x++) {
            String folder = paths[x];
            if (folder != "Android") {
              newPath += "/$folder";
            } else {
              break;
            }
          }
          newPath += "/Download";
          directory = Directory(newPath);

          // Create the directory if it doesn't exist
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }

        return directory;
      } catch (e) {
        // If any error occurs, fall back to the application documents directory
        debugPrint('Error accessing external storage: $e');
        return await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Import habits from CSV file
  static Future<List<Map<String, dynamic>>> importHabitsFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      final contents = await file.readAsString();

      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(contents);

      // Skip header row
      if (rowsAsListOfValues.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> importedHabits = [];
      Map<String, Map<String, dynamic>> habitsMap = {};

      // Start from 1 to skip header
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        var row = rowsAsListOfValues[i];
        if (row.length < 3) continue;

        String habitId = row[0].toString();
        String habitName = row[1].toString();
        String completionDate = row[2].toString();

        // If this is a new habit we haven't processed yet
        if (!habitsMap.containsKey(habitId)) {
          habitsMap[habitId] = {
            'id': int.tryParse(habitId) ?? DateTime.now().millisecondsSinceEpoch,
            'name': habitName,
            'completedDays': <DateTime>[]
          };
        }

        // Add completion date if present
        if (completionDate.isNotEmpty) {
          try {
            DateTime date = DateTime.parse(completionDate);
            (habitsMap[habitId]!['completedDays'] as List<DateTime>).add(date);
          } catch (e) {
            debugPrint('Error parsing date: $completionDate');
          }
        }
      }

      // Convert map to list
      importedHabits = habitsMap.values.toList();
      return importedHabits;
    } catch (e) {
      debugPrint('Error importing habits: $e');
      rethrow;
    }
  }
}