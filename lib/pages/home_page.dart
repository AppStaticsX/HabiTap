import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:habitap/components/app_drawer.dart';
import 'package:habitap/components/habit_tile.dart';
import 'package:habitap/components/heatmap.dart';
import 'package:habitap/database/habit_database.dart';
import 'package:habitap/models/habit.dart';
import 'package:habitap/util/habit_util.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Add device info package

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController textController = TextEditingController();
  bool isStoragePermissionGranted = false;

  @override
  void initState() {
    super.initState();
    // Make sure to reload habits when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStoragePermission(); // Check storage permission on app start
    });
  }

  // Check if we need to request storage permission based on Android version
  Future<void> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      // For Android 11 (API level 30) and above, we need to request MANAGE_EXTERNAL_STORAGE
      if (androidInfo.version.sdkInt >= 30) {
        // Check if we have manage external storage permission
        if (await Permission.manageExternalStorage.isGranted) {
          debugPrint('Manage external storage permission granted');
          setState(() {
            isStoragePermissionGranted = true;
          });
          _loadHabits();
        } else {
          _requestManageExternalStoragePermission();
        }
      } else {
        // For Android 10 and below, regular storage permission is enough
        _requestStoragePermission();
      }
    } else {
      // For non-Android platforms, just load habits
      setState(() {
        isStoragePermissionGranted = true;
      });
      _loadHabits();
    }
  }

  // Method to request storage permission for Android 10 and below
  Future<void> _requestStoragePermission() async {
    // Request storage permission
    PermissionStatus status = await Permission.storage.request();

    // Handle the permission status
    if (status.isGranted) {
      // Permission granted, proceed with your app functionality
      debugPrint('Storage permission granted');
      setState(() {
        isStoragePermissionGranted = true;
      });
      _loadHabits();
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, show dialog to open app settings
      _showPermissionPermanentlyDeniedDialog();
    } else {
      // Permission denied but not permanently
      _showPermissionDeniedDialog();
    }
  }

  // Method to request manage external storage permission for Android 11+
  Future<void> _requestManageExternalStoragePermission() async {
    // Request manage external storage permission
    PermissionStatus status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      debugPrint('Manage external storage permission granted');
      setState(() {
        isStoragePermissionGranted = true;
      });
      _loadHabits();
    } else {
      // Show dialog to guide user to enable permission in settings
      _showManageStoragePermissionDialog();
    }
  }

  void _loadHabits() {
    // Method to load habits after permission is granted
    Provider.of<HabitDatabase>(context, listen: false).readHabits();
  }

  // Dialog specifically for Manage External Storage permission (Android 11+)
  void _showManageStoragePermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
            'This app requires permission to manage all files on your device to properly store and manage habit data. '
                'Please click "Allow" on the next screen and enable the permission.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showExitDialog();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // Open app settings to enable the permission
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Dialog for when permission is permanently denied
  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
            'Storage permission is required for this app to function properly. '
                'Please grant storage permission in the app settings.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showExitDialog();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // This is provided by permission_handler
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Dialog for when permission is denied but not permanently
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
            'Storage permission is required for this app to store habit data. '
                'Please grant the permission to continue using the app.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showExitDialog();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkStoragePermission(); // Check permissions again
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Exit dialog when user denies permission
  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
            'You must allow storage permission to continue using the app.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkStoragePermission(); // Give one more chance
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              // Exit the app
              Navigator.pop(context);
              exit(0); // This is a hard exit, consider using a more graceful approach
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  // Show custom toast message similar to the Java implementation
  void _showCustomToast(String message, IconData icon, {int durationInSeconds = 2}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: durationInSeconds),
      ),
    );
  }

  void createNewHabit() {
    if (!isStoragePermissionGranted) {
      _showCustomToast(
          'Storage permission is required to add habits',
          Icons.warning_amber_rounded,
          durationInSeconds: 3
      );
      _checkStoragePermission();
      return;
    }

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('New Habbit'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Create a New Habit',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: false,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
              // Add shadow with BoxDecoration by wrapping TextField in Container
            ),
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                String newHabitName = textController.text;
                context.read<HabitDatabase>().addHabit(newHabitName);
                Navigator.pop(context);
                textController.clear();
              },
              child: const Text('Save'),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.pop(context);
                textController.clear();
              },
              child: const Text('Cancel'),
            )
          ],
        )
    );
  }

  void checkHabitOnOff(bool? value, Habit habit) {
    if (value != null) {
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  void editHabitBox(Habit habit) {
    if (!isStoragePermissionGranted) {
      _showCustomToast(
          'Storage permission is required to edit habits',
          Icons.warning_amber_rounded,
          durationInSeconds: 3
      );
      _checkStoragePermission();
      return;
    }

    textController.text = habit.name;

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Habit'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Create a New Habit',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: false,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
              // Add shadow with BoxDecoration by wrapping TextField in Container
            ),
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                String newHabitName = textController.text;
                context.read<HabitDatabase>().updateHabitName(habit.id, newHabitName);
                Navigator.pop(context);
                textController.clear();
              },
              child: const Text('Save'),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.pop(context);
                textController.clear();
              },
              child: const Text('Cancel'),
            )
          ],
        )
    );
  }

  void deleteHabitBox(Habit habit) {
    if (!isStoragePermissionGranted) {
      _showCustomToast(
          'Storage permission is required to delete habits',
          Icons.warning_amber_rounded,
          durationInSeconds: 3
      );
      _checkStoragePermission();
      return;
    }

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Habit?'),
          actions: [
            MaterialButton(
              onPressed: () {
                context.read<HabitDatabase>().deleteHabit(habit.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
            MaterialButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            )
          ],
        )
    );
  }

  String _getCurrentDate() {
    // Format date as "dd MMMM yyyy"
    return DateFormat('dd MMMM yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(onPressed: () {},
                icon: Icon(Icons.notifications_active_outlined)),
          )
        ],
        title: Text(_getCurrentDate(),
          style: const TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 10,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: !isStoragePermissionGranted
          ? _buildPermissionRequiredMessage()
          : ListView(
        children: [
          const SizedBox(height: 16),
          _buildHeatMap(),
          const SizedBox(height: 16),
          _buildHabitList(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPermissionRequiredMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: 80,
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            "Storage Permission Required",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              "This app needs storage permission to save your habit data. Please grant the permission to continue.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _checkStoragePermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Grant Permission"),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatMap() {
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;

    // Get the total number of habits for the heatmap
    int totalHabits = currentHabits.length;
    // Use at least 1 for total habits to avoid division by zero
    totalHabits = totalHabits > 0 ? totalHabits : 1;

    return FutureBuilder(
        future: habitDatabase.getFirstLaunchDate(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Heatmap(
              datasets: prepMapDataset(currentHabits),
              startDate: snapshot.data!,
              totalHabits: totalHabits, // Pass the total number of habits
            );
          } else {
            return Container();
          }
        }
    );
  }

  Widget _buildHabitList() {
    final habitDatabase = context.watch<HabitDatabase>();
    List<Habit> currentHabits = habitDatabase.currentHabits;

    // Check if there are no habits and show a message
    if (currentHabits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_add_outlined,
                size: 50,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                "No habits added yet",
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                "Create your first habit to get started",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Tap + button to add a Habit.",
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.4),
                child: Transform.rotate(
                  angle: -20 * (math.pi / 180), // Convert 30 degrees to radians
                  child: Lottie.asset(
                    'assets/lottie/arrow-anim.json', // Update with your actual path
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                    repeat: false, // Set to true for continuous animation
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }

    // If there are habits, show the ListView with habit tiles
    return ListView.builder(
        itemCount: currentHabits.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final habit = currentHabits[index];

          // Use the updated utility function to check if habit is completed today
          bool isCompletedToday = isHabitCompletedToday(habit);

          return HabitTile(
            isCompleted: isCompletedToday,
            text: habit.name,
            onChanged: (value) => checkHabitOnOff(value, habit),
            editHabit: (context) => editHabitBox(habit),
            deleteHabit: (context) => deleteHabitBox(habit),
          );
        }
    );
  }
}