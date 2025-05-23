import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habitap/database/habit_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: ListView(
        children: const [
          // Account Section
          Padding(
            padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 0.0),
            child: Text(
              'Account',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: AccountTile(),
          ),

          // Import & Export Section
          Padding(
            padding: EdgeInsets.only(left: 24.0, top: 24.0, bottom: 0.0),
            child: Text(
              'Import & Export',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ExportCSVTile(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: BackupToStorageTile(),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ImportDataTile(),
          ),
        ],
      ),
    );
  }
}

class AccountTile extends StatelessWidget {
  const AccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(
                Icons.person_outline,
                color: Colors.white,
              ),
            ),
            title: const Text(
              'Anonymous',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class ExportCSVTile extends StatelessWidget {
  const ExportCSVTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.share_outlined,
          size: 26,
        ),
        title: const Text(
          'Share Backup Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () => _exportHabits(context),
      ),
    );
  }

  void _exportHabits(BuildContext context) async {
    try {
      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing export...'))
      );

      // Export functionality
      final habitDatabase = Provider.of<HabitDatabase>(context, listen: false);
      await habitDatabase.exportHabitsAsCSV();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Habits exported successfully!'))
      );
    } catch (e) {
      debugPrint('Export error: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString().split('\n')[0]}'))
      );
    }
  }
}

class BackupToStorageTile extends StatelessWidget {
  const BackupToStorageTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.save_alt,
          size: 26,
        ),
        title: const Text(
          'Save Backup to Storage',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: const Text(
          '/storage/emulated/0/HabiTap/backup/',
          style: TextStyle(fontSize: 12),
        ),
        onTap: () => _saveToStorage(context),
      ),
    );
  }

  void _saveToStorage(BuildContext context) async {
    try {
      // Request storage permission first
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission is required to save backups'))
        );
        return;
      }

      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saving backup to storage...'))
      );

      // Export functionality
      final habitDatabase = Provider.of<HabitDatabase>(context, listen: false);
      final filePath = await habitDatabase.exportHabitsToCustomDirectory();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved to: $filePath'))
      );
    } catch (e) {
      debugPrint('Backup error: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: ${e.toString().split('\n')[0]}'))
      );
    }
  }
}

class ImportDataTile extends StatelessWidget {
  const ImportDataTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(
          Icons.drive_folder_upload,
          size: 26,
          color: Colors.white,
        ),
        title: const Text(
          'Import data',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        onTap: () => _importHabits(context),
      ),
    );
  }

  void _importHabits(BuildContext context) async {
    try {
      // Pick file directly without permission checks
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Importing habits...'))
        );

        final habitDatabase = Provider.of<HabitDatabase>(context, listen: false);
        await habitDatabase.importHabitsFromCSV(result.files.single.path!);

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habits imported successfully!'))
        );
      }
    } catch (e) {
      debugPrint('Import error: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${e.toString().split('\n')[0]}'))
      );
    }
  }
}